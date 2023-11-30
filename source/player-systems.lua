local function isCoyoteTime(e)
	return e.timeSinceGrounded <= e.coyoteTime
end

playerMoveSystem = Tiny.processingSystem()
playerMoveSystem.filter = Tiny.requireAll(
	"speed",
	"pos",
	"isPlayer",
	"momentum",
	"isGrounded",
	"jumpStrength",
	"coyoteTime",
	"timeSinceGrounded"
)
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
		-- normal jump
		if e.isGrounded or
		   isCoyoteTime(e) then
			moveVector.y = -e.jumpStrength
			e.isGrounded = false
			e.currentAnimation = e.jumpAnimation
			addJumpEffect(e.pos.x, e.pos.y)
		end
		-- double jump
		if not e.isGrounded and
		   not e.hasDoubleJumped and
		   not isCoyoteTime(e) then
			moveVector.y = -e.momentum.y - e.jumpStrength
			e.isGrounded = false
			e.currentAnimation = e.jumpAnimation
			e.hasDoubleJumped = true
			addJumpEffect(e.pos.x, e.pos.y)
		end
	end

	e.momentum.x = moveVector.x * e.speed
	e.momentum.y = e.momentum.y + moveVector.y
end