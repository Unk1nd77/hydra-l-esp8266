#include <stdio.h>
#include <string.h>
#include "freertos/FreeRTOS.h"
#include "freertos/task.h"
#include "freertos/event_groups.h"
#include "esp_system.h"
#include "esp_wifi.h"
#include "esp_log.h"
#include "nvs_flash.h"
#include "esp_http_server.h"
#include "driver/i2c.h"
#include "driver/gpio.h"
#include "bme280.h"
#include "lcd.h"
#include "tcpip_adapter.h"
#include "esp_spiffs.h"
#include "esp_http_client.h"
#include "cJSON.h"
#include "esp_ota_ops.h"
#include "sdkconfig.h"
#include <sys/param.h>

// Определения для I2C (WeMos D1 Mini)
#define I2C_MASTER_SCL_IO           2
#define I2C_MASTER_SDA_IO           14
#define I2C_MASTER_NUM              I2C_NUM_0
#define I2C_MASTER_TX_BUF_DISABLE   0
#define I2C_MASTER_RX_BUF_DISABLE   0
#define I2C_MASTER_FREQ_HZ          100000
#define I2C_MASTER_TIMEOUT_MS       1000

// Определения для WiFi
#define WIFI_SSID      "your_ssid"
#define WIFI_PASS      "your_password"
#define MAXIMUM_RETRY  5
#define AP_SSID        "Hydra-L"
#define AP_PASS        "12345678"
#define AP_MAX_CONN    4

// Определения для OTA
#define OTA_URL        "http://188.35.161.31/firmware/hydra-l.bin"
#define OTA_TIMEOUT_MS 30000

// Определения для кнопок
#define BUTTON_1_GPIO     12
#define BUTTON_2_GPIO     13
#define DEBOUNCE_TIME_MS  50

// Глобальные переменные
static const char *TAG = "ESP8266_RTOS";
static EventGroupHandle_t s_wifi_event_group;
#define WIFI_CONNECTED_BIT BIT0
#define WIFI_FAIL_BIT      BIT1

static int s_retry_num = 0;

// Структуры для хранения данных
typedef struct {
    float temperature;
    float humidity;
    float pressure;
} sensor_data_t;

static sensor_data_t sensor_data = {0};

// Глобальные переменные
static char lcd_string1[17] = {0};
static char lcd_string2[17] = {0};
static char lcd_mode = '0';
static bool lcd_backlight = true;
static char device_name[32] = {0};
static char akey[32] = {0};

// Глобальные переменные для сетевой информации
static char current_ip[16] = "0.0.0.0";
static char current_mac[18] = "00:00:00:00:00:00";
static int current_rssi = 0;

// Структура для усреднения показаний
#define SENSOR_AVG_COUNT 5
typedef struct {
    float values[SENSOR_AVG_COUNT];
    int index;
    int count;
} sensor_avg_t;

static sensor_avg_t temp_avg = {0};
static sensor_avg_t hum_avg = {0};
static sensor_avg_t press_avg = {0};

// Структура для хранения состояния кнопок
typedef struct {
    uint32_t last_press_time;
    bool is_pressed;
} button_state_t;

static button_state_t button1_state = {0};
static button_state_t button2_state = {0};

// Функция для обновления скользящего среднего
static float update_average(sensor_avg_t *avg, float new_value) {
    avg->values[avg->index] = new_value;
    avg->index = (avg->index + 1) % SENSOR_AVG_COUNT;
    if (avg->count < SENSOR_AVG_COUNT) avg->count++;
    
    float sum = 0;
    for (int i = 0; i < avg->count; i++) {
        sum += avg->values[i];
    }
    return sum / avg->count;
}

// Инициализация I2C
static esp_err_t i2c_master_init()
{
    int i2c_master_port = I2C_MASTER_NUM;
    i2c_config_t conf = {
        .mode = I2C_MODE_MASTER,
        .sda_io_num = I2C_MASTER_SDA_IO,
        .sda_pullup_en = GPIO_PULLUP_ENABLE,
        .scl_io_num = I2C_MASTER_SCL_IO,
        .scl_pullup_en = GPIO_PULLUP_ENABLE,
        .master.clk_speed = I2C_MASTER_FREQ_HZ,
    };
    
    esp_err_t err = i2c_param_config(i2c_master_port, &conf);
    if (err != ESP_OK) {
        ESP_LOGE(TAG, "I2C param config failed: %s", esp_err_to_name(err));
        return err;
    }
    
    err = i2c_driver_install(i2c_master_port, conf.mode, I2C_MASTER_RX_BUF_DISABLE, I2C_MASTER_TX_BUF_DISABLE, 0);
    if (err != ESP_OK) {
        ESP_LOGE(TAG, "I2C driver install failed: %s", esp_err_to_name(err));
        return err;
    }
    
    return ESP_OK;
}

