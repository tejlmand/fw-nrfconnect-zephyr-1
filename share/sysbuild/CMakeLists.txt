# Copyright (c) 2021 Nordic Semiconductor
#
# SPDX-License-Identifier: Apache-2.0

cmake_minimum_required(VERSION 3.20)

if(NOT DEFINED APP_DIR)
  message(FATAL_ERROR "No main application specified")
endif()

# This will update the APP_DIR cache variable to PATH type and apply a comment.
# If APP_DIR is a relative path, then CMake will adjust to absolute path based
# on current working dir.
set(APP_DIR ${APP_DIR} CACHE PATH "Main Application Source Directory")

# Add sysbuild/cmake/modules to CMAKE_MODULE_PATH which allows us to integrate
# sysbuild CMake modules with general Zephyr CMake modules.
list(APPEND CMAKE_MODULE_PATH ${CMAKE_CURRENT_LIST_DIR}/cmake/modules)
# List of Zephyr and sysbuild CMake modules we need for sysbuild.
# Note: sysbuild_kconfig will internally load kconfig CMake module.
set(zephyr_modules extensions sysbuild_extensions python west root zephyr_module boards shields sysbuild_kconfig)

find_package(Zephyr REQUIRED HINTS $ENV{ZEPHYR_BASE} COMPONENTS ${zephyr_modules})

project(sysbuild LANGUAGES)

# Global list of images enabled in this multi image build system.
set(IMAGES)

get_filename_component(APP_DIR  ${APP_DIR} ABSOLUTE)
get_filename_component(app_name ${APP_DIR} NAME)

# Propagate bootloader and signing settings from this system to the MCUboot and
# application image build systems.
if(SB_CONFIG_BOOTLOADER_MCUBOOT)
  set(${app_name}_CONFIG_BOOTLOADER_MCUBOOT y CACHE STRING
      "MCUBOOT is enabled as bootloader" FORCE
  )
  set(${app_name}_CONFIG_MCUBOOT_SIGNATURE_KEY_FILE
      \"${SB_CONFIG_BOOT_SIGNATURE_KEY_FILE}\" CACHE STRING
      "Signature key file for signing" FORCE
  )

  set(${app_name}_CONFIG_ROM_START_OFFSET "0x200" CACHE STRING
      "Flash load offset" FORCE
  )

  # Set corresponding values in mcuboot
  set(mcuboot_CONFIG_BOOT_SIGNATURE_TYPE_${SB_CONFIG_SIGNATURE_TYPE} y CACHE STRING
      "MCUBOOT signature type" FORCE
  )
  set(mcuboot_CONFIG_BOOT_SIGNATURE_KEY_FILE
      \"${SB_CONFIG_BOOT_SIGNATURE_KEY_FILE}\" CACHE STRING
      "Signature key file for signing" FORCE
  )
else()
  set(${app_name}_CONFIG_BOOTLOADER_MCUBOOT n CACHE STRING
      "MCUBOOT is disabled as bootloader" FORCE
  )
endif()

# This adds the primary application to the build.
ExternalZephyrProject_Add(
  APPLICATION ${app_name}
  SOURCE_DIR ${APP_DIR}
  MAIN_APP
)
list(APPEND IMAGES "${app_name}")
set(DEFAULT_IMAGE "${app_name}")

add_subdirectory(bootloader)
add_subdirectory(radio)

# This allows for board and app specific images to be included.
include(${BOARD_DIR}/sysbuild.cmake OPTIONAL)

# This allows image specific sysbuild.cmake to be processed.
list(LENGTH IMAGES images_length)
while(NOT "${images_length}" EQUAL "${processed_length}")
  foreach(image ${IMAGES})
    if(NOT image IN_LIST images_sysbuild_processed)
      ExternalProject_Get_property(${image} SOURCE_DIR)
      include(${SOURCE_DIR}/sysbuild.cmake OPTIONAL)
      list(APPEND images_sysbuild_processed ${image})
    endif()
  endforeach()

  list(LENGTH images_sysbuild_processed processed_length)
  list(LENGTH IMAGES images_length)
endwhile()

foreach(image ${IMAGES})
  ExternalZephyrProject_Cmake(APPLICATION ${image})
endforeach()

# Temp implementation - start
# Run partition manager for each image before running CMake.

if(${BOARD} STREQUAL "nrf5340dk_nrf5340_cpuapp")
  # When using board nrf5340dk_nrf5340_cpuapp, then the board: nrf5340dk_nrf5340_cpunet
  # belongs to the CPUNET domain.
  set(nrf5340dk_nrf5340_cpunet_DOMAIN CPUNET)
endif()

include(${ZEPHYR_NRF_MODULE_DIR}/cmake/extensions.cmake)
include(${ZEPHYR_NRF_MODULE_DIR}/cmake/sysbuild/partition_manager.cmake OPTIONAL)

# Temp implementation - end
include(cmake/domains.cmake)

include(${ZEPHYR_NRF_MODULE_DIR}/cmake/fw_zip.cmake)

set(FW_BIN_FILES)
set(FW_LOAD_OFFSETS)
set(FW_FILE_NAMES)
foreach(image ${IMAGES})
  set(IMAGE_FW_BIN_FILE)
  set(IMAGE_FW_LOAD_OFFSET)
  sysbuild_get(IMAGE_FW_BIN_FILE IMAGE ${image} VAR PM_ZIP_FW_BIN_FILE CACHE)
  sysbuild_get(IMAGE_FW_LOAD_OFFSET IMAGE ${image} VAR PM_ZIP_FW_LOAD_OFFSET CACHE)
  list(APPEND FW_BIN_FILES ${IMAGE_FW_BIN_FILE})
  list(APPEND FW_LOAD_OFFSETS ${IMAGE_FW_LOAD_OFFSET})
  list(APPEND FW_FILE_NAMES ${image}.bin)

#Version needed
endforeach()

generate_dfu_zip(
  OUTPUT ${PROJECT_BINARY_DIR}/dfu_application.zip
  BIN_FILES ${FW_BIN_FILES}
  FILE_NAMES ${FW_FILE_NAMES}
  TYPE application
  SCRIPT_PARAMS ""
  )
#      SCRIPT_PARAMS ${generate_script_params}
