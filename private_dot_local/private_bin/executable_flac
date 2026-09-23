for f in *.flac; do metaflac --set-tag="ARTIST=Matmos" --set-tag="ALBUM=Invisibles" --set-tag="TITLE=$f" "$f"; done

for f in *.flac; do         echo $f >> tags.txt;         metaflac --export-tags-to=tags.tmp "$f";         cat tags.tmp >> tags.txt;         rm tags.tmp; done
