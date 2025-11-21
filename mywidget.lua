local wibox = require("wibox")
local gears = require("gears")
local awful = require("awful")

-- Create the textbox widget
local system_widget = wibox.widget {
    widget = wibox.widget.textbox,
    align  = "center",
    valign = "center",
    markup = '<span color="#AAAAAA">Loading...</span>'
}

-- Global variables to store data
local weather_data = "Loading..."
local uptime_data = "Loading..."
local news_data = "Loading..."

-- Function to update widget display
local function update_widget_display()
    local display_text = string.format(
        '<span color="#80CCE6">%s</span> | <span color="#FFB347">⏱ %s</span> | <span color="#DDA0DD">%s</span>',
        weather_data, uptime_data, news_data
    )
    system_widget.markup = display_text
    -- Debug: print to see what's happening
    -- print("Widget updated: " .. os.date("%H:%M:%S"))
end

-- Function to update weather using get_weather.sh
local function update_weather_widget()
    local cmd = "bash -c 'cd /home/likhithn/.config/awesome && ./get_weather.sh'"

    awful.spawn.easy_async(cmd, function(stdout, stderr, reason, exit_code)
        if stdout and stdout ~= "" then
            -- Clean up the output (remove newlines and trim whitespace)
            local weather_output = stdout:gsub("\n", ""):gsub("^%s*(.-)%s*$", "%1")

            if exit_code == 0 then
                weather_data = weather_output
            else
                weather_data = '<span color="#FF5555">' .. weather_output .. '</span>'
            end
        else
            -- Show stderr or reason if no stdout
            local error_msg = stderr or reason or "Weather Error"
            weather_data = '<span color="#FF5555">' .. error_msg .. '</span>'
        end
        update_widget_display()
    end)
end

-- Function to update uptime
local function update_uptime()
    awful.spawn.easy_async("uptime -p", function(stdout)
        if stdout and stdout ~= "" then
            -- Clean up uptime output (remove "up " and newline)
            local uptime_clean = stdout:gsub("up ", ""):gsub("\n", "")
            uptime_data = uptime_clean
        else
            uptime_data = "N/A"
        end
        update_widget_display()
    end)
end

-- Function to update news headlines
local function update_news()
    local cmd = "bash -c 'cd /home/likhithn/.config/awesome && ./get_news.sh'"

    awful.spawn.easy_async(cmd, function(stdout, stderr, reason, exit_code)
        if stdout and stdout ~= "" then
            local news_output = stdout:gsub("\n", ""):gsub("^%s*(.-)%s*$", "%1")
            -- Clean up CDATA tags that might be in RSS feeds
            news_output = news_output:gsub("%<%!%[CDATA%[", ""):gsub("%]%]%>", "")

            if exit_code == 0 then
                news_data = news_output
            else
                news_data = '<span color="#FF5555">' .. news_output .. '</span>'
            end
        else
            -- Show stderr or reason if no stdout
            local error_msg = stderr or reason or "📰 News Error"
            news_data = '<span color="#FF5555">' .. error_msg .. '</span>'
        end
        update_widget_display()
    end)
end

-- Initial updates
update_weather_widget()
update_uptime()
update_news()

-- Separate timers with different intervals to avoid conflicts
local weather_timer = gears.timer {
    timeout = 300,  -- 5 minutes for weather
    autostart = true,
    callback = update_weather_widget
}

local uptime_timer = gears.timer {
    timeout = 60,   -- 1 minute for uptime
    autostart = true,
    callback = update_uptime
}

local news_timer = gears.timer {
    timeout = 60,   -- 1 minute for news headline rotation
    autostart = true,
    callback = update_news
}

return system_widget