// Обработчик событий WiFi
static void event_handler(void* arg, esp_event_base_t event_base,
                                int32_t event_id, void* event_data)
{
    if (event_base == WIFI_EVENT && event_id == WIFI_EVENT_STA_START) {
        esp_wifi_connect();
    } else if (event_base == WIFI_EVENT && event_id == WIFI_EVENT_STA_DISCONNECTED) {
        if (s_retry_num < MAXIMUM_RETRY) {
            esp_wifi_connect();
            s_retry_num++;
            ESP_LOGI(TAG, "retry to connect to the AP");
        } else {
            xEventGroupSetBits(s_wifi_event_group, WIFI_FAIL_BIT);
        }
        ESP_LOGI(TAG,"connect to the AP fail");
    } else if (event_base == IP_EVENT && event_id == IP_EVENT_STA_GOT_IP) {
        ip_event_got_ip_t* event = (ip_event_got_ip_t*) event_data;
        ESP_LOGI(TAG, "got ip:" IPSTR, IP2STR(&event->ip_info.ip));
        s_retry_num = 0;
        xEventGroupSetBits(s_wifi_event_group, WIFI_CONNECTED_BIT);
        
        // Получаем сетевую информацию
        uint8_t mac[6];
        esp_wifi_get_mac(WIFI_IF_STA, mac);
        snprintf(current_mac, sizeof(current_mac), "%02x:%02x:%02x:%02x:%02x:%02x",
                 mac[0], mac[1], mac[2], mac[3], mac[4], mac[5]);
        
        tcpip_adapter_ip_info_t ip_info;
        if (tcpip_adapter_get_ip_info(TCPIP_ADAPTER_IF_STA, &ip_info) == ESP_OK) {
            snprintf(current_ip, sizeof(current_ip), IPSTR, IP2STR(&ip_info.ip));
        }
        
        wifi_ap_record_t ap_info;
        if (esp_wifi_sta_get_ap_info(&ap_info) == ESP_OK) {
            current_rssi = ap_info.rssi;
        }
    }
}

// Обработчик для получения данных
static esp_err_t data_handler(httpd_req_t *req)
{
    char buf[256];
    snprintf(buf, sizeof(buf),
             "{\"temperature\":%.1f,\"humidity\":%.1f,\"pressure\":%.1f,\"rssi\":%d,\"mac\":\"%s\",\"ip\":\"%s\"}",
             sensor_data.temperature, sensor_data.humidity, sensor_data.pressure,
             current_rssi, current_mac, current_ip);
    
    httpd_resp_set_type(req, "application/json");
    httpd_resp_send(req, buf, strlen(buf));
    return ESP_OK;
}

// Функция отправки данных на сервер
static void send_data_to_server(void)
{
    cJSON *root = cJSON_CreateObject();
    cJSON *system = cJSON_CreateObject();
    cJSON *bme280 = cJSON_CreateObject();
    
    cJSON_AddStringToObject(system, "Akey", akey);
    cJSON_AddStringToObject(system, "Serial", device_name);
    cJSON_AddStringToObject(system, "Version", "2024-03-20");
    cJSON_AddNumberToObject(system, "RSSI", current_rssi);
    cJSON_AddStringToObject(system, "MAC", current_mac);
    cJSON_AddStringToObject(system, "IP", current_ip);
    
    cJSON_AddNumberToObject(bme280, "temp", sensor_data.temperature);
    cJSON_AddNumberToObject(bme280, "humidity", sensor_data.humidity);
    cJSON_AddNumberToObject(bme280, "pressure", sensor_data.pressure);
    
    cJSON_AddItemToObject(root, "system", system);
    cJSON_AddItemToObject(root, "BME280", bme280);
    
    char *json_str = cJSON_Print(root);
    cJSON_Delete(root);
    
    esp_http_client_config_t config = {
        .url = "http://188.35.161.31/core/jsonadd.php",
        .method = HTTP_METHOD_POST,
        .timeout_ms = 10000,
    };
    
    esp_http_client_handle_t client = esp_http_client_init(&config);
    if (client) {
        esp_http_client_set_post_field(client, json_str, strlen(json_str));
        esp_http_client_set_header(client, "Content-Type", "application/json");
        
        esp_err_t err = esp_http_client_perform(client);
        if (err == ESP_OK) {
            ESP_LOGI(TAG, "Data sent successfully");
        } else {
            ESP_LOGE(TAG, "HTTP POST request failed: %s", esp_err_to_name(err));
        }
        
        esp_http_client_cleanup(client);
    }
    
    free(json_str);
}

