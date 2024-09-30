# R
# Ejecutar con: Rscript extrae_lineas_msgid.R
files <- if (length(commandArgs(trailingOnly  = TRUE)) > 1) 
  commandArgs()[-1] else dir(,"[.]po$")
message(sprintf("Extraer msgid de %d archivos...", length(files)))
for (i in files) {
  lines <- grep(readLines(i), pattern = "^\\s*(\"|msg)", value= TRUE)
  msgs <- grep("^\\s*msg", lines)
  grps <- cut(seq_along(lines), c(msgs, Inf), labels = FALSE, right = FALSE)
  text <- vapply(seq_along(msgs), "", FUN = function(j) 
    paste0(gsub(
      "\\s*(msg(id|id_plural|str)(\\[\\d*\\])?)?\\s*\"(([^\"]|\\\\.)*)\".*", 
      "\\4", lines[grps == j]), collapse = ""))
  writeLines(text[grep("^\\s*msgid", lines[msgs])], paste0(i, ".txt"))
}
message("Listo")
