#pragma once
#include <string>
#include <QObject>
#include <QThread>

class DriftModule : public QObject
{
    Q_OBJECT

public:
    virtual ~DriftModule() = default;

    std::string moduleName;
    bool enabled;
    bool running;
    bool threaded;

public slots:
    virtual void start();
    virtual void stop();
    virtual void restart();

signals:
    void started(const QString& name);
};
