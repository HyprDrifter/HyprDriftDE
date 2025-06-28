add_library(wallpaper
    WallpaperManager.cpp
    WallpaperManager.h
)
target_include_directories(wallpaper
    PUBLIC 
        ${CMAKE_CURRENT_SOURCE_DIR}
        ${PROJECT_SOURCE_DIR}/src/utils
)

target_link_libraries(wallpaper 
    PUBLIC 
        utils
)