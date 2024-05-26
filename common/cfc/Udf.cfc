<cfcomponent displayname="Udf" hint="Common functions" name="Udf">
			
	<!---******************************************************************************************************
		Security (note: this looks like it can be removed)
	******************************************************************************************************--->
			
	<cfscript>
		
		/* Moved session scope vars to the top of the page.
		Set a session var to indicate whether the user is an admin user.*/
		function isLoggedIn() {
			return structKeyExists(session,"loggedin");
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
			
</cfcomponent>			