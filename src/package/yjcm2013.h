#ifndef _YJCM2013_H
#define _YJCM2013_H

#include "package.h"
#include "card.h"
#include "wind.h"

#include <QMutex>
#include <QGroupBox>
#include <QAbstractButton>

class YJCM2013Package: public Package {
    Q_OBJECT

public:
    YJCM2013Package();
};

#endif