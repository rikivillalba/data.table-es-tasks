# R
# Ejecutar con: Rscript extrae_lineas_msgid.R
files <- if (length(commandArgs(trailingOnly  = TRUE)) > 1) 
  commandArgs()[-1] else dir(,"[.]po$")
message(sprintf("Extraer data de %d archivos...", length(files)))
for (i in files) {
  lines <- readLines(i) |> grep(pattern = "^\\s*(\"|msg)", value= TRUE)
  pos_msg <- grep("^\\s*msg", lines)
  pos_msgid <- grep("^\\s*msgid", lines)
  pos_msgid_end <- pos_msg[match(pos_msgid, pos_msg, length(lines)) + 1] - 1
  sapply(seq_along(pos_msgid), function(i) paste0(collapse = "", sub(
    "[^\"]*\"(.*)\"[^\"]*$", "\\1", lines[pos_msgid[i]:pos_msgid_end[i]]))) |>
    writeLines(paste0(i,".txt"))
}
message("Listo")
