Flag = Class{}

FLAG_BASE = 16
FLAG_POLE = 12
FLAG_TOP = 8

function Flag:init(map)
    self.height = 6

    self.animations = {
        ['idle'] = Animation({
            texture = map.spritesheet,
            frames = {
                map.tileSprites[13], map.tileSprites[14]
            },
            interval = 0.4
        }),
        ['falling'] = Animation ({
            texture = map.spritesheet,
            frames = {
                map.tileSprites[15]
            }
        })
    }
    self.ground = map.mapHeight / 2

    self.x = map.mapWidth - 7
    self.yCor = self.ground + (self.height * map.tileHeight)

    self.dy = 0
    self.currentAnimation = self.animations['idle']

    -- set the 
    map:setTile(self.x, self.ground - 1, FLAG_BASE)

    for i = 0, self.height - 2 do
        map:setTile(self.x, self.ground - 2 - i, FLAG_POLE)
    end

    map:setTile(self.x, self.ground - self.height, FLAG_TOP)

    self.map = map
end

function Flag:update(dt)
    self.currentAnimation:update(dt)
    self.yCor = self.yCor + self.dy * dt
end

function Flag:render()
    love.graphics.draw(self.map.spritesheet, self.currentAnimation:getCurrentFrame(), 
    self.x * self.map.tileWidth - 4, self.yCor)
end