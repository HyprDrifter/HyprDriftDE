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

public slots:
    void start();
    void stop();
    void restart();
};

