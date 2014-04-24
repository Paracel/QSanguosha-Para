-- translation for Assassins Package

return {
	["assassins"] = "铜雀台",

	["#fuwan"] = "沉毅的国丈",
	["fuwan"] = "伏完",
	["illustrator:fuwan"] = "LiuHeng",
	["moukui"] = "谋溃",
	[":moukui"] = "每当你指定【杀】的目标后，你可以选择一项：摸一张牌，或弃置目标角色一张牌。若如此做，此【杀】被该角色的【闪】抵消后，其弃置你的一张牌。",
	["moukui:draw"] = "摸一张牌",
	["moukui:discard"] = "弃置目标角色一张牌",

	["#liuxie"] = "受困天子",
	["liuxie"] = "刘协",
	["illustrator:liuxie"] = "LiuHeng",
	["tianming"] = "天命",
	[":tianming"] = "每当你成为【杀】的目标时，你可以弃置两张牌，然后摸两张牌。若全场唯一的体力值最多的角色不是你，该角色也可以弃置两张牌，然后摸两张牌。",
	["mizhao"] = "密诏",
	[":mizhao"] = "阶段技。你可以将所有手牌（至少一张）交给一名其他角色：若如此做，你令该角色与另一名由你选择的有手牌的角色拼点：若一名角色赢，视为该角色对没赢的角色使用一张【杀】。",
	["@mizhao-pindian"] = "请选择与 %src 拼点的角色",

	["#lingju"] = "情随梦逝",
	["lingju"] = "灵雎",
	["illustrator:lingju"] = "木美人",
	["jieyuan"] = "竭缘",
	[":jieyuan"] = "每当你对其他角色造成伤害时，若其体力值大于或等于你的体力值，你可以弃置一张黑色手牌：若如此做，此伤害+1。每当你受到其他角色的伤害时，若其体力值大于或等于你的体力值，你可以弃置一张红色手牌：若如此做，此伤害-1。",
	["@jieyuan-increase"] = "你可以弃置一张黑色手牌令 %src 受到的伤害+1",
	["@jieyuan-decrease"] = "你可以弃置一张红色手牌令 %src 造成的伤害-1",
	["#JieyuanIncrease"] = "%from 发动了“<font color=\"yellow\"><b>竭缘</b></font>”，伤害点数从 %arg 点增加至 %arg2 点",
	["#JieyuanDecrease"] = "%from 发动了“<font color=\"yellow\"><b>竭缘</b></font>”，伤害点数从 %arg 点减少至 %arg2 点",
	["fenxin"] = "焚心",
	[":fenxin"] = "限定技。若你不是主公，你杀死一名非主公其他角色时，展示身份牌前，你可以与该角色交换身份牌。",
	["$FenxinAnimate"] = "image=image/animate/fenxin.png",
}
