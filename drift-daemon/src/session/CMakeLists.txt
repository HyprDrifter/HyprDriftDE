add_library(session
    SessionManager.cpp
    SessionManager.h
)
target_include_directories(session
    PUBLIC 
        ${CMAKE_CURRENT_SOURCE_DIR}
        ${PROJECT_SOURCE_DIR}/src/utils
        ${PROJECT_SOURCE_DIR}/src/driftModule
)

target_link_libraries(session 
    PUBLIC 
        utils
        driftModule
)