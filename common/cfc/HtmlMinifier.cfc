component displayname="HtmlMinifier" hint="Removes comments and unneeded whitespace from the html of a page before it is sent to the browser. This is the same code on ColdFusion and Lucee (it only uses java regular expressions), and it is only used when the 'Minimize Code' blog option is checked." {

	// What this does and does not do:
	// - pre and textarea blocks are never changed. Script blocks that are not JavaScript (ie json-ld or a template) are never changed.
	// - In JavaScript blocks: whole-line double slash comments and standalone block comments are removed, and the indentation and blank lines are removed. Comments at the end of a line of code are not touched.
	// - In style blocks: block comments are removed, and the indentation and blank lines are removed.
	// - In the html: html comments (except conditional comments) are removed, and the indentation and blank lines are removed. Spaces between words are not touched.
	// - This is not a JavaScript parser. To be safe, a script block is left alone when it has a template literal (backtick), a line that ends with a backslash.
	//   When the opening and closing marks of the block comments do not match up in a block, only the double slash comments and whitespace are removed. If anything goes wrong the original html is returned.
	// - The comments in the templates should be ColdFusion comments, which are never sent to the browser. This catches the ones that are not.

	public HtmlMinifier function init() {
		var Pattern = createObject("java", "java.util.regex.Pattern");
		// The blocks that are protected while the html is minified. Note: the backreference \1 makes sure that the block is closed by the same tag.
		variables.blockPattern = Pattern.compile("(?is)<(pre|textarea|script|style)\b[^>]*>.*?</\1\s*>");
		variables.scriptPattern = Pattern.compile("(?is)^(<script\b[^>]*>)(.*?)(</script\s*>)$");
		variables.stylePattern = Pattern.compile("(?is)^(<style\b[^>]*>)(.*?)(</style\s*>)$");
		// The marker is a control character, then the number of the block, then another control character.
		variables.markerPattern = Pattern.compile(chr(1) & "(\d+)" & chr(2));
		return this;
	}

	public string function minify(required string html) {
		try {
			var keep = [];
			var out = createObject("java", "java.lang.StringBuilder").init();
			var m = variables.blockPattern.matcher(arguments.html);
			var last = 0;
			var block = "";
			var tag = "";
			// Replace the blocks with a marker, minify them separately and put them back at the end
			while (m.find()) {
				out.append(arguments.html.substring(last, m.start()));
				block = m.group();
				tag = lCase(m.group(1));
				if (tag == "script") {
					block = minifyScript(block);
				} else if (tag == "style") {
					block = minifyStyle(block);
				}
				arrayAppend(keep, block);
				out.append(chr(1) & arrayLen(keep) & chr(2));
				last = m.end();
			}
			out.append(arguments.html.substring(last));
			var s = out.toString();
			// html comments, except the conditional comments.
			s = s.replaceAll("(?s)<!--(?!\[if|<!\[endif).*?-->", "");
			s = trimLines(s);
			// Put the blocks back
			var rm = variables.markerPattern.matcher(s);
			var result = createObject("java", "java.lang.StringBuilder").init();
			last = 0;
			while (rm.find()) {
				result.append(s.substring(last, rm.start()));
				result.append(keep[int(rm.group(1))]);
				last = rm.end();
			}
			result.append(s.substring(last));
			return result.toString();
		} catch (any e) {
			// Never break a page because of this. Send the original html.
			return arguments.html;
		}
	}

	private string function minifyScript(required string block) {
		var m = variables.scriptPattern.matcher(arguments.block);
		if (!m.find()) return arguments.block;
		var openTag = m.group(1);
		var body = m.group(2);
		var closeTag = m.group(3);
		// Only JavaScript. An external script has no body. The type may also be a variable that was already evaluated (ie deferjs).
		if (reFindNoCase("\bsrc\s*=", openTag) || !len(trim(body))) return arguments.block;
		if (reFindNoCase("\btype\s*=\s*[""']?(?!text/javascript|application/javascript|module|deferjs)[^""'\s>]", openTag)) return arguments.block;
		// Leave the script alone if it has a template literal or a line that continues with a backslash, whitespace may be significant.
		if (find("`", body) || reFind("\\[ \t]*\r?\n", body)) return arguments.block;
		body = body.replaceAll("(?m)^[ \t]*//(?![^\r\n]*(?:/\*|\*/))[^\r\n]*(?:\r?\n|\z)", "");
		if (blockCommentsAreBalanced(body)) {
			// A comment that is on its own lines, not a comment that is followed by code.
			body = body.replaceAll("(?m)^[ \t]*/\*(?!!)[^*]*\*+(?:[^/*][^*]*\*+)*/[ \t]*(?:\r?\n|\z)", "");
		}
		return openTag & trimLines(body) & closeTag;
	}

	private string function minifyStyle(required string block) {
		var m = variables.stylePattern.matcher(arguments.block);
		if (!m.find()) return arguments.block;
		var openTag = m.group(1);
		var body = m.group(2);
		var closeTag = m.group(3);
		if (!len(trim(body)) || reFindNoCase("\btype\s*=\s*[""']?(?!text/css)[^""'\s>]", openTag)) return arguments.block;
		if (blockCommentsAreBalanced(body)) {
			body = body.replaceAll("/\*(?!!)[^*]*\*+(?:[^/*][^*]*\*+)*/", "");
		}
		// A line break can not be inside of a CSS string, so every run of white space that has a line break can be one space.
		body = body.replaceAll("\s*\r?\n\s*", " ");
		return openTag & trim(body) & closeTag;
	}

	// The number of /* and */ must match. Otherwise a comment may be open (ie a /* at the end of a line of code) and what looks like a standalone comment can be the end of it.
	private boolean function blockCommentsAreBalanced(required string code) {
		var opens = len(arguments.code) - len(replace(arguments.code, "/*", "", "all"));
		var closes = len(arguments.code) - len(replace(arguments.code, "*/", "", "all"));
		return opens == closes;
	}

	// Removes the indentation, the trailing spaces and the blank lines
	private string function trimLines(required string code) {
		var s = arguments.code;
		s = s.replaceAll("(?m)^[ \t]+", "");
		s = s.replaceAll("(?m)[ \t]+$", "");
		s = s.replaceAll("(\r?\n)([ \t]*\r?\n)+", "$1");
		return s;
	}

}
