#!/bin/sh
# Mount den's storage share at ~/den-storage on first access, and unmount it
# after 10 idle minutes (autofs). den is reachable only on the tailnet, so
# Tailscale must be up for the mount to succeed.
#
# Runs on every apply but uses sudo only when /etc has drifted: a macOS upgrade
# can restore the stock /etc/auto_master. To pick up a rotated Samba password,
# reconnect once in Finder so the keychain has it, then:
#   sudo rm /etc/auto_den && chezmoi apply
set -eu

mountpoint="${HOME}/den-storage"
url_tail="den/storage"
user="dmikalova"
timeout=600

if grep -q '^/-[[:space:]]*auto_den' /etc/auto_master \
  && [ -f /etc/auto_den ] \
  && grep -q "^AUTOMOUNT_TIMEOUT=${timeout}\$" /etc/autofs.conf; then
  exit 0
fi

# Finder stores this when you connect to smb://den/storage and choose
# "Remember this password in my keychain".
if ! pw=$(security find-internet-password -s den -a "$user" -w 2>/dev/null); then
  echo "warning: no keychain password for smb://${user}@den; connect once in Finder (Cmd-K, smb://${url_tail}), then run chezmoi apply again" >&2
  exit 0
fi
enc=$(printf %s "$pw" | jq -sRr @uri)
unset pw

echo "configuring autofs for ${mountpoint} (sudo)"

# autofs mounts as root and cannot read the login keychain, so the map holds
# the password. Create the file 0600 before it has content.
if [ ! -f /etc/auto_den ]; then
  sudo install -m 600 -o root -g wheel /dev/null /etc/auto_den
  printf '%s\t-fstype=smbfs,soft,noowners,nosuid,nobrowse\t://%s:%s@%s\n' \
    "$mountpoint" "$user" "$enc" "$url_tail" | sudo tee /etc/auto_den >/dev/null
fi
unset enc

if ! grep -q '^/-[[:space:]]*auto_den' /etc/auto_master; then
  printf '/-\t\t\tauto_den\t-nosuid\n' | sudo tee -a /etc/auto_master >/dev/null
fi

# The timeout is global: it applies to every autofs mount on this Mac.
sudo sed -i '' "s/^AUTOMOUNT_TIMEOUT=.*/AUTOMOUNT_TIMEOUT=${timeout}/" /etc/autofs.conf

sudo automount -cv
