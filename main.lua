-- written by groverbuger for g3d
-- september 2021
-- MIT license

local g3d = require "g3d"
local earth = g3d.newModel("assets/sphere.obj", "assets/earth.png", {4,0,0})
local moon = g3d.newModel("assets/sphere.obj", "assets/moon.png", {4,5,0}, nil, 0.5)
local background = g3d.newModel("assets/sphere.obj", "assets/starfield.png", nil, nil, 500)

-- center of moon orbit
local moonPivot = g3d.matrices.new():fromTranslation(4, 0, 0)

local rotateMatrix = g3d.matrices.new()

-- position of moon relative to the orbit center
local offsetMatrix = g3d.matrices.new():fromTranslation(0, 5, 0)

-- size of the moon
local scaleMatrix = g3d.matrices.new():fromScale(0.5, 0.5, 0.5)

function love.update(dt)

    -- 1. Reset rotateMatrix to the identity, rotated by dt radians around the Z axis.
    -- 2. Multiply moonPivot with rotateMatrix, rotating it by dt radians around Z.
    -- 3. Copy moonPivot's data into moon.matrix. moonPivot will not be modified again until the next update.
    -- 4. Multiply moon.matrix by offsetMatrix, shifting it 5 units in the Y axis relative to moonPivot's (now moon.matrix's) orientation.
    --      Because the shift is relative to the pivot orientation, the moon will stay tidally locked.
    -- 5. Multiply moon.matrix by scaleMatrix, shrinking the model. This should be done last to avoid having to adjust the translation offset.
    --      Alternatively, scaleMatrix is not actually necessary here since you can include the scale in offsetMatrix.

    moonPivot:multiply(rotateMatrix:fromRotation(0, 0, dt)):copyTo(moon.matrix):multiply(offsetMatrix):multiply(scaleMatrix)

    -- Ugly version that moves the moon around without spinning it. Done by grabbing the position component after pivot * offset then reconstructing the moon matrix with just those coordinates.

    -- moon.matrix:fromTranslation(moonPivot:multiply(rotateMatrix:fromRotation(0, 0, dt)):copyTo(moon.matrix):multiply(offsetMatrix):getTranslation()):multiply(scaleMatrix)


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
