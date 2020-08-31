-- Pong minigame by engineer
local lua_container = "A"

local screen_width, screen_height = client.screen_size()
local mid_x, mid_y = screen_width / 2, screen_height / 2

local minigame_enabled = ui.new_checkbox("LUA", lua_container, "Minigame")
local minigame_color = ui.new_color_picker("LUA", lua_container, "Minigame color", 255, 255, 255, 255)
local minigame_hotkey = ui.new_hotkey("LUA", lua_container, "Pause")
local minigame_up = ui.new_hotkey("LUA", lua_container, "Up")
local minigame_down = ui.new_hotkey("LUA", lua_container, "Down")

ui.set(minigame_hotkey, "Toggle")

local function handle_menu()
    if ui.get(minigame_enabled) then
        ui.set_visible(minigame_hotkey, true)
        ui.set_visible(minigame_up, true)
        ui.set_visible(minigame_down, true)
    else
        ui.set_visible(minigame_hotkey, false)
        ui.set_visible(minigame_up, false)
        ui.set_visible(minigame_down, false)
    end
end
ui.set_callback(minigame_enabled, handle_menu)
handle_menu()

-- get_fps() pasted from admin's FPS Indicator https://gamesense.pub/forums/viewtopic.php?id=17280
local frametimes = {}
local fps_prev = 0
local last_update_time = 0

local function get_fps()
	local ft = globals.absoluteframetime()
	if ft > 0 then
		table.insert(frametimes, 1, ft)
	end

	local count = #frametimes
	if count == 0 then
		return 0
	end

	local i, accum = 0, 0
	while accum < 0.5 do
		i = i + 1
		accum = accum + frametimes[i]
		if i >= count then
			break
		end
	end
	accum = accum / i
	while i < count do
		i = i + 1
		table.remove(frametimes)
	end
	
	local fps = 1 / accum
	local rt = globals.realtime()
	if math.abs(fps - fps_prev) > 4 or rt - last_update_time > 2 then
		fps_prev = fps
		last_update_time = rt
	else
		fps = fps_prev
	end
	
	return math.floor(fps + 0.5)
end

-- Minigame pause screen
local function pause_screen()
    if ui.get(minigame_enabled) and not ui.get(minigame_hotkey) then
        renderer.rectangle(mid_x - 125, mid_y / 2.5 - 50, 250, 100, 0, 0, 0, 50)
        renderer.text(mid_x, mid_y / 2.5 - 12, 255, 255, 255, 100, "+c", nil, "PAUSED")
        renderer.text(mid_x, mid_y / 2.5 + 15, 255, 255, 255, 100, "bc", nil, 'Active "Pause" hotkey to resume')
    end
end
client.set_event_callback("paint_ui", pause_screen)

-- Pong minigame
local pong = {
    player = {
        x = 50,
        y = mid_y - 125,
        w = 20,
        h = screen_height / 8,
        score = 0,
        speed = 12
    },
    enemy = {
        x = screen_width - 20 - 50,
        y = mid_y - 125,
        w = 20,
        h = screen_height / 8,
        score = 0,
        speed = 12,
        direction = 1
    },
    ball = {
        x,
        y,
        x_vel,
        y_vel,
        accel = 0.01,
        r = 20,
        w = screen_height / 60,
        h = screen_height / 60,
    }
}

local function reset_pong()
    pong.ball.x = screen_width * .8
    pong.ball.y = mid_y + math.random(-200, 200)
    -- pong.ball.y_vel = 11 * (math.random(0, 1) * 2 - 1)
    pong.ball.y_vel = math.random(-10, 10)
    pong.ball.x_vel = 12
end
reset_pong()

