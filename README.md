# dotfiles

My macOS setup, managed with [yadm](https://yadm.io). The repo's work tree is my actual home directory, so these are real files sitting where they belong. No symlink farm to babysit, and a new machine gets dressed in one command.

## Ash

I paint my own terminal palettes. The current one is **Ash**: black glass, a plain grey ramp, and pastel color only where it carries meaning. It replaced Voltage, which was louder than it needed to be.

![Ash palette](.github/assets/ash.svg)

The top row is the grey ramp, from the black glass up to the text color. The bottom row is the pastels: rose, peach, butter, mint, aqua, sky, lilac, plus pure white. Hover and selection are white washes (5% and 10%), borders are 7% white hairlines, and sky `#a6c8f4` is the one accent.

It's built to match my [T3 Code glass build](https://github.com/dyascj/t3code/tree/glass), so the terminal and the browser read as the same app. Ghostty reads the palette from `.config/ghostty/ash.conf` and dresses like T3 in `config`: black glass at 85% with a 23px blur, SF Mono, tabs in the title bar, roomy padding, and a matching dock icon. Zen Browser wears it as a `userChrome.css` in `.config/zen/chrome/`, riding Zen's native macOS vibrancy on the clear fullScreenUI material with a 55% black wash on top, a touch lighter than T3's black glass. The acrylic url bar and compact sidebar float over it.

Zed has a full theme at `.config/zed/themes/ash.json` with a blurred window. VS Code gets the colors through `workbench.colorCustomizations` and `editor.tokenColorCustomizations` in `settings.json`, on solid black. btop has a transparent variant in `.config/btop/themes/ash.theme` with grey boxes and pastel graphs. One palette, five surfaces.

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

- `brew bundle --global` installs everything in the Brewfile, apps included (Ghostty, Zen, Zed, VS Code, AeroSpace, Sol). A failed package gets reported and the setup keeps going.
- Copies SF Mono out of Terminal.app so Ghostty can use it.
- Installs my VS Code extensions from a saved list.
- Clones my [T3 Code glass fork](https://github.com/dyascj/t3code/tree/glass) into `~/Developer/t3code-glass`, links `t3-glass-update` into `~/.local/bin`, and sets up the private Rust toolchain it builds with. Run `t3-glass-update` afterwards to build and install the app (it takes a few minutes).
- Sets zsh as the default shell.

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
