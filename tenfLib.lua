-----------------------------------------------------------------------------------------
--
-- Samling av återanvändbara funktioner
-- tenfLib.lua
-- 10Fingers
--
-- Uppdatering #8: 2012-11-15 Marcus Thunström
-- Uppdatering #7: 2012-08-30 Tommy Lindh
-- Uppdatering #6: 2012-08-29 Marcus Thunström
-- Uppdatering #5: 2012-08-14 Tommy Lindh
-- Uppdatering #4: 2012-08-02 Tommy Lindh
-- Uppdatering #3: 2012-08-01 Marcus Thunström
-- Uppdatering #2: 2012-07-24 Alexander Alesand
-- Uppdatering #1: 2012-07-?? Marcus Thunström
--
-----------------------------------------------------------------------------------------
--
-- Om du vill lägga till en funktion:
--  1. Deklarera funktionen som local högst upp på sidan
--  2. Definiera funktionen bland de andra funktionerna
--  3. Lägg till din funktions namn i tabellen som returneras längst ner på sidan
--  4. Lägg till datum och ditt namn i uppdateringslistan här ovan
--  5. Commita till alla sprintar
--
-----------------------------------------------------------------------------------------






local addSelfRemovingEventListener, removeEventListeners
local calculate, compare, executeMathStatement
local changeGroup
local clamp
local copyFile
local enableFocusOnTouch, disableFocusOnTouch
local enableTouchPhaseEvents, disableTouchPhaseEvents
local extractRandom
local fileExists, getMissingFiles
local fitObjectInArea
local fitTextInArea
local foreach
local getCsvTable
local getKeys, getUniqueValues, getValues
local getLetterOffset
local getLineHeight
local getRandom
local getScaleFactor
local gotoCurrentScene
local indexOf, indexOfChild, indexWith, indicesWith, indicesContaining
local isVowel, isConsonant
local jsonLoad, jsonSave
local latLonDist
local loadSounds, unloadSounds
local localToLocal
local midPoint
local moduleCreate, moduleExists, moduleUnload, requireNew
local newCaret
local newFormattedText
local newGroup
local newLetterSequence
local newMultiLineText
local newOutlineLetterSequence
local newOutlineText
local newSpriteMultiImageSet
local numberSequence
local numberToString
local orderObjects
local pointDist
local pointInRect, rectIntersection
local predefArgsFunc
local printObj
local randomize
local randomWithSparsity
local range
local removeAllChildren
local removeTableItem
local runTimeSequence
local sceneRemoveAfterExit
local setAttr
local setTableValue, getTableValue
local settingsFileLoad, settingsFileSave
local shuffleList
local splitEquation
local sqlBool, sqlInt, sqlStr
local stopPropagation
local stringCount
local stringPad
local stringSplit
local stringToLower, stringToUpper
local tableCopy
local tableDiff
local tableFlatten
local tableGetAttr
local tableInsertUnique
local tableLimitLength
local tableMerge, tableMergeUnique
local tableSum
local tableCount
local toFileName
local wordwrap
local xmlGetChild
local xor







-- Lägger till en eventlistener som bara exekveras högst en gång
function addSelfRemovingEventListener(object, eventName, handler)
	local function localHandler(e)
		object:removeEventListener(eventName, localHandler)
		handler(e)
	end
	object:addEventListener(eventName, localHandler)
end



-- Tar bort alla eventlisteners på ett objekt
-- Uppdaterad: 2012-11-15 09:30 av Marcus Thunström
function removeEventListeners(obj, eventName, handler)
	if not obj._functionListeners then return end
	if eventName then
		for _, handler in ipairs(obj._functionListeners[eventName]) do
			obj:removeEventListener(eventName, handler)
		end
	else
		for eventName, handlerList in pairs(obj._functionListeners) do
			for _, handler in ipairs(handlerList) do
				obj:removeEventListener(eventName, handler)
			end
		end
	end
end







-- Utför en simpel uträkning och returnerar resultatet
-- Exempel:
--   print(calculate(4, "+", 3)) -- 7
--   print(calculate(9, "/", 2)) -- 4.5
--   print(calculate(11, "foo", 14)) -- nil
-- Uppdaterad: 2012-04-14 11:00 av Marcus Thunström
function calculate(nr1, op, nr2)
	if op == '+' then return nr1+nr2
	elseif op == '-' then return nr1-nr2
	elseif op == '*' then return nr1*nr2
	elseif op == '/' then return nr1/nr2
	elseif op == '%' then return nr1%nr2
	elseif op == '^' then return nr1^nr2
	else return nil end -- error
end



-- Jämför två tal
-- Exempel: compare(2, 5, "<")  -- true
-- Uppdaterad: 2012-09-24 17:20 av Marcus Thunström
function compare(a, b, method)
	method = method or '='
	if     method == '='    then return a == b
	elseif method == '~='   then return a ~= b
	elseif method == '<'    then return a < b
	elseif method == '>'    then return a > b
	elseif method == '<='   then return a <= b
	elseif method == '>='   then return a >= b
	elseif method == '!='   then return a ~= b
	elseif method == '<>'   then return a < b or a > b
	elseif method == 'type' then return type(a) == type(b)
	end
	return nil
end



-- Returnerar värdet av ett matematiskt påstående
-- Variabler och funktioner kan användas i påståendet (Se exempel)
--[[
	Exempel:

		executeMathStatement("1+2")  -- 3
		executeMathStatement("1+x*y", {x=2, y=3})  -- (1+2)*3  = 9

		local funcs = {}
		funcs.randOne = function(currentNumber, operator)
			return false, math.random(3, 5) -- returnerat värde läggs på det gamla värdet
		end
		executeMathStatement("5+randOne", funcs)  -- 5+math.random(3,5)  = [8..10]

		funcs.randTwo = function(currentNumber, operator)
			return true, math.random(3, 5) -- returnerat värde ersätter det gamla värdet
		end
		executeMathStatement("5+randTwo", funcs)  -- math.random(3,5)  = [3..5]

		funcs.mod = function(currentNumber, operator)
			return nil, nil, "%" -- returnera ny operator (men inget nytt värde)
		end
		executeMathStatement("5mod3", funcs)  -- 5%3  = 2

]]
-- Uppdaterad: 2012-09-05 18:05 av Marcus Thunström
function executeMathStatement(eq, funcs)
	local nr, op, funcs = 0, '+', funcs or {}
	for _, part in ipairs(splitEquation(eq)) do
		local func = funcs[part]
		if part == ' ' then
			--void
		elseif func then
			if type(func) == 'function' then
				local absolute, newNr, newOp = funcs[part](nr, op)
				if newOp then op = newOp end
				if absolute then nr = newNr elseif newNr then nr = calculate(nr, op, newNr) end
			else
				nr = calculate(nr, op, func)
			end
		elseif part=='+' or part=='-' or part=='*' or part=='/' or part=='%' or part=='^' then
			op = part
		elseif funcs._nr then
			nr = calculate(nr, op, funcs._nr(tonumber(part)))
		else
			nr = calculate(nr, op, tonumber(part))
		end
	end
	return nr
end







--Flyttar ett object från en grupp till en annan.
--Objektet behåller sin plats på skärmen.

-- Uppdaterad: 2012-08-01 19:50 av Marcus Thunström
function changeGroup(object, group)
	local x, y = localToLocal(object, 0, 0, group)
	group:insert(object)
	object.xOrigin, object.yOrigin = x, y
end







-- Begränsar ett värde inom ett intervall
function clamp(value, min, max)
	if value <= min then
		return min
	elseif value >= max then
		return max
	else 
		return value
	end
end







-- Kopierar en fil till en annan fil
function copyFile( copyFromPath, pasteToPath )
	local reader = io.open( copyFromPath, "r" )
	if not reader then
		print ("WARNING: copyFromPath är inte korrekt")
		return false
	end
	local contents = reader:read( "*a" )
	io.close( reader )

	local writer = io.open( pasteToPath, "w" )
	if not writer then
		print ("WARNING: pasteToPath är inte korrekt")
		return false
	end
	writer:write( contents )
	io.close( writer )
	return true
end







--[[

	enableFocusOnTouch()
	disableFocusOnTouch()
		Gör att ett objekt får focus när man trycker på det och förlorar focus när man släpper.

	Beskrivning:
		enableFocusOnTouch( object )
		 * object: det displayObject som ska ha denna funktionalitet.
		disableFocusOnTouch( object )
		 * object: det displayObject som ska sluta ha denna funktionalitet.

	Event:
		focusBegan
			Exekveras när objektet får focus.
			Har samma parametrar som touch-event, förrutom 'phase'.
		focusMoved
			Exekveras när event.x eller event.y ändras.
			Har samma parametrar som touch-event, förrutom 'phase'.
			event.over är en boolean som säger om event.x och event.y är inom objektets contentBounds.
		focusEnded
			Exekveras när objektet förlorar focus.
			Har samma parametrar som touch-event, förrutom 'phase'.
			event.over är en boolean som säger om event.x och event.y är inom objektets contentBounds.

	Exempel:
		local img = newImage("foo.png")
		enableFocusOnTouch(img)
		img:addEventListener("focusEnded", function(event)
			if event.over then print("Bilden fungerar nu precis som en widget-knapp.") end
		end)

]]
-- Uppdaterad: 2012-10-19 10:50 av Marcus Thunström
do

	local focusKey = {}

	local touchListener

	function enableFocusOnTouch(obj)
		obj:addEventListener('touch', touchListener)
		return obj
	end

	function disableFocusOnTouch(obj)
		obj:removeEventListener('touch', touchListener)
		return obj
	end

	function touchListener(e)
		local obj, p = e.target, e.phase
		--print "eggroll"
		if p == 'began' then
			display.getCurrentStage():setFocus(obj)
			obj[focusKey] = true
			e.name, e.phase = 'focusBegan', nil
			obj:dispatchEvent(e)
			return true
		elseif obj[focusKey] then
			if p == 'moved' then
				local bounds = obj.contentBounds
				e.name, e.phase = 'focusMoved', nil
				e.over = pointInRect(e.x, e.y, bounds.xMin, bounds.yMin, bounds.xMax-bounds.xMin, bounds.yMax-bounds.yMin)
				obj:dispatchEvent(e)
			else
				display.getCurrentStage():setFocus(nil)
				obj[focusKey] = nil
				local bounds = obj.contentBounds
				e.name, e.phase = 'focusEnded', nil
				e.over = pointInRect(e.x, e.y, bounds.xMin, bounds.yMin, bounds.xMax-bounds.xMin, bounds.yMax-bounds.yMin)
				obj:dispatchEvent(e)
			end
			return true
		end
	end

