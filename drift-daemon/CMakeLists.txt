cmake_minimum_required(VERSION 3.15)
project(drift-daemon VERSION 0.1 LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 23)
set(CMAKE_CXX_STANDARD_REQUIRED ON)


add_executable(drift-daemon 
    src/main.cpp
    src/utilities.cpp
    src/DriftCore.cpp
    src/Logger.cpp
)

find_package(Qt6 REQUIRED COMPONENTS Core)
target_link_libraries(drift-daemon PRIVATE Qt6::Core)