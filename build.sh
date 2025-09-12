#!/bin/bash

# Скрипт для сборки проекта Hydra-L на Linux
# Автор: Kiro AI Assistant
# Версия: 2.0

set -e  # Остановка при ошибке

echo "=== Hydra-L Build Script v2.0 ==="
echo "Сборка стабильной версии прошивки для ESP8266"
echo

# Проверка переменных окружения
if [ -z "$IDF_PATH" ]; then
    echo "Ошибка: Переменная IDF_PATH не установлена"
    echo "Пожалуйста, выполните: export IDF_PATH=/path/to/ESP8266_RTOS_SDK"
    exit 1
fi

if [ ! -d "$IDF_PATH" ]; then
    echo "Ошибка: Директория IDF_PATH не существует: $IDF_PATH"
    exit 1
fi

echo "IDF_PATH: $IDF_PATH"

# Проверка наличия инструментов
if ! command -v xtensa-lx106-elf-gcc &> /dev/null; then
    echo "Ошибка: xtensa-lx106-elf-gcc не найден в PATH"
    echo "Пожалуйста, установите ESP8266 toolchain"
    exit 1
fi

echo "Toolchain: $(xtensa-lx106-elf-gcc --version | head -n1)"

# Проверка Python зависимостей
echo "Проверка Python зависимостей..."
python3 -c "import click, cryptography, pyparsing, pyserial" 2>/dev/null || {
    echo "Ошибка: Не все Python зависимости установлены"
    echo "Выполните: pip3 install click cryptography pyparsing pyserial"
    exit 1
}

# Очистка предыдущей сборки
echo "Очистка предыдущей сборки..."
rm -rf build/
rm -f sdkconfig

# Копирование конфигурации по умолчанию
if [ -f "sdkconfig.defaults" ]; then
    cp sdkconfig.defaults sdkconfig
    echo "Конфигурация скопирована из sdkconfig.defaults"
fi

# Сборка проекта
echo "Начало сборки..."
echo "Это может занять несколько минут..."

# Используем idf.py для сборки
python3 $IDF_PATH/tools/idf.py build

if [ $? -eq 0 ]; then
    echo
    echo "=== СБОРКА ЗАВЕРШЕНА УСПЕШНО ==="
    echo
    echo "Файлы прошивки созданы в директории build/"
    echo "Основной файл: build/hydra_l.bin"
    echo
    echo "Для прошивки выполните:"
    echo "python3 $IDF_PATH/tools/idf.py -p /dev/ttyUSB0 flash"
    echo
    echo "Для мониторинга выполните:"
    echo "python3 $IDF_PATH/tools/idf.py -p /dev/ttyUSB0 monitor"
    echo
else
    echo
    echo "=== ОШИБКА СБОРКИ ==="
    echo "Проверьте логи выше для диагностики проблем"
    exit 1
fi