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

option(ENABLE_COVERAGE "Enable code coverage support")

set(GCOV_BASE_DIR ${CMAKE_BINARY_DIR}/coverage CACHE PATH
  "GCov coverage base directory")
set(GCOV_HTML_DIR ${GCOV_BASE_DIR}/html CACHE PATH
  "GCov HTML report output directory")
set(GCOV_INFO_FILE ${GCOV_BASE_DIR}/coverage.info CACHE FILEPATH
  "GCov information file name")

set(LCOV_FLAGS -b ${CMAKE_BINARY_DIR} -d ${CMAKE_SOURCE_DIR} -q)

include(TextUtils)

if(ENABLE_COVERAGE)
  if(CMAKE_COMPILER_IS_GNUCXX)
    find_program(GCOV gcov)
    find_program(LCOV lcov)
    find_program(GENHTML genhtml)
    if(NOT (LCOV AND GCOV AND GENHTML))
      set(_programs)
      if(NOT LCOV)
        list(APPEND _programs "'lcov'")
      endif()
      if(NOT GCOV)
        list(APPEND _programs "'gcov'")
      endif()
      if(NOT GENHTML)
        list(APPEND _programs "'genhtml'")
      endif()
      oxford_comma(_text ${_programs})
      message(FATAL_ERROR "Could not find ${_text}, please install.")
    endif()
    add_definitions(-fprofile-arcs -ftest-coverage)
    link_libraries(gcov)

    message(STATUS "Building with coverage information")
    message(STATUS "Target coverage-clear added to clear coverage information")
    message(STATUS "Target coverage-html added to generate HTML report")
    add_custom_target(coverage-clear
      COMMAND ${LCOV} ${LCOV_FLAGS} -z
      COMMENT "Clearing coverage information")
    add_custom_target(coverage-info
      COMMAND ${CMAKE_COMMAND} -E make_directory ${GCOV_BASE_DIR}
      COMMAND ${LCOV} ${LCOV_FLAGS} -o ${GCOV_INFO_FILE} -c
      COMMAND ${LCOV} ${LCOV_FLAGS} -o ${GCOV_INFO_FILE} -r ${GCOV_INFO_FILE}
          '/usr/include/*' 'ext/gmock/*' 'ext/gtest/*' '*/tests/*'
      COMMENT "Generating coverage info file ${GCOV_INFO_FILE}")
    add_custom_target(coverage-html
      DEPENDS coverage-info
      COMMAND ${CMAKE_COMMAND} -E make_directory ${GCOV_HTML_DIR}
      COMMAND ${GENHTML} -o ${GCOV_HTML_DIR} ${GCOV_INFO_FILE}
      COMMENT "Generating HTML report on coverage in ${GCOV_HTML_DIR}")
  else()
    message(FATAL_ERROR "Not able to generate coverage for ${CMAKE_CXX_COMPILER}")
  endif()
endif()
