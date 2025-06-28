add_library(apps
    AppLauncher.cpp
    AppLauncher.h
)
target_include_directories(apps PUBLIC ${CMAKE_CURRENT_SOURCE_DIR})
