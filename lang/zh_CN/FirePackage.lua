-- translation for FirePackage

return {
	["fire"] = "火包",

	["#xunyu"] = "王佐之才",
	["xunyu"] = "荀彧",
	["quhu"] = "驱虎",
	[":quhu"] = "<font color=\"green\"><b>阶段技。</b></font>出牌阶段，你可以与一名体力值大于你的角色拼点：若你赢，该角色对其攻击范围内的另一名由你选择的角色造成1点伤害；若你没赢，该角色对你造成1点伤害。",
	["#QuhuNoWolf"] = "%from “<font color=\"yellow\"><b>驱虎</b></font>”拼点赢，由于 %to 攻击范围内没有其他角色，结算中止",
	["jieming"] = "节命",
	[":jieming"] = "每当你受到1点伤害后，你可以令一名角色将手牌数补至等于体力上限的张数（至多五张）。",
	["jieming:yes"] = "你可以令一名角色将手牌数补至等于体力上限的张数（至多五张）",
	["@jieming"] = "请选择“节命”的目标",
	["~jieming"] = "选择一名角色→点击确定",

	["#dianwei"] = "古之恶来",
	["dianwei"] = "典韦",
	["qiangxi"] = "强袭",
	[":qiangxi"] = "<font color=\"green\"><b>阶段技。</b></font>出牌阶段，你可以失去1点体力或弃置一张装备牌并选择一名攻击范围内的角色：若如此做，你对该角色造成1点伤害。",

	["#wolong"] = "卧龙",
	["wolong"] = "卧龙诸葛亮",
	["&wolong"] = "诸葛亮",
	["bazhen"] = "八阵",
	[":bazhen"] = "<font color=\"blue\"><b>锁定技。</b></font>若你的装备区没有防具牌，视为你装备【八卦阵】。",
	["bazhen:yes"] = "发动【八卦阵】效果",
	["huoji"] = "火计",
	[":huoji"] = "你可以将一张红色手牌当【火攻】使用。",
	["kanpo"] = "看破",
	[":kanpo"] = "你可以将一张黑色手牌当【无懈可击】使用。",

	["#pangtong"] = "凤雏",
	["pangtong"] = "庞统",
	["lianhuan"] = "连环",
	[":lianhuan"] = "你可以将一张♣手牌当【铁索连环】使用或重铸。",
	["niepan"] = "涅槃",
	[":niepan"] = "<font color=\"red\"><b>限定技。</b></font>当你处于濒死状态时，你可以弃置你区域里的牌，将武将牌翻至正面朝上并重置之，然后回复至3点体力。",
	["@nirvana"] = "涅槃",
	["niepan:yes"] = "弃置你区域里的牌，将武将牌翻至正面朝上并重置之，然后回复至3点体力",

	["#taishici"] = "笃烈之士",
	["taishici"] = "太史慈",
	["tianyi"] = "天义",
	[":tianyi"] = "<font color=\"green\"><b>阶段技。</b></font>出牌阶段，你可以与一名其他角色拼点：若你赢，你拥有以下技能：此回合内你可以额外使用一张【杀】，你使用【杀】可以额外选择一名目标且无距离限制；若你没赢，你不能使用【杀】，直到回合结束。",

	["#yuanshao"] = "高贵的名门",
	["yuanshao"] = "袁绍",
	["luanji"] = "乱击",
	[":luanji"] = "你可以将两张相同花色的手牌当【万箭齐发】使用。",
	["xueyi"] = "血裔",
	[":xueyi"] = "<font color=\"orange\"><b>主公技。</b></font><font color=\"blue\"><b>锁定技。</b></font>场上每有一名存活的其他群雄角色，你的手牌上限+2。",

	["#yanliangwenchou"] = "虎狼兄弟",
	["yanliangwenchou"] = "颜良·文丑",
	["&yanliangwenchou"] = "颜良文丑",
	["shuangxiong"] = "双雄",
	[":shuangxiong"] = "摸牌阶段，你可以放弃摸牌并进行一次判定：若如此做，你获得此判定牌，你可以将与此判定牌颜色不同的牌当【决斗】使用，直到回合结束。",
	["shuangxiong:yes"] = "放弃摸牌并进行一次判定：若如此做，你获得此判定牌，你可以将与此判定牌颜色不同的牌当【决斗】使用，直到回合结束",

	["#pangde"] = "人马一体",
	["pangde"] = "庞德",
	["mengjin"] = "猛进",
	[":mengjin"] = "你使用的【杀】被目标角色的【闪】抵消后，你可以弃置该角色的一张牌。",
	["mengjin:yes"] = "你可以弃置该角色一张牌",
	
-- Lines

--荀彧
	["$quhu1"] = "借你之手，与他一搏吧。",
	["$quhu2"] = "此乃驱虎吞狼之计。",
	["$jieming1"] = "秉忠贞之志，守谦退之节。",
	["$jieming2"] = "我，永不背弃！",
	["~xunyu"] = "主公要臣死，臣不得不死！",
--典韦
	["$qiangxi1"] = "吃我一戟！",
	["$qiangxi2"] = "看我三步之内，取你小命！",
	["~dianwei"] = "主公，快走！",
--庞统
	["$lianhuan1"] = "伤一敌，可连其百。",
	["$lianhuan2"] = "统统连起来吧。",
	["$niepan1"] = "浴火重生！",
	["$niepan2"] = "凤雏岂能消亡？",
	["$NiepanAnimate"] = "anim=image/animate/niepan.png",
	["~pangtong"] = "看来，我命中注定将丧命于此。",
--卧龙诸葛亮
	["$bazhen1"] = "你可识得此阵？",
	["$bazhen2"] = "太极生两仪，两仪生四象，四象生八卦。",
	["$kanpo1"] = "雕虫小技。",
	["$kanpo2"] = "你的计谋被识破了。",
	["$huoji1"] = "燃烧吧！",
	["$huoji2"] = "此火可助我军大获全胜。",
	["~wolong"] = "我的计谋竟被……",
--太史慈
	["$tianyi1"] = "我当要替天行道！",
	["$tianyi2"] = "请助我一臂之力！",
	["~taishici"] = "大丈夫，当带三尺之剑，立不世之功！",
--袁绍
	["$luanji1"] = "弓箭手，准备放箭！",
	["$luanji2"] = "全都去死吧！",
	["~yuanshao"] = "老天不助我袁家呀！",
--颜良文丑
	["$shuangxiong1"] = "吾乃河北上将颜良（文丑）是也。",
	["$shuangxiong2"] = "快来与我等决一死战！",
	["~yanliangwenchou"] = "这红脸长须大将是？",
--庞德
	["$mengjin1"] = "你！可敢挡我？",
	["$mengjin2"] = "我要杀你们个片甲不留！",
	["~pangde"] = "四面都是水，我命休矣……",

	-- illustrator
	["illustrator:yuanshao"] = "SoniaTang",
	["illustrator:pangde"] = "LiuHeng",
	["illustrator:wolong"] = "北",
	["illustrator:xunyu"] = "LiuHeng",
	["illustrator:dianwei"] = "小冷",
	["illustrator:taishici"] = "Tuu.",
}

