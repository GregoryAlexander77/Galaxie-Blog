/*
	Galaxie Blog code editor for TinyMCE (2026-11-07, owner: "put an advanced code editor back into the editor without the security issues").

	It replaces what the Source code button (and View, Source code) opens: instead of TinyMCE's plain text box, the post's HTML in
	CodeMirror, with colors, line numbers, matching tags, closing tags typed for you, and find and replace (Ctrl+F, Ctrl+Shift+F / Ctrl+H).

	Why this one is safe where the old third-party "codemirror" plugin (removed in 4.31) was not:
	- No library of its own. It uses the CodeMirror 5.65.9 that the admin page already loads (includes/templates/head.cfm), and only
	  loads a few of that copy's own add-ons (search, closing tags) on first use.
	- No page of its own. The old plugin opened a standalone source.html page, inside the plugin folder, that anyone could request; this
	  opens in TinyMCE's own dialog, so it only exists in a signed-in admin's editor.
	- The edited HTML goes back the same way TinyMCE's own Source code dialog sends it (editor.setContent in one undo step), so TinyMCE's
	  cleanup still runs, and saving the post is unchanged. CodeMirror shows the HTML as text; nothing in it runs while you edit.

	Loaded by includes/templates/js/tinyMce.cfm (external_plugins) when the editor has the code plugin. If CodeMirror is missing, the
	Source code button opens TinyMCE's own dialog as before.
*/
(function () {
	"use strict";
	if (!window.tinymce) { return; }

	// The page's own CodeMirror folder, from the script the head loaded.
	function libraryBase() {
		var scripts = document.getElementsByTagName("script");
		for (var i = 0; i < scripts.length; i++) {
			var m = (scripts[i].getAttribute("src") || "").match(/^(.*\/codemirror5\/)lib\/codemirror\.js/);
			if (m) { return m[1]; }
		}
		return null;
	}

	// CodeMirror's styles, made to win inside TinyMCE's dialog. TinyMCE's skin resets every element under .tox
	// (".tox :not(svg):not(rect) { position: static; width: auto; background: 0 0; ... }"), which beats CodeMirror's own one-class
	// rules: the line-number gutter then fills the whole width and the code is pushed out of sight. So each CodeMirror stylesheet is
	// added again with ".tox .galaxieCodeHost " in front of every selector (keyframes and @-rules left as they are).
	var scopedCss = {};
	function scopeCss(text) {
		return text.replace(/\/\*[\s\S]*?\*\//g, "").replace(/(^|[{}])(\s*)([^{}@]+)\{/g, function (all, before, space, selectors) {
			if (/^\s*(from|to|\d+(\.\d+)?%)\s*(,|$)/.test(selectors)) { return all; }
			var scoped = selectors.split(",").map(function (s) {
				s = s.trim();
				return s ? ".tox .galaxieCodeHost " + s : s;
			}).join(", ");
			return before + space + scoped + " {";
		});
	}
	function addScopedCss(href) {
		if (scopedCss[href]) { return scopedCss[href]; }
		scopedCss[href] = fetch(href, { credentials: "same-origin" }).then(function (r) { return r.ok ? r.text() : ""; }).then(function (text) {
			if (!text) { return; }
			var style = document.createElement("style");
			style.setAttribute("data-galaxie-code", href);
			style.textContent = scopeCss(text);
			document.head.appendChild(style);
		}).catch(function () {});
		return scopedCss[href];
	}

	// The add-ons the head doesn't load, once per page.
	var addOnsReady = null;
	function loadAddOns() {
		if (addOnsReady) { return addOnsReady; }
		var base = libraryBase();
		addOnsReady = new Promise(function (resolve) {
			if (!base) { resolve(); return; }
			["addon/dialog/dialog.css", "addon/search/matchesonscrollbar.css"].forEach(function (href) { addScopedCss(base + href); });
			var scripts = ["addon/dialog/dialog.js", "addon/search/searchcursor.js", "addon/search/search.js", "addon/scroll/annotatescrollbar.js",
				"addon/search/matchesonscrollbar.js", "addon/search/jump-to-line.js", "addon/edit/closetag.js", "addon/fold/xml-fold.js", "addon/edit/matchtags.js"];
			var next = function () {
				var src = scripts.shift();
				if (!src) { resolve(); return; }
				if (document.querySelector('script[src="' + base + src + '"]')) { next(); return; }
				var s = document.createElement("script"); s.src = base + src;
				s.onload = next; s.onerror = next;
				document.head.appendChild(s);
			};
			next();
		});
		return addOnsReady;
	}

	// A dark admin theme gets a dark editor.
	function isDark(el) {
		var c = window.getComputedStyle(el).backgroundColor.match(/\d+(\.\d+)?/g);
		if (!c || (c.length > 3 && Number(c[3]) === 0)) { return false; }
		return (0.299 * c[0] + 0.587 * c[1] + 0.114 * c[2]) < 110;
	}
	function useDarkTheme() {
		var base = libraryBase();
		return base ? addScopedCss(base + "theme/material-darker.css") : Promise.resolve();
	}

	function open(editor) {
		var html = editor.getContent({ source_view: true });
		var cm = null;
		editor.windowManager.open({
			title: "Source code",
			size: "large",
			body: {
				type: "panel",
				items: [
					{ type: "htmlpanel", html: '<div class="galaxieCodeHost" style="border: 1px solid rgba(128,128,128,.4);"></div>' +
						'<div style="margin-top: 6px; font-size: 13px; opacity: .8;">Find: Ctrl+F &nbsp; Replace: Ctrl+Shift+F &nbsp; Go to a line: Alt+G &nbsp; Indent: Tab / Shift+Tab</div>' }
				]
			},
			buttons: [
				{ type: "cancel", name: "cancel", text: "Cancel" },
				{ type: "submit", name: "save", text: "Save", primary: true }
			],
			onSubmit: function (api) {
				var value = cm ? cm.getValue() : html;
				editor.focus();
				editor.undoManager.transact(function () { editor.setContent(value); });
				editor.selection.setCursorLocation();
				editor.nodeChanged();
				api.close();
			}
		});
		var hosts = document.querySelectorAll(".tox-dialog .galaxieCodeHost");
		var host = hosts[hosts.length - 1];
		if (!host) { return; }
		var dialog = host.closest(".tox-dialog");
		var dark = dialog && isDark(dialog);
		var base = libraryBase();
		// A bigger dialog than TinyMCE's large one (650px tall), and the code filling it: the window's height less the dialog's title,
		// buttons, padding and the keys line under the code.
		var sizeIt = function () {
			if (!cm || !dialog) { return; }
			dialog.style.maxWidth = "1400px";
			dialog.style.height = Math.max(400, Math.min(window.innerHeight - 60, 1100)) + "px";
			var content = dialog.querySelector(".tox-dialog__body-content");
			if (content) { content.style.maxHeight = "none"; }
			var head = dialog.querySelector(".tox-dialog__header"), foot = dialog.querySelector(".tox-dialog__footer"), keys = host.nextElementSibling;
			var room = dialog.clientHeight - (head ? head.offsetHeight : 0) - (foot ? foot.offsetHeight : 0) - 32 - (keys ? keys.offsetHeight + 6 : 0) - 4;
			cm.setSize(null, Math.max(240, room));
		};
		var options = {
			value: html,
			mode: "htmlmixed",
			theme: dark ? "material-darker" : "default",
			lineNumbers: true,
			lineWrapping: true,
			indentUnit: 4,
			indentWithTabs: true,
			tabSize: 4,
			matchTags: { bothTags: true },
			autoCloseTags: true,
			autoCloseBrackets: true,
			extraKeys: {
				"Ctrl-Space": "autocomplete",
				"Ctrl-H": "replace"
			}
		};
		// CodeMirror measures its gutter when it starts, so its styles go in first (they're cached after the first time).
		var closed = false;
		editor.once("CloseWindow", function () { closed = true; window.removeEventListener("resize", sizeIt); });
		Promise.all([base ? addScopedCss(base + "lib/codemirror.css") : null, dark ? useDarkTheme() : null]).then(function () {
			if (closed || !document.body.contains(host)) { return; }
			cm = window.CodeMirror(host, options);
			sizeIt();
			window.addEventListener("resize", sizeIt);
			setTimeout(function () { cm.refresh(); cm.focus(); }, 30);
			// The add-ons switch on as they arrive.
			loadAddOns().then(function () {
				if (!cm) { return; }
				cm.setOption("matchTags", { bothTags: true });
				cm.setOption("autoCloseTags", true);
				// Options an add-on defines only reach editors made after it loaded.
				cm.setOption("search", { bottom: false });
			});
		});
	}

	tinymce.PluginManager.add("galaxiecode", function (editor) {
		// After every plugin has started, so it takes over from the code plugin's own command.
		editor.on("init", function () {
			if (typeof window.CodeMirror !== "function") { return; }
			editor.addCommand("mceCodeEditor", function () { open(editor); });
		});
		return { getMetadata: function () { return { name: "Galaxie code editor", url: "https://www.gregoryalexander.com" }; } };
	});
})();
