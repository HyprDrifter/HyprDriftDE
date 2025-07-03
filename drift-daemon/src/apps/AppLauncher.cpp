#include <string>

#include "AppLauncher.h"
#include "DriftModule.h"
#include "utilities.h"


AppLauncher::AppLauncher(/* args */)
{
    moduleName = "App Launcher";
    threaded = true;
}

AppLauncher::~AppLauncher()
{
}


void AppLauncher::start()
{
    enabled = true;
    
    running = true;
    emit started(QString::fromStdString(moduleName));
}

void AppLauncher::stop()
{
    writeLine(moduleName + " Stopped");
}

void AppLauncher::restart()
{
    stop();
    start();
}