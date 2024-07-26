#!/bin/bash

# スクリプトをエラーが発生した場合に停止する
set -e

# 引数チェック
if [ "$#" -ne 1 ]; then
  echo "Usage: $0 <username>"
  exit 1
fi

USERNAME=$1

# Sambaのインストール
sudo apt -y purge samba samba-common samba-common-bin
sudo apt -y autoremove
sudo apt -y update
sudo apt -y install samba

# ユーザーが既に存在するか確認
if id "$USERNAME" &>/dev/null; then
  echo "User $USERNAME already exists, skipping user creation."
else
  # 新規ユーザーの追加
  sudo adduser --disabled-login --gecos "" $USERNAME
fi

# Sambaユーザーの追加とパスワード設定
echo "Setting Samba password for user $USERNAME"
sudo smbpasswd -a $USERNAME

# Samba設定ファイルの編集
SAMBA_CONF="/etc/samba/smb.conf"
SHARE_NAME="share"
SHARE_PATH="$(pwd)/share"

# 共有ディレクトリの作成
sudo mkdir -p $SHARE_PATH
sudo chown $USERNAME:$USERNAME $SHARE_PATH
sudo chmod 700 $SHARE_PATH  # パーミッションを設定


sudo bash -c "cat >> $SAMBA_CONF <<EOL
[global]
   smb encrypt = required
[$SHARE_NAME]
   path = $SHARE_PATH
   valid users = $USERNAME
   guest ok = yes
   read only = no
   browsable = yes
EOL"

# UFWの設定（Sambaのポートを許可）
sudo ufw allow Samba

# UFWの有効化
sudo ufw enable

# Sambaサービスの再起動
sudo systemctl restart smbd
sudo systemctl restart nmbd

echo "Samba setup completed for user $USERNAME"
