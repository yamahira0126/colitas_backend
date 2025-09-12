import re
import sys
import json
import subprocess

URL = ""
API_KEY = ""
AUTH_TOKEN = ""


PID = sys.argv[1]
TYPESCRIPT_ID = sys.argv[3]

def limit_string_length(input_string, max_length=1000000, suffix_length=1000):
    if len(input_string) <= max_length:
        return input_string
    else:
        return input_string[:max_length] + input_string[-suffix_length:]

with open(f'/usr/local/src/yamahira/typescript_{TYPESCRIPT_ID}', 'r') as input_file:
    result = ""
    for line in input_file:
        output_line = re.sub(r'\x1b\[[^mGK]*[mGK]', '', line)
        result += output_line
    result = result.split("2004l\n")

try:
    with open(f'/usr/local/src/yamahira/lastcommand_{PID}', 'r', encoding='utf-8') as file:
        lines = file.readlines()
        last_line = lines[-1].strip()
        existence_uuid = 0
        if last_line:
            parts = last_line.split('@w@a@w@')
            log_dict = {}
            for element in parts:
                key_value = element.split('@c@w@c@')
                if len(key_value) == 2:
                    key, value = key_value[0], key_value[1]
                    log_dict[key] = value
                   # print(log_dict)
        else:
            cmd = []

        try:
            # curlコマンドの-dで送信するJSONデータ
            # 更新後のデータ
            update_data = {
                'output': limit_string_length(result[-1]),
                'exit_code': log_dict['ExitCode'],
                'after_path': f'{sys.argv[4]}',
            }
            update_data_json = json.dumps(update_data)

            # --- UPDATE用のcmdリスト ---
            cmd = [
                'curl',
                '-X', 'PATCH',  # メソッドをPATCHに変更
                '-H', f'apikey: {API_KEY}',
                '-H', f'Authorization: Bearer {AUTH_TOKEN}',
                '-H', 'Content-Type: application/json',
                '-d', update_data_json,
                f'{URL}?uuid=eq.{sys.argv[2]}'  # URLにどの行を更新するかの条件を追加
            ]
        except KeyError as e:
            # curlコマンドの-dで送信するJSONデータ
            data = {
                'path': log_dict.get('CurrentDir'),
                'base_command': log_dict.get('BaseCommand'),
                'full_command': log_dict.get('FullCommand'),
                'uuid': sys.argv[2]
            }

            # Python辞書をJSON形式の文字列に変換
            data_json = json.dumps(data)

            # curlコマンドの各要素をリストに格納
            cmd = [
                'curl',
                '-X', 'POST',
                '-H', f'apikey: {API_KEY}',
                '-H', f'Authorization: Bearer {AUTH_TOKEN}',
                '-H', 'Content-Type: application/json',
                '-d', data_json,
                URL
            ]

        # --- コマンドの実行 ---
        try:
            result = subprocess.run(cmd, text=True, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
        except subprocess.CalledProcessError as e:
            print(f"log取得のエラーコード: {e.returncode}")
            print(f"学生の方は無視していただいて大丈夫です。: {e.stderr}")

except subprocess.CalledProcessError as e:
    print(f"コマンドがエラーを返しました。エラーコード: {e.returncode}")
    print(f"エラーメッセージ: {e.stderr}")