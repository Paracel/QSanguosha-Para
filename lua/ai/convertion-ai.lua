sgs.ai_skill_invoke.cv_caopi = function(self, data)
	if math.random(0, 2) == 0 then return true end
	return false
end

sgs.ai_skill_invoke.cv_zhugeliang = function(self, data)
	if math.random(0, 2) > 0 then return false end
	if math.random(0, 4) == 0 then sgs.ai_skill_choice.cv_zhugeliang = "tw_zhugeliang" return true
	else sgs.ai_skill_choice.cv_zhugeliang = "heg_zhugeliang" return true end
end

sgs.ai_skill_invoke.cv_nos_huangyueying = function(self, data)
	if math.random(0, 2) > 0 then return false end
	if math.random(0, 4) == 0 then sgs.ai_skill_choice.cv_nos_huangyueying = "tw_huangyueying" return true
	else sgs.ai_skill_choice.cv_nos_huangyueying = "heg_huangyueying" return true end
end

sgs.ai_skill_invoke.cv_sunshangxiang = function(self, data)
	local lord = self.room:getLord()
	if lord and lord:hasLordSkill("shichou") then
		return self:isFriend(lord)
	end
	return lord:getKingdom() == "shu"
end

sgs.ai_chaofeng.sp_sunshangxiang = sgs.ai_chaofeng.sunshangxiang

sgs.ai_skill_invoke.cv_caiwenji = function(self, data)
	local lord = self.room:getLord()
	if lord and lord:hasLordSkill("xueyi") then
		return not self:isFriend(lord)
	end
	return lord:getKingdom() == "wei"
end

sgs.ai_chaofeng.sp_caiwenji = sgs.ai_chaofeng.caiwenji

sgs.ai_skill_invoke.cv_machao = function(self, data)
	local lord = self.room:getLord()
	if lord and lord:hasLordSkill("xueyi") and self:isFriend(lord) then
		sgs.ai_skill_choice.cv_machao = "sp_machao"
		return true
	end
	if lord and lord:hasLordSkill("shichou") and not self:isFriend(lord) then
		sgs.ai_skill_choice.cv_machao = "sp_machao"
		return true
	end
	if lord and lord:getKingdom() == "qun" and not lord:hasLordSkill("xueyi") then
		sgs.ai_skill_choice.cv_machao = "sp_machao"
		return true
	end
	if math.random(0, 2) == 0 then
		sgs.ai_skill_choice.cv_machao = "tw_machao"
		return true
	end
end

sgs.ai_chaofeng.sp_machao = sgs.ai_chaofeng.machao

sgs.ai_skill_invoke.cv_diaochan = function(self, data)
	if math.random(0, 2) == 0 then return false
	elseif math.random(0, 3) == 0 then sgs.ai_skill_choice.cv_diaochan = "tw_diaochan" return true
	elseif math.random(0, 3) == 0 then sgs.ai_skill_choice.cv_diaochan = "heg_diaochan" return true
	else sgs.ai_skill_choice.cv_diaochan = "sp_diaochan" return true end
end

sgs.ai_chaofeng.sp_diaochan = sgs.ai_chaofeng.diaochan

sgs.ai_skill_invoke.cv_pangde = sgs.ai_skill_invoke.cv_caiwenji
sgs.ai_skill_invoke.cv_jiaxu = sgs.ai_skill_invoke.cv_caiwenji

sgs.ai_skill_invoke.cv_yuanshu = function(self, data)
	return math.random(0, 2) == 0
end

sgs.ai_skill_invoke.cv_zhaoyun = sgs.ai_skill_invoke.cv_yuanshu
sgs.ai_skill_invoke.cv_ganning = sgs.ai_skill_invoke.cv_yuanshu
sgs.ai_skill_invoke.cv_shenlvbu = sgs.ai_skill_invoke.cv_yuanshu

sgs.ai_skill_invoke.cv_daqiao = function(self, data)
	if math.random(0, 3) >= 1 then return false
	elseif math.random(0, 4) == 0 then sgs.ai_skill_choice.cv_daqiao = "tw_daqiao" return true
	else sgs.ai_skill_choice.cv_daqiao = "wz_daqiao" return true end
end

sgs.ai_skill_invoke.cv_xiaoqiao = function(self, data)
	if math.random(0, 3) >= 1 then return false
	elseif math.random(0, 4) == 0 then sgs.ai_skill_choice.cv_xiaoqiao = "wz_xiaoqiao" return true
	else sgs.ai_skill_choice.cv_xiaoqiao = "heg_xiaoqiao" return true end
end

sgs.ai_skill_invoke.cv_zhouyu = function(self, data)
	if math.random(0, 3) >= 1 then return false
	elseif math.random(0, 4) == 0 then sgs.ai_skill_choice.cv_zhouyu = "heg_zhouyu" return true
	else sgs.ai_skill_choice.cv_zhouyu = "sp_heg_zhouyu" return true end
end

sgs.ai_skill_invoke.cv_zhenji = function(self, data)
	if math.random(0, 3) >= 2 then return false
	elseif math.random(0, 4) == 0 then sgs.ai_skill_choice.cv_zhenji = "sp_zhenji" return true
	elseif math.random(0, 4) == 0 then sgs.ai_skill_choice.cv_zhenji = "tw_zhenji" return true
	else sgs.ai_skill_choice.cv_zhenji = "heg_zhenji" return true end
end

sgs.ai_skill_invoke.cv_lvbu = function(self, data)
	if math.random(0, 3) >= 1 then return false
	elseif math.random(0, 4) == 0 then sgs.ai_skill_choice.cv_lvbu = "tw_lvbu" return true
	else sgs.ai_skill_choice.cv_lvbu = "heg_lvbu" return true end
end

sgs.ai_skill_invoke.cv_zhangliao = sgs.ai_skill_invoke.cv_yuanshu
sgs.ai_skill_invoke.cv_luxun = sgs.ai_skill_invoke.cv_yuanshu

sgs.ai_skill_invoke.cv_huanggai = function(self, data)
	return math.random(0, 4) == 0
end

sgs.ai_skill_invoke.cv_guojia = sgs.ai_skill_invoke.cv_huanggai
sgs.ai_skill_invoke.cv_zhugeke = sgs.ai_skill_invoke.cv_huanggai
sgs.ai_skill_invoke.cv_yuejin = sgs.ai_skill_invoke.cv_huanggai
sgs.ai_skill_invoke.cv_madai = sgs.ai_skill_invoke.cv_huanggai

sgs.ai_skill_invoke.cv_zhugejin = function(self, data)
	return math.random(0, 4) > 1
end