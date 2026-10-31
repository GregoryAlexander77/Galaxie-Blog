/**
 * Excel export for the admin grids (5.0.x, 2026-10-31, owner: "grid Excel exports", the Error Log first).
 *
 * Writes a real .xlsx file (Office Open XML) from rows of data, with plain Java zip classes, so it works the same on Adobe
 * ColdFusion and Lucee and needs neither cfspreadsheet nor Lucee's Spreadsheet extension, nor Kendo Professional: the free
 * jsGrid grids get the same export as the Kendo ones. One sheet; a bold header row that stays in place while scrolling, with
 * Excel's filter buttons on it; dates as real Excel dates; numbers as numbers; everything else as text.
 *
 * Usage (ProxyController exportErrorLog):
 *   var columns = [ { field: "ErrorLogId", title: "Error Id", type: "number", width: 10 }, { field: "Date", title: "Date", type: "date" }, ... ];
 *   var xlsx = new ExcelExport().build(rows, columns, "Error Log");
 *   new ExcelExport().send(xlsx, "error-log.xlsx");
 * rows is an array of structs (an HQL "new Map" result) or a query. A column's type is "text" (the default), "number",
 * "date", "boolean" (shown as Yes / No) or "html" (text with its tags taken out, such as a comment); width is in Excel's
 * character units (a guess from the title when left out).
 */
