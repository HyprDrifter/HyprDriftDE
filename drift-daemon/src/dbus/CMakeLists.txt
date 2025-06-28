add_library(dbus
    DBusManager.cpp
    DBusManager.h
)
target_include_directories(dbus
    PUBLIC 
        ${CMAKE_CURRENT_SOURCE_DIR}
        ${PROJECT_SOURCE_DIR}/src/utils
)

target_link_libraries(dbus 
    PUBLIC 
        utils
)