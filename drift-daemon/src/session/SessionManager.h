#pragma once

#include <string>

#include "DriftModule.h"

class SessionManager : public DriftModule
{
private:
    /* data */
public:
    SessionManager(/* args */);
    ~SessionManager();
    void start();
    void stop();
};

