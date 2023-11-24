player = {
	isPlayer = true,
	speed = 100,
	pos = {
		x = 0,
		y = ScreenCenter.y - 42
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