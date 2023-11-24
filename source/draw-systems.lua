levelDrawSystem = Tiny.processingSystem()
levelDrawSystem.filter = Tiny.requireAll("image")
function levelDrawSystem:process(e)
	e.image:draw(0, 0)
end

drawSystem = Tiny.processingSystem()
drawSystem.filter = Tiny.requireAll("pos", "flip", "sprite", "currentAnimation")
function drawSystem:process(e)
	e.currentAnimation:draw(e.pos.x + e.sprite.offset.x, e.pos.y + e.sprite.offset.y, e.flip)
end