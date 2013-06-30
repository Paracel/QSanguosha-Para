function SmartAI:useCardDrowning(card, use)
	if self.player:hasSkill("noswuyan") or (self.player:hasSkill("wuyan") and not self.player:hasSkill("jueqing")) then return end
	self:sort(self.enemies)
	local targets, equip_enemy = {}, {}
	for _, enemy in ipairs(self.enemies) do
		if (not use.current_targets or not table.contains(use.current_targets, enemy:objectName()))
			and self:hasTrickEffective(card, enemy) and self:damageIsEffective(enemy) and self:canAttack(enemy)
			and not self:getDamagedEffects(enemy, self.player) and not self:needToLoseHp(enemy, self.player) then
			if enemy:hasEquip() then table.insert(equip_enemy, enemy)
			else table.insert(targets, enemy)
			end
		end
	end
	if not (self.player:hasSkill("wumou") and self.player:getMark("@wrath") < 7) then
		if #equip_enemy > 0 then
			local function cmp(a, b)
				return a:getEquips():length() >= b:getEquips():length()
			end
			table.sort(equip_enemy, cmp)
			for _, enemy in ipairs(equip_enemy) do
				if not self:needToThrowArmor(enemy) then table.insert(targets, enemy) end
			end
		end
		for _, friend in ipairs(self.friends_noself) do
			if not (not use.current_targets or not table.contains(use.current_targets, friend:objectName())) and self:needToThrowArmor(friend) then
				table.insert(targets, friend)
			end
		end
	end
	if #targets > 0 then
		local targets_num = 1 + sgs.Sanguosha:correctCardTarget(sgs.TargetModSkill_ExtraTarget, self.player, card)
		use.card = card
		if use.to then
			for i = 1, targets_num, 1 do
				use.to:append(targets[i])
				if #targets == i then break end
			end
		end
	end
end

sgs.ai_card_intention.Drowning = function(self, card, from, tos)
	for _, to in ipairs(tos) do
		if not self:hasTrickEffective(card, to, from) or not self:damageIsEffective(to, sgs.DamageStruct_Normal, from)
			or self:needToThrowArmor(to) then
		else
			sgs.updateIntention(from, to, 80)
		end
	end
end

sgs.ai_use_value.Drowning = 5
sgs.ai_use_priority.Drowning = 7

sgs.ai_skill_choice.drowning = function(self, choices, data)
	local effect = data:toCardEffect()
	if not self:damageIsEffective(self.player, sgs.DamageStruct_Normal, effect.from)
		or self:needToLoseHp(self.player, effect.from)
		or self:getDamagedEffects(self.player, effect.from) then return "damage" end
	if self:isWeak() and not self:needDeath() then return "throw" end

	local value = 0
	for _, equip in sgs.qlist(self.player:getEquips()) do
		if equip:isKindOf("Weapon") then value = value + self:evaluateWeapon(equip)
		elseif equip:isKindOf("Armor") then
			value = value + self:evaluateArmor(equip)
			if self:needToThrowArmor() then value = value - 5 end
		elseif equip:isKindOf("OffensiveHorse") then value = value + 2.5
		elseif equip:isKindOf("DefensiveHorse") then value = value + 5
		end
	end
	if value < 8 then return "throw" else return "damage" end
end

sgs.ai_skill_playerchosen.koftuxi = function(self, targets)
	local cardstr = sgs.ai_skill_use["@@tuxi"](self, "@tuxi")
	if cardstr:match("->") then
		local targetstr = cardstr:split("->")[2]:split("+")
		if #targetstr > 0 then
			local target = findPlayerByObjectName(self.room, targetstr[1])
			return target
		end
	end
	return nil
end

sgs.ai_playerchosen_intention.koftuxi = function(self, from, to)
	local lord = self.room:getLord()
	if sgs.evaluatePlayerRole(from) == "neutral" and sgs.evaluatePlayerRole(to) == "neutral"
		and lord and not lord:isKongcheng()
		and not self:doNotDiscard(lord, "h", true) and from:aliveCount() >= 4 then
		sgs.updateIntention(from, lord, -35)
		return
	end
	if from:getState() == "online" then
		if (to:hasSkills("kongcheng|zhiji|lianying") and to:getHandcardNum() == 1) or to:hasSkills("tuntian+zaoxian") then
		else
			sgs.updateIntention(from, to, 80)
		end
	else
		local intention = from:hasFlag("AI_TuxiToFriend_" .. to:objectName()) and -5 or 80
		sgs.updateIntention(from, to, intention)
	end
end

sgs.ai_chaofeng.kof_zhangliao = 4

xiechan_skill = {}
xiechan_skill.name = "xiechan"
table.insert(sgs.ai_skills, xiechan_skill)
xiechan_skill.getTurnUseCard = function(self)
	if self.player:getMark("@twine") <= 0 then return end
	self:sort(self.enemies, "handcard")
	if self.player:hasSkill("luoyi") and not self.player:hasFlag("luoyi") then return end
	return sgs.Card_Parse("@XiechanCard=.")
end

