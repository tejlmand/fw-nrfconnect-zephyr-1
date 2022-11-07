# Copyright (c) 2022 Nordic Semiconductor
#
# SPDX-License-Identifier: Apache-2.0

# Include MCUboot if enabled.
if(SB_CONFIG_RADIO_HCI_RPMSG)
  ExternalZephyrProject_Add(
    APPLICATION ${SB_CONFIG_RADIO_HCI_RPMSG_NAME}
    SOURCE_DIR ${ZEPHYR_BASE}/samples/bluetooth/hci_rpmsg
    BOARD ${SB_CONFIG_RADIO_HCI_RPMSG_BOARD}
  )
  # MCUBoot default configuration is to perform a full chip erase.
  # Placing MCUBoot first in list to ensure it is flashed before other images.
  set(IMAGES ${IMAGES} "${SB_CONFIG_RADIO_HCI_RPMSG_NAME}" PARENT_SCOPE)
endif()
