#include "DriftCore.h"

#include "Logger.h"
#include "DBusManager.h"
#include "SettingsManager.h"
#include "SessionManager.h"
#include "AppLauncher.h"
#include "WallpaperManager.h"
#include "ProcessManager.h"
#include "ThemeManager.h"

#include <QThread>
#include <QObject>
#include <QMetaObject>
#include <QCoreApplication>

#include <memory>
#include <string>
#include <vector>
#include <algorithm>
#include <stdexcept>
#include <pwd.h>
#include <unistd.h>
#include <cstdlib>
#include <ranges>

DriftCore::DriftCore(/* args */)
{
    coreRunning = false;

    settingsManager = registerModule<SettingsManager>(modules);
    logger = registerModule<Logger>(modules);
    sessionManager = registerModule<SessionManager>(modules);
    dBusManager = registerModule<DBusManager>(modules);
    processManager = registerModule<ProcessManager>(modules);
    themeManager = registerModule<ThemeManager>(modules);
    wallpaperManager = registerModule<WallpaperManager>(modules);
    appLauncher = registerModule<AppLauncher>(modules);
}

DriftCore::~DriftCore()
{
}

template <typename T>
T *DriftCore::registerModule(std::vector<std::unique_ptr<DriftModule>> &vec)
{
    auto mod = std::make_unique<T>();
    T *raw = mod.get();

    if (raw->threaded)
    {
        QThread *t = new QThread(this);
        raw->moveToThread(t);
        connect(this, &DriftCore::startModules, raw, &DriftModule::start);
        connect(raw, &DriftModule::started, this, &DriftCore::moduleStarted);

        // connect(raw,&DriftModule::stopModules,)
        t->start();
    }
    else
    {
        connect(this, &DriftCore::startModules, raw, &DriftModule::start);
        connect(raw, &DriftModule::started, this, &DriftCore::moduleStarted);
    }
    vec.emplace_back(std::move(mod));
    return raw;
}

void DriftCore::start()
{
    writeLine("Drift Core Is launching....");
    writeLine("--------------------------------------");
    coreRunning = true;
    getSystemInfo();
    writeLine("--------------------------------------");
    writeLine("Drift Core is online");
    writeLine("--------------------------------------");
    writeLine("Starting all modules");
    writeLine("--------------------------------------");

    for (const auto &mod : modules)
    {
        auto *m = mod.get();
        moduleStartupQueue.emplace_back(m);
    }

    QMetaObject::invokeMethod(this, [this]
        { emit startModules(); 
    }, Qt::QueuedConnection);
}

void DriftCore::stop()
{
    writeLine("Core Shutting Down...");
    for (auto &mod : std::ranges::reverse_view(modules))
    {
        writeLine("");
        writeLine("--------------------------------------");
        writeLine("");
        writeLine("Shutting down module : " + mod->moduleName);
        mod->stop();
    }
    writeLine("Core Successfully Shut Down.");
    coreRunning = false;
}

void DriftCore::core()
{
    writeLine("--------------------------------------");
    writeLine("Entering event loop...");
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

    xdgRuntimeDir = getEnvVariable("XDG_RUNTIME_DIR");
    writeLine("XDG Runtime Dir : " + xdgRuntimeDir);

    xdgCurrentDesktop = getEnvVariable("XDG_CURRENT_DESKTOP");
    writeLine("Current Desktop : " + xdgCurrentDesktop);

    waylandDisplay = getEnvVariable("WAYLAND_DISPLAY");
    writeLine("Wayland Display : " + waylandDisplay);

    setenv("HYPRDRIFT_SESSION", "1", 1);
    writeLine("Set HYPRDRIFT_SESSION=1");
}

std::string DriftCore::getEnvVariable(const char *varName)
{
    std::string val;
    writeLine("Looking for environment variable : " + std::string(varName));
    while (true)
    {
        const char *envVal = std::getenv(varName);
        if (envVal && *envVal != '\0')
        {
            val = envVal;
            break;
        }
        writeLine("Waiting for env var: " + std::string(varName));
        QThread::msleep(100);
    }
    writeLine("Found environment variable : " + std::string(varName));
    return val;
}

DriftModule &DriftCore::getModule(const std::string &name)
{
    for (const auto &mod : modules)
    {
        if (mod->moduleName == name)
        {
            return *mod; // Dereference unique_ptr to return a reference
        }
    }

    throw std::runtime_error("DriftCore::getModule(): Module not found: " + name);
}

DriftModule *DriftCore::getModulePointer(const std::string &name)
{
    for (const auto &mod : modules)
    {
        if (mod->moduleName == name)
        {
            return mod.get(); // Dereference unique_ptr to return a reference
        }
    }

    throw std::runtime_error("DriftCore::getModule(): Module not found: " + name);
}

void DriftCore::startModule(const std::string &moduleName)
{
    DriftModule *m = getModulePointer(moduleName);
    QMetaObject::invokeMethod(m, &DriftModule::start, Qt::QueuedConnection);
}

void DriftCore::stopModule(const std::string &moduleName)
{
    DriftModule *m = getModulePointer(moduleName);
    QMetaObject::invokeMethod(m, &DriftModule::stop, Qt::QueuedConnection);
}

void DriftCore::restartModule(const std::string &moduleName)
{
    DriftModule *m = getModulePointer(moduleName);
    QMetaObject::invokeMethod(m, &DriftModule::restart, Qt::QueuedConnection);
}

// QT Slots

void DriftCore::moduleStarted(const QString &name)
{
    if (starting)
    {
        writeLine("Module Started : " + name.toStdString());
        auto it = std::find_if(moduleStartupQueue.begin(), moduleStartupQueue.end(), [&name](DriftModule *mod)
            { return mod->moduleName == name.toStdString(); 
        });

        if (it != moduleStartupQueue.end())
        {
            moduleStartupQueue.erase(it);
        }

        if (moduleStartupQueue.size() == 0)
        {
            starting = false;
            writeLine("--------------------------------------");
            writeLine("All modules started.");

            core(); // only start once all are ready
        }
    }
}