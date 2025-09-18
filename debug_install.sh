#!/bin/bash

# Отладочная версия скрипта установки
# Исправляет проблемы с URL и git

set -e

echo "🔍 Отладочная установка Hydra-L ESP8266"
echo "========================================"

# Проверяем git
echo "📋 Проверка git:"
git --version
echo ""

# Проверяем переменные окружения
echo "📋 Проверка переменных окружения:"
echo "GIT_ASKPASS: $GIT_ASKPASS"
echo ""

# Определение операционной системы
echo "📋 Определение ОС:"
echo "OSTYPE: $OSTYPE"
if [[ "$OSTYPE" == "darwin"* ]]; then
    echo "Обнаружена macOS"
    INSTALL_SCRIPT="./scripts/install_macos.sh"
elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
    echo "Обнаружена Linux"
    INSTALL_SCRIPT="./scripts/install_linux.sh"
else
    echo "Неподдерживаемая ОС: $OSTYPE"
    exit 1
fi

echo "Скрипт установки: $INSTALL_SCRIPT"
echo ""

# Проверяем существование скрипта
if [ ! -f "$INSTALL_SCRIPT" ]; then
    echo "❌ Ошибка: Скрипт $INSTALL_SCRIPT не найден"
    exit 1
fi

echo "✅ Скрипт найден: $INSTALL_SCRIPT"
echo ""

# Запускаем скрипт с отладкой
echo "🚀 Запуск скрипта установки..."
echo "========================================"
bash -x "$INSTALL_SCRIPT"