// Загрузка конфигурации
static esp_err_t load_config(void)
{
    FILE *f = fopen("/spiffs/config.txt", "r");
    if (f == NULL) {
        ESP_LOGW(TAG, "Config file not found, using defaults");
        strcpy(device_name, "Hydra-L-001");
        strcpy(akey, "default_key");
        return ESP_OK;
    }
    
    char line[64];
    if (fgets(line, sizeof(line), f)) {
        line[strcspn(line, "\n")] = 0;
        strncpy(device_name, line, sizeof(device_name) - 1);
    }
    if (fgets(line, sizeof(line), f)) {
        line[strcspn(line, "\n")] = 0;
        strncpy(akey, line, sizeof(akey) - 1);
    }
    
    fclose(f);
    return ESP_OK;
}

// Обработчики HTTP
static esp_err_t set_mode_handler(httpd_req_t *req)
{
    char buf[10];
    int ret = httpd_req_recv(req, buf, sizeof(buf) - 1);
    if (ret <= 0) {
        return ESP_FAIL;
    }
    buf[ret] = '\0';
    
    lcd_mode = buf[0];
    
    httpd_resp_send(req, "OK", 2);
    return ESP_OK;
}

static esp_err_t set_lcd_handler(httpd_req_t *req)
{
    char buf[100];
    int ret = httpd_req_recv(req, buf, sizeof(buf) - 1);
    if (ret <= 0) {
        return ESP_FAIL;
    }
    buf[ret] = '\0';
    
    char *num = strtok(buf, "=");
    char *str = strtok(NULL, "=");
    
    if (num && str) {
        if (strcmp(num, "1") == 0) {
            strncpy(lcd_string1, str, 16);
            lcd_string1[16] = '\0';
        } else if (strcmp(num, "2") == 0) {
            strncpy(lcd_string2, str, 16);
            lcd_string2[16] = '\0';
        }
    }
    
    httpd_resp_send(req, "OK", 2);
    return ESP_OK;
}

static esp_err_t set_led_handler(httpd_req_t *req)
{
    char buf[10];
    int ret = httpd_req_recv(req, buf, sizeof(buf) - 1);
    if (ret <= 0) {
        return ESP_FAIL;
    }
    buf[ret] = '\0';
    
    if (strcmp(buf, "1") == 0) {
        lcd_backlight = true;
        lcd_backlight_on();
    } else {
        lcd_backlight = false;
        lcd_backlight_off();
    }
    
    httpd_resp_send(req, "OK", 2);
    return ESP_OK;
}

// Запуск веб-сервера
static httpd_handle_t start_webserver(void)
{
    httpd_handle_t server = NULL;
    httpd_config_t config = HTTPD_DEFAULT_CONFIG();
    config.max_uri_handlers = 8;

    if (httpd_start(&server, &config) == ESP_OK) {
        httpd_uri_t data = {
            .uri       = "/getData",
            .method    = HTTP_GET,
            .handler   = data_handler,
            .user_ctx  = NULL
        };
        
        httpd_uri_t set_mode = {
            .uri       = "/setMode",
            .method    = HTTP_POST,
            .handler   = set_mode_handler,
            .user_ctx  = NULL
        };
        
        httpd_uri_t set_lcd = {
            .uri       = "/setLCD",
            .method    = HTTP_POST,
            .handler   = set_lcd_handler,
            .user_ctx  = NULL
        };
        
        httpd_uri_t set_led = {
            .uri       = "/setLED",
            .method    = HTTP_POST,
            .handler   = set_led_handler,
            .user_ctx  = NULL
        };
        
        httpd_register_uri_handler(server, &data);
        httpd_register_uri_handler(server, &set_mode);
        httpd_register_uri_handler(server, &set_lcd);
        httpd_register_uri_handler(server, &set_led);
        
        return server;
    }

    ESP_LOGE(TAG, "Error starting server!");
    return NULL;
}

