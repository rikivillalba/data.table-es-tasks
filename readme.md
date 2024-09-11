# Workflow para actualización directa de catálogos .po
(para el proyecto data.table)

## Requerimientos: 
* GNU gettext
* En windows: RTools: https://cran.r-project.org/bin/windows/Rtools/
se puede usar un símbolo del sistema MSYS2 en la terminal nueva de 
Windows (wt.exe) o en el emulador que viene con msys.
Si no está instalado, hay que instalar gettext: `pacman -S gettext`.

## Workflow
1. Ejecutar ./descargar.sh para obtener ultimos .pot y los .po actuales de 
github.
    * "data.table.pot" y "R-data.table.pot"
    * "es.po" y "R-es.po" se guardan con el sufijo .orig
2. Ejecutar el script `./procesar.sh`.
    * los archivos "es.po" y "R-es.po" son generados con la información en 
	los .orig descargados y el catálogo local, "catalog.po". 
	* Si el catálogo "catalog.po" no existe es generado y actualizado con los 
	po descargados.
	* Si hay nuevas traducciones en los archivos .fuzzy y .untransalted, se 
	agregan al catálogo (si no son 'fuzzy').
	* los archivos ".fuzzy" y ".untranslated" son generados.
3. Actualizar los archivos .fuzzy y .untranslated: estos tienen los casos
encontrados en es.pot R-es.pot que no están en el catálogo y figuran en las 
plantillas .pot descargadas. 
    * Los archivos .fuzzy contienen coincidencias aproximadas, generalmente por
	cambios menores en la plantilla, y la traducción original. Al editarlos, no
	olvide borrar la marca 'fuzzy', dejando la almohadilla seguida de coma (#,) 
	si hay otras marcas. **Las entradas 'fuzzy' no se consideran en las 
	traducciones**.
	* los archivos .untranslated contienen los casos nuevos en la plantilla, no
	hay traducciones ni en el catálogo 
4. Volver al punto 2 hasta que .fuzzy y .untranslated están vacíos, si están
vacíos... ¡enhorabuena! el trabajo está finalizado.
  
## Referencia Herramientas gettext utilizadas
### msgmerge 
> msgmerge [option] def.po ref.pot

Usado para adaptar un catálogo a una plantilla, agrega los elementos que están
en la plantilla y no en el .po, y elimina con comentario #~ los que no están 
en la plantilla. También marca como "fuzzy" las traducciones que tienen cambios
menores, para su corrección.

> msgattrib [option] [inputfile]

Usado para filtrar, a partir del resultado de msgmerge, los elementos sin 
traducción o marcados como "fuzzy". 

> msgcat [option] [inputfile]...

Usando la opción --use-first, combina las traducciones de los archivos creados
filtrando mediante msgattrib (los cuales se editan a mano) con las traducciones
ya existentes en es.po y R-es.po.
