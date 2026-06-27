# AWS SSO + Awsume helper
aws-auth() {
	if [[ -z "$1" ]]; then
		echo "Usage: aws-auth <role-name>"
		return 1
	fi

	local role="$1"

	# Check if SSO session is valid
	if ! aws sts get-caller-identity --profile codemobs.read &>/dev/null; then
		echo "AWS SSO not logged in. Logging in..."
		if ! aws sso login --profile codemobs.read; then
			echo "AWS SSO login failed"
			return 1
		fi
	fi

	awsume "$role"
	# echo "Switched to AWS role: $role"
}

aws-generate-config() {
	cat >~/.aws/config <<'EOF'
[default]
cli_pager=
output = json
region = us-west-2
EOF

	aws-sso-util configure populate \
		--region us-west-2 \
		--sso-region us-west-2 \
		--sso-start-url https://crunchycloud.awsapps.com/start \
		--account-name-case lower \
		--role-name-case lower \
		--trim-account-name '-(?<=pr)o(?=d)' \
		--trim-account-name '(?<=acc)oun(?=t)' \
		--trim-account-name '(?<=el)lation' \
		--trim-account-name '(?<=eng)ineering' \
		--trim-account-name '(?<=infra)structure' \
		--trim-account-name '(?<=int)ernal' \
		--trim-account-name '(?<=m)ana(?=g)|(?<=g)e(?=m)|(?<=m)en(?=t)' \
		--trim-account-name '(?<=pr)o(?=d)|(?<=d)uction' \
		--trim-account-name '(?<=sec)urity' \
		--trim-account-name '(?<=st)agin(?=g)' \
		--trim-account-name '^cr-' \
		--trim-account-name '^(?<=cr)unchyroll' \
		--trim-role-name '(?<=admin)istrator' \
		--trim-role-name '(?<=read)only' \
		--trim-role-name 'payer-'
	sed -i '' 's/elg/el-g/g' ~/.aws/config
	sed -i '' 's|credential_process = aws-sso-util|credential_process = /opt/homebrew/bin/aws-sso-util|g' ~/.aws/config
}