end



--[[

	enableTouchPhaseEvents()
	disableTouchPhaseEvents()
		Lägger till ytterligare typer av touch event som inte använder sig av phase-paramater.

	Beskrivning:
		enableTouchPhaseEvents( object )
		 * object: det displayObject som ska dispatcha dessa event.
		disableTouchPhaseEvents( object )
		 * object: det displayObject som ska sluta dispatcha dessa event.

	Event:
		touchBegan
			Exekveras när touch-event avfyras och event.phase är "began".
			Har samma parametrar som touch-event, förrutom 'phase'.
		touchMoved
			Exekveras när touch-event avfyras och event.phase är "moved".
			Har samma parametrar som touch-event, förrutom 'phase'.
		touchEnded
			Exekveras när touch-event avfyras och event.phase är "ended" eller "cancelled".
			Har samma parametrar som touch-event, förrutom 'phase'.

	Exempel:
		local img = newImage("foo.png")
		enableFocusOnTouch(img)
		img:addEventListener("focusEnded", function(event)
			if event.over then print("Bilden fungerar nu precis som en widget-knapp.") end
		end)

]]
-- Uppdaterad: 2012-10-19 10:55 av Marcus Thunström
do

	local phaseEventNames = {began='touchBegan', moved='touchMoved'}
	local standardPhaseEventName = 'touchEnded'

	local touchListener

	function enableTouchPhaseEvents(obj)
		obj:addEventListener('touch', touchListener)
		return obj
	end

	function disableTouchPhaseEvents(obj)
		obj:removeEventListener('touch', touchListener)
		return obj
	end

	function touchListener(e)
		e.name = (phaseEventNames[e.phase] or standardPhaseEventName)
		e.phase = nil
		return e.target:dispatchEvent(e)
	end

end







