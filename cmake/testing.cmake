# Copyright (c) 2015, 2016, Oracle and/or its affiliates. All rights reserved.
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; version 2 of the License.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA  02110-1301  USA

set(_TEST_RUNTIME_DIR ${CMAKE_BINARY_DIR}/tests)
set(STAGE_DIR ${CMAKE_BINARY_DIR}/stage CACHE INTERNAL "STAGE_DIR")

# Set {RUNTIME,LIBRARY}_OUTPUT_DIRECTORY properties of a target to the stage dir.
# On unix platforms this is just one directory, but on Windows it's per build-type,
# e.g. build/stage/Debug/lib, build/stage/Release/lib, etc
function(set_target_output_directory target target_output_directory dirname)
  if(WIN32)
    foreach(config_ ${CMAKE_CONFIGURATION_TYPES})
      string(TOUPPER ${config_} config__)
      set_property(TARGET ${target} PROPERTY
        ${target_output_directory}_${config__} ${STAGE_DIR}/${config_}/${dirname})
    endforeach()
  else()
    set_property(TARGET ${target} PROPERTY
      ${target_output_directory} ${STAGE_DIR}/${dirname})
  endif()
endfunction()

# Prepare staging area
foreach(dir etc;run;log;bin;lib)
  if(WIN32)
    foreach(config_ ${CMAKE_CONFIGURATION_TYPES})
      file(MAKE_DIRECTORY ${STAGE_DIR}/${config_}/${dir})
    endforeach()
  else()
    file(MAKE_DIRECTORY ${STAGE_DIR}/${dir})
  endif()
endforeach()

function(ADD_TEST_FILE FILE)
  set(one_value_args MODULE LABEL ENVIRONMENT)
  set(multi_value_args LIB_DEPENDS INCLUDE_DIRS)
  cmake_parse_arguments(TEST "" "${one_value_args}" "${multi_value_args}" ${ARGN})

  if(NOT TEST_MODULE)
    message(FATAL_ERROR "Module name missing for test file ${FILE}")
  endif()

  get_filename_component(test_ext ${FILE} EXT)
  get_filename_component(runtime_dir ${FILE} PATH)  # Not using DIRECTORY because of CMake >=2.8.11 requirement

  set(runtime_dir ${CMAKE_BINARY_DIR}/tests/${TEST_MODULE})

  if(test_ext STREQUAL ".cc")
    # Tests written in C++
    get_filename_component(test_target ${FILE} NAME_WE)
    string(REGEX REPLACE "^test_" "" test_target ${test_target})
    set(test_target "test_${TEST_MODULE}_${test_target}")
    set(test_name "tests/${TEST_MODULE}/${test_target}")
    add_executable(${test_target} ${FILE})
    target_link_libraries(${test_target}
      gtest gtest_main gmock gmock_main routertest_helpers
      router_lib harness-library
      ${CMAKE_THREAD_LIBS_INIT})
    foreach(libtarget ${TEST_LIB_DEPENDS})
      #add_dependencies(${test_target} ${libtarget})
      target_link_libraries(${test_target} ${libtarget})
    endforeach()
    foreach(include_dir ${TEST_INCLUDE_DIRS})
      target_include_directories(${test_target} PUBLIC ${include_dir})
    endforeach()
    set_target_properties(${test_target}
      PROPERTIES
      RUNTIME_OUTPUT_DIRECTORY ${runtime_dir}/)
    add_test(NAME ${test_name}
      COMMAND ${runtime_dir}/${test_target})
    if(WIN32)
      set_tests_properties(${test_name} PROPERTIES
        ENVIRONMENT
          "STAGE_DIR=${STAGE_DIR};CMAKE_SOURCE_DIR=${CMAKE_SOURCE_DIR};CMAKE_BINARY_DIR=${CMAKE_BINARY_DIR};PATH=${CMAKE_BINARY_DIR}\\stage\\$<CONFIG>\\lib\;${CMAKE_BINARY_DIR}\\stage\\$<CONFIG>\\bin\;$ENV{PATH};${TEST_ENVIRONMENT}")
    else()
      set_tests_properties(${test_name} PROPERTIES
        ENVIRONMENT
          "STAGE_DIR=${STAGE_DIR};CMAKE_SOURCE_DIR=${CMAKE_SOURCE_DIR};CMAKE_BINARY_DIR=${CMAKE_BINARY_DIR};LD_LIBRARY_PATH=$ENV{LD_LIBRARY_PATH};DYLD_LIBRARY_PATH=$ENV{DYLD_LIBRARY_PATH};${TEST_ENVIRONMENT}")
    endif()
  else()
    message(ERROR "Unknown test type; file '${FILE}'")
  endif()

endfunction(ADD_TEST_FILE)

function(ADD_TEST_DIR DIR_NAME)
  set(one_value_args MODULE ENVIRONMENT)
  set(multi_value_args LIB_DEPENDS INCLUDE_DIRS)
  cmake_parse_arguments(TEST "" "${one_value_args}" "${multi_value_args}" ${ARGN})

  if(NOT TEST_MODULE)
    message(FATAL_ERROR "Module name missing for test folder ${DIR_NAME}")
  endif()

  get_filename_component(abs_path ${DIR_NAME} ABSOLUTE)

  file(GLOB test_files RELATIVE ${abs_path}
    ${abs_path}/*.cc)

  foreach(test_file ${test_files})
    if(NOT ${test_file} MATCHES "^helper")
      ADD_TEST_FILE(${abs_path}/${test_file}
        MODULE ${TEST_MODULE}
        ENVIRONMENT ${TEST_ENVIRONMENT}
        LIB_DEPENDS ${TEST_LIB_DEPENDS}
        INCLUDE_DIRS ${TEST_INCLUDE_DIRS}
        )
    endif()
  endforeach(test_file)

endfunction(ADD_TEST_DIR)
