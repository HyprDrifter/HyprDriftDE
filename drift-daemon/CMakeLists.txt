cmake_minimum_required(VERSION 3.15)
project(drift-daemon VERSION 0.1 LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 23)
set(CMAKE_CXX_STANDARD_REQUIRED ON)


# Qt
find_package(Qt6 REQUIRED COMPONENTS Core)

set(CMAKE_AUTOMOC ON)
set(CMAKE_AUTORCC ON)
set(CMAKE_AUTOUIC ON)

# YAML-CPP
include(FetchContent)
FetchContent_Declare(
  yaml-cpp
  GIT_REPOSITORY https://github.com/jbeder/yaml-cpp.git
  GIT_TAG master
)
FetchContent_MakeAvailable(yaml-cpp)

# Add subdirectories
add_subdirectory(src/core)
add_subdirectory(src/driftModule)
add_subdirectory(src/utils)
add_subdirectory(src/dbus)
add_subdirectory(src/settings)
add_subdirectory(src/logging)
add_subdirectory(src/theme)
add_subdirectory(src/process)
add_subdirectory(src/session)
add_subdirectory(src/apps)
add_subdirectory(src/wallpaper)


# Main executable
add_executable(drift-daemon
    src/main.cpp
)

# Link modules
target_link_libraries(drift-daemon
    PRIVATE
        core
        driftModule
        util
        dbus
        settings
        logging
        theme
        process
        session
        apps
        wallpaper
        Qt6::Core
)
