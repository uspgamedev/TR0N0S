local Particle = require "particle"
local RGB      = require "rgb"

--MODULE WITH USEFUL LOGICAL, MATHEMATICAL AND USEFUL STUFF--

local util = {}

--------------------
--SETUP FUNCTIONS
--------------------

--Set game's global variables, random seed and window configuration
function util.configGame()
    local P_1, P_2      --Player 1 and 2
    local rgb_b, rgb_h  --Color for body and head

    --RANDOM SEED
    math.randomseed( os.time() )
    math.random(); math.random(); --Improves random

    --GLOBAL VARIABLES

    DEBUG = false      --DEBUG mode status
    
    --MATCH/GAME SETUP VARS
    game_setup = false  --Inicial setup for each game
    GOAL = 3          --Best of X games that will be played in the match
    MATCH_BEGIN = false --If is in a current match
    MAX_PLAYERS = 10    --Max number of players in a game
    N_PLAYERS = 2       --Number of players playing
    
    --CONTROL VARS
    WASD_PLAYER = 1     --Player using wasd keys
    ARROWS_PLAYER = 2   --Player using arrow keys
    
    --TIME VARS
    MAX_COUNTDOWN = 3   --Countdown in the beggining of each game
    TIMESTEP = 0.03     --Time between each game step

    --MAP VARS
    TILESIZE = 8        --Size of the game's tile
    HUDSIZE = 100       --Size of window dedicated for HUD
    BORDER = 8*TILESIZE --Border of the game map
    MARGIN = 12         --Size of margin for players' inicial position
    map = {}            --Game map
    map_x = 80          --Map x size (in tiles)
    map_y = 80          --Map y size (in tiles)
        
    --TIMERS
    if not Game_Timer then
        Game_Timer = Timer.new()  --Timer for all game-related timing stuff
    end

    if not Color_Timer then
        Color_Timer = Timer.new()  --Timer for all color-related timing stuff
    end

    --DRAWING TABLES
    TB_T   = {}  --Default TextBox table
    B_T    = {}  --Default Button table
    TXT_T  = {}  --Default Text table
    F_T    = {}  --Filter table
    PB_T   = {}  --Players Button table
    PART_T = {}  --Particles table
        
    --COLOR TABLES
    
    --All base colors players can have
    C_T    = {COLOR(75,209,109), COLOR(174,252,91),  COLOR(220,252,91),
              COLOR(91,252,91),  COLOR(91,252,177),  COLOR(91,226,252),
              COLOR(91,134,252), COLOR(112,91,252),  COLOR(180,91,252),
              COLOR(52,68,191),  COLOR(52,149,191),  COLOR(52,191,159),
              COLOR(73,196,89),  COLOR(109,209,46),  COLOR(210,227,61),
              COLOR(227,192,39), COLOR(111,230,32),  COLOR(134,227,20),
              COLOR(10,209,17),  COLOR(118,199,101), COLOR(0,194,74)}
    --Color for the map
    map_color = COLOR(0, 0, 0)
    --All base colors map background can have
    MC_T   = {COLOR(250,107,12), COLOR(250,81,62), COLOR(240,60,177), COLOR(180,18,201)}

    --OTHER TABLES
    P_T   = {}  --Players table

    --WINDOW CONFIG
    success = love.window.setMode(TILESIZE*map_x + 2*BORDER, TILESIZE*map_y + 2*BORDER, {borderless = not DEBUG})

    --FONT STUFF
    font_but_m = love.graphics.newFont( "assets/vanadine_bold.ttf", 30) --Font for buttons, medium size
    font_reg_m = love.graphics.newFont( "assets/FUTUVA.ttf", 30) --Font for regular text, medium size
    font_reg_s = love.graphics.newFont( "assets/FUTUVA.ttf", 16) --Font for regular text, small size
    love.graphics.setFont(font_reg_m)

    --Creates first two players with random colors

    --Player 1
    rgb_b = RGB.randomColor()
    rgb_h = RGB.randomDarkColor(rgb_b)
    P_1   = PLAYER(1, false, nil, nil, nil, nil, rgb_b, rgb_h, false, nil, "WASD")
    table.insert(P_T, P_1)

    --Player 2
    rgb_b = RGB.randomColor()
    rgb_h = RGB.randomDarkColor(rgb_b)
    P_2   = PLAYER(2, false, nil, nil, nil, nil, rgb_b, rgb_h, false, nil, "ARROWS")
    table.insert(P_T, P_2)

