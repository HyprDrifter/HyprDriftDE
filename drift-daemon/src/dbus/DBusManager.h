#pragma once

#include <string>

#include "DriftModule.h"

class DBusManager : public DriftModule
{
private:
    /* data */
public:
    DBusManager(/* args */);
    ~DBusManager();
    void start();
    void stop();
};

