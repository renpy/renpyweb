#!/bin/bash

# 'the_question' and 'tutorial' are not suitable for distribution, we
# need to add missing fonts. Also enable console/developer mode.
# For debugging and showcasing at https://renpy.beuc.net/play/

set -ex

if [ -z "$1" ]; then
    echo "usage: $0 game.zip"
    exit 1
fi

workdir=$(mktemp -d)
unzip -d "$workdir" "$1"
mkdir -p "$workdir"/launcher/game/fonts
cp -a renpy/launcher/game/fonts/SourceHanSansLite.ttf "$workdir"/launcher/game/fonts
rm -f "$workdir"/game/script_version.txt
destzip=$(readlink -f "$1")
rm -f "$destzip"
(cd "$workdir" && zip -r "$destzip" .)
echo "'$1' ready."
