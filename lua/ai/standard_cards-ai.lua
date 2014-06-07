function SmartAI:canAttack(enemy, attacker, nature)
	attacker = attacker or self.player
	if (#self:getEnemies(attacker) == 1 and sgs.turncount > 1) or attacker:hasSkill("jueqing") then return true end
	nature = nature or sgs.DamageStruct_Normal
	if not self:damageIsEffective(enemy, nature, attacker) then return false end
	local damage = 1
	if nature == sgs.DamageStruct_Fire and not enemy:hasArmorEffect("silver_lion") then
		if enemy:hasArmorEffect("vine") then damage = damage + 1 end
		if enemy:getMark("@gale") > 0 then damage = damage + 1 end
	end
	if self:getDamagedEffects(enemy, attacker) or (self:needToLoseHp(enemy, attacker, false, true) and #self:getEnemies(attacker) > 1) or not sgs.isGoodTarget(enemy, self.enemies, self) then return false end
	if self:objectiveLevel(enemy) <= 2 or self:cantbeHurt(enemy, self.player, damage) or not self:damageIsEffective(enemy, nature, attacker) then return false end
	if nature ~= sgs.DamageStruct_Normal and enemy:isChained() and not self:isGoodChainTarget(enemy, self.player, nature) then return false end
	return true
end

function SmartAI:hasExplicitRebel()
	for _, player in sgs.qlist(self.room:getAllPlayers()) do
		if sgs.isRolePredictable() and sgs.evaluatePlayerRole(player) == "rebel" then return true end
		if sgs.compareRoleEvaluation(player, "rebel", "loyalist") == "rebel" then return true end
	end
	return false
end

function sgs.isGoodHp(player)
	local goodHp = player:getHp() > 1 or getCardsNum("Peach", player) >= 1 or getCardsNum("Analeptic", player) >= 1
					or hasBuquEffect(player)
					or (player:hasSkill("niepan") and player:getMark("@nirvana") > 0)
					or (player:hasSkill("fuli") and player:getMark("@laoji") > 0)
	if goodHp then
		return goodHp
	else
		for _, p in sgs.qlist(global_room:getOtherPlayers(player)) do
			if sgs.compareRoleEvaluation(p, "rebel", "loyalist") == sgs.compareRoleEvaluation(player, "rebel", "loyalist")
				and getCardsNum("Peach", p) > 0 and not global_room:getCurrent():hasSkill("wansha") then
				return true
			end
		end
		return false
	end
end

function sgs.isGoodTarget(player, targets, self, isSlash)
	local arr = { "jieming", "nosyiji", "yiji", "guixin", "fangzhu", "vsganglie", "nosmiji" }
	local m_skill = false
	local attacker = global_room:getCurrent()

	if targets and type(targets) == "table" then
		if #targets == 1 then return true end
		local foundtarget = false
		for i = 1, #targets, 1 do
			if sgs.isGoodTarget(targets[i]) and not self:cantbeHurt(targets[i]) then
				foundtarget = true
				break
			end
		end
		if not foundtarget then return true end
	end

	for _, masochism in ipairs(arr) do
		if player:hasSkill(masochism) then
			if masochism == "nosmiji" and player:isWounded() then m_skill = false
			elseif attacker and attacker:hasSkill("jueqing") then m_skill = false
			elseif masochism == "jieming" and self and self:getJiemingChaofeng(player) > -4 then m_skill = false
			elseif masochism == "nosyiji" and self and not self:findFriendsByType(sgs.Friend_Draw, player) then m_skill = false
			else
				m_skill = true
				break
			end
		end
	end

	if not (attacker and attacker:hasSkill("jueqing")) and player:hasSkill("huilei") and not player:isLord() and player:getHp() == 1 then
		if attacker and attacker:getHandcardNum() >= 4 then return false end
		return sgs.compareRoleEvaluation(player, "rebel", "loyalist") == "rebel"
	end

	if not (attacker and attacker:hasSkill("jueqing")) and player:hasSkill("wuhun") and not player:isLord()
		and ((attacker and attacker:isLord()) or player:getHp() <= 2) then
		return false
	end

	if player:hasLordSkill("shichou") and player:getMark("@hate") == 0 then
		for _, p in sgs.qlist(player:getRoom():getOtherPlayers(player)) do
			if p:getMark("hate_" .. player:objectName()) > 0 and p:getMark("@hate_to") > 0 then
				return false
			end
		end
	end

	if isSlash and self and (self:hasCrossbowEffect() or self:getCardsNum("Crossbow") > 0) and self:getCardsNum("Slash") > player:getHp() then
		return true
	end

	if player:hasSkill("hunzi") and player:getMark("hunzi") == 0 and player:isLord() and player:getHp() == 2 and sgs.current_mode_players["loyalist"] > 0 then
		return false
	end

	if (m_skill or player:hasSkills("fenyong+xuehen")) and sgs.isGoodHp(player) then
		return false
	else
		return true
	end
end

function sgs.getDefenseSlash(player, self)
	local attacker = global_room:getCurrent()
	local defense = getCardsNum("Jink", player)

	local knownJink = getKnownCard(player, nil, "Jink", true)
	if sgs.card_lack[player:objectName()]["Jink"] == 1 and knownJink == 0 then defense = 0 end
	defense = defense + knownJink * 1.2
	
	local jink = sgs.cloneCard("jink")
	if player:isCardLimited(jink, sgs.Card_MethodUse) then defense = 0 end

	if (player:hasArmorEffect("eight_diagram") or player:hasArmorEffect("bazhen")) and not attacker:hasWeapon("qinggang_sword") then
		hasEightDiagram = true
	end

	if player:getMark("yijue") > 0 then
		defense = 0
	elseif player:getMark("@qianxi_red") > 0 and (not player:hasSkill("qingguo") and not (player:hasSkill("longhun") and player:getHp() == 1)) then
		defense = 0
	elseif player:getMark("@qianxi_black") > 0 then
		if player:hasSkill("qingguo") then defense = defense / 2 end
		if player:hasSkill("longhun") and player:getHp() == 1 then defense = defense * 3 / 4 end
	end

	if hasEightDiagram then
		defense = defense + 1.5
		if player:hasSkill("tiandu") then defense = defense + 0.6 end
		if player:hasSkills("guicai|nosguicai") or player:hasSkill("huanshi") then defense = defense + 0.3 end
	end

	if player:hasSkills("tuntian+zaoxian") and getCardsNum("Jink", player) > 0 and player:getMark("yijue") == 0 then defense = defense + 1.5 end
	if player:hasSkill("aocai") and player:getPhase() == sgs.Player_NotActive then defense = defense + 0.5 end
	if player:hasSkill("wanrong") and not hasManjuanEffect(player) then defense = defense + 0.5 end

	local hujiaJink = 0
	if player:hasLordSkill("hujia") then
		local lieges = global_room:getLieges("wei", player)
		for _, liege in sgs.qlist(lieges) do
			if sgs.compareRoleEvaluation(liege, "rebel", "loyalist") == sgs.compareRoleEvaluation(player, "rebel", "loyalist") then
				hujiaJink = hujiaJink + getCardsNum("Jink", liege)
				if liege:hasArmorEffect("eight_diagram") or liege:hasArmorEffect("bazhen") then hujiaJink = hujiaJink + 0.8 end
			end
		end
		defense = defense + hujiaJink
	end

	if attacker and attacker:objectName() ~= player:objectName() and attacker:canSlashWithoutCrossbow() then
		if not sgs.isJinkAvailable(attacker, player) then defense = 0 end
	end

	if defense > 0 and attacker:objectName() ~= player:objectName() then
		local jiangqin = global_room:findPlayerBySkillName("niaoxiang")
		local need_double_jink = attacker:hasSkill("wushuang")
								or (attacker:hasSkill("roulin") and player:isFemale())
								or (player:hasSkill("roulin") and attacker:isFemale())
								or (jiangqin and jiangqin:isAdjacentTo(player) and attacker:isAdjacentTo(player) and self and self:isEnemy(jiangqin))
		if need_double_jink and getKnownCard(player, nil, "Jink", true, "he") < 2
			and getCardsNum("Jink", player) < 1.5
			and (not player:hasLordSkill("hujia") or hujiaJink < 2) then
			defense = 0
		end

		if attacker:hasSkill("dahe") and player:hasFlag("dahe") and getKnownNum(player) / player:getHandcardNum() >= 0.7 then
			local cards = player:getHandcards()
			local known = 0
			for _, card in sgs.qlist(cards) do
				local flag = string.format("%s_%s_%s", "visible", global_room:getCurrent():objectName(), player:objectName())
				if isCard("Jink", card, player) and (card:hasFlag("visible") or card:hasFlag(flag)) then
					known = known + 1
				end
			end
			for _, card in sgs.qlist(player:getEquips()) do
				if isCard("Jink", card, player) then
					known = known + 1
				end
			end
			if known == 0 then defense = 0 end
		end
	end

	if attacker and not attacker:hasSkill("jueqing") and attacker:objectName() ~= player:objectName() then
		local m = sgs.masochism_skill:split("|")
		for _, masochism in ipairs(m) do
			if player:hasSkill(masochism) and sgs.isGoodHp(player) then defense = defense + 1 end
		end
		if attacker:getWeapon() and player:hasSkill("duodao") and player:canDiscard(player, "he") then defense = defense + 1 end
		if player:hasSkill("jieming") then defense = defense + 3 end
		if player:hasSkill("nosyiji") then defense = defense + 3 end
		if player:hasSkill("yiji") then defense = defense + 3 end
		if player:hasSkill("guixin") then defense = defense + 4 end
		if player:hasSkill("yuce") then defense = defense + 1 end
	end
	if attacker and attacker:hasSkill("jueqing") and attacker:objectName() ~= player:objectName() and player:hasSkill("zhaxiang") then defense = defense + 4 end

	if not sgs.isGoodTarget(player) then defense = defense + 10 end

	if player:hasSkills("nosrende|rende") and player:getHp() > 2 then defense = defense + 1 end
	if player:hasSkill("kuanggu") and player:getHp() > 1 then defense = defense + 0.2 end
	if player:hasSkill("kofkuanggu") and player:getHp() > 1 then defense = defense + 0.25 end
	if player:hasSkill("zaiqi") and player:getHp() > 1 then defense = defense + 0.35 end
	if player:hasSkill("tianming") then defense = defense + 0.1 end
	if player:hasSkill("yajiao") then defense = defense + 0.1 end

	if player:getHp() > getBestHp(player) then defense = defense + 1.3 end
	if player:hasSkill("tianxiang") then defense = defense + player:getHandcardNum() * 0.5 end

	if player:getHp() <= 2 then defense = defense - 0.4 end

	local playernum = global_room:alivePlayerCount()
	if (player:getSeat() - attacker:getSeat()) % playernum >= playernum - 2 and playernum > 3 and player:getHandcardNum() <= 2 and player:getHp() <= 2 then
		defense = defense - 0.4
	end

	if player:getHandcardNum() == 0 and player:getPile("wooden_ox"):isEmpty() and hujiaJink == 0 and not player:hasSkill("kongcheng") then
		if player:getHp() <= 1 then defense = defense - 2.5 end
		if player:getHp() == 2 then defense = defense - 1.5 end
		if not hasEightDiagram then defense = defense - 2 end
		if attacker:hasWeapon("guding_blade") and attacker:objectName() ~= player:objectName() and not player:hasArmorEffect("silver_lion") and not attacker:hasWeapon("qinggang_sword") then
			defense = defense - 2
		end
	end

	local has_fire_slash = 0
	local cards = sgs.QList2Table(attacker:getHandcards())
	for i = 1, #cards, 1 do
		if cards[i]:objectName() == "slash" then
			if attacker:hasWeapon("fan") then
				has_fire_slash = 1
				break
			elseif attacker:hasSkill("lihuo") then
				has_fire_slash = 2
				break
			end
		end
	end

	if player:hasArmorEffect("vine") and attacker:objectName() ~= player:objectName() and not attacker:hasWeapon("qinggang_sword") and has_fire_slash > 0 then
		defense = defense - 0.6 / has_fire_slash
	end

	if player:isLord() then
		defense = defense - 0.4
		if sgs.isLordInDanger() then defense = defense - 0.7 end
	end

	if not player:faceUp() then defense = defense - 0.35 end

	if player:containsTrick("indulgence") and not player:containsTrick("YanxiaoCard") then defense = defense - 0.15 end
	if player:containsTrick("supply_shortage") and not player:containsTrick("YanxiaoCard") then defense = defense - 0.15 end

	if (attacker:hasSkill("roulin") and player:isFemale()) or (attacker:isFemale() and player:hasSkill("roulin")) then
		defense = defense - 0.4
	end

	if not hasEightDiagram then
		if player:hasSkill("jijiu") then defense = defense - 3 end
		if player:hasSkill("dimeng") then defense = defense - 2.5 end
		if player:hasSkill("guzheng") and knownJink == 0 then defense = defense - 2.5 end
		if player:hasSkill("qiaobian") then defense = defense - 2.4 end
		if player:hasSkill("jieyin") then defense = defense - 2.3 end
		if player:hasSkills("noslijian|lijian") then defense = defense - 2.2 end
		if player:hasSkill("nosmiji") and player:isWounded() then defense = defense - 1.5 end
	end
	return defense
end

sgs.ai_compare_funcs["defenseSlash"] = function(a, b)
	return sgs.getDefenseSlash(a) < sgs.getDefenseSlash(b)
end

function SmartAI:slashProhibit(card, enemy, from)
	card = card or sgs.cloneCard("slash")
	from = from or self.player
	if self.room:isProhibited(from, enemy, card) then return true end
	local nature = sgs.DamageStruct_Normal
	if card:isKindOf("FireSlash") then nature = sgs.DamageStruct_Fire
	elseif card:isKindOf("ThunderSlash") then nature = sgs.DamageStruct_Thunder end
	for _, askill in ipairs(sgs.getPlayerSkillList(enemy)) do
		local filter = sgs.ai_slash_prohibit[askill:objectName()]
		if filter and type(filter) == "function" and filter(self, from, enemy, card) then return true end
	end

	if self:isFriend(enemy, from) then
		if card:isKindOf("FireSlash") or from:hasSkill("lihuo") or from:hasWeapon("fan") then
			if enemy:hasArmorEffect("vine") and not (enemy:isChained() and self:isGoodChainTarget(enemy, from, nature, nil, card)) then return true end
		end
		if enemy:isChained() and card:isKindOf("NatureSlash") and (not self:isGoodChainTarget(enemy, from, nature, nil, card) and not from:hasSkill("jueqing"))
			and self:slashIsEffective(card, enemy, from) then return true end
		if getCardsNum("Jink", enemy, from) == 0 and enemy:getHp() < 2 and self:slashIsEffective(card, enemy, from) then return true end
		if enemy:isLord() and self:isWeak(enemy) and self:slashIsEffective(card, enemy, from) then return true end
		if from:hasWeapon("guding_blade") and enemy:isKongcheng() then return true end
	else
		if card:isKindOf("NatureSlash") and not from:hasSkill("jueqing") and enemy:isChained()
			and not self:isGoodChainTarget(enemy, from, nature, nil, card) and self:slashIsEffective(card, enemy, nil, from) then
			return true
		end
	end

	return not self:slashIsEffective(card, enemy, from)
end

function SmartAI:canLiuli(other, another)
	if not other:hasSkill("liuli") then return false end
	if type(another) == "table" then
		if #another == 0 then return false end
		for _, target in ipairs(another) do
			if target:getHp() < 3 and self:canLiuli(other, target) then return true end
		end
		return false
	end
	if not self:needToLoseHp(another, self.player, true) or not self:getDamagedEffects(another, self.player, true) then return false end
	local n = other:getHandcardNum()
	if n > 0 and other:inMyAttackRange(another) then return true
	elseif other:getWeapon() and other:getOffensiveHorse() and other:inMyAttackRange(another) then return true
	elseif other:getWeapon() or other:getOffensiveHorse() then return other:distanceTo(another) <= 1
	else return false end
end

function SmartAI:slashIsEffective(slash, to, from, ignore_armor)
	if not slash or not to then self.room:writeToConsole(debug.traceback()) return false end
	from = from or self.player
	if not ignore_armor and from:objectName() == self.player:objectName() then
		if self.moukui_effect then
			ignore_armor = true
		elseif to:getArmor() and from:hasSkill("moukui") then
			if not self:isFriend(to) or (to:getArmor() and self:needToThrowArmor(to, true)) then
				if not (self:isEnemy(to) and self:doNotDiscard(to)) then
					self.moukui_effect = slash
					local id = self:askForCardChosen(to, "he", "dummy")
					self.moukui_effect = nil
					if id == to:getArmor():getEffectiveId() then ignore_armor = true end
				end
			end
		end
	end
	local cloned
	if not slash:isKindOf("Slash") then
		cloned = true
		slash = sgs.cloneCard("slash")
	end
	if to:getPile("dream"):length() > 0 and to:isLocked(slash) then return false end
	if to:hasSkill("yizhong") and not to:getArmor() then
		if slash:isBlack() then
			return false
		end
	end
	if to:getMark("@late") > 0 then return false end

	local natures = {
		Slash = sgs.DamageStruct_Normal,
		FireSlash = sgs.DamageStruct_Fire,
		ThunderSlash = sgs.DamageStruct_Thunder,
	}

	local nature = natures[slash:getClassName()]
	self.equipsToDec = sgs.getCardNumAtCertainPlace(slash, from, sgs.Player_PlaceEquip)
	local eff = self:damageIsEffective(to, nature, from)
	self.equipsToDec = 0
	if not eff then return false end
	if self:isFriend(from, to) and from:hasSkill("chuanxin")
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

	if (to:hasArmorEffect("vine") or to:getMark("@gale") > 0) and self:getCardId("FireSlash") and slash:isKindOf("ThunderSlash") and self:objectiveLevel(to) >= 3 then
		return false
	end

	local skillname = slash:getSkillName()
	local changed = not cloned and slash:isVirtualCard() and slash:subcardsLength() > 0
					and not (skillname == "hongyan" or skillname == "jinjiu" or skillname == "wushen" or skillname == "guhuo" or skillname == "nosguhuo")
	if not from:hasWeapon("qinggang_sword") and not ignore_armor then
		if to:hasArmorEffect("renwang_shield") and slash:isBlack() then return false end
		if to:hasArmorEffect("vine")
			and not (nature ~= sgs.DamageStruct_Normal or (not changed and (from:hasWeapon("fan") or (from:hasSkill("lihuo") and not self:isWeak(from))))) then
			return false
		end
	end
	if slash:isKindOf("ThunderSlash") then
		local f_slash = self:getCard("FireSlash")
		if f_slash and self:hasHeavySlashDamage(from, f_slash, to, true) > self:hasHeavySlashDamage(from, slash, to, true)
			and (not to:isChained() or self:isGoodChainTarget(to, from, sgs.DamageStruct_Fire, nil, f_slash)) then
			return self:slashProhibit(f_slash, to, from)
		end
	elseif slash:isKindOf("FireSlash") then
		local t_slash = self:getCard("ThunderSlash")
		if t_slash and self:hasHeavySlashDamage(from, t_slash, to, true) > self:hasHeavySlashDamage(from, slash, to, true)
			and (not to:isChained() or self:isGoodChainTarget(to, from, sgs.DamageStruct_Thunder, nil, t_slash)) then
			return self:slashProhibit(t_slash, to, from)
		end
	end

	return true
end

function SmartAI:slashIsAvailable(player, slash)
	player = player or self.player
	slash = slash or self:getCard("Slash", player)
	if not slash or not slash:isKindOf("Slash") then slash = sgs.cloneCard("slash") end
	assert(slash)
	return slash:isAvailable(player)
end

function sgs.isJinkAvailable(from, to, slash, judge_considered)
	return (not judge_considered and from:hasSkills("tieji|nostieji"))
			or (from:hasSkill("liegong") and from:getPhase() == sgs.Player_Play
				and (to:getHandcardNum() <= from:getAttackRange() or to:getHandcardNum() >= from:getHp()))
			or (from:hasSkill("kofliegong") and from:getPhase() == sgs.Player_Play and to:getHandcardNum() >= from:getHp())
			or (from:hasFlag("ZhaxiangInvoked") and slash and slash:isRed())
end

function SmartAI:findWeaponToUse(enemy)
	local weaponvalue = {}
	local hasweapon
	for _, c in sgs.qlist(self.player:getHandcards()) do
		if c:isKindOf("Weapon") then
			local dummy_use = { isDummy == true }
			self:useEquipCard(c, dummy_use)
			if dummy_use.card then
				weaponvalue[c] = self:evaluateWeapon(c, self.player, enemy)
				hasweapon = true
			end
		end
	end
	if not hasweapon then return end
	if self.player:getWeapon() then weaponvalue[self.player:getWeapon()] = self:evaluateWeapon(self.player:getWeapon(), self.player, enemy) end
	local max_value, max_card = -1000
	for c, v in pairs(weaponvalue) do
		if v > max_value then max_card = c max_value = v end
	end
	if self.player:getWeapon() and self.player:getWeapon():getEffectiveId() == max_card:getEffectiveId() then return false end
	return max_card
end

function SmartAI:isPriorFriendOfSlash(friend, card, source)
	source = source or self.player
	if self:hasHeavySlashDamage(source, card, friend) or card:getSkillName() == "lihuo" then return false end
	local huatuo = self.room:findPlayerBySkillName("jijiu")
	return self:findLeijiTarget(friend, 50, source)
			or (not source:hasSkill("jueqing") and friend:isLord() and source:hasSkill("guagu") and friend:getLostHp() >= 1)
			or (not source:hasSkill("jueqing") and friend:hasSkill("jieming") and source:hasSkill("nosrende") and (huatuo and self:isFriend(huatuo, source)))
			or (friend:hasSkill("hunzi") and friend:getHp() == 2 and self:getDamagedEffects(friend, source))
			or (not source:hasSkill("jueqing") and card:isKindOf("NatureSlash") and friend:isChained() and self:isGoodChainTarget(friend, source, nil, nil, card))
			or (source:hasSkill("jueqing") and friend:hasSkill("zhaxiang") and not self:isWeak(friend) and not (friend:getHp() == 2 and friend:hasSkill("chanyuan")))
			or self:hasQiuyuanEffect(source, friend)
end

function SmartAI:useCardSlash(card, use)
	if not use.isDummy and not self:slashIsAvailable(self.player, card) then return end

	local basicnum = 0
	local cards = self.player:getCards("he")
	cards = sgs.QList2Table(cards)
	for _, acard in ipairs(cards) do
		if acard:getTypeId() == sgs.Card_TypeBasic and not acard:isKindOf("Peach") then basicnum = basicnum + 1 end
	end
	local no_distance = sgs.Sanguosha:correctCardTarget(sgs.TargetModSkill_DistanceLimit, self.player, card) > 50
						or self.player:hasFlag("slashNoDistanceLimit")
						or card:getSkillName() == "qiaoshui"
	self.slash_targets = 1 + sgs.Sanguosha:correctCardTarget(sgs.TargetModSkill_ExtraTarget, self.player, card)
	if use.isDummy and use.extra_target then self.slash_targets = self.slash_targets + use.extra_target end
	if self.player:hasSkill("duanbing") then self.slash_targets = self.slash_targets + 1 end

	local rangefix = 0
	if card:isVirtualCard() then
		if self.player:getWeapon() and card:getSubcards():contains(self.player:getWeapon():getEffectiveId()) then
			if self.player:getWeapon():getClassName() ~= "Weapon" then
				rangefix = sgs.weapon_range[self.player:getWeapon():getClassName()] - self.player:getAttackRange(false)
			end
		end
		if self.player:getOffensiveHorse() and card:getSubcards():contains(self.player:getOffensiveHorse():getEffectiveId()) then
			rangefix = rangefix + 1
		end
	end

	local function canAppendTarget(target)
		if use.to:contains(target) then return false end
		local targets = sgs.PlayerList()
		for _, to in sgs.qlist(use.to) do
			targets:append(to)
		end
		return card:targetFilter(targets, target, self.player)
	end

	if not use.isDummy and self.player:hasSkill("qingnang") and self:isWeak() and self:getOverflow() == 0 then return end
	for _, friend in ipairs(self.friends_noself) do
		local slash_prohibit = false
		slash_prohibit = self:slashProhibit(card, friend)
		if self:isPriorFriendOfSlash(friend, card) then
			if not slash_prohibit then
				if (not use.current_targets or not table.contains(use.current_targets, friend:objectName()))
					and (self.player:canSlash(friend, card, not no_distance, rangefix)
						or (use.isDummy and (self.player:distanceTo(friend, rangefix) <= self.predictedRange)))
					and self:slashIsEffective(card, friend) then
					use.card = card
					if use.to and canAppendTarget(friend) then
						use.to:append(friend)
					end
					if not use.to or self.slash_targets <= use.to:length() then return end
				end
			end
		end
	end

	local targets = {}
	local forbidden = {}
	self:sort(self.enemies, "defenseSlash")
	for _, enemy in ipairs(self.enemies) do
		if not self:slashProhibit(card, enemy) and sgs.isGoodTarget(enemy, self.enemies, self, true) and not self:hasLiyuEffect(enemy, card) then
			if not self:getDamagedEffects(enemy, self.player, true) and not self:hasQiuyuanEffect(self.player, enemy) then table.insert(targets, enemy)
			else table.insert(forbidden, enemy) end
		end
	end
	if #targets == 0 and #forbidden > 0 then targets = forbidden end

	for _, target in ipairs(targets) do
		local canliuli = false
		for _, friend in ipairs(self.friends_noself) do
			if self:canLiuli(target, friend) and self:slashIsEffective(card, friend) and #targets > 1 and friend:getHp() < 3 then canliuli = true end
		end
		local use_wuqian = false
		if self.player:hasSkill("wuqian") and self.player:getMark("@wrath") >= 2
			and (not self.player:hasSkill("wushuang") or target:getMark("Armor_Nullified") == 0)
			and not target:isLocked(sgs.cloneCard("jink")) and not target:isLocked(sgs.cloneCard("jink"), true)
			and (self:hasHeavySlashDamage(self.player, card, target)
				or (getCardsNum("Jink", target, self.player) < 2 and getCardsNum("Jink", target, self.player) >= 1 and target:getHp() <= 2)) then
			use_wuqian = true
		end
		if (not use.current_targets or not table.contains(use.current_targets, target:objectName()))
			and (self.player:canSlash(target, card, not no_distance, rangefix)
				or (use.isDummy and self.predictedRange and self.player:distanceTo(target, rangefix) <= self.predictedRange))
			and self:objectiveLevel(target) > 3
			and self:slashIsEffective(card, target, self.player, use_wuqian)
			and not (target:hasSkill("xiangle") and basicnum < 2)
			and not canliuli
			and not (not self:isWeak(target) and #self.enemies > 1 and #self.friends > 1 and self.player:hasSkill("keji")
			and self:getOverflow() > 0 and not self:hasCrossbowEffect()) then

			if target:getHp() > 1 and target:hasSkills("jianxiong|nosjianxiong") and card:getSkillName() == "spear" then
				local ids, isGood = card:getSubcards(), true
				for _, id in sgs.qlist(ids) do
					local c = sgs.Sanguosha:getCard(id)
					if isCard("Peach", c, target) or isCard("Analeptic", c, target) then isGood = false break end
				end
				if not isGood then continue end
			end
 
			-- fill the card use struct
			local usecard = card
			if not use.to or use.to:isEmpty() then
				if self.player:hasWeapon("spear") and card:getSkillName() == "spear" and self:getCardsNum("Slash") == 0 then
				elseif self.player:hasWeapon("crossbow") and self:getCardsNum("Slash") > 1 then
				elseif not use.isDummy then
					local card = self:findWeaponToUse(target)
					if card then
						use.card = card
						return
					end
				end
				if target:isChained() and self:isGoodChainTarget(target, nil, nil, nil, card) and not use.card then
					if self:hasCrossbowEffect() and card:isKindOf("NatureSlash") then
						local slashes = self:getCards("Slash")
						for _, slash in ipairs(slashes) do
							if not slash:isKindOf("NatureSlash") and self:slashIsEffective(slash, target)
								and not self:slashProhibit(slash, target) then
								usecard = slash
								break
							end
						end
					elseif not card:isKindOf("NatureSlash") then
						local slash = self:getCard("NatureSlash")
						if slash and self:slashIsEffective(slash, target) and not self:slashProhibit(slash, target) then usecard = slash end
					end
				end
				local godsalvation = self:getCard("GodSalvation")
				if not use.isDummy and godsalvation and godsalvation:getId() ~= card:getId() and self:willUseGodSalvation(godsalvation)
					and (not target:isWounded() or not self:hasTrickEffective(godsalvation, target, self.player)) then
					use.card = godsalvation
					return
				end
			end
			use.card = use.card or usecard
			if use.to and not use.to:contains(target) and canAppendTarget(target) then
				use.to:append(target)
			end
			if not use.isDummy then
				local analeptic = self:searchForAnaleptic(use, target, use.card)
				if analeptic and self:shouldUseAnaleptic(target, use.card) and analeptic:getEffectiveId() ~= card:getEffectiveId() then
					use.card = analeptic
					if use.to then use.to = sgs.SPlayerList() end
					return
				end
				if self.player:hasSkill("jilve") and self.player:getMark("@bear") > 0 and not self.player:hasFlag("JilveWansha") and not self.player:hasSkill("wansha")
					and target:getHp() == 1 and (target:isKongcheng() or getCardsNum("Jink", target, self.player) < 1 or sgs.card_lack[target:objectName()]["Jink"] == 1) then
					use.card = sgs.Card_Parse("@JilveCard=.")
					sgs.ai_skill_choice.jilve = "wansha"
					if use.to then use.to = sgs.SPlayerList() end
					return
				end
				if use_wuqian then
					use.card = sgs.Card_Parse("@WuqianCard=.")
					if use.to then
						use.to = sgs.SPlayerList()
						use.to:append(target)
					end
					return
				end
			end
			if not use.to or self.slash_targets <= use.to:length() then return end
		end
	end

	local nosqiuyuan_effect = false
	for _, enemy in ipairs(self.enemies) do
		if not enemy:isKongcheng() and not (enemy:getHandcardNum() == 1 and self:needKongcheng(enemy, true)) then
			nosqiuyuan_effect = true
			break
		end
	end
	for _, friend in ipairs(self.friends_noself) do
		local slash_prohibit = self:slashProhibit(card, friend)
		if (not use.current_targets or not table.contains(use.current_targets, friend:objectName()))
			and not self:hasHeavySlashDamage(self.player, card, friend) and card:getSkillName() ~= "lihuo"
			and (not use.to or not use.to:contains(friend))
			and (self.player:hasSkill("pojun") and friend:getHp() > 4 and getCardsNum("Jink", friend, self.player) == 0 and friend:getHandcardNum() < 3)
			or (self:getDamagedEffects(friend, self.player) and not (friend:isLord() and #self.enemies < 1))
			or (self:needToLoseHp(friend, self.player, true, true) and not (friend:isLord() and #self.enemies < 1))
			or self:hasQiuyuanEffect(self.player, friend) then

			if not slash_prohibit then
				if ((self.player:canSlash(friend, card, not no_distance, rangefix))
					or (use.isDummy and self.predictedRange and self.player:distanceTo(friend, rangefix) <= self.predictedRange))
					and self:slashIsEffective(card, friend) then
					use.card = card
					if use.to and canAppendTarget(friend) then
						use.to:append(friend)
					end
					if not use.to or self.slash_targets <= use.to:length() then return end
				end
			end
		end
	end
end

sgs.ai_skill_use.slash = function(self, prompt)
	local parsedPrompt = prompt:split(":")
	local callback = sgs.ai_skill_cardask[parsedPrompt[1]] -- for askForUseSlashTo
	if self.player:hasFlag("slashTargetFixToOne") and type(callback) == "function" then
		local slash
		local target
		for _, player in sgs.qlist(self.room:getOtherPlayers(self.player)) do
			if player:hasFlag("SlashAssignee") then target = player break end
		end
		local target2 = nil
		if #parsedPrompt >= 3 then target2 = findPlayerByObjectName(self.room, parsedPrompt[3]) end
		if not target then return "." end
		local ret = callback(self, nil, nil, target, target2)
		if ret == nil or ret == "." then return "." end
		slash = sgs.Card_Parse(ret)
		local no_distance = sgs.Sanguosha:correctCardTarget(sgs.TargetModSkill_DistanceLimit, self.player, slash) > 50 or self.player:hasFlag("slashNoDistanceLimit")
		local targets = {}
		local use = { to = sgs.SPlayerList() }
		if self.player:canSlash(target, slash, not no_distance) then use.to:append(target) else return "." end

		if parsedPrompt[1] ~= "@niluan-slash" and target:hasSkill("xiansi") and target:getPile("counter"):length() > 1
			and not (self:needKongcheng() and self.player:isLastHandCard(slash, true)) then
			return "@XiansiSlashCard=."
		end

		self:useCardSlash(slash, use)
		for _, p in sgs.qlist(use.to) do table.insert(targets, p:objectName()) end
		if table.contains(targets, target:objectName()) then return ret .. "->" .. table.concat(targets, "+") end
		return "."
	end
	local useslash, target
	local slashes = self:getCards("Slash")
	self:sort(self.enemies, "defenseSlash")
	for _, slash in ipairs(slashes) do
		local no_distance = sgs.Sanguosha:correctCardTarget(sgs.TargetModSkill_DistanceLimit, self.player, slash) > 50 or self.player:hasFlag("slashNoDistanceLimit")
		for _, friend in ipairs(self.friends_noself) do
			local slash_prohibit = false
			slash_prohibit = self:slashProhibit(card, friend)
			if not self:hasHeavySlashDamage(self.player, card, friend)
				and self.player:canSlash(friend, slash, not no_distance) and not self:slashProhibit(slash, friend)
				and self:slashIsEffective(slash, friend)
				and (self:findLeijiTarget(friend, 50, self.player)
					or (friend:isLord() and self.player:hasSkill("guagu") and friend:getLostHp() >= 1 and getCardsNum("Jink", friend, self.player) == 0)
					or (friend:hasSkill("jieming") and self.player:hasSkill("nosrende") and (huatuo and self:isFriend(huatuo))))
				and not (self.player:hasFlag("slashTargetFix") and not friend:hasFlag("SlashAssignee"))
				and not (slash:isKindOf("XiansiSlashCard") and friend:getPile("counter"):length() < 2) then

				useslash = slash
				target = friend
				break
			end
		end
	end
	if not useslash then
		for _, slash in ipairs(slashes) do
			local no_distance = sgs.Sanguosha:correctCardTarget(sgs.TargetModSkill_DistanceLimit, self.player, slash) > 50 or self.player:hasFlag("slashNoDistanceLimit")
			for _, enemy in ipairs(self.enemies) do
				if self.player:canSlash(enemy, slash, not no_distance) and not self:slashProhibit(slash, enemy)
					and self:slashIsEffective(slash, enemy) and sgs.isGoodTarget(enemy, self.enemies, self)
					and not (self.player:hasFlag("slashTargetFix") and not enemy:hasFlag("SlashAssignee")) then

					useslash = slash
					target = enemy
					break
				end
			end
		end
	end
	if useslash and target then
		local targets = {}
		local use = { to = sgs.SPlayerList() }
		use.to:append(target)

		if target:hasSkill("xiansi") and target:getPile("counter"):length() > 1 and not (self:needKongcheng() and self.player:isLastHandCard(slash, true)) then
			return "@XiansiSlashCard=."
		end

		self:useCardSlash(useslash, use)
		for _, p in sgs.qlist(use.to) do table.insert(targets, p:objectName()) end
		if table.contains(targets, target:objectName()) then return useslash:toString() .. "->" .. table.concat(targets, "+") end
	end
	return "."
end

sgs.ai_skill_playerchosen.slash_extra_targets = function(self, targets)
	local slash = sgs.cloneCard("slash")
	targets = sgs.QList2Table(targets)
	self:sort(targets, "defenseSlash")
	for _, target in ipairs(targets) do
		if self:isEnemy(target) and not self:slashProhibit(slash, target) and sgs.isGoodTarget(target, targetlist, self) and self:slashIsEffective(slash, target) then
			return target
		end
	end
	return nil
end

sgs.ai_skill_playerchosen.zero_card_as_slash = function(self, targets)
	local slash = sgs.cloneCard("slash")
	local targetlist = sgs.QList2Table(targets)
	local arrBestHp, canAvoidSlash, forbidden = {}, {}, {}
	self:sort(targetlist, "defenseSlash")
	for _, target in ipairs(targetlist) do
		if self:isEnemy(target) and not self:slashProhibit(slash, target) and sgs.isGoodTarget(target, targetlist, self) then
			if self:slashIsEffective(slash, target) then
				if self:getDamagedEffects(target, self.player, true) or self:findLeijiTarget(target, 50, self.player) then
					table.insert(forbidden, target)
				elseif self:needToLoseHp(target, self.player, true) then
					table.insert(arrBestHp, target)
				else
					return target
				end
			else
				table.insert(canAvoidSlash, target)
			end
		end
	end
	for _, target in ipairs(targetlist) do
		if not self:slashProhibit(slash, target) then
			if self:slashIsEffective(slash, target) then
				if self:isFriend(target) and (self:needToLoseHp(target, self.player, true) or self:getDamagedEffects(target, self.player, true))
					or self:findLeijiTarget(target, 50, self.player) then
					return target
				end
			else
				table.insert(canAvoidSlash, target)
			end
		end
	end
	if #canAvoidSlash > 0 then return canAvoidSlash[1] end
	if #arrBestHp > 0 then return arrBestHp[1] end

	self:sort(targetlist, "defenseSlash")
	targetlist = sgs.reverse(targetlist)
	for _, target in ipairs(targetlist) do
		if target:objectName() ~= self.player:objectName() and not self:isFriend(target) and not table.contains(forbidden, target) then
			return target
		end
	end
	return targetlist[1]
end

sgs.ai_card_intention.Slash = function(self, card, from, tos)
	if sgs.ai_collateral then sgs.ai_collateral = false return end
	if card:hasFlag("nosjiefan-slash") or card:getSkillName() == "mizhao" then return end
	for _, to in ipairs(tos) do
		if table.contains(sgs.ai_leiji_effect, to) then
			table.removeOne(sgs.ai_leiji_effect, to)
			continue
		end
		if to:hasSkill("nosqiuyuan") then continue end
		if from:hasSkill("jueqing") and to:hasSkill("zhaxiang") then continue end
		if not self:hasHeavySlashDamage(from, card, to) and (self:getDamagedEffects(to, from, true) or self:needToLoseHp(to, from, true)) then continue end
		if from:hasSkill("pojun") and to:getHp() > 2 + self:hasHeavySlashDamage(from, card, to, true) then continue end
		sgs.updateIntention(from, to, 80)
	end
end

sgs.ai_skill_cardask["slash-jink"] = function(self, data, pattern, target)
	local function getJink()
		if target and target:hasSkill("dahe") and self.player:hasFlag("dahe") then
			for _, card in ipairs(self:getCards("Jink")) do
				if card:getSuit() == sgs.Card_Heart then
					return card:toString()
				end
			end
			return "."
		end
		return nil
	end

	local slash
	if type(data) == "userdata" then
		local effect = data:toSlashEffect()
		slash = effect.slash
	else
		slash = sgs.cloneCard("slash")
	end
	local cards = sgs.QList2Table(self.player:getHandcards())
	if (not target or self:isFriend(target)) and slash:hasFlag("nosjiefan-slash") then return "." end
	if sgs.ai_skill_cardask.nullfilter(self, data, pattern, target) then return "." end
	--if not target then self.room:writeToConsole(debug.traceback()) end
	if not target then return getJink() end
	if not self:hasHeavySlashDamage(target, slash, self.player) and self:getDamagedEffects(self.player, target, slash) then return "." end
	if slash:isKindOf("NatureSlash") and self.player:isChained() and self:isGoodChainTarget(self.player, target, nil, nil, slash) then return "." end
	if self:isFriend(target) then
		if self:findLeijiTarget(self.player, 50, target) then return getJink() end
		if target:hasSkill("jieyin") and not self.player:isWounded() and self.player:isMale() and not self.player:hasSkills("leiji|nosleiji") then return "." end
		if not target:hasSkill("jueqing") then
			if (target:hasSkill("nosrende") or (target:hasSkill("rende") and not target:hasUsed("RendeCard"))) and self.player:hasSkill("jieming") then return "." end
			if target:hasSkill("pojun") and not self.player:faceUp() then return "." end
		end
	else
		if self:hasHeavySlashDamage(target, slash) then return getJink() end

		local current = self.room:getCurrent()
		if current and current:hasSkill("nosjuece") and self.player:getHp() > 0 then
			local use = false
			for _, card in ipairs(self:getCards("Jink")) do
				if not self.player:isLastHandCard(card, true) then
					use = true
					break
				end
			end
			if not use then return "." end
		end
		if self.player:getHandcardNum() == 1 and self:needKongcheng() then return getJink() end
		if not self:hasLoseHandcardEffective() and not self.player:isKongcheng() then return getJink() end
		if target:hasSkill("mengjin") and not (target:hasSkill("nosqianxi") and target:distanceTo(self.player) == 1) then
			if self:doNotDiscard(self.player, "he", true) then return getJink() end
			if self.player:getCards("he"):length() == 1 and not self.player:getArmor() then return getJink() end
			if self.player:hasSkills("jijiu|qingnang") and self.player:getCards("he"):length() > 1 then return "." end
			if self:canUseJieyuanDecrease(target) then return "." end
			if (self:getCardsNum("Peach") > 0 or (self:getCardsNum("Analeptic") > 0 and self:isWeak()))
				and not self.player:hasSkills("tuntian+zaoxian") and not self:willSkipPlayPhase() then
				return "."
			end
		end
		if self.player:getHp() > 1 and getKnownCard(target, self.player, "Slash") >= 1 and getKnownCard(target, self.player, "Analeptic") >= 1 and self:getCardsNum("Jink") == 1
			and (target:getPhase() < sgs.Player_Play or (self:slashIsAvailable(target) and target:canSlash(self.player))) then
			return "."
		end
		if not (target:hasSkill("nosqianxi") and target:distanceTo(self.player) == 1) then
			if target:hasWeapon("axe") then
				if target:hasSkills(sgs.lose_equip_skill) and target:getEquips():length() > 1 and target:getCards("he"):length() > 2 then return "." end
				if target:getHandcardNum() - target:getHp() > 2 and not self:isWeak() and self:getOverflow() <= 0 then return "." end
			elseif target:hasWeapon("blade") then
				if (slash:isKindOf("FireSlash")
					and not target:hasSkill("jueqing")
					and (self.player:hasArmorEffect("vine") or self.player:getMark("@gale") > 0))
					or self:hasHeavySlashDamage(target, slash)
					or (self.player:getHp() == 1 and #self.friends_noself == 0) then
				elseif ((self:getCardsNum("Jink") <= getCardsNum("Slash", target, self.player) or self.player:hasSkill("qingnang")) and self.player:getHp() > 1)
					or (self.player:hasSkill("jijiu") and self:getSuitNum("red", true) > 0)
					or self:canUseJieyuanDecrease(target) then
					return "."
				end
			end
		end
	end
	return getJink()
end

sgs.dynamic_value.damage_card.Slash = true

sgs.ai_use_value.Slash = 4.4
sgs.ai_keep_value.Slash = 3.6
sgs.ai_use_priority.Slash = 2.4

function SmartAI:useCardPeach(card, use)
	local mustusepeach = false
	if not self.player:isWounded() then return end
	if self.player:hasSkill("longhun") and not self.player:isLord()
		and math.min(self.player:getMaxCards(), self.player:getHandcardNum()) + self.player:getCards("e"):length() > 3 then return end
	local peaches = 0
	local cards = self.player:getHandcards()
	cards = sgs.QList2Table(cards)
	for _, card in ipairs(cards) do
		if isCard("Peach", card, self.player) then peaches = peaches + 1 end
	end
	if self.player:isLord() and (self.player:hasSkill("hunzi") and self.player:getMark("hunzi") == 0)
		and self.player:getHp() < 4 and self.player:getHp() > peaches then return end
	if (self.player:hasSkill("nosrende") or (self.player:hasSkill("rende") and not self.player:hasUsed("RendeCard"))) and self:findFriendsByType(sgs.Friend_Draw) then return end
	if self.player:hasArmorEffect("silver_lion") then
		for _, card in sgs.qlist(self.player:getHandcards()) do
			if card:isKindOf("Armor") and self:evaluateArmor(card) > 0 then
				use.card = card
				return
			end
		end
	end

	local SilverLion, OtherArmor
	for _, card in sgs.qlist(self.player:getHandcards()) do
		if card:isKindOf("SilverLion") then
			SilverLion = card
		elseif card:isKindOf("Armor") and self:evaluateArmor(card) > 0 then
			OtherArmor = true
		end
	end
	if SilverLion and OtherArmor then
		use.card = SilverLion
		return
	end

	for _, enemy in ipairs(self.enemies) do
		if self.player:getHandcardNum() < 3
			and (enemy:hasSkills(sgs.drawpeach_skill) or getCardsNum("Dismantlement", enemy, self.player) >= 1
				or (not self.player:hasSkills("qianxun|nosqianxun") and enemy:hasSkill("jixi") and enemy:getPile("field"):length() > 0
					and (enemy:distanceTo(self.player, 1) == 1 or enemy:hasSkills("qicai|nosqicai")))
				or (((enemy:hasSkill("qixi") and not self.player:hasSkill("weimu")) or enemy:hasSkill("yinling"))
					and getKnownCard(enemy, self.player, "black", nil, "he") >= 1)
				or (not self.player:hasSkills("qianxun|nosqianxun") and getCardsNum("Snatch", enemy, self.player) >= 1
					and (enemy:distanceTo(self.player) == 1 or enemy:hasSkills("qicai|nosqicai")))
				or (enemy:hasSkill("tiaoxin") and (self.player:inMyAttackRange(enemy) and self:getCardsNum("Slash") < 1)
					or not self.player:canSlash(enemy))) then
			mustusepeach = true
			break
		end
	end

	if mustusepeach or (self.player:hasSkill("nosbuqu") and self.player:getHp() < 1 and self.player:getMaxCards() == 0) or peaches > self.player:getHp() then
		use.card = card
		return
	end

	if self.player:hasSkill("jiuchi") and self:getCardsNum("Analeptic") > 0 and self:getOverflow() <= 0 and #self.friends_noself > 0 then
		return
	end

	if self:needToLoseHp(self.player) then return end

	local lord = self.room:getLord()
	if lord and self:isFriend(lord) and lord:getHp() <= 2 and not hasBuquEffect(lord) and peaches == 1 then
		if self.player:isLord() then use.card = card end
		return
	end

	self:sort(self.friends, "hp")
	if self.friends[1]:objectName() == self.player:objectName() or self.player:getHp() < 2 then
		use.card = card
		return
	end

	if #self.friends > 1 and ((not hasBuquEffect(self.friends[2]) and self.friends[2]:getHp() < 3 and self:getOverflow() < 2)
								or (not hasBuquEffect(self.friends[1]) and self.friends[1]:getHp() < 2 and peaches <= 1 and self:getOverflow() < 3)) then
		return
	end

	if self.player:hasSkill("jieyin") and self:getOverflow() > 0 then
		self:sort(self.friends, "hp")
		for _, friend in ipairs(self.friends) do
			if friend:isWounded() and friend:isMale() then return end
		end
	end

	if self.player:hasSkill("ganlu") and not self.player:hasUsed("GanluCard") then
		local dummy_use = { isDummy = true }
		self:useSkillCard(sgs.Card_Parse("@GanluCard=."), dummy_use)
		if dummy_use.card then return end
	end

	use.card = card
end

sgs.ai_card_intention.Peach = function(self, card, from, tos)
	for _, to in ipairs(tos) do
		if to:hasSkill("wuhun") then continue end
		sgs.updateIntention(from, to, -120)
	end
end

sgs.ai_use_value.Peach = 6
sgs.ai_keep_value.Peach = 7
sgs.ai_use_priority.Peach = 2.8

sgs.ai_use_value.Jink = 8.9
sgs.ai_keep_value.Jink = 5.2

sgs.dynamic_value.benefit.Peach = true

sgs.weapon_range.Weapon = 1
sgs.weapon_range.Crossbow = 1
sgs.weapon_range.DoubleSword = 2
sgs.weapon_range.QinggangSword = 2
sgs.weapon_range.IceSword = 2
sgs.weapon_range.GudingBlade = 2
sgs.weapon_range.Axe = 3
sgs.weapon_range.Blade = 3
sgs.weapon_range.Spear = 3
sgs.weapon_range.Halberd = 4
sgs.weapon_range.KylinBow = 5

sgs.ai_skill_invoke.double_sword = function(self, data)
	return not self:needKongcheng(self.player, true)
end

function sgs.ai_slash_weaponfilter.double_sword(self, to, player)
	return player:getGender() ~= to:getGender()
end

function sgs.ai_weapon_value.double_sword(self, enemy, player)
	if enemy and enemy:isMale() ~= player:isMale() then return 4 end
end

function SmartAI:getExpectedJinkNum(use)
	local jink_list = use.from:getTag("Jink_" .. use.card:toString()):toStringList()
	local index, jink_num = 1, 1
	for _, p in sgs.qlist(use.to) do
		if p:objectName() == self.player:objectName() then
			local n = tonumber(jink_list[index])
			if n == 0 then return 0
			elseif n > jink_num then jink_num = n end
		end
		index = index + 1
	end
	return jink_num
end

sgs.ai_skill_cardask["double-sword-card"] = function(self, data, pattern, target)
	if self.player:isKongcheng() then return "." end
	local use = data:toCardUse()
	local jink_num = self:getExpectedJinkNum(use)
	if jink_num > 1 and self:getCardsNum("Jink") == jink_num then return "." end

	if self:needKongcheng(self.player, true) and self.player:getHandcardNum() <= 2 then
		if self.player:getHandcardNum() == 1 then
			local card = self.player:getHandcards():first()
			return (jink_num > 0 and isCard("Jink", card, self.player)) and "." or ("$" .. card:getEffectiveId())
		end
		if self.player:getHandcardNum() == 2 then
			local first = self.player:getHandcards():first()
			local last = self.player:getHandcards():last()
			local jink = isCard("Jink", first, self.player) and first or (isCard("Jink", last, self.player) and last)
			if jink then
				return first:getEffectiveId() == jink:getEffectiveId() and ("$" .. last:getEffectiveId()) or ("$" .. first:getEffectiveId())
			end
		end
	end
	if target and self:isFriend(target) then return "." end
	if self:needBear() then return "." end
	if target and self:needKongcheng(target, true) then return "." end
	local cards = self.player:getHandcards()
	for _, card in sgs.qlist(cards) do
		if (card:isKindOf("Slash") and self:getCardsNum("Slash") > 1)
			or (card:isKindOf("Jink") and self:getCardsNum("Jink") > 2)
			or card:isKindOf("Disaster")
			or (card:isKindOf("EquipCard") and not self.player:hasSkills(sgs.lose_equip_skill))
			or (not self.player:hasSkills("nosjizhi|jizhi") and (card:isKindOf("Collateral") or card:isKindOf("GodSalvation")
															or card:isKindOf("FireAttack") or card:isKindOf("IronChain") or card:isKindOf("AmazingGrace"))) then
			return "$" .. card:getEffectiveId()
		end
	end
	return "."
end

function sgs.ai_weapon_value.qinggang_sword(self, enemy)
	if enemy and enemy:getArmor() and enemy:hasArmorEffect(enemy:getArmor():objectName()) then return 3 end
end

function sgs.ai_slash_weaponfilter.qinggang_sword(self, enemy)
	if enemy and enemy:getArmor() and enemy:hasArmorEffect(enemy:getArmor():objectName())
		and (sgs.card_lack[enemy:objectName()] == 1 or getCardsNum("Jink", enemy, self.player) < 1) then
		return true
	end
end

sgs.ai_skill_invoke.ice_sword = function(self, data)
	local damage = data:toDamage()
	local target = damage.to
	if self:isFriend(target) then
		if self:getDamagedEffects(target, self.players, true) or self:needToLoseHp(target, self.player, true) then return false
		elseif target:isChained() and self:isGoodChainTarget(target, self.player, nil, nil, damage.card) then return false
		elseif self:isWeak(target) or damage.damage > 1 then return true
		elseif target:getLostHp() < 1 then return false end
		return true
	else
		if self:isWeak(target) or damage.damage > 1 or self:hasHeavySlashDamage(self.player, damage.card, target) then return false end
		if target:hasSkill("lirang") and #self:getFriendsNoSelf(target) > 0 then return false end
		if target:getArmor() and self:evaluateArmor(target:getArmor(), target) > 3 and not (target:hasArmorEffect("silver_lion") and target:isWounded()) then
			return true
		end
		if target:hasSkills("tuntian+zaoxian") and target:getPhase() == sgs.Player_NotActive then return false end
		if target:hasSkills(sgs.need_kongcheng) then return false end
		if target:getCards("he"):length() < 4 and target:getCards("he"):length() > 1 then return true end
		return false
	end
end

function sgs.ai_slash_weaponfilter.guding_blade(self, to)
	return to:isKongcheng() and not to:hasArmorEffect("silver_lion")
end

function sgs.ai_weapon_value.guding_blade(self, enemy)
	if not enemy then return end
	local value = 2
	if enemy:getHandcardNum() < 1 and not enemy:hasArmorEffect("silver_lion") then value = 4 end
	return value
end

sgs.ai_skill_cardask["@axe"] = function(self, data, pattern, target)
	if target and self:isFriend(target) then return "." end
	local effect = data:toSlashEffect()
	local allcards = self.player:getCards("he")
	allcards = sgs.QList2Table(allcards)
	if self:hasHeavySlashDamage(self.player, effect.slash, target) or #allcards - 3 >= self.player:getHp() or self:getOverflow() >= 2
		or (self.player:hasSkill("kuanggu") and self.player:isWounded() and self.player:distanceTo(effect.to) == 1)
		or (self.player:hasSkill("kofkuanggu"))
		or (effect.to:getHp() == 1 and not hasBuquEffect(effect.to))
		or ((self:needKongcheng() or not self:hasLoseHandcardEffective()) and self.player:getHandcardNum() > 0)
		or (self.player:hasSkills(sgs.lose_equip_skill) and self.player:getEquips():length() > 1 and self.player:getHandcardNum() < 2)
		or self:needToThrowArmor() then

		local hcards = {}
		for _, c in sgs.qlist(self.player:getHandcards()) do
			if not (isCard("Slash", c, self.player) and self:hasCrossbowEffect()) then table.insert(hcards, c) end
		end
		self:sortByKeepValue(hcards)
		local cards = {}
		local hand, armor, def, off = 0, 0, 0, 0
		if self:needToThrowArmor() then
			table.insert(cards, self.player:getArmor():getEffectiveId())
			armor = 1
		end
		if (self.player:hasSkills(sgs.need_kongcheng) or not self:hasLoseHandcardEffective()) and self.player:getHandcardNum() > 0 then
			hand = 1
			for _, card in ipairs(hcards) do
				table.insert(cards, card:getEffectiveId())
				if #cards == 2 then break end
			end
		end
		if #cards < 2 and self.player:hasSkills(sgs.lose_equip_skill) then
			if #cards < 2 and self.player:getOffensiveHorse() then
				off = 1
				table.insert(cards, self.player:getOffensiveHorse():getEffectiveId())
			end
			if #cards < 2 and self.player:getArmor() then
				armor = 1
				table.insert(cards, self.player:getArmor():getEffectiveId())
			end
			if #cards < 2 and self.player:getDefensiveHorse() then
				def = 1
				table.insert(cards, self.player:getDefensiveHorse():getEffectiveId())
			end
		end

		if #cards < 2 and hand < 1 and self.player:getHandcardNum() > 2 then
			hand = 1
			for _, card in ipairs(hcards) do
				table.insert(cards, card:getEffectiveId())
				if #cards == 2 then break end
			end
		end

		if #cards < 2 and off < 1 and self.player:getOffensiveHorse() then
			off = 1
			table.insert(cards, self.player:getOffensiveHorse():getEffectiveId())
		end
		if #cards < 2 and hand < 1 and self.player:getHandcardNum() > 0 then
			hand = 1
			for _, card in ipairs(hcards) do
				table.insert(cards, card:getEffectiveId())
				if #cards == 2 then break end
			end
		end
		if #cards < 2 and armor < 1 and self.player:getArmor() then
			armor = 1
			table.insert(cards, self.player:getArmor():getEffectiveId())
		end
		if #cards < 2 and def < 1 and self.player:getDefensiveHorse() then
			def = 1
			table.insert(cards, self.player:getDefensiveHorse():getEffectiveId())
		end

		if #cards == 2 then
			local num = 0
			for _, id in ipairs(cards) do
				if self.player:hasEquip(sgs.Sanguosha:getCard(id)) then num = num + 1 end
			end
			self.equipsToDec = num
			local eff = self:damageIsEffective(effect.to, effect.nature, self.player)
			self.equipsToDec = 0
			if not eff then return "." end
			return "$" .. table.concat(cards, "+")
		end
	end
end

function sgs.ai_slash_weaponfilter.axe(self, to, player)
	return self:getOverflow(player) > 1
end

function sgs.ai_weapon_value.axe(self, enemy, player)
	if player:hasSkills("jiushi|jiuchi|luoyi|nosluoyi|pojun") then return 6 end
	if enemy and enemy:getHp() < 3 then return 6 - enemy:getHp() end
	if enemy and self:getOverflow() > 0 then return 3.1 end
end

sgs.ai_skill_cardask["blade-slash"] = function(self, data, pattern, target)
	if target and self:isFriend(target) and not self:findLeijiTarget(target, 50, self.player) then
		return "."
	end
	for _, slash in ipairs(self:getCards("Slash")) do
		if self:slashIsEffective(slash, target) then
			return slash:toString()
		end
	end
	return "."
end

function sgs.ai_weapon_value.blade(self, enemy)
	if not enemy then return math.min(self:getCardsNum("Slash"), 3) end
end

function cardsView_spear(self, player, skill_name)
	local cards = player:getCards("he")
	for _, id in sgs.qlist(player:getPile("wooden_ox")) do
		cards:prepend(sgs.Sanguosha:getCard(id))
	end
	cards = sgs.QList2Table(cards)
	if skill_name ~= "fuhun" or player:hasSkill("wusheng") then
		for _, acard in ipairs(cards) do
			if isCard("Slash", acard, player) then return end
		end
	end
	local cards = player:getCards("h")
	for _, id in sgs.qlist(player:getPile("wooden_ox")) do
		cards:prepend(sgs.Sanguosha:getCard(id))
	end
	cards = sgs.QList2Table(cards)
	local newcards = {}
	for _, card in ipairs(cards) do
		if not isCard("Slash", card, player) and not isCard("Peach", card, player) and not (isCard("ExNihilo", card, player) and player:getPhase() == sgs.Player_Play) then table.insert(newcards, card) end
	end
	if #newcards < 2 then return end
	sgs.ais[player:objectName()]:sortByKeepValue(newcards)

	local card_id1 = newcards[1]:getEffectiveId()
	local card_id2 = newcards[2]:getEffectiveId()

	local card_str = ("slash:%s[%s:%s]=%d+%d"):format(skill_name, "to_be_decided", 0, card_id1, card_id2)
	return card_str
end

function sgs.ai_cardsview.spear(self, class_name, player)
	if class_name == "Slash" then
		return cardsView_spear(self, player, "spear")
	end
end

function turnUse_spear(self, inclusive, skill_name)
	local cards = self.player:getCards("he")
	for _, id in sgs.qlist(self.player:getPile("wooden_ox")) do
		cards:prepend(sgs.Sanguosha:getCard(id))
	end
	cards = sgs.QList2Table(cards)
	if skill_name ~= "fuhun" or self.player:hasSkill("wusheng") then
		for _, acard in ipairs(cards) do
			if isCard("Slash", acard, self.player) then return end
		end
	end

	local cards = self.player:getCards("h")
	cards = sgs.QList2Table(cards)
	self:sortByUseValue(cards)
	local newcards = {}
	for _, card in ipairs(cards) do
		if not isCard("Slash", card, self.player) and not isCard("Peach", card, self.player) and not (isCard("ExNihilo", card, self.player) and self.player:getPhase() == sgs.Player_Play) then table.insert(newcards, card) end
	end
	if #newcards <= self.player:getHp() - 1 and self.player:getHp() <= 4 and not self:hasHeavySlashDamage(self.player)
		and not self.player:hasSkills("kongcheng|lianying|noslianying|paoxiao|shangshi|noshangshi")
		and not (self.player:hasSkill("zhiji") and self.player:getMark("zhiji") == 0) then return end
	if #newcards < 2 then return end

	local card_id1 = newcards[1]:getEffectiveId()
	local card_id2 = newcards[2]:getEffectiveId()

	if newcards[1]:isBlack() and newcards[2]:isBlack() then
		local black_slash = sgs.cloneCard("slash", sgs.Card_NoSuitBlack)
		local nosuit_slash = sgs.cloneCard("slash")

		self:sort(self.enemies, "defenseSlash")
		for _, enemy in ipairs(self.enemies) do
			if self.player:canSlash(enemy) and not self:slashProhibit(nosuit_slash, enemy) and self:slashIsEffective(nosuit_slash, enemy)
				and self:canAttack(enemy) and self:slashProhibit(black_slash, enemy) and self:isWeak(enemy) then
				local redcards, blackcards = {}, {}
				for _, acard in ipairs(newcards) do
					if acard:isBlack() then table.insert(blackcards, acard) else table.insert(redcards, acard) end
				end
				if #redcards == 0 then break end

				local redcard, othercard

				self:sortByUseValue(blackcards, true)
				self:sortByUseValue(redcards, true)
				redcard = redcards[1]

				othercard = #blackcards > 0 and blackcards[1] or redcards[2]
				if redcard and othercard then
					card_id1 = redcard:getEffectiveId()
					card_id2 = othercard:getEffectiveId()
					break
				end
			end
		end
	end

	local card_str = ("slash:%s[%s:%s]=%d+%d"):format(skill_name, "to_be_decided", 0, card_id1, card_id2)
	local slash = sgs.Card_Parse(card_str)
	return slash
end

local spear_skill = {}
spear_skill.name = "spear"
table.insert(sgs.ai_skills, spear_skill)
spear_skill.getTurnUseCard = function(self, inclusive)
	return turnUse_spear(self, inclusive, "spear")
end

function sgs.ai_weapon_value.spear(self, enemy, player)
	if enemy and getCardsNum("Slash", player, self.player) == 0 then
		if self:getOverflow(player) > 0 then return 2
		elseif player:getHandcardNum() > 2 then return 1
		end
	end
	return 0
end

function sgs.ai_slash_weaponfilter.fan(self, to)
	return to:hasArmorEffect("vine")
end

sgs.ai_skill_invoke.kylin_bow = function(self, data)
	local damage = data:toDamage()

	if damage.to:getCards("e"):length() == 1 then
		if damage.from:hasSkill("kuangfu") then return false end
		if damage.from:hasSkill("qiaomeng") and damage.card and damage.card:isKindOf("Slash") and damage.card:isBlack() then return false end
	end
	if damage.to:hasSkills(sgs.lose_equip_skill) then
		return self:isFriend(damage.to)
	end

	return self:isEnemy(damage.to)
end

function sgs.ai_slash_weaponfilter.kylin_bow(self, to)
	return to:getDefensiveHorse() or to:getOffensiveHorse()
end

function sgs.ai_weapon_value.kylin_bow(self, enemy)
	if enemy and (enemy:getOffensiveHorse() or enemy:getDefensiveHorse()) then return 1 end
end

sgs.ai_skill_invoke.eight_diagram = function(self, data)
	local dying = 0
	local handang = self.room:findPlayerBySkillName("nosjiefan")
	for _, aplayer in sgs.qlist(self.room:getAlivePlayers()) do
		if aplayer:getHp() < 1 and not aplayer:hasSkill("nosbuqu") then dying = 1 break end
	end
	if handang and self:isFriend(handang) and dying > 0 then return false end

	local heart_jink = false
	for _, card in sgs.qlist(self.player:getCards("he")) do
		if card:getSuit() == sgs.Card_Heart and isCard("Jink", card, self.player) then
			heart_jink = true
			break
		end
	end
	if self.player:hasFlag("dahe") then
		if self.player:hasSkills("tiandu|leiji|nosleiji") and not heart_jink then return true else return false end
	end
	if sgs.hujiasource and (not self:isFriend(sgs.hujiasource) or sgs.hujiasource:hasFlag("dahe")) then return false end
	if self:needKongcheng(self.player, true) and self.player:getHandcardNum() == 1 then
		local card = self.player:getHandcards():first()
		if isCard("Jink", card, self.player) and not self.player:isLocked(card) then return false end
	end
	if self.player:hasSkills("tiandu|leiji") then return true end
	local zhangjiao = self.room:findPlayerBySkillName("guidao")
	if zhangjiao and self:isEnemy(zhangjiao) and self:getFinalRetrial(zhangjiao) == 2 then
		if getKnownCard(zhangjiao, self.player, "black", false, "he") > 1 then return false end
		if self:getCardsNum("Jink") > 1 and getKnownCard(zhangjiao, self.player, "black", false, "he") > 0 then return false end
	end
	if self:getDamagedEffects(self.player, nil, true) or self:needToLoseHp(self.player, nil, true) then return false end
	if self.player:getPile("incantation"):length() > 0 then
		local card = sgs.Sanguosha:getCard(self.player:getPile("incantation"):first())
		local zhangbao = self.room:findPlayerBySkillName("yingbing")
		if zhangbao and self:isEnemy(zhangbao) and not zhangbao:hasSkill("manjuan") and not self:hasWizard(self.friends)
			and (card:isBlack() and not (self.player:hasSkill("hongyan") and card:getSuit() == sgs.Card_Spade)) then return false end
	end
	return true
end

function sgs.ai_armor_value.eight_diagram(player, self)
	local zj = self.room:findPlayerBySkillName("guidao")
	local haszj = zj and self:isEnemy(player, zj)
	if haszj then
		return 2
	end
	if player:hasSkills("tiandu|leiji|nosleiji|noszhenlie") then
		return 6
	end

	if self.role == "loyalist" and self.player:getKingdom() == "wei" and not self.player:hasSkills("bazhen|yizhong|bossmanjia") and self.room:getLord() and self.room:getLord():hasLordSkill("hujia") then
		return 5
	end

	return 4
end

function sgs.ai_armor_value.renwang_shield()
	return 4.5
end

function sgs.ai_armor_value.silver_lion(player, self)
	if self:hasWizard(self:getEnemies(player), true) then
		for _, player in sgs.qlist(self.room:getAlivePlayers()) do
			if player:containsTrick("lightning") then return 5 end
		end
	end
	if self.player:isWounded() and not self.player:getArmor() then return 9 end
	if self.player:isWounded() and self:getCardsNum("Armor", "h") >= 2 and not self.player:hasArmorEffect("silver_lion") then return 8 end
	return 1
end

sgs.ai_use_priority.OffensiveHorse = 2.69
sgs.ai_use_priority.Halberd = 2.685
sgs.ai_use_priority.KylinBow = 2.68
sgs.ai_use_priority.Blade = 2.675
sgs.ai_use_priority.GudingBlade = 2.67
sgs.ai_use_priority.DoubleSword = 2.665
sgs.ai_use_priority.Spear = 2.66
sgs.ai_use_priority.IceSword = 2.65
sgs.ai_use_priority.QinggangSword = 2.645
sgs.ai_use_priority.Axe = 2.688
sgs.ai_use_priority.Crossbow = 2.63
sgs.ai_use_priority.EightDiagram = 0.8
sgs.ai_use_priority.RenwangShield = 0.7
sgs.ai_use_priority.DefensiveHorse = 2.75

sgs.dynamic_value.damage_card.ArcheryAttack = true
sgs.dynamic_value.damage_card.SavageAssault = true

sgs.ai_use_value.ArcheryAttack = 3.8
sgs.ai_use_priority.ArcheryAttack = 3.5
sgs.ai_keep_value.ArcheryAttack = 3.38
sgs.ai_use_value.SavageAssault = 3.9
sgs.ai_use_priority.SavageAssault = 3.5
sgs.ai_keep_value.SavageAssault = 3.13

sgs.ai_skill_cardask.aoe = function(self, data, pattern, target, name)
	if self.room:getMode():find("_mini_34") and self.player:getLostHp() == 1 and name == "archery_attack" then return "." end
	if sgs.ai_skill_cardask.nullfilter(self, data, pattern, target) then return "." end

	local aoe
	if type(data) == "userdata" then aoe = data:toCardEffect().card else aoe = sgs.cloneCard(name) end
	assert(aoe ~= nil)
	local menghuo = self.room:findPlayerBySkillName("huoshou")
	local attacker = target
	if menghuo and aoe:isKindOf("SavageAssault") then attacker = menghuo end

	if not self:damageIsEffective(nil, nil, attacker) then return "." end
	if self:getDamagedEffects(self.player, attacker) or self:needToLoseHp(self.player, attacker) then return "." end

	if self.player:hasSkill("wuyan") and not attacker:hasSkill("jueqing") then return "." end
	if attacker:hasSkill("wuyan") and not attacker:hasSkill("jueqing") then return "." end
	if self.player:getMark("@fenyong") > 0 and not attacker:hasSkill("jueqing") then return "." end

	if not attacker:hasSkill("jueqing") and self.player:hasSkills("jianxiong|nosjianxiong") and (self.player:getHp() > 1 or self:getAllPeachNum() > 0)
		and not self:willSkipPlayPhase() then
		if not self:needKongcheng(self.player, true) and self:getAoeValue(aoe) > -10 then return "." end
		if aoe:isVirtualCard() then
			if aoe:subcardsLength() > 2 and not self:isWeak() then return "." end
			for _, id in sgs.qlist(damagecard:getSubcards()) do
				local card = sgs.Sanguosha:getCard(id)
				if (not self:needKongcheng(self.player, true) or aoe:subcardsLength() > 2) and isCard("Peach", card, self.player) then return "." end
			end
		end
	end

	local current = self.room:getCurrent()
	if current and current:hasSkill("nosjuece") and self:isEnemy(current) and self.player:getHp() > 0 then
		local classname = (name == "savage_assault" and "Slash" or "Jink")
		local use = false
		for _, card in ipairs(self:getCards(classname)) do
			if not self.player:isLastHandCard(card, true) then
				use = true
				break
			end
		end
		if not use then return "." end
	end
end

sgs.ai_skill_cardask["savage-assault-slash"] = function(self, data, pattern, target)
	return sgs.ai_skill_cardask.aoe(self, data, pattern, target, "savage_assault")
end

sgs.ai_skill_cardask["archery-attack-jink"] = function(self, data, pattern, target)
	return sgs.ai_skill_cardask.aoe(self, data, pattern, target, "archery_attack")
end

sgs.ai_keep_value.Nullification = 3.8
sgs.ai_use_value.Nullification = 8

function SmartAI:useCardAmazingGrace(card, use)
	if self.player:hasSkill("noswuyan") then use.card = card return end
	if (self.role == "lord" or self.role == "loyalist") and sgs.turncount <= 2 and self.player:getSeat() <= 3 and self.player:aliveCount() > 5 then return end
	local value = 1
	local suf, coeff = 0.8, 0.8
	if (self:needKongcheng() and self.player:getHandcardNum() == 1) or self.player:hasSkills("nosjizhi|jizhi") then
		suf = 0.6
		coeff = 0.6
	end

	local pos_ind, neg_ind = 1, -1
	local ganning = self.room:findPlayerBySkillName("fenwei")
	if ganning and ganning:getMark("@fenwei") > 0 then
		if self:isEnemy(ganning) then pos_ind = 0.9 elseif self:isFriend(ganning) then neg_ind = -0.9 end
	end

	for _, player in sgs.qlist(self.room:getOtherPlayers(self.player)) do
		local index = 0
		if self:hasTrickEffective(card, player, self.player) then
			if self:isFriend(player) then index = pos_ind elseif self:isEnemy(player) then index = neg_ind end
		end
		value = value + index * suf
		if value < 0 then return end
		suf = suf * coeff
	end
	use.card = card
end

sgs.ai_use_value.AmazingGrace = 3
sgs.ai_keep_value.AmazingGrace = -1
sgs.ai_use_priority.AmazingGrace = 1
sgs.dynamic_value.benefit.AmazingGrace = true

function SmartAI:willUseGodSalvation(card)
	if not card then self.room:writeToConsole(debug.traceback()) return false end
	local good, bad = 0, 0
	local wounded_friend = 0
	local wounded_enemy = 0

	local liuxie = self.room:findPlayerBySkillName("huangen")
	if liuxie then
		if self:isFriend(liuxie) then
			if self.player:hasSkill("noswuyan") and liuxie:getHp() > 0 then return true end
			good = good + 5 * liuxie:getHp()
		else
			if self.player:hasSkill("noswuyan") and self:isEnemy(liuxie) and liuxie:getHp() > 1 then return false end
			bad = bad + 5 * liuxie:getHp()
		end
	end

	if self.player:hasSkill("noswuyan") then return (self.player:isWounded() or self.player:hasSkills("nosjizhi|jizhi")) end
	if self.player:hasSkill("nosjizhi") then good = good + 6 end
	if self.player:hasSkill("jizhi") then good = good + 4 end
	if (self.player:hasSkill("kongcheng") and self.player:getHandcardNum() == 1) or not self:hasLoseHandcardEffective() then good = good + 5 end

	for _, friend in ipairs(self.friends) do
		good = good + 10 * getCardsNum("Nullification", friend, self.player)
		if self:hasTrickEffective(card, friend, self.player) then
			if friend:isWounded() then
				wounded_friend = wounded_friend + 1
				good = good + 10
				if friend:isLord() then good = good + 10 / math.max(friend:getHp(), 1) end
				if friend:hasSkills(sgs.masochism_skill) then
					good = good + 5
				end
				if friend:getHp() <= 1 and self:isWeak(friend) then
					good = good + 5
					if friend:isLord() then good = good + 10 end
				else
					if friend:isLord() then good = good + 5 end
				end
			elseif friend:hasSkill("danlao") then good = good + 5
			end
		end
	end

	for _, enemy in ipairs(self.enemies) do
		bad = bad + 10 * getCardsNum("Nullification", enemy, self.player)
		if self:hasTrickEffective(card, enemy, self.player) then
			if enemy:isWounded() then
				wounded_enemy = wounded_enemy + 1
				bad = bad + 10
				if enemy:isLord() then
					bad = bad + 10 / math.max(enemy:getHp(), 1)
				end
				if enemy:hasSkills(sgs.masochism_skill) then
					bad = bad + 5
				end
				if enemy:getHp() <= 1 and self:isWeak(enemy) then
					bad = bad + 5
					if enemy:isLord() then bad = bad + 10 end
				else
					if enemy:isLord() then bad = bad + 5 end
				end
			elseif enemy:hasSkill("danlao") then bad = bad + 5
			end
		end
	end

	if self.room:alivePlayerCount() > 2 then
		local ganning = self.room:findPlayerBySkillName("fenwei")
		if ganning and ganning:getMark("@fenwei") > 0 then
			if self:isEnemy(ganning) then bad = bad * 1.1 elseif self:isFriend(ganning) then good = good * 1.1 end
		end
	end

	return (good - bad > 2 and wounded_friend > 0)  or (wounded_friend == 0 and wounded_enemy == 0 and self.player:hasSkills("nosjizhi|jizhi"))
end

function SmartAI:useCardGodSalvation(card, use)
	if self:willUseGodSalvation(card) then
		use.card = card
	end
end

sgs.ai_use_priority.GodSalvation = 3.9
sgs.ai_keep_value.GodSalvation = 3.32
sgs.dynamic_value.benefit.GodSalvation = true

function SmartAI:useCardDuel(duel, use)
	if self.player:hasSkill("wuyan") and not self.player:hasSkill("jueqing") then return end
	if self.player:hasSkill("noswuyan") then return end

	local enemies = self:exclude(self.enemies, duel)
	local friends = self:exclude(self.friends_noself, duel)
	duel:setFlags("AI_Using")
	local n1 = self:getCardsNum("Slash")
	duel:setFlags("-AI_Using")
	if use.isWuqian or self.player:hasSkill("wushuang") then n1 = n1 * 2 end
	local huatuo = self.room:findPlayerBySkillName("jijiu")
	local targets = {}

	local canUseDuelTo = function(target)
		return self:hasTrickEffective(duel, target) and self:damageIsEffective(target, sgs.DamageStruct_Normal) and not self.room:isProhibited(self.player, target, duel)
	end

	for _, friend in ipairs(friends) do
		if (not use.current_targets or not table.contains(use.current_targets, friend:objectName()))
			and friend:hasSkill("jieming") and canUseDuelTo(friend) and self.player:hasSkill("nosrende") and (huatuo and self:isFriend(huatuo)) then
			table.insert(targets, friend)
		end
	end

	for _, enemy in ipairs(enemies) do
		if (not use.current_targets or not table.contains(use.current_targets, enemy:objectName()))
			and self.player:hasFlag("AI_DuelTo_" .. enemy:objectName()) and canUseDuelTo(enemy) then
			table.insert(targets, enemy)
		end
	end

	local cmp = function(a, b)
		local v1 = getCardsNum("Slash", a, self.player)
		local v2 = getCardsNum("Slash", b, self.player)

		if self:getDamagedEffects(a, self.player) then v1 = v1 + 20 end
		if self:getDamagedEffects(b, self.player) then v2 = v2 + 20 end

		if not self:isWeak(a) and a:hasSkills("jianxiong|nosjianxiong") and not self.player:hasSkill("jueqing") then v1 = v1 + 10 end
		if not self:isWeak(b) and b:hasSkills("jianxiong|nosjianxiong") and not self.player:hasSkill("jueqing") then v2 = v2 + 10 end

		if a:getHp() > getBestHp(a) then v1 = v1 + 5 end
		if b:getHp() > getBestHp(b) then v2 = v2 + 5 end

		if a:hasSkills(sgs.masochism_skill) then v1 = v1 + 5 end
		if b:hasSkills(sgs.masochism_skill) then v2 = v2 + 5 end

		if not self:isWeak(a) and a:hasSkill("jiang") then v1 = v1 + 5 end
		if not self:isWeak(b) and b:hasSkill("jiang") then v2 = v2 + 5 end

		if a:hasLordSkill("jijiang") then v1 = v1 + 2 * self:getJijiangSlashNum(a) end
		if b:hasLordSkill("jijiang") then v2 = v2 + 2 * self:getJijiangSlashNum(b) end

		if v1 == v2 then return sgs.getDefenseSlash(a, self) < sgs.getDefenseSlash(b, self) end

		return v1 < v2
	end

	table.sort(enemies, cmp)

	for _, enemy in ipairs(enemies) do
		local useduel
		local n2 = getCardsNum("Slash", enemy, self.player)
		if enemy:hasSkill("wushuang") then n2 = n2 * 2 end
		if sgs.card_lack[enemy:objectName()]["Slash"] == 1 then n2 = 0 end
		useduel = n1 >= n2 or self:needToLoseHp(self.player)
					or self:getDamagedEffects(self.player, enemy) or (n2 < 1 and sgs.isGoodHp(self.player))
					or ((self.player:hasSkills("jianxiong|nosjianxiong") or self.player:getMark("shuangxiong") > 0) and sgs.isGoodHp(self.player))

		if (not use.current_targets or not table.contains(use.current_targets, enemy:objectName()))
			and self:objectiveLevel(enemy) > 3 and canUseDuelTo(enemy) and not self:cantbeHurt(enemy) and useduel and sgs.isGoodTarget(enemy, enemies, self) then
			if not table.contains(targets, enemy) then table.insert(targets, enemy) end
		end
	end

	if #targets > 0 then
		local godsalvation = self:getCard("GodSalvation")
		if godsalvation and godsalvation:getId() ~= duel:getId() and self:willUseGodSalvation(godsalvation) then
			local use_gs = true
			for _, p in ipairs(targets) do
				if not p:isWounded() or not self:hasTrickEffective(godsalvation, p, self.player) then break end
				use_gs = false
			end
			if use_gs then
				use.card = godsalvation
				return
			end
		end

		local targets_num = 1 + sgs.Sanguosha:correctCardTarget(sgs.TargetModSkill_ExtraTarget, self.player, duel)
		if use.isDummy and use.xiechan then targets_num = 100 end
		local enemySlash = 0
		local setFlag = false

		local lx = self.room:findPlayerBySkillName("huangen")

		use.card = duel
		for i = 1, #targets, 1 do
			local n2 = getCardsNum("Slash", targets[i], self.player)
			if targets[i]:hasSkill("wushuang") then n2 = n2 * 2 end
			if sgs.card_lack[targets[i]:objectName()]["Slash"] == 1 then n2 = 0 end
			if self:isEnemy(targets[i]) then enemySlash = enemySlash + n2 end

			if use.to then
				if i == 1 and not use.current_targets then
					use.to:append(targets[i])
				elseif n1 >= enemySlash and not targets[i]:hasSkill("danlao") and not (lx and self:isEnemy(lx) and lx:getHp() > targets_num / 2) then
					use.to:append(targets[i])
				end
				if not setFlag and self.player:getPhase() == sgs.Player_Play and self:isEnemy(targets[i]) then 
					self.player:setFlags("AI_DuelTo_" .. targets[i]:objectName())
					setFlag = true
				end
				if use.to:length() == targets_num then return end
			end
		end
	end
end

sgs.ai_card_intention.Duel = function(self, card, from, tos)
	if string.find(card:getSkillName(), "lijian") or card:getSkillName() == "liyu" then return end
	sgs.updateIntentions(from, tos, 80)
end

sgs.ai_use_value.Duel = 3.7
sgs.ai_use_priority.Duel = 2.9
sgs.ai_keep_value.Duel = 3.42

sgs.dynamic_value.damage_card.Duel = true

sgs.ai_skill_cardask["duel-slash"] = function(self, data, pattern, target)
	if self.player:getPhase() == sgs.Player_Play then return self:getCardId("Slash") end

	if sgs.ai_skill_cardask.nullfilter(self, data, pattern, target) then return "." end
	if self.player:hasFlag("AIGlobal_NeedToWake") then return "." end
	if self.player:hasSkill("wuyan") and not target:hasSkill("jueqing") then return "." end
	if target:hasSkill("wuyan") and not self.player:hasSkill("jueqing") then return "." end
	if self.player:hasSkill("wuhun") and self:isEnemy(target) and target:isLord() and #self.friends_noself > 0 then return "." end
	if self:cantbeHurt(target) then return "." end
	if self:getDamagedEffects(self.player, target) or self:needToLoseHp(self.player, target) then return "." end
	if self:isFriend(target) and (target:hasSkill("nosrende") or (target:hasSkill("rende") and not target:hasUsed("RendeCard"))) and self.player:hasSkill("jieming") then return "." end
	if not self:damageIsEffective(self.player, sgs.DamageStruct_Normal, target) then return "." end
	if (not self:isFriend(target) and self:getCardsNum("Slash") * 2 >= target:getHandcardNum())
		or (target:getHp() > 2 and self.player:getHp() <= 1 and self:getCardsNum("Peach") == 0 and not hasBuquEffect(self.player)) then
		return self:getCardId("Slash")
	else return "." end
end

function SmartAI:useCardExNihilo(card, use)
	local xiahou = self.room:findPlayerBySkillName("yanyu")
	if xiahou and self:isEnemy(xiahou) and xiahou:getMark("YanyuDiscard2") > 0 then return end

	use.card = card
end

sgs.ai_card_intention.ExNihilo = -80

sgs.ai_keep_value.ExNihilo = 3.6
sgs.ai_use_value.ExNihilo = 10
sgs.ai_use_priority.ExNihilo = 9.3

sgs.dynamic_value.benefit.ExNihilo = true

function SmartAI:getDangerousCard(who)
	local weapon = who:getWeapon()
	local armor = who:getArmor()
	if weapon and weapon:isKindOf("Spear") and who:getHandcardNum() >= 3 and who:hasSkill("paoxiao") then return weapon:getEffectiveId() end
	if weapon and weapon:isKindOf("Axe") and who:hasSkills("luoyi|nosluoyi|pojun|jiushi|jiuchi|jie||jieyuan") then return weapon:getEffectiveId() end
	if armor and armor:isKindOf("EightDiagram") and who:hasSkills("leiji|nosleiji") then return armor:getEffectiveId() end
	if weapon and (weapon:isKindOf("SPMoonSpear") or weapon:isKindOf("MoonSpear")) and who:hasSkills("guidao|longdan|guicai|nosguicai|jilve|huanshi|qingguo|kanpo") then return weapon:getEffectiveId() end
	if weapon and who:hasSkill("liegong") and sgs.weapon_range[weapon:getClassName()] >= who:getHp() - 1 then return weapon:getEffectiveId() end

	if self:isFriend(who) then return end
	if weapon and weapon:isKindOf("Crossbow") and getCardsNum("Slash", who, self.player) > 1 then
		for _, friend in ipairs(self:getEnemies(who)) do
			if who:canSlash(friend) then return weapon:getEffectiveId() end
		end
	end
	if weapon and weapon:isKindOf("GudingBlade") and not who:hasSkill("jueqing") and getCardsNum("Slash", who, self.player) > 0 then
		for _, friend in ipairs(self:getEnemies(who)) do
			if who:canSlash(friend) and friend:isKongcheng() and not friend:hasSkills("kongcheng|tianming") then
				return weapon:getEffectiveId()
			end
		end
	end
	if weapon then
		if who:hasSkill("liegong") and sgs.weapon_range[weapon:getClassName()] > 2 then return weapon:getEffectiveId() end
		for _, friend in ipairs(self:getEnemies(who)) do
			if who:distanceTo(friend) < who:getAttackRange(false) and self:isWeak(friend) and not self:doNotDiscard(who, "e", true) then return weapon:getEffectiveId() end
		end
	end
end

function SmartAI:getValuableCard(who)
	local weapon = who:getWeapon()
	local armor = who:getArmor()
	local offhorse = who:getOffensiveHorse()
	local defhorse = who:getDefensiveHorse()
	local treasure = who:getTreasure()

	local friends = self:getEnemies(who)
	self:sort(friends, "hp")
	local friend
	if #friends > 0 then friend = friends[1] end
	if friend and self:isWeak(friend) and who:inMyAttackRange(friend) and not self:doNotDiscard(who, "e", true) then
		if weapon and who:distanceTo(friend) > who:getAttackRange(false) then return weapon:getEffectiveId() end
		if offhorse and who:distanceTo(friend) > who:getAttackRange() + 1 then return offhorse:getEffectiveId() end
	end

	if armor then
		local lord = self.room:getLord()
		if lord and self:isFriend(who, lord) and lord:hasLordSkill("hujia") and who:getKingdom() == "wei" and armor:isKindOf("EightDiagram") then
			return armor:getEffectiveId()
		end
	end

	if treasure then
		if treasure:isKindOf("WoodenOx") and who:getPile("wooden_ox"):length() > 1 then
			return treasure:getEffectiveId()
		end
	end

	if weapon then
		if (weapon:isKindOf("MoonSpear") and who:hasSkill("keji") and who:getHandcardNum() > 5) or who:hasSkill("qiangxi") then
			return weapon:getEffectiveId()
		end
	end

	local equips = sgs.QList2Table(who:getEquips())
	for _, equip in ipairs(equips) do
		if who:hasSkills("longhun|nosguose|guose|yanxiao") and equip:getSuit() ~= sgs.Card_Diamond then return equip:getEffectiveId() end
		if who:hasSkills("qixi|yinling|guidao|duanliang") and equip:isBlack() then return equip:getEffectiveId() end
		if who:hasSkill("jijiu|wusheng|xueji|nosfuhun") and equip:isRed() then return equip:getEffectiveId() end
		if who:hasSkill("baobian") and who:getHp() <= 2 then return  equip:getEffectiveId() end
		if who:hasSkills(sgs.need_equip_skill) and not who:hasSkills(sgs.lose_equip_skill) then return equip:getEffectiveId() end
	end

	if armor and self:evaluateArmor(armor, who) > 3
		and not self:needToThrowArmor(who)
		and not self:doNotDiscard(who, "e")
		and not (self.moukui_effect and self.moukui_effect:isKindOf("FireSlash") and armor:isKindOf("Vine") and not self.player:hasSkill("jueqing")) then
		return armor:getEffectiveId()
	end

	if defhorse and not self:doNotDiscard(who, "e") then
		if self.player:getPhase() == sgs.Player_Play then
			local slash = sgs.cloneCard("slash")
			if self.player:hasWeapon("kylin_bow") and self:slashIsAvailable(self.player, slash) and self.player:canSlash(who)
				and self:slashIsEffective(sgs.cloneCard("slash"), who, self.player)
				and (getCardsNum("Jink", who, self.player) < 1 or sgs.card_lack[who:objectName()].Jink == 1) then
			else
				return defhorse:getEffectiveId()
			end
		else
			return defhorse:getEffectiveId()
		end
	end

	if offhorse then
		if who:hasSkills("nosqianxi|kuanggu|duanbing|qianxi") then
			return offhorse:getEffectiveId()
		end
	end


	if armor and not self:needToThrowArmor(who) and not self:doNotDiscard(who, "e")
		and not (self.moukui_effect and self.moukui_effect:isKindOf("FireSlash") and armor:isKindOf("Vine") and not self.player:hasSkill("jueqing")) then
		return armor:getEffectiveId()
	end

	if offhorse and who:getHandcardNum() > 1 then
		if not self:doNotDiscard(who, "e", true) then
			for _, friend in ipairs(self:getEnemies(who)) do
				if who:distanceTo(friend) == who:getAttackRange() and who:getAttackRange() > 1 then
					return offhorse:getEffectiveId()
				end
			end
		end
	end

	if treasure then
		return treasure:getEffectiveId()
	end

	if weapon and who:getHandcardNum() > 1 then
		if not self:doNotDiscard(who, "e", true) then
			for _, friend in ipairs(self:getEnemies(who)) do
				if who:inMyAttackRange(friend) and who:distanceTo(friend) > who:getAttackRange(false) then
					return weapon:getEffectiveId()
				end
			end
		end
	end
end

function SmartAI:useCardSnatchOrDismantlement(card, use)
	local isYinling = card:isKindOf("YinlingCard")
	local isJixi = card:getSkillName() == "jixi"
	local isDiscard = (not card:isKindOf("Snatch"))
	local name = isYinling and "yinling" or card:objectName()
	local using_2013 = (name == "dismantlement") and self.room:getMode() == "02_1v1" and sgs.GetConfig("1v1/Rule", "Classical") ~= "Classical"
	if not isYinling and self.player:hasSkill("noswuyan") then return end
	local players = self.room:getOtherPlayers(self.player)
	local tricks
	local usecard = false

	local targets = {}
	local targets_num = isYinling and 1 or (1 + sgs.Sanguosha:correctCardTarget(sgs.TargetModSkill_ExtraTarget, self.player, card))
	local lx = self.room:findPlayerBySkillName("huangen")

	local addTarget = function(player, cardid)
		if not table.contains(targets, player:objectName())
			and (not use.current_targets or not table.contains(use.current_targets, player:objectName()))
			and not (use.to and use.to:length() > 0 and player:hasSkill("danlao"))
			and not (use.to and use.to:length() > 0 and lx and self:isEnemy(lx) and lx:getHp() > targets_num / 2) then
			if not usecard then
				use.card = card
				usecard = true
			end
			table.insert(targets, player:objectName())
			if usecard and use.to and use.to:length() < targets_num then
				use.to:append(player)
				if not use.isDummy then
					sgs.Sanguosha:getCard(cardid):setFlags("AIGlobal_SDCardChosen_" .. name)
				end
			end
			if #targets == targets_num then return true end
		end
	end

	players = self:exclude(players, card)
	if not isYinling and not using_2013 then
		for _, player in ipairs(players) do
			if not player:getJudgingArea():isEmpty() and self:hasTrickEffective(card, player)
				and ((player:containsTrick("lightning") and self:getFinalRetrial(player) == 2) or #self.enemies == 0) then
				tricks = player:getCards("j")
				for _, trick in sgs.qlist(tricks) do
					if trick:isKindOf("Lightning") and (not isDiscard or self.player:canDiscard(player, trick:getId())) then
						if addTarget(player, trick:getEffectiveId()) then return end
					end
				end
			end
		end
	end

	local enemies = {}
	if #self.enemies == 0 and self:getOverflow() > 0 then
		local lord = self.room:getLord()
		for _, player in ipairs(players) do
			if not self:isFriend(player) then
				if lord and self.player:isLord() then
					local kingdoms = {}
					if lord:getGeneral():isLord() then table.insert(kingdoms, lord:getGeneral():getKingdom()) end
					if lord:getGeneral2() and lord:getGeneral2():isLord() then table.insert(kingdoms, lord:getGeneral2():getKingdom()) end
					if not table.contains(kingdoms, player:getKingdom()) and not lord:hasSkill("yongsi") then table.insert(enemies, player) end
				elseif lord and player:objectName() ~= lord:objectName() then
					table.insert(enemies, player)
				elseif not lord then
					table.insert(enemies, player)
				end
			end
		end
		enemies = self:exclude(enemies, card)
		local temp = {}
		for _, enemy in ipairs(enemies) do
			if enemy:hasSkill("tuntian+guidao") and enemy:hasSkills("zaoxian|jixi|ziliang|leiji|nosleiji") then continue end
			if self:hasTrickEffective(card, enemy) or isYinling then
				table.insert(temp, enemy)
			end
		end
		enemies = temp
		self:sort(enemies, "defense")
		enemies = sgs.reverse(enemies)
	else
		enemies = self:exclude(self.enemies, card)
		local temp = {}
		for _, enemy in ipairs(enemies) do
			if enemy:hasSkill("tuntian+guidao") and enemy:hasSkills("zaoxian|jixi|ziliang|leiji|nosleiji") then continue end
			if self:hasTrickEffective(card, enemy) or isYinling then
				table.insert(temp, enemy)
			end
		end
		enemies = temp
		self:sort(enemies, "defense")
	end
	for _, enemy in ipairs(enemies) do
		if self:slashIsAvailable() and not (not isYinling and enemy:hasSkill("qianxun")) then
			for _, slash in ipairs(self:getCards("Slash")) do
				if not self:slashProhibit(slash, enemy) and enemy:getHandcardNum() == 1 and enemy:getHp() == 1 and self:hasLoseHandcardEffective(enemy)
					and self:objectiveLevel(enemy) > 3 and not self:cantbeHurt(enemy) and not enemy:hasSkills("kongcheng|tianming") and self.player:canSlash(enemy, slash)
					and (not enemy:isChained() or self:isGoodChainTarget(enemy, nil, nil, nil, slash))
					and (not self:hasEightDiagramEffect(enemy) or self.player:hasWeapon("qinggang_sword")) then
					if addTarget(enemy, enemy:getHandcards():first():getEffectiveId()) then return end
				end
			end
		end
	end
	for _, enemy in ipairs(enemies) do
		if not enemy:isNude() then
			local dangerous = self:getDangerousCard(enemy)
			if dangerous and (not isDiscard or self.player:canDiscard(enemy, dangerous)) then
				if addTarget(enemy, dangerous) then return end
			end
		end
	end

	self:sort(self.friends_noself, "defense")
	local friends = self:exclude(self.friends_noself, card)
	if not isYinling and not using_2013 then
		for _, friend in ipairs(friends) do
			if (friend:containsTrick("indulgence") or friend:containsTrick("supply_shortage")) and not friend:containsTrick("YanxiaoCard")
				and self:hasTrickEffective(card, friend) then
				local cardchosen
				tricks = friend:getJudgingArea()
				for _, trick in sgs.qlist(tricks) do
					if trick:isKindOf("Indulgence") and (not isDiscard or self.player:canDiscard(friend, trick:getId())) then
						if friend:getHp() <= friend:getHandcardNum() or friend:isLord() or name == "snatch" then
							cardchosen = trick:getEffectiveId()
							break
						end
					end
					if trick:isKindOf("SupplyShortage") and (not isDiscard or self.player:canDiscard(friend, trick:getId())) then
						cardchosen = trick:getEffectiveId()
						break
					end
					if trick:isKindOf("Indulgence") and (not isDiscard or self.player:canDiscard(friend, trick:getId())) then
						cardchosen = trick:getEffectiveId()
						break
					end
				end
				if cardchosen then
					if addTarget(friend, cardchosen) then return end
				end
			end
		end
	end

	local hasLion, target
	for _, friend in ipairs(friends) do
		if (self:hasTrickEffective(card, friend) or isYinling) and self:needToThrowArmor(friend) and (not isDiscard or self.player:canDiscard(friend, friend:getArmor():getEffectiveId())) then
			hasLion = true
			target = friend
		end
	end

	for _, enemy in ipairs(enemies) do
		if not enemy:isNude() then
			local valuable = self:getValuableCard(enemy)
			if valuable and (not isDiscard or self.player:canDiscard(enemy, valuable)) then
				if addTarget(enemy, valuable) then return end
			end
		end
	end

	local new_enemies = table.copyFrom(enemies)
	local compare_JudgingArea = function(a, b)
		return a:getJudgingArea():length() > b:getJudgingArea():length()
	end
	table.sort(new_enemies, compare_JudgingArea)
	local yanxiao_card, yanxiao_target, yanxiao_prior
	if not isYinling and not using_2013 then
		for _, enemy in ipairs(new_enemies) do
			for _, acard in sgs.qlist(enemy:getJudgingArea()) do
				if acard:isKindOf("YanxiaoCard") and self:hasTrickEffective(card, enemy) and (not isDiscard or self.player:canDiscard(enemy, acard:getId())) then
					yanxiao_card = acard
					yanxiao_target = enemy
					if enemy:containsTrick("indulgence") or enemy:containsTrick("supply_shortage") then yanxiao_prior = true end
					break
				end
			end
			if yanxiao_card and yanxiao_target then break end
		end
		if yanxiao_prior and yanxiao_card and yanxiao_target then
			if addTarget(yanxiao_target, yanxiao_card:getEffectiveId()) then return end
		end
	end

	for _, enemy in ipairs(enemies) do
		local cards = sgs.QList2Table(enemy:getHandcards())
		local flag = string.format("%s_%s_%s", "visible", self.player:objectName(), enemy:objectName())
		if #cards <= 2 and not enemy:isKongcheng() and not self:doNotDiscard(enemy, "h", true) and not (not isYinling and enemy:hasSkill("qianxun")) then
			for _, cc in ipairs(cards) do
				if (cc:hasFlag("visible") or cc:hasFlag(flag)) and (cc:isKindOf("Peach") or cc:isKindOf("Analeptic")) then
					if addTarget(enemy, self:getCardRandomly(enemy, "h")) then return end
				end
			end
		end
	end

	for _, enemy in ipairs(enemies) do
		if not enemy:isNude() then
			if enemy:hasSkills("jijiu|qingnang|jieyin") then
				local cardchosen
				local equips = { enemy:getDefensiveHorse(), enemy:getArmor(), enemy:getOffensiveHorse(), enemy:getWeapon() }
				for _, equip in ipairs(equips) do
					if equip and (not enemy:hasSkill("jijiu") or equip:isRed()) and (not isDiscard or self.player:canDiscard(enemy, equip:getEffectiveId())) then
						cardchosen = equip:getEffectiveId()
						break
					end
				end

				if not cardchosen and enemy:getDefensiveHorse() and (not isDiscard or self.player:canDiscard(enemy, enemy:getDefensiveHorse():getEffectiveId())) then cardchosen = enemy:getDefensiveHorse():getEffectiveId() end
				if not cardchosen and enemy:getArmor() and not self:needToThrowArmor(enemy) and (not isDiscard or self.player:canDiscard(enemy, enemy:getArmor():getEffectiveId())) then
					cardchosen = enemy:getArmor():getEffectiveId()
				end
				if not cardchosen and not enemy:isKongcheng() and enemy:getHandcardNum() <= 3 and (not isDiscard or self.player:canDiscard(enemy, "h"))
					and not (not isYinling and enemy:hasSkill("qianxun")) then
					cardchosen = self:getCardRandomly(enemy, "h")
				end

				if cardchosen then
					if addTarget(enemy, cardchosen) then return end
				end
			end
		end
	end

	for _, enemy in ipairs(enemies) do
		if enemy:getArmor() and enemy:hasArmorEffect("eight_diagram") and not self:needToThrowArmor(enemy)
			and (not isDiscard or self.player:canDiscard(enemy, enemy:getArmor():getEffectiveId())) then
			addTarget(enemy, enemy:getArmor():getEffectiveId())
		end
	end

	for i = 1, 2 + (isJixi and 3 or 0), 1 do
		for _, enemy in ipairs(enemies) do
			if not enemy:isNude()
				and not (self:needKongcheng(enemy) and i <= 2) and not self:doNotDiscard(enemy) then
				if (enemy:getHandcardNum() == i and sgs.getDefenseSlash(enemy, self) < 6 + (isJixi and 6 or 0) and enemy:getHp() <= 3 + (isJixi and 2 or 0)) then
					local cardchosen
					if self.player:distanceTo(enemy) == self.player:getAttackRange() + 1 and enemy:getDefensiveHorse() and not self:doNotDiscard(enemy, "e")
						and (not isDiscard or self.player:canDiscard(enemy, enemy:getDefensiveHorse():getEffectiveId()))then
						cardchosen = enemy:getDefensiveHorse():getEffectiveId()
					elseif enemy:getArmor() and not self:needToThrowArmor(enemy) and not self:doNotDiscard(enemy, "e")
						and (not isDiscard or self.player:canDiscard(enemy, enemy:getArmor():getEffectiveId()))then
						cardchosen = enemy:getArmor():getEffectiveId()
					elseif not isDiscard or self.player:canDiscard(enemy, "h") and not (not isYinling and enemy:hasSkill("qianxun")) then
						cardchosen = self:getCardRandomly(enemy, "h")
					end
					if cardchosen then
						if addTarget(enemy, cardchosen) then return end
					end
				end
			end
		end
	end

	for _, enemy in ipairs(enemies) do
		if not enemy:isNude() then
			local valuable = self:getValuableCard(enemy)
			if valuable and (not isDiscard or self.player:canDiscard(enemy, valuable)) then
				if addTarget(enemy, valuable) then return end
			end
		end
	end

	if hasLion and (not isDiscard or self.player:canDiscard(target, target:getArmor():getEffectiveId())) then
		if addTarget(target, target:getArmor():getEffectiveId()) then return end
	end

	if not isYinling and not using_2013
		and yanxiao_card and yanxiao_target and (not isDiscard or self.player:canDiscard(yanxiao_target, yanxiao_card:getId())) then
		if addTarget(yanxiao_target, yanxiao_card:getEffectiveId()) then return end
	end

	for _, enemy in ipairs(enemies) do
		if not enemy:isKongcheng() and not self:doNotDiscard(enemy, "h") and not (not isYinling and enemy:hasSkill("qianxun"))
			and enemy:hasSkills(sgs.cardneed_skill) and (not isDiscard or self.player:canDiscard(enemy, "h")) then
			if addTarget(enemy, self:getCardRandomly(enemy, "h")) then return end
		end
	end

	for _, enemy in ipairs(enemies) do
		if enemy:hasEquip() and not self:doNotDiscard(enemy, "e") then
			local cardchosen
			if enemy:getDefensiveHorse() and (not isDiscard or self.player:canDiscard(enemy, enemy:getDefensiveHorse():getEffectiveId())) then
				cardchosen = enemy:getDefensiveHorse():getEffectiveId()
			elseif enemy:getArmor() and not self:needToThrowArmor(enemy) and (not isDiscard or self.player:canDiscard(enemy, enemy:getArmor():getEffectiveId())) then
				cardchosen = enemy:getArmor():getEffectiveId()
			elseif enemy:getOffensiveHorse() and (not isDiscard or self.player:canDiscard(enemy, enemy:getOffensiveHorse():getEffectiveId())) then
				cardchosen = enemy:getOffensiveHorse():getEffectiveId()
			elseif enemy:getWeapon() and (not isDiscard or self.player:canDiscard(enemy, enemy:getWeapon():getEffectiveId())) then
				cardchosen = enemy:getWeapon():getEffectiveId()
			end
			if cardchosen then
				if addTarget(enemy, cardchosen) then return end
			end
		end
	end

	if name == "snatch" or self:getOverflow() > 0 then
		for _, enemy in ipairs(enemies) do
			local equips = enemy:getEquips()
			if not enemy:isNude() and not self:doNotDiscard(enemy, "he") then
				local cardchosen
				if not equips:isEmpty() and not self:doNotDiscard(enemy, "e") then
					cardchosen = self:getCardRandomly(enemy, "e")
				elseif not (not isYinling and enemy:hasSkill("qianxun")) then
					cardchosen = self:getCardRandomly(enemy, "h") end
				if cardchosen then
					if addTarget(enemy, cardchosen) then return end
				end
			end
		end
	end
end

SmartAI.useCardSnatch = SmartAI.useCardSnatchOrDismantlement

sgs.ai_use_value.Snatch = 9
sgs.ai_use_priority.Snatch = 4.3
sgs.ai_keep_value.Snatch = 3.18

SmartAI.useCardDismantlement = SmartAI.useCardSnatchOrDismantlement

sgs.ai_use_value.Dismantlement = 5.6
sgs.ai_use_priority.Dismantlement = 4.4

sgs.ai_choicemade_filter.cardChosen.snatch = function(self, player, promptlist)
	local from = findPlayerByObjectName(self.room, promptlist[4])
	local to = findPlayerByObjectName(self.room, promptlist[5])
	if from and to then
		local id = tonumber(promptlist[3])
		local place = self.room:getCardPlace(id)
		local card = sgs.Sanguosha:getCard(id)
		local intention = 70
		if place == sgs.Player_PlaceDelayedTrick then
			if not card:isKindOf("Disaster") then intention = -intention else intention = 0 end
			if card:isKindOf("YanxiaoCard") then intention = -intention end
		elseif place == sgs.Player_PlaceEquip then
			if card:isKindOf("Armor") and self:evaluateArmor(card, to) <= -2 then intention = 0 end
			if card:isKindOf("SilverLion") then
				if to:getLostHp() > 1 then
					if to:hasSkills(sgs.use_lion_skill) then
						intention = self:willSkipPlayPhase(to) and -intention or 0
					else
						intention = self:isWeak(to) and -intention or 0
					end
				else
					intention = 0
				end
			elseif to:hasSkills(sgs.lose_equip_skill) then
				if self:isWeak(to) and (card:isKindOf("DefensiveHorse") or card:isKindOf("Armor")) then
					intention = math.abs(intention)
				else
					intention = 0
				end
			end
			if (promptlist[2] == "snatch" or promptlist[2] == "youdi_obtain")
				and (card:isKindOf("OffensiveHorse") or card:isKindOf("Weapon")) and self:isFriend(from, to) then
				local canAttack
				for _, p in ipairs(self:getEnemies(from)) do
					if from:inMyAttackRange(p) then
						canAttack = true
						break
					end
				end
				if not canAttack then intention = 0 end
			end
		elseif place == sgs.Player_PlaceHand then
			if self:needKongcheng(to, true) and to:getHandcardNum() == 1 then
				intention = 0
			end
		end
		sgs.updateIntention(from, to, intention)
	end
end

sgs.ai_choicemade_filter.cardChosen.dismantlement = sgs.ai_choicemade_filter.cardChosen.snatch

function SmartAI:useCardCollateral(card, use)
	if self.player:hasSkill("noswuyan") then return end
	local fromList = sgs.QList2Table(self.room:getOtherPlayers(self.player))
	local toList = sgs.QList2Table(self.room:getAlivePlayers())

	local cmp = function(a, b)
		local alevel = self:objectiveLevel(a)
		local blevel = self:objectiveLevel(b)

		if alevel ~= blevel then return alevel > blevel end

		local anum = getCardsNum("Slash", a, self.player)
		local bnum = getCardsNum("Slash", b, self.player)
		if anum ~= bnum then return anum < bnum end
		return a:getHandcardNum() < b:getHandcardNum()
	end

	table.sort(fromList, cmp)
	self:sort(toList, "defense")

	local needCrossbow = false
	for _, enemy in ipairs(self.enemies) do
		if self.player:canSlash(enemy) and self:objectiveLevel(enemy) > 3
			and sgs.isGoodTarget(enemy, self.enemies, self) and not self:slashProhibit(nil, enemy) then
			needCrossbow = true
			break
		end
	end

	needCrossbow = needCrossbow and self:getCardsNum("Slash") > 2 and not self.player:hasSkill("paoxiao")

	if needCrossbow then
		for i = #fromList, 1, -1 do
			local friend = fromList[i]
			if (not use.current_targets or not table.contains(use.current_targets, friend:objectName()))
				and friend:getWeapon() and friend:getWeapon():isKindOf("Crossbow") and self:hasTrickEffective(card, friend) then
				for _, enemy in ipairs(toList) do
					if friend:canSlash(enemy, nil) and friend:objectName() ~= enemy:objectName() then
						self.player:setFlags("AI_CollateralNeedCrossbow")
						use.card = card
						if use.to then use.to:append(friend) end
						if use.to then use.to:append(enemy) end
						return
					end
				end
			end
		end
	end

	local n = nil
	local final_enemy = nil
	for _, enemy in ipairs(fromList) do
		if (not use.current_targets or not table.contains(use.current_targets, enemy:objectName()))
			and self:hasTrickEffective(card, enemy)
			and not enemy:hasSkills(sgs.lose_equip_skill)
			and self:objectiveLevel(enemy) >= 0
			and enemy:getWeapon() then

			for _, enemy2 in ipairs(toList) do
				if enemy:canSlash(enemy2) and self:objectiveLevel(enemy2) > 3 and enemy:objectName() ~= enemy2:objectName() then
					n = 1
					final_enemy = enemy2
					break
				end
			end

			if not n then
				for _, enemy2 in ipairs(toList) do
					if enemy:canSlash(enemy2) and self:objectiveLevel(enemy2) <= 3 and self:objectiveLevel(enemy2) >= 0 and enemy:objectName() ~= enemy2:objectName() then
						n = 1
						final_enemy = enemy2
						break
					end
				end
			end

			if not n then
				for _, friend in ipairs(toList) do
					if enemy:canSlash(friend) and self:objectiveLevel(friend) < 0 and enemy:objectName() ~= friend:objectName()
						and (self:needToLoseHp(friend, enemy, true) or self:getDamagedEffects(friend, enemy, true)) then
						n = 1
						final_enemy = friend
						break
					end
				end
			end

			if not n then
				for _, friend in ipairs(toList) do
					if enemy:canSlash(friend) and self:objectiveLevel(friend) < 0 and enemy:objectName() ~= friend:objectName()
						and getKnownCard(friend, self.player, "Jink", true, "he") >= 2 then
						n = 1
						final_enemy = friend
						break
					end
				end
			end

			if n then
				use.card = card
				if use.to then use.to:append(enemy) end
				if use.to then use.to:append(final_enemy) end
				return
			end
		end
		n = nil
	end

	for _, friend in ipairs(fromList) do
		if (not use.current_targets or not table.contains(use.current_targets, friend:objectName()))
			and friend:getWeapon() and (getKnownCard(friend, self.player, "Slash", true, "he") > 0 or (getCardsNum("Slash", friend, self.player) > 1 and friend:getHandcardNum() >= 4))
			and self:hasTrickEffective(card, friend)
			and self:objectiveLevel(friend) < 0 then

			for _, enemy in ipairs(toList) do
				if friend:canSlash(enemy, nil) and self:objectiveLevel(enemy) > 3 and friend:objectName() ~= enemy:objectName()
					and sgs.isGoodTarget(enemy, self.enemies, self) and not self:slashProhibit(nil, enemy) then
					use.card = card
					if use.to then use.to:append(friend) end
					if use.to then use.to:append(enemy) end
					return
				end
			end
		end
	end

	self:sortEnemies(toList)

	for _, friend in ipairs(fromList) do
		if (not use.current_targets or not table.contains(use.current_targets, friend:objectName()))
			and friend:getWeapon() and friend:hasSkills(sgs.lose_equip_skill)
			and self:hasTrickEffective(card, friend)
			and self:objectiveLevel(friend) < 0
			and not (friend:getWeapon():isKindOf("Crossbow") and getCardsNum("Slash", friend, self.player) > 1) then

			for _, enemy in ipairs(toList) do
				if friend:canSlash(enemy, nil) and friend:objectName() ~= enemy:objectName() then
					use.card = card
					if use.to then use.to:append(friend) end
					if use.to then use.to:append(enemy) end
					return
				end
			end
		end
	end
end

sgs.ai_use_value.Collateral = 5.8
sgs.ai_use_priority.Collateral = 2.75
sgs.ai_keep_value.Collateral = 3.40

sgs.ai_card_intention.Collateral = function(self, card, from, tos)
	--assert(#tos == 1)
	-- bugs here?
	--[[if sgs.compareRoleEvaluation(tos[1], "rebel", "loyalist") ~= sgs.compareRoleEvaluation(from, "rebel", "loyalist") then
		sgs.updateIntention(from, tos[1], 80)
	end]]
	sgs.ai_collateral = true
end

sgs.ai_skill_cardask["collateral-slash"] = function(self, data, pattern, target, target2)
	if target2 and target2:hasFlag("AI_CollateralNeedCrossbow") and self:isFriend(target2) then
		return "."
	end
	if self:isFriend(target) and self:findLeijiTarget(target, 50, self.player) then
		for _, slash in ipairs(self:getCards("Slash")) do
			if self:slashIsEffective(slash, target) then
				return slash:toString()
			end
		end
	end
	if target and (self:getDamagedEffects(target, self.player, true) or self:needToLoseHp(target, self.player, true)) then
		for _, slash in ipairs(self:getCards("Slash")) do
			if self:slashIsEffective(slash, target) and self:isFriend(target) then
				return slash:toString()
			end
			if not self:slashIsEffective(slash, target) and self:isEnemy(target) then
				return slash:toString()
			end
		end
		for _, slash in ipairs(self:getCards("Slash")) do
			if not self:getDamagedEffects(target, self.player, true) and self:isEnemy(target) then
				return slash:toString()
			end
		end
	end

	if self:needBear() then return "." end
	if target and not self.player:hasSkills(sgs.lose_equip_skill) and self:isEnemy(target) then
		for _, slash in ipairs(self:getCards("Slash")) do
			if self:slashIsEffective(slash, target) then
				return slash:toString()
			end
		end
	end
	if target and not self.player:hasSkills(sgs.lose_equip_skill) and self:isFriend(target) then
		for _, slash in ipairs(self:getCards("Slash")) do
			if not self:slashIsEffective(slash, target) then
				return slash:toString()
			end
		end
		if (target:getHp() > 2 or getCardsNum("Jink", target, self.player) > 1) and target:getRole() ~= "lord" and self.player:getHandcardNum() > 1 then
			for _, slash in ipairs(self:getCards("Slash")) do
				return slash:toString()
			end
		end
	end
	return "."
end

local function hp_subtract_handcard(a, b)
	local diff1 = a:getHp() - a:getHandcardNum()
	local diff2 = b:getHp() - b:getHandcardNum()

	return diff1 < diff2
end

function SmartAI:enemiesContainsTrick(enemy_count)
	local trick_all, possible_indul_enemy, possible_ss_enemy = 0, 0, 0
	local enemy_num, temp_enemy = 0

	local zhanghe = self.room:findPlayerBySkillName("qiaobian")
	if zhanghe and (not self:isEnemy(zhanghe) or zhanghe:isKongcheng() or not zhanghe:faceUp()) then zhanghe = nil end

	local indul_num, ss_num = 0, 0
	for _, acard in sgs.qlist(self.player:getCards("he")) do
		if isCard("Indulgence", acard, self.player) then indul_num = indul_num + 1 end
		if isCard("SupplyShortage", acard, self.player) then ss_num = ss_num + 1 end
	end

	for _, enemy in ipairs(self.enemies) do
		if not enemy:containsTrick("YanxiaoCard") then
			if enemy:containsTrick("indulgence") then
				if not enemy:hasSkill("keji") and (not zhanghe or self:playerGetRound(enemy) >= self:playerGetRound(zhanghe)) then
					trick_all = trick_all + 1
					if not temp_enemy or temp_enemy:objectName() ~= enemy:objectName() then
						enemy_num = enemy_num + 1
						temp_enemy = enemy
					end
				end
			else
				possible_indul_enemy = possible_indul_enemy + 1
			end
			if self.player:distanceTo(enemy) == 1 or (self.player:hasSkill("duanliang") and self.player:distanceTo(enemy) <= 2) then
				if enemy:containsTrick("supply_shortage") then
					if not enemy:hasSkill("shensu") and (not zhanghe or self:playerGetRound(enemy) >= self:playerGetRound(zhanghe)) then
						trick_all = trick_all + 1
						if not temp_enemy or temp_enemy:objectName() ~= enemy:objectName() then
							enemy_num = enemy_num + 1
							temp_enemy = enemy
						end
					end
				else
					possible_ss_enemy  = possible_ss_enemy + 1
				end
			end
		end
	end

	indul_num = math.min(possible_indul_enemy, indul_num)
	ss_num = math.min(possible_ss_enemy, ss_num)
	trick_all = (enemy_count and enemy_num or trick_all) + indul_num + ss_num
	return trick_all
end

function SmartAI:playerGetRound(player, source)
	if not player then self.room:writeToConsole(debug.traceback()) return 0 end
	source = source or self.room:getCurrent() or self.player
	if player:objectName() == source:objectName() then return 0 end
	return (player:getSeat() - source:getSeat()) % self.room:alivePlayerCount()
end

function SmartAI:useCardIndulgence(card, use)
	local enemies = {}
	if #self.enemies == 0 then
		if sgs.turncount <= 1 and self.role == "lord" and not sgs.isRolePredictable()
			and sgs.evaluatePlayerRole(self.player:getNextAlive()) == "neutral"
			and not (self.player:hasLordSkill("shichou") and self.player:getNextAlive():getKingdom() == "shu") then
			enemies = self:exclude({ self.player:getNextAlive() }, card)
		end
	else
		enemies = self:exclude(self.enemies, card)
	end
	if #enemies == 0 then return end

	local zhanghe = self.room:findPlayerBySkillName("qiaobian")
	local zhanghe_seat = zhanghe and zhanghe:faceUp() and not self:isFriend(zhanghe) and zhanghe:getSeat() or 0

	local sb_daqiao = self.room:findPlayerBySkillName("yanxiao")
	local yanxiao = sb_daqiao and not self:isFriend(sb_daqiao) and sb_daqiao:faceUp()
					and (self:hasSuit("diamond", true, sb_daqiao)
						or sb_daqiao:getHandcardNum() > 2
						or sb_daqiao:containsTrick("YanxiaoCard"))

	local getvalue = function(enemy)
		if enemy:containsTrick("indulgence") or enemy:containsTrick("YanxiaoCard")
			or (enemy:hasSkill("qiaobian") and not enemy:isKongcheng()
				and not enemy:containsTrick("supply_shortage") and not enemy:containsTrick("indulgence")) then
			return -100
		end
		if zhanghe_seat > 0 and (self:playerGetRound(zhanghe) <= self:playerGetRound(enemy) and self:enemiesContainsTrick() <= 1 or not enemy:faceUp()) then
			return -100
		end
		if yanxiao and (self:playerGetRound(sb_daqiao) <= self:playerGetRound(enemy) and self:enemiesContainsTrick(true) <= 1 or not enemy:faceUp()) then
			return -100
		end

		local value = enemy:getHandcardNum() - enemy:getHp()

		if enemy:hasSkills("noslijian|lijian|fanjian|nosfanjian|dimeng|jijiu|jieyin|anxu|yongsi|zhiheng|manjuan|nosrende|rende|qixi|jixi") then value = value + 10 end
		if enemy:hasSkills("qice|nosguose|guose|duanliang|nosjujian|luoshen|nosjizhi|jizhi|jilve|wansha|mingce") then value = value + 5 end
		if enemy:hasSkills("guzheng|luoying|yinling|gongxin|shenfen|ganlu|duoshi") then value = value + 3 end
		if self:isWeak(enemy) then value = value + 3 end
		if enemy:isLord() then value = value + 3 end

		if self:objectiveLevel(enemy) < 3 then value = value -10 end
		if not enemy:faceUp() then value = value -10 end
		if enemy:hasSkills("keji|shensu") then value = value - enemy:getHandcardNum() end
		if enemy:hasSkills("guanxing|xiuluo") then value = value - 5 end
		if enemy:hasSkills("lirang") then value = value - 5 end
		if enemy:hasSkills("tuxi|nostuxi|noszhenlie|guanxing|qinyin|zongshi|tiandu") then value = value - 3 end
		if self:needBear(enemy) then value = value - 20 end
		if not sgs.isGoodTarget(enemy, self.enemies, self) then value = value - 1 end
		if getKnownCard(enemy, self.player, "Dismantlement", true) > 0 then value = value + 2 end
		value = value + (self.room:alivePlayerCount() - self:playerGetRound(enemy)) / 2
		return value
	end

	local cmp = function(a, b)
		return getvalue(a) > getvalue(b)
	end

	table.sort(enemies, cmp)

	local target = enemies[1]
	if getvalue(target) > -100 then
		use.card = card
		if use.to then use.to:append(target) end
		return
	end
end

sgs.ai_use_value.Indulgence = 8
sgs.ai_use_priority.Indulgence = 0.5
sgs.ai_keep_value.Indulgence = 3.5
sgs.ai_card_intention.Indulgence = 120

function SmartAI:willUseLightning(card)
	if self.player:containsTrick("lightning") then return false end
	if self.player:hasSkill("weimu") and card:isBlack() then return false end
	if self.room:isProhibited(self.player, self.player, card) then return false end

	--if not self:hasWizard(self.enemies) then--and self.room:isProhibited(self.player, self.player, card) then
	local function hasDangerousFriend()
		local hashy = false
		for _, aplayer in ipairs(self.enemies) do
			if aplayer:hasSkill("hongyan") then hashy = true break end
		end
		for _, aplayer in ipairs(self.enemies) do
			if aplayer:hasSkill("guanxing") or (aplayer:hasSkill("gongxin") and hashy)
			or aplayer:hasSkill("xinzhan") then
				if self:isFriend(aplayer:getNextAlive()) then return true end
			end
		end
		return false
	end
	if self:getFinalRetrial(self.player) == 2 then
		return false
	elseif self:getFinalRetrial(self.player) == 1 then
		return true
	elseif not hasDangerousFriend() then
		local players = self.room:getAllPlayers()
		players = sgs.QList2Table(players)

		local friends = 0
		local enemies = 0

		for _, player in ipairs(players) do
			if self:objectiveLevel(player) >= 4 and not player:hasSkill("hongyan")
				and not (player:hasSkill("weimu") and card:isBlack()) then
				enemies = enemies + 1
			elseif self:isFriend(player) then
				friends = friends + 1
			end
		end

		local ratio
		if friends == 0 then ratio = 999 else ratio = enemies / friends end

		if ratio > 1.5 then
			return true
		end
	end
	return false
end

function SmartAI:useCardLightning(card, use)
	if self:willUseLightning(card) then
		use.card = card
	end
end

sgs.dynamic_value.lucky_chance.Lightning = true

sgs.ai_keep_value.Lightning = -1

sgs.ai_skill_askforag.amazing_grace = function(self, card_ids)
	local nextPlayerCanUse, nextPlayerIsEnemy = false, false
	local nextAlive = self.player:getNextAlive()
	if not nextAlive:hasSkill("manjuan") and sgs.turncount > 1 and not self:willSkipPlayPhase(nextAlive) then
		if self:isFriend(nextAlive) then
			nextPlayerCanUse = true
		else
			nextPlayerIsEnemy = true
		end
	end

	local cards = {}
	local trickCards = {}
	for _, card_id in ipairs(card_ids) do
		local acard = sgs.Sanguosha:getCard(card_id)
		table.insert(cards, acard)
		if acard:getTypeId() == sgs.Card_TypeTrick then
			table.insert(trickCards, acard)
		end
	end

	local nextFriendNum = 0
	local aplayer = self.player:getNextAlive()
	for i = 1, self.player:aliveCount() do
		if self:isFriend(aplayer) then
			aplayer = aplayer:getNextAlive()
			if not aplayer:hasSkill("manjuan") then nextFriendNum = nextFriendNum + 1 end
		else
			break
		end
	end

	local selfIsCurrent = (self.player:getPhase() == sgs.Player_Play)
	local wuguotai = self.room:findPlayerBySkillName("buyi")
	local nextNeedBuyi = false
	if not nextAlive:hasSkill("manjuan") and wuguotai and self:isFriend(nextAlive, wuguotai) and self:isWeak(nextAlive) then nextNeedBuyi = true end

	if self.player:hasSkill("manjuan") and self.player:getPhase() == sgs.Player_NotActive then
		if self:isFriend(nextAlive) then
			self:sortByCardNeed(cards)
			local index = 1
			if nextNeedBuyi and no_basic_num == 1 then index = 2 end
			return cards[index]:getEffectiveId()
		elseif self:isEnemy(nextAlive) then
			self:sortByCardNeed(cards, true)
			if nextNeedBuyi and no_basic_num == 1 then
				for _, c in ipairs(cards) do
					if c:getTypeId() ~= sgs.Card_TypeBasic then return c:getEffectiveId() end
				end
			end
			return cards[1]:getEffectiveId()
		end
	end

	if nextNeedBuyi then
		local maxvaluecard, minvaluecard
		local maxvalue, minvalue = -100, 100
		for _, bycard in ipairs(cards) do
			if not bycard:isKindOf("BasicCard") then
				local value = self:getUseValue(bycard)
				if value > maxvalue then
					maxvalue = value
					maxvaluecard = bycard
				end
				if value < minvalue then
					minvalue = value
					minvaluecard = bycard
				end
			end
		end
		if minvaluecard and nextPlayerCanUse then
			return minvaluecard:getEffectiveId()
		end
		if maxvaluecard then
			return maxvaluecard:getEffectiveId()
		end
	end

	local friendNeedPeach, peach
	local peachnum, jinknum = 0, 0
	if nextPlayerCanUse then
		if (not self.player:isWounded() and nextAlive:isWounded())
			or (self.player:getLostHp() < self:getCardsNum("Peach"))
			or (not selfIsCurrent and self:willSkipPlayPhase() and self.player:getHandcardNum() + 2 > self.player:getMaxCards()) then
			friendNeedPeach = true
		end
	end
	for _, card in ipairs(cards) do
		if card:isKindOf("Peach") then
			peach = card:getEffectiveId()
			peachnum = peachnum + 1
		end
		if card:isKindOf("Jink") then jinknum = jinknum + 1 end
	end
	if (not friendNeedPeach and peach) or peachnum > 1 then return peach end

	local exnihilo, jink, analeptic, nullification, snatch, dismantlement, indulgence
	for _, card in ipairs(cards) do
		if isCard("ExNihilo", card, self.player) then
			if not nextPlayerCanUse or (not self:willSkipPlayPhase() and (self.player:hasSkills("nosjizhi|jizhi|zhiheng|nosrende|rende") or not nextAlive:hasSkills("nosjizhi|jizhi|zhiheng"))) then
				exnihilo = card:getEffectiveId()
			end
		elseif isCard("Jink", card, self.player) then
			jink = card:getEffectiveId()
		elseif isCard("Analeptic", card, self.player) then
			analeptic = card:getEffectiveId()
		elseif isCard("Nullification", card, self.player) then
			nullification = card:getEffectiveId()
		elseif isCard("Snatch", card, self.player) then
			snatch = card
		elseif isCard("Dismantlement", card, self.player) then
			dismantlement = card
		elseif isCard("Indulgence", card, self.player) then
			indulgence = card:getEffectiveId()
		end
	end

	for _, target in sgs.qlist(self.room:getAlivePlayers()) do
		if self:willSkipPlayPhase(target) or self:willSkipDrawPhase(target) then
			if nullification then return nullification
			elseif self:isFriend(target) and snatch and self:hasTrickEffective(snatch, target, self.player)
					and not self:willSkipPlayPhase() and self.player:distanceTo(target) == 1 then
				return snatch:getEffectiveId()
			elseif self:isFriend(target) and dismantlement and self:hasTrickEffective(dismantlement, target, self.player)
					and not self:willSkipPlayPhase() and self.player:objectName() ~= target:objectName() then
				return dismantlement:getEffectiveId()
			end
		end
	end

	if selfIsCurrent then
		if exnihilo then return exnihilo end
		if (jink or analeptic) and (self:getCardsNum("Jink") == 0 or (self:isWeak() and self:getOverflow() == 0)) then
			return jink or analeptic
		end
		if indulgence then return indulgence end
	else
		local CP = self.room:getCurrent()
		local possible_attack = 0
		for _, enemy in ipairs(self.enemies) do
			if enemy:inMyAttackRange(self.player) and self:playerGetRound(CP, enemy) < self:playerGetRound(CP, self.player) then
				possible_attack = possible_attack + 1
			end
		end
		if possible_attack > self:getCardsNum("Jink") and self:getCardsNum("Jink") <= 2 and sgs.getDefenseSlash(self.player, self) <= 2 then
			if jink or analeptic or exnihilo then return jink or analeptic or exnihilo end
		else
			if exnihilo or indulgence then return exnihilo or indulgence end
		end
	end

	if nullification and (self:getCardsNum("Nullification") < 2 or not nextPlayerCanUse) then 
		return nullification
	end

	if jinknum == 1 and jink and self:isEnemy(nextAlive) and (nextAlive:isKongcheng() or sgs.card_lack[nextAlive:objectName()]["Jink"] == 1) then
		return jink
	end

	local eightdiagram, silverlion, vine, renwang, armor, defHorse, offHorse, wooden_ox
	local weapon, crossbow, halberd, double, qinggang, axe, gudingblade
	for _, card in ipairs(cards) do
		if card:isKindOf("EightDiagram") then eightdiagram = card:getEffectiveId()
		elseif card:isKindOf("SilverLion") then silverlion = card:getEffectiveId()
		elseif card:isKindOf("Vine") then vine = card:getEffectiveId()
		elseif card:isKindOf("RenwangShield") then renwang = card:getEffectiveId()
		elseif card:isKindOf("DefensiveHorse") and not self:getSameEquip(card) then defHorse = card:getEffectiveId()
		elseif card:isKindOf("OffensiveHorse") and not self:getSameEquip(card) then offHorse = card:getEffectiveId()
		elseif card:isKindOf("Crossbow") then crossbow = card:getEffectiveId()
		elseif card:isKindOf("DoubleSword") then double = card:getEffectiveId()
		elseif card:isKindOf("QinggangSword") then qinggang = card:getEffectiveId()
		elseif card:isKindOf("Axe") then axe = card:getEffectiveId()
		elseif card:isKindOf("GudingBlade") then gudingblade = card:getEffectiveId()
		elseif card:isKindOf("Halberd") then halberd = card:getEffectiveId() end
		if card:isKindOf("Armor") then armor = card:getEffectiveId()
		elseif card:isKindOf("Weapon") then weapon = card:getEffectiveId()
		elseif card:isKindOf("WoodenOx") then wooden_ox = card:getEffectiveId()
		end
	end

	if armor and not self.player:hasSkills("yizhong|bazhen|bossmanjia") then
		if eightdiagram then
			local lord = self.room:getLord()
			if self.player:hasSkills("tiandu|leiji|nosleiji|noszhenlie|gushou|hongyan") and not self:getSameEquip(sgs.Sanguosha:getCard(eightdiagram)) then
				return eightdiagram
			end
			if nextPlayerIsEnemy and nextAlive:hasSkills("tiandu|leiji|nosleiji|noszhenlie|gushou|hongyan") and not nextAlive:hasSkills("bazhen|yizhong|bossmanjia")
				and not self:getSameEquip(sgs.Sanguosha:getCard(eightdiagram), nextAlive) then
				return eightdiagram
			end
			if self.role == "loyalist" and self.player:getKingdom() == "wei"
				and lord and lord:hasLordSkill("hujia") and ((lord:objectName() ~= nextAlive:objectName() and nextPlayerIsEnemy) or lord:getArmor()) then
				return eightdiagram
			end
			if sgs.ai_armor_value.eight_diagram(self.player, self) >= 5 then return eightdiagram end
		end

		if silverlion then
			local lightning
			for _, aplayer in sgs.qlist(self.room:getOtherPlayers(self.player)) do
				if aplayer:hasSkill("nosleiji") and self:isEnemy(aplayer) then
					return silverlion
				end
				if aplayer:containsTrick("lightning") then
					lightning = true
				end
			end
			if lightning and self:hasWizard(self.enemies) then return silverlion end
			if self.player:isChained() then
				for _, friend in ipairs(self.friends) do
					if friend:hasArmorEffect("vine") and friend:isChained() then
						return silverlion
					end
				end
			end
			if self.player:isWounded() then return silverlion end
		end

		if vine then
			if sgs.ai_armor_value.vine(self.player, self) > 0 and self.room:alivePlayerCount() <= 3 then
				return vine
			end
		end

		if renwang then
			if sgs.ai_armor_value.renwang_shield(self.player, self) > 0 and self:getCardsNum("Jink") == 0 then return renwang end
		end
	end

	if defHorse and (not self.player:hasSkills("leiji|nosleiji") or self:getCardsNum("Jink") == 0) then
		local before_num, after_num = 0, 0
		for _, enemy in ipairs(self.enemies) do
			if enemy:canSlash(self.player, nil, true) then
				before_num = before_num + 1
			end
			if enemy:canSlash(self.player, nil, true, 1) then
				after_num = after_num + 1
			end
		end
		if before_num > after_num and (self:isWeak() or self:getCardsNum("Jink") == 0) then return defHorse end
	end

	if wooden_ox then
		local zhanghe = self.room:findPlayerBySkillName("qiaobian")
		local wuguotai = self.room:findPlayerBySkillName("ganlu")
		if not (zhanghe and self:isEnemy(zhanghe)) and not (wuguotai and self:isEnemy(wuguotai)) then return wooden_ox end
	end

	if analeptic then
		local slashs = self:getCards("Slash")
		for _, enemy in ipairs(self.enemies) do
			local hit_num = 0
			for _, slash in ipairs(slashs) do
				if self:slashIsEffective(slash, enemy) and self.player:canSlash(enemy, slash) and self:slashIsAvailable() then
					hit_num = hit_num + 1
					if getCardsNum("Jink", enemy, self.player) < 1
						or enemy:isKongcheng() 
						or self.player:hasSkills("tieji|nostieji|liegong|kofliegong|wushuang|dahe|qianxi")
						or self.player:hasSkill("roulin") and enemy:isFemale()
						or (self.player:hasWeapon("axe") or self:getCardsNum("Axe") > 0) and self.player:getCards("he"):length() > 4 then
						return analeptic
					end
				end
			end
			if (self.player:hasWeapon("blade") or self:getCardsNum("Blade") > 0) and getCardsNum("Jink", enemy, self.player) <= hit_num then return analeptic end
			if self:hasCrossbowEffect(self.player) and hit_num >= 2 then return analeptic end
		end
	end

	if weapon and (self:getCardsNum("Slash") > 0 and self:slashIsAvailable() or not selfIsCurrent) then
		local current_range = self.player:getAttackRange()
		local nosuit_slash = sgs.cloneCard("slash")
		local slash = selfIsCurrent and self:getCard("Slash") or nosuit_slash

		self:sort(self.enemies, "defense")

		if crossbow then
			if self:getCardsNum("Slash") > 1 or self.player:hasSkills("noskurou|keji") 
				or (self.player:hasSkills("luoshen|yongsi|luoying|guzheng") and not selfIsCurrent and self.room:alivePlayerCount() >= 4) then
				return crossbow
			end
			if self.player:hasSkill("guixin") and self.room:alivePlayerCount() >= 6 and (self.player:getHp() > 1 or self:getCardsNum("Peach") > 0) then
				return crossbow
			end
			if self.player:hasSkills("nosrende|rende") then
				for _, friend in ipairs(self.friends_noself) do
					if getCardsNum("Slash", friend) > 1 then
						return crossbow
					end
				end
			end
			if nextPlayerIsEnemy then
				local canSave, huanggai
				for _, enemy in ipairs(self.enemies) do
					if enemy:hasSkill("buyi") then canSave = true end
					if enemy:hasSkill("jijiu") and getKnownCard(enemy, self.player, "red", nil, "he") > 1 then canSave = true end
					if enemy:hasSkill("chunlao") and enemy:getPile("wine"):length() > 1 then canSave = true end
					if enemy:hasSkill("noskurou") then huanggai = enemy end
					if enemy:hasSkill("keji") then return crossbow end
					if enemy:hasSkills("luoshen|yongsi|guzheng") then return crossbow end
					if enemy:hasSkill("luoying") and sgs.Sanguosha:getCard(crossbow):getSuit() ~= sgs.Card_Club then return crossbow end
				end
				if huanggai and (huanggai:getHp() > 2 or canSave) then return crossbow end
				if getCardsNum("Slash", nextAlive, self.player) >= 3 then return crossbow end
			end
		end

		if halberd and #self.enemies >= 2 then
			if self.player:hasSkills("nosrende|rende") and self:findFriendsByType(sgs.Friend_Draw) then return halberd end
			if selfIsCurrent and self.player:getHandcardNum() == 1 and self.player:getHandcards():first():isKindOf("Slash") then return halberd end
		end

		if gudingblade then
			local range_fix = current_range - 2
			for _, enemy in ipairs(self.enemies) do
				if self.player:canSlash(enemy, slash, true, range_fix) and enemy:isKongcheng() and (not enemy:hasSkill("tianming") or enemy:hasSkill("manjuan")) and
					(not selfIsCurrent or (self:getCardsNum("Dismantlement") > 0 or (self:getCardsNum("Snatch") > 0 and self.player:distanceTo(enemy) == 1))) then
					return gudingblade
				end
			end
		end

		if axe then
			local range_fix = current_range - 3
			local FFFslash = self:getCard("FireSlash")
			for _, enemy in ipairs(self.enemies) do
				if enemy:hasArmorEffect("vine") and FFFslash and self:slashIsEffective(FFFslash, enemy) and 
					self.player:getCardCount() >= 3 and self.player:canSlash(enemy, FFFslash, true, range_fix) then
					return axe
				elseif self:getCardsNum("Analeptic") > 0 and self.player:getCardCount() >= 4 and
					self:slashIsEffective(slash, enemy) and self.player:canSlash(enemy, slash, true, range_fix) then
					return axe
				end
			end
		end

		if double then
			local range_fix = current_range - 2
			for _, enemy in ipairs(self.enemies) do
				if self.player:getGender() ~= enemy:getGender() and self.player:canSlash(enemy, nil, true, range_fix) then
					return double
				end
			end
		end

		if qinggang then
			local range_fix = current_range - 2
			for _, enemy in ipairs(self.enemies) do
				if self.player:canSlash(enemy, slash, true, range_fix) and self:slashIsEffective(slash, enemy, self.player, true) then
					return qinggang
				end
			end
		end
	end

	self:sortByUseValue(cards)
	for _, card in ipairs(cards) do
		for _, skill in ipairs(sgs.getPlayerSkillList(self.player)) do
			local callback = sgs.ai_cardneed[skill:objectName()]
			if type(callback) == "function" and callback(self.player, card, self) then
				return card:getEffectiveId()
			end
		end
	end

	local ag_snatch, ag_dismantlement, ag_indulgence, ag_supplyshortage, ag_collateral, ag_duel, ag_aoe, ag_fireattack, ag_godsalvation, ag_lightning
	local new_enemies = {}
	if #self.enemies > 0 then
		new_enemies = self.enemies
	else
		for _, aplayer in sgs.qlist(self.room:getOtherPlayers(self.player)) do
			if sgs.evaluatePlayerRole(aplayer) == "neutral" then
				table.insert(new_enemies, aplayer)
			end
		end
	end
	local hasTrick = false
	for _, card in ipairs(cards) do
		for _, enemy in ipairs(new_enemies) do
			if not enemy:isNude() and isCard("Snatch", card, self.player) and self:hasTrickEffective(sgs.cloneCard("snatch", card:getSuit(), card:getNumber()), enemy) and self.player:distanceTo(enemy) == 1 then
				ag_snatch = card:getEffectiveId()
				hasTrick = true
			elseif not enemy:isNude() and ((isCard("Dismantlement", card, self.player) and self:hasTrickEffective(sgs.cloneCard("dismantlement", card:getSuit(), card:getNumber()), enemy))
											or (card:isBlack() and self.player:hasSkill("yinling") and self.player:getPile("brocade"):length() < 4)) then
				ag_dismantlement = card:getEffectiveId()
				hasTrick = true
			elseif isCard("Indulgence", card, self.player) and self:hasTrickEffective(sgs.cloneCard("indulgence", card:getSuit(), card:getNumber()), enemy)
				and not enemy:containsTrick("indulgence") and not self:willSkipPlayPhase(enemy) then
				ag_indulgence = card:getEffectiveId()
				hasTrick = true
			elseif isCard("SupplyShortage", card, self.player) and self:hasTrickEffective(sgs.cloneCard("supply_shortage", card:getSuit(), card:getNumber()), enemy)
				and not enemy:containsTrick("supply_shortage") and not self:willSkipDrawPhase(enemy) then
				ag_supplyshortage = card:getEffectiveId()
				hasTrick = true
			elseif isCard("Collateral", card, self.player) and self:hasTrickEffective(sgs.cloneCard("collateral", card:getSuit(), card:getNumber()), enemy) and enemy:getWeapon() then
				ag_collateral = card:getEffectiveId()
				hasTrick = true
			elseif isCard("Duel", card, self.player) and (self:getCardsNum("Slash") >= getCardsNum("Slash", enemy, self.player) or self.player:getHandcardNum() > 4)
				and self:hasTrickEffective(sgs.cloneCard("duel", card:getSuit(), card:getNumber()), enemy) then
				ag_duel = card:getEffectiveId()
				hasTrick = true
			elseif card:isKindOf("AOE") then
				local dummy_use = { isDummy = true }
				self:useTrickCard(card, dummy_use)
				if dummy_use.card then
					aoe = card:getEffectiveId()
					hasTrick = true
				end
			elseif isCard("FireAttack", card, self.player) and self:hasTrickEffective(sgs.cloneCard("fire_attack", card:getSuit(), card:getNumber()), enemy)
				and self:damageIsEffective(enemy, sgs.DamageStruct_Fire, self.player) then

				local FFF
				if self.player:hasSkill("hongyan") and self:hasSuit("spade", false, enemy) then FFF = false end
				if not FFF and enemy:getHp() == 1 or ((enemy:hasArmorEffect("vine") or enemy:getMark("@gale") > 0) and not self.player:hasSkill("jueqing")) then FFF = true end
				if FFF then
					local suits = {}
					local suitnum = 0
					for _, hcard in sgs.qlist(self.player:getHandcards()) do
						if hcard:getSuit() == sgs.Card_Spade then suits.spade = true
						elseif hcard:getSuit() == sgs.Card_Heart then suits.heart = true
						elseif hcard:getSuit() == sgs.Card_Club then suits.club = true
						elseif hcard:getSuit() == sgs.Card_Diamond then suits.diamond = true
						end
					end
					for k, hassuit in pairs(suits) do
						if hassuit then suitnum = suitnum + 1 end
					end
					if suitnum >= 3 or (suitnum >= 2 and enemy:getHandcardNum() == 1) then
						ag_fireattack = card:getEffectiveId()
						hasTrick = true
					end
				end
			elseif isCard("GodSalvation", card, self.player) and self:willUseGodSalvation(sgs.cloneCard("god_salvation", card:getSuit(), card:getNumber())) then
				ag_godsalvation = card:getEffectiveId()
				hasTrick = true
			elseif card:isKindOf("Lightning") and self:willUseLightning(card) then
				ag_lightning = card:getEffectiveId()
				hasTrick = true
			end
		end
	end

	for _, card in ipairs(cards) do
		for _, friend in ipairs(self.friends_noself) do
			if self:willSkipPlayPhase(friend, true) or self:willSkipDrawPhase(friend, true) or self:needToThrowArmor(friend) then
				if self:hasTrickEffective(sgs.cloneCard("snatch", card:getSuit(), card:getNumber()), enemy) and isCard("Snatch", card, self.player) and self.player:distanceTo(friend) == 1 then
					ag_snatch = card:getEffectiveId()
					hasTrick = true
				elseif (isCard("Dismantlement", card, self.player) and self:hasTrickEffective(sgs.cloneCard("dismantlement", card:getSuit(), card:getNumber()), enemy))
						or (card:isBlack() and self.player:hasSkill("yinling") and self.player:getPile("brocade"):length() < 4) then
					ag_dismantlement = card:getEffectiveId()
					hasTrick = true
				end
			end
		end
	end

	if hasTrick then
		if not self:willSkipPlayPhase() or not nextPlayerCanUse then
			return ag_snatch or ag_dismantlement or ag_indulgence or ag_supplyshortage or ag_collateral or ag_duel or ag_aoe or ag_godsalvation or ag_fireattack or ag_lightning
		end
		if #trickCards > nextFriendNum + 1 and nextPlayerCanUse then
			return ag_lightning or ag_fireattack or ag_godsalvation or ag_aoe or ag_duel or ag_collateral or ag_supplyshortage or ag_indulgence or ag_dismantlement or ag_snatch
		end
	end

	if weapon and not self.player:getWeapon() and self:getCardsNum("Slash") > 0 and (self:slashIsAvailable() or not selfIsCurrent) then
		local inAttackRange
		for _, enemy in ipairs(self.enemies) do
			if self.player:inMyAttackRange(enemy) then
				inAttackRange = true
				break
			end
		end
		if not inAttackRange then return weapon end
	end

	self:sortByCardNeed(cards, true)
	for _, card in ipairs(cards) do
		if not card:isKindOf("TrickCard") and not card:isKindOf("Peach") then
			return card:getEffectiveId()
		end
	end

	return cards[1]:getEffectiveId()
end

local wooden_ox_skill = {}
wooden_ox_skill.name = "wooden_ox"
table.insert(sgs.ai_skills, wooden_ox_skill)
wooden_ox_skill.getTurnUseCard = function(self)
	if self.player:hasUsed("WoodenOxCard") or self.player:isKongcheng() or not self.player:hasTreasure("wooden_ox") then return end
	self.wooden_ox_assist = nil
	local cards = sgs.QList2Table(self.player:getHandcards())
	self:sortByUseValue(cards, true)
	local card, friend = self:getCardNeedPlayer(cards)
	if card and friend and friend:objectName() ~= self.player:objectName() and (self:getOverflow() > 0 or self:isWeak(friend)) then
		self.wooden_ox_assist = friend
		return sgs.Card_Parse("@WoodenOxCard=" .. card:getEffectiveId())
	end
	if self:getOverflow() > 0 or (self:needKongcheng() and #cards == 1) then
		return sgs.Card_Parse("@WoodenOxCard=" .. cards[1]:getEffectiveId())
	end
end

sgs.ai_skill_use_func.WoodenOxCard = function(card, use, self)
	use.card = card
end

sgs.ai_skill_playerchosen.wooden_ox = function(self, targets)
	if self.wooden_ox_assist then return self.wooden_ox_assist end
	if self.player:hasSkill("yongsi") then
		local kingdoms = {}
		for _, p in sgs.qlist(self.room:getAlivePlayers()) do
			local kingdom = p:getKingdom()
			if not table.contains(kingdoms, kingdom) then table.insert(kingdoms, kingdom) end
		end
		if self.player:getCardCount(true) <= #kingdoms then
			self:sort(self.friends_noself)
			for _, friend in ipairs(self.friends_noself) do
				if not friend:getTreasure() then return friend end
			end
		end
	end
end

sgs.ai_playerchosen_intention.wooden_ox = -60