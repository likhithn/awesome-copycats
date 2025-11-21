#!/bin/zsh
source /home/likhithn/.zshrc

# File to store headlines and current index
HEADLINES_FILE="/tmp/awesome_headlines.txt"
INDEX_FILE="/tmp/awesome_headlines_index.txt"

# Function to fetch new headlines
fetch_headlines() {
    # Using BBC RSS feed (no API key required) - try HTTPS first, then HTTP
    response=$(curl -s --max-time 30 "https://feeds.bbci.co.uk/news/rss.xml" 2>/dev/null)

    # If HTTPS fails, try HTTP
    if [ -z "$response" ]; then
        response=$(curl -s --max-time 30 "http://feeds.bbci.co.uk/news/rss.xml" 2>/dev/null)
    fi

    # If BBC fails, try Reuters
    if [ -z "$response" ]; then
        response=$(curl -s --max-time 30 "http://feeds.reuters.com/reuters/topNews" 2>/dev/null)
    fi

    # Check if we got a response
    if [ -z "$response" ]; then
        echo "📰 News Error: No response"
        exit 1
    fi

    # Extract multiple headlines (skip first 2 which are usually site title and description)
    echo "$response" | grep -o '<title>.*</title>' | tail -n +3 | head -10 | sed 's/<title>//g' | sed 's/<\/title>//g' | sed 's/&amp;/\&/g' | sed 's/&quot;/"/g' | sed 's/<!\[CDATA\[//g' | sed 's/\]\]>//g' | sed 's/&lt;/</g' | sed 's/&gt;/>/g' | sed 's/&#39;/'"'"'/g' > "$HEADLINES_FILE"

    # Reset index to 0
    echo "0" > "$INDEX_FILE"
}


# Main logic
# Check if headlines file exists and is less than 10 minutes old
if [ ! -f "$HEADLINES_FILE" ] || [ $(find "$HEADLINES_FILE" -mmin +10 2>/dev/null | wc -l) -eq 1 ]; then
    fetch_headlines
fi

# Check if headlines file has content
if [ ! -s "$HEADLINES_FILE" ]; then
    echo "📰 News Error: Could not parse headlines"
    exit 1
fi

# Get current index
if [ -f "$INDEX_FILE" ]; then
    current_index=$(cat "$INDEX_FILE")
else
    current_index=0
fi

# Get total number of headlines
total_headlines=$(wc -l < "$HEADLINES_FILE")

# If index is beyond available headlines, reset to 0
if [ "$current_index" -ge "$total_headlines" ]; then
    current_index=0
fi

# Get the current headline (1-indexed for sed)
headline_line=$((current_index + 1))
headline=$(sed -n "${headline_line}p" "$HEADLINES_FILE")

# If headline is empty, try first headline
if [ -z "$headline" ]; then
    headline=$(head -1 "$HEADLINES_FILE")
    current_index=0
fi

# Increment index for next time
next_index=$((current_index + 1))
if [ "$next_index" -ge "$total_headlines" ]; then
    next_index=0
fi
echo "$next_index" > "$INDEX_FILE"

# Truncate if too long and add news emoji
if [ ${#headline} -gt 60 ]; then
    headline="${headline:0:57}..."
fi

echo "📰 $headline"
