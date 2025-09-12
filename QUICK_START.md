# Hydra-L ESP8266 - Быстрый старт

## 🚀 Установка и запуск за 5 минут

### 1. Клонирование проекта
```bash
git clone https://github.com/Unk1nd77/hydra-l-esp8266.git
cd hydra-l-esp8266
```

### 2. Автоматическая установка окружения
```bash
# macOS
./install_macos.sh

# Linux
./install_linux.sh
```

### 3. Активация окружения
```bash
source ~/esp/setup_env.sh
```

### 4. Сборка проекта
```bash
./build.sh
```

### 5. Прошивка устройства
```bash
# Найти порт устройства
ls /dev/cu.*        # macOS
ls /dev/ttyUSB*     # Linux

# Прошивка
python3 $IDF_PATH/tools/idf.py -p /dev/cu.usbserial-* flash monitor
```

## ⚙️ Дополнительные возможности

### Настройка проекта
```bash
./menuconfig.sh     # Интерактивная настройка
```

### Тестирование
```bash
./test_build.sh     # Проверка окружения
```

### Очистка
```bash
rm -rf build/ sdkconfig
```

## 🔧 Основные команды

| Команда | Описание |
|---------|----------|
| `./build.sh` | Сборка проекта |
| `./menuconfig.sh` | Настройка параметров |
| `./test_build.sh` | Тестирование окружения |
| `idf.py flash` | Прошивка устройства |
| `idf.py monitor` | Мониторинг Serial порта |
| `idf.py flash monitor` | Прошивка + мониторинг |

## 📱 После прошивки

1. **Устройство создаст WiFi точку доступа "Hydra-L"**
2. **Пароль: 12345678**
3. **Веб-интерфейс: http://192.168.4.1**
4. **API для данных: http://192.168.4.1/getData**

## 🐛 Проблемы?

- **Ошибки сборки:** `./fix_sdk_compatibility.sh`
- **Menuconfig не работает:** Установите ncurses
- **Порт не найден:** Проверьте подключение USB
- **Подробная помощь:** См. README.md и MENUCONFIG_GUIDE.md