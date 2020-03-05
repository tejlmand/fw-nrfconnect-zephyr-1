# SPDX-License-Identifier: Apache-2.0

# This file provides Zephyr Config Package functionality.
#
# The purpose of this files it to allow users to decide if the want to:
# - Use ZEPHYR_BASE environment setting for explicitly set select a zephyr installation
# - Support automatic Zephyr installation lookup through the use of find_package(ZEPHYR)

# First check to see if user has provided a Zephyr base manually.
# Set Zephyr base to environment setting.
# It will be empty if not set in environment.

include(${CMAKE_CURRENT_LIST_DIR}/zephyr_package_search.cmake)

macro(include_boilerplate location)
  set(Zephyr_FOUND True)
  if(NOT NO_BOILERPLATE)
    message("Including boilerplate (${location}): ${ZEPHYR_BASE}/cmake/app/boilerplate.cmake")
    include(${ZEPHYR_BASE}/cmake/app/boilerplate.cmake NO_POLICY_SCOPE)
  endif()
endmacro()

set(ZEPHYR_BASE $ENV{ZEPHYR_BASE})

if (ZEPHYR_BASE)
  # Get rid of any double folder string before comparison, as example, user provides
  # ZEPHYR_BASE=//path/to//zephyr_base/
  # must also work.
  get_filename_component(ZEPHYR_BASE ${ZEPHYR_BASE} ABSOLUTE)

  include_boilerplate("zephyr base")
  return()
endif()

# If ZEPHYR_CANDIDATE is set, it means this file was include instead of called via find_package directly.
if(ZEPHYR_CANDIDATE)
  set(IS_INCLUDED TRUE)
endif()

# Find out the current Zephyr base.
get_filename_component(CURRENT_ZEPHYR_DIR ${CMAKE_CURRENT_LIST_FILE}/${ZEPHYR_RELATIVE_DIR} ABSOLUTE)
get_filename_component(PROJECT_WORKTREE_DIR ${CMAKE_CURRENT_LIST_FILE}/${PROJECT_WORKTREE_RELATIVE_DIR} ABSOLUTE)

string(FIND "${CMAKE_CURRENT_SOURCE_DIR}" "${CURRENT_ZEPHYR_DIR}/" COMMON_INDEX)
if (COMMON_INDEX EQUAL 0)
  # Project is in-zephyr-tree.
  # We are in Zephyr tree.
  set(ZEPHYR_BASE ${CURRENT_ZEPHYR_DIR})
  include_boilerplate("in-zephyr-tree")
  return()
endif()

if(IS_INCLUDED)
  # A higher level did the checking and included us and as we are not in-zephyr-tree (checked above)
  # then we must be in work-tree.
  set(ZEPHYR_BASE ${CURRENT_ZEPHYR_DIR})
  include_boilerplate("in-work-tree")
endif()

if(NOT IS_INCLUDED)
  string(FIND "${CMAKE_CURRENT_SOURCE_DIR}" "${PROJECT_WORKTREE_DIR}/" COMMON_INDEX)
  if (COMMON_INDEX EQUAL 0)
    # Project is in-project-worktree-tree.
    # This means this Zephyr is likely the correct one, but there could be an alternative installed along-side
    # Thus, check if there is an even better candidate.

    check_zephyr_package(PROJECT_WORKTREE_DIR ${PROJECT_WORKTREE_DIR})

    # We are the best candidate, so let's include boiler plate.
    set(ZEPHYR_BASE ${CURRENT_ZEPHYR_DIR})
    include_boilerplate("in-work-tree")
    return()
  endif()

  check_zephyr_package(SEARCH_PARENTS)

  # Ending here means there were no candidates in-tree of the app.
  # Thus, the app is build oot.
  # CMake find_package has already done the version checking, so let's just include boiler plate.
  # Previous find_package would have cleared Zephyr_FOUND variable, thus set it again.
  set(ZEPHYR_BASE ${CURRENT_ZEPHYR_DIR})
  include_boilerplate("out-of-worktree")
endif()
