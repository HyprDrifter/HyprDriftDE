#pragma once

#include <string>
#include <memory>

#include "utilities.h"
#include "Logger.h"
#include "DBusManager.h"
#include "SettingsManager.h"
#include "SessionManager.h"
#include "AppLauncher.h"

class DriftCore
{
public:
    DriftCore();
    ~DriftCore();
    void start();
    void stop();

private:
    
    bool coreRunning;
    std::unique_ptr<Logger> logger;

    void core();
    
};