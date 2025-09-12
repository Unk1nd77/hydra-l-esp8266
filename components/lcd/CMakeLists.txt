idf_component_register(
    SRCS "lcd.c"
    INCLUDE_DIRS "include"
    REQUIRES esp8266 esp_common freertos log
)