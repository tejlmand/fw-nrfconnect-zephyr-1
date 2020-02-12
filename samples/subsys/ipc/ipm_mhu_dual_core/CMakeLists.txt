#
# Copyright (c) 2019 Linaro Limited
#
# SPDX-License-Identifier: Apache-2.0
#

cmake_minimum_required(VERSION 3.13.1)

find_package(Zephyr 2.2.0 HINTS $ENV{ZEPHYR_BASE})
project(ipm_mhu_dual_core)

target_sources(app PRIVATE src/main.c)
