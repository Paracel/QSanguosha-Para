sgs.ai_skill_invoke.chengxiang = function(self, data)
	return not (self.player:hasSkill("manjuan") and self.player:getPhase() == sgs.Player_NotActive)
end

sgs.ai_skill_askforag.chengxiang = function(self, card_ids)
	return self:askForAG(card_ids, false, "dummyreason")
end

function sgs.ai_cardsview_valuable.renxin(self, class_name, player)
	if class_name == "Peach" and not player:isKongcheng() then
		local dying = player:getRoom():getCurrentDyingPlayer()
		if not dying or self:isEnemy(dying, player) or dying:objectName() == player:objectName() then return nil end
		if dying:hasSkill("manjuan") and dying:getPhase() == sgs.Player_NotActive then
			local peach_num = 0
			if not player:hasFlag("Global_PreventPeach") then
				for _, c in sgs.qlist(player:getCards("he")) do
					if isCard("Peach", c, player) then peach_num = peach_num + 1 end
					if peach_num > 1 then return nil end
				end
			end
		end
		if not player:faceUp() then
			if player:getHp() < 2 and (getCardsNum("Jink", player) > 0 or getCardsNum("Analeptic", player) > 0) then return nil end
			return "@RenxinCard=."
		else
			if not dying:hasFlag("Global_PreventPeach") then
				for _, c in sgs.qlist(player:getHandcards()) do
					if not isCard("Peach", c, player) then return nil end
				end
			end
			return "@RenxinCard=."
		end
		return nil
	end
end

function sgs.ai_cardsview.renxin(self, class_name, player)
	if class_name == "Peach" and not player:isKongcheng() then
		local dying = player:getRoom():getCurrentDyingPlayer()
		if not dying or self:isEnemy(dying, player) or dying:objectName() == player:objectName() then return nil end
		if dying:hasSkill("manjuan") and dying:getPhase() == sgs.Player_NotActive then
			local peach_num = 0
			if not player:hasFlag("Global_PreventPeach") then
				for _, c in sgs.qlist(player:getCards("he")) do
					if isCard("Peach", c, player) then peach_num = peach_num + 1 end
					if peach_num > 1 then return nil end
				end
			end
		end
		if player:getHp() < 2 and (getCardsNum("Jink", player) > 0 or getCardsNum("Analeptic", player) > 0) then return nil end
		if not self:isWeak(player) then return "@RenxinCard=." end
		return nil
	end
end

sgs.ai_card_intention.RenxinCard = sgs.ai_card_intention.Peach

sgs.ai_skill_invoke.jingce = function(self, data)
	return not self:needKongcheng(self.player, true)
end