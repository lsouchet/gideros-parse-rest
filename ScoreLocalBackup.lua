require "json"

ScoreLocalBackup = Core.class()

function ScoreLocalBackup:init()
	self.scoreFilename = "|D|localScores"
	self.scores = dataSaver.load(self.scoreFilename)
	if not self.scores then
		self.scores = {}
	end
	self.picturesFilename = "|D|pictures"
	self.pictures = dataSaver.load(self.picturesFilename)
	if not self.pictures then
		self.pictures = {}
	end
end

function ScoreLocalBackup:loadFromParse(parse, facebookIdList, callback)
	local function onGetScore(success, scoreList, backup) 
		for i, score in ipairs(scoreList) do
			if not self.scores[score.owner.facebookId] then 
				self.scores[score.owner.facebookId] = {}
			end
			if not self.scores[score.owner.facebookId][score.level] then 
				self.scores[score.owner.facebookId][score.level] = {}
			end
			self.scores[score.owner.facebookId][score.level] = score.score
		end
		self:updatePictures()
	end
	parse:getScore(nil, facebookIdList, onGetScore, self)
end

function ScoreLocalBackup:save()
	dataSaver.save(self.scoreFilename, self.scores)
	dataSaver.save(self.picturesFilename, self.pictures)
end

function ScoreLocalBackup:print()
	for fbId, tab in pairs(self.scores) do
		print("User ", fbId)
		for lvl, score in pairs(tab) do 
			print("lvl:", lvl, ", score: " , score)
		end
	end
end

function ScoreLocalBackup:printPictures()
	for index, bmp in pairs(self.pictures) do 
		print("picture", bmp["path"])
	end
end

function ScoreLocalBackup:getScoreForLevel(level)
	local result = {}
	for fbId, tab in pairs(self.scores) do
		if tab[level] ~= nil then
			table.append(result, {facebookId = fbId, score = tab[level], picture = self.pictures[fbId]})
		end
	end
end

function ScoreLocalBackup:updatePictures()
	--print("updatePictures")
	for fbId, tab in pairs(self.scores) do
		--print("picture", fbId)
		self:getPicture(fbId)
	end
end

function ScoreLocalBackup:getPicture(fbId)
	local function onGetImage(event)
		--print("ScoreLocalBackup.onGetImage", event.data)
		local function onDownloadPicture(event)
			--print("ScoreLocalBackup.onDownloadPicture")
			local imagePath = "|D|"..fbId..".jpg"
			local out = io.open(imagePath, "wb")
			out:write(event.data)
			out:close()
			local tex = Texture.new(imagePath, true)
			self.pictures[fbId]["path"] = imagePath

		end
		local data = json.decode(event.data)
		if (self.pictures[fbId] == nil or self.pictures[fbId]["url"] ~= data.data.url) then
			--print("ScoreLocalBackup.getPicture", "download new image")
			local imageLoader = UrlLoader.new(data.data.url)
			imageLoader:addEventListener(Event.COMPLETE, onDownloadPicture)
			self.pictures[fbId] = {url = data.data.url}
		else
			--print("ScoreLocalBackup.getPicture", "Image already downloaded")
		end
	end
	local url = "https://graph.facebook.com/"..fbId.."/picture?type=square&redirect=false"
			local loader = UrlLoader.new(url)
			loader:addEventListener(Event.COMPLETE, onGetImage)
end