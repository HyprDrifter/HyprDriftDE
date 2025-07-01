#pragma once

#include <string>

#include "DriftModule.h"

class ProcessManager : public DriftModule
{
private:
    /* data */
public:
    ProcessManager(/* args */);
    ~ProcessManager();
    void start();
    void stop();
};

