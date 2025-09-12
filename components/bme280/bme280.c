#include <string.h>
#include "freertos/FreeRTOS.h"
#include "freertos/task.h"
#include "esp_log.h"
#include "driver/i2c.h"
#include "bme280.h"

static const char *TAG = "BME280";

// Регистры BME280
#define BME280_REG_ID           0xD0
#define BME280_REG_RESET        0xE0
#define BME280_REG_CTRL_HUM     0xF2
#define BME280_REG_STATUS       0xF3
#define BME280_REG_CTRL_MEAS    0xF4
#define BME280_REG_CONFIG       0xF5
#define BME280_REG_PRESS_MSB    0xF7
#define BME280_REG_TEMP_MSB     0xFA
#define BME280_REG_HUM_MSB      0xFD

// Команды
#define BME280_RESET_CMD        0xB6
#define BME280_ID               0x60

// Настройки для Bosch BME280
#define BME280_OVERSAMP_TEMP    0x01
#define BME280_OVERSAMP_PRES    0x01
#define BME280_OVERSAMP_HUM     0x01
#define BME280_MODE_NORMAL      0x03
#define BME280_STANDBY_500      0x00
#define BME280_FILTER_OFF       0x00

// Структура для калибровочных данных
typedef struct {
    uint16_t dig_T1;
    int16_t  dig_T2;
    int16_t  dig_T3;
    uint16_t dig_P1;
    int16_t  dig_P2;
    int16_t  dig_P3;
    int16_t  dig_P4;
    int16_t  dig_P5;
    int16_t  dig_P6;
    int16_t  dig_P7;
    int16_t  dig_P8;
    int16_t  dig_P9;
    uint8_t  dig_H1;
    int16_t  dig_H2;
    uint8_t  dig_H3;
    int16_t  dig_H4;
    int16_t  dig_H5;
    int8_t   dig_H6;
} bme280_calib_data_t;

static bme280_calib_data_t calib_data;

// Вспомогательные функции
static esp_err_t bme280_read_reg(uint8_t reg, uint8_t *data)
{
    i2c_cmd_handle_t cmd = i2c_cmd_link_create();
    i2c_master_start(cmd);
    i2c_master_write_byte(cmd, (BME280_ADDR << 1) | I2C_MASTER_WRITE, true);
    i2c_master_write_byte(cmd, reg, true);
    i2c_master_start(cmd);
    i2c_master_write_byte(cmd, (BME280_ADDR << 1) | I2C_MASTER_READ, true);
    i2c_master_read_byte(cmd, data, I2C_MASTER_LAST_NACK);
    i2c_master_stop(cmd);
    esp_err_t ret = i2c_master_cmd_begin(I2C_MASTER_NUM, cmd, pdMS_TO_TICKS(1000));
    i2c_cmd_link_delete(cmd);
    return ret;
}

static esp_err_t bme280_write_reg(uint8_t reg, uint8_t data)
{
    i2c_cmd_handle_t cmd = i2c_cmd_link_create();
    i2c_master_start(cmd);
    i2c_master_write_byte(cmd, (BME280_ADDR << 1) | I2C_MASTER_WRITE, true);
    i2c_master_write_byte(cmd, reg, true);
    i2c_master_write_byte(cmd, data, true);
    i2c_master_stop(cmd);
    esp_err_t ret = i2c_master_cmd_begin(I2C_MASTER_NUM, cmd, pdMS_TO_TICKS(1000));
    i2c_cmd_link_delete(cmd);
    return ret;
}

