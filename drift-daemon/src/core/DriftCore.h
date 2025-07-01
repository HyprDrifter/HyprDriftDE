#pragma once

#include <string>
#include <memory>
#include <list>

#include "utilities.h"
#include "Logger.h"
#include "DBusManager.h"
#include "SettingsManager.h"
#include "SessionManager.h"
#include "AppLauncher.h"
#include "ProcessManager.h"
#include "ThemeManager.h"
#include "WallpaperManager.h"
#include "DriftModule.h"

class DriftCore : public DriftModule
{
public:
    DriftCore();
    ~DriftCore() override;

    bool coreRunning;
    void start();
    void stop();
    void restartModule(std::string moduleName);
    
    

private:
    
    
    std::string user;
    std::string homeDir;
    
    bool hyprlandSession;
    std::string xdgRuntimeDir;
    std::string xdgCurrentDesktop;
    std::string waylandDisplay;


    // Raw pointers
    SettingsManager* settingsManager;
    Logger* logger;
    SessionManager* sessionManager;
    DBusManager* dBusManager;
    ProcessManager* processManager;
    ThemeManager* themeManager;
    WallpaperManager* wallpaperManager;

    std::vector<std::unique_ptr<DriftModule>> modules;

    void core();
    void getSystemInfo();

    DriftModule& getModule(std::string name);
};