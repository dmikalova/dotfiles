#!/bin/sh
# One-time manual setup checklist: settings macOS doesn't expose via a plain
# `defaults` key on this OS version, or that would need sudo inside an
# unattended chezmoi script. Runs once per machine (chezmoi tracks it), and
# again only if this file's contents change.

cat <<'EOF'

=========================================================
  Manual macOS setup checklist (one-time, not scriptable)
=========================================================

Lock/sleep timing (System Settings > Lock Screen):
  - "Turn display off after" (currently ~5 min via pmset)
  - "Require password after screen saver begins or display
     is turned off" -> set your preferred delay
  Not stored in any readable `defaults` key on this macOS
  version, and `pmset` requires sudo, so this stays manual.

Spaces (Mission Control):
  - Ensure exactly 2 Spaces exist: work = space 1,
    personal = space 2 (matches dot_hammerspoon/apps.lua)

=========================================================

EOF
