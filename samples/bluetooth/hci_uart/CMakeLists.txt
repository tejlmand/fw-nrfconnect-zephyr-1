# SPDX-License-Identifier: Apache-2.0

cmake_minimum_required(VERSION 3.13.1)
if(BOARD STREQUAL bbc_microbit)
  set(CONF_FILE microbit.conf)
elseif(BOARD STREQUAL nrf52840_pca10090)
  set(CONF_FILE nrf52840_pca10090.conf)
else()
  set(CONF_FILE nrf5.conf)
endif()

find_package(Zephyr 2.2.0 HINTS $ENV{ZEPHYR_BASE})
project(hci_uart)

target_sources(app PRIVATE src/main.c)
