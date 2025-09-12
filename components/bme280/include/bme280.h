#pragma once

#include "esp_err.h"
#include "driver/i2c.h"

#ifdef __cplusplus
extern "C" {
#endif

// I2C определения
#define I2C_MASTER_NUM              I2C_NUM_0
#define BME280_ADDR                 0x76

/**
 * @brief Инициализация BME280
 * @return ESP_OK при успехе
 */
esp_err_t bme280_init(void);

/**
 * @brief Чтение данных с BME280
 * @param temperature Указатель для сохранения температуры (°C)
 * @param humidity Указатель для сохранения влажности (%)
 * @param pressure Указатель для сохранения давления (hPa)
 * @return ESP_OK при успехе
 */
esp_err_t bme280_read(float *temperature, float *humidity, float *pressure);

#ifdef __cplusplus
}
#endif