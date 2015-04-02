require "ParseLib"

print("***********************PARSELIB TESTS*****************\n")
Test = Core.class()
function Test:init(testName)
	self.testName = testName
	self.parse = ParseLib.new(appId, apiKey, "ScoreTest", "PlayerTest")
end

--Ctor
TestCtor = Core.class(Test)
function TestCtor:init(testName)
	self.parse = nil
	self.parse = ParseLib.new(appId, apiKey)
	if (self.parse.scoreClass == "Score" and self.parse.playerClass == "Player") then
		print(self.testName.." SUCCESS")
	else
		print(self.testName.." FAILURE: ", "("..self.parse.scoreClass.." == Score and "..self.parse.playerClass.." == Player)")
	end
end
test = TestCtor.new("TestCtor")

--Ctor Params
TestCtorParams = Core.class(Test)
function TestCtorParams:init(testName)
	self.parse = nil
	self.parse = ParseLib.new(appId, apiKey, "ScoreTest", "PlayerTest")
	if (self.parse.scoreClass == "ScoreTest" and self.parse.playerClass == "PlayerTest") then
		print(self.testName.." SUCCESS")
	else
		print(self.testName.." FAILURE: ", "("..self.parse.scoreClass.." == ScoreTest and "..self.parse.playerClass.." == PlayerTest)")
	end
end
test = TestCtorParams.new("TestCtor")

--Login
TestLogin = Core.class(Test)
function TestLogin:init(testName)
	local function callback(success, userId)
		if (success and self.parse.userObjectId ~= nil and self.parse.currentFacebookId == self.facebookId) then
			print(self.testName.." SUCCESS")
		else
			print(self.testName.." FAILURE: ", "("..tostring(success).." and "..tostring(self.parse.userObjectId).." ~= nil and "..tostring(self.parse.currentFacebookId).." == "..self.facebookId..")")
		end
	end
	self.facebookId = "10152817179103304"
	self.parse:login(self.facebookId, callback)
end
test = TestLogin.new("TestLogin")

--addScore
local function testAddScore(success)
	if (success) then
		print("Scores added successfully")
	else
		print("Unable to add score")
	end
end


--Add score at specified level for logged in user.
local l = {
{level = 4, score = 13000},
{level = 6, score = 25000},
{level = 12, score = 240},
{level = 8, score = 1000}}
print("do")
for k, v in ipairs(l) do
	print(v.level, v.score)
end
parse = ParseLib.new(appId, apiKey, "ScoreTest", "PlayerTest")
parse:login("10152817179103304",
	function(success) print("HELLO")
		if (success) then print("addScore") parse:addScore(l, testAddScore) end
	end)


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
