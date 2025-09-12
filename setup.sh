#!/bin/bash

# --------------------------------------------------
# リモートサーバーの初期設定を行うスクリプト
#
# 使い方:
# ./setup_remote.sh <学籍番号>
# --------------------------------------------------

# スクリプトの途中でエラーが発生したら、その時点で処理を終了する
set -e

# --- 設定項目 ---

# SSH接続情報
SSH_KEY_PATH="$HOME/.ssh/labsuser.pem"
SSH_USER="admin"

# ダウンロードするファイルのURL
PYTHON_SCRIPT_URL="https://raw.githubusercontent.com/yamahira0126/colitas_backend/main/command_logger.py"
BASHRC_URL="https://raw.githubusercontent.com/yamahira0126/colitas_backend/main/.bashrc"
TTYD_SERVICE_URL="https://raw.githubusercontent.com/yamahira0126/colitas_backend/main/ttyd"

# --- スクリプト本体 ---

# [引数チェック] 学籍番号が指定されているか確認
if [ -z "$1" ]; then
  echo "❌ Error: Please provide the Gakuseki ID as an argument."
  echo "Usage: $0 <Gakuseki_ID>"
  exit 1
fi

GAKUSEKI_ID="$1"
SSH_HOST="$2"

echo "🚀 Starting remote server setup for Gakuseki ID: $GAKUSEKI_ID"

# 'Here Document' (<<EOF) を使って、リモートサーバー上で一連のコマンドを実行
ssh -i "$SSH_KEY_PATH" "$SSH_USER@$SSH_HOST" <<EOF
  # リモート側でもエラー発生時は即終了させる
  set -e

  # --- 変数定義 ---
  TARGET_DIR="/usr/local/src/yamahira"
  GAKUSEKI_FILE="\$TARGET_DIR/gakuseki"

  # ===== ここから追加した処理 =====
  
  # 既存の学籍番号をファイルから読み込む（ファイルが存在しない場合は空文字になる）
  EXISTING_GAKUSEKI=\$(cat "\$GAKUSEKI_FILE" 2>/dev/null || true)

  # 引数の学籍番号と既存の学籍番号が一致するかチェック
  if [ "\$EXISTING_GAKUSEKI" == "$GAKUSEKI_ID" ]; then
    echo "  -> ✅ Setup for Gakuseki ID '$GAKUSEKI_ID' has already been completed. Nothing to do."
    # 処理を正常終了させる
    exit 0
  fi
  
  echo "  -> ⚠️  Gakuseki ID does not match or is not set. Starting setup..."
  # ===== 追加処理ここまで =====

  # --- 以下、セットアップ処理 ---
  PYTHON_FILE="\$TARGET_DIR/command_logger.py"
  
  echo "  -> 📂 Creating directory: \$TARGET_DIR"
  # -p オプションで親ディレクトリも同時に作成し、ディレクトリが既に存在してもエラーにしない
  sudo mkdir -p "\$TARGET_DIR"

  echo "  -> 🔐 Setting permissions for user 'admin' on \$TARGET_DIR"
  # ディレクトリの所有者をadminユーザーに変更
  sudo chown admin:admin "\$TARGET_DIR"
  # 所有者(admin)に読み取り、書き込み、実行権限を付与
  sudo chmod u+rwx "\$TARGET_DIR"

  echo "  -> ✍️  Writing Gakuseki ID (\$GAKUSEKI_ID) to \$GAKUSEKI_FILE"
  # sudo経由でファイルに書き込むため tee コマンドを使用
  echo "$GAKUSEKI_ID" | sudo tee "\$GAKUSEKI_FILE" > /dev/null

  echo "  -> 🐍 Downloading Python script to \$PYTHON_FILE"
  # sudo curlで特権が必要なディレクトリにファイルをダウンロード
  sudo curl -fsSL -o "\$PYTHON_FILE" "$PYTHON_SCRIPT_URL"

  echo "  -> 🛡️  Backing up existing .bashrc to .bashrc_backup"
  # [ -f ~/.bashrc ] でファイルの存在を確認してからコピーを実行
  [ -f ~/.bashrc ] && cp ~/.bashrc ~/.bashrc_backup || echo "  -> No existing .bashrc to back up. Skipping."

  echo "  -> ⚙️  Downloading and updating .bashrc"
  # curlで直接 .bashrc ファイルを上書きして更新
  curl -fsSL -o ~/.bashrc "$BASHRC_URL"

  echo "  -> 🌐 Installing ttyd from GitHub..."
  # ttydの実行ファイルをGitHubから直接ダウンロードして/usr/local/binに配置
  sudo curl -fsSL -o /usr/local/bin/ttyd https://github.com/tsl0922/ttyd/releases/download/1.7.7/ttyd.x86_64
  # ダウンロードしたファイルに実行権限を付与
  sudo chmod +x /usr/local/bin/ttyd

  echo "  -> 📝 Downloading ttyd.service file from GitHub..."
  sudo curl -fsSL -o /etc/systemd/system/ttyd.service "$TTYD_SERVICE_URL"

  echo "  -> 🚀 Enabling and starting ttyd service..."
  sudo systemctl daemon-reload
  sudo systemctl enable ttyd
  sudo systemctl start ttyd

  echo "  -> ✅ Remote setup complete!"
  echo "     NOTE: Please log out and log back in for .bashrc changes to take effect."

EOF

echo "🎉 Script finished successfully."