local tiny = import "tiny-ecs/tiny"
local bump = import "bump/bump"

import("CoreLibs/timer")
import("CoreLibs/object")

gfx = playdate.graphics;

local testRoom = import "rooms/test"

--
-- GLOBALS
DeltaTime = 0
LastFrameTime = 0

ScreenSize = playdate.geometry.vector2D.new(400, 240)
local screenCenter <const> = playdate.geometry.point.new(
	(ScreenSize / 2):unpack()
)

local colliders = bump.newWorld()
local world = tiny.world()

local function addEntityWithCollisions(e)
	world:add(e)
	colliders:add(e, e.pos.x, e.pos.y, e.width, e.height)
end
--

local function generateRoomEntities(room)
	local layers = room.layers
	local image = gfx.imagetable.new("images/foreground", 3)
	local tilemap = gfx.tilemap.new()
	tilemap:setImageTable(image)
	local processedTiles = {}
	local processedColliders = {}
	for i = 1, #layers do
		if layers[i].type == "tiles" then
			local tiles = layers[i].tiles
			for columnIndex = 0, room.width do
				for rowIndex = 0, room.height do
					local tile = tiles[rowIndex * room.width + columnIndex + 1]
					local width = room.tilewidth
					local height = room.tileheight
					local x = (columnIndex) * width
					local y = (rowIndex) * height
					table.insert(
						processedTiles,
						{
							width = width,
							height = height,
							pos = {
								x = x,
								y = y
							},
							tileIndex = tile
						}
				)
				end
			end
		elseif layers[i].type == "colliders" then
			local colliders = layers[i].colliders
			for k = 1, #colliders do
				local collider = colliders[k]
				table.insert(
					processedColliders,
					{
						pos = {
							x = collider.x,
							y = collider.y
						},
						width = collider.width,
						height = collider.height,
						collisionLayer = "platform"
					}
			)
			end
		end
	end

	return processedTiles, processedColliders
end

local playerMoveSystem = tiny.processingSystem()
playerMoveSystem.filter = tiny.requireAll("speed", "pos", "isPlayer", "momentum", "isGrounded", "jumpStrength", "coyoteTime", "timeSinceGrounded")
function playerMoveSystem:process(e, dt)
	local moveVector = playdate.geometry.vector2D.new(0, 0)
	if (playdate.buttonIsPressed(playdate.kButtonLeft)) then
		moveVector.x = -1
	end
	if (playdate.buttonIsPressed(playdate.kButtonRight)) then
		moveVector.x = 1
	end
	if (playdate.buttonJustPressed(playdate.kButtonA)) then
		if e.isGrounded or e.timeSinceGrounded <= e.coyoteTime then
			moveVector.y = -e.jumpStrength
			e.isGrounded = false
		end
	end

	e.momentum.x = moveVector.x * e.speed
	e.momentum.y = e.momentum.y + moveVector.y
end

local momentumSystem = tiny.processingSystem()
momentumSystem.filter = tiny.requireAll("momentum", "pos")
function momentumSystem:process(e, dt)
	local targetX = e.pos.x + e.momentum.x * dt
	local targetY = e.pos.y + e.momentum.y * dt
	local newX, newY = colliders:move(e, targetX, targetY)
	e.pos.x = newX
	e.pos.y = newY
end

local gravitySystem = tiny.processingSystem()
gravitySystem.filter = tiny.requireAll("fallAcceleration", "momentum")
function gravitySystem:process(e, dt)
	if e.isGrounded == true then
		return
	end

	local vector = playdate.geometry.vector2D.new(0, e.fallAcceleration)
	e.momentum.y = e.momentum.y + e.fallAcceleration
end

local drawSystem = tiny.processingSystem()
drawSystem.filter = tiny.requireAll("color", "pos", tiny.requireAny("width", "height"))
function drawSystem:process(e, dt)
	local w = e.width or 1
	local h = e.height or 1
	if e.color == gfx.kColorWhite then
		gfx.setColor(gfx.kColorWhite)
		gfx.fillRect(e.pos.x, e.pos.y, w, h)
		gfx.setColor(gfx.kColorBlack)
		gfx.setLineWidth(2)
		gfx.drawRect(e.pos.x, e.pos.y, w, h)
	else -- default to black fill
		gfx.setColor(e.color)
		gfx.fillRect(e.pos.x, e.pos.y, w, h)
	end
end

local collisionSyncSystem = tiny.processingSystem()
collisionSyncSystem.filter = tiny.requireAll("pos", "width", "height", "collisionLayer")
function collisionSyncSystem:process(e, dt)
	colliders:update(e, e.pos.x, e.pos.y, e.width, e.height)
end

local groundedSystem = tiny.processingSystem()
groundedSystem.filter = tiny.requireAll("isGrounded", "pos")
function groundedSystem:process(e, dt)
	local actualX, actualY, cols, len = colliders:check(e, e.pos.x, e.pos.y + 1, nil)
	local wasGrounded = e.isGrounded
	if len > 0 then
		for i = 1, len do
			local other = cols[i].other
			if other.collisionLayer == "platform" then
				e.isGrounded = true

				if not wasGrounded and e.isGrounded then
					e.timeSinceGrounded = 0
					if e.momentum ~= nil then
						e.momentum.y = 0
					end
				end
				return
			end
		end
	end

	e.isGrounded = false

	e.timeSinceGrounded = e.timeSinceGrounded + dt
end

local tileDrawSystem = tiny.processingSystem()
tileDrawSystem.filter = tiny.requireAll("pos", "tileIndex")
function tileDrawSystem:process(e, dt)
	if e.tileIndex ~= 0 then
		local image = gfx.imagetable.new("images/foreground", 3)
		local tile = image:getImage(e.tileIndex)
		tile:draw(e.pos.x, e.pos.y)
	end
end

local player = {
	isPlayer = true,
	speed = 100,
	pos = {
		x = 0,
		y = screenCenter.y - 42
	},
	momentum = playdate.geometry.vector2D.new(0, 0),
	width = 32,
	height = 32,
	color = gfx.kColorWhite,
    fallAcceleration = 35,
	jumpStrength = 400,
	gravityIgnoreLength = 1,
	collisionLayer = "player",
	isGrounded = false,
	timeSinceGrounded = 0,
	coyoteTime = 0.1,
}

world:add(
	groundedSystem,
	playerMoveSystem,
    gravitySystem,
	drawSystem,
	momentumSystem,
	tileDrawSystem
)

addEntityWithCollisions(player)

local tiles, levelColliders = generateRoomEntities(testRoom)

for i = 1, #levelColliders do
	addEntityWithCollisions(levelColliders[i])
end

for i = 1, #tiles do
	world:add(tiles[i])
end

world:refresh()
gfx.setBackgroundColor(gfx.kColorBlack)

function playdate:update(arg, ...)
	playdate.timer.updateTimers()
	gfx.clear()
	DeltaTime = ( playdate.getCurrentTimeMilliseconds() - LastFrameTime ) / 1000
	
	-- run systems etc
	world:update(DeltaTime)
	LastFrameTime = playdate.getCurrentTimeMilliseconds()
end
