# SPDX-License-Identifier: Apache-2.0

cmake_minimum_required(VERSION 3.13.1)

find_package(Zephyr 2.2.0 HINTS $ENV{ZEPHYR_BASE})
project(gpio_counter)

target_sources(app PRIVATE src/main.c)
zephyr_include_directories(${ZEPHYR_BASE}/boards/x86/up_squared)
