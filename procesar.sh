touch catalog.po
touch es.po R-es.po
touch es.po.orig R-es.po.orig
touch es.po.fuzzy R-es.po.fuzzy
touch es.po.untranslated R-es.po.untranslated 
	
# es.po.fuzzy es generado vía: msgattrib -o es.po.fuzzy --only-fuzzy es.po
# El usuario *debe editar el archivo y eliminar la marca "fuzzy"* donde corresponda.
# Los que no fueron editados y sacados de fuzzy NO SE AGREGAN AL CATALOGO 

msgattrib -o es.po.fuzzy --force-po --no-fuzzy es.po.fuzzy
msgattrib -o R-es.po.fuzzy --force-po --no-fuzzy R-es.po.fuzzy

# borrar comentarios al principio de .fuzzy
sed -i -n -e '/^[^#]/,$p' es.po.fuzzy
sed -i -n -e '/^[^#]/,$p' R-es.po.fuzzy

msgcat -o catalog.po --use-first es.po.fuzzy es.po.untranslated es.po.orig catalog.po
msgcat -o catalog.po --use-first R-es.po.fuzzy R-es.po.untranslated R-es.po.orig catalog.po

msgcat -o es.po --use-first es.po.fuzzy es.po.untranslated es.po
msgcat -o R-es.po --use-first R-es.po.fuzzy R-es.po.untranslated R-es.po

msgmerge -U --backup=off -C catalog.po es.po data.table.pot
msgmerge -U --backup=off -C catalog.po R-es.po R-data.table.pot

sed -i -e "s/^\"PO-Revision-Date: .*/\"PO-Revision-Date: $(date '+%Y-%m-%d %H:%M%z')\"/" es.po
sed -i -e "s/^\"PO-Revision-Date: .*/\"PO-Revision-Date: $(date '+%Y-%m-%d %H:%M%z')\"/" R-es.po

msgattrib -o es.po.untranslated --force-po --untranslated es.po
msgattrib -o es.po.fuzzy --force-po --only-fuzzy es.po

msgattrib -o R-es.po.untranslated --force-po --untranslated R-es.po
msgattrib -o R-es.po.fuzzy --force-po --only-fuzzy R-es.po

sed -i -e "
   1i # ========================================================================
   1i # Nota: Luego de editar las lineas que considere, elimine la marca 'fuzzy'
   1i # teniendo cuidado de preservar las otras marcas (ej c-format) y la coma
   1i # luego de la almohadilla (#,). Las entradas 'fuzzy' no se incorporan 
   1i # a catalog.po ni al archivo traducido.
   1i # ========================================================================
" es.po.fuzzy

sed -i -e "
   1i # ========================================================================
   1i # Nota: Luego de editar las lineas que considere, elimine la marca 'fuzzy'
   1i # teniendo cuidado de preservar las otras marcas (ej c-format) y la coma
   1i # luego de la almohadilla (#,). Las entradas 'fuzzy' no se incorporan 
   1i # a catalog.po ni al archivo traducido.
   1i # ========================================================================
"   R-es.po.fuzzy

echo es.po.untranslated: 
msgfmt -o /dev/null --statistics es.po.untranslated
echo R-es.po.untranslated: 
msgfmt -o /dev/null --statistics R-es.po.untranslated
echo es.po.fuzzy: 
msgfmt -o /dev/null --statistics es.po.fuzzy
echo R-es.po.fuzzy:
msgfmt -o /dev/null --statistics R-es.po.fuzzy
