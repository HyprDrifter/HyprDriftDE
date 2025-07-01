add_library(apps
    AppLauncher.cpp
    AppLauncher.h
)
target_include_directories(apps 
    PUBLIC 
        ${CMAKE_CURRENT_SOURCE_DIR}
        ${PROJECT_SOURCE_DIR}/src/utils
        ${PROJECT_SOURCE_DIR}/src/driftModule
)

target_link_libraries(apps 
    PUBLIC 
        utils
        driftModule
)
