# dotfiles

![Ash: T3 Code glass, Ghostty with neofetch and cmatrix, AeroSpace tiling and SketchyBar](.github/assets/desktop.png)

My macOS setup, managed with [yadm](https://yadm.io). The repo's work tree is my actual home directory, so these are real files sitting where they belong. No symlink farm to babysit, and a new machine gets dressed in one command.

## Ash

I paint my own terminal palettes. The current one is **Ash**: black glass, a plain grey ramp, and pastel color only where it carries meaning. It replaced Voltage, which was louder than it needed to be.

![Ash palette](.github/assets/ash.svg)

The top row is the grey ramp, from the black glass up to the text color. The bottom row is the pastels: rose, peach, butter, mint, aqua, sky, lilac, plus pure white. Hover and selection are white washes (5% and 10%), borders are 7% white hairlines, and sky `#a6c8f4` is the one accent.

It's built to match my [T3 Code glass build](https://github.com/dyascj/t3code/tree/glass), so the terminal and the browser read as the same app. Ghostty reads the palette from `.config/ghostty/ash.conf` and dresses like T3 in `config`: black glass at 85% with a 23px blur, SF Mono, tabs in the title bar, roomy padding, and a matching dock icon. Zen Browser wears it as a `userChrome.css` in `.config/zen/chrome/`, riding Zen's native macOS vibrancy on the clear fullScreenUI material with a 55% black wash on top, a touch lighter than T3's black glass. The acrylic url bar and compact sidebar float over it. Websites can be see-through too: bootstrap turns on Zen's transparent-page pref and the sheet drops the white tint Zen lays behind pages, then the [Zen Internet](https://addons.mozilla.org/en-US/firefox/addon/zen-internet/) add-on clears the backgrounds of the sites in its style library (GitHub, YouTube and friends), so the glass runs right through the page.

Zed has a full theme at `.config/zed/themes/ash.json` with a blurred window. VS Code gets the colors through `workbench.colorCustomizations` and `editor.tokenColorCustomizations` in `settings.json`, on solid black. btop has a transparent variant in `.config/btop/themes/ash.theme` with grey boxes and pastel graphs. One palette, five surfaces.


## Tiling

Windows tile with [AeroSpace](https://github.com/nikitabobko/AeroSpace) across five workspaces, with 10pt gaps. The config lives in `.config/aerospace/aerospace.toml`, and the smart stacking and free mode behind it in `.config/aerospace/mode.sh`.

### Smart stacking

A new window splits the window you're in, and each split turns the other way from the last. Windows spiral into a grid instead of piling into thin strips:

```
1 window      2 windows      3 windows       4 windows
┌───────┐     ┌───┬───┐      ┌───┬───┐       ┌───┬───┐
│       │     │   │   │      │   │ 2 │       │   │ 2 │
│   1   │     │ 1 │ 2 │      │ 1 ├───┤       │ 1 ├─┬─┤
│       │     │   │   │      │   │ 3 │       │   │3│4│
└───────┘     └───┴───┘      └───┴───┘       └───┴─┴─┘
```

- **Pick where it lands.** The new window splits whichever window is focused, so click the one it should share space with before opening it. Open from 1 instead of 3 above and you get a 2x2 grid.
- **Tidy up** (⌥=) rebuilds the workspace you're on into the spiral and evens out the sizes. Use it when a workspace gets messy, or after dragging windows in from another one.
- **Flip** (⌥/) turns a split sideways when a pair would read better stacked, or side by side.
- **Two to four windows** per workspace is the sweet spot on a 14" screen. Past that, apps hit their minimum sizes (Finder won't go below about 480pt wide) and start spilling off the edge.

### Free mode

⌥T floats every window so it moves and resizes like stock macOS, and new windows float too. Press it again and everything snaps back into the smart stack. Workspaces work the same in both. System Settings always floats.

### Controls

Every shortcut is Option-based.

| Keys | Does |
| --- | --- |
| ⌥1 to ⌥5 | Go to that workspace |
| ⌥⇧1 to ⌥⇧5 | Send the window you're in there |
| ⌥⇥ | Back to the last workspace |
| ⌥T | Tiling or free mode |
| ⌥F | Float or tile just this window |
| ⌥↩ | Fullscreen |
| ⌥/ | Flip the split |
| ⌥= | Tidy up: smart stack and even out sizes |
| ⌃⌥ arrows | Move the window left, right, up or down |

Option alone with the arrows is left for jumping by word in text.

My Keychron has no right Option key, so right Control stands in for it. A LaunchAgent in `Library/LaunchAgents/local.keyboard.right-option.plist` remaps it with `hidutil` at every login. The Mac's own keyboards have no right Control, so they're untouched.

## What's inside

| Tool | Where |
| --- | --- |
| [Ghostty](https://ghostty.org) | `.config/ghostty/` |
| VS Code | `Library/Application Support/Code/User/settings.json` |
| zsh | `.zshrc`, `.zprofile` |
| [powerlevel10k](https://github.com/romkatv/powerlevel10k) | `.p10k.zsh` |
| [Zed](https://zed.dev) | `.config/zed/` |
| [Zen Browser](https://zen-browser.app) | `.config/zen/chrome/userChrome.css` |
| [T3 Code](https://github.com/dyascj/t3code/tree/glass) (glass fork) | cloned by bootstrap |
| btop | `.config/btop/` |
| [AeroSpace](https://github.com/nikitabobko/AeroSpace) | `.config/aerospace/` |
| neofetch | `.config/neofetch/` |
| Homebrew | `.Brewfile` |

## New machine

```sh
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
eval "$(/opt/homebrew/bin/brew shellenv)"
brew install yadm
yadm clone https://github.com/dyascj/dotfiles.git
yadm bootstrap
```

Homebrew comes first because yadm installs through it. `yadm clone` puts every file where it belongs, and the [bootstrap script](.config/yadm/bootstrap) handles the rest:

- `brew bundle --global` installs everything in the Brewfile, apps included (Ghostty, Zen, Zed, VS Code, AeroSpace, Sol, Tailscale, Vorssaint). A failed package gets reported and the setup keeps going.
- Copies SF Mono out of Terminal.app so Ghostty can use it.
- Installs my VS Code extensions from a saved list.
- Clones my [T3 Code glass fork](https://github.com/dyascj/t3code/tree/glass) into `~/Developer/t3code-glass`, links `t3-glass-update` into `~/.local/bin`, and sets up the private Rust toolchain it builds with. Run `t3-glass-update` afterwards to build and install the app (it takes a few minutes).
- Sets zsh as the default shell.
- Starts AeroSpace, which starts itself at every login after that.

A few things only macOS can say yes to, so they wait for me after bootstrap:

- **Privacy & Security > Accessibility:** turn on AeroSpace, or nothing tiles.
- **Tailscale:** sign in.
- **Zen Internet:** install the add-on in Zen, open its popup and hit "Refetch latest styles" with auto-update on.

Zen hides its config behind a machine-specific profile folder, so it's the one exception to the no-symlinks rule: bootstrap finds the active Zen profile, links `userChrome.css` in from `.config`, and turns on the prefs the theme needs. Zen has no profile until it's opened once, so launch it, quit it, and run `yadm bootstrap` again to wire it up. Every step skips what's already done, so rerunning is safe.

## Day to day

yadm is just git with your home directory as the work tree, so the muscle memory carries over:

```sh
yadm status
yadm add .config/ghostty/ash.conf
yadm commit -m "warmer cursor"
yadm push
```

Machine-specific stuff never touches the repo. `.zshrc` sources an untracked `~/.zshrc.local` at the end if one exists.
