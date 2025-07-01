#pragma once
#include <string>

class DriftModule {
public:
    std::string moduleName;
    virtual void start() = 0;
    virtual void stop() = 0;
    virtual ~DriftModule() = default;
};
