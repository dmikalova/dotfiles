# Dot Files

Personal dot files managed with [Chezmoi](https://www.chezmoi.io/).

## Usage

Set the chezmoi source alias, then preview and apply:

```sh
alias chezmoi='chezmoi --source ~/Code/github.com/dmikalova/dotfiles'
chezmoi status
chezmoi diff
chezmoi apply
```

Add a file to chezmoi:

```sh
chezmoi add ~/.config/example/config.toml
```

Edit a managed file:

```sh
chezmoi edit ~/.zshrc
```
