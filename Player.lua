Player = Class{}

local MOVEMENT_SPEED = 100
local SPEED_BOOST = 30
local JUMP_SPEED = 300
local GRAVITY = 30
local INVINCIBILITY_DURATION = 1

function Player:init(map)
    self.width = 16
    self.height = 20

    self.x = 0
    self.y = map.tileHeight * (map.mapHeight / 2 - 1) - self.height
    self.map = map

    self.dx = 0
    self.dy = 0

    self.texture = love.graphics.newImage('graphics/nani.png')
    self.frames = generateQuads(self.texture, 16, 20)

    self.jumpPoint = self.y
    self.timer = 0
    self.invincible = false

    -- dictionary of Animation objects
    self.animations = {
        ['idle'] = Animation({
            texture = self.texture,
            frames = {
                self.frames[1] --idle animation frame
            },
            interval = 1
        }), 
        ['walking'] = Animation({
            texture = self.texture,
            frames = {
                -- all frames that are the walking animation
                self.frames[9], self.frames[10], self.frames[11]
            },
            interval = 0.1
        }),
        ['jumping'] = Animation({
            texture = self.texture,
            frames = {
                self.frames[3]
            },
            interval = 1
        }),
        ['dead'] = Animation({
            texture = self.texture,
            frames = {
                self.frames[4], self.frames[5]
            },
            interval = 0.4
        }),
        ['victory'] = Animation({
            texture = self.texture,
            frames = {
                self.frames[6], self.frames[7]
            },
            interval = 0.65
        })
    }

    self.currentAnimation = self.animations['idle']

    self.state = 'idle'
    self.direction = 'right'
    self.numPowercubes = 0
    
    self.sounds = {
        ['jump'] = love.audio.newSource('sounds/jump.wav', 'static'),
        ['coin'] = love.audio.newSource('sounds/coin.wav', 'static'),
        ['powerup'] = love.audio.newSource('sounds/powerup-reveal.wav', 'static'),
        ['hit'] = love.audio.newSource('sounds/hit.wav', 'static'),
        ['death'] = love.audio.newSource('sounds/death.wav', 'static'),
        ['goal'] = love.audio.newSource('sounds/goal.wav', 'static'),
        ['powercube'] = love.audio.newSource('sounds/collect_powercube.wav', 'static'),
        ['hurt'] = love.audio.newSource('sounds/hurt.wav', 'static')
    }

    -- table of functions; calling a specific key will call the function
    self.states = {

        ['idle'] = function(dt)          
            if love.keyboard.isDown('space') then
                self.state = 'jumping'
                self.sounds['jump']:play()
            elseif love.keyboard.isDown('right') or love.keyboard.isDown('left') then
                self.state = 'walking'
            else
                self.currentAnimation = self.animations['idle']
                self.dx = 0
            end

            self:checkBelowCollision()

            if love.keyboard.wasPressed('6') then
                self.numPowercubes = self.numPowercubes + 1
            end
        end, 
        ['walking'] = function(dt)
            if love.keyboard.isDown('space') then
                self.state = 'jumping'
                self.sounds['jump']:play()
            elseif love.keyboard.isDown('right') then
                self.currentAnimation = self.animations['walking']
                self.direction = 'right'
                if love.keyboard.isDown('c') then
                    self.dx = MOVEMENT_SPEED + SPEED_BOOST
                else
                    self.dx = MOVEMENT_SPEED
                end    
            elseif love.keyboard.isDown('left') then
                self.currentAnimation = self.animations['walking']
                self.direction = 'left'
                if love.keyboard.isDown('c') then
                    self.dx = -MOVEMENT_SPEED - SPEED_BOOST
                else
                    self.dx = -MOVEMENT_SPEED
                end    
            else
                self.state = 'idle'
            end

            self:checkLeftCollision()
            self:checkRightCollision()
            self:checkBelowCollision()
            self:checkGoal()

            -- if player is standing over a pit
            if self.map:collides(self.map:tileAt(self.x, self.y + self.height)) == 0 and 
            self.map:collides(self.map:tileAt(self.x + self.width - 1, self.y + self.height)) == 0 then
                self.state = 'falling'
                self.currentAnimation = self.animations['jumping']
            end 
        end,
        ['jumping'] = function(dt) 
            self.currentAnimation = self.animations['jumping']
            self:airMovement()
            if love.keyboard.wasReleased('space') or self.y <= self.jumpPoint - 70 then
                self.dy = 0
                self.state = 'falling'
            elseif love.keyboard.isDown('space') then
                self.dy = -JUMP_SPEED
            end 

            -- if the player jumped into a block with the top left corner of the head
            local leftHit = self.map:tileAt(self.x, self.y).id
            if  leftHit == BLOCK then
                self.map:setTile(math.floor(self.x / self.map.tileWidth) + 1, math.floor(self.y / self.map.tileHeight) + 1, TILE_EMPTY)
                self.map:addPowerup((math.floor(self.x / self.map.tileWidth) * self.map.tileWidth),(math.floor(self.y / self.map.tileHeight) * self.map.tileHeight))
                self.dy = 0
                self.state = 'falling'
                self.sounds['hit']:play()
                self.sounds['powerup']:play()
                self.y = self.y + 2
            elseif leftHit == SKULL then
                self:takeDamage()
                self.dy = 0
                self.state = 'falling'
                self.y = self.y + 2
            end

            -- if the player jumped into a block with the top right corner of the head
            local rightHit = self.map:tileAt(self.x + self.map.tileWidth - 1, self.y).id
            if  rightHit == BLOCK then
                self.map:setTile(math.floor(self.x / self.map.tileWidth) + 2, math.floor(self.y / self.map.tileHeight) + 1, TILE_EMPTY)
                self.map:addPowerup((math.floor(self.x / self.map.tileWidth + 1) * self.map.tileWidth),(math.floor(self.y / self.map.tileHeight) * self.map.tileHeight))
                self.dy = 0
                self.state = 'falling'
                self.sounds['hit']:play()
                self.sounds['powerup']:play()
                self.y = self.y + 2
            elseif rightHit == SKULL then
                self:takeDamage()
                self.dy = 0
                self.state = 'falling'
                self.y = self.y + 2
            end
    
            self:checkLeftCollision()
            self:checkRightCollision()
            self:checkGoal()
        end,
        ['falling'] = function(dt)
            self.dy = self.dy + GRAVITY
            self:airMovement()
       
            --revert back to idle state if character has fallen onto the ground or a block
            -- could make left self.x + 5 and right self.x + self.width - 5 to be to fit between two bricks 
            local left = self.map:collides(self.map:tileAt(self.x, self.y + self.height - 1))
            local right = self.map:collides(self.map:tileAt(self.x + self.width - 1, self.y + self.height-1))
            if  left == 1 or right == 1 or left == 3 or right == 3 then
                self.dy = 0  
                self.state = 'idle'  
                self.currentAnimation = self.animations['idle']
                self.y = (self.map:tileAt(self.x, self.y + self.height).y - 1) * self.map.tileHeight - self.height
                self.jumpPoint = self.y 
                if left == 3 or right == 3 then
                    self:takeDamage()
                end
            end

            self:checkLeftCollision()
            self:checkRightCollision()
            self:checkGoal()

            -- if the player falls off the screen  
            if self.y >= map.tileHeight * (map.mapHeight / 2 - 1) - 10 then
                self.state = 'dead'
                self.sounds['death']:play()
            end
        end,
        ['dead'] = function(dt)
            self.dx = 0
            gameState = 'dead'
            self.invincible = false
            self.currentAnimation = self.animations['dead']
        end,
        ['win'] = function(dt)
            -- if the character finishes the level and reaches the end of the screen
            if self.x >= self.map.mapWidthPixels - self.width - 2 then
                self.currentAnimation = self.animations['victory']
                --self.y = 100000000000000 make player disappear
                return
            -- if the player walks into the flagpole
            elseif self.dy == 0 then
                self.dx = MOVEMENT_SPEED
            -- once the player slides down to pole, onto the ground
            elseif self.y >= (self.map.mapHeight / 2 - 1) * self.map.tileHeight - self.height then
                self.currentAnimation = self.animations['walking']
                self.dy = 0
            -- sliding down the pole
            else
                self.dy = GRAVITY * 3
            end
        end
    }
