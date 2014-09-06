-- This is the Smart AI, and it should be loaded and run at the server side

-- "middleclass" is the Lua OOP library written by kikito
-- more information see: https://github.com/kikito/middleclass

-- initialize the random seed for later use
math.randomseed(tostring(os.time()):reverse():sub(1, 6))

-- SmartAI is the base class for all other specialized AI classes
SmartAI = (require "middleclass").class("SmartAI")

version = "QSanguosha AI 20140801 (V1.41421356 Alpha)"
--- this function is only function that exposed to the host program
--- and it clones an AI instance by general name
-- @param player The ServerPlayer object that want to create the AI object
-- @return The AI object
function CloneAI(player)
	return SmartAI(player).lua_ai
end

sgs.ais = {}
sgs.ai_card_intention = {}
sgs.ai_playerchosen_intention = {}
sgs.ai_role = {}
sgs.role_evaluation = {}
sgs.ai_keep_value = {}
sgs.ai_use_value = {}
sgs.ai_use_priority = {}
sgs.ai_global_flags = {}
sgs.ai_current_judge = {}
sgs.ai_skill_invoke = {}
sgs.ai_skill_suit = {}
sgs.ai_skill_cardask = {}
sgs.ai_skill_choice = {}
sgs.ai_skill_askforag = {}
sgs.ai_skill_askforyiji = {}
sgs.ai_skill_pindian = {}
sgs.ai_skill_playerchosen = {}
sgs.ai_skill_discard = {}
sgs.ai_cardshow = {}
sgs.ai_skill_cardchosen = {}
sgs.ai_skill_use = {}
sgs.ai_cardneed = {}
sgs.ai_skill_use_func = {}
sgs.ai_skills = {}
sgs.ai_slash_weaponfilter = {}
sgs.ai_slash_prohibit = {}
sgs.ai_view_as = {}
sgs.ai_cardsview = {}
sgs.ai_cardsview_valuable = {}
sgs.ai_nullification = {}
sgs.dynamic_value = {
	damage_card = {},
	control_usecard = {},
	control_card = {},
	lucky_chance = {},
	benefit = {}
}
sgs.ai_choicemade_filter = {
	cardUsed = {},
	cardResponded = {},
	cardChosen = {},
	skillInvoke = {},
	skillChoice = {},
	Nullification = {},
	playerChosen = {},
	Yiji = {},
	viewCards = {},
	pindian = {}
}

sgs.card_lack = {}
sgs.ai_need_damaged = {}
sgs.ai_debug_func = {}
sgs.ai_event_callback = {}
sgs.ai_defense = {
	Normal = {},
	Process = {}
}

for i = sgs.NonTrigger, sgs.NumOfEvents, 1 do
	sgs.ai_event_callback[i] = {}
end

function setInitialTables()
	sgs.current_mode_players = { lord = 0, loyalist = 0, rebel = 0, renegade = 0 }
	sgs.ai_type_name = { "Skill", "Basic", "Trick", "Equip" }
	sgs.lose_equip_skill = "kofxiaoji|xiaoji|xuanfeng|nosxuanfeng"
	sgs.need_kongcheng = "lianying|noslianying|kongcheng|sijian"
	sgs.masochism_skill = "nosyiji|yiji|jieming|fankui|nosfankui|nosenyuan|ganglie|vsganglie|nosganglie|enyuan|fangzhu|guixin|langgu|quanji|fenyong|chengxiang|noschengxiang"
	sgs.wizard_skill = "guicainosguicai|guidao|jilve|tiandu|noszhenlie|huanshi"
	sgs.wizard_harm_skill = "guicai|nosguicai|guidao|jilve|huanshi"
	sgs.priority_skill = "dimeng|haoshi|qingnang|nosjizhi|jizhi|guzheng|qixi|jieyin|nosguose|guose|duanliang|jujian|fanjian|nosfanjian|noslijian|lijian|" ..
							"manjuan|lihun|tuxi|nostuxi|qiaobian|yongsi|zhiheng|luoshen|nosrende|rende|mingce|wansha|gongxin|jilve|" ..
							"anxu|qice|yinling|qingcheng|zhaoxin"
	sgs.save_skill = "jijiu|buyi|nosjiefan|chunlao|longhun"
	sgs.exclusive_skill = "huilei|duanchang|enyuan|wuhun|zhuiyi|buqu|nosbuqu|nosyiji|yiji|ganglie|vsganglie|nosganglie|guixin|jieming|nosmiji"
	sgs.cardneed_skill = "paoxiao|tianyi|xianzhen|shuangxiong|nosjizhi|jizhi|noseguose|guose|duanliang|qixi|qingnang|yinling|nosluoyi|guhuo|nosguhuo|kanpo|" ..
							"jieyin|renjie|zhiheng|nosrende|rende|nosjujian|guicai|nosguicai|guidao|longhun|luanji|qiaobian|beige|jieyuan|" ..
							"mingce|nosfuhun|lirang|xuanfeng|xinzhan|dangxian|bifa|xiaoguo"
	sgs.drawpeach_skill = "tuxi|nostuxi|qiaobian"
	sgs.recover_skill = "nosrende|rende|kuanggu|kofkuanggu|zaiqi|jieyin|qingnang|shenzhi"
	sgs.use_lion_skill = "longhun|duanliang|qixi|guidao|noslijian|lijian|jujian|nosjujian|zhiheng|mingce|yongsi|fenxun|gongqi|" ..
							"yinling|jilve|qingcheng|diyyicong"
	sgs.need_equip_skill = "shensu|mingce|jujian|beige|yuanhu|huyuan|gongqi|nosgongqi|yanzheng|qingcheng|longhun"

	sgs.Friend_All = 0
	sgs.Friend_Draw = 1
	sgs.Friend_Male = 2
	sgs.Friend_Female = 3
	sgs.Friend_Wounded = 4
	sgs.Friend_MaleWounded = 5
	sgs.Friend_FemaleWounded = 6

	for _, aplayer in sgs.qlist(global_room:getAllPlayers()) do
		table.insert(sgs.role_evaluation, aplayer:objectName())
		table.insert(sgs.ai_role, aplayer:objectName())
		if aplayer:isLord() then
			sgs.role_evaluation[aplayer:objectName()] = { lord = 99999, rebel = 0, loyalist = 99999, renegade = 0 }
			sgs.ai_role[aplayer:objectName()] = "loyalist"
		else
			sgs.role_evaluation[aplayer:objectName()] = { rebel = 0, loyalist = 0, renegade = 0 }
			sgs.ai_role[aplayer:objectName()] = "neutral"
		end
	end

end

function SmartAI:initialize(player)
	self.player = player
	self.room = player:getRoom()
	self.role = player:getRole()
	self.lua_ai = sgs.LuaAI(player)
	self.lua_ai.callback = function(full_method_name, ...)
		--The __FUNCTION__ macro is defined as CLASS_NAME::SUBCLASS_NAME::FUNCTION_NAME
		--in MSVC, while in gcc only FUNCTION_NAME is in place.
		local method_name_start = 1
		while true do
			local found = string.find(full_method_name, "::", method_name_start)
			if found ~= nil then
				method_name_start = found + 2
			else
				break
			end
		end
		local method_name = string.sub(full_method_name, method_name_start)
		local method = self[method_name]
		if method then
			local success, result1, result2
			success, result1, result2 = pcall(method, self, ...)
			if not success then
				self.room:writeToConsole(result1)
				self.room:writeToConsole(method_name)
				self.room:writeToConsole(debug.traceback())
				self.room:outputEventStack()
			else
				return result1, result2
			end
		end
	end

	self.retain = 2
	self.keepValue = {}
	self.kept = {}
	self.keepdata = {}
	self.predictedRange = 1
	self.slashAvail = 1
	if not sgs.initialized then
		sgs.initialized = true
		sgs.ais = {}
		sgs.turncount = 0
		sgs.ai_gameProcess = nil
		sgs.ai_gameProcess_arg = nil
		global_room = self.room
		global_room:writeToConsole(version .. ", Powered by " .. _VERSION)

		setInitialTables()
		if sgs.isRolePredictable() then
			for _, aplayer in sgs.qlist(global_room:getAllPlayers()) do
				if aplayer:getRole() ~= "lord" then sgs.role_evaluation[aplayer:objectName()][aplayer:getRole()] = 65535 end
			end
		end
	end

	sgs.ais[player:objectName()] = self

	sgs.card_lack[player:objectName()] = {}
	sgs.card_lack[player:objectName()]["Slash"] = 0
	sgs.card_lack[player:objectName()]["Jink"] = 0
	sgs.card_lack[player:objectName()]["Peach"] = 0

	self:updateAlivePlayerRoles()
	self:updatePlayers()
end

function sgs.cloneCard(name, suit, number)
	suit = suit or sgs.Card_SuitToBeDecided
	number = number or -1
	local card = sgs.Sanguosha:cloneCard(name, suit, number)
	card:deleteLater()
	return card
end

function sgs.getCardNumAtCertainPlace(card, player, place)
	if not card:isVirtualCard() and place == sgs.Player_PlaceHand then return 1
	elseif card:subcardsLength() == 0 then return 0
	else
		local num = 0
		for _, id in sgs.qlist(card:getSubcards()) do
			if place == sgs.Player_PlaceHand then
				if player:handCards():contains(id) then num = num + 1 end
			elseif place == sgs.Player_PlaceEquip then
				if player:hasEquip(sgs.Sanguosha:getCard(id)) then num = num + 1 end
			end
		end
		return num
	end
end

function sgs.getValue(player)
	if not player then global_room:writeToConsole(debug.traceback()) end
	return player:getHp() * 2 + player:getHandcardNum()
end

function sgs.getDefense(player)
	if not player then return 0 end
	local current_player = global_room:getCurrent()
	if not current_player then return sgs.getValue(player) end

	local handcard = (player:getMark("yijue") > 0) and 0 or player:getHandcardNum()
	local defense = math.min(player:getHp() * 2 + handcard + player:getPile("wooden_ox"):length(), player:getHp() * 3)
	local attacker = global_room:getCurrent()
	local hasEightDiagram = false
	if player:hasArmorEffect("eight_diagram") then
		hasEightDiagram = true
	end

	if not player:getArmor() and player:hasSkill("yizhong|bossmanjia") then defense = defense + 2 end

	if hasEightDiagram then
		defense = defense + 1.3
		if player:hasSkill("tiandu") then defense = defense + 0.6 end
		if player:hasSkill("leiji") then defense = defense + 0.4 end
		if player:hasSkill("nosleiji") then defense = defense + 0.4 end
		if player:hasSkill("noszhenlie") then defense = defense + 0.2 end
		if player:hasSkill("hongyan") then defense = defense + 0.2 end
	end

	if player:hasSkills("tuntian+zaoxian") and player:getMark("yijue") == 0 then defense = defense + player:getHandcardNum() * 0.4 end
	if player:hasSkill("aocai") and player:getPhase() == sgs.Player_NotActive then defense = defense + 0.3 end
	if not attacker or (attacker and not attacker:hasSkill("jueqing")) then
		local m = sgs.masochism_skill:split("|")
		for _, masochism in ipairs(m) do
			if player:hasSkill(masochism) and sgs.isGoodHp(player) then
				defense = defense + 1
			end
		end
		if player:hasSkill("jieming") then defense = defense + 3 end
		if player:hasSkill("nosyiji") then defense = defense + 3 end
		if player:hasSkill("yiji") then defense = defense + 3 end
		if player:hasSkill("guixin") then defense = defense + 4 end
		if player:hasSkill("yuce") then defense = defense + 2 end
		if player:hasSkills("chengxiang|noschengxiang") then defense = defense + 2 end

		if player:hasLordSkill("shichou") and player:getMark("xhate") == 1 then
			for _, p in sgs.qlist(global_room:getOtherPlayers(player)) do
				if p:getMark("hate_" .. player:objectName()) > 0 and p:getMark("@hate_to") > 0 then
					defense = defense + p:getHp()
					break
				end
			end
		end
	end
	if attacker and attacker:hasSkill("jueqing") and player:hasSkill("zhaxiang") then defense = defense + 4 end

	if player:hasSkill("nosrende") and player:getHp() > 2 and player:getHandcardNum() > 1 then defense = defense + 1 end
	if player:hasSkill("rende") and player:getHp() > 2 and player:getHandcardNum() > 1 then defense = defense + 1 end
	if player:hasSkill("kuanggu") and player:getHp() > 1 then defense = defense + 0.5 end
	if player:hasSkill("kofkuanggu") and player:getHp() > 1 then defense = defense + 1 end
	if player:hasSkill("zaiqi") and player:getHp() > 1 then defense = defense + player:getLostHp() * 0.5 end
	if player:hasSkill("tianming") then defense = defense + 0.5 end
	if player:hasSkill("nosmiji") then defense = defense + player:getLostHp() * 0.5 end
	if player:hasSkill("keji") then defense = defense + player:getHandcardNum() * 0.25 end
	if player:hasSkill("aocai") and player:getPhase() == sgs.Player_NotActive then defense = defense + 0.5 end
	if player:hasSkill("wanrong") and not hasManjuanEffect(player) then defense = defense + 0.5 end
	if player:hasSkill("tianxiang") then defense = defense + player:getHandcardNum() * 0.5 end

	if player:getHp() > getBestHp(player) then defense = defense + 0.8 end
	if player:getHp() <= 2 then defense = defense - 0.4 end
	if player:hasSkill("benghuai") and player:getMaxHp() <= 5 then defense = defense - 1 end

	if player:isLord() then
		defense = defense - 0.4
		if sgs.isLordInDanger() then defense = defense - 0.7 end
	end

	if not player:faceUp() then defense = defense - 1 end

	if player:containsTrick("indulgence") and not player:containsTrick("YanxiaoCard") then defense = defense - 0.5 end
	if player:containsTrick("supply_shortage") and not player:containsTrick("YanxiaoCard") then defense = defense - 0.5 end

	if player:hasSkill("qianhuan") then defense = defense + 2 + player:getPile("sorcery"):length() end
	if player:hasSkill("jijiu") then defense = defense + 2 end
	if player:hasSkill("qingnang") then defense = defense + 2 end
	if player:hasSkill("dimeng") then defense = defense + 2.5 end
	if player:hasSkill("guzheng") then defense = defense + 2.5 end
	if player:hasSkill("qiaobian") then defense = defense + 2.4 end
	if player:hasSkill("jieyin") then defense = defense + 2.3 end
	if player:hasSkill("noslijian") then defense = defense + 2.2 end
	if player:hasSkill("lijian") then defense = defense + 2.1 end
	if player:hasSkill("nosmiji") and player:isWounded() then defense = defense + 1.5 end
	if player:hasSkill("guhuo") then
		for _, p in sgs.qlist(global_room:getOtherPlayers(player)) do
			if p:hasSkill("chanyuan") then defense = defense + 1 end
		end
	end
	if player:hasSkills("huashen+xinsheng") then defense = defense + (player:getState() == "online" and 4 or 2) end
	if player:hasSkill("paiyi") then defense = defense + 1.5 end
	if player:hasSkill("yongsi") then defense = defense + 2 end

	defense = defense + (player:aliveCount() - (player:getSeat() - current_player:getSeat()) % player:aliveCount()) / 4
	defense = defense + player:getVisibleSkillList(true):length() * 0.25

	return defense
end

function SmartAI:assignKeep(start)
	if start then
		self.keepValue = {}
		self.kept = {}

		self.keepdata = {}
		for k, v in pairs(sgs.ai_keep_value) do
			self.keepdata[k] = v
		end
		for _, askill in ipairs(sgs.getPlayerSkillList(self.player)) do
			local skilltable = sgs[askill:objectName() .. "_keep_value"]
			if skilltable then
				for k, v in pairs(skilltable) do
					self.keepdata[k] = v
				end
			end
		end
		local num = self.player:getMaxCards()
		if self.player:hasSkill("keji") then num = math.max(self.player:getHandcardNum(), num) end
		if self.player:hasSkill("qiaobian") then num = math.max(self.player:getHandcardNum() - 1, num) end
		if not self:isWeak() or num >= 4 then
			for _, friend in ipairs(self.friends_noself) do
				if self:willSkipDrawPhase(friend) or self:willSkipPlayPhase(friend) then
					self.keepdata.Nullification = 5.5
					break
				end
			end
		end
		if not self:isWeak() then
			local needDamaged = false
			if self.player:getHp() > getBestHp(self.player) then needDamaged = true end
			if not needDamaged and not sgs.isGoodTarget(self.player, self.friends, self) then needDamaged = true end
			if not needDamaged then
				for _, skill in ipairs(sgs.getPlayerSkillList(self.player)) do
					local callback = sgs.ai_need_damaged[skill:objectName()]
					if type(callback) == "function" and callback(self, nil, self.player) then
						needDamaged = true
						break
					end
				end
			end
			if needDamaged then
				self.keepdata.ThunderSlash = 5.2
				self.keepdata.FireSlash = 5.1
				self.keepdata.Slash = 5
				self.keepdata.Jink = 4.5
			end
		end
		for _, enemy in ipairs(self.enemies) do
			if enemy:hasSkill("nosqianxi") and enemy:distanceTo(self.player) == 1 then
				self.keepdata.Jink = 6
			end
		end
		if self:isWeak() then
			for _, ap in sgs.qlist(self.room:getAlivePlayers()) do
				if ap:hasSkill("buyi") and self:isFriend(ap) then
					self.keepdata.TrickCard = 8
					self.keepdata.EquipCard = 7.9
					break
				end
			end
			self.keepdata.Peach = (self.keepdata.Peach or 7) + (4 - math.max(self.player:getHp(), 0))
			self.keepdata.Analeptic = (self.keepdata.Analeptic or 4.1) + (4 - math.max(self.player:getHp(), 0))
		end
	end
	local cards = self.player:getHandcards()
	cards = sgs.QList2Table(cards)
	self:sortByKeepValue(cards, true, self.kept, true)
	
	local resetCards = function(allcards)
		local result = {}
		for _, a in ipairs(allcards) do
			local found
			for _, b in ipairs(self.kept) do
				if a:getEffectiveId() == b:getEffectiveId() then
					found = true
					break
				end
			end
			if not found then table.insert(result, a) end
		end
		return result
	end
	
	local cards_num = #cards
	for i = 1, cards_num do
		local card = cards[1]
		self.keepValue[card:getId()] = self:getKeepValue(card, self.kept)
		table.insert(self.kept, card)
		cards = resetCards(cards)
		if #cards == 0 then break end
	end
end

function SmartAI:getKeepValue(card, kept, wrt)
	if not kept then
		local cardPlace = self.room:getCardPlace(card:getEffectiveId())
		if cardPlace == sgs.Player_PlaceHand then
			local v = self.keepValue[card:getId()]
			if not v then
				self.room:writeToConsole(card:getId() .. " " .. card:objectName())
				self.room:writeToConsole(debug.traceback())
				v = 0
			end
			return v
		else
			local at_play = self.player:getPhase() == sgs.Player_Play
			if card:isKindOf("SilverLion") and self.player:isWounded() then return -10 end
			if self.player:hasSkills(sgs.lose_equip_skill) then
				if card:isKindOf("OffensiveHorse") then return -10
				elseif card:isKindOf("Weapon") then return -9.9
				elseif card:isKindOf("OffensiveHorse") then return -9.8
				else return -9.7
				end
			end
			if card:isKindOf("Armor") then
				if self.player:hasSkills("bazhen|yizhong")
					or (self.player:hasSkill("bossmanjia") and sgs.ai_armor_value.vine(self.player, self, true) > 0) then return -10 end
			end
			if self:needKongcheng() then return 5.0 end
			if card:isKindOf("Armor") then return self:isWeak() and 5.2 or 3.2
			elseif card:isKindOf("DefensiveHorse") then return self:isWeak() and 4.3 or 3.19
			elseif card:isKindOf("Weapon") then return (at_play and self:slashIsAvailable() and self:getCardsNum("Slash") > 0) and 3.39 or 3.2
			else return 3.19
			end
		end
		return self.keepValue[card:getId()] or self.keepdata[card:getClassName()] or 0
	end

	local value_suit, value_number, newvalue = 0, 0, 0
	if wrt then
		local class_name = card:getClassName()
		local suit_string = card:getSuitString()
		local number = card:getNumber()
		local i = 0
		
		for _, askill in ipairs(sgs.getPlayerSkillList(self.player)) do
			if sgs[askill:objectName() .. "_suit_value"] then
				local v = sgs[askill:objectName() .. "_suit_value"][suit_string]
				if v then
					i = i + 1
					value_suit = value_suit + v
				end
			end
		end
		if i > 0 then value_suit = value_suit / i end
		
		i = 0
		for _, askill in ipairs(sgs.getPlayerSkillList(self.player)) do
			if sgs[askill:objectName() .. "_number_value"] then
				local v = sgs[askill:objectName() .. "_number_value"][tostring(number)]
				if v then
					i = i + 1
					value_number = value_number + v
				end
			end
		end
		if i > 0 then value_number = value_number / i end
	end
	
	local maxvalue, mostvaluable_class = -10, card:getClassName()
	for k, v in pairs(self.keepdata) do
		if isCard(k, card, self.player) and v > maxvalue then
			maxvalue = v
			mostvaluable_class = k
		end
	end
	
	newvalue = maxvalue + value_suit + value_number
	
	if wrt then return newvalue end
	
	newvalue = self.keepValue[card:getId()] or 0
	local dec = 0
	for _, acard in ipairs(kept) do
		if isCard(mostvaluable_class, acard, self.player) and isCard(mostvaluable_class, card, self.player) then
			newvalue = newvalue - 1.2 - dec
			dec = dec + 0.1
		elseif acard:isKindOf("Slash") and card:isKindOf("Slash") then
			newvalue = newvalue - 1.2 - dec
			dec = dec + 0.1
		end
	end
	return newvalue
end

function SmartAI:getUseValue(card)
	local class_name = card:getClassName()
	local v = sgs.ai_use_value[class_name] or 0
	if class_name == "LuaSkillCard" and card:isKindOf("LuaSkillCard") then
		v = sgs.ai_use_value[card:objectName()] or 0
	end

	if card:isKindOf("GuhuoCard") or card:isKindOf("NosGuhuoCard") then
		local userstring = card:toString()
		userstring = (userstring:split(":"))[3]
		local guhuocard = sgs.cloneCard(userstring, card:getSuit(), card:getNumber())
		local usevalue = self:getUseValue(guhuocard) + #self.enemies * 0.3
		if sgs.Sanguosha:getCard(card:getSubcards():first()):objectName() == userstring
			and (card:isKindOf("GuhuoCard") or card:getSuit() == sgs.Card_Heart) then usevalue = usevalue + 3 end
		return usevalue
	end

	if card:getTypeId() == sgs.Card_TypeEquip then
		if self.player:hasEquip(card) then
			if card:isKindOf("OffensiveHorse") and self.player:getAttackRange() > 2 then return 5.5 end
			if card:isKindOf("DefensiveHorse") and self:hasEightDiagramEffect() then return 5.5 end
			return 9
		end
		if not self:getSameEquip(card) then v = 6.7 end
		if self.weaponUsed and card:isKindOf("Weapon") then v = 2 end
		if self.player:hasSkill("qiangxi") and card:isKindOf("Weapon") then v = 2 end
		if self.player:hasSkill("noskurou") and card:isKindOf("Crossbow") then return 9 end
		if self.player:hasSkills("bazhen|yizhong|bossmanjia") and card:isKindOf("Armor") then v = 2 end
		if self.role == "loyalist" and self.player:getKingdom() == "wei" and not self.player:hasSkills("bazhen|yizhong|bossmanjia")
			and self.room:getLord() and self.room:getLord():hasLordSkill("hujia") and card:isKindOf("EightDiagram") then
			v = 9
		end
		if self.player:hasSkills(sgs.lose_equip_skill) then return 10 end
	elseif card:getTypeId() == sgs.Card_TypeBasic then
		if card:isKindOf("Slash") then
			if self.player:hasFlag("TianyiSuccess") or self.player:hasFlag("JiangchiInvoke")
				or self:hasHeavySlashDamage(self.player, card) then v = 8.7 end
			if self.player:hasWeapon("Crossbow") or self.player:hasSkill("paoxiao") then v = v + 4 end
			if card:getSkillName() == "longdan" and self.player:hasSkill("chongzhen") then v = v + 1 end
			if card:getSkillName() == "fuhun" then v = v + (self.player:getPhase() == sgs.Player_Play and 1 or -1) end
		elseif card:isKindOf("Jink") then
			if self:getCardsNum("Jink") > 1 then v = v - 6 end
			if card:getSkillName() == "longdan" and self.player:hasSkill("chongzhen") then v = v + 1 end
		elseif card:isKindOf("Peach") then
			if self.player:isWounded() then v = v + 6 end
		end
	elseif card:getTypeId() == sgs.Card_TypeTrick then
		if self.player:getWeapon() and not self.player:hasSkills(sgs.lose_equip_skill) and card:isKindOf("Collateral") then v = 2 end
		if card:getSkillName() == "shuangxiong" then v = 6 end
		if card:isKindOf("Duel") then v = v + self:getCardsNum("Slash") * 2 end
		if self.player:hasSkill("nosjizhi") then v = v + 4 end
		if self.player:hasSkill("jizhi") then v = v + 3 end
		if self.player:hasSkill("wumou") and card:isNDTrick() and not card:isKindOf("AOE") then
			if not (card:isKindOf("Duel") and self.player:hasUsed("WuqianCard")) then v = 1 end
		end
	end

	if self.player:hasSkills(sgs.need_kongcheng) then
		if self.player:getHandcardNum() == 1 then v = 10 end
	end
	if self.player:hasWeapon("halberd") and card:isKindOf("Slash") and self.player:isLastHandCard(card) then v = 10 end
	if self.player:getPhase() == sgs.Player_Play then v = self:adjustUsePriority(card, v) end
	return v
end

function SmartAI:getUsePriority(card)
	local class_name = card:getClassName()
	local v = 0
	if card:isKindOf("EquipCard") then
		if self.player:hasSkills(sgs.lose_equip_skill) then return 15 end
		if card:isKindOf("Armor") and not self.player:getArmor() then v = (sgs.ai_use_priority[class_name] or 0) + 5.2
		elseif card:isKindOf("Weapon") and not self.player:getWeapon() then v = (sgs.ai_use_priority[class_name] or 0) + 3
		elseif card:isKindOf("DefensiveHorse") and not self.player:getDefensiveHorse() then v = 5.8
		elseif card:isKindOf("OffensiveHorse") and not self.player:getOffensiveHorse() then v = 5.5
		end
		return v
	end

	v = sgs.ai_use_priority[class_name] or 0
	if class_name == "LuaSkillCard" and card:isKindOf("LuaSkillCard") then
		v = sgs.ai_use_priority[card:objectName()] or 0
	end
	return self:adjustUsePriority(card, v)
end

function SmartAI:adjustUsePriority(card, v)
	if v <= 0 then return 0 end
	if card:isKindOf("Slash") then
		if card:getSkillName() == "Spear" then v = v - 0.1 end
		if card:isRed() then
			if self.slashAvail == 1 and self.player:hasSkill("jie") then v = v + 0.16 end
			for _, friend in ipairs(self.friends) do
				if friend:hasSkill("longyin") and friend:canDiscard(friend, "he") and not hasManjuanEffect(friend) then
					v = v + 0.16
					break
				end
			end
			v = v - 0.05
		end
		if self.player:getMark("qiangwu") > 0 and card:getNumber() > self.player:getMark("qiangwu") then v = v + 0.08 end
		if card:isKindOf("NatureSlash") then
			if self.slashAvail == 1 then
				v = v + 0.05
				if card:isKindOf("FireSlash") then
					for _, enemy in ipairs(self.enemies) do
						if enemy:hasArmorEffect("vine") or enemy:getMark("@gale") > 0 then v = v + 0.07 break end
					end
				elseif card:isKindOf("ThunderSlash") then
					for _, enemy in ipairs(self.enemies) do
						if enemy:getMark("@fog") > 0 then v = v + 0.06 break end
					end
				end
			else
				v = v - 0.05
			end
		end
		if card:getSkillName() == "longdan" and self.player:hasSkill("chongzhen") then v = v + 0.08 end
		if card:getSkillName() == "fuhun" then v = v + (self.player:getPhase() == sgs.Player_Play and 0.06 or -0.05) end
		if self.player:hasSkill("jiang") and card:isRed() then v = v + 0.05 end
		if self.player:hasSkill("wushen") and card:getSuit() == sgs.Card_Heart then v = v + 0.03 end
		if self.player:hasSkill("jinjiu") and card:getEffectiveId() >= 0 and sgs.Sanguosha:getEngineCard(card:getEffectiveId()):isKindOf("Analeptic") then v = v + 0.03 end
		if self.slashAvail == 1 then
			v = v + math.min(sgs.Sanguosha:correctCardTarget(sgs.TargetModSkill_ExtraTarget, self.player, card) * 0.1, 0.5)
			v = v + math.min(sgs.Sanguosha:correctCardTarget(sgs.TargetModSkill_DistanceLimit, self.player, card) * 0.05, 0.5)
			if self.player:hasSkill("lihuo") and card:isKindOf("FireSlash") and card:getSkillName() == "lihuo" then v = v - 0.02 end
		end
	end
	if self.player:hasSkill("mingzhe") and card:isRed() then v = v + (self.player:getPhase() ~= sgs.Player_NotActive and 0.05 or -0.05) end
	v = v + (13 - card:getNumber()) / 1000
	if self.player:getPhase() == sgs.Player_Play and self.player:hasSkill("botu") and card:getSuit() <= 3
		and bit32.band(self.player:getMark("botu"), bit32.lshift(1, card:getSuit())) == 0 then v = v + 0.05 end
	if not self.player:getPile("wooden_ox"):isEmpty() then
		local id_table = {}
		if not card:isVirtualCard() then id_table = { card:getEffectiveId() }
		else id_table = sgs.QList2Table(card:getSubcards()) end
		for _, id in ipairs(id_table) do
			if self.player:getPile("wooden_ox"):contains(id) then
				v = v + 0.05
				break
			end
		end
	end
	return v
