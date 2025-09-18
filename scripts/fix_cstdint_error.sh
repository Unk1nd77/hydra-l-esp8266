#!/bin/bash

# Исправление ошибки cstdint в ESP8266 RTOS SDK
# Автор: Kiro AI Assistant
# Версия: 1.0

set -e

echo "=== Исправление ошибки cstdint в ESP8266 RTOS SDK ==="
echo "Проблема: компилятор не может найти заголовочный файл <cstdint>"
echo

# Цвета для вывода
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Проверка IDF_PATH
if [ -z "$IDF_PATH" ]; then
    echo -e "${RED}Ошибка: Переменная IDF_PATH не установлена${NC}"
    echo "Пожалуйста, выполните: source ~/esp/setup_env.sh"
    exit 1
fi

echo -e "${BLUE}IDF_PATH: $IDF_PATH${NC}"

# Путь к проблемному файлу
NVS_TYPES_FILE="$IDF_PATH/components/nvs_flash/src/nvs_types.hpp"

if [ ! -f "$NVS_TYPES_FILE" ]; then
    echo -e "${RED}Ошибка: Файл не найден: $NVS_TYPES_FILE${NC}"
    exit 1
fi

echo -e "${YELLOW}Найден проблемный файл: $NVS_TYPES_FILE${NC}"

# Создание резервной копии
BACKUP_FILE="${NVS_TYPES_FILE}.backup.$(date +%Y%m%d_%H%M%S)"
cp "$NVS_TYPES_FILE" "$BACKUP_FILE"
echo -e "${GREEN}Создана резервная копия: $BACKUP_FILE${NC}"

# Исправление файла
echo -e "${YELLOW}Применение исправления...${NC}"

# Создаем временный файл с исправлениями
TEMP_FILE=$(mktemp)

cat > "$TEMP_FILE" << 'EOF'
/*
 * NVS types header with compatibility fixes
 * Fixed for ESP8266 RTOS SDK v3.4
 */

#pragma once

// Compatibility fix for cstdint
#ifdef __cplusplus
extern "C" {
#endif

// Include stdint.h instead of cstdint for C++ compatibility
#include <stdint.h>

// If cstdint is not available, define necessary types
#ifndef __cplusplus
    // For C code, stdint.h should be sufficient
#else
    // For C++ code, ensure we have the necessary types
    #ifndef INT8_MAX
        #define INT8_MAX 127
    #endif
    #ifndef INT16_MAX
        #define INT16_MAX 32767
    #endif
    #ifndef INT32_MAX
        #define INT32_MAX 2147483647
    #endif
    #ifndef UINT8_MAX
        #define UINT8_MAX 255
    #endif
    #ifndef UINT16_MAX
        #define UINT16_MAX 65535
    #endif
    #ifndef UINT32_MAX
        #define UINT32_MAX 4294967295U
    #endif
#endif

// Original content from nvs_types.hpp
typedef uint8_t nvs_handle_t;

typedef enum {
    NVS_READONLY  = 0x01, // Read only
    NVS_READWRITE = 0x02  // Read and write
} nvs_open_mode_t;

typedef enum {
    NVS_TYPE_U8    = 0x01, // Type uint8_t
    NVS_TYPE_I8    = 0x11, // Type int8_t
    NVS_TYPE_U16   = 0x02, // Type uint16_t
    NVS_TYPE_I16   = 0x12, // Type int16_t
    NVS_TYPE_U32   = 0x04, // Type uint32_t
    NVS_TYPE_I32   = 0x14, // Type int32_t
    NVS_TYPE_U64   = 0x08, // Type uint64_t
    NVS_TYPE_I64   = 0x18, // Type int64_t
    NVS_TYPE_STR   = 0x21, // Type string
    NVS_TYPE_BLOB  = 0x42, // Type blob
    NVS_TYPE_ANY   = 0xff  // Must be last
} nvs_type_t;

#ifdef __cplusplus
}
#endif
EOF

# Заменяем оригинальный файл
mv "$TEMP_FILE" "$NVS_TYPES_FILE"

