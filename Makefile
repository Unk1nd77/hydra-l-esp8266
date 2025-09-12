# Makefile для проекта Hydra-L ESP8266
# Альтернативный способ сборки

PROJECT_NAME := hydra_l

# Проверка переменных окружения
ifndef IDF_PATH
$(error IDF_PATH не установлен. Выполните: export IDF_PATH=/path/to/ESP8266_RTOS_SDK)
endif

# Включение основного Makefile ESP8266 RTOS SDK
include $(IDF_PATH)/make/project.mk

# Дополнительные цели
.PHONY: setup clean-all flash-all monitor-all

# Настройка окружения
setup:
	@echo "Проверка окружения..."
	@echo "IDF_PATH: $(IDF_PATH)"
	@which xtensa-lx106-elf-gcc || (echo "Toolchain не найден!" && exit 1)
	@python3 -c "import click, cryptography, pyparsing, pyserial" || (echo "Python зависимости не установлены!" && exit 1)
	@echo "Окружение настроено корректно"

# Полная очистка
clean-all: clean
	rm -f sdkconfig
	rm -f sdkconfig.old

# Прошивка с автоопределением порта
flash-all: all
	@PORT=$$(ls /dev/ttyUSB* /dev/ttyACM* 2>/dev/null | head -n1); \
	if [ -z "$$PORT" ]; then \
		echo "Порт не найден. Укажите вручную: make flash ESPPORT=/dev/ttyUSB0"; \
		exit 1; \
	fi; \
	echo "Используется порт: $$PORT"; \
	$(MAKE) flash ESPPORT=$$PORT

# Мониторинг с автоопределением порта
monitor-all:
	@PORT=$$(ls /dev/ttyUSB* /dev/ttyACM* 2>/dev/null | head -n1); \
	if [ -z "$$PORT" ]; then \
		echo "Порт не найден. Укажите вручную: make monitor ESPPORT=/dev/ttyUSB0"; \
		exit 1; \
	fi; \
	echo "Используется порт: $$PORT"; \
	$(MAKE) monitor ESPPORT=$$PORT

# Справка
help:
	@echo "Доступные команды:"
	@echo "  make setup      - Проверка окружения"
	@echo "  make all        - Сборка проекта"
	@echo "  make clean      - Очистка сборки"
	@echo "  make clean-all  - Полная очистка"
	@echo "  make flash-all  - Прошивка (автопорт)"
	@echo "  make monitor-all- Мониторинг (автопорт)"
	@echo "  make menuconfig - Конфигурация"
	@echo ""
	@echo "Ручное указание порта:"
	@echo "  make flash ESPPORT=/dev/ttyUSB0"
	@echo "  make monitor ESPPORT=/dev/ttyUSB0"