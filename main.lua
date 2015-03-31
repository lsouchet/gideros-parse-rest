require "ParseLib"
local parse = ParseLib.new(appId, apiKey, "ScoreTest", "PlayerTest")

--Login
local function testLogin(success, userId)
	if (success) then
		print("User ", userId.facebookId, "successfully logged in")
	else
		print("Unable to log user")
	end
end

-- Login new user with provided facebook Id
--Timer.delayedCall(1000, function() parse:login("10152817179103304", testLogin) end)

--addScore
local function testAddScore(success)
	if (success) then
		print("Scores added successfully")
	else
		print("Unable to add score")
	end
end


--Add score at specified level for logged in user.
--local l = {
--{level = "4", score = "1300"},
--{level = "6", score = "2500"},
--{level = "12", score = "240"},
--{level = "8", score = "100"}}
--print("do")
--for k, v in ipairs(l) do
--	print(v.level, v.score)
--end
--
--parse:login("10152817179103304",
--	function(success)
--		if (success) then print("addScore") parse:addScore(l, testAddScore) end
--	end)


--Get score
local function testGetScore(success, scoreList)
	if (success) then
		for i, score in ipairs(scoreList) do
			print("Get score ", score.score, "for level ", score.level)
		end
	else
		print("Unable to get scores")
	end
end

--Get score for current user at specified level
--[[parse:login("10152817179103304", 
	function(success, user) 
	if (success) then parse:getScore("2", nil, testGetScore) end
	end)
--]]
