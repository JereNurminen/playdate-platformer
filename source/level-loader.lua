function loadLevel(world, systems, entitiesWithCollisions, entitiesWithoutCollisions, room)
    world:clearSystems()
    world:clearEntities()

    local levelColliders, bgImage = generateRoomEntities(room)
    
    world:add(bgImage)
    world:refresh()

    for i = 1, #systems do
        world:add(systems[i])
    end

    for i = 1, #levelColliders do
        addEntityWithCollisions(levelColliders[i])
    end

    for i = 1, #entitiesWithCollisions do
        addEntityWithCollisions(entitiesWithCollisions[i])
    end

    for i = 1, #entitiesWithoutCollisions do
        world:add(entitiesWithoutCollisions[i])
    end
end