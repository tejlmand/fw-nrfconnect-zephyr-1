# Copyright (c) 2022 Nordic Semiconductor
#
# SPDX-License-Identifier: Apache-2.0

# Include MCUboot if enabled.
if(SB_CONFIG_BOOTLOADER_MCUBOOT)
  ExternalZephyrProject_Add(
    APPLICATION mcuboot
    SOURCE_DIR ${ZEPHYR_MCUBOOT_MODULE_DIR}/boot/zephyr/
  )
  # MCUBoot default configuration is to perform a full chip erase.
  # Placing MCUBoot first in list to ensure it is flashed before other images.
  set(IMAGES "mcuboot" ${IMAGES} PARENT_SCOPE)
endif()

# Temp implementation - start
# This code provides the possibility of applying Kconfig fragments to images
# when secure boot is enabled. Temporary use the existing nRF Connect SDK scheme
# until a more proper scheme is developed uypstream.

# Add an overlay file to an image.
# This can be used by sysbuild to set overlay of Kconfig configuration or devicetree
# in its images.
#
# Parameters:
#   'image' - image name
#   'overlay_file' - overlay to be added to  image
#   'overlay_type' - 'OVERLAY_CONFIG' or 'DTC_OVERLAY_FILE'
function(add_overlay image overlay_file overlay_type)
  set(old_overlays ${${image}_${overlay_type}})
  string(FIND "${old_overlays}" "${overlay_file}" found)
  if (${found} EQUAL -1)
    set(${image}_${overlay_type} "${old_overlays};${overlay_file}" CACHE STRING
      "Extra config fragments for ${image} image" FORCE
    )
  endif()
endfunction()

# Convenience macro to add configuration overlays to image.
macro(add_overlay_config image overlay_file)
  add_overlay(${image} ${overlay_file} OVERLAY_CONFIG)
endmacro()

# Convenience macro to add device tree overlays to image.
macro(add_overlay_dts image overlay_file)
  add_overlay(${image} ${overlay_file} DTC_OVERLAY_FILE)
endmacro()

if(SB_CONFIG_BOOTLOADER_MCUBOOT)
  add_overlay_config(
    mcuboot
     ${ZEPHYR_NRF_MODULE_DIR}/subsys/partition_manager/ext_flash_mcuboot_secondary.conf
  )
endif()


if(SB_CONFIG_SECURE_BOOT)
  add_overlay_config(
    ${SB_CONFIG_RADIO_HCI_RPMSG_NAME} # ToDo: Create a common Kconfig setting
                                      # which can then default to the exact
                                      # remote image selected, as to work for
                                      # hci, mpsl, thread, etc.
    "${ZEPHYR_NRF_MODULE_DIR}/subsys/bootloader/image/secure_boot.conf"
  )

  add_overlay_config(
    mcuboot
    "${ZEPHYR_NRF_MODULE_DIR}/subsys/pcd/pcd.conf"
  )
endif()

# Temp implementation - end
