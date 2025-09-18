# 🚨 Быстрое исправление ошибки cstdint

## Проблема
```
fatal error: cstdint: No such file or directory
 #include <cstdint>
          ^~~~~~~~~
compilation terminated.
```

## Решение

### Автоматическое исправление:
```bash
# Запустите скрипт исправления
./scripts/fix_cstdint_error.sh

# Затем соберите проект
./build.sh
```

### Ручное исправление (если автоматическое не работает):

1. **Найдите проблемный файл:**
```bash
find $IDF_PATH -name "nvs_types.hpp" -type f
```

2. **Откройте файл и замените:**
```bash
# Было:
#include <cstdint>

# Стало:
#include <stdint.h>
```

3. **Очистите build и пересоберите:**
```bash
rm -rf build/
./build.sh
```

## Что делает исправление

- ✅ Заменяет `#include <cstdint>` на `#include <stdint.h>`
- ✅ Создает файл совместимости `nvs_compat.h`
- ✅ Создает резервные копии оригинальных файлов
- ✅ Очищает build директорию для пересборки

## Проверка

После исправления проект должен собираться без ошибок:
```bash
./build.sh
```

Если ошибка повторяется, проверьте:
1. Правильность установки toolchain
2. Версию ESP8266 RTOS SDK
3. Переменные окружения (IDF_PATH)
