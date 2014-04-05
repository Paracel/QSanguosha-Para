#include "yjcm2014.h"
#include "settings.h"
#include "skill.h"
#include "standard.h"
#include "client.h"
#include "clientplayer.h"
#include "engine.h"
#include "maneuvering.h"

class Youdi: public PhaseChangeSkill {
public:
    Youdi(): PhaseChangeSkill("youdi") {
    }

    virtual bool onPhaseChange(ServerPlayer *target) const{
        if (target->getPhase() != Player::Finish || target->isNude()) return false;
        Room *room = target->getRoom();
        QList<ServerPlayer *> players;
        foreach (ServerPlayer *p, room->getOtherPlayers(target)) {
            if (p->canDiscard(target, "he")) players << p;
        }
        if (players.isEmpty()) return false;
        ServerPlayer *player = room->askForPlayerChosen(target, players, objectName(), "youdi-invoke", true, true);
        if (player) {
            int id = room->askForCardChosen(player, target, "he", objectName(), false, Card::MethodDiscard);
            room->throwCard(id, target, player);
            if (!Sanguosha->getCard(id)->isKindOf("Slash") && player->isAlive() && !player->isNude()) {
                QVariant player_data = QVariant::fromValue((PlayerStar)player);
                if (room->askForChoice(target, objectName(), "obtain+cancel", player_data) == "obtain") {
                    int id2= room->askForCardChosen(target, player, "he", "youdi_obtain");
                    room->obtainCard(target, id2);
                }
            }
        }
        return false;
    }
};

YJCM2014Package::YJCM2014Package()
    : Package("YJCM2014")
{
/*
    General *caifuren = new General(this, "caifuren", "qun", 3, false); // YJ 301

    General *caozhen = new General(this, "caozhen", "wei"); // YJ 302

    General *chenqun = new General(this, "chenqun", "wei", 3); // YJ 303

    General *guyong = new General (this, "guyong", "wu", 3); // YJ 304

    General *hanhaoshihuan = new General(this, "hanhaoshihuan", "wei"); // YJ 305

    General *jvshou = new General(this, "jvshou", "qun", 3); // YJ 306

    General *sunluban = new General(this, "sunluban", "wu", 3, false); // YJ 307

    General *wuyi = new General(this, "wuyi", "shu"); // YJ 308

    General *zhangsong = new General(this, "zhangsong", "shu", 3); // YJ 309

    General *zhoucang = new General(this, "zhoucang", "shu"); // YJ 310*/

    General *zhuhuan = new General(this, "zhuhuan", "wu"); // YJ 311
    zhuhuan->addSkill(new Youdi);
}

ADD_PACKAGE(YJCM2014)
