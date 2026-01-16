# dotfiles

catppuccin mocha theme for ghostty, zen browser, sketchybar, and more.

## what's in here

```
dotfiles/
├── ghostty/
│   ├── config
│   └── catppuccin-mocha.conf
├── vscode/
│   └── settings.json
├── zen-browser/
│   ├── userChrome.css
│   └── userContent.css
├── sketchybar/
│   ├── sketchybarrc
│   └── plugins/
├── yabai/
│   ├── yabairc
│   └── skhdrc
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

### zen browser

1. go to `about:config`
2. set `toolkit.legacyUserProfileCustomizations.stylesheets` to `true`
3. go to `about:support` → click "Open Profile Folder"
4. make a `chrome` folder if it doesn't exist
5. copy the css files there:

```bash
cp zen-browser/*.css ~/Library/Application\ Support/zen/Profiles/*.Default*/chrome/
```

6. restart zen

### sketchybar

```bash
brew install FelixKratz/formulae/sketchybar
cp -r sketchybar ~/.config/
chmod +x ~/.config/sketchybar/plugins/*
brew services start sketchybar
```

hide the default menu bar:
```bash
defaults write NSGlobalDomain _HIHideMenuBar -bool true && killall Finder
```

### yabai

```bash
brew install koekeishiya/formulae/yabai koekeishiya/formulae/skhd
cp yabai/yabairc ~/.yabairc
cp yabai/skhdrc ~/.skhdrc
chmod +x ~/.yabairc
yabai --start-service
skhd --start-service
```

grant accessibility permissions when prompted.

### starship

```bash
brew install starship
cp starship.toml ~/.config/starship.toml
```

add to your shell rc:
```bash
eval "$(starship init zsh)"
```

## hotkeys

| key | action |
|-----|--------|
| alt + hjkl | focus window |
| shift + alt + hjkl | swap window |
| alt + 1-5 | switch space |
| shift + alt + 1-5 | move window to space |
| alt + f | fullscreen |
| alt + t | toggle float |
| alt + r | rotate layout |

## notes

- ghostty uses hack nerd font
- zen uses blue (`#89b4fa`) for active tabs, mauve (`#cba6f7`) for accents
- sketchybar floats with rounded corners
- yabai uses bsp tiling with 10px gaps
