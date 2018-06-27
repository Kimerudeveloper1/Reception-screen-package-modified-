gl.setup(NATIVE_WIDTH, NATIVE_HEIGHT)

node.alias "*" -- catch all communication

util.noglobals()

local json = require "json"
local easing = require "easing"
local loader = require "loader"

local min, max, abs, floor = math.min, math.max, math.abs, math.floor

local IDLE_ASSET = "empty.png"

local node_config = {}

local overlay_debug = false
local font_regl = resource.load_font "default-font.ttf"
local font_bold = resource.load_font "default-font-bold.ttf"


function node.render()
	print(WIDTH, HEIGHT)	
	WIDTH, HEIGHT = HEIGHT, WIDTH
	print(WIDTH, HEIGHT)
	gl.translate(HEIGHT, 0)
    gl.rotate(90, 0, 0, 1)
	font_regl:write(0, 0, "Hello World", 100, 1,1,1,1)
end
