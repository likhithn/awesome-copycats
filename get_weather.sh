#!/bin/zsh
source /home/likhithn/.zshrc
response=$(curl -s "http://api.openweathermap.org/data/2.5/weather?id=2693678&appid=eec8bea6e24153197509309a7e6fd348&units=metric" 2>/dev/null)

temp=$(echo "$response" | jq -r '"\(.main.temp)°C"')
summary=$(echo "$response" | jq -r '"\(.weather[0].main)"')
sunrise_epoch=$(echo "$response" | jq -r '.sys.sunrise')
sunset_epoch=$(echo "$response" | jq -r '.sys.sunset')
sunrise=$(date -d @"$sunrise_epoch" +"%H:%M")
sunset=$(date -d @"$sunset_epoch" +"%H:%M")
if [ -z "$temp" ] || [ -z "$summary" ] || [ -z "$sunrise" ] || [ -z "$sunset" ]; then
    echo "Parse Error: Unknown issue"
    exit 1
fi
echo "$temp | $summary | 🌅 $sunrise | 🌇 $sunset "
