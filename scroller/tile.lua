local api, CHILDS, CONTENTS = ...

local json = require "json"
local scissors = sys.get_ext "scissors"

local font
local color
local speed

local M = {}

-- { source: { text1, text2, text3, ...} }
local content = {__myself__ = {}}

local function mix_content()
    local out = {}
    local offset = 1
    while true do
        local added = false
        for tile, items in pairs(content) do
            if items[offset] then
                out[#out+1] = items[offset]
                added = true
            end
        end
        if not added then
            break
        end
        offset = offset + 1
    end
    return out
end

local feed = util.generator(mix_content).next

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
local data = {}
util.data_mapper{
	["socket/ticker"] = function(text)
		print('LOOOOOOOOOOOOOOK THERE')
        print(text)
		
		-- local oldTexts = content.__myself__
	
		-- local newTextArray = json.decode(text)
		-- local texts = {}
		
		-- local sum = #oldTexts + #newTextArray
		-- if sum > 20 then
			-- for idx = 1, #oldTexts - sum + 20 do
				-- texts[idx] = oldTexts[sum - 20 + idx]	
			-- end
		-- end

		-- for idx = 1, #newTextArray do
			-- texts[#texts + 1] = {text = newTextArray[idx]}	
		-- end
		
		-- print("UPDATE TICKER TEXT !!!!!!!!!!!!!!!")
		-- for idx = 1, #texts do
			-- print(texts[idx].text)
		-- end
		
		-- content.__myself__ = texts
		-- end;
		
		data[#data + 1] = text
	end;
	["socket/end"] = function(text2)
		print('LOOOOOOOOOOOOOOK THERE LAST')
        print(text2)
		data[#data + 1] = text2
		
		local s = concatter(data)
		print(s:sub(57880, 57900))
		local newTextArray = json.decode(s)
		local texts = {}
		for idx = 1, #newTextArray do
			texts[idx] = {text = newTextArray[idx]}
		end
		-- end
		
		print("UPDATE TICKER TEXT !!!!!!!!!!!!!!!")
		for idx = 1, #texts do
			print(texts[idx].text)
		end
		
		content.__myself__ = texts
		
		data = ""
	end;
}


function M.task(starts, ends, parent_config)
    for now, x1, y1, x2, y2 in api.from_to(starts, ends) do
        draw_scroller(x1, y1, x2-x1, y2-y1, parent_config)
    end
end

return M
