#ifndef _DISTANCEVIEWDIALOG_H
#define _DISTANCEVIEWDIALOG_H

class ClientPlayer;

#include <QDialog>

class DistanceViewDialogUI;

class DistanceViewDialog: public QDialog {
    Q_OBJECT

public:
    DistanceViewDialog(QWidget *parent = 0);
    ~DistanceViewDialog();

private:
    DistanceViewDialogUI *ui;

private slots:
    void showDistance();
};

#endif
// FORMATTED
