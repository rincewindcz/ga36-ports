_RELEASE_MODE = true
_DEMO = false

function love.conf(t)
    t.identity = 'game'
    t.console = false
    t.title = 'Balatro'
    t.window.width = 0
    t.window.height = 0
    t.window.minwidth = 100
    t.window.minheight = 100
    t.modules.physics = false
end
