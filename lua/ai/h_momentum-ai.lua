function sgs.ai_skill_invoke.wangxi(self, data)
	local target = data:toPlayer()
	if self:isFriend(target) then
		return not self:needKongcheng(target, true) and not (hasManjuanEffect(self.player) and hasManjuanEffect(target))
	else
		if hasManjuanEffect(self.player) then return false end
		return self:needKongcheng(target, true) or hasManjuanEffect(target)
	end
end

sgs.ai_choicemade_filter.skillInvoke.wangxi = function(self, player, promptlist)
	local damage = self.room:getTag("CurrentDamageStruct"):toDamage()
	local target = nil
	if damage.from and damage.from:objectName() == player:objectName() then
		target = damage.to
	elseif damage.to and damage.to:objectName() == player:objectName() then
		target = damage.from
	end
	if target and promptlist[3] == "yes" then
		if self:needKongcheng(target, true) then sgs.updateIntention(player, target, 10)
		elseif not hasManjuanEffect(target) and player:getState() == "robot" then sgs.updateIntention(player, target, -60)
		end
	end
end