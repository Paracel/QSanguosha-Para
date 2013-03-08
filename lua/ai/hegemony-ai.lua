sgs.ai_skill_cardask["@xiaoguo"] = function(self, data)
	local currentplayer = self.room:getCurrent()

	local has_anal, has_slash, has_jink
	for _, acard in sgs.qlist(self.player:getHandcards()) do
		if acard:isKindOf("Analeptic") then has_anal = acard
		elseif acard:isKindOf("Slash") then has_slash = acard
		elseif acard:isKindOf("Jink") then has_jink = acard
		end
	end

	local card

	if has_slash then card = has_slash
	elseif has_jink then card = has_jink
	elseif has_anal then
		if (getCardsNum("EquipCard", currentplayer) == 0 and not self:isWeak()) or self:getCardsNum("Analeptic") > 1 then
			card = has_anal
		end
	end

	if not card then return "." end
	if self:isFriend(currentplayer) then
		if self:needToThrowArmor(currentplayer) then 
			if card:isKindOf("Slash") or (card:isKindOf("Jink") and self:getCardsNum("Jink") > 1) then
				return "$" .. card:getEffectiveId()
			else return "."
			end
		end
	elseif self:isEnemy(currentplayer) then
		if not self:damageIsEffective(currentplayer) then return "." end
		if self:getDamagedEffects(currentplayer) or self:needToLoseHp(currentplayer) then return "." end
		if self:needToThrowArmor() then return "." end
		if self:hasSkills(sgs.lose_equip_skill, currentplayer) and currentplayer:getCards("e"):length() > 0 then return "." end
		return "$" .. card:getEffectiveId()
	end
	return "."
end

