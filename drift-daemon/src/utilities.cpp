#include <iostream>
#include "utilities.h"

void writeLine(const std::string text)
{
    std::cout << text << "\n";
}

std::string readLine()
{
    return []{
        std::string text = "";
        std::getline(std::cin, text);
        return text;
    }();
}