end

function SmartAI:getDynamicUsePriority(card)
	if not card then return 0 end

	if card:hasFlag("AIGlobal_KillOff") then return 15 end
	local class_name = card:getClassName()
	local dynamic_value

	-- direct control
	if card:isKindOf("AmazingGrace") then
		local zhugeliang = self.room:findPlayerBySkillName("kongcheng")
		if zhugeliang and self:isEnemy(zhugeliang) and zhugeliang:isKongcheng() then
			return math.max(sgs.ai_use_priority.Slash, sgs.ai_use_priority.Duel) + 0.1
		end
	end
	if card:isKindOf("Peach") and self.player:hasSkills("kuanggu|kofkuanggu") then return 1.01 end
	if card:isKindOf("YanxiaoCard") and self.player:containsTrick("YanxiaoCard") then return 0.1 end
	if card:isKindOf("DelayedTrick") and not card:isKindOf("YanxiaoCard") and #card:getSkillName() > 0 then
		return (sgs.ai_use_priority[card:getClassName()] or 0.01) - 0.01
	end
	if self.player:hasSkill("nosdanshou") and not self.player:hasSkill("jueqing")
		and (card:isKindOf("Slash") or card:isKindOf("Duel") or card:isKindOf("AOE")
			or sgs.dynamic_value.damage_card[card:getClassName()]) then
		return 0
	end
	if card:isKindOf("Duel") then
		--[[if self:getCardsNum("FireAttack") > 0 and dummy_use.to and not dummy_use.to:isEmpty() then
			for _, p in sgs.qlist(dummy_use.to) do
				if p:getHp() == 1 then return sgs.ai_use_priority.FireAttack + 0.1 end
			end
		end]]
		if self:hasCrossbowEffect()
			or self.player:hasFlag("XianzhenSuccess")
			or self.player:canSlashWithoutCrossbow()
			or sgs.Sanguosha:correctCardTarget(sgs.TargetModSkill_Residue, self.player, sgs.cloneCard("slash")) > 0
			or self.player:hasUsed("FenxunCard") then
			return sgs.ai_use_priority.Slash - 0.1
		end
	end

	local value = self:getUsePriority(card) or 0
	if card:getTypeId() == sgs.Card_TypeEquip then
		if self.player:hasSkills(sgs.lose_equip_skill) then value = value + 12 end
		if card:isKindOf("Weapon") and self.player:getPhase() == sgs.Player_Play and #self.enemies > 0 then
			self:sort(self.enemies)
			local enemy = self.enemies[1]
			local v, inAttackRange = self:evaluateWeapon(card, self.player, enemy) / 20
			value = value + v
			if inAttackRange then value = value + 0.5 end
		end
	end

	if card:isKindOf("AmazingGrace") then
		dynamic_value = 10
		for _, player in sgs.qlist(self.room:getOtherPlayers(self.player)) do
			dynamic_value = dynamic_value - 1
			if self:isEnemy(player) then dynamic_value = dynamic_value - ((player:getHandcardNum() + player:getHp()) / player:getHp()) * dynamic_value
			else dynamic_value = dynamic_value + ((player:getHandcardNum() + player:getHp()) / player:getHp()) * dynamic_value
			end
		end
		value = value + dynamic_value
	end

	return value
end

function SmartAI:cardNeed(card)
	if not self.friends then self.room:writeToConsole(debug.traceback()) self.room:writeToConsole(sgs.turncount) return end
	local class_name = card:getClassName()
	local suit_string = card:getSuitString()
	local value
	if card:isKindOf("Peach") then
		self:sort(self.friends, "hp")
		if self.friends[1]:getHp() < 2 then return 13 end
		if (self.player:getHp() < 3 or self.player:getLostHp() > 1 and not (self.player:hasSkill("longhun") or hasBuquEffect(self.player))) or self.player:hasSkills("noskurou|benghuai") then return 15 end
		return self:getUseValue(card)
	end
	local wuguotai = self.room:findPlayerBySkillName("buyi")
	if wuguotai and self:isFriend(wuguotai) and not card:isKindOf("BasicCard") and self:isWeak() then return 12 end
	if self:isWeak() and card:isKindOf("Jink") and self:getCardsNum("Jink") < 1 then return 11 end

	local i = 0
	for _, askill in ipairs(sgs.getPlayerSkillList(self.player)) do
		if sgs[askill:objectName() .. "_keep_value"] then
			local v = sgs[askill:objectName() .. "_keep_value"][class_name]
			if v then
				i = i + 1
				if value then value = value + v else value = v end
			end
		end
	end
	if value then return value / i + 4 end
	i = 0
	for _, askill in ipairs(sgs.getPlayerSkillList(self.player)) do
		if sgs[askill:objectName() .. "_suit_value"] then
			local v = sgs[askill:objectName() .. "_suit_value"][suit_string]
			if v then
				i = i + 1
				if value then value = value + v else value = v end
			end
		end
	end
	if value then return value / i + 4 end

	if card:isKindOf("Slash") and self:getCardsNum("Slash") == 0 then return 5.9 end
	if card:isKindOf("Analeptic") then
		if self.player:getHp() < 2 then return 10 end
	end
	if card:isKindOf("Slash") and (self:getCardsNum("Slash") > 0) then return 4 end
	if card:isKindOf("Crossbow") and self.player:hasSkills("luoshen|yongsi|noskurou|keji|wusheng|wushen") then return 20 end
	if card:isKindOf("Axe") and self.player:hasSkills("luoyi|nosluoyi|jiushi|jiuchi|pojun") then return 15 end
	if card:isKindOf("Weapon") and (not self.player:getWeapon()) and (self:getCardsNum("Slash") > 1) then return 6 end
	if card:isKindOf("Nullification") and self:getCardsNum("Nullification") == 0 then
		if self:willSkipPlayPhase() or self:willSkipDrawPhase() then return 10 end
		for _, friend in ipairs(self.friends) do
			if self:willSkipPlayPhase(friend) or self:willSkipDrawPhase(friend) then return 9 end
		end
		return 6
	end
	return self:getUseValue(card)
end

-- compare functions
sgs.ai_compare_funcs = {
	hp = function(a, b)
		local c1 = a:getHp()
		local c2 = b:getHp()
		if c1 == c2 then
			return sgs.ai_compare_funcs.defense(a, b)
		else
			return c1 < c2
		end
	end,

	value = function(a, b)
		return sgs.getValue(a) < sgs.getValue(b)
	end,

	handcard = function(a, b)
		local c1 = a:getHandcardNum()
		local c2 = b:getHandcardNum()
		if c1 == c2 then
			return sgs.ai_compare_funcs.defense(a, b)
		else
			return c1 < c2
		end
	end,

	defense = function(a, b)
		return sgs.getDefense(a) < sgs.getDefense(b)
	end,

	threat = function(a, b)
		local players = sgs.QList2Table(a:getRoom():getOtherPlayers(a))
		local d1 = a:getHandcardNum()
		for _, player in ipairs(players) do
			if a:canSlash(player) then
				d1 = d1 + 10 / (sgs.getDefense(player))
			end
		end
		players = sgs.QList2Table(b:getRoom():getOtherPlayers(b))
		local d2 = b:getHandcardNum()
		for _, player in ipairs(players) do
			if b:canSlash(player) then
				d2 = d2 + 10 / (sgs.getDefense(player))
			end
		end

		return d1 > d2
	end,
}

function SmartAI:sort(players, key)
	if not players then self.room:writeToConsole(debug.traceback()) end
	if #players == 0 then return end
	function _sort(players, key)
		local func = sgs.ai_compare_funcs[key or "defense"]
		table.sort(players, func)
	end
	if not pcall(_sort, players, key) then self.room:writeToConsole(debug.traceback()) end
end

function SmartAI:sortByKeepValue(cards, inverse, kept, wrt)
	local compare_func = function(a,b)
		local value1 = self:getKeepValue(a, kept, wrt)
		local value2 = self:getKeepValue(b, kept, wrt)

		local v1, v2 = value1, value2
		if wrt then
			self.keepValue[a:getId()] = v1
			self.keepValue[b:getId()] = v2
		end
		
		if v1 ~= v2 then
			if inverse then return v1 > v2 end
			return v1 < v2
		else
			if not inverse then return a:getNumber() > b:getNumber() end
			return a:getNumber() < b:getNumber()
		end
	end

	table.sort(cards, compare_func)
end

function SmartAI:sortByUseValue(cards, inverse)
	local compare_func = function(a, b)
		local value1 = self:getUseValue(a)
		local value2 = self:getUseValue(b)

		if value1 ~= value2 then
			if not inverse then return value1 > value2 end
			return value1 < value2
		else
			if not inverse then return a:getNumber() > b:getNumber() end
			return a:getNumber() < b:getNumber()
		end
	end

	table.sort(cards, compare_func)
end

function SmartAI:sortByUsePriority(cards, player)
	local compare_func = function(a, b)
		local value1 = self:getUsePriority(a)
		local value2 = self:getUsePriority(b)

		if value1 ~= value2 then
			return value1 > value2
		else
			return a:getNumber() > b:getNumber()
		end
	end

	table.sort(cards, compare_func)
end

function SmartAI:sortByDynamicUsePriority(cards)
	local compare_func = function(a, b)
		local value1 = self:getDynamicUsePriority(a)
		local value2 = self:getDynamicUsePriority(b)

		if value1 ~= value2 then
			return value1 > value2
		else
			return a and a:getTypeId() ~= sgs.Card_TypeSkill and not (b and b:getTypeId() ~= sgs.Card_TypeSkill)
		end
	end

	table.sort(cards, compare_func)
end

function SmartAI:sortByCardNeed(cards, inverse)
	local compare_func = function(a, b)
		local value1 = self:cardNeed(a)
		local value2 = self:cardNeed(b)

		if value1 ~= value2 then
			if inverse then return value1 > value2 end
			return value1 < value2
		else
			if not inverse then return a:getNumber() > b:getNumber() end
			return a:getNumber() < b:getNumber()
		end
	end

	table.sort(cards, compare_func)
end

function SmartAI:getPriorTarget()
	if #self.enemies == 0 then return end
	self:sort(self.enemies, "defenseSlash")
	return self.enemies[1]
end

function sgs.evaluatePlayerRole(player)
	if not player then global_room:writeToConsole("Player is empty in role's evaluation!") return end
	if player:isLord() then return "loyalist" end
	if sgs.isRolePredictable() then return player:getRole() end
	return sgs.ai_role[player:objectName()]
end

function sgs.compareRoleEvaluation(player, first, second)
	if player:isLord() then return "loyalist" end
	if sgs.isRolePredictable() then return player:getRole() end
	if (first == "renegade" or second == "renegade") and sgs.ai_role[player:objectName()] == "renegade" then return "renegade" end
	if sgs.ai_role[player:objectName()] == first then return first end
	if sgs.ai_role[player:objectName()] == second then return second end
	return "neutral"
end

function sgs.isRolePredictable(classical)
	if not classical and sgs.GetConfig("RolePredictable", false) then return true end
	local mode = string.lower(global_room:getMode())
	local isMini = (mode:find("mini") or mode:find("custom_scenario"))
	if (not mode:find("0") and not isMini) or mode:find("02p") or mode:find("02_1v1") or mode:find("04_1v3") or mode:find("04_boss")
		or mode == "06_3v3" or mode == "06_xmode" or mode == "08_defense" or (not classical and isMini) then return true end
	return false
end

function sgs.findIntersectionSkills(first, second)
	if type(first) == "string" then first = first:split("|") end
	if type(second) == "string" then second = second:split("|") end

	local findings = {}
	for _, skill in ipairs(first) do
		for _, compare_skill in ipairs(second) do
			if skill == compare_skill and not table.contains(findings, skill) then table.insert(findings, skill) end
		end
	end
	return findings
end

function sgs.findUnionSkills(first, second)
	if type(first) == "string" then first = first:split("|") end
	if type(second) == "string" then second = second:split("|") end

	local findings = table.copyFrom(first)
	for _, skill in ipairs(second) do
		if not table.contains(findings, skill) then table.insert(findings, skill) end
	end

	return findings
end

sgs.ai_card_intention.general = function(from, to, level)
	if sgs.isRolePredictable() then return end
	if not to then global_room:writeToConsole(debug.traceback()) return end
	if from:isLord() then return end
	sgs.outputRoleValues(from, level)

	if sgs.evaluatePlayerRole(to) == "loyalist" then
		if ((sgs.role_evaluation[from:objectName()]["loyalist"] > 50 and level > 0 and sgs.current_mode_players["rebel"] > 0)
			or (sgs.role_evaluation[from:objectName()]["loyalist"] < -50 and level < 0)) and sgs.current_mode_players["renegade"] > 0 then
			sgs.role_evaluation[from:objectName()]["renegade"] = sgs.role_evaluation[from:objectName()]["renegade"] + math.abs(level)
		elseif sgs.ai_role[from:objectName()] ~= "rebel" and sgs.ai_role[from:objectName()] ~= "neutral"
				and level > 0 and to:isLord() and sgs.current_mode_players["renegade"] > 0 then
			sgs.role_evaluation[from:objectName()]["renegade"] = sgs.role_evaluation[from:objectName()]["renegade"] + math.abs(level)
		end
		sgs.role_evaluation[from:objectName()]["loyalist"] = sgs.role_evaluation[from:objectName()]["loyalist"] - level
	end
	if sgs.evaluatePlayerRole(to) == "rebel" then
		if ((sgs.role_evaluation[from:objectName()]["loyalist"] < -50 and level > 0) or (sgs.role_evaluation[from:objectName()]["loyalist"] > 0 and level < 0))
			and sgs.current_mode_players["renegade"] > 0 then
			sgs.role_evaluation[from:objectName()]["renegade"] = sgs.role_evaluation[from:objectName()]["renegade"] + math.abs(level)
		end
		sgs.role_evaluation[from:objectName()]["loyalist"] = sgs.role_evaluation[from:objectName()]["loyalist"] + level
	end

	for _, p in sgs.qlist(global_room:getAllPlayers()) do
		sgs.ais[p:objectName()]:updatePlayers(true, p:isLord())
	end
	sgs.outputRoleValues(from, level)
end

function sgs.outputRoleValues(player, level)
	global_room:writeToConsole(player:getGeneralName() .. " " .. level .. " " .. sgs.evaluatePlayerRole(player)
								.. " L " .. math.ceil(sgs.role_evaluation[player:objectName()]["loyalist"])
								.. " R " .. math.ceil(sgs.role_evaluation[player:objectName()]["renegade"])
								.. " " .. sgs.gameProcess(player:getRoom()) .. ":" .. sgs.gameProcess(player:getRoom(), 1)
								.. " " .. sgs.current_mode_players["loyalist"] .. sgs.current_mode_players["rebel"] .. sgs.current_mode_players["renegade"])
end

function sgs.updateIntention(from, to, intention, card)
	if not to then global_room:writeToConsole(debug.traceback()) return end
	if from:objectName() == to:objectName() then return end

	sgs.ai_card_intention.general(from, to, intention)
end

function sgs.updateIntentions(from, tos, intention, card)
	for _, to in ipairs(tos) do
		sgs.updateIntention(from, to, intention, card)
	end
end

function sgs.isLordHealthy()
	local lord = global_room:getLord()
	if not lord then return true end
	local lord_hp
	if lord:hasSkill("benghuai") and lord:getHp() > 4 then lord_hp = 4
	else lord_hp = lord:getHp() end
	return lord_hp > 3 or (lord_hp > 2 and sgs.getDefense(lord) > 3)
end

function sgs.isLordInDanger()
	local lord = global_room:getLord()
	if not lord then return false end
	local lord_hp
	if lord:hasSkill("benghuai") and lord:getHp() > 4 then lord_hp = 4
	else lord_hp = lord:getHp() end
	return lord_hp < 3
end

function sgs.gameProcess(room, arg, update)
	if not update and sgs.ai_gameProcess and sgs.ai_gameProcess_arg then
		if arg and arg == 1 then
			return sgs.ai_gameProcess_arg
		else
			return sgs.ai_gameProcess
		end
	end

	local rebel_num = sgs.current_mode_players["rebel"]
	local loyal_num = sgs.current_mode_players["loyalist"]
	if rebel_num == 0 and loyal_num > 0 then return "loyalist"
	elseif loyal_num == 0 and rebel_num > 1 then return "rebel" end
	local loyal_value, rebel_value = 0, 0
	local health = sgs.isLordHealthy()
	local danger = sgs.isLordInDanger()
	local currentplayer = room:getCurrent()
	local lord = room:getLord()
	for _, aplayer in sgs.qlist(room:getAlivePlayers()) do
		local role = aplayer:getRole()
		local hp = aplayer:getHp()
		if aplayer:hasSkill("benghuai") and aplayer:getHp() > 4 then hp = 4 end
		if role == "rebel" then
			rebel_value = rebel_value + hp + math.max(sgs.getDefense(aplayer) - hp * 2, 0) * 0.5
			if lord and aplayer:inMyAttackRange(lord) then rebel_value = rebel_value + 0.4 end
		elseif role == "loyalist" or role == "lord" then
			loyal_value = loyal_value + hp + math.max(sgs.getDefense(aplayer) - hp * 2, 0) * 0.5
		end
	end
	local diff = loyal_value - rebel_value + (loyal_num + 0.75 - rebel_num) * 2
	sgs.ai_gameProcess_arg = diff

	local process = "neutral"
	if diff >= 2 then
		if health then process = "loyalist"
		else process = "dilemma" end
	elseif diff >= 1 then
		if health then process = "loyalish"
		elseif danger then process = "dilemma"
		else process = "rebelish" end
	elseif diff <= -2 then process = "rebel"
	elseif diff <= -1 then
		if health then process = "rebelish"
		else process = "rebel" end
	elseif not health then process = "rebelish"
	end
	sgs.ai_gameProcess = process
	if arg and arg == 1 then return diff end
	return process
end

