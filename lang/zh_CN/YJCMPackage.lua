-- translation for YJCM Package

return {
	["YJCM"] = "一将成名",

	["#caozhi"] = "八斗之才",
	["caozhi"] = "曹植",
	["luoying"] = "落英",
	[":luoying"] = "你的回合外，其他角色的判定牌或弃置的牌进入弃牌堆时，若该牌为♣，你可以获得之。";
	["jiushi"] = "酒诗",
	[":jiushi"] = "若你的武将牌正面朝上，你可以将武将牌翻面，视为你使用了一张【酒】。每当你受到伤害扣减体力前，若武将牌背面朝上，你可以在伤害结算后将武将牌翻至正面朝上。",

	["#yujin"] = "魏武之刚",
	["yujin"] = "于禁",
	["yizhong"] = "毅重",
	[":yizhong"] = "<font color=\"blue\"><b>锁定技。</b></font>若你的装备区没有防具牌，黑色【杀】对你无效。",

	["#fazheng"] = "蜀汉的辅翼",
	["fazheng"] = "法正",
	["enyuan"] = "恩怨",
	[":enyuan"] = "每当你获得一名其他角色的两张或更多的牌后，你可以令其摸一张牌。每当你受到1点伤害后，你可以令伤害来源选择一项：交给你一张手牌，或失去1点体力。",
	["EnyuanGive"] = "请交给目标角色 %arg 张手牌",
	["xuanhuo"] = "眩惑",
	[":xuanhuo"] = "摸牌阶段，你可以放弃摸牌并选择一名其他角色：若如此做，该角色摸两张牌，然后该角色可以对其攻击范围内由你选择的另一名角色使用一张【杀】，否则令你获得其两张牌。",
	["@xuanhuo-card"] = "你可以发动“眩惑”",
	["~xuanhuo"] = "选择一名其他角色→点击确定",
	["xuanhuo-slash"] = "请对已选定的目标使用一张【杀】",

	["#masu"] = "怀才自负",
	["masu"] = "马谡",
	["xinzhan"] = "心战",
	[":xinzhan"] = "<font color=\"green\"><b>阶段技。</b></font>出牌阶段，若你的手牌数大于你的体力上限，你可以观看牌堆顶的3张牌，展示并获得其中任意数量的<font color=\"red\">♥</font>牌，然后将其余的牌以任意顺序置于牌堆顶。",
	["huilei"] = "挥泪",
	[":huilei"] = "<font color=\"blue\"><b>锁定技。</b></font>杀死你的角色弃置其所有牌。",
	["#HuileiThrow"] = "%from 的“%arg”被触发，伤害来源 %to 弃置所有牌",

	["#xushu"] = "忠孝的侠士",
	["xushu"] = "徐庶",
	["wuyan"] = "无言",
	[":wuyan"] = "<font color=\"blue\"><b>锁定技。</b></font>每当你造成或受到伤害时，你防止锦囊牌的伤害。",
	["jujian"] = "举荐",
	[":jujian"] = "回合结束阶段开始时，你可以弃置一张非基本牌并选择一名其他角色：若如此做，该角色选择一项：摸两张牌，或回复1点体力，或重置武将牌并将其翻至正面朝上。",
	["@jujian-card"] = "你可以发动“举荐”",
	["~jujian"] = "选择一张非基本牌→选择一名其他角→点击确定",
	["#WuyanBad"] = "%from 的“%arg2”被触发，本次伤害被防止",
	["#WuyanGood"] = "%from 的“%arg2”被触发，防止了本次伤害",
	["@jujian-discard"] = "请弃置一张非基本牌",
	["jujian:draw"] = "摸两张牌",
	["jujian:recover"] = "回复1点体力",
	["jujian:reset"] = "重置并翻至正面朝上",

	["#lingtong"] = "豪情烈胆",
	["lingtong"] = "凌统",
	["xuanfeng"] = "旋风",
	[":xuanfeng"] = "每当你失去一张装备区的装备牌后，或弃牌阶段弃置了两张或更多的牌后（每阶段限一次），你可以弃置一名其他角色的一张牌，然后再弃置一名其他角色的一张牌。",
	["xuanfeng:nothing"] = "不发动",
	["xuanfeng:discard"] = "弃置一至两名其他角色的两张牌",

	["#wuguotai"] = "武烈皇后",
	["wuguotai"] = "吴国太",
	["ganlu"] = "甘露",
	[":ganlu"] = "<font color=\"green\"><b>阶段技。</b></font>出牌阶段，你可以令装备区的装备牌数量差不超过X的两名角色交换他们装备区的装备牌。（X为你已损失的体力值）",
	["buyi"] = "补益",
	[":buyi"] = "每当一名角色进入濒死状态时，你可以展示该角色的一张手牌：若该牌为非基本牌，该角色弃置该牌，然后回复1点体力。",
	["#GanluSwap"] = "%from 交换了 %to 的装备",

	["#xusheng"] = "江东的铁壁",
	["xusheng"] = "徐盛",
	["pojun"] = "破军",
	[":pojun"] = "每当你使用【杀】对目标角色造成一次伤害后，你可以令其摸X张牌，然后将其武将牌翻面。（X为该角色的体力值且至多为5）",

	["#gaoshun"] = "攻无不克",
	["gaoshun"] = "高顺",
	["xianzhen"] = "陷阵",
	[":xianzhen"] = "<font color=\"green\"><b>阶段技。</b></font>出牌阶段，你可以与一名其他角色拼点：若你赢，你拥有以下技能：此回合内，该角色的防具无效，你无视与该角色的距离，你对该角色使用【杀】无数量限制；若你没赢，你不能使用【杀】，直到回合结束。",
	["jinjiu"] = "禁酒",
	[":jinjiu"] = "<font color=\"blue\"><b>锁定技。</b></font>你的【酒】视为【杀】。",
	["@xianzhen-slash"] = "你可以对“陷阵”目标使用任意数量的【杀】",

	["#chengong"] = "刚直壮烈",
	["chengong"] = "陈宫",
	["mingce"] = "明策",
	[":mingce"] = "<font color=\"green\"><b>阶段技。</b></font>出牌阶段，你可以将一张装备牌或【杀】交给一名其他角色：若如此做，该角色可以视为对其攻击范围内由你选择的另一名角色使用一张【杀】，否则其摸一张牌。",
	["zhichi"] = "智迟",
	[":zhichi"] = "<font color=\"blue\"><b>锁定技。</b></font>你的回合外，每当你受到一次伤害后，【杀】和非延时类锦囊牌对你无效，直到回合结束。",
	["mingce:use"] = "对攻击范围内的一名角色使用一张【杀】",
	["mingce:draw"] = "摸一张牌",
	["#ZhichiDamaged"] = "%from 受到了伤害，本回合内【<font color=\"yellow\"><b>杀</b></font>】和非延时锦囊都将对其无效",
	["#ZhichiAvoid"] = "%from 的“%arg”被触发，【<font color=\"yellow\"><b>杀</b></font>】和非延时锦囊对其无效",
	["@late"] = "智迟",

	["#zhangchunhua"] = "冷血皇后",
	["zhangchunhua"] = "张春华",
	["jueqing"] = "绝情",
	[":jueqing"] = "<font color=\"blue\"><b>锁定技。</b></font>伤害结算开始前，你将要造成的伤害视为体力流失。",
	["shangshi"] = "伤逝",
	[":shangshi"] = "每当你于弃牌阶段外手牌数改变后，或已损失体力值改变后，或弃牌阶段结束后，若你的手牌数小于X，你可以将手牌补至X张。（X为你已损失的体力值且至多为2）",

    ["#zhonghui"] = "桀骜的野心家",
	["zhonghui"] = "钟会",
	["quanji"] = "权计",
	["#quanji"] = "权计",
	[":quanji"] = "每当你受到1点伤害后，你可以摸一张牌，然后将一张手牌置于武将牌上，称为“权”。每有一张“权”，你的手牌上限+1。",
	[":#quanji"] = "每当你受到1点伤害后，你可以摸一张牌，然后将一张手牌置于武将牌上，称为“权”。",
	["zili"] = "自立",
	[":zili"] = "<font color=\"purple\"><b>觉醒技。</b></font>回合开始阶段开始时，若“权”大于或等于三张，你失去1点体力上限，摸两张牌或回复1点体力，然后获得技能“排异”（<font color=\"green\"><b>阶段技。</b></font>出牌阶段，你可以将一张“权”置入弃牌堆并选择一名角色：若如此做，该角色摸两张牌。若该角色手牌数大于你的手牌数，你对其造成1点伤害）。",
	["#ZiliWake"] = "%from 的“权”为 %arg 张，触发“%arg2”觉醒",
	["zili:draw"] = "摸两张牌",
	["zili:recover"] = "回复1点体力",
	["paiyi"] = "排异",
	[":paiyi"] = "<font color=\"green\"><b>阶段技。</b></font>出牌阶段，你可以将一张“权”置入弃牌堆并选择一名角色：若如此做，该角色摸两张牌。若该角色手牌数大于你的手牌数，你对其造成1点伤害",
	["power"] = "权",
	["QuanjiPush"] = "请将一张手牌置于武将牌上",

	["designer:caozhi"] = "Foxear",
	["designer:yujin"] = "城管无畏",
	["designer:fazheng"] = "Michael_Lee",
	["designer:masu"] = "点点",
	["designer:xushu"] = "双叶松",
	["designer:xusheng"] = "阿江",
	["designer:lingtong"] = "ShadowLee",
	["designer:wuguotai"] = "章鱼咬你哦",
	["designer:gaoshun"] = "羽柴文理",
	["designer:chengong"] = "Kaycent",
	["designer:zhangchunhua"] = "JZHIEI",
	
-- Lines

--曹植
	["$luoying1"] = "别着急哟，给我就好。",
	["$luoying2"] = "这些都是我的！",
	["$jiushi1"] = "置酒高殿上，亲友从我游。",
	["$jiushi2"] = "走马行酒醴，驱车布鱼肉。",
	["~caozhi"] = "本是同根生，相煎何太急。",
	
--于禁
	["$yizhong1"] = "不先为备，何以待敌。",
	["$yizhong2"] = "稳重行军，百战不殆！",
	["~yujin"] = "我…无颜面对丞相了……",

--法正
	["$enyuan1"] = "得人恩果千年记。",
	["$enyuan2"] = "滴水之恩，涌泉以报。",
	["$enyuan3"] = "谁敢得罪我！",
	["$enyuan4"] = "睚眦之怨，无不报复。",
	["$xuanhuo1"] = "重用许靖，以眩远近。",
	["$xuanhuo2"] = "给你的，十倍奉还给我！",
	["~fazheng"] = "蜀翼既折，蜀汉哀矣……",

--马谡	
	["$xinzhan"] = "吾通晓兵法，世人皆知。",
	["$huilei1"] = "丞相视某如子，某以丞相为父。",
	["$huilei2"] = "谡愿以死安大局。",

--徐庶	
	["$wuyan1"] = "唉，一切尽在不言中。",
	["$wuyan2"] = "嘘，言多必失啊。",
	["$jujian1"] = "我看好你！",
	["$jujian2"] = "将军岂愿抓牌乎？",
	["~xushu"] = "娘，孩儿不孝，向您…请罪……",

--凌统
	["$xuanfeng1"] = "伤敌于千里之外！",
	["$xuanfeng2"] = "索命于须臾之间！",
	["~lingtong"] = "大丈夫不惧死亡",
	
--吴国太	
	["$ganlu1"] = "男婚女嫁，需当交换文定之物。",
	["$ganlu2"] = "此真乃吴之佳婿也。",
	["$buyi1"] = "吾乃吴国之母，何人敢造次。",
	["$buyi2"] = "有老身在，汝等尽可放心。",
	["~wuguotai"] = "卿等务必用心辅佐仲谋……",

--徐盛
	["$pojun1"] = "大军在此！汝等休想前进一步！",
	["$pojun2"] = "敬请养精蓄锐！",
	["~xusheng"] = "盛不能奋身出命，不亦辱乎。",

--高顺
	["$xianzhen1"] = "攻无不克，战无不胜。",
	["$xianzhen2"] = "破阵斩将，易如反掌。",
	["$jinjiu1"] = "贬酒阙色，所以无污。",
	["$jinjiu2"] = "避嫌远疑，所以无误。",
	["~gaoshun"] = "生死有命……",

--陈宫
	["cv:chengong"] = "V7, 官方",
	["$mingce1"] = "如此，霸业可图也！",
	["$mingce2"] = "如此，一击可擒也！",
	["$zhichi1"] = "如今之计，唯有退守，再做决断！",
	["$zhichi2"] = "若吾早知如此。",
	["~chengong"] = "请出就戮！",
	
--张春华
	["$shangshi1"] = "无情者伤人，有情者自伤",
	["$shangshi2"] = "自损八百，可伤敌一千",
	["$jueqing1"] = "你的死活与我何干",
	["$jueqing2"] = "无来无去，不悔不怨",
	["~zhangchunhua"] = "怎能如此对我……",
	
--钟会	
	["cv:zhonghui"] = "风叹息",
    ["$quanji1"] = "终于轮到我掌权了。",
    ["$quanji2"] = "夺得军权方能施展一番。",
    ["$paiyi1"] = "待我设计构陷之。",
    ["$paiyi2"] = "非我族者，其心可诛。",
	["$zili"] = "以我之才，何必屈人之下？",
	["$ZiliAnimate"] = "anim=image/animate/zili.png",
	["~zhonghui"] = "大权在手竟一夕败亡，时耶？命耶？",


	-- illustrator
	["illustrator:caozhi"] = "木美人",
	["illustrator:yujin"] = "Yi章",
	["illustrator:fazheng"] = "雷没才",
	["illustrator:masu"] = "张帅",
	["illustrator:xushu"] = "XINA",
	["illustrator:lingtong"] = "绵Myan",
	["illustrator:xusheng"] = "天空之城",
	["illustrator:wuguotai"] = "zoo",
	["illustrator:chengong"] = "黑月乱",
	["illustrator:gaoshun"] = "鄧Sir",
	["illustrator:zhangchunhua"] = "樱花闪乱",
	["illustrator:zhonghui"] = "雪君S",
}
