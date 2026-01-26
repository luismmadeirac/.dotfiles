# Ghostty Configuration for Neovim

This configuration is optimized for the Nightingale colorscheme in Neovim.

## What Changed

### Font
- **Family:** JetBrainsMono Nerd Font Mono
- **Size:** 13pt
- Provides all the icons needed for the statusline

### Colors
- **Background:** #1c1c1c (matching Nightingale)
- **Foreground:** #c0caf5 (light blue-white)
- **Cursor:** #7aa2f7 (blue, matching Primary color)
- Custom 16-color palette matching Tokyo Night/Nightingale theme

### Window
- Hidden titlebar for clean look
- 4px padding on all sides
- No close confirmation

## Testing

After restarting Ghostty, test the setup:

```bash
# Test icons
echo -e "\ue0b0 \ue0b2 \uf303   \uf07b \uf553"

# Test colors
for i in {0..15}; do
  echo -en "\e[48;5;${i}m  \e[0m"
  [ $((($i + 1) % 8)) -eq 0 ] && echo
done
```

## Customization

### Adjust Font Size
```
font-size = 14  # Larger
font-size = 12  # Smaller
```

### Enable Transparency
Uncomment these lines:
```
background-opacity=0.95
background-blur=true
```

### Change Background Color
```
background = #000000  # Pure black
background = #1a1b26  # Tokyo Night background
background = #1c1c1c  # Current (Nightingale-like)
```

### Enable Font Ligatures
Uncomment:
```
font-feature = -calt
font-feature = -liga
```

## Reload Configuration

Ghostty automatically reloads the config file when you save it.
If not, restart Ghostty completely (⌘Q and reopen).

## Backup

Your original config is saved as `config.bak`.

To restore:
```bash
cp ~/.config/ghostty/config.bak ~/.config/ghostty/config
```

## Key Features

✅ **JetBrains Mono Nerd Font** - All icons display correctly  
✅ **Dark theme** - Matches Nightingale in Neovim  
✅ **Custom palette** - 16 colors matching the theme  
✅ **Clean window** - No titlebar, minimal padding  
✅ **Performance** - Shell integration enabled  

## Neovim Integration

With this Ghostty config:
- Statusline icons (▊, , , etc.) display perfectly
- Colors match between terminal and Neovim
- True color support (24-bit) enabled by default
- Cursor color matches your theme

## Color Palette Reference

The palette matches these colors:
- **Blue (#7aa2f7):** Functions, keywords, primary
- **Purple (#bb9af7):** Strings, accent
- **Green (#9ece6a):** Added lines, success
- **Red (#f7768e):** Errors, deleted lines
- **Yellow (#e0af68):** Warnings, constants
- **Cyan (#7dcfff):** Types, info

## Documentation

Ghostty docs: https://ghostty.org/docs
