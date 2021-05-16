--[[ CLASS MAP.LUA
    - initializes, stores, and renders the map
    - uses help class Util.lua to generate quads from the spritesheet
]]

Map = Class{}

-- Constants for tiles
TILE_BRICK = 1
TILE_EMPTY = 4

BUSH_LEFT = 2
BUSH_RIGHT = 3

BLOCK = 5

CLOUD_LEFT = 6
CLOUD_RIGHT = 7

BLOCK_HIT = 9 
MUSHROOM_TOP = 10
MUSHROOM_STEM = 11

SKULL = 17

SCROLL_SPEED = 120


function Map:init()
    -- spritesheet image
    self.spritesheet = love.graphics.newImage('graphics/spritesheetC.png')

    -- pixel dimensions of each sprite
    self.tileWidth = 16
    self.tileHeight = 16

    -- dimensions of map; how many blocks 
    self.mapWidth = 100
    self.mapHeight = 28

    -- tiles on the map; stores index (from 1) of sprite from tileSprites
    self.tiles = {}

    -- stores a list of size 16, each a sprite (texture object)
    self.tileSprites = generateQuads(self.spritesheet, self.tileWidth, self.tileHeight)   

    -- camera coordinates
    self.camX = 0
    self.camY = 0

    --dimensions of map in pixels
    self.mapWidthPixels = self.tileWidth * self.mapWidth
    self.mapHeightPixels = self.tileHeight * self.mapHeight

    self.player = Player(self)

    -- fill screen with empty blocks
    for y = 1, self.mapHeight do
        for x = 1, self.mapWidth do
            -- set tile at index x,y to be empty
            self:setTile(x, y, TILE_EMPTY)
        end 
    end

    -- procedurally generate clouds, bushes, mushrooms and blocks
    local curLine = 2
    self:fillColumnBricks(1)
    self:fillColumnBricks(self.mapWidth)
    local ground = self.mapHeight / 2

    while curLine < self.mapWidth - 20 do
        -- 1/10 chance of cloud and enough room to spawn and it is an even # column
        if math.random(5) == 1 and curLine < self.mapWidth - 2 and curLine % 2 == 0 then
            local cloudStart = math.random(ground - 5)

            self:setTile(curLine, cloudStart, CLOUD_LEFT)
            self:setTile(curLine + 1, cloudStart, CLOUD_RIGHT)
        end 

        -- chance of spawning skull
        if math.random(12) == 1 then
            self:setTile(curLine, ground - 1, SKULL)
            -- chance of spawning another skull above it
            for i = 1, 3 do
            if math.random(2 * i) == 1 then
                self:setTile(curLine, ground - 1 - i, SKULL)
            else
                break
            end
            end
            self:fillColumnBricks(curLine)
            curLine = curLine + 1
        -- chance of height 2 mushroom
        elseif math.random(15) == 1 then
            self:setTile(curLine, ground - 2, MUSHROOM_TOP)
            self:setTile(curLine, ground - 1, MUSHROOM_STEM)
            self:fillColumnBricks(curLine)
            curLine = curLine + 1
        -- chance of height 1 mushroom
        elseif math.random(25) == 1 then
            self:setTile(curLine, ground - 1, MUSHROOM_TOP)
            self:fillColumnBricks(curLine)
            curLine = curLine + 1
        -- 10% chance of spawning bush
        elseif math.random(10) == 1 and curLine < self.mapWidth - 4 then
            if math.random(2) == 1 then
                self:setTile(curLine, ground - 5, SKULL)
            end
            for i = 0, 1 do 
                self:setTile(curLine + i, ground - 1, BUSH_LEFT + i)
                self:fillColumnBricks(curLine + i)
            end 
            curLine = curLine + 2
        -- 1/6 chance of spawning brick floors
        elseif math.random(10) ~= 1 then
            -- chance of spawning block
            if math.random(10) == 1 then
                self:setTile(curLine, ground - 4, BLOCK)
            end
            self:fillColumnBricks(curLine)
            curLine = curLine + 1
        -- spawn an empty gap
        else
            curLine = curLine + 2
            self:fillColumnBricks(curLine)
            curLine = curLine + 1
        end 
    end 

    -- end area requires flat ground
    for i = self.mapWidth - 20, self.mapWidth do
        self:fillColumnBricks(i)
    end

    self:setTile(self.mapWidth - 3, 4, CLOUD_LEFT)
    self:setTile(self.mapWidth - 2, 4, CLOUD_RIGHT)

    -- create pyramid of blocks
    for i = 0, 3 do
        for j = self.mapWidth - 14 + i, self.mapWidth - 14 + 3 do
            self:setTile(j, ground - 1 - i, TILE_BRICK)
        end
    end

    self.flag = Flag(self)

    self.music = love.audio.newSource('sounds/music.wav', 'static')
    self.music:setLooping(true)
    self.music:setVolume(0.5)
    self.music:play()

    self.powercubes = {}
    self.numPowerCubesSpawned = 0

    self.mapState = 'play'
