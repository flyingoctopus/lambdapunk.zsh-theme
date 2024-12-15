# lambdapunk.zsh-theme

A minimal, Monokai-inspired Zsh theme with dynamic prompts, VCS integration, and command timing.

## Features

- **Version Control**: Displays branch, commit hash, and status for Git and Mercurial. Handles detached HEAD and uncommitted repos.
- **Dynamic Prompt**: Small terminal width? We got you fam. And featuring symbols like `ॐ` (success) and `λ` (error).
- **Package Manager Awareness**: Supports `venv`, `conda`, `nix-shell`, and `asdf`.
- **Command Timing**: Tracks duration and timestamps of commands.

## Prerequisites

- **Zsh** and **Oh My Zsh** installed.
- Nerd Font for icons: [https://www.nerdfonts.com/](https://www.nerdfonts.com/).
- git/mercurial/miniforge/asdf/nix-shell for VCS prompts (optional).

## Installation

1. Download the theme:
   ```sh
   mkdir -p $ZSH_CUSTOM/themes
   curl -o $ZSH_CUSTOM/themes/lambdapunk.zsh-theme https://raw.githubusercontent.com/flyingoctopus/lambdapunk.zsh-theme/refs/heads/main/lambdapunk.zsh-theme
   ```
2. Set it in `.zshrc`:
   ```sh
   ZSH_THEME="lambdapunk"
   ```
3. Reload Zsh:
   ```sh
   source ~/.zshrc
   ```

## Example Prompt

```sh
ॐ  user in hostname using [~/projects/my-repo]
~ git status
```
