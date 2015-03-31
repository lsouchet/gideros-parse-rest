-- ParseLib V1.1
-- 31/03/15

ParseLib = Core.class()
--Required to create page post data.

function ParseLib:init(appId, apiKey)
	self.scoreClass = "ScoreTest"
	self.playerClass = "PlayerTest"
	self.baseUrl = "https://api.parse.com/1/classes/"
	self.urls = {score = self.baseUrl..self.scoreClass, player = self.baseUrl..self.playerClass}
	self.headerAppId = {name = "X-Parse-Application-Id", key = appId}
	self.headerApiKey = {name = "X-Parse-REST-API-Key", key = apiKey}
	self.headerJson = {name = "Content-Type", key = "application/json"}

	self:resetUserData()
end

function ParseLib:resetUserData()
	self.userObjectId = nil
	self.currentFacebookId = nil
end

function ParseLib:getPostHeader()
	return {[self.headerAppId["name"]] = self.headerAppId["key"],
	 		[self.headerApiKey["name"]] = self.headerApiKey["key"],
	 		[self.headerJson["name"]] = self.headerJson["key"]}
end

function ParseLib:getGETHeader()
	return {[self.headerAppId["name"]] = self.headerAppId["key"],
	 		[self.headerApiKey["name"]] = self.headerApiKey["key"]}
end

onLoginComplete = function(request, event)
	local callback = request.userRequest["Callback"]
	local params = request.userRequest["Param"]
	local user = Json.Decode(event.data)
	if user.results == nil then
		if request.userRequest and callback then
			callback(false, nil, params)
		end
		return
	end
	if #user.results < 1 then
		if (request.self.createPlayer == nil) then
			if callback then
				callback(false, nil, params)
			else
				print("ParseLib.onLoginComplete: Unable to create player")
			end
			return
		end
		request.self.createPlayer(request.self, request.userRequest["FacebookId"],
								  request.userRequest["Callback"])
		return
	end
	if user.results[1].objectId == nil then
		if callback then
			callback(false, nil, params)
		else
			print("ParseLib.onLoginComplete: No object id")
		end
		return
	end
	if user.results[1].facebookId == nil then
		if callback then
			callback(false, nil, params)
		else
			print("ParseLib.onLoginComplete: No object id")
		end
		return
	end
	request.self.userObjectId = user.results[1].objectId
	request.self.currentFacebookId = user.results[1].facebookId
	if callback then
		callback(true, user.results[1], params)
	end
end

onLoginError = function(request)
	local callback = request.userRequest["Callback"]
	local params = request.userRequest["Param"]
	print("ParseLib.onLoginError: Unable to connect")
	if callback then
		callback(false, nil, params)
	end
end

-- Get user id from facebook ID. Callback(bool, user id)
function ParseLib:login(facebookId, callback, params)
	self:resetUserData()
	local headers = self:getGETHeader()
	local body = '?where={"facebookId":"'..facebookId..'"}'
	local loader = UrlLoader.new(self.urls["player"]..body, UrlLoader.GET, headers, '')
	local request = {}
	request.userRequest = {}
	request.userRequest["Callback"] = callback
	request.userRequest["Param"] = params
	request.userRequest["FacebookId"] = facebookId
	request.self = self
	loader:addEventListener(Event.COMPLETE, onLoginComplete, request)
	loader:addEventListener(Event.ERROR, onLoginError, request)
end

onCreateComplete = function(request, event)
	local callback = request.userRequest["Callback"]
	local params = request.userRequest["Param"]
	local user = Json.Decode(event.data)
	if user.createdAt == nil or user.objectId == nil then
		if callback then
			callback(false, nil, params)
		else
			print("ParseLib.onCreateComplete: ", event.data)
		end
		return
	end
	request.self.userObjectId = user.objectId
	request.self.currentFacebookId = request.userRequest["FacebookId"]
	if callback then
		callback(true, user, params)
	end
end

onCreateError = function(request)
	local callback = request.userRequest["Callback"]
	local params = request.userRequest["Param"]
	if (callback) then
		callback(false, nil, params)
	else 
		print("ParseLib.onCreateError")
	end
end

-- Add player to database with username and password. 
-- Callback(bool, user) is called when query ends.
function ParseLib:createPlayer(facebookId, callback, params)
	self:resetUserData()
	local headers = self:getPostHeader()
	local body = '{"facebookId":"'..facebookId..'"}'
	local loader = UrlLoader.new(self.urls["player"], UrlLoader.POST, headers, body)
	local request = {}
	request.userRequest = {}
	request.userRequest["Callback"] = callback
	request.userRequest["Param"] = params
	request.userRequest["FacebookId"] = facebookId
	request.self = self
	loader:addEventListener(Event.COMPLETE, onCreateComplete, request)
	loader:addEventListener(Event.ERROR, onCreateError, request)
end

onGetScoreComplete = function(request, event) -- tab = {self,player}
	--print("ParseLib.onGetScoreComplete", event.data)
	local callback = request.userRequest["Callback"]
	local params = request.userRequest["Param"]
	local scores = Json.Decode(event.data)
	if scores == nil or scores.results == nil or #scores.results < 1 or 
		scores.results[1].score == nil then
		if callback then 
			callback(false, nil, params)
			return
		end
	end
	if callback then 
		callback(true, scores.results, params)
	end
end

onGetScoreError = function(request)
	local callback = request.userRequest["Callback"]
	local params = request.userRequest["Param"]
	print("ParseLib.onGetScoreError: Unable to connect")
	if callback then
		callback(false, nil, params)
	end
end


