# GitHub Copilot CLI
# Docs: https://docs.github.com/en/copilot/concepts/agents/about-copilot-cli

# Shell command suggestions
alias '??'='copilot -p'

# Explain a command
copilot_explain() {
	copilot -p "Explain this command: $*" -s
}
alias 'explain'='copilot_explain'
