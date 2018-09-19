local api, CHILDS, CONTENTS = ...

local json = require "json"
local scissors = sys.get_ext "scissors"

local font
local color
local speed

local M = {}

-- { source: { text1, text2, text3, ...} }
local content = {__myself__ = {}}
local tempContent = {__myself__ = {}}

local tempTickerFinish = 0
local isReset = false
local function generator()
    local index = 1
	
    return {
        next = function(self)
			if #content.__myself__ < 1 and #tempContent.__myself__ < 1 then
				return nil
			else				
				-- temp ticker
				if tempTickerFinish ~= 0 then 
					if index > #tempContent.__myself__ or isReset then
						index = 1
						isReset = false
					end
					
					index = index + 1
					print("YYYYEEEEEESSSS")
					print(tempContent.__myself__[index - 1])
					return tempContent.__myself__[index - 1]
				end
				
								
				-- origin ticker
				if index > #content.__myself__ or isReset then
					index = 1
					isReset = false
				end
				
				index = index + 1
				return content.__myself__[index - 1]
			end
        end;
    }
end

local feed = generator().next

api.add_listener("scroller", function(tile, value)
    print("got new scroller content from " .. tile)
    content[tile] = value
    -- pp(content)
end)

local items = {}
local current_left = 0
local last = sys.now()

local function draw_scroller(x, y, w, h, parent_config)
    -- scissors.set(x, y, x+w, y+h)
	
	if parent_config.rotation == 90 or parent_config.rotation == 270 then
        y = NATIVE_WIDTH - h
	end
	
	-- print(x, y, w, h)
	
    local now = sys.now()
    local delta = now - last
    last = now
    local advance = delta * speed

    local idx = 1
    local x = current_left

    local function prepare_image(obj)
        if not obj then
            return
        end
        local ok, obj_copy = pcall(obj.copy, obj)
        if ok then
            return resource.load_image{
                file = obj_copy,
                mipmap = true,
            }
        else
            return obj
        end
    end

    while x < WIDTH do
        if idx > #items then
            local ok, item = pcall(feed)
            if ok and item then
                items[#items+1] = {
                    text = item.text .. "    -    ",
                    image = prepare_image(item.image)
                }
            else
                print "no scroller item. showing blanks"
                items[#items+1] = {
                    text = "                      ",
                }
            end
        end

        local item = items[idx]

        if item.image then
            local state, img_w, img_h = item.image:state()
            if state == "loaded" then
                local img_max_height = h
                local proportional_width = img_max_height / img_h * img_w
                item.image:draw(x, y, x+proportional_width, y+img_max_height)
                x = x + proportional_width + 30
            end
        end

		-- print("SCROLLER")
		-- print(x, y+3, item.text, h-8)
        local text_width = font:write(
            x, y+3, item.text, h-8, 
            color.r, color.g, color.b, color.a
        )
        x = x + text_width

        if x < 0 then
            assert(idx == 1)
            if item.image then
                item.image:dispose()
            end
            table.remove(items, idx)
            current_left = x
        else
            idx = idx + 1
        end
    end

    scissors.disable()

    current_left = current_left - advance
end

function M.updated_config_json(config)
    font = resource.load_font(api.localized(config.font.asset_name))
    color = config.color
    speed = config.speed

	-- NOT NEED TO GET TEXT FROM CONFIG 
    -- content.__myself__ = {}
    -- local texts = content.__myself__
    -- for idx = 1, #config.texts do
        -- texts[#texts+1] = {text = config.texts[idx].text}
    -- end
end


local concatter = function(s)
	local t = { }
	for k,v in ipairs(s) do
		t[#t+1] = tostring(v)
	end
	return table.concat(t,"")
end

local processOriginTicker = function(ticker)
	local newTextArray = ticker.TickerText
	local oldTexts = {}
	if ticker.IsResetText == false then
		oldTexts = content.__myself__
	end
		
	print(#newTextArray)
	local texts = {}
		
	-- add to start. Order from newest to oldest
	local sum = #oldTexts + #newTextArray
	if sum > 20 then
		texts = oldTexts
		for idx = 20 - #newTextArray, 1, -1 do
			texts[idx + #newTextArray] = oldTexts[idx]
		end 
		for idx = 1, #newTextArray do
			texts[idx] = {text = newTextArray[idx]}	
		end
	else
		texts = oldTexts
		for idx = sum - #newTextArray, 1, -1 do
			texts[idx + #newTextArray] = oldTexts[idx]
		end 
		for idx = 1, #newTextArray do
			texts[idx] = {text = newTextArray[idx]}	
		end
	end
		
		-- add to end. Order from oldest to newest
		-- local sum = #oldTexts + #newTextArray
		-- if sum > 20 then
			-- for idx = 1, #oldTexts - sum + 20 do
				-- texts[idx] = oldTexts[sum - 20 + idx]	
			-- end
			-- for idx = 1, #newTextArray do
				-- texts[#texts + 1] = {text = newTextArray[idx]}	
			-- end
		-- else
			-- texts = oldTexts
			-- for idx = 1, #newTextArray do
				-- texts[#texts + 1] = {text = newTextArray[idx]}	
			-- end
		-- end
		
	print("UPDATED TICKER TEXT !!!!!!!!!!!!!!!")
	for idx = 1, #texts do
		print(texts[idx].text)
	end
		
	return texts
end

local processTempTicker = function(ticker)
	local newTextArray = ticker.TickerText
	local texts = {}
	
	for idx = 1, #newTextArray do
		texts[idx] = {text = newTextArray[idx]}
	end 
	
	tempTickerFinish = sys.now() + ticker.ShownPeriodSeconds
	print("UPDATED TEMP TICKER TEXT !!!!!!!!!!!!!!!")
	for idx = 1, #texts do
		print(texts[idx].text)
	end
	
	return texts
end

local data = {}
util.data_mapper{
	["socket/ticker"] = function(text)
		print(text)
		data[#data + 1] = text
	end;
	["socket/end"] = function(text)
		data[#data + 1] = text
		
		local allDataString = concatter(data)
		local recievedDataOject = json.decode(allDataString)
		
		if recievedDataOject.ShownPeriodSeconds == 0 then
			content.__myself__ = processOriginTicker(recievedDataOject)
		else
			print("GOOOOOD")
			tempContent.__myself__ = processTempTicker(recievedDataOject)
		end
		
		isReset = true
		data = {}
	end;
}

function M.task(starts, ends, parent_config)
    for now, x1, y1, x2, y2 in api.from_to(starts, ends) do	
		print(sys.now())
		print(tempTickerFinish)
		if tempTickerFinish ~= 0 and sys.now() > tempTickerFinish then -- reset temp ticker
			tempTickerFinish = 0
			tempContent.__myself__ = nil
			isReset = true
		end
	
        draw_scroller(x1, y1, x2-x1, y2-y1, parent_config)
    end
end

return M
