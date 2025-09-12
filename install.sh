#!/bin/bash
# Удобная ссылка на скрипт установки

# Определение операционной системы
if [[ "$OSTYPE" == "darwin"* ]]; then
    exec ./scripts/install_macos.sh "$@"
elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
    exec ./scripts/install_linux.sh "$@"
else
    echo "Неподдерживаемая операционная система: $OSTYPE"
    echo "Поддерживаются: macOS, Linux"
    exit 1
fi