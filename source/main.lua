-- 3rd party libs
Bump = import "bump/Bump"
Tiny = import "tiny-ecs/Tiny"

colliders = Bump.newWorld()
world = Tiny.world()

-- Playdate libs
import("CoreLibs/timer")
import("CoreLibs/object")
import("CoreLibs/animation")
gfx = playdate.graphics;

-- global constants
ScreenSize = playdate.geometry.vector2D.new(400, 240)
ScreenCenter = playdate.geometry.point.new(
	(ScreenSize / 2):unpack()
)
DeltaTime = 0
LastFrameTime = 0

-- assets
playerIdleAnimation = gfx.animation.loop.new(100, playdate.graphics.imagetable.new("images/player-idle"), true)
playerWalkAnimation = gfx.animation.loop.new(100, playdate.graphics.imagetable.new("images/player-walk"), true)
playerJumpAnimation = gfx.animation.loop.new(100, playdate.graphics.imagetable.new("images/player-jump"), false)
jumpEffectImageTable = playdate.graphics.imagetable.new("images/player-jump-fx")
foregroundTiles = gfx.imagetable.new("images/foreground", 3)

-- utilities
function addEntityWithCollisions(e)
	world:add(e)
	colliders:add(e, e.pos.x, e.pos.y, e.width, e.height)
end


-- setup functions
import "room-setup"
import "level-loader"

-- entities
import "jump-effect-entity"
import "player-entity"

-- systems
import "player-systems"
import "draw-systems"
import "physics-systems"

-- levels
local testRoom = import "rooms/test"

--

baseSystems = {
	groundedSystem,
	playerMoveSystem,
    gravitySystem,
	drawSystem,
	cleanUpSystem,
	momentumSystem,
	levelDrawSystem
}

loadLevel(world, baseSystems, {player}, {}, testRoom)

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
