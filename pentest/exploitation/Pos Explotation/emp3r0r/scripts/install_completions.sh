#!/bin/bash

# Script to install emp3r0r shell completions

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" &>/dev/null && pwd)"
BINARY_PATH="$SCRIPT_DIR/../core/emp3r0r"

# Check if emp3r0r binary exists
if [ ! -f "$BINARY_PATH" ]; then
    echo "Error: emp3r0r binary not found at $BINARY_PATH"
    echo "Please build the binary first or adjust the path in this script."
    exit 1
fi

# Determine shell
SHELL_TYPE=$(basename "$SHELL")

# Install completions based on shell
case "$SHELL_TYPE" in
bash)
    # Create bash completion directory if it doesn't exist
    BASH_COMPLETION_DIR="$HOME/.bash_completion.d"
    mkdir -p "$BASH_COMPLETION_DIR"

    # Generate and install bash completion
    "$BINARY_PATH" completion bash >"$BASH_COMPLETION_DIR/emp3r0r"

    # Add to bashrc if not already there
    if ! grep -q "bash_completion.d/emp3r0r" "$HOME/.bashrc"; then
        echo -e "\n# emp3r0r completion\nif [ -f \"$BASH_COMPLETION_DIR/emp3r0r\" ]; then\n  source \"$BASH_COMPLETION_DIR/emp3r0r\"\nfi" >>"$HOME/.bashrc"
        echo "Added completion to ~/.bashrc - restart your shell or run 'source ~/.bashrc'"
    else
        echo "Bash completion already configured in ~/.bashrc"
    fi
    ;;

zsh)
    # Create zsh completion directory if needed
    ZSH_COMPLETION_DIR="${fpath[1]:-$HOME/.zsh/completion}"
    mkdir -p "$ZSH_COMPLETION_DIR"

    # Generate and install zsh completion
    "$BINARY_PATH" completion zsh >"$ZSH_COMPLETION_DIR/_emp3r0r"

    # Check if compinit is in zshrc
    if ! grep -q "compinit" "$HOME/.zshrc"; then
        echo -e "\n# Initialize completion system\nautoload -U compinit; compinit" >>"$HOME/.zshrc"
    fi

    # Add completion directory to fpath if needed
    if ! grep -q "$ZSH_COMPLETION_DIR" "$HOME/.zshrc"; then
        echo -e "\n# emp3r0r completion\nfpath=($ZSH_COMPLETION_DIR \$fpath)" >>"$HOME/.zshrc"
        echo "Added completion to ~/.zshrc - restart your shell or run 'source ~/.zshrc'"
    else
        echo "Zsh completion already configured in ~/.zshrc"
    fi
    ;;

*)
    # For other shells, provide manual instructions
    echo "Automatic setup not supported for $SHELL_TYPE"
    echo -e "\nManual installation instructions:"
    echo "- For bash: emp3r0r completion bash > ~/.bash_completion"
    echo "- For zsh: emp3r0r completion zsh > ~/.zsh/completion/_emp3r0r"
    ;;
esac

echo "Shell completion installation complete!"
