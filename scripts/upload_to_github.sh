#!/bin/bash

# Скрипт для загрузки проекта Hydra-L на GitHub
# Автор: Kiro AI Assistant
# Версия: 1.0

set -e

# Цвета для вывода
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}=== Загрузка проекта Hydra-L на GitHub ===${NC}"
echo

# Проверка наличия Git
if ! command -v git &> /dev/null; then
    echo -e "${RED}Ошибка: Git не установлен${NC}"
    echo "Установите Git и повторите попытку"
    exit 1
fi

# Проверка настройки Git
if [ -z "$(git config --global user.name)" ] || [ -z "$(git config --global user.email)" ]; then
    echo -e "${YELLOW}Внимание: Git не настроен${NC}"
    echo "Настройте Git:"
    echo "git config --global user.name 'Ваше Имя'"
    echo "git config --global user.email 'your-email@example.com'"
    exit 1
fi

echo -e "${GREEN}✓ Git настроен${NC}"
echo "Пользователь: $(git config --global user.name)"
echo "Email: $(git config --global user.email)"
echo

# Запрос URL репозитория
echo -e "${YELLOW}Введите URL вашего GitHub репозитория:${NC}"
echo "Примеры:"
echo "  SSH: git@github.com:username/hydra-l-esp8266.git"
echo "  HTTPS: https://github.com/username/hydra-l-esp8266.git"
echo
read -p "URL репозитория: " REPO_URL

if [ -z "$REPO_URL" ]; then
    echo -e "${RED}Ошибка: URL репозитория не указан${NC}"
    exit 1
fi

# Проверка, что мы в правильной директории
if [ ! -f "main/main.c" ] || [ ! -f "CMakeLists.txt" ]; then
    echo -e "${RED}Ошибка: Запустите скрипт из директории проекта${NC}"
    exit 1
fi

echo -e "${GREEN}✓ Проект найден${NC}"

# Создание .gitignore если не существует
if [ ! -f ".gitignore" ]; then
    echo "Создание .gitignore..."
    cat > .gitignore << 'EOF'
# Build files
build/
sdkconfig
sdkconfig.old
*.log

# IDE files
.vscode/
.idea/
*.swp
*.swo
*~

# OS files
.DS_Store
Thumbs.db

# Temporary files
*.tmp
*.temp
*.bak

# Dependencies
node_modules/
__pycache__/
*.pyc

# Personal config files
config.txt
secrets.h
EOF
    echo -e "${GREEN}✓ .gitignore создан${NC}"
fi

# Инициализация Git репозитория
if [ ! -d ".git" ]; then
    echo "Инициализация Git репозитория..."
    git init
    echo -e "${GREEN}✓ Git репозиторий инициализирован${NC}"
fi

# Добавление remote origin
if git remote get-url origin &> /dev/null; then
    echo "Обновление remote origin..."
    git remote set-url origin "$REPO_URL"
else
    echo "Добавление remote origin..."
    git remote add origin "$REPO_URL"
fi
echo -e "${GREEN}✓ Remote origin настроен${NC}"

# Создание основной ветки
CURRENT_BRANCH=$(git branch --show-current 2>/dev/null || echo "")
if [ -z "$CURRENT_BRANCH" ]; then
    git checkout -b main
    echo -e "${GREEN}✓ Создана ветка main${NC}"
fi

# Добавление всех файлов
echo "Добавление файлов в Git..."
git add .

# Проверка статуса
echo -e "${BLUE}Статус репозитория:${NC}"
git status --short

echo
read -p "Продолжить загрузку? (y/N): " CONFIRM
if [[ ! $CONFIRM =~ ^[Yy]$ ]]; then
    echo "Загрузка отменена"
    exit 0
fi

# Коммит
echo "Создание коммита..."
git commit -m "Initial commit: Hydra-L ESP8266 firmware v2.0

- Stable ESP8266 firmware for sensor device
- BME280 temperature, humidity, pressure sensor support
- LCD 1602 display with I2C interface
- WiFi connectivity (STA+AP mode)
- Web server with REST API
- Remote data transmission
- Button handling with debounce
- Sensor data averaging
- Linux build scripts and automation
- Comprehensive documentation

Fixes:
- Resolved FreeRTOS definition conflicts
- Fixed I2C initialization issues
- Improved LCD driver stability
- Enhanced WiFi connectivity
- Added proper error handling
- Optimized memory usage"

echo -e "${GREEN}✓ Коммит создан${NC}"

# Загрузка на GitHub
echo "Загрузка на GitHub..."
if git push -u origin main; then
    echo
    echo -e "${GREEN}🎉 ПРОЕКТ УСПЕШНО ЗАГРУЖЕН НА GITHUB! 🎉${NC}"
    echo
    echo "Ваш проект доступен по адресу:"
    echo "$REPO_URL"
    echo
    echo "Что дальше:"
    echo "1. Проверьте проект на GitHub"
    echo "2. Добавьте описание и теги"
    echo "3. Настройте GitHub Pages (если нужно)"
    echo "4. Пригласите соавторов (если нужно)"
    echo
else
    echo -e "${RED}Ошибка при загрузке на GitHub${NC}"
    echo
    echo "Возможные причины:"
    echo "1. Неправильный URL репозитория"
    echo "2. Проблемы с аутентификацией"
    echo "3. Репозиторий не пустой"
    echo
    echo "Попробуйте:"
    echo "1. Проверить URL репозитория"
    echo "2. Настроить SSH ключи или токен доступа"
    echo "3. Использовать git push --force (осторожно!)"
    exit 1
fi