native.setProperty( "windowTitleText", "Particles by Hetsen" )

_W = display.contentWidth
_H = display.contentHeight

local physics = require( "physics" )
local json = require ("json")

function jsonLoad(fileName, dir)
	local path = system.pathForFile(fileName, dir or system.DocumentsDirectory)
	if not path then return nil end
	local file = io.open(path, 'r')
	if not file then return nil end
	local data = require('json').decode(file:read('*a'))
	io.close(file)
	return data
end


config = jsonLoad("config.cfg", system.ResourceDirectory)
if config == nil then
	config =
	{
		["volumeUp"] = "n",
		["volumeDown"] = "m",
		["pauseStars"] = "u",
		["trailtimeUp"] = "i",
		["trailtimeDown"] = "o",
		["music"] = "b",
		["debug"] = "false"
	}
end

physics.isStarted = false


-- [[ Variables ]] --
gravity = 1
timerCount = 0
trailTime = 300
starfieldTimerPaused = false
gameRunning = true
volume = .3
musicOn = true
level = 0

-- [[ Load sfx]] --

startGameSound 	= audio.loadSound( "sfx/start.mp3" )
crash 			= audio.loadSound( "sfx/crash.mp3" )
volumePop		= audio.loadSound( "sfx/volumepop.wav" )
music			= audio.loadSound( "sfx/music2.mp3" )

audio.play(music, {loops=-1, channel=2})
audio.setVolume(volume)

-- [[ Various texts and images ]] --

holderField = display.newImage("graphics/holderfield_new.png",0,0)
holderField.x, holderField.y = _W*.5, _H*.5
holderField.alpha = .2
holderField.xScale, holderField.yScale = .8,.8


startTextGroup = display.newGroup()

coverBack = display.newRect(0,0,_W,_H)
coverBack.x, coverBack.y = _W*.5, _H*.5
coverBack.alpha = 0
coverBack:toFront()

display.setDefault( "background", 0, 0, .06 )

startTextRect = display.newRoundedRect(startTextGroup,0,0,1100,500,9)
startTextRect:setFillColor(0.2,0.2,0.2,.2)
startTextRect.alpha = 0
startTextRect.x, startTextRect.y = _W*.5, _H*.55

timerImage = display.newImage("graphics/pointCounter.png",0,0)
timerImage.x, timerImage.y = _W*.47, 25

timerText = display.newText("0",0,0,"amiga4ever.ttf",24)
timerText.anchorX = 0
timerText.x, timerText.y = timerImage.x+timerImage.width*.57, 28


pressScreenText = display.newImage(startTextGroup,"graphics/startText.png",0,0)
pressScreenText.x, pressScreenText.y = _W*.5, _H*.3


infoScreentext = display.newImage(startTextGroup,"graphics/configField.png",0,0)
infoScreentext.xScale, infoScreentext.yScale = .7,.7
infoScreentext.x, infoScreentext.y = pressScreenText.x-200, pressScreenText.y + pressScreenText.height+200



secondInfoText = display.newImage(startTextGroup,"graphics/howtoplayField.png",0,0)
secondInfoText.xScale, secondInfoText.yScale = .7,.7
secondInfoText.x, secondInfoText.y = infoScreentext.x+500, infoScreentext.y+15
startTextGroup:toFront()

--[[
menuGroup = display.newGroup()
menuGroup:toFront()
menuGroup.x, menuGroup.y = -200, _H*.5
menu = display.newRect(menuGroup,0,0,400,600)
menu:setFillColor(0)
menu.alpha = 0.7
transition.to(menuGroup,{time=100, x=_W*.55, onComplete=function(e)
	transition.to(e,{time=100, x=_W*.5})
end})
]]--


particleList = {}

group = display.newGroup()
group:toBack()

fallList = {"graphics/polygon2.png","graphics/star.png","graphics/trail.png","graphics/triangle.png","graphics/square.png"}

-- [[ Difficulty ]] --
if level == 0 then
	holderField.alpha = 0
elseif level == 1 then
	holderField.alpha = .2
end


-- [[ Score counter ]] --
function counter()
	timerCount = timerCount+1
	timerText.text = timerCount
end




--[[ Resets all data in the game ]] --

function resetAll()
	audio.play(crash)
	transition.to(startTextGroup,{time=500,alpha=1})
	coverBack.alpha = 1
	transition.to(coverBack,{time=500, alpha=0})
	timer.cancel( gravityTimer )
	timer.cancel( scoreTimer )
	timer.cancel( particleTimer )
	gravityTimer = nil
	scoreTimer = nil
	particleTimer = nil
	gameRunning = true

	display.remove(moveMe)

	physics.pause()
	physics.isStarted = false
	
	gravity = 1
	timerCount = 0 
	
	particle.gravityScale = gravity

	transition.to(pressScreenText, {time=150, alpha=1})

	infoScreentext.alpha = 0
	secondInfoText.x = _W*.5

	timer.performWithDelay(4000,function()
		Runtime:addEventListener( "tap", startGame)
	end, 1)
