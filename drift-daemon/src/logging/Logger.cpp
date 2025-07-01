#include <iostream>
#include <string>

#include "Logger.h"
#include "utilities.h"
#include "DriftModule.h"

Logger::Logger()
{
    moduleName = "Logger";
    threaded = true;
}

Logger::~Logger()
{

}


void Logger::start()
{
    enabled = true;
    
    running = true;
    emit started(QString::fromStdString(moduleName));
}

void Logger::stop()
{
    writeLine(moduleName + " Stopped");
}

void Logger::restart()
{
    stop();
    start();
}