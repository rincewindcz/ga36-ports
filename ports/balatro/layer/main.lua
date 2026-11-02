-- Runs the user's Balatro.exe or Balatro.love: mounts it over this layer and
-- applies ga36/patches.lua to its Lua source as it is loaded. Nothing of the
-- game is stored or rewritten. The game file has to be in the LOVE save
-- directory, the only place LOVE 11.5 mounts archives from.

local function show_message(text)
    function love.load()
        love.window.setMode(0, 0, {fullscreen = true})
        love.graphics.setFont(love.graphics.newFont('ga36/Nunito-Black.ttf', 22))
    end
    function love.draw()
        local w, h = love.graphics.getDimensions()
        love.graphics.printf(text, 40, h/2 - 100, w - 80, 'center')
    end
    function love.gamepadpressed() love.event.quit() end
    function love.keypressed() love.event.quit() end
end

local function find_game()
    local save = love.filesystem.getSaveDirectory()
    for _, name in ipairs(love.filesystem.getDirectoryItems('')) do
        local ext = name:lower():match('%.(%w+)$')
        if (ext == 'exe' or ext == 'love') and love.filesystem.getRealDirectory(name) == save then
            return name
        end
    end
end

local function start_game(name)
    assert(love.filesystem.mount(name, '', false), name .. ' could not be opened')
    assert(love.filesystem.getInfo('game.lua') and love.filesystem.getInfo('version.jkr'), name .. ' is not Balatro')

    local patch = require('ga36/patches').apply
    local function compile(path)
        local source = assert(love.filesystem.read(path))
        return assert(loadstring(patch(path, source), '@' .. path))
    end

    table.insert(package.loaders, 2, function(module)
        local path = module:gsub('%.', '/') .. '.lua'
        if love.filesystem.getInfo(path) then return compile(path) end
    end)

    local new_thread = love.thread.newThread
    love.thread.newThread = function(file)
        if not love.filesystem.getInfo(file) then return new_thread(file) end
        return new_thread(patch(file, love.filesystem.read(file)))
    end

    compile('main.lua')()
end

local game = find_game()
if not game then
    show_message('Balatro game file not found.\n\nCopy Balatro.exe from the Windows game or Balatro.love from the macOS game into ports/balatro/love/game and start again.\n\nPress any button to quit.')
else
    local ok, message = xpcall(start_game, debug.traceback, game)
    if not ok then
        print(message)
        local reason = tostring(message):match('^[^\n]*'):gsub('^.-: ', '')
        show_message('Balatro could not be started.\n\n' .. reason .. '\n\nPress any button to quit.')
    end
end
