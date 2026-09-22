// Command secrets is a small TUI for managing the JSON blob of secrets
// stored in the macOS Keychain under the "dotfiles-secrets" generic
// password entry (see exports.zsh.tmpl, which reads it at shell startup).
package main

import (
	"fmt"
	"os"

	"github.com/charmbracelet/bubbles/textinput"
	tea "github.com/charmbracelet/bubbletea"
	"github.com/charmbracelet/lipgloss"
)

func main() {
	secrets, err := loadSecrets()
	if err != nil {
		fmt.Fprintln(os.Stderr, err)
		os.Exit(1)
	}

	m := newModel(secrets)
	if _, err := tea.NewProgram(m).Run(); err != nil {
		fmt.Fprintln(os.Stderr, err)
		os.Exit(1)
	}
}

type mode int

const (
	modeList mode = iota
	modeAddKey
	modeAddValue
	modeEditValue
	modeRenameKey
	modeConfirmDelete
)

var (
	titleStyle  = lipgloss.NewStyle().Bold(true).Foreground(lipgloss.Color("212"))
	cursorStyle = lipgloss.NewStyle().Foreground(lipgloss.Color("212"))
	keyStyle    = lipgloss.NewStyle().Bold(true)
	valueStyle  = lipgloss.NewStyle().Foreground(lipgloss.Color("245"))
	helpStyle   = lipgloss.NewStyle().Foreground(lipgloss.Color("241"))
	errorStyle  = lipgloss.NewStyle().Foreground(lipgloss.Color("204"))
	promptStyle = lipgloss.NewStyle().Bold(true)
	emptyStyle  = lipgloss.NewStyle().Foreground(lipgloss.Color("241")).Italic(true)
	maskedValue = "••••••••"
)

type model struct {
	secrets  map[string]string
	keys     []string
	cursor   int
	revealed map[string]bool

	mode       mode
	input      textinput.Model
	pendingKey string // key being added/edited/renamed/deleted

	status   string
	err      error
	quitting bool
}

func newTextInput(placeholder string, mask bool) textinput.Model {
	ti := textinput.New()
	ti.Placeholder = placeholder
	ti.CharLimit = 256
	ti.Width = 40
	ti.Focus()
	if mask {
		ti.EchoMode = textinput.EchoPassword
		ti.EchoCharacter = '•'
	}
	return ti
}

func newModel(secrets map[string]string) model {
	return model{
		secrets:  secrets,
		keys:     sortedKeys(secrets),
		revealed: map[string]bool{},
	}
}

func (m model) Init() tea.Cmd {
	return nil
}

func (m model) Update(msg tea.Msg) (tea.Model, tea.Cmd) {
	keyMsg, ok := msg.(tea.KeyMsg)
	if !ok {
		return m, nil
	}

	switch m.mode {
	case modeList:
		return m.updateList(keyMsg)
	case modeConfirmDelete:
		return m.updateConfirmDelete(keyMsg)
	default:
		return m.updateInput(keyMsg)
	}
}

func (m model) updateList(msg tea.KeyMsg) (tea.Model, tea.Cmd) {
	m.status = ""
	m.err = nil

	switch msg.String() {
	case "ctrl+c", "q", "esc":
		m.quitting = true
		return m, tea.Quit

	case "up", "k":
		if m.cursor > 0 {
			m.cursor--
		}

	case "down", "j":
		if m.cursor < len(m.keys)-1 {
			m.cursor++
		}

	case "enter", " ":
		if key, ok := m.currentKey(); ok {
			m.revealed[key] = !m.revealed[key]
		}

	case "a":
		m.mode = modeAddKey
		m.input = newTextInput("key name", false)

	case "e":
		if key, ok := m.currentKey(); ok {
			m.pendingKey = key
			m.mode = modeEditValue
			m.input = newTextInput("new value", true)
		}

	case "r":
		if key, ok := m.currentKey(); ok {
			m.pendingKey = key
			m.mode = modeRenameKey
			m.input = newTextInput("new key name", false)
			m.input.SetValue(key)
		}

	case "d", "x":
		if key, ok := m.currentKey(); ok {
			m.pendingKey = key
			m.mode = modeConfirmDelete
		}
	}

	return m, nil
}

func (m model) updateConfirmDelete(msg tea.KeyMsg) (tea.Model, tea.Cmd) {
	switch msg.String() {
	case "y", "Y":
		delete(m.secrets, m.pendingKey)
		delete(m.revealed, m.pendingKey)
		if err := saveSecrets(m.secrets); err != nil {
			m.err = err
		} else {
			m.status = fmt.Sprintf("removed %s", m.pendingKey)
		}
		m.keys = sortedKeys(m.secrets)
		if m.cursor >= len(m.keys) && m.cursor > 0 {
			m.cursor = len(m.keys) - 1
		}
		m.mode = modeList
	case "n", "N", "esc":
		m.mode = modeList
	}
	return m, nil
}

