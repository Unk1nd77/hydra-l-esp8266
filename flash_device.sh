#!/bin/bash

# Скрипт "все в одном" для прошивки Hydra-L устройства
# Автор: Kiro AI Assistant

set -e

# Цвета для вывода
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}"
echo "╔══════════════════════════════════════════════════════════════╗"
echo "║                    HYDRA-L FLASH TOOL                       ║"
echo "║              Автоматическая прошивка ESP8266                ║"
echo "╚══════════════════════════════════════════════════════════════╝"
echo -e "${NC}"

# Определение операционной системы
if [[ "$OSTYPE" == "darwin"* ]]; then
    OS="macOS"
    SERIAL_PATTERN="/dev/cu.*"
elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
    OS="Linux"
    SERIAL_PATTERN="/dev/ttyUSB* /dev/ttyACM*"
else
    echo -e "${RED}❌ Неподдерживаемая операционная система${NC}"
    exit 1
fi

echo -e "${GREEN}✓ Обнаружена система: $OS${NC}"

# Функция для поиска ESP8266 устройства
find_esp_device() {
    echo -e "${YELLOW}🔍 Поиск ESP8266 устройства...${NC}"
    
    if [[ "$OS" == "macOS" ]]; then
        DEVICES=$(ls /dev/cu.* 2>/dev/null | grep -E "(usbserial|wchusbserial)" | head -1)
    else
        DEVICES=$(ls /dev/ttyUSB* /dev/ttyACM* 2>/dev/null | head -1)
    fi
    
    if [ -z "$DEVICES" ]; then
        echo -e "${RED}❌ ESP8266 устройство не найдено!${NC}"
        echo
        echo "Проверьте:"
        echo "1. USB кабель подключен"
        echo "2. Драйверы CH340/CP2102 установлены"
        echo "3. Устройство включено"
        echo
        if [[ "$OS" == "macOS" ]]; then
            echo "Доступные порты:"
            ls /dev/cu.* 2>/dev/null || echo "Нет доступных портов"
        else
            echo "Доступные порты:"
            ls /dev/ttyUSB* /dev/ttyACM* 2>/dev/null || echo "Нет доступных портов"
        fi
        exit 1
    fi
    
    echo -e "${GREEN}✓ Найдено устройство: $DEVICES${NC}"
    ESP_PORT="$DEVICES"
}

# Проверка окружения
check_environment() {
    echo -e "${YELLOW}🔧 Проверка окружения разработки...${NC}"
    
    if [ -z "$IDF_PATH" ]; then
        echo -e "${YELLOW}⚠ Окружение не активировано. Активируем...${NC}"
        if [ -f "$HOME/esp/setup_env.sh" ]; then
            source "$HOME/esp/setup_env.sh"
        else
            echo -e "${RED}❌ Окружение не установлено!${NC}"
            echo "Сначала выполните:"
            if [[ "$OS" == "macOS" ]]; then
                echo "./install_macos.sh"
            else
                echo "./install_linux.sh"
            fi
            exit 1
        fi
    fi
    
    if ! command -v xtensa-lx106-elf-gcc &> /dev/null; then
        echo -e "${RED}❌ ESP8266 toolchain не найден!${NC}"
        echo "Выполните установку окружения"
        exit 1
    fi
    
    echo -e "${GREEN}✓ Окружение готово${NC}"
}

# Сборка проекта
build_project() {
    echo -e "${YELLOW}🔨 Сборка прошивки...${NC}"
    
    if [ ! -f "./build.sh" ]; then
        echo -e "${RED}❌ Скрипт сборки не найден!${NC}"
        echo "Убедитесь, что вы находитесь в директории проекта"
        exit 1
    fi
    
    ./build.sh
    
    if [ ! -f "build/hydra_l.bin" ]; then
        echo -e "${RED}❌ Сборка не удалась!${NC}"
        exit 1
    fi
    
    echo -e "${GREEN}✓ Прошивка собрана успешно${NC}"
}

# Прошивка устройства
flash_device() {
    echo -e "${YELLOW}📱 Прошивка устройства...${NC}"
    echo "Порт: $ESP_PORT"
    echo
    
    python3 $IDF_PATH/tools/idf.py -p "$ESP_PORT" flash
    
    if [ $? -eq 0 ]; then
        echo
        echo -e "${GREEN}🎉 ПРОШИВКА ЗАВЕРШЕНА УСПЕШНО! 🎉${NC}"
        echo
        echo "Ваше устройство готово к работе:"
        echo "• WiFi сеть: Hydra-L (пароль: 12345678)"
        echo "• Веб-интерфейс: http://192.168.4.1"
        echo "• API данных: http://192.168.4.1/getData"
        echo
        
        read -p "Запустить мониторинг Serial порта? (y/N): " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            echo -e "${BLUE}Запуск мониторинга (Ctrl+] для выхода)...${NC}"
            python3 $IDF_PATH/tools/idf.py -p "$ESP_PORT" monitor
        fi
    else
        echo -e "${RED}❌ Ошибка прошивки!${NC}"
        exit 1
    fi
}

# Основная логика
main() {
    echo "Этот скрипт автоматически:"
    echo "1. Найдет ваше ESP8266 устройство"
    echo "2. Соберет прошивку"
    echo "3. Прошьет устройство"
    echo
    read -p "Продолжить? (Y/n): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Nn]$ ]]; then
        echo "Отменено пользователем"
        exit 0
    fi
    
    find_esp_device
    check_environment
    build_project
    flash_device
}

# Проверка, что скрипт запущен из правильной директории
if [ ! -f "main/main.c" ] || [ ! -f "CMakeLists.txt" ]; then
    echo -e "${RED}❌ Запустите скрипт из директории проекта hydra-l-esp8266${NC}"
    exit 1
fi

# Запуск основной функции
main