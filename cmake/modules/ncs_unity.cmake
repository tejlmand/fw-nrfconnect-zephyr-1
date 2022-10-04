#
# Copyright (c) 2019 Nordic Semiconductor
#
# SPDX-License-Identifier: LicenseRef-Nordic-5-Clause
#

include(west)
include(zephyr_module)
include(unittest)

set(NRF_DIR ${ZEPHYR_NRF_MODULE_DIR})

set_property(GLOBAL PROPERTY CMOCK_DIR ${ZEPHYR_BASE}/../test/cmock)
get_property(CMOCK_DIR GLOBAL PROPERTY CMOCK_DIR)
set(UNITY_CONFIG_FILE ${NRF_DIR}/tests/unity/unity_cfg.yaml CACHE STRING "")

find_program(
  RUBY_EXECUTABLE
  ruby
)
if(${RUBY_EXECUTABLE} STREQUAL RUBY_EXECUTABLE-NOTFOUND)
  message(FATAL_ERROR "Unable to find ruby")
endif()

target_include_directories(testbinary PUBLIC
	${CMOCK_DIR}/vendor/unity/src
	${CMOCK_DIR}/src
        ${NRF_DIR}/tests/unity
)

target_sources(testbinary PRIVATE
	${CMOCK_DIR}/vendor/unity/src/unity.c
	${CMOCK_DIR}/src/cmock.c
)

target_sources(testbinary PRIVATE ${NRF_DIR}/tests/unity/src/generic_teardown.c)
target_compile_definitions(testbinary PUBLIC UNITY_INCLUDE_CONFIG_H)

# Generate test runner file.
function(test_runner_generate test_file_path)
  get_property(CMOCK_DIR GLOBAL PROPERTY CMOCK_DIR)
  set(UNITY_PRODUCTS_DIR ${APPLICATION_BINARY_DIR}/runner)
  file(MAKE_DIRECTORY "${UNITY_PRODUCTS_DIR}")
  get_filename_component(test_file_name "${test_file_path}" NAME)
  set(output_file "${UNITY_PRODUCTS_DIR}/runner_${test_file_name}")

  add_custom_command(
    COMMAND ${RUBY_EXECUTABLE}
    ${CMOCK_DIR}/vendor/unity/auto/generate_test_runner.rb
    ${UNITY_CONFIG_FILE}
    ${test_file_path} ${output_file}
    DEPENDS ${test_file_path} ${UNITY_CONFIG_FILE}
    OUTPUT ${output_file}
    WORKING_DIRECTORY ${PROJECT_SOURCE_DIR}
  )

  target_sources(testbinary PRIVATE ${output_file})

  message(STATUS "Generating test runner ${output_file}")
endfunction()

# Generate cmock for provided header file.
function(cmock_generate header_path dst_path)
  get_property(CMOCK_DIR GLOBAL PROPERTY CMOCK_DIR)
  set(MOCK_PREFIX mock_)

  get_filename_component(file_name "${header_path}" NAME_WE)
  set(MOCK_FILE ${dst_path}/${MOCK_PREFIX}${file_name}.c)

  file(MAKE_DIRECTORY "${dst_path}")

  add_custom_command(OUTPUT ${MOCK_FILE}
    COMMAND ${RUBY_EXECUTABLE}
    ${CMOCK_DIR}/lib/cmock.rb
    --mock_prefix=${MOCK_PREFIX}
    --mock_path=${dst_path}
    -o${UNITY_CONFIG_FILE}
    ${header_path}
    DEPENDS ${header_path} ${UNITY_CONFIG_FILE}
    WORKING_DIRECTORY ${PROJECT_SOURCE_DIR}
  )

  target_sources(testbinary PRIVATE ${MOCK_FILE})
endfunction()

# Add --wrap linker option for each function listed in the input file.
function(cmock_linker_trick func_name_path)
  file(STRINGS ${func_name_path} contents)
  if (contents)
    set(linker_str "-Wl")
  endif()
  foreach(src ${contents})
    set(linker_str "${linker_str},--wrap=${src}")
  endforeach()
#  zephyr_link_libraries(${linker_str})
  target_link_libraries(testbinary PUBLIC ${linker_string})
endfunction()


# Handle wrapping functions from mocked file.
# Function takes header file and generates a file containing list of functions.
# File is then passed to 'cmock_linker_trick' which adds linker option for each
# function listed in the file.
function(cmock_linker_wrap_trick header_file_path)
  set(flist_file "${header_file_path}.flist")

  execute_process(
    COMMAND
    ${PYTHON_EXECUTABLE}
    ${NRF_DIR}/scripts/unity/func_name_list.py
    --input ${header_file_path}
    --output ${flist_file}
    WORKING_DIRECTORY ${PROJECT_SOURCE_DIR}
    RESULT_VARIABLE op_result
    OUTPUT_VARIABLE output_result
  )

  if (NOT ${op_result} EQUAL 0)
    message(SEND_ERROR "${output_result}")
    message(FATAL_ERROR "Failed to parse header ${header_file_path}")
  endif()
  cmock_linker_trick(${flist_file})
endfunction()

# Function takes original header and prepares two version
# - version with system calls removed and static inline functions
#   converted to standard function declarations
# - version with addtional __wrap_ prefix for all functions that
#   is used to generate cmock
function(cmock_headers_prepare in_header out_header wrap_header)
  execute_process(
    COMMAND
    ${PYTHON_EXECUTABLE}
    ${NRF_DIR}/scripts/unity/header_prepare.py
    "--input" ${in_header}
    "--output" ${out_header}
    "--wrap" ${wrap_header}
    WORKING_DIRECTORY ${PROJECT_SOURCE_DIR}
    RESULT_VARIABLE op_result
    OUTPUT_VARIABLE output_result
  )

  if (NOT ${op_result} EQUAL 0)
    message(SEND_ERROR "${output_result}")
    message(FATAL_ERROR "Failed to parse header ${in_header}")
  endif()
endfunction()

#function for handling usage of mock
#optional second argument can contain offset that include should be placed in
#for example if file under test is include mocked header as <foo/header.h> then
# mock and replaced header should be placed in <mock_path>/foo with <mock_path>
# added as include path.
function(cmock_handle header_file)
  get_property(CMOCK_DIR GLOBAL PROPERTY CMOCK_DIR)
  set(CMOCK_PRODUCTS_DIR ${APPLICATION_BINARY_DIR}/mocks)

  #get optional offset macro
  set (extra_macro_args ${ARGN})
  list(LENGTH extra_macro_args num_extra_args)
  if (${num_extra_args} EQUAL 1)
    list(GET extra_macro_args 0 optional_offset)
    set(dst_path "${CMOCK_PRODUCTS_DIR}/${optional_offset}")
  else()
    set(dst_path "${CMOCK_PRODUCTS_DIR}")
  endif()

  file(MAKE_DIRECTORY "${dst_path}/internal")

  get_filename_component(header_name "${header_file}" NAME)
  set(mod_header_path "${dst_path}/${header_name}")
  set(wrap_header "${dst_path}/internal/${header_name}")

  cmock_headers_prepare(${header_file} ${mod_header_path} ${wrap_header})
  cmock_generate(${wrap_header} ${dst_path})

  cmock_linker_wrap_trick(${mod_header_path})

  target_include_directories(testbinary BEFORE PRIVATE ${CMOCK_PRODUCTS_DIR})
  message(STATUS "Generating cmock for header ${header_file}")
endfunction()
