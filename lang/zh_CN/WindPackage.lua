-- translation for WindPackage

return {
	["wind"] = "风包",

	["#xiahouyuan"] = "疾行的猎豹",
	["xiahouyuan"] = "夏侯渊",
	["shensu"] = "神速",
	[":shensu"] = "你可以选择一至两项：跳过判定阶段和摸牌阶段，或跳过出牌阶段并弃置一张装备牌：你每选择上述一项，视为你使用一张无距离限制的普通【杀】。",
	["@shensu1"] = "跳过判定阶段和摸牌阶段，视为你使用一张无距离限制的普通【杀】",
	["@shensu2"] = "跳过出牌阶段并弃置一张装备牌，视为你使用一张无距离限制的普通【杀】",
	["~shensu1"] = "选择一名其他角色→点击确定",
	["~shensu2"] = "选择一张装备牌→选择一名其他角色→点击确定",

	["#caoren"] = "大将军",
	["caoren"] = "曹仁",
	["jushou"] = "据守",
	[":jushou"] = "回合结束阶段开始时，你可以摸三张牌，然后将武将牌翻面。",
	["jushou:yes"] = "摸三张牌，然后将武将牌翻面",

	["#huangzhong"] = "老当益壮",
	["huangzhong"] = "黄忠",
	["liegong"] = "烈弓",
	[":liegong"] = "每当你于出牌阶段内指定【杀】的目标后，若目标角色的手牌数大于或等于你的体力值，或目标角色的手牌数小于或等于你的攻击范围，你可以令此【杀】不能被【闪】响应。",
	["liegong:yes"] = "此【杀】不能被【闪】响应",

	["#weiyan"] = "嗜血的独狼",
	["weiyan"] = "魏延",
	["illustrator:weiyan"] = "SoniaTang",
	["kuanggu"] = "狂骨",
	[":kuanggu"] = "<font color=\"blue\"><b>锁定技。</b></font>每当你对一名距离1以内角色造成1点伤害后，你回复1点体力。",

	["#zhangjiao"] = "天公将军",
	["zhangjiao"] = "张角",
	["illustrator:zhangjiao"] = "LiuHeng",
	["leiji"] = "雷击",
	[":leiji"] = "每当你使用或打出一张【闪】时，你可以令一名角色进行一次判定：若判定结果为♠，你对该角色造成2点雷电伤害。",
	["@leiji"] = "请选择“雷击”的目标",
	["~leiji"] = "选择一名角色→点击确定",
	["guidao"] = "鬼道",
	[":guidao"] = "每当一名角色的判定牌生效前，你可以打出一张黑色牌代替之并获得原判定牌。",
	["@guidao-card"] = "请发动“%dest”来修改 %src 的 %arg 判定",
	["~guidao"] = "选择一张黑色牌→点击确定",
	["huangtian"] = "黄天",
	[":huangtian"] = "<font color=\"orange\"><b>主公技。</b></font><font color=\"green\"><b>阶段技。</b></font>其他群雄角色的出牌阶段，该角色可以交给你一张【闪】或【闪电】。",
	["huangtianv"] = "黄天送牌",

	["#xiaoqiao"] = "矫情之花",
	["xiaoqiao"] = "小乔",
	["hongyan"] = "红颜",
	[":hongyan"] = "<font color=\"blue\"><b>锁定技。</b></font>你的♠牌视为<font color=\"red\">♥</font>牌。",
	["tianxiang"] = "天香",
	[":tianxiang"] = "每当你受到一次伤害时，你可以弃置一张<font color=\"red\">♥</font>牌并选择一名其他角色：若如此做，你将此伤害转移给该角色，此伤害结算后该角色摸X张牌（X为该角色已损失的体力值）。",
	["@tianxiang-card"] = "请选择“天香”的目标",
	["~tianxiang"] = "选择一张<font color=\"red\">♥</font>手牌→选择一名其他角色→点击确定",
	["#HongyanJudge"] = "%from 的“<font color=\"yellow\"><b>红颜</b></font>”被触发，判定牌被视为<font color=\"red\">♥</font>",

	["#zhoutai"] = "历战之驱",
	["zhoutai"] = "周泰",
	["buqu"] = "不屈",
	[":buqu"] = "每当你扣减体力后，若你的体力为0或更低，你可以将牌堆顶的一张牌置于你的武将牌上，称为“不屈牌”。当且仅当出现同点数的“不屈牌”，你进入濒死状态。若你的武将牌上有“不屈牌”，你的体力值为-X+1。（X为“不屈牌”的数量）",
	["buqu:alive"] = "发动“不屈”",
	["buqu:dead"] = "不发动“不屈”",
	["#BuquDuplicate"] = "%from 发动“<font color=\"yellow\"><b>不屈</b></font>”失败，其“不屈牌”中有 %arg 组重复点数",
	["#BuquDuplicateGroup"] = "第 %arg 组重复点数为 %arg2",
	["$BuquDuplicateItem"] = "重复“不屈牌”: %card",
	["$BuquRemove"] = "%from 移除了“不屈牌”：%card", 

	["#yuji"] = "太平道人",
	["yuji"] = "于吉",
	["illustrator:yuji"] = "LiuHeng",
	["guhuo"] = "蛊惑",
	[":guhuo"] = "每当你需要使用或打出一张基本牌或非延时类锦囊牌时，你可以将一张手牌背面朝上置于桌上，体力值大于0的其他角色选择是否质疑，然后你展示该牌：若无角色质疑，该牌按你所述类型结算；若有角色质疑：若该牌为真，质疑角色各失去1点体力；若该牌为假，质疑角色各摸一张牌；且若该牌为<font color=\"red\">♥</font>且为真，则依旧进行结算，否则将其置入弃牌堆。",
	["guhuo_pile"] = "蛊惑牌堆",
	["#Guhuo"] = "%from 发动了“%arg2”，声明此牌为 【%arg】，指定的目标为 %to",
	["#GuhuoNoTarget"] = "%from 发动了“%arg2”，声明此牌为 【%arg】",
	["#GuhuoCannotQuestion"] = "%from 当前体力值为 %arg，无法质疑",
	["guhuo:question"] = "质疑",
	["guhuo:noquestion"] = "不质疑",
	["question"] = "质疑",
	["noquestion"] = "不质疑",
	["#GuhuoQuery"] = "%from 表示 %arg",
	["$GuhuoResult"] = "%from 发动“<font color=\"yellow\"><b>蛊惑</b></font>”所用的牌是 %card",
	["guhuo_saveself"] = "“蛊惑”【桃】或【酒】",
	["guhuo_slash"] = "“蛊惑”【杀】",
	["normal_slash"] = "普通杀",

--Lines

--曹仁
	["$jushou1"] = "我先休息一会儿！",
	["$jushou2"] = "尽管来吧！",
	["~caoren"] = "实在是守不住了……",
	
--夏侯渊
	["$shensu1"] = "吾善于千里袭人！",
	["$shensu2"] = "取汝首级犹如探囊取物！",
	["~xiahouyuan"] = "竟然比我还…快……",
	
--黄忠
	["$liegong1"] = "百步穿杨！",
	["$liegong2"] = "中！",
	["~huangzhong"] = "不得不服老了……",
	
--魏延
	["$kuanggu1"] = "我会怕你吗？",
	["$kuanggu2"] = "真是美味呀！",
	["~weiyan"] = "谁敢杀我！啊……",
	
--小乔
	["$tianxiang1"] = "接着哦~",
	["$tianxiang2"] = "替我挡着~",
	["$hongyan"] = "（红颜~）",
	["~xiaoqiao"] = "公瑾…我先走一步……",
	
--周泰
	["$buqu1"] = "我绝不会倒下！",
	["$buqu2"] = "还不够！",
	["~zhoutai"] = "已经尽力了……",
	
--张角
	["$leiji1"] = "雷公助我！",
	["$leiji2"] = "以我之真气，合天地之造化。",
	["$guidao1"] = "哼哼哼哼……",
	["$guidao2"] = "天下大势，为我所控！",
	["$huangtian1"] = "苍天已死，黄天当立！",
	["$huangtian2"] = "岁在甲子，天下大吉！",
	["~zhangjiao"] = "黄天…也死了……",
	
--于吉
	["$guhuo1"] = "你信吗？",
	["$guhuo2"] = "猜猜看哪？",
	["~yuji"] = "竟然…被猜到了……",

-- guhuo dialog
	["single_target"] = "单目标锦囊",
	["multiple_targets"] = "多目标锦囊",
}
