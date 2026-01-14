cmake_minimum_required(VERSION 3.15)

project(BloodConnectNative LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

set(SOURCES
    "${CMAKE_CURRENT_SOURCE_DIR}/src/main.cpp"
    "${CMAKE_CURRENT_SOURCE_DIR}/src/utils.cpp"
    "${CMAKE_CURRENT_SOURCE_DIR}/src/firestore_bridge.cpp"
    "${CMAKE_CURRENT_SOURCE_DIR}/src/notification_helper.cpp"
)

# Fail early if any source is missing.
foreach(_src IN LISTS SOURCES)
  if(NOT EXISTS "${_src}")
    message(FATAL_ERROR "Missing source file: ${_src}")
  endif()
endforeach()

add_executable(BloodConnectNative ${SOURCES})

target_include_directories(BloodConnectNative PRIVATE include)

if (MSVC)
    target_compile_options(BloodConnectNative PRIVATE /W4)
else()
    target_compile_options(BloodConnectNative PRIVATE -Wall -Wextra -pedantic)
endif()

install(TARGETS BloodConnectNative DESTINATION bin)