component output="false" {

	// Excel keeps at most 32,767 characters in a cell; longer text (a long error detail) is cut there.
	variables.MAX_CELL = 32000;

	public binary function build(required any rows, required array columns, string sheetName = "Sheet1") {
		var data = isQuery(arguments.rows) ? queryToArray(arguments.rows) : arguments.rows;
		var parts = [:];
		parts["[Content_Types].xml"] = '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>'
			& '<Types xmlns="http://schemas.openxmlformats.org/package/2006/content-types">'
			& '<Default Extension="rels" ContentType="application/vnd.openxmlformats-package.relationships+xml"/>'
			& '<Default Extension="xml" ContentType="application/xml"/>'
			& '<Override PartName="/xl/workbook.xml" ContentType="application/vnd.openxmlformats-officedocument.spreadsheetml.sheet.main+xml"/>'
			& '<Override PartName="/xl/worksheets/sheet1.xml" ContentType="application/vnd.openxmlformats-officedocument.spreadsheetml.worksheet+xml"/>'
			& '<Override PartName="/xl/styles.xml" ContentType="application/vnd.openxmlformats-officedocument.spreadsheetml.styles+xml"/>'
			& '</Types>';
		parts["_rels/.rels"] = '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>'
			& '<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">'
			& '<Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/officeDocument" Target="xl/workbook.xml"/>'
			& '</Relationships>';
		parts["xl/workbook.xml"] = '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>'
			& '<workbook xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main" xmlns:r="http://schemas.openxmlformats.org/officeDocument/2006/relationships">'
			& '<sheets><sheet name="' & xml(sheetTitle(arguments.sheetName)) & '" sheetId="1" r:id="rId1"/></sheets>'
			& '<definedNames><definedName name="_xlnm._FilterDatabase" localSheetId="0" hidden="1">' & xml("'" & replace(sheetTitle(arguments.sheetName), "'", "''", "all") & "'") & '!$A$1:$' & columnLetter(arrayLen(arguments.columns)) & '$' & (arrayLen(data) + 1) & '</definedName></definedNames>'
			& '</workbook>';
		parts["xl/_rels/workbook.xml.rels"] = '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>'
			& '<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">'
			& '<Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/worksheet" Target="worksheets/sheet1.xml"/>'
			& '<Relationship Id="rId2" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/styles" Target="styles.xml"/>'
			& '</Relationships>';
		// Styles: 0 plain, 1 bold header on a light grey fill, 2 a date and time.
		parts["xl/styles.xml"] = '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>'
			& '<styleSheet xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main">'
			& '<numFmts count="1"><numFmt numFmtId="164" formatCode="yyyy-mm-dd h:mm AM/PM"/></numFmts>'
			& '<fonts count="2"><font><sz val="11"/><name val="Calibri"/></font><font><b/><sz val="11"/><name val="Calibri"/></font></fonts>'
			& '<fills count="3"><fill><patternFill patternType="none"/></fill><fill><patternFill patternType="gray125"/></fill>'
			& '<fill><patternFill patternType="solid"><fgColor rgb="FFE8E8E8"/><bgColor indexed="64"/></patternFill></fill></fills>'
			& '<borders count="1"><border><left/><right/><top/><bottom/><diagonal/></border></borders>'
			& '<cellStyleXfs count="1"><xf numFmtId="0" fontId="0" fillId="0" borderId="0"/></cellStyleXfs>'
			& '<cellXfs count="3"><xf numFmtId="0" fontId="0" fillId="0" borderId="0" xfId="0"/>'
			& '<xf numFmtId="0" fontId="1" fillId="2" borderId="0" xfId="0" applyFont="1" applyFill="1"/>'
			& '<xf numFmtId="164" fontId="0" fillId="0" borderId="0" xfId="0" applyNumberFormat="1"/></cellXfs>'
			& '</styleSheet>';
		parts["xl/worksheets/sheet1.xml"] = sheetXml(data, arguments.columns);
		return zip(parts);
	}

	// Sends the file to the browser as a download and ends the request.
	public void function send(required binary xlsx, required string fileName) {
		var name = reReplace(arguments.fileName, "[^A-Za-z0-9._-]", "-", "all");
		cfheader(name = "Content-Disposition", value = 'attachment; filename="' & name & '"');
		cfheader(name = "Cache-Control", value = "no-store");
		cfcontent(type = "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet", variable = arguments.xlsx, reset = true);
	}

	/* ---------- the sheet ---------- */

	private string function sheetXml(required array data, required array columns) {
		var sb = createObject("java", "java.lang.StringBuilder").init();
		var lastColumn = columnLetter(arrayLen(arguments.columns));
		var c = 0;
		var r = 0;
		sb.append('<?xml version="1.0" encoding="UTF-8" standalone="yes"?>');
		sb.append('<worksheet xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main" xmlns:r="http://schemas.openxmlformats.org/officeDocument/2006/relationships">');
		sb.append('<dimension ref="A1:' & lastColumn & (arrayLen(arguments.data) + 1) & '"/>');
		// The header row stays in place while scrolling.
		sb.append('<sheetViews><sheetView workbookViewId="0"><pane ySplit="1" topLeftCell="A2" activePane="bottomLeft" state="frozen"/></sheetView></sheetViews>');
		sb.append('<cols>');
		for (c = 1; c <= arrayLen(arguments.columns); c++) {
			sb.append('<col min="' & c & '" max="' & c & '" width="' & columnWidth(arguments.columns[c]) & '" customWidth="1"/>');
		}
		sb.append('</cols><sheetData>');
		sb.append('<row r="1">');
		for (c = 1; c <= arrayLen(arguments.columns); c++) {
			sb.append(textCell(columnLetter(c) & "1", arguments.columns[c].title ?: arguments.columns[c].field, 1));
		}
		sb.append('</row>');
		for (r = 1; r <= arrayLen(arguments.data); r++) {
			var rowNumber = r + 1;
			sb.append('<row r="' & rowNumber & '">');
			for (c = 1; c <= arrayLen(arguments.columns); c++) {
				sb.append(cell(columnLetter(c) & rowNumber, valueOf(arguments.data[r], arguments.columns[c].field), arguments.columns[c].type ?: "text"));
			}
			sb.append('</row>');
		}
		sb.append('</sheetData>');
		// Excel's filter buttons on the header row.
		sb.append('<autoFilter ref="A1:' & lastColumn & (arrayLen(arguments.data) + 1) & '"/>');
		sb.append('</worksheet>');
		return sb.toString();
	}

	private string function cell(required string ref, any value, required string type) {
		if (isNull(arguments.value) || (isSimpleValue(arguments.value) && !len(trim(arguments.value)))) { return ""; }
		if (!isSimpleValue(arguments.value)) { return textCell(arguments.ref, serializeJSON(arguments.value)); }
		switch (arguments.type) {
			case "number":
				if (isNumeric(arguments.value)) { return '<c r="' & arguments.ref & '"><v>' & arguments.value & '</v></c>'; }
				break;
			case "date":
				if (isDate(arguments.value)) { return '<c r="' & arguments.ref & '" s="2"><v>' & excelDate(arguments.value) & '</v></c>'; }
				break;
			case "boolean":
				if (isBoolean(arguments.value)) { return textCell(arguments.ref, arguments.value ? "Yes" : "No"); }
				break;
			case "html":
				return textCell(arguments.ref, plainText(arguments.value));
		}
		return textCell(arguments.ref, arguments.value);
	}

	private string function textCell(required string ref, required string value, numeric style = 0) {
		return '<c r="' & arguments.ref & '" t="inlineStr"' & (arguments.style ? ' s="' & arguments.style & '"' : '') & '><is><t xml:space="preserve">' & xml(left(arguments.value, variables.MAX_CELL)) & '</t></is></c>';
	}

	/* ---------- helpers ---------- */

	// HTML as plain text: line breaks and paragraphs become new lines, the other tags go, and the common entities are decoded.
	private string function plainText(required string html) {
		var text = reReplaceNoCase(arguments.html, "<(br|/p|/div|/li)[^>]*>", chr(10), "all");
		text = reReplace(text, "<[^>]*>", "", "all");
		text = replace(text, "&nbsp;", " ", "all");
		text = replace(text, "&lt;", "<", "all");
		text = replace(text, "&gt;", ">", "all");
		text = replace(text, "&quot;", '"', "all");
		text = replace(text, "&##39;", "'", "all");
		text = replace(text, "&apos;", "'", "all");
		// Characters saved as numbers, as the blog saves comments (encodeForHTML): &#x21; and &#33; are both "!".
		text = decodeNumbered(text, "&##x([0-9a-fA-F]{1,6});", 16);
		text = decodeNumbered(text, "&##([0-9]{1,7});", 10);
		text = replace(text, "&amp;", "&", "all");
		// No more than one empty line in a row.
		return trim(reReplace(text, "(" & chr(10) & "\s*){3,}", chr(10) & chr(10), "all"));
	}

	private string function decodeNumbered(required string text, required string pattern, required numeric radix) {
		var result = arguments.text;
		var found = reFind(arguments.pattern, result, 1, true);
		var guard = 0;
		while (found.pos[1] && guard < 100000) {
			var code = inputBaseN(mid(result, found.pos[2], found.len[2]), arguments.radix);
			var character = (code > 0 && code <= 1114111) ? chr(code) : "";
			result = left(result, found.pos[1] - 1) & character & mid(result, found.pos[1] + found.len[1], len(result));
			found = reFind(arguments.pattern, result, found.pos[1] + len(character), true);
			guard++;
		}
		return result;
	}

	// A row's value for a field: struct keys and HQL map keys, either case.
	private any function valueOf(required any row, required string field) {
		if (structKeyExists(arguments.row, arguments.field)) { return arguments.row[arguments.field]; }
		return javacast("null", "");
	}

	// Excel counts days from 1899-12-30, with the time as a fraction of a day.
	private string function excelDate(required date value) {
		var d = arguments.value;
		var days = dateDiff("d", createDate(1899, 12, 30), createDate(year(d), month(d), day(d)));
		var fraction = (hour(d) * 3600 + minute(d) * 60 + second(d)) / 86400;
		return numberFormat(days + fraction, "0.00000000");
	}

	// 1 is A, 26 is Z, 27 is AA.
	private string function columnLetter(required numeric n) {
		var letters = "";
		var i = arguments.n;
		while (i > 0) {
			var m = (i - 1) mod 26;
			letters = chr(65 + m) & letters;
			i = int((i - 1) / 26);
		}
		return letters;
	}

	private numeric function columnWidth(required struct column) {
		if (isNumeric(arguments.column.width ?: "")) { return arguments.column.width; }
		if ((arguments.column.type ?: "") eq "date") { return 20; }
		if ((arguments.column.type ?: "") eq "number" || (arguments.column.type ?: "") eq "boolean") { return max(8, len(arguments.column.title ?: "") + 4); }
		return max(14, len(arguments.column.title ?: "") + 4);
	}

	// Sheet names: at most 31 characters, none of : \ / ? * [ ]
	private string function sheetTitle(required string name) {
		var title = trim(reReplace(arguments.name, "[:\\/?*\[\]]", " ", "all"));
		return len(title) ? left(title, 31) : "Sheet1";
	}

	// Text made safe for XML: the five special characters escaped and the control characters XML does not allow removed.
	private string function xml(required string value) {
		var text = reReplace(arguments.value, "[\x00-\x08\x0B\x0C\x0E-\x1F]", "", "all");
		text = replace(text, "&", "&amp;", "all");
		text = replace(text, "<", "&lt;", "all");
		text = replace(text, ">", "&gt;", "all");
		text = replace(text, '"', "&quot;", "all");
		return text;
	}

	private array function queryToArray(required query q) {
		var result = [];
		for (var row in arguments.q) { arrayAppend(result, row); }
		return result;
	}

	// The parts zipped in memory into the .xlsx file.
	private binary function zip(required struct parts) {
		var bytesOut = createObject("java", "java.io.ByteArrayOutputStream").init();
		var zipOut = createObject("java", "java.util.zip.ZipOutputStream").init(bytesOut);
		// [Content_Types].xml first, as Office writes it.
		var names = ["[Content_Types].xml", "_rels/.rels", "xl/workbook.xml", "xl/_rels/workbook.xml.rels", "xl/styles.xml", "xl/worksheets/sheet1.xml"];
		for (var name in names) {
			var bytes = charsetDecode(arguments.parts[name], "utf-8");
			zipOut.putNextEntry(createObject("java", "java.util.zip.ZipEntry").init(name));
			zipOut.write(bytes, 0, len(bytes));
			zipOut.closeEntry();
		}
		zipOut.close();
		return bytesOut.toByteArray();
	}
}
