-- Rendering for the Mali-400. Every card sprite in the game goes through a
-- shader with about a dozen uniforms, which rules out batching, and every text
-- glyph is a Text object with a draw call of its own.

local gfx = love.graphics
local draw, print_text, set_font = gfx.draw, gfx.print, gfx.setFont

-- gfx.print goes through LOVE's automatic batching, drawing a Text object does not.
local Text = {}
Text.__index = Text

function Text:set(text)
    self.text = type(text) == 'table' and text[2] or text
    self.width = nil
end
function Text:getWidth()
    self.width = self.width or self.font:getWidth(self.text)
    return self.width
end
function Text:getHeight() return self.font:getHeight() end
function Text:release() end

function gfx.newText(font, text)
    local object = setmetatable({font = font}, Text)
    object:set(text)
    return object
end

local current_font
function gfx.setFont(font, ...)
    current_font = font
    return set_font(font, ...)
end

function gfx.draw(object, ...)
    if getmetatable(object) ~= Text then return draw(object, ...) end
    if current_font ~= object.font then gfx.setFont(object.font) end
    return print_text(object.text, ...)
end

-- Edition effects keep their look but stop animating: the first draw renders the
-- sprite through the real shader into a small canvas, later draws use the canvas.
local BAKED = {foil = true, holo = true, polychrome = true, negative = true, negative_shine = true,
               booster = true, voucher = true, debuff = true, played = true}
local MAX_BAKES = 256
local bakes, bake_count = {}, 0

local function bake(sprite, shader_name, send)
    local _, _, w, h = sprite.sprite:getViewport()
    local canvas = gfx.newCanvas(w, h, {dpiscale = 1})
    canvas:setFilter('linear', 'linear')
    local shader = G.SHADERS[shader_name]
    shader:send('mouse_screen_pos', {0, 0})
    shader:send('screen_scale', 1)
    shader:send('hovering', 0)
    shader:send('dissolve', 0)
    shader:send('time', 123.33412)
    shader:send('texture_details', sprite:get_pos_pixel())
    shader:send('image_details', sprite:get_image_dims())
    shader:send('burn_colour_1', G.C.CLEAR)
    shader:send('burn_colour_2', G.C.CLEAR)
    shader:send('shadow', false)
    if send then shader:send(shader_name, send) end

    gfx.push('all')
    gfx.origin()
    gfx.setScissor()
    gfx.setCanvas(canvas)
    gfx.clear(0, 0, 0, 0)
    gfx.setShader(shader, shader)
    gfx.setColor(1, 1, 1, 1)
    draw(sprite.atlas.image, sprite.sprite, 0, 0)
    gfx.pop()
    return canvas
end

local function draw_baked(sprite, shader_name, send)
    local pos = sprite.sprite_pos
    local key = sprite.atlas.name .. ':' .. pos.x .. ':' .. pos.y .. ':' .. shader_name
    local canvas = bakes[key]
    if not canvas then
        if bake_count >= MAX_BAKES then
            for _, old in pairs(bakes) do old:release() end
            bakes, bake_count = {}, 0
        end
        canvas = bake(sprite, shader_name, send)
        bakes[key], bake_count = canvas, bake_count + 1
    end

    prep_draw(sprite, 1)
    gfx.scale(1/(sprite.scale.x/sprite.VT.w), 1/(sprite.scale.y/sprite.VT.h))
    gfx.setColor(G.BRUTE_OVERLAY or G.C.WHITE)
    gfx.setBlendMode('alpha', 'premultiplied')
    draw(canvas, 0, 0, 0, sprite.VT.w/sprite.T.w, sprite.VT.h/sprite.T.h)
    gfx.setBlendMode('alpha', 'alphamultiply')
    gfx.pop()
    add_to_drawhash(sprite)
end

local draw_shader = Sprite.draw_shader
function Sprite:draw_shader(shader, shadow_height, send, no_tilt, other_obj, ms, mr, mx, my, custom_shader, tilt_shadow)
    if shader == 'flame' then return end
    local major = self.role.draw_major or self
    if not shadow_height and (major.dissolve or 0) == 0 then
        if other_obj then
            if shader == 'voucher' then return end
            if shader == nil or shader == 'dissolve' or shader == 'hologram' then
                return self:draw_from(other_obj, ms, mr, mx, my)
            end
        elseif shader == nil or shader == 'dissolve' then
            return self:draw_self()
        elseif BAKED[shader] then
            return draw_baked(self, shader, send)
        end
    end
    return draw_shader(self, shader, shadow_height, send, no_tilt, other_obj, ms, mr, mx, my, custom_shader, tilt_shadow)
end

-- The swirl shaders need more fragment precision than the Mali-400 has and come
-- out as one flat colour there, at about 100 ms per frame.
local function flat_colour(step)
    if step.shader == 'background' then return G.C.BACKGROUND.C end
    for _, uniform in ipairs(step.send) do
        if uniform.name == 'colour_2' then return uniform.val or uniform.ref_table[uniform.ref_value] end
    end
    return G.C.BLUE
end

local sprite_draw = Sprite.draw
function Sprite:draw(overlay)
    local step = self == G.SPLASH_BACK and self.draw_steps and self.draw_steps[1]
    if step and (step.shader == 'background' or step.shader == 'splash') then
        local colour = flat_colour(step)
        gfx.clear(colour[1], colour[2], colour[3], 1)
        return
    end
    return sprite_draw(self, overlay)
end

local splash_screen = Game.splash_screen
function Game:splash_screen(...)
    self.SETTINGS.skip_splash = 'Yes'
    return splash_screen(self, ...)
end
