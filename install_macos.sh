#!/bin/bash

# Скрипт установки окружения для разработки ESP8266 на macOS
# Автор: Kiro AI Assistant
# Версия: 1.0

set -e

echo "=== ESP8266 Development Environment Setup for macOS ==="
echo "Установка окружения для разработки ESP8266 на macOS"
echo

# Цвета для вывода
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

print_status() {
    if [ $1 -eq 0 ]; then
        echo -e "${GREEN}✓ $2${NC}"
    else
        echo -e "${RED}✗ $2${NC}"
        exit 1
    fi
}

print_info() {
    echo -e "${BLUE}ℹ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠ $1${NC}"
}

# Проверка macOS
if [[ "$OSTYPE" != "darwin"* ]]; then
    echo -e "${RED}Ошибка: Этот скрипт предназначен для macOS${NC}"
    exit 1
fi

print_info "Обнаружена система: macOS $(sw_vers -productVersion)"

# Проверка и установка Homebrew
print_info "Проверка Homebrew..."
if ! command -v brew &> /dev/null; then
    print_warning "Homebrew не установлен. Устанавливаем..."
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    
    # Добавление Homebrew в PATH для Apple Silicon
    if [[ $(uname -m) == "arm64" ]]; then
        echo 'eval "$(/opt/homebrew/bin/brew shellenv)"' >> ~/.zshrc
        eval "$(/opt/homebrew/bin/brew shellenv)"
    fi
else
    print_status 0 "Homebrew установлен"
fi

# Обновление Homebrew
print_info "Обновление Homebrew..."
brew update

# Установка системных зависимостей
print_info "Установка системных зависимостей..."
brew install git wget python3 cmake ninja

# Проверка Python
print_info "Проверка Python..."
if command -v python3 &> /dev/null; then
    PYTHON_VERSION=$(python3 --version | cut -d' ' -f2)
    print_status 0 "Python $PYTHON_VERSION установлен"
else
    print_status 1 "Python3 не найден"
fi

# Создание рабочей директории
WORK_DIR="$HOME/esp"
print_info "Создание рабочей директории: $WORK_DIR"
mkdir -p $WORK_DIR
cd $WORK_DIR

# Скачивание ESP8266 RTOS SDK
if [ ! -d "ESP8266_RTOS_SDK" ]; then
    print_info "Скачивание ESP8266 RTOS SDK..."
    git clone --recursive https://github.com/espressif/ESP8266_RTOS_SDK.git
    cd ESP8266_RTOS_SDK
    git checkout v3.4
    git submodule update --init --recursive
    cd ..
    print_status 0 "ESP8266 RTOS SDK установлен"
else
    print_status 0 "ESP8266 RTOS SDK уже установлен"
fi

# Скачивание toolchain
TOOLCHAIN_DIR="xtensa-lx106-elf"
if [ ! -d "$TOOLCHAIN_DIR" ]; then
    print_info "Скачивание ESP8266 toolchain..."
    
    # Определение архитектуры Mac
    ARCH=$(uname -m)
    case $ARCH in
        x86_64)
            TOOLCHAIN_URL="https://dl.espressif.com/dl/xtensa-lx106-elf-gcc8_4_0-esp-2020r3-macos.tar.gz"
            ;;
        arm64)
            # Для Apple Silicon используем x86_64 версию с Rosetta
            TOOLCHAIN_URL="https://dl.espressif.com/dl/xtensa-lx106-elf-gcc8_4_0-esp-2020r3-macos.tar.gz"
            print_warning "Используется x86_64 toolchain с Rosetta для Apple Silicon"
            ;;
        *)
            echo -e "${RED}Неподдерживаемая архитектура: $ARCH${NC}"
            exit 1
            ;;
    esac
    
    wget $TOOLCHAIN_URL -O toolchain.tar.gz
    tar -xzf toolchain.tar.gz
    rm toolchain.tar.gz
    print_status 0 "ESP8266 toolchain установлен"
else
    print_status 0 "ESP8266 toolchain уже установлен"
fi

# Установка Python зависимостей
print_info "Установка Python зависимостей..."

