#include <string>

#include "AppLauncher.h"
#include "DriftModule.h"
#include "utilities.h"


AppLauncher::AppLauncher(/* args */)
{
}

AppLauncher::~AppLauncher()
{
}


void AppLauncher::start()
{
    writeLine("App Launcher Started");
}

void AppLauncher::stop()
{
    writeLine("Theme Manager Started");
}