end 

--[[ function tileAt()
    -- converts x, y pixel coordinates to x, y index pairs
    -- returns the id of the tile at the specified x and y pixel coordinates
]]
function Map:tileAt(x, y)
    --return self:getTile(math.floor(x / self.tileWidth) + 1, math.floor(y / self.tileHeight) + 1)
    return {
        x = math.floor(x / self.tileWidth) + 1,
        y = math.floor(y / self.tileHeight) + 1,
        id = self:getTile(math.floor(x / self.tileWidth) + 1, math.floor(y / self.tileHeight) + 1)
    }
end

--[[ function setTile()
    - stores what the tile should be in the 1D array tiles{} at index x,y
    - (y-1) * mapWidth jumps ahead to the appropriate row, and adding x gets to the correct location
    - arrays are 1-indexed
]]
function Map:setTile(x, y, tile)
    self.tiles[(y - 1) * self.mapWidth + x] = tile
end 

--[[ function getTile()
    -- returns sprite ID of the sprite stored at index x, y in tiles array
]]
function Map:getTile(x, y)
    return self.tiles[(y - 1) * self.mapWidth + x]
end

--[[ function collides()
    - give a tile object, check if it is collidable
]]
function Map:collides(tile)
    local collidables = {
        TILE_BRICK, BLOCK, MUSHROOM_TOP, MUSHROOM_STEM
    }

    local damages = {
        SKULL
    }

    local flagTiles = {
        FLAG_BASE, FLAG_POLE, FLAG_TOP
    }

    for _, v in ipairs(damages) do
        if tile.id == v then
            return 3
        end
    end

    --iterate over collidables and check if the tile is collidable
    for _, v in ipairs(collidables) do
        if tile.id == v then
            return 1 -- wall collision
        end 
    end

    -- check if the player is colliding with the goal
    for _, v in ipairs(flagTiles) do
        if tile.id == v then
            return 2 -- flag collision
        end 
    end

    return 0 --no collision 
end

function Map:update(dt)
    --cs50 way of moving the camera
    self.camX = math.max(0, math.min(self.player.x - VIRTUAL_WIDTH / 2,
    math.min(self.mapWidthPixels - VIRTUAL_WIDTH, self.player.x)))

    self.player:update(dt)
    self.flag:update(dt)

    -- if player walks/falls/jumps into a powercube
    for i = 0, self.numPowerCubesSpawned - 1 do
        if self.powercubes[i] ~= nil then
            self.powercubes[i]:update(dt)
            if self.powercubes[i]:collides(self.player.x + self.tileWidth / 2, self.player.y + self.tileHeight / 2) then
                self.powercubes[i] = nil
                self.player.sounds['powercube']:play()
                self.player.numPowercubes = self.player.numPowercubes + 1
            end
        end
    end

    -- update animations for field objects (flags, powercubes)
    if self.player.y >= (self.mapHeight / 2 - 1) * self.tileHeight - self.player.height and gameState == 'win' then
        self.flag.dy = 0
        self.flag.currentAnimation = self.flag.animations['idle']
    elseif gameState == 'win' then
        self.flag.dy = 90
        self.flag.currentAnimation = self.flag.animations['falling']
    end

    --update powercubes spawned (animation)
    for i = 0, self.numPowerCubesSpawned - 1 do
        if self.powercubes[i] ~= nil then
            self.powercubes[i]:update(dt)
        end
    end

end

--[[ function render()
    - draw the sprites on the screen based off their value in tiles{}
]]
function Map:render()
    for y = 1, self.mapHeight do
        for x = 1, self.mapWidth do
            --[[
                love.graphics.draw() PARAMETERS:
                1. Source of where the sprite originates
                2. The actual sprite texture object (stored in tileSprites, tiles stores the index of the sprite)
                3. x-coordinate of which pixel to draw at
                4. y-coordinate of which pixel to draw at
            ]]
            love.graphics.draw(self.spritesheet, self.tileSprites[self:getTile(x, y)],
                (x-1) * self.tileWidth, (y-1) * self.tileHeight)
        end 
    end
    self.player:render()
    self.flag:render()

    -- if player walks/falls/jumps into a powercube
    for i = 0, self.numPowerCubesSpawned - 1 do
        if self.powercubes[i] ~= nil then
            self.powercubes[i]:render()
        end
    end
end

function Map:fillColumnBricks(x) 
    for y = self.mapHeight / 2, self.mapHeight do
        self:setTile(x, y, TILE_BRICK)
    end
end 

function Map:addPowerup(x, y)
    --self:setTile(x, y, BLOCK_HIT)
    self.powercubes[self.numPowerCubesSpawned] = Powerup(x, y, self)
    self.numPowerCubesSpawned = self.numPowerCubesSpawned + 1
end