func (m model) updateInput(msg tea.KeyMsg) (tea.Model, tea.Cmd) {
	switch msg.String() {
	case "esc":
		m.mode = modeList
		m.pendingKey = ""
		return m, nil

	case "enter":
		return m.submitInput()

	case "ctrl+c":
		m.quitting = true
		return m, tea.Quit
	}

	var cmd tea.Cmd
	m.input, cmd = m.input.Update(msg)
	return m, cmd
}

func (m model) submitInput() (tea.Model, tea.Cmd) {
	value := m.input.Value()

	switch m.mode {
	case modeAddKey:
		if value == "" {
			m.err = fmt.Errorf("key name can't be empty")
			return m, nil
		}
		if _, exists := m.secrets[value]; exists {
			m.err = fmt.Errorf("%s already exists", value)
			return m, nil
		}
		m.pendingKey = value
		m.mode = modeAddValue
		m.input = newTextInput("value", true)
		m.err = nil
		return m, nil

	case modeAddValue:
		m.secrets[m.pendingKey] = value
		return m.commit(fmt.Sprintf("added %s", m.pendingKey))

	case modeEditValue:
		m.secrets[m.pendingKey] = value
		return m.commit(fmt.Sprintf("updated %s", m.pendingKey))

	case modeRenameKey:
		if value == "" {
			m.err = fmt.Errorf("key name can't be empty")
			return m, nil
		}
		if value != m.pendingKey {
			if _, exists := m.secrets[value]; exists {
				m.err = fmt.Errorf("%s already exists", value)
				return m, nil
			}
			m.secrets[value] = m.secrets[m.pendingKey]
			delete(m.secrets, m.pendingKey)
			if m.revealed[m.pendingKey] {
				m.revealed[value] = true
			}
			delete(m.revealed, m.pendingKey)
		}
		return m.commit(fmt.Sprintf("renamed %s -> %s", m.pendingKey, value))
	}

	return m, nil
}

// commit saves the in-memory secrets map to the Keychain and returns to the
// list view, keeping the cursor on the key that was just touched.
func (m model) commit(status string) (tea.Model, tea.Cmd) {
	touched := m.pendingKey
	if err := saveSecrets(m.secrets); err != nil {
		m.err = err
	} else {
		m.status = status
	}
	m.keys = sortedKeys(m.secrets)
	m.mode = modeList
	m.pendingKey = ""
	for i, k := range m.keys {
		if k == touched {
			m.cursor = i
			break
		}
	}
	return m, nil
}

func (m model) currentKey() (string, bool) {
	if m.cursor < 0 || m.cursor >= len(m.keys) {
		return "", false
	}
	return m.keys[m.cursor], true
}

func (m model) View() string {
	if m.quitting {
		return ""
	}

	switch m.mode {
	case modeAddKey:
		return m.viewInput("Add secret", "key name:")
	case modeAddValue:
		return m.viewInput(fmt.Sprintf("Add secret: %s", m.pendingKey), "value:")
	case modeEditValue:
		return m.viewInput(fmt.Sprintf("Edit secret: %s", m.pendingKey), "new value:")
	case modeRenameKey:
		return m.viewInput(fmt.Sprintf("Rename secret: %s", m.pendingKey), "new key name:")
	case modeConfirmDelete:
		return m.viewList() + "\n" + promptStyle.Render(fmt.Sprintf("Delete %s? (y/n)", m.pendingKey))
	default:
		return m.viewList()
	}
}

func (m model) viewList() string {
	var b []string
	b = append(b, titleStyle.Render("dotfiles-secrets")+"  "+helpStyle.Render("(macOS Keychain)"))
	b = append(b, "")

	if len(m.keys) == 0 {
		b = append(b, emptyStyle.Render("no secrets yet -- press 'a' to add one"))
	}

	for i, key := range m.keys {
		cursor := "  "
		if i == m.cursor {
			cursor = cursorStyle.Render("> ")
		}
		value := maskedValue
		if m.revealed[key] {
			value = m.secrets[key]
		}
		b = append(b, fmt.Sprintf("%s%s  %s", cursor, keyStyle.Render(key), valueStyle.Render(value)))
	}

	b = append(b, "")
	if m.err != nil {
		b = append(b, errorStyle.Render("error: "+m.err.Error()))
	} else if m.status != "" {
		b = append(b, helpStyle.Render(m.status))
	}
	b = append(b, helpStyle.Render("enter/space reveal  a add  e edit  r rename  d delete  q quit"))

	return joinLines(b)
}

func (m model) viewInput(title, label string) string {
	b := []string{
		titleStyle.Render(title),
		"",
		promptStyle.Render(label),
		m.input.View(),
	}
	if m.err != nil {
		b = append(b, "", errorStyle.Render("error: "+m.err.Error()))
	}
	b = append(b, "", helpStyle.Render("enter confirm  esc cancel"))
	return joinLines(b)
}

func joinLines(lines []string) string {
	out := ""
	for i, line := range lines {
		if i > 0 {
			out += "\n"
		}
		out += line
	}
	return out
}
