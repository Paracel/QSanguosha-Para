#include "h-momentum.h"
#include "general.h"
#include "standard.h"
#include "standard-equips.h"
#include "maneuvering.h"
#include "skill.h"
#include "engine.h"
#include "client.h"
#include "serverplayer.h"
#include "room.h"
#include "ai.h"
#include "settings.h"
#include "jsonutils.h"

HMomentumPackage::HMomentumPackage()
    : Package("h_momentum")
{
    /*General *lidian = new General(this, "lidian", "wei", 3); // WEI 017
    lidian->addSkill(new Xunxun);
    lidian->addSkill(new Wangxi);

    General *zangba = new General(this, "zangba", "wei", 4); // WEI 023
    zangba->addSkill(new Hengjiang);*/

    General *heg_madai = new General(this, "heg_madai", "shu", 4, true, true); // SHU 019
    heg_madai->addSkill("mashu");
    heg_madai->addSkill("qianxi");

    /*General *mifuren = new General(this, "mifuren", "shu", 3, false); // SHU 021
    mifuren->addSkill(new Guixiu);
    mifuren->addSkill(new Cunsi);

    General *chenwudongxi = new General(this, "chenwudongxi", "wu", 4);

    General *heg_sunce = new General(this, "heg_sunce", "wu", 4); // WU 010 G

    General *heg_dongzhuo = new General(this, "heg_dongzhuo", "qun", 4); // QUN 006 G

    General *zhangren = new General(this, "zhangren", "qun", 3);

    skills << new Yongjue;*/
}

ADD_PACKAGE(HMomentum)
