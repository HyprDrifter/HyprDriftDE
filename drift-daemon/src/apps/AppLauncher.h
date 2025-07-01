#pragma once

#include <string>
#include "DriftModule.h"


class AppLauncher : public DriftModule
{
private:
    /* data */
public:
    AppLauncher(/* args */);
    ~AppLauncher();

    void start();
    void stop();
};