local function pong_game()
    local r, g, b, a = ui.get(minigame_color)

    if ui.get(minigame_enabled) then
        if ui.get(minigame_hotkey) then
            -- FPS needed to make movement consistent on different FPS
            local fps = get_fps()
            local fps_scale = 60 / fps
            
            -- Ball movement
            pong.ball.x = pong.ball.x - pong.ball.x_vel * fps_scale
            pong.ball.y = pong.ball.y - pong.ball.y_vel * fps_scale

            -- Player controls
            if ui.get(minigame_up) then
                pong.player.y = pong.player.y - pong.player.speed * fps_scale
            end
            if ui.get(minigame_down) then
                pong.player.y = pong.player.y + pong.player.speed * fps_scale
            end

            -- Restrain player position
            if pong.player.y < 0 then
                pong.player.y = 0
            elseif pong.player.y > screen_height - pong.player.h then
                pong.player.y = screen_height - pong.player.h
            end

            -- Enemy controls
            if pong.ball.y + pong.ball.h < pong.enemy.y + pong.enemy.h / 2 then
                pong.enemy.direction = -1
            elseif pong.ball.y > pong.enemy.y - pong.enemy.h / 2 then
                pong.enemy.direction = 1
            else
                pong.enemy.direction = 0
            end
            
            pong.enemy.y = pong.enemy.y + pong.enemy.speed * pong.enemy.direction * fps_scale

            -- Restrain enemy position
            if pong.enemy.y < 0 then
                pong.enemy.y = 0
            elseif pong.enemy.y > screen_height - pong.enemy.h then
                pong.enemy.y = screen_height - pong.enemy.h
            end

            -- Ball collisions
            if (pong.ball.x < (pong.player.w + pong.player.x) and pong.ball.y >= pong.player.y - pong.ball.h and pong.ball.y <= pong.player.y + pong.player.h) and not (pong.ball.x + pong.player.w < pong.player.x) then
                pong.ball.x_vel = pong.ball.x_vel * (-1 - pong.ball.accel)
                pong.ball.y_vel = ((pong.player.y + pong.player.h / 2) - (pong.ball.y + pong.ball.h / 2)) / (pong.player.h / 2) * 15
            end

            if (pong.ball.x > screen_width - (screen_width - pong.enemy.x) - pong.ball.w and pong.ball.y >= pong.enemy.y - pong.ball.h and pong.ball.y <= pong.enemy.y + pong.enemy.h) and not (pong.ball.x > pong.enemy.x + pong.player.w) then
                pong.ball.x_vel = pong.ball.x_vel * (-1 - pong.ball.accel)
            end

            if pong.ball.y < 0 or pong.ball.y > screen_height - pong.ball.h then
                pong.ball.y_vel = pong.ball.y_vel * -1
            end

            -- Win condition
            if pong.ball.x < 0 - pong.ball.w then
                pong.enemy.score = pong.enemy.score + 1
                reset_pong()
            elseif pong.ball.x > screen_width then
                pong.player.score = pong.player.score + 1
                reset_pong()
            end

            -- Render players and ball
            for i = 1, 5 do
                renderer.rectangle(pong.ball.x + i, pong.ball.y + i, pong.ball.w, pong.ball.h, 0, 0, 0, 50)
            end
            renderer.rectangle(pong.ball.x, pong.ball.y, pong.ball.w, pong.ball.h, r, g, b, a)

            for i = 1, 5 do
                renderer.rectangle(pong.player.x + i, pong.player.y + i, pong.player.w, pong.player.h, 0, 0, 0, 50)
            end
            renderer.rectangle(pong.player.x, pong.player.y, pong.player.w, pong.player.h, r, g, b, a)
            
            for i = 1, 5 do
                renderer.rectangle(pong.enemy.x + i, pong.enemy.y + i, pong.enemy.w, pong.enemy.h, 0, 0, 0, 50)
            end
            renderer.rectangle(pong.enemy.x, pong.enemy.y, pong.enemy.w, pong.enemy.h, r, g, b, a)
            
            renderer.text(mid_x, 125, 255, 255, 255, 255, "+c", nil, pong.player.score .. " — " .. pong.enemy.score)

            renderer.texture(pong.ball.texture, pong.ball.x, pong.ball.y, pong.ball.w, pong.ball.h)
        else
            renderer.rectangle(pong.ball.x, pong.ball.y, pong.ball.w, pong.ball.h, r, g, b, a / 5)
            renderer.rectangle(pong.player.x, pong.player.y, pong.player.w, pong.player.h, r, g, b, a / 5)
            renderer.rectangle(pong.enemy.x, pong.enemy.y, pong.enemy.w, pong.enemy.h, r, g, b, a / 5)
            renderer.text(mid_x, 125, 255, 255, 255, 50, "+c", nil, pong.player.score .. " — " .. pong.enemy.score)
        end
    end
end
client.set_event_callback("paint_ui", pong_game)
