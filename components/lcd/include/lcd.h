#pragma once

#include "esp_err.h"
#include "driver/i2c.h"

#ifdef __cplusplus
extern "C" {
#endif

// I2C определения
#define I2C_MASTER_NUM              I2C_NUM_0

/**
 * @brief Инициализация LCD дисплея
 * @return ESP_OK при успехе
 */
esp_err_t lcd_init(void);

/**
 * @brief Очистка дисплея
 * @return ESP_OK при успехе
 */
esp_err_t lcd_clear(void);

/**
 * @brief Установка курсора
 * @param col Колонка (0-15)
 * @param row Строка (0-1)
 * @return ESP_OK при успехе
 */
esp_err_t lcd_set_cursor(uint8_t col, uint8_t row);

/**
 * @brief Вывод строки на дисплей
 * @param str Строка для вывода
 * @return ESP_OK при успехе
 */
esp_err_t lcd_print(const char *str);

/**
 * @brief Включение подсветки
 * @return ESP_OK при успехе
 */
esp_err_t lcd_backlight_on(void);

/**
 * @brief Выключение подсветки
 * @return ESP_OK при успехе
 */
esp_err_t lcd_backlight_off(void);

#ifdef __cplusplus
}
#endif