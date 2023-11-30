momentumSystem = Tiny.processingSystem()
momentumSystem.filter = Tiny.requireAll("momentum", "pos")
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

gravitySystem = Tiny.processingSystem()
gravitySystem.filter = Tiny.requireAll("fallAcceleration", "momentum")
function gravitySystem:process(e)
	if e.isGrounded == true then
		return
	end

	e.momentum.y = e.momentum.y + e.fallAcceleration
end

collisionSyncSystem = Tiny.processingSystem()
collisionSyncSystem.filter = Tiny.requireAll("pos", "width", "height", "collisionLayer", "hitBox")
function collisionSyncSystem:process(e)
	colliders:update(e, e.pos.x, e.pos.y, e.width, e.height)
end

groundedSystem = Tiny.processingSystem()
groundedSystem.filter = Tiny.requireAll("isGrounded", "pos")
function groundedSystem:process(e, dt)
	local actualX, actualY, cols, len = colliders:check(e, e.pos.x, e.pos.y + 1, nil)
	local wasGrounded = e.isGrounded
	if len > 0 then
		for i = 1, len do
			local other = cols[i].other
			if other.collisionLayer == "platform" then
				e.isGrounded = true
				
				if e.hasDoubleJumped ~= nil then
					e.hasDoubleJumped = false
				end

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