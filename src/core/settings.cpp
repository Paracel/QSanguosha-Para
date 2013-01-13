#include "settings.h"
#include "photo.h"
#include "card.h"
#include "engine.h"

#include <QFontDatabase>
#include <QStringList>
#include <QFile>
#include <QMessageBox>
#include <QApplication>
#include <QNetworkInterface>
#include <QDateTime>

Settings Config;

static const qreal ViewWidth = 1280 * 0.8;
static const qreal ViewHeight = 800 * 0.8;

//consts
const int Settings::S_CHOOSE_GENERAL_TIMEOUT = 15;
const int Settings::S_GUANXING_TIMEOUT = 20;
const int Settings::S_SURRNDER_REQUEST_MIN_INTERVAL = 60;
const int Settings::S_PROGRESS_BAR_UPDATE_INTERVAL = 200;
const int Settings::S_SERVER_TIMEOUT_GRACIOUS_PERIOD = 1000;
const int Settings::S_MOVE_CARD_ANIMATION_DURAION = 600;
const int Settings::S_JUDGE_ANIMATION_DURATION = 1200;
const int Settings::S_REGULAR_ANIMATION_SLOW_DURAION = 1200;
const int Settings::S_JUDGE_SHORT_DELAY = 100;
const int Settings::S_JUDGE_LONG_DELAY = 800;

Settings::Settings()
#ifdef Q_OS_WIN32
    : QSettings("config.ini", QSettings::IniFormat)
#else
    : QSettings("QSanguosha.org", "QSanguosha")
#endif
                ,Rect(-ViewWidth/2, -ViewHeight/2, ViewWidth, ViewHeight)
{
}

