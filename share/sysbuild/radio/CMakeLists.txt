# Copyright (c) 2022 Nordic Semiconductor
#
# SPDX-License-Identifier: Apache-2.0

# Include MCUboot if enabled.
if(SB_CONFIG_RADIO_HCI_RPMSG)
  ExternalZephyrProject_Add(
    APPLICATION hci_rpmsg
    SOURCE_DIR ${ZEPHYR_BASE}/samples/bluetooth/hci_rpmsg
    BOARD nrf5340dk_nrf5340_cpunet
  )
  # MCUBoot default configuration is to perform a full chip erase.
  # Placing MCUBoot first in list to ensure it is flashed before other images.
  set(IMAGES ${IMAGES} "hci_rpmsg" PARENT_SCOPE)
endif()
