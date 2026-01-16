# dotfiles

catppuccin mocha theme for ghostty, sketchybar, and more.

## what's in here

```
dotfiles/
├── ghostty/
│   ├── config
│   └── catppuccin-mocha.conf
├── vscode/
│   └── settings.json
├── sketchybar/
│   ├── sketchybarrc
│   └── plugins/
│       ├── cpu.sh
│       ├── ram.sh
│       └── space.sh
└── starship.toml
```

## colors

[catppuccin mocha](https://github.com/catppuccin/catppuccin)

| color | hex | usage |
|-------|-----|-------|
| base | `#1e1e2e` | main background |
| mantle | `#181825` | sidebar, content boxes |
| crust | `#11111b` | darkest background |
| surface0 | `#313244` | dialogs, toolbars |
| surface1 | `#45475a` | hover states, borders |
| text | `#cdd6f4` | primary text |
| subtext0 | `#a6adc8` | secondary text |
| mauve | `#cba6f7` | primary accent |
| blue | `#89b4fa` | selected tabs, links |
| lavender | `#b4befe` | button hover |
| sapphire | `#74c7ec` | link hover |

## setup

### ghostty

```bash
cp ghostty/* ~/.config/ghostty/
```

### vs code

```bash
# macos
cp vscode/settings.json ~/Library/Application\ Support/Code/User/settings.json

# linux
cp vscode/settings.json ~/.config/Code/User/settings.json
```

### sketchybar

minimal floating badges showing CPU, RAM, and desktop spaces.

```bash
brew install FelixKratz/formulae/sketchybar
cp -r sketchybar ~/.config/
chmod +x ~/.config/sketchybar/plugins/*
brew services start sketchybar
```

features:
- transparent bar with floating pill-shaped badges
- left side: clickable desktop spaces (1-5)
- right side: CPU % and RAM usage
- click CPU/RAM to open Activity Monitor

note: clicking spaces requires enabling keyboard shortcuts in System Settings > Keyboard > Keyboard Shortcuts > Mission Control > Switch to Desktop 1-5 (ctrl+1 through ctrl+5).

### starship

```bash
brew install starship
cp starship.toml ~/.config/starship.toml
```

add to your shell rc:
```bash
eval "$(starship init zsh)"
```

## notes

- ghostty uses hack nerd font
- sketchybar uses floating badges with 70% opacity backgrounds
- all configs use catppuccin mocha mauve (`#cba6f7`) as the primary accent
