// -----------------------------------------------------------------------------
// WinAppQt -- Qt variant of the sample app, compiled only with -DUSE_QT=ON
// (plus -DCMAKE_PREFIX_PATH pointing at a Qt kit, e.g. C:/Qt/6.8.0/msvc2022_64).
//
//   cmake --preset msvc-debug -DUSE_QT=ON -DCMAKE_PREFIX_PATH="C:/Qt/6.8.0/msvc2022_64"
//   cmake --build --preset msvc-debug
// -----------------------------------------------------------------------------

#include <QApplication>
#include <QMessageBox>
#include <QString>

#include "app_core.h"

int main(int argc, char* argv[])
{
    QApplication app(argc, argv);

    QMessageBox::information(nullptr,
                              QStringLiteral("vscode_WinApp (Qt)"),
                              QString::fromStdString(app::BuildInfo()));
    return 0;
}
