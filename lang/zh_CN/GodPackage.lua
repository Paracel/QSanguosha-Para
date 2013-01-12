-- translation for GodPackage

return {
	["god"] = "神",

	["#shenguanyu"] = "鬼神再临",
	["shenguanyu"] = "神关羽",
	["wushen"] = "武神",
	[":wushen"] = "<font color=\"blue\"><b>锁定技。</b></font>你的<font color=\"red\">♥</font>手牌视为普通【杀】。你使用<font color=\"red\">♥</font>【杀】无距离限制。",
	["wuhun"] = "武魂",
	[":wuhun"] = "<font color=\"blue\"><b>锁定技。</b></font>每当你受到伤害扣减体力前，伤害来源获得等于伤害点数的“梦魇”标记。你死亡时，你选择“梦魇”标记数最多且不为0的一名存活角色，该角色进行一次判定：若判定结果不为【桃】或【桃园结义】，该角色死亡。",
	["@nightmare"] = "梦魇",
	["#WuhunRevenge"] = "%from 的“%arg2”被触发，拥有最多“梦魇”标记的角色 %to（%arg个）死亡",

	["#shenlvmeng"] = "圣光之国士",
	["shenlvmeng"] = "神吕蒙",
	["shelie"] = "涉猎",
	[":shelie"] = "摸牌阶段，你可以放弃摸牌并展示牌堆顶的五张牌：若如此做，你获得其中每种花色的牌各一张，然后将其余的牌置入弃牌堆。",
	["gongxin"] = "攻心",
	[":gongxin"] = "<font color=\"green\"><b>阶段技。</b></font>出牌阶段，你可以观看一名其他角色的手牌，然后选择其中一张<font color=\"red\">♥</font>牌并选择一项：弃置之，或将其置于牌堆顶。",
	["shelie:yes"] = "放弃摸牌并展示牌堆顶的五张牌：若如此做，你获得其中每种花色的牌各一张，然后将其余的牌置入弃牌堆",
	[":gongxin:"] = "请选择处理方式:",
	["gongxin:discard"] = "弃置",
	["gongxin:put"] = "置于牌堆顶",

	["#shenzhouyu"] = "赤壁的火神",
	["shenzhouyu"] = "神周瑜",
	["qinyin"] = "琴音",
	[":qinyin"] = "<font color=\"green\"><b>阶段技。</b></font>弃牌阶段，每当你弃置两张或更多的牌后，你可以令所有角色失去1点体力，或令所有角色回复1点体力。",
	["qinyin:yes"] = "令所有角色失去1点体力，或令所有角色回复1点体力",
	[":qinyin:"] = "请选择一项:",
	["qinyin:up"] = "所有角色回复1点体力",
	["qinyin:down"] = "所有角色失去1点体力",
	["yeyan"] = "业炎",
	[":yeyan"] = "<font color=\"red\"><b>限定技。</b></font>出牌阶段，你可以对至多三名角色各造成1点火焰伤害；你可以弃置四种花色的手牌各一张，失去3点体力并选择一至两名角色：若如此做，你对这些角色造成共计不超过3点火焰伤害且对其中一名角色造成至少2点火焰伤害。",
	["@flame"] = "业炎",
	["greatyeyan"] = "业炎",
	["smallyeyan"] = "业炎",

	["#shenzhugeliang"] = "赤壁的妖术师",
	["shenzhugeliang"] = "神诸葛亮",
	["qixing"] = "七星",
	[":qixing"] = "分发起始手牌时，你可以获得十一张牌：若如此做，你选择其中四张作为手牌，将其余七张移出游戏称为“星”。摸牌阶段摸牌后，你可以获得任意数量的“星”，然后将等数量的手牌加入“星”。",
	["@star"] = "七星",
	["stars"] = "星",
	["kuangfeng"] = "狂风",
	[":kuangfeng"] = "回合结束阶段开始时，你可以将一张“星”置入弃牌堆并选择一名角色：若如此做，伤害结算开始时，该角色受到的火焰伤害+1，直到你下回合开始。",
	["@gale"] = "狂风",
	["dawu"] = "大雾",
	[":dawu"] = "回合结束阶段开始时，你可以将任意数量的“星”置入弃牌堆并选择等数量的角色：若如此做，伤害结算开始时，这些角色受到的除雷电伤害外的伤害被防止，直到你下回合开始。",
	["@fog"] = "大雾",
	["@qixing-exchange"] = "请选择 %arg 张手牌用于交换",
	["@kuangfeng-card"] = "你可以发动“狂风”",
	["@dawu-card"] = "你可以发动“大雾”",
 	["~dawu"] = "选择若干名角色→点击确定→然后在窗口中选择相应数量的牌",
 	["~kuangfeng"] = "选择一名角色→点击确定→然后在窗口中选择一张牌",
	["#QixingExchange"] = "%from 发动了“%arg2”，交换了 %arg 张手牌",
	["#FogProtect"] = "%from 的“<font color=\"yellow\"><b>大雾</b></font>”效果被触发，防止了 %arg 点伤害[%arg2]",
	["#GalePower"] = "“<font color=\"yellow\"><b>狂风</b></font>”效果被触发，%from 的火焰伤害从 %arg 点增加至 %arg2 点",

	["#shencaocao"] = "超世之英杰",
	["shencaocao"] = "神曹操",
	["guixin"] = "归心",
	[":guixin"] = "每当你受到1点伤害后，你可以依次获得所有其他角色区域里的一张牌，然后将武将牌翻面。",
	["feiying"] = "飞影",
	[":feiying"] = "<font color=\"blue\"><b>锁定技。</b></font>其他角色与你的距离+1",
	["guixin:yes"] = "你可以依次获得所有其他角色区域里的一张牌，然后将武将牌翻面",

	["#shenlvbu"] = "修罗之道",
	["shenlvbu"] = "神吕布",
	["kuangbao"] = "狂暴",
	[":kuangbao"] = "<font color=\"blue\"><b>锁定技。</b></font>游戏开始时，你获得两枚“暴怒”标记。每当你造成或受到1点伤害后，你获得一枚“暴怒”标记。",
	["@wrath"] = "暴怒",
	["wumou"] = "无谋",
	[":wumou"] = "<font color=\"blue\"><b>锁定技。</b></font>每当你使用一张非延时类锦囊牌时，你须选择一项：失去1点体力，或弃一枚“暴怒”标记。",
	["wuqian"] = "无前",
	[":wuqian"] = "出牌阶段，你可以弃两枚“暴怒”标记并选择一名其他角色：若如此做，你拥有技能“无双”且该角色防具无效，直到回合结束。",
	["shenfen"] = "神愤",
	[":shenfen"] = "<font color=\"green\"><b>阶段技。</b></font>出牌阶段，你可以弃六枚“暴怒”标记：若如此做，所有其他角色受到你造成的1点伤害，依次弃置装备区的所有牌，然后依次弃置四张手牌，然后你将武将牌翻面。",
	["#KuangbaoDamage"] = "%from 的“%arg2”被触发，造成 %arg 点伤害获得 %arg 枚“暴怒”标记",
	["#KuangbaoDamaged"] = "%from 的“%arg2”被触发，受到 %arg 点伤害获得 %arg 枚“暴怒”标记",
	["wumou:discard"] = "弃一枚“暴怒”标记",
	["wumou:losehp"] = "失去1点体力",

	["#shenzhaoyun"] = "神威如龙",
	["shenzhaoyun"] = "神赵云",
	["juejing"] = "绝境",
	[":juejing"] = "<font color=\"blue\"><b>锁定技。</b></font>摸牌阶段，你额外摸X张牌。你的手牌上限+2。（X为你已损失的体力值）",
	["longhun"] = "龙魂",
	[":longhun"] = "你可以将X张同花色的牌按以下规则使用或打出：<font color=\"red\">♥</font>当【桃】；<font color=\"red\">♦</font>当火【杀】；♠当【无懈可击】；♣当【闪】。（X为你的当前体力值且至少为1）",

	["#shensimayi"] = "晋国之祖",
	["shensimayi"] = "神司马懿",
	["renjie"] = "忍戒",
	[":renjie"] = "<font color=\"blue\"><b>锁定技。</b></font>每当你受到1点伤害后或于弃牌阶段弃置一张牌时，你获得一枚“忍”。",
	["@bear"] = "忍",
	["baiyin"] = "拜印",
	[":baiyin"] ="<font color=\"purple\"><b>觉醒技。</b></font>回合开始阶段开始时，若你拥有四枚或更多的“忍”，你失去1点体力上限，然后获得技能“极略”（你可以弃一枚“忍”并发动以下技能之一：“鬼才”、“放逐”、“集智”、“制衡”、“完杀”）。",
	["#BaiyinWake"] = "%from 的“忍”为 %arg 个，触发“<font color=\"yellow\"><b>拜印</b></font>”觉醒",
	["jilve"] = "极略",
	[":jilve"] = "弃一枚“忍”发动以下技能之一：“鬼才”、“放逐”、“集智”、“制衡”、“完杀”",
	["lianpo"] = "连破",
	[":lianpo"] = "你的回合结束后，若你于此回合内杀死至少一名角色，你可以进行一个额外的回合。",
	["@jilve-zhiheng"] = "请发动“制衡”",
	["~zhiheng"] = "选择需要弃置的牌→点击确定",
	["#LianpoCanInvoke"] = "%from 在本回合内杀死了 %arg 名角色，满足“%arg2”的发动条件",
	["#LianpoRecord"] = "%from 杀死了 %to，可在 %arg 回合结束后进行一个额外的回合",

-- Lines

--神关羽
	["cv:shenguanyu"] = "奈何",
	["$wushen1"] = "武神现世，天下莫敌！",
	["$wushen2"] = "战意，化为青龙翱翔吧！",
	["$wuhun1"] = "关某记下了。",
	["$wuhun2"] = "我生不能啖汝之肉，死当追汝之魂！",
	["$wuhun3"] = "桃园之梦，再也不会回来了……",
	["$WuhunAnimate"] = "anim=image/animate/wuhun.png",
	["~shenguanyu"] = "吾一世英名，竟葬于小人之手！",

--神吕蒙
	["$shelie1"] = "略懂，略懂。",
	["$shelie2"] = "什么都略懂一点儿，生活更多彩一些。",
	["$gongxin1"] = "攻城为下，攻心为上。",
	["$gongxin2"] = "我替施主把把脉。",
	["~shenlvmeng"] = "劫数难逃，我们别无选择……",

--神周瑜
	["$qinyin1"] = "（琴音）",
	["$qinyin2"] = "（琴音）",
	["$yeyan1"] = "聆听吧，这献给你的镇魂曲！",
	["$yeyan2"] = "让这熊熊业火，焚尽你的罪恶！",
	["$yeyan3"] = "（业炎琴音）",
	["$YeyanAnimate"] = "anim=image/animate/yeyan.png",
	["~shenzhouyu"] = "逝者不死，浴火重生……",
	
--神诸葛亮
	["$qixing1"] = "伏望天恩，誓讨汉贼。",
	["$qixing2"] = "祈星辰之力，佑我蜀汉。",
	["$dawu1"] = "此计可保你一时平安。",
	["$dawu2"] = "此非万全之策，唯惧天雷。",
	["$kuangfeng1"] = "万事俱备，只欠业火。",
	["$kuangfeng2"] = "风……起……",
	["~shenzhugeliang"] = "今当远离，临表涕零，不知所言……",

--神曹操
	["$guixin1"] = "山不厌高，海不厌深。",
	["$guixin2"] = "周公吐哺，天下归心。",
	["$GuixinAnimate"] = "anim=image/animate/guixin.png",
	["~shencaocao"] = "腾蛇乘雾，终为土灰……",
	
--神吕布
	["$kuangbao1"] = "呃～啊啊啊～！",
	["$kuangbao2"] = "哼！",
	["$wumou1"] = "哪个说我有勇无谋？！",
	["$wumou2"] = "不管这些啦！",
	["$wuqian1"] = "看我神威，无坚不摧！",
	["$wuqian2"] = "天王老子也保不住你！",
	["$shenfen1"] = "凡人们，颤抖吧！这是神之怒火！",
	["$shenfen2"] = "这，才是活生生的地狱！",
	["$ShenfenAnimate"] = "anim=image/animate/shenfen.png",
	["~shenlvbu"] = "我在修罗炼狱，等着你们！呵呵呵哈哈哈哈……",
	
--神赵云
	["cv:shenzhaoyun"] = "猎狐",
	["$juejing"] = "龙战于野，其血玄黄。",
	["$longhun1"] = "金甲映日，驱邪祛秽。", -- spade
	["$longhun2"] = "腾龙行云，首尾不见。", -- club
	["$longhun3"] = "潜龙于渊，涉灵愈伤。", -- heart
	["$longhun4"] = "千里一怒，红莲灿世。", -- diamond
	["~shenzhaoyun"] = "血染鳞甲，龙坠九天。",

--神司马懿
	["cv:shensimayi"] = "泥马",
	["$renjie"] = "韬光养晦，静待时机。",
	["$baiyin"] = "是可忍，孰不可忍！",
	["$BaiyinAnimate"] = "anim=image/animate/baiyin.png",
	["$jilve1"] = "天意如何，我命由我。", -- guicai
	["$jilve2"] = "远逐敌雠，拔除异己。", -- fangzhu
	["$jilve3"] = "心狠手毒，方能成事。", -- wansha
	["$jilve4"] = "暂且思量，再作打算。", -- zhiheng
	["$jilve5"] = "此计即成，彼计亦得。", -- jizhi
	["$lianpo"] = "敌军已乱，乘胜追击。",
	["~shensimayi"] = "我已谋划至此，奈何……",
}
