local awful = require('awful')
local wibox = require('wibox')
local gears = require('gears')

local notes_file = os.getenv('HOME') .. '/.notes'
local editor = os.getenv('EDITOR') or 'code'

-- Ensure notes file exists
awful.spawn.with_shell('test -f "' .. notes_file .. '" || touch "' .. notes_file .. '"')

local textbox = wibox.widget{
    align = 'left',
    valign = 'center',
    widget = wibox.widget.textbox
}

local container = wibox.container.margin(textbox, 6, 6)

-- Function to update preview (first line)
local function update()
    local fh = io.open(notes_file, 'r')
    if not fh then
        textbox.text = 'No notes yet — click to create'
        return
    end
    local first = fh:read('*l')
    fh:close()
    if first == nil or first == '' then
        textbox.text = 'No notes yet — click to create'
    else
        -- Trim and shorten
        if #first > 60 then
            first = first:sub(1,57) .. '...'
        end
        textbox.text = first
    end
end

-- Update at start and periodically
update()
gears.timer{timeout = 10, autostart = true, callback = update}

-- Open editor on click
container:buttons(gears.table.join(
    awful.button({}, 1, function()
        awful.spawn(string.format('%s %s', editor, notes_file))
    end)
))

return container
