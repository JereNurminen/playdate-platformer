function newEffect(x, y, animation)
    return {
        pos = {
            x = x,
            y = y
        },
        sprite = {
            offset = {
                x = 0,
                y = 0,
            }
        },
        currentAnimation = animation,
        flip = gfx.kImageUnflipped,
        cleanUpAfterDone = true
    }
end

function addJumpEffect(x, y)
    print("jump effect at " .. x .. ", " .. y)
    world:add(newEffect(x, y,
        gfx.animation.loop.new(100, jumpEffectImageTable, false)))
end