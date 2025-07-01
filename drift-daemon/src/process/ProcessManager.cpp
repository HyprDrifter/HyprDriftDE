#include <string>

#include "utilities.h"
#include "ProcessManager.h"
#include "DriftModule.h"

ProcessManager::ProcessManager(/* args */)
{
    moduleName = "Process Manager";
    threaded = true;
}

ProcessManager::~ProcessManager()
{
}


void ProcessManager::start()
{
    enabled = true;
    
    running = true;
    emit started(QString::fromStdString(moduleName));
}

void ProcessManager::stop()
{
    writeLine(moduleName + " Stopped");
}

void ProcessManager::restart()
{
    stop();
    start();
}