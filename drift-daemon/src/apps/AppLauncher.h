#pragma once

#include <string>
#include "DriftModule.h"
#include <QObject>


class AppLauncher : public DriftModule
{
private:
    /* data */
public:
    AppLauncher(/* args */);
    ~AppLauncher();


public slots:
    void start();
    void stop();
    void restart();
};


