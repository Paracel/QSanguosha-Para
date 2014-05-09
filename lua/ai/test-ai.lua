local gdlonghun_skill = {}
gdlonghun_skill.name = "gdlonghun"
table.insert(sgs.ai_skills, gdlonghun_skill)
gdlonghun_skill.getTurnUseCard = function(self)
	local cards = sgs.QList2Table(self.player:getCards("he"))
	for _, id in sgs.qlist(self.player:getPile("wooden_ox")) do
		table.insert(cards, 1, sgs.Sanguosha:getCard(id))
	end
	self:sortByUseValue(cards, true)
	for _, card in ipairs(cards) do
		if card:getSuit() == sgs.Card_Diamond then
			return sgs.Card_Parse(("fire_slash:gdlonghun[%s:%s]=%d"):format(card:getSuitString(), card:getNumberString(), card:getId()))
		end
	end
end

sgs.ai_view_as.gdlonghun = function(card, player, card_place)
	local suit = card:getSuitString()
	local number = card:getNumberString()
	local card_id = card:getEffectiveId()
	if player:getHp() > 1 or card_place == sgs.Player_PlaceSpecial then return end
	if card:getSuit() == sgs.Card_Diamond then
		return ("fire_slash:gdlonghun[%s:%s]=%d"):format(suit, number, card_id)
	elseif card:getSuit() == sgs.Card_Club then
		return ("jink:gdlonghun[%s:%s]=%d"):format(suit, number, card_id)
	elseif card:getSuit() == sgs.Card_Heart and player:getMark("Global_PreventPeach") == 0 then
		return ("peach:gdlonghun[%s:%s]=%d"):format(suit, number, card_id)
	elseif card:getSuit() == sgs.Card_Spade then
		return ("nullification:gdlonghun[%s:%s]=%d"):format(suit, number, card_id)
	end
end

sgs.gdlonghun_suit_value = {
	heart = 6.7,
	spade = 5,
	club = 4.2,
	diamond = 3.9,
}