end

-- [[ Here is where the magic starts, here is where you lose ]] --
local function onLocalCollision( self, event )

    if ( event.phase == "began" ) then
        if self.myName == "moveMe" and event.other.myName == "particle" then
        	resetAll() -- Calls function to reset the game
 	
        	transition.to(event.other,{time=1000,xScale=10,yScale=10,alpha=0, onComplete=function(e)
        		e:removeSelf()
        	end}) --On collision the object gets bigger
    end

    elseif ( event.phase == "ended" ) then
    	-- do nothing!
    end
end


-- [[ Touch function for the player ]] --
local function onTouch( event )
local t = event.target
local phase = event.phase
if "began" == phase then
    local parent = t.parent
    parent:insert( t )
    display.getCurrentStage():setFocus( t )

    t.isFocus = true

    t.x0 = event.x - t.x
    t.y0 = event.y - t.y
elseif t.isFocus then
    if "moved" == phase then
        t.x = event.x - t.x0
        t.y = event.y - t.y0
        if level == 1 then
        	if moveMe.x <= 485 or moveMe.x >= 795 or moveMe.y >= 600 or moveMe.y <= 120 then
        		resetAll()
       		end
       	elseif level == 0 then
       		-- izi m0de
       	elseif level == 2 then
       		
       		if moveMe.x <= 525 or moveMe.x >= 760 or moveMe.y >= 540 or moveMe.y <= 180 then
       			resetAll()
       		end
       	end

        trail = display.newImage("graphics/trail.png",0,0)
		trail.x, trail.y = t.x, t.y
		trail.xScale, trail.yScale = 1,.7
			transition.to(trail, {time=trailTime,rotation=180, xScale=.3, yScale=.3, alpha=0, onComplete=function(e)
				e:removeSelf()
				e = nil
			end})
    elseif "ended" == phase or "cancelled" == phase then
        display.getCurrentStage():setFocus( nil )
        t.isFocus = false
    end
end

return true
end

-- [[ Adds player to the game ]] --
function startGame()
	if physics.isStarted == false then
		audio.play(startGameSound)
		transition.to(startTextGroup, {time=200,alpha=0})
		
		moveMe = display.newImage("graphics/trail.png",-10,-10)

		scoreTimer = timer.performWithDelay(1000, counter, -1)

		physics.start()
		physics.setGravity(0,5)

		gameRunning = true
		gameStarted()

		moveMe.myName = "moveMe"
		moveMe.x, moveMe.y = _W*.5, _H*.5

		physics.addBody(moveMe,{radius=5})
		moveMe.bodyType = "kinematic"
		moveMe.collision = onLocalCollision
		moveMe:addEventListener( "collision" )
	end
	Runtime:removeEventListener( "tap", startGame)
	moveMe:addEventListener("touch", onTouch)
end

-- [[ Starts the enemies ]] --
function gameStarted()

		-- [[ Increases the gravity of the enemies ]] --
		function increase()
			gravity = gravity + 0.001
		end

		gravityTimer = timer.performWithDelay(500, increase, -1)

		-- [[ Creates the falling enemies ]] --
		function particles()
			--particle = display.newRect(0,0,10,10)
			particle = display.newImage(fallList[math.random(1,5)],0,0)
			particle.xScale, particle.yScale = 1, 1
			particle.x, particle.y = math.random(0,_W), -40
			particle.myName = "particle"
			particle:toBack()
			randomRed = math.random(0,1)/.75
			randomGreen = math.random(0,1)/.35
			randomBlue = math.random(0,1)/.15
			colorIt = math.random(0,1)
			
			if randomRed == 0 and randomGreen == 0 and randomBlue == 0 then
				-- do nothing
			else
				if colorIt == 1 then
					particle:setFillColor(randomRed, randomGreen, randomBlue, .5)
				end
				--
			end
			--table.insert(particleList, particle)
			physics.addBody(particle, {radius=6})
			moveMe.bodyType = "static"
			particle.gravityScale = gravity
			particle.collision = onLocalCollision
			particle:addEventListener( "collision" )
			transition.to(particle,{time=4000, xScale=.5, yScale=.5, rotation=math.random(-1080,1080), onComplete=function(e)
				display.remove(e)
				e = nil
			end})
		end
		if gameRunning == true then
			gameRunning = false
			particleTimer = timer.performWithDelay(10, particles, -1)
		end