sgs.ai_skill_use_func.XiechanCard = function(card, use, self)
	self.player:setFlags("AI_XiechanUsing")
	local max_card = self:getMaxCard()
	self.player:setFlags("-AI_XiechanUsing")
	if max_card:isKindOf("Slash") and self:getCardsNum("Slash") <= 2 then return end
	local max_point = max_card:getNumber()

	local dummy_use = { isDummy = true, xiechan = true, to = sgs.SPlayerList() }
	local duel = sgs.Sanguosha:cloneCard("Duel")
	self:useCardDuel(duel, dummy_use)
	if not dummy_use.card or not dummy_use.card:isKindOf("Duel") then return end
	for _, enemy in sgs.qlist(dummy_use.to) do
		if not enemy:isKongcheng() and not (enemy:hasSkill("kongcheng") and enemy:getHandcardNum() == 1) then
			local enemy_max_card = self:getMaxCard(enemy)
			local enemy_max_point = enemy_max_card and enemy_max_card:getNumber() or 100
			if max_point > enemy_max_point then
				self.xiechan_card = max_card:getId()
				use.card = card
				if use.to then use.to:append(enemy) end
				return
			end
		end
	end
end

sgs.ai_view_as.kofqingguo = function(card, player, card_place)
	local suit = card:getSuitString()
	local number = card:getNumberString()
	local card_id = card:getEffectiveId()
	if card_place == sgs.Player_PlaceEquip then
		return ("jink:kofqingguo[%s:%s]=%d"):format(suit, number, card_id)
	end
end

function sgs.ai_cardneed.kofqingguo(to, card)
	if card:isKindOf("Weapon") then return not to:getWeapon()
	elseif card:isKindOf("Armor") then return not to:getArmor()
	elseif card:isKindOf("OffensiveHorse") then return not to:getOffensiveHorse()
	elseif card:isKindOf("DefensiveHorse") then return not to:getDefensiveHorse()
	end
	return false
end


sgs.ai_skill_invoke.kofliegong = sgs.ai_skill_invoke.liegong

function sgs.ai_cardneed.kofliegong(to, card)
	return isCard("Slash", card, to) and getKnownCard(to, "Slash", true) == 0
end

sgs.ai_skill_invoke.yinli = function(self)
	return not self:needKongcheng(self.player, true)
end

sgs.ai_skill_askforag.yinli = function(self, card_ids)
	if self:needKongcheng(self.player, true) then return card_ids[1] else return -1 end
end

sgs.ai_skill_choice.kofxiaoji = function(self, choices)
	if choices:match("recover") then return "recover" else return "draw" end
end

sgs.kofxiaoji_keep_value = sgs.xiaoji_keep_value

sgs.ai_skill_invoke.suzi = true
sgs.ai_skill_invoke.cangji = true

sgs.ai_skill_use["@@cangji"] = function(self, prompt)
	for i = 0, 3, 1 do
		local equip = self.player:getEquip(i)
		if not equip then continue end
		self:sort(self.friends_noself)
		if i == 0 then
			if equip:isKindOf("Crossbow") or equip:isKindOf("Blade") then
				for _, friend in ipairs(self.friends_noself) do
					if not self:getSameEquip(equip) and not self:hasCrossbowEffect(friend) and getCardsNum("Slash", friend) > 1 then
						return "@CangjiCard=" .. equip:getEffectiveId() .. "->" .. friend:objectName()
					end
				end
			elseif equip:isKindOf("Axe") then
				for _, friend in ipairs(self.friends_noself) do
					if not self:getSameEquip(equip)
						and (friend:getCardCount(true) >= 4
							or (friend:getCardCount(true) >= 2 and self:hasHeavySlashDamage(friend))) then
						return "@CangjiCard=" .. equip:getEffectiveId() .. "->" .. friend:objectName()
					end
				end
			end
		end
		for _, friend in ipairs(self.friends_noself) do
			if not self:getSameEquip(equip, friend) and not (i == 1 and (self:evaluateArmor(equip, friend) <= 0 or friend:hasSkills("bazhen|yizhong"))) then
				return "@CangjiCard=" .. equip:getEffectiveId() .. "->" .. friend:objectName()
			end
		end
		if equip:isKindOf("SilverLion") then
			for _, enemy in ipairs(self.enemies) do
				if not enemy:getArmor() and enemy:hasSkills("bazhen|yizhong") then
					return "@CangjiCard=" .. equip:getEffectiveId() .. "->" .. enemy:objectName()
				end
			end
		end
	end
	return "."
end

sgs.ai_card_intention.CangjiCard = function(self, card, from, tos)
	local to = tos[1]
	local equip = sgs.Sanguosha:getCard(card:getEffectiveId())
	if equip:isKindOf("SilverLion") and to:hasSkills("bazhen|yizhong") then
		sgs.updateIntention(from, to, 40)
	else
		sgs.updateIntention(from, to, -40)
	end
end

sgs.ai_skill_invoke.huwei = function(self, data)
	local drowning = sgs.Sanguosha:cloneCard("drowning")
	local dummy_use = { isDummy = true }
	self:useTrickCard(drowning, dummy_use)
	return (dummy_use.card ~= nil)
end

sgs.ai_skill_invoke.xiaoxi = function(self, data)
	local slash = sgs.Sanguosha:cloneCard("slash")
	local dummy_use = { isDummy = true }
	self:useBasicCard(slash, dummy_use)
	return (dummy_use.card ~= nil)
end

sgs.ai_skill_invoke.manyi = function(self, data)
	local sa = sgs.Sanguosha:cloneCard("savage_assault")
	local dummy_use = { isDummy = true }
	self:useTrickCard(sa, dummy_use)
	return (dummy_use.card ~= nil)
end

-- @@todo: Mouzhu AI

sgs.ai_skill_invoke.yanhuo = function(self, data)
	local opponent = self.player:getOtherPlayers(true):first()
	return opponent:isAlive() and not self:doNotDiscard(opponent)
end

sgs.ai_skill_playerchosen.yanhuo = function(self, targets)
	return self:findPlayerToDiscard()
end