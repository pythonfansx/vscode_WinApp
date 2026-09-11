// -----------------------------------------------------------------------------
// WinAppQt - Qt Widgets edition of the sample app (template/qt branch).
//
// Qt linkage is controlled at configure time:
//   APP_QT_LINK=static  -> msvc2019_64_static kit, everything folded into
//                          one exe (platform plugin imported below; the kit
//                          is built with /MT, so the CRT is forced static too)
//   APP_QT_LINK=dynamic -> msvc2019_64 kit, exe needs Qt5*.dll at runtime
//                          (deploy with windeployqt)
// -----------------------------------------------------------------------------

#include <QApplication>
#include <QLabel>
#include <QMessageBox>
#include <QPushButton>
#include <QString>
#include <QVBoxLayout>
#include <QWidget>

#include "app_core.h"

#if defined(QT_STATIC)
#  include <QtPlugin>
Q_IMPORT_PLUGIN(QWindowsIntegrationPlugin)
#endif

int main(int argc, char* argv[])
{
    QApplication app(argc, argv);

    auto* window = new QWidget;
    window->setWindowTitle(QStringLiteral("vscode_WinApp (Qt)"));

    auto* layout = new QVBoxLayout(window);
    auto* report = new QLabel(QString::fromStdString(app::BuildInfo()));
    report->setTextInteractionFlags(Qt::TextSelectableByMouse);
    auto* about = new QPushButton(QStringLiteral("About"));
    auto* quit = new QPushButton(QStringLiteral("Quit"));

    layout->addWidget(report);
    layout->addWidget(about);
    layout->addWidget(quit);

    QWidget::connect(about, &QPushButton::clicked, window, [window]
    {
        QMessageBox::about(window, QStringLiteral("vscode_WinApp (Qt)"),
                           QString::fromStdString(app::BuildInfo()));
    });
    QWidget::connect(quit, &QPushButton::clicked, window, &QWidget::close);

    window->resize(420, 220);
    window->show();
    return app.exec();
}
