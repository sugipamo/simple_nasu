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
sudo apt update
sudo apt install -y samba

# 新規ユーザーの追加
sudo adduser --disabled-login --gecos "" $USERNAME

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

# グローバル設定の追加（通信の暗号化）
sudo bash -c "cat >> $SAMBA_CONF <<EOL
[global]
   smb encrypt = required
EOL"

# Samba設定ファイルに共有設定を追加
sudo bash -c "cat >> $SAMBA_CONF <<EOL

[$SHARE_NAME]
   path = $SHARE_PATH
   valid users = $USERNAME
   guest ok = no
   read only = no
   browsable = no
EOL"

# Sambaサービスの再起動
sudo systemctl restart smbd
sudo systemctl restart nmbd

echo "Samba setup completed for user $USERNAME"