end

function Player:update(dt)
    local timer = 0
    self.states[self.state](dt)
    self.currentAnimation:update(dt)
    --update player X position
    if self.direction == 'left' then
        self.x = math.max(self.x + self.dx * dt, 0)
    else
        self.x = math.min(self.x + self.dx * dt, self.map.mapWidthPixels - self.map.tileWidth)
    end

    --update player Y position
    self.y = self.y + self.dy * dt

    --update timer for invincibility frames
    if self.invincible then
        self.timer = self.timer + dt
    end

    if self.timer > INVINCIBILITY_DURATION then
        self.timer = 0
        self.invincible = false
    end
    
    --check death
    if self.numPowercubes < 0 then
        self.state = 'dead'
        self.dy = 0
        self.numPowercubes = 0
        self.sounds['death']:play()
    end
end

function Player:render()
    local scaleX

    -- check which direction the character is walking 
    if self.direction == 'left' then
        scaleX = -1
    else
        scaleX = 1
    end

    --draw character, possibily flipped axis, with the correct animation frame
    love.graphics.draw(self.texture, self.currentAnimation:getCurrentFrame(), 
        math.floor(self.x + self.width / 2), math.floor(self.y + self.height / 2), 
        0, scaleX, 1, self.width / 2, self.height / 2)
    
    if self.invincible then
        love.graphics.setColor(10/255, 255/255, 10/255, 255/255)
    else 
        love.graphics.setColor(1, 1, 1, 1)
    end

    -- draw powerup count
    if self.numPowercubes ~= 0 then
        love.graphics.draw(self.map.spritesheet, self.map.tileSprites[BLOCK_HIT], self.x - 5, self.y - self.map.tileHeight - 2)
        love.graphics.setFont(smallFont)
        love.graphics.print(tostring(self.numPowercubes), self.x + 7, self.y - self.map.tileHeight)
    end
