269<cfcomponent displayname="Udf" hint="Common functions" name="Udf">
			
	<!---******************************************************************************************************
		Security (note: this looks like it can be removed)
	******************************************************************************************************--->
			
	<cfscript>
		
		/* Moved session scope vars to the top of the page.
		Set a session var to indicate whether the user is an admin user.*/
		function isLoggedIn() {
			return structKeyExists(session,"loggedin") and session.loggedin;
		}

		// ------------------------------------------------------ //
		
		/* Utility functions. Not used at present */
		function titleCase(str) {
			return uCase(left(str,1)) & right(str,len(str)-1);
		}
		
		// ------------------------------------------------------ //

		/** Not used at present
		* Tests passed value to see if it is a valid e-mail address (supports subdomain nesting and new top-level domains).
		* Update by David Kearns to support '
		* SBrown@xacting.com pointing out regex still wasn't accepting ' correctly.
		* More TLDs
		* Version 4 by P Farrel, supports limits on u/h
		* Added mobi
		* v6 more tlds
		*
		* @param str      The string to check. (Required)
		* @return Returns a boolean.
		* @author Jeff Guillaume (SBrown@xacting.comjeff@kazoomis.com)
		* @version 6, July 29, 2008
		* Note this is different from CFLib as it has the "allow +" support
		*/
		function isEmail(str) {
			return (REFindNoCase("^['_a-z0-9-]+(\.['_a-z0-9-]+)*(\+['_a-z0-9-]+)*@[a-z0-9-]+(\.[a-z0-9-]+)*\.(([a-z]{2,3})|(aero|asia|biz|cat|coop|info|museum|name|jobs|post|pro|tel|travel|mobi))$",arguments.str) AND len(listGetAt(arguments.str, 1, "@")) LTE 64 AND
			len(listGetAt(arguments.str, 2, "@")) LTE 255) IS 1;
		}
		
		// ------------------------------------------------------ //

		/**
		 * An 'enhanced' version of ParagraphFormat.
		 * Added replacement of tab with nonbreaking space char, idea by Mark R Andrachek.
		 * Rewrite and multiOS support by Nathan Dintenfas.
		 * 
		 * @param string 	 The string to format. (Required)
		 * @return Returns a string. 
		 * @author Ben Forta (ben@forta.com) 
		 * @version 3, June 26, 2002 
		 */
		function paragraphFormat2(str) {
			//first make Windows style into Unix style
			str = replace(str,chr(13)&chr(10),chr(10),"ALL");
			//now make Macintosh style into Unix style
			str = replace(str,chr(13),chr(10),"ALL");
			//now fix tabs
			str = replace(str,chr(9),"&nbsp;&nbsp;&nbsp;","ALL");
			//now return the text formatted in HTML
			return replace(str,chr(10),"<br />","ALL");
		}
		
		// ------------------------------------------------------ //

		/**
		 * A quick way to test if a string is a URL
		 * 
		 * @param stringToCheck 	 The string to check. 
		 * @return Returns a boolean. 
		 * @author Nathan Dintenfass (nathan@changemedia.com) 
		 * @version 1, November 22, 2001 
		 */
		function isURL(stringToCheck){
				return REFindNoCase("^(((https?:|ftp:|gopher:)\/\/))[-[:alnum:]\?%,\.\/&##!@:=\+~_]+[A-Za-z0-9\/]$",stringToCheck) NEQ 0;
		}
		
		// ------------------------------------------------------ //

		/**
		 * Converts a byte value into kb or mb if over 1,204 bytes.
		 * 
		 * @param bytes 	 The number of bytes. (Required)
		 * @return Returns a string. 
		 * @author John Bartlett (jbartlett@strangejourney.net) 
		 * @version 1, July 31, 2005 
		 */
		function KBytes(bytes) {
			var b=0;

			if(arguments.bytes lt 1024) return trim(numberFormat(arguments.bytes,"9,999")) & " bytes";

			b=arguments.bytes / 1024;

			if (b lt 1024) {
				if(b eq int(b)) return trim(numberFormat(b,"9,999")) & " KB";
				return trim(numberFormat(b,"9,999.9")) & " KB";
			}
			b= b / 1024;
			if (b eq int(b)) return trim(numberFormat(b,"999,999,999")) & " MB";
			return trim(numberFormat(b,"999,999,999.9")) & " MB";
		}
		
		// ------------------------------------------------------ //

		// I take the given date/time object and return the string that
		// represents the date/time using the ISO 8601 format standard.
		// The returned value is always in the context of UTC and therefore
		// uses the special UTC designator ("Z"). The function will
		// implicitly convert your date/time object to UTC (as part of
		// the formatting) unless you explicitly ask it not to.
		string function getIsoTimeString(
			required date datetime,
			boolean convertToUTC = true
			) {
			if ( convertToUTC ) {
				datetime = dateConvert( "local2utc", datetime );
			}
			// When formatting the time, make sure to use "HH" so that the
			// time is formatted using 24-hour time.
			return(
				dateFormat( datetime, "yyyy-mm-dd" ) &
				"T" &
				timeFormat( datetime, "HH:mm:ss" ) &
				"Z"
			);
		}
		// ------------------------------------------------------ //

		// Create a javascript date. Taken from Dan's blog at https://blog.pengoworks.com/index.cfm/2008/5/2/UDF-Convert-ColdFusion-Date-to-JavaScript-Date-Object. Gregory changed some of the formatting. The year and month minus 1 is necessary to handle javascript years and months. Note: javascript months start with a 0 index so we must subtract 1 from the date. 
		function jsDateFormat(date){
			if( isDate(date)){    
				return 'new Date(#year(date)#, #(month(date)-1)#, #day(date)#, #hour(date)#, #minute(date)#, #second(date)#)';
			} else {
				return "null";
			}
		} 
		
		// ------------------------------------------------------ //

		/**
		 * Returns a relative path from the current template to an absolute file path.
		 * 
		 * @param abspath 	 Absolute path. (Required)
		 * @return Returns a string. 
		 * @author Isaac Dealey (info@turnkey.to) 
		 * @version 1, May 2, 2003 
		 */
		function getRelativePath(abspath){ 
			var aHere = listtoarray(expandPath("/"),"\/"); 
			var aThere = ""; var lenThere = 0; 
			var aRel = ArrayNew(1); var x = 0; 
			var newpath = ""; 

			aThere = ListToArray(abspath,"\/"); lenThere = arraylen(aThere); 

			for (x = 1; x lte arraylen(aHere); x = x + 1) { 
				if (x GT lenThere OR comparenocase(aHere[x],aThere[x])) { 
					ArrayPrepend(aRel,".."); if (x lte lenThere) { ArrayAppend(aRel,aThere[x]); } 
				} 
			}

			for (; x lte arraylen(aThere); x = x + 1) { ArrayAppend(aRel,aThere[x]); }

			newpath = "/" & ArrayToList(aRel,"/"); 

			return newpath; 
		}
		Request.getRelativePath = getRelativePath;

	</cfscript>
	
	<!--- Script by Saman W Jayasekara --->
	<cffunction name="cleanup" access="private" returntype="string" output="Yes" hint="Possible Malicious html code from a given string"> 
	 <cfargument name="str" type="string" required="yes">
	 <cfargument name="action" type="string" required="no" default="cleanup" hint="If [cleanup], this will clean up the string and output new string, if [find], this will output a value or zero"> 
	 <!--- **************************************************************************** ---> 
	 <!--- Remove string between <script> <object><iframe><style><meta> and <link> tags ---> 
	 <!--- @param str     String to clean up. (Required)                                ---> 
	 <!--- @param action    Replace and Clean up or Find                                ---> 
	 <!--- @author         Saman W Jayasekara (sam @ cflove . org)                      ---> 
	 <!--- @version 1.1    May 22, 2010 												--->       
	 <!--- Gregory added attachScript to the list 										--->
	 <!--- **************************************************************************** ---> 
	 <cfswitch expression="#arguments.action#"> 
		<cfcase value="cleanup"> 
			<cfset local.str = ReReplaceNoCase(arguments.str,"<script.*?</*.script*.>|<attachScript.*?</*.attachScript*.>|<applet.*?</*.applet*.>|<embed.*?</*.embed*.>|<ilayer.*?</*.ilayer*.>|<frame.*?</*.frame*.>|<object.*?</*.object*.>|<iframe.*?</*.iframe*.>|<style.*?</*.style*.>|<meta([^>]*[^/])>|<link([^>]*[^/])>|<script([^>]*[^/])>", "", "ALL")> 
			<cfset local.str = local.str.ReplaceAll("<\w+[^>]*\son\w+=.*[ /]*>|<script.*/*>|</*.script>|<[^>]*(javascript:)[^>]*>|<[^>]*(onClick:)[^>]*>|<[^>]*(onDblClick:)[^>]*>|<[^>]*(onMouseDown:)[^>]*>|<[^>]*(onMouseOut:)[^>]*>|<[^>]*(onMouseUp:)[^>]*>|<[^>]*(onMouseOver:)[^>]*>|<[^>]*(onBlur:)[^>]*>|<[^>]*(onFocus:)[^>]*>|<[^>]*(onSelect:)[^>]*>","") > 
			<cfset local.str = reReplaceNoCase(local.str, "</?(script|applet|embed|ilayer|frame|iframe|frameset|style|link)[^>]*>","","all")> 
		</cfcase> 
		<cfdefaultcase> 
			<cfset local.str = REFindNoCase("<script.*?</script*.>|<applet.*?</applet*.>|<embed.*?</embed*.>|<ilayer.*?</ilayer*.>|<frame.*?</frame*.>|<object.*?</object*.>|<iframe.*?</iframe*.>|<style.*?</style*.>|<meta([^>]*[^/])>|<link([^>]*[^/])>|<\w+[^>]*\son\w+=.*[ /]*>|<[^>]*(javascript:)[^>]*>|<[^>]*(onClick:)[^>]*>|<[^>]*(onDblClick:)[^>]*>|<[^>]*(onMouseDown:)[^>]*>|<[^>]*(onMouseOut:)[^>]*>|<[^>]*(onMouseUp:)[^>]*>|<[^>]*(onMouseOver:)[^>]*>|<[^>]*(onBlur:)[^>]*>|<[^>]*(onFocus:)[^>]*>|<[^>]*(onSelect:)[^>]*>",arguments.str)> 
		</cfdefaultcase> 
	 </cfswitch> 
	 <cfreturn local.str> 
	</cffunction>
				
	<cffunction name="getYouTubeVideoId" returnType="string" 
			hint="Function to get the YouTube ID. This should work for most URL's. Gregory Alexander modified an approach suggested by Ray Camden">
		<cfargument name="youTubeUrl" default="" required="yes">

		<!---Check to see if this is a short YouTube URL (http://youtu.be/f89niPP64Hg) --->
		<cfif listGetAt(arguments.youTubeUrl, 2, '/') eq 'youtu.be'>
			<cfset youTubeId = listLast(arguments.youTubeUrl, '/')>
		<cfelse>
			<cfset youTubeId = reReplaceNoCase(arguments.youTubeUrl, ".*?v=([a-z0-9\-_]+).*","\1")>
		</cfif>

		<cfreturn youTubeId>

	</cffunction>
			
	<!--- This UDF from Steven Erat, http://www.talkingtree.com/blog --->
	<cffunction name="replaceLinks" access="public" output="yes" returntype="string">
		<cfargument name="input" required="Yes" type="string">
		<cfargument name="linkmax" type="numeric" required="false" default="50">
		<cfscript>
			var inputReturn = arguments.input;
			var pattern = "";
			var urlMatches = structNew();
			var inputCopy = arguments.input;
			var result = "";
			var rightStart = "";
			var rightInputCopyLen = "";
			var targetNameMax = "";
			var targetLinkName = "";
			var i = "";
			var match = "";

			pattern = "(((https?:|ftp:|gopher:)\/\/)|(www\.|ftp\.))[-[:alnum:]\?%,\.\/&##!;@:=\+~_]+[A-Za-z0-9\/]";

			while (len(inputCopy)) {
				result = refind(pattern,inputCopy,1,'true');
				if (result.pos[1]){
					match = mid(inputCopy,result.pos[1],result.len[1]);
					urlMatches[match] = "";
					rightStart = result.len[1] + result.pos[1];
					rightInputCopyLen = len(inputCopy)-rightStart;
					if (rightInputCopyLen GT 0){
						inputCopy = right(inputCopy,rightInputCopyLen);
					} else break;
				} else break;
			}

			//convert back to array
			urlMatches = structKeyArray(urlMatches);

			targetNameMax = arguments.linkmax;
			for (i=1; i LTE arraylen(urlMatches);i=i+1) {
				targetLinkName = urlMatches[i];
				if (len(targetLinkName) GTE targetNameMax) {
					targetLinkName = left(targetLinkName,targetNameMax) & "...";
				}
				// Added a no rel tag (GA).
				inputReturn = replace(inputReturn,urlMatches[i],'<a href="#urlMatches[i]#" target="_blank" rel="noopener">#targetLinkName#</a>',"all");
			}
		</cfscript>
		<cfreturn inputReturn>
	</cffunction>
			
	<cffunction name="createFullyQualifiedMediaUrl" returntype="string" output="false" 
			hint="Unfortunately, the mediaUrl contains the baseUrl (i.e. '/blog') and this creates problems when we try to create a fully qualified URL. This function will remove the baseUrl from the mediaUrl string in the database. This function is used to create a fully qualified URL to the media file">
		<cfargument name="mediaUrlFromDb" type="string" required="yes" default=""/>

		<!--- Remove the baseUrl from the mediaUrl string --->
		<cfset formattedMediaUrl = replaceNoCase(mediaUrlFromDb, application.baseUrl, '', 'one')>
		<!--- Create a fully qualified URL by appending the formattedMediaUrl to the application.blogHostUrl --->
		<cfset fullyQualifiedMediaUrl = application.blogHostUrl & formattedMediaUrl>

		<!--- Return it --->
		<cfreturn fullyQualifiedMediaUrl>
	</cffunction>

	<!---//*****************************************************************************************
		Comment formatting (5.03)
	//******************************************************************************************--->

	<!--- Visitors can format a comment with a few Markdown marks: **bold**, *italic*, `code`, fenced code blocks, lists, > quotes and
	links. A visitor's comment is saved as encoded plain text (addComment) and stays that way; the marks are read here, when the comment
	is shown. Every piece of the visitor's text is encoded, and the only HTML on the page is the handful of fixed tags written below. A
	link must start with http:// or https://. No HTML from a visitor is ever accepted, so nothing has to be cleaned. A comment that
	already has HTML in it was written or edited in the administrator's comment editor (or imported from BlogCFC), and is shown as it
	always was. --->
	<cffunction name="formatComment" access="public" output="false" returntype="string"
			hint="Turns a stored comment into the HTML shown on the page and in emails.">
		<cfargument name="comment" type="string" required="false" default="">
		<cfscript>
			var text = arguments.comment;
			var lines = [];
			var html = [];
			var i = 1;
			var j = 0;
			var lineCount = 0;
			var line = "";
			var block = [];
			var closing = 0;
			var lang = "";

			if (not len(trim(text))) {
				return "";
			}
			if (find("<", text)) {
				return paragraphFormat2(text);
			}
			text = commentPlainText(text);
			lines = listToArray(text, chr(10), true);
			lineCount = arrayLen(lines);

			while (i lte lineCount) {
				line = lines[i];

				// A fenced code block: ``` (with an optional language) up to the next ``` line. Without a closing fence the marks are
				// shown as typed. The code is shown exactly as typed, nothing inside it is formatted.
				if (left(trim(line), 3) eq "```") {
					lang = lCase(trim(mid(trim(line), 4, len(trim(line)))));
					closing = 0;
					for (j = i + 1; j lte lineCount; j++) {
						if (trim(lines[j]) eq "```") {
							closing = j;
							break;
						}
					}
					if (closing and reFind("^[a-z0-9+-]*$", lang)) {
						block = [];
						for (j = i + 1; j lt closing; j++) {
							arrayAppend(block, lines[j]);
						}
						arrayAppend(html, '<pre class="language-' & commentCodeLanguage(lang) & '"><code>' & commentEncode(arrayToList(block, chr(10))) & '</code></pre>');
						i = closing + 1;
						continue;
					}
				}

				// A blank line ends a paragraph.
				if (not len(trim(line))) {
					i++;
					continue;
				}

				// A list: lines starting with - * or +, or with a number and a period.
				if (reFind("^\s*[-*+]\s+\S", line) or reFind("^\s*[0-9]{1,3}[.)]\s+\S", line)) {
					block = [];
					lang = reFind("^\s*[-*+]\s", line) ? "ul" : "ol";
					while (i lte lineCount and ((lang eq "ul" and reFind("^\s*[-*+]\s+\S", lines[i])) or (lang eq "ol" and reFind("^\s*[0-9]{1,3}[.)]\s+\S", lines[i])))) {
						arrayAppend(block, "<li>" & commentInline(reReplace(lines[i], "^\s*([-*+]|[0-9]{1,3}[.)])\s+", "")) & "</li>");
						i++;
					}
					arrayAppend(html, "<" & lang & ">" & arrayToList(block, "") & "</" & lang & ">");
					continue;
				}

				// A quote: lines starting with >.
				if (reFind("^\s*>", line)) {
					block = [];
					while (i lte lineCount and reFind("^\s*>", lines[i])) {
						arrayAppend(block, commentInline(reReplace(lines[i], "^\s*>\s?", "")));
						i++;
					}
					arrayAppend(html, "<blockquote>" & arrayToList(block, "<br />") & "</blockquote>");
					continue;
				}

				// A paragraph: every other line up to a blank line or one of the blocks above. Line breaks are kept, as before. Its first
				// line is always taken, so a ``` line without a closing fence is shown as text.
				block = [commentInline(line)];
				i++;
				while (i lte lineCount and len(trim(lines[i])) and left(trim(lines[i]), 3) neq "```" and not reFind("^\s*([-*+]\s+\S|[0-9]{1,3}[.)]\s+\S|>)", lines[i])) {
					arrayAppend(block, commentInline(lines[i]));
					i++;
				}
				arrayAppend(html, "<p>" & arrayToList(block, "<br />") & "</p>");
			}
			return arrayToList(html, chr(10));
		</cfscript>
	</cffunction>

	<cffunction name="commentSnippet" access="public" output="false" returntype="string"
			hint="A comment as encoded plain text without the formatting marks, for the short previews in the recent comments lists.">
		<cfargument name="comment" type="string" required="false" default="">
		<cfscript>
			var text = arguments.comment;
			if (find("<", text)) {
				return text;
			}
			text = commentPlainText(text);
			text = reReplace(text, "(^|\n)\s*```[^\n]*", "\1", "all");
			text = reReplace(text, "(^|\n)\s*>\s?", "\1", "all");
			text = replace(text, "**", "", "all");
			text = replace(text, "`", "", "all");
			return commentEncode(trim(text));
		</cfscript>
	</cffunction>

	<cffunction name="unpackFromBrowser" access="public" output="false" returntype="string"
			hint="Decodes text that the browser sent past Global Script Protection (blogJsContent.cfm bypassScriptProtection: 'galaxie64:' and base64). Text without that start is returned as it is, so a page that was open before an update still saves what it sends.">
		<cfargument name="text" type="string" required="false" default="">
		<cfscript>
			var s = "";
			if (left(arguments.text, 10) neq "galaxie64:") {
				return arguments.text;
			}
			s = replace(replace(trim(mid(arguments.text, 11, len(arguments.text))), "-", "+", "all"), "_", "/", "all");
			if (not len(s)) {
				return "";
			}
			if (reFind("[^A-Za-z0-9+/]", s)) {
				throw(type="Galaxie.UnpackFromBrowser", message="The text from the browser could not be read.");
			}
			s = s & repeatString("=", (4 - len(s) mod 4) mod 4);
			return charsetEncode(binaryDecode(s, "base64"), "utf-8");
		</cfscript>
	</cffunction>

	<cffunction name="commentPlainText" access="private" output="false" returntype="string"
			hint="The visitor's text as typed: the stored comment decoded, with Unix line endings and without the two characters commentInline uses as markers.">
		<cfargument name="comment" type="string" required="true">
		<cfscript>
			var text = decodeForHtml(arguments.comment);
			text = replace(text, chr(13) & chr(10), chr(10), "all");
			text = replace(text, chr(13), chr(10), "all");
			text = replace(text, chr(1), "", "all");
			return replace(text, chr(2), "", "all");
		</cfscript>
	</cffunction>

	<cffunction name="commentEncode" access="private" output="false" returntype="string"
			hint="Encodes text for the page. Only the five characters that matter in HTML text and in a quoted attribute are changed, so the Markdown marks stay readable for commentInline.">
		<cfargument name="text" type="string" required="true">
		<cfscript>
			var s = replace(arguments.text, "&", "&amp;", "all");
			s = replace(s, "<", "&lt;", "all");
			s = replace(s, ">", "&gt;", "all");
			s = replace(s, '"', "&quot;", "all");
			return replace(s, "'", "&##39;", "all");
		</cfscript>
	</cffunction>

	<cffunction name="commentCodeLanguage" access="private" output="false" returntype="string"
			hint="The Prism language for a code block. CFML tags are highlighted as markup; an unknown name gets no highlighting.">
		<cfargument name="lang" type="string" required="true">
		<cfscript>
			var languages = {
				"cfml": "markup", "cfm": "markup", "html": "markup", "xml": "markup", "markup": "markup",
				"cfscript": "cfscript", "cfc": "cfscript",
				"js": "javascript", "javascript": "javascript", "ts": "typescript", "typescript": "typescript", "json": "json",
				"css": "css", "sql": "sql", "java": "java", "csharp": "csharp", "cs": "csharp", "php": "php", "python": "python", "py": "python",
				"ruby": "ruby", "bash": "bash", "sh": "bash", "shell": "bash", "powershell": "powershell", "ps": "powershell",
				"markdown": "markdown", "md": "markdown"
			};
			return structKeyExists(languages, arguments.lang) ? languages[arguments.lang] : "none";
		</cfscript>
	</cffunction>

	<cffunction name="commentInline" access="private" output="false" returntype="string"
			hint="Formats one line of a comment: `code`, [text](link), bare links, **bold** and *italic*.">
		<cfargument name="line" type="string" required="true">
		<cfscript>
			// Code and links are set aside behind a numbered marker (chr(1) number chr(2)) so that nothing inside them is formatted,
			// and put back at the end. The list is kept in a struct: Adobe ColdFusion passes an array to a function as a copy.
			var keep = {items: []};
			var s = commentSetAside(arguments.line, "`([^`]+)`", "code", keep);
			var k = 0;
			s = commentEncode(s);
			s = commentSetAside(s, "\[([^\]" & chr(1) & chr(2) & "]+)\]\((https?://[^\s)]+)\)", "link", keep);
			s = commentSetAside(s, "https?://[^\s" & chr(1) & chr(2) & "]+", "url", keep);
			s = reReplace(s, "\*\*([^*]+)\*\*", "<strong>\1</strong>", "all");
			s = reReplace(s, "\*([^*\s]([^*]*[^*\s])?)\*", "<em>\1</em>", "all");
			for (k = arrayLen(keep.items); k gte 1; k--) {
				s = replace(s, chr(1) & k & chr(2), keep.items[k], "all");
			}
			return s;
		</cfscript>
	</cffunction>

	<cffunction name="commentSetAside" access="private" output="false" returntype="string"
			hint="Replaces each match of the pattern with a numbered marker and keeps its HTML in keep.items.">
		<cfargument name="s" type="string" required="true">
		<cfargument name="pattern" type="string" required="true">
		<cfargument name="kind" type="string" required="true">
		<cfargument name="keep" type="struct" required="true">
		<cfscript>
			var out = "";
			var start = 1;
			var found = reFind(arguments.pattern, arguments.s, start, true);
			var whole = "";
			var href = "";
			var tail = "";
			var piece = "";

			while (found.pos[1] gt 0) {
				out = out & mid(arguments.s, start, found.pos[1] - start);
				whole = mid(arguments.s, found.pos[1], found.len[1]);
				if (arguments.kind eq "code") {
					// The code is still the visitor's raw text here; it is encoded on its own.
					piece = "<code>" & commentEncode(mid(arguments.s, found.pos[2], found.len[2])) & "</code>";
				} else if (arguments.kind eq "link") {
					// The text and the address were already encoded with the rest of the line.
					piece = commentLink(mid(arguments.s, found.pos[3], found.len[3]), mid(arguments.s, found.pos[2], found.len[2]));
				} else {
					// A bare address: punctuation at its end belongs to the sentence, not to the address.
					href = whole;
					tail = "";
					while (len(href) and (reFind("[.,;:!?)]$", href) or reFind("&(quot|##39|gt);$", href))) {
						if (reFind("&(quot|##39|gt);$", href)) {
							tail = mid(href, reFind("&(quot|##39|gt);$", href), len(href)) & tail;
							href = left(href, reFind("&(quot|##39|gt);$", href) - 1);
						} else {
							tail = right(href, 1) & tail;
							href = left(href, len(href) - 1);
						}
					}
					piece = (reFind("^https?://[^/\s]", href) ? commentLink(href, href) : href) & tail;
				}
				arrayAppend(arguments.keep.items, piece);
				out = out & chr(1) & arrayLen(arguments.keep.items) & chr(2);
				start = found.pos[1] + found.len[1];
				if (start gt len(arguments.s)) {
					break;
				}
				found = reFind(arguments.pattern, arguments.s, start, true);
			}
			if (start lte len(arguments.s)) {
				out = out & mid(arguments.s, start, len(arguments.s) - start + 1);
			}
			return out;
		</cfscript>
	</cffunction>

	<cffunction name="commentLink" access="private" output="false" returntype="string"
			hint="A link in a comment. Both values arrive encoded. nofollow and ugc tell search engines the link is a visitor's.">
		<cfargument name="href" type="string" required="true">
		<cfargument name="text" type="string" required="true">
		<cfreturn '<a href="' & arguments.href & '" rel="nofollow ugc noopener" target="_blank">' & arguments.text & '</a>'>
	</cffunction>

</cfcomponent>			