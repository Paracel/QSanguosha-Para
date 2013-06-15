-- translation for SP Package

return {
	["sp"] = "SP",

	["#yangxiu"] = "恃才放旷",
	["yangxiu"] = "杨修",
	["illustrator:yangxiu"] = "张可",
	["jilei"] = "鸡肋",
	[":jilei"] = "每当你受到伤害时，你可以选择一种牌的类别，伤害来源不能使用、打出或弃置其该类别的手牌，直到回合结束。",
	["@jilei_basic"] = "鸡肋（基本牌）",
	["@jilei_equip"] = "鸡肋（装备牌）",
	["@jilei_trick"] = "鸡肋（锦囊牌）",
	["danlao"] = "啖酪",
	[":danlao"] = "每当一张锦囊牌指定了包括你在内的至少两名目标时，你可以摸一张牌，然后该锦囊牌对你无效。",
	["#Jilei"] = "由于“<font color=\"yellow\"><b>鸡肋</b></font>”效果，%from 本回合不能使用、打出或弃置 %arg",
	["#JileiClear"] = "%from 的“<font color=\"yellow\"><b>鸡肋</b></font>”效果消失",
	["#DanlaoAvoid"] = "“%arg2”效果被触发，【%arg】 对 %from 无效",

	["#gongsunzan"] = "白马将军",
	["gongsunzan"] = "公孙瓒",
	["illustrator:gongsunzan"] = "Vincent",
	["yicong"] = "义从",
	[":yicong"] = "<font color=\"blue\"><b>锁定技。</b></font>若你的体力值大于2，你与其他角色的距离-1；若你的体力值小于或等于2，其他角色与你的距离+1。",

	["#yuanshu"] = "仲家帝",
	["yuanshu"] = "SP袁术",
	["&yuanshu"] = "袁术",
	["illustrator:yuanshu"] = "吴昊",
	["yongsi"] = "庸肆",
	[":yongsi"] = "<font color=\"blue\"><b>锁定技。</b></font>摸牌阶段，你额外摸X张牌。弃牌阶段开始时，你须弃置X张牌。（X为现存势力数）",
	["weidi"] = "伪帝",
	[":weidi"] = "<font color=\"blue\"><b>锁定技。</b></font>你拥有且可以发动当前主公的主公技。",
	["@weidi-jijiang"] = "请发动“激将”",
	["#YongsiGood"] = "%from 的“%arg2”被触发，额外摸了 %arg 张牌",
	["#YongsiBad"] = "%from 的“%arg2”被触发，须弃置 %arg 张牌",
	["#YongsiJilei"] = "%from 的“%arg2”被触发，由于“<font color=\"yellow\"><b>鸡肋</b></font>”的效果，仅弃置了 %arg 张牌", 
	["#YongsiWorst"] = "%from 的“%arg2”被触发，弃置了所有牌（共 %arg 张）",

	["#sp_guanyu"] = "汉寿亭侯",
	["sp_guanyu"] = "SP关羽",
	["&sp_guanyu"] = "关羽",
	["illustrator:sp_guanyu"] = "LiuHeng",
	["danji"] = "单骑",
	[":danji"] = "<font color=\"purple\"><b>觉醒技。</b></font>准备阶段开始时，若你的手牌数大于体力值，且本局游戏主公为曹操，你失去1点体力上限，然后获得技能“马术”。",
	["$DanjiAnimate"] = "image=image/animate/danji.png",
	["#DanjiWake"] = "%from 的手牌数 %arg 大于体力值 %arg2 ，且本局游戏主公为曹操，触发“<font color=\"yellow\"><b>单骑</b></font>”觉醒",

	["#caohong"] = "福将",
	["caohong"] = "曹洪",
	["illustrator:caohong"] = "LiuHeng",
	["yuanhu"] = "援护",
	[":yuanhu"] = "结束阶段开始时，你可以将一张装备牌置于一名角色装备区内：若此牌为武器牌，你弃置该角色距离1的一名角色区域内的一张牌；若此牌为防具牌，该角色摸一张牌；若此牌为坐骑牌，该角色回复1点体力。",
	["@yuanhu-equip"] = "你可以发动“援护”",
	["@yuanhu-discard"] = "请选择 %src 距离1的一名角色",
	["~yuanhu"] = "选择一张装备牌→选择一名角色→点击确定",

	["#guanyinping"] = "武姬",
	["guanyinping"] = "关银屏",
	["illustrator:guanyinping"] = "木美人",
	["xueji"] = "血祭",
	[":xueji"] = "<font color=\"green\"><b>阶段技。</b></font>你可以弃置一张红色牌并选择你攻击范围内的至多X名其他角色：若如此做，你对这些角色各造成1点伤害，然后这些角色各摸一张牌。（X为你已损失的体力值）",
	["huxiao"] = "虎啸",
	[":huxiao"] = "<font color=\"blue\"><b>锁定技。</b></font>每当你于出牌阶段使用【杀】被【闪】抵消后，本阶段你可以额外使用一张【杀】。",
	["wuji"] = "武继",
	[":wuji"] = "<font color=\"purple\"><b>觉醒技。</b></font>结束阶段开始时，若你于本回合造成了至少3点伤害，你增加1点体力上限，回复1点体力，然后失去技能“虎啸”。",
	["$WujiAnimate"] = "image=image/animate/wuji.png",
	["#WujiWake"] = "%from 本回合已造成 %arg 点伤害，触发“%arg2”觉醒",

	["#xiahouba"] = "棘途壮志",
	["xiahouba"] = "夏侯霸",
	["illustrator:xiahouba"] = "熊猫探员",
	["baobian"] = "豹变",
	[":baobian"] = "<font color=\"blue\"><b>锁定技。</b></font>若你的体力值为3或更低，你拥有技能“挑衅”。若你的体力值为2或更低，你拥有技能“咆哮”。若你的体力值为1或更低，你拥有技能“神速”。",

	["#chenlin"] = "破竹之咒",
	["chenlin"] = "陈琳",
	["illustrator:chenlin"] = "木美人",
	["bifa"] = "笔伐",
	[":bifa"] = "结束阶段开始时，你可以将一张手牌移出游戏并选择一名其他角色：若如此做，该角色的回合开始时，观看该牌，然后可以交给你一张与该牌类型相同的牌并获得该牌，否则将该牌置入弃牌堆，然后失去1点体力。",
	["@bifa-remove"] = "你可以发动“笔伐”",
	["~bifa"] = "选择一张手牌→选择一名其他角色→点击确定",
	["@bifa-give"] = "请交给目标角色一张类型相同的手牌",
	["songci"] = "颂词",
	[":songci"] = "出牌阶段，你可以令一名手牌数大于体力值的角色弃置两张牌，或令一名手牌数小于体力值的角色摸两张牌。对每名角色限一次。",
	["@songci"] = "颂词",
	["$BifaView"] = "%from 观看了 %arg 牌 %card",

	["#erqiao"] = "江东之花",
	["erqiao"] = "大乔＆小乔",
	["&erqiao"] = "大乔小乔",
	["illustrator:erqiao"] = "木美人",
	["xingwu"] = "星舞",
	[":xingwu"] = "弃牌阶段开始时，你可以将一张与你本回合使用的牌颜色均不同的手牌置于武将牌上。若你有三张“星舞牌”，你将其置入弃牌堆，然后选择一名男性角色，你对其造成2点伤害并弃置其装备区的所有牌。",
	["@xingwu"] = "你可以发动“星舞”将一张手牌置于武将牌上",
	["@xingwu-choose"] = "请选择一名男性角色",
	["luoyan"] = "落雁",
	[":luoyan"] = "<font color=\"blue\"><b>锁定技。</b></font>若你的武将牌上有“星舞牌”，你拥有技能“天香”和“流离”。",

	["#zhugeke"] = "兴家赤族",
	["zhugeke"] = "诸葛恪",
	["illustrator:zhugeke"] = "LiuHeng",
	["aocai"] = "傲才",
	[":aocai"] = "你的回合外，每当你需要使用或打出一张基本牌时，你可以观看牌堆顶的两张牌，然后使用或打出其中一张该类别的基本牌。",
	["duwu"] = "黩武",
	[":duwu"] = "出牌阶段，你可以弃置任意数量的牌并选择攻击范围内的一名体力值等于该数量的其他角色：若如此做，你对该角色造成1点伤害。若此伤害令该角色进入濒死状态，濒死结算后你失去1点体力，且本阶段你不能再次发动“黩武”。",

	-- HuLao Pass
	["Hulaopass"] = "虎牢关模式",
	["HulaoPass"] = "虎牢关",

	["#shenlvbu1"] = "最强神话",
	["shenlvbu1"] = "吕布-虎牢关",
	["&shenlvbu1"] = "最强神话",
	["illustrator:shenlvbu1"] = "LiuHeng",
	["#shenlvbu2"] = "暴怒的战神",
	["shenlvbu2"] = "吕布-虎牢关",
	["&shenlvbu2"] = "暴怒战神",
	["illustrator:shenlvbu2"] = "LiuHeng",
	["xiuluo"] = "修罗",
	[":xiuluo"] = "准备阶段开始时，你可以弃置一张与判定区内延时类锦囊牌花色相同的手牌：若如此做，你弃置该延时类锦囊牌。",
	["@xiuluo"] = "请弃置一张与判定区某一张牌花色相同的手牌",
	["shenwei"] = "神威",
	[":shenwei"] = "<font color=\"blue\"><b>锁定技。</b></font>摸牌阶段，你额外摸两张牌。你的手牌上限+2。",
	["shenji"] = "神戟",
	[":shenji"] = "<font color=\"blue\"><b>锁定技。</b></font>若你的装备区没有武器牌，你使用【杀】可以额外选择至多两个目标。",

	["#HulaoTransfigure"] = "%arg 变身为 %arg2, 第二阶段开始！",
	["#Reforming"] = "%from 进入重整状态",
	["#ReformingRecover"] = "%from 在重整状态中回复了 %arg 点体力",
	["#ReformingDraw"] = "%from 在重整状态中摸了 %arg 张牌",
	["#ReformingRevive"] = "%from 从重整状态中复活！",
	["draw_1v3"] = "重整摸牌",
	["weapon_recast"] = "武器重铸",
	["Hulaopass:recover"] = "回复1点体力",
	["Hulaopass:draw"] = "摸一张牌",
	["$StageChange"] = "image=image/animate/StageChange.png",

	["sp_cards"] = "SP卡牌包",
	["sp_moonspear"] = "银月枪",
	[":sp_moonspear"] = "装备牌·武器<br />攻击范围：３<br />武器特效：你的回合外，每当你使用或打出一张黑色牌时，你可以令你攻击范围内的一名其他角色打出一张【闪】，否则该角色受到你对其造成的1点伤害。",
	["@sp_moonspear"] = "请选择攻击范围内的一名其他角色令其打出一张【闪】",
	["@moon-spear-jink"] = "【银月枪】效果被触发，请打出一张【闪】",
}