static esp_err_t bme280_read_calib_data(void)
{
    uint8_t calib[32];
    esp_err_t ret;
    
    // Чтение калибровочных данных температуры и давления
    for (int i = 0; i < 26; i++) {
        ret = bme280_read_reg(0x88 + i, &calib[i]);
        if (ret != ESP_OK) {
            ESP_LOGE(TAG, "Failed to read calibration data at 0x%02X", 0x88 + i);
            return ret;
        }
    }
    
    // Распаковка калибровочных данных
    calib_data.dig_T1 = (calib[1] << 8) | calib[0];
    calib_data.dig_T2 = (calib[3] << 8) | calib[2];
    calib_data.dig_T3 = (calib[5] << 8) | calib[4];
    calib_data.dig_P1 = (calib[7] << 8) | calib[6];
    calib_data.dig_P2 = (calib[9] << 8) | calib[8];
    calib_data.dig_P3 = (calib[11] << 8) | calib[10];
    calib_data.dig_P4 = (calib[13] << 8) | calib[12];
    calib_data.dig_P5 = (calib[15] << 8) | calib[14];
    calib_data.dig_P6 = (calib[17] << 8) | calib[16];
    calib_data.dig_P7 = (calib[19] << 8) | calib[18];
    calib_data.dig_P8 = (calib[21] << 8) | calib[20];
    calib_data.dig_P9 = (calib[23] << 8) | calib[22];
    calib_data.dig_H1 = calib[25];
    
    // Чтение калибровочных данных влажности
    uint8_t h_calib[7];
    for (int i = 0; i < 7; i++) {
        ret = bme280_read_reg(0xE1 + i, &h_calib[i]);
        if (ret != ESP_OK) {
            ESP_LOGE(TAG, "Failed to read humidity calibration data at 0x%02X", 0xE1 + i);
            return ret;
        }
    }
    
    calib_data.dig_H2 = (h_calib[1] << 8) | h_calib[0];
    calib_data.dig_H3 = h_calib[2];
    calib_data.dig_H4 = (h_calib[3] << 4) | (h_calib[4] & 0x0F);
    calib_data.dig_H5 = (h_calib[5] << 4) | (h_calib[4] >> 4);
    calib_data.dig_H6 = h_calib[6];
    
    return ESP_OK;
}

esp_err_t bme280_init(void)
{
    ESP_LOGI(TAG, "Initializing BME280");
    
    // Проверка ID
    uint8_t id;
    esp_err_t ret = bme280_read_reg(BME280_REG_ID, &id);
    if (ret != ESP_OK) {
        ESP_LOGE(TAG, "Failed to read BME280 ID: %s", esp_err_to_name(ret));
        return ret;
    }
    
    if (id != BME280_ID) {
        ESP_LOGE(TAG, "BME280 not found, ID: 0x%02X (expected 0x%02X)", id, BME280_ID);
        return ESP_FAIL;
    }
    
    ESP_LOGI(TAG, "BME280 found with ID: 0x%02X", id);

    // Сброс
    ret = bme280_write_reg(BME280_REG_RESET, BME280_RESET_CMD);
    if (ret != ESP_OK) {
        ESP_LOGE(TAG, "Failed to reset BME280: %s", esp_err_to_name(ret));
        return ret;
    }
    
    vTaskDelay(pdMS_TO_TICKS(100));

    // Чтение калибровочных данных
    ret = bme280_read_calib_data();
    if (ret != ESP_OK) {
        ESP_LOGE(TAG, "Failed to read calibration data: %s", esp_err_to_name(ret));
        return ret;
    }

    // Настройка влажности
    ret = bme280_write_reg(BME280_REG_CTRL_HUM, BME280_OVERSAMP_HUM);
    if (ret != ESP_OK) {
        ESP_LOGE(TAG, "Failed to configure humidity: %s", esp_err_to_name(ret));
        return ret;
    }
    
    // Настройка конфигурации
    ret = bme280_write_reg(BME280_REG_CONFIG, 
        (BME280_STANDBY_500 << 5) | (BME280_FILTER_OFF << 2));
    if (ret != ESP_OK) {
        ESP_LOGE(TAG, "Failed to configure BME280: %s", esp_err_to_name(ret));
        return ret;
    }
    
    // Настройка измерений
    ret = bme280_write_reg(BME280_REG_CTRL_MEAS, 
        (BME280_OVERSAMP_TEMP << 5) | (BME280_OVERSAMP_PRES << 2) | BME280_MODE_NORMAL);
    if (ret != ESP_OK) {
        ESP_LOGE(TAG, "Failed to configure measurements: %s", esp_err_to_name(ret));
        return ret;
    }

    ESP_LOGI(TAG, "BME280 initialized successfully");
    return ESP_OK;
}

