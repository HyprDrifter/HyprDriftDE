#pragma once

#include <string>

#include "DriftModule.h"

class ThemeManager : public DriftModule
{
private:
    /* data */
public:
    ThemeManager(/* args */);
    ~ThemeManager();
    void start() override;
    void stop() override;
};

