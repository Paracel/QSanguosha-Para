#include "jiange-defense.h"
#include "settings.h"
#include "skill.h"
#include "standard.h"
#include "client.h"
#include "clientplayer.h"
#include "engine.h"
#include "maneuvering.h"

bool isJianGeFriend(const Player *a, const Player *b) {
    return a->getRole() == b->getRole();
}

class JGChiying: public TriggerSkill {
public:
    JGChiying(): TriggerSkill("jgchiying") {
        events << DamageInflicted;
        frequency = Compulsory;
    }

    virtual bool triggerable(const ServerPlayer *target) const{
        return target != NULL;
    }

    virtual bool trigger(TriggerEvent, Room *room, ServerPlayer *, QVariant &data) const{
        DamageStruct damage = data.value<DamageStruct>();
        ServerPlayer *zidan = room->findPlayerBySkillName(objectName());
        if (zidan && isJianGeFriend(zidan, damage.to) && damage.damage > 1) {
            LogMessage log;
            log.type = "#JGChiying";
            log.from = zidan;
            log.to << damage.to;
            log.arg = QString::number(damage.damage);
            log.arg2 = objectName();
            room->sendLog(log);
            room->broadcastSkillInvoke(objectName());
            room->notifySkillInvoked(zidan, objectName());

            damage.damage = 1;
            data = QVariant::fromValue(damage);
        }
        return false;
    }
};

class JGJingfan: public DistanceSkill {
public:
    JGJingfan(): DistanceSkill("jgjingfan") {
        frequency = Compulsory;
    }

    virtual int getCorrect(const Player *from, const Player *to) const{
        int dist = 0;
        if (!isJianGeFriend(from, to)) {
            foreach (const Player *p, from->getAliveSiblings()) {
                if (p->hasSkill(objectName()) && isJianGeFriend(p, from))
                    dist--;
            }
            return dist;
        }
        return 0;
    }
};

JianGeDefensePackage::JianGeDefensePackage()
    : Package("JianGeDefense")
{
    General *jg_soul_caozhen = new General(this, "jg_soul_caozhen", "wei", 5, true, true);
    jg_soul_caozhen->addSkill(new JGChiying);
    jg_soul_caozhen->addSkill(new JGJingfan);
}

ADD_PACKAGE(JianGeDefense)
