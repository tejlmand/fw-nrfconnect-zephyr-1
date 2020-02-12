# SPDX-License-Identifier: Apache-2.0

cmake_minimum_required(VERSION 3.13.1)
if(BOARD STREQUAL "qemu_cortex_m3")
set(CONF_FILE qemu.conf)
else()
set(CONF_FILE default.conf)
endif()

LIST(APPEND QEMU_EXTRA_FLAGS -serial unix:/tmp/bt-stack-tester)

find_package(Zephyr 2.2.0 HINTS $ENV{ZEPHYR_BASE})
project(tester)

zephyr_library_include_directories(${ZEPHYR_BASE}/samples/bluetooth)
target_sources(app PRIVATE
    src/main.c
    src/bttester.c
    src/gap.c
    src/gatt.c
    )
if(CONFIG_BT_L2CAP_DYNAMIC_CHANNEL)
target_sources(app PRIVATE src/l2cap.c)
endif()

if(CONFIG_BT_MESH)
target_sources(app PRIVATE src/mesh.c)
endif()
