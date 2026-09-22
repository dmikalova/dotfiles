# AWS SSO + Awsume helper
aws-auth() {
	local role="${1:-sb-ro}"

	# Check if SSO session is valid
	if ! aws sts get-caller-identity --profile "$role" &>/dev/null; then
		echo "AWS SSO not logged in. Logging in..."
		if ! aws sso login --profile "$role"; then
			echo "AWS SSO login failed"
			return 1
		fi
	fi

	awsume "$role"
	# echo "Switched to AWS role: $role"
}

aws-generate-config() {
	mkdir -p $HOME/.aws
	cat >$HOME/.aws/config <<'EOF'
[default]
cli_pager=
output = json
region = us-west-2
EOF

	aws-sso-util configure populate \
		--region us-west-2 \
		--sso-region us-west-2 \
		--sso-start-url https://d-9267a1970f.awsapps.com/start \
		--account-name-case lower \
		--role-name-case lower

	# shorten account names
	sed -i '' \
		-e 's/gs-production/prod/g' \
		-e 's/gs-sandbox/sb/g' \
		-e 's/gs-staging/stg/g' \
		-e 's/gs-internal/int/g' \
		$HOME/.aws/config

	# shorten/simplify role suffixes
	sed -i '' \
		-e 's/\.goodship-developer//g' \
		-e 's/\.readonlyaccess/-ro/g' \
		-e 's/\.administratoraccess/-admin/g' \
		$HOME/.aws/config

	# credential_process needs an absolute path; bare "aws-sso-util" isn't resolved via PATH
	sed -i '' 's|credential_process = aws-sso-util|credential_process = /opt/homebrew/bin/aws-sso-util|g' $HOME/.aws/config
}
