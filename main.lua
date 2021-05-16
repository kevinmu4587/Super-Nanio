WINDOW_WIDTH = 1280
WINDOW_HEIGHT = 720

VIRTUAL_WIDTH = 432
VIRTUAL_HEIGHT = 243

Class = require 'class'
push = require 'push'

require 'Util'
require 'Map'
require 'Player'
require 'Animation'
require 'Flag'
require 'Powerup'

function love.load()
    love.graphics.setDefaultFilter('nearest', 'nearest')
    love.window.setTitle('Super Nanio!')
    push:setupScreen(VIRTUAL_WIDTH, VIRTUAL_HEIGHT, WINDOW_WIDTH, WINDOW_HEIGHT, {
        fullscreen = false,
        vsync = true,
        resizable = true
    })
    math.randomseed(os.time())
    map = Map()

    -- table of all keys pressed in the current frame
    love.keyboard.keysPressed = {}
    love.keyboard.keysReleased = {}

    -- fonts for the game
    pixelFont = love.graphics.newFont('04B_03__.TTF', 32)
    smallFont = love.graphics.newFont('04B_03__.TTF', 16)

    gameState = 'play'

    -- state functions on what to render
    renderStates = {
        -- render's full map and translation
        ['play'] = function()
            love.graphics.setFont(smallFont)
            love.graphics.translate(math.floor(-map.camX), math.floor(-map.camY))
            map:render()
        end,

        -- prints death text behind map
        ['dead'] = function()
            love.graphics.setFont(pixelFont)
            love.graphics.printf('You Died', 0, VIRTUAL_HEIGHT / 2 - 16, VIRTUAL_WIDTH, 'center')
            love.graphics.setFont(smallFont)
            love.graphics.printf('z: try again   x: new map', 0, VIRTUAL_HEIGHT / 2 + 15, VIRTUAL_WIDTH, 'center')

            love.graphics.translate(math.floor(-map.camX), math.floor(-map.camY))
            map:render()
    
            -- restart game or extra life
            if love.keyboard.wasPressed('x') then
                map = Map()
                gameState = 'play'
                map.music:stop()
            elseif love.keyboard.wasPressed('z') then
                map.player = Player(map)                
                gameState = 'play'
            end
    
        end,

        -- show winning text 
        ['win'] = function()
            love.graphics.setFont(pixelFont)
            love.graphics.printf('Level Complete!', 0, VIRTUAL_HEIGHT / 3 - 16, VIRTUAL_WIDTH, 'center')
            love.graphics.setFont(smallFont)
            love.graphics.printf('Press Z to play again.', 0, VIRTUAL_HEIGHT / 3 + 15, VIRTUAL_WIDTH, 'center')

            love.graphics.translate(math.floor(-map.camX), math.floor(-map.camY))
            map:render()
    
            -- generate new map
            if love.keyboard.wasPressed('z') then
                map = Map()
                gameState = 'play'
                map.music:stop()
            end
        end
    }
end

function love.update(dt)
    map:update(dt)
end 

function love.keypressed(key)
    if key == 'escape' then
        love.event.quit()
    end

    love.keyboard.keysPressed[key] = true
end

function love.keyreleased(key)
   love.keyboard.keysReleased[key] = true
end 

function love.keyboard.wasPressed(key)
    return love.keyboard.keysPressed[key]
end

function love.keyboard.wasReleased(key) 
    return love.keyboard.keysReleased[key]
end

function love.draw()
    push:apply('start')
    love.graphics.setFont(pixelFont)
    love.graphics.clear(108/255, 140/255, 255/255, 255/255)

    renderStates[gameState]()

    love.keyboard.keysPressed = {}
    love.keyboard.keysReleased = {}
    push:apply('end')
end 