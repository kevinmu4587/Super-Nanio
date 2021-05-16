--[[ CLASS UTIL.LUA
    -- used to generate an array of sprites given a spritesheet
]]

--[[ function generateQuads()
    -- used to split the spritesheet and read it into the array quads{}
]]
function generateQuads(atlas, tilewidth, tileheight)
    -- number of items horizontally
    local sheetWidth = atlas:getWidth() / tilewidth
    -- number of items vertically
    local sheetHeight = atlas:getHeight() / tileheight

    -- index (arrays are 1-indexed)
    local sheetCounter = 1
    -- list to store sprites
    local quads = {}

    -- loop through every element in the spritesheet
    for y = 0, sheetHeight - 1 do
        for x = 0, sheetWidth - 1 do
            -- add one sprite into the list
            --[[
                -- love.graphics.newQuad() PARAMETERS:
                1. starting x-coordinate pixel
                2. starting y-coordinate pixel
                3. length of block (16 pixels)
                4. height of block (16 pixels)
                5. requisite; dimensions of spritesheet
            ]]
            quads[sheetCounter] = love.graphics.newQuad(x * tilewidth, y * tileheight, tilewidth, tileheight, atlas:getDimensions())
            sheetCounter = sheetCounter + 1
        end
    end 
    return quads
end