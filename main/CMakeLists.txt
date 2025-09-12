idf_component_register(
    SRCS "main.c"
    INCLUDE_DIRS "."
    REQUIRES esp8266 esp_common freertos log nvs_flash esp_http_server 
             tcpip_adapter spiffs esp_http_client json app_update
             bme280 lcd
)