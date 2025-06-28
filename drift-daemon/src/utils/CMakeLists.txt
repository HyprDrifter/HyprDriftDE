add_library(utils
    utilities.cpp
    utilities.h
)
target_include_directories(utils 
    PUBLIC 
        ${CMAKE_CURRENT_SOURCE_DIR}
)

target_link_libraries(utils 
    PUBLIC 
)