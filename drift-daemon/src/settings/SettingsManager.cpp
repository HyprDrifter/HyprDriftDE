#include <string>
#include <list>
#include <yaml-cpp/yaml.h>
#include <iostream>
#include <fstream>
#include <filesystem>
#include <unistd.h>
#include <sys/types.h>
#include <pwd.h>

#include "utilities.h"
#include "SettingsManager.h"
#include "DriftModule.h"

SettingsManager::SettingsManager()
{
    moduleName = "Settings Manager";
    threaded = true;

    user = getuid();
    writeLine(user);
    struct passwd *pw = getpwuid(getuid());
    home = pw->pw_dir;

    std::string defaultFileString = "/etc/hyprdrift/config/quickdrift/drift-config.yaml";
    std::string userFileString = home + "/.config/hyprdrift/config/drift-config.yaml";

    verifyUserDirectories(home);

    std::ifstream defaultFile(defaultFileString);
    std::ifstream userFile(userFileString);

    if(userFile)
    {
        parseConfig(userFileString);
    } 
    else if(defaultFile)
    {
        std::filesystem::copy_file(defaultFileString, userFileString);
        parseConfig(userFileString);
    }
    else
    {
        writeLine("Neither user or default config exist");
    }
}

SettingsManager::~SettingsManager()
{
}

void SettingsManager::start()
{
    enabled = true;
    
    running = true;
    emit started(QString::fromStdString(moduleName));
}

void SettingsManager::stop()
{
    writeLine(moduleName + " Stopped");
}

void SettingsManager::restart()
{
    stop();
    start();
}

void SettingsManager::verifyUserDirectories(std::string dir)
{
    std::filesystem::create_directories(dir + "/.cache/hyprdrift");
    std::filesystem::create_directories(dir + "/.cache/hyprdrift/drift");
    std::filesystem::create_directories(dir + "/.cache/hyprdrift/quickdrift");
    std::filesystem::create_directories(dir + "/.config/hyprdrift");
    std::filesystem::create_directories(dir + "/.config/hyprdrift/config");
}

void SettingsManager::parseConfig(const std::string &path)
{

    YAML::Node config = YAML::LoadFile(path);

    // General
    timeFormat = config["general"]["timeFormat"].as<std::string>();
    dateFormat = config["general"]["dateFormat"].as<std::string>();
    logLocation = config["general"]["logLocation"].as<std::string>();
    userConfigFile = config["general"]["userConfigFile"].as<std::string>();
    defaultConfigFile = config["general"]["defaultConfigFile"].as<std::string>();
    for (const auto& app : config["general"]["startupApps"])
        startupApps.push_back(app.as<std::string>());

    // Theme
    themeBase = config["theme"]["base"].as<std::string>();
    themeVariant = config["theme"]["variant"].as<std::string>();
    accentColor = config["theme"]["accentColor"].as<std::string>();
    borderRadius = config["theme"]["borderRadius"].as<int>();
    panelOpacity = config["theme"]["panelOpacity"].as<double>();
    fontFamily = config["theme"]["font"]["family"].as<std::string>();
    fontSize = config["theme"]["font"]["size"].as<int>();

    // Interface - Panel
    panelEnabled = config["interface"]["panel"]["enabled"].as<bool>();
    panelPosition = config["interface"]["panel"]["position"].as<std::string>();
    panelFloating = config["interface"]["panel"]["floating"].as<bool>();
    panelWidthMode = config["interface"]["panel"]["width"]["mode"].as<std::string>();
    panelHeightMode = config["interface"]["panel"]["height"]["mode"].as<std::string>();
    for (const auto& item : config["interface"]["panel"]["leftModules"])
        panelLeftModules.push_back(item.as<std::string>());
    for (const auto& item : config["interface"]["panel"]["centerModules"])
        panelCenterModules.push_back(item.as<std::string>());
    for (const auto& item : config["interface"]["panel"]["rightModules"])
        panelRightModules.push_back(item.as<std::string>());

    // Interface - Dock
    dockEnabled = config["interface"]["dock"]["enabled"].as<bool>();
    dockPosition = config["interface"]["dock"]["position"].as<std::string>();
    dockFloating = config["interface"]["dock"]["floating"].as<bool>();
    dockHeightMode = config["interface"]["dock"]["height"].as<std::string>(); // "fit"
    dockWidth = config["interface"]["dock"]["width"].as<int>();

    // Shortcuts
    shortcutLauncher = config["shortcuts"]["launcher"].as<std::string>();
    shortcutTerminal = config["shortcuts"]["terminal"].as<std::string>();

    // Core
    coreLocation = config["core"]["coreLocation"].as<std::string>();
    debugMode = config["core"]["debugMode"].as<bool>();
}