-- Tar bort 'amount' stycken objekt ur en array och returnerar de borttagna objekten
-- Exempel:
--   local allNumbers = {1, 2, 3, 5, 8}
--   local extractedNumbers = extractRandom(allNumbers, 2)
--   -- Om nu extractedNumbers={3,8} så är allNumbers={1,2,5}
--   -- Om istället extractedNumbers={5,1} så är allNumbers={2,3,8}
-- Uppdaterad: 2012-04-14 11:00 av Marcus Thunström
function extractRandom(t, amount)
	local randT = {}
	for i = 1, amount do
		table.insert(randT, table.remove(t, math.random(1, #t)))
	end
	return randT
end







-- Kollar om en fil existerar i ett directory (Åäö konverteras automatiskt till aa, ae och oe)
-- Exempel:
--   print(fileExists("filSomInteFinns.png", system.TemporaryDirectory))  -- false
-- Uppdaterad: 2012-04-23 16:45 av Marcus Thunström
function fileExists(file, dir)
	local path = system.pathForFile(toFileName(file), dir or system.DocumentsDirectory)
	if not path then return false end
	local handle = io.open(path, 'r')
	if handle then
		handle:close()
		return true
	else
		return false
	end
end



--[[

	getMissingFiles()
		Kollar vilka filer som inte existerar.
		Åäö konverteras automatiskt till aa, ae och oe.
		Notera att funktionen inte fungerar som väntat för PNG-bilder i Resources-mappen (p.g.a. pngcrush).

	Beskrivning:
		missingFileArray = getMissingFiles( [path,] fileNames, [extension, [directory] ] )
		 * path: vägen till filen. (Default="")
		 * fileNames: array med filnamn.
		 * extension: filändelse på filerna. (Default="")
		 * directory: vilket directory filerna ligger i. (Default=system.DocumentsDirectory)
		 > Returnerar: en array med filnamnen på de filer som inte finns.

	Exempel:
		local soundNames = {"hej", "räka"}
		local missingSounds = getMissingFiles("sounds/", soundNames, ".mp3")
		print("Ljud som fattas: "..unpack(missingSounds))

]]
-- Uppdaterad: 2012-10-16 17:40 av Marcus Thunström
function getMissingFiles(path, fileNames, ext, dir)
	if type(path) == 'table' then path, fileNames, ext, dir = nil, path, fileNames, ext end
	path, ext = path or '', ext or ''
	local missing = {}
	for _, fileName in ipairs(fileNames) do
		if not fileExists(path..fileName..ext, dir) then missing[#missing+1] = fileName end
	end
	return missing
end







-- Skalar ner ett displayobjekt så det passar i en ruta om objektet är för stort
-- Kan även skala upp för små objekt om 'alwaysScale' är satt
-- Uppdaterad: 2012-07-23 16:35 av Marcus Thunström
function fitObjectInArea(obj, width, height, alwaysScale)
	local objW, objH = obj.width, obj.height
	if alwaysScale or objW > width or objH > height then
		local scale = math.min(width/objW, height/objH)
		obj.xScale, obj.yScale = scale, scale
	end
	return obj
end







-- Förminskar textstorleken tills textobjektet får plats inom en viss bredd
-- Uppdaterad: 2012-05-09 13:45 av Marcus Thunström
function fitTextInArea(txtObj, maxWidth)
	while txtObj.contentWidth > maxWidth do 
		txtObj.size = txtObj.size-2
	end
	return txtObj
end







-- Kör en funktion på alla objekt i en array eller grupp
-- Uppdaterad: 2012-09-13 15:35 av Marcus Thunström
function foreach(tableOrGroup, callback, reverse)
	local from, to, step = 1, tableOrGroup.numChildren or #tableOrGroup, 1
	if reverse then from, to, step = to, from, -1 end
	for i = from, to, step do
		if callback(tableOrGroup[i], i) then break end
	end
end







-- Konverterar en fil innehållande CSV-data till en array med tables
-- Första raden i CSV-filen används som kolumn/attributnamn
--   getCsvTable(fileName, [dir,] [colNames])
-- Uppdaterad: 2012-08-28 12:00 av Marcus Thunström
function getCsvTable(fileName, dir, colNames)
	if type(dir) ~= 'userdata' then dir, colNames = nil, dir end

	local path = system.pathForFile(fileName, dir or system.ResourceDirectory)
	if not path then return nil end
	local file = io.open(path, 'r')

	local contents = file:read('*a')
	io.close(file)

	local lines = {}

	local values = {}
	local valueStart = 1
	local isInQuote = false
	local isQuote = false
	local lastChar = nil
	for i = 1, #contents+1 do
		local char = contents:sub(i, i)
		isQuote = (char == '"')
		if isInQuote then

			if isQuote then
				isInQuote = false
				isQuote = true
			elseif char == '' then
				error('EOF reached - missing a quote sign in '..fileName, 2)
			end

		else--if not isInQuote then

			if isQuote then
				isInQuote = true
			elseif (char == '\n' or char == '') and lastChar == '\n' then
				valueStart = i+1
			elseif char == ',' or char == '\n' or char == '' then
				local valueEnd = i-1
				if lastChar == '"' then valueStart = valueStart+1; valueEnd = valueEnd-1 end
				if valueEnd < valueStart then
					values[#values+1] = ''
				else
					values[#values+1] = contents:sub(valueStart, valueEnd):gsub('""', '"')
				end
				valueStart = i+1
				if char ~= ',' then
					lines[#lines+1] = values
					values = {}
				end
			end

		end
		lastChar = char
	end--for

	if #lines < 2 then
		return {}
	else
		local cols = lines[1]
		local t = {}
		for i = 2, #lines do
			local line = lines[i]
			local row = {}
			if colNames then
				for i, col in ipairs(cols) do
					local k = colNames[col]
					if k then row[k] = line[i] or '' end
				end
			else
				for i, col in ipairs(cols) do row[col] = line[i] or '' end
			end
			t[#t+1] = row
		end
		return t
	end

end







-- Listar alla keys som används i en tabell
-- Uppdaterad 2012-08-16 13:50 av Marcus Thunström
function getKeys(t)
	local keys = {}
	for k, _ in pairs(t) do keys[#keys+1] = k end
	return keys
end

-- Listar alla unika värden i en tabell
function getUniqueValues(t)
	local values = {}
	for _, v in pairs(t) do
		values[v] = true
	end
	return getKeys(values)
end

-- Listar alla värden som finns i en tabell eller alla DisplayObjects i en grupp
-- Du kan specifiera vilka index/keys vars värde ska returneras
-- Uppdaterad 2012-10-24 14:45 av Marcus Thunström
function getValues(t, keys)
	local values = {}
	if keys then
		for i, k in ipairs(keys) do
			values[i] = t[k]
		end
	else
		if t.numChildren then
			for i = 1, t.numChildren do values[i] = t[i] end
		else
			for _, v in pairs(t) do values[#values+1] = v end
		end
	end
	return values
end







-- Beräknar en bokstavs x-position i ett textobjekt
-- Uppdaterad 2012-07-23 19:15 av Marcus Thunström
function getLetterOffset(textObject, letter, fontName)
	local referenceText = textObject.text:sub(1, (textObject.text:find(letter))-1, 1, true)
	local referenceTextObject = display.newText(referenceText, 0, 0, fontName, textObject.size)
	local width1 = referenceTextObject.width
	referenceTextObject.text = referenceTextObject.text..letter
	local width2 = referenceTextObject.width
	local offset = (width1+width2)/2
	referenceTextObject:removeSelf()
	return offset
end







-- Returnerar radhöjden för en text
-- Uppdaterad 2012-11-14 10:30 av Marcus Thunström
do

	local _W = display.contentWidth
	local newText, remove = display.newText, display.remove

	function getLineHeight(fontName, fontSize, singleRow)
		local refTxtObj = newText('', 0, 0, _W, 0, fontName, fontSize)
		local h = refTxtObj.height
		local lineHeight
		if singleRow then
			lineHeight = h
		else
			refTxtObj.text = '\n'
			lineHeight = refTxtObj.height-h
		end
		remove(refTxtObj)
		return lineHeight
	end

end







-- Returnerar ett slumpmässigt objekt från en array eller en grupp
-- Ett intervall kan anges
-- Uppdaterad 2012-09-12 15:00 av Marcus Thunström
function getRandom(t, from, to)
	return t[math.random(from or 1, to or t.numChildren or #t)]
end







-- Returnerar skalfaktorn för text i retina-upplösning
-- alltså 2 för retina och 1 för "vanlig"
-- Uppdaterad 2012-09-25 15:00 av Tommy Lindh
function getScaleFactor()
    local deviceWidth = ( display.contentWidth - (display.screenOriginX * 2) ) / display.contentScaleX
    return math.floor(deviceWidth / display.contentWidth)
end







-- Uppdaterad: innan 2012-07-16 av Marcus Thunström
--[[
function gotoCurrentScene(options)

	local storyboard = require('storyboard')
	local curSceneName = storyboard.getCurrentSceneName()

	local overlay = display.captureScreen()

	local tmpSceneName = 'temp'..math.random(10000, 99999)
	local tmpScene = storyboard.newScene(tmpSceneName)

	function tmpScene:createScene()
		self.view:insert(overlay)
		overlay.x, overlay.y = display.contentWidth/2, display.contentHeight/2
	end
	function tmpScene:enterScene()
		storyboard.gotoScene(curSceneName, options)
	end
	function tmpScene:didExitScene()
		storyboard.removeScene(tmpSceneName)
	end

	tmpScene:addEventListener('createScene', tmpScene)
	tmpScene:addEventListener('enterScene', tmpScene)
	tmpScene:addEventListener('didExitScene', tmpScene)

	storyboard.gotoScene(tmpSceneName)

end



 ]]--



--[[ Notera: ej relevant längre!
-- Buggfix: delvis svart skärm när man går från en scen till samma scen
-- Uppdaterad: 2012-05-09 13:45 av Marcus Thunström
function gotoSceneSlideEffectFix(sceneToFollow, time, offsetX, offsetY)

	tabBar.isVisible = false
	local overlay = display.captureScreen()
	tabBar.isVisible = true

	if sceneToFollow then overlay:toBack() else overlay.isVisible = false end
	overlay:setReferencePoint(display.CenterReferencePoint)

	local handle = {}

	local function efHandle()
		if not sceneToFollow then return end
		overlay.x = sceneToFollow.view.x+(offsetX or 0)
		overlay.y = sceneToFollow.view.y+(offsetY or 0)
	end

	Runtime:addEventListener('enterFrame', efHandle)

	timer.performWithDelay(time, function()
		overlay:removeSelf()
		Runtime:removeEventListener('enterFrame', efHandle)
		handle.setScene = nil
	end)

	function handle:setScene(scene)
		sceneToFollow = scene
		overlay.isVisible = not not scene
		overlay:toBack()
	end

	return handle

end
--]]







-- Returnerar vilket index ett värde har i en array (precis som table.indexOf)
-- Funktionen fungerar även på displaygrupper
--[[
	Beskrivning:
		index = indexOf(table, value, returnLast)
			table: arrayen att söka igenom
			value: värdet att söka efter
			returnLast: om satt, returnerar sista förekomsten av värdet istället för första
	Exempel:
		t = {"A", "B", "C", "B"}
		indexOf(t, "B")  -- 2
		indexOf(t, "foo")  -- nil
		indexOf(t, "B", true)  -- 4
]]
-- Uppdaterad: 2012-08-16 08:50 av Marcus Thunström
function indexOf(t, obj, returnLast, startIndex)
	startIndex = startIndex or 1
	local from, to, step = startIndex, t.numChildren or #t, startIndex
	if returnLast then from, to, step = to, from, -1 end
	for i = from, to, step do
		if t[i] == obj then return i end
	end
	return nil
end



-- Returnerar vilken position 'child' har i en/sin parent
-- Ger tillbaks nil om 'child' inte finns i 'parent' (om 'parent' har angetts)
-- Uppdaterad: 2012-05-07 14:00 av Marcus Thunström
function indexOfChild(child, parent)
	parent = parent or child.parent
	for i = 1, parent.numChildren do
		if parent[i] == child then return i end
	end
	return nil
end



-- Kollar upp vilket objekt i en array vars specifierad attribut innehåller ett värde
-- Funktionen fungerar även på displaygrupper
--[[
	Beskrivning:
		index = indexOf(table, attr, value, returnLast, invert)
			table: arrayen att söka igenom
			attr: vilket attribut som ska kollas på objekten
			value: värdet att söka efter
			returnLast: om satt, returnerar sista förekomsten av värdet istället för första
			invert: om satt, returnerar alla förekomster som INTE innehåller värdet
	Exempel:
		t = {
			{name = "foo"},
			{name = "bar"},
			{name = "bat"}
			{name = "foo"},
		}
		indexWith(t, "name", "bar")  -- 2
		indexWith(t, "name", "foobar")  -- nil
		indexWith(t, "name", "foo", true)  -- 4
		indexWith(t, "name", "foo", false, true)  -- 2
]]
-- Uppdaterad: 2012-08-16 09:50 av Marcus Thunström
function indexWith(t, attr, obj, returnLast, invert, startIndex)
	invert = not invert
	local from, to, step
	if returnLast then
		from, to, step = startIndex or t.numChildren or #t, 1, -1
	else
		from, to, step = startIndex or 1, t.numChildren or #t, 1
	end
	if attr then
		for i = from, to, step do
			if (t[i][attr] == obj) == invert then return i, t[i] end
		end
	else -- obj = key/value pairs
		for i = from, to, step do
			local match = true
			for k, v in pairs(obj) do
				if t[i][k] ~= v then match=false; break end
			end
			if match == invert then return i, t[i] end
		end
	end
	return nil, nil
end



-- Kollar upp vilka objekt i arrayen 't' vars attribut 'attr' innehåller 'obj'
-- Sätt invert för 
-- Funktionen fungerar även på displaygrupper
-- Exempel:
--   t = {
--     {name = "foo"},
--     {name = "bar"},
--     {name = "foo"},
--     {name = "bat"}
--   }
--   indicesWith(t, "name", "foo")  -- {1, 3}
--   indicesWith(t, "name", "foobar")  -- {}
--   indicesWith(t, "name", "bat", true)  -- {1, 2, 3}
-- Uppdaterad: 2012-08-28 13:10 av Marcus Thunström
function indicesWith(t, attr, obj, invert)
	invert = not invert
	local indices, objects = {}, {}
	if attr then
		for i = 1, t.numChildren or #t do
			if (t[i][attr] == obj) == invert then indices[#indices+1]=i; objects[#objects+1]=t[i] end
		end
	else -- obj = key/value pairs
		for i = 1, t.numChildren or #t do
			local match = true
			for k, v in pairs(obj) do
				if t[i][k] ~= v then match=false; break end
			end
			if match == invert then indices[#indices+1]=i; objects[#objects+1]=t[i] end
		end
	end
	return indices, objects
end



--[[

	indicesContaining()
		Kollar upp vilka strängar i en array som innehåller en söksträng.
		Det går att ange index var sökningen ska ske i strängarna i arrayen.

	Beskrivning:
		indexArray, stringArray = indicesContaining( array, search [, searchIndex [, invert ] ] )
		 * array: array med strängar att söka igenom.
		 * search: sträng att söka efter.
		 * searchIndex: Var i strängarna i arrayen som matchningen ska ske. (Default=nil)
		 * invert: om index till strängar som INTE matchar ska returneras. (Default=false)
		 > Returnerar: en array med index och en array med de matchande strängarna.

	Exempel:
		local t = {
			"bar",
			"foo",
			"foobar",
			"bat",
		}
		indicesContaining(t, "ba")  -- {1, 3, 4}, {"bar", "foobar", "bat"}
		indicesContaining(t, "ba", 1)  -- {1, 4}, {"bar", "bat"}
		indicesContaining(t, "ba", 1, true)  -- {2, 3}, {"foo", "foobar"}

]]
-- Uppdaterad: 2012-10-03 11:40 av Marcus Thunström
function indicesContaining(t, search, searchIndex, invert)
	invert = not invert
	local indices, strings = {}, {}
	if searchIndex then
		local endIndex = searchIndex+#search-1
		for i, str in ipairs(t) do
			if (str:sub(searchIndex, endIndex) == search) == invert then indices[#indices+1]=i; strings[#strings+1]=str end
		end
	else
		for i, str in ipairs(t) do
			if invert ~= not str:find(search, 1, true) then indices[#indices+1]=i; strings[#strings+1]=str end
		end
	end
	return indices, strings
end







do

	local vowels = {'a', 'o', 'u', 'å', 'e', 'i', 'y', 'ä', 'ö'}

	function isVowel(letter)
		return not isConsonant(letter)
	end

	function isConsonant(letter)
		return not table.indexOf(vowels, stringToLower(letter))
	end

end







-- Ladda data från en JSON-fil
-- jsonLoad(fileName, dir)
function jsonLoad(fileName, dir)
	local path = system.pathForFile(fileName, dir or system.DocumentsDirectory)
	if not path then return nil end
	local file = io.open(path, 'r')
	if not file then return nil end
	local data = require('json').decode(file:read('*a'))
	io.close(file)
	return data
end

-- Spara data till en JSON-fil
-- jsonSave(fileName, [dir,] data)
function jsonSave(fileName, dir, data)
	if type(dir) ~= 'userdata' then dir, data = nil, dir end
	local path = system.pathForFile(fileName, dir or system.DocumentsDirectory)
	if path then 
		local file = io.open(path, 'w+')
		if file then 
			file:write(require('json').encode(data))
			io.close(file) 
			return true
		end 
	end 
end







-- Räknar ut avståndet mellan två latitud/longitud-koordinater
-- Källa: http://www.movable-type.co.uk/scripts/latlong.html
function latLonDist(lat1, lon1, lat2, lon2)

	local R = 6371 -- km
	local dLat = math.rad(lat2-lat1)
	local dLon = math.rad(lon2-lon1)
	local lat1 = math.rad(lat1)
	local lat2 = math.rad(lat2)

	local a = math.sin(dLat/2) * math.sin(dLat/2) +
		math.sin(dLon/2) * math.sin(dLon/2) * math.cos(lat1) * math.cos(lat2) 
	local c = 2 * math.atan2(math.sqrt(a), math.sqrt(1-a)) 
	local d = R * c

	return d

end







-- Laddar flera ljud in i en tabell
--[[
	Beskrivning:
		soundTable = loadSounds(t, [pathPrefix, pathSuffix])
			t: tabell innehållande ljudfilsnamn (se exempel)
			pathPrefix: sträng som läggs till före ljudfilsnamnet när ljudet laddas
			pathSuffix: sträng som läggs till efter ljudfilsnamnet när ljudet laddas (Default = ".mp3")

	Exempel 1:
		local t = {
			["foo"] = 'audio/foo_music.mp3',
			["bar"] = 'audio/bar_sound.mp3',
		}
		local sounds = loadSounds(t)
		audio.play(sounds['foo'])  -- spelar upp 'audio/foo_music.mp3'

	Exempel 2:
		local t = {"foo", "bär"}
		local sounds = loadSounds(t, "audio/", ".mp3")
		audio.play(sounds["bär"])  -- spelar upp 'audio/baer.mp3'
]]
-- Uppdaterad: 2012-09-04 11:15 av Marcus Thunström
function loadSounds(t, pre, suf)
	pre, suf = pre or '', suf or '.mp3'
	local sounds = {}
	if type((pairs(t)(t))) == 'number' then
		for _, name in ipairs(t) do sounds[name] = audio.loadSound(pre..toFileName(name)..suf) end
	else
		for name, path in pairs(t) do sounds[name] = audio.loadSound(pre..toFileName(path)..suf) end
	end
	return sounds
end



-- Kör audio.dispose() på alla ljud i en array eller tabell
-- Uppdaterad: 2012-08-27 09:15 av Marcus Thunström
function unloadSounds(t)
	for _, h in pairs(t) do audio.dispose(h) end
end







-- Returnerar ett displayobjekts koordinater i ett annat objekts koordinatsystem
-- Uppdaterad: 2012-07-17 15:50 av Marcus Thunström
function localToLocal(obj, objX, objY, refSpace)
	local contentX, contentY = obj:localToContent(objX, objY)
	return refSpace:contentToLocal(contentX, contentY)
end







-- Returnerar coordinaten för punkten mitt mellan två punkter
-- Uppdaterad: 2012-08-16 13:20 av Marcus Thunström
function midPoint(x1, x2, y1, y2)
	x1, x2, y1, y2 = x1 or 0, x2 or 0, y1 or 0, y2 or 0
	return x1+(x2-x1)/2, y1+(y2-y1)/2
end







-- Skapar angiven modul (om den inte redan existerar)
-- Sätt 'overwrite' till true för att skriva över existerande modul
-- Uppdaterad: 2012-08-31 09:00 av Marcus Thunström
function moduleCreate(name, content, overwrite)
	if not (overwrite and package.loaded[name]) then package.loaded[name] = content end
	return require(name)
end

-- Kollar om angiven modul existerar
-- Uppdaterad: 2012-08-31 09:00 av Marcus Thunström
function moduleExists(name)
	return not not package.loaded[name]
end

-- Tar bort angiven modul
-- Uppdaterad: 2012-08-31 09:00 av Marcus Thunström
function moduleUnload(name)
	package.loaded[name] = nil
end

-- Tar bort angiven modulen om den finns och returnerar en nyladdad modul
-- Uppdaterad: 2012-08-31 09:00 av Marcus Thunström
function requireNew(name)
	package.loaded[name] = nil
	return require(name)
end







-- Skapar en textmarkör som blinkar
-- Uppdaterad: 2012-10-19 14:25 av Marcus Thunström
function newCaret(parent, fontName, fontSize, color, x, y)
	local caret = setAttr(display.newText('|', 0, 0, fontName, fontSize), {x=x, y=y}, {tc=color})
	if parent then parent:insert(caret) end
	local timerId
	timerId = timer.performWithDelay(700, function()
		if not caret.parent then timer.cancel(timerId); return end
		caret.isVisible = not caret.isVisible
	end, 0)
	return caret
end







--[[

	newFormattedText()
		Skapar en grupp med textobjekt med olika formatering.

	Beskrivning:
		newFormattedText( [parent,] textData [, wrapWidth], left, top )
		 * parent: vilken grupp den formaterade texten ska läggas in i. (Optional, default=nil)
		 * textData: textdata (se 'textdataparametrar' och exempel).
		 * wrapWidth: hur långa raderna får vara. (Optional, default=nil)
		 * left: marginal till vänster kant.
		 * top: marginal till övre kant.
		 > Returnerar: en grupp med textobjekt.

	Textdataparametrar:
		color: textfärg. (Optional, default=nil)
		font: typsnitt. (Optional, default=native.systemFont)
		size: textstorlek.
		text: textsträng.

	Exempel:
		local wrapWidth, left, top = 500, 150, 130
		local textData = {
			{text="Hej på", font=native.systemFont, size=64},
			{text=" dig", font=native.systemFontBold, size=64, color={240,140,0}},
			{text=" och din", font=native.systemFont, size=64},
			{text=" katt!", font=native.systemFontBold, size=64, color={0,140,240}},
		}
		local textGroup = newFormattedText(sceneView, textData, wrapWidth, left, top)

]]
-- Uppdaterad: 2012-11-07 16:00 av Marcus Thunström
function newFormattedText(parent, txtData, wrapWidth, left, top)

	if type(txtData) ~= 'table' then parent, txtData, wrapWidth, left, top = nil, parent, txtData, wrapWidth, left end
	if not top then wrapWidth, left, top = nil, wrapWidth, left end

	local txtGroup = newGroup(parent)
	txtGroup.x, txtGroup.y = left, top

	local x, y, h = 0, 0, 0
	for _, data in ipairs(txtData) do
		local color = data.color; if color and type(color) ~= 'table' then color = {color} end
		for i, txt in ipairs(stringSplit(data.text, ' ')) do
			local txtObj = display.newText(txtGroup, ((x==0 or i==1) and txt or ' '..txt), x, y, data.font, data.size)
			if wrapWidth and txtGroup.width > wrapWidth then
				x, y, h = 0, y+h, 0
				txtObj:removeSelf()
				txtObj = display.newText(txtGroup, txt, x, y, data.font, data.size)
			end
			if color then txtObj:setTextColor(unpack(color)) end
			x, h = x+txtObj.width, math.max(h, getLineHeight(data.font, data.size))
		end
	end

	return txtGroup

end







-- Skapar en grupp direkt i en annan grupp
-- Uppdaterad: 2012-04-14 11:00 av Marcus Thunström
function newGroup(parent)
	local group = display.newGroup()
	if parent then parent:insert(group) end
	return group
end







-- Skapar en grupp som innehåller alla individuella tecken i en sträng som individuella textobjekt
-- Uppdaterad: 2012-10-10 10:35 av Marcus Thunström
do
	local function increaseSpacing(self, amount)
		amount = amount or 1
		for i = 1, self.numChildren do
			self[i].x = self[i].x+(i-1)*amount
		end
	end
	local function setText(self, txt)
		for i = 1, self.numChildren do
			self[i].text = txt
		end
	end
	local function setTextColor(self, ...)
		for i = 1, self.numChildren do
			self[i]:setTextColor(...)
		end
	end
	function newLetterSequence(parent, str, ...)

		local charGroup = display.newGroup()
		if parent then parent:insert(charGroup) end

		local utf8 = require('modules.utf8')

		local refText = display.newText('', ...)
		for i = 1, utf8.len(str) do
			--
			local char = utf8.sub(str, i, i)
			local txtObj = display.newText(charGroup, char, ...)
			--
			local w = refText.width
			refText.text = refText.text..char
			txtObj.x = (w+refText.width)/2
			--
		end
		refText:removeSelf()

		charGroup:setReferencePoint(display.CenterReferencePoint)
		charGroup.increaseSpacing = increaseSpacing
		charGroup.setText = setText
		charGroup.setTextColor = setTextColor

		return charGroup

	end
end







--[[

	newMultiLineText()
		Alternativ till display.newText(), fast radbrytningar funkar utan att man behöver specificera bredd och höjd.
		Man kan även ange vilken typ av justering texten ska ha. (Vänster, höger eller centrerat.)
		Notera att texten aldrig bryts automatiskt.

	Beskrivning:
		textGroup = newMultiLineText( [parent,] text, x, y, fontName, fontSize, align )
		 * parent: vilken grupp textgruppen ska läggas in i, om någon alls. (Default=nil)
		 * text: sträng som kan innehålla radbrytningar.
		 * align: textjustering. ("R"=höger, "L"=vänster, "C"=centrerat)
		 > Returnerar: en grupp med textobjekt.

	Exempel:
		newMultiLineText(sceneView, "Foo!\nFoobar!!!", 450, 300, native.systemFont, 24, "C")

]]
-- Uppdaterad: 2012-09-28 13:50 av Marcus Thunström
do

	local alignments = {
		R = 'TR',
		C = 'TC',
		L = 'TL',
	}

	local setTextColor

	function newMultiLineText(parent, text, x, y, font, size, align)
		local textGroup = newGroup(parent)
		textGroup.setTextColor = setTextColor
		local rp, rowY = alignments[align] or alignments.L, 0
		for _, txt in ipairs(stringSplit(text, '\n')) do
			rowY = rowY+setAttr(display.newText(textGroup, txt, 0, 0, font, size), {x=0, y=rowY}, {rp=rp}).height
		end
		setAttr(textGroup, {x=x, y=y}, {rp='C'})
		return textGroup
	end

	function setTextColor(textGroup, ...)
		local args = {...}
		foreach(textGroup, function(txtObj)
			txtObj:setTextColor(unpack(args))
		end)
	end

end







-- Kombinerar newLetterSequence() och newOutlineText()
-- Uppdaterad: 2012-10-10 10:35 av Marcus Thunström
do
	local function increaseSpacing(self, amount)
		amount = amount or 1
		for i = 1, self.numChildren do
			self[i].x = self[i].x+(i-1)*amount
		end
	end
	local function setText(self, txt)
		for i = 1, self.numChildren do
			self[i].text = txt
		end
	end
	local function setTextColor(self, ...)
		for i = 1, self.numChildren do
			self[i]:setTextColor(...)
		end
	end
	function newOutlineLetterSequence(txtColor, outlineColor, offset, quality, parent, str, ...)

		local charGroup = display.newGroup()
		if parent then parent:insert(charGroup) end

		local utf8 = require('modules.utf8')

		local refText = display.newText('', ...)
		for i = 1, utf8.len(str) do
			--
			local char = utf8.sub(str, i, i)
			local txtObj = newOutlineText(txtColor, outlineColor, offset, quality, charGroup, char, ...)
			--
			local w = refText.width
			refText.text = refText.text..char
			txtObj.x = (w+refText.width)/2
			--
		end
		refText:removeSelf()

		charGroup:setReferencePoint(display.CenterReferencePoint)
		charGroup.increaseSpacing = increaseSpacing
		charGroup.setText = setText
		charGroup.setTextColor = setTextColor

		return charGroup

	end
end







-- Skapar en text med en färgad outline
--[[
	Beskrivning:
		displayGroup = newOutlineText(textColor, outlineColor, outlineThickness, quality, parent, string, left, top, [width, height,] font, size)
			textColor & outlineColor: RGBA-färg
			outlineThickness: ytterlinjens tjocklek
			quality: hur många textobjekt ytterlinjen ska bestå av
	Exempel:
		local niceText = newOutlineText({0,200,255}, {150,0,0}, 1, 3, nil, "Kalle", 80, 70, "aNiceFont", 32)
]]
-- Uppdaterad: 2012-07-27 14:50 av Marcus Thunström
do

	local function setOutlineColor(self, ...)
		for i = 1, self.numChildren-1 do self[i]:setTextColor(...) end
	end

	local function setText(self, txt)
		for i = 1, self.numChildren do self[i].text = txt end
	end

	local function setTextColor(self, ...)
		self[self.numChildren]:setTextColor(...)
	end

	local mt
	mt = {
		__index = function(self, k)
			if k == 'text' then
				return self[1].text
			else
				setmetatable(self, self.__coronaMt)
				local v = self[k]
				setmetatable(self, mt)
				return v
			end
		end,
		__newindex = function(self, k, v)
			if k == 'text' then
				for i = 1, self.numChildren do self[i].text = v end
			else
				setmetatable(self, self.__coronaMt)
				self[k] = v
				setmetatable(self, mt)
			end
		end,
	}



	function newOutlineText(txtColor, outlineColor, offset, quality, parent, ...)

		local txtGroup = display.newGroup()
		if parent then parent:insert(txtGroup) end

		if type(outlineColor) ~= 'table' then
			outlineColor = {outlineColor, outlineColor, outlineColor, 255}
		end
		local r, g, b, a = unpack(outlineColor)
		a = a or 255

		local ang = 0
		local stepAng = 2*math.pi/quality
		for outline = 1, quality do
			local txtObj = display.newText(txtGroup, ...)
			txtObj:setTextColor(r, g, b, a)
			txtObj.x, txtObj.y = offset*math.sin(ang), offset*math.cos(ang)
			ang = ang+stepAng
		end

		local txtObj = display.newText(txtGroup, ...)
		txtObj:setTextColor(unpack(type(txtColor) == 'table' and txtColor or {txtColor}))
		txtObj.x, txtObj.y = 0, 0

		txtGroup.setText = setText
		txtGroup.setTextColor = setTextColor
		txtGroup.setOutlineColor = setOutlineColor

		txtGroup.__coronaMt = getmetatable(txtGroup)
		setmetatable(txtGroup, mt)

		return txtGroup

	end

end







-- Skapar ett sprite sheet utifrån flera bildfiler med en frame i varje fil
-- Uppdaterad: 2012-04-14 11:00 av Marcus Thunström
function newSpriteMultiImageSet(pathPrefix, pathSuffix, frames, w, h)
	local spriteSheets = {}
	for frame = 1, frames do
		local path = pathPrefix..stringPad(tostring(frame), '0', 3, 'L')..pathSuffix
		table.insert(spriteSheets, {
			sheet = sprite.newSpriteSheet(path, w, h),
			frames = {1}
		})
	end
	return sprite.newSpriteMultiSet(spriteSheets)
end







-- Skapar en array med 'amount' antal slumpmässigt unika nummer mellan 'min' och 'max'
-- Det går att ange nummer som alltid ska vara med med 'nrsToKeep'
-- Exempel:
--
--   local numbers = numberSequence(1, 10, 3)
--   -- numbers kan vara t.ex. {2,6,8} eller {1,8,10}
--
--   numbers = numberSequence(1, 10, 4, {1,2} )
--   -- numbers kan vara t.ex. {1,2,4,10} eller {1,2,7,9}
--   -- 1 & 2 är alltid med
--
-- Uppdaterad: 2012-04-14 11:00 av Marcus Thunström
function numberSequence(min, max, amount, nrsToKeep)
	nrsToKeep = nrsToKeep or {}
	local nrs = {}
	for nr = min, max do table.insert(nrs, nr) end
	for i = min, max-amount do
		local loops, iToRemove = 0
		repeat
			loops = loops+1
			if loops > 10000 then return nrs end -- Error: kan inte ta bort till räckligt många nummer?
			iToRemove = math.random(1, #nrs)
		until table.indexOf(nrsToKeep, nrs[iToRemove]) == nil
		table.remove(nrs, iToRemove)
	end
	return nrs
end







-- numberToString()
-- Gör om ett nummer till en sträng (t.ex. numberToString(5) returnerar "fem")
-- Uppdaterad: 2012-10-19 16:00 av Marcus Thunström
-- TODO: dynamiskt sätta ihop mer avancerade nummersträngar - t.ex. numberToString(125) ska returnera names[100]..names[20]..names[5]
do

	local names = {
		[0] = 'noll',
		[1] = 'ett',
		[2] = 'två',
		[3] = 'tre',
		[4] = 'fyra',
		[5] = 'fem',
		[6] = 'sex',
		[7] = 'sju',
		[8] = 'åtta',
		[9] = 'nio',
		[10] = 'tio',
		[11] = 'elva',
		[12] = 'tolv',
		[13] = 'tretton',
		[14] = 'fjorton',
		[15] = 'femton',
		[16] = 'sexton',
		[17] = 'sjutton',
		[18] = 'arton',
		[19] = 'nitton',
		[20] = 'tjugo',
		[30] = 'trettio',
		[40] = 'fyrtio',
		[70] = 'sjuttio',
		[80] = 'åttio',
		[90] = 'nittio',
		[100] = 'hundra',
		[1000] = 'tusen',
	}

	function numberToString(nr)
		return names[nr]
	end

end







-- Ordnar displayObjects efter deras y-värde
-- Uppdaterad: 2012-09-26 17:10 av Marcus Thunström
function orderObjects(group)
	local children = {}
	foreach(group, function(child, i) children[i] = child end)
	table.sort(children, function(a, b) return a.y < b.y end)
	for _, child in ipairs(children) do child:toFront() end
end







-- Returnerar avståndet mellan två punkter
-- Uppdaterad: 2012-09-05 12:15 av Marcus Thunström
function pointDist(x1, y1, x2, y2)
	return math.sqrt((x1-x2)^2+(y1-y2)^2)
end







-- Kollar om en punkt är inom en rektangel
-- Det finns två sätt att kalla på funktionen:
--   pointInRect(pointX, pointY, rectX, rectY, rectWidth, rectHeight)
--   pointInRect(pointX, pointY, rectObject)
--     rectObject är ett ett objekt med ett x-, y-, width- och height-värde
-- Uppdaterad: 2012-04-14 11:00 av Marcus Thunström
function pointInRect(pointX, pointY, rectX, rectY, w, h)
	if type(rectX) == 'table' then
		local rect = rectX
		rectX, rectY, w, h = rect.x, rect.y, rect.width, rect.height
	end
	return pointX >= rectX and pointY >= rectY and pointX < rectX+w and pointY < rectY+h
end


-- Kollar om två rektanglar överlappar varandra (fungerar med alla display objects)
-- rectIntersection(r1, r2)
-- r1 och r2 är displayobjects.
-- Uppdaterad: 2012-08-30 17:57 av Tommy Lindh
function rectIntersection(r1, r2)
	local bounds1 = r1.contentBounds
	local bounds2 = r2.contentBounds

    return not ( bounds2.xMin > bounds1.xMax
				or bounds2.xMax < bounds1.xMin
				or bounds2.yMin > bounds1.yMax
				or bounds2.yMax < bounds1.yMin
			)
end




-- "Predefined arguments function"
-- Returnerar en funktion som kallar på speciferad function med en uppsättning av fördefinerade argument
-- Exempel:
--   function printString(str)
--     print(str)
--   end
--   printHello = predefArgsFunc(printString, "Hello!")
--   printHello()  -- Hello!
--   printWorld = predefArgsFunc(printString, "world")
--   printWorld()  -- world
-- Uppdaterad: 2012-05-09 16:20 av Marcus Thunström
function predefArgsFunc(func, ...)
	local args = {...}
	return function() return func(unpack(args)) end
end







-- Printar ut objekt på ett bättre sätt
-- Uppdaterad: 2012-11-12 10:20 av Marcus Thunström
function printObj(...)
	local function printObj(o, indent, name)
		if indent > 100 then return end
		if name then
			name = tostring(name)..' = '
		else
			name = ''
		end
		if type(o) == 'table' then
			print(string.rep('\t', indent)..name..'{')
			for i, v in pairs(o) do
				if v == o then
					print(string.rep('\t', indent+1)..name..'SELF')
				else
					printObj(v, indent+1, i)
				end
			end
			print(string.rep('\t', indent)..'}')
		else
			print(string.rep('\t', indent)..name..tostring(o))
		end
	end
	for i, v in ipairs({...}) do
		printObj(v, 0)
	end
end







-- Lägger objekten i en array i slumpmässig ordning (Notera att originalarrayen ändras)
-- Ett intervall kan anges
-- Funktionen kan även blanda runt bokstäver i en utf8-sträng
-- Uppdaterad: 2012-09-12 13:10 av Marcus Thunström
function randomize(t, from, to)
	if type(t) == 'table' then
		from, to = from or 1, to or #t
		if from < 1 then from = #t+from+1 end
		if to < 1 then to = #t+to end
		for i = from, to-1 do table.insert(t, from, table.remove(t, math.random(i, to))) end
		return t
	else--if type(t) == 'string' then
		local utf8 = require('modules.utf8')
		local indices, len = {}, utf8.len(t)
		for i = 1, len do indices[i] = i end
		for i = 1, len-1 do table.insert(indices, 1, table.remove(indices, math.random(i, len))) end
		local str = ''
		for _, i in ipairs(indices) do str = str..utf8.sub(t, i, i) end
		return str
	end
end







-- Variation av math.random, med mindre risk för specifierade nummer
-- Uppdaterad: 2012-06-20 17:30 av Marcus Thunström
--[[ Slumphetstest:
	for sparsity = 1, 10 do
		print('Sparsity: '..sparsity)
		local counts = {[0]=0, 0, 0, 0, 0, 0}
		for i = 1, 10000 do
			local nr = randomWithSparsity(0, 5, {0, 5}, sparsity)
			counts[nr] = counts[nr]+1
		end
		for i = 0, 5 do
			print('  '..i..': '..counts[i])
		end
	end
--]]
function randomWithSparsity(min, max, sparsities, sparsity)
	sparsities = sparsities or {}
	local nr
	for i = 1, sparsity do
		nr = math.random(min, max)
		if not table.indexOf(sparsities, nr) then return nr end
	end
	return nr
end







-- Fyller en ny array med nummer mellan angivet intervall
-- Exempel:
--    range(3) -- {1,2,3}
--    range(2, 5) -- {2,3,4,5}
--    range(0, 30, 10) -- {0,10,20,30}
-- Uppdaterad: 2012-10-24 14:35 av Marcus Thunström
function range(from, to, step)
	if not to then from, to = 1, from end
	local arr = {}
	for nr = from, to, step or 1 do
		arr[#arr+1] = nr
	end
	return arr
end







-- Tar bort alla children från en grupp
-- Kan även ta bort children i en array från deras respektive parent
-- Uppdaterad: 2012-04-14 11:00 av Marcus Thunström
function removeAllChildren(t)
	local len = t.numChildren or #t
	for i = len, 1, -1 do
		local child = t[i]
		if child.parent then child:removeSelf() end
	end
end







-- Tar bort ett objekt från en array
-- Uppdaterad: 2012-04-14 11:00 av Marcus Thunström
function removeTableItem(t, obj)
	return table.remove(t, table.indexOf(t, obj))
end







-- Lägger till en didExitScene event listener på en scen som tar bort scenen
--[[
	Exempel:
		function scene:exitScene()
			require('modules.tenfLib').sceneRemoveAfterExit(self)
		end
		scene:addEventListener("exitScene", scene)
]]
-- Uppdaterad: 2012-09-25 14:35 av Marcus Thunström
--[[
do

	local storyboard = require('storyboard')

	function sceneRemoveAfterExit(scene)
		local sceneName = storyboard.getCurrentSceneName()
		scene:addEventListener('didExitScene', function()
			storyboard.removeScene(sceneName)
		end)
	end

end
]]






-- Kör flera transition.to/from, timer.performWithDelay och/eller audio.play efter varann
-- Returnerar ett handle som kan användas för att manipulera sekvensen
--[[
	Exempel:
		local o1 = display.newRect(0, 50, 100, 100)
		local o2 = display.newRect(600, 50, 100, 100)
		local steps = {
			{type='delay', time=1000, onComplete=function()print('delay#1')end},
			{type='transition', target=o1, x=200, time=1000, onComplete=function()print('transition#1')end},
			{type='delay', time=1000, onComplete=function()print('delay#2')end},
			{type='transition', multi={
				{target=o2, x=400, y=300, time=2000},
				{target=o1, y=300, time=1000},
			}, onComplete=function()print('transition#2')end}
		}
		local handle = runTimeSequence(steps)
]]
-- Uppdaterad: 2012-10-16 14:25 av Marcus Thunström
do

	local performWithDelay  = timer.performWithDelay
	local tranFrom          = transition.from
	local tranTo            = transition.to

	local function performMagic(obj)
		local transitionFunc, target = (obj.from and tranFrom or tranTo), obj.target
		obj.type, obj.target, obj.from = nil, nil, nil
		return transitionFunc, target
	end

	function runTimeSequence(steps)
		local delay         = nil
		local i             = 0
		local soundChannel  = nil
		local timeSequence  = {}
		local transitions   = {}

		local function performNext(...)
			delay = nil
			soundChannel = nil
			transitions = {}
			if steps[i] and steps[i]._callback then steps[i]._callback(...) end
			i = i+1
			local step = steps[i]
			if not step then return end
			step._callback = step.onComplete
			if step.type == 'delay' then
			----------------------------------------------------------------

				delay = performWithDelay(step.time, performNext)

			elseif step.type == 'transition' then
			----------------------------------------------------------------

				local multi = step.multi
				if multi then

					if #multi == 0 then
						performNext()
					else
						local longestPart = multi[1]
						for i = #multi, 2, -1 do
							local part = multi[i]
							if ((part.time or 500) + (part.delay or 0)) > ((longestPart.time or 500) + (longestPart.delay or 0)) then longestPart = part end
						end
						for _, part in ipairs(multi) do
							if part == longestPart then part.onComplete = performNext else part.onComplete = nil end
							local transitionFunc, target = performMagic(part)
							transitions[#transitions+1] = transitionFunc(target, part)
						end
					end

				else

					step.onComplete = performNext
					local transitionFunc, target = performMagic(step)
					transitions = {transitionFunc(target, step)}

				end

			elseif step.type == 'sound' and step.target then
			----------------------------------------------------------------

				soundChannel = audio.play(step.target, setAttr(step, {onComplete=function(e)
					if e.completed then performNext(e) end
				end}))

			else
			----------------------------------------------------------------

				performNext()

			end

		end

		function timeSequence:cancel()
			if delay then timer.cancel(delay) end
			if soundChannel then audio.stop(soundChannel) end
			for i = 1, #transitions do
				transition.cancel(transitions[i])
			end
			delay = nil
			soundChannel = nil
			transitions = {}
		end

		function timeSequence:skip()
			timeSequence:cancel()
			performNext()
		end

		performNext()
		return timeSequence
	end

end







-- Sätter flera attributer på ett objekt i ett svep
-- Kan även sätta speciella parametrar m.h.a. metoder, så som referenspunkt med setReferencePoint()
-- Returnerar argumentobjektet
-- Exempel:
--   img = display.newImage('foo.png')
--   setAttr(img, {x=70, rotation=5})
--   img2 = display.newImageRect('background.png', 1024, 768)
--   setAttr(img, {x=0, y=0}, {rp='TL'})
-- Uppdaterad: 2012-07-11 19:55 av Marcus Thunström
do
	local rps = {
		TL=display.TopLeftReferencePoint,
		TC=display.TopCenterReferencePoint,
		TR=display.TopRightReferencePoint,
		CL=display.CenterLeftReferencePoint,
		C=display.CenterReferencePoint,
		CR=display.CenterRightReferencePoint,
		BL=display.BottomLeftReferencePoint,
		BC=display.BottomCenterReferencePoint,
		BR=display.BottomRightReferencePoint
	}
	function setAttr(obj, attrs, special)
		attrs = attrs or {}
		special = special or {}
		if special.rp then obj:setReferencePoint(rps[special.rp]) end
		for k, v in pairs(attrs) do
			obj[k] = v
		end
		if special.fc then obj:setFillColor(unpack(type(special.fc)=='table'and special.fc or{special.fc})) end
		if special.sc then obj:setStrokeColor(unpack(type(special.sc)=='table'and special.sc or{special.sc})) end
		if special.tc then obj:setTextColor(unpack(type(special.tc)=='table'and special.tc or{special.tc})) end
		return obj
	end
end







-- Sätter en attribut i en multidimensionell array/tabell
-- Om en viss dimension inte finns så skapas den (Se exempel)
--[[
	Exempel:
		local t = {}
		setTableValue(t, {1, 2, 3}, "foo")
		print(t[1][2][3])  -- foo
]]
-- Uppdaterad: 2012-08-24 17:25 av Marcus Thunström
function setTableValue(t, path, v)
	if path[2] then
		local k = table.remove(path, 1)
		if not t[k] then t[k] = {} end
		setTableValue(t[k], path, v)
	else
		t[path[1]] = v
	end
end



-- Hämtar en attribut från en multidimensionell array/tabell på ett säkert sätt
-- Om en viss dimension inte finns så ges inget error - funktionen returnerar bara nil (Se exempel)
--[[
	Exempel:

		local t = {a = "foo"}

		print(t.a)  -- foo
		print(getTableValue(t, {"a"}))  -- foo, true

		print(t.a.b)  -- nil
		print(getTableValue(t, {"a", "b"}))  -- nil, true

		print(t.a.b.c)  -- Runtime error: attempt to index field 'b' (a nil value)
		print(getTableValue(t, {"a", "b", "c"}))  -- nil, false  (Inget error här)

]]
-- Uppdaterad: 2012-08-24 17:30 av Marcus Thunström
function getTableValue(t, path)
	if path[2] then
		local k = table.remove(path, 1)
		if not t[k] then return nil, false end
		return getTableValue(t[k], path)
	else
		return t[path[1]], true
	end
end







-- Ladda inställningsfil
-- settingsFileLoad( fileName, dir )
-- Uppdaterad: 2012-11-14 09:20 av Marcus Thunström
function settingsFileLoad(fileName, dir)
	local path = system.pathForFile(fileName, dir or system.DocumentsDirectory)
	if not path then return nil end
	local data = {}
	for line in io.lines(path) do
		local i = string.find(line, '=', 1, true)
		local v = line:sub(i+1)
		if v ~= '' then
			if v == 'true' or v == 'false' then v = (v == 'true') end
			data[line:sub(1, i-1)] = v
		end
	end
	return data
end

-- Spara inställningsfil
-- settingsFileSave( fileName, [dir,] data )
-- Uppdaterad: 2012-11-14 09:20 av Marcus Thunström
function settingsFileSave(fileName, dir, data)
	if type(dir) ~= 'userdata' then dir, data = nil, dir end
	local path = system.pathForFile(fileName, dir or system.DocumentsDirectory)
	local file = io.open(path, 'w+')
	for k, v in pairs(data) do file:write(k..'='..tostring(v)..'\n') end
	io.close(file)
end







--Slumpar positionerna på objekten i en lista.
--Valfria upperbound och lowerbound för att slumpa del av listan.

-- Uppdaterad: 2012-09-04 11:50 av Marcus Thunström
function shuffleList(list, lowerBound, upperBound)
	lowerBound = lowerBound or 1
	upperBound = upperBound or #list
	for i = upperBound, lowerBound, -1 do
	   local j = math.random(lowerBound, i)
	   local tempi = list[i]
	   list[i] = list[j]
	   list[j] = tempi
	end
end







-- Delar på en sträng innehållande siffror, tecken och variabler till en array
-- Notera: det bör inte vara något whitespace i strängen
-- Exempel:
--   splitEquation("3+_=10")  -- {"3", "+", "_", "=", "10"}
--   splitEquation("32+x=58+y")  -- {"32", "+", "x", "=", "58", "+", "y"}
-- Uppdaterad: 2012-04-14 11:00 av Marcus Thunström
function splitEquation(str)

	if str == '' then return {} end

	local starts = {}
	local startI, endI

	endI = 0
	while true do -- hitta siffror
		startI, endI = string.find(str, '%d+', endI+1)
		if startI == nil then break end
		starts[#starts+1] = startI
	end
	endI = 0
	while true do -- hitta tecken
		startI, endI = string.find(str, '%p', endI+1)
		if startI == nil then break end
		starts[#starts+1] = startI
	end
	endI = 0
	while true do -- hitta bokstäver/ord
		startI, endI = string.find(str, '[%l%u]+', endI+1)
		if startI == nil then break end
		starts[#starts+1] = startI
	end
	endI = 0
	while true do -- hitta mellanrum
		startI, endI = string.find(str, '%s+', endI+1)
		if startI == nil then break end
		starts[#starts+1] = startI
	end
	table.sort(starts)

	local parts = {}
	for i = 1, #starts-1 do
		parts[#parts+1] = string.sub(str, starts[i], starts[i+1]-1)
	end
	parts[#parts+1] = string.sub(str, starts[#starts], #str)
	return parts

end







-- Uppdaterad: 2012-05-15 10:55 av Marcus Thunström
function sqlBool(v)
	return v and 1 or 0
end

-- Uppdaterad: 2012-05-15 10:55 av Marcus Thunström
function sqlInt(v)
	return math.floor(tonumber(v) or 0)
end

-- Uppdaterad: 2012-05-15 10:55 av Marcus Thunström
function sqlStr(v)
	return '"'..(v or ''):gsub('"', '""')..'"'
end







-- Lägg till denna funktion som event listener för att stoppa bubbling vid ett visst displayobjekt
-- Exempel:
--   w, h = display.contentWidth, display.contentHeight
--   touchBlocker = display.newRect(0, 0, w, h)
--   touchBlocker:addEventListener("touch", stopPropagation)
function stopPropagation()
	return true
end







-- Räknar antalet sub-strängar i en sträng
-- Exempel:
--   print(stringCount("Hej hej hej!", "hej"))  -- 2
-- Uppdaterad: 2012-04-14 11:00 av Marcus Thunström
function stringCount(strToSearch, strToFind)
	if #strToFind == 0 then return 0 end
	local count = 0
	local _, i = 0, 1
	while true do
		_, i = string.find(strToSearch, strToFind, i+1, true)
		if i == nil then
			return count
		else
			count = count+1
		end
	end
end







-- Fyller ut tomrummet runt en sträng så att strängen får en bestämd längd
-- Exempel:
--   print(stringPad('Hej', '!', 6))  -- Hej!!!
-- Uppdaterad: 2012-04-14 11:00 av Marcus Thunström
function stringPad(str, padding, len, side)
	side = side or 'R'
	if #str < len then
		if side == 'L' then
			return string.rep(padding, math.floor((len-#str)/#padding))..str
		else
			return str..string.rep(padding, math.floor((len-#str)/#padding))
		end
	else
		return str
	end
end







-- Delar en sträng till en array
-- Exempel:
--   arr = stringSplit("Hej på dig!", " ")
--   print(arr[2])  -- "på"
-- Uppdaterad: innan 2012-05-14 av Marcus Thunström
function stringSplit(str, delimiter)
	local result = {}
	local from = 1
	local delimFrom, delimTo = string.find(str, delimiter, from)
	while delimFrom do
		result[#result+1] = string.sub(str, from, delimFrom-1)
		from  = delimTo + 1
		delimFrom, delimTo = string.find(str, delimiter, from)
	end
	result[#result+1] = string.sub(str, from)
	return result
end







-- Ändrar alla bokstäver (inklusive åäö) i en sträng till stora eller små
-- Kan även ta en array med strängar som argument (även multidimensionella arrayer)
-- Uppdaterad: 2012-09-07 11:45 av Marcus Thunström

function stringToLower(str)
	if type(str) == 'table' then
		local arr = {}
		for i, s in ipairs(str) do
			arr[i] = stringToLower(s)
		end
		return arr
	else
		return str:lower():gsub('Å', 'å'):gsub('Ä', 'ä'):gsub('Ö', 'ö')
	end
end

function stringToUpper(str)
	if type(str) == 'table' then
		local arr = {}
		for i, s in ipairs(str) do
			arr[i] = stringToUpper(s)
		end
		return arr
	else
		return str:upper():gsub('å', 'Å'):gsub('ä', 'Ä'):gsub('ö', 'Ö')
	end
end







-- Kopierar en tabell
-- Uppdaterad: 2012-07-16 09:50 av Marcus Thunström
function tableCopy(t, deepCopy)
	local copy = {}
	if deepCopy then
		for k, v in pairs(t) do
			copy[k] = ((type(v) == 'table') and tableCopy(v, true) or v)
		end
	else
		for k, v in pairs(t) do
			copy[k] = v
		end
	end
	return copy
end







--[[

	tableDiff()
		Returnerar skillnaden mellan arrayer.

	Beskrivning:
		tableDiff( t1, t2 [, ... ] )
		 * t1: arrayen att jämföra från.
		 * t2: arrayen att jämföra mot.
		 * ...: fler arrayer att jämföra mot.
		 > Returnerar: en array med alla värden i 't1' som inte finns i någon annan array.

	Exempel:
		local t1 = {"grön", "röd", "blå", "röd"}
		local t2 = {"grön", "gul", "röd"}
		local difference = tableDiff(t1, t2)
		print(table.concat(difference, ", ")) -- blå

]]
-- Uppdaterad: 2012-10-19 18:10 av Marcus Thunström
function tableDiff(t, ...)
	local len, indexOf, diff = select('#', ...), table.indexOf, {}
	for i, v in ipairs(t) do
		local exists = false
		for arg = 1, len do
			if indexOf(select(arg, ...), v) then exists = true; break end
		end
		if not exists then diff[#diff+1] = v end
	end
	return diff
end







-- Gör om en multidimensionell tabell till en array
-- Uppdaterad: 2012-11-12 13:30 av Marcus Thunström
function tableFlatten(t, outputT)
	outputT = outputT or {}
	for _, o in pairs(t) do
		if type(o) == 'table' then
			tableFlatten(o, outputT)
		else
			outputT[#outputT+1] = o
		end
	end
	return outputT
end







-- Hämtar specifierad attribut hos alla objekt i en array eller grupp
-- Uppdaterad: 2012-08-26 17:15 av Marcus Thunström
--[[
	Exempel:
		local t = {
			{x=1, y=10},
			{x=2, y=15},
			{x=3, y=20},
		}
		tableGetAttr(t, "y")  -- {10,15,20}
]]
function tableGetAttr(t, attr)
	local vals = {}
	foreach(t, function(o, i) vals[i] = o[attr] end)
	return vals
end







-- Lägger in ett värde i en tabell om det inte redan finns däri
-- Uppdaterad: 2012-07-25 15:05 av Marcus Thunström
--[[
	Exempel:
		local t = {}
		tableInsertUnique(t, "A")  -- t = {"A"}
		tableInsertUnique(t, "B")  -- t = {"A", "B"}
		tableInsertUnique(t, "A")  -- t = {"A", "B"}
]]
function tableInsertUnique(t, v)
	local unique = true
	for i, tv in ipairs(t) do
		if v == tv then
			unique = false
			break
		end
	end
	if unique then t[#t+1] = v end
	return t
end







-- Slår ihop två numrerade arrayer till en array
-- Uppdaterad: 2012-07-27 17:00 av Marcus Thunström
--[[
	Exempel:
		local t1 = {"A", "B"}
		local t2 = {"i", "j"}
		local t3 = {true}
		tableMerge(t1, t2, t3)  -- {"A", "B", "i", "j", true}
]]
function tableMerge(t1, ...)
	local t = table.copy(t1)
	for _, t2 in ipairs{...} do
		for _, v in ipairs(t2) do
			t[#t+1] = v
		end
	end
	return t
end



-- Slår ihop två numrerade arrayer till en array utan att skapa dublettvärden
-- Uppdaterad: 2012-09-27 11:25 av Marcus Thunström
--[[
	Exempel:
		local t1 = {"A", "i", "B", true}
		local t2 = {"i", "j"}
		local t3 = {true}
		tableMergeUnique(t1, t2, t3)  -- {"A", "i", "B", true, "j"}
]]
function tableMergeUnique(t1, ...)
	local t = table.copy(t1)
	for _, t2 in ipairs{...} do
		for _, v in ipairs(t2) do
			tableInsertUnique(t, v)
		end
	end
	return t
end







-- Returnerar summan av alla värden i en tabell
-- Uppdaterad: 2012-10-30 18:00 av Marcus Thunström
function tableSum(t)
	local sum = 0
	for _, v in pairs(t) do sum = sum+v end
	return sum
end





-- Returnerar antal objekt i en tabell eller array
-- Uppdaterad: 2012-11-13 14:04 av Tommy Lindh
function tableCount(t)
	local count = 0
	if t then
		for k, v in pairs(t) do
			count = count + 1
		end
	else
		print "WARNING: table i tableCount är nil"
		count = nil
	end
	return count
end







-- Tar bort överflödiga element i en array
-- Uppdaterad: 2012-10-02 15:10 av Marcus Thunström
function tableLimitLength(t, len)
	for i = len+1, #t do t[i] = nil end
	return t
end







-- Ersätter ÅÄÖ med AA, AE och OE
-- Uppdaterad: 2012-04-14 11:00 av Marcus Thunström
function toFileName(name)
	name = string.gsub(name, 'Å', 'AA')
	name = string.gsub(name, 'Ä', 'AE')
	name = string.gsub(name, 'Ö', 'OE')
	name = string.gsub(name, 'å', 'aa')
	name = string.gsub(name, 'ä', 'ae')
	name = string.gsub(name, 'ö', 'oe')
	return name
end







-- Källa: http://lua-users.org/wiki/StringRecipes
-- Uppdaterad: innan 2012-05-18 09:55 av Marcus Thunström
function wordwrap(str, limit, indent, indent1)
	indent = indent or ''
	indent1 = indent1 or indent
	limit = limit or 72
	local here = 1-#indent1
	return indent1..str:gsub('(%s+)()(%S+)()',
		function(sp, st, word, fi)
			if fi-here > limit then
			here = st - #indent
			return '\n'..indent..word
		end
	end)
end







-- Uppdaterad: 2012-05-14 18:20 av Marcus Thunström
function xmlGetChild(parent, childName)
	for i, child in ipairs(parent.child) do
		if child.name == childName then return child end
	end
	return nil
end







-- Returnerar ett true-värde om endast ett argument är något, annars false
--[[
	Exempel:
		print(xor(false, false))  -- false
		print(xor(true, false))  -- true
		print(xor(false, true))  -- true
		print(xor(true, true))  -- false
		print(xor(nil, true))  -- true
		print(xor(8, false))  -- 8
		print(xor(8, false, 5))  -- false
]]
-- Uppdaterad: 2012-09-11 15:45 av Marcus Thunström
function xor(...)
	local trueAmount = 0
	for _, v in pairs{...} do
		if v then trueAmount = trueAmount+1; trueV = v end
	end
	return trueAmount == 1 and trueV
end







return {
	addSelfRemovingEventListener = addSelfRemovingEventListener,  removeEventListeners = removeEventListeners,
	calculate = calculate,  compare = compare,  executeMathStatement = executeMathStatement,
	changeGroup = changeGroup,
	clamp = clamp,
	copyFile = copyFile,
	enableFocusOnTouch = enableFocusOnTouch,  disableFocusOnTouch = disableFocusOnTouch,
	enableTouchPhaseEvents = enableTouchPhaseEvents,  disableTouchPhaseEvents = disableTouchPhaseEvents,
	extractRandom = extractRandom,
	fileExists = fileExists,  getMissingFiles = getMissingFiles,
	fitObjectInArea = fitObjectInArea,
	fitTextInArea = fitTextInArea,
	foreach = foreach,
	getCsvTable = getCsvTable,
	getKeys = getKeys,  getUniqueValues = getUniqueValues,  getValues = getValues,
	getLetterOffset = getLetterOffset,
	getLineHeight = getLineHeight,
	getRandom = getRandom,
	getScaleFactor = getScaleFactor,
	gotoCurrentScene = gotoCurrentScene,
	indexOf = indexOf,  indexOfChild = indexOfChild,  indexWith = indexWith,  indicesWith = indicesWith,  indicesContaining = indicesContaining,
	isVowel = isVowel,  isConsonant = isConsonant,
	jsonLoad = jsonLoad,  jsonSave = jsonSave,
	latLonDist = latLonDist,
	loadSounds = loadSounds,  unloadSounds = unloadSounds,
	localToLocal = localToLocal,
	midPoint = midPoint,
	moduleCreate = moduleCreate,  moduleExists = moduleExists,  moduleUnload = moduleUnload,  requireNew = requireNew,
	newCaret = newCaret,
	newFormattedText = newFormattedText,
	newGroup = newGroup,
	newLetterSequence = newLetterSequence,
	newMultiLineText = newMultiLineText,
	newOutlineLetterSequence = newOutlineLetterSequence,
	newOutlineText = newOutlineText,
	newSpriteMultiImageSet = newSpriteMultiImageSet,
	numberSequence = numberSequence,
	numberToString = numberToString,
	orderObjects = orderObjects,
	pointDist = pointDist,
	pointInRect = pointInRect, rectIntersection = rectIntersection,
	predefArgsFunc = predefArgsFunc,
	printObj = printObj,
	randomize = randomize,
	randomWithSparsity = randomWithSparsity,
	range = range,
	removeAllChildren = removeAllChildren,
	removeTableItem = removeTableItem,
	runTimeSequence = runTimeSequence,
	sceneRemoveAfterExit = sceneRemoveAfterExit,
	setAttr = setAttr,
	setTableValue = setTableValue,  getTableValue = getTableValue,
	settingsFileLoad = settingsFileLoad,  settingsFileSave = settingsFileSave,
	shuffleList = shuffleList,
	splitEquation = splitEquation,
	sqlBool = sqlBool,  sqlInt = sqlInt,  sqlStr = sqlStr,
	stopPropagation = stopPropagation,
	stringCount = stringCount,
	stringPad = stringPad,
	stringSplit = stringSplit,
	stringToLower = stringToLower,  stringToUpper = stringToUpper,
	tableCopy = tableCopy,
	tableDiff = tableDiff,
	tableFlatten = tableFlatten,
	tableGetAttr = tableGetAttr,
	tableInsertUnique = tableInsertUnique,
	tableLimitLength = tableLimitLength,
	tableMerge = tableMerge,  tableMergeUnique = tableMergeUnique,
	tableSum = tableSum,
	tableCount = tableCount,
	toFileName = toFileName,
	wordwrap = wordwrap,
	xmlGetChild = xmlGetChild,
	xor = xor,
}






