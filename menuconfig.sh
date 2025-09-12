#!/bin/bash

# Скрипт для запуска menuconfig с проверкой зависимостей
# Автор: Kiro AI Assistant

set -e

# Цвета для вывода
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Определение операционной системы
if [[ "$OSTYPE" == "darwin"* ]]; then
    OS="macOS"
elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
    OS="Linux"
else
    OS="Unknown"
fi

echo -e "${BLUE}=== Hydra-L Menuconfig v1.0 ===${NC}"
echo -e "${BLUE}Настройка конфигурации ESP8266 проекта${NC}"
echo -e "${BLUE}Операционная система: $OS${NC}"
echo

# Проверка переменных окружения
if [ -z "$IDF_PATH" ]; then
    echo -e "${RED}Ошибка: Переменная IDF_PATH не установлена${NC}"
    echo "Пожалуйста, выполните: source ~/esp/setup_env.sh"
    exit 1
fi

# Проверка ncurses на macOS
if [[ "$OS" == "macOS" ]]; then
    if ! brew list ncurses &>/dev/null; then
        echo -e "${YELLOW}Установка ncurses для menuconfig...${NC}"
        brew install ncurses flex bison gperf
    fi
    
    # Установка переменных окружения для ncurses на macOS
    export LDFLAGS="-L$(brew --prefix ncurses)/lib"
    export CPPFLAGS="-I$(brew --prefix ncurses)/include"
    export PKG_CONFIG_PATH="$(brew --prefix ncurses)/lib/pkgconfig"
fi

# Проверка ncurses на Linux
if [[ "$OS" == "Linux" ]]; then
    if ! dpkg -l | grep -q libncurses5-dev 2>/dev/null && ! rpm -q ncurses-devel 2>/dev/null; then
        echo -e "${YELLOW}Для menuconfig требуются ncurses библиотеки${NC}"
        echo "Установите их:"
        echo "Ubuntu/Debian: sudo apt install libncurses5-dev"
        echo "Fedora/CentOS: sudo dnf install ncurses-devel"
        echo "Arch Linux: sudo pacman -S ncurses"
        exit 1
    fi
fi

# Проверка, что проект собран
if [ ! -d "build" ]; then
    echo -e "${YELLOW}Проект не собран. Запускаем сборку...${NC}"
    ./build.sh
fi

echo -e "${GREEN}Запуск menuconfig...${NC}"
echo "Используйте стрелки для навигации, Enter для входа в меню, Esc для выхода"
echo "Нажмите любую клавишу для продолжения..."
read -n 1 -s

# Запуск menuconfig
python3 $IDF_PATH/tools/idf.py menuconfig

if [ $? -eq 0 ]; then
    echo
    echo -e "${GREEN}=== MENUCONFIG ЗАВЕРШЕН УСПЕШНО ===${NC}"
    echo
    echo "Конфигурация сохранена в файл sdkconfig"
    echo
    echo "Для применения изменений выполните:"
    echo -e "${BLUE}./build.sh${NC}"
    echo
    echo "Основные разделы конфигурации:"
    echo "• Serial flasher config - настройки прошивки"
    echo "• Partition Table - таблица разделов"
    echo "• Component config → ESP8266-specific - настройки ESP8266"
    echo "• Component config → FreeRTOS - настройки RTOS"
    echo "• Component config → Wi-Fi - настройки WiFi"
    echo "• Component config → HTTP Server - настройки веб-сервера"
else
    echo
    echo -e "${RED}=== ОШИБКА MENUCONFIG ===${NC}"
    echo "Проверьте установку ncurses библиотек"
    exit 1
fi