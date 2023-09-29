local tiny = import "tiny-ecs/tiny"
local bump = import "bump/bump"

import("CoreLibs/timer")
import("CoreLibs/object")
import("CoreLibs/animation")

gfx = playdate.graphics;

local testRoom = import "rooms/test"

local foregroundTiles = gfx.imagetable.new("images/foreground", 3)

local playerIdleAnimation = gfx.animation.loop.new(100, playdate.graphics.imagetable.new("images/player-idle"), true)
local playerWalkAnimation = gfx.animation.loop.new(100, playdate.graphics.imagetable.new("images/player-walk"), true)
local playerJumpAnimation = gfx.animation.loop.new(100, playdate.graphics.imagetable.new("images/player-jump"), false)

ScreenSize = playdate.geometry.vector2D.new(400, 240)
local screenCenter <const> = playdate.geometry.point.new(
	(ScreenSize / 2):unpack()
)

DeltaTime = 0
LastFrameTime = 0

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
		if layers[i].type == "tilelayer" then
			local tiles = layers[i].data
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
							sprite = {
								offset = {
									x = 0,
									y = 0
								}
							},
							tileIndex = tile
						}
				)
				end
			end
		elseif layers[i].name == "platforms" then
			local colliders = layers[i].objects
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

	local levelImage = gfx.image.new(ScreenSize.x, ScreenSize.y)
	gfx.lockFocus(levelImage)
	for i = 1, #processedTiles do
		local x = processedTiles[i]
		if x.tileIndex ~= nil and x.tileIndex ~= 0  then
			local tile = foregroundTiles:getImage(x.tileIndex)
			tile:draw(x.pos.x, x.pos.y)
		end
	end
	gfx.unlockFocus()

	local levelBg = {
		image = levelImage
	}

	return processedColliders, levelBg
end

local playerMoveSystem = tiny.processingSystem()
playerMoveSystem.filter = tiny.requireAll("speed", "pos", "isPlayer", "momentum", "isGrounded", "jumpStrength", "coyoteTime", "timeSinceGrounded")
function playerMoveSystem:process(e)
	local moveVector = playdate.geometry.vector2D.new(0, 0)
	if (playdate.buttonIsPressed(playdate.kButtonLeft)) then
		moveVector.x = -1
		e.flip = gfx.kImageFlippedX
		if (e.isGrounded) then 
			e.currentAnimation = e.walkAnimation
		end
	elseif (playdate.buttonIsPressed(playdate.kButtonRight)) then
		moveVector.x = 1
		e.flip = gfx.kImageUnflipped
		if (e.isGrounded) then 
			e.currentAnimation = e.walkAnimation
		end
	elseif (e.isGrounded) then
		e.currentAnimation = e.idleAnimation
	end
	if (playdate.buttonJustPressed(playdate.kButtonA)) then
		if e.isGrounded or e.timeSinceGrounded <= e.coyoteTime then
			moveVector.y = -e.jumpStrength
			e.isGrounded = false
			e.currentAnimation = e.jumpAnimation
		end
	end

	e.momentum.x = moveVector.x * e.speed
	e.momentum.y = e.momentum.y + moveVector.y
end

local momentumSystem = tiny.processingSystem()
momentumSystem.filter = tiny.requireAll("momentum", "pos")
function momentumSystem:process(e, dt)
	local oldX = e.pos.x
	local oldY = e.pos.y
	local targetX = oldX + e.momentum.x * dt
	local targetY = oldY + e.momentum.y * dt
	local newX, newY = colliders:move(e, targetX, targetY)
	e.pos.x = newX
	e.pos.y = newY

	if oldX == newX then
		e.momentum.x = 0
	end
	if oldY == newY then
		e.momentum.y = 0
	end
end

local gravitySystem = tiny.processingSystem()
gravitySystem.filter = tiny.requireAll("fallAcceleration", "momentum")
function gravitySystem:process(e)
	if e.isGrounded == true then
		return
	end

	e.momentum.y = e.momentum.y + e.fallAcceleration
end

local drawSystem = tiny.processingSystem()
drawSystem.filter = tiny.requireAll("pos", "flip", "sprite")
function drawSystem:process(e)
	e.currentAnimation:draw(e.pos.x + e.sprite.offset.x, e.pos.y + e.sprite.offset.y, e.flip)
end

local collisionSyncSystem = tiny.processingSystem()
collisionSyncSystem.filter = tiny.requireAll("pos", "width", "height", "collisionLayer", "hitBox")
function collisionSyncSystem:process(e)
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
					e.currentAnimation = e.idleAnimation
				end
				return
			end
		end
	end

	e.isGrounded = false

	e.timeSinceGrounded = e.timeSinceGrounded + dt
end


local levelDrawSystem = tiny.processingSystem()
levelDrawSystem.filter = tiny.requireAll("image")
function levelDrawSystem:process(e)
	e.image:draw(0, 0)
end

local player = {
	isPlayer = true,
	speed = 100,
	pos = {
		x = 0,
		y = screenCenter.y - 42
	},
	momentum = playdate.geometry.vector2D.new(0, 0),
	width = 16,
	height = 16,
	color = gfx.kColorWhite,
    fallAcceleration = 35,
	jumpStrength = 400,
	gravityIgnoreLength = 1,
	collisionLayer = "player",
	isGrounded = false,
	timeSinceGrounded = 0,
	coyoteTime = 0.1,
	sprite = {
		offset = {
			x = -8,
			y = 0,
		}
	},
	walkAnimation = playerWalkAnimation,
	idleAnimation = playerIdleAnimation,
	jumpAnimation = playerJumpAnimation,
	currentAnimation = playerIdleAnimation,
	flip = gfx.kImageUnflipped
}

world:add(
	groundedSystem,
	playerMoveSystem,
    gravitySystem,
	drawSystem,
	momentumSystem,
	levelDrawSystem
)

addEntityWithCollisions(player)

local levelColliders, bgImage = generateRoomEntities(testRoom)

for i = 1, #levelColliders do
	addEntityWithCollisions(levelColliders[i])
end

world:add(bgImage)

world:refresh()
gfx.setBackgroundColor(gfx.kColorBlack)

function playdate:update(arg, ...)
	gfx.clear()
	
	-- run systems etc
	world:update(playdate.getElapsedTime())
	playdate:resetElapsedTime()
	playdate:drawFPS()
end

function playdate.debugDraw()
	playdate.setDebugDrawColor(1,0,0,1)
	gfx.drawRect(player.pos.x, player.pos.y, player.width, player.height)
end