-- translation for MountainPackage

return {
	["mountain"] = "山包",

	["#zhanghe"] = "料敌机先",
	["zhanghe"] = "张郃",
	["illustrator:zhanghe"] = "张帅",
	["qiaobian"] = "巧变",
	[":qiaobian"] = "你可以弃置一张手牌：若如此做，跳过一个阶段（除回合开始阶段和回合结束阶段）。若以此法跳过摸牌阶段，你可以依次获得一至两名其他角色的各一张手牌；若以此法跳过出牌阶段，你可以将场上的一张牌置于另一名角色相应的区域内。",
	["@qiaobianask"] = "请选择目标角色",
	["@qiaobian-2"] = "你可以依次获得一至两名其他角色的各一张手牌",
	["@qiaobian-3"] = "你可以将场上的一张牌移动至另一名角色相应的区域内",
	["#qiaobian-1"] = "你可以弃置 %arg 张手牌跳过判定阶段",
	["#qiaobian-2"] = "你可以弃置 %arg 张手牌跳过摸牌阶段",
	["#qiaobian-3"] = "你可以弃置 %arg 张手牌跳过出牌阶段",
	["#qiaobian-4"] = "你可以弃置 %arg 张手牌跳过弃牌阶段",
	["~qiaobian2"] = "选择 1-2 名其他角色→点击确定。",
	["~qiaobian3"] = "选择一名角色→点击确定。",

	["#dengai"] = "矫然的壮士",
	["dengai"] = "邓艾",
	["tuntian"] = "屯田",
	[":tuntian"] = "你的回合外，每当你失去一次手牌后，你可以进行一次判定：若判定结果不为<font color=\"red\">♥</font>，将判定牌置于武将牌上，称为“田”。你每拥有一张“田”，你与其他角色的距离-1。",
	["jixi"] = "急袭",
	[":jixi"] = "你可以将一张“田”当【顺手牵羊】使用。",
	["zaoxian"] = "凿险",
	[":zaoxian"] = "<font color=\"purple\"><b>觉醒技。</b></font>回合开始阶段开始时，若你的“田”大于或等于三张，你失去1点体力上限，然后获得技能“急袭”（你可以将一张“田”当【顺手牵羊】使用）。",
	["#ZaoxianWake"] = "%from 的“田”为 %arg 张，触发“%arg2”觉醒",
	["field"] = "田",

	["#liushan"] = "无为的真命主",
	["liushan"] = "刘禅",
	["illustrator:liushan"] = "LiuHeng",
	["xiangle"] = "享乐",
	[":xiangle"] = "<font color=\"blue\"><b>锁定技。</b></font>每当你被指定为【杀】的目标时，【杀】的使用者须弃置一张基本牌，否则此【杀】对你无效。",
	["fangquan"] = "放权",
	[":fangquan"] = "你可以跳过你的出牌阶段并在回合结束阶段开始时弃置一张手牌：若如此做，令一名其他角色进行一个额外的回合。",
	["ruoyu"] = "若愚",
	[":ruoyu"] = "<font color=\"orange\"><b>主公技。</b></font><font color=\"purple\"><b>觉醒技。</b></font>回合开始阶段开始时，若你的体力值为场上最少（或之一），你增加1点体力上限，回复1点体力，然后获得技能“激将”。",
	["#Xiangle"] = "%to 的“%arg”被触发， %from 须弃置一张基本牌使此【<font color=\"yellow\"><b>杀</b></font>】生效",
	["#XiangleAvoid"] = "%to 的“%arg”效果被触发，%from 对其使用的【<font color=\"yellow\"><b>杀</b></font>】无效",
	["#Fangquan"] = "%from 发动了“<font color=\"yellow\"><b>放权</b></font>”，%to 将进行一个额外的回合",
	["#RuoyuWake"] = "%from 的体力值(%arg)为场上最少，触发“%arg2”觉醒",
	["@xiangle-discard"] = "你须再弃置一张基本牌使此【杀】生效",

	["#jiangwei"] = "龙的衣钵",
	["jiangwei"] = "姜维",
	["tiaoxin"] = "挑衅",
	[":tiaoxin"] = "<font color=\"green\"><b>阶段技。</b></font>出牌阶段，你可以令攻击范围内包含你的一名其他角色对你使用一张【杀】，否则你弃置其一张牌。",
	["zhiji"] = "志继",
	[":zhiji"] = "<font color=\"purple\"><b>觉醒技。</b></font>回合开始阶段开始时，若你没有手牌，你失去1点体力上限，然后回复1点体力或摸两张牌，并获得技能“观星”。",
	["zhiji:draw"] = "摸2张牌",
	["zhiji:recover"] = "回复1点体力",
	["#ZhijiWake"] = "%from 没有手牌，触发“%arg”觉醒",
	["@tiaoxin-slash"] = "%src 对你发动“挑衅”，请对其使用一张【杀】",

	["#sunce"] = "江东的小霸王",
	["sunce"] = "孙策",
	["jiang"] = "激昂",
	[":jiang"] = "每当你指定或被指定为红色【杀】或【决斗】的目标后，你可以摸一张牌。",
	["hunzi"] = "魂姿",
	[":hunzi"] = "<font color=\"purple\"><b>觉醒技。</b></font>回合开始阶段开始时，若你的体力值为1，你失去1点体力上限，然后获得技能“英姿”和“英魂”。",
	["zhiba"] = "制霸",
	["zhiba_pindian"] = "制霸拼点",
	[":zhiba"] = "<font color=\"orange\"><b>主公技。</b></font><font color=\"green\"><b>阶段技。</b></font>其他吴势力角色的出牌阶段，该角色可以与你拼点：若该角色没赢，你可以获得你与该角色的拼点牌。若你已发动“魂姿”，你可以拒绝此拼点。",
	["#HunziWake"] = "%from 的体力值为 <font color=\"yellow\"><b>1</b></font>，触发“%arg”觉醒",
	["zhiba_pindian:accept"] = "接受",
	["zhiba_pindian:reject"] = "拒绝",

	["#erzhang"] = "经天纬地",
	["erzhang"] = "张昭·张纮",
	["&erzhang"] = "张昭张纮",
	["illustrator:erzhang"] = "废柴男",
	["zhijian"] = "直谏",
	[":zhijian"] = "出牌阶段，你可以将你手牌中的一张装备牌置于一名其他角色装备区内：若如此做，你摸一张牌。",
	["guzheng"] = "固政",
	[":guzheng"] = "其他角色的弃牌阶段结束时，你可以令其获得一张弃牌堆中此阶段中弃置的该角色的牌：若如此做，你获得其余此阶段弃置的弃牌堆中的牌。",
	["$ZhijianEquip"] = "%from 被装备了 %card",

	["#caiwenji"] = "异乡的孤女",
	["caiwenji"] = "蔡文姬",
	["illustrator:caiwenji"] = "SoniaTang",
	["beige"] = "悲歌",
	[":beige"] = "每当一名角色受到一次【杀】的伤害后，你可以弃置一张手牌令该角色进行一次判定：若判定结果为<font color=\"red\">♥</font>，该角色回复1点体力；<font color=\"red\">♦</font>，该角色摸两张牌；♠，伤害来源将其武将牌翻面；♣，伤害来源弃置两张牌。",
	["duanchang"] = "断肠",
	[":duanchang"] = "<font color=\"blue\"><b>锁定技。</b></font>杀死你的角色失去所有武将技能。",
	["#DuanchangLoseSkills"] = "%from 的“%arg”被触发， %to 失去所有武将技能",
	["@duanchang"] = "断肠",

	["#zuoci"] = "谜之仙人",
	["zuoci"] = "左慈",
	["illustrator:zuoci"] = "废柴男",
	["huashen"] = "化身",
	[":huashen"] ="所有玩家展示武将牌后，你可以获得两张未加入游戏的武将牌，称为“化身牌”，然后选择其中一张“化身牌”的一项技能（除主公技、限定技与觉醒技），你拥有该技能且性别与势力改为与“化身牌”相同。回合开始时和回合结束后，你可以更换“化身牌”，然后为当前的“化身牌”重新选择一项技能。",
	["xinsheng"] = "新生",
	[":xinsheng"] = "每当你受到1点伤害后，你可以获得一张“化身牌”。",
	["#GetHuashen"] = "%from 获得了 %arg 张“化身牌”，现在共有 %arg2 张“化身牌”",

-- Lines

--张郃
	["cv:zhanghe"] = "爪子",
	["$qiaobian1"] = "虚招令旗，以之惑敌。", -- judge
	["$qiaobian2"] = "绝其汲道，困其刍粮。", -- draw
	["$qiaobian3"] = "以守为攻，后发制人。", -- play
	["$qiaobian4"] = "停止前进，扎营御敌！", -- discard
	["~zhanghe"] = "归兵勿追，追兵难归啊……",

--邓艾
	["$tuntian1"] = "休养生息，备战待敌。",
	["$tuntian2"] = "锄禾日当午，汗滴禾下土。",
	["$zaoxian1"] = "屯田日久，当建奇功！",
	["$zaoxian2"] = "开辟险路，奇袭敌军！",
	["$ZaoxianAnimate"] = "anim=image/animate/zaoxian.png",
	["$jixi1"] = "攻其无备，出其不意。",
	["$jixi2"] = "偷渡阴平，直取蜀汉！",
	["~dengai"] = "吾破蜀克敌，竟葬于奸贼之手！",

--刘禅
	["$fangquan1"] = "这可如何是好啊！",
	["$fangquan2"] = "你办事儿，我放心！",
	["$ruoyu1"] = "不装疯卖傻，岂能安然无恙？",
	["$ruoyu2"] = "世人皆错看我，唉……",
	["$RuoyuAnimate"] = "anim=image/animate/ruoyu.png",
	["$xiangle1"] = "嗯…打打杀杀，真没意思！",
	["$xiangle2"] = "我爸爸是刘备！",
	["$jijiang3"] = "匡扶汉室，谁敢出战？",
	["$jijiang4"] = "我蜀汉岂无人乎！",
	["~liushan"] = "别打脸…我投降还不行吗？",

--姜维
	["$tiaoxin1"] = "汝等小儿，可敢杀我。",
	["$tiaoxin2"] = "贼将早降，可免一死。",
	["$zhiji1"] = "先帝之志，丞相之托，不可忘也！",
	["$zhiji2"] = "丞相厚恩，维万死不能相报！",
	["$ZhijiAnimate"] = "anim=image/animate/zhiji.png",
	["~jiangwei"] = "我计不成，乃天命也…",

--孙策
	["cv:sunce"] = "官方，猎狐",
	["$jiang1"] = "吾乃江东小霸王孙伯符！",
	["$jiang2"] = "江东子弟，何惧于天下!",
	["$hunzi1"] = "父亲在上，魂佑江东；公瑾在旁，智定天下！",
	["$hunzi2"] = "愿承父志，与公瑾共谋天下！",
	["$HunziAnimate"] = "anim=image/animate/hunzi.png",
	["$Hunzi2"] = "愿承父志，与公瑾共谋天下！",
	["$yingzi3"] = "公瑾，助我决一死战！",
	["$yingzi4"] = "尔等看好了！",
	["$yinghun3"] = "孙氏英烈，庇佑江东。",
	["$yinghun4"] = "父亲，助我背水一战！",
	["$sunce_zhiba1"] = "是友是敌，一探便知。",
	["$sunce_zhiba2"] = "我若怕你，非孙伯符也！",
	["$sunce_zhiba3"] = "哈哈，汝乃吾之真卿也！",
	["$sunce_zhiba4"] = "哼，错当佞臣做忠臣，誓不饶你！",
	["$sunce_zhiba5"] = "且慢！莫不是你欲用诈降之计赚我。",
	["~sunce"] = "内事不决问张昭，外事不决问周瑜……",

--张昭张纮
	["$zhijian1"] = "请恕老臣直言。",
	["$zhijian2"] = "为臣者，当冒死以谏。",
	["$guzheng1"] = "今当稳固内政，以御外患。",
	["$guzheng2"] = "固国安邦，须当如是。",
	["~erzhang"] = "竭力尽智，死而无憾…",

--蔡文姬
	["cv:caiwenji"] = "呼呼",
	["$beige1"] = "欲死不能得，欲生无一可。", -- club
	["$beige2"] = "此行远兮，君尚珍重！", -- spade
	["$beige3"] = "翩翩吹我衣，肃肃入我耳。", -- diamond
	["$beige4"] = "岂偕老之可期，庶尽欢于余年。", -- heart
	["$duanchang1"] = "雁飞高兮邈难寻，空断肠兮思愔愔。",
	["$duanchang2"] = "胡人落泪沾边草，汉使断肠对归客。",

--左慈
	["cv:zuoci"] = "东方胤弘，眠眠",
	["$huashen1"] = "藏形变身,自在吾心(男声)",
	["$huashen2"] = "遁形幻千,随意所欲(男声)",
	["$xinsheng1"] = "吐故纳新,师法天地(男声)",
	["$xinsheng2"] = "灵根不灭,连绵不绝(男声)",
	["~zuoci"] = "释知遗形,神灭形消",

	["$huashen3"] = "藏形变身,自在吾心(女声)",
	["$huashen4"] = "遁形幻千,随意所欲(女声)",
	["$xinsheng3"] = "吐故纳新,师法天地(女声)",
	["$xinsheng4"] = "灵根不灭,连绵不绝(女声)",
}
