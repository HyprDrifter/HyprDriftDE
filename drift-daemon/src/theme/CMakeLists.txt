add_library(theme
    ThemeManager.cpp
    ThemeManager.h
)
target_include_directories(theme PUBLIC
    PUBLIC 
        ${CMAKE_CURRENT_SOURCE_DIR}
        ${PROJECT_SOURCE_DIR}/src/utils
        ${PROJECT_SOURCE_DIR}/src/driftModule
)

target_link_libraries(theme 
    PUBLIC 
        utils
        driftModule
)