#include <string>
#include <iostream>
#include <fstream>
#include <filesystem>


#include "utilities.h"
#include "WallpaperManager.h"
#include "DriftModule.h"

WallpaperManager::WallpaperManager(/* args */)
{
    moduleName = "Wallpaper Manager";
    threaded = true;
}

WallpaperManager::~WallpaperManager()
{
}

void WallpaperManager::start()
{
    enabled = true;
    
    running = true;
    emit started(QString::fromStdString(moduleName));
}

void WallpaperManager::stop()
{
    writeLine(moduleName + " Stoped");
}

void WallpaperManager::restart()
{
    stop();
    start();
}

