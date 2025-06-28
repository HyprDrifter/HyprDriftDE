#include <string>
#include <iostream>
#include <memory>

#include "utilities.h"
#include "DriftCore.h"
#include "Logger.h"
#include "DBusManager.h"
#include "SettingsManager.h"
#include "SessionManager.h"
#include "AppLauncher.h"

DriftCore::DriftCore(/* args */)
{
    coreRunning = false;
    logger = std::make_unique<Logger>();
}

DriftCore::~DriftCore()
{
}

void DriftCore::start()
{
    writeLine("Drift Core Is launching....");
    coreRunning = true;
    writeLine("Launching Settings Manager...");
    writeLine("Launching Logger...");
    logger->start();
    writeLine("Launching DBus Manager...");
    writeLine("Launching Process Manager...");
    writeLine("Launching Theme Manager...");
    writeLine("Drift Core is online");
    writeLine("----------------------------------");
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
    writeLine("Waiting for signal.");
    while (coreRunning)
    {
    }
}