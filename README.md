# Hydra-L ESP8266 Firmware v2.0

Стабильная версия прошивки для ESP8266 с поддержкой BME280 и LCD дисплея.

## Особенности

- ✅ Исправлены все конфликты определений FreeRTOS
- ✅ Убраны неиспользуемые функции и переменные
- ✅ Стабильная работа на Linux без костылей
- ✅ Поддержка BME280 (температура, влажность, давление)
- ✅ Поддержка LCD 1602 с I2C
- ✅ WiFi в режиме STA+AP
- ✅ Веб-сервер с REST API
- ✅ Отправка данных на удаленный сервер
- ✅ Обработка кнопок с debounce
- ✅ Усреднение показаний сенсоров

## Требования

### Система
- Linux (Ubuntu, Fedora, Debian и др.)
- Python 3.6+
- Git

### ESP8266 RTOS SDK
```bash
# Клонирование SDK
git clone --recursive https://github.com/espressif/ESP8266_RTOS_SDK.git
cd ESP8266_RTOS_SDK
git checkout v3.4
git submodule update --init --recursive

# Установка переменной окружения
export IDF_PATH=$PWD
```

### Toolchain
```bash
# Скачивание и установка toolchain
wget https://dl.espressif.com/dl/xtensa-lx106-elf-gcc8_4_0-esp-2020r3-linux-amd64.tar.gz
tar -xzf xtensa-lx106-elf-gcc8_4_0-esp-2020r3-linux-amd64.tar.gz
export PATH=$PWD/xtensa-lx106-elf/bin:$PATH
```

### Python зависимости
```bash
pip3 install click cryptography pyparsing pyserial
```

## Сборка

1. **Настройка окружения:**
```bash
export IDF_PATH=/path/to/ESP8266_RTOS_SDK
export PATH=/path/to/xtensa-lx106-elf/bin:$PATH
```

2. **Сборка проекта:**
```bash
cd my_project_fixed
./build.sh
```

3. **Прошивка:**
```bash
python3 $IDF_PATH/tools/idf.py -p /dev/ttyUSB0 flash
```

4. **Мониторинг:**
```bash
python3 $IDF_PATH/tools/idf.py -p /dev/ttyUSB0 monitor
```

## Конфигурация

### WiFi настройки
Измените в `main/main.c`:
```c
#define WIFI_SSID      "your_ssid"
#define WIFI_PASS      "your_password"
```

### I2C пины (WeMos D1 Mini)
```c
#define I2C_MASTER_SCL_IO           2    // D4
#define I2C_MASTER_SDA_IO           14   // D5
```

### Кнопки
```c
#define BUTTON_1_GPIO     12  // D6
#define BUTTON_2_GPIO     13  // D7
```

## API Endpoints

- `GET /getData` - Получение данных сенсоров
- `POST /setMode` - Установка режима LCD (0-2)
- `POST /setLCD` - Установка текста LCD
- `POST /setLED` - Управление подсветкой LCD

## Режимы LCD

- **Режим 0**: Показания сенсоров
- **Режим 1**: Пользовательский текст
- **Режим 2**: IP адрес устройства

## Устранение проблем

### Ошибки сборки
1. Проверьте переменные окружения `IDF_PATH` и `PATH`
2. Убедитесь, что установлены все зависимости
3. Проверьте версию ESP8266_RTOS_SDK (должна быть v3.4)

### Ошибки прошивки
1. Проверьте подключение ESP8266
2. Убедитесь в правильности порта (`/dev/ttyUSB0`)
3. Попробуйте другую скорость: `--baud 115200`

### Проблемы с WiFi
1. Проверьте правильность SSID и пароля
2. Убедитесь, что сеть работает на 2.4GHz
3. Проверьте логи через монитор

## Структура проекта

```
my_project_fixed/
├── main/
│   └── main.c              # Основной код
├── components/
│   ├── bme280/             # Драйвер BME280
│   │   ├── bme280.c
│   │   ├── include/bme280.h
│   │   └── CMakeLists.txt
│   └── lcd/                # Драйвер LCD
│       ├── lcd.c
│       ├── include/lcd.h
│       └── CMakeLists.txt
├── CMakeLists.txt          # Конфигурация сборки
├── sdkconfig.defaults      # Настройки по умолчанию
├── build.sh               # Скрипт сборки
└── README.md              # Документация
```

## Лицензия

MIT License

## Поддержка

Для получения поддержки создайте issue в репозитории проекта.