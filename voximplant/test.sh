#!/bin/bash

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/conf.txt"

MESSAGE=$(awk '$9 ~ /^500/ {print $1}' server_access.log | sort | uniq -c | sort -nr | head -5)

TEXT="🚨 Топ IP с ошибкой 500:

${MESSAGE}"

curl -s -X POST "https://api.telegram.org/bot${TOKEN}/sendMessage" -d chat_id="${CHAT_ID}" --data-urlencode "text=${TEXT}" > /dev/null
