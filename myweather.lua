local wibox = require("wibox")
local gears = require("gears")
local awful = require("awful")
local json = require("lain.util.dkjson")

-- Weather configuration
local API_KEY = "eec8bea6e24153197509309a7e6fd348"
local CITY_ID = "2693678" -- Lund, SE

-- Create the textbox widget
local weather_widget = wibox.widget {
    widget = wibox.widget.textbox,
    align  = "center",
    valign = "center",
    markup = '<span color="#AAAAAA">Loading...</span>'
}

-- Function to try HTTP request with multiple fallbacks
local function try_http_request(url, callback)
    -- First try wget with proxy
    local wget_cmd_proxy = string.format("bash -c 'export HTTP_PROXY=http://wwwproxy.se.axis.com:3128; export HTTPS_PROXY=http://wwwproxy.se.axis.com:3128; wget -q -O - --timeout=10 \"%s\"'", url)

    awful.spawn.easy_async(wget_cmd_proxy, function(response, stderr, reason, exit_code)
        if exit_code == 0 and response and response ~= "" then
            callback(response, nil)
        else
            -- Try wget direct
            local wget_cmd_direct = string.format("wget -q -O - --timeout=10 '%s'", url)
            awful.spawn.easy_async(wget_cmd_direct, function(response2, stderr2, reason2, exit_code2)
                if exit_code2 == 0 and response2 and response2 ~= "" then
                    callback(response2, nil)
                else
                    -- Try curl with proxy as last resort
                    local curl_cmd_proxy = string.format("bash -c 'export HTTP_PROXY=http://wwwproxy.se.axis.com:3128; export HTTPS_PROXY=http://wwwproxy.se.axis.com:3128; curl -s --connect-timeout 10 --max-time 30 \"%s\"'", url)
                    awful.spawn.easy_async(curl_cmd_proxy, function(response3, stderr3, reason3, exit_code3)
                        if exit_code3 == 0 and response3 and response3 ~= "" then
                            callback(response3, nil)
                        else
                            -- All methods failed
                            local error_msg = "All HTTP methods failed - wget_proxy(" .. (exit_code or "?") .. ") wget_direct(" .. (exit_code2 or "?") .. ") curl_proxy(" .. (exit_code3 or "?") .. ")"
                            callback(nil, error_msg)
                        end
                    end)
                end
            end)
        end
    end)
end

-- Function to update weather
local function update_weather()
    -- Debug: Show that we're trying to fetch
    weather_widget.markup = '<span color="#AAAAAA">Fetching...</span>'

    -- Use HTTPS like the working sunrise widget
    local url = string.format("https://api.openweathermap.org/data/2.5/weather?id=%s&appid=%s&units=metric", CITY_ID, API_KEY)

    try_http_request(url, function(response, error_msg)
        if error_msg then
            weather_widget.markup = '<span color="#FF5555">Net Error</span>'
            return
        end

        -- Debug: Show we got a response
        weather_widget.markup = '<span color="#AAAAAA">Parsing...</span>'

        local data, pos, err = json.decode(response)
        if err then
            weather_widget.markup = '<span color="#FF5555">JSON Error</span>'
            return
        end

        if not data or not data.main or not data.main.temp then
            weather_widget.markup = '<span color="#FF5555">No Temp</span>'
            return
        end

        local temp = math.floor(data.main.temp)
        weather_widget.markup = string.format('<span color="#80CCE6">%d°C</span>', temp)
    end)
end-- Initial update with delay
gears.timer.start_new(5, function()
    update_weather()
    return false  -- Don't repeat, just run once
end)

-- Update every 10 minutes
gears.timer {
    timeout = 600,
    autostart = true,
    callback = update_weather
}

return weather_widget
