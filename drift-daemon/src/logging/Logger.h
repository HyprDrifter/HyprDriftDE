#pragma once
#include <string>
#include <iostream>

#include "DriftModule.h"

class Logger : public DriftModule
{
private:
    bool running = false;
public:
    Logger(/* args */);
    ~Logger();

public slots:
    void start();
    void stop();
    void restart();
};
