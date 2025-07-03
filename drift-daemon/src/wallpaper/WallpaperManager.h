#pragma once

#include <string>

#include "utilities.h"
#include "DriftModule.h"

class WallpaperManager : public DriftModule
{
private:
    /* data */
public:
    WallpaperManager(/* args */);
    ~WallpaperManager() override;
    void start();
    void stop();
    void restart();
};

