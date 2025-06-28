add_library(logging
    Logger.cpp
    Logger.h
)
target_include_directories(logging
    PUBLIC 
        ${CMAKE_CURRENT_SOURCE_DIR}
        ${PROJECT_SOURCE_DIR}/src/utils
)

target_link_libraries(logging 
    PUBLIC 
        utils
)