-- get scores for current user at level "level". callback(bool, scores)
function ParseLib:getScore(level, facebookId, callback, params)
	local headers = {[self.headerAppId["name"]] = self.headerAppId["key"],
	 				[self.headerApiKey["name"]] = self.headerApiKey["key"]}
	local body = '?order='
	if level then
		body = body..'score'
	else
		body = body..'level'
	end
	body = body..'&include=owner&where={"owner":{"$inQuery":{"where":{"facebookId":'
	if facebookId == nil then
		if self.currentFacebookId == nil or self.userObjectId == nil then
			print("ParseLib.getScore, not logged in")
			if callback then
				callback(false, params)
			end
			return
		end
		body = body..'"'..self.currentFacebookId..'"'
	elseif #facebookId == 0 then
		print("ParseLib.getScore", "no facebook id provided")
		callback(false, params)
		return
	elseif #facebookId < 2 then
		body = body..'"'..facebookId[1]..'"'
	else
		body = body..'{"$in":["'..facebookId[1]..'"'
		for i = 2, table.getn(facebookId), 1 do
			body = body..',"'..facebookId[i]..'"'
		end
		body = body..']}'
	end
	body = body..'},"className":"'..self.playerClass..'"}}'
	if level then
		body = body..',"level":'..level
	end
	body = body.."}"
	local loader = UrlLoader.new(self.urls["score"]..body, UrlLoader.GET, headers, "")
	local request = {}
	request.userRequest = {}
	request.userRequest["Callback"] = callback
	request.userRequest["Param"] = params
	request.userRequest["GetScore"] = facebookId
	request.self = self
	loader:addEventListener(Event.COMPLETE, onGetScoreComplete, request)
	loader:addEventListener(Event.ERROR, onGetScoreError, request)
end

function ParseLib:addScore(levelScorePair, callback, params)
	if (self.currentFacebookId == nil or self.userObjectId == nil) then
		print("ParseLib.addScore: ", "not logged in")
		if callback then
			callback(false, params)
		end
		return
	end
	self.currentAddScore = levelScorePair
	for k, v in ipairs(levelScorePair) do
		self:internalAddScore(v.level, v.score, callback, params)
	end
end

onAddScoreComplete = function(request, event)
	local callback = request.userRequest["Callback"]
	local params = request.userRequest["Param"]
	local level = request.userRequest["Level"]
	local score = request.userRequest["Score"]
	local callCallback = true
	if request.self.currentAddScore then
		callCallback = false
		for k, v in ipairs(request.self.currentAddScore) do
			if v.level == level then
				table.remove(request.self.currentAddScore, k)
				break
			end
		end
		if #request.self.currentAddScore < 1 then
			callCallback = true
		end
	end
	if callback and callCallback == true then
    	callback(true, params)
    else
		print("ParseLib.onAddScoreComplete", level, score)
    end
end

onAddScoreError = function(request)
	local callback = request.userRequest["Callback"]
	local params = request.userRequest["Param"]
	if callback then
		callback(false, params)
	else 
		print("ParseLib.onAddScoreError: Unable to connect")
	end
end

-- Add new score in world for current user. callback(bool)
function ParseLib:internalAddScore(level, score, callback, params)
	--print("ParseLib.addScore", level, score)
	if (self.currentFacebookId == nil or self.userObjectId == nil) then
		print("ParseLib.internalAddScore: ", "not logged in")
		if callback then
			callback(false, params)
		end
		return
	end
	local request = {}
	request.internalRequest = {}
	request.internalRequest["Callback"] = callback
	request.internalRequest["Param"] = params
	request.userRequest = {}
	request.userRequest["Level"] = level
	request.userRequest["Score"] = score
	request.self = self
	local function insertScoreSwitch(success, score, request)
		--print("ParseLib.insertScoreSwitch", success, score)
		request.userRequest["Param"] = request.internalRequest["Param"]
		request.userRequest["Callback"] = request.internalRequest["Callback"]
		local callback = request.userRequest["Callback"]
		local params = request.userRequest["Param"]
		local localScore = score
		if success == true then
			self:updateScore(localScore[1].objectId, request.userRequest["Score"], request.userRequest["Level"],
				callback, params)
		else
			self:insertScore(request.userRequest["Score"], request.userRequest["Level"], callback, params)
		end
	end
	self:getScore(level, nil, insertScoreSwitch, request)
end

function ParseLib:updateScore(scoreObjectId, score, level, callback, params)
	--print("ParseLib.updateScore", scoreObjectId, score)
	local headers = self:getPostHeader()
	local body = '{"score":'..score..',"quantity":{"__op":"Increment","amount":1}}'
	local loader = UrlLoader.new(self.urls["score"].."/"..scoreObjectId, UrlLoader.PUT, headers, body)
	local request = {}
	request.userRequest = {}
	request.userRequest["Callback"] = callback
	request.userRequest["Param"] = params
	request.userRequest["Level"] = level
	request.userRequest["Score"] = score
	request.self = self
	loader:addEventListener(Event.COMPLETE, onAddScoreComplete, request)
	loader:addEventListener(Event.ERROR, onAddScoreError, request)
end

function ParseLib:insertScore(score, level, callback, params)
	--print("ParseLib.insertScore", score, level)
	local headers = self:getPostHeader()
	local body = '{"score":'..score..',"level":'..level..',"owner":{"__type":"Pointer","className":"'..self.playerClass..'","objectId":"'..self.userObjectId..'"},"quantity":1}'
	local loader = UrlLoader.new(self.urls["score"], UrlLoader.POST, headers, body)
	local request = {}
	request.userRequest = {}
	request.userRequest["Callback"] = callback
	request.userRequest["Param"] = params
	request.userRequest["Level"] = level
	request.userRequest["Score"] = score
	request.self = self
	loader:addEventListener(Event.COMPLETE, onAddScoreComplete, request)
	loader:addEventListener(Event.ERROR, onAddScoreError, request)
end