end

--Setup a new match, setting all scores to zero
function util.setupMatch()
   
    for i, p in ipairs(P_T) do
        p.score = 0
    end

end

 --Setup a new game
function util.setupGame()
    
    if not game_setup then
        countdown = MAX_COUNTDOWN --Setup countdown
             
        --Clear all timers related to color    
        Color_Timer.clear()

        game_begin = false
        step = 0
        winner = 0
        
        resetMap()
        
        setupPlayers()

        game_setup = true
        StartCountdown()
    end

end


--Setup all players
function setupPlayers()
    local p_x, p_y, is_rand
    
    for i, p in ipairs(P_T) do

        --Get random positions for all players
        is_rand = false
        while is_rand == false do
            p_x = math.random(map_x-2*MARGIN)+MARGIN
            p_y = math.random(map_y-2*MARGIN)+MARGIN
            is_rand = true
            --Iterate in all other players and checks for a valid position
            for j=1,i-1 do
                if(p_x == P_T[j].x and p_y == P_T[j].y) then
                    is_rand = false
                end
            end
        end

        p.x = p_x  --Player x position
        p.y = p_y  --Player y position

        p.dir     = nil --Player current direction
        p.nextdir = nil --Player next direction

        p.dead = false

        p.side = nil
    end

end

------------------
--UPDATE FUNCTIONS
------------------

--Update step and all players position
function util.tick(dt)
    
    --Update "real-time" stuff
    Particle.update(dt)
    
    --Update "timestep" stuff
    step = math.min(TIMESTEP, step + dt)
    if step >= TIMESTEP then    
        
        UpdateCPU()

        UpdateHuman()

        CheckCollision()

        --Reset step counter
        step = 0
    end

end

--Updates cpu players position
function UpdateCPU()
    
    for i, p in ipairs(P_T) do
        if not p.dead and p.cpu then
            local dir = p.dir
            local x = p.x
            local y = p.y
            
            --Draw player "trail" before moving
            map[x][y] = p.number


            --CPU LEVEL 1
            if p.level == 1 then

               dir = CPU_Level1(p)


            --CPU LEVEL 2
            elseif p.level == 2 then

               dir = CPU_Level2(p)

            --CPU LEVEL 3
            elseif p.level == 3 then

               dir = CPU_Level3(p)

            end


            --Move CPU
            if dir == 1 then
                x = math.max(1, x - 1)         --Left
            elseif dir == 2 then
                y = math.max(1, y-1)           --Up
            elseif dir == 3 then
                x = math.min(map_x, x+1)       --Right
            elseif dir == 4 then
                y = math.min(map_y, y+1)       --Down
            end

            --Updates player direction
            p.dir = dir
            
            --Update player position
            p.x = x
            p.y = y
        end
    end

end



--Updates non-cpu players positions
function UpdateHuman()
    local x, y, dir

    for i, p in ipairs(P_T) do
        if not p.dead and not p.cpu then
            dir = p.nextdir
            x = p.x
            y = p.y
            
            --Draw player "trail" before moving
            map[x][y] = p.number

            --Move players 
            if dir == 1 then
                x = math.max(1, x - 1)         --Left
            elseif dir == 2 then
                y = math.max(1, y-1)           --Up
            elseif dir == 3 then
                x = math.min(map_x, x+1)       --Right
            elseif dir == 4 then
                y = math.min(map_y, y+1)       --Down
            end

            --Updates player direction
            p.dir = dir
            
            --Update player position
            p.x = x
            p.y = y
        end
    end

end

-----------------------
--USEFUL GAME FUNCTIONS
-----------------------

