find *.po -exec sh -c "msggrep -w15000 -Ke '' {} | sed -nE '/^$|(msgid)/p' | sed -E 's/^msgid \\\"(.*)\\\"/\\1/' > {}.txt" ;