end 

function Player:airMovement()
    -- movement in the air
    if love.keyboard.isDown('right') then
        self.direction = 'right'
        if love.keyboard.isDown('c') then
            self.dx = MOVEMENT_SPEED + SPEED_BOOST
        else
            self.dx = MOVEMENT_SPEED
        end    
    elseif love.keyboard.isDown('left') then
        self.direction = 'left'
        if love.keyboard.isDown('c') then
            self.dx = -MOVEMENT_SPEED - SPEED_BOOST
        else
            self.dx = -MOVEMENT_SPEED
        end    
    else 
        self.dx = 0
    end
end

function Player:checkLeftCollision()
    if self.dx < 0 then
        local top = self.map:collides(self.map:tileAt(self.x - 1, self.y))
        local bottom = self.map:collides(self.map:tileAt(self.x - 1, self.y + self.height - 1))
        if  top == 1 or bottom == 1 or top == 3 or bottom == 3 then
            self.dx = 0
            self.x = self.map:tileAt(self.x - 1, self.y).x * self.map.tileWidth
            if top == 3 or bottom == 3 then
                self:takeDamage()
            end
        end 
    end
end

function Player:checkRightCollision()
    if self.dx > 0 then
        local top = self.map:collides(self.map:tileAt(self.x + self.width, self.y))
        local bottom = self.map:collides(self.map:tileAt(self.x + self.width, self.y + self.height - 1))
        if top == 1 or bottom == 1 or top == 3 or bottom == 3 then
            self.dx = 0
            self.x = (self.map:tileAt(self.x + self.width, self.y).x - 2)* self.map.tileWidth
            if top == 3 or bottom == 3 then
                self:takeDamage()
            end
        end 
    end
end

function Player:checkGoal()
    if self.map:collides(self.map:tileAt(self.x, self.y)) == 2 or 
    self.map:collides(self.map:tileAt(self.x, self.y + self.height - 1)) == 2 then
        gameState = 'win'
        self.state = 'win'
        self.dx = 0
        self.sounds['goal']:play()
    end 
end

function Player:checkBelowCollision()
    local left = self.map:collides(self.map:tileAt(self.x, self.y + self.height))
    local right = self.map:collides(self.map:tileAt(self.x + self.width - 1, self.y + self.height))
    if left == 3 or right == 3 then
        self:takeDamage()
    end
end

function Player:takeDamage(dt)
    if not self.invincible then
        self.numPowercubes = self.numPowercubes - 1
        self.sounds['hurt']:play()
        self.invincible = true
        self.timer = 0
    end
end