--Checks collision between players and walls/another player
function CheckCollision()
    local color = COLOR(65,17,180)

    for i, p1 in ipairs(P_T) do
        
        if not p1.dead then
            
            --Check collision with wall
            if map[p1.x][p1.y] ~= 0 then
                p1.dead = true
                Particle.explosion(p1.x*TILESIZE + BORDER, p1.y*TILESIZE + BORDER, color)
            end

            --Check collision with other players
            for j=i+1, #P_T do
                if p1.x == P_T[j].x and p1.y == P_T[j].y then
                    p1.dead = true

                    P_T[j].dead = true

                    Particle.explosion(p1.x*TILESIZE + BORDER, p1.y*TILESIZE + BORDER, color)
                end
            end

        end
  end

end

--Count how many players are alive and declare a winner
function util.countPlayers()
    
    cont = 0
    winner = 0

    for i, p in ipairs(P_T) do
        if p.dead == false then
            cont = cont+1
            winner = p.number
        end
    end

    return cont 
end


--Handles winner of every game, and checks if match is over
function util.checkWinner()
    
    if winner ~= 0 then
        p = P_T[winner]
        --Increses player score
        p.score = p.score + 1

        if p.score >= GOAL then
            MATCH_BEGIN = false    --End of match, a player has reached target score
        end
    end

end

--------------------
--CPU'S AI FUNCTIONS
--------------------

--CPU LEVEL 1 - "L4-M0"
--Has 80% of going the same direction, and 20% of "turning" left or right
function CPU_Level1(p)
    local dir = p.dir

    --Chooses a random different valid (not reverse) direction
    if math.random() <= .2 then
        --"Turn right"    
        if math.random() <= .5 then
            dir = dir%4 + 1
        --"Turn left"
        else
            dir = (dir+2)%4 + 1
        end
    end

    return dir
end

--CPU LEVEL 2 - "TIMMY-2000"
--If it would reach an obstacle, turns direction
function CPU_Level2(p)
    local dir = p.dir
    local next_x, next_y --Position that the CPU will go if move forward
    local left_x, left_y --Position that the CPU will go if turn left
    local right_x, right_y --Position that the CPU will go if turn right

            
    next_x, next_y = nextPosition(p.x, p.y, dir)
    left_x, left_y = nextPosition(p.x, p.y, (dir + 2)%4 + 1)
    right_x, right_y = nextPosition(p.x, p.y, dir%4 + 1)

    --Found obstacle
    if  not validPosition(next_x, next_y) or map[next_x][next_y] ~= 0 then
        --Randomly tries to go right or left when reaching
        if math.random() < 0.5 then
            if  validPosition(left_x, left_y) and map[left_x][left_y] == 0 then
                dir = (dir + 2)%4 + 1 --turn left
            else
                dir = dir%4 + 1       --turn right
            end
        else
            if  validPosition(right_x, right_y) and map[right_x][right_y] == 0 then
                dir = dir%4 + 1       --turn right
            else
                dir = (dir + 2)%4 + 1 --turn left
            end
        end
    end

    return dir
end

--CPU LEVEL 3 - "R0B1N"
--Goes around everything
function CPU_Level3(p)
    local dir = p.dir
    local next_x, next_y   --Position that the CPU will go if move forward
    local left_x, left_y   --Position that the CPU will go if turn left
    local right_x, right_y --Position that the CPU will go if turn right
    local side = p.side    --Side CPU is going around

    next_x, next_y   = nextPosition(p.x, p.y, dir)
    left_x, left_y   = nextPosition(p.x, p.y, (dir + 2)%4 + 1)
    right_x, right_y = nextPosition(p.x, p.y, dir%4 + 1)

    if side == "left" then

        --Can go left?
        if validPosition(left_x, left_y) and map[left_x][left_y] == 0 then
            dir = (dir + 2)%4 + 1 --turn left
        --Can't go forward?
        elseif not validPosition(next_x, next_y) or map[next_x][next_y] ~= 0 then
            dir = dir%4 + 1       --turn right
        end

    elseif side == "right" then

        --Can go right?
        if validPosition(right_x, right_y) and map[right_x][right_y] == 0 then
            dir = dir%4 + 1       --turn right
        --Can't go forward?
        elseif not validPosition(next_x, next_y) or map[next_x][next_y] ~= 0 then
            dir = (dir + 2)%4 + 1 --turn left
        end

    elseif side == nil then

        --Found obstacle
        if  not validPosition(next_x, next_y) or map[next_x][next_y] ~= 0 then
            if math.random() < 0.5 then
                if  validPosition(left_x, left_y) and map[left_x][left_y] == 0 then
                    dir = (dir + 2)%4 + 1 --turn left
                    p.side = "right"
                else
                    dir = dir%4 + 1       --turn right
                    p.side = "left"
                end
            else
                if  validPosition(right_x, right_y) and map[right_x][right_y] == 0 then
                    dir = dir%4 + 1       --turn right
                    p.side = "left"
                else
                    dir = (dir + 2)%4 + 1 --turn left
                    p.side = "right"
                end
            end
        end
    end

    return dir
