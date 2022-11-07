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

  # Can we do this in a more clever way ?
  # Should adding of hci_rpmasg be a downstream feature, or could we perhaps
  # overload upstream image adding.
  if(NOT "${SB_CONFIG_RADIO_HCI_RPMSG_DOMAIN}" IN_LIST PM_DOMAINS)
    set(PM_DOMAINS ${PM_DOMAINS} ${SB_CONFIG_RADIO_HCI_RPMSG_DOMAIN} PARENT_SCOPE)
  endif()
  set(PM_${SB_CONFIG_RADIO_HCI_RPMSG_DOMAIN}_IMAGES
      ${PM_${SB_CONFIG_RADIO_HCI_RPMSG_DOMAIN}_IMAGES}
      "${SB_CONFIG_RADIO_HCI_RPMSG_NAME}" PARENT_SCOPE
  )

  if(SB_CONFIG_RADIO_HCI_RPMSG_DOMAIN_APP)
    set(DOMAIN_APP_${SB_CONFIG_RADIO_HCI_RPMSG_DOMAIN} "${SB_CONFIG_RADIO_HCI_RPMSG_NAME}" PARENT_SCOPE)
  endif()
endif()
