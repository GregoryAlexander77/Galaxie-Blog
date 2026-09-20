#!/bin/bash
# Builds the Kendo Core bundles that Galaxie Blog loads (in /js) from the individual Kendo Core component files in the same folder:
#   kendo.galaxie.public.min.js  the widgets that the public site uses (visitors)
#   kendo.galaxie.admin.min.js   the public widgets plus the widgets that the administrative site uses
# kendo.ui.core.min.js has every Kendo Core widget (about 900 KB), including the mobile widgets. It is still used by the installer and by a post that needs a widget that is not in the bundles, see postNeedsFullKendoCore() in blog.cfc and includes/templates/head.cfm.
# The components are added in the order of the modules in kendo.ui.core.min.js, which makes sure that a module always comes after the modules that it needs.
# To add a widget, add its component name to the list below, plus the components that it needs (see the define([...]) at the top of the component file), and run this again. Then add the widget to the list in postNeedsFullKendoCore() in blog.cfc.
cd "$(dirname "$0")/js" || exit 1

# Splitter and Menu are needed by every page as kendo.web.ext.js (the extended dialogs) extends the Window, Splitter and Menu widgets when it loads.
PUBLIC="core userevents data.odata data.xml data binder fx validator draganddrop mobile.scroller resizable selectable popup list calendar virtuallist multiselect menu panelbar pager responsivepanel splitter window"
ADMIN="$PUBLIC badge button dateinput datepicker autocomplete dropdownlist combobox color slider colorpicker numerictextbox floatinglabel timepicker datetimepicker"

ORDER=$(grep -o 'define("kendo\.[a-z.0-9]*\.min"' kendo.ui.core.min.js | sed 's/define("kendo\.//;s/\.min"//' | grep -v '^ui\.core$' | tr '\n' ' ')

build() { # $1 = output file, $2 = list of components
	printf '/** Kendo UI Core custom bundle for Galaxie Blog (see build-galaxie-bundle.sh). Copyright Progress Software Corporation, licensed under the Apache License 2.0 (http://www.apache.org/licenses/LICENSE-2.0). */\n' > "$1"
	for c in $ORDER; do
		case " $2 " in *" $c "*) ;; *) continue;; esac
		f=kendo.$c.min.js
		[ -f "$f" ] || { echo "Missing $f"; exit 1; }
		# Remove the license banner at the top and the source map comment at the bottom of each component.
		perl -0pe 's/\A\xEF\xBB\xBF//; s/\A\/\*\*.*?\*\/\s*//s; s/\/\/# sourceMappingURL=[^\r\n]*\s*\z//' "$f" >> "$1"
		printf '\n' >> "$1"
	done
	# Every component in the list must have been added.
	for c in $2; do case " $ORDER " in *" $c "*) ;; *) echo "$c is not a module of kendo.ui.core.min.js"; exit 1;; esac; done
	ls -l "$1"
}

rm -f kendo.galaxie.min.js
build kendo.galaxie.public.min.js "$PUBLIC"
build kendo.galaxie.admin.min.js "$ADMIN"