end

---------------------
--COUNTDOWN FUNCTIONS
---------------------

--Start the countdown to start a game
function StartCountdown()
    local cd = countdown
    local t, rand
    
    time = 0
    Game_Timer.during(MAX_COUNTDOWN, 
        
        --Decreases countdown
        function(dt)
            t = time+dt
            cd = cd - t
            countdown = math.floor(cd)+1
        end,

        --After countdown, start game and fixes players positions
        function()

            RemovePlayerIndicator()

            game_begin = true

            --Players go at a random direction at the start if they dont chose any
            for i, p in ipairs(P_T) do
                rand = math.random(4)
                if p.dir     == nil then p.dir     = rand end
                if p.nextdir == nil then p.nextdir = rand end
            end
        end
    )

end


-------------------------
--PLAYER BUTTON FUNCTIONS
-------------------------

--Update players buttons on setup
--TODO: improve so it doesnt delete all buttons and creates new ones
function util.updatePlayersB()
    local font = font_reg_m
    local color_b, color_t, cputext, controltext, pl
    local pb, ptb, x, y

    util.clearTable(PB_T)

    for i, p in ipairs(P_T) do
        if p.cpu then
            cputext = "CPU"
            controltext = "Level " .. p.level
        else
            cputext = "HUMAN"
            controltext = p.control
        end

        --Counting the perceptive luminance - human eye favors green color... 
        pl = 1 - ( 0.299 * p.b_color.r + 0.587 * p.b_color.g + 0.114 * p.b_color.b)/255;

        if pl < 0.5 then
            color_t = COLOR(0, 0, 0)       --bright colors - using black font
        else
            color_t = COLOR(255, 255, 255) --dark colors - using white font
        end

        color_b = COLOR(p.b_color.r, p.b_color.g, p.b_color.b)

        --Creates player button
        x = 40
        y = 150 + 45*i
        w = 500
        h = 40
        pb = But(x, y, w, h,
                        "PLAYER " .. i .. " " .. cputext .. " (" .. controltext .. ")",
                        font, color_b, color_t, 
                        --Change players from CPU to HUMAN witha controller
                        function()
                            --Human with WASD controls, on click, becomes ARROWS if possible, else becomes CPU
                            if not p.cpu and p.control == "WASD" then
                                if ARROWS_PLAYER == 0 then
                                    p.control = "ARROWS"
                                    ARROWS_PLAYER = p.number
                                    WASD_PLAYER = 0
                                else
                                    p.cpu = true
                                    p.level = 1
                                    p.control = nil
                                    WASD_PLAYER = 0
                                end

                            --Human with ARROWS controls, on click, becomes CPU Level1
                            elseif not p.cpu and p.control == "ARROWS" then
                                p.cpu = true
                                p.level = 1
                                p.control = nil
                                ARROWS_PLAYER = 0

                            --CPU Level different from 3, on click, becomes next level CPU
                            elseif p.cpu and p.level ~= 3 then
                                p.level = p.level + 1

                            --CPU Level3, on click, becomes WASD or ARROWS if possible. Else becomes CPU Level1
                            elseif p.cpu and p.level == 3 then
                                if WASD_PLAYER == 0 then
                                    p.control = "WASD"
                                    WASD_PLAYER = p.number
                                    p.cpu = false
                                    p.level = nil
                                elseif ARROWS_PLAYER == 0 then
                                    p.control = "ARROWS"
                                    ARROWS_PLAYER = p.number
                                    p.cpu = false
                                    p.level = nil
                                else
                                    p.level = 1
                                end
                            end

                            util.updatePlayersB()
                        end)
        table.insert(PB_T, pb)

        --Creates players head color box
        x = x + w
        w = 40
        h = 40
        ptb = TB(x, y, w, h, "", font, p.h_color, COLOR(0,0,0))
        TB_T["P"..p.number.."tb"] = ptb
    end