// Задача чтения сенсоров
static void sensor_task(void *pvParameters)
{
    TickType_t xLastWakeTime = xTaskGetTickCount();
    const TickType_t xFrequency = pdMS_TO_TICKS(5000);
    
    while (1) {
        float temp, hum, press;
        if (bme280_read(&temp, &hum, &press) == ESP_OK) {
            sensor_data.temperature = update_average(&temp_avg, temp);
            sensor_data.humidity = update_average(&hum_avg, hum);
            sensor_data.pressure = update_average(&press_avg, press);
            
            ESP_LOGI(TAG, "T=%.1f°C, H=%.1f%%, P=%.1fhPa", 
                     sensor_data.temperature, sensor_data.humidity, sensor_data.pressure);
        } else {
            ESP_LOGE(TAG, "Failed to read BME280");
        }
        
        vTaskDelayUntil(&xLastWakeTime, xFrequency);
    }
}

// Задача обновления LCD
static void lcd_task(void *pvParameters)
{
    char buf[32];
    TickType_t xLastWakeTime = xTaskGetTickCount();
    const TickType_t xFrequency = pdMS_TO_TICKS(2000);
    
    while (1) {
        switch(lcd_mode) {
            case '0':
                lcd_clear();
                lcd_set_cursor(0, 0);
                snprintf(buf, sizeof(buf), "T=%.1fC H=%.1f%%", sensor_data.temperature, sensor_data.humidity);
                lcd_print(buf);
                lcd_set_cursor(0, 1);
                snprintf(buf, sizeof(buf), "P=%.1fhPa", sensor_data.pressure);
                lcd_print(buf);
                break;
            case '1':
                lcd_clear();
                lcd_set_cursor(0, 0);
                lcd_print(lcd_string1);
                lcd_set_cursor(0, 1);
                lcd_print(lcd_string2);
                break;
            case '2':
                lcd_clear();
                lcd_set_cursor(0, 0);
                lcd_print("IP Address:");
                lcd_set_cursor(0, 1);
                lcd_print(current_ip);
                break;
        }
        
        vTaskDelayUntil(&xLastWakeTime, xFrequency);
    }
}

// Задача отправки данных на сервер
static void server_task(void *pvParameters)
{
    TickType_t xLastWakeTime = xTaskGetTickCount();
    const TickType_t xFrequency = pdMS_TO_TICKS(60000);
    
    while (1) {
        if (xEventGroupGetBits(s_wifi_event_group) & WIFI_CONNECTED_BIT) {
            send_data_to_server();
        }
        
        vTaskDelayUntil(&xLastWakeTime, xFrequency);
    }
}

// Обработчик прерывания для кнопок
static void IRAM_ATTR button_isr_handler(void* arg)
{
    button_state_t* button = (button_state_t*) arg;
    uint32_t current_time = xTaskGetTickCount() * portTICK_PERIOD_MS;
    
    if (current_time - button->last_press_time > DEBOUNCE_TIME_MS) {
        button->is_pressed = true;
        button->last_press_time = current_time;
    }
}

// Задача обработки кнопок
static void button_task(void *pvParameters)
{
    gpio_config_t io_conf = {
        .pin_bit_mask = (1ULL << BUTTON_1_GPIO) | (1ULL << BUTTON_2_GPIO),
        .mode = GPIO_MODE_INPUT,
        .pull_up_en = GPIO_PULLUP_ENABLE,
        .pull_down_en = GPIO_PULLDOWN_DISABLE,
        .intr_type = GPIO_INTR_NEGEDGE
    };
    gpio_config(&io_conf);
    
    gpio_install_isr_service(0);
    gpio_isr_handler_add(BUTTON_1_GPIO, button_isr_handler, &button1_state);
    gpio_isr_handler_add(BUTTON_2_GPIO, button_isr_handler, &button2_state);
    
    while (1) {
        if (button1_state.is_pressed) {
            lcd_mode = (lcd_mode == '2') ? '0' : (lcd_mode + 1);
            button1_state.is_pressed = false;
            ESP_LOGI(TAG, "Button 1 pressed, LCD mode: %c", lcd_mode);
        }
        
        if (button2_state.is_pressed) {
            lcd_backlight = !lcd_backlight;
            if (lcd_backlight) {
                lcd_backlight_on();
            } else {
                lcd_backlight_off();
            }
            button2_state.is_pressed = false;
            ESP_LOGI(TAG, "Button 2 pressed, backlight: %s", lcd_backlight ? "ON" : "OFF");
        }
        
        vTaskDelay(pdMS_TO_TICKS(50));
    }
}

