#include <string>

#include "SessionManager.h"
#include "DriftModule.h"
#include "utilities.h"

SessionManager::SessionManager(/* args */)
{
    moduleName = "Session Manager";
    threaded = true;
    
}

SessionManager::~SessionManager()
{
}

void SessionManager::start()
{
    enabled = true;
    
    running = true;
    emit started(QString::fromStdString(moduleName));
}

void SessionManager::stop()
{
    writeLine(moduleName + " Stopped");
}

void SessionManager::restart()
{
    stop();
    start();
}
