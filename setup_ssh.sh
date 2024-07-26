#!/bin/bash

# 更新と基本パッケージのインストール
sudo apt update
sudo apt upgrade -y

# OpenSSHサーバーのインストール
sudo apt install -y openssh-server
sudo systemctl start ssh
sudo systemctl enable ssh

# 使用可能なネットワークインターフェースを取得
INTERFACE=$(ip -o -4 route show to default | awk '{print $5}')

# ネットワークインターフェースが取得できない場合のエラーハンドリング
if [ -z "$INTERFACE" ]; then
  echo "Error: Could not find a network interface."
  exit 1
fi

NETPLAN_CONFIG="/etc/netplan/99_config.yaml"

# 設定ファイルのバックアップ
sudo cp $NETPLAN_CONFIG ${NETPLAN_CONFIG}.bak

# 静的IPアドレスの設定
sudo bash -c "cat > $NETPLAN_CONFIG <<EOF
network:
  version: 2
  renderer: networkd
  ethernets:
    $INTERFACE:
      dhcp4: false
      dhcp6: false
      addresses:
        - 192.168.0.100/24
        - 2001:db8::100/64
      routes:
        - to: default
          via: 192.168.0.1
        - to: default
          via: 2001:db8::1
      nameservers:
        addresses:
          - 192.168.0.1
          - 8.8.8.8
          - 8.8.4.4
          - 2001:4860:4860::8888
          - 2001:4860:4860::8844
EOF"

chmod 600 $NETPLAN_CONFIG

# 設定の適用
sudo netplan apply

# sshdの設定変更
SSHD_CONFIG="/etc/ssh/sshd_config.d/50-cloud-init.conf"

# 設定のバックアップ
sudo cp $SSHD_CONFIG ${SSHD_CONFIG}.bak

sudo bash -c "cat >> $SSHD_CONFIG <<EOF
Port 2458
# AddressFamily inet6
ListenAddress ::

PermitRootLogin no
PasswordAuthentication yes
PermitEmptyPasswords no
ChallengeResponseAuthentication no
EOF"

# 設定を反映
sudo systemctl restart ssh

# UFWの設定
sudo ufw allow OpenSSH
sudo ufw allow 2458/tcp
sudo ufw enable

sudo reboot now