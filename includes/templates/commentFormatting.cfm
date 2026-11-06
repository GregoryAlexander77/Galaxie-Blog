<!--- The comment editor (5.03, owner 11-02: "a tinymce editor with limited functions, but markdown would be accepted if the user
types it in"). A small TinyMCE editor takes the place of the comment box: bold, italic, code, links, code samples, lists and quotes,
and typed Markdown (**bold**, *italic*, `code`, - lists, > quotes) turns into formatting as it is typed.

What is sent is still plain text. On every change the editor's content is turned back into Markdown and put in the comment box
(#comments, now hidden), which the form sends as before. The server keeps encoding every comment and formats it itself
(Udf.cfc formatComment), so the server never takes HTML from a visitor: HTML sent past the editor is shown as text. This is what the
old TinyMCE comment plugin, removed as insecure, didn't do.

If TinyMCE can't be loaded, the plain comment box stays, and Markdown typed in it still works. --->
<cfsilent>
<cfif not isDefined("kendoTheme") or not isDefined("darkTheme")>
	<cfset commentTheme = application.blog.getTheme(themeAlias = trim(application.blog.getSelectedThemeAlias()))>
	<cfset kendoTheme = commentTheme[1]["KendoTheme"]>
	<cfset darkTheme = commentTheme[1]["DarkTheme"]>
</cfif>
<!--- The editor's skin has the Kendo theme's name (as in the post editor); a theme without one gets TinyMCE's own. --->
<cfset commentEditorSkin = lCase(trim(kendoTheme))>
<cfif not reFind("^[a-z0-9_-]+$", commentEditorSkin) or not fileExists(expandPath(application.baseUrl & "/common/libs/tinymce/skins/ui/" & commentEditorSkin & "/skin.min.css"))>
	<cfset commentEditorSkin = darkTheme ? "oxide-dark" : "oxide">
</cfif>
</cfsilent>
<script>
(function () {
	var box = document.getElementById('comments');
	if (!box || !window.galaxieLoader || !galaxieLoader.tinymce) { return; }
	var BASE = '<cfoutput>#application.baseUrl#</cfoutput>';
	var holder = $('<textarea id="galaxieCommentEditor"></textarea>').insertAfter(box);

	<!--- The editor's content as Markdown, in the shape formatComment reads: paragraphs split by a blank line, line breaks kept,
	- and 1. lists, > quotes, ``` code blocks with their language, `code`, **bold**, *italic* and [text](link). --->
	function plain(s) { return String(s || '').replace(/ /g, ' '); }
	function wrap(s, mark) {
		var m = s.match(/^(\s*)([\s\S]*?)(\s*)$/);
		return m[2] ? m[1] + mark + m[2] + mark + m[3] : s;
	}
	function inline(node) {
		var out = '';
		$.each(node.childNodes, function (i, n) {
			if (n.nodeType === 3) { out += plain(n.nodeValue); return; }
			if (n.nodeType !== 1) { return; }
			var tag = n.nodeName;
			if (tag === 'BR') { out += '\n'; return; }
			if (tag === 'CODE') { var c = plain(n.textContent).replace(/`/g, "'"); if (c) { out += '`' + c + '`'; } return; }
			if (tag === 'A') {
				var href = n.getAttribute('href') || '';
				var label = $.trim(plain(n.textContent)).replace(/[\[\]]/g, '');
				if (/^https?:\/\//i.test(href)) {
					href = href.replace(/\s/g, '%20').replace(/\)/g, '%29');
					out += (!label || label === href) ? href : '[' + label + '](' + href + ')';
				} else {
					out += label;
				}
				return;
			}
			var inner = inline(n);
			if (tag === 'STRONG' || tag === 'B') { out += wrap(inner, '**'); }
			else if (tag === 'EM' || tag === 'I') { out += wrap(inner, '*'); }
			else { out += inner; }
		});
		return out;
	}
	function toMarkdown(root) {
		var blocks = [];
		function walk(parent, quote) {
			$.each(parent.childNodes, function (i, n) {
				var tag = n.nodeName, t;
				if (n.nodeType === 3) { if ($.trim(n.nodeValue)) { blocks.push({ quote: quote, text: plain(n.nodeValue) }); } return; }
				if (n.nodeType !== 1) { return; }
				if (tag === 'PRE') {
					var lang = ((n.className || '').match(/language-([a-z0-9+-]+)/) || [])[1] || '';
					blocks.push({ quote: quote, code: true, text: '```' + lang + '\n' + plain(n.textContent).replace(/\n$/, '') + '\n```' });
					return;
				}
				if (tag === 'UL' || tag === 'OL') {
					var lines = [];
					$(n).children('li').each(function (k) { t = $.trim(inline(this).replace(/\n+/g, ' ')); if (t) { lines.push((tag === 'OL' ? (k + 1) + '. ' : '- ') + t); } });
					if (lines.length) { blocks.push({ quote: quote, text: lines.join('\n') }); }
					return;
				}
				if (tag === 'BLOCKQUOTE') { walk(n, true); return; }
				t = inline(tag === 'P' || tag === 'DIV' ? n : { childNodes: [n] }).replace(/^\n+|\n+$/g, '');
				if ($.trim(t)) { blocks.push({ quote: quote, text: t }); }
			});
		}
		walk(root, false);
		<!--- ``` typed by hand: each line is its own paragraph in the editor, so the lines up to the closing ``` are put back together. --->
		var merged = [];
		for (var i = 0; i < blocks.length; i++) {
			var b = blocks[i];
			if (!b.code && /^\s*```/.test(b.text) && !/\n\s*```\s*$/.test(b.text)) {
				var j = i + 1;
				while (j < blocks.length && !blocks[j].code) {
					b = { quote: b.quote, text: b.text + '\n' + blocks[j].text };
					j++;
					if (/^\s*```\s*$/.test(blocks[j - 1].text.split('\n').pop())) { break; }
				}
				if (/\n\s*```\s*$/.test(b.text)) { merged.push(b); i = j - 1; continue; }
			}
			merged.push(blocks[i]);
		}
		var out = '';
		$.each(merged, function (k, b) {
			var text = b.quote ? $.map(b.text.split('\n'), function (l) { return '> ' + l; }).join('\n') : b.text;
			out += (k ? (b.quote && merged[k - 1].quote ? '\n' : '\n\n') : '') + text;
		});
		return $.trim(out);
	}

	galaxieLoader.prism(function () {
		galaxieLoader.tinymce(function () {
			<!--- The window is made again each time it opens; the editor from the last time is gone with it. --->
			var old = tinymce.get('galaxieCommentEditor');
			if (old) { old.remove(); }
			tinymce.init({
				target: holder[0],
				base_url: BASE + '/common/libs/tinymce',
				suffix: '.min',
				skin_url: BASE + '/common/libs/tinymce/skins/ui/<cfoutput>#commentEditorSkin#</cfoutput>',
				content_css: [BASE + '/common/libs/tinymce/skins/content/<cfoutput>#darkTheme ? "dark" : "default"#</cfoutput>/content.min.css',
					BASE + '/common/libs/prism/themes/<cfoutput>#darkTheme ? "prismOkaidia" : "prismCoy"#</cfoutput>.css'],
				content_style: 'body { font-family: Arial, "Lucida Grande", "DejaVu Sans", Verdana, sans-serif; font-size: 15px; margin: 8px 10px; } pre { white-space: pre-wrap; }',
				menubar: false,
				statusbar: false,
				branding: false,
				height: Math.max($(box).outerHeight() || 0, 220),
				width: box.style.width || '100%',
				plugins: 'lists link autolink codesample textpattern paste',
				toolbar: 'bold italic inlinecode | link | codesample | bullist numlist blockquote',
				toolbar_mode: 'wrap',
				<!--- Only what the comment can show; pasted text comes in as plain text. --->
				valid_elements: 'p,br,strong/b,em/i,a[href],ul,ol,li,pre[class],code,blockquote',
				paste_as_text: true,
				link_title: false,
				target_list: false,
				link_assume_external_targets: 'https',
				<!--- Code samples are highlighted with the page's own Prism, which knows these languages; formatComment knows the same ones. --->
				codesample_global_prismjs: true,
				codesample_languages: [
					{ text: 'HTML, XML or CFML tags', value: 'markup' },
					{ text: 'CFScript', value: 'cfscript' },
					{ text: 'JavaScript', value: 'javascript' },
					{ text: 'CSS', value: 'css' },
					{ text: 'SQL', value: 'sql' },
					{ text: 'JSON', value: 'json' },
					{ text: 'Java', value: 'java' },
					{ text: 'C\x23', value: 'csharp' },<!--- \x23 is #, which ColdFusion would read inside cfoutput --->

					{ text: 'PHP', value: 'php' },
					{ text: 'Python', value: 'python' },
					{ text: 'Bash (Linux, macOS)', value: 'bash' },
					{ text: 'PowerShell (Windows)', value: 'powershell' }
				],
				textpattern_patterns: [
					{ start: '**', end: '**', format: 'bold' },
					{ start: '*', end: '*', format: 'italic' },
					{ start: '`', end: '`', format: 'code' },
					{ start: '- ', cmd: 'InsertUnorderedList' },
					{ start: '* ', cmd: 'InsertUnorderedList' },
					{ start: '1. ', cmd: 'InsertOrderedList' },
					{ start: '> ', format: 'blockquote' }
				],
				setup: function (editor) {
					editor.ui.registry.addToggleButton('inlinecode', {
						icon: 'sourcecode',
						tooltip: 'Code (a few words)',
						onAction: function () { editor.execCommand('mceToggleFormat', false, 'code'); },
						onSetup: function (api) {
							var mark = function () { api.setActive(editor.formatter.match('code')); };
							editor.on('NodeChange', mark);
							return function () { editor.off('NodeChange', mark); };
						}
					});
					var sync = function () { box.value = toMarkdown(editor.getBody()); };
					editor.on('input change keyup ExecCommand SetContent Undo Redo NodeChange', sync);
					editor.on('init', function () {
						if (box.value) { editor.setContent($('<div/>').text(box.value).html().replace(/\n/g, '<br>')); }
						$(box).hide();
					});
				}
			});
		});
	});
})();
</script>
