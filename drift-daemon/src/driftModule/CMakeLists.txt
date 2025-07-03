add_library(driftModule
    DriftModule.cpp
    DriftModule.h
)

target_include_directories(driftModule 
    PUBLIC 
        ${CMAKE_CURRENT_SOURCE_DIR}
)

target_link_libraries(driftModule 
    PUBLIC 
        Qt6::Core
)

# Enable Qt MOC if needed
set_target_properties(driftModule PROPERTIES AUTOMOC ON)