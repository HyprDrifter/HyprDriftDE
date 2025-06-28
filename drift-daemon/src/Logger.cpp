#include <iostream>
#include <string>

#include "Logger.h"
#include "utilities.h"

Logger::Logger()
{
    
}

Logger::~Logger()
{

}


void Logger::start()
{
    running = true;
    writeLine("Logger Started");
}