function SmartAI:objectiveLevel(player)
	if player:objectName() == self.player:objectName() then return -2 end

	local players = self.room:getOtherPlayers(self.player)
	players = sgs.QList2Table(players)

	if #players == 1 then return 5 end

	if sgs.isRolePredictable(true) then
		if self.lua_ai:isFriend(player) then return -2
		elseif self.lua_ai:isEnemy(player) then return 5
		elseif self.lua_ai:relationTo(player) == sgs.AI_Neutrality then
			if self.lua_ai:getEnemies():isEmpty() then return 4 else return 0 end
		else return 0 end
	end

	local rebel_num = sgs.current_mode_players["rebel"]
	local loyal_num = sgs.current_mode_players["loyalist"]
	local renegade_num = sgs.current_mode_players["renegade"]
	local target_role = sgs.evaluatePlayerRole(player)

	if self.role == "renegade" then
		if player:isLord() and not sgs.GetConfig("EnableHegemony", false) and self.room:getMode() ~= "couple"
			and player:getHp() <= 0 and player:hasFlag("Global_Dying") then return -2 end
		if target_role == "rebel" and player:getHp() <= 1 and not hasBuquEffect(player) and not player:hasSkill("kongcheng")
			and (player:isKongcheng() or sgs.card_lack[player:objectName()]["Jink"] == 1 and player:getHandcardNum() <= 1)
			and getCardsNum("Peach", player, self.player) < 1 and getCardsNum("Analeptic", player, self.player) < 1 then return 5 end

		if rebel_num == 0 or loyal_num == 0 then
			if rebel_num > 0 then
				if rebel_num > 1 then
					if player:isLord() then
						return -2
					elseif target_role == "rebel" then
						return 5
					else
						return 0
					end
				elseif renegade_num > 1 then
					if player:isLord() then
						return 0
					elseif target_role == "renegade" then
						return 3
					else
						return 5
					end
				else
					local process = sgs.gameProcess(self.room)
					if process == "loyalist" then
						if player:isLord() then
							if not sgs.isLordHealthy() then return -1
							else return 1 end
						elseif target_role == "rebel" then
							return 0
						else
							return 5
						end
					elseif process:match("rebel") then
						if target_role == "rebel" then
							if process == "rebel" then return 5 else return 3 end
						else return -1 end
					else
						if player:isLord() then
							return 0
						else
							return 5
						end
					end
				end
			elseif loyal_num > 0 then
				if player:isLord() then
					if not sgs.isLordHealthy() then return 0
					else return 1 end
				elseif target_role == "renegade" and renegade_num > 1 then
					return 3
				else
					return 5
				end
			else
				if player:isLord() then
					if sgs.isLordInDanger then return 0
					elseif not sgs.isLordHealthy() then return 3
					else return 5 end
				elseif sgs.isLordHealthy() then return 3
				else return 5
				end
			end
		else
			local process = sgs.gameProcess(self.room)
			if process == "neutral" or (sgs.turncount <= 1 and sgs.isLordHealthy()) then
				if sgs.turncount <= 1 and sgs.isLordHealthy() then
					if renegade_num > 1 or self:getOverflow() <= -1 then return 0 end
					local rebelish = (sgs.current_mode_players["loyalist"] + 1 < sgs.current_mode_players["rebel"])
					if player:isLord() then return rebelish and -1 or 0 end
					if target_role == "loyalist" then return rebelish and -0.5 or 3.5
					elseif target_role == "rebel" then return rebelish and 3.5 or 0
					else return 0
					end
				end
				if player:isLord() then return -1 end
				local renegade_attack_skill = string.format("buqu|nosbuqu|%s|%s|%s|%s", sgs.priority_skill, sgs.save_skill, sgs.recover_skill, sgs.drawpeach_skill)
				for i = 1, #players, 1 do
					if not players[i]:isLord() and players[i]:hasSkills(renegade_attack_skill) then return 5 end
				end
				return self:getOverflow() > 0 and 3 or 0
			elseif process:match("rebel") then
				return target_role == "rebel" and 5 or (target_role == "neutral" and 0 or -1)
			elseif process:match("dilemma") then
				if target_role == "rebel" then return 5
				elseif target_role == "loyalist" or target_role == "renegade" then return 0
				elseif player:isLord() then return -2
				else return 5 end
			elseif process == "loyalish" then
				if player:isLord() or target_role == "renegade" then return 0 end
				local rebelish = (sgs.current_mode_players["loyalist"] + 1 < sgs.current_mode_players["rebel"])
				if target_role == "loyalist" then return rebelish and 0 or 3.5
				elseif target_role == "rebel" then return rebelish and 3.5 or 0
				else return 0
				end
			else
				if player:isLord() or target_role == "renegade" then return 0 end
				return target_role == "rebel" and -2 or 5
			end
		end
	end

	if self.player:isLord() or self.role == "loyalist" then
		if player:isLord() then return -2 end
		if self.role == "loyalist" and loyal_num == 1 and renegade_num == 0 then return 5 end
		if sgs.gameProcess(self.room):match("rebel") and rebel_num > 1 and target_role == "renegade" then return -1 end
		if target_role == "neutral" then
			if rebel_num > 0 then
				local current_friend_num, current_enemy_num, current_renegade_num = 0, 0, 0
				local mode = self.room:getMode()
				local consider_renegade = (mode == "05p") or (mode == "07p") or (mode == "09p")
				local rebelish = sgs.gameProcess(self.room):match("rebel")
				for _, aplayer in sgs.qlist(self.room:getAlivePlayers()) do
					if sgs.ai_role[aplayer:objectName()] == "loyalist" or aplayer:objectName() == self.player:objectName() then
						current_friend_num = current_friend_num + 1
					elseif sgs.ai_role[aplayer:objectName()] == "renegade" then
						current_renegade_num = current_renegade_num + 1
					elseif sgs.ai_role[aplayer:objectName()] == "rebel" then
						current_enemy_num = current_enemy_num + 1
					end
				end
				if current_friend_num + ((consider_renegade or rebelish) and current_renegade_num or 0) >= loyal_num + ((rebelish or consider_renegade) and renegade_num or 0) + 1 then
					return self:getOverflow() > -1 and 5 or 3
				elseif current_enemy_num + (consider_renegade and current_renegade_num or rebelish and 0 or current_renegade_num)
						>= rebel_num + (consider_renegade and renegade_num or (rebelish and 0 or renegade_num)) then
					return -1
				elseif self:getOverflow() > -1 and (current_friend_num + ((consider_renegade or rebelish) and current_renegade_num or 0) + 1
						== loyal_num + ((rebelish or consider_renegade) and renegade_num or 0) + 1) and current_enemy_num <= 1 and current_enemy_num / rebel_num < 0.35 then
					return 1
				end
			else
				local explicit_renegade = 0
				for _, aplayer in sgs.qlist(self.room:getOtherPlayers(player)) do
					if sgs.ai_role[aplayer:objectName()] == "renegade" then
						explicit_renegade = explicit_renegade + 1
						break
					end
				end
				if explicit_renegade == renegade_num then return -1 end
			end
		end

		if rebel_num == 0 then
			if #players == 2 and self.role == "loyalist" then return 5 end

			local has_renegade = false
			for _, p in sgs.qlist(self.room:getOtherPlayers(self.player)) do
				if sgs.evaluatePlayerRole(p) == "renegade" then
					has_renegade = true
					break
				end
			end
			if self.room:getLord() and (has_renegade or self.room:getLord():hasSkill("benghuai")) then
				if self.player:isLord() then
					if sgs.ai_role[player:objectName()] == "loyalist" then return -2
					else
						return player:getHp() > 1 and 4 or 0
					end
				else
					if self.role == "loyalist" and sgs.ai_role[self.player:objectName()] == "renegade" then
						if #players == 2 then return 5 end
						local renegade_player = {}
						for _, p in ipairs(players) do
							if sgs.role_evaluation[p:objectName()]["renegade"] > 0 then
								table.insert(renegade_player, p:objectName())
							end
						end
						if #renegade_player > 0 then return table.contains(renegade_player, player:objectName()) and 5 or -2
						else return 4 end
					end
					return sgs.ai_role[player:objectName()] == "loyalist" and -2 or 4
				end
			end

			self:sort(players, "hp")
			local maxhp = players[#players]:isLord() and players[#players - 1]:getHp() or players[#players]:getHp()
			if maxhp > 2 then return player:getHp() == maxhp and 5 or 0 end
			if maxhp == 2 then return self.player:isLord() and 0 or (player:getHp() == maxhp and 5 or 1) end
			return self.player:isLord() and 0 or 5
		end
		if loyal_num == 0 then
			if rebel_num > 2 then
				if target_role == "renegade" then return -1 end
			elseif rebel_num > 1 then
				if target_role == "renegade" then return 0 end
			elseif target_role == "renegade" then return sgs.isLordInDanger() and -1 or 4 end
		end
		if renegade_num == 0 then
			if target_role ~= "loyalist" then return 5 end
		end

		if loyal_num + 1 > rebel_num and renegade_num > 0 and target_role == "renegade" then
			local process = sgs.gameProcess(self.room)
			if process == "loyalist" or process == "loyalish" then return 5 end
		end

		if sgs.gameProcess(self.room) == "rebel" and rebel_num > loyal_num and target_role == "renegade" then return -2 end
		if target_role == "rebel" then return 5
		elseif target_role == "loyalist" then return -2
		else return 0 end
	elseif self.role == "rebel" then
		if loyal_num == 0 and renegade_num == 0 then return player:isLord() and 5 or -2 end
		if target_role == "neutral" then
			local current_friend_num, current_enemy_num, current_renegade_num = 0, 0, 0
			for _, aplayer in sgs.qlist(self.room:getAlivePlayers()) do
				if sgs.ai_role[aplayer:objectName()] == "rebel" or aplayer:objectName() == self.player:objectName() then
					current_friend_num = current_friend_num + 1
				elseif sgs.ai_role[aplayer:objectName()] == "renegade" then current_renegade_num = current_renegade_num + 1
				elseif sgs.ai_role[aplayer:objectName()] == "loyalist" then current_enemy_num = current_enemy_num + 1 end
			end
			local loyalish = sgs.gameProcess(self.room):match("loyal")
			local mode = self.room:getMode()
			local consider_renegade = (mode == "05p") or (mode == "07p") or (mode == "09p")
			if current_friend_num + ((consider_renegade or loyalish) and current_renegade_num or 0) >= rebel_num + ((consider_renegade or loyalish) and renegade_num or 0) then
				return self:getOverflow() > -1 and 5 or 3
			elseif current_enemy_num + (consider_renegade and current_renegade_num or loyalish and 0 or current_renegade_num)
					>= loyal_num + (consider_renegade and renegade_num or (loyalish and 0 or renegade_num)) + 1 then
				return -1
			elseif loyal_num + renegade_num > 0 and self:getOverflow() > -1 and (current_friend_num + ((consider_renegade or loyalish) and current_renegade_num or 0) + 1
					== rebel_num + ((consider_renegade or loyalish) and renegade_num or 0)) and current_enemy_num <= 1 and current_enemy_num / (loyal_num + renegade_num) < 0.35 then
				return 1
			else
				return 0
			end
		end

		if rebel_num > loyal_num + renegade_num + 1 and target_role == "renegade" then
			local process = sgs.gameProcess(self.room)
			if process == "rebel" or process == "rebelish" then return 5 end
		end

		if sgs.gameProcess(self.room) == "loyalist" and renegade_num > 0 and target_role == "renegade" then return -2 end
		if player:isLord() then return 5
		elseif target_role == "loyalist" then return 5
		elseif target_role == "rebel" then return -2
		else return 0 end
	end
end

function SmartAI:isFriend(other, another)
	if not other then self.room:writeToConsole(debug.traceback()) return end
	if another then
		local of, af = self:isFriend(other), self:isFriend(another)
		return of ~= nil and af ~= nil and of == af
	end
	if sgs.isRolePredictable(true) and self.lua_ai:relationTo(other) ~= sgs.AI_Neutrality then return self.lua_ai:isFriend(other) end
	if self.player:objectName() == other:objectName() then return true end
	local obj_level = self:objectiveLevel(other)
	if obj_level < 0 then return true
	elseif obj_level == 0 then return nil end
	return false
end

function SmartAI:isEnemy(other, another)
	if not other then self.room:writeToConsole(debug.traceback()) return end
	if another then
		local of, af = self:isFriend(other), self:isFriend(another)
		return of ~= nil and af ~= nil and of ~= af
	end
	if sgs.isRolePredictable(true) and self.lua_ai:relationTo(other) ~= sgs.AI_Neutrality then return self.lua_ai:isEnemy(other) end
	if self.player:objectName() == other:objectName() then return false end
	local obj_level = self:objectiveLevel(other)
	if obj_level > 0 then return true
	elseif obj_level == 0 then return nil end
	return false
end

function SmartAI:getFriendsNoself(player)
	player = player or self.player
	local friends_noself = {}
	for _, p in sgs.qlist(self.room:getAlivePlayers()) do
		if self:isFriend(p, player) and p:objectName() ~= player:objectName() then table.insert(friends_noself, p) end
	end
	return friends_noself
end

function SmartAI:getFriends(player)
	player = player or self.player
	local friends = {}
	for _, p in sgs.qlist(self.room:getAlivePlayers()) do
		if self:isFriend(p, player) then table.insert(friends, p) end
	end
	return friends
end

function SmartAI:getEnemies(player)
	local enemies = {}
	for _, p in sgs.qlist(self.room:getAlivePlayers()) do
		if self:isEnemy(p, player) then table.insert(enemies, p) end
	end
	return enemies
end

function SmartAI:sortEnemies(players)
	local comp_func = function(a, b)
		local alevel = self:objectiveLevel(a)
		local blevel = self:objectiveLevel(b)

		if alevel ~= blevel then return alevel > blevel end
		return sgs.getDefenseSlash(a, self) < sgs.getDefenseSlash(b, self)
	end
	table.sort(players, comp_func)
end

function SmartAI:updateAlivePlayerRoles()
	for _, arole in ipairs({ "lord", "loyalist", "rebel", "renegade" }) do
		sgs.current_mode_players[arole] = 0
	end
	for _, aplayer in sgs.qlist(self.room:getOtherPlayers(self.room:getLord())) do
		sgs.current_mode_players[aplayer:getRole()] = sgs.current_mode_players[aplayer:getRole()] + 1
	end
end

function SmartAI:updatePlayers(clear_flags)
	if clear_flags ~= false then clear_flags = true end
	if self.role ~= self.player:getRole() then self.role = self.player:getRole() end
	if clear_flags then
		for _, aflag in ipairs(sgs.ai_global_flags) do
			sgs[aflag] = nil
		end
	end

	if sgs.isRolePredictable(true) then
		self.friends = {}
		self.friends_noself = {}
		local friends = sgs.QList2Table(self.lua_ai:getFriends())
		for i = 1, #friends, 1 do
			if friends[i]:isAlive() and friends[i]:objectName() ~= self.player:objectName() then
				table.insert(self.friends, friends[i])
				table.insert(self.friends_noself, friends[i])
			end
		end
		table.insert(self.friends, self.player)

		local enemies = sgs.QList2Table(self.lua_ai:getEnemies())
		for i = 1, #enemies, 1 do
			if enemies[i]:isDead() or enemies[i]:objectName() == self.player:objectName() then table.remove(enemies, i) end
		end
		self.enemies = enemies

		self.retain = 2
		self.harsh_retain = false
		if #self.enemies == 0 then
			local neutrality = {}
			for _, aplayer in sgs.qlist(self.room:getOtherPlayers(self.player)) do
				if self.lua_ai:relationTo(aplayer) == sgs.AI_Neutrality and not aplayer:isDead() then table.insert(neutrality, aplayer) end
			end
			local function compare_func(a, b)
				return self:objectiveLevel(a) > self:objectiveLevel(b)
			end
			table.sort(neutrality, compare_func)
			table.insert(self.enemies, neutrality[1])
		end
		return
	end

	self:updateAlivePlayerRoles()
	sgs.evaluateAlivePlayersRole()

	self.enemies = {}
	self.friends = {}
	self.friends_noself = {}

	self.retain = 2
	self.harsh_retain = true

	for _, player in sgs.qlist(self.room:getOtherPlayers(self.player)) do
		local level = self:objectiveLevel(player)
		if level < 0 then
			table.insert(self.friends_noself, player)
			table.insert(self.friends, player)
		elseif level > 0 then
			table.insert(self.enemies, player)
		end
	end
	table.insert(self.friends, self.player)

	self:updateAlivePlayerRoles()
	sgs.gameProcess(self.room, 1, true)
end

function sgs.evaluateAlivePlayersRole()
	local players = sgs.QList2Table(global_room:getAlivePlayers())
	local cmp = function(a, b)
		local ar_value, br_value = sgs.role_evaluation[a:objectName()]["renegade"], sgs.role_evaluation[b:objectName()]["renegade"]
		local al_value, bl_value = sgs.role_evaluation[a:objectName()]["loyalist"], sgs.role_evaluation[b:objectName()]["loyalist"]
		return (ar_value > br_value) or (ar_value == br_value and al_value > bl_value)
	end
	table.sort(players, cmp)

	local loyal_num = sgs.current_mode_players["loyalist"]
	local rebel_num = sgs.current_mode_players["rebel"]
	local renegade_num = sgs.current_mode_players["renegade"]
	for i = 1, #players, 1 do
		local p = players[i]
		if not p:isLord() then
			local renegade_val = sgs.current_mode_players["rebel"] == 0 and (sgs.current_mode_players["loyalist"] == 0 and -1000 or 80) or 150
			if renegade_num > 0 and sgs.role_evaluation[p:objectName()]["renegade"] >= renegade_val then
				sgs.ai_role[p:objectName()] = "renegade"
				renegade_num = renegade_num - 1
			else
				if (sgs.role_evaluation[p:objectName()]["loyalist"] > 0 and loyal_num > 0) or p:isLord() then
					sgs.ai_role[p:objectName()] = "loyalist"
				elseif sgs.role_evaluation[p:objectName()]["loyalist"] < 0 and rebel_num > 0 then
					sgs.ai_role[p:objectName()] = "rebel"
				else
					if sgs.role_evaluation[p:objectName()]["loyalist"] > 80 then
						-- renegade or rebel for loyal_num must be 0 here (otherwise we get the first 'if')
						if renegade_num > 0 then
							sgs.ai_role[p:objectName()] = "renegade"
							renegade_num = renegade_num - 1
						elseif rebel_num > 0 then -- despite that the loyal value is larger than 80, there are no loyalists or even renegades actually
							sgs.ai_role[p:objectName()] = "rebel"
						end
					elseif sgs.role_evaluation[p:objectName()]["loyalist"] < -80 then
						-- renegade or loyalist
						if renegade_num > 0 then
							sgs.ai_role[p:objectName()] = "renegade"
							renegade_num = renegade_num - 1
						elseif loyal_num > 0 then -- the same as the above
							sgs.ai_role[p:objectName()] = "loyalist"
						end
					else
						sgs.ai_role[p:objectName()] = "neutral"
					end
				end
			end
		end
	end
end

function findPlayerByObjectName(room, name, include_death, except)
	if not room then return end
	local players = nil
	if include_death then
		players = room:getPlayers()
	else
		players = room:getAllPlayers()
	end
	if except then
		players:removeOne(except)
	end
	for _,p in sgs.qlist(players) do
		if p:objectName() == name then
			return p
		end
	end
end

function getTrickIntention(trick_class, target)
	local intention = sgs.ai_card_intention[trick_class]
	if type(intention) == "number" then
		return intention
	elseif type(intention == "function") then
		if trick_class == "IronChain" then
			if target and target:isChained() then return -60 else return 60 end
		elseif trick_class == "Drowning" then
			if target and target:getArmor() and target:hasSkills("yizhong|bazhen|bossmanjia") then return 0 else return 60 end
		end
	end
	if trick_class == "Collateral" then return 0 end
	if sgs.dynamic_value.damage_card[trick_class] then
		return 70
	end
	if sgs.dynamic_value.benefit[trick_class] then
		return -40
	end
	if target then
		if trick_class == "Snatch" or trick_class == "Dismantlement" then
			local judgelist = target:getCards("j")
			if not judgelist or judgelist:isEmpty() then
				if not target:hasArmorEffect("silver_lion") or not target:isWounded() then
					return 80
				end
			end
		end
	end
	return 0
end

sgs.ai_choicemade_filter.Nullification.general = function(self, player, promptlist)
	local trick_class = promptlist[2]
	local target_objectName = promptlist[3]
	if trick_class == "Nullification" then
		if not sgs.nullification_source or not sgs.nullification_intention or type(sgs.nullification_intention) ~= "number" then
			self.room:writeToConsole(debug.traceback())
			return
		end
		sgs.nullification_level = sgs.nullification_level + 1
		if sgs.nullification_level % 2 == 0 then
			sgs.updateIntention(player, sgs.nullification_source, sgs.nullification_intention)
		elseif sgs.nullification_level % 2 == 1 then
			sgs.updateIntention(player, sgs.nullification_source, -sgs.nullification_intention)
		end
	else
		sgs.nullification_source = findPlayerByObjectName(global_room, target_objectName)
		sgs.nullification_level = 1
		sgs.nullification_intention = getTrickIntention(trick_class, sgs.nullification_source)
		if player:objectName() ~= target_objectName then
			sgs.updateIntention(player, sgs.nullification_source, -sgs.nullification_intention)
		end
	end
end

sgs.ai_choicemade_filter.playerChosen.general = function(self, from, promptlist)
	if from:objectName() == promptlist[3] then return end
	local reason = string.gsub(promptlist[2], "%-", "_")
	local to = findPlayerByObjectName(self.room, promptlist[3])
	local callback = sgs.ai_playerchosen_intention[reason]
	if callback then
		if type(callback) == "number" then
			sgs.updateIntention(from, to, sgs.ai_playerchosen_intention[reason])
		elseif type(callback) == "function" then
			callback(self, from, to)
		end
	end
end

sgs.ai_choicemade_filter.viewCards.general = function(self, from, promptlist)
	local to = findPlayerByObjectName(self.room, promptlist[#promptlist])
	if to and not to:isKongcheng() then
		local flag = string.format("%s_%s_%s", "visible", from:objectName(), to:objectName())
		for _, card in sgs.qlist(to:getHandcards()) do
			if not card:hasFlag("visible") then card:setFlags(flag) end
		end
	end
end

function SmartAI:filterEvent(triggerEvent, player, data)
	if not sgs.recorder then
		sgs.recorder = self
	end

	local file = io.open("lua/ai/AIDebug.Readme")
	if file then
		file:close()
		sgs.debugmode = true
	else
		sgs.debugmode = false
	end
	if player:objectName() == self.player:objectName() then
		if sgs.debugmode and sgs.ai_debug_func[triggerEvent] and type(sgs.ai_debug_func[triggerEvent]) == "function" then
			sgs.ai_debug_func[triggerEvent](self, player, data)
		end
		if type(sgs.ai_event_callback[event]) == "table" then
			for _, callback in pairs(sgs.ai_event_callback[event]) do
				if type(callback) == "function" then callback(self, player, data) end
			end
		end
	end

	if triggerEvent == sgs.ChoiceMade and (self == sgs.recorder or self.player:objectName() == sgs.recorder.player:objectName()) then
		local carduse = data:toCardUse()
		if carduse and carduse.card ~= nil then
			for _, aflag in ipairs(sgs.ai_global_flags) do
				sgs[aflag] = nil
			end
			for _, callback in ipairs(sgs.ai_choicemade_filter.cardUsed) do
				if type(callback) == "function" then
					callback(self, player, carduse)
				end
			end
		elseif data:toString() then
			promptlist = data:toString():split(":")
			local callbacktable = sgs.ai_choicemade_filter[promptlist[1]]
			if callbacktable and type(callbacktable) == "table" then
				local index = (promptlist[1] == "cardResponded") and 3 or 2
				local callback = callbacktable[promptlist[index]] or callbacktable.general
				if type(callback) == "function" then
					callback(self, player, promptlist)
				end
			end
			if data:toString() == "skillInvoke:fenxin:yes" then
				for _, aplayer in sgs.qlist(self.room:getAllPlayers()) do
					if aplayer:hasFlag("FenxinTarget") then
						local temp_table = sgs.role_evaluation[player:objectName()]
						sgs.role_evaluation[player:objectName()] = sgs.role_evaluation[aplayer:objectName()]
						sgs.role_evaluation[aplayer:objectName()] = temp_table
						self:updatePlayers()
						break
					end
				end
			end
		end
	elseif event == sgs.CardUsed or event == sgs.GameStart or event == sgs.EventPhaseStart then
		self:updatePlayers(true)
	elseif event == sgs.BuryVictim or event == sgs.HpChanged or event == sgs.MaxHpChanged then
		self:updatePlayers(false)
	end

	if triggerEvent == sgs.BuryVictim then
		if self == sgs.recorder then self:updateAlivePlayerRoles() end
	end

	if triggerEvent == sgs.AskForPeaches then
		if self.player:objectName() == player:objectName() then
			local dying = data:toDying()
			if self:isFriend(dying.who) and dying.who:getHp() < 1 then
				sgs.card_lack[player:objectName()]["Peach"] = 1
			end
		end
	end

	if self.player:objectName() == player:objectName() and triggerEvent == sgs.CardsMoveOneTime then
		local move = data:toMoveOneTime()
		if move.to and move.to:objectName() == player:objectName() and move.to_place == sgs.Player_PlaceHand and player:getHandcardNum() >= 1 then
			self:assignKeep(true)
		end
	end

	if self ~= sgs.recorder then return end

	if triggerEvent == sgs.CardEffected then
		local struct = data:toCardEffect()
		local card = struct.card
		local from = struct.from
		local to = struct.to
		if card and card:isKindOf("AOE") and to and (to:hasFlag("AIGlobal_LordInDangerSA") or to:hasFlag("AIGlobal_LordInDangerAA")) then
			to:setFlags("-AIGlobal_LordInDangerAA")
			to:setFlags("-AIGlobal_LordInDangerSA")
		end
	elseif triggerEvent == sgs.PreDamageDone then
		local damage = data:toDamage()
		local lord = self.room:getLord()
		if lord and damage.trigger_chain and lord:isChained() and self:damageIsEffective(lord, damage.nature, from) then
			if lord:hasArmorEffect("vine") and damage.nature == sgs.DamageStruct_Fire and lord:getHp() <= damage.damage + 1 then
				sgs.lordNeedPeach = damage.damage + 2 - lord:getHp()
			elseif lord:getHp() <= damage.damage then
				sgs.lordNeedPeach = damage.damage + 1 - lord:getHp()
			end
		else
			sgs.lordNeedPeach = nil
		end
	elseif triggerEvent == sgs.Damaged then
		local damage = data:toDamage()
		local card = damage.card
		local from = damage.from
		local to = damage.to
		local source = self.room:getCurrent()

		if not damage.card then
			local intention
			if sgs.ai_quhu_effect then
				sgs.ai_quhu_effect = false
				local xunyu = self.room:findPlayerBySkillName("quhu")
				intention = 80
				from = xunyu
			elseif from and (from:hasFlag("ShenfenUsing") or from:hasFlag("FenchengUsing")) or damage.reason == "zhendu" then
				intention = 0
			else
				intention = 100
			end

			if sgs.ai_nosganglie_effect and sgs.ai_nosganglie_effect == string.format("%s_%s_%d", from:objectName(), to:objectName(), sgs.turncount) then
				sgs.ai_nosganglie_effect = nil
				intention = -30
			end

			if damage.transfer or damage.chain then intention = 0 end
			if from then sgs.updateIntention(from, to, intention) end
		end
	elseif triggerEvent == sgs.PreCardUsed then
		local struct = data:toCardUse()
		local card = struct.card
		local to = struct.to
		to = sgs.QList2Table(to)
		local from = struct.from
		local source = self.room:getCurrent()
		local str
		str = card:getClassName() .. card:toString() .. ":"
		local toname = {}
		for _, ato in ipairs(to) do
			table.insert(toname, ato:getGeneralName())
		end
		if from then str = str .. from:getGeneralName() .. "->" .. table.concat(toname, "+") end
		if source then str = str .. "#" .. source:getGeneralName() end
		sgs.laststr = str

		if card:isKindOf("Collateral") then sgs.ai_collateral = true end

		sgs.ai_leiji_effect = {}
		if card:isKindOf("Slash") then
			for _, t in ipairs(to) do
				if self:findLeijiTarget(t, 50, from) then
					table.insert(sgs.ai_leiji_effect, t)
				end
			end
		end

		if card:isKindOf("AOE") and self.player:objectName() == player:objectName() then sgs.ai_AOE_data = data end
		if card:isKindOf("Slash") and struct.from:getPhase() < sgs.Player_Play and struct.m_reason == sgs.CardUseStruct_CARD_USE_REASON_PLAY
			and struct.m_addHistory then
			struct.from:setFlags("AI_SlashInPlayPhase")
		end

		sgs.do_not_save_targets = {}
		if from and sgs.ai_role[from:objectName()] == "rebel" and not self:isFriend(from, from:getNextAlive())
			and (card:isKindOf("SavageAssault") or card:isKindOf("ArcheryAttack") or card:isKindOf("Duel") or card:isKindOf("Slash")) then
			for _, target in ipairs(to) do
				if self:isFriend(target, from) and sgs.ai_role[target:objectName()] == "rebel" and target:getHp() == 1 and target:isKongcheng()
				and sgs.isGoodTarget(target, nil, self) and getCardsNum("Analeptic", target, self.player) + getCardsNum("Peach", target, self.player) == 0
				and self:getEnemyNumBySeat(from, target) > 0 then
					table.insert(sgs.do_not_save_targets, target)
				end
			end
		end

		local callback = sgs.ai_card_intention[card:getClassName()]
		if #to > 0 and callback then
			if type(callback) == "function" then
				callback(self, card, from, to)
			elseif type(callback) == "number" then
				sgs.updateIntentions(from, to, callback, card)
			end
		else
			if #to > 0 and not sgs.isRolePredictable() and card:isKindOf("SkillCard") and not card:targetFixed() then
				logmsg("card_intention.txt", card:getClassName()) -- tmp debug
			end
		end
		if card:getClassName() == "LuaSkillCard" and card:isKindOf("LuaSkillCard") then
			local luaskillcardcallback = sgs.ai_card_intention[card:objectName()]
			if #to > 0 and luaskillcardcallback then
				if type(luaskillcardcallback) == "function" then
					luaskillcardcallback(card, from, to)
				elseif type(luaskillcardcallback) == "number" then
					sgs.updateIntentions(from, to, luaskillcardcallback, card)
				end
			end
		end

		local lords = {}
		for _, p in sgs.qlist(self.room:getAlivePlayers()) do
			if p:getRole() == "lord" or ((self.room:getMode() == "06_3v3" or self.room:getMode() == "06_XMode") and p:getRole() == "renegade") then
				table.insert(lords, p)
			end
		end
		for _, lord in ipairs(lords) do
			if card and lord and lord:getHp() == 1 and self:aoeIsEffective(card, lord, from) then
				if card:isKindOf("SavageAssault") then
					lord:setFlags("AIGlobal_LordInDangerSA")
				elseif card:isKindOf("ArcheryAttack") then
					lord:setFlags("AIGlobal_LordInDangerAA")
				end
			end
		end

		if sgs.turncount <= 1 and #to > 0 then
			local who = to[1]
			local lord = self.room:getLord()
			if not lord then return end
			if (card:isKindOf("Snatch") or card:isKindOf("Dismantlement") or card:isKindOf("YinlingCard")) and sgs.evaluatePlayerRole(who) == "neutral" then
				local aplayer = self:exclude({ lord }, card, player)
				if #aplayer == 1 and (lord:getJudgingArea():isEmpty() or lord:containsTrick("YanxiaoCard")) and not self:doNotDiscard(lord, "he") then
					sgs.updateIntention(player, lord, -50)
				end
			end
		end
	elseif triggerEvent == sgs.CardUsed then
		local struct = data:toCardUse()
		local card = struct.card
		if card:isKindOf("Snatch") or card:isKindOf("Dismantlement") or card:isKindOf("YinlingCard") then
			local reason = { ["Snatch"] = "snatch", ["Dismantlement"] = "dismantlement", ["YinlingCard"] = "yinling" }
			for _, p in sgs.qlist(struct.to) do
				for _, c in sgs.qlist(p:getCards("hej")) do
					c:setFlags("-AIGlobal_SDCardChosen_" .. reason[card:getClassName()])
				end
			end
		end
		if card:isKindOf("AOE") and sgs.ai_AOE_data then sgs.ai_AOE_data = nil end
	elseif triggerEvent == sgs.CardFinished then
		local struct = data:toCardUse()
		local card = struct.card
		local lord = self.room:getLord()
		if card and lord and card:isKindOf("Duel") and lord:hasFlag("AIGlobal_NeedToWake") then
			lord:setFlags("-AIGlobal_NeedToWake")
		end
		if card:isKindOf("Collateral") then sgs.ai_collateral = false end
	elseif triggerEvent == sgs.BeforeCardsMove then
		local move = data:toMoveOneTime()
		local from = nil -- convert move.from from const Player * to ServerPlayer *
		if move.from then from = findPlayerByObjectName(self.room, move.from:objectName()) end
		local reason = move.reason
		local from_places = sgs.QList2Table(move.from_places)

		for i = 1, move.card_ids:length() do
			local place = move.from_places:at(i - 1)
			local card_id = move.card_ids:at(i - 1)
			local card = sgs.Sanguosha:getCard(card_id)
			if reason.m_skillName == "qiaobian" and from and move.to and self.room:getCurrent():objectName() == player:objectName() then
				if table.contains(from_places, sgs.Player_PlaceDelayedTrick) then
					if card:isKindOf("YanxiaoCard") then
						sgs.updateIntention(player, from, 80)
						sgs.updateIntention(player, move.to, -80)
					end
					if card:isKindOf("SupplyShortage") or card:isKindOf("Indulgence") then
						sgs.updateIntention(player, from, -80)
						sgs.updateIntention(player, move.to, 80)
					end
				end
				if table.contains(from_places, sgs.Player_PlaceEquip) then
					sgs.updateIntention(player, move.to, -80)
				end
			end
		end
	elseif triggerEvent == sgs.CardsMoveOneTime then
		local move = data:toMoveOneTime()
		local from, to -- convert move.from and move.to from const Player * to ServerPlayer *
		if move.from then from = findPlayerByObjectName(self.room, move.from:objectName()) end
		if move.to then to = findPlayerByObjectName(self.room, move.to:objectName()) end
		local reason = move.reason
		local from_places = sgs.QList2Table(move.from_places)

		for i = 1, move.card_ids:length() do
			local place = move.from_places:at(i - 1)
			local card_id = move.card_ids:at(i - 1)
			local card = sgs.Sanguosha:getCard(card_id)

			if place == sgs.Player_DrawPile
				or (move.to_place == sgs.Player_DrawPile and not (from and tonumber(from:property("zongxuan_move"):toString()) == card_id)) then
				self.top_draw_pile_id = nil
			end

			if move.to_place == sgs.Player_PlaceHand and to and player:objectName() == to:objectName() then
				if card:hasFlag("visible") then
					if isCard("Slash", card, to) then sgs.card_lack[move.to:objectName()]["Slash"] = 0 end
					if isCard("Jink", card, to) then sgs.card_lack[move.to:objectName()]["Jink"] = 0 end
				else
					sgs.card_lack[move.to:objectName()]["Slash"] = 0
					sgs.card_lack[move.to:objectName()]["Jink"] = 0
				end
			end

			if move.to_place == sgs.Player_PlaceHand and move.to and place ~= sgs.Player_DrawPile then
				if move.from and player:objectName() == move.from:objectName()
					and move.from:objectName() ~= move.to:objectName() and place == sgs.Player_PlaceHand and not card:hasFlag("visible") then
					local flag = string.format("%s_%s_%s", "visible", move.from:objectName(), move.to:objectName())
					card:setFlags(flag)
				end
			end

			if move.to_place == sgs.Player_PlaceHand then
				if (not from or sgs.card_lack[from:objectName()]["Peach"] == 0) and to and not card:hasFlag("visible") and sgs.card_lack[to:objectName()]["Peach"] == 1 then
					sgs.card_lack[to:objectName()]["Peach"] = 0
				end
			end

			if player:hasFlag("AIGlobal_PlayPhaseNotSkipped") and sgs.turncount <= 3 and player:getPhase() == sgs.Player_Discard
				and reason.m_reason == sgs.CardMoveReason_S_REASON_RULEDISCARD
				and (not self:needBear(player) or (player:hasSkills("renjie+baiyin") and player:getMark("jilve") == 0))
				and not player:hasFlag("ShuangrenSkipPlay")
				and move.from and move.from:objectName() == player:objectName() then
				local is_neutral = (sgs.evaluatePlayerRole(player) == "neutral")
				if isCard("Slash", card, player) and not player:hasFlag("AI_SlashInPlayPhase")
					and not player:isLocked(sgs.cloneCard("slash", card:getSuit(), card:getNumber())) then
					for _, target in sgs.qlist(self.room:getOtherPlayers(player)) do
						local has_slash_prohibit_skill = false
						if target:hasSkill("fangzhu") and target:getLostHp() <= 2 then
							has_slash_prohibit_skill = true
						end
						if not has_slash_prohibit_skill and target:hasSkill("xiangle") then
							local basic_num = 0
							for _, c_id in sgs.qlist(move.card_ids) do
								local c = sgs.Sanguosha:getCard(c_id)
								if c:isKindOf("BasicCard") then basic_num = basic_num + 1 end
							end
							if basic_num < 2 then has_slash_prohibit_skill = true break end
						else
							for _, askill in ipairs(sgs.getPlayerSkillList(target)) do
								local filter = sgs.ai_slash_prohibit[askill:objectName()]
								if filter and type(filter) == "function" and filter(self, player, target, card) then
									has_slash_prohibit_skill = true
									break
								end
							end
						end
						if player:canSlash(target, card, true) and self:slashIsEffective(card, target)
							and not has_slash_prohibit_skill and sgs.isGoodTarget(target, self.enemies, self) then
							if is_neutral then
								sgs.updateIntention(player, target, -35)
							end
						end
					end
				end

				if isCard("Indulgence", card, player) and self.room:getLord() and not self.room:getLord():hasSkill("qiaobian") then
					for _, target in sgs.qlist(self.room:getOtherPlayers(player)) do
						if not (target:containsTrick("indulgence") or target:containsTrick("YanxiaoCard") or target:hasSkill("qiaobian")) then
							local aplayer = self:exclude({ target }, card, player)
							if #aplayer == 1 and is_neutral then
								sgs.updateIntention(player, target, -35)
							end
						end
					end
				end

				if isCard("SupplyShortage", card, player) and self.room:getLord() and not self.room:getLord():hasSkill("qiaobian") then
					for _, target in sgs.qlist(self.room:getOtherPlayers(player)) do
						if player:distanceTo(target) <= (player:hasSkill("duanliang") and 2 or 1)
							and not (target:containsTrick("supply_shortage") or target:containsTrick("YanxiaoCard") or target:hasSkill("qiaobian")) then
							local aplayer = self:exclude({ target }, card, player)
							if #aplayer == 1 and is_neutral then
								sgs.updateIntention(player, target, -35)
							end
						end
					end
				end
			end
		end
	elseif triggerEvent == sgs.StartJudge then
		local judge = data:toJudge()
		local reason = judge.reason
		if reason == "beige" then
			local caiwenji = self.room:findPlayerBySkillName("beige")
			local intention = -60
			if player:objectName() == caiwenji:objectName() then intention = 0 end
			sgs.updateIntention(caiwenji, player, intention)
		end

		local judgex = { who = judge.who, reason = judge.reason, good = judge:isGood() }
		table.insert(sgs.ai_current_judge, judgex)
	elseif triggerEvent == sgs.AskForRetrial then
		local judge = data:toJudge()

		local judge_len = #sgs.ai_current_judge
		local last_judge = sgs.ai_current_judge[judge_len]
		table.remove(sgs.ai_current_judge, judge_len)

		if not last_judge.good and judge:isGood() then
			sgs.updateIntention(player, last_judge.who, -30)
		elseif last_judge.good and not judge:isGood() then
			sgs.updateIntention(player, last_judge.who, 30)
		end

		last_judge.good = judge:isGood()
		table.insert(sgs.ai_current_judge, last_judge)
	elseif triggerEvent == sgs.FinishJudge then
		table.remove(sgs.ai_current_judge, #sgs.ai_current_judge)
	elseif triggerEvent == sgs.EventPhaseEnd and player:getPhase() == sgs.Player_Play then
		player:setFlags("AIGlobal_PlayPhaseNotSkipped")
	elseif triggerEvent == sgs.EventPhaseStart and player:getPhase() == sgs.Player_NotActive then
		if player:isLord() then sgs.turncount = sgs.turncount + 1 end

		local file = io.open("lua/ai/AIDebug.Readme")
		if file then
			file:close()
			sgs.debugmode = true
		else
			sgs.debugmode = false
		end
	elseif triggerEvent == sgs.GameStart then
		local file = io.open("lua/ai/AIDebug.Readme")
		if file then
			file:close()
			sgs.debugmode = true
		else
			sgs.debugmode = false
		end
		if player:isLord() and sgs.debugmode then
			logmsg("ai.html", "<meta charset='utf-8'/>")
		end
	end
end

function SmartAI:askForSuit(reason)
	local callback = sgs.ai_skill_suit[reason]
	if type(callback) == "function" then
		if callback(self) then return callback(self) end
	end
	return math.random(0, 3)
end

function SmartAI:askForSkillInvoke(skill_name, data)
	skill_name = string.gsub(skill_name, "%-", "_")
	local invoke = sgs.ai_skill_invoke[skill_name]
	if type(invoke) == "boolean" then
		return invoke
	elseif type(invoke) == "function" then
		return invoke(self, data)
	else
		local skill = sgs.Sanguosha:getSkill(skill_name)
		return skill and skill:getFrequency() == sgs.Skill_Frequent
	end
end

function SmartAI:askForChoice(skill_name, choices, data)
	local choice = sgs.ai_skill_choice[skill_name]
	if type(choice) == "string" then
		return choice
	elseif type(choice) == "function" then
		return choice(self, choices, data)
	else
		local choice_table = choices:split("+")
		local r = math.random(1, #choice_table)
		return choice_table[r]
	end
end

function SmartAI:askForDiscard(reason, discard_num, min_num, optional, include_equip, pattern)
	min_num = min_num or discard_num
	pattern = pattern or "."
	local exchange = self.player:hasFlag("Global_AIDiscardExchanging")
	local callback = sgs.ai_skill_discard[reason]
	self:assignKeep(true)
	if type(callback) == "function" then
		local cb = callback(self, discard_num, min_num, optional, include_equip, pattern)
		if cb then
			if type(cb) == "number" and not self.player:isJilei(sgs.Sanguosha:getCard(cb)) then return { cb }
			elseif type(cb) == "table" then
				for _, card_id in ipairs(cb) do
					if not exchange and self.player:isJilei(sgs.Sanguosha:getCard(card_id)) then
						return {}
					end
				end
				return cb
			end
			return {}
		end
	elseif optional then
		return min_num == 1 and self:needToThrowArmor() and sgs.Sanguosha:matchExpPattern(pattern, self.player, self.player:getArmor())
				and self.player:getArmor():getEffectiveId() or {}
	end

	local flag = "h"
	if include_equip and (self.player:getEquips():isEmpty() or not self.player:isJilei(self.player:getEquips():first())) then flag = flag .. "e" end
	local all_cards = self.player:getCards(flag)
	local cards = {}
	for _, c in sgs.qlist(all_cards) do
		if sgs.Sanguosha:matchExpPattern(pattern, self.player, c) then table.insert(cards, c) end
	end
	self:sortByKeepValue(cards)
	local to_discard, temp = {}, {}

	local least = min_num
	if discard_num - min_num > 1 then
		least = discard_num - 1
	end
	for _, card in ipairs(cards) do
		if exchange or not self.player:isJilei(card) then
			place = self.room:getCardPlace(card:getEffectiveId())
			if self.player:hasSkills(sgs.lose_equip_skill) and place == sgs.Player_PlaceEquip then
				table.insert(temp, card:getEffectiveId())
			elseif self:getKeepValue(card) >= 4.1 then
				table.insert(temp, card:getEffectiveId())
			else
				table.insert(to_discard, card:getEffectiveId())
			end
			if #to_discard == discard_num then return to_discard end
		end
	end
	if #to_discard < discard_num then
		for _, id in ipairs(temp) do
			table.insert(to_discard, id)
			if #to_discard == discard_num then return to_discard end
		end
	end
	return to_discard
end

function SmartAI:askForNullification(trick, from, to, positive)
	local null_card
	null_card = self:getCardId("Nullification")
	local null_num = self:getCardsNum("Nullification")
	local menghuo = self.room:findPlayerBySkillName("huoshou")

	if null_card then null_card = sgs.Card_Parse(null_card) else return nil end
	if self.player:isLocked(null_card) then return nil end
	if (from and from:isDead()) or (to and to:isDead()) then return nil end
	if self:needBear() then return nil end
	if self.player:hasSkill("wumou") then
		if self.player:getMark("@wrath") == 0 and (self:isWeak() or self.player:isLord()) then return nil end
		if to:objectName() == self.player:objectName() and not self:isWeak() and (trick:isKindOf("AOE") or trick:isKindOf("Duel") or trick:isKindOf("FireAttack")) then
			return
		end
	end

	if trick:isKindOf("FireAttack") then
		if to:isKongcheng() or from:isKongcheng() then return nil end
		if self.player:objectName() == from:objectName() and self.player:getHandcardNum() == 1 and self.player:handCards():first() == null_card:getId() then return nil end
	end
	if ("snatch|dismantlement"):match(trick:objectName()) and to:isAllNude() then return nil end

	if from and not from:hasSkill("jueqing") then
		if (trick:isKindOf("Duel") or trick:isKindOf("FireAttack") or trick:isKindOf("Drowning") or trick:isKindOf("AOE"))
			and (to:hasSkill("wuyan") or (self:getDamagedEffects(to, from) and self:isFriend(to))) then
			return nil
		end
		if (trick:isKindOf("Duel") or trick:isKindOf("Drowning") or trick:isKindOf("AOE")) and not self:damageIsEffective(to, sgs.DamageStruct_Normal) then return nil end
		if trick:isKindOf("FireAttack") and not self:damageIsEffective(to, sgs.DamageStruct_Fire) then return nil end
	end
	if (trick:isKindOf("Duel") or trick:isKindOf("FireAttack") or trick:isKindOf("Drowning") or trick:isKindOf("AOE")) and self:needToLoseHp(to, from) and self:isFriend(to) then
		return nil
	end
	if trick:isKindOf("Drowning") and self:needToThrowArmor(to) and self:isFriend(to) then return nil end

	local callback = sgs.ai_nullification[trick:getClassName()]
	if type(callback) == "function" then
		local shouldUse = callback(self, trick, from, to, positive)
		if shouldUse then return null_card end
	end

	if positive then
		if from and (trick:isKindOf("FireAttack") or trick:isKindOf("Duel") or trick:isKindOf("AOE"))
			and (self:needDeath(to) or self:cantbeHurt(to, from, 1)) then
			if self:isFriend(from) then return null_card end
			return
		end
		if ("snatch|dismantlement"):match(trick:objectName()) and not to:containsTrick("YanxiaoCard") and (to:containsTrick("indulgence") or to:containsTrick("supply_shortage")) then
			if self:isEnemy(from) then return null_card end
			if self:isFriend(to) and to:isNude() then return nil end
		end
		if trick:isKindOf("Duel") and (trick:getSkillName() == "lijian" or trick:getSkillName() == "liyu") and (self:isFriend(to) or (self:isFriend(from) and to:hasSkill("wuhun"))) then
			if to:getHp() == 1 and sgs.ai_role[to:objectName()] == "rebel" and from and sgs.ai_role[from:objectName()] == "rebel" then return end
			return null_card
		end
		if from and self:isEnemy(from) and (sgs.evaluatePlayerRole(from) ~= "neutral" or sgs.isRolePredictable()) then
			if self.player:hasSkill("kongcheng") and self.player:getHandcardNum() == 1 and self.player:isLastHandCard(null_card) and trick:isKindOf("SingleTargetTrick") then return null_card end
			if trick:isKindOf("ExNihilo") and (self:isWeak(from) or from:hasSkills(sgs.cardneed_skill) or from:hasSkill("manjuan")) then return null_card end
			if trick:isKindOf("IronChain") and not to:hasArmorEffect("vine") then return nil end
			if self:isFriend(to) then
				if trick:isKindOf("Dismantlement") then
					if self:getDangerousCard(to) or self:getValuableCard(to) then return null_card end
					if to:getHandcardNum() == 1 and not self:needKongcheng(to) then
						if (getKnownCard(to, self.player, "TrickCard|EquipCard|Slash", false) == 1) then
							return nil
						end
						return null_card
					end
				else
					if trick:isKindOf("Snatch") then return null_card end
					if trick:isKindOf("Duel") and self:damageIsEffective(to, sgs.DamageStruct_Normal, from) and self:isWeak(to) then return null_card end
					if trick:isKindOf("FireAttack") and from:objectName() ~= to:objectName() and self:damageIsEffective(to, sgs.DamageStruct_Fire, player) then
						if from:getHandcardNum() > 2
							or self:isWeak(to)
							or to:hasArmorEffect("vine")
							or to:getMark("@gale") > 0
							or to:isChained() and not self:isGoodChainTarget(to, from, sgs.DamageStruct_Fire, nil, trick) then
							return null_card
						end
					end
				end
			elseif self:isEnemy(to) then
				if (trick:isKindOf("Snatch") or trick:isKindOf("Dismantlement")) and to:getCards("j"):length() > 0 then
					return null_card
				elseif trick:isKindOf("Drowning") and to:getEquips():length() <= 2 and self:needToThrowArmor(to) then
					return null_card
				end
			end
		end

		if self:isFriend(to) then
			if not (to:hasSkill("guanxing") and global_room:alivePlayerCount() > 4) then
				if trick:isKindOf("Indulgence") and not to:isSkipped(sgs.Player_Play) then
					if to:getPile("incantation"):length() > 0 then
						local card = sgs.Sanguosha:getCard(to:getPile("incantation"):first())
						if card:getSuit() == sgs.Card_Heart or (to:hasSkill("hongyan") and card:getSuit() == sgs.Card_Spade) then return nil end
					end
					if to:getHp() - to:getHandcardNum() >= 2 then return nil end
					if to:hasSkill("nostuxi") and to:getHp() > 2 then return nil end
					if to:hasSkill("tuxi") and to:getHp() > 2 then
						local count = 0
						for _, enemy in ipairs(#self:getEnemies(to)) do
							if enemy:getHandcardNum() >= to:getHandcardNum() then count = count + 1 end
							if count == 2 then return nil end
						end
					end
					if to:hasSkill("qiaobian") and not to:isKongcheng() then return nil end
					return null_card
				elseif trick:isKindOf("SupplyShortage") and not to:isSkipped(sgs.Player_Draw) then
					if to:getPile("incantation"):length() > 0 then
						local card = sgs.Sanguosha:getCard(to:getPile("incantation"):first())
						if card:getSuit() == sgs.Card_Club then return nil end
					end
					if to:hasSkills("guidao|tiandu") then return nil end
					if to:getMark("@kuiwei") == 0 then return nil end
					if to:hasSkill("qiaobian") and not to:isKongcheng() then return nil end
					return null_card
				end
			end
			if trick:isKindOf("AOE") and not (from:hasSkill("wuyan") and not (menghuo and trick:isKindOf("SavageAssault"))) then
				local lord = self.room:getLord()
				local currentplayer = self.room:getCurrent()
				if lord and self:isFriend(lord) and self:isWeak(lord) and self:aoeIsEffective(trick, lord)
					and ((lord:getSeat() - currentplayer:getSeat()) % (self.room:alivePlayerCount()))
						> ((to:getSeat() - currentplayer:getSeat()) % (self.room:alivePlayerCount()))
					and not (self.player:objectName() == to:objectName() and self.player:getHp() == 1 and not self:canAvoidAOE(trick)) then
					return nil
				end
				if self.player:objectName() == to:objectName() then
					if self.player:hasSkills("jieming|nosyiji|yiji|guixin")
						and (self.player:getHp() > 1 or self:getCardsNum("Peach") > 0 or self:getCardsNum("Analeptic") > 0) then
						return nil
					elseif not self:canAvoidAOE(trick) and not (self.player:hasSkill("wumou") and sgs.ai_skill_choice.wumou(self) == "losehp") then
						return null_card
					end
				end
				if self:isWeak(to) and self:aoeIsEffective(trick, to) then
					if ((to:getSeat() - currentplayer:getSeat()) % (self.room:alivePlayerCount()))
						> ((self.player:getSeat() - currentplayer:getSeat()) % (self.room:alivePlayerCount())) or null_num > 1 then
						return null_card
					elseif self:canAvoidAOE(trick) or self.player:getHp() > 1 or (to:isLord() and self.role == "loyalist") then
						return null_card
					end
				end
			end
			if trick:isKindOf("Duel") and not from:hasSkill("wuyan") then
				if self.player:objectName() == to:objectName() then
					if self.player:hasSkills(sgs.masochism_skill)
						and (self.player:getHp() > 1 or self:getCardsNum("Peach") > 0 or self:getCardsNum("Analeptic") > 0) then
						return nil
					elseif self:getCardsNum("Slash") == 0 then
						return null_card
					end
				end
			end
		end
		if from then
			if self:isEnemy(to) then
				if trick:isKindOf("GodSalvation") and self:isWeak(to) then
					return null_card
				end
				if trick:isKindOf("AmazingGrace") then
					local NP = to:getNextAlive()
					if self:isFriend(NP) then
						local ag_ids = self.room:getTag("AmazingGrace"):toIntList()
						local peach_num, exnihilo_num, snatch_num, analeptic_num, crossbow_num, indulgence_num = 0, 0, 0, 0, 0, 0
						local fa_card
						for _, ag_id in sgs.qlist(ag_ids) do
							local ag_card = sgs.Sanguosha:getCard(ag_id)
							if ag_card:isKindOf("Peach") then peach_num = peach_num + 1 end
							if ag_card:isKindOf("ExNihilo") then exnihilo_num = exnihilo_num + 1 end
							if ag_card:isKindOf("Snatch") then snatch_num = snatch_num + 1 end
							if ag_card:isKindOf("Analeptic") then analeptic_num = analeptic_num + 1 end
							if ag_card:isKindOf("Crossbow") then crossbow_num = crossbow_num + 1 end
							if ag_card:isKindOf("FireAttack") then fa_card = ag_card end
							if ag_card:isKindOf("Indulgence") then indulgence_num = indulgence_num + 1 end
						end
						if (peach_num == 1 and to:getHp() < getBestHp(to))
							or (peach_num > 0 and (self:isWeak(to) or (NP:getHp() < getBestHp(NP) and self:getOverflow(NP) <= 0))) then
							return null_card
						end
						if peach_num == 0 and not self:willSkipPlayPhase(NP) then
							if exnihilo_num > 0 then
								if NP:hasSkills("nosjizhi|jizhi|nosrende|zhiheng")
									or (NP:hasSkill("rende") and not NP:hasUsed("RendeCard"))
									or (NP:hasSkill("jilve") and NP:getMark("@bear") > 0) then return null_card end
							else
								for _, enemy in ipairs(self.enemies) do
									if indulgence_num > 0 and not self:willSkipPlayPhase(enemy, true) then
										return null_card
									elseif snatch_num > 0 and to:distanceTo(enemy) == 1
											and (self:willSkipPlayPhase(enemy, true) or self:willSkipDrawPhase(enemy, true)) then
										return null_card
									elseif analeptic_num > 0 and (enemy:hasWeapon("axe") or getCardsNum("Axe", enemy, self.player) > 0) then
										return null_card
									elseif crossbow_num > 0 and getCardsNum("Slash", enemy, self.player) >= 3 then
										local slash = sgs.cloneCard("slash")
										for _, friend in ipairs(self.friends) do
											if enemy:distanceTo(friend) == 1 and self:slashIsEffective(slash, friend, enemy) then
												return null_card
											end
										end
									end
								end
							end
						end
					end
					if fa_card then
						for _, friend in ipairs(self.friends) do
							if (friend:hasArmorEffect("vine") or friend:getMark("@gale") > 0) and not to:hasSkill("jueqing")
								and self:hasTrickEffective(fa_card, friend, to) and to:getHandcardNum() > 2 then
								return null_card
							end
						end
					end
				end
			end
		end
	else
		if from then
			if (trick:isKindOf("FireAttack") or trick:isKindOf("Duel") or trick:isKindOf("AOE"))
				and (self:needDeath(to) or self:cantbeHurt(to, from, 1)) then
				if self:isEnemy(from) then return null_card end
				return
			end
			if (trick:getSkillName() == "lijian" or trick:getSkillName() == "liyu") and trick:isKindOf("Duel") then
				if self:isEnemy(to) and (self:isWeak(to) or null_num > 1 or self:getOverflow() > 0 or not self:isWeak()) then return null_card end
				return
			end
			if from:objectName() == to:objectName() then
				if self:isFriend(from) then return null_card else return end
			end
			if not (trick:isKindOf("GlobalEffect") or trick:isKindOf("AOE")) then
				if self:isFriend(from) and not self:isFriend(to) then
					if ("snatch|dismantlement"):match(trick:objectName()) and to:isNude() then
					elseif trick:isKindOf("FireAttack") and to:isKongcheng() then
					else return null_card end
				end
			end
		else
			if self:isEnemy(to) and (sgs.evaluatePlayerRole(to) ~= "neutral" or sgs.isRolePredictable()) then return null_card else return end
		end
	end
end

function SmartAI:getCardRandomly(who, flags)
	local cards = who:getCards(flags)
	if cards:isEmpty() then return end
	local r = math.random(0, cards:length() - 1)
	local card = cards:at(r)
	if who:hasArmorEffect("silver_lion") then
		if self:isEnemy(who) and who:isWounded() and card == who:getArmor() then
			if r ~= (cards:length() - 1) then
				card = cards:at(r + 1)
			elseif r > 0 then
				card = cards:at(r - 1)
			end
		end
	end
	return card:getEffectiveId()
end

function SmartAI:askForCardChosen(who, flags, reason, method)
	local isDiscard = (method == sgs.Card_MethodDiscard)
	local cardchosen = sgs.ai_skill_cardchosen[string.gsub(reason, "%-", "_")]
	local card
	if type(cardchosen) == "function" then
		card = cardchosen(self, who, flags, method)
		if card then
			if type(card) == "number" then return card
			else return card:getEffectiveId() end
		end
	elseif type(cardchosen) == "number" then
		sgs.ai_skill_cardchosen[string.gsub(reason, "%-", "_")] = nil
		for _, acard in sgs.qlist(who:getCards(flags)) do
			if acard:getEffectiveId() == cardchosen then return cardchosen end
		end
	end

	if ("snatch|dismantlement|yinling"):match(reason) then
		local flag = "AIGlobal_SDCardChosen_" .. reason
		local to_choose
		for _, card in sgs.qlist(who:getCards(flags)) do
			if card:hasFlag(flag) then
				card:setFlags("-" .. flag)
				to_choose = card:getId()
				break
			end
		end
		if to_choose then
			local is_handcard
			if not who:isKongcheng() and who:handCards():contains(to_choose) then is_handcard = true end
			if is_handcard and reason == "dismantlement" and self.room:getMode() == "02_1v1" and sgs.GetConfig("1v1/Rule", "Classical") ~= "Classical" then
				local cards = sgs.QList2Table(who:getHandcards())
				local peach, jink
				for _, card in ipairs(cards) do
					if not peach and isCard("Peach", card, who) then peach = card:getId() end
					if not jink and isCard("Jink", card, who) then jink = card:getId() end
					if peach and jink then break end
				end
				if peach or jink then return peach or jink end
				self:sortByKeepValue(cards, true)
				return cards[1]:getEffectiveId()
			else
				return to_choose
			end
		end
	end

	if self:isFriend(who) then
		if flags:match("j") and not who:containsTrick("YanxiaoCard") and not who:hasSkill("qiaobian") then
			local tricks = who:getCards("j")
			local lightning, indulgence, supply_shortage
			for _, trick in sgs.qlist(tricks) do
				if trick:isKindOf("Lightning") and (not isDiscard or self.player:canDiscard(who, trick:getId())) then
					lightning = trick:getId()
				elseif trick:isKindOf("Indulgence") and (not isDiscard or self.player:canDiscard(who, trick:getId()))  then
					indulgence = trick:getId()
				elseif not trick:isKindOf("Disaster") and (not isDiscard or self.player:canDiscard(who, trick:getId())) then
					supply_shortage = trick:getId()
				end
			end

			if self:hasWizard(self.enemies) and lightning then
				return lightning
			end

			if indulgence and supply_shortage then
				if who:getHp() < who:getHandcardNum() then
					return indulgence
				else
					return supply_shortage
				end
			end

			if indulgence or supply_shortage then
				return indulgence or supply_shortage
			end
		end

		if flags:match("e") then
			if who:getArmor() and self:needToThrowArmor(who) and (not isDiscard or self.player:canDiscard(who, who:getArmor():getEffectiveId())) then
				return who:getArmor():getEffectiveId()
			end
			if who:getArmor() and self:evaluateArmor(who:getArmor(), who) < -5 and (not isDiscard or self.player:canDiscard(who, who:getArmor():getEffectiveId())) then
				return who:getArmor():getEffectiveId()
			end
			if who:hasSkills(sgs.lose_equip_skill) and self:isWeak(who) then
				if who:getWeapon() and (not isDiscard or self.player:canDiscard(who, who:getWeapon():getEffectiveId())) then return who:getWeapon():getEffectiveId() end
				if who:getOffensiveHorse() and (not isDiscard or self.player:canDiscard(who, who:getOffensiveHorse():getEffectiveId())) then return who:getOffensiveHorse():getEffectiveId() end
			end
		end
	else
		local dangerous = self:getDangerousCard(who)
		if flags:match("e") and dangerous and (not isDiscard or self.player:canDiscard(who, dangerous)) then return dangerous end
		if flags:match("e") and who:getTreasure() and who:getPile("wooden_ox"):length() > 1 and (not isDiscard or self.player:canDiscard(who, who:getTreasure():getId())) then
			return who:getTreasure():getId()
		end
		if flags:match("e") and who:getArmor() and who:hasArmorEffect("eight_diagram") and not self:needToThrowArmor(who)
			and (not isDiscard or self.player:canDiscard(who, who:getArmor():getId())) then return who:getArmor():getId() end
		if flags:match("e") and who:hasSkills("jijiu|beige|mingce|weimu|qingcheng") and not self:doNotDiscard(who, "e", false, 1, reason) then
			if who:getDefensiveHorse() and (not isDiscard or self.player:canDiscard(who, who:getDefensiveHorse():getEffectiveId())) then return who:getDefensiveHorse():getEffectiveId() end
			if who:getArmor() and not self:needToThrowArmor(who) and (not isDiscard or self.player:canDiscard(who, who:getArmor():getEffectiveId())) then return who:getArmor():getEffectiveId() end
			if who:getOffensiveHorse() and (not who:hasSkill("jijiu") or who:getOffensiveHorse():isRed()) and (not isDiscard or self.player:canDiscard(who, who:getOffensiveHorse():getEffectiveId())) then
				return who:getOffensiveHorse():getEffectiveId()
			end
			if who:getWeapon() and (not who:hasSkill("jijiu") or who:getWeapon():isRed()) and (not isDiscard or self.player:canDiscard(who, who:getWeapon():getEffectiveId())) then
				return who:getWeapon():getEffectiveId()
			end
		end
		if flags:match("e") then
			local valuable = self:getValuableCard(who)
			if valuable and (not isDiscard or self.player:canDiscard(who, valuable)) then
				return valuable
			end
		end
		if flags:match("h") and (not isDiscard or self.player:canDiscard(who, "h")) then
			if who:hasSkills("jijiu|qingnang|qiaobian|jieyin|beige|buyi|manjuan")
				and not who:isKongcheng() and who:getHandcardNum() <= 2 and not self:doNotDiscard(who, "h", false, 1, reason) then
				return self:getCardRandomly(who, "h")
			end
			local cards = sgs.QList2Table(who:getHandcards())
			local flag = string.format("%s_%s_%s", "visible", self.player:objectName(), who:objectName())
			if #cards <= 2 and not self:doNotDiscard(who, "h", false, 1, reason) then
				for _, cc in ipairs(cards) do
					if (cc:hasFlag("visible") or cc:hasFlag(flag)) and (cc:isKindOf("Peach") or cc:isKindOf("Analeptic")) then
						return self:getCardRandomly(who, "h")
					end
				end
			end
		end

		if flags:match("j") then
			local tricks = who:getCards("j")
			local lightning, yanxiao
			for _, trick in sgs.qlist(tricks) do
				if trick:isKindOf("Lightning") and (not isDiscard or self.player:canDiscard(who, trick:getId())) then
					lightning = trick:getId()
				elseif trick:isKindOf("YanxiaoCard") and (not isDiscard or self.player:canDiscard(who, trick:getId())) then
					yanxiao = trick:getId()
				end
			end
			if self:hasWizard(self.enemies, true) and lightning then
				return lightning
			end
			if yanxiao then
				return yanxiao
			end
		end

		if flags:match("h") and not self:doNotDiscard(who, "h") then
			if (who:getHandcardNum() == 1 and sgs.getDefenseSlash(who, self) < 3 and who:getHp() <= 2) or who:hasSkills(sgs.cardneed_skill) then
				return self:getCardRandomly(who, "h")
			end
		end

		if flags:match("e") and not self:doNotDiscard(who, "e") then
			local def, arm, off, weap = who:getDefensiveHorse(), who:getArmor(), who:getOffensiveHorse(), who:getWeapon()
			if def and (not isDiscard or self.player:canDiscard(who, def:getEffectiveId())) then return def:getEffectiveId() end
			if arm and not self:needToThrowArmor(who) and (not isDiscard or self.player:canDiscard(who, arm:getEffectiveId()))
				and not (self.moukui_effect and self.moukui_effect:isKindOf("FireSlash") and arm:isKindOf("Vine") and not self.player:hasSkill("jueqing")) then
				return arm:getEffectiveId()
			end
			if off and (not isDiscard or self.player:canDiscard(who, off:getEffectiveId())) then return off:getEffectiveId() end
			if weap and (not isDiscard or self.player:canDiscard(who, weap:getEffectiveId())) then return weap:getEffectiveId() end
		end

		if flags:match("h") then
			if (not who:isKongcheng() and who:getHandcardNum() <= 2) and not self:doNotDiscard(who, "h", false, 1, reason) then
				return self:getCardRandomly(who, "h")
			end
		end
	end
	return -1
end

function sgs.ai_skill_cardask.nullfilter(self, data, pattern, target)
	local damage_nature = sgs.DamageStruct_Normal

	local effect
	if type(data) == "userdata" then
		effect = data:toSlashEffect()
		if effect and effect.slash then damage_nature = effect.nature end
	end

	if self.player:isDead() then return "." end
	if target and self:needDeath() then return "." end
	if target and target:hasSkill("jueqing") and not self:needToLoseHp() then return end
	if effect and target and target:hasSkill("nosqianxi") and target:distanceTo(self.player) == 1 then return end
	if target and sgs.ai_role[target:objectName()] == "rebel"
		and self.role == "rebel" and sgs.do_not_save_targets and table.contains(sgs.do_not_save_targets, player) then return "." end
	if not self:damageIsEffective(nil, damage_nature, target) then return "." end
	if target and target:hasSkill("guagu") and self.player:isLord() then return "." end

	if effect and self:hasHeavySlashDamage(target, effect.slash) then return end
	if effect and target and target:hasWeapon("ice_sword") and self.player:getCards("he"):length() > 1 then return end
	if self:getDamagedEffects(self.player, target) or self:needToLoseHp(self.player, target) then return "." end
	if self:needBear() and self.player:getLostHp() == 0 then return "." end
	if self.player:hasSkill("zili") and not self.player:hasSkill("paiyi") and self.player:getLostHp() < 2 then return "." end
	if self.player:hasSkill("wumou") and self.player:getMark("@wrath") < 7 and self.player:getHp() > 2 then return "." end
	if self.player:hasSkill("tianxiang") then
		local dmgStr = { damage = 1, nature = damage_nature }
		local willTianxiang = sgs.ai_skill_use["@@tianxiang"](self, dmgStr, sgs.Card_MethodDiscard)
		if willTianxiang ~= "." then return "." end
	elseif self.player:hasSkill("longhun") and self.player:getHp() > 1 then
		return "."
	end
end

function SmartAI:askForCard(pattern, prompt, data)
	local target, target2
	local parsedPrompt = prompt:split(":")
	if parsedPrompt[2] then
		local players = self.room:getPlayers()
		players = sgs.QList2Table(players)
		for _, player in ipairs(players) do
			if player:getGeneralName() == parsedPrompt[2] or player:objectName() == parsedPrompt[2] then target = player break end
		end
		if parsedPrompt[3] then
			for _, player in ipairs(players) do
				if player:getGeneralName() == parsedPrompt[3] or player:objectName() == parsedPrompt[3] then target2 = player break end
			end
		end
	end
	local arg, arg2 = parsedPrompt[4], parsedPrompt[5]
	local callback = sgs.ai_skill_cardask[parsedPrompt[1]]
	if type(callback) == "function" then
		local ret = callback(self, data, pattern, target, target2, arg, arg2)
		if ret then return ret end
	end

	if data and type(data) == "number" then return end
	local card
	if pattern == "slash" then
		card = sgs.ai_skill_cardask.nullfilter(self, data, pattern, target) or self:getCardId("Slash") or "."
	elseif pattern == "jink" then
		card = sgs.ai_skill_cardask.nullfilter(self, data, pattern, target) or self:getCardId("Jink") or "."
	end
	return card
end

sgs.ai_choicemade_filter.cardResponded.general = function(self, player, promptlist)
	local pattern = promptlist[2]
	if promptlist[#promptlist] == "_nil_" then
		if pattern == "slash" then
			if card == "." then sgs.card_lack[player:objectName()]["Slash"] = 1 end
		elseif pattern == "jink" then
			if card == "." then sgs.card_lack[player:objectName()]["Jink"] = 1 end
		end
	end
end

function SmartAI:askForUseCard(pattern, prompt, method)
	local use_func = sgs.ai_skill_use[pattern]
	if use_func then
		return use_func(self, prompt, method) or "."
	else
		return "."
	end
end

function SmartAI:askForAG(card_ids, refusable, reason)
	local cardchosen = sgs.ai_skill_askforag[string.gsub(reason, "%-", "_")]
	if type(cardchosen) == "function" then
		local card_id = cardchosen(self, card_ids)
		if card_id then return card_id end
	end

	if refusable and reason == "xinzhan" then
		local next_player = self.player:getNextAlive()
		if self:isFriend(next_player) and next_player:containsTrick("indulgence") and not next_player:containsTrick("YanxiaoCard") then
			if #card_ids == 1 then return -1 end
		end
		for _, card_id in ipairs(card_ids) do
			return card_id
		end
		return -1
	end
	local ids = card_ids
	local cards = {}
	for _, id in ipairs(ids) do
		table.insert(cards, sgs.Sanguosha:getCard(id))
	end
	for _, card in ipairs(cards) do
		if card:isKindOf("Peach") then return card:getEffectiveId() end
	end
	for _, card in ipairs(cards) do
		if card:isKindOf("Indulgence") and not (self:isWeak() and self:getCardsNum("Jink") == 0) then return card:getEffectiveId() end
		if card:isKindOf("AOE") and not (self:isWeak() and self:getCardsNum("Jink") == 0) then return card:getEffectiveId() end
	end
	self:sortByCardNeed(cards)
	return cards[#cards]:getEffectiveId()
end

function SmartAI:askForCardShow(requestor, reason)
	local func = sgs.ai_cardshow[reason]
	if func then
		return func(self, requestor)
	else
		return self.player:getRandomHandCard()
	end
end

function sgs.ai_cardneed.bignumber(to, card, self)
	if not self:willSkipPlayPhase(to) and self:getUseValue(card) < 6 then
		return card:getNumber() > 10
	end
end

function sgs.ai_cardneed.equip(to, card, self)
	if not self:willSkipPlayPhase(to) then
		return card:getTypeId() == sgs.Card_TypeEquip
	end
end

function sgs.ai_cardneed.weapon(to, card, self)
	if not self:willSkipPlayPhase(to) then
		return card:isKindOf("Weapon")
	end
end

function SmartAI:getEnemyNumBySeat(from, to, target, include_neutral)
	target = target or from
	local players = sgs.QList2Table(self.room:getAllPlayers())
	local to_seat = (to:getSeat() - from:getSeat()) % #players
	local enemynum = 0
	for _, p in ipairs(players) do
		if  (self:isEnemy(target, p) or (include_neutral and not self:isFriend(target, p))) and ((p:getSeat() - from:getSeat()) % #players) < to_seat then
			enemynum = enemynum + 1
		end
	end
	return enemynum
end

function SmartAI:getFriendNumBySeat(from, to)
	local players = sgs.QList2Table(self.room:getAllPlayers())
	local to_seat = (to:getSeat() - from:getSeat()) % #players
	local friendnum = 0
	for _, p in ipairs(players) do
		if self:isFriend(from, p) and ((p:getSeat() - from:getSeat()) % #players) < to_seat then
			friendnum = friendnum + 1
		end
	end
	return friendnum
end

function SmartAI:hasHeavySlashDamage(from, slash, to, return_value)
	from = from or self.room:getCurrent()
	to = to or self.player
	local is_friend = self:isFriend(from, to)
	if not from:hasSkill("jueqing") and self:hasSilverLionEffect(to) then
		if return_value then return 1 else return false end
	end
	local dmg = 1
	local fireSlash = slash and (slash:isKindOf("FireSlash")
								or (slash:objectName() == "slash" and (from:hasWeapon("fan") or (from:hasSkill("lihuo") and not self:isWeak(from)))))
	if (slash and slash:hasFlag("drank")) then
		dmg = dmg + 1
	elseif from:getMark("drank") > 0 then
		dmg = dmg + from:getMark("drank")
	end
	if not from:hasSkill("jueqing") then
		if from:hasFlag("nosluoyi") then dmg = dmg + 1 end
		if from:getMark("@luoyi") > 0 then dmg = dmg + 1 end
		if slash and from:hasSkill("jie") and slash:isRed() then dmg = dmg + 1 end
		if from:hasSkill("anjian") and not to:inMyAttackRange(from) then dmg = dmg + 1 end

		local guanyu = self.room:findPlayerBySkillName("zhongyi")
		if guanyu and guanyu:getPile("loyal"):length() > 0 and self:isFriend(guanyu, from) and not is_friend then dmg = dmg + 1 end

		if (to:hasArmorEffect("vine") or to:getMark("@gale") > 0) and fireSlash then dmg = dmg + 1 end
		if from:hasWeapon("guding_blade") and slash and to:isKongcheng() then dmg = dmg + 1 end
		if from:hasSkill("jieyuan") and to:getHp() >= from:getHp() and from:getHandcardNum() >= 3 and not is_friend then dmg = dmg + 1 end
		if to:hasSkill("jieyuan") and from:getHp() >= to:getHp()
			and (to:getHandcardNum() > 3 or getKnownCard(to, self.player, "red") > 0) and not is_friend then dmg = dmg - 1 end
	end
	if return_value then return dmg end
	return dmg > 1
end

function SmartAI:needKongcheng(player, need_keep)
	player = player or self.player
	if need_keep then
		return player:isKongcheng() and (player:hasSkill("kongcheng") or (player:hasSkill("zhiji") and player:getMark("zhiji") == 0))
	end
	if not self:hasLoseHandcardEffective(player) and not player:isKongcheng() then return true end
	if player:hasSkill("zhiji") and player:getMark("zhiji") == 0 then return true end
	if player:hasSkill("shude") and player:getPhase() == sgs.Player_Play then return true end
	return player:hasSkills(sgs.need_kongcheng)
end

function SmartAI:getLeastHandcardNum(player)
	player = player or self.player
	local least = 0
	if player:hasSkills("lianying|noslianying") and least < 1 then least = 1 end
	local jwfy = self.room:findPlayerBySkillName("shoucheng")
	if least < 1 and jwfy and self:isFriend(jwfy, player) then least = 1 end
	if player:hasSkill("shangshi") and least < math.min(2, player:getLostHp()) then least = math.min(2, player:getLostHp()) end
	if player:hasSkill("nosshangshi") and least < player:getLostHp() then least = player:getLostHp() end
	return least
end

function SmartAI:hasLoseHandcardEffective(player)
	player = player or self.player
	return player:getHandcardNum() > self:getLeastHandcardNum(player)
end

function SmartAI:getCardNeedPlayer(cards, friends_table, handcard)
	cards = cards or sgs.QList2Table(self.player:getHandcards())
	if handcard == nil then handcard = true end
	local cardtogivespecial = {}
	local specialnum = 0
	local keptslash = 0
	local friends = {}

	local cmpByAction = function(a, b)
		return a:getRoom():getFront(a, b):objectName() == a:objectName()
	end
	local cmpByNumber = function(a, b)
		return a:getNumber() > b:getNumber()
	end

	friends_table = friends_table or self.friends_noself
	for _, player in ipairs(friends_table) do
		local exclude = (handcard and self:needKongcheng(player)) or self:willSkipPlayPhase(player)
		if player:hasSkills("keji|qiaobian|shensu") or player:getHp() - player:getHandcardNum() >= 3
			or (player:isLord() and self:isWeak(player) and self:getEnemyNumBySeat(self.player, player) >= 1) then
			exclude = false
		end
		if self:objectiveLevel(player) <= -2 and not (handcard and hasManjuanEffect(player)) and not exclude then
			table.insert(friends, player)
		end
	end
	if self.role ~= "renegade" then
		local R_num = sgs.current_mode_players["renegade"]
		if R_num > 0 and #friends > R_num then
			local k = 0
			local temp_friends, new_friends = {}, {}
			for _, p in ipairs(friends) do
				if k < R_num and sgs.explicit_renegade and sgs.ai_role[p:objectName()] == "renegade" then
					k = k + 1
				else table.insert(temp_friends, p) end
			end
			if k == R_num then friends = temp_friends
			else
				local cmp = function(a, b)
					local ar_value, br_value = sgs.role_evaluation[a:objectName()]["renegade"], sgs.role_evaluation[b:objectName()]["renegade"]
					local al_value, bl_value = sgs.role_evaluation[a:objectName()]["loyalist"], sgs.role_evaluation[b:objectName()]["loyalist"]
					return (ar_value > br_value) or (ar_value == br_value and al_value > bl_value)
				end
				table.sort(temp_friends, cmp)
				for _, p in ipairs(temp_friends) do
					if k < R_num and sgs.role_evaluation[p:objectName()]["renegade"] > 0 then
						k = k + 1
					else table.insert(new_friends, p) end
				end
				friends = new_friends
			end
		end
	end

	-- special move between nos_liubei and xunyu and huatuo
	for _, player in ipairs(friends) do
		if player:hasSkill("jieming") or player:hasSkill("jijiu") then
			specialnum = specialnum + 1
		end
	end
	if specialnum > 1 and #cardtogivespecial == 0 and self.player:hasSkill("nosrende") and self.player:getPhase() == sgs.Player_Play then
		local xunyu = self.room:findPlayerBySkillName("jieming")
		local huatuo = self.room:findPlayerBySkillName("jijiu")
		local no_distance = self.slash_distance_limit
		local redcardnum = 0
		for _, acard in ipairs(cards) do
			if isCard("Slash", acard, self.player) then
				if self.player:canSlash(xunyu, nil, not no_distance) and self:slashIsEffective(acard, xunyu) then
					keptslash = keptslash + 1
				end
				if keptslash > 0 then
					table.insert(cardtogivespecial, acard)
				end
			elseif isCard("Duel", acard, self.player) then
				table.insert(cardtogivespecial, acard)
			end
		end
		for _, hcard in ipairs(cardtogivespecial) do
			if hcard:isRed() then redcardnum = redcardnum + 1 end
		end
		if self.player:getHandcardNum() > #cardtogivespecial and redcardnum > 0 then
			for _, hcard in ipairs(cardtogivespecial) do
				if hcard:isRed() then return hcard, huatuo end
				return hcard, xunyu
			end
		end
	end

	-- keep one jink
	local cardtogive = {}
	local keptjink = 0
	for _, acard in ipairs(cards) do
		if isCard("Jink", acard, self.player) and keptjink < 1 then
			keptjink = keptjink + 1
		else
			table.insert(cardtogive, acard)
		end
	end

	-- weak friend
	self:sort(friends, "defense")
	for _, friend in ipairs(friends) do
	if self:isWeak(friend) and friend:getHandcardNum() < 3 then
		for _, hcard in ipairs(cards) do
			if isCard("Peach", hcard, friend)
				or (isCard("Jink", hcard, friend) and self:getEnemyNumBySeat(self.player, friend) > 0)
				or isCard("Analeptic", hcard, friend) then
					return hcard, friend
				end
			end
		end
	end

	if (self.player:hasSkill("nosrende") and self.player:isWounded() and self.player:getMark("nosrende") < 2) then
		if (self.player:getHandcardNum() < 2 and self.player:getMark("nosrende") == 0) then return end

		if ((self.player:getHandcardNum() == 2 and self.player:getMark("nosrende") == 0) or
			(self.player:getHandcardNum() == 1 and self.player:getMark("nosrende") == 1)) and self:getOverflow() <= 0 then
			for _, enemy in ipairs(self.enemies) do
				if enemy:hasWeapon("guding_blade")
					and (enemy:canSlash(self.player)
					or self.player:hasSkills("shensu|jiangchi|tianyi|wushen|nosgongqi")) then
					return
				end
				if enemy:canSlash(self.player) and enemy:hasSkill("nosqianxi") and enemy:distanceTo(self.player) == 1 then return end
			end
		end
	end

	if (self.player:hasSkill("rende") and not self.player:hasUsed("RendeCard") and self.player:isWounded() and self.player:getMark("rende") < 2) then
		if (self.player:getHandcardNum() < 2 and self.player:getMark("rende") == 0) then return end

		if ((self.player:getHandcardNum() == 2 and self.player:getMark("rende") == 0) or
			(self.player:getHandcardNum() == 1 and self.player:getMark("rende") == 1)) and self:getOverflow() <= 0 then
			for _, enemy in ipairs(self.enemies) do
				if enemy:hasWeapon("guding_blade")
					and (enemy:canSlash(self.player)
					or self.player:hasSkills("shensu|jiangchi|tianyi|wushen|nosgongqi")) then
					return
				end
				if enemy:canSlash(self.player) and enemy:hasSkill("nosqianxi") and enemy:distanceTo(self.player) == 1 then return end
			end
		end
	end

	-- armor,DefensiveHorse
	for _, friend in ipairs(friends) do
		if friend:getHp() <= 2 and friend:faceUp() then
			for _, hcard in ipairs(cards) do
				if (hcard:isKindOf("Armor") and not friend:getArmor() and not friend:hasSkills("yizhong|bazhen|bossmanjia"))
					or (hcard:isKindOf("DefensiveHorse") and not friend:getDefensiveHorse()) then
					return hcard, friend
				end
			end
		end
	end

	-- jijiu, jieyin
	self:sortByUseValue(cards, true)
	for _, friend in ipairs(friends) do
		if friend:hasSkills("jijiu|jieyin") and friend:getHandcardNum() < 4 then
			for _, hcard in ipairs(cards) do
				if (hcard:isRed() and friend:hasSkill("jijiu")) or friend:hasSkill("jieyin") then
					return hcard, friend
				end
			end
		end
	end

	--Crossbow
	for _, friend in ipairs(friends) do
		if friend:hasSkills("longdan|wusheng|keji") and not friend:hasSkill("paoxiao") and friend:getHandcardNum() >= 2 then
			for _, hcard in ipairs(cards) do
				if hcard:isKindOf("Crossbow") then
					return hcard, friend
				end
			end
		end
	end
	for _, friend in ipairs(friends) do
		if getKnownCard(friend, self.player, "Crossbow") > 0 then
			for _, p in sgs.qlist(self.room:getOtherPlayers(friend)) do
				if self:isEnemy(p) and sgs.isGoodTarget(p, self.enemies, self) and friend:distanceTo(p) <= 1 then
					for _, hcard in ipairs(cards) do
						if isCard("Slash", hcard, friend) then
							return hcard, friend
						end
					end
				end
			end
		end
	end

	table.sort(friends, cmpByAction)
	for _, friend in ipairs(friends) do
		if friend:faceUp() then
			local can_slash = false
			for _, p in sgs.qlist(self.room:getOtherPlayers(friend)) do
				if self:isEnemy(p) and sgs.isGoodTarget(p, self.enemies, self) and friend:inMyAttackRange(p) then
					can_slash = true
					break
				end
			end

			if not can_slash then
				for _, p in sgs.qlist(self.room:getOtherPlayers(friend)) do
					if self:isEnemy(p) and sgs.isGoodTarget(p, self.enemies, self) and friend:inMyAttackRange(p) then
						for _, hcard in ipairs(cardtogive) do
							if hcard:isKindOf("Weapon")
								and friend:distanceTo(p) <= friend:getAttackRange() + (sgs.weapon_range[hcard:getClassName()] or 0) and not friend:getWeapon() then
								return hcard, friend
							end
							if hcard:isKindOf("OffensiveHorse")
								and friend:distanceTo(p) <= friend:getAttackRange() + 1 and not friend:getOffensiveHorse() then
								return hcard, friend
							end
						end
					end
				end
			end
		end
	end

	table.sort(cardtogive, cmpByNumber)
	for _, friend in ipairs(friends) do
		if not self:needKongcheng(friend) and friend:faceUp() then
			for _, hcard in ipairs(cardtogive) do
				for _, askill in ipairs(sgs.getPlayerSkillList(friend)) do
					local callback = sgs.ai_cardneed[askill:objectName()]
					if type(callback) == "function" and callback(friend, hcard, self) then
						return hcard, friend
					end
				end
			end
		end
	end

	-- slash
	if self.role == "lord" and self.player:hasLordSkill("jijiang") then
		for _, friend in ipairs(friends) do
			if friend:getKingdom() == "shu" and friend:getHandcardNum() < 3 then
				for _, hcard in ipairs(cardtogive) do
					if isCard("Slash", hcard, friend) then
						return hcard, friend
					end
				end
			end
		end
	end

	-- kongcheng
	self:sort(self.enemies, "defense")
	if #self.enemies > 0 and self.enemies[1]:isKongcheng() and self.enemies[1]:hasSkill("kongcheng")
		and not hasManjuanEffect(self.enemies[1]) then
		for _, acard in ipairs(cardtogive) do
			if acard:isKindOf("Lightning") or acard:isKindOf("Collateral") or (acard:isKindOf("Slash") and self.player:getPhase() == sgs.Player_Play)
				or acard:isKindOf("OffensiveHorse") or acard:isKindOf("Weapon") then
				return acard, self.enemies[1]
			end
		end
	end

	self:sort(friends, "defense")
	for _, hcard in ipairs(cardtogive) do
		for _, friend in ipairs(friends) do
			if not self:needKongcheng(friend) and not friend:hasSkill("manjuan") and not self:willSkipPlayPhase(friend)
					and friend:hasSkills(sgs.priority_skill) then
				if (self:getOverflow() > 0 or self.player:getHandcardNum() > 3) and friend:getHandcardNum() <= 3 then
					return hcard, friend
				end
			end
		end
	end

	local shoulduse = self.player:isWounded()
						and ((self.player:hasSkill("rende") and not self.player:hasUsed("RendeCard") and self.player:getMark("rende") < 2)
							or (self.player:hasSkill("nosrende") and self.player:getMark("nosrende") < 2))

	if #cardtogive == 0 and shoulduse then cardtogive = cards end

	self:sort(friends, "handcard")
	for _, hcard in ipairs(cardtogive) do
		for _, friend in ipairs(friends) do
			if not self:needKongcheng(friend, true) and not hasManjuanEffect(friend) then
				if friend:getHandcardNum() <= 3 and (self:getOverflow() > 0 or self.player:getHandcardNum() > 3 or shouldUse) then
					return hcard, friend
				end
			end
		end
	end

	for _, hcard in ipairs(cardtogive) do
		for _, friend in ipairs(friends) do
			if not self:needKongcheng(friend) and not hasManjuanEffect(friend) then
				if friend:getHandcardNum() <= 3
					and (self:getOverflow() > 0 or self.player:getHandcardNum() > 3 or shouldUse) then
					return hcard, friend
				end
			end
		end
	end

	for _, hcard in ipairs(cardtogive) do
		for _, friend in ipairs(friends) do
			if (not self:needKongcheng(friend) or #friends == 1) and not hasManjuanEffect(friend) then
				if self:getOverflow() > 0 or self.player:getHandcardNum() > 3 or shouldUse then
					return hcard, friend
				end
			end
		end
	end

	if #cards > 0 and shouldUse then
		local need_rende = (sgs.current_mode_players["rebel"] == 0 and sgs.current_mode_players["loyalist"] > 0 and self.player:isWounded())
							or (sgs.current_mode_players["rebel"] > 0 and sgs.current_mode_players["renegade"] > 0
								and sgs.current_mode_players["loyalist"] == 0 and self:isWeak())
		if need_rende then
			local players = sgs.QList2Table(self.room:getOtherPlayers(self.player))
			self:sort(players, "defense")
			self:sortByUseValue(cards, true)
			return cards[1], players[1]
		end
	end
end

function SmartAI:askForYiji(card_ids, reason)
	if reason then
		local callback = sgs.ai_skill_askforyiji[string.gsub(reason, "%-", "_")]
		if type(callback) == "function" then
			local target, cardid = callback(self, card_ids)
			if target and cardid then return target, cardid end
		end
	end
	return nil, -1
end

sgs.ai_choicemade_filter.Yiji.general = function(self, from, promptlist)
	if from:objectName() == promptlist[4] then return end
	local to = findPlayerByObjectName(from:getRoom(), promptlist[4])
	if not to then return end
	local intention = -70
	if hasManjuanEffect(to) then
		intention = 0
	elseif to:hasSkill("kongcheng") and to:isKongcheng() then
		intention = 30
	end
	sgs.updateIntention(from, to, intention)
end

function SmartAI:askForPindian(requestor, reason)
	local passive = { "mizhao", "lieren" }
	if self.player:objectName() == requestor:objectName() and not table.contains(passive, reason) then
		if self[reason .. "_card"] then
			return sgs.Sanguosha:getCard(self[reason .. "_card"])
		else
			self.room:writeToConsole("Pindian card for " .. reason .. " not found!!")
			return self:getMaxCard(self.player):getId()
		end
	end
	local cards = sgs.QList2Table(self.player:getHandcards())
	local compare_func = function(a, b)
		return a:getNumber() < b:getNumber()
	end
	table.sort(cards, compare_func)
	local maxcard, mincard, minusecard
	for _, card in ipairs(cards) do
		if self:getUseValue(card) < 6 then mincard = card break end
	end
	for _, card in ipairs(sgs.reverse(cards)) do
		if self:getUseValue(card) < 6 then maxcard = card break end
	end
	self:sortByUseValue(cards, true)
	minusecard = cards[1]
	maxcard = maxcard or minusecard
	mincard = mincard or minusecard

	local sameclass, c1 = true
	for _, c2 in ipairs(cards) do
		if not c1 then c1 = c2
		elseif c1:getClassName() ~= c2:getClassName() then sameclass = false end
	end
	if sameclass then
		if self:isFriend(requestor) and self.player:objectName() ~= requestor:objectName() then return self:getMinCard()
		else return self:getMaxCard() end
	end

	local callback = sgs.ai_skill_pindian[reason]
	if type(callback) == "function" then
		local ret = callback(minusecard, self, requestor, maxcard, mincard)
		if ret then return ret end
	end
	if self:isFriend(requestor) then return mincard else return maxcard end
end

sgs.ai_skill_playerchosen.damage = function(self, targets)
	local targetlist = sgs.QList2Table(targets)
	self:sort(targetlist, "hp")
	for _, target in ipairs(targetlist) do
		if self:isEnemy(target) then return target end
	end
	return targetlist[#targetlist]
end

function SmartAI:askForPlayerChosen(targets, reason)
	local playerchosen = sgs.ai_skill_playerchosen[string.gsub(reason, "%-", "_")]
	local target = nil
	if type(playerchosen) == "function" then
		target = playerchosen(self, targets)
		return target
	end
	local r = math.random(0, targets:length() - 1)
	return targets:at(r)
end

function SmartAI:ableToSave(saver, dying)
	local current = self.room:getCurrent()
	if current and current:getPhase() ~= sgs.Player_NotActive and current:hasSkill("wansha")
		and current:objectName() ~= saver:objectName() and current:objectName() ~= dying:objectName()
		and not saver:hasSkills("jiuzhu|chunlao|nosjiefan|nosrenxin") then
		return false
	end
	local peach = sgs.cloneCard("peach", sgs.Card_NoSuitRed, 0)
	if saver:isCardLimited(peach, sgs.Card_MethodUse, true) and not saver:hasSkills("jiuzhu|chunlao|nosjiefan|nosrenxin") then return false end
	return true
end

function SmartAI:willUsePeachTo(dying)
	local card_str
	local forbid = sgs.cloneCard("peach")
	if self.player:isLocked(forbid) or dying:isLocked(forbid) then return "." end
	if self.player:objectName() == dying:objectName() and not self:needDeath(dying) then
		local analeptic = sgs.cloneCard("analeptic")
		if not self.player:isLocked(analeptic) and self:getCardId("Analeptic") then return self:getCardId("Analeptic") end
		if self:getCardId("Peach") then return self:getCardId("Peach") end
	end
	if not sgs.GetConfig("EnableHegemony", false) and self.role == "renegade" and self.room:getMode() ~= "couple"
		and not (dying:isLord() or dying:objectName() == self.player:objectName())
		and (sgs.current_mode_players["loyalist"] + 1 == sgs.current_mode_players["rebel"]
				or sgs.current_mode_players["loyalist"] == sgs.current_mode_players["rebel"]
				or self.room:getCurrent():objectName() == self.player:objectName()) then
		return "."
	end

	if self.player:isLord() and dying:objectName() ~= self.player:objectName() and self:getEnemyNumBySeat(self.room:getCurrent(), self.player, self.player) > 0
		and self:getCardsNum("Peach") == 1 and self:isWeak() and self.player:getHp() == 1 then return "." end

	if sgs.ai_role[dying:objectName()] == "renegade" and dying:objectName() ~= self.player:objectName() then
		if self.role == "loyalist" or self.role == "lord" then
			if sgs.current_mode_players["loyalist"] + sgs.current_mode_players["renegade"] >= sgs.current_mode_players["rebel"] then return "."
			elseif sgs.gameProcess(self.room) == "loyalist" or sgs.gameProcess(self.room) == "loyalish" or sgs.gameProcess(self.room) == "dilemma" then return "."
			end
		elseif self.role == "rebel" then
			if sgs.current_mode_players["rebel"] + sgs.current_mode_players["renegade"] - 1 >= sgs.current_mode_players["loyalist"] + 1 then return "."
			elseif sgs.gameProcess(self.room) == "rebelish" or sgs.gameProcess(self.room) == "rebel" or sgs.gameProcess(self.room) == "dilemma" then return "."
			end
		elseif self.role == "renegade" then
			return "."
		end
	end

	if self:isFriend(dying) then
		if self:needDeath(dying) then return "." end

		local lords = {}
		for _, p in sgs.qlist(self.room:getAlivePlayers()) do
			if p:getRole() == "lord" or ((self.room:getMode() == "06_3v3" or self.room:getMode() == "06_XMode") and p:getRole() == "renegade") then
				table.insert(lords, p)
			end
		end
		for _, lord in ipairs(lords) do
			if not sgs.GetConfig("EnableHegemony", false) and lord and self.player:objectName() ~= dying:objectName() and dying:objectName() ~= lord:objectName()
				and (self:isFriend(lord) or (not sgs.isRolePredictable() and (self.role == "loyalist" or (self.role == "renegade" and self.room:alivePlayerCount() > 2))))
				and ((sgs.lordNeedPeach and self:getCardsNum("Peach") <= sgs.lordNeedPeach)
					or (lord:hasFlag("AIGlobal_LordInDangerSA") and getCardsNum("Slash", lord, self.player) <= 1 and #self:getCards("Peach") < 2)
					or (lord:hasFlag("AIGlobal_LordInDangerAA") and getCardsNum("Jink", lord, self.player) <= 1 and #self:getCards("Peach") < 2)) then
				return "."
			end
		end

		if sgs.turncount > 1 and not dying:isLord() and dying:objectName() ~= self.player:objectName() then
			local possible_friend = 0
			for _, friend in ipairs(self.friends_noself) do
				if (getKnownNum(friend) == friend:getHandcardNum() and getCardsNum("Peach", friend, self.player) == 0)
					or (self:playerGetRound(friend) < self:playerGetRound(self.player)) then
				elseif sgs.card_lack[friend:objectName()]["Peach"] == 1 then
				elseif not self:ableToSave(friend, dying) then
				elseif friend:getHandcardNum() > 0 or getCardsNum("Peach", friend, self.player) > 0 then
					possible_friend = possible_friend + 1
				end
			end
			if possible_friend == 0 and self:getCardsNum("Peach") < 1 - dying:getHp() then
				return "."
			end
		end

		local lord = self.room:getLord()
		local CP = self.room:getCurrent()
		if CP and lord and dying:objectName() ~= lord:objectName() and dying:objectName() ~= self.player:objectName() and lord:getHp() == 1
			and self:isFriend(lord) and self:isEnemy(CP) and getCardsNum("Peach", lord, self.player) == 0 and getCardsNum("Analeptic", lord, self.player) == 0 and #self.friends_noself <= 2
			and CP:canSlash(lord) and self:slashIsAvailable(CP)
			and self:damageIsEffective(CP, nil, lord) and self:getCardsNum("Peach") <= self:getEnemyNumBySeat(CP, lord, self.player) + 1 then
			return "."
		end

		local buqu = dying:getPile("nosbuqu")
		local weaklord = 0
		if not buqu:isEmpty() then
			local same = false
			for i, card_id in sgs.qlist(buqu) do
				for j, card_id2 in sgs.qlist(buqu) do
					if i ~= j and sgs.Sanguosha:getCard(card_id):getNumber() == sgs.Sanguosha:getCard(card_id2):getNumber() then
						same = true
						break
					end
				end
			end
			if not same then return "." end
		end
		if self.player:objectName() == dying:objectName() then
			card_str = self:getCardId("Analeptic")
			if not card_str then card_str = self:getCardId("Peach") end
		elseif dying:isLord() then
			card_str = self:getCardId("Peach")
		elseif self:doNotSave(dying) then return "."
		else
			for _, friend in ipairs(self.friends_noself) do
				if friend:getHp() == 1 and friend:isLord() and not friend:hasSkill("buqu") then weaklord = weaklord + 1 end
			end
			for _, enemy in ipairs(self.enemies) do
				if enemy:getHp() == 1 and enemy:isLord() and not enemy:hasSkill("buqu") and self.player:getRole() == "renegade" then weaklord = weaklord + 1 end
			end
			if weaklord < 1 or self:getAllPeachNum() > 1 then
				card_str = self:getCardId("Peach")
			end
		end
	else
		if not sgs.GetConfig("EnableHegemony", false) and self.role == "renegade" and self.room:getMode() ~= "couple"
			and dying:isLord() and self.room:alivePlayerCount() > 2 then
			card_str = self:getCardId("Peach")
		end
		if dying:hasSkill("wuhun") then
			local lord = self.room:getLord()
			if not lord or self:isEnemy(lord) then return "." end
			local should = (self.role == "renegade" and self.room:alivePlayerCount() > 2)
							or ((self.role == "lord" or self.role == "loyalist") and sgs.current_mode_players["rebel"] + sgs.current_mode_players["renegade"] > 1)
			if not should then return nil end
			local revengeTargets = self:getWuhunRevengeTargets()
			if table.contains(revengeTargets, lord) then
				local finalRetrial, wizard = self:getFinalRetrial(self.room:getCurrent(), "wuhun")
				if finalRetrial == 0 or finalRetrial == 2 then
					card_str = self:getCardId("Peach")
				elseif finalRetrial == 1 then
					local flag = wizard:hasSkill("huanshi") and "he" or "h"
					if getKnownCard(wizard, self.player, "Peach|GodSalvation", false, flag) > 0 then return "." end
					card_str = self:getCardId("Peach")
				end
			end
		end
	end
	if not card_str then return nil end
	return card_str
end

function SmartAI:askForSinglePeach(dying)
	local card_str = self:willUsePeachTo(dying)
	return card_str or "."
end

function SmartAI:getTurnUse()
	local cards = self.player:getHandcards()
	for _, id in sgs.qlist(self.player:getPile("wooden_ox")) do
		cards:prepend(sgs.Sanguosha:getCard(id))
	end
	cards = sgs.QList2Table(cards)

	local turnUse = {}
	local slash = sgs.cloneCard("slash")
	local slashAvail = 1 + sgs.Sanguosha:correctCardTarget(sgs.TargetModSkill_Residue, self.player, slash)
	self.predictedRange = self.player:getAttackRange()
	self.slash_distance_limit = (1 + sgs.Sanguosha:correctCardTarget(sgs.TargetModSkill_DistanceLimit, self.player, slash) > 50)

	self.weaponUsed = false
	self:fillSkillCards(cards)
	self:sortByUseValue(cards)

	if self.player:hasWeapon("crossbow") or #self.player:property("extra_slash_specific_assignee"):toString():split("+") > 0 then
		slashAvail = 100
	elseif self.player:hasWeapon("vscrossbow") then
		slashAvail = slashAvail + 3
	end

	for _, card in ipairs(cards) do
		local dummy_use = { isDummy = true }

		local type = card:getTypeId()
		self["use" .. sgs.ai_type_name[type + 1] .. "Card"](self, card, dummy_use)

		if dummy_use.card then
			if dummy_use.card:isKindOf("Slash") then
				if slashAvail > 0 then
					slashAvail = slashAvail - 1
					table.insert(turnUse, dummy_use.card)
				elseif dummy_use.card:hasFlag("AIGlobal_KillOff") then table.insert(turnUse, dummy_use.card) end
			else
				if self.player:hasFlag("InfinityAttackRange") or self.player:getMark("InfinityAttackRange") > 0 then
					self.predictedRange = 10000
				elseif dummy_use.card:isKindOf("Weapon") then
					self.predictedRange = sgs.weapon_range[card:getClassName()]
					self.weaponUsed = true
				else
					self.predictedRange = 1
				end
				if dummy_use.card:objectName() == "crossbow" then slashAvail = 100 end
				if dummy_use.card:objectName() == "vscrossbow" then slashAvail = slashAvail + 3 end
				table.insert(turnUse, dummy_use.card)
			end
		end
	end
	self.slashAvail = slashAvail

	return turnUse
end

function SmartAI:activate(use)
	self:updatePlayers()
	self:assignKeep(true)
	self.toUse = self:getTurnUse()
	self:sortByDynamicUsePriority(self.toUse)
	for _, card in ipairs(self.toUse) do
		if not self.player:isCardLimited(card, card:getHandlingMethod())
			or (card:canRecast() and not self.player:isCardLimited(card, sgs.Card_MethodRecast)) then
			local type = card:getTypeId()
			self["use" .. sgs.ai_type_name[type + 1] .. "Card"](self, card, use)

			if use:isValid(nil) then
				self.toUse = nil
				return
			end
		end
	end
	self.toUse = nil
end

function SmartAI:getOverflow(player)
	player = player or self.player
	local kingdom_num = 0
	if player:hasSkill("yongsi") and player:getPhase() <= sgs.Player_Discard and not (player:hasSkill("keji") and not player:hasFlag("KejiSlashInPlayPhase")) then
		local kingdoms = {}
		for _, ap in sgs.qlist(self.room:getAlivePlayers()) do
			if not kingdoms[ap:getKingdom()] then
				kingdoms[ap:getKingdom()] = true
				kingdom_num = kingdom_num + 1
			end
		end
	end

	if kingdom_num > 0 then
		if player:getCardCount() <= kingdom_num then return player:getHandcardNum() end
		local MaxHandCards = math.min(player:getHp(), player:getCardCount() - kingdom_num)
		return player:getHandcardNum() - MaxHandCards
	end
	return player:getHandcardNum() - player:getHp()
end

function SmartAI:isWeak(player)
	player = player or self.player
	local hcard = player:getHandcardNum()
	if hasBuquEffect(player) then return false end
	if player:hasSkill("longhun") and player:getCards("he"):length() > 2 then return false end
	if player:hasSkill("hunzi") and player:getMark("hunzi") == 0 and player:getHp() > 1 then return false end
	if (player:getHp() <= 2 and hcard <= 2) or player:getHp() <= 1 then return true end
	return false
end

function SmartAI:useCardByClassName(card, use)
	if not card then global_room:writeToConsole(debug.traceback()) return end
	local class_name = card:getClassName()
	local use_func = self["useCard" .. class_name]

	if use_func then
		use_func(self, card, use)
	end
end

function SmartAI:hasWizard(players, onlyharm)
	local skill
	if onlyharm then skill = sgs.wizard_harm_skill else skill = sgs.wizard_skill end
	for _, player in ipairs(players) do
		if player:hasSkills(skill) then
			return true
		end
	end
end

function SmartAI:canRetrial(player, to_retrial, reason)
	player = player or self.player
	to_retrial = to_retrial or self.player
	if player:hasSkill("guidao") and not (reason and reason == "wuhun") then
		local blackequipnum = 0
		for _, equip in sgs.qlist(player:getEquips()) do
			if equip:isBlack() then blackequipnum = blackequipnum + 1 end
		end
		local h_num = (player:getMark("yijue") > 0) and 0 or player:getHandcardNum()
		if blackequipnum + h_num then return true end
	end
	if player:hasSkill("guicai") and not player:getEquips():isEmpty() then return true end
	if player:getMark("yijue") == 0 then return false end
	if player:hasSkills("guicai|nosguicai") and player:getHandcardNum() > 0 then return true end
	if player:hasSkill("huanshi") and not player:isNude()
		and (not string.startsWith(self.room:getMode(), "06_") or self:isFriend(to_retrial, player)) then return true end
	if player:hasSkill("jilve") and (player:getHandcardNum() > 0 and player:getMark("@bear") > 0) then return true end
end

function SmartAI:getFinalRetrial(player, reason)
	local maxfriendseat = -1
	local maxenemyseat = -1
	local tmpfriend
	local tmpenemy
	local wizardf, wizarde
	player = player or self.room:getCurrent()
	for _, aplayer in ipairs(self.friends) do
		if aplayer:hasSkills(sgs.wizard_harm_skill .. "|huanshi") and self:canRetrial(aplayer, player, reason) then
			tmpfriend = (aplayer:getSeat() - player:getSeat()) % (global_room:alivePlayerCount())
			if tmpfriend > maxfriendseat then
				maxfriendseat = tmpfriend
				wizardf = aplayer
			end
		end
	end
	for _, aplayer in ipairs(self.enemies) do
		if aplayer:hasSkills(sgs.wizard_harm_skill .. "|huanshi") and self:canRetrial(aplayer, player, reason) then
			tmpenemy = (aplayer:getSeat() - player:getSeat()) % (global_room:alivePlayerCount())
			if tmpenemy > maxenemyseat then
				maxenemyseat = tmpenemy
				wizarde = aplayer
			end
		end
	end
	if maxfriendseat == -1 and maxenemyseat == -1 then return 0, nil
	elseif maxfriendseat > maxenemyseat then return 1, wizardf
	else return 2, wizarde end
end

--- Determine that the current judge is worthy retrial
-- @param judge The JudgeStruct that contains the judge information
-- @return True if it is needed to retrial
function SmartAI:needRetrial(judge)
	local reason = judge.reason
	local lord = self.room:getLord()
	local who = judge.who
	local good = judge:isGood()
	if reason == "lightning" then
		if who:hasSkills("wuyan|hongyan") then return false end

		if lord and (who:isLord() or (who:isChained() and lord:isChained())) and self:objectiveLevel(lord) <= 3 then
			if self:hasSilverLionEffect(lord) and lord:getHp() >= 2 and self:isGoodChainTarget(lord, self.player, sgs.DamageStruct_Thunder) then return false end
			return self:damageIsEffective(lord, sgs.DamageStruct_Thunder) and not good
		end

		if self:isFriend(who) then
			if who:isChained() and self:isGoodChainTarget(who, self.player, sgs.DamageStruct_Thunder, 3) then return false end
		else
			if who:isChained() and not self:isGoodChainTarget(who, self.player, sgs.DamageStruct_Thunder, 3) then return good end
		end
	end

	if reason == "indulgence" then
		if who:isSkipped(sgs.Player_Draw) and who:isKongcheng() then
			if (who:hasSkill("shenfen") and who:getMark("@wrath") >= 6)
				or (who:hasSkills("noskurou|kurou+zhaxiang") and who:getHp() >= 3)
				or (who:hasSkill("jixi") and who:getPile("field"):length() > 2)
				or (who:hasSkill("lihun") and self:isLihunTarget(self:getEnemies(who), 0))
				or (who:hasSkill("xiongyi") and who:getMark("@arise") > 0) then
				if self:isFriend(who) then
					return not good
				else
					return good
				end
			end
		end
		if self:isFriend(who) then
			if who:getHp() - who:getHandcardNum() >= 2 and self:getOverflow() <= 0 then return false end
			if who:hasSkill("nostuxi") and who:getHp() > 2 and self:getOverflow() <= 0 then return false end
			if who:hasSkill("tuxi") and who:getHp() > 2 and self:getOverflow() <= 0 then
				local count = 0
				for _, enemy in ipairs(#self:getEnemies(who)) do
					if enemy:getHandcardNum() >= who:getHandcardNum() then count = count + 1 end
					if count == 2 then return false end
				end
			end
			return not good
		else
			return good
		end
	end

	if reason == "supply_shortage" then
		if self:isFriend(who) then
			if who:hasSkill("tiandu") or (who:hasSkill("guidao") and self:hasSuit("club", true, who)) then return false end
			return not good
		else
			return good
		end
	end

	if reason == "luoshen" then
		if self:isFriend(who) then
			if who:getHandcardNum() > 30 then return false end
			if self:hasCrossbowEffect(who) or getKnownCard(who, self.player, "Crossbow", false) > 0 then return not judge:isGood() end
			if self:getOverflow(who) > 1 and self.player:getHandcardNum() < 3 then return false end
			return not good
		else
			return good
		end
	end

	if reason == "nostieji" then
		local target
		for _, p in sgs.qlist(self.room:getAlivePlayers()) do
			if p:hasFlag("NosTiejiTarget") then
				target = p
				break
			end
		end
		if target and target:isKongcheng() and not self:hasEightDiagramEffect(target) and not self.player:hasSkill("guidao") then return false end
	end

	if reason == "tuntian" then
		if not who:hasSkill("jixi") then return false end
	end

	if reason == "beige" then return true end

	if self:isFriend(who) then
		return not good
	elseif self:isEnemy(who) then
		return good
	else
		return false
	end
end

function SmartAI:dontRespondPeachInJudge(judge)
	local peach_num = self:getCardsNum("Peach")
	if peach_num == 0 then return false end
	if self:willSkipPlayPhase() and self:getCardsNum("Peach") > self.player:getMaxCards() then return false end

	if peach_num <= self.player:getLostHp() then
		return true
	else
		for _, friend in ipairs(self.friends) do
			if self:isWeak(friend) then return true end
		end
	end

	if not judge then self.room:writeToConsole(debug.traceback()) end

	if judge.reason == "tuntian" and judge.who:getMark("zaoxian") == 0 and judge.who:getPile("field"):length() < 2 then return true
	elseif (judge.reason == "eight_diagram" or judge.reason == "bazhen") and self:isFriend(judge.who) and not self:isWeak(judge.who) then return true
	elseif judge.reason == "nosmiji" and judge.who:getLostHp() == 1 then return true
	elseif judge.reason == "nostieji" then
		local target
		for _, p in sgs.qlist(self.room:getAlivePlayers()) do
			if p:hasFlag("NosTiejiTarget") then
				target = p
				break
			end
		end
		if target then return not (self:isEnemy(target) and self:isWeak(target)) else return true end
	elseif judge.reason == "qianxi" then return true
	end

	return false
end

function SmartAI:getRetrialCardId(cards, judge, self_card)
	if self_card == nil then self_card = true end
	local can_use = {}
	local reason = judge.reason
	local who = judge.who

	local other_suit, hasSpade = {}
	for _, card in ipairs(cards) do
		local card_x = sgs.Sanguosha:getEngineCard(card:getEffectiveId())
		if who:hasSkill("hongyan") and card_x:getSuit() == sgs.Card_Spade then
			card_x = sgs.cloneCard(card_x:objectName(), sgs.Card_Heart, card:getNumber())
		end
		if reason == "beige" and not isCard("Peach", card_x, self.player) then
			local damage = self.room:getTag("CurrentDamageStruct"):toDamage()
			if damage.from then
				if self:isFriend(damage.from) then
					if not self:toTurnOver(damage.from, 0) and judge.card:getSuit() ~= sgs.Card_Spade and card_x:getSuit() == sgs.Card_Spade then
						table.insert(can_use, card)
						hasSpade = true
					elseif (not self_card or self:getOverflow() > 0) and judge.card:getSuit() ~= card_x:getSuit() then
						local retr = true
						if (judge.card:getSuit() == sgs.Card_Heart and who:isWounded() and self:isFriend(who))
							or (judge.card:getSuit() == sgs.Card_Diamond and self:isEnemy(who) and hasManjuanEffect(who))
							or (judge.card:getSuit() == sgs.Card_Club and self:needToThrowArmor(damage.from)) then
							retr = false
						end
						if retr
							and ((self:isFriend(who) and card_x:getSuit() == sgs.Card_Heart and who:isWounded())
								or (card_x:getSuit() == sgs.Card_Diamond and self:isEnemy(who) and hasManjuanEffect(who))
								or (card_x:getSuit() == sgs.Card_Diamond and self:isFriend(who) and not hasManjuanEffect(who))
								or (card_x:getSuit() == sgs.Card_Club and (self:needToThrowArmor(damage.from) or damage.from:isNude())))
								or (judge.card:getSuit() == sgs.Card_Spade and self:toTurnOver(damage.from, 0)) then
							table.insert(other_suit, card)
						end
					end
				else
					if not self:toTurnOver(damage.from, 0) and card_x:getSuit() ~= sgs.Card_Spade and judge.card:getSuit() == sgs.Card_Spade then
						table.insert(can_use, card)
					end
				end
			end
		elseif self:isFriend(who) and judge:isGood(card_x)
				and not (self_card and (self:getFinalRetrial() == 2 or self:dontRespondPeachInJudge(judge)) and isCard("Peach", card_x, self.player)) then
			table.insert(can_use, card)
		elseif self:isEnemy(who) and not judge:isGood(card_x)
				and not (self_card and (self:getFinalRetrial() == 2 or self:dontRespondPeachInJudge(judge)) and isCard("Peach", card_x, self.player)) then
			table.insert(can_use, card)
		end
	end
	if not hasSpade and #other_suit > 0 then table.insertTable(can_use, other_suit) end

	if next(can_use) then
		if self:needToThrowArmor() then
			for _, c in ipairs(can_use) do
				if c:getEffectiveId() == self.player:getArmor():getEffectiveId() then return c:getEffectiveId() end
			end
		end
		self:sortByKeepValue(can_use)
		return can_use[1]:getEffectiveId()
	else
		return -1
	end
end

function SmartAI:damageIsEffective(player, nature, source)
	player = player or self.player
	source = source or self.room:getCurrent()
	nature = nature or sgs.DamageStruct_Normal

	if source:hasSkill("jueqing") then return true end

	if player:getMark("@fenyong") > 0 then return false end
	if player:getMark("@fog") > 0 and nature ~= sgs.DamageStruct_Thunder then return false end
	if player:hasSkills("shixin|jgyuhuo") and nature == sgs.DamageStruct_Fire then return false end
	local equipsToDec = source:objectName() == self.player:objectName() and self.equipsToDec or 0
	if player:hasSkill("mingshi") and source:getEquips():length() - equipsToDec <= math.min(2, player:getEquips():length()) then return false end
	if player:hasSkill("yuce") and not player:isKongcheng() and player:getHp() > 1 then
		if self:isFriend(player, source) then return false
		else
			if source:objectName() ~= self.player:objectName() then
				if source:getHandcardNum() <= 2 then return false end
			else
				if (getKnownCard(player, self.player, "TrickCard|EquipCard", false, "h") < player:getHandcardNum()
					and self:getCardsNum("TrickCard") + self:getCardsNum("EquipCard", "h") < 1)
					or self:getCardsNum("BasicCard") < 2 then
					return false
				end
			end
		end
	end

	if player:hasLordSkill("shichou") and player:getMark("xhate") == 1 then
		for _, p in sgs.qlist(self.room:getOtherPlayers(player)) do
			if p:getMark("hate_" .. player:objectName()) > 0 and p:getMark("@hate_to") > 0 then return self:damageIsEffective(p, nature, source) end
		end
	end

	return true
end

function SmartAI:getDamagedEffects(player, damage_from, isSlash)
	local attacker = damage_from or self.room:getCurrent()

	if attacker:hasSkill("jueqing") then return false end
	if isSlash then
		if attacker:hasSkill("nosqianxi") and attacker:distanceTo(player) == 1 and not self:isFriend(player, attacker) then
			return false
		end
		if attacker:hasWeapon("ice_sword") and player:getCards("he"):length() > 1 and not self:isFriend(player, attacker) then
			return false
		end
	end
	if player:hasLordSkill("shichou") then
		return sgs.ai_need_damaged.shichou(self, attacker, player) == 1
	end

	if attacker:objectName() ~= player:objectName() and self:hasHeavySlashDamage(attacker, nil, player) then return false end

	if sgs.isGoodHp(player) then
		for _, askill in ipairs(sgs.getPlayerSkillList(player)) do
			local callback = sgs.ai_need_damaged[askill:objectName()]
			if type(callback) == "function" and callback(self, attacker, player) then return true end
		end
	end
	return false
end

local function prohibitUseDirectly(card, player)
	if player:isCardLimited(card, card:getHandlingMethod()) then return true end
	if card:isKindOf("Peach") and player:getMark("Global_PreventPeach") > 0 then return true end
	return false
end

function sgs.getPlayerSkillList(player)
	local skills = sgs.QList2Table(player:getVisibleSkillList(true))
	if player:hasSkill("weidi") and not player:isLord() then
		local lord = player:getRoom():getLord()
		if lord then
			for _, skill in sgs.qlist(lord:getVisibleSkillList()) do
				if skill:isLordSkill() then table.insert(skills, skill) end
			end
		end
	end
	return skills
end

function sgs.getCardPlace(room, card)
	local id = card:getEffectiveId()
	local card_place = room:getCardPlace(id)
	if card_place == sgs.Player_PlaceSpecial then
		local player = room:getCardOwner(id)
		if player then
			local pile_name = player:getPileName(id)
			if pile_name == "wooden_ox" then return sgs.Player_PlaceHand end
		end
	end
	return card_place
end

local function cardsViewValuable(self, class_name, player)
	for _, skill in ipairs(sgs.getPlayerSkillList(player)) do
		local askill = skill:objectName()
		if player:hasSkill(askill) or player:hasLordSkill(askill) then
			local callback = sgs.ai_cardsview_valuable[askill]
			if type(callback) == "function" then
				local ret = callback(self, class_name, player)
				if ret then return ret end
			end
		end
	end
end

local function cardsView(self, class_name, player)
	for _, skill in ipairs(sgs.getPlayerSkillList(player)) do
		local askill = skill:objectName()
		if player:hasSkill(askill) or player:hasLordSkill(askill) then
			local callback = sgs.ai_cardsview_valuable[askill]
			if type(callback) == "function" then
				local ret = callback(self, class_name, player)
				if ret then return ret end
			end
		end
	end
	for _, skill in ipairs(sgs.getPlayerSkillList(player)) do
		local askill = skill:objectName()
		if player:hasSkill(askill) or player:hasLordSkill(askill) then
			local callback = sgs.ai_cardsview[askill]
			if type(callback) == "function" then
				local ret = callback(self, class_name, player)
				if ret then return ret end
			end
		end
	end
end

local function getSkillViewCard(card, class_name, player, card_place)
	for _, skill in ipairs(sgs.getPlayerSkillList(player)) do
		local askill = skill:objectName()
		if player:hasSkill(askill) or player:hasLordSkill(askill) then
			local callback = sgs.ai_view_as[askill]
			if type(callback) == "function" then
				local skill_card_str = callback(card, player, card_place, class_name)
				if skill_card_str then
					local skill_card = sgs.Card_Parse(skill_card_str)
					if skill_card:isKindOf(class_name) and not player:isCardLimited(skill_card, skill_card:getHandlingMethod()) then return skill_card_str end
				end
			end
		end
	end
end

function isCard(class_name, card, player)
	if not player or not card then global_room:writeToConsole(debug.traceback()) end
	if type(card) == "number" and card >= 0 then card = sgs.Sanguosha:getCard(card)
	elseif type(card) ~= "userdata" then global_room:writeToConsole(debug.traceback()) end
	if not card:isKindOf(class_name) then
		local place
		local id = card:getEffectiveId()
		if global_room:getCardOwner(id) == nil or global_room:getCardOwner(id):objectName() ~= player:objectName() then place = sgs.Player_PlaceHand
		else place = sgs.getCardPlace(global_room, card) end
		if getSkillViewCard(card, class_name, player, place) then return true end
		if player:hasSkill("wushen") and card:getSuit() == sgs.Card_Heart and class_name == "Slash" then return true end
		if player:hasSkill("jinjiu") and card:isKindOf("Analeptic") and class_name == "Slash" then return true end
	else
		if player:hasSkill("wushen") and card:getSuit() == sgs.Card_Heart and class_name ~= "Slash" then return false end
		if player:hasSkill("jinjiu") and class_name == "Analeptic" then return false end
		if not prohibitUseDirectly(card, player) then return true end
	end
	return false
end

function SmartAI:getMaxCard(player, cards)
	player = player or self.player
	if player:isKongcheng() then return nil end

	cards = cards or sgs.QList2Table(player:getHandcards())
	local max_card, max_point = nil, 0
	for _, card in ipairs(cards) do
		local flag = string.format("%s_%s_%s", "visible", global_room:getCurrent():objectName(), player:objectName())
		if (player:objectName() == self.player:objectName() and not self:isValuableCard(card)) or card:hasFlag("visible") or card:hasFlag(flag) then
			local point = card:getNumber()
			if point > max_point then
				max_point = point
				max_card = card
			end
		end
	end
	if player:objectName() == self.player:objectName() and not max_card then
		for _, card in ipairs(cards) do
			local point = card:getNumber()
			if point > max_point then
				max_point = point
				max_card = card
			end
		end
	end

	if player:objectName() ~= self.player:objectName() then return max_card end

	if (player:hasSkills("tianyi|dahe|xianzhen") or self.player:hasFlag("AI_XiechanUsing")) and max_point > 0 then
		for _, card in ipairs(cards) do
			if card:getNumber() == max_point and not isCard("Slash", card, player) then
				return card
			end
		end
	end
	if player:hasSkill("qiaoshui") and max_point > 0 then
		for _, card in ipairs(cards) do
			if card:getNumber() == max_point and not card:isNDTrick() then
				return card
			end
		end
	end

	return max_card
end

function SmartAI:getMinCard(player)
	player = player or self.player

	if player:isKongcheng() then
		return nil
	end

	local cards = player:getHandcards()
	local min_card, min_point = nil, 14
	for _, card in sgs.qlist(cards) do
		local flag = string.format("%s_%s_%s", "visible", global_room:getCurrent():objectName(), player:objectName())
		if player:objectName() == self.player:objectName() or card:hasFlag("visible") or card:hasFlag(flag) then
			local point = card:getNumber()
			if point < min_point then
				min_point = point
				min_card = card
			end
		end
	end

	return min_card
end

function getKnownNum(player)
	if not player then
		global_room:writeToConsole(debug.traceback())
		return 0
	else
		local cards = player:getHandcards()
		for _, id in sgs.qlist(player:getPile("wooden_ox")) do
			cards:prepend(sgs.Sanguosha:getCard(id))
		end
		local known = 0
		for _, card in sgs.qlist(cards) do
			local flag = string.format("%s_%s_%s", "visible", global_room:getCurrent():objectName(), player:objectName())
			if card:hasFlag("visible") or card:hasFlag(flag) then
				known = known + 1
			end
		end
		return known
	end
end

function getKnownCard(player, from, class_name, viewas, flags)
	if not player
		or (flags and type(flags) ~= "string")
		or (from and type(from) ~= "userdata") then global_room:writeToConsole(debug.traceback()) return 0 end
	flags = flags or "h"
	player = findPlayerByObjectName(global_room, player:objectName())
	local cards = player:getCards(flags)
	if flags:match("h") then
		for _, id in sgs.qlist(player:getPile("wooden_ox")) do
			cards:prepend(sgs.Sanguosha:getCard(id))
		end
	end
	local known = 0
	local suits = { ["club"] = 1, ["spade"] = 1, ["diamond"] = 1, ["heart"] = 1 }
	for _, card in sgs.qlist(cards) do
		local flag = nil
		if from then flag = string.format("%s_%s_%s", "visible", from:objectName(), player:objectName()) end
		if card:hasFlag("visible") or (flag and card:hasFlag(flag)) or (from and player:objectName() == from:objectName()) then
			for _, name in ipairs(class_name:split("|")) do
				if (suits[name] and card:getSuitString() == name)
					or (name == "red" and card:isRed()) or (name == "black" and card:isBlack())
					or (viewas and isCard(name, card, player)) or card:isKindOf(name) then
					known = known + 1
				end
			end
		end
	end
	return known
end

function SmartAI:getCardId(class_name, player, acard)
	player = player or self.player
	local cards
	if acard then cards = { acard }
	else
		cards = player:getCards("he")
		for _, key in sgs.list(player:getPileNames()) do
			for _, id in sgs.qlist(player:getPile(key)) do
				cards:append(sgs.Sanguosha:getCard(id))
			end
		end
		cards = sgs.QList2Table(cards)
	end
	self:sortByUsePriority(cards, player)

	local card_str = cardsViewValuable(self, class_name, player)
	if card_str then return card_str end

	local guhuo_str = self:getGuhuoCard(class_name, false)
	if guhuo_str then return guhuo_str end

	local viewArr, cardArr = {}, {}

	for _, card in ipairs(cards) do
		local viewas, cardid
		local card_place = sgs.getCardPlace(self.room, card)
		viewas = getSkillViewCard(card, class_name, player, card_place)
		if viewas then table.insert(viewArr, viewas) end
		if card:isKindOf(class_name) and not prohibitUseDirectly(card, player) and card_place ~= sgs.Player_PlaceSpecial then
			table.insert(cardArr, card:getEffectiveId())
		end
	end
	if #viewArr > 0 or #cardArr > 0 then
		local viewas, cardid
		viewas = #viewArr > 0 and viewArr[1]
		cardid = #cardArr > 0 and cardArr[1]
		local viewCard
		if viewas then viewCard = sgs.Card_Parse(viewas) end
		return (player:hasSkill("chongzhen") and viewCard and viewCard:getSkillName() == "longdan") and (viewas or cardid) or (cardid or viewas)
	end
	return cardsView(self, class_name, player)
end

function SmartAI:getCard(class_name, player)
	player = player or self.player
	local card_id = self:getCardId(class_name, player)
	if card_id then return sgs.Card_Parse(card_id) end
end

function SmartAI:getCards(class_name, flag)
	local player = self.player
	local room = self.room
	if flag and type(flag) ~= "string" then room:writeToConsole(debug.traceback()) return {} end

	local private_pile
	if not flag then private_pile = true end
	flag = flag or "he"
	local all_cards = player:getCards(flag)
	if private_pile then
		for _, key in sgs.list(player:getPileNames()) do
			for _, id in sgs.qlist(player:getPile(key)) do
				all_cards:append(sgs.Sanguosha:getCard(id))
			end
		end
	elseif flag:match("h") then
		for _, id in sgs.qlist(player:getPile("wooden_ox")) do
			all_cards:prepend(sgs.Sanguosha:getCard(id))
		end
	end

	local cards = {}
	local card_place, card_str

	card_str = cardsViewValuable(self, class_name, player)
	if card_str then
		card_str = sgs.Card_Parse(card_str)
		table.insert(cards, card_str)
	end

	for _, card in sgs.qlist(all_cards) do
		card_place = sgs.getCardPlace(room, card)

		if card:hasFlag("AI_Using") then
		elseif class_name == "." and card_place ~= sgs.Player_PlaceSpecial then table.insert(cards, card)
		elseif card:isKindOf(class_name) and not prohibitUseDirectly(card, player) and card_place ~= sgs.Player_PlaceSpecial then table.insert(cards, card)
		else
			card_str = getSkillViewCard(card, class_name, player, card_place)
			if card_str then
				card_str = sgs.Card_Parse(card_str)
				table.insert(cards, card_str)
			end
		end
	end

	card_str = cardsView(self, class_name, player)
	if card_str then
		card_str = sgs.Card_Parse(card_str)
		table.insert(cards, card_str)
	end

	return cards
end

function getCardsNum(class_name, player, from)
	if not player then global_room:writeToConsole(debug.traceback()) end
	local cards = sgs.QList2Table(player:getHandcards())
	for _, id in sgs.qlist(player:getPile("wooden_ox")) do
		table.insert(cards, 1, sgs.Sanguosha:getCard(id))
	end

	local num = 0
	local shownum = 0
	local redpeach = 0
	local redslash = 0
	local blackcard = 0
	local blacknull = 0
	local equipnull = 0
	local equipcard = 0
	local heartslash = 0
	local heartpeach = 0
	local spadenull = 0
	local spadewine = 0
	local spadecard = 0
	local diamondcard = 0
	local clubcard = 0
	local slashjink = 0

	for _, card in ipairs(cards) do
		local flag = nil
		if from then flag = string.format("%s_%s_%s", "visible", from:objectName(), player:objectName()) end
		if card:hasFlag("visible") or (from and card:hasFlag(flag)) or (from and from:objectName() == player:objectName()) then
			shownum = shownum + 1
			if card:isKindOf(class_name) then
				num = num + 1
			end
			if card:isKindOf("EquipCard") then
				equipcard = equipcard + 1
			end
			if card:isKindOf("Slash") or card:isKindOf("Jink") then
				slashjink = slashjink + 1
			end
			if card:isRed() then
				if not card:isKindOf("Slash") then
					redslash = redslash + 1
				end
				if not card:isKindOf("Peach") then
					redpeach = redpeach + 1
				end
			end
			if card:isBlack() then
				blackcard = blackcard + 1
				if not card:isKindOf("Nullification") then
					blacknull = blacknull + 1
				end
			end
			if card:getSuit() == sgs.Card_Heart then
				if not card:isKindOf("Slash") then
					heartslash = heartslash + 1
				end
				if not card:isKindOf("Peach") then
					heartpeach = heartpeach + 1
				end
			end
			if card:getSuit() == sgs.Card_Spade then
				if not card:isKindOf("Nullification") then
					spadenull = spadenull + 1
				end
				if not card:isKindOf("Analeptic") then
					spadewine = spadewine + 1
				end
			end
			if card:getSuit() == sgs.Card_Diamond and not card:isKindOf("Slash") then
				diamondcard = diamondcard + 1
			end
			if card:getSuit() == sgs.Card_Club then
				clubcard = clubcard + 1
			end
		end
	end
	local ecards = player:getCards("e")
	for _, card in sgs.qlist(ecards) do
		equipcard = equipcard + 1
		if player:getHandcardNum() > player:getHp() then
			equipnull = equipnull + 1
		end
		if card:isRed() then
			redpeach = redpeach + 1
			redslash = redslash + 1
		end
		if card:getSuit() == sgs.Card_Heart then
			heartpeach = heartpeach + 1
		end
		if card:getSuit() == sgs.Card_Spade then
			spadecard = spadecard + 1
		end
		if card:getSuit() == sgs.Card_Diamond then
			diamondcard = diamondcard + 1
		end
		if card:getSuit() == sgs.Card_Club then
			clubcard = clubcard + 1
		end
	end

	if class_name == "Slash" then
		local slashnum
		if player:hasSkill("wusheng") then
			slashnum = redslash + num + (player:getHandcardNum() - shownum) * 0.69
		elseif player:hasSkill("wushen") then
			slashnum = heartslash + num + (player:getHandcardNum() - shownum) * 0.5
		elseif player:hasSkill("longhun") then
			slashnum = diamondcard + num + (player:getHandcardNum() - shownum) * 0.5
		elseif player:hasSkill("nosgongqi") then
			slashnum = equipcard + num + (player:getHandcardNum() - shownum) * 0.5
		elseif player:hasSkill("longdan") then
			slashnum = slashjink + (player:getHandcardNum() - shownum) * 0.72
		else
			slashnum = num + (player:getHandcardNum() - shownum) * 0.35
		end
		return slashnum
	elseif class_name == "Jink" then
		if player:hasSkill("qingguo") then
			return blackcard + num + (player:getHandcardNum() - shownum) * 0.85
		elseif player:hasSkill("longdan") then
			return slashjink + (player:getHandcardNum() - shownum) * 0.72
		elseif player:hasSkill("longhun") then
			return clubcard + num + (player:getHandcardNum() - shownum) * 0.65
		elseif player:hasSkill("kofqingguo") then
			return num + (player:getHandcardNum() - shownum) * 0.6 + player:getEquips():length()
		else
			return num + (player:getHandcardNum() - shownum) * 0.6
		end
	elseif class_name == "Peach" then
		if player:hasSkill("jijiu") then
			return num + redpeach + (player:getHandcardNum() - shownum) * 0.6
		elseif player:hasSkill("longhun") then
			return num + heartpeach + (player:getHandcardNum() - shownum) * 0.5
		elseif player:hasSkill("chunlao") then
			return num + player:getPile("wine"):length()
		elseif player:hasSkill("jiuzhu") then
			return math.max(num, math.max(0, math.min(player:getCardCount(), player:getHp() - 1)))
		else
			return num
		end
	elseif class_name == "Analeptic" then
		if player:hasSkill("jiuchi") then
			return num + spadewine + (player:getHandcardNum() - shownum) / 3
		elseif player:hasSkill("jiushi") then
			return num + 1
		else
			return num
		end
	elseif class_name == "Nullification" then
		if player:hasSkill("kanpo") then
			return num + blacknull+(player:getHandcardNum() - shownum) / 2
		elseif player:hasSkill("yanzheng") then
			return num + equipnull
		else
			return num
		end
	else
		return num
	end
end

function SmartAI:getCardsNum(class_name, flag, selfonly)
	local player = self.player
	local n = 0
	if type(class_name) == "table" then
		for _, each_class in ipairs(class_name) do
			n = n + self:getCardsNum(each_class, flag, selfonly)
		end
		return n
	end
	n = #self:getCards(class_name, flag)

	card_str = cardsView(self, class_name, player)
	if card_str then
		card_str = sgs.Card_Parse(card_str)
		if card_str:getSkillName() == "spear" or card_str:getSkillName() == "fuhun" then
			n = n + math.floor(player:getHandcardNum() / 2) - 1
		elseif card_str:getSkillName() == "jiuzhu" then
			n = math.max(n, math.max(0, math.min(player:getCardCount(), player:getHp() - 1)))
		elseif card_str:getSkillName() == "chunlao" then
			n = n + player:getPile("wine"):length() - 1
		elseif card_str:getSkillName() == "nosrenxin" then
			n = n + 1
		end
	end

	if selfonly then return n end
	if class_name == "Jink" then
		if player:hasLordSkill("hujia") then
			local lieges = self.room:getLieges("wei", player)
			for _, liege in sgs.qlist(lieges) do
				if self:isFriend(liege, player) then
					n = n + getCardsNum("Jink", liege, player)
				end
			end
		end
	elseif class_name == "Slash" then
		if player:hasLordSkill("jijiang") then
			local lieges = self.room:getLieges("shu", player)
			for _, liege in sgs.qlist(lieges) do
				if self:isFriend(liege, player) then
				n = n + getCardsNum("Slash", liege, player)
				end
			end
		end
	end
	return n
end

function SmartAI:getAllPeachNum(player)
	player = player or self.player
	local n = 0
	for _, friend in ipairs(self:getFriends(player)) do
		local num = self.player:objectName() == friend:objectName() and self:getCardsNum("Peach") or getCardsNum("Peach", friend, self.player)
		n = n + num
	end
	return n
end

function SmartAI:getRestCardsNum(class_name, player)
	player = player or self.player
	local ban = table.concat(sgs.Sanguosha:getBanPackages(), "|")
	local discard_pile = self.room:getDiscardPile()
	local totalnum, discardnum, knownnum = 0, 0, 0
	local card
	for i = 1, sgs.Sanguosha:getCardCount() do
		card = sgs.Sanguosha:getEngineCard(i - 1)
		if card:isKindOf(class_name) and not ban:match(card:getPackage()) then totalnum = totalnum + 1 end
	end
	for _, card_id in sgs.qlist(discard_pile) do
		card = sgs.Sanguosha:getCard(card_id)
		if card:isKindOf(class_name) then discardnum = discardnum + 1 end
	end
	for _, player in sgs.qlist(self.room:getOtherPlayers(player)) do
		knownnum = knownnum + getKnownCard(player, self.player, class_name, false)
	end
	return totalnum - discardnum - knownnum
end

function SmartAI:hasSuit(suit_strings, include_equip, player)
	return self:getSuitNum(suit_strings, include_equip, player) > 0
end

function SmartAI:getSuitNum(suit_strings, include_equip, player)
	player = player or self.player
	local n = 0
	local flag = include_equip and "he" or "h"
	local allcards
	if player:objectName() == self.player:objectName() then
		allcards = sgs.QList2Table(player:getCards(flag))
	else
		allcards = include_equip and sgs.QList2Table(player:getEquips()) or {}
		local handcards = sgs.QList2Table(player:getHandcards())
		local flag = string.format("%s_%s_%s", "visible", self.player:objectName(), player:objectName())
		for i = 1, #handcards, 1 do
			if handcards[i]:hasFlag("visible") or handcards[i]:hasFlag(flag) then
				table.insert(allcards, handcards[i])
			end
		end
	end
	for _, card in ipairs(allcards) do
		for _, suit_string in ipairs(suit_strings:split("|")) do
			if card:getSuitString() == suit_string
				or (suit_string == "black" and card:isBlack()) or (suit_string == "red" and card:isRed()) then
				n = n + 1
			end
		end
	end
	return n
end

function SmartAI:fillSkillCards(cards)
	local i = 1
	while i <= #cards do
		if prohibitUseDirectly(cards[i], self.player) then
			table.remove(cards, i)
		else
			i = i + 1
		end
	end
	for _, skill in ipairs(sgs.ai_skills) do
		if self.player:hasSkill(skill.name) or (skill.name == "shuangxiong" and self.player:hasFlag("shuangxiong")) then
			local skill_card = skill.getTurnUseCard(self, #cards == 0)
			if skill_card then table.insert(cards, skill_card) end
		end
	end
end

function SmartAI:useSkillCard(card, use)
	local name
	if card:isKindOf("LuaSkillCard") then
		name = "#" .. card:objectName()
	else
		name = card:getClassName()
	end
	if not use.isDummy
		and not self.player:hasSkill(card:getSkillName()) and not self.player:hasLordSkill(card:getSkillName()) then return end
	if not sgs.ai_skill_use_func[name] then return end
	sgs.ai_skill_use_func[name](card, use, self)
	if use.to then
		if not use.to:isEmpty() and sgs.dynamic_value.damage_card[name] then
			for _, target in sgs.qlist(use.to) do
				if self:damageIsEffective(target) then return end
			end
			use.card = nil
		end
	end
end

function SmartAI:useBasicCard(card, use)
	if not card then global_room:writeToConsole(debug.traceback()) return end
	if not (card:isKindOf("Peach") and self.player:getLostHp() > 1) and self:needBear() then return end
	if self:needRende() then return end
	self:useCardByClassName(card, use)
end

function SmartAI:aoeIsEffective(card, to, source)
	source = source or self.player

	if source:hasSkill("noswuyan") or to:hasSkill("noswuyan") then
		return false
	end
	if source:hasSkill("wuyan") and not source:hasSkill("jueqing") then
		return false
	end

	local players = self.room:getAlivePlayers()
	players = sgs.QList2Table(players)

	if to:hasArmorEffect("vine") then
		return false
	end
	if self.room:isProhibited(self.player, to, card) then
		return false
	end
	if to:getPile("dream"):length() > 0 and to:isLocked(card) then
		return false
	end

	if to:hasSkill("wuyan") and not source:hasSkill("jueqing") then
		return false
	end

	if card:isKindOf("SavageAssault") then
		if to:hasSkills("huoshou|juxiang|manyi") then
			return false
		end
	end

	if to:getMark("@late") > 0 then
		return false
	end

	if to:hasSkill("danlao") and #players > 2 then
		return false
	end

	local liuxie = self.room:findPlayerBySkillName("huangen")
	if liuxie and self:isFriend(to, liuxie) and #players > 2 and liuxie:getHp() > 1 then
		return false
	end

	if not self:hasTrickEffective(card, to, source) or not self:damageIsEffective(to, sgs.DamageStruct_Normal, source) then
		return false
	end

	return true
end

function SmartAI:canAvoidAOE(card)
	if not self:aoeIsEffective(card, self.player) then return true end
	if card:isKindOf("SavageAssault") then
		if self:getCardsNum("Slash") > 0 then
			return true
		end
	end
	if card:isKindOf("ArcheryAttack") then
		if self:getCardsNum("Jink") > 0 or (self:hasEightDiagramEffect() and self.player:getHp() > 1) then
			return true
		end
	end
	return false
end

function SmartAI:getDistanceLimit(card, from)
	from = from or self.player
	if (card:isKindOf("Snatch") or card:isKindOf("SupplyShortage")) and card:getSkillName() ~= "qiaoshui" then
		return 1 + sgs.Sanguosha:correctCardTarget(sgs.TargetModSkill_DistanceLimit, from, card)
	end
end

function SmartAI:exclude(players, card, from)
	from = from or self.player
	local excluded = {}
	local limit = self:getDistanceLimit(card, from)
	local range_fix = 0
	if card:isVirtualCard() then
		for _, id in sgs.qlist(card:getSubcards()) do
			if from:getOffensiveHorse() and from:getOffensiveHorse():getEffectiveId() == id then range_fix = range_fix + 1 end
		end
		if card:getSkillName() == "jixi" then range_fix = range_fix + 1 end
	end

	for _, player in sgs.list(players) do
		if not self.room:isProhibited(from, player, card) then
			local should_insert = true
			if limit then
				should_insert = from:distanceTo(player, range_fix) <= limit
			end
			if should_insert then
				table.insert(excluded, player)
			end
		end
	end
	return excluded
end

function SmartAI:getJiemingChaofeng(player)
	local max_x, chaofeng = 0, 0
	for _, friend in ipairs(self:getFriends(player)) do
		local x = math.min(friend:getMaxHp(), 5) - friend:getHandcardNum()
		if x > max_x then
			max_x = x
		end
	end
	if max_x < 2 then
		chaofeng = 5 - max_x * 2
	else
		chaofeng = (-max_x) * 2
	end
	return chaofeng
end

function SmartAI:getAoeValueTo(card, to, from)
	local value, sj_num = 0, 0
	if card:isKindOf("ArcheryAttack") then sj_num = getCardsNum("Jink", to, from) end
	if card:isKindOf("SavageAssault") then sj_num = getCardsNum("Slash", to, from) end

	if self:aoeIsEffective(card, to, from) then
		local jink = sgs.cloneCard("jink")
		local slash = sgs.cloneCard("slash")
		local isLimited = (card:isKindOf("ArcheryAttack") and to:isCardLimited(jink, sgs.Card_MethodResponse))
							or (card:isKindOf("ArcheryAttack") and to:isCardLimited(jink, sgs.Card_MethodResponse))
		if (card:isKindOf("SavageAssault") and sgs.card_lack[to:objectName()]["Slash"] == 1)
			or (card:isKindOf("ArcheryAttack") and sgs.card_lack[to:objectName()]["Jink"] == 1)
			or sj_num < 1 or isLimited then
			value = -70
		else
			value = -50
		end
		value = value + math.min(20, to:getHp() * 5)

		if self:getDamagedEffects(to, from) then value = value + 40 end
		if self:needToLoseHp(to, from, nil, true) then value = value + 10 end

		if card:isKindOf("ArcheryAttack") then
			if to:hasSkills("leiji|nosleiji") and (sj_num >= 1 or self:hasEightDiagramEffect(to)) and self:findLeijiTarget(to, 50, from) then
				value = value + 100
				if self:hasSuit("spade", true, to) then value = value + 150
				else value = value + to:getHandcardNum() * 35
				end
			elseif self:hasEightDiagramEffect(to) then
				value = value + 20
				if self:getFinalRetrial(to) == 2 then
					value = value - 15
				elseif self:getFinalRetrial(to) == 1 then
					value = value + 10
				end
			end
		end

		if card:isKindOf("ArcheryAttack") and sj_num >= 1 then
			if to:hasSkill("mingzhe") then value = value + 8 end
			if to:hasSkill("xiaoguo") then value = value - 4 end
		elseif card:isKindOf("SavageAssault") and sj_num >= 1 then
			if to:hasSkill("xiaoguo") then value = value - 4 end
		end

		if to:hasSkills("longdan+chongzhen") and self:isEnemy(to) then
			if card:isKindOf("ArcheryAttack") and getCardsNum("Slash", to, from) >= 1 then
				value = value + 15
			elseif card:isKindOf("SavageAssault") and getCardsNum("Jink", to, from) >= 1 then
				value = value + 15
			end
		end

		local wansha = self.room:getCurrent() and self.room:getCurrent():hasSkill("wansha")
		if wansha and to:getHp() == 1 and (sgs.card_lack[to:objectName()]["Peach"] == 1 or getCardsNum("Peach", to, from) == 0) then
			value = value - 30
			if self:isFriend(to) and self:getCardsNum("Peach") >= 1 then
				value = value + 10
			end
		end

		if not from:hasSkill("jueqing") then
			if self.room:getMode() ~= "06_3v3" and self.room:getMode() ~= "06_XMode" then
				if to:getHp() == 1 and from:isLord() and sgs.evaluatePlayerRole(to) == "loyalist" and self:getCardsNum("Peach") == 0 then
					value = value - from:getCardCount() * 20
				end
			end

			if to:getHp() > 1 then
				if to:hasSkill("quanji") then value = value + 10 end
				if to:hasSkill("langgu") and self:isEnemy(to, from) then value = value - 15 end
				if to:hasSkills("jianxiong|nosjianxiong") then
					local v = 10
					if card:isVirtualCard() then v = math.max(to:hasSkill("jianxiong") and 1 or 0, card:subcardsLength()) * 10 end
					value = value + v
				end
				if to:hasSkills("fenyong+xuehen") and to:getMark("@fenyong") == 0 then
					value = value + 30
				end
				if to:hasSkill("shenfen") and to:hasSkill("kuangbao") then
					value = value + math.min(25, to:getMark("@wrath") * 5)
				end
			end
		end
	else
		value = value + 10
		if to:hasSkill("juxiang") and not card:isVirtualCard() then value = value + 20 end
		if to:hasSkill("danlao") and self.player:aliveCount() > 2 then value = value + 20 end
	end
	return value
end

function SmartAI:getAoeValue(card, player)
	local attacker = player or self.player
	local good, bad = 0, 0
	local lord = self.room:getLord()

	local canHelpLord = function()
		if not lord or self:isEnemy(lord, attacker) then return false end
		if card:getSkillName() == "qice" then return false end
		local peach_num, null_num, slash_num, jink_num = 0, 0, 0, 0
		if card:isVirtualCard() and card:subcardsLength() > 0 then
			for _, subcardid in sgs.qlist(card:getSubcards()) do
				local subcard = sgs.Sanguosha:getCard(subcardid)
				if isCard("Peach", subcard, attacker) then peach_num = peach_num - 1 end
				if isCard("Slash", subcard, attacker) then slash_num = slash_num - 1 end
				if isCard("Jink", subcard, attacker) then jink_num = jink_num - 1 end
				if isCard("Nullification", subcard, attacker) then null_num = null_num - 1 end
			end
		end
		if card:isKindOf("SavageAssault") and lord:hasLordSkill("jijiang") and self.player:getKingdom() == "shu"
			and self:getCardsNum("Slash") > slash_num then return true end
		if card:isKindOf("ArcheryAttack") and lord:hasLordSkill("hujia") and self.player:getKingdom() == "wei"
			and self:getCardsNum("Jink") > jink_num then return true end
		if self:getCardsNum("Peach") > peach_num then return true end

		local goodnull, badnull = 0, 0
		for _, p in sgs.qlist(self.room:getAlivePlayers()) do
			if self:isFriend(lord, p) then
				goodnull = goodnull + getCardsNum("Nullification", p, from)
			else
				badnull = badnull + getCardsNum("Nullification", p, from)
			end
		end
		return goodnull - null_num - badnull >= 2
	end

	if card:isKindOf("SavageAssault") then
		local menghuo = self.room:findPlayerBySkillName("huoshou")
		attacker = menghuo or attacker
	end

	local isEffective_F, isEffective_E = 0, 0
	for _, friend in ipairs(self:getFriendsNoself(attacker)) do
		good = good + self:getAoeValueTo(card, friend, attacker)
		if self:aoeIsEffective(card, friend, attacker) then isEffective_F = isEffective_F + 1 end
	end

	for _, enemy in ipairs(self:getEnemies(attacker)) do
		bad = bad + self:getAoeValueTo(card, enemy, attacker)
		if self:aoeIsEffective(card, enemy, attacker) then isEffective_E = isEffective_E + 1 end
	end

	if isEffective_F == 0 and isEffective_E == 0 then
		return attacker:hasSkills("jizhi|nosjizhi") and 10 or -100
	elseif isEffective_E == 0 then
		return -100
	end
	if not sgs.GetConfig("EnableHegemony", false) then
		if self.role ~= "lord" and sgs.isLordInDanger() and self:aoeIsEffective(card, lord, attacker) and not canHelpLord() and not hasBuquEffect(lord) then
			if self:isEnemy(lord) then
				good = good + (lord:getHp() == 1 and 200 or 150)
				if lord:getHp() <= 2 then
					if #self.enemies == 1 then good = good + 150 - lord:getHp() * 50 end
					if lord:isKongcheng() then good = good + 150 - lord:getHp() * 50 end
				end
			else
				bad = bad + (lord:getHp() == 1 and 2013 or 250)
			end
		end
	end
	if isEffective_E + isEffective_F > 1 then
		for _, player in sgs.qlist(self.room:getAlivePlayers()) do
			if player:hasSkill("huangen") then
				if self:isFriend(player, attacker) then
					if player:getHp() >= #self:getFriendsNoself(attacker) then
						good = good + 300
					else
						good = good + player:getHp() * 50
					end
				elseif self:isEnemy(player, attacker) then
					if player:getHp() >= #self:getEnemies(attacker) then
						bad = bad + 300
					else
						bad = bad + player:getHp() * 50
					end
				end
			end
		end
	end
	local enemy_number = 0
	for _, player in sgs.qlist(self.room:getOtherPlayers(attacker)) do
		if self:cantbeHurt(player, attacker) and self:aoeIsEffective(card, player, attacker) then
			if player:hasSkill("wuhun") and not self:isWeak(player) and attacker:getMark("@nightmare") == 0 then
				if attacker:objectName() == self.player:objectName() and self.role ~= "renegade" and self.role ~= "lord" then
				elseif attacker:objectName() ~= self.player:objectName() and not (self:isFriend(attacker) and attacker:objectName() == lord:objectName()) then
				else
					bad = bad + 250
				end
			else
				bad = bad + 250
			end
		end
		if self:aoeIsEffective(card, player, attacker) and not self:isFriend(player, attacker) then enemy_number = enemy_number + 1 end
	end

	local forbid_start = true
	if attacker:hasSkills("nosjizhi|jizhi") then
		forbid_start = false
		good = good + 51
	end
	if attacker:hasSkills("shenfen+kuangbao") then
		forbid_start = false
		good = good + 3 * enemy_number
		if not attacker:hasSkill("wumou") then
			good = good + 3 * enemy_number
		end
		if self.player:getMark("@wrath") > 0 then
			good = good + enemy_number
		end
	end
	if not sgs.GetConfig("EnableHegemony", false) then
		if forbid_start and sgs.turncount < 2 and attacker:getSeat() <= 3 and card:isKindOf("SavageAssault") and enemy_number > 0 then
			if self.role ~= "rebel" then
				good = good + (isEffective_E > 0 and 50 or 0)
			else
				bad = bad + (isEffective_F > 0 and 50 or 0)
			end
		end
		if sgs.current_mode_players["rebel"] == 0 and attacker:getRole() ~= "lord" and sgs.current_mode_players["loyalist"] > 0 and self:isWeak(lord) then
			bad = bad + 300
		end
	end
	if attacker:hasSkills("jianxiong|nosjianxiong|luanji|qice|manjuan") then good = good + 2 * enemy_number end

	local xiahou = self.room:findPlayerBySkillName("yanyu")
	if xiahou and self:isEnemy(xiahou) and xiahou:getMark("YanyuDiscard2") > 0 then bad = bad + 50 end

	if self.room:alivePlayerCount() > 2 then
		local ganning = self.room:findPlayerBySkillName("fenwei")
		if ganning and ganning:getMark("@fenwei") > 0 then
			if self:isEnemy(ganning) then bad = bad * 1.1 elseif self:isFriend(ganning) then good = good * 1.1 end
		end
	end

	return good - bad
end

function SmartAI:hasTrickEffective(card, to, from)
	to = to or self.player
	from = from or self.player
	if not card then
		self.room:writeToConsole(debug.traceback())
		return false
	end
	if self.room:isProhibited(from, to, card) then return false end
	if to:getMark("@late") > 0 and not card:isKindOf("DelayedTrick") then return false end
	if to:getPile("dream"):length() > 0 and to:isLocked(card) then return false end

	if to:objectName() ~= from:objectName() then
		if from:hasSkill("noswuyan") or to:hasSkill("noswuyan") then
			if card:isKindOf("TrickCard") and not card:isKindOf("DelayedTrick") then
				return false
			end
		end
	end

	if to:hasSkills("wuyan|hongyan") and card:isKindOf("Lightning") then return false end

	if (from:hasSkill("wuyan") or to:hasSkill("wuyan")) and not from:hasSkill("jueqing") then
		if card:isKindOf("TrickCard") and
			(card:isKindOf("Duel") or card:isKindOf("FireAttack") or card:isKindOf("Drowning")
			or card:isKindOf("ArcheryAttack") or card:isKindOf("SavageAssault")) then
			return false
		end
	end

	local nature = sgs.DamageStruct_Normal
	if card:isKindOf("FireAttack") then nature = sgs.DamageStruct_Fire end
	if (card:isKindOf("Duel") or card:isKindOf("FireAttack") or card:isKindOf("Drowning")
		or card:isKindOf("ArcheryAttack") or card:isKindOf("SavageAssault")) then
		self.equipsToDec = sgs.getCardNumAtCertainPlace(card, from, sgs.Player_PlaceEquip)
		local eff = self:damageIsEffective(to, nature, from)
		self.equipsToDec = 0
		if not eff then return false end
	end
	if card:isKindOf("Duel") and self:isFriend(from, to) and from:hasSkill("chuanxin")
		and to:getEquips():isEmpty() then
		if to:getMark("chuanxin_" .. from:objectName()) > 0 then return false
		else
			local count = 0
			for _, skill in sgs.qlist(to:getVisibleSkillList()) do
				if not skill:isAttachedLordSkill() then count = count + 1 end
			end
			if count <= 1 then return false end
		end
	end

	return true
end

function SmartAI:useTrickCard(card, use)
	if not card then global_room:writeToConsole(debug.traceback()) return end
	if self:needBear() and not ("amazing_grace|ex_nihilo|snatch|iron_chain|collateral"):match(card:objectName()) then return end
	if self.player:hasSkill("wumou") and self.player:getMark("@wrath") < 7 then
		if not (card:isKindOf("AOE") or card:isKindOf("DelayedTrick") or card:isKindOf("IronChain") or card:isKindOf("Drowning"))
			and not (card:isKindOf("Duel") and self.player:getMark("@wrath") > 0) then return end
	end
	if self:needRende() and not card:isKindOf("ExNihilo") then return end
	if card:isKindOf("AOE") then
		local others = self.room:getOtherPlayers(self.player)
		others = sgs.QList2Table(others)
		local avail = #others
		local avail_friends = 0
		for _, other in ipairs(others) do
			if self.room:isProhibited(self.player, other, card) then
				avail = avail - 1
			elseif self:isFriend(other) then
				avail_friends = avail_friends + 1
			end
		end
		if avail < 1 then return end

		local menghuo = nil
		if card:isKindOf("SavageAssault") then menghuo = self.room:findPlayerBySkillName("huoshou") end
		if self.player:hasSkill("noswuyan")
			or (self.player:hasSkill("wuyan")
				and not (menghuo and (not menghuo:hasSkill("wuyan") or menghuo:hasSkill("jueqing")) and avail > 1)
				and not self.player:hasSkill("jueqing")) then
			if self.player:hasSkill("huangen") and self.player:getHp() > 0 and avail > 1 and avail_friends > 0 then use.card = card else return end
		end

		local mode = global_room:getMode()
		if mode:find("p") and mode >= "04p" then
			if self.player:isLord() and sgs.turncount < 2 and card:isKindOf("ArcheryAttack") and self:getOverflow() < 1 then return end
			if self.role == "loyalist" and sgs.turncount < 2 and card:isKindOf("ArcheryAttack") then return end
			if self.role == "rebel" and sgs.turncount < 2 and card:isKindOf("SavageAssault") then return end
		end

		local good = self:getAoeValue(card)
		if good > 0 then
			use.card = card
		end
	else
		self:useCardByClassName(card, use)
	end
	if use.to then
		if not use.to:isEmpty() and sgs.dynamic_value.damage_card[card:getClassName()] then
			local nature = card:isKindOf("FireAttack") and sgs.DamageStruct_Fire or sgs.DamageStruct_Normal
			for _, target in sgs.qlist(use.to) do
				if self:damageIsEffective(target, nature) then return end
			end
			use.card = nil
		end
	end
end

sgs.weapon_range = {}

function SmartAI:hasEightDiagramEffect(player)
	player = player or self.player
	return player:hasArmorEffect("eight_diagram") or player:hasArmorEffect("bazhen")
end

function SmartAI:hasCrossbowEffect(player)
	player = player or self.player
	return player:hasWeapon("Crossbow") or player:hasSkill("paoxiao")
end

function SmartAI:hasSilverLionEffect(player)
	player = player or self.player
	if player:hasArmorEffect("silver_lion") then return true end
	local zidan = self.room:findPlayerBySkillName("jgchiying")
	if zidan and zidan:getRole() == player:getRole() then return true end
end

sgs.ai_weapon_value = {}

function SmartAI:evaluateWeapon(card, player, enemy)
	player = player or self.player
	local enemies = {}
	if enemy then
		if type(enemy) == "table" then enemies = enemy
		else enemies = { enemy } end
	else
		enemies = self:getEnemies(player)
	end
	local deltaSelfThreat = 0
	local currentRange
	if not card then return -1
	else
		currentRange = math.max(sgs.weapon_range[card:getClassName()] or 0, player:getAttackRange(false))
	end
	local inAttackRange
	for _, enemy in ipairs(enemies) do
		if player:distanceTo(enemy) <= currentRange then
			inAttackRange = true
			local def = sgs.getDefenseSlash(enemy, self) / 2
			if def < 0 then def = 6 - def
			elseif def <= 1 then def = 6
			else def = 6 / def
			end
			deltaSelfThreat = deltaSelfThreat + def
		end
	end

	local slash_num = player:objectName() == self.player:objectName() and self:getCardsNum("Slash") or getCardsNum("Slash", player, self.player)
	local analeptic_num = player:objectName() == self.player:objectName() and self:getCardsNum("Analeptic") or getCardsNum("Analeptic", player, self.player)
	local peach_num = player:objectName() == self.player:objectName() and self:getCardsNum("Peach") or getCardsNum("Peach", player, self.player)
	if card:isKindOf("Crossbow") and not player:hasSkill("paoxiao") and deltaSelfThreat ~= 0 then
		deltaSelfThreat = deltaSelfThreat + slash_num * 3 - 2
		if player:hasSkill("noskurou") then deltaSelfThreat = deltaSelfThreat + peach_num + analeptic_num + self.player:getHp() end
		if player:getWeapon() and not self:hasCrossbowEffect(player) and not player:canSlashWithoutCrossbow() and slash_num > 0 then
			for _, enemy in ipairs(enemies) do
				if player:distanceTo(enemy) <= currentRange
					and (sgs.card_lack[enemy:objectName()]["Jink"] == 1 or slash_num >= enemy:getHp()) then
					deltaSelfThreat = deltaSelfThreat + 10
				end
			end
		end
	end
	local callback = sgs.ai_weapon_value[card:objectName()]
	if type(callback) == "function" then
		deltaSelfThreat = deltaSelfThreat + (callback(self, nil, player) or 0)
		for _, enemy in ipairs(enemies) do
			if player:distanceTo(enemy) <= currentRange and callback then
				local added = sgs.ai_slash_weaponfilter[card:objectName()]
				if added and type(added) == "function" and added(self, enemy, player) then deltaSelfThreat = deltaSelfThreat + 1 end
				deltaSelfThreat = deltaSelfThreat + (callback(self, enemy, player) or 0)
			end
		end
	end

	if player:hasSkill("jijiu") and card:isRed() then deltaSelfThreat = deltaSelfThreat + 0.5 end
	if player:hasSkills("qixi|guidao") and card:isBlack() then deltaSelfThreat = deltaSelfThreat + 0.5 end

	return deltaSelfThreat, inAttackRange
end

sgs.ai_armor_value = {}

function SmartAI:evaluateArmor(card, player)
	player = player or self.player
	local ecard = card or player:getArmor()

	local value = 0
	for _, askill in sgs.qlist(player:getVisibleSkillList()) do
		local callback = sgs.ai_armor_value[askill:objectName()]
		if type(callback) == "function" then
			return value + (callback(ecard, player, self) or 0)
		end
	end
	if not ecard then return value end
	if player:hasSkill("jijiu") and ecard:isRed() then value = value + 0.5 end
	if player:hasSkills("qixi|guidao") and ecard:isBlack() then value = value + 0.5 end
	local callback = sgs.ai_armor_value[ecard:objectName()]
	if type(callback) == "function" then
		return value + (callback(player, self) or 0)
	end
	return value + 0.5
end

function SmartAI:getSameEquip(card, player)
	player = player or self.player
	if not card then return end
	if card:isKindOf("Weapon") then return player:getWeapon()
	elseif card:isKindOf("Armor") then return player:getArmor()
	elseif card:isKindOf("DefensiveHorse") then return player:getDefensiveHorse()
	elseif card:isKindOf("OffensiveHorse") then return player:getOffensiveHorse() end
end

function SmartAI:useEquipCard(card, use)
	if not card then global_room:writeToConsole(debug.traceback()) return end
	if self.player:hasSkills("kofxiaoji|xiaoji") and self:evaluateArmor(card) > -5 then
		use.card = card
		return
	end
	if self.player:hasSkills(sgs.lose_equip_skill) and self:evaluateArmor(card) > -5 and #self.enemies > 1 then
		use.card = card
		return
	end
	if self.player:getHandcardNum() == 1 and self:needKongcheng() and self:evaluateArmor(card) > -5 then
		use.card = card
		return
	end
	local same = self:getSameEquip(card)
	local zzzh, isfriend_zzzh = self.room:findPlayerBySkillName("guzheng")
	if zzzh and zzzh:hasSkill("zhijian") then isfriend_zzzh = self:isFriend(zzzh) end
	if same then
		if (self.player:hasSkill("nosgongqi") and self:slashIsAvailable())
			or (self.player:hasSkill("nosrende") and self:findFriendsByType(sgs.Friend_Draw))
			or (self.player:hasSkill("rende") and not self.player:hasUsed("RendeCard") and self:findFriendsByType(sgs.Friend_Draw))
			or (self.player:hasSkills("yongsi|renjie") and self:getOverflow() < 2)
			or (self.player:hasSkills("qixi|duanliang|yinling") and (card:isBlack() or same:isBlack()))
			or (self.player:hasSkills("nosguose|longhun") and (card:getSuit() == sgs.Card_Diamond or same:getSuit() == sgs.Card_Diamond))
			or (self.player:hasSkill("guose") and not self.player:hasUsed("GuoseCard") and (card:getSuit() == sgs.Card_Diamond or same:getSuit() == sgs.Card_Diamond))
			or (self.player:hasSkill("jijiu") and (card:isRed() or same:isRed()))
			or (self.player:hasSkill("guidao") and same:isBlack() and card:isRed())
			or isfriend_zzzh then return end
	end
	local canUseSlash = self:getCardId("Slash") and self:slashIsAvailable(self.player)
	self:useCardByClassName(card, use)
	if use.card then return end
	if card:isKindOf("Weapon") then
		if self:needBear() then return end
		if same and self.player:hasSkill("qiangxi") and not self.player:hasUsed("QiangxiCard") then
			local dummy_use = { isDummy = true }
			self:useSkillCard(sgs.Card_Parse("@QiangxiCard=" .. same:getEffectiveId()), dummy_use)
			if dummy_use.card and dummy_use.card:getSubcards():length() == 1 then return end
		end
		if self.player:hasSkill("nosrende") or (self.player:hasSkill("rende") and not self.player:hasUsed("RendeCard")) then
			for _, friend in ipairs(self.friends_noself) do
				if not friend:getWeapon() then return end
			end
		end
		if self.player:hasSkills("paoxiao|nosfuhun") and card:isKindOf("Crossbow") then return end
		if not use.to and not self:needKongcheng() and not self.player:hasSkills(sgs.lose_equip_skill) and self:getOverflow() <= (canUseSlash and self.slashAvail or 0)
			and not canUseSlash and not card:isKindOf("Crossbow") and not card:isKindOf("VSCrossbow") then return end
		if (self.player:hasSkill("zhiheng") or self.player:hasSkill("jilve") and self.player:getMark("@bear") > 0)
			and not self.player:hasUsed("ZhihengCard") and self.player:getWeapon() and not card:isKindOf("Crossbow") then return end
		if not self:needKongcheng() and self.player:getHandcardNum() <= self.player:getHp() - 2 then return end
		if not self.player:getWeapon() or self:evaluateWeapon(card) > self:evaluateWeapon(self.player:getWeapon()) then
			use.card = card
		end
	elseif card:isKindOf("Armor") then
		if self:needBear() and self.player:getLostHp() == 0 then return end
		local lion = self:getCard("SilverLion")
		if lion and self.player:isWounded() and not self.player:hasArmorEffect("silver_lion") and not card:isKindOf("SilverLion")
			and not (not self.player:getArmor() and (self.player:hasSkills("bazhen|yizhong")
													or (self.player:hasSkill("bossmanjia") and sgs.ai_armor_value.vine(self.player, self, true) > -2))) then
			use.card = lion
			return
		end
		if (self.player:hasSkill("nosrende") or (self.player:hasSkill("rende") and not self.player:hasUsed("RendeCard"))) and self:evaluateArmor(card) < 4 then
			for _, friend in ipairs(self.friends_noself) do
				if not friend:getArmor() then return end
			end
		end
		if self:evaluateArmor(card) > self:evaluateArmor() or (isfriend_zzzh == false and self:getOverflow() > 0) then use.card = card end
		return
	elseif card:isKindOf("Treasure") then
		if card:isKindOf("WoodenOx") then
			local zhanghe = self.room:findPlayerBySkillName("qiaobian")
			local wuguotai = self.room:findPlayerBySkillName("ganlu")
			if (zhanghe and self:isEnemy(zhanghe)) or (wuguotai and self:isEnemy(wuguotai)) then return end
			use.card = card
		end
	elseif self:needBear() then return
	elseif card:isKindOf("OffensiveHorse") then
		if (self.player:hasSkill("nosrende") or (self.player:hasSkill("rende") and not self.player:hasUsed("RendeCard"))) then
			for _, friend in ipairs(self.friends_noself) do
				if not friend:getOffensiveHorse() then return end
			end
			use.card = card
			return
		else
			if not self.player:hasSkills(sgs.lose_equip_skill) and self:getOverflow() <= 0 and not (canUseSlash or self:getCardId("Snatch")) then
				return
			else
				if self.lua_ai:useCard(card) then
					use.card = card
					return
				end
			end
		end
	elseif card:isKindOf("DefensiveHorse") then
		local tiaoxin = true
		if self.player:hasSkill("tiaoxin") then
			local dummy_use = { isDummy = true, defHorse = true }
			self:useSkillCard(sgs.Card_Parse("@TiaoxinCard=."), dummy_use)
			if not dummy_use.card then tiaoxin = false end
		end
		if tiaoxin and self.lua_ai:useCard(card) then
			use.card = card
		end
	elseif self.lua_ai:useCard(card) then
		use.card = card
	end
end

function SmartAI:damageMinusHp(self, enemy, type)
		local trick_effectivenum = 0
		local slash_damagenum = 0
		local analepticpowerup = 0
		local effectivefireattacknum = 0
		local basicnum = 0
		local cards = self.player:getCards("he")
		cards = sgs.QList2Table(cards)
		for _, acard in ipairs(cards) do
			if acard:getTypeId() == sgs.Card_TypeBasic and not acard:isKindOf("Peach") then basicnum = basicnum + 1 end
		end
		for _, acard in ipairs(cards) do
			if ((acard:isKindOf("Duel") or acard:isKindOf("SavageAssault") or acard:isKindOf("ArcheryAttack") or acard:isKindOf("FireAttack"))
			and not self.room:isProhibited(self.player, enemy, acard))
			or ((acard:isKindOf("SavageAssault") or acard:isKindOf("ArcheryAttack")) and self:aoeIsEffective(acard, enemy)) then
				if acard:isKindOf("FireAttack") then
					if not enemy:isKongcheng() then
					effectivefireattacknum = effectivefireattacknum + 1
					else
					trick_effectivenum = trick_effectivenum -1
					end
				end
				trick_effectivenum = trick_effectivenum + 1
			elseif acard:isKindOf("Slash") and self:slashIsEffective(acard, enemy) and (slash_damagenum == 0 or self:hasCrossbowEffect())
				and self.player:inMyAttackRange(enemy) then
				if not (enemy:hasSkill("xiangle") and basicnum < 2) then
					slash_damagenum = slash_damagenum + 1
				end
				if self:getCardsNum("Analeptic") > 0 and analepticpowerup == 0
					and not (self:hasSilverLionEffect(enemy) or self:hasEightDiagramEffect(enemy)) then
						slash_damagenum = slash_damagenum + 1
						analepticpowerup = analepticpowerup + 1
				end
				if self.player:hasWeapon("guding_blade")
					and (enemy:isKongcheng() or (self.player:hasSkill("lihun") and enemy:isMale() and not enemy:hasSkill("kongcheng")))
					and not self:hasSilverLionEffect(enemy) then
					slash_damagenum = slash_damagenum + 1
				end
			end
		end
		if type == 0 then return (trick_effectivenum + slash_damagenum - effectivefireattacknum - enemy:getHp())
		else return (trick_effectivenum + slash_damagenum - enemy:getHp()) end
	return -10
end

function SmartAI:needRende()
	return self.player:getLostHp() > 1 and self:findFriendsByType(sgs.Friend_Draw)
			and ((self.player:hasSkill("nosrende") and self.player:getMark("nosrende") < 2)
				or (self.player:hasSkill("rende") and not self.player:hasUsed("RendeCard") and self.player:getMark("rende") < 2))
end

function hasBuquEffect(player)
	return (player:hasSkill("buqu") and player:getPile("buqu"):length() <= 4) or (player:hasSkill("nosbuqu") and player:getPile("nosbuqu"):length() <= 4)
end

function SmartAI:needToThrowArmor(player)
	player = player or self.player
	if not player:getArmor() or not player:hasArmorEffect(player:getArmor():objectName()) then return false end
	if self:evaluateArmor(player:getArmor(), player) <= 0 then return true end
	if player:hasSkills("bazhen|yizhong") then return true end
	if player:hasSkills("bossmanjia") and sgs.ai_armor_value.vine(self.player, self, true) > 0 then return true end
	if player:hasArmorEffect("silver_lion") and player:isWounded() then
		if self:isFriend(player) then
			if player:objectName() == self.player:objectName() then
				return true
			else
				return self:isWeak(player) or not player:hasSkills(sgs.use_lion_skill)
			end
		else
			return true
		end
	end
	local FS = sgs.cloneCard("fire_slash")
	if player:objectName() ~= self.player:objectName() and self:isEnemy(player) and self.player:getPhase() == sgs.Player_Play and self:slashIsAvailable()
		and not self:slashProhibit(FS, player, self.player) and player:hasArmorEffect("vine")
		and (self:getCard("FireSlash") or (self:getCard("Slash") and (self.player:hasWeapon("fan") or self.player:hasSkill("lihuo") or self:getCardsNum("Fan") >= 1)))
		and (player:isKongcheng() or sgs.card_lack[player:objectName()]["Jink"] == 1 or getCardsNum("Jink", player, self.player) < 1) then
		return true
	end
	return false
end

function SmartAI:doNotDiscard(to, flags, conservative, n, reason)
	if not to then global_room:writeToConsole(debug.traceback()) return end
	flags = flags or "he"
	n = n or 1
	if to:isNude() then return true end
	local enemies = self:getEnemies(to)
	local good_enemy = false
	for _, enemy in ipairs(enemies) do
		if not enemy:hasSkills("nosqianxun|noswuyan|weimu") then
			good_enemy = true
			break
		end
	end
	if conservative and not good_enemy then conservative = false end
	conservative = conservative or (sgs.turncount <= 2 and self.room:alivePlayerCount() > 2)
	if to:hasSkills("tuntian+zaoxian") and to:getPhase() == sgs.Player_NotActive and (conservative or (good_enemy and #self.enemies > 1)) then return true end

	if flags == "nil" then
		if to:hasSkill("lirang") and #self.enemies > 1 then return true end
		if self:needKongcheng(to) and to:getHandcardNum() <= n then return true end
		if self:getLeastHandcardNum(to) <= n then return true end
		if to:hasSkills(sgs.lose_equip_skill) and to:hasEquip() then return true end
		if self:needToThrowArmor(to) then return true end
	else
		if flags:match("e") then
			if to:hasSkills("jieyin+xiaoji") and to:getDefensiveHorse() then return false end
			if to:hasSkills("jieyin+xiaoji") and to:getArmor() and not to:getArmor():isKindOf("SilverLion") then return false end
		end
		if flags == "h" or (flags == "he" and not to:hasEquip()) then
			if to:isKongcheng() or not self.player:canDiscard(to, "h") then return true end
			if not self:hasLoseHandcardEffective(to) then return true end
			if #self.friends > 1 and to:getHandcardNum() <= n and to:hasSkill("sijian") then return false end
			if to:getHandcardNum() <= n and self:needKongcheng(to) then return true end
		elseif flags:match("e") then
			if not self.player:canDiscard(to, "e") then return true end
			if to:hasSkills(sgs.lose_equip_skill) and to:getHandcardNum() < n then return true end
			if to:getCardCount() <= n and to:getArmor() and self:needToThrowArmor(to) then return true end
		end
	end
	if flags == "he" and n > 2 then
		if not self.player:canDiscard(to, "e") then return true end
		if to:getCardCount() < n then return true end
	end
	return false
end

function SmartAI:findPlayerToDiscard(flags, include_self, isDiscard, players, return_table)
	local player_table = {}
	if isDiscard == nil then isDiscard = true end
	local friends, enemies = {}, {}
	if not players then
		friends = include_self and self.friends or self.friends_noself
		enemies = self.enemies
	else
		for _, player in sgs.qlist(players) do
			if self:isFriend(player) and (include_self or player:objectName() ~= self.player:objectName()) then table.insert(friends, player)
			elseif self:isEnemy(player) then table.insert(enemies, player) end
		end
	end
	flags = flags or "he"

	self:sort(enemies, "defense")
	if flags:match("e") then
		for _, enemy in ipairs(enemies) do
			if self.player:canDiscard(enemy, "e") then
				local dangerous = self:getDangerousCard(enemy)
				if dangerous and (not isDiscard or self.player:canDiscard(enemy, dangerous)) then
					table.insert(player_table, enemy)
				end
			end
		end
		for _, enemy in ipairs(enemies) do
			if enemy:hasArmorEffect("eight_diagram") and not self:needToThrowArmor(enemy) and self.player:canDiscard(enemy, enemy:getArmor():getEffectiveId()) then
				table.insert(player_table, enemy)
			end
		end
	end

	if flags:match("j") then
		for _, friend in ipairs(friends) do
			if ((friend:containsTrick("indulgence") and not friend:hasSkill("keji")) or friend:containsTrick("supply_shortage"))
				and not friend:containsTrick("YanxiaoCard") and not (friend:hasSkill("qiaobian") and not friend:isKongcheng())
				and (not isDiscard or self.player:canDiscard(friend, "j")) then
				table.insert(player_table, friend)
			end
		end
		for _, friend in ipairs(friends) do
			if friend:containsTrick("lightning") and self:hasWizard(enemies, true) and (not isDiscard or self.player:canDiscard(friend, "j")) then table.insert(player_table, friend) end
		end
		for _, enemy in ipairs(enemies) do
			if enemy:containsTrick("lightning") and self:hasWizard(enemies, true) and (not isDiscard or self.player:canDiscard(enemy, "j")) then table.insert(player_table, enemy) end
		end
	end

	if flags:match("e") then
		for _, friend in ipairs(friends) do
			if self:needToThrowArmor(friend) and (not isDiscard or self.player:canDiscard(friend, friend:getArmor():getEffectiveId())) then
				table.insert(player_table, friend)
			end
		end
		for _, enemy in ipairs(enemies) do
			if self.player:canDiscard(enemy, "e") then
				local valuable = self:getValuableCard(enemy)
				if valuable and (not isDiscard or self.player:canDiscard(enemy, valuable)) then
					table.insert(player_table, enemy)
				end
			end
		end
		for _, enemy in ipairs(enemies) do
			if enemy:hasSkills("jijiu|beige|mingce|weimu|qingcheng") and not self:doNotDiscard(enemy, "e") then
				if enemy:getDefensiveHorse() and (not isDiscard or self.player:canDiscard(enemy, enemy:getDefensiveHorse():getEffectiveId())) then table.insert(player_table, enemy) end
				if enemy:getArmor() and not self:needToThrowArmor(enemy) and (not isDiscard or self.player:canDiscard(enemy, enemy:getArmor():getEffectiveId())) then table.insert(player_table, enemy) end
				if enemy:getOffensiveHorse() and (not enemy:hasSkill("jijiu") or enemy:getOffensiveHorse():isRed()) and (not isDiscard or self.player:canDiscard(enemy, enemy:getOffensiveHorse():getEffectiveId())) then
					table.insert(player_table, enemy)
				end
				if enemy:getWeapon() and (not enemy:hasSkill("jijiu") or enemy:getWeapon():isRed()) and (not isDiscard or self.player:canDiscard(enemy, enemy:getWeapon():getEffectiveId())) then
					table.insert(player_table, enemy)
				end
			end
		end
	end

	if flags:match("h") then
		for _, enemy in ipairs(enemies) do
			local cards = sgs.QList2Table(enemy:getHandcards())
			local flag = string.format("%s_%s_%s","visible", self.player:objectName(), enemy:objectName())
			if #cards <= 2 and not enemy:isKongcheng() and not (enemy:hasSkills("tuntian+zaoxian") and enemy:getPhase() == sgs.Player_NotActive) then
				for _, cc in ipairs(cards) do
					if (cc:hasFlag("visible") or cc:hasFlag(flag)) and (cc:isKindOf("Peach") or cc:isKindOf("Analeptic")) and (not isDiscard or self.player:canDiscard(enemy, cc:getId())) then
						table.insert(player_table, enemy)
					end
				end
			end
		end
	end

	if flags:match("e") then
		for _, enemy in ipairs(enemies) do
			if enemy:hasEquip() and not self:doNotDiscard(enemy, "e") and (not isDiscard or self.player:canDiscard(enemy, "e")) then
				table.insert(player_table, enemy)
			end
		end
	end

	if flags:match("j") then
		for _, enemy in ipairs(enemies) do
			if enemy:containsTrick("YanxiaoCard") and (not isDiscard or self.player:canDiscard(enemy, "j")) then table.insert(player_table, enemy) end
		end
	end

	if flags:match("h") then
		self:sort(enemies, "handcard")
		for _, enemy in ipairs(enemies) do
			if (not isDiscard or self.player:canDiscard(enemy, "h")) and not self:doNotDiscard(enemy, "h") then
				table.insert(player_table, enemy)
			end
		end
	end

	if flags:match("h") then
		local zhugeliang = self.room:findPlayerBySkillName("kongcheng")
		if zhugeliang and self:isFriend(zhugeliang) and zhugeliang:getHandcardNum() == 1 and self:getEnemyNumBySeat(self.player, zhugeliang) > 0
			and zhugeliang:getHp() <= 2 and (not isDiscard or self.player:canDiscard(zhugeliang, "h")) then
			table.insert(player_table, zhugeliang)
		end
	end
	if return_table then return player_table
	else
		if #player_table == 0 then return nil else return player_table[1] end
	end
end

function SmartAI:findPlayerToDraw(include_self, drawnum)
	drawnum = drawnum or 1
	local players = sgs.QList2Table(include_self and self.room:getAllPlayers() or self.room:getOtherPlayers(self.player))
	local friends = {}
	for _, player in ipairs(players) do
		if self:isFriend(player) and not hasManjuanEffect(player)
			and not (player:hasSkill("kongcheng") and player:isKongcheng() and drawnum <= 2) then
			table.insert(friends, player)
		end
	end
	if #friends == 0 then return end

	self:sort(friends, "defense")
	for _, friend in ipairs(friends) do
		if friend:getHandcardNum() < 2 and not self:needKongcheng(friend) and not self:willSkipPlayPhase(friend) then
			return friend
		end
	end

	for _, friend in ipairs(friends) do
		if friend:hasSkills(sgs.cardneed_skill) and not self:willSkipPlayPhase(friend) then
			return friend
		end
	end

	self:sort(friends, "handcard")
	for _, friend in ipairs(friends) do
		if not self:needKongcheng(friend) and not self:willSkipPlayPhase(friend) then
			return friend
		end
	end
	return nil
end

function getBestHp(player)
	local arr = { ganlu = 1, yinghun = 1, nosmiji = 1, xueji = 1, baobian = math.max(0, player:getMaxHp() - 3), shangshi = 1, nosshangshi = 1 }

	if player:hasSkill("longhun") and player:getCards("he"):length() > 2 then return 1 end
	if player:hasSkill("hunzi") and player:getMark("hunzi") == 0 then return 2 end

	for skill, dec in pairs(arr) do
		if player:hasSkill(skill) then
			return math.max((player:isLord() and 3 or 2), player:getMaxHp() - dec)
		end
	end

	if player:hasSkills("renjie+baiyin") and player:getMark("baiyin") == 0 then return (player:getMaxHp() - 1) end
	if player:hasSkills("quanji+zili") and player:getMark("zili") == 0 then return (player:getMaxHp() - 1) end
	return player:getMaxHp()
end

function SmartAI:findFriendsByType(prompt, player)
	player = player or self.player
	local friends = self:getFriendsNoself(player)
	if #friends < 1 then return false end
	if prompt == sgs.Friend_Draw then
		for _, friend in ipairs(friends) do
			if not friend:hasSkill("manjuan") and not self:needKongcheng(friend, true) then return true end
		end
	elseif prompt == sgs.Friend_Male then
		for _, friend in ipairs(friends) do
			if friend:isMale() then return true end
		end
	elseif prompt == sgs.Friend_MaleWounded then
		for _, friend in ipairs(friends) do
			if friend:isMale() and friend:isWounded() then return true end
		end
	elseif prompt == sgs.Friend_All then
		return true
	else
		global_room:writeToConsole(debug.traceback())
		return
	end
	return false
end

function SmartAI:needToLoseHp(to, from, isSlash, passive)
	from = from or self.room:getCurrent()
	to = to or self.player
	if isSlash and not from:hasSkill("jueqing") then
		if from:hasSkill("nosqianxi") and from:distanceTo(to) == 1 then
			return false
		end
		if from:hasWeapon("ice_sword") and to:getCards("he"):length() > 1 and not self:isFriend(from, to) then
			return false
		end
		if self:hasHeavySlashDamage(from, nil, to) then return false end
	end
	if from:hasSkill("jueqing") and to:hasSkills(sgs.masochism_skill) then return false end

	local n = getBestHp(to)
	if not passive then
		if to:getMaxHp() > 2 then
			if to:hasSkills("miji|nosmiji") and self:findFriendsByType(sgs.Friend_Draw, to) then n = math.min(n, to:getMaxHp() - 1) end
			if (to:hasSkill("nosrende") or (to:hasSkill("rende") and not to:hasUsed("RendeCard")))
				and not self:willSkipPlayPhase(to) and self:findFriendsByType(sgs.Friend_Draw, to) then n = math.min(n, to:getMaxHp() - 1) end
		end
	end

	local friends = self:getFriendsNoself(to)
	local need_jieyin
	local sunshangxiang = self.room:findPlayerBySkillName("jieyin")
	if sunshangxiang and sunshangxiang:isWounded() and self:isFriend(sunshangxiang, to)
		and not sunshangxiang:isNude() and not self:willSkipPlayPhase(sunshangxiang)
		and not to:isWounded() and to:isMale() then
		need_jieyin = true
		self:sort(friends, "hp")
		for _, friend in ipairs(friends) do
			if friend:isMale() and friend:isWounded() then need_jieyin = false end
		end
		if need_jieyin then n = math.min(n, to:getMaxHp() - 1) end
	end

	return to:getHp() > n
end

dofile "lua/ai/debug-ai.lua"
dofile "lua/ai/standard_cards-ai.lua"
dofile "lua/ai/maneuvering-ai.lua"
dofile "lua/ai/standard-ai.lua"
dofile "lua/ai/basara-ai.lua"
dofile "lua/ai/boss-ai.lua"
dofile "lua/ai/hulaoguan-ai.lua"
dofile "lua/ai/jiange_defense-ai.lua"
dofile "lua/ai/conversion-ai.lua"

local loaded = "standard|standard_cards|maneuvering"

local ai_files = sgs.GetFileNames("lua/ai")

for _, aextension in ipairs(sgs.Sanguosha:getExtensions()) do
	if not loaded:match(aextension) then
		local file_name = string.lower(aextension) .. "-ai.lua"
		if table.contains(ai_files, file_name) then dofile("lua/ai/" .. file_name) end
	end
end

for _, ascenario in ipairs(sgs.Sanguosha:getModScenarioNames()) do
	if not loaded:match(ascenario) then
		local file_name = string.lower(ascenario) .. "-ai.lua"
		if table.contains(ai_files, file_name) then dofile("lua/ai/" .. file_name) end
	end
end