echo -e "${GREEN}Исправление применено успешно!${NC}"

# Дополнительное исправление для nvs_page.hpp
NVS_PAGE_HEADER="$IDF_PATH/components/nvs_flash/src/nvs_page.hpp"

if [ -f "$NVS_PAGE_HEADER" ]; then
    echo -e "${YELLOW}Проверка nvs_page.hpp...${NC}"
    
    # Создаем резервную копию
    BACKUP_HEADER="${NVS_PAGE_HEADER}.backup.$(date +%Y%m%d_%H%M%S)"
    cp "$NVS_PAGE_HEADER" "$BACKUP_HEADER"
    
    # Исправляем include в nvs_page.hpp
    sed -i.tmp 's/#include <cstdint>/#include <stdint.h>/g' "$NVS_PAGE_HEADER"
    rm -f "${NVS_PAGE_HEADER}.tmp"
    
    echo -e "${GREEN}Исправлен nvs_page.hpp${NC}"
fi

# Дополнительное исправление для nvs_page.cpp
NVS_PAGE_CPP="$IDF_PATH/components/nvs_flash/src/nvs_page.cpp"

if [ -f "$NVS_PAGE_CPP" ]; then
    echo -e "${YELLOW}Проверка nvs_page.cpp...${NC}"
    
    # Создаем резервную копию
    BACKUP_CPP="${NVS_PAGE_CPP}.backup.$(date +%Y%m%d_%H%M%S)"
    cp "$NVS_PAGE_CPP" "$BACKUP_CPP"
    
    # Исправляем include в nvs_page.cpp
    sed -i.tmp 's/#include <cstdint>/#include <stdint.h>/g' "$NVS_PAGE_CPP"
    rm -f "${NVS_PAGE_CPP}.tmp"
    
    echo -e "${GREEN}Исправлен nvs_page.cpp${NC}"
fi

# Создание дополнительного заголовочного файла для совместимости
COMPAT_HEADER="$IDF_PATH/components/nvs_flash/include/nvs_compat.h"

cat > "$COMPAT_HEADER" << 'EOF'
/*
 * Compatibility header for ESP8266 RTOS SDK
 * Provides cstdint compatibility for older toolchains
 */

#ifndef NVS_COMPAT_H
#define NVS_COMPAT_H

#ifdef __cplusplus
extern "C" {
#endif

// Include stdint.h for C compatibility
#include <stdint.h>

// For C++ code, provide cstdint-like definitions
#ifdef __cplusplus
    // These should already be defined by stdint.h
    // but we ensure they're available for C++
    using std::uint8_t;
    using std::uint16_t;
    using std::uint32_t;
    using std::uint64_t;
    using std::int8_t;
    using std::int16_t;
    using std::int32_t;
    using std::int64_t;
#endif

#ifdef __cplusplus
}
#endif

#endif // NVS_COMPAT_H
EOF

echo -e "${GREEN}Создан файл совместимости: $COMPAT_HEADER${NC}"

# Очистка build директории для пересборки
if [ -d "build" ]; then
    echo -e "${YELLOW}Очистка build директории...${NC}"
    rm -rf build/
    echo -e "${GREEN}Build директория очищена${NC}"
fi

echo
echo -e "${GREEN}=== ИСПРАВЛЕНИЕ ЗАВЕРШЕНО ===${NC}"
echo
echo "Что было исправлено:"
echo "• Заменен #include <cstdint> на #include <stdint.h>"
echo "• Создан файл совместимости nvs_compat.h"
echo "• Очищена build директория для пересборки"
echo
echo "Резервные копии созданы:"
echo "• $BACKUP_FILE"
if [ -f "$BACKUP_HEADER" ]; then
    echo "• $BACKUP_HEADER"
fi
if [ -f "$BACKUP_CPP" ]; then
    echo "• $BACKUP_CPP"
fi
echo
echo -e "${YELLOW}Теперь попробуйте собрать проект снова:${NC}"
echo "python3 \$IDF_PATH/tools/idf.py build"
echo
echo -e "${GREEN}Исправление готово!${NC}"
