player = {
	isPlayer = true,
	speed = 100,
	pos = {
		x = 16,
		y = ScreenCenter.y
	},
	momentum = playdate.geometry.vector2D.new(0, 0),
	width = 16,
	height = 16,
	color = gfx.kColorWhite,
    fallAcceleration = 45,
	jumpStrength = 350,
	gravityIgnoreLength = 1,
	collisionLayer = "player",
	isGrounded = false,
	timeSinceGrounded = 0,
	hasDoubleJumped = false,
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