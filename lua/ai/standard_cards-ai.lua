function SmartAI:canAttack(enemy, attacker, nature)
	attacker = attacker or self.player
	nature = nature or sgs.DamageStruct_Normal
	local damage = 1
	if nature == sgs.DamageStruct_Fire and not enemy:hasArmorEffect("silver_lion") then
		if enemy:hasArmorEffect("vine") then damage = damage + 1 end
		if enemy:getMark("@gale") > 0 then damage = damage + 1 end
	end
	if #self.enemies == 1 or self:hasSkills("jueqing") then return true end
	if self:getDamagedEffects(enemy, attacker) or (enemy:getHp() > getBestHp(enemy) and #self.enemies > 1) or not sgs.isGoodTarget(enemy, self.enemies, self) then return false end
	if self:objectiveLevel(enemy) <= 3 or self:cantbeHurt(enemy, self.player, damage) or not self:damageIsEffective(enemy, nature, attacker) then return false end
	if nature ~= sgs.DamageStruct_Normal and enemy:isChained() and not self:isGoodChainTarget(enemy) then return false end
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
					or (player:hasSkill("buqu") and player:getPile("buqu"):length() <= 4)
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

function sgs.isGoodTarget(player, targets, self)
	local arr = { "jieming", "yiji", "guixin", "fangzhu", "neoganglie", "nosmiji" }
	local m_skill = false
	local attacker = global_room:getCurrent()
	if attacker:hasSkill("jueqing") then return true end

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
			if masochism == "nosmiji" and player:isWounded() then
				m_skill = false
			else
				m_skill = true
				break
			end
		end
	end

	if player:hasSkill("huilei") and player:getHp() == 1 then
		if attacker:getHandcardNum() >= 4 then return false end
		return sgs.compareRoleEvaluation(player, "rebel", "loyalist") == "rebel"
	end

	if player:hasSkill("wuhun") and (attacker:isLord() or player:getHp() <= 2) then
		return false
	end

	if player:hasLordSkill("shichou") and player:getMark("@hate") == 0 then
		for _, p in sgs.qlist(player:getRoom():getOtherPlayers(player)) do
			if p:getMark("@hate_" .. player:objectName()) > 0 and p:getMark("@hate_to") > 0 then
				return false
			end
		end
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

function sgs.getDefenseSlash(player)
	local attacker = global_room:getCurrent()
	local defense = getCardsNum("Jink", player)

	local knownJink = getKnownCard(player, "Jink", true)
	if sgs.card_lack[player:objectName()]["Jink"] == 1 and knownJink == 0 then defense = 0 end
 	defense = defense + knownJink * 1.2

	if (player:hasArmorEffect("eight_diagram") or player:hasArmorEffect("bazhen")) and not attacker:hasWeapon("qinggang_sword") then
		hasEightDiagram = true
	end

	if not hasEightDiagramEffect then
		if player:getMark("@qianxi_red") > 0 and (not player:hasSkill("qingguo") and not (player:hasSkill("longhun") and player:getHp() == 1)) then
			defense = 0
		elseif player:getMark("@qianxi_black") > 0 then
			if player:hasSkill("qingguo") then defense = defense / 2 end
			if player:hasSkill("longhun") and player:getHp() == 1 then defense = defense * 3 / 4 end
		end
	end

	if hasEightDiagram then
		defense = defense + 1.5
		if player:hasSkill("tiandu") then defense = defense + 0.6 end
		if player:hasSkill("guicai") or player:hasSkill("huanshi") then defense = defense + 0.3 end
	end

	if player:hasSkill("tuntian") and getCardsNum("Jink", player) > 0 then
		defense = defense + 1.5
	end

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

	local hcard = player:getHandcardNum()
	if attacker:hasSkill("liegong") and attacker:canSlashWithoutCrossbow() and (hcard >= attacker:getHp() or hcard <= attacker:getAttackRange()) then
		defense = 0
	end

	local m = sgs.masochism_skill:split("|")
	for _, masochism in ipairs(m) do
		if player:hasSkill(masochism) and sgs.isGoodHp(player) then
			defense = defense + 1.3
		end
	end

	if not sgs.isGoodTarget(player) then defense = defense + 10 end

	if player:hasSkill("rende") and player:getHp() > 2 then defense = defense + 3 end
	if player:hasSkill("kuanggu") and player:getHp() > 1 then defense = defense + 0.2 end
	if player:hasSkill("zaiqi") and player:getHp() > 1 then defense = defense + 0.35 end

	if player:getHp() > getBestHp(player) then defense = defense + 1.3 end
	if player:hasSkill("tianxiang") then defense = defense + player:getHandcardNum() * 0.5 end

	if player:getHp() <= 2 then defense = defense - 0.4 end

	local playernum = global_room:alivePlayerCount()
	if (player:getSeat() - attacker:getSeat()) % playernum >= playernum - 2 and playernum > 3 and player:getHandcardNum() <= 2 and player:getHp() <= 2 then
		defense = defense - 0.4
	end

	if player:getHandcardNum() == 0 and hujiaJink == 0 and not player:hasSkill("kongcheng") then
		if player:getHp() <= 1 then defense = defense - 2.5 end
		if player:getHp() == 2 then defense = defense - 1.5 end
		if not hasEightDiagram then defense = defense - 2 end
		if attacker:hasWeapon("guding_blade") and not player:hasArmorEffect("silver_lion") and not attacker:hasWeapon("qinggang_sword") then
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

	if player:hasArmorEffect("vine") and not attacker:hasWeapon("qinggang_sword") and has_fire_slash > 0 then
		defense = defense - 0.6 / has_fire_slash
	end

	if player:isLord() then
		defense = defense - 0.4
		if sgs.isLordInDanger() then defense = defense - 0.7 end
	end

	if (sgs.ai_chaofeng[player:getGeneralName()] or 0) >= 3 then
		defense = defense - math.max(6, (sgs.ai_chaofeng[player:getGeneralName()] or 0)) * 0.035
 	end

	if not player:faceUp() then defense = defense - 0.35 end

	if player:containsTrick("indulgence") and not player:containsTrick("YanxiaoCard") then defense = defense - 0.15 end
	if player:containsTrick("supply_shortage") and not player:containsTrick("YanxiaoCard") then defense = defense - 0.15 end

	if (attacker:hasSkill("roulin") and player:isFemale()) or (attacker:isFemale() and player:hasSkill("roulin")) then
		defense = defense - 1.4
	end

	if not hasEightDiagram then
		if player:hasSkill("jijiu") then defense = defense - 3 end
		if player:hasSkill("dimeng") then defense = defense - 2.5 end
		if player:hasSkill("guzheng") and knownJink == 0 then defense = defense - 2.5 end
		if player:hasSkill("qiaobian") then defense = defense - 2.4 end
		if player:hasSkill("jieyin") then defense = defense - 2.3 end
		if player:hasSkill("lijian") then defense = defense - 2.2 end
		if player:hasSkill("nosmiji") and player:isWounded() then defense = defense - 1.5 end
	end
	return defense
end

sgs.ai_compare_funcs["defenseSlash"] = function(a, b)
	return sgs.getDefenseSlash(a) < sgs.getDefenseSlash(b)
end

function SmartAI:slashProhibit(card, enemy)
	card = card or sgs.Sanguosha:cloneCard("slash", sgs.Card_NoSuit, 0)
	for _, askill in sgs.qlist(enemy:getVisibleSkillList()) do
		local filter = sgs.ai_slash_prohibit[askill:objectName()]
		if filter and type(filter) == "function" and filter(self, self.player, enemy, card) then return true end
	end

	if self:isFriend(enemy) then
		if card:isKindOf("FireSlash") or self.player:hasSkill("lihuo") or self.player:hasWeapon("fan") then
			if enemy:hasArmorEffect("vine") and not (enemy:isChained() and self:isGoodChainTarget(enemy)) then return true end
		end
		if enemy:isChained() and card:isKindOf("NatureSlash") and (not self:isGoodChainTarget(enemy) and not self.player:hasSkill("jueqing"))
			and self:slashIsEffective(card, enemy) then return true end
		if getCardsNum("Jink", enemy) == 0 and enemy:getHp() < 2 and self:slashIsEffective(card, enemy) then return true end
		if enemy:isLord() and self:isWeak(enemy) and self:slashIsEffective(card, enemy) then return true end
		if self.player:hasWeapon("guding_blade") and enemy:isKongcheng() then return true end
	else
		if enemy:isChained() and not self:isGoodChainTarget(enemy) and not self.player:hasSkill("jueqing") and self:slashIsEffective(card, enemy)
			and card:isKindOf("NatureSlash") then
			return true
		end
	end

	return self.room:isProhibited(self.player, enemy, card) or not self:slashIsEffective(card, enemy)
end

function SmartAI:canLiuli(other, another)
	if not other:hasSkill("liuli") then return false end
	local n = other:getHandcardNum()
	if n > 0 and (other:distanceTo(another) <= other:getAttackRange()) then return true
	elseif other:getWeapon() and other:getOffensiveHorse() and (other:distanceTo(another) <= other:getAttackRange()) then return true
	elseif other:getWeapon() or other:getOffensiveHorse() then return other:distanceTo(another) <= 1
	else return false end
end

function SmartAI:slashIsEffective(slash, to, from, ignore_armor)
	if not slash or not to then self.room:writeToConsole(debug.traceback()) return false end
	from = from or self.player
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
	if not self:damageIsEffective(to, nature, from) then return false end

	if (to:hasArmorEffect("vine") or to:getMark("@gale") > 0) and self:getCardId("FireSlash") and slash:isKindOf("ThunderSlash") and self:objectiveLevel(to) >= 3 then
		return false
	end

	local skillname = slash:getSkillName()
	local changed = slash:isVirtualCard() and slash:subcardsLength() > 0
					and not (skillname == "hongyan" or skillname == "jinjiu" or skillname == "wushen" or skillname == "guhuo")
	local armor = to:getArmor()
	if armor and to:hasArmorEffect(armor:objectName()) and not from:hasWeapon("qinggang_sword") and not ignore_armor then
		if armor:objectName() == "renwang_shield" then
			return not slash:isBlack()
		elseif armor:objectName() == "vine" then
			return nature ~= sgs.DamageStruct_Normal or (not changed and (from:hasWeapon("fan") or (from:hasSkill("lihuo") and not self:isWeak(from))))
		end
	end

	return true
end

function SmartAI:slashIsAvailable(player)
	player = player or self.player
	local slash = self:getCard("Slash", player)
	if not slash or not slash:isKindOf("Slash") then slash = sgs.Sanguosha:cloneCard("slash", sgs.Card_NoSuit, 0) end
	assert(slash)
	return slash:isAvailable(player)
end

function SmartAI:useCardSlash(card, use)
	if not self:slashIsAvailable() then return end
	if card:isVirtualCard() and card:subcardsLength() > 0
		and self.player:getWeapon() and self.player:getWeapon():isKindOf("Crossbow")
		and card:getSubcards():contains(self.player:getWeapon():getEffectiveId())
		and not self.player:canSlashWithoutCrossbow() then
		return
	end
	local basicnum = 0
	local cards = self.player:getCards("he")
	cards = sgs.QList2Table(cards)
	for _, acard in ipairs(cards) do
		if acard:getTypeId() == sgs.Card_TypeBasic and not acard:isKindOf("Peach") then basicnum = basicnum + 1 end
	end
	local no_distance = sgs.Sanguosha:correctCardTarget(sgs.TargetModSkill_DistanceLimit, self.player, card) > 50 or self.player:hasFlag("slashNoDistanceLimit")
	self.slash_targets = 1 + sgs.Sanguosha:correctCardTarget(sgs.TargetModSkill_ExtraTarget, self.player, card)
	if self.player:hasSkill("duanbing") then self.slash_targets = self.slash_targets + 1 end

	self.predictedRange = self.player:getAttackRange()

	local rangefix = 0
	if card:isVirtualCard() then
		if self.player:getWeapon() and card:getSubcards():contains(self.player:getWeapon():getEffectiveId()) then
			if self.player:getWeapon():getClassName() ~= "Weapon" then
				rangefix = sgs.weapon_range[self.player:getWeapon():getClassName()] - 1
			end
		end
		if self.player:getOffensiveHorse() and card:getSubcards():contains(self.player:getOffensiveHorse():getEffectiveId()) then
			rangefix = rangefix + 1
		end
	end

	if self.player:hasSkill("qingnang") and self:isWeak() and self:getOverflow() == 0 then return end
	local huatuo = self.room:findPlayerBySkillName("jijiu")
	for _, friend in ipairs(self.friends_noself) do
		local slash_prohibit = false
		slash_prohibit = self:slashProhibit(card, friend)
		if (self.player:hasSkill("pojun") and friend:getHp() > 4 and getCardsNum("Jink", friend) == 0
			and friend:getHandcardNum() < 3)
		or self:getDamagedEffects(friend, self.player)
		or (friend:hasSkill("leiji") and not self.player:hasFlag("luoyi") and self:hasSuit("spade", true, friend)
			and (getKnownCard(friend, "Jink", true) >= 1 or (not self:isWeak(friend) and self:hasEightDiagramEffect(friend)))
		and (self:hasExplicitRebel() or not friend:isLord()))
		or (friend:isLord() and self.player:hasSkill("guagu") and friend:getLostHp() >= 1 and getCardsNum("Jink", friend) == 0)
		or (friend:hasSkill("jieming") and self.player:hasSkill("rende") and (huatuo and self:isFriend(huatuo)))
		then
			if not slash_prohibit then
				if ((self.player:canSlash(friend, card, not no_distance, rangefix))
					or (use.isDummy and (self.player:distanceTo(friend, rangefix) <= self.predictedRange)))
					and self:slashIsEffective(card, friend) then
					use.card = card
					if use.to then
						if use.to:length() == self.slash_targets - 1 and self.player:hasSkill("duanbing") then
							local has_extra = false
							for _, tg in sgs.qlist(use.to) do
								if self.player:distanceTo(tg, rangefix) == 1 then
									has_extra = true
									break
								end
							end
							if has_extra or self.player:distanceTo(friend, rangefix) == 1 then
								use.to:append(friend)
							end
						else
							use.to:append(friend)
						end
						self:speak("hostile", self.player:isFemale())
						if self.slash_targets <= use.to:length() then return end
					end
				end
			end
		end
	end

	local targets = {}
	self:sort(self.enemies, "defenseSlash")
	for _, enemy in ipairs(self.enemies) do
		if not self:slashProhibit(card, enemy) and sgs.isGoodTarget(enemy, self.enemies, self) then table.insert(targets, enemy) end
	end

	for _, target in ipairs(targets) do
		local canliuli = false
		for _, friend in ipairs(self.friends_noself) do
			if self:canLiuli(target, friend) and self:slashIsEffective(card, friend) and #targets > 1 and friend:getHp() < 3 then canliuli = true end
		end
		if (self.player:canSlash(target, card, not no_distance, rangefix)
			or (use.isDummy and self.predictedRange and (self.player:distanceTo(target) <= self.predictedRange)))
			and self:objectiveLevel(target) > 3
			and self:slashIsEffective(card, target)
			and not (target:hasSkill("xiangle") and basicnum < 2) and not canliuli
			and not (not self:isWeak(target) and #self.enemies > 1 and #self.friends > 1 and self.player:hasSkill("keji")
			and self:getOverflow() > 0 and not self:hasCrossbowEffect()) then
			-- fill the card use struct
			local usecard = card
			if not use.to or use.to:isEmpty() then
				if self.player:hasWeapon("spear") and card:getSkillName() == "spear" and self:getCardsNum("Slash") == 0 then
				elseif self.player:hasWeapon("crossbow") and self:getCardsNum("Slash") > 1 then
				else
					local equips = self:getCards("EquipCard", self.player, "h")
					for _, equip in ipairs(equips) do
						local callback = sgs.ai_slash_weaponfilter[equip:objectName()]
						if callback and type(callback) == "function" and callback(target, self)
							and self.player:distanceTo(target) <= (sgs.weapon_range[equip:getClassName()] or 0) then
							self:useEquipCard(equip, use)
							if use.card then return end
						end
					end
				end
				if target:isChained() and self:isGoodChainTarget(target) and not use.card then
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
				if godsalvation and godsalvation:getId() ~= card:getId() and self:willUseGodSalvation(godsalvation) then
					use.card = godsalvation
					return
				end
				local anal = self:searchForAnaleptic(use, target, card)
				if anal and self:shouldUseAnaleptic(target, card) then
					if anal:getEffectiveId() ~= card:getEffectiveId() then use.card = anal return end
				end
			end
			use.card = use.card or usecard
			if use.to and not use.to:contains(target) then
				if use.to:length() == self.slash_targets - 1 and self.player:hasSkill("duanbing") then
					local has_extra = false
					for _, tg in sgs.qlist(use.to) do
						if self.player:distanceTo(tg, rangefix) == 1 then
							has_extra = true
							break
						end
					end
					if has_extra or self.player:distanceTo(target, rangefix) == 1 then
						use.to:append(target)
					end
				else
					use.to:append(target)
				end
				if self.slash_targets <= use.to:length() then return end
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
		if #parsedPrompt >= 3 then
			for _, p in sgs.qlist(self.room:getAlivePlayers()) do
				if p:objectName() == parsedPrompt[3] then
					target2 = p
					break
				end
			end
		end
		if not target then return "." end
		local ret = callback(self, nil, nil, target, target2)
		if ret == nil or ret == "." then return "." end
		slash = sgs.Card_Parse(ret)
		local no_distance = sgs.Sanguosha:correctCardTarget(sgs.TargetModSkill_DistanceLimit, self.player, slash) > 50 or self.player:hasFlag("slashNoDistanceLimit")
		if self.player:canSlash(target, slash, not no_distance) then return ret .. "->" .. target:objectName() end
		return "."
	end
	local slashes = self:getCards("Slash")
	self:sort(self.enemies, "defenseSlash")
	for _, slash in ipairs(slashes) do
		local no_distance = sgs.Sanguosha:correctCardTarget(sgs.TargetModSkill_DistanceLimit, self.player, slash) > 50 or self.player:hasFlag("slashNoDistanceLimit")
		for _, enemy in ipairs(self.enemies) do
			if self.player:canSlash(enemy, slash, not no_distance) and not self:slashProhibit(slash, enemy)
				and self:slashIsEffective(slash, enemy) and sgs.isGoodTarget(enemy, self.enemies, self)
				and not (self.player:hasFlag("slashTargetFix") and not enemy:hasFlag("SlashAssignee")) then
				return ("%s->%s"):format(slash:toString(), enemy:objectName())
			end
		end
	end
	return "."
end

sgs.ai_skill_playerchosen.slash_extra_targets = function(self, targets)
	local slash = sgs.Sanguosha:cloneCard("slash", sgs.Card_NoSuit, 0)
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
	local slash = sgs.Sanguosha:cloneCard("slash", sgs.Card_NoSuit, 0)
	local targetlist = sgs.QList2Table(targets)
	local arrBestHp, canAvoidSlash = {}, {}
	self:sort(targetlist, "defenseSlash")
	for _, target in ipairs(targetlist) do
		if self:isEnemy(target) and not self:slashProhibit(slash, target) and sgs.isGoodTarget(target, targetlist, self) then
			if self:slashIsEffective(slash, target) then
				if target:getHp() > getBestHp(target) then
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
				if self:isFriend(target) and (target:getHp() > getBestHp(target) or self:getDamagedEffects(target, self.player)) then
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
		if target:objectName() ~= self.player:objectName() and not self:isFriend(target) then
			return target
		end
	end
	return targetlist[1]
end

sgs.ai_card_intention.Slash = function(self, card, from, tos)
	for _, to in ipairs(tos) do
		local value = 80
		if sgs.ai_collateral then sgs.ai_collateral = false value = 0 end

		if sgs.ai_leiji_effect then
			if from and from:hasSkill("liegong") then return end
			sgs.ai_leiji_effect = false
			if sgs.ai_pojun_effect then
				value = value / 1.5
			else
				--value = -value / 1.5
				value = 0
			end
		end
		speakTrigger(card, from, to)
		if to:hasSkill("yiji") then
			-- value = value*(2-to:getHp()) / 1.1
			value = math.max(value*(2-to:getHp()) / 1.1, 0)
		end
		if from:hasSkill("pojun") and to:getHp() > 3 then value = 0 end
		sgs.updateIntention(from, to, value)
	end
end

sgs.ai_skill_cardask["slash-jink"] = function(self, data, pattern, target)
	local effect = data:toSlashEffect()
	local cards = sgs.QList2Table(self.player:getHandcards())
	if (not target or self:isFriend(target)) and effect.slash:hasFlag("nosjiefan-slash") then return "." end
	if sgs.ai_skill_cardask.nullfilter(self, data, pattern, target) then return "." end
	--if not target then self.room:writeToConsole(debug.traceback()) end
	if not target then return end
	if self:isFriend(target) then
		if not target:hasSkill("jueqing") then
			if target:hasSkill("rende") and self.player:hasSkill("jieming") then return "." end
			if target:hasSkill("pojun") and not self.player:faceUp() then return "." end
			if (target:hasSkill("jieyin") and (not self.player:isWounded()) and self.player:isMale()) and not self.player:hasSkill("leiji") then return "." end
			if self.player:isChained() and self:isGoodChainTarget(self.player) then return "." end
		end
	else
		if not self:hasHeavySlashDamage(target, effect.slash) then
			if target:hasSkill("mengjin") and not (target:hasSkill("nosqianxi") and target:distanceTo(self.player) == 1) then
				if self:doNotDiscard(self.player, "he", true) then return end
				if self.player:getCards("he"):length() == 1 and not self.player:getArmor() then return end
				if self:hasSkills("jijiu|qingnang") and self.player:getCards("he"):length() > 1 then return "." end
				if self:canUseJieyuanDecrease(target) then return "." end
				if (self:getCardsNum("Peach") > 0 or (self:getCardsNum("Analeptic") > 0 and self:isWeak()))
					and not self.player:hasSkill("tuntian") and not self:willSkipPlayPhase() then
					return "."
				end
			end
		end
		if (self.player:getHandcardNum() == 1 and self:needKongcheng()) or not self:hasLoseHandcardEffective() then return end
		if not (target:hasSkill("nosqianxi") and target:distanceTo(self.player) == 1) then
			if target:hasWeapon("axe") then
				if self:hasSkills(sgs.lose_equip_skill, target) and target:getEquips():length() > 1 and target:getCards("he"):length() > 2 then return "." end
				if target:getHandcardNum() - target:getHp() > 2 then return "." end
			elseif target:hasWeapon("blade") then
				if ((effect.slash:isKindOf("FireSlash")
					and not target:hasSkill("jueqing")
					and (self.player:hasArmorEffect("vine") or self.player:getMark("@gale") > 0))
					or self:hasHeavySlashDamage(target, effect.slash)) then
				elseif self:getCardsNum("Jink") <= getCardsNum("Slash", target) or self:hasSkills("jijiu|qingnang") or self:canUseJieyuanDecrease(target) then
					return "."
				end
			end
		end
	end
	if target:hasSkill("dahe") and self.player:hasFlag("dahe") then
		for _, card in ipairs(self:getCards("Jink")) do
			if card:getSuit() == sgs.Card_Heart then
				return card:getId()
			end
		end
		return "."
	end
end

sgs.dynamic_value.damage_card.Slash = true

sgs.ai_use_value.Slash = 4.4
sgs.ai_keep_value.Slash = 2
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
		if card:isKindOf("Peach") then peaches = peaches + 1 end
	end
	if self.player:isLord() and (self.player:hasSkill("hunzi") and self.player:getMark("hunzi") == 0)
		and self.player:getHp() < 4 and self.player:getHp() > peaches then return end
	for _, enemy in ipairs(self.enemies) do
		if self.player:getHandcardNum() < 3 and
			(self:hasSkills(sgs.drawpeach_skill, enemy) or getCardsNum("Dismantlement", enemy) >= 1
			or (not self.player:hasSkill("qianxun") and enemy:hasSkill("jixi") and enemy:getPile("field"):length() > 0 and (enemy:distanceTo(self.player, 1) == 1 or enemy:hasSkill("qicai")))
			or (((enemy:hasSkill("qixi") and not self.player:hasSkill("weimu")) or enemy:hasSkill("yinling")) and getKnownCard(enemy, "black", nil, "he") >= 1)
			or (not self.player:hasSkill("qianxun") and getCardsNum("Snatch", enemy) >= 1 and (enemy:distanceTo(self.player) == 1 or enemy:hasSkill("qicai")))) then
			mustusepeach = true
		end
	end
	if self.player:hasSkill("rende") and #self.friends_noself > 0 then
		return
	end

	if mustusepeach or (self.player:hasSkill("buqu") and self.player:getHp() < 1) or peaches > self.player:getHp() then
		use.card = card
		return
	end

	if self.player:hasSkill("jiuchi") and self:getCardsNum("Analeptic") > 0 and self:getOverflow() <= 0 and #self.friends_noself > 0 then
		return
	end

	if self.player:getHp() >= getBestHp(self.player) then return end

	local lord = self.room:getLord()
	if lord and self:isFriend(lord) and lord:getHp() <= 2 and not lord:hasSkill("buqu") and peaches == 1 then
		if self.player:isLord() then use.card = card end
		return
	end

	self:sort(self.friends, "hp")
	if self.friends[1]:objectName() == self.player:objectName() or self.player:getHp() < 2 then
		use.card = card
		return
	end

	if #self.friends > 1 and self.friends[2]:getHp() < 3 and not self.friends[2]:hasSkill("buqu") and self:getOverflow() < 1 then
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

sgs.ai_card_intention.Peach = -120

sgs.ai_use_value.Peach = 6
sgs.ai_keep_value.Peach = 5
sgs.ai_use_priority.Peach = 2.8

sgs.ai_use_value.Jink = 8.9
sgs.ai_keep_value.Jink = 4

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

function sgs.ai_slash_weaponfilter.double_sword(to, self)
	return self.player:getGender() ~= to:getGender()
end

function sgs.ai_weapon_value.double_sword(self, enemy)
	if enemy and enemy:isMale() ~= self.player:isMale() then return 3 end
end

function SmartAI:getExpectedJinkNum(use)
	local cantUseJink, needDoubleJink = false, false
	if (use.from:getMark("no_jink" .. use.card:toString()) > 0) then
		local num = use.from:getMark("no_jink" .. use.card:toString())
		for _, p in sgs.qlist(use.to) do
			if p:objectName() == self.player:objectName() and math.fmod(num, 10) > 0 then
				cantUseJink = true
				break
			end
			num = math.floor(num / 10)
		end
	end
	if (use.from:getMark("double_jink" .. use.card:toString()) > 0) then
		local num = use.from:getMark("double_jink" .. use.card:toString())
		for _, p in sgs.qlist(use.to) do
			if p:objectName() == self.player:objectName() and num % 10 > 0 then
				needDoubleJink = true
				break
			end
			num = math.floor(num / 10)
		end
	end
	if cantUseJink then return 0
	elseif needDoubleJink then return 2
	else return 1 end
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
			or (card:isKindOf("EquipCard") and not self:hasSkills(sgs.lose_equip_skill))
			or (not self.player:hasSkill("jizhi") and (card:isKindOf("Collateral") or card:isKindOf("GodSalvation")
														or card:isKindOf("FireAttack") or card:isKindOf("IronChain") or card:isKindOf("AmazingGrace"))) then
			return "$" .. card:getEffectiveId()
		end
	end
	return "."
end

function sgs.ai_weapon_value.qinggang_sword(self, enemy)
	if enemy and enemy:getArmor() then return 3 end
end

sgs.ai_skill_invoke.ice_sword = function(self, data)
	local damage = data:toDamage()
	local target = damage.to
	if self:isFriend(target) then
		if self:isWeak(target) or damage.damage > 1 then return true
		elseif target:getLostHp() < 1 then return false end
		return true
	else
		if self:isWeak(target) or damage.damage > 1 or self:hasHeavySlashDamage(self.player, damage.card, target) then return false end
		if target:getArmor() and self:evaluateArmor(target:getArmor(), target) > 3 then return true end
		local num = target:getHandcardNum()
		if self.player:hasSkill("tieji") or (self.player:hasSkill("liegong")
			and (num >= self.player:getHp() or num <= self.player:getAttackRange())) then return false end
		if target:hasSkill("tuntian") then return false end
		if self:hasSkills(sgs.need_kongcheng, target) then return false end
		if target:getCards("he"):length() < 4 and target:getCards("he"):length() > 1 then return true end
		return false
	end
end

function sgs.ai_slash_weaponfilter.guding_blade(to)
	return to:isKongcheng()
end

function sgs.ai_weapon_value.guding_blade(self, enemy)
	if not enemy then return end
	local value = 2
	if enemy:getHandcardNum() < 1 then value = 4 end
	return value
end

sgs.ai_skill_cardask["@axe"] = function(self, data, pattern, target)
	if target and self:isFriend(target) then return "." end
	local effect = data:toSlashEffect()
	local allcards = self.player:getCards("he")
	allcards = sgs.QList2Table(allcards)
	if self:hasHeavySlashDamage(self.player, effect.slash, target) or #allcards - 3 >= self.player:getHp()
		or (self.player:hasSkill("kuanggu") and self.player:isWounded() and self.player:distanceTo(effect.to) == 1)
		or (effect.to:getHp() == 1 and not effect.to:hasSkill("buqu"))
		or ((self:needKongcheng() or not self:hasLoseHandcardEffective()) and self.player:getHandcardNum() > 0)
		or (self:hasSkills(sgs.lose_equip_skill, self.player) and self.player:getEquips():length() > 1 and self.player:getHandcardNum() < 2)
		or self:needToThrowArmor() then

		local hcards = self.player:getCards("h")
		hcards = sgs.QList2Table(hcards)
		self:sortByKeepValue(hcards)
		local cards = {}
		local hand, armor, def, off = 0, 0, 0, 0
		if self:needToThrowArmor() then
			table.insert(cards, self.player:getArmor():getEffectiveId())
			armor = 1
		end
		if (self:hasSkills(sgs.need_kongcheng) or not self:hasLoseHandcardEffective()) and self.player:getHandcardNum() > 0 then
			hand = 1
			for _, card in ipairs(hcards) do
				table.insert(cards, card:getEffectiveId())
				if #cards == 2 then break end
			end
		end
		if #cards < 2 and self:hasSkills(sgs.lose_equip_skill, self.player) then
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
			return "$" .. table.concat(cards, "+")
		end
	end
end

function sgs.ai_slash_weaponfilter.axe(to, self)
	return self:getOverflow() > 0
end

function sgs.ai_weapon_value.axe(self, enemy)
	if self:hasSkills("jiushi|jiuchi|luoyi|pojun", self.player) then return 6 end
	if enemy and enemy:getHp() < 3 then return 5 - enemy:getHp() end
end

sgs.ai_skill_cardask["blade-slash"] = function(self, data, pattern, target)
	if target and self:isFriend(target) and not (target:hasSkill("leiji") and getCardsNum("Jink", target) > 0) then
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
	if not enemy then return self:getCardsNum("Slash") end
end

function cardsView_spear(player, skill_name)
	local cards = player:getCards("he")
	cards = sgs.QList2Table(cards)
	if skill_name ~= "fuhun" or player:hasSkill("wusheng") then
		for _, acard in ipairs(cards) do
			if isCard("Slash", acard, player) then return end
		end
	end
	local cards = player:getCards("h")
	cards = sgs.QList2Table(cards)
	local newcards = {}
	for _, card in ipairs(cards) do
		if not isCard("Slash", card, player) and not isCard("Peach", card, player) and not (isCard("ExNihilo", card, player) and player:getPhase() == sgs.Player_Play) then table.insert(newcards, card) end
	end
	if #newcards < 2 then return end

	local card_id1 = newcards[1]:getEffectiveId()
	local card_id2 = newcards[2]:getEffectiveId()

	local card_str = ("slash:%s[%s:%s]=%d+%d"):format(skill_name, "to_be_decided", 0, card_id1, card_id2)
	return card_str
end

function sgs.ai_cardsview.spear(class_name, player)
	if class_name == "Slash" then
		return cardsView_spear(player, "spear")
	end
end

function turnUse_spear(self, inclusive, skill_name)
	local cards = self.player:getCards("he")
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
	if #newcards <= self.player:getHp() - 1 and not self:hasHeavySlashDamage(self.player) and not self:hasSkills("kongcheng|lianying|paoxiao") then return end
	if #newcards < 2 then return end

	local card_id1 = newcards[1]:getEffectiveId()
	local card_id2 = newcards[2]:getEffectiveId()

	if newcards[1]:isBlack() and newcards[2]:isBlack() then
		local black_slash = sgs.Sanguosha:cloneCard("slash", sgs.Card_NoSuitBlack, 0)
		local nosuit_slash = sgs.Sanguosha:cloneCard("slash", sgs.Card_NoSuit, 0)

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

function sgs.ai_slash_weaponfilter.fan(to)
	return to:hasArmorEffect("vine")
end

sgs.ai_skill_invoke.kylin_bow = function(self, data)
	local damage = data:toDamage()

	if damage.from:hasSkill("kuangfu") and damage.to:getCards("e"):length() == 1 then return false end
	if self:hasSkills(sgs.lose_equip_skill, damage.to) then
		return self:isFriend(damage.to)
	end

	return self:isEnemy(damage.to)
end

function sgs.ai_slash_weaponfilter.kylin_bow(to)
	if to:getDefensiveHorse() then return true else return false end
end

function sgs.ai_weapon_value.kylin_bow(self, target)
	if not target then
		for _, enemy in ipairs(self.enemies) do
			if enemy:getOffensiveHorse() or enemy:getDefensiveHorse() then return 1 end
		end
	end
end

sgs.ai_skill_invoke.eight_diagram = function(self, data)
	local dying = 0
	local handang = self.room:findPlayerBySkillName("nosjiefan")
	for _, aplayer in sgs.qlist(self.room:getAlivePlayers()) do
		if aplayer:getHp() < 1 and not aplayer:hasSkill("buqu") then dying = 1 break end
	end
	if handang and self:isFriend(handang) and dying > 0 then return false end
	if self.player:hasFlag("dahe") then return false end
	if sgs.hujiasource and not self:isFriend(sgs.hujiasource) then return false end
	if self.player:hasSkill("tiandu") then return true end
	local zhangjiao = self.room:findPlayerBySkillName("guidao")
	if zhangjiao and self:isEnemy(zhangjiao) and self:getFinalRetrial(zhangjiao) == 2 and getKnownCard(zhangjiao, "black", false, "he") > 0 then
		return false
	end
	if self:getDamagedEffects(self.player) or self.player:getHp() > getBestHp(self.player) then return false end
	return true
end

function sgs.ai_armor_value.eight_diagram(player, self)
	local haszj = self:hasSkills("guidao", self:getEnemies(player))
	if haszj then
		return 2
	end
	if player:hasSkills("tiandu|leiji|noszhenlie") then
		return 6
	end

	if self.role == "loyalist" and self.player:getKingdom() == "wei" and not self:hasSkills("bazhen|yizhong") and self.room:getLord() and self.room:getLord():hasLordSkill("hujia") then
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
sgs.ai_use_priority.Axe = 2.64
sgs.ai_use_priority.Crossbow = 2.63
sgs.ai_use_priority.SilverLion = 0.9
sgs.ai_use_priority.EightDiagram = 0.8
sgs.ai_use_priority.RenwangShield = 0.7
sgs.ai_use_priority.DefensiveHorse = 2.75

sgs.dynamic_value.damage_card.ArcheryAttack = true
sgs.dynamic_value.damage_card.SavageAssault = true

sgs.ai_use_value.ArcheryAttack = 3.8
sgs.ai_use_priority.ArcheryAttack = 3.5
sgs.ai_use_value.SavageAssault = 3.9
sgs.ai_use_priority.SavageAssault = 3.5

sgs.ai_skill_cardask.aoe = function(self, data, pattern, target, name)
	if self.room:getMode():find("_mini_34") and self.player:getLostHp() == 1 and name == "archery_attack" then return "." end
	if sgs.ai_skill_cardask.nullfilter(self, data, pattern, target) then return "." end
	if target:hasSkill("drwushuang") and self.player:getCardCount(true) == 1 and self:hasLoseHandcardEffective() then return "." end

	local aoe = sgs.Sanguosha:cloneCard(name, sgs.Card_NoSuit, 0)
	local menghuo = self.room:findPlayerBySkillName("huoshou")
	local attacker = target
	if menghuo and aoe:isKindOf("SavageAssault") then attacker = menghuo end

	if not self:damageIsEffective(nil, nil, attacker) then return "." end
	if self:getDamagedEffects(self.player, attacker) or self.player:getHp() > getBestHp(self.player) then return "." end

	if self.player:hasSkill("wuyan") and not attacker:hasSkill("jueqing") then return "." end
	if attacker:hasSkill("wuyan") and not attacker:hasSkill("jueqing") then return "." end
	if self.player:getMark("@fenyong") > 0 and not attacker:hasSkill("jueqing") then return "." end

	if not attacker:hasSkill("jueqing") and self.player:hasSkill("jianxiong") and self:getAoeValue(aoe) > -10
		and (self.player:getHp() > 1 or self:getAllPeachNum() > 0) and not self.player:containsTrick("indulgence") then return "." end
end

sgs.ai_skill_cardask["savage-assault-slash"] = function(self, data, pattern, target)
	return sgs.ai_skill_cardask.aoe(self, data, pattern, target, "savage_assault")
end

sgs.ai_skill_cardask["archery-attack-jink"] = function(self, data, pattern, target)
	return sgs.ai_skill_cardask.aoe(self, data, pattern, target, "archery_attack")
end

sgs.ai_keep_value.Nullification = 3
sgs.ai_use_value.Nullification = 8

function SmartAI:useCardAmazingGrace(card, use)
	if self.player:hasSkill("noswuyan") then use.card = card end
	if (self.role == "lord" or self.role == "loyalist") and sgs.turncount <= 2 and self.player:getSeat() <= 3 and self.player:aliveCount() > 5 then return end
	local value = 1
	local suf, coeff = 0.8, 0.8
	if self:hasSkills(sgs.need_kongcheng) and self.player:getHandcardNum() == 1 or self.player:hasSkill("jizhi") then
		suf = 0.6
		coeff = 0.6
	end
	for _, player in sgs.qlist(self.room:getOtherPlayers(self.player)) do
		local index = 0
		if self:isFriend(player) then index = 1 elseif self:isEnemy(player) then index = -1 end
		value = value + index * suf
		if value < 0 then return end
		suf = suf * coeff
	end
	use.card = card
end

sgs.ai_use_value.AmazingGrace = 3
sgs.ai_keep_value.AmazingGrace = -1
sgs.ai_use_priority.AmazingGrace = 1

function SmartAI:willUseGodSalvation(card)
	if not card then self.room:writeToConsole(debug.traceback()) return false end
	local good, bad = 0, 0
	local wounded_friend = false
	if self.player:hasSkill("noswuyan") and self.player:isWounded() then return true end
	if self.player:hasSkill("jizhi") then good = good + 6 end
	if (self:hasSkills("kongcheng") and self.player:getHandcardNum() == 1) or not self:hasLoseHandcardEffective() then good = good + 5 end
	local liuxie = self.room:findPlayerBySkillName("huangen")
	if liuxie then
		if self:isFriend(player, liuxie) then
			good = good + 5 * liuxie:getHp()
		else
			bad = bad + 5 * liuxie:getHp()
		end
	end

	for _, friend in ipairs(self.friends) do
		good = good + 10 * getCardsNum("Nullification", friend)
		if self:hasTrickEffective(card, friend, self.player) then
			if friend:isWounded() then
				wounded_friend = true
				good = good + 10
				if friend:isLord() then good = good + 10 / math.max(friend:getHp(), 1) end
				if self:hasSkills(sgs.masochism_skill, friend) then
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
	if not wounded_friend then return false end

	for _, enemy in ipairs(self.enemies) do
		bad = bad + 10 * getCardsNum("Nullification", enemy)
		if self:hasTrickEffective(card, enemy, self.player) then
			if enemy:isWounded() then
				bad = bad + 10
				if enemy:isLord() then
					bad = bad + 10 / math.max(enemy:getHp(), 1)
				end
				if self:hasSkills(sgs.masochism_skill, enemy) then
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
	return good > bad
end

function SmartAI:useCardGodSalvation(card, use)
	if self:willUseGodSalvation(card) then
		use.card = card
	end
end

sgs.ai_use_priority.GodSalvation = 3.9
sgs.dynamic_value.benefit.GodSalvation = true

function SmartAI:useCardDuel(duel, use)
	if self.player:hasSkill("wuyan") and not self.player:hasSkill("jueqing") then return end
	if self.player:hasSkill("noswuyan") then return end

	local enemies = self:exclude(self.enemies, duel)
	local friends = self:exclude(self.friends_noself, duel)
	local n1 = self:getCardsNum("Slash")
	local huatuo = self.room:findPlayerBySkillName("jijiu")

	local canUseDuelTo = function(target)
		return self:hasTrickEffective(duel, target) and self:damageIsEffective(target, sgs.DamageStruct_Normal) and not self.room:isProhibited(self.player, target, duel)
	end

	for _, friend in ipairs(friends) do
		if friend:hasSkill("jieming") and canUseDuelTo(friend) and self.player:hasSkill("rende") and (huatuo and self:isFriend(huatuo))then
			use.card = duel
			if use.to then
				use.to:append(friend)
			end
			return
		end
	end

	for _, enemy in ipairs(enemies) do
		if self.player:hasFlag("duelTo" .. enemy:objectName()) and canUseDuelTo(enemy) then

			local godsalvation = self:getCard("GodSalvation")
			if godsalvation and godsalvation:getId()~= duel:getId() and self:willUseGodSalvation(godsalvation) and not enemy:isWounded() then
				use.card = godsalvation return
			end

			use.card = duel
			if use.to then
				use.to:append(enemy)
				self:speak("duel", self.player:isFemale())
			end
			return
		end
	end

	local cmp = function(a, b)
		local v1 = getCardsNum("Slash", a)
		local v2 = getCardsNum("Slash", b)

		if self:getDamagedEffects(a, self.player) then v1 = v1 + 20 end
		if self:getDamagedEffects(b, self.player) then v2 = v2 + 20 end

		if not self:isWeak(a) and a:hasSkill("jianxiong") and not self.player:hasSkill("jueqing") then v1 = v1 + 10 end
		if not self:isWeak(b) and b:hasSkill("jianxiong") and not self.player:hasSkill("jueqing") then v2 = v2 + 10 end

		if a:getHp() > getBestHp(a) then v1 = v1 + 5 end
		if b:getHp() > getBestHp(b) then v2 = v2 + 5 end

		if self:hasSkills(sgs.masochism_skill, a) then v1 = v1 + 5 end
		if self:hasSkills(sgs.masochism_skill, b) then v2 = v2 + 5 end

		if not self:isWeak(a) and a:hasSkill("jiang") then v1 = v1 + 5 end
		if not self:isWeak(b) and b:hasSkill("jiang") then v2 = v2 + 5 end

		if a:hasLordSkill("jijiang") then v1 = v1 + 10 end
		if b:hasLordSkill("jijiang") then v2 = v2 + 10 end

		if v1 == v2 then return sgs.getDefenseSlash(a) < sgs.getDefenseSlash(b) end

		return v1 < v2
	end

	table.sort(enemies, cmp)

	for _, enemy in ipairs(enemies) do
		local useduel
		local n2 = getCardsNum("Slash", enemy)
		if sgs.card_lack[enemy:objectName()]["Slash"] == 1 then n2 = 0 end
		useduel = n1 >= n2 or self.player:getHp() > getBestHp(self.player)
					or self:getDamagedEffects(self.player, enemy) or (n2 < 1 and sgs.isGoodHp(self.player))
					or ((self:hasSkills("jianxiong") or self.player:getMark("shuangxiong") > 0) and sgs.isGoodHp(self.player))

		if self:objectiveLevel(enemy) > 3 and canUseDuelTo(enemy) and not self:cantbeHurt(enemy) and useduel and sgs.isGoodTarget(enemy, enemies, self) then
			local godsalvation = self:getCard("GodSalvation")
			if godsalvation and godsalvation:getId()~= duel:getId() and self:willUseGodSalvation(godsalvation) and not enemy:isWounded() then
				use.card = godsalvation
				return
			end

			use.card = duel
			if use.to then
				use.to:append(enemy)
				self:speak("duel", self.player:isFemale())
			end
			if self.player:getPhase() == sgs.Player_Play then
				self.player:setFlags("duelTo" .. enemy:objectName())
			end
			return
		end
	end
end

sgs.ai_card_intention.Duel = function(self, card, from, tos)
	if sgs.ai_lijian_effect then
		sgs.ai_lijian_effect = false
		return
	end
	sgs.updateIntentions(from, tos, 80)
end

sgs.ai_use_value.Duel = 3.7
sgs.ai_use_priority.Duel = 2.9

sgs.dynamic_value.damage_card.Duel = true

sgs.ai_skill_cardask["duel-slash"] = function(self, data, pattern, target)
	if sgs.ai_skill_cardask.nullfilter(self, data, pattern, target) then return "." end
	if self.player:hasFlag("NeedToWake") then return "." end
	if self.player:hasSkill("wuyan") and not target:hasSkill("jueqing") then return "." end
	if target:hasSkill("wuyan") and not self.player:hasSkill("jueqing") then return "." end
	if self:getDamagedEffects(self.player, target) or self.player:getHp() > getBestHp(self.player) then return "." end
	if self:isFriend(target) and target:hasSkill("rende") and self.player:hasSkill("jieming") then return "." end
	if not self:damageIsEffective(self.player, sgs.DamageStruct_Normal, target) then return "." end
	if (not self:isFriend(target) and self:getCardsNum("Slash") * 2 >= target:getHandcardNum())
		or (target:getHp() > 2 and self.player:getHp() <= 1 and self:getCardsNum("Peach") == 0 and not self.player:hasSkill("buqu")) then
		return self:getCardId("Slash")
	else return "." end
end

function SmartAI:useCardExNihilo(card, use)
	use.card = card
	if not use.isDummy then
		self:speak("lucky")
	end
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
	if weapon and weapon:isKindOf("Axe") and self:hasSkills("luoyi|pojun|jiushi|jiuchi|jie||jieyuan", who) then return weapon:getEffectiveId() end
	if armor and armor:isKindOf("EightDiagram") and who:hasSkill("leiji") then return armor:getEffectiveId() end
	if weapon and (weapon:isKindOf("SPMoonSpear") or weapon:isKindOf("MoonSpear")) and self:hasSkills("guidao|longdan|guicai|jilve|huanshi|qingguo|kanpo", who) then return weapon:getEffectiveId() end
	if weapon and who:hasSkill("liegong") and sgs.weapon_range[weapon:getClassName()] >= who:getHp() - 1 then return weapon:getEffectiveId() end
	if weapon and weapon:isKindOf("Crossbow") and getCardsNum("Slash", who) > 1 then
		for _, friend in ipairs(self.friends) do
			if who:canSlash(friend) then return weapon:getEffectiveId() end
		end
	end
end

function SmartAI:getValuableCard(who)
	local weapon = who:getWeapon()
	local armor = who:getArmor()
	local offhorse = who:getOffensiveHorse()
	local defhorse = who:getDefensiveHorse()
	self:sort(self.friends, "hp")
	local friend
	if #self.friends > 0 then friend = self.friends[1] end
	if friend and self:isWeak(friend) and who:distanceTo(friend) <= who:getAttackRange() and not self:doNotDiscard(who, "e", true) then
		if weapon and who:distanceTo(friend) > 1
			and not ((weapon:isKindOf("MoonSpear") or weapon:isKindOf("SPMoonSpear")) and who:hasSkill("keji") and who:getHandcardNum() > 5) then return weapon:getEffectiveId() end
		if offhorse and who:distanceTo(friend) > 1 then return offhorse:getEffectiveId() end
	end

	if weapon then
		if (weapon:isKindOf("MoonSpear") and who:hasSkill("keji") and who:getHandcardNum() > 5)
			or self:hasSkills("qiangxi|zhulou", who) then
			return weapon:getEffectiveId()
		end
	end

	if defhorse and not self:doNotDiscard(who, "e") then
		return defhorse:getEffectiveId()
	end

	if armor and self:evaluateArmor(armor, who) > 3
		and not self:needToThrowArmor(who)
		and not self:doNotDiscard(who, "e") then
		return armor:getEffectiveId()
	end

	if offhorse then
		if self:hasSkills("nosqianxi|kuanggu|duanbing", who) then
			return offhorse:getEffectiveId()
		end
	end

	local equips = sgs.QList2Table(who:getEquips())
	for _, equip in ipairs(equips) do
		if who:hasSkill("longhun") and not equip:getSuit() == sgs.Card_Diamond then return equip:getEffectiveId() end
		if who:hasSkill("qixi|yinling") and equip:isBlack() then return equip:getEffectiveId() end
		if who:hasSkill("guidao") and equip:isBlack() then return equip:getEffectiveId() end
		if who:hasSkill("guose|yanxiao") and equip:getSuit() == sgs.Card_Diamond then return equip:getEffectiveId() end
		if who:hasSkill("jijiu") and equip:isRed() then return equip:getEffectiveId() end
		if who:hasSkill("wusheng|xueji") and equip:isRed() then return equip:getEffectiveId() end
		if who:hasSkill("duanliang") and equip:isBlack() then return equip:getEffectiveId() end
		if self:hasSkills("shensu|mingce|beige|yuanhu|gongqi|nosgongqi|yanzheng|qingcheng|neoluoyi", who) then return equip:getEffectiveId() end
		if who:hasSkill("baobian") and who:getHp() <= 2 then return equip:getEffectiveId() end
	end

	if weapon then
		if not self:doNotDiscard(who, "e", true) then
			for _, friend in ipairs(self.friends) do
				if who:distanceTo(friend) <= who:getAttackRange() and who:distanceTo(friend) > 1 then
					return weapon:getEffectiveId()
				end
			end
		end
	end

	if offhorse then
		if not self:doNotDiscard(who, "e", true) then
			for _, friend in ipairs(self.friends) do
				if who:distanceTo(friend) == who:getAttackRange() and who:getAttackRange() > 1 then
					return offhorse:getEffectiveId()
				end
			end
		end
	end
end

function SmartAI:useCardSnatchOrDismantlement(card, use)
	local isYinling = card:isKindOf("YinlingCard")
	local isJixi = card:getSkillName() == "jixi"
	local name = isYinling and "yinling" or card:objectName()
	if not isYinling and self.player:hasSkill("noswuyan") then return end
	local players = self.room:getOtherPlayers(self.player)
	local tricks
	players = self:exclude(players, card)
	if not isYinling then
		for _, player in ipairs(players) do
			if not player:getJudgingArea():isEmpty() and self:hasTrickEffective(card, player)
				and ((player:containsTrick("lightning") and self:getFinalRetrial(player) == 2) or #self.enemies == 0) then
				use.card = card
				if use.to then
					tricks = player:getCards("j")
					for _, trick in sgs.qlist(tricks) do
						if trick:isKindOf("Lightning") then
							sgs.ai_skill_cardchosen[name] = trick:getEffectiveId()
						end
					end
					use.to:append(player)
				end
				return
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
		self:sort(enemies, "defense")
		enemies = sgs.reverse(enemies)
	else
		enemies = self:exclude(self.enemies, card)
		self:sort(enemies, "defense")
	end
	self:sort(self.friends_noself, "defense")
	local friends = self:exclude(self.friends_noself, card)
	local hasLion, target
	for _, enemy in ipairs(enemies) do
		if not enemy:isNude() and (self:hasTrickEffective(card, enemy) or isYinling) then
			if self:getDangerousCard(enemy) then
				use.card = card
				if use.to then
					sgs.ai_skill_cardchosen[name] = self:getDangerousCard(enemy)
					use.to:append(enemy)
					self:speak("hostile", self.player:isFemale())
				end
				return
			end
		end
	end

	if not isYinling then
		for _, friend in ipairs(friends) do
			if (friend:containsTrick("indulgence") or friend:containsTrick("supply_shortage")) and not friend:containsTrick("YanxiaoCard")
				and self:hasTrickEffective(card, friend) then
				use.card = card
				if use.to then
					tricks = friend:getJudgingArea()
					for _, trick in sgs.qlist(tricks) do
						if trick:isKindOf("Indulgence") then
							if friend:getHp() <= friend:getHandcardNum() or friend:isLord() or name == "snatch" then
								sgs.ai_skill_cardchosen[name] = trick:getEffectiveId()
								break
							end
						end
						if trick:isKindOf("SupplyShortage") then
							sgs.ai_skill_cardchosen[name] = trick:getEffectiveId()
							break
						end
						if trick:isKindOf("Indulgence") then
							sgs.ai_skill_cardchosen[name] = trick:getEffectiveId()
							break
						end
					end
					use.to:append(friend)
				end
				return
			end
		end
	end

	for _, friend in ipairs(friends) do
		if (self:hasTrickEffective(card, friend) or isYinling) and self:needToThrowArmor(friend) then
			hasLion = true
			target = friend
		end
	end

	for _, enemy in ipairs(enemies) do
		if not enemy:isNude() and (self:hasTrickEffective(card, enemy) or isYinling) then
			if self:getValuableCard(enemy) then
				use.card = card
				if use.to then
					sgs.ai_skill_cardchosen[name] = self:getValuableCard(enemy)
					use.to:append(enemy)
					self:speak("hostile", self.player:isFemale())
				end
				return
			end
		end
	end

	local new_enemies = table.copyFrom(enemies)
	local compare_JudgingArea = function(a, b)
		return a:getJudgingArea():length() > b:getJudgingArea():length()
	end
	table.sort(new_enemies, compare_JudgingArea)
	local yanxiao_card, yanxiao_target, yanxiao_prior
	if not isYinling then
		for _, enemy in ipairs(new_enemies) do
			for _, acard in sgs.qlist(enemy:getJudgingArea()) do
				if acard:isKindOf("YanxiaoCard") and self:hasTrickEffective(card, enemy) then
					yanxiao_card = acard
					yanxiao_target = enemy
					if enemy:containsTrick("indulgence") or enemy:containsTrick("supply_shortage") then yanxiao_prior = true end
					break
				end
			end
			if yanxiao_card and yanxiao_target then break end
		end
		if yanxiao_prior and yanxiao_card and yanxiao_target then
			use.card = card
			if use.to then
				sgs.ai_skill_cardchosen[name] = yanxiao_card:getEffectiveId()
				use.to:append(yanxiao_target)
			end
			return
		end
	end

	for _, enemy in ipairs(enemies) do
		local cards = sgs.QList2Table(enemy:getHandcards())
		local flag = string.format("%s_%s_%s", "visible", self.player:objectName(), enemy:objectName())
		if #cards <= 2 and (self:hasTrickEffective(card, enemy) or isYinling) and not enemy:isKongcheng() and not self:doNotDiscard(enemy, "h", true) then
			for _, cc in ipairs(cards) do
				if (cc:hasFlag("visible") or cc:hasFlag(flag)) and (cc:isKindOf("Peach") or cc:isKindOf("Analeptic")) then
					use.card = card
					if use.to then
						sgs.ai_skill_cardchosen[name] = self:getCardRandomly(enemy, "h")
						use.to:append(enemy)
						self:speak("hostile", self.player:isFemale())
					end
					return
				end
			end
		end
	end

	for _, enemy in ipairs(enemies) do
		if not enemy:isNude() and (self:hasTrickEffective(card, enemy) or isYinling) then
			if self:hasSkills("jijiu|qingnang|jieyin", enemy) then
				local cardchosen
				local equips = { enemy:getDefensiveHorse(), enemy:getArmor(), enemy:getOffensiveHorse(), enemy:getWeapon() }
				for _, equip in ipairs(equips) do
					if equip and equip:isRed() and enemy:hasSkill("jijiu") then
						cardchosen = equip:getEffectiveId()
						break
					end
				end

				if not cardchosen and enemy:getDefensiveHorse() then cardchosen = enemy:getDefensiveHorse():getEffectiveId() end
				if not cardchosen and enemy:getArmor() and not enemy:getArmor():isKindOf("SilverLion") then
					cardchosen = enemy:getArmor():getEffectiveId()
				end
				if not cardchosen and not enemy:isKongcheng() and enemy:getHandcardNum() <= 3 then
					cardchosen = self:getCardRandomly(enemy, "h")
				end

				if cardchosen then
					use.card = card
					if use.to then
						sgs.ai_skill_cardchosen[name] = cardchosen
						use.to:append(enemy)
						self:speak("hostile", self.player:isFemale())
					end
					return
				end
			end
		end
	end

	for i = 1, 2 + (isJixi and 3 or 0), 1 do
		for _, enemy in ipairs(enemies) do
			if not enemy:isNude() and (self:hasTrickEffective(card, enemy) or isYinling)
				and not (self:needKongcheng(enemy) and i <= 2) and not self:doNotDiscard(enemy) then
				if (enemy:getHandcardNum() == i and sgs.getDefenseSlash(enemy) < 6 + (isJixi and 6 or 0) and enemy:getHp() <= 3 + (isJixi and 2 or 0)) then
					local cardchosen
					if self.player:distanceTo(enemy) == self.player:getAttackRange() + 1 and enemy:getDefensiveHorse() and not self:doNotDiscard(enemy, "e") then
						cardchosen = enemy:getDefensiveHorse():getEffectiveId()
					elseif enemy:getArmor() and not self:needToThrowArmor(enemy) and not self:doNotDiscard(enemy, "e") then
						cardchosen = enemy:getArmor():getEffectiveId()
					else
						cardchosen = self:getCardRandomly(enemy, "h")
					end
					use.card = card
					if use.to then
						sgs.ai_skill_cardchosen[name] = cardchosen
						use.to:append(enemy)
						self:speak("hostile", self.player:isFemale())
					end
					return
				end
			end
		end
	end

	for _, enemy in ipairs(enemies) do
		if not enemy:isNude() and self:getValuableCard(enemy) and (self:hasTrickEffective(card, enemy) or isYinling) then
			use.card = card
			if use.to then
				sgs.ai_skill_cardchosen[name] = self:getValuableCard(enemy)
				use.to:append(enemy)
				self:speak("hostile", self.player:isFemale())
			end
			return
		end
	end

	if hasLion then
		use.card = card
		if use.to then
			sgs.ai_skill_cardchosen[name] = target:getArmor():getEffectiveId()
			use.to:append(target)
		end
		return
	end

	if not isYinling and yanxiao_card and yanxiao_target then
		use.card = card
		if use.to then
			sgs.ai_skill_cardchosen[name] = yanxiao_card:getEffectiveId()
			use.to:append(yanxiao_target)
		end
		return
	end

	for _, enemy in ipairs(enemies) do
		if not enemy:isKongcheng() and not self:doNotDiscard(enemy, "h") and (self:hasTrickEffective(card, enemy) or isYinling) and self:hasSkills(sgs.cardneed_skill, enemy) then
			use.card = card
			if use.to then
				sgs.ai_skill_cardchosen[name] = self:getCardRandomly(enemy, "h")
				use.to:append(enemy)
				self:speak("hostile", self.player:isFemale())
			end
			return
		end
	end

	for _, enemy in ipairs(enemies) do
		if enemy:hasEquip() and not self:doNotDiscard(enemy, "e") and (self:hasTrickEffective(card, enemy) or isYinling) then
			local cardchosen
			if enemy:getDefensiveHorse() then
				cardchosen = enemy:getDefensiveHorse():getEffectiveId()
			elseif enemy:getArmor() and not self:needToThrowArmor(enemy) then
				cardchosen = enemy:getArmor():getEffectiveId()
			elseif enemy:getOffensiveHorse() then
				cardchosen = enemy:getOffensiveHorse():getEffectiveId()
			elseif enemy:getWeapon() then
				cardchosen = enemy:getWeapon():getEffectiveId()
			end
			use.card = card
			if use.to then
				sgs.ai_skill_cardchosen[name] = cardchosen
				use.to:append(enemy)
				self:speak("hostile", self.player:isFemale())
			end
			return
		end
	end

	if name == "snatch" or self:getOverflow() > 0 then
		for _, enemy in ipairs(enemies) do
			local equips = enemy:getEquips()
			if not enemy:isNude() and self:hasTrickEffective(card, enemy) and not self:doNotDiscard(enemy, "he") then
				use.card = card
				if use.to then
					if not equips:isEmpty() and not self:doNotDiscard(enemy, "e") then
						sgs.ai_skill_cardchosen[name] = self:getCardRandomly(enemy, "e")
					else
						sgs.ai_skill_cardchosen[name] = self:getCardRandomly(enemy, "h") end
					use.to:append(enemy)
					self:speak("hostile", self.player:isFemale())
				end
				return
			end
		end
	end
end

SmartAI.useCardSnatch = SmartAI.useCardSnatchOrDismantlement

sgs.ai_use_value.Snatch = 9
sgs.ai_use_priority.Snatch = 4.3

sgs.dynamic_value.control_card.Snatch = true
function sgs.ai_card_intention.Snatch()
	sgs.ai_snat_disma_effect = false
end

SmartAI.useCardDismantlement = SmartAI.useCardSnatchOrDismantlement

sgs.ai_use_value.Dismantlement = 5.6
sgs.ai_use_priority.Dismantlement = 4.4
function sgs.ai_card_intention.Dismantlement()
	sgs.ai_snat_disma_effect = false
end

sgs.dynamic_value.control_card.Dismantlement = true

function SmartAI:useCardCollateral(card, use)
	if self.player:hasSkill("noswuyan") then return end
	local fromList = sgs.QList2Table(self.room:getOtherPlayers(self.player))
	local toList = sgs.QList2Table(self.room:getAlivePlayers())

	local cmp = function(a, b)
		local alevel = self:objectiveLevel(a)
		local blevel = self:objectiveLevel(b)

		if alevel ~= blevel then return alevel > blevel end

		local anum = getCardsNum("Slash", a)
		local bnum = getCardsNum("Slash", b)
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

	needCrossbow = needCrossbow and self:getCardsNum("Slash", friend) > 2 and not self.player:hasSkill("paoxiao")

	if needCrossbow then
		for i = #fromList, 1, -1 do
			local friend = fromList[i]
			if friend:getWeapon() and friend:getWeapon():isKindOf("Crossbow")
				and not friend:hasSkill("weimu") and not self.room:isProhibited(self.player, friend, card) then
				for _, enemy in ipairs(toList) do
					if friend:canSlash(enemy, nil) and friend:objectName() ~= enemy:objectName() then
						self.player:setFlags("GlobalFlag_CollateralNeedCrossbow")
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
		if not self.room:isProhibited(self.player, enemy, card)
			and self:hasTrickEffective(card, enemy)
			and not self:hasSkills(sgs.lose_equip_skill, enemy)
			and not enemy:hasSkill("weimu")
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
					if enemy:canSlash(enemy2) and self:objectiveLevel(enemy2) <=3 and self:objectiveLevel(enemy2) >=0 and enemy:objectName() ~= enemy2:objectName() then
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
						and getKnownCard(friend, "Jink", true, "he") >= 2 then
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
		if friend:getWeapon() and getCardsNum("Slash", friend) >= 1
			and not friend:hasSkill("weimu")
			and self:objectiveLevel(friend) < 0
			and not self.room:isProhibited(self.player, friend, card) then

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
		if friend:getWeapon() and self:hasSkills(sgs.lose_equip_skill, friend)
			and not friend:hasSkill("weimu")
			and self:objectiveLevel(friend) < 0
			and not (friend:getWeapon():isKindOf("Crossbow") and getCardsNum("Slash", to) > 1)
			and not self.room:isProhibited(self.player, friend, card) then

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

sgs.ai_card_intention.Collateral = function(self, card, from, tos)
	assert(#tos == 1)
	-- bugs here?
	--[[if sgs.compareRoleEvaluation(tos[1], "rebel", "loyalist") ~= sgs.compareRoleEvaluation(from, "rebel", "loyalist") then
		sgs.updateIntention(from, tos[1], 80)
	end]]
	sgs.ai_collateral = false
end

sgs.dynamic_value.control_card.Collateral = true

sgs.ai_skill_cardask["collateral-slash"] = function(self, data, pattern, target, target2)
	if target2 and target2:hasFlag("GlobalFlag_CollateralNeedCrossbow") and self:isFriend(target2) then
		return "."
	end
	if self:isFriend(target) and target:hasSkill("leiji")
		and (self:hasSuit("spade", true, target) or target:getHandcardNum() >= 3)
		and (getKnownCard(target, "Jink", true) >= 1
			or (not self:isWeak(friend) and self:hasEightDiagramEffect(friend))) then
		for _, slash in ipairs(self:getCards("Slash")) do
			if self:slashIsEffective(slash, target) then
				return slash:toString()
			end
		end
	end
	if target and (self:getDamagedEffects(target, self.player) or target:getHp() > getBestHp(target)) then
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
	if target and not self:hasSkills(sgs.lose_equip_skill) and self:isEnemy(target) then
		for _, slash in ipairs(self:getCards("Slash")) do
			if self:slashIsEffective(slash, target) then
				return slash:toString()
			end
		end
	end
	if target and not self:hasSkills(sgs.lose_equip_skill) and self:isFriend(target) then
		for _, slash in ipairs(self:getCards("Slash")) do
			if not self:slashIsEffective(slash, target) then
				return slash:toString()
			end
		end
		if (target:getHp() > 2 or getCardsNum("Jink", target) > 1) and not target:getRole() == "lord" and self.player:getHandcardNum() > 1 then
			for _, slash in ipairs(self:getCards("Slash")) do
				return slash:toString()
			end
		end
	end
	self:speak("collateral", self.player:isFemale())
	return "."
end

local function hp_subtract_handcard(a, b)
	local diff1 = a:getHp() - a:getHandcardNum()
	local diff2 = b:getHp() - b:getHandcardNum()

	return diff1 < diff2
end

function SmartAI:enemiesContainsTrick()
	local trick_all, possible_indul_enemy, possible_ss_enemy = 0, 0, 0

	local zhanghe = self.room:findPlayerBySkillName("qiaobian")
	if zhanghe and (not self:isEnemy(zhanghe) or zhanghe:isKongcheng() or not zhanghe:faceUp()) then zhanghe = nil end

	local indul_num, ss_num = 0, 0
	for _, acard in sgs.qlist(self.player:getCards("he")) do
		if isCard("Indulgence", acard, self.player) then indul_num = indul_num + 1 end
		if isCard("SupplyShortage", acard, self.player) then ss_num = ss_num + 1 end
	end

	for _, enemy in ipairs(self.enemies) do
		if not enemy:containsTrick("YanxiaoCard") and not (self:hasSkills("qiaobian", enemy)
			and enemy:getHandcardNum() > 0) and not self:hasSkills("keji", enemy) then
			if enemy:containsTrick("indulgence") and (not zhanghe or self:playerGetRound(enemy) >= self:playerGetRound(zhanghe)) then
				trick_all = trick_all + 1
			else
				possible_indul_enemy = possible_indul_enemy + 1
			end
		end
		if not self:hasSkills("shensu", enemy) and (self.player:distanceTo(enemy) == 1 or self.player:hasSkill("duanliang") and self.player:distanceTo(enemy) <= 2) then
			if enemy:containsTrick("supply_shortage") and (not zhanghe or self:playerGetRound(enemy) >= self:playerGetRound(zhanghe)) then
				trick_all = trick_all + 1
			else
				possible_ss_enemy  = possible_ss_enemy + 1
			end
		end
	end

	indul_num = math.min(possible_indul_enemy, indul_num)
	ss_num = math.min(possible_ss_enemy, ss_num)
	trick_all = trick_all + indul_num + ss_num
	return trick_all
end

function SmartAI:playerGetRound(player, source, friend_or_enemy)
	if not player then self.room:writeToConsole(debug.traceback()) return 0 end
	source = source or self.player
	if player:objectName() == source:objectName() then return 0 end
	local round = 0
	for i = 1, self.room:alivePlayerCount() do
		if friend_or_enemy then
			if friend_or_enemy == 0 and self:isFriend(source) then
				round = round + 1
			elseif friend_or_enemy == 1 and not self:isEnemy(source) then
				round = round + 1
			end
		else
			round = round + 1
		end
		if source:getNextAlive():objectName() == player:objectName() then break end
		source = source:getNextAlive()
	end
	return round
end

function SmartAI:useCardIndulgence(card, use)
	local enemies = {}
	if #self.enemies == 0 then
		if sgs.turncount == 0 and self.role == "lord" and not sgs.isRolePredictable()
			and sgs.role_evaluation[self.player:getNextAlive():objectName()]["loyalist"] == 30
			and not (self.player:hasLordSkill("shichou") and self.player:getNextAlive():getKingdom() == "shu") then
			enemies = self:exclude({ self.player:getNextAlive() }, card)
		end
	else
		enemies = self:exclude(self.enemies, card)
	end

	local zhanghe = self.room:findPlayerBySkillName("qiaobian")
	local zhanghe_seat = zhanghe and zhanghe:faceUp() and self:isEnemy(zhanghe) and zhanghe:getSeat() or 0

	if #enemies == 0 then return end

	local getvalue = function(enemy)
		if enemy:containsTrick("indulgence") or enemy:containsTrick("YanxiaoCard")
			or (self:hasSkills("qiaobian", enemy) and not enemy:isKongcheng()) then
			return -100
		end
		if zhanghe_seat > 0 and (self:playerGetRound(zhanghe) <= self:playerGetRound(enemy) and self:enemiesContainsTrick() <= 1 or not enemy:faceUp()) then
			return - 100
		end

		local value = enemy:getHandcardNum() - enemy:getHp()

		if enemy:hasSkills("lijian|fanjian|neofanjian|nosfanjian|dimeng|jijiu|jieyin|anxu|yongsi|zhiheng|manjuan|rende") then value = value + 10 end
		if enemy:hasSkills("rende|qixi|qice|guose|duanliang|nosjujian|luoshen|jizhi|jilve|wansha|mingce") then value = value + 5 end
		if enemy:hasSkills("guzheng|luoying|yinling|gongxin|shenfen|ganlu|duoshi") then value = value + 3 end
		if self:isWeak(enemy) then value = value + 3 end
		if enemy:isLord() then value = value + 3 end

		if self:objectiveLevel(enemy) < 3 then value = value -10 end
		if not enemy:faceUp() then value = value -10 end
		if enemy:hasSkills("keji|shensu") then value = value - enemy:getHandcardNum() end
		if enemy:hasSkills("guanxing|xiuluo") then value = value - 5 end
		if enemy:hasSkills("lirang") then value = value - 5 end
		if enemy:hasSkills("tuxi|noszhenlie|guanxing|qinyin|zongshi|tiandu") then value = value - 3 end
		if self:needBear(enemy) then value = value - 20 end
		if not sgs.isGoodTarget(enemy, self.enemies, self) then value = value - 1 end
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
	local peachnum = 0
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
	end
	if (not friendNeedPeach and peach) or peachnum > 1 then return peach end

	local exnihilo, jink, analeptic, nullification
	for _, card in ipairs(cards) do
		if card:isKindOf("ExNihilo") then
			if not nextPlayerCanUse or (not self:willSkipPlayPhase() and (self:hasSkills("jizhi|zhiheng|rende") or not self:hasSkills("jizhi|zhiheng", nextp))) then
				exnihilo = card:getEffectiveId()
			end
		end
		if card:isKindOf("Jink") then
			jink = card:getEffectiveId()
		end
		if card:isKindOf("Analeptic") then
			analeptic = card:getEffectiveId()
		end
		if card:isKindOf("Nullification") then
			nullification = card:getEffectiveId()
		end
	end

	for _, friend in ipairs(self.friends) do
		if self:willSkipPlayPhase(friend) or self:willSkipDrawPhase(friend) then return nullification end
	end

	if selfIsCurrent then
		if exnihilo then return exnihilo end
		if (jink or analeptic) and (self:getCardsNum("Jink") == 0 or (self:isWeak() and self:getOverflow() == 0)) then
			return jink or analeptic
		end
	else
		local enemy_num = self:playerGetRound(self.player, self.room:getCurrent(), 1)
		local InAttackRange = 0
		for _, enemy in ipairs(self.enemies) do
			if enemy:inMyAttackRange(self.player) then
				InAttackRange = InAttackRange + 1
			end
		end
		local possible_attack = math.min(enemy_num, InAttackRange)
		if possible_attack > self:getCardsNum("Jink") and self:getCardsNum("Jink") <= 2 then
			if jink or analeptic or exnihilo then return jink or analeptic or exnihilo end
		else
			if exnihilo then return exnihilo end
		end
	end

	if nullification and (self:getCardsNum("Nullification") < 2 or not nextplayercanuse) then 
		return nullification
	end

	local eightdiagram, silverlion, vine, renwang, armor, defHorse, offHorse
	local weapon, crossbow, halberd, double, qinggang, axe, gudingblade
	for _, card in ipairs(cards) do
		if card:isKindOf("EightDiagram") then eightdiagram = card:getEffectiveId() end
		if card:isKindOf("SilverLion") then silverlion = card:getEffectiveId() end
		if card:isKindOf("Vine") then vine = card:getEffectiveId() end
		if card:isKindOf("RenwangShield") then renwang = card:getEffectiveId() end
		if card:isKindOf("Armor") then armor = card:getEffectiveId() end
		if card:isKindOf("DefensiveHorse") and not self:getSameEquip(card) then defHorse = card:getEffectiveId() end
		if card:isKindOf("OffensiveHorse") and not self:getSameEquip(card) then offHorse = card:getEffectiveId() end
		if card:isKindOf("Crossbow") then crossbow = card:getEffectiveId() end
		if card:isKindOf("DoubleSword") then double = card:getEffectiveId() end
		if card:isKindOf("QinggangSword") then qinggang = card:getEffectiveId() end
		if card:isKindOf("Axe") then axe = card:getEffectiveId() end
		if card:isKindOf("GudingBlade") then gudingblade = card:getEffectiveId() end
		if card:isKindOf("Halberd") then halberd = card:getEffectiveId() end
		if card:isKindOf("Weapon") then weapon = card:getEffectiveId() end
	end

	if armor and not self:hasSkills("yizhong|bazhen") then
		if eightdiagram then
			local lord = self.room:getLord()
			if self:hasSkills("tiandu|leiji|noszhenlie|gushou|hongyan") and not self:getSameEquip(card) then
				return eightdiagram
			end
			if nextPlayerIsEnemy and self:hasSkills("tiandu|leiji|noszhenlie|gushou|hongyan", nextAlive) and not self:hasSkills("bazhen|yizhong", nextAlive)
				and not self:getSameEquip(card, nextAlive) then
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
				if aplayer:hasSkill("leiji") and self:isEnemy(aplayer) then
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

	if defHorse and (not self.player:hasSkill("leiji") or self:getCardsNum("Jink") == 0) then
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

	if analeptic then
		local slashs = self:getCards("Slash")
		for _, enemy in ipairs(self.enemies) do
			for _, slash in ipairs(slashs) do
				if (self:getCardsNum("Jink", enemy) < 1 or enemy:isKongcheng()) and self:slashIsEffective(slash, enemy) and self.player:canSlash(enemy, slash) then
					return analeptic
				end
			end
		end
	end

	if weapon and (self:getCardsNum("Slash") > 0 and self:slashIsAvailable() or not selfIsCurrent) then
		local current_range = self.player:getAttackRange()
		local nosuit_slash = sgs.Sanguosha:cloneCard("slash", sgs.Card_NoSuit, 0)
		local slash = selfIsCurrent and self:getCard("Slash") or nosuit_slash

		self:sort(self.enemies, "defense")

		if crossbow then
			if #self:getCards("Slash") > 1 or self:hasSkills("kurou|keji") 
				or (self:hasSkills("luoshen|yongsi|luoying|guzheng") and not selfIsCurrent and self.room:alivePlayerCount() >= 4) then
				return crossbow
			end
			if self.player:hasSkill("guixin") and self.room:alivePlayerCount() >= 6 and (self.player:getHp() > 1 or self:getCardsNum("Peach") > 0) then
				return crossbow
			end
			if self.player:hasSkill("rende") then
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
					if enemy:hasSkill("jijiu") and getKnownCard(enemy, "red", nil, "he") > 1 then canSave = true end
					if enemy:hasSkill("chunlao") and enemy:getPile("wine"):length() > 1 then canSave = true end
					if enemy:hasSkill("kurou") then huanggai = enemy end
					if enemy:hasSkill("keji") then return crossbow end
					if self:hasSkills("luoshen|yongsi|guzheng", enemy) then return crossbow end
					if enemy:hasSkill("luoying") and sgs.Sanguosha:getCard(crossbow):getSuit() ~= sgs.Card_Club then return crossbow end
				end
				if huanggai and (huanggai:getHp() > 2 or canSave) then return crossbow end
				if getCardsNum("Slash", nextAlive) >= 3 then return crossbow end
			end
		end

		if halberd and #self.enemies >= 2 then
			if self.player:hasSkill("rende") and #self.friends_noself > 0 then return halberd end
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
					self.player:getCardCount(true) >= 3 and self.player:canSlash(enemy, FFFslash, true, range_fix) then
					return axe
				elseif self:getCardsNum("Analeptic") > 0 and self.player:getCardCount(true) >= 4 and
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
		for _, skill in sgs.qlist(self.player:getVisibleSkillList()) do
			local callback = sgs.ai_cardneed[skill:objectName()]
			if type(callback) == "function" and callback(self.player, card, self) then
				return card:getEffectiveId()
			end
		end
	end

	local ag_snatch, ag_dismantlement, ag_indulgence, ag_supplyshortage, ag_collateral, ag_duel, ag_aoe, ag_fireattack, ag_godsalvation
	local new_enemies = {}
	if #self.enemies > 0 then
		new_enemies = self.enemies
	else
		for _, aplayer in sgs.qlist(self.room:getOtherPlayers(self.player)) do
			if sgs.evaluateRoleTrends(aplayer) == "neutral" then
				table.insert(new_enemies, aplayer)
			end
		end
	end
	local hasTrick = false
	for _, card in ipairs(cards) do
		for _, enemy in ipairs(new_enemies) do
			if not enemy:isNude() and isCard("Snatch", card, self.player) and self:hasTrickEffective(sgs.Sanguosha:cloneCard("snatch", card:getSuit(), card:getNumber()), enemy) and self.player:distanceTo(enemy) == 1 then
				ag_snatch = card:getEffectiveId()
				hasTrick = true
			elseif not enemy:isNude() and ((isCard("Dismantlement", card, self.player) and self:hasTrickEffective(sgs.Sanguosha:cloneCard("dismantlement", card:getSuit(), card:getNumber()), enemy))
											or (card:isBlack() and self.player:hasSkill("yinling") and self.player:getPile("brocade"):length() < 4)) then
				ag_dismantlement = card:getEffectiveId()
				hasTrick = true
			elseif isCard("Indulgence", card, self.player) and self:hasTrickEffective(sgs.Sanguosha:cloneCard("indulgence", card:getSuit(), card:getNumber()), enemy)
				and not enemy:containsTrick("indulgence") and not self:willSkipPlayPhase(enemy) then
				ag_indulgence = card:getEffectiveId()
				hasTrick = true
			elseif isCard("SupplyShortage", card, self.player) and self:hasTrickEffective(sgs.Sanguosha:cloneCard("supply_shortage", card:getSuit(), card:getNumber()), enemy)
				and not enemy:containsTrick("supply_shortage") and not self:willSkipDrawPhase(enemy) then
				ag_supplyshortage = card:getEffectiveId()
				hasTrick = true
			elseif isCard("Collateral", card, self.player) and self:hasTrickEffective(sgs.Sanguosha:cloneCard("collateral", card:getSuit(), card:getNumber()), enemy) and enemy:getWeapon() then
				ag_collateral = card:getEffectiveId()
				hasTrick = true
			elseif isCard("Duel", card, self.player) and (self:getCardsNum("Slash") >= getCardsNum("Slash", enemy) or self.player:getHandcardNum() > 4)
				and self:hasTrickEffective(sgs.Sanguosha:cloneCard("duel", card:getSuit(), card:getNumber()), enemy) then
				ag_duel = card:getEffectiveId()
				hasTrick = true
			elseif card:isKindOf("AOE") then
				local dummy_use = { isDummy = true }
				self:useTrickCard(card, dummy_use)
				if dummy_use.card then
					aoe = card:getEffectiveId()
					hasTrick = true
				end
			elseif isCard("FireAttack", card, self.player) and self:hasTrickEffective(sgs.Sanguosha:cloneCard("fire_attack", card:getSuit(), card:getNumber()), enemy)
				and self:damageIsEffective(enemy, sgs.DamageStruct_Fire, self.player) then

				local FFF
				if self.player:hasSkill("hongyan") and getKnownCard(enemy, "spade") > 0 then FFF = false end
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
			elseif isCard("GodSalvation", card, self.player) and self:willUseGodSalvation(sgs.Sanguosha:cloneCard("god_salvation", card:getSuit(), card:getNumber())) then
				ag_godsalvation = card:getEffectiveId()
				hasTrick = true
			end
		end
	end

	for _, friend in ipairs(self.friends_noself) do
		if self:willSkipPlayPhase(friend, true) or self:willSkipDrawPhase(friend, true) or self:needToThrowArmor(friend) then
			if self:hasTrickEffective(sgs.Sanguosha:cloneCard("snatch", card:getSuit(), card:getNumber()), enemy) and isCard("Snatch", card, self.player) and self.player:distanceTo(friend) == 1 then
				ag_snatch = card:getEffectiveId()
				hasTrick = true
			elseif (isCard("Dismantlement", card, self.player) and self:hasTrickEffective(sgs.Sanguosha:cloneCard("dismantlement", card:getSuit(), card:getNumber()), enemy))
					or (card:isBlack() and self.player:hasSkill("yinling") and self.player:getPile("brocade"):length() < 4) then
				ag_dismantlement = card:getEffectiveId()
				hasTrick = true
			end
		end
	end

	if hasTrick then
		if not self:willSkipPlayPhase() or not nextPlayerCanUse then
			return ag_snatch or ag_dismantlement or ag_indulgence or ag_supplyshortage or ag_collateral or ag_duel or ag_aoe or ag_godsalvation or ag_fireattack
		end
		if #trickCards > nextFriendNum + 1 and nextPlayerCanUse then
			return ag_fireattack or ag_godsalvation or ag_aoe or ag_duel or ag_collateral or ag_supplyshortage or ag_indulgence or ag_dismantlement or ag_snatch
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