-- goodluckOS port layer for R U NUTS: runs the unmodified game
-- (runuts_main.lua) on a 1600x900 virtual screen scaled into the display and
-- turns gamepad input into the keys the game reads.

-- LOVE turns the JIT off on ARM (jitsetup.lua); krabice's FFI vector library
-- asserts that it is on, and its cdata arithmetic is slow without it.
jit.on()
require 'runuts_main'

-- Game jam look for every level set (the development version gives the main
-- levels the post-it theme)
local Screens = require 'screens'
function Screens.themeFor() return 'blueprint' end

-- The nut's torque is applied once per frame and Box2D clears it after each
-- physics step, so below 60 fps the extra steps of a frame run without it and
-- the nut cannot roll over its corners (blueprint runs at about 49 fps here).
-- Apply it again before every further step of the frame.
local Simulation = require 'krabice.simulation'
local GameScreen = require 'screens.game'
local Input = require 'game.input'
local Nut = require 'game.nut'
local game_update = GameScreen.update

function GameScreen:update(dt)
    local first = true
    self.simulation.step = function(simulation, frames)
        if not first then
            local left, right = self.input:isDown(Input.LEFT), self.input:isDown(Input.RIGHT)
            if left ~= right then
                self.nut.body:applyTorque(left and -Nut.NUT_TORQUE or Nut.NUT_TORQUE)
            end
        end
        first = false
        return Simulation.step(simulation, frames)
    end
    game_update(self, dt)
    self.simulation.step = nil
end

local VIRTUAL_W, VIRTUAL_H = 1600, 900
local STICK_THRESHOLD = 0.5

local BUTTON_KEYS = {
    dpup = 'up', dpdown = 'down', dpleft = 'left', dpright = 'right',
    a = 'space', b = 'r', x = 'g', y = 'f4',
    start = 'p', back = 'q',
}
local AXIS_KEYS = { leftx = { 'left', 'right' }, lefty = { 'up', 'down' } }

local graphics = love.graphics
local pixel_width, pixel_height = graphics.getWidth, graphics.getHeight
local set_mode = love.window.setMode
local game_draw = love.draw
local scale, offset_x, offset_y = 1, 0, 0
local stick = {}

local function layout()
    local w, h = pixel_width(), pixel_height()
    scale = math.min(w / VIRTUAL_W, h / VIRTUAL_H)
    offset_x = math.floor((w - VIRTUAL_W * scale) / 2)
    offset_y = math.floor((h - VIRTUAL_H * scale) / 2)
end

function love.window.setMode()
    local ok = set_mode(0, 0, { fullscreen = true })
    layout()
    return ok
end

function graphics.getWidth() return VIRTUAL_W end
function graphics.getHeight() return VIRTUAL_H end
function graphics.getDimensions() return VIRTUAL_W, VIRTUAL_H end

function love.draw()
    graphics.push('all')
    graphics.translate(offset_x, offset_y)
    graphics.scale(scale)
    game_draw()
    graphics.pop()

    graphics.push('all')
    graphics.setColor(0, 0, 0)
    local w, h = pixel_width(), pixel_height()
    graphics.rectangle('fill', 0, 0, w, offset_y)
    graphics.rectangle('fill', 0, h - offset_y, w, offset_y)
    graphics.rectangle('fill', 0, 0, offset_x, h)
    graphics.rectangle('fill', w - offset_x, 0, offset_x, h)
    graphics.pop()
end

local function press(key)
    if key then love.keypressed(key, key, false) end
end

local function release(key)
    if key then love.keyreleased(key, key, false) end
end

function love.gamepadpressed(_, button) press(BUTTON_KEYS[button]) end
function love.gamepadreleased(_, button) release(BUTTON_KEYS[button]) end

function love.gamepadaxis(_, axis, value)
    local keys = AXIS_KEYS[axis]
    if not keys then return end
    local key = (value < -STICK_THRESHOLD and keys[1]) or (value > STICK_THRESHOLD and keys[2]) or nil
    if stick[axis] == key then return end
    release(stick[axis])
    press(key)
    stick[axis] = key
end
