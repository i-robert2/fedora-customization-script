mod_userpic() {
    echo "[userpic] Setting user avatar from GitHub profile..."

    local AVATAR_URL="https://avatars.githubusercontent.com/u/65817006?v=4"
    local AVATAR_DIR="$HOME/.local/share/icons"
    local AVATAR_FILE="$AVATAR_DIR/user-avatar.png"
    mkdir -p "$AVATAR_DIR"

    curl -fsSL -o "$AVATAR_FILE" "$AVATAR_URL"
    echo "  Avatar downloaded (full resolution)."

    # Set as the user account picture (shows on login screen + system menu)
    sudo cp "$AVATAR_FILE" "/var/lib/AccountsService/icons/$(whoami)"
    sudo chmod 644 "/var/lib/AccountsService/icons/$(whoami)"

    # Update AccountsService config to point to the icon
    local AS_FILE="/var/lib/AccountsService/users/$(whoami)"
    if [ -f "$AS_FILE" ]; then
        sudo sed -i "s|^Icon=.*|Icon=/var/lib/AccountsService/icons/$(whoami)|" "$AS_FILE"
    else
        sudo tee "$AS_FILE" > /dev/null <<EOF
[User]
Icon=/var/lib/AccountsService/icons/$(whoami)
EOF
    fi

    echo "  User avatar set (visible on login screen + system menu)."
}