add_library(settings
    SettingsManager.cpp
    SettingsManager.h
)
target_include_directories(settings
    PUBLIC 
        ${CMAKE_CURRENT_SOURCE_DIR}
        ${PROJECT_SOURCE_DIR}/src/utils
        ${PROJECT_SOURCE_DIR}/src/driftModule
)

target_link_libraries(settings 
    PUBLIC 
        driftModule
        utils
        yaml-cpp
)