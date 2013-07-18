neoluoyi_skill = {}
neoluoyi_skill.name = "neoluoyi"
table.insert(sgs.ai_skills, neoluoyi_skill)
neoluoyi_skill.getTurnUseCard = function(self)
	if self.player:hasUsed("LuoyiCard") then return nil end
	if self:needToThrowArmor() then
		return sgs.Card_Parse("@LuoyiCard=" .. self.player:getArmor():getEffectiveId())
	end

	local luoyicard
	local cards = self.player:getHandcards()
	cards = sgs.QList2Table(cards)
	local slashtarget = 0
	local dueltarget = 0
	local equipnum = 0
	local offhorse = self.player:getOffensiveHorse()
	local noHorseTargets = 0
	self:sort(self.enemies, "hp")
	for _, card in sgs.qlist(self.player:getCards("he")) do
		if card:isKindOf("EquipCard") and not (card:isKindOf("Weapon") and self:hasEquip(card)) then
			equipnum = equipnum + 1
		end
	end
	for _, card in ipairs(cards) do
		if isCard("Slash", card, self.player) then
			local slash = card:isKindOf("Slash") and card or sgs.Sanguosha:cloneCard("slash", card:getSuit(), card:getNumber())
			for _, enemy in ipairs(self.enemies) do
				if self.player:canSlash(enemy, slash) and self:slashIsEffective(slash, enemy) and self:objectiveLevel(enemy) > 3 and sgs.isGoodTarget(enemy, self.enemies, self) then
					if getCardsNum("Jink", enemy) < 1 or (self.player:hasWeapon("axe") and self.player:getCards("he"):length() > 4) then
						slashtarget = slashtarget + 1
						if offhorse and self.player:distanceTo(enemy, 1) <= self.player:getAttackRange() then
							noHorseTargets = noHorseTargets + 1
						end
					end
				end
			end
		end
		if isCard("Duel", card, self.player) then
			local duel = sgs.Sanguosha:cloneCard("duel", card:getSuit(), card:getNumber())
			for _, enemy in ipairs(self.enemies) do
				if self:getCardsNum("Slash") >= getCardsNum("Slash", enemy) and self:hasTrickEffective(duel, enemy)
					and self:objectiveLevel(enemy) > 3 and not self:cantbeHurt(enemy, self.player, 2) and self:damageIsEffective(enemy) then
					dueltarget = dueltarget + 1
				end
			end
		end
	end
	if (slashtarget + dueltarget) > 0 and equipnum > 0 then
		self:speak("luoyi")
		if self:needToThrowArmor() then
			luoyicard = self.player:getArmor()
		end
		if not luoyicard then
			for _, card in sgs.qlist(self.player:getCards("he")) do
				if card:isKindOf("EquipCard") and not self.player:hasEquip(card) then
					luoyicard = card
					break
				end
			end
		end
		if not luoyicard and offhorse then
			if noHorseTargets == 0 then
				for _, card in sgs.qlist(self.player:getCards("he")) do
					if card:isKindOf("EquipCard") and not card:isKindOf("OffensiveHorse") then
						luoyicard = card
						break
					end
				end
				if not luoyicard and dueltarget == 0 then return nil end
			end
		end
		if not luoyicard then
			for _, card in sgs.qlist(self.player:getCards("he")) do
				if card:isKindOf("EquipCard") and not (card:isKindOf("Weapon") and self.player:hasEquip(card)) then
					luoyicard = card
					break
				end
			end
		end
		if not luoyicard then return nil end
		return sgs.Card_Parse("@LuoyiCard=" .. luoyicard:getEffectiveId())
	end
end

sgs.ai_skill_use_func.LuoyiCard = function(card, use, self)
	use.card = card
end

sgs.ai_use_priority.LuoyiCard = 9.2

local neofanjian_skill = {}
neofanjian_skill.name = "neofanjian"
table.insert(sgs.ai_skills, neofanjian_skill)
neofanjian_skill.getTurnUseCard = function(self)
	if self.player:isKongcheng() then return nil end
	if self.player:usedTimes("NeoFanjianCard") > 0 then return nil end
	return sgs.Card_Parse("@NeoFanjianCard=.")
end

sgs.ai_skill_use_func.NeoFanjianCard = function(card, use, self)
	self:sort(self.enemies, "defense")
	local target
	for _, enemy in ipairs(self.enemies) do
		if self:canAttack(enemy) and not self:hasSkills("qingnang|tianxiang", enemy) then
			target = enemy

			local wuguotai = self.room:findPlayerBySkillName("buyi")
			local care = (target:getHp() <= 1) and (self:isFriend(target, wuguotai))
			local ucard = nil
			local handcards = self.player:getCards("h")
			handcards = sgs.QList2Table(handcards)
			self:sortByKeepValue(handcards)
			for _, cd in ipairs(handcards) do
				local flag = not (cd:isKindOf("Peach") or cd:isKindOf("Analeptic"))
				local suit = cd:getSuit()
				if flag and care then
					flag = cd:isKindOf("BasicCard")
				end
				if flag and target:hasSkill("longhun") then
					flag = (suit ~= sgs.Card_Heart)
				end
				if flag and target:hasSkill("jiuchi") then
					flag = (suit ~= sgs.Card_Spade)
				end
				if flag and target:hasSkill("jijiu") then
					flag = (cd:isBlack())
				end
				if flag then
					ucard = cd
					break
				end
			end
			if ucard then
				local keep_value = self:getKeepValue(ucard)
				if ucard:getSuit() == sgs.Card_Diamond then keep_value = keep_value + 0.5 end
				if keep_value < 6 then
					use.card = sgs.Card_Parse("@NeoFanjianCard=" .. ucard:getId())
					if use.to then use.to:append(target) end
					return
				end
			end
		end
	end
