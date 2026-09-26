#!/bin/sh
# Import GitHub's web-flow signing keys, which sign the commits GitHub makes
# (web edits, merges and API commits such as the conformance bot's), so git
# can verify them. SSH signatures, ours, are checked against allowed_signers
# instead. With a key of our own, certify them locally so git reports them as
# good (G) rather than of unknown validity (U); gpg asks for its passphrase.
set -eu

curl -fsSL https://github.com/web-flow.gpg | gpg --quiet --import

if [ -n "$(gpg --list-secret-keys --with-colons 2>/dev/null)" ]; then
  for fpr in 968479A1AFF927E37D1A566BB5690EEEBB952194 5DE3E0509C47EA3CF04A42D34AEE18F83AFDEB23; do
    gpg --quiet --quick-lsign-key "$fpr" 2>/dev/null || true
  done
fi
