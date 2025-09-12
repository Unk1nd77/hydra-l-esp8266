#!/bin/bash

# Универсальный скрипт для сборки проекта Hydra-L
# Поддерживает: macOS, Linux
# Автор: Kiro AI Assistant
# Версия: 2.1

set -e  # Остановка при ошибке

# Цвета для вывода
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Определение операционной системы
if [[ "$OSTYPE" == "darwin"* ]]; then
    OS="macOS"
    SERIAL_PORTS="/dev/cu.*"
elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
    OS="Linux"
    SERIAL_PORTS="/dev/ttyUSB* /dev/ttyACM*"
else
    OS="Unknown"
fi

echo -e "${BLUE}=== Hydra-L Build Script v2.1 ===${NC}"
echo -e "${BLUE}Сборка стабильной версии прошивки для ESP8266${NC}"
echo -e "${BLUE}Операционная система: $OS${NC}"
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

# Попробуем разные способы проверки зависимостей
check_python_deps() {
    python3 -c "import click, cryptography, pyparsing, serial" 2>/dev/null && return 0
    
    # Попробуем активировать виртуальное окружение если оно есть
    if [ -f "$HOME/esp/python_env/bin/activate" ]; then
        source "$HOME/esp/python_env/bin/activate"
        python3 -c "import click, cryptography, pyparsing, serial" 2>/dev/null && return 0
        deactivate 2>/dev/null || true
    fi
    
    return 1
}

if ! check_python_deps; then
    echo -e "${RED}Ошибка: Не все Python зависимости установлены${NC}"
    echo
    if [[ "$OS" == "macOS" ]]; then
        echo "Попробуйте один из способов:"
        echo "1. pip3 install --break-system-packages --user click cryptography pyparsing pyserial"
        echo "2. ./install_macos.sh (автоматическая установка)"
        echo "3. Создать виртуальное окружение:"
        echo "   python3 -m venv ~/esp/python_env"
        echo "   source ~/esp/python_env/bin/activate"
        echo "   pip install click cryptography pyparsing pyserial"
    else
        echo "Выполните: pip3 install --user click cryptography pyparsing pyserial"
        echo "Или запустите: ./install_linux.sh"
    fi
    exit 1
fi

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
    echo -e "${GREEN}=== СБОРКА ЗАВЕРШЕНА УСПЕШНО ===${NC}"
    echo
    echo "Файлы прошивки созданы в директории build/"
    echo "Основной файл: build/hydra_l.bin"
    echo
    echo -e "${YELLOW}Для прошивки выполните:${NC}"
    if [[ "$OS" == "macOS" ]]; then
        echo "python3 \$IDF_PATH/tools/idf.py -p /dev/cu.usbserial-* flash"
        echo
        echo "Найти порт можно командой: ls /dev/cu.*"
    else
        echo "python3 \$IDF_PATH/tools/idf.py -p /dev/ttyUSB0 flash"
        echo
        echo "Найти порт можно командой: ls /dev/ttyUSB* /dev/ttyACM*"
    fi
    echo
    echo -e "${YELLOW}Для мониторинга выполните:${NC}"
    if [[ "$OS" == "macOS" ]]; then
        echo "python3 \$IDF_PATH/tools/idf.py -p /dev/cu.usbserial-* monitor"
    else
        echo "python3 \$IDF_PATH/tools/idf.py -p /dev/ttyUSB0 monitor"
    fi
    echo
else
    echo
    echo -e "${RED}=== ОШИБКА СБОРКИ ===${NC}"
    echo "Проверьте логи выше для диагностики проблем"
    exit 1
fi