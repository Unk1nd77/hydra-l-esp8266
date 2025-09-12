#!/bin/bash

# Скрипт тестирования сборки Hydra-L v2.0
# Автор: Kiro AI Assistant

set -e

echo "=== Hydra-L v2.0 Build Test ==="
echo "Тестирование стабильной сборки на Linux"
echo

# Цвета для вывода
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Функция для вывода статуса
print_status() {
    if [ $1 -eq 0 ]; then
        echo -e "${GREEN}✓ $2${NC}"
    else
        echo -e "${RED}✗ $2${NC}"
        exit 1
    fi
}

print_warning() {
    echo -e "${YELLOW}⚠ $1${NC}"
}

print_info() {
    echo -e "ℹ $1"
}

# Проверка окружения
print_info "Проверка окружения разработки..."

# Проверка IDF_PATH
if [ -z "$IDF_PATH" ]; then
    print_warning "IDF_PATH не установлен"
    if [ -d "../ESP8266_RTOS_SDK" ]; then
        export IDF_PATH="$(realpath ../ESP8266_RTOS_SDK)"
        print_info "Автоматически установлен IDF_PATH: $IDF_PATH"
    else
        echo -e "${RED}Ошибка: ESP8266_RTOS_SDK не найден${NC}"
        echo "Выполните: ./install_linux.sh"
        exit 1
    fi
fi

print_status 0 "IDF_PATH: $IDF_PATH"

# Проверка toolchain
if command -v xtensa-lx106-elf-gcc &> /dev/null; then
    TOOLCHAIN_VERSION=$(xtensa-lx106-elf-gcc --version | head -n1)
    print_status 0 "Toolchain: $TOOLCHAIN_VERSION"
else
    print_status 1 "Toolchain не найден"
fi

# Проверка Python зависимостей
print_info "Проверка Python зависимостей..."
python3 -c "import click, cryptography, pyparsing, pyserial" 2>/dev/null
print_status $? "Python зависимости"

# Проверка структуры проекта
print_info "Проверка структуры проекта..."

check_file() {
    if [ -f "$1" ]; then
        print_status 0 "Файл: $1"
    else
        print_status 1 "Файл отсутствует: $1"
    fi
}

check_file "main/main.c"
check_file "components/bme280/bme280.c"
check_file "components/lcd/lcd.c"
check_file "CMakeLists.txt"
check_file "sdkconfig.defaults"

# Проверка синтаксиса C кода
print_info "Проверка синтаксиса C кода..."

check_syntax() {
    xtensa-lx106-elf-gcc -fsyntax-only -I$IDF_PATH/components/freertos/include \
        -I$IDF_PATH/components/esp8266/include \
        -I$IDF_PATH/components/driver/include \
        -I$IDF_PATH/components/log/include \
        -I$IDF_PATH/components/esp_common/include \
        -I./components/bme280/include \
        -I./components/lcd/include \
        "$1" 2>/dev/null
    return $?
}

check_syntax "components/bme280/bme280.c"
print_status $? "Синтаксис BME280"

check_syntax "components/lcd/lcd.c"
print_status $? "Синтаксис LCD"

# Тестовая сборка
print_info "Запуск тестовой сборки..."

# Очистка предыдущей сборки
rm -rf build/
rm -f sdkconfig

# Копирование конфигурации
if [ -f "sdkconfig.defaults" ]; then
    cp sdkconfig.defaults sdkconfig
fi

# Сборка
echo "Выполняется сборка (это может занять несколько минут)..."
python3 $IDF_PATH/tools/idf.py build > build.log 2>&1
BUILD_RESULT=$?

if [ $BUILD_RESULT -eq 0 ]; then
    print_status 0 "Сборка проекта"
    
    # Проверка размера прошивки
    if [ -f "build/hydra_l.bin" ]; then
        SIZE=$(stat -c%s "build/hydra_l.bin")
        SIZE_KB=$((SIZE / 1024))
        print_info "Размер прошивки: ${SIZE_KB} KB"
        
        if [ $SIZE_KB -lt 1024 ]; then
            print_status 0 "Размер прошивки в норме"
        else
            print_warning "Прошивка больше 1MB"
        fi
    fi
    
    # Проверка наличия всех файлов
    check_file "build/hydra_l.bin"
    check_file "build/bootloader/bootloader.bin"
    check_file "build/partition_table/partition-table.bin"
    
else
    print_status 1 "Сборка проекта"
    echo "Лог ошибок:"
    tail -20 build.log
    exit 1
fi

# Анализ использования памяти
print_info "Анализ использования памяти..."
if [ -f "build/hydra_l.map" ]; then
    python3 $IDF_PATH/tools/idf.py size > size.log 2>&1
    if [ $? -eq 0 ]; then
        print_status 0 "Анализ памяти"
        echo "Использование памяти:"
        cat size.log | grep -E "(DRAM|IRAM|Flash)"
    fi
fi

# Финальный отчет
echo
echo "=== РЕЗУЛЬТАТ ТЕСТИРОВАНИЯ ==="
echo
print_status 0 "Все тесты пройдены успешно!"
echo
echo "Файлы прошивки готовы:"
echo "  • build/hydra_l.bin - основная прошивка"
echo "  • build/bootloader/bootloader.bin - загрузчик"
echo "  • build/partition_table/partition-table.bin - таблица разделов"
echo
echo "Для прошивки выполните:"
echo "  python3 \$IDF_PATH/tools/idf.py -p /dev/ttyUSB0 flash"
echo
echo "Для мониторинга выполните:"
echo "  python3 \$IDF_PATH/tools/idf.py -p /dev/ttyUSB0 monitor"
echo
print_status 0 "Проект готов к использованию!"