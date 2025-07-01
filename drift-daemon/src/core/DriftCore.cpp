#include <string>
#include <iostream>
#include <memory>
#include <QCoreApplication>
#include <cstdlib>
#include <pwd.h>
#include <unistd.h>
#include <list>

#include "utilities.h"
#include "DriftCore.h"
#include "Logger.h"
#include "DBusManager.h"
#include "SettingsManager.h"
#include "SessionManager.h"
#include "AppLauncher.h"
#include "WallpaperManager.h"
#include "DriftModule.h"

DriftCore::DriftCore(/* args */)
{
    coreRunning = false;

    auto settingsManager_u = std::make_unique<SettingsManager>();
    auto logger_u = std::make_unique<Logger>();
    auto sessionManager_u = std::make_unique<SessionManager>();
    auto dBusManager_u = std::make_unique<DBusManager>();
    auto processManager_u = std::make_unique<ProcessManager>();
    auto themeManager_u = std::make_unique<ThemeManager>();
    auto wallpaperManager_u = std::make_unique<WallpaperManager>();

    // Raw pointers for access
    settingsManager = settingsManager_u.get();
    logger = logger_u.get();
    sessionManager = sessionManager_u.get();
    dBusManager = dBusManager_u.get();
    processManager = processManager_u.get();
    themeManager = themeManager_u.get();
    wallpaperManager = wallpaperManager_u.get();

    // Store in polymorphic module list
    modules.emplace_back(std::move(settingsManager_u));
    modules.emplace_back(std::move(logger_u));
    modules.emplace_back(std::move(sessionManager_u));
    modules.emplace_back(std::move(dBusManager_u));
    modules.emplace_back(std::move(processManager_u));
    modules.emplace_back(std::move(themeManager_u));
    modules.emplace_back(std::move(wallpaperManager_u));
}

DriftCore::~DriftCore()
{
}

void DriftCore::start()
{
    writeLine("Drift Core Is launching....");
    coreRunning = true;
    getSystemInfo();
    writeLine("Drift Core is online");
    writeLine("-----------------------------");
    writeLine("Launching " + modules[0]->moduleName + " ...");
    settingsManager->start();
    writeLine("-----------------------------");
    writeLine("Launching Logger...");
    logger->start();
    writeLine("-----------------------------");
    writeLine("Launching DBus Manager...");
    dBusManager->start();
    writeLine("-----------------------------");
    writeLine("Launching Process Manager...");
    processManager->start();
    writeLine("-----------------------------");
    writeLine("Launching Theme Manager...");
    themeManager->start();
    writeLine("-----------------------------");
    writeLine("Launching Wallpaper Manager...");
    wallpaperManager->start();
    writeLine("-----------------------------");

    core();
}

void DriftCore::stop()
{
    coreRunning = false;
    writeLine("Core Shutting Down...");
    writeLine("Theme Manager Shutting Down...");
    writeLine("Process Manager Shutting Down...");
    writeLine("DBus Manager Shutting Down...");
    writeLine("Logger Shutting Down...");
    writeLine("Core Successfully Shut Down.");
}

void DriftCore::core()
{
    writeLine("Entering event loop...");
    QCoreApplication::exec(); // blocks and processes events
}

void DriftCore::getSystemInfo()
{
    user = []
    {
        struct passwd *pw = getpwuid(getuid());
        return pw ? std::string(pw->pw_name) : "";
    }();
    writeLine("User : " + user);

    homeDir = []
    {
        struct passwd *pw = getpwuid(getuid());
        return pw ? std::string(pw->pw_dir) : "";
    }();
    writeLine("Home directory : " + homeDir);

    xdgRuntimeDir = std::getenv("XDG_RUNTIME_DIR");
    writeLine("XDG Runtime Dir : " + xdgRuntimeDir);

    xdgCurrentDesktop = std::getenv("XDG_CURRENT_DESKTOP");
    writeLine("Current Desktop : " + xdgCurrentDesktop);

    waylandDisplay = std::getenv("WAYLAND_DISPLAY");
    writeLine("Wayland Display : " + waylandDisplay);

    setenv("HYPRDRIFT_SESSION", "1", 1);
    writeLine("Set HYPRDRIFT_SESSION=1");
}

void DriftCore::restartModule(std::string moduleName)
{
    getModule(moduleName);
}

DriftModule& DriftCore::getModule(const std::string name)
{
    for (const auto& mod : modules)
    {
        if (mod->moduleName == name)
        {
            return *mod; // Dereference unique_ptr to return a reference
        }
    }

    throw std::runtime_error("Module not found: " + name);
}
