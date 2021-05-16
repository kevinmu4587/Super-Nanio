Powerup = Class{}

function Powerup:init(x, y, map)
    self.x = x
    self.y = y

    map:setTile(x, y, BLOCK_HIT)
    self.sheet = love.graphics.newImage('graphics/powerup.png')
    self.frames = generateQuads(self.sheet, map.tileWidth, map.tileHeight)

    self.map = map

    self.animations = {
        ['powercube'] = Animation({
            texture = self.sheet,
            frames = {
                self.frames[1], self.frames[2], self.frames[3], self.frames[4]
            },
            interval = 0.5
        })
    }

    self.currentAnimation = self.animations['powercube']
end

function Powerup:update(dt)
    self.currentAnimation:update(dt)
end

function Powerup:collides(playerx, playery)
    if playerx >= self.x and playerx <= self.x + self.map.tileWidth and 
    playery >= self.y and playery <= self.y + self.map.tileHeight then
        return true
    end
end

function Powerup:render()
    love.graphics.draw(self.sheet, self.currentAnimation:getCurrentFrame(), self.x, self.y)
end