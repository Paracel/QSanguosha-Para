-- this script to store the basic configuration for game program itself
-- and it is a little different from config.ini

config = {
	version = "20130301",
	version_name = "Alpha",
	mod_name = "Para",
	kingdoms = { "wei", "shu", "wu", "qun", "god" },
	package_names = {
		"StandardCard",
		"StandardExCard",
		"Maneuvering",
		"SPCard",
		"Nostalgia",
		"GreenHandCard",
		"New3v3Card",

		"Standard",
		"Wind",
		"Fire",
		"Thicket",
		"Mountain",
		"God",
		"YJCM",
		"YJCM2012",
		"Assassins", 
		"Special3v3",
		"SP",
		"BGM",
		"BGMDIY",
		"Hegemony",
		"HegemonySP",
		"Ling",
		"NostalYJCM",
		"NostalYJCM2012",
		"NostalGeneral",
		"GreenHand",
		"Dragon",
		"Test"
	},

	scene_names = {
		"Guandu",
		"Fancheng",
		"Couple",
		"Custom"
	},

	hulao_packages = {
		"standard",
		"wind"
	},

	xmode_packages = {
		"standard",
		"wind",
		"fire"
	},

	color_wei = "#547998",
	color_shu = "#D0796C",
	color_wu = "#4DB873",
	color_qun = "#8A807A",
	color_god = "#96943D",

	easy_text = {
		"太慢了，做两个俯卧撑吧！",
		"快点吧，我等的花儿都谢了！",
		"高，实在是高！",
		"好手段，可真不一般啊！",
		"哦，太菜了。水平有待提高。",
		"你会不会玩啊？！",
		"嘿，一般人，我不使这招。",
		"呵，好牌就是这么打地！",
		"杀！神挡杀神！佛挡杀佛！",
		"你也忒坏了吧？！"
	},

	kof_ban = {
		"sunquan",
		"huatuo"
	},

	hulao_ban = {
		"yuji"
	},

	xmode_ban = {
		"huatuo",
		"zhangjiao",
		"yuji"
	},

	basara_ban = {
		"dongzhuo",
		"zuoci",
		"shenzhugeliang",
		"shenlvbu",
		"bgm_lvmeng"
	},

	pairs_ban = {
		"huatuo", "zhoutai", "zuoci", "bgm_pangtong", "neo_zhoutai",
		"simayi+zhenji", "simayi+dengai",
		"caoren+shenlvbu", "caoren+caozhi", "caoren+bgm_diaochan", "caoren+bgm_caoren", "caoren+neo_caoren",
		"guojia+dengai",
		"zhenji+zhangjiao", "zhenji+shensimayi", "zhenji+zhugejin", "zhenji+nos_wangyi",
		"zhanghe+yuanshu",
		"dianwei+weiyan",
		"dengai+zhangjiao", "dengai+shensimayi", "dengai+zhugejin",
		"liubei+luxun", "liubei+zhangchunhua", "liubei+nos_zhangchunhua",
		"zhangfei+huanggai", "zhangfei+zhangchunhua", "zhangfei+nos_zhangchunhua",
		"zhugeliang+xushu", "zhugeliang+nos_xushu",
		"huangyueying+wolong", "huangyueying+ganning", "huangyueying+huanggai", "huangyueying+yuanshao", "huangyueying+yanliangwenchou",
		"huangzhong+xusheng",
		"wolong+luxun", "wolong+zhangchunhua", "wolong+nos_zhangchunhua",
		"sunquan+sunshangxiang",
		"lvmeng+yuanshu",
		"huanggai+sunshangxiang", "huanggai+yuanshao", "huanggai+yanliangwenchou", "huanggai+dongzhuo",
		    "huanggai+wuguotai", "huanggai+guanxingzhangbao", "huanggai+huaxiong", "huanggai+xiahouba", "huanggai+nos_guanxingzhangbao", "huanggai+neo_zhangfei",
		"luxun+yuji", "luxun+yanliangwenchou", "luxun+guanxingzhangbao", "luxun+heg_luxun", "luxun+nos_guanxingzhangbao",
		"sunshangxiang+shensimayi", "sunshangxiang+heg_luxun",
		"sunce+guanxingzhangbao", "sunce+nos_guanxingzhangbao",
		"yanliangwenchou+zhangchunhua", "yanliangwenchou+nos_zhangchunhua",
		"dongzhuo+shenzhaoyun", "dongzhuo+wangyi", "dongzhuo+diy_wangyuanji", "dongzhuo+nos_zhangchunhua", "dongzhuo+nos_wangyi",
		"yuji+zhangchunhua", "yuji+nos_zhangchunhua",
		"shenlvbu+caozhi", "shenlvbu+liaohua", "shenlvbu+bgm_diaochan", "shenlvbu+bgm_caoren", "shenlvbu+neo_caoren",
		"shenzhaoyun+huaxiong",
		"caozhi+bgm_diaochan", "caozhi+bgm_caoren", "caozhi+neo_caoren",
		"gaoshun+zhangchunhua", "gaoshun+nos_zhangchunhua",
		"zhangchunhua+guanxingzhangbao", "zhangchunhua+xiahouba", "zhangchunhua+heg_luxun", "zhangchunhua+nos_guanxingzhangbao", "zhangchunhua+neo_zhangfei",
		"guanxingzhangbao+bgm_zhangfei", "guanxingzhangbao+nos_zhangchunhua",
		"liaohua+bgm_diaochan",
		"xiahouba+nos_zhangchunhua",
		"bgm_diaochan+bgm_caoren",
		"bgm_caoren+neo_caoren",
		"bgm_zhangfei+nos_guanxingzhangbao",
		"nos_zhangchunhua+heg_luxun", "nos_zhangchunhua+nos_guanxingzhangbao", "nos_zhangchunhua+neo_zhangfei",
	},
	
	couple_lord = "caocao",
	couple_couples = {
		"caopi|caozhi+zhenji",
		"simayi|shensimayi+zhangchunhua",
		"diy_simazhao+diy_wangyuanji",
		"liubei|bgm_liubei+ganfuren|sp_sunshangxiang",
		"zhugeliang|wolong|shenzhugeliang+huangyueying",
		"menghuo+zhurong",
		"zhouyu|shenzhouyu+xiaoqiao",
		"lvbu|shenlvbu|dongzhuo+diaochan|bgm_diaochan",
		"sunjian+wuguotai",
		"sunce+daqiao|bgm_daqiao",
		"sunquan+bulianshi"
	}
}