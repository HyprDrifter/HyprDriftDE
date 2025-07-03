#pragma once

#include <string>
#include <vector>

#include "DriftModule.h"

class Logger;
class DBusManager;
class SettingsManager;
class SessionManager;
class AppLauncher;
class WallpaperManager;
class ProcessManager;
class ThemeManager;

class DriftCore : public DriftModule
{
    Q_OBJECT

public:
    DriftCore();
    ~DriftCore() override;

    bool coreRunning;
    void start();
    void stop();

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
    DriftModule* getModulePointer(const std::string& name);

    void startModule(const std::string& moduleName);
    void stopModule(const std::string& moduleName);
    void restartModule(const std::string& moduleName);

signals:
    void startModules();
    void stopModules();
    void restartModules();
};