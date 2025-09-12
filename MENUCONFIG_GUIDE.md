# Руководство по настройке menuconfig для Hydra-L

## 🔧 Запуск menuconfig

```bash
# Простой способ (с автоматической установкой зависимостей)
./menuconfig.sh

# Или напрямую
python3 $IDF_PATH/tools/idf.py menuconfig
```

## 📋 Основные разделы настройки

### 1. Serial flasher config
**Путь:** `Serial flasher config`

Важные настройки:
- **Default serial port** - порт для прошивки (например, `/dev/cu.usbserial-*`)
- **Default baud rate** - скорость прошивки (рекомендуется 460800)
- **Flash size** - размер flash памяти (обычно 4MB для ESP8266)
- **Flash frequency** - частота flash (40MHz для стабильности)

### 2. Partition Table
**Путь:** `Partition Table`

Варианты:
- **Single factory app, no OTA** - простая схема без OTA обновлений
- **Factory app, two OTA definitions** - поддержка OTA обновлений
- **Custom partition table CSV** - пользовательская таблица

### 3. ESP8266-specific настройки
**Путь:** `Component config → ESP8266-specific`

Ключевые параметры:
- **CPU frequency** - частота процессора (80MHz/160MHz)
- **WiFi RX buffer number** - количество буферов WiFi (16 по умолчанию)
- **WiFi TX buffer number** - количество буферов передачи (16)
- **Enable WPA3-Personal** - поддержка WPA3

### 4. FreeRTOS настройки
**Путь:** `Component config → FreeRTOS`

Важные параметры:
- **Tick rate (Hz)** - частота системного таймера (100Hz)
- **Main task stack size** - размер стека главной задачи (3584 bytes)
- **Timer task stack size** - размер стека таймера (2048 bytes)
- **Enable FreeRTOS trace facility** - отладочная информация

### 5. WiFi настройки
**Путь:** `Component config → Wi-Fi`

Настройки:
- **WiFi RX buffer size** - размер буфера приема (1600 bytes)
- **WiFi left continuous RX buffer number** - непрерывные буферы (8)
- **WiFi NVS flash** - сохранение настроек WiFi в NVS

### 6. HTTP Server
**Путь:** `Component config → HTTP Server`

Параметры:
- **Max HTTP Request Header Length** - максимальная длина заголовка (512)
- **Max HTTP URI Length** - максимальная длина URI (512)
- **HTTP Server task stack size** - размер стека сервера (4096)

### 7. LWIP (сетевой стек)
**Путь:** `Component config → LWIP`

Настройки:
- **Max number of open sockets** - максимум сокетов (10)
- **Enable SO_REUSEADDR option** - переиспользование адресов
- **Enable SO_RCVBUF option** - буферы приема

### 8. Log output
**Путь:** `Component config → Log output`

Уровни логирования:
- **Default log verbosity** - уровень по умолчанию (Info)
- **Maximum log verbosity** - максимальный уровень (Verbose)

## 🎯 Рекомендуемые настройки для Hydra-L

### Для стабильной работы:
```
CPU frequency: 80MHz
Flash frequency: 40MHz
WiFi RX buffer number: 16
WiFi TX buffer number: 16
FreeRTOS tick rate: 100Hz
HTTP Server stack size: 4096
Max sockets: 10
Log level: Info
```

### Для экономии памяти:
```
CPU frequency: 80MHz
WiFi RX buffer number: 8
WiFi TX buffer number: 8
HTTP Server stack size: 3072
Max sockets: 5
Log level: Warning
```

### Для высокой производительности:
```
CPU frequency: 160MHz
Flash frequency: 80MHz
WiFi RX buffer number: 32
WiFi TX buffer number: 32
FreeRTOS tick rate: 1000Hz
HTTP Server stack size: 6144
Max sockets: 16
Log level: Error
```

## 🔧 Применение изменений

После изменения настроек в menuconfig:

1. **Сохранение:** Нажмите `S` для сохранения
2. **Выход:** Нажмите `Q` для выхода
3. **Пересборка:** Выполните `./build.sh`
4. **Прошивка:** Выполните прошивку устройства

## ⚠️ Важные замечания

- **Резервная копия:** Сделайте копию `sdkconfig` перед изменениями
- **Тестирование:** Тестируйте изменения на реальном устройстве
- **Память:** Следите за использованием RAM и Flash памяти
- **Совместимость:** Некоторые настройки могут конфликтовать

## 🐛 Устранение проблем

### Menuconfig не запускается:
```bash
# macOS
brew install ncurses flex bison gperf

# Linux (Ubuntu/Debian)
sudo apt install libncurses5-dev flex bison gperf

# Linux (Fedora/CentOS)
sudo dnf install ncurses-devel flex bison gperf
```

### Ошибки после изменения настроек:
```bash
# Очистка и пересборка
rm -rf build/ sdkconfig
cp sdkconfig.defaults sdkconfig
./build.sh
```

### Восстановление настроек по умолчанию:
```bash
# Восстановление из defaults
rm sdkconfig
cp sdkconfig.defaults sdkconfig
```