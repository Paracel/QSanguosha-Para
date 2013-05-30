-- translation for Special 3v3 Package

return {
	["Special1v1"] = "1v1",
	["New1v1Card"] = "1v1卡牌",

	["kof_zhangliao"] = "张辽1v1",
	["&kof_zhangliao"] = "张辽",
	["koftuxi"] = "突袭",
	[":koftuxi"] = "摸牌阶段，若你的手牌数小于对手的手牌数，你可以少摸一张牌并你获得对手的一张手牌。",
					-- [[身份局：摸牌阶段，你可以少摸一张牌并选择一名手牌数大于你的手牌数的其他角色：若如此做，你获得该角色一张手牌。]]
	["koftuxi-invoke"] = "你可以发动“突袭”<br/> <b>操作提示</b>: 选择一名其他角色→点击确定<br/>",

	["kof_zhenji"] = "甄姬1v1",
	["&kof_zhenji"] = "甄姬",
	["kofqingguo"] = "倾国",
	[":kofqingguo"] = "你可以将一张装备区的装备牌当【闪】使用或打出。",

	["kof_huangzhong"] = "黄忠1v1",
	["&kof_huangzhong"] = "黄忠",
	["kofliegong"] = "烈弓",
	[":kofliegong"] = "每当你于出牌阶段内指定【杀】的目标后，若目标角色的手牌数大于或等于你的体力值，你可以令此【杀】不能被【闪】响应。",

	["kof_jiangwei"] = "姜维1v1",
	["&kof_jiangwei"] = "姜维",

	["kof_sunshangxiang"] = "孙尚香1v1",
	["&kof_sunshangxiang"] = "孙尚香",
	["yinli"] = "姻礼",
	[":yinli"] = "其他角色的回合内，该角色拥有的装备牌以未经转化的方式置入弃牌堆时，你可以获得之。",
	["kofxiaoji"] = "枭姬",
	[":kofxiaoji"] = "每当你失去一张装备区的装备牌后，你可以选择一项：摸两张牌，或回复1点体力。",
	["kofxiaoji:draw"] = "摸两张牌",
	["kofxiaoji:recover"] = "回复1点体力",
	["kofxiaoji:cancel"] = "不发动",

	["#hejin"] = "色厉内荏",
	["hejin"] = "何进",
	["illustrator:hejin"] = "G.G.G.",
	["mouzhu"] = "谋诛",
	[":mouzhu"] = "<font color=\"green\"><b>阶段技。</b></font>你可以令对手交给你一张手牌：若你的手牌数大于对手的手牌数，对手选择一项：视为对你使用一张无距离限制的【杀】，或视为对你使用一张【决斗】。",
				--[[身份局：阶段技。你可以令一名有手牌的其他角色交给你一张手牌：若你的手牌数大于该角色的手牌数，该角色选择一项：视为对你使用一张无距离限制的【杀】，或视为对你使用一张【决斗】。]]
	["mouzhu:slash"] = "视为使用一张【杀】",
	["mouzhu:duel"] = "视为使用一张【决斗】",
	["@mouzhu-give"] = "请交给 %src 一张手牌",
	["yanhuo"] = "延祸",
	[":yanhuo"] = "你死亡时，你可以依次弃置对手的X张牌。（X为你死亡时的牌数）",
				--[[身份局：你死亡时，你可以依次弃置一名其他角色X张牌。（X为你死亡时的牌数）]]
	["yanhuo-invoke"] = "你可以发动“延祸”<br/> <b>操作提示</b>: 选择一名其他角色→点击确定<br/>",

	["drowning"] = "水淹七军",
	[":drowning"] = "锦囊牌<br />出牌时机：出牌阶段<br />使用目标：对方角色。<br />作用效果：令目标角色选择一项：1.弃置所有装备区的装备牌。 2.受到1点伤害",
	["drowning:damage"] = "受到1点伤害",
	["drowning:throw"] = "弃置所有装备",
}
