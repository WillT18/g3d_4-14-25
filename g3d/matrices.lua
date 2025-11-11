-- written by groverbuger for g3d
-- september 2021
-- MIT license

local vectors = require(g3d.path .. ".vectors")
local vectorCrossProduct = vectors.crossProduct
local vectorDotProduct = vectors.dotProduct
local vectorNormalize = vectors.normalize
local vectorMagnitude = vectors.magnitude

----------------------------------------------------------------------------------------------------
-- matrix class
----------------------------------------------------------------------------------------------------
-- matrices are 16 numbers in table, representing a 4x4 matrix like so:
--
--       fwd  side  up  pos
--
--  x  |  1    2    3    4  |
--     |                    |
--  y  |  5    6    7    8  |
--     |                    |
--  z  |  9    10   11   12 |
--     |                    |
--     |  13   14   15   16 |

local matrix = {}
matrix.__index = matrix

function matrix.new()
    local self = setmetatable({}, matrix)

    -- initialize a matrix as the identity matrix
    self[1],  self[2],  self[3],  self[4]  = 1, 0, 0, 0
    self[5],  self[6],  self[7],  self[8]  = 0, 1, 0, 0
    self[9],  self[10], self[11], self[12] = 0, 0, 1, 0
    self[13], self[14], self[15], self[16] = 0, 0, 0, 1

    return self
end

-- Revert a matrix to the identity matrix
-- Multiplying a matrix by this does nothing
function matrix:reset()
    self[1],  self[2],  self[3],  self[4]  = 1, 0, 0, 0
    self[5],  self[6],  self[7],  self[8]  = 0, 1, 0, 0
    self[9],  self[10], self[11], self[12] = 0, 0, 1, 0
    self[13], self[14], self[15], self[16] = 0, 0, 0, 1
end

-- Revert to default rotation offset by a specified translation
-- Multiplying a matrix by this shifts it in its relative space
function matrix:fromTranslation(x, y, z)
    self[1],  self[2],  self[3],  self[4]  = 1, 0, 0, x
    self[5],  self[6],  self[7],  self[8]  = 0, 1, 0, y
    self[9],  self[10], self[11], self[12] = 0, 0, 1, z
    self[13], self[14], self[15], self[16] = 0, 0, 0, 1
end

-- Revert to the origin rotated by specified euler angles
-- Multiplying a matrix by this rotates it in it relative space
function matrix:fromRotation(x, y, z)
    local ca, cb, cc = math.cos(z), math.cos(y), math.cos(x)
    local sa, sb, sc = math.sin(z), math.sin(y), math.sin(x)
    self[1],  self[2],  self[3],  self[4]  = ca*cb, ca*sb*sc - sa*cc, ca*sb*cc + sa*sc, 0
    self[5],  self[6],  self[7],  self[8]  = sa*cb, sa*sb*sc + ca*cc, sa*sb*cc - ca*sc, 0
    self[9],  self[10], self[11], self[12] = -sb, cb*sc, cb*cc, 0
    self[13], self[14], self[15], self[16] = 0, 0, 0, 1
end

-- Unit matrix with scaled rotation vectors
-- Useful for changing the dimensions of a model
function matrix:fromScale(x, y, z)
    self[1],  self[2],  self[3],  self[4]  = x, 0, 0, 0
    self[5],  self[6],  self[7],  self[8]  = 0, y, 0, 0
    self[9],  self[10], self[11], self[12] = 0, 0, z, 0
    self[13], self[14], self[15], self[16] = 0, 0, 0, 1
end

-- automatically converts a matrix to a string
-- for printing to console and debugging
function matrix:__tostring()
    return ("%f\t%f\t%f\t%f\n%f\t%f\t%f\t%f\n%f\t%f\t%f\t%f\n%f\t%f\t%f\t%f"):format(unpack(self))
end

----------------------------------------------------------------------------------------------------
-- transformation, projection, and rotation matrices
----------------------------------------------------------------------------------------------------
-- the three most important matrices for 3d graphics
-- these three matrices are all you need to write a simple 3d shader

