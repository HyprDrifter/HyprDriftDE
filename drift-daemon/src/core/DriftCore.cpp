#include <string>
#include <iostream>
#include <memory>
#include <QCoreApplication>
#include <cstdlib>
#include <pwd.h>
#include <unistd.h>

#include "utilities.h"
#include "DriftCore.h"
#include "Logger.h"
#include "DBusManager.h"
#include "SettingsManager.h"
#include "SessionManager.h"
#include "AppLauncher.h"
#include "WallpaperManager.h"

DriftCore::DriftCore(/* args */)
{
    coreRunning = false;
    settingsManager = std::make_unique<SettingsManager>();
    logger = std::make_unique<Logger>();
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
    writeLine("Launching Settings Manager...");
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
    QCoreApplication::exec();  // blocks and processes events
}

void DriftCore::getSystemInfo()
{
    user = [] {
        struct passwd* pw = getpwuid(getuid());
        return pw ? std::string(pw->pw_name) : "";
    }();
    writeLine("User : " + user);
    
    homeDir = [] {
        struct passwd* pw = getpwuid(getuid());
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