end

sgs.ai_card_intention.NeoFanjianCard = sgs.ai_card_intention.FanjianCard
sgs.dynamic_value.damage_card.NeoFanjianCard = true

function sgs.ai_skill_suit.neofanjian(self)
	local map = { 0, 0, 1, 2, 2, 3, 3, 3 }
	local suit = map[math.random(1, 8)]
	if self.player:hasSkill("hongyan") and suit == sgs.Card_Spade then return sgs.Card_Heart else return suit end
end
sgs.ai_skill_invoke.yishi = function(self, data)
	local damage = data:toDamage()
	local target = damage.to
	if self:isFriend(target) then
		if damage.damage == 1 and self:getDamagedEffects(target, self.player)
			and (target:getJudgingArea():isEmpty() or target:containsTrick("YanxiaoCard")) then
			return false
		end
		return true
	else
		if target:isNude() then return false end
		if self:hasHeavySlashDamage(self.player, damage.card, target) then return false end
		if target:getEquips():length() == 0
			and (target:getHandcardNum() == 1 and (self:hasSkills(sgs.need_kongcheng, target) or not self:hasLoseHandcardEffective(target))) then
			return false
		end
		if (target:hasSkills("tuntian+zaoxian") and target:getPhase() == sgs.Player_NotActive)
			or (target:isKongcheng() and self:hasSkills(sgs.lose_equip_skill, target)) then
			return false
		end
		if self:getDamagedEffects(target, self.player, true) or (target:getArmor() and not target:getArmor():isKindOf("SilverLion")) then return true end
		return false
	end
	return false
end

sgs.ai_skill_invoke.zhulou = function(self, data)
	for _, card in sgs.qlist(self.player:getCards("he")) do
		if card:isKindOf("Weapon") then
			return true
		end
	end
	if self.player:getHandcardNum() < 3 and self.player:getHp() > 2 then
		return true
	end
	return false
end

sgs.ai_skill_cardask["@zhulou-discard"] = function(self, data)
	for _, card in sgs.qlist(self.player:getCards("he")) do
		if card:isKindOf("Weapon") and not self.player:hasEquip(card) then
			return "$" .. card:getEffectiveId()
		end
	end
	for _, card in sgs.qlist(self.player:getCards("he")) do
		if card:isKindOf("Weapon") then
			return "$" .. card:getEffectiveId()
		end
	end
	return "."
end

sgs.ai_cardneed.zhulou = sgs.ai_cardneed.weapon
sgs.zhulou_keep_value = sgs.qiangxi_keep_value

function sgs.ai_skill_invoke.neojushou(self, data)
	if not self.player:faceUp() then return true end
	for _, friend in ipairs(self.friends) do
		if self:hasSkills("fangzhu|jilve", friend) then return true end
	end
	return self:isWeak()
end

sgs.ai_skill_invoke.neoganglie = function(self, data)
	local damage = data:toDamage()
	if not damage.from then
		local zhangjiao = self.room:findPlayerBySkillName("guidao")
		return zhangjiao and self:isFriend(zhangjiao)
	end
	local target = damage.from
	if (self:needToLoseHp(target, self.player) or self:getDamagedEffects(target, self.player)) and target:isKongcheng() then return false end
	if not self:isFriend(target) then
		target:setFlags("AI_GanglieTarget")
		return true
	else
		if self:getDamagedEffects(target, self.player) then
			sgs.ai_ganglie_effect = string.format("%s_%s_%d", self.player:objectName(), target:objectName(), sgs.turncount)
			return true
		end
	end
	return false
end

sgs.ai_need_damaged.neoganglie = function(self, attacker, player)
	if not attacker:hasSkill("neoganglie") and self:getDamagedEffects(attacker, player) then return self:isFriend(attacker, player) end
	if self:isEnemy(attacker, player) and attacker:getHp() <= 2 and not hasBuquEffect(attacker) and sgs.isGoodTarget(attacker, self:getEnemies(player), self) then
		return true
	end
	return false
end

sgs.ai_skill_choice.neoganglie = function(self, choices)
	local target
	for _, player in sgs.qlist(self.room:getOtherPlayers(self.player)) do
		if player:hasFlag("AI_GanglieTarget") then
			target = player
			target:setFlags("-AI_GanglieTarget")
		end
	end
	if (self:getDamagedEffects(target, self.player) or self:needToLoseHp(target, self.player)) and self:isFriend(target) then return "damage" end
	if (self:getDamagedEffects(target, self.player) or self:needToLoseHp(target, self.player, false, true)) and self:isEnemy(target) and not target:isKongcheng() then
		return "throw"
	end
	return "damage"
end

sgs.ai_skill_discard.neoganglie = function(self, discard_num, min_num, optional, include_equip)
	local to_discard = {}
	local cards = sgs.QList2Table(self.player:getHandcards())
	local index = 0
	self:sortByKeepValue(cards)
	cards = sgs.reverse(cards)

	for i = #cards, 1, -1 do
		local card = cards[i]
		if not self.player:isJilei(card) then
			table.insert(to_discard, card:getEffectiveId())
			table.remove(cards, i)
			index = index + 1
			if index == 2 then break end
		end
	end
	return to_discard
end

sgs.ai_choicemade_filter.skillInvoke.neoganglie = sgs.ai_choicemade_filter.skillInvoke.ganglie