-- returns a transformation matrix
-- translation, rotation, and scale are all 3d vectors
function matrix:setTransformationMatrix(translation, rotation, scale)
    -- translations
    self[4]  = translation[1]
    self[8]  = translation[2]
    self[12] = translation[3]

    -- rotations
    if #rotation == 3 then
        -- use 3D rotation vector as euler angles
        -- source: https://en.wikipedia.org/wiki/Rotation_matrix
        local ca, cb, cc = math.cos(rotation[3]), math.cos(rotation[2]), math.cos(rotation[1])
        local sa, sb, sc = math.sin(rotation[3]), math.sin(rotation[2]), math.sin(rotation[1])
        self[1], self[2],  self[3]  = ca*cb, ca*sb*sc - sa*cc, ca*sb*cc + sa*sc
        self[5], self[6],  self[7]  = sa*cb, sa*sb*sc + ca*cc, sa*sb*cc - ca*sc
        self[9], self[10], self[11] = -sb, cb*sc, cb*cc
    else
        -- use 4D rotation vector as a quaternion
        local qx, qy, qz, qw = rotation[1], rotation[2], rotation[3], rotation[4]
        self[1], self[2],  self[3]  = 1 - 2*qy^2 - 2*qz^2, 2*qx*qy - 2*qz*qw,   2*qx*qz + 2*qy*qw
        self[5], self[6],  self[7]  = 2*qx*qy + 2*qz*qw,   1 - 2*qx^2 - 2*qz^2, 2*qy*qz - 2*qx*qw
        self[9], self[10], self[11] = 2*qx*qz - 2*qy*qw,   2*qy*qz + 2*qx*qw,   1 - 2*qx^2 - 2*qy^2
    end

    -- scale
    local sx, sy, sz = scale[1], scale[2], scale[3]
    self[1], self[2],  self[3]  = self[1] * sx, self[2]  * sy, self[3]  * sz
    self[5], self[6],  self[7]  = self[5] * sx, self[6]  * sy, self[7]  * sz
    self[9], self[10], self[11] = self[9] * sx, self[10] * sy, self[11] * sz

    -- fourth row is not used, just set it to the fourth row of the identity matrix
    self[13], self[14], self[15], self[16] = 0, 0, 0, 1
end

function matrix:getScale()
    -- does not account for negative scaling
    local sx = vectorMagnitude(self[1], self[5], self[9])
    local sy = vectorMagnitude(self[2], self[6], self[10])
    local sz = vectorMagnitude(self[3], self[7], self[11])
    return sx, sy, sz
end

-- transpose of the camera (look at) matrix
function matrix:lookAtFrom(pos, target, up, orig_scale)
    self[4]  = pos[1]
    self[8]  = pos[2]
    self[12] = pos[3]

    local sx, sy, sz
    if orig_scale then
        sx, sy, sz = unpack(orig_scale)
    else
        sx, sy, sz = self:getScale()
    end

    -- forward, side, up directions
    local f_x, f_y, f_z = vectorNormalize(pos[1]-target[1], pos[2]-target[2], pos[3]-target[3])
    local s_x, s_y, s_z = vectorNormalize(vectorCrossProduct(up[1],up[2],up[3], f_x,f_y,f_z))
    local u_x, u_y, u_z = vectorCrossProduct(f_x,f_y,f_z, s_x,s_y,s_z)

    self[1], self[2], self[3]   = f_x*sx, s_x*sy, u_x*sz
    self[5], self[6], self[7]   = f_y*sx, s_y*sy, u_y*sz
    self[9], self[10], self[11] = f_z*sx, s_z*sy, u_z*sz
end

-- Overwrite another matrix's values with this matrix's values
function matrix:copyTo(other)
    for i = 1, 16 do
        other[i] = self[i]
    end
end

-- Overwrite this matrix's values with another matrix's values
function matrix:copyFrom(other)
    matrix.copyTo(other, self)
end

-- Duplicate this matrix
-- Useful because multiply alters the first matrix's values instead of constructing a new one, and the original may need to be preserved for some reason
function matrix:copyNew()
    local new = matrix.new()
    matrix.copyTo(self, new)
    return new
end

-- Shift a matrix's position in absolute space
function matrix:offset(x, y, z)
    self[4] = self[4] + x
    self[8] = self[8] + y
    self[12] = self[12] + z
end

