--MODULE FOR PARTICLES AND STUFF--

local particle = {}

--Color object
PARTICLE = Class{
    init = function(self, x, y, dir_x, dir_y, speed, color)
        self.x = x                   --Particle X position
        self.y = y                   --Particle Y position
        self.dir_x = dir_x           --X direction of particle
        self.dir_y = dir_y           --Y direction of particle
        self.speed = speed           --Particle speed
        self.color = {}
        self.color.r     = color.r   --Red
        self.color.g     = color.g   --Green
        self.color.b     = color.b   --Blue
        if color.a then
        	self.color.a = color.a   --Alpha
        else
        	self.color.a = 255
        end  
    end
}

--Creates a colored article explosion starting position (x,y)
function particle.explosion(x, y, color, duration, max_part, speed)
    local duration = duration or 2    --Duration particles will stay on screen
    local max_part = max_part or 25   --Number of particles created in a explosion
    local speed    = speed    or 100  --Particles speed
    local part, rand
    local signal_x, signal_y --signal (positive or negative) for dir_x and dir_y
    local id = math.random() --Creates an id for this explosion

    --Creates all particles of explosion
    for i=1, max_part do
        if math.random() < 0.5 then signal_x = 1 else signal_x = -1 end
        if math.random() < 0.5 then signal_y = 1 else signal_y = -1 end
        --Creates a random lightning for each particle
        local max = 70
        rand = math.random()*max*2 - max --Varies between -max and max
        part = PARTICLE(x, y, math.random()*signal_x, math.random()*signal_y, speed, COLOR(color.r+rand, color.g+rand, color.b+rand))
        PART_T["px"..x.."y"..y.."i"..i.."id"..id] = part
    end

    --Timer for removing particles
    Game_Timer.after(duration, 
        function()
            
            for i=1, max_part do
                PART_T["px"..x.."y"..y.."i"..i.."id"..id] = nil
            end

        end
    )
end

--Updates all particles positions
function particle.update(dt)
    
    for i, p in pairs(PART_T) do
        --Moves particles
        p.x = p.x + p.dir_x * p.speed * dt
        p.y = p.y + p.dir_y * p.speed * dt
        --Fade-out effect
        p.color.a = p.color.a * 0.95
    end

end

return particle