// Инициализация WiFi
static void wifi_init_sta(void)
{
    s_wifi_event_group = xEventGroupCreate();

    tcpip_adapter_init();
    ESP_ERROR_CHECK(esp_event_loop_create_default());

    wifi_init_config_t cfg = WIFI_INIT_CONFIG_DEFAULT();
    ESP_ERROR_CHECK(esp_wifi_init(&cfg));

    ESP_ERROR_CHECK(esp_event_handler_register(WIFI_EVENT, ESP_EVENT_ANY_ID, &event_handler, NULL));
    ESP_ERROR_CHECK(esp_event_handler_register(IP_EVENT, IP_EVENT_STA_GOT_IP, &event_handler, NULL));

    wifi_config_t wifi_config = {
        .sta = {
            .ssid = WIFI_SSID,
            .password = WIFI_PASS,
            .threshold.authmode = WIFI_AUTH_WPA2_PSK,
        },
    };

    ESP_ERROR_CHECK(esp_wifi_set_mode(WIFI_MODE_APSTA));
    ESP_ERROR_CHECK(esp_wifi_set_config(ESP_IF_WIFI_STA, &wifi_config));
    
    // Настройка AP
    wifi_config_t ap_config = {
        .ap = {
            .ssid = AP_SSID,
            .ssid_len = strlen(AP_SSID),
            .password = AP_PASS,
            .max_connection = AP_MAX_CONN,
            .authmode = WIFI_AUTH_WPA_WPA2_PSK
        },
    };
    ESP_ERROR_CHECK(esp_wifi_set_config(ESP_IF_WIFI_AP, &ap_config));
    
    ESP_ERROR_CHECK(esp_wifi_start());

    ESP_LOGI(TAG, "WiFi initialization finished");
}

void app_main(void)
{
    ESP_LOGI(TAG, "Starting Hydra-L firmware");
    
    // Инициализация NVS
    esp_err_t ret = nvs_flash_init();
    if (ret == ESP_ERR_NVS_NO_FREE_PAGES || ret == ESP_ERR_NVS_NOT_FOUND) {
        ESP_LOGI(TAG, "NVS partition was truncated and needs to be erased");
        ESP_ERROR_CHECK(nvs_flash_erase());
        ret = nvs_flash_init();
    }
    ESP_ERROR_CHECK(ret);
    ESP_LOGI(TAG, "NVS initialized successfully");

    // Инициализация I2C
    ESP_ERROR_CHECK(i2c_master_init());
    ESP_LOGI(TAG, "I2C initialized successfully");

    // Инициализация LCD
    ESP_ERROR_CHECK(lcd_init());
    lcd_clear();
    lcd_set_cursor(0, 0);
    lcd_print("Hydra-L v2.0");
    lcd_set_cursor(0, 1);
    lcd_print("Starting...");

    // Инициализация BME280
    ESP_ERROR_CHECK(bme280_init());
    ESP_LOGI(TAG, "BME280 initialized successfully");

    // Инициализация SPIFFS
    esp_vfs_spiffs_conf_t conf = {
        .base_path = "/spiffs",
        .partition_label = NULL,
        .max_files = 5,
        .format_if_mount_failed = true
    };
    esp_err_t spiffs_ret = esp_vfs_spiffs_register(&conf);
    if (spiffs_ret != ESP_OK) {
        ESP_LOGW(TAG, "SPIFFS initialization failed: %s", esp_err_to_name(spiffs_ret));
    } else {
        ESP_LOGI(TAG, "SPIFFS initialized successfully");
    }

    // Загрузка конфигурации
    load_config();

    // Инициализация WiFi
    wifi_init_sta();

    // Создание задач
    xTaskCreate(sensor_task, "sensor_task", 4096, NULL, 5, NULL);
    xTaskCreate(lcd_task, "lcd_task", 2048, NULL, 4, NULL);
    xTaskCreate(server_task, "server_task", 4096, NULL, 3, NULL);
    xTaskCreate(button_task, "button_task", 2048, NULL, 2, NULL);

    // Запуск веб-сервера
    httpd_handle_t server = start_webserver();
    if (server) {
        ESP_LOGI(TAG, "Web server started successfully");
    }

    ESP_LOGI(TAG, "Hydra-L firmware started successfully");
}