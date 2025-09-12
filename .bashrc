column_kugiri=@w@a@w@
key_value_kugiri=@c@w@c@
output_flag=0

NOW_PROCESS=$(ps -p $PPID -o comm | awk 'END{print $0}')
# スクリプトではない(ttyd,sshd)だったら
if [ $NOW_PROCESS != "script" ]; then
  export typescriptID=$$
  script -f /usr/local/src/yamahira/typescript_$$
  exit
fi

function __accept-line() {
    if [ ! ${#READLINE_LINE} -eq 0 ]; then
        # 改行が含まれていたら、最初に1行目だけ残す
        if [[ "$READLINE_LINE" == *$'\n'* ]]; then
            READLINE_LINE="$(echo "$READLINE_LINE" | head -n 1)"
        fi

        # READLINE_LINEをスペース区切りで配列に変換
        local command_array=($READLINE_LINE)
        # 配列の最初の要素をBaseCommandとする
        local BaseCommand=${command_array[0]}
        # READLINE_LINE全体をFullCommandとする
        local FullCommand="$READLINE_LINE"

        local log_file=/usr/local/src/yamahira/lastcommand_$$
        unique_id=$(uuidgen)
        local uuid_file=/usr/local/src/yamahira/lastuuid_$$
        # UUID をログファイルに書き込む
        echo "$unique_id" > "$uuid_file"
        {
        echo -n "TimeStamp${key_value_kugiri}$(date "+%Y%m%d%H%M%S")${column_kugiri}"
        echo -n "CurrentDir${key_value_kugiri}${PWD}${column_kugiri}"
        echo -n "BaseCommand${key_value_kugiri}$READLINE_LINE${column_kugiri}"
        echo -n "FullCommand${key_value_kugiri}$READLINE_LINE${column_kugiri}"
        } >${log_file}
        python3 /usr/local/src/yamahira/command_logger.py $$ $unique_id $typescriptID
        output_flag=1
    else
        output_flag=0
  fi
}

bind -x '"\1299": __accept-line'
bind '"\1298": accept-line'
bind '"\C-m": "\1299\1298"'

function log_command() {
    local exit_code=$?
    sleep 0.3
    local log_file=/usr/local/src/yamahira/lastcommand_$$
    local uuid_file=/usr/local/src/yamahira/lastuuid_$$
    if [ $output_flag -eq 1 ]; then
        echo -n "ExitCode${key_value_kugiri}$exit_code" >>${log_file}
        local uuid=$(cat "$uuid_file" | tr -d '\n')
        python3 /usr/local/src/yamahira/command_logger.py $$ $uuid $typescriptID ${PWD}
    fi
}
PROMPT_COMMAND="log_command"