end

--Remove all player indicator text
function RemovePlayerIndicator()

    for i, p in ipairs(P_T) do
        TXT_T["player"..p.number.."txt"] = nil
        if  p.control == "WASD" then
            TXT_T["WASD"] = nil
        elseif p.control == "ARROWS" then
            TXT_T["ARROWS"] = nil
        else
            TXT_T["CPU"..i] = nil
        end
    end

end

---------------------
--UTILITIES FUNCTIONS
---------------------

--Clears all elements in a table
function util.clearTable(T)
    
    if not T then return end --If table is empty
    --Clear T table
    for k in pairs (T) do
        T[k] = nil
    end

end

--Clear all buttons and textboxes tables
function util.clearAllTables(mode)
    
    util.clearTable(TB_T)

    util.clearTable(B_T)

    util.clearTable(TXT_T)

    util.clearTable(F_T)

    util.clearTable(PB_T)

    if mode ~= "notPart" then
        util.clearTable(PART_T)
    end

end

--Checks if position (x,y) is inside map
function validPosition(x, y)
    
    if x < 1 or x > map_x or y < 1 or y > map_y then
        return false
    end

    return true 
end

--Returns next position starting in (x,y) and going direction dir
function nextPosition(x, y, dir)

    if dir == 1 then     --Left
        x = x - 1
    elseif dir == 2 then --Up
        y = y - 1      
    elseif dir == 3 then --Right
        x = x + 1
    elseif dir == 4 then --Down
        y = y + 1
    end

    return x, y
end

--Reset map, puttting 0 in all positions
function resetMap()
    
    --Resets map background color with a random possible color
    map_color = MC_T[math.random(#MC_T)]

    RGB.backgroundTransition()
    
    for i=1,map_x do
        map[i] = {}
        for j=1,map_y do
            map[i][j] = 0
        end
    end

end

----------------------
--TRANSITION FUNCTIONS
----------------------

--Makes a smooth transition in object 'o' position
--from point (x0,y0) to point (xf,yf)
function util.smoothMove(o, x0, y0, xf, yf, duration)
    local diff = 0

    --Starts a timer that gradually increse
    Game_Timer.during(duration,

        --Gradually change actual color until target color
        function(dt)
            ratio = diff/duration
            diff = diff + dt
            o.x = math.abs(ratio * xf + (1 - ratio) * x0)
            o.y = math.abs(ratio * yf + (1 - ratio) * y0)

        end,
        
        function()

            o.x = xf
            o.y = yf

        end
    )

end

--Makes a smooth transition in object 'o' alpha
--from i to f
function util.smoothAlpha(o, i, f, duration)
    local diff = 0

    --Starts a timer that gradually increse
    Game_Timer.during(duration,

        --Gradually change actual color until target color
        function(dt)
            ratio = diff/duration
            diff = diff + dt
            o.a = math.abs(ratio * f + (1 - ratio) * i)
        end,
        
        function()

        o.a = f
        
        end
    )

end


--------------------
--ZOEIRAZOEIRAZOEIRA 
--------------------

function util.zoera()
    local text = "omar"
    for i, v in pairs(TXT_T) do
        v.text = text
    end

    for i, v in pairs(TB_T) do
        v.text = text
    end

    for i, v in pairs(B_T) do
        v.text = text
    end


    for i, v in pairs(PB_T) do
        v.text = text
    end

end

--Return functions
return util