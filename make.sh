#!/usr/bin/env bash

set -eu
set -o pipefail

scratch=$(mktemp -d -t tmp.XXXXXXXXXX)
function finish {
	rm -rf "$scratch"
}
trap finish EXIT

device_id=$1
output=${2:-}
logo=$(realpath logo-v2.svg)

(

	cd "$scratch"

	if [ "$(printf "%s" "$device_id" | wc -c)" -ne 32 ]; then
		echo "value must be 32 characters exactly"
		exit 1
	fi

	title=$(curl --silent --fail 'https://api.notion.com/v1/pages/'"$device_id" \
		-H 'Notion-Version: 2022-06-28' \
		-H 'Authorization: Bearer '"$NOTION_API_KEY"'' |
		jq -r '.properties.Name.title[0].plain_text')

    echo "Printing a label for $device_id -- $title"

	qrcode --encode "https://www.notion.so/$1" >code.pbm
	convert code.pbm -scale 1200% code.png

	rm code.pbm

	margin=0
	lineheight=44
	convert \
		-size 300x$((lineheight * 4 + 1)) \
		xc:white \
		-font "FreeMono" \
		-pointsize 62 \
		-draw 'text '"$margin"','"$((lineheight * 1))"' "'"${1:0:8}"'"' \
		-draw 'text '"$margin"','"$((lineheight * 1))"' "'"${1:0:8}"'"' \
		-draw 'text '"$margin"','"$((lineheight * 1))"' "'"${1:0:8}"'"' \
		-draw 'text '"$margin"','"$((lineheight * 1))"' "'"${1:0:8}"'"' \
		-draw 'text '"$margin"','"$((lineheight * 1))"' "'"${1:0:8}"'"' \
		-draw 'text '"$margin"','"$((lineheight * 1))"' "'"${1:0:8}"'"' \
		-draw 'text '"$margin"','"$((lineheight * 2))"' "'"${1:8:8}"'"' \
		-draw 'text '"$margin"','"$((lineheight * 3))"' "'"${1:16:8}"'"' \
		-draw 'text '"$margin"','"$((lineheight * 3))"' "'"${1:16:8}"'"' \
		-draw 'text '"$margin"','"$((lineheight * 3))"' "'"${1:16:8}"'"' \
		-draw 'text '"$margin"','"$((lineheight * 3))"' "'"${1:16:8}"'"' \
		-draw 'text '"$margin"','"$((lineheight * 3))"' "'"${1:16:8}"'"' \
		-draw 'text '"$margin"','"$((lineheight * 3))"' "'"${1:16:8}"'"' \
		-draw 'text '"$margin"','"$((lineheight * 4))"' "'"${1:24:8}"'"' \
		bottom.png

	# Make the logo ~300px wide x ~380px tall
	convert "$logo" -scale 16% logo.resized.png

	# Stack the logo on top of the hash text
	convert -append -gravity Center logo.resized.png bottom.png logo.resized.png

	# place the logo+hashtext next to the QR code
	convert +append -gravity Center logo.resized.png code.png out.png

	if [ "${title:-}" != "" ]; then
		chars_per_line=18
		len=$(printf "%s" "$title" | wc -c)
		# + chars_per_line / 2 causes division to round up
		lines=$(((len + (chars_per_line / 2)) / chars_per_line))

		# going from the last line of text to the first
		# prepend the output image with our block of text.
		for line in $(seq "$lines" -1 0); do
			charstart=$((line * chars_per_line))
			if [ "${title:charstart:chars_per_line}" != "" ]; then
				echo "${title:charstart:chars_per_line}" |
					magick \
						-background white \
						-fill black \
						-size 696x$((lineheight + 10)) \
						-font "FreeMono" \
						-pointsize 62 \
						label:@- \
						title.png

				convert -append -gravity Center title.png out.png out.png
			fi
		done
	fi

	# I used this to adjust all the resize and dimensions above so the image
	# wasn't too tall ,but was 696px wide -- the ideal width for the 62red
	# tape:
	#
	magick identify out.png
)

if [ "${output:-}" != "" ]; then
	cp "$scratch/out.png" "$output"
else
	brother_ql \
		--model QL-800 \
		--backend pyusb \
		--printer usb://0x04f9:0x209b/000M0Z857837 \
		print \
		--label 62red --red \
		"$scratch/out.png"
fi