esp_err_t bme280_read(float *temperature, float *humidity, float *pressure)
{
    uint8_t data[8];
    int32_t adc_T, adc_P, adc_H;
    int32_t var1, var2;
    int32_t t_fine;

    // Чтение данных
    for (int i = 0; i < 8; i++) {
        esp_err_t ret = bme280_read_reg(BME280_REG_PRESS_MSB + i, &data[i]);
        if (ret != ESP_OK) {
            ESP_LOGE(TAG, "Failed to read sensor data: %s", esp_err_to_name(ret));
            return ret;
        }
    }

    adc_P = (data[0] << 12) | (data[1] << 4) | (data[2] >> 4);
    adc_T = (data[3] << 12) | (data[4] << 4) | (data[5] >> 4);
    adc_H = (data[6] << 8) | data[7];

    // Компенсация температуры
    var1 = ((((adc_T >> 3) - ((int32_t)calib_data.dig_T1 << 1))) * 
            ((int32_t)calib_data.dig_T2)) >> 11;
    var2 = (((((adc_T >> 4) - ((int32_t)calib_data.dig_T1)) * 
              ((adc_T >> 4) - ((int32_t)calib_data.dig_T1))) >> 12) * 
            ((int32_t)calib_data.dig_T3)) >> 14;
    t_fine = var1 + var2;
    *temperature = ((t_fine * 5 + 128) >> 8) / 100.0f;

    // Компенсация давления
    var1 = (((int32_t)t_fine) >> 1) - 64000;
    var2 = (((var1 >> 2) * (var1 >> 2)) >> 11) * ((int32_t)calib_data.dig_P6);
    var2 = var2 + ((var1 * ((int32_t)calib_data.dig_P5)) << 1);
    var2 = (var2 >> 2) + (((int32_t)calib_data.dig_P4) << 16);
    var1 = (((calib_data.dig_P3 * (((var1 >> 2) * (var1 >> 2)) >> 13)) >> 3) + 
            ((((int32_t)calib_data.dig_P2) * var1) >> 1)) >> 18;
    var1 = ((((32768 + var1)) * ((int32_t)calib_data.dig_P1)) >> 15);
    
    if (var1 == 0) {
        *pressure = 0;
        ESP_LOGW(TAG, "Pressure calculation failed (division by zero)");
    } else {
        int64_t p = (((uint32_t)(1048576 - adc_P) - (var2 >> 12))) * 3125;
        p = (p / var1) * 2;
        var1 = (((int32_t)calib_data.dig_P9) * ((int32_t)(((p >> 3) * (p >> 3)) >> 13))) >> 12;
        var2 = (((int32_t)(p >> 2)) * ((int32_t)calib_data.dig_P8)) >> 13;
        p = (uint32_t)((int32_t)p + ((var1 + var2 + calib_data.dig_P7) >> 4));
        *pressure = p / 100.0f;
    }

    // Компенсация влажности
    int32_t v_x1_u32r;
    v_x1_u32r = (t_fine - ((int32_t)76800));
    v_x1_u32r = (((((adc_H << 14) - (((int32_t)calib_data.dig_H4) << 20) - 
                    (((int32_t)calib_data.dig_H5) * v_x1_u32r)) + ((int32_t)16384)) >> 15) * 
                 (((((((v_x1_u32r * ((int32_t)calib_data.dig_H6)) >> 10) * 
                      (((v_x1_u32r * ((int32_t)calib_data.dig_H3)) >> 11) + ((int32_t)32768))) >> 10) + 
                    ((int32_t)2097152)) * ((int32_t)calib_data.dig_H2) + 8192) >> 14));
    v_x1_u32r = (v_x1_u32r - (((((v_x1_u32r >> 15) * (v_x1_u32r >> 15)) >> 7) * 
                              ((int32_t)calib_data.dig_H1)) >> 4));
    v_x1_u32r = (v_x1_u32r < 0 ? 0 : v_x1_u32r);
    v_x1_u32r = (v_x1_u32r > 419430400 ? 419430400 : v_x1_u32r);
    *humidity = (v_x1_u32r >> 12) / 1024.0f;

    return ESP_OK;
}