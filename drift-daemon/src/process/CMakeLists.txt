add_library(process
    ProcessManager.cpp
    ProcessManager.h
)
target_include_directories(process
    PUBLIC 
        ${CMAKE_CURRENT_SOURCE_DIR}
        ${PROJECT_SOURCE_DIR}/src/utils
        ${PROJECT_SOURCE_DIR}/src/driftModule
)

target_link_libraries(process 
    PUBLIC 
        utils
        driftModule
)