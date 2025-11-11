-- written by groverbuger for g3d
-- september 2021
-- MIT license

local g3d = require "g3d"
local earth = g3d.newModel("assets/sphere.obj", "assets/earth.png", {4,0,0})
local moon = g3d.newModel("assets/sphere.obj", "assets/moon.png", {4,5,0}, nil, 0.5)
local background = g3d.newModel("assets/sphere.obj", "assets/starfield.png", nil, nil, 500)

-- center of moon orbit
local moonPivot = g3d.matrices.new()
moonPivot:fromTranslation(4, 0, 0)

local rotateMatrix = g3d.matrices.new()

-- position of moon relative to the orbit center
local offsetMatrix = g3d.matrices.new()
offsetMatrix:fromTranslation(0, 5, 0)

-- size of the moon
local scaleMatrix = g3d.matrices.new()
scaleMatrix:fromScale(0.5, 0.5, 0.5)

function love.update(dt)

    -- adjust the rotate to increment at 2pi radians/second
    rotateMatrix:fromRotation(0, 0, dt)
    -- rotate the pivot by the increment amount
    moonPivot:multiply(rotateMatrix)
    -- transfer moonPivot's data to moon.matrix, leaving moonPivot unchanged until the next step
    moonPivot:copyTo(moon.matrix)
    -- shift the moon's position and set it's scale
    -- it's important that scale is multiplied last
    moon.matrix:multiply(offsetMatrix)
    moon.matrix:multiply(scaleMatrix)

    g3d.camera.firstPersonMovement(dt)
    if love.keyboard.isDown "escape" then
        love.event.push "quit"
    end
end

function love.draw()
    earth:draw()
    moon:draw()
    background:draw()
end

function love.mousemoved(x,y, dx,dy)
    g3d.camera.firstPersonLook(dx,dy)
end
