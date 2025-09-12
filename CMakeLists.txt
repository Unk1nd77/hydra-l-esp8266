cmake_minimum_required(VERSION 3.10)

# Установка пути к ESP8266 RTOS SDK
set(IDF_PATH $ENV{IDF_PATH})
if(NOT IDF_PATH)
    set(IDF_PATH ${CMAKE_CURRENT_SOURCE_DIR}/../ESP8266_RTOS_SDK)
endif()

include($ENV{IDF_PATH}/tools/cmake/project.cmake)
project(hydra_l)