void Settings::init() {
    if (!qApp->arguments().contains("-server")) {
        QString font_path = value("DefaultFontPath", "font/font.ttf").toString();
        int font_id = QFontDatabase::addApplicationFont(font_path);
        if (font_id != -1) {
            QString font_family = QFontDatabase::applicationFontFamilies(font_id).first();
            BigFont.setFamily(font_family);
            SmallFont.setFamily(font_family);
            TinyFont.setFamily(font_family);
        } else
            QMessageBox::warning(NULL, tr("Warning"), tr("Font file %1 could not be loaded!").arg(font_path));

        BigFont.setPixelSize(56);
        SmallFont.setPixelSize(27);
        TinyFont.setPixelSize(18);

        SmallFont.setWeight(QFont::Bold);

        AppFont = value("AppFont", QApplication::font("QMainWindow")).value<QFont>();
        UIFont = value("UIFont", QApplication::font("QTextEdit")).value<QFont>();
        TextEditColor = QColor(value("TextEditColor", "white").toString());
    }

    CountDownSeconds = value("CountDownSeconds", 3).toInt();
    GameMode = value("GameMode", "02p").toString();


    if (!contains("BanPackages")) {
        QStringList banlist;
        banlist << "nostalgia" << "nostal_general" << "nostal_yjcm" << "nostal_yjcm2012"
                << "test" << "GreenHand" << "dragon"
                << "sp_cards" << "ling" << "GreenHandCard"
                << "New3v3Card";

        setValue("BanPackages", banlist);
    }

    BanPackages = value("BanPackages").toStringList();

    FreeChoose = value("FreeChoose", false).toBool();
    ForbidSIMC = value("ForbidSIMC", false).toBool();
    DisableChat = value("DisableChat", false).toBool();
    FreeAssignSelf = value("FreeAssignSelf", false).toBool();
    Enable2ndGeneral = value("Enable2ndGeneral", false).toBool();
    EnableSame = value("EnableSame", false).toBool();
    EnableBasara = value("EnableBasara", false).toBool();
    EnableHegemony = value("EnableHegemony", false).toBool();
    MaxHpScheme = value("MaxHpScheme", 0).toInt();
    PreventAwakenBelow3 = value("PreventAwakenBelow3", false).toBool();
    AnnounceIP = value("AnnounceIP", false).toBool();
    Address = value("Address", QString()).toString();
    EnableAI = value("EnableAI", true).toBool();
    OriginAIDelay = value("OriginAIDelay", 1000).toInt();
    AlterAIDelayAD = value("AlterAIDelayAD", false).toBool();
    AIDelayAD = value("AIDelayAD", 0).toInt();
    ServerPort = value("ServerPort", 9527u).toUInt();

#ifdef Q_OS_WIN32
    UserName = value("UserName", qgetenv("USERNAME")).toString();
#else
    UserName = value("USERNAME", qgetenv("USER")).toString();
#endif

    if (UserName == "Admin" || UserName == "Administrator")
        UserName = tr("Sanguosha-fans");
    ServerName = value("ServerName", tr("%1's server").arg(UserName)).toString();

    HostAddress = value("HostAddress", "127.0.0.1").toString();
    UserAvatar = value("UserAvatar", "zhangliao").toString();
    HistoryIPs = value("HistoryIPs").toStringList();
    DetectorPort = value("DetectorPort", 9526u).toUInt();
    MaxCards = value("MaxCards", 15).toInt();

    EnableHotKey = value("EnableHotKey", true).toBool();
    NeverNullifyMyTrick = value("NeverNullifyMyTrick", true).toBool();
    EnableMinimizeDialog = value("EnableMinimizeDialog", false).toBool();
    EnableAutoTarget = value("EnableAutoTarget", false).toBool();
    EnableIntellectualSelection = value("EnableIntellectualSelection", false).toBool();
    NullificationCountDown = value("NullificationCountDown", 8).toInt();
    OperationTimeout = value("OperationTimeout", 15).toInt();
    OperationNoLimit = value("OperationNoLimit", false).toBool();
    EnableEffects = value("EnableEffects", true).toBool();
    EnableLastWord = value("EnableLastWord", true).toBool();
    EnableBgMusic = value("EnableBgMusic", true).toBool();
    BGMVolume = value("BGMVolume", 1.0f).toFloat();
    EffectVolume = value("EffectVolume", 1.0f).toFloat();
    DisableLua = value("DisableLua", false).toBool();

    BackgroundImage = value("BackgroundImage", "backdrop/default.jpg").toString();

    QStringList roles_ban, kof_ban, basara_ban, hegemony_ban, pairs_ban;

    kof_ban << "sunquan" << "huatuo";

    basara_ban << "dongzhuo" << "zuoci" << "shenzhugeliang" << "shenlvbu" << "bgm_lvmeng";

    hegemony_ban.append(basara_ban);
    foreach (QString general, Sanguosha->getLimitedGeneralNames()) {
        if (Sanguosha->getGeneral(general)->getKingdom() == "god" && !hegemony_ban.contains(general))
            hegemony_ban << general;
    }

    pairs_ban << "huatuo" << "zhoutai" << "zuoci" << "bgm_pangtong" << "neo_zhoutai"
              << "simayi+zhenji" << "simayi+dengai"
              << "caoren+shenlvbu" << "caoren+caozhi" << "caoren+bgm_diaochan" << "caoren+bgm_caoren" << "caoren+neo_caoren"
              << "guojia+dengai"
              << "zhenji+zhangjiao" << "zhenji+shensimayi" << "zhenji+wangyi" << "zhenji+zhugejin"
              << "zhanghe+yuanshu"
              << "dianwei+weiyan"
              << "dengai+zhangjiao" << "dengai+shensimayi" << "dengai+zhugejin"
              << "liubei+luxun" << "liubei+zhangchunhua" << "liubei+nos_zhangchunhua"
              << "zhangfei+huanggai" << "zhangfei+zhangchunhua" << "zhangfei+nos_zhangchunhua"
              << "zhugeliang+xushu" << "zhugeliang+nos_xushu"
              << "huangyueying+wolong" << "huangyueying+ganning" << "huangyueying+huanggai" << "huangyueying+yuanshao" << "huangyueying+yanliangwenchou"
              << "huangzhong+xusheng"
              << "wolong+luxun" << "wolong+zhangchunhua" << "wolong+nos_zhangchunhua"
              << "sunquan+sunshangxiang"
              << "lvmeng+yuanshu"
              << "huanggai+sunshangxiang" << "huanggai+yuanshao" << "huanggai+yanliangwenchou" << "huanggai+dongzhuo" << "huanggai+wuguotai" << "huanggai+guanxingzhangbao" << "huanggai+huaxiong" << "huanggai+neo_zhangfei"
              << "luxun+yuji" << "luxun+yanliangwenchou" << "luxun+guanxingzhangbao" << "luxun+heg_luxun"
              << "sunshangxiang+heg_luxun"
              << "sunce+guanxingzhangbao"
              << "yanliangwenchou+zhangchunhua" << "yanliangwenchou+nos_zhangchunhua"
              << "dongzhuo+shenzhaoyun" << "dongzhuo+nos_zhangchunhua" << "dongzhuo+diy_wangyuanji"
              << "yuji+zhangchunhua" << "yuji+nos_zhangchunhua"
              << "shenlvbu+caozhi" << "shenlvbu+liaohua" << "shenlvbu+bgm_diaochan" << "shenlvbu+bgm_caoren" << "shenlvbu+neo_caoren"
              << "shenzhaoyun+huaxiong"
              << "caozhi+bgm_diaochan" << "caozhi+bgm_caoren" << "caozhi+neo_caoren"
              << "gaoshun+zhangchunhua" << "gaoshun+nos_zhangchunhua"
              << "zhangchunhua+guanxingzhangbao" << "zhangchunhua+heg_luxun" << "zhangchunhua+neo_zhangfei"
              << "guanxingzhangbao+nos_zhangchunhua"
              << "liaohua+bgm_diaochan"
              << "bgm_diaochan+bgm_caoren"
              << "bgm_caoren+neo_caoren"
              << "nos_zhangchunhua+heg_luxun" << "nos_zhangchunhua+neo_zhangfei";

    QStringList banlist = value("Banlist/Roles").toStringList();
    if (banlist.isEmpty()) {
        foreach (QString ban_general, roles_ban)
                banlist << ban_general;

        setValue("Banlist/Roles", banlist);
    }

    banlist = value("Banlist/1v1").toStringList();
    if (banlist.isEmpty()) {
        foreach (QString ban_general, kof_ban)
                banlist << ban_general;

        setValue("Banlist/1v1", banlist);
    }

    banlist = value("Banlist/Basara").toStringList();
    if (banlist.isEmpty()) {
        foreach (QString ban_general, basara_ban)
                    banlist << ban_general;

        setValue("Banlist/Basara", banlist);
    }

    banlist = value("Banlist/Hegemony").toStringList();
    if (banlist.isEmpty()) {
        foreach (QString ban_general, hegemony_ban)
            banlist << ban_general;
        setValue("Banlist/Hegemony", banlist);
    }

    banlist = value("Banlist/Pairs").toStringList();
    if (banlist.isEmpty()) {
        foreach (QString ban_general, pairs_ban)
            banlist << ban_general;

        setValue("Banlist/Pairs", banlist);
    }

    QStringList forbid_packages = value("ForbidPackages").toStringList();
    if (forbid_packages.isEmpty()) {
        forbid_packages << "New3v3Card";

        setValue("ForbidPackages", forbid_packages);
    }
}

