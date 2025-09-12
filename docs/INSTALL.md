# 📱 Простая установка прошивки Hydra-L

## Что вам нужно:
- Компьютер с macOS или Linux
- ESP8266 устройство (WeMos D1 Mini или аналог)
- USB кабель для подключения ESP8266

## 🔥 Установка за 5 шагов

### Шаг 1: Откройте терминал
- **macOS**: Нажмите `Cmd + Space`, введите "Terminal", нажмите Enter
- **Linux**: Нажмите `Ctrl + Alt + T`

### Шаг 2: Скачайте проект
Скопируйте и вставьте эту команду в терминал:
```bash
git clone https://github.com/Unk1nd77/hydra-l-esp8266.git && cd hydra-l-esp8266
```

### Шаг 3: Установите все необходимое автоматически
**На macOS:**
```bash
./install_macos.sh
```

**На Linux:**
```bash
./install_linux.sh
```

⏰ *Это займет 5-10 минут. Скрипт установит все необходимые программы.*

### Шаг 4: Активируйте окружение
```bash
source ~/esp/setup_env.sh
```

### Шаг 5: Соберите и прошейте
```bash
# Сборка прошивки (займет 2-3 минуты)
./build.sh

# Подключите ESP8266 к компьютеру через USB

# Найдите порт устройства
ls /dev/cu.*        # macOS
ls /dev/ttyUSB*     # Linux

# Прошейте (замените /dev/cu.usbserial-* на ваш порт)
python3 $IDF_PATH/tools/idf.py -p /dev/cu.usbserial-* flash monitor
```

## ✅ Готово!

После прошивки ваше устройство:
1. **Создаст WiFi сеть "Hydra-L"** (пароль: 12345678)
2. **Будет доступно по адресу**: http://192.168.4.1
3. **Покажет данные сенсоров** на LCD дисплее

## 🆘 Проблемы?

### Команда не найдена
```bash
# Если git не установлен (macOS)
xcode-select --install

# Если git не установлен (Linux)
sudo apt install git  # Ubuntu/Debian
sudo dnf install git  # Fedora
```

### Устройство не найдено
1. Проверьте USB подключение
2. Установите драйверы CH340/CP2102:
   - **macOS**: `brew install --cask wch-ch34x-usb-serial-driver`
   - **Linux**: драйверы обычно уже есть

### Ошибки сборки
```bash
# Исправление проблем совместимости
./fix_sdk_compatibility.sh
```

### Нужна помощь?
- Откройте [Issues на GitHub](https://github.com/Unk1nd77/hydra-l-esp8266/issues)
- Посмотрите подробную документацию в README.md

---

**🎉 Поздравляем! Вы успешно прошили свое IoT устройство!**