# Проверка, нужно ли использовать --break-system-packages
if pip3 install --user -r $IDF_PATH/requirements.txt 2>/dev/null; then
    print_status 0 "Python зависимости установлены через --user"
elif pip3 install --break-system-packages --user -r $IDF_PATH/requirements.txt 2>/dev/null; then
    print_status 0 "Python зависимости установлены с --break-system-packages"
else
    print_warning "Не удалось установить через pip, пробуем через Homebrew..."
    brew install python-cryptography || true
    
    # Создаем виртуальное окружение как fallback
    print_info "Создание виртуального окружения для Python зависимостей..."
    python3 -m venv ~/esp/python_env
    source ~/esp/python_env/bin/activate
    pip install -r $IDF_PATH/requirements.txt
    deactivate
    
    print_warning "Python зависимости установлены в виртуальное окружение"
    print_warning "Для активации используйте: source ~/esp/python_env/bin/activate"
fi

# Создание скрипта активации окружения
SETUP_SCRIPT="$WORK_DIR/setup_env.sh"
print_info "Создание скрипта активации окружения: $SETUP_SCRIPT"

cat > $SETUP_SCRIPT << 'EOF'
#!/bin/bash
# ESP8266 Development Environment Setup for macOS

export IDF_PATH="$HOME/esp/ESP8266_RTOS_SDK"
export PATH="$HOME/esp/xtensa-lx106-elf/bin:$PATH"

echo "ESP8266 development environment activated (macOS)"
echo "IDF_PATH: $IDF_PATH"
echo "Toolchain: $(xtensa-lx106-elf-gcc --version 2>/dev/null | head -n1 || echo 'Not found')"
EOF

chmod +x $SETUP_SCRIPT

# Добавление в .zshrc (macOS использует zsh по умолчанию)
SHELL_RC="$HOME/.zshrc"
BASHRC_LINE="source $SETUP_SCRIPT"

if ! grep -q "$BASHRC_LINE" $SHELL_RC 2>/dev/null; then
    print_info "Добавление в $SHELL_RC..."
    echo "" >> $SHELL_RC
    echo "# ESP8266 Development Environment" >> $SHELL_RC
    echo "$BASHRC_LINE" >> $SHELL_RC
fi

# Проверка установки
print_info "Проверка установки..."
source $SETUP_SCRIPT

if command -v xtensa-lx106-elf-gcc &> /dev/null; then
    TOOLCHAIN_VERSION=$(xtensa-lx106-elf-gcc --version | head -n1)
    print_status 0 "Toolchain: $TOOLCHAIN_VERSION"
else
    print_status 1 "Toolchain не найден в PATH"
fi

echo
echo -e "${GREEN}=== УСТАНОВКА ЗАВЕРШЕНА УСПЕШНО ===${NC}"
echo
echo "Для активации окружения выполните:"
echo -e "${BLUE}source $SETUP_SCRIPT${NC}"
echo
echo "Или перезапустите терминал для автоматической активации"
echo
echo "Проверка установки:"
echo -e "${BLUE}1. source $SETUP_SCRIPT${NC}"
echo -e "${BLUE}2. xtensa-lx106-elf-gcc --version${NC}"
echo -e "${BLUE}3. python3 \$IDF_PATH/tools/idf.py --version${NC}"
echo
echo -e "${GREEN}Теперь вы можете собирать проекты ESP8266 на macOS!${NC}"

# Дополнительные инструкции для macOS
echo
echo -e "${YELLOW}=== ДОПОЛНИТЕЛЬНЫЕ ИНСТРУКЦИИ ДЛЯ macOS ===${NC}"
echo
echo "Для работы с USB-Serial адаптерами может потребоваться:"
echo "1. Установка драйверов CH340/CP2102:"
echo "   brew install --cask wch-ch34x-usb-serial-driver"
echo
echo "2. Порты устройств обычно находятся в:"
echo "   /dev/cu.usbserial-* или /dev/cu.wchusbserial*"
echo
echo "3. Для поиска портов используйте:"
echo "   ls /dev/cu.*"