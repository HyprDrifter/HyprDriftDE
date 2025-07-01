#pragma once

#include <string>
#include <vector>
#include <yaml-cpp/yaml.h>
#include <QObject>

#include "DriftModule.h"


class SettingsManager : public DriftModule
{


public:
    SettingsManager();
    ~SettingsManager() override;

    void start();
    void stop();
    void restart();
    
private:
    std::string user;
    std::string home;
    YAML::Node config;

    // General
    std::string timeFormat;
    std::string dateFormat;
    std::string logLocation;
    std::string userConfigFile;
    std::string defaultConfigFile;
    std::vector<std::string> startupApps;

    // Theme
    std::string themeBase;
    std::string themeVariant;
    std::string accentColor;
    int borderRadius;
    double panelOpacity;
    std::string fontFamily;
    int fontSize;

    // Interface - Panel
    bool panelEnabled;
    std::string panelPosition;
    bool panelFloating;
    std::string panelWidthMode;
    std::string panelHeightMode;
    std::vector<std::string> panelLeftModules;
    std::vector<std::string> panelCenterModules;
    std::vector<std::string> panelRightModules;

    // Interface - Dock
    bool dockEnabled;
    std::string dockPosition;
    bool dockFloating;
    std::string dockHeightMode;
    int dockWidth;

    // Shortcuts
    std::string shortcutLauncher;
    std::string shortcutTerminal;

    // Core
    std::string coreLocation;
    bool debugMode;

    void verifyUserDirectories(std::string dir);
    void parseConfig(const std::string& path);
};


