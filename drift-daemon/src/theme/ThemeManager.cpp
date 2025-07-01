#include <string>

#include "utilities.h"
#include "ThemeManager.h"
#include "DriftModule.h"

ThemeManager::ThemeManager(/* args */)
{
    moduleName = "Theme Manager";
    threaded = false;
}

ThemeManager::~ThemeManager()
{
}

void ThemeManager::start()
{
    enabled = true;
    
    running = true;
    emit started(QString::fromStdString(moduleName));
}

void ThemeManager::stop()
{
    writeLine(moduleName + " Stopped");
}

void ThemeManager::restart()
{
    stop();
    start();
}