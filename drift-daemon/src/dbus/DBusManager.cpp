#include <string>

#include "utilities.h"
#include "DBusManager.h"
#include "DriftModule.h"

DBusManager::DBusManager(/* args */)
{
    moduleName = "DBus Manager";
    threaded = false;
}

DBusManager::~DBusManager()
{
}


void DBusManager::start()
{
    enabled = true;
    
    running = true;
    emit started(QString::fromStdString(moduleName));
}

void DBusManager::stop()
{
    writeLine(moduleName + " Stopped");
}

void DBusManager::restart()
{
    stop();
    start();
}