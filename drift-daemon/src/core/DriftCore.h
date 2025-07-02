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
    Q_OBJECT

public:
    DriftCore();
    ~DriftCore() override;

    bool coreRunning;
    void start();
    void stop();
    void restartModule(const std::string& moduleName);

public slots:
    void moduleStarted(const QString& name);

private:
    
    
    std::string user;
    std::string homeDir;
    
    bool hyprlandSession;
    std::string xdgRuntimeDir;
    std::string xdgCurrentDesktop;
    std::string waylandDisplay;

    bool starting = true;

    // Raw pointers
    SettingsManager* settingsManager;
    Logger* logger;
    SessionManager* sessionManager;
    DBusManager* dBusManager;
    ProcessManager* processManager;
    ThemeManager* themeManager;
    WallpaperManager* wallpaperManager;
    AppLauncher* appLauncher;

    std::vector<std::unique_ptr<DriftModule>> modules;
    std::vector<DriftModule*> moduleStartupQueue;

    template<typename T>
    T* registerModule(std::vector<std::unique_ptr<DriftModule>>& vec);

    void core();
    void getSystemInfo();
    std::string getEnvVariable(const char* varName);

    DriftModule& getModule(const std::string& name);

signals:
    void startModules();
};