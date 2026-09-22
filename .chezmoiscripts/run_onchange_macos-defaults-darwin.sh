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

# Appearance: Light, no auto dark-mode switching, Green accent
defaults delete NSGlobalDomain AppleInterfaceStyle 2>/dev/null || true
defaults write NSGlobalDomain AppleInterfaceStyleSwitchesAutomatically -bool false
defaults write NSGlobalDomain AppleAccentColor -int 3
defaults write NSGlobalDomain AppleAquaColorVariant -int 1

killall Dock 2>/dev/null || true
killall Finder 2>/dev/null || true
killall ControlCenter 2>/dev/null || true
