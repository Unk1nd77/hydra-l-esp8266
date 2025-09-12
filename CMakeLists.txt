cmake_minimum_required(VERSION 3.5)

# Установка политик для совместимости с новыми версиями CMake
if(POLICY CMP0115)
    cmake_policy(SET CMP0115 OLD)
endif()
if(POLICY CMP0148)
    cmake_policy(SET CMP0148 OLD)
endif()

# Установка пути к ESP8266 RTOS SDK
set(IDF_PATH $ENV{IDF_PATH})
if(NOT IDF_PATH)
    set(IDF_PATH ${CMAKE_CURRENT_SOURCE_DIR}/../ESP8266_RTOS_SDK)
endif()

# Настройки для pthread поддержки
set(CONFIG_PTHREAD_TASK_STACK_SIZE_DEFAULT 2048)
set(CONFIG_PTHREAD_STACK_MIN 768)

include($ENV{IDF_PATH}/tools/cmake/project.cmake)
project(hydra_l)