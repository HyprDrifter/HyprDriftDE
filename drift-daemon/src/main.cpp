#include <iostream>
#include "DriftCore.h"
#include <QCoreApplication>


int main(int argc, char *argv[]) {
    QCoreApplication app(argc, argv);
    DriftCore core;
    core.start(); // Initializes and runs modules
    return app.exec();
}