sgs.ai_choicemade_filter.cardResponded["@xiaoguo"] = function(player, promptlist)
	if promptlist[#promptlist] ~= "_nil_" then
		local current = player:getRoom():getCurrent()
		if not current then return end
		local intention = 50
		if (current:hasArmorEffect("silver_lion") and current:isWounded() and self:isWeak(current))
			or (current:getArmor() and current:hasSkills("bazhen|yizhong")) then
			intention = -30
		end
		sgs.updateIntention(player, current, intention)
	end
end

sgs.ai_skill_cardask["@xiaoguo-discard"] = function(self, data)
	local yuejin = self.room:findPlayerBySkillName("xiaoguo")
	local player = self.player

	if self:needToThrowArmor(player) then
		return "$" .. player:getArmor():getEffectiveId()
	end

	if not self:damageIsEffective(player, sgs.DamageStruct_Normal, yuejin) then
		return "."
	end

	if self:getDamagedEffects(self.player) then
		return "."
	end

	if player:getHp() > getBestHp(player) then
		return "."
	end

	local card_id
	if self:hasSkills(sgs.lose_equip_skill, player) then
		if player:getWeapon() then card_id = player:getWeapon():getId()
		elseif player:getOffensiveHorse() then card_id = player:getOffensiveHorse():getId()
		elseif player:getDefensiveHorse() then card_id = player:getDefensiveHorse():getId()
		elseif player:getArmor() then card_id = player:getArmor():getId()
		end
	end

	if not card_id then
		for _, card in sgs.qlist(player:getHandcards()) do
			if card:getTypeId() == sgs.Card_TypeEquip then
				card_id = card:getEffectiveId()
				break
			end
		end
	end

	if not card_id then
		if player:getWeapon() then card_id = player:getWeapon():getId()
		elseif player:getOffensiveHorse() then card_id = player:getOffensiveHorse():getId()
		elseif player:getDefensiveHorse() then card_id = player:getDefensiveHorse():getId()
		elseif player:getHp() < 4 and player:getArmor() then card_id = player:getArmor():getId()
		end
	end

	if not card_id then return "." else return "$" .. card_id end
end

sgs.ai_cardneed.xiaoguo = function(to, card)
	return getKnownCard(to, "BasicCard", true) == 0 and card:getTypeId() == sgs.Card_TypeBasic
end

sgs.ai_skill_use["@@shushen"] = function(self, prompt)
	if #self.friends_noself == 0 then return "." end
	local to = self:findPlayerToDraw(false, 1)
	if to then return ("@ShushenCard=.->%s"):format(to:objectName()) end
	return "."
end

sgs.ai_card_intention.ShushenCard = -80

sgs.ai_skill_invoke.shenzhi = function(self, data)
	return self.player:getHandcardNum() >= self.player:getHp() and self.player:getHandcardNum() <= self.player:getHp() + math.max(3, self.player:getHp())
			and self.player:getLostHp() > 0 and self:getCardsNum("Peach") == 0
end

function sgs.ai_cardneed.shenzhi(to, card)
	return to:getHandcardNum() < to:getHp()
end

local duoshi_skill = {}
duoshi_skill.name = "duoshi"
table.insert(sgs.ai_skills, duoshi_skill)
duoshi_skill.getTurnUseCard = function(self, inclusive)
	local cards = self.player:getCards("h")
	cards = sgs.QList2Table(cards)

	local red_card
	if self.player:getCardCount(false) <= 2 then return end
	self:sortByUseValue(cards, true)

	for _, card in ipairs(cards) do
		if card:isRed() then
			local shouldUse = true
			if card:isKindOf("Slash") then
				local dummy_use = { isDummy = true }
				if self:getCardsNum("Slash") == 1 then
					self:useBasicCard(card, dummy_use)
					if dummy_use.card then shouldUse = false end
				end
			end

			if self:getUseValue(card) > sgs.ai_use_value.DuoshiCard and card:isKindOf("TrickCard") then
				local dummy_use = { isDummy = true }
				self:useTrickCard(card, dummy_use)
				if dummy_use.card then shouldUse = false end
			end

			if shouldUse and not card:isKindOf("Peach") then
				red_card = card
				break
			end

		end
	end

	if red_card then
		local card_id = red_card:getEffectiveId()
		local card_str = ("@DuoshiCard=" .. card_id)
		local await = sgs.Card_Parse(card_str)
		assert(await)
		return await
	end
end

sgs.ai_skill_use_func.DuoshiCard = function(card, use, self)
	use.card = card
	if use.to then use.to:append(self.player) end
	for _, player in ipairs(self.friends) do
		if use.to and not player:hasSkill("manjuan") and player:objectName() ~= self.player:objectName() then
			use.to:append(player)
		end
	end
	for _, enemy in ipairs(self.enemies) do
		if use.to and enemy:hasSkill("manjuan") then
			use.to:append(enemy)
		end
	end
end

sgs.ai_use_value.DuoshiCard = 3
sgs.ai_use_priority.DuoshiCard = 2.2
sgs.ai_card_intention.DuoshiCard = function(self, card, from, tos)
	for _, to in ipairs(tos) do
		sgs.updateIntention(from, to, to:hasSkill("manjuan") and 50 or -50)
	end
end

local fenxun_skill = {}
fenxun_skill.name = "fenxun"
table.insert(sgs.ai_skills, fenxun_skill)
fenxun_skill.getTurnUseCard = function(self)
	if self.player:hasUsed("FenxunCard") then return end
	if self:needBear() then return end
	if not self.player:isNude() then
		local card_id
		local slashcount = self:getCardsNum("Slash")
		local jinkcount = self:getCardsNum("Jink")
		local cards = self.player:getHandcards()
		cards = sgs.QList2Table(cards)
		self:sortByKeepValue(cards)

		if self:needToThrowArmor() then
			return sgs.Card_Parse("@FenxunCard=" .. self.player:getArmor():getId())
		elseif self.player:getHandcardNum() > 0 then
			local lightning = self:getCard("Lightning")
			if lightning and not self:willUseLightning(lightning) then
				card_id = lightning:getEffectiveId()
			else
				for _, acard in ipairs(cards) do
					if (acard:isKindOf("AmazingGrace") or acard:isKindOf("EquipCard")) then
						card_id = acard:getEffectiveId()
						break
					end
				end
			end
			if not card_id and jinkcount > 1 then
				for _, acard in ipairs(cards) do
					if acard:isKindOf("Jink") then
						card_id = acard:getEffectiveId()
						break
					end
				end
			end
			if not card_id and slashcount > 1 then
				for _, acard in ipairs(cards) do
					if acard:isKindOf("Slash") then
						slashcount = slashcount - 1
						card_id = acard:getEffectiveId()
						break
					end
				end
			end
		end

		if not card_id and self.player:getWeapon() then
			card_id = self.player:getWeapon():getId()
		end

		if not card_id then
			for _, acard in ipairs(cards) do
				if (acard:isKindOf("AmazingGrace") or acard:isKindOf("EquipCard") or acard:isKindOf("BasicCard"))
					and not isCard("Peach", acard, self.player) and not isCard("Slash", acard, self.player) then
					card_id = acard:getEffectiveId()
					break
				end
			end
		end

		if slashcount > 0 and card_id then
			return sgs.Card_Parse("@FenxunCard=" .. card_id)
		end
	end
	return nil
end

sgs.ai_skill_use_func.FenxunCard = function(card, use, self)
	if not self.player:hasUsed("FenxunCard") then
		self:sort(self.enemies, "defense")
		local target
		for _, enemy in ipairs(self.enemies) do
			for _, slash in ipairs(self:getCards("Slash")) do
				if self.player:distanceTo(enemy) > 1 and not self:slashProhibit(slash, enemy) 
				  and self.player:canSlash(enemy, slash, false) and sgs.isGoodTarget(enemy, self.enemies, self) then
					target = enemy
					break
				end
			end
		end
		if target and self:getCardsNum("Slash") > 0 then
			use.card = card
			if use.to then use.to:append(target) end
		end
	end
end

sgs.ai_use_value.FenxunCard = 5.5
sgs.ai_use_priority.FenxunCard = 8
sgs.ai_card_intention.FenxunCard = 50

sgs.ai_skill_choice.mingshi = function(self, choices, data)
	local damage = data:toDamage()
	return (self:isFriend(damage.to) or damage.damage > 1) and "no" or "yes"
end

sgs.ai_skill_invoke.lirang = function(self, data)
	if #self.friends_noself == 0 then return false end
	for _, friend in ipairs(self.friends_noself) do
		local insert = true
		if insert and friend:hasSkill("manjuan") and friend:getPhase() == sgs.Player_NotActive then insert = false end
		if insert and friend:hasFlag("DimengTarget") then
			local another
			for _, p in sgs.qlist(self.room:getOtherPlayers(friend)) do
				if p:hasFlag("DimengTarget") then
					another = p
					break
				end
			end
			if not another or not self:isFriend(another) then insert = false end
		end
		if insert then return true end
	end
	return false
end

sgs.ai_skill_use["@@sijian"] = function(self, prompt)
	local player = self:findPlayerToDiscard()
	if player then return ("@SijianCard=.->%s"):format(player:objectName()) end
	return "."
end

sgs.ai_card_intention.SijianCard = function(self, card, from, tos)
	local intention = 80
	local to = tos[1]
	if to:hasSkill("kongcheng") and to:getHandcardNum() == 1 and to:getHp() <= 2 then
		intention = -30
	elseif to:hasArmorEffect("silver_lion") and to:isWounded() then
		intention = -30
	end
	sgs.updateIntention(from, tos[1], intention)
end

sgs.ai_skill_choice.suishi1 = function(self, choices)
	local tianfeng = self.room:findPlayerBySkillName("suishi")
	if tianfeng and self:isFriend(tianfeng) then
		return "draw"
	end
	return "no"
end

sgs.ai_skill_choice.suishi2 = function(self, choices)
	local tianfeng = self.room:findPlayerBySkillName("suishi")
	if tianfeng and self:objectiveLevel(tianfeng) > 3 then
		return "damage"
	end
	return "no"
end

sgs.ai_skill_use["@@shuangren"] = function(self, prompt)
	self:sort(self.enemies, "handcard")
	local max_card = self:getMaxCard()
	local max_point = max_card:getNumber()

	local slash = sgs.Sanguosha:cloneCard("slash", sgs.Card_NoSuit, 0)
	local dummy_use = { isDummy = true }
	self.room:setPlayerFlag(self.player, "slashNoDistanceLimit")
	self:useBasicCard(slash, dummy_use)
	self.room:setPlayerFlag(self.player, "-slashNoDistanceLimit")

	if dummy_use.card then
		for _, enemy in ipairs(self.enemies) do
			if not (enemy:hasSkill("kongcheng") and enemy:getHandcardNum() == 1) and not enemy:isKongcheng() then
				local enemy_max_card = self:getMaxCard(enemy)
				local enemy_max_point = enemy_max_card and enemy_max_card:getNumber() or 100
				if max_point > enemy_max_point then
					return "@ShuangrenCard=" .. max_card:getEffectiveId() .. "->" .. enemy:objectName()
				end
			end
		end
		for _, enemy in ipairs(self.enemies) do
			if not (enemy:hasSkill("kongcheng") and enemy:getHandcardNum() == 1) and not enemy:isKongcheng() then
				if max_point >= 10 then
					return "@ShuangrenCard=" .. max_card:getEffectiveId() .. "->" .. enemy:objectName()
				end
			end
		end

		self:sort(self.friends_noself, "handcard")
		for index = #self.friends_noself, 1, -1 do
			local friend = self.friends_noself[index]
			if not friend:isKongcheng() then
				local friend_min_card = self:getMinCard(friend)
				local friend_min_point = friend_min_card and friend_min_card:getNumber() or 100
				if max_point > friend_min_point then
					return "@ShuangrenCard=" .. max_card:getEffectiveId() .. "->" .. friend:objectName()
				end
			end
		end

		local zhugeliang = self.room:findPlayerBySkillName("kongcheng")
		if zhugeliang and self:isFriend(zhugeliang) and zhugeliang:getHandcardNum() == 1 and zhugeliang:objectName() ~= self.player:objectName() then
			if max_point >= 7 then
				return "@ShuangrenCard=" .. max_card:getEffectiveId() .. "->" .. zhugeliang:objectName()
			end
		end

		for index = #self.friends_noself, 1, -1 do
			local friend = self.friends_noself[index]
			if not friend:isKongcheng() then
				if max_point >= 7 then
					return "@ShuangrenCard=" .. max_card:getEffectiveId() .. "->" .. friend:objectName()
				end
			end
		end
	end
	return "."
end

function sgs.ai_skill_pindian.shuangren(minusecard, self, requestor)
	local maxcard = self:getMaxCard()
	return self:isFriend(requestor) and self:getMinCard() or (maxcard:getNumber() < 6 and minusecard or maxcard)
end

sgs.ai_skill_playerchosen.shuangren_slash = sgs.ai_skill_playerchosen.zero_card_as_slash
sgs.ai_card_intention.ShuangrenCard = sgs.ai_card_intention.TianyiCard

xiongyi_skill = {}
xiongyi_skill.name = "xiongyi"
table.insert(sgs.ai_skills, xiongyi_skill)
xiongyi_skill.getTurnUseCard = function(self)
	if self.player:getMark("@arise") < 1 then return end
	if (#self.friends <= #self.enemies and self.player:getLostHp() >= 1) or self:isWeak() then return sgs.Card_Parse("@XiongyiCard=.") end
end

sgs.ai_skill_use_func.XiongyiCard = function(card, use, self)
	use.card = card
	for i = 1, #self.friends do
		if use.to then use.to:append(self.friends[i]) end
	end
end

sgs.ai_card_intention.XiongyiCard = -80

sgs.ai_skill_invoke.kuangfu = function(self, data)
	local damage = data:toDamage()
	if self:hasSkills(sgs.lose_equip_skill, damage.to) then
		return self:isFriend(damage.to)
	end
	local benefit = (damage.to:getCards("e"):length() == 1 and damage.to:getArmor() and self:needToThrowArmor(damage.to))
	if self:isFriend(damage.to) then return benefit end
	return not benefit
end

sgs.ai_skill_choice.kuangfu = function(self, choices)
	return "move"
end

local qingcheng_skill = {}
qingcheng_skill.name = "qingcheng"
table.insert(sgs.ai_skills, qingcheng_skill)
qingcheng_skill.getTurnUseCard = function(self, inclusive)
	local equipcard
	if self:needToThrowArmor() then
		equipcard = self.player:getArmor()
	else
		for _, card in sgs.qlist(self.player:getCards("he")) do
			if card:isKindOf("EquipCard") and not self.player:hasEquip(card) then
				equipcard = card
				break
			end
		end
		if not equipcard then
			for _, card in sgs.qlist(self.player:getCards("he")) do
				if card:isKindOf("EquipCard") and not card:isKindOf("Armor") and not card:isKindOf("DefensiveHorse") then
					equipcard = card
				end
			end
		end
	end

	if equipcard then
		local card_id = equipcard:getEffectiveId()
		local card_str = ("@QingchengCard=" .. card_id)
		local qc_card = sgs.Card_Parse(card_str)

		return qc_card
	end
end

sgs.ai_skill_use_func.QingchengCard = function(card, use, self)
	if self.room:alivePlayerCount() == 2 then
		local only_enemy = self.room:getOtherPlayers(self.player):first()
		if only_enemy:getLostHp() < 3 then return end
	end
	for _, enemy in ipairs(self.enemies) do
		for _, askill in ipairs(("noswuyan|wuyan|weimu|kanpo|liuli|yiji|jieming|ganglie|neoganglie|fankui|jianxiong|enyuan|nosenyuan" ..
								"|qingguo|longdan|xiangle|jiang|yanzheng|tianming|" ..
								"huangen|danlao|qianxun|juxiang|huoshou|anxian|fenyong|zhichi|jilei|feiying|yicong|wusheng|wushuang|tianxiang|leiji|" ..
								"xuanfeng|nosxuanfeng|luoying|xiaoguo|guhuo|guidao|guicai|shangshi|lianying|sijian|xiaoji|mingshi|zhiyu|hongyan|tiandu|lirang|" .. 
								"guzheng|xingshang|shushen"):split("|")) do
			if enemy:hasSkill(askill, true) and enemy:getMark("Qingcheng" .. askill) == 0 then
				use.card = card
				if use.to then
					use.to:append(enemy)
				end
				return
			end
		end
	end
	for _, friend in ipairs(self.friends_noself) do
		if friend:hasSkill("shiyong", true) and friend:getMark("Qingchengshiyong") == 0 then
			use.card = card
			if use.to then
				use.to:append(friend)
			end
			return
		end
	end
	return
end

sgs.ai_skill_choice.qingcheng = function(self, choices, data)
	local target = data:toPlayer()
	for _, askill in ipairs(("noswuyan|wuyan|weimu|kanpo|liuli|qingguo|longdan|xiangle|jiang|yanzheng|tianming|" ..
							"huangen|danlao|qianxun|juxiang|huoshou|anxian|fenyong|zhichi|jilei|feiying|yicong|wusheng|wushuang|tianxiang|leiji|" ..
							"xuanfeng|nosxuanfeng|luoying|xiaoguo|guhuo|guidao|guicai|shangshi|lianying|sijian|xiaoji|mingshi|zhiyu|hongyan|tiandu|lirang|" .. 
							"guzheng|xingshang|shushen"):split("|")) do
		if target:hasSkill(askill, true) and target:getMark("Qingcheng" .. askill) == 0 then
			return askill
		end
	end
end

sgs.ai_use_value.QingchengCard = 2
sgs.ai_use_priority.QingchengCard = 2.2
sgs.ai_card_intention.QingchengCard = 30

sgs.ai_skill_invoke.cv_caopi = function(self, data)
	if math.random(0, 2) == 0 then return true end
	return false
end

sgs.ai_skill_invoke.cv_zhugeliang = sgs.ai_skill_invoke.cv_caopi
sgs.ai_skill_invoke.cv_huangyueying = sgs.ai_skill_invoke.cv_caopi
