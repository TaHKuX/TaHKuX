#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_FILE="${SCRIPT_DIR}/conf.txt"
LOG_FILE="${SCRIPT_DIR}/server_access.log"

if [[ ! -f "$CONFIG_FILE" ]]; then
    echo "Ошибка: файл конфигурации $CONFIG_FILE не найден!" >&2
    exit 1
fi

if [[ ! -f "$LOG_FILE" ]]; then
    echo "Ошибка: файл лога $LOG_FILE не найден!" >&2
    exit 1
fi

# Загрузка переменных TOKEN и CHAT_ID из конфига
# shellcheck source=/dev/null
source "$CONFIG_FILE"

if [[ -z "${TOKEN:-}" || -z "${CHAT_ID:-}" ]]; then
    echo "Ошибка: в $CONFIG_FILE должны быть заданы TOKEN и CHAT_ID!" >&2
    exit 1
fi

# Поиск топ-5 IP с кодом ответа 500
# Формат лога: IP - - [дата] "МЕТОД URL ПРОТОКОЛ" СТАТУС ...
TOP_IPS=$(awk '$9 == "500" {print $1}' "$LOG_FILE" | sort | uniq -c | sort -rn | head -n 5 | awk '{printf "• `%s` — %d раз(а)\n", $2, $1}')

if [[ -z "$TOP_IPS" ]]; then
    MESSAGE="🎉 *ЧУДО СЛУЧИЛОСЬ!*
Ни одной 500-й ошибки в логах не найдено. Сервер жив, здоров и даже не дымится. Можно выдохнуть и попить кофе ☕"
else
    MESSAGE="🚨 *ВНИМАНИЕ! СЕРВЕР В ПАНИКЕ!* 🚨

Кажется, бэкенд решил прилечь отдохнуть. Вот *ТОП-5 подозреваемых IP*, которые чаще всего доводили его до 500-й ошибки:

${TOP_IPS}
🛠 _Срочно несите синюю изоленту и подорожник!_"
fi

# Отправка сообщения в Telegram
RESPONSE=$(curl -s -X POST "https://api.telegram.org/bot${TOKEN}/sendMessage" \
    -d chat_id="${CHAT_ID}" \
    -d parse_mode="Markdown" \
    --data-urlencode "text=${MESSAGE}")

if echo "$RESPONSE" | grep -q '"ok":true'; then
    echo "Отчет успешно отправлен в Telegram!"
else
    echo "Ошибка при отправке в Telegram: $RESPONSE" >&2
    exit 1
fi
