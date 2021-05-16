Animation = Class{}

function Animation:init(params)
    self.texture = params.texture
    self.frames = params.frames --list of different frames part of the animation
    self.interval = params.interval or 0.05 --length of time between animations
    self.timer = 0
    self.currentFrame = 1 --index into frames array
end

function Animation:update(dt)
    -- check how much time has elapsed; update timer every frame
    self.timer = self.timer + dt

    -- if the animation doesn't have multiple frames of animation
    if #self.frames == 1 then
        return self.currentFrame
    else 
        -- if it is time to update the frame
        while self.timer > self.interval do
            -- reset timer
            self.timer = self.timer - self.interval

            -- move onto the next frame
            self.currentFrame = self.currentFrame + 1

            -- loop back to beginning of animation of all frames have played
            if self.currentFrame > #self.frames then
                self.currentFrame = 1
            end           
        end 
    end
end

function Animation:getCurrentFrame()
    -- return the actual frame object
    return self.frames[self.currentFrame]
end 

function Animation:restart()
    self.timer = 0
    self.currentFrame = 1
end