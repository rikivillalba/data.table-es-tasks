#/usr/bin/R

# Reconvertir txt a PO

setwd("C:\\Users\\AR30592993\\Documents\\R\\translations\\data.table\\vignettes\\es\\po")

# Script para cargar los archivos .txt generados en los po originales
# los txt se generan ocn el script siguiente :
# find *.po -exec sh -c "msggrep -w20000 -Ke '' {} | sed -nE '/^$|(msgid)/p' | sed -E 's/^msgid \\\"(.*)\\\"/\\1/' > {}.txt" ;
# al estar línea por línea soin más faciles de traducir masivamente 
# (aunque puede tener algún prolema con los escapees tipo \n)

po_files  <- dir(pattern="po$")
po_txt_files <- paste0(po_files, ".txt")
stopifnot(all(file.exists(po_txt_files)))

for (f in split(data.frame(po_files, po_txt_files), po_files)) {
  lines_po <- readLines(f$po_files)
  lines_txt <- readLines(f$po_txt_files)
  lines_txt <- gsub("(?<!\\\\)\"", "\\\\\"", lines_txt, perl = T)
  msgstr_pos <- grep("msgstr \"\"", lines_po)[-1]
  stopifnot(length(msgstr_pos) == length(lines_txt))
  lines_po[msgstr_pos] <- paste0("msgstr \"", lines_txt, "\"")
  writeLines(lines_po, paste0(f$po_files, ""))
}  

#!/bin/bash
system("sh -c \"find -name '*.po' -exec msggrep -o '{}' -Ke '' '{}' \\\\;\"")

