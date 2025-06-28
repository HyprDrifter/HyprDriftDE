#pragma once
#include <string>
#include <iostream>


class Logger
{
private:
    bool running = false;
public:
    Logger(/* args */);
    ~Logger();

    void start();
};
