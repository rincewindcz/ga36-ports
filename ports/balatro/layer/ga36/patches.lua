-- Text edits to the game's Lua source, applied in memory as each file is loaded.
-- Every edit states how often it must match, so a game version this port does
-- not know stops with a message instead of running half patched.

local M = {}

local function replace(source, path, old, new, expected)
    local parts, from, count = {}, 1, 0
    while true do
        local first, last = source:find(old, from, true)
        if not first then break end
        parts[#parts + 1] = source:sub(from, first - 1)
        parts[#parts + 1] = new
        from = last + 1
        count = count + 1
    end
    parts[#parts + 1] = source:sub(from)
    if expected and count ~= expected then
        error(path .. ': this game version is not supported, expected ' .. expected ..
            ' of "' .. old .. '", found ' .. count, 0)
    end
    return table.concat(parts)
end

local function replace_line(source, path, prefix, new)
    local first = source:find(prefix, 1, true)
    if not first then
        error(path .. ': this game version is not supported, missing "' .. prefix .. '"', 0)
    end
    local last = source:find('\n', first, true) or #source + 1
    return source:sub(1, first - 1) .. new .. source:sub(last)
end

local function jit_off_on_arm(source, path)
    source = replace(source, path, "(love.system.getOS() == 'OS X' ) and (jit.arch == 'arm64' or jit.arch == 'arm')", "jit.arch == 'arm'")
    return replace(source, path, "(love.system.getOS() == 'OS X' )and (jit.arch == 'arm64' or jit.arch == 'arm')", "jit.arch == 'arm'")
end

local MODULES = {
    'portmaster/text_cleanup', 'portmaster/loc_fix', 'portmaster/achievements', 'portmaster/cpu_opt',
    'portmaster/particle_cleanup', 'portmaster/controls', 'portmaster/small_screen', 'portmaster/perf',
    'ga36/render',
}

local SWAY = {
    '0.02*math.sin(2*G.TIMERS.REAL+card.T.x)',
    '0.02*math.sin(2*G.TIMERS.REAL+card.T.x+card.T.y)',
    '0.1*math.sin(0.666*G.TIMERS.REAL+card.T.x)',
    '0.03*math.sin(0.666*G.TIMERS.REAL+card.T.x)',
    '0.05*math.sin(2*1.666*G.TIMERS.REAL+card.T.x)',
}

local EDITS = {}

EDITS['main.lua'] = function(s, p)
    s = jit_off_on_arm(s, p)
    local requires = {'require "challenges"'}
    for _, module in ipairs(MODULES) do requires[#requires + 1] = 'require "' .. module .. '"' end
    s = replace(s, p, 'require "challenges"', table.concat(requires, '\n'), 1)
    return replace(s, p, 'resources/fonts/m6x11plus.ttf', 'ga36/Nunito-Black.ttf')
end

EDITS['engine/sound_manager.lua'] = jit_off_on_arm
EDITS['engine/save_manager.lua'] = jit_off_on_arm

EDITS['globals.lua'] = function(s, p)
    s = replace(s, p, 'crt = 70,', 'crt = 0,', 1)
    s = replace(s, p, 'bloom = 1', 'bloom = 0', 1)
    s = replace(s, p, "shadows = 'On'", "shadows = 'Off'", 1)
    return replace(s, p, 'texture_scaling = 2,', 'texture_scaling = 1,', 1)
end

EDITS['game.lua'] = function(s, p)
    s = replace(s, p, 'resources/fonts/m6x11plus.ttf', 'ga36/Nunito-Black.ttf')
    s = replace(s, p, '{mipmaps = true,', '{mipmaps = false,')

    -- No CJK fonts or languages: 61 MB of fonts, and the 2x atlases on top ran the console out of memory.
    s = replace(s, p, 'if love.filesystem.getInfo(v.file) then',
        "if not v.file:find('GoNoto', 1, true) and not v.file:find('NotoSans[SKJT]') then", 1)
    s = replace(s, p, 'for _, v in pairs(self.LANGUAGES) do',
        "for _, k in ipairs({'ja', 'ko', 'zh_CN', 'zh_TW'}) do self.LANGUAGES[k] = nil end\n" ..
        '        self.FONTS[8], self.FONTS[9] = self.FONTS[1], self.FONTS[1]\n' ..
        '        for _, v in pairs(self.LANGUAGES) do', 1)

    -- The splash is skipped, so its logos are not needed.
    s = replace_line(s, p, '{name = "playstack_logo"', '')
    s = replace(s, p, '{name = "localthunk_logo", path = "resources/textures/1x/localthunk-logo.png", px=1390,py=560}', '', 1)
    s = replace(s, p, "(not G.SETTINGS.tutorial_complete) and G.SETTINGS.tutorial_progress.completed_parts['big_blind']",
        "(not G.SETTINGS.tutorial_complete) and G.SETTINGS.tutorial_progress and G.SETTINGS.tutorial_progress.completed_parts['big_blind']", 1)

    -- Draw to the screen: no game canvas, no CRT pass.
    s = replace(s, p, 'love.graphics.setCanvas{self.CANVAS}', '', 1)
    s = replace(s, p, 'love.graphics.setCanvas(G.AA_CANVAS)', '', 1)
    s = replace(s, p, 'love.graphics.draw(self.CANVAS, 0, 0)', '', 1)
    return replace(s, p, 'if (not G.recording_mode or G.video_control )and true then', 'if false then', 1)
end

EDITS['cardarea.lua'] = function(s, p)
    for _, sway in ipairs(SWAY) do
        s = replace(s, p, '(G.SETTINGS.reduced_motion and 0 or 1)*' .. sway, '(G.SETTINGS.reduced_motion and 0 or ' .. sway .. ')')
    end
    return replace(s, p, '(G.SETTINGS.reduced_motion and 0 or 1)*', '(G.SETTINGS.reduced_motion and 0 or 1)*', 0)
end

EDITS['engine/text.lua'] = function(s, p)
    s = replace(s, p, 'if self.config.quiver then', 'if self.config.quiver and not G.SETTINGS.reduced_motion then', 1)
    s = replace(s, p, '(G.SETTINGS.reduced_motion and 0 or 1)*0.02*math.sin(2*G.TIMERS.REAL+k)',
        '(G.SETTINGS.reduced_motion and 0 or 0.02*math.sin(2*G.TIMERS.REAL+k))', 1)
    s = replace_line(s, p, 'if self.config.float then letter.offset.y =',
        'if self.config.float then letter.offset.y = (G.SETTINGS.reduced_motion and 0 or math.sqrt(self.scale)*(2+(self.font.FONTSCALE/G.TILESIZE)*2000*math.sin(2.666*G.TIMERS.REAL+200*k))) + 60*(letter.scale-1) end')
    return replace_line(s, p, 'if self.config.bump then letter.offset.y =',
        'if self.config.bump then letter.offset.y = (G.SETTINGS.reduced_motion and 0 or self.bump_amount*math.sqrt(self.scale)*7*math.max(0, (5+self.bump_rate)*math.sin(self.bump_rate*G.TIMERS.REAL+200*k) - 3 - self.bump_rate)) end')
end

function M.apply(path, source)
    local edit = EDITS[path]
    return edit and edit(source, path) or source
end

return M
