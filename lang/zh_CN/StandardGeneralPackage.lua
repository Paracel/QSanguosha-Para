-- translation for StandardGeneralPackage

return {
	["standard"] = "标准版",

--wei
	["#caocao"] = "魏武帝",
	["caocao"] = "曹操",
	["jianxiong"] = "奸雄",
	[":jianxiong"] = "每当你受到一次伤害后，你可以获得对你造成伤害的牌。",
	["hujia"] = "护驾",
	[":hujia"] = "<font color=\"orange\"><b>主公技。</b></font>每当你需要使用或打出一张【闪】时，你可以令其他魏势力角色打出一张【闪】，视为你使用或打出之。",
	["jianxiong:yes"] = "获得对你造成伤害的牌",
	["hujia:yes"] = "其他魏势力角色依次选择是否打出一张【闪】，视为你使用或打出之",
	[":hujia:"] = "曹操令你选择是否打出一张【闪】",
	["hujia:accept"] = "响应“护驾”",
	["hujia:ignore"] = "不响应",
	["@hujia-jink"] = "请打出一张【闪】响应 %src “护驾”",

	["#zhangliao"] = "前将军",
	["zhangliao"] = "张辽",
	["tuxi"] = "突袭",
	[":tuxi"] = "摸牌阶段，你可以放弃摸牌并选择一至两名有手牌的其他角色：若如此做，你依次获得这些角色各一张手牌。",
	["@tuxi-card"] = "你可以发动“突袭”",
	["~tuxi"] = "选择 1-2 名其他角色→点击确定",

	["#guojia"] = "早终的先知",
	["guojia"] = "郭嘉",
	["tiandu"] = "天妒",
	[":tiandu"] = "每当你的判定牌生效后，你可以获得之。",
	["yiji"] = "遗计",
	[":yiji"] = "每当你受到1点伤害后，你可以观看牌堆顶的两张牌，然后将一张牌交给一名角色，将另一张牌交给一名角色。",

	["#xiahoudun"] = "独眼的罗刹",
	["xiahoudun"] = "夏侯惇",
	["ganglie"] = "刚烈",
	[":ganglie"] = "每当你受到一次伤害后，你可以进行一次判定：若判定结果不为<font color=\"red\">♥</font>，则伤害来源选择一项：弃置两张手牌，或受到你造成的1点伤害。",
	["ganglie:yes"] = "进行一次判定：若判定结果不为<font color=\"red\">♥</font>，则伤害来源选择一项：弃置两张手牌，或受到你造成的1点伤害",

	["#simayi"] = "狼顾之鬼",
	["simayi"] = "司马懿",
	["fankui"] = "反馈",
	[":fankui"] = "每当你受到一次伤害后，你可以获得伤害来源的一张牌。",
	["guicai"] = "鬼才",
	[":guicai"] = "每当一名角色的判定牌生效前，你可以打出一张手牌代替之。",
	["@guicai-card"] = "请发动“%dest”来修改 %src 的 %arg 判定",
	["~guicai"] = "选择一张手牌→点击确定",
	["fankui:yes"] = "你可以获得伤害来源的一张牌",

	["#xuchu"] = "虎痴",
	["xuchu"] = "许褚",
	["luoyi"] = "裸衣",
	[":luoyi"] = "摸牌阶段，你可以少摸一张牌：若如此做，你使用且你为伤害来源的【杀】或【决斗】将要造成的伤害+1，直到回合结束。",
	["luoyi:yes"] = "你使用且你为伤害来源的【杀】或【决斗】将要造成的伤害+1，直到回合结束",
	["#LuoyiBuff"] = "%from 的“<font color=\"yellow\"><b>裸衣</b></font>”效果被触发，伤害从 %arg 点增加至 %arg2 点",

	["#zhenji"] = "薄幸的美人",
	["zhenji"] = "甄姬",
	["luoshen"] = "洛神",
	[":luoshen"] = "回合开始阶段开始时，你可以进行一次判定：若判定结果为黑色，你获得判定牌，且你可以再次发动“洛神”。",
	["qingguo"] = "倾国",
	[":qingguo"] = "你可以将一张黑色手牌当【闪】使用或打出。",
--shu
	["#liubei"] = "乱世的枭雄",
	["liubei"] = "刘备",
	["rende"] = "仁德",
	[":rende"] = "出牌阶段，你可以将任意数量的手牌交给其他角色。当你于本阶段内以此法给出的手牌首次达到两张或更多后，你回复1点体力。",
	["jijiang"] = "激将",
	[":jijiang"] = "<font color=\"orange\"><b>主公技。</b></font>每当你需要使用或打出一张【杀】时，你可以令其他蜀势力角色打出一张【杀】，视为你使用或打出之。",
	[":jijiang:"] = "%from 令你选择是否打出一张【杀】:",
	["jijiang:accept"] = "响应激将",
	["jijiang:ignore"] = "不响应",
	["@jijiang-slash"] = "请打出一张【杀】响应“激将”",

	["#guanyu"] = "美髯公",
	["guanyu"] = "关羽",
	["wusheng"] = "武圣",
	[":wusheng"] = "你可以将一张红色牌当普通【杀】使用或打出。",

	["#zhangfei"] = "万夫不当",
	["zhangfei"] = "张飞",
	["paoxiao"] = "咆哮",
	[":paoxiao"] = "<font color=\"blue\"><b>锁定技。</b></font>你于出牌阶段内使用【杀】无数量限制。",

	["#zhaoyun"] = "少年将军",
	["zhaoyun"] = "赵云",
	["longdan"] = "龙胆",
	[":longdan"] = "你可以将一张【杀】当【闪】使用或打出，或将一张【闪】当普通【杀】使用或打出。",

	["#machao"] = "一骑当千",
	["machao"] = "马超",
	["tieji"] = "铁骑",
	[":tieji"] = "每当你指定【杀】的目标后，你可以进行一次判定：若判定结果为红色，此【杀】不能被【闪】响应。",
	["mashu"] = "马术",
	[":mashu"] = "<font color=\"blue\"><b>锁定技。</b></font>你与其他角色的距离-1。",
	["tieji:yes"] = "你可以进行一次判定：若判定结果为红色，此【杀】不能被【闪】响应",

	["#zhugeliang"] = "迟暮的丞相",
	["zhugeliang"] = "诸葛亮",
	["guanxing"] = "观星",
	[":guanxing"] = "回合开始阶段开始时，你可以观看牌堆顶的X张牌，然后将任意数量的牌以任意顺序置于牌堆顶，将其余的牌以任意顺序置于牌堆底。（X为存活角色数且至多为5）",
	["kongcheng"] = "空城",
	[":kongcheng"] = "<font color=\"blue\"><b>锁定技。</b></font>若你没有手牌，你不能被选择为【杀】或【决斗】的目标。",
	["#GuanxingResult"] = "%from 的“<font color=\"yellow\"><b>观星</b></font>”结果：%arg 上 %arg2 下",

	["#huangyueying"] = "归隐的杰女",
	["huangyueying"] = "黄月英",
	["jizhi"] = "集智",
	[":jizhi"] = "每当你使用一张非延时类锦囊牌时，你可以摸一张牌。",
	["qicai"] = "奇才",
	[":qicai"] = "<font color=\"blue\"><b>锁定技。</b></font>你使用锦囊牌无距离限制。",
--wu
	["#sunquan"] = "年轻的贤君",
	["sunquan"] = "孙权",
	["zhiheng"] = "制衡",
	[":zhiheng"] = "<font color=\"green\"><b>阶段技。</b></font>出牌阶段，你可以弃置任意数量的牌：若如此做，你摸等数量的牌。",
	["jiuyuan"] = "救援",
	[":jiuyuan"] = "<font color=\"orange\"><b>主公技。</b></font><font color=\"blue\"><b>锁定技。</b></font>若你处于濒死状态，其他吴势力角色对你使用【桃】时，你回复的体力+1。",
	["#JiuyuanExtraRecover"] = "%from 的“%arg”被触发，将额外回复 <font color=\"yellow\"><b>1</b></font> 点体力",

	["#zhouyu"] = "大都督",
	["zhouyu"] = "周瑜",
	["yingzi"] = "英姿",
	[":yingzi"] = "摸牌阶段，你可以额外摸一张牌。",
	["fanjian"] = "反间",
	[":fanjian"] = "<font color=\"green\"><b>阶段技。</b></font>出牌阶段，你可以令一名其他角色选择一种花色，然后获得你的一张手牌并展示之。若此牌花色与该角色所选花色不同，你对其造成1点伤害。",
	["yingzi:yes"] = "你可以额外摸一张牌",

	["#lvmeng"] = "白衣渡江",
	["lvmeng"] = "吕蒙",
	["keji"] = "克己",
	[":keji"] = "若你跳过了出牌阶段，或于出牌阶段未使用或打出【杀】，你可以跳过弃牌阶段。",

	["#luxun"] = "儒生雄才",
	["luxun"] = "陆逊",
	["qianxun"] = "谦逊",
	[":qianxun"] = "<font color=\"blue\"><b>锁定技。</b></font>你不能被选择为【顺手牵羊】与【乐不思蜀】的目标。",
	["lianying"] = "连营",
	[":lianying"] = "每当你失去最后的手牌后，你可以摸一张牌。",

	["#ganning"] = "锦帆游侠",
	["ganning"] = "甘宁",
	["qixi"] = "奇袭",
	[":qixi"] = "你可以将一张黑色牌当【过河拆桥】使用。",

	["#huanggai"] = "轻身为国",
	["huanggai"] = "黄盖",
	["kurou"] = "苦肉",
	[":kurou"] = "出牌阶段，你可以失去1点体力：若如此做，你摸两张牌。",

	["#daqiao"] = "矜持之花",
	["daqiao"] = "大乔",
	["guose"] = "国色",
	[":guose"] = "你可以将一张<font color=\"red\">♦</font>牌当【乐不思蜀】使用。",
	["liuli"] = "流离",
	[":liuli"] = "每当你被指定为【杀】的目标时，你可以弃置一张牌并选择你攻击范围内的一名其他角色（除该【杀】使用者）：若如此做，该角色被指定为此【杀】的目标。",
	["~liuli"] = "选择一张牌——选择一名其他角色→点击确定",
	["@liuli"] = "%src 对你使用【杀】，你可以弃置一张牌将此【杀】目标指定为你攻击范围内除 %src 以外的一名角色",

	["#sunshangxiang"] = "弓腰姬",
	["sunshangxiang"] = "孙尚香",
	["jieyin"] = "结姻",
	[":jieyin"] = "<font color=\"green\"><b>阶段技。</b></font>出牌阶段，你可以弃置两张手牌并选择一名已受伤的男性角色：若如此做，你和该角色各回复1点体力。",
	["xiaoji"] = "枭姬",
	[":xiaoji"] = "每当你失去一张装备区的装备牌后，你可以摸两张牌。",
--qun
	["#lvbu"] = "武的化身",
	["lvbu"] = "吕布",
	["wushuang"] = "无双",
	[":wushuang"] = "<font color=\"blue\"><b>锁定技。</b></font>每当你指定【杀】的目标后，目标角色须连续使用两张【闪】抵消此【杀】。与你【决斗】的角色每次须连续打出两张【杀】。",
	["@wushuang-slash-1"] = "%src 对你【决斗】，“无双”被触发，你须连续打出两张【杀】",
	["@wushuang-slash-2"] = "%src 的【决斗】有“无双”效果，你须再打出一张【杀】",
	["@double-jink-1"] = "%src 对你使用【杀】，你须连续使用两张【闪】",
	["@double-jink-2"] = "%src 对你使用【杀】，你须再使用一张【闪】",

	["#huatuo"] = "神医",
	["huatuo"] = "华佗",
	["qingnang"] = "青囊",
	[":qingnang"] = "<font color=\"green\"><b>阶段技。</b></font>出牌阶段，你可以弃置一张手牌并选择一名已受伤的角色：若如此做，该角色回复1点体力。",
	["jijiu"] = "急救",
	[":jijiu"] = "你的回合外，你可以将一张红色牌当【桃】使用。",

	["#diaochan"] = "乱世的舞姬",
	["diaochan"] = "貂蝉",
	["lijian"] = "离间",
	[":lijian"] = "<font color=\"green\"><b>阶段技。</b></font>出牌阶段，你可以弃置一张牌并选择两名男性角色：若如此做，视为其中一名角色对另一名角色使用一张【决斗】，此【决斗】不能被【无懈可击】响应。",
	["biyue"] = "闭月",
	[":biyue"] = "回合结束阶段开始时，你可以摸一张牌。",
	["biyue:yes"] = "你可以摸一张牌",

	
-- Lines

--曹操
	["$jianxiong1"] = "宁教我负天下人，休教天下人负我！", 
	["$jianxiong2"] = "吾好梦中杀人！", 
	["$hujia1"] = "魏将何在？", 
	["$hujia2"] = "来人，护驾！", 
	["~caocao"] = "霸业未成，未成啊……",
	
--司马懿
	["$guicai1"] = "天命？哈哈哈哈～",
	["$guicai2"] = "吾乃天命之子！",
	["$fankui1"] = "下次注意点～",
	["$fankui2"] = "出来混，早晚要还的。",
	["~simayi"] = "难道真是天命难违？",
	
--夏侯惇
	["$ganglie1"] = "鼠辈，竟敢伤我！",
	["$ganglie2"] = "以彼之道，还施彼身！",
	["~xiahoudun"] = "两边都看不见了……",
	
--张辽
	["$tuxi1"] = "哼，没想到吧！",
	["$tuxi2"] = "拿来吧！",
	["~zhangliao"] = "真的没想到……",
	
--许褚
	["$luoyi1"] = "破！", 
	["$luoyi2"] = "谁来与我大战三百回合？", 
	["~xuchu"] = "冷，好冷啊……",
	
--郭嘉
	["$tiandu1"] = "就这样吧。",
	["$tiandu2"] = "哦？",
	["$yiji1"] = "也好。",
	["$yiji2"] = "罢了。",
	["~guojia"] = "咳，咳……",
	
--甄姬
	["$luoshen1"] = "仿佛兮若轻云之蔽月。",
	["$luoshen2"] = "飘摇兮若流风之回雪。",
	["$qingguo1"] = "凌波微步，罗袜生尘。",
	["$qingguo2"] = "休迅飞凫，飘忽若神。",
	["~zhenji"] = "悼良会之永绝兮，哀一逝而异乡。",
	

--刘备
	["$rende1"] = "以德服人。",
	["$rende2"] = "惟贤惟德，能服于人。",
	["$jijiang1"] = "蜀将何在？",
	["$jijiang2"] = "尔等敢应战否？",
	["~liubei"] = "这就是桃园吗？",
	
--关羽
	["$wusheng1"] = "关羽在此，尔等受死！", 
	["$wusheng2"] = "看尔乃插标卖首！",
	["~guanyu"] = "什么？此地名叫麦城？",
	
--张飞
	["$paoxiao1"] = "啊～",
	["$paoxiao2"] = "燕人张飞在此！",
	["~zhangfei"] = "实在是杀不动了……",
	
--诸葛亮
	["$guanxing1"] = "观今夜天象，知天下大事。",
	["$guanxing2"] = "知天易，逆天难。",
	["$guanxing3"] = "继丞相之遗志，讨篡汉之逆贼！",--姜维
	["$guanxing4"] = "克复中原，指日可待！",--姜维
	["$kongcheng1"] = "（抚琴声）", 
	["$kongcheng2"] = "（抚琴声）", 
	["~zhugeliang"] = "将星陨落，天命难违。",
	
--赵云
	["$longdan1"] = "能进能退，乃真正法器！", 
	["$longdan2"] = "吾乃常山赵子龙也！",
	["~zhaoyun"] = "这，就是失败的滋味吗？",
	
--马超
	["$tieji1"] = "全军突击！",
	["$tieji2"] = "(枪声，马叫声)",
	["~machao"] = "(马蹄声……)",
	
--黄月英
	["$jizhi1"] = "哼哼～",
	["$jizhi2"] = "哼～",
	["~huangyueying"] = "亮……",

	
--孙权
	["$zhiheng1"] = "容我三思。",
	["$zhiheng2"] = "且慢。",
	["$jiuyuan1"] = "有汝辅佐，甚好！",
	["$jiuyuan2"] = "好舒服啊～",
	["~sunquan"] = "父亲，大哥，仲谋愧矣……",
	
--甘宁
	["$qixi1"] = "接招吧。",
	["$qixi2"] = "你的牌太多啦～",
	["~ganning"] = "二十年后，又是一条…好汉！",
	
--吕蒙
	["$keji1"] = "不是不报，时候未到！",
	["$keji2"] = "留得青山在，不怕没柴烧！",
	["~lvmeng"] = "被看穿了吗？",
	
--黄盖
	["$kurou1"] = "请鞭笞我吧 ，公瑾！",
	["$kurou2"] = "赴汤蹈火，在所不辞！",
	["~huanggai"] = "失血过多了……",
	
--周瑜
	["$yingzi1"] = "哈哈哈哈~", 
	["$yingzi2"] = "汝等看好了！",
	["$fanjian1"] = "挣扎吧，在血和暗的深渊里！", 
	["$fanjian2"] = "痛苦吧，在仇与恨的地狱中！", 
	["~zhouyu"] = "既生瑜，何生……",
	
--大乔
	["$guose1"] = "请休息吧。", 
	["$guose2"] = "你累了。", 
	["$liuli1"] = "交给你了。", 
	["$liuli2"] = "你来嘛～", 
	["~daqiao"] = "伯符，我去了……",
	
--陆逊
	["$lianying1"] = "牌不是万能的，但是没牌是万万不能的。",
	["$lianying2"] = "旧的不去，新的不来。",
	["~luxun"] = "我还是太年轻了……",
	
--孙尚香
	["$jieyin1"] = "夫君，身体要紧。", 
	["$jieyin2"] = "他好，我也好。", 
	["$xiaoji1"] = "哼！", 
	["$xiaoji2"] = "看我的厉害！", 
	["~sunshangxiang"] = "不！还不可以死！",

	
--华佗
	["$jijiu1"] = "别紧张，有老夫呢。", 
	["$jijiu2"] = "救人一命，胜造七级浮屠。", 
	["$qingnang1"] = "早睡早起，方能养生。", 
	["$qingnang2"] = "越老越要补啊。", 
	["~huatuo"] = "医者…不能自医啊……",
	
--吕布
	["$wushuang1"] = "谁能挡我！",
	["$wushuang2"] = "神挡杀神，佛挡杀佛！",
	["~lvbu"] = "不可能！",
	
--貂蝉
	["$biyue1"] = "失礼了～",
	["$biyue2"] = "羡慕吧～",
	["$lijian1"] = "嗯呵呵～呵呵～",
	["$lijian2"] = "夫君，你要替妾身做主啊～",
	["~diaochan"] = "父亲大人，对不起……",	
	
	["$guidao1"] = "哼哼哼哼…",
	["$guidao2"] = "天下大势，为我所控！",

-- test
	["test"] = "测试",

	["#zhibasunquan"] = "年轻的贤君",
	["zhibasunquan"] = "制霸孙权",
	["&zhibasunquan"] = "孙权",
	["super_zhiheng"] = "制衡",
	[":super_zhiheng"] = "出牌阶段，你可以弃置任意数量的牌：若如此做，你摸等数量的牌。每阶段你可以发动X+1次该技能。（X为你已损失的体力值）",
	["$super_zhiheng1"] = "容我三思。",
	["$super_zhiheng2"] = "且慢。",
	
	["#wuxingzhuge"] = "迟暮的丞相",
	["wuxingzhuge"] = "五星诸葛",
	["&wuxingzhuge"] = "诸葛亮", 
	["super_guanxing"] = "观星",
	[":super_guanxing"] = "回合开始阶段开始时，你可以观看牌堆顶的五张牌，然后将任意数量的牌以任意顺序置于牌堆顶，将其余的牌以任意顺序置于牌堆底。",
	
	["#super_yuanshu"] = "仲家帝",
	["super_yuanshu"] = "袁术-测试",
	["&super_yuanshu"] = "袁术",
	["illustrator:super_yuanshu"] = "吴昊",
	["super_yongsi"] = "庸肆",
	[":super_yongsi"] = "<font color=\"blue\"><b>锁定技。</b></font>摸牌阶段，你额外摸X张牌。弃牌阶段开始时，你须弃置X张牌。",
	
	["#super_caoren"] = "大司马",
	["super_caoren"] = "曹仁-测试",
	["&super_caoren"] = "曹仁",
	["super_jushou"] = "据守",
	[":super_jushou"] = "回合结束阶段开始时，你可以摸X张牌，然后将武将牌翻面。",

	["super_max_cards"] = "手牌上限",
	["super_offensive_distance"] = "距离-X",
	["super_defensive_distance"] = "距离+X",
	
	["increase"] = "增加",
	["decrease"] = "减少",
	
	["#gaodayihao"] = "神威如龙",
	["gaodayihao"] = "高达一号",
	["&gaodayihao"] = "神赵云",
	["illustrator:gaodayihao"] = "巴萨小马",
	["nosjuejing"] = "绝境",
	[":nosjuejing"] = "<font color=\"blue\"><b>锁定技。</b></font>摸牌阶段，你不摸牌。每当你的手牌数变化后，若你的手牌数不为4，你须将手牌补至或弃置至四张。",
	["noslonghun"] = "龙魂",
	[":noslonghun"] = "你可以将一张牌按以下规则使用或打出：<font color=\"red\">♥</font>当【桃】；<font color=\"red\">♦</font>当火【杀】；♠当【无懈可击】；♣当【闪】。回合开始阶段开始时，若其他角色的装备区内有【青釭剑】，你可以获得之。",
	["#noslonghun_duojian"] = "龙魂",
	["$noslonghun1"] = "金甲映日,驱邪祛秽", -- spade
	["$noslonghun2"] = "腾龙行云,首尾不见", -- club
	["$noslonghun3"] = "潜龙于渊,涉灵愈伤", -- heart
	["$noslonghun4"] = "千里一怒,红莲灿世", -- diamond
	["$noslonghun5"] = "龙战于野,其血玄黄",
	
	["#nobenghuai_dongzhuo"] = "魔王",
	["nobenghuai_dongzhuo"] = "董卓-无崩",
	["&nobenghuai_dongzhuo"] = "董卓",
	["illustrator:nobenghuai_dongzhuo"] = "小冷",
	
	["#sujiang"] = "金童",
	["sujiang"] = "素将",
	["illustrator:sujiang"] = "火凤燎原",
	["#sujiangf"] = "玉女",
	["sujiangf"] = "素将(女)",
	["&sujiangf"] = "素将",
	["illustrator:sujiangf"] = "轩辕剑",
}

