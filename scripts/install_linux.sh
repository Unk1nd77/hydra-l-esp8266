#!/bin/bash

# Скрипт установки окружения для разработки ESP8266 на Linux
# Версия: 2.2 (работает без RPM Fusion, с российскими зеркалами)

set -e

echo "=== ESP8266 Development Environment Setup ==="
echo "Установка окружения для разработки ESP8266 на Linux"
echo "Поддержка российских зеркал и работа без RPM Fusion"
echo

# Определение дистрибутива Linux
if [ -f /etc/os-release ]; then
    . /etc/os-release
    DISTRO=$ID
else
    echo "Не удалось определить дистрибутив Linux"
    exit 1
fi

echo "Обнаружен дистрибутив: $DISTRO"

# Функция для настройки российских зеркал Fedora
setup_fedora_mirrors() {
    echo "Настройка российских зеркал для Fedora..."
    
    # Остановить все процессы DNF
    sudo pkill dnf 2>/dev/null || true
    
    # Очистить кэш
    sudo dnf clean all
    
    # Настроить российские зеркала
    sudo dnf config-manager --set-enabled fedora
    sudo dnf config-manager --set-enabled updates
    
    # Добавить российские зеркала
    echo "Добавление российских зеркал..."
    sudo dnf config-manager --add-repo https://mirror.yandex.ru/fedora/linux/ 2>/dev/null || true
    sudo dnf config-manager --add-repo https://mirror.selectel.ru/fedora/linux/ 2>/dev/null || true
    
    # Обновить кэш
    sudo dnf makecache
}

# Установка системных зависимостей
echo "Установка системных зависимостей..."
case $DISTRO in
    ubuntu|debian)
        echo "Установка для Ubuntu/Debian..."
        sudo apt update
        sudo apt install -y \
            git \
            wget \
            flex \
            bison \
            gperf \
            python3 \
            python3-pip \
            python3-setuptools \
            cmake \
            ninja-build \
            ccache \
            libffi-dev \
            libssl-dev \
            dfu-util \
            libusb-1.0-0
        ;;
    fedora|centos|rhel)
        echo "Установка для Fedora/CentOS/RHEL..."
        
        # Настроить российские зеркала для Fedora
        if [[ "$DISTRO" == "fedora" ]]; then
            setup_fedora_mirrors
        fi
        
        # Установить пакеты
        sudo dnf install -y \
            git \
            wget \
            flex \
            bison \
            gperf \
            python3 \
            python3-pip \
            python3-setuptools \
            cmake \
            ninja-build \
            ccache \
            libffi-devel \
            openssl-devel \
            dfu-util \
            libusbx-devel
        ;;
    arch|manjaro)
        echo "Установка для Arch Linux..."
        sudo pacman -S --needed \
            git \
            wget \
            flex \
            bison \
            gperf \
            python \
            python-pip \
            python-setuptools \
            cmake \
            ninja \
            ccache \
            libffi \
            openssl \
            dfu-util \
            libusb
        ;;
    *)
        echo "Неподдерживаемый дистрибутив: $DISTRO"
        echo "Попробуйте установить зависимости вручную:"
        echo "git wget flex bison gperf python3 python3-pip python3-setuptools cmake ninja-build ccache"
        ;;
esac

# Создание рабочей директории
WORK_DIR="$HOME/esp"
echo "Создание рабочей директории: $WORK_DIR"
mkdir -p $WORK_DIR
cd $WORK_DIR

# Скачивание ESP8266 RTOS SDK
if [ ! -d "ESP8266_RTOS_SDK" ]; then
    echo "Скачивание ESP8266 RTOS SDK..."
    
    # Настроить git для работы с российскими зеркалами
    git config --global http.sslVerify true
    git config --global http.postBuffer 1048576000
    
    # Клонировать SDK
    GIT_URL="https://github.com/espressif/ESP8266_RTOS_SDK.git"
    echo "Клонирование: $GIT_URL"
    
    if ! git clone --recursive "$GIT_URL"; then
        echo "Ошибка при клонировании, пробуем альтернативный метод..."
        git clone "$GIT_URL"
        cd ESP8266_RTOS_SDK
        git submodule update --init --recursive
        cd ..
    else
        cd ESP8266_RTOS_SDK
        git checkout v3.4
        git submodule update --init --recursive
        cd ..
    fi
else
    echo "ESP8266 RTOS SDK уже установлен"
fi

# Скачивание toolchain
TOOLCHAIN_DIR="xtensa-lx106-elf"
if [ ! -d "$TOOLCHAIN_DIR" ]; then
    echo "Скачивание ESP8266 toolchain..."
    
    # Определение архитектуры
    ARCH=$(uname -m)
    case $ARCH in
        x86_64)
            TOOLCHAIN_URL="https://dl.espressif.com/dl/xtensa-lx106-elf-gcc8_4_0-esp-2020r3-linux-amd64.tar.gz"
            ;;
        i686|i386)
            TOOLCHAIN_URL="https://dl.espressif.com/dl/xtensa-lx106-elf-gcc8_4_0-esp-2020r3-linux-i686.tar.gz"
            ;;
        *)
            echo "Неподдерживаемая архитектура: $ARCH"
            exit 1
            ;;
    esac
    
    echo "Скачивание toolchain: $TOOLCHAIN_URL"
    
    # Скачиваем с проверкой
    if ! wget "$TOOLCHAIN_URL" -O toolchain.tar.gz; then
        echo "Ошибка при скачивании toolchain"
        exit 1
    fi
    
    tar -xzf toolchain.tar.gz
    rm toolchain.tar.gz
else
    echo "ESP8266 toolchain уже установлен"
fi

# Установка Python зависимостей
echo "Установка Python зависимостей..."
pip3 install --user click cryptography pyparsing pyserial

# Создание скрипта активации окружения
SETUP_SCRIPT="$WORK_DIR/setup_env.sh"
echo "Создание скрипта активации окружения: $SETUP_SCRIPT"

cat > $SETUP_SCRIPT << 'EOF'
#!/bin/bash
# ESP8266 Development Environment Setup

export IDF_PATH="$HOME/esp/ESP8266_RTOS_SDK"
export PATH="$HOME/esp/xtensa-lx106-elf/bin:$PATH"

echo "ESP8266 development environment activated"
echo "IDF_PATH: $IDF_PATH"
echo "Toolchain: $(xtensa-lx106-elf-gcc --version 2>/dev/null | head -n1 || echo 'Not found')"
EOF

chmod +x $SETUP_SCRIPT

# Добавление в .bashrc
BASHRC_LINE="source $SETUP_SCRIPT"
if ! grep -q "$BASHRC_LINE" ~/.bashrc; then
    echo "Добавление в ~/.bashrc..."
    echo "" >> ~/.bashrc
    echo "# ESP8266 Development Environment" >> ~/.bashrc
    echo "$BASHRC_LINE" >> ~/.bashrc
fi

echo
echo "=== УСТАНОВКА ЗАВЕРШЕНА ==="
echo
echo "Для активации окружения выполните:"
echo "source $SETUP_SCRIPT"
echo
echo "Или перезапустите терминал для автоматической активации"
echo
echo "Проверка установки:"
echo "1. source $SETUP_SCRIPT"
echo "2. xtensa-lx106-elf-gcc --version"
echo "3. python3 \$IDF_PATH/tools/idf.py --version"
echo
echo "Теперь вы можете собирать проекты ESP8266!"
