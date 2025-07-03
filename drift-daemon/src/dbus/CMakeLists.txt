add_library(dbus
    DBusManager.cpp
    DBusManager.h
)
target_include_directories(dbus
    PUBLIC 
        ${CMAKE_CURRENT_SOURCE_DIR}
        ${PROJECT_SOURCE_DIR}/src/utils
        ${PROJECT_SOURCE_DIR}/src/driftModule
)

target_link_libraries(dbus 
    PUBLIC 
        utils
        driftModule
)