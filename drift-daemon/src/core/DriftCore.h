#pragma once

#include <string>
#include <memory>

#include "utilities.h"
#include "Logger.h"
#include "DBusManager.h"
#include "SettingsManager.h"
#include "SessionManager.h"
#include "AppLauncher.h"
#include "ProcessManager.h"
#include "ThemeManager.h"
#include "WallpaperManager.h"

class DriftCore
{
public:
    DriftCore();
    ~DriftCore();
    void start();
    void stop();
    

private:
    
    bool coreRunning;
    
    std::string user;
    std::string homeDir;
    
    bool hyprlandSession;
    std::string xdgRuntimeDir;
    std::string xdgCurrentDesktop;
    std::string waylandDisplay;


    std::unique_ptr<SettingsManager> settingsManager;
    std::unique_ptr<Logger> logger;
    std::unique_ptr<SessionManager> sessionManager;
    std::unique_ptr<DBusManager> dBusManager;
    std::unique_ptr<ProcessManager> processManager;
    std::unique_ptr<ThemeManager> themeManager;
    std::unique_ptr<WallpaperManager> wallpaperManager;

    void core();
    void getSystemInfo();
};