-- Multiply this matrix by another matrix
-- This matrix becomes the result of the operation, so if the original needs to be preserved it should be copied first
function matrix:multiply(other)
    local a11, a12, a13, a14, a21, a22, a23, a24, a31, a32, a33, a34, a41, a42, a43, a44 = unpack(self)
    local b11, b12, b13, b14, b21, b22, b23, b24, b31, b32, b33, b34, b41, b42, b43, b44 = unpack(other)
    -- first row
    self[1] = a11*b11 + a12*b21 + a13*b31 + a14*b41
    self[2] = a11*b12 + a12*b22 + a13*b32 + a14*b42
    self[3] = a11*b13 + a12*b23 + a13*b33 + a14*b43
    self[4] = a11*b14 + a12*b24 + a13*b34 + a14*b44
    -- second row
    self[5] = a21*b11 + a22*b21 + a23*b31 + a24*b41
    self[6] = a21*b12 + a22*b22 + a23*b32 + a24*b42
    self[7] = a21*b13 + a22*b23 + a23*b33 + a24*b43
    self[8] = a21*b14 + a22*b24 + a23*b34 + a24*b44
    -- third row
    self[9] = a31*b11 + a32*b21 + a33*b31 + a34*b41
    self[10]= a31*b12 + a32*b22 + a33*b32 + a34*b42
    self[11]= a31*b13 + a32*b23 + a33*b33 + a34*b43
    self[12]= a31*b14 + a32*b24 + a33*b34 + a34*b44
    -- fourth row
    self[13]= a41*b11 + a42*b21 + a43*b31 + a44*b41
    self[14]= a41*b12 + a42*b22 + a43*b32 + a44*b42
    self[15]= a41*b13 + a42*b23 + a43*b33 + a44*b43
    self[16]= a41*b14 + a42*b24 + a43*b34 + a44*b44
end

-- Determinant of the matrix
function matrix:determinant()
    local a11, a12, a13, a14, a21, a22, a23, a24, a31, a32, a33, a34, a41, a42, a43, a44 = unpack(self)
    return
          a11 * (a22*a33*a44 + a23*a34*a42 + a24*a32*a43
                -a24*a33*a42 - a22*a34*a43 - a23*a32*a44)
        - a12 * (a21*a33*a44 + a23*a34*a41 + a24*a31*a43
                -a24*a33*a41 - a21*a34*a43 - a23*a31*a44)
        + a13 * (a21*a32*a44 + a22*a34*a41 + a24*a31*a42
                -a24*a32*a41 - a21*a34*a42 - a22*a31*a44)
        - a14 * (a21*a32*a43 + a22*a33*a41 + a23*a31*a42
                -a23*a32*a41 - a21*a33*a42 - a22*a31*a43)
end

-- Inverse of the matrix
-- An invertible matrix multiplied by its inverse is the identity matrix
function matrix:invert()
    local a11, a12, a13, a14, a21, a22, a23, a24, a31, a32, a33, a34, a41, a42, a43, a44 = unpack(self)

    local i11 =  a22*a33*a44 - a22*a34*a43 - a32*a23*a44 + a32*a24*a43 + a42*a23*a34 - a42*a24*a33
    local i12 = -a12*a33*a44 + a12*a34*a43 + a32*a13*a44 - a32*a14*a43 - a42*a13*a34 + a42*a14*a33
    local i13 =  a12*a23*a44 - a12*a24*a43 - a22*a13*a44 + a22*a14*a43 + a42*a13*a24 - a42*a14*a23
    local i14 = -a12*a23*a34 + a12*a24*a33 + a22*a13*a34 - a22*a14*a33 - a32*a13*a24 + a32*a14*a23

    local i21 = -a21*a33*a44 + a21*a34*a43 + a31*a23*a44 - a31*a24*a43 - a41*a23*a34 + a41*a24*a33
    local i22 =  a11*a33*a44 - a11*a34*a43 - a31*a13*a44 + a31*a14*a43 + a41*a13*a34 - a41*a14*a33
    local i23 = -a11*a23*a44 + a11*a24*a43 + a21*a13*a44 - a21*a14*a43 - a41*a13*a24 + a41*a14*a23
    local i24 =  a11*a23*a34 - a11*a24*a33 - a21*a13*a34 + a21*a14*a33 + a31*a13*a24 - a31*a14*a23

    local i31  =  a21*a32*a44 - a21*a34*a42 - a31*a22*a44 + a31*a24*a42 + a41*a22*a34 - a41*a24*a32
    local i32 = -a11*a32*a44 + a11*a34*a42 + a31*a12*a44 - a31*a14*a42 - a41*a12*a34 + a41*a14*a32
    local i33 =  a11*a22*a44 - a11*a24*a42 - a21*a12*a44 + a21*a14*a42 + a41*a12*a24 - a41*a14*a22
    local i34 = -a11*a22*a34 + a11*a24*a32 + a21*a12*a34 - a21*a14*a32 - a31*a12*a24 + a31*a14*a22

    local i41 = -a21*a32*a43 + a21*a33*a42 + a31*a22*a43 - a31*a23*a42 - a41*a22*a33 + a41*a23*a32
    local i42 =  a11*a32*a43 - a11*a33*a42 - a31*a12*a43 + a31*a13*a42 + a41*a12*a33 - a41*a13*a32
    local i43 = -a11*a22*a43 + a11*a23*a42 + a21*a12*a43 - a21*a13*a42 - a41*a12*a23 + a41*a13*a22
    local i44 =  a11*a22*a33 - a11*a23*a32 - a21*a12*a33 + a21*a13*a32 + a31*a12*a23 - a31*a13*a22

    local det = a11*i11 + a12*i21 + a13*i31 + a14*i41
    --assert(det ~= 0, "Matrix has no inverse.")
    if (det ~= 0) then
        self[1], self[2], self[3], self[4] = i11, i12, i13, i14
        self[5], self[6], self[7], self[8] = i21, i22, i23, i24
        self[9], self[10],self[11],self[12]= i31, i32, i33, i34
        self[13],self[14],self[15],self[16]= i41, i42, i43, i44
    end
