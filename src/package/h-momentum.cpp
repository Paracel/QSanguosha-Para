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

class Xunxun: public PhaseChangeSkill {
public:
    Xunxun(): PhaseChangeSkill("xunxun") {
        frequency = Frequent;
    }

    virtual bool onPhaseChange(ServerPlayer *lidian) const{
        if (lidian->getPhase() == Player::Draw) {
            Room *room = lidian->getRoom();
            if (room->askForSkillInvoke(lidian, objectName())) {
                QList<int> card_ids = room->getNCards(4);
                QList<int> obtained;
                room->fillAG(card_ids, lidian);
                int id1 = room->askForAG(lidian, card_ids, false, objectName());
                card_ids.removeOne(id1);
                obtained << id1;
                room->takeAG(lidian, id1, false);
                int id2 = room->askForAG(lidian, card_ids, false, objectName());
                card_ids.removeOne(id2);
                obtained << id2;
                room->clearAG(lidian);

                room->askForGuanxing(lidian, card_ids, Room::GuanxingDownOnly);
                DummyCard *dummy = new DummyCard(obtained);
                lidian->obtainCard(dummy, false);
                delete dummy;

                return true;
            }
        }

        return false;
    }
};

class Wangxi: public TriggerSkill {
public:
    Wangxi(): TriggerSkill("wangxi") {
        events << Damage << Damaged;
    }

    virtual bool trigger(TriggerEvent triggerEvent, Room *room, ServerPlayer *player, QVariant &data) const{
        DamageStruct damage = data.value<DamageStruct>();
        ServerPlayer *target = NULL;
        if (triggerEvent == Damage)
            target = damage.to;
        else
            target = damage.from;
        if (!target || target == player) return false;
        QList<ServerPlayer *> players;
        players << player << target;
        room->sortByActionOrder(players);

        for (int i = 1; i <= damage.damage; i++) {
            if (!target->isAlive() || !player->isAlive())
                return false;
            if (room->askForSkillInvoke(player, objectName(), QVariant::fromValue((PlayerStar)target)))
                room->drawCards(players, 1, objectName());
        }
        return false;
    }
};

HMomentumPackage::HMomentumPackage()
    : Package("h_momentum")
{
    General *lidian = new General(this, "lidian", "wei", 3); // WEI 017
    lidian->addSkill(new Xunxun);
    lidian->addSkill(new Wangxi);

    /*General *zangba = new General(this, "zangba", "wei", 4); // WEI 023
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
