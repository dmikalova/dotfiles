package main

import (
	"encoding/hex"
	"encoding/json"
	"fmt"
	"os"
	"os/exec"
	"sort"
	"strings"
)

const keychainService = "dotfiles-secrets"

func keychainAccount() string {
	if u := os.Getenv("USER"); u != "" {
		return u
	}
	return os.Getenv("LOGNAME")
}

// isHex reports whether s looks like a hex-encoded byte string. `security
// -w` prints values containing non-ASCII bytes as hex and plain text
// otherwise, so callers must detect which they got before decoding.
func isHex(s string) bool {
	if s == "" || len(s)%2 != 0 {
		return false
	}
	for _, r := range s {
		if !strings.ContainsRune("0123456789abcdefABCDEF", r) {
			return false
		}
	}
	return true
}

func loadSecrets() (map[string]string, error) {
	out, err := exec.Command("security", "find-generic-password", "-a", keychainAccount(), "-s", keychainService, "-w").Output()
	if err != nil {
		if exitErr, ok := err.(*exec.ExitError); ok && strings.Contains(string(exitErr.Stderr), "could not be found") {
			return map[string]string{}, nil
		}
		return nil, fmt.Errorf("reading %s from keychain: %w", keychainService, err)
	}

	raw := strings.TrimSpace(string(out))
	if raw == "" {
		return map[string]string{}, nil
	}

	jsonBytes := []byte(raw)
	if isHex(raw) {
		decoded, err := hex.DecodeString(raw)
		if err != nil {
			return nil, fmt.Errorf("hex-decoding keychain value: %w", err)
		}
		jsonBytes = decoded
	}

	secrets := map[string]string{}
	if err := json.Unmarshal(jsonBytes, &secrets); err != nil {
		return nil, fmt.Errorf("parsing keychain value as JSON: %w", err)
	}
	return secrets, nil
}

func saveSecrets(secrets map[string]string) error {
	data, err := json.Marshal(secrets)
	if err != nil {
		return err
	}

	cmd := exec.Command("security", "add-generic-password", "-a", keychainAccount(), "-s", keychainService, "-w", string(data), "-U")
	if out, err := cmd.CombinedOutput(); err != nil {
		return fmt.Errorf("writing %s to keychain: %w (%s)", keychainService, err, strings.TrimSpace(string(out)))
	}
	return nil
}

func sortedKeys(secrets map[string]string) []string {
	keys := make([]string, 0, len(secrets))
	for k := range secrets {
		keys = append(keys, k)
	}
	sort.Strings(keys)
	return keys
}
