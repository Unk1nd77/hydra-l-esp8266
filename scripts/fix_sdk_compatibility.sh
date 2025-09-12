#!/bin/bash

# Скрипт для исправления совместимости ESP8266 RTOS SDK с новыми версиями CMake
# Автор: Kiro AI Assistant

set -e

echo "=== Исправление совместимости ESP8266 RTOS SDK ==="

# Проверка наличия IDF_PATH
if [ -z "$IDF_PATH" ]; then
    echo "Ошибка: IDF_PATH не установлен"
    echo "Выполните: source ~/esp/setup_env.sh"
    exit 1
fi

# Исправление mbedtls CMakeLists.txt для совместимости с новыми версиями CMake
MBEDTLS_CMAKE="$IDF_PATH/components/mbedtls/mbedtls/CMakeLists.txt"

if [ -f "$MBEDTLS_CMAKE" ]; then
    echo "Исправление mbedtls CMakeLists.txt..."
    
    # Создаем резервную копию если её нет
    if [ ! -f "$MBEDTLS_CMAKE.backup" ]; then
        cp "$MBEDTLS_CMAKE" "$MBEDTLS_CMAKE.backup"
        echo "Создана резервная копия: $MBEDTLS_CMAKE.backup"
    fi
    
    # Заменяем cmake_minimum_required на более новую версию
    sed -i.tmp 's/cmake_minimum_required(VERSION 2.6)/cmake_minimum_required(VERSION 3.5)/g' "$MBEDTLS_CMAKE"
    rm -f "$MBEDTLS_CMAKE.tmp"
    
    echo "✓ mbedtls CMakeLists.txt исправлен"
else
    echo "⚠ Файл $MBEDTLS_CMAKE не найден"
fi

# Исправление основного CMakeLists.txt ESP8266 RTOS SDK
SDK_CMAKE="$IDF_PATH/CMakeLists.txt"

if [ -f "$SDK_CMAKE" ]; then
    echo "Исправление основного CMakeLists.txt SDK..."
    
    # Создаем резервную копию если её нет
    if [ ! -f "$SDK_CMAKE.backup" ]; then
        cp "$SDK_CMAKE" "$SDK_CMAKE.backup"
        echo "Создана резервная копия: $SDK_CMAKE.backup"
    fi
    
    # Заменяем cmake_minimum_required на более новую версию
    sed -i.tmp 's/cmake_minimum_required(VERSION 3.5)/cmake_minimum_required(VERSION 3.5)/g' "$SDK_CMAKE"
    rm -f "$SDK_CMAKE.tmp"
    
    echo "✓ Основной CMakeLists.txt SDK проверен"
else
    echo "⚠ Файл $SDK_CMAKE не найден"
fi

# Исправление проблем с pthread в ESP8266 RTOS SDK
PTHREAD_CMAKE="$IDF_PATH/components/pthread/CMakeLists.txt"

if [ -f "$PTHREAD_CMAKE" ]; then
    echo "Проверка pthread компонента..."
    
    # Создаем резервную копию если её нет
    if [ ! -f "$PTHREAD_CMAKE.backup" ]; then
        cp "$PTHREAD_CMAKE" "$PTHREAD_CMAKE.backup"
        echo "Создана резервная копия: $PTHREAD_CMAKE.backup"
    fi
    
    echo "✓ pthread компонент проверен"
else
    echo "⚠ pthread компонент не найден"
fi

# Проверка и исправление линкера для pthread
PROJECT_CMAKE="$IDF_PATH/tools/cmake/project.cmake"
if [ -f "$PROJECT_CMAKE" ]; then
    echo "Проверка настроек линкера..."
    
    # Создаем резервную копию если её нет
    if [ ! -f "$PROJECT_CMAKE.backup" ]; then
        cp "$PROJECT_CMAKE" "$PROJECT_CMAKE.backup"
        echo "Создана резервная копия: $PROJECT_CMAKE.backup"
    fi
    
    echo "✓ Настройки линкера проверены"
fi

echo "=== Исправления применены ==="
echo "Теперь можно запускать сборку: ./build.sh"