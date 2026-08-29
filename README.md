# dotfiles

My macOS setup, managed with [yadm](https://yadm.io). The repo's work tree is my actual home directory, so these are real files sitting where they belong. No symlink farm to babysit, and a new machine gets dressed in one command.

## Voltage

I paint my own terminal palettes. The current one is **Voltage**: a pure neutral black with electric, fully saturated accents. No tint in the greys, all the color in the signal.

![Voltage palette](.github/assets/voltage.svg)

The top row is the ANSI terminal palette, the bottom row is the syntax palette (keyword, string, number, constant, variable, function, type, text). Background is `#0a0a0a`, surfaces are `#171717`, the accent is `#009fff`, and the terminal cursor is a pale `#b4cbff`.

Ghostty reads the palette from `.config/ghostty/voltage.conf`. VS Code gets the same colors through `workbench.colorCustomizations` in `settings.json`, layered over a translucent window (vscode-vibrancy). Neovim runs its own build of the theme, a single-file colorscheme at `.config/nvim/colors/voltage.lua` with full treesitter and diagnostic highlights, and it keeps a transparent background so the terminal blur shows through. Zed has a full theme at `.config/zed/themes/voltage.json`. Zen Browser wears it as a `userChrome.css` in `.config/zen/chrome/`, Obsidian gets a full theme (plus a paper light mode) in `.config/obsidian/themes/Voltage/`, and btop has a transparent variant in `.config/btop/themes/`. One palette, seven surfaces.

## What's inside

| Tool | Where |
| --- | --- |
| [Ghostty](https://ghostty.org) | `.config/ghostty/` |
| VS Code | `Library/Application Support/Code/User/settings.json` |
| zsh | `.zshrc`, `.zprofile` |
| [powerlevel10k](https://github.com/romkatv/powerlevel10k) | `.p10k.zsh` |
| Neovim | `.config/nvim/` |
| [Zed](https://zed.dev) | `.config/zed/` |
| [Zen Browser](https://zen-browser.app) | `.config/zen/chrome/userChrome.css` |
| [Obsidian](https://obsidian.md) | `.config/obsidian/themes/Voltage/` |
| btop | `.config/btop/` |
| neofetch | `.config/neofetch/` |
| Homebrew | `.Brewfile` |

## New machine

```sh
brew install yadm
yadm clone https://github.com/dyascj/dotfiles.git
yadm bootstrap
```

`yadm clone` puts every file where it belongs. The [bootstrap script](.config/yadm/bootstrap) handles the rest: installs Homebrew if it's missing, runs `brew bundle --global` for everything in the Brewfile, installs my VS Code extensions from a saved list, and sets zsh as the default shell.

Zen and Obsidian hide their config behind machine-specific folder names (a random profile hash, per-vault settings), so those two are the exception to the no-symlinks rule: bootstrap finds the active Zen profile and every registered Obsidian vault, then links the theme files in from `.config`. Run `yadm bootstrap` again after the first launch of either app and it wires them up.

## Day to day

yadm is just git with your home directory as the work tree, so the muscle memory carries over:

```sh
yadm status
yadm add .config/ghostty/voltage.conf
yadm commit -m "warmer cursor"
yadm push
```

Machine-specific stuff never touches the repo. `.zshrc` sources an untracked `~/.zshrc.local` at the end if one exists.
