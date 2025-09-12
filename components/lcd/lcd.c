#include <string.h>
#include "freertos/FreeRTOS.h"
#include "freertos/task.h"
#include "esp_log.h"
#include "driver/i2c.h"
#include "lcd.h"

static const char *TAG = "LCD";

// Адрес I2C для LCD 1602
#define LCD_ADDR 0x27
#define LCD_BACKLIGHT 0x08
#define LCD_ENABLE 0x04
#define LCD_COMMAND 0x00
#define LCD_DATA 0x01
#define LCD_LINE_1 0x80
#define LCD_LINE_2 0xC0

// Команды LCD
#define LCD_CLEAR_DISPLAY 0x01
#define LCD_RETURN_HOME 0x02
#define LCD_ENTRY_MODE_SET 0x04
#define LCD_DISPLAY_CONTROL 0x08
#define LCD_CURSOR_SHIFT 0x10
#define LCD_FUNCTION_SET 0x20
#define LCD_SET_CGRAM_ADDR 0x40
#define LCD_SET_DDRAM_ADDR 0x80

// Опции для LCD_ENTRY_MODE_SET
#define LCD_ENTRY_RIGHT 0x00
#define LCD_ENTRY_LEFT 0x02
#define LCD_ENTRY_SHIFT_INCREMENT 0x01
#define LCD_ENTRY_SHIFT_DECREMENT 0x00

// Опции для LCD_DISPLAY_CONTROL
#define LCD_DISPLAY_ON 0x04
#define LCD_DISPLAY_OFF 0x00
#define LCD_CURSOR_ON 0x02
#define LCD_CURSOR_OFF 0x00
#define LCD_BLINK_ON 0x01
#define LCD_BLINK_OFF 0x00

// Опции для LCD_FUNCTION_SET
#define LCD_8BIT_MODE 0x10
#define LCD_4BIT_MODE 0x00
#define LCD_2LINE 0x08
#define LCD_1LINE 0x00
#define LCD_5x10DOTS 0x04
#define LCD_5x8DOTS 0x00

static uint8_t backlight_state = LCD_BACKLIGHT;

static esp_err_t lcd_write_nibble(uint8_t data, uint8_t rs)
{
    uint8_t data_byte = (data & 0x0F) << 4 | backlight_state | rs;
    
    i2c_cmd_handle_t cmd = i2c_cmd_link_create();
    i2c_master_start(cmd);
    i2c_master_write_byte(cmd, (LCD_ADDR << 1) | I2C_MASTER_WRITE, true);
    i2c_master_write_byte(cmd, data_byte | LCD_ENABLE, true);
    i2c_master_write_byte(cmd, data_byte & ~LCD_ENABLE, true);
    i2c_master_stop(cmd);
    esp_err_t ret = i2c_master_cmd_begin(I2C_MASTER_NUM, cmd, pdMS_TO_TICKS(1000));
    i2c_cmd_link_delete(cmd);
    
    return ret;
}

static esp_err_t lcd_write_byte(uint8_t data, uint8_t rs)
{
    esp_err_t ret;
    
    ret = lcd_write_nibble(data >> 4, rs);
    if (ret != ESP_OK) {
        ESP_LOGE(TAG, "Failed to write high nibble: %s", esp_err_to_name(ret));
        return ret;
    }
    
    ret = lcd_write_nibble(data & 0x0F, rs);
    if (ret != ESP_OK) {
        ESP_LOGE(TAG, "Failed to write low nibble: %s", esp_err_to_name(ret));
        return ret;
    }
    
    vTaskDelay(pdMS_TO_TICKS(2));
    return ESP_OK;
}

esp_err_t lcd_init(void)
{
    ESP_LOGI(TAG, "Initializing LCD");
    
    vTaskDelay(pdMS_TO_TICKS(50));
    
    // Инициализация LCD в 4-битном режиме
    esp_err_t ret;
    
    ret = lcd_write_nibble(0x03, LCD_COMMAND);
    if (ret != ESP_OK) return ret;
    vTaskDelay(pdMS_TO_TICKS(5));
    
    ret = lcd_write_nibble(0x03, LCD_COMMAND);
    if (ret != ESP_OK) return ret;
    vTaskDelay(pdMS_TO_TICKS(1));
    
    ret = lcd_write_nibble(0x03, LCD_COMMAND);
    if (ret != ESP_OK) return ret;
    vTaskDelay(pdMS_TO_TICKS(1));
    
    ret = lcd_write_nibble(0x02, LCD_COMMAND);
    if (ret != ESP_OK) return ret;
    
    // Настройка дисплея
    ret = lcd_write_byte(LCD_FUNCTION_SET | LCD_4BIT_MODE | LCD_2LINE | LCD_5x8DOTS, LCD_COMMAND);
    if (ret != ESP_OK) return ret;
    
    ret = lcd_write_byte(LCD_DISPLAY_CONTROL | LCD_DISPLAY_ON | LCD_CURSOR_OFF | LCD_BLINK_OFF, LCD_COMMAND);
    if (ret != ESP_OK) return ret;
    
    ret = lcd_write_byte(LCD_ENTRY_MODE_SET | LCD_ENTRY_LEFT, LCD_COMMAND);
    if (ret != ESP_OK) return ret;
    
    ret = lcd_write_byte(LCD_CLEAR_DISPLAY, LCD_COMMAND);
    if (ret != ESP_OK) return ret;
    
    vTaskDelay(pdMS_TO_TICKS(2));
    
    ESP_LOGI(TAG, "LCD initialized successfully");
    return ESP_OK;
}

esp_err_t lcd_clear(void)
{
    esp_err_t ret = lcd_write_byte(LCD_CLEAR_DISPLAY, LCD_COMMAND);
    if (ret == ESP_OK) {
        vTaskDelay(pdMS_TO_TICKS(2));
    }
    return ret;
}

esp_err_t lcd_set_cursor(uint8_t col, uint8_t row)
{
    uint8_t address = (row == 0) ? LCD_LINE_1 : LCD_LINE_2;
    address += col;
    return lcd_write_byte(address, LCD_COMMAND);
}

esp_err_t lcd_print(const char *str)
{
    if (!str) return ESP_ERR_INVALID_ARG;
    
    esp_err_t ret = ESP_OK;
    while (*str && ret == ESP_OK) {
        ret = lcd_write_byte(*str++, LCD_DATA);
    }
    return ret;
}

esp_err_t lcd_backlight_on(void)
{
    backlight_state = LCD_BACKLIGHT;
    return lcd_write_nibble(0x00, LCD_COMMAND);
}

esp_err_t lcd_backlight_off(void)
{
    backlight_state = 0;
    return lcd_write_nibble(0x00, LCD_COMMAND);
}