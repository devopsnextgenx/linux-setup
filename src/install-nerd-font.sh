#!/input/local/bin/bash

# Determine the OS and set the correct font directory
if [[ "$OSTYPE" == "linux-gnu"* ]]; then
    FONT_DIR="$HOME/.local/share/fonts"
elif [[ "$OSTYPE" == "darwin"* ]]; then
    FONT_DIR="$HOME/Library/Fonts"
else
    echo "Unsupported OS. Please install the fonts manually."
    exit 1
fi

# Create the directory if it doesn't exist
mkdir -p "$FONT_DIR"

echo "Downloading MesloLGS NF fonts from GitHub..."

# URLs for the 4 required styles
URLS=(
    "https://github.com/romkatv/powerlevel10k-media/raw/master/MesloLGS%20NF%20Regular.ttf"
    "https://github.com/romkatv/powerlevel10k-media/raw/master/MesloLGS%20NF%20Bold.ttf"
    "https://github.com/romkatv/powerlevel10k-media/raw/master/MesloLGS%20NF%20Italic.ttf"
    "https://github.com/romkatv/powerlevel10k-media/raw/master/MesloLGS%20NF%20Bold%20Italic.ttf"
)

for url in "${URLS[@]}"; do
    filename=$(basename "$url" | sed 's/%20/ /g')
    echo "Downloading $filename..."
    curl -L -s -o "$FONT_DIR/$filename" "$url"
done

# Update font cache (Linux only)
if [[ "$OSTYPE" == "linux-gnu"* ]]; then
    echo "Updating font cache..."
    fc-cache -f "$FONT_DIR"
fi

echo "Fonts installed successfully!"
echo "⚠️ IMPORTANT: You must open your Terminal settings and change the font to 'MesloLGS NF' before proceeding."