end

----------------------------------------------------------------------------------------------------
-- camera transformations
----------------------------------------------------------------------------------------------------

-- returns a perspective projection matrix
-- (things farther away appear smaller)
-- all arguments are scalars aka normal numbers
-- aspectRatio is defined as window width divided by window height
function matrix:setProjectionMatrix(fov, near, far, aspectRatio)
    local top = near * math.tan(fov/2)
    local bottom = -1*top
    local right = top * aspectRatio
    local left = -1*right

    self[1],  self[2],  self[3],  self[4]  = 2*near/(right-left), 0, (right+left)/(right-left), 0
    self[5],  self[6],  self[7],  self[8]  = 0, 2*near/(top-bottom), (top+bottom)/(top-bottom), 0
    self[9],  self[10], self[11], self[12] = 0, 0, -1*(far+near)/(far-near), -2*far*near/(far-near)
    self[13], self[14], self[15], self[16] = 0, 0, -1, 0
end

-- returns an orthographic projection matrix
-- (things farther away are the same size as things closer)
-- all arguments are scalars aka normal numbers
-- aspectRatio is defined as window width divided by window height
function matrix:setOrthographicMatrix(fov, size, near, far, aspectRatio)
    local top = size * math.tan(fov/2)
    local bottom = -1*top
    local right = top * aspectRatio
    local left = -1*right

    self[1],  self[2],  self[3],  self[4]  = 2/(right-left), 0, 0, -1*(right+left)/(right-left)
    self[5],  self[6],  self[7],  self[8]  = 0, 2/(top-bottom), 0, -1*(top+bottom)/(top-bottom)
    self[9],  self[10], self[11], self[12] = 0, 0, -2/(far-near), -(far+near)/(far-near)
    self[13], self[14], self[15], self[16] = 0, 0, 0, 1
end

-- returns a view matrix
-- eye, target, and up are all 3d vectors
function matrix:setViewMatrix(eye, target, up)
    local z1, z2, z3 = vectorNormalize(eye[1] - target[1], eye[2] - target[2], eye[3] - target[3])
    local x1, x2, x3 = vectorNormalize(vectorCrossProduct(up[1], up[2], up[3], z1, z2, z3))
    local y1, y2, y3 = vectorCrossProduct(z1, z2, z3, x1, x2, x3)

    self[1],  self[2],  self[3],  self[4]  = x1, x2, x3, -1*vectorDotProduct(x1, x2, x3, eye[1], eye[2], eye[3])
    self[5],  self[6],  self[7],  self[8]  = y1, y2, y3, -1*vectorDotProduct(y1, y2, y3, eye[1], eye[2], eye[3])
    self[9],  self[10], self[11], self[12] = z1, z2, z3, -1*vectorDotProduct(z1, z2, z3, eye[1], eye[2], eye[3])
    self[13], self[14], self[15], self[16] = 0, 0, 0, 1
end

return setmetatable(matrix, {__call = matrix.new})
