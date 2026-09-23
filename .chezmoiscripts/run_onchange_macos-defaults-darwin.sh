#!/bin/sh
# macOS system preferences not covered by System Settings sync

echo "configuring macos defaults"

# Displays have separate Spaces: off (share one strip of Spaces across all
# displays, so window-manager logic that assumes a single space list keeps
# working with multiple monitors). Requires logging out to fully take effect.
defaults write com.apple.spaces spans-displays -bool true

# Desktop: no icons
defaults write com.apple.finder CreateDesktop -bool false

# Menu bar: always show Sound (volume) icon. On macOS 26's Control Center
# ("BentoBox") menu bar, an item only renders once it has a preferred
# position, not just a visibility flag - confirmed by diffing
# com.apple.controlcenter before/after toggling this manually.
defaults write com.apple.controlcenter "NSStatusItem VisibleCC Sound" -bool true
defaults write com.apple.controlcenter "NSStatusItem Preferred Position Sound" -int 281

# Keyboard shortcut: Spotlight search on Option+Space instead of Command+Space
# (ID 64 = "Show Spotlight search"). Parameters are (ASCII code, key code,
# modifier flags); 524288 = Option. This writes the correct value, but on
# macOS 26 the live hotkey daemon does not hot-load AppleSymbolicHotKeys from
# disk - confirmed even a full logout doesn't pick it up. It only takes
# effect once you open System Settings > Keyboard > Keyboard Shortcuts >
# Spotlight and interact with the shortcut field directly (re-pressing
# Option+Space there registers it live, with no resulting file change).
# This write just pre-seeds the correct value; the manual step is still
# required once per machine.
defaults write com.apple.symbolichotkeys AppleSymbolicHotKeys -dict-add "64" \
	'{enabled = 1; value = {parameters = (32, 49, 524288); type = standard;};}'

# Appearance: Light, no auto dark-mode switching, Green accent
defaults delete NSGlobalDomain AppleInterfaceStyle 2>/dev/null || true
defaults write NSGlobalDomain AppleInterfaceStyleSwitchesAutomatically -bool false
defaults write NSGlobalDomain AppleAccentColor -int 3
defaults write NSGlobalDomain AppleAquaColorVariant -int 1

killall Dock 2>/dev/null || true
killall Finder 2>/dev/null || true
killall ControlCenter 2>/dev/null || true
