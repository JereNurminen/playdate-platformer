function generateRoomEntities(room)
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
