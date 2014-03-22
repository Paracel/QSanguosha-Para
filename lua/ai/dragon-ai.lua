sgs.ai_skill_use["@@drzhiheng"] = function(self, prompt)
	if self.player:getHandcardNum() > self.player:getHp() then return "." end
	local to_discard = {}
	for _, zcard in sgs.qlist(self.player:getHandcards()) do
		if not isCard("Peach", zcard, self.player) and not isCard("Jink", zcard, self.player) and not isCard("Nullification", zcard, self.player) then
			table.insert(to_discard, zcard:getId())
		end
	end
	local use_cards = {}
	for index = #unpreferedCards, 1, -1 do
		if not self.player:isJilei(sgs.Sanguosha:getCard(to_discard[index])) then table.insert(use_cards, to_discard[index]) end
	end
	if #use_cards > 0 then
		return ("@DrZhihengCard=" .. table.concat(use_cards, "+"))
	else
		return ("@DrZhihengCard=.")
	end
end

local drjiedao_skill = {}
drjiedao_skill.name = "drjiedao"
table.insert(sgs.ai_skills, drjiedao_skill)
drjiedao_skill.getTurnUseCard = function(self)
	if self.player:hasUsed("DrJiedaoCard") then return end
	local can_use = false
	for _, p in sgs.qlist(self.room:getOtherPlayers(self.player)) do
		if p:getWeapon() then
			can_use = true
			break
		end
	end
	if can_use then return sgs.Card_Parse("@DrJiedaoCard=.") end
end

sgs.ai_skill_use_func.DrJiedaoCard = function(card, use, self)
	self:sort(self.enemies, "defense")
	local targets = {}
	for _, enemy in ipairs(self.enemies) do
		if enemy:getWeapon() and not enemy:hasSkills(sgs.lose_equip_skill) and not enemy:hasSkills("tuntian+zaoxian") then
			table.insert(targets, enemy)
		end
	end
	for _, friend in ipairs(self.friends_noself) do
		if friend:getWeapon() then
			table.insert(targets, friend)
		end
	end
	if #targets == 0 then return end
	local equip_need
	for _, enemy in ipairs(self.enemies) do
		if self:getCardsNum("Slash") > 0
			and self.player:canSlash(enemy, nil, false) and not self:cantbeHurt(enemy, self.player, self:hasHeavySlashDamage(self.player, nil, enemy, true))
			and sgs.isGoodTarget(enemy, self.enemies, self)
			and self:damageIsEffective(self.player, sgs.DamageStruct_Normal, enemy) then
			if self.player:distanceTo(enemy) == 1 and self:getCardsNum("Slash") > 3 then equip_need = "Crossbow"
			elseif self.player:distanceTo(enemy) <= 2 and enemy:getArmor() and not enemy:getArmor():isKindOf("SilverLion") then equip_need = "QinggangSword"
			elseif self.player:distanceTo(enemy) <= 2 and enemy:isKongcheng() then equip_need = "GudingBlade"
			elseif self.player:distanceTo(enemy) <= 4 and enemy:hasArmorEffect("vine") then equip_need = "Fan"
			elseif self.player:distanceTo(enemy) <= 5 and (enemy:getOffensiveHorse() or enemy:getDefensiveHorse()) then equip_need = "KylinBow"
			elseif self.player:getHandcardNum() == 1 and isCard("Slash", self.player:getHandcards():first(), self.player) then equip_need = "Halberd"
			elseif self.player:distanceTo(enemy) <= 3 and self.player:getCardCount() >= 5 then equip_need = "Axe"
			end
		end
		if equip_need then break end
	end
	if equip_need then
		for _, player in ipairs(targets) do
			if player:getWeapon() and player:getWeapon():isKindOf(equip_need) then
				use.card = card
				if use.to then use.to:append(player) end
				return
			end
		end
	end
	if self.player:getWeapon() then return end
	for _, player in ipairs(targets) do
		if player:getWeapon() then
			use.card = card
			if use.to then use.to:append(player) end
			return
		end
	end
end

sgs.ai_skill_cardask["@jijiu-decrease"] = function(self, data)
	local damage = data:toDamage()
	if not self:isFriend(damage.to) then return "." end
	if damage.to:hasSkills(sgs.masochism_skill) and damage.damage <= 1 and damage.to:getHp() > 1 then return "." end
	local cards = sgs.QList2Table(self.player:getCards("he"))
	self:sortByKeepValue(cards)
	for _, card in ipairs(cards) do
		if card:isRed() then return "$" .. card:getEffectiveId() end
	end
	return "."
end

local drqingnang_skill = {}
drqingnang_skill.name = "drqingnang"
table.insert(sgs.ai_skills, drqingnang_skill)
drqingnang_skill.getTurnUseCard = function(self)
	if self.player:isNude() or self.player:getLostHp() == 0 then return nil end

	local cards = self.player:getCards("he")
	cards = sgs.QList2Table(cards)

	self:sortByKeepValue(cards)

	local card_str = ("@DrQingnangCard=%d"):format(cards[1]:getId())
	return sgs.Card_Parse(card_str)
end

sgs.ai_skill_use_func.DrQingnangCard = function(card, use, self)
	use.card = card
end

sgs.ai_use_priority.DrQingnangCard = 4.2
sgs.ai_card_intention.DrQingnangCard = -80

sgs.ai_skill_discard.drwushuang = function(self, discard_num, min_num, optional, include_equip)
	return self:askForDiscard("dummyreason", discard_num, min_num, false, true)
end
