#!/bin/bash
# Hydra-L ESP8266 - Полная установка и прошивка одной командой

set -e

echo "🚀 Hydra-L ESP8266 - Автоматическая установка"
echo "=============================================="
echo

# Определение ОС и запуск установки
if [[ "$OSTYPE" == "darwin"* ]]; then
    echo "📱 Обнаружена macOS"
    ./scripts/install_macos.sh
elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
    echo "🐧 Обнаружена Linux"
    ./scripts/install_linux.sh
else
    echo "❌ Неподдерживаемая ОС: $OSTYPE"
    exit 1
fi

echo
echo "✅ Установка завершена!"
echo
echo "Следующие шаги:"
echo "1. Подключите ESP8266 через USB"
echo "2. Запустите: ./flash.sh"
echo