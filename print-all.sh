#!/usr/bin/env bash

set -eu
set -o pipefail

database_id=$1

ids_to_print() (
	local database_id=$1
	curl --silent --fail -X POST 'https://api.notion.com/v1/databases/'"$database_id"'/query' \
		-H 'Authorization: Bearer '"$NOTION_API_KEY"'' \
		-H 'Notion-Version: 2022-06-28' \
		-H "Content-Type: application/json" \
		--data "$(jq -n '.filter = { "property": "Print", "checkbox": { "equals": true } }')" |
		jq -r '.results[] |.id' | tr -d '-'
)

mark_printed() (
	local id=$1
	curl --silent --fail https://api.notion.com/v1/pages/"$id" \
		-H 'Authorization: Bearer '"$NOTION_API_KEY"'' \
		-H "Content-Type: application/json" \
		-H "Notion-Version: 2022-06-28" \
		-X PATCH \
		--data "$(jq -n '.properties.Print.checkbox = false')" |
		jq .
)

(
	for id in $(ids_to_print "$database_id"); do
		./make.sh "$id"
		mark_printed "$id" >/dev/null
	done
)