end



Runtime:addEventListener( "tap", startGame)

--[[ Keyboard ]]--
local function onKeyReceived(event)
	if (system.getInfo("platformName") == "Win") then
		if (event.keyName == "f11") and (event.phase == "down") then
			if (native.getProperty("windowMode") == "fullscreen") then
				native.setProperty("windowMode", "normal")
			else
				native.setProperty("windowMode", "fullscreen")
			end
		end
		if (event.keyName == "escape") and (event.phase == "up") then
			native.requestExit()
		end
		if (event.keyName == config.trailtimeUp) and (event.phase == "up") then
			trailTime = trailTime + 100

		end
		if (event.keyName == config.pauseStars and (event.phase == "up")) then
			if starfieldTimerPaused == false then
				starfieldTimerPaused = true
				timer.pause(starFieldTimer)
			elseif starfieldTimerPaused == true then
				timer.resume(starFieldTimer)
				starfieldTimerPaused = false
			end
		end
		if (event.keyName == config.trailtimeDown) and (event.phase == "up") then
			if trailTime == 0 then
				--do nothing
			else 
				trailTime = trailTime - 100
			end
		end
		if (event.keyName == config.volumeDown) and (event.phase == "up") then
			if volume <= 0.1 then
				-- do nothing
			else
				volume = volume-.1
				audio.setVolume( volume )
				audio.play(volumePop)
				print(volume) 
			end
		end
		if (event.keyName == config.volumeUp) and (event.phase == "up") then
			if volume >= 1.5 then
				-- do nothing
			else
				volume = volume+.1
				audio.setVolume(volume)
				audio.play(volumePop)
				print(volume)
			end
		end
		if (event.keyName == config.music) and (event.phase == "up") then
			if musicOn == true then
				musicOn = false
				audio.setVolume(0,{channel=2})
			else
				musicOn = true
				audio.setVolume(volume, {channel=2})
				print("Music volume: "..volume)
			end
		end
		if gameRunning == true then
			if (event.keyName == "1") and (event.phase == "up") then
				level = 0
				transition.to(holderField, {time=150, xScale=0.1, yScale=0.1, alpha=0})
			end
			if (event.keyName == "2") and (event.phase == "up") then
				level = 1
				transition.to(holderField, {time=150, alpha=.2, xScale=.8, yScale=.8})
			end
			if (event.keyName == "3") and (event.phase == "up") then
				level = 2
				transition.to(holderField, {time=150, xScale=.6, yScale=.6, alpha=.2})
			end
		end
	end
end
Runtime:addEventListener("key", onKeyReceived)

--[[ Background starfield ]]--
function starField(e)
	for i=1,15 do
		x = math.random(0,display.contentWidth)
		y = math.random(0,display.contentHeight)
		size = math.random(0,5)
		smaller = size-size+.001

		brick = display.newImage(fallList[math.random(1,3)],x,y)
		brick.xScale, brick.yScale = .3,.3
		brick:setFillColor( math.random(0,1), math.random(0,1), math.random(0,1), 0.78 )
		brick:toBack()

		starTrans = transition.to(brick,{time=500,x=display.contentWidth*.5,y=display.contentHeight*.5,xScale=smaller,yScale=smaller,alpha=0,onComplete=function(e)
			display.remove(e)
			x = nil
			y = nil
			size = nil
			smaller = nil
			e:removeSelf()
			e = nil
		end})
	end
end


starFieldTimer = timer.performWithDelay(300,starField,-1)

-- [[ Debug code ]] --
if config.debug == nil then
	--do nothing
else
	if config.debug == "true" then

		memoryText = display.newText("",0,0,native.systemFont,24)
		memoryText.x, memoryText.y = _W*.3, _H*.3

		memoryText2 = display.newText("",0,0,native.systemFont,24)
		memoryText2.x, memoryText2.y = _W*.3, _H*.4

		local printMemUsage = function()  
		    local memUsed = (collectgarbage("count"))
		    local texUsed = system.getInfo( "textureMemoryUsed" ) / 1048576 -- Reported in Bytes
		    memoryText2.text = "System Memory: "..memUsed
		    memoryText.text = "Texture Memory: "..texUsed
		end
			timer.performWithDelay(500,printMemUsage,-1)

		local myText = display.newText(display.fps, display.contentWidth - 30, display.contentHeight - 30, native.systemFont, 16)
		 
		local function updateText()
		    myText.txt = display.fps
		end
		 
		Runtime:addEventListener("enterFrame", updateText)
		elseif config.debug == "false" then
			--do nothing
		else
			--do nothing
	end
end