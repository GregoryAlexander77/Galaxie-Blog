<cfcomponent displayname="StringUtils" hint="String utilities" name="StringUtils" output="yes">
	
	<!---******************************************************************************************************
		String Utils 
	******************************************************************************************************--->
	
	<cffunction name="trimStr" returntype="string" output="false">
		<cfargument name="s" type="string" required="yes">
		<cfreturn Trim(Replace(s, chr(160), " ", "ALL"))>
	</cffunction>
			
	<!--- Scripts to clean up the string when we are bypassing ColdFusion/Lucee Global Script Protection. To bypass this on the client side, we are using the bypassScriptProtection JavaScript function in the blogJsContent.cfm template to replace 'script' with 'attachScript', 'style' with 'attachStyle' and 'meta' with 'attachMeta'. On the server, we need to clean these strings up and eliminate the attach string before we save it to the db. Without this logic we would have an 'InvalidTag' string replacing these strings when Global Script Protection is enabled. We are also removing any backslashes and backticks as these will cause tinymce to break. --->
	<cffunction name="sanitizeStrForDb" access="public" output="false" returntype="string" 
			hint="Cleans up the 'attach' strings to bypass script protection and removes any characters that will break tinyMce">
		<cfargument name="s" type="string" required="yes">
		<!--- Replaces the comment outside of the script tags. The comment is necessary to render the script in the tinymce editor. This may occur when the user is editting an existing post with a script. --->
		<!--- Replace the opening comment --->
		<cfset s = replaceNoCase(s, "<!--<attachScript", "<script", "all")>
		<!--- Replace the end comment --->
		<cfset s = replaceNoCase(s, "</attachScript>-->", "</script>", "all")>
		<!--- Clean up 'attachScript' --->
		<cfset s = replaceNoCase(s, "attachScript", "script", "all")>
		<!--- ...'attachStyle'... --->
		<cfset s = replaceNoCase(s, "attachStyle", "style", "all")>	
		<!--- Iframes --->
		<cfset s = replaceNoCase(s, "attachIframe", "iframe", "all")>	
		<!--- ...'meta'... --->
		<cfset s = replaceNoCase(s, "attachMeta", "meta", "all")>
		<!--- Sanitize the strings for tinyMce. --->
		<!--- There must not be any literal template strings (`). We are not replacing these --->
		<cfset s = replaceNoCase(s,"`","'","all")>
		<!--- Replace any backslashes with the ascii symbol --->
		<cfset s = replaceNoCase(s,"\","&bsol;","all")>	
		<!--- Return it --->
		<cfreturn s>
	</cffunction>
			
	<!--- Generic string functions --->
				
	<cffunction name="replaceStringInContent" access="public" output="false" returntype="string" 
			hint="Replaces or removes everything between to defined strings. Used by the search results template and to remove the ld json when importing data from Galaxie 1. You should use this instead of the Jsoup functions to remove stuff between tags when you don't want JSoup to format the html including adding end tags for ColdFusion tags (ie <cfset x = 'foo'></cfset>)">
		<cfargument name="content" required="yes" hint="What is the content that we need to search and replace?">
		<cfargument name="startString" required="yes" hint="What is the string that we are looking for?">
		<cfargument name="endString" required="yes" hint="And what is the end of the string?">
		<cfargument name="replaceValueWith" required="no" default="" hint="What do you want to replace the string that is found between the start and end positions with? If you leave this blank, it will remove the content that is found.">

		<cftry>
			<!--- Find the start and end position of the mainEntityOfPage block. --->
			<cfset startPos = findNoCase(arguments.startString, arguments.content)>
			<cfset endPos = findNoCase(arguments.endString, arguments.content)>

			<!--- And determine the count --->
			<cfset valueCount = endPos - startPos>
			<!--- Get the value in the string. --->
			<cfset stringValue = mid(arguments.content, startPos, valueCount+len(arguments.endString))>
			<!--- Remove the ld json code block from the string --->
			<cfset newString = replaceNoCase(arguments.content, stringValue, replaceValueWith)>

			<cfcatch type="any">
				<!--- The string was not found. --->
				<cfset newString = arguments.content>
			</cfcatch>
		</cftry>

		<!--- Return new post content --->
		<cfreturn newString>

	</cffunction>
				
	<cffunction name="removeTag" access="public" output="false" returntype="string" 
			hint="Removes everything between two tags. Used by the search results and rss templates. You should use this instead of the Jsoup functions to remove stuff between tags when you don't want JSoup to format the html including adding end tags for ColdFusion tags (ie <cfset x = 'foo'></cfset>)">

		<cfargument name="str" required="yes" hint="What is the string that you want parsed?">
		<cfargument name="tag" required="yes" hint="What tag is to be removed?">

		<!--- Set the strings that we're searching for. --->
		<cfset keyWordStartString = "<" & arguments.tag & ">">
		<cfset keyWordEndString = "</" & arguments.tag & ">">

		<!--- Find the start and end position of the keywords. --->
		<cfset strStartPos = findNoCase(keyWordStartString, arguments.str)>
		<cfset strEndPos = findNoCase(keyWordEndString, arguments.str)>
			
		<!--- There will be an error if there is no content. Put this in a try block --->
		<cftry>
			<!--- Add the lengh of the keyword to get the proper start position. --->
			<cfset keyWordValueStartPos = strStartPos + len(strStartPos)>
			<!--- And determine the count --->
			<cfset valueCount = strEndPos - strStartPos>
			<!--- Get the value. --->
			<cfset tagData = mid(arguments.str, keyWordValueStartPos, valueCount)>
			<!--- Strip it out. --->
			<cfset strippedContent = replaceNoCase(arguments.str, tagData, "", "all")>
				
			<!--- Rip out the opening tag --->
			<cfset strippedContent = replaceNoCase(strippedContent, "<" & arguments.tag & ">", "", "all")>
			<!--- And the closing tag. Note- we are also removing the end tag of the closing tag of the directive body '>' --->
			<cfset strippedContent = replaceNoCase(strippedContent, "></" & arguments.tag & ">", "", "all")>
			<!--- Finally, remove the end tag if it still exists --->
			<cfset strippedContent = replaceNoCase(strippedContent, "</" & arguments.tag & ">", "", "all")>
			<cfcatch type="any">
				<cfset strippedContent = arguments.str>
			</cfcatch>
		</cftry>

		<!--- Return new post content --->
		<cfreturn strippedContent>

	</cffunction>
				
	<cffunction name="removeXmlDirective" access="public" output="false" returntype="string" 
			hint="Removes an xml directive from the post. Used when importing old data">

		<cfargument name="str" required="yes" hint="What is the string that you want parsed?">
		<cfargument name="xmlDirective" required="yes" hint="What xmlDirective is to be removed?">
		<cfargument name="xmlVersion" required="no" default="2" hint="I changed the structure to a more standard format on version 2.">
			
		<cfif version eq 2>
			<cfset openingTagEnding = ">">
		<cfelse>
			<cfset openingTagEnding = ":">
		</cfif>
			
		<!---
		Example format of xml directives
		<descMetaTag:Blah blah blah.></descMetaTag>
		--->
			
		<!--- Get the content --->
		<cfset xmlKeywordContent = application.blog.getXmlKeywordValue(arguments.str, arguments.xmlDirective)>
			
		<cfset strippedContent = arguments.str>
			
		<!--- There will be an error if there is no content. Put this in a try block --->
		<cftry>
			<!--- If there is any content, strip it out. --->
			<cfif len(xmlKeywordContent)>
				<cfset strippedContent = replaceNoCase(arguments.str, xmlKeywordContent, "", "all")>
			</cfif>
			<!--- The content should now look like '<descMetaTag:></descMetaTag>' --->
				
			<!--- Set the opening and closing tags --->
			<cfset openingXmlDirective = "<" & arguments.xmlDirective & openingTagEnding>
			<cfif arguments.version eq 1>
				<cfset closingXmlDirective = "></" & arguments.xmlDirective & ">">
			<cfelse>
				<cfset closingXmlDirective = "</" & arguments.xmlDirective & ">">
			</cfif>
			
			<!--- Now eliminate the tags --->
			<cfif arguments.version eq 1>
				<cfset xmlDirectiveTags = "<" & arguments.xmlDirective & ":></" & arguments.xmlDirective & ">">
			<cfelse>
				<cfset xmlDirectiveTags = "<" & arguments.xmlDirective & "></" & arguments.xmlDirective & ">">
			</cfif>
			<!--- Rip out the opening xmlDirective tags. --->
			<cfset strippedContent = replaceNoCase(strippedContent, xmlDirectiveTags, "", "all")>
			
			<!--- On rare occassions when there are other directives, there may be a period betwen the tags (<descMetaTag:.</descMetaTag>). I am not sure if this is an artifact or not, but strip these out too --->
			<!--- Rip out the opening xmlDirective tags. --->
			<cfset strippedContent = replaceNoCase(strippedContent, openingXmlDirective, "", "all")>
			<!--- And the closing tag. --->
			<cfset strippedContent = replaceNoCase(strippedContent, ".</" & arguments.xmlDirective & ">", "", "all")>
				
			<cfcatch type="any">
				<cfset strippedContent = arguments.str>
			</cfcatch>
		</cftry>
		
		<!--- Return new post content --->
		<cfreturn strippedContent>

	</cffunction>
				
	<!--- Function to remove the 'quasi' xml keywords from the post content. Note: this is used when importing data. ---> 
	<cffunction name="removeXmlKeyWordContentFromPost" access="public" returntype="string" hint="Removes the vaarious 'qausi' xml that I am stuffing into an individual post. This will go away once I develop the new database">
		<cfargument name="postContent" required="yes" hint="The post content is typically 'RendererObj.renderBody(body,mediaPath)'.">
		<cfargument name="xmlKeywords" required="yes" hint="Supply all of the xmlKeywords.">
		<cfargument name="xmlVersion" required="no" default="2" hint="I changed the structure to a more standard format on version 2.">
			
		<cfif version eq 2>
			<cfset openingTagEnding = ">">
		<cfelse>
			<cfset openingTagEnding = ":">
		</cfif>

		<!--- Preset our newPostContent content. --->
		<cfset newPostContent = arguments.postContent>

		<!--- Loop through the xml keywords --->
		<cfloop list="#arguments.xmlKeywords#" index="i">

			<!--- Put this in a try block. --->
			<cftry>

				<!--- Isolate the keyword --->
				<cfset thisKeyword = i>

				<!--- Find the start and end position of the keywords. --->
				<cfset keyWordStartString = "<" & thisKeyword & openingTagEnding>
				<cfset keyWordEndString = "</" & thisKeyword & ">">

				<!--- Find the start and end position of the keywords. --->
				<cfset postDataStartPos = findNoCase(keyWordStartString, newPostContent)>
				<cfset postDataEndPos = findNoCase(keyWordEndString, newPostContent)>

				<!--- And determine the count --->
				<cfset valueCount = postDataEndPos - postDataStartPos>
				<!--- Get the value in the xml string. --->
				<cfset xmlBody = mid(newPostContent, postDataStartPos, valueCount)>

				<!--- Strip the content. --->
				<cfset strippedPostContent = replaceNoCase(newPostContent, xmlBody, "", "all")>
				<!--- Strip the start of the tag --->
				<cfset strippedPostContent = replaceNoCase(strippedPostContent, keyWordStartString, "", "all")>
				<!--- And finally, strip the ending tag --->
				<cfset strippedPostContent = replaceNoCase(strippedPostContent, keyWordEndString, "", "all")>

				<!--- Return new post content --->
				<cfset newPostContent = strippedPostContent>

				<cfcatch type="any">
					<cfset error = cfcatch.detail>
				</cfcatch>
			</cftry>

		</cfloop>

		<!--- Return it. --->
		<cfreturn newPostContent>

	</cffunction>
					
	<!--- By design, the theme image locations are only using part of the file path starting from /images. This was initially done as I wanted to keep the theme images from using specific domain and blog path information. This simplifies the logic when installing the blog and allows the blog to be more portable from server to server. However, we need this information when using the editors and the full paths will be sent in. We need to remove the path info here. I may revisit this decision in future editions. --->
	<cffunction name="setThemeFilePath"  access="public" output="yes" returntype="string" 
			hint="Removes domain and file path information from theme related images when storing the location in the database. This should only keep the information after the '/images/' string">
		<cfargument name="filePath" required="yes" hint="Pass in the file path">
			
		<cfparam name="imageFilePath" default="">
			
		<cfif len(arguments.filePath)>
			<!--- Find the '/image' string position --->
			<cfset startPos = findNoCase( '/images/', arguments.filePath )>
			<!--- If the start position is 1, we don't need to do anything --->
			<cfif startPos eq 1>
				<cfset imageFilePath = arguments.filePath>
			<cfelse>
				<!--- We only want to perform this logic if the path is stored in this blog. --->
				<cfif arguments.filePath contains application.baseUrl>
					<!--- Determine the count --->
					<cfset endPos = (len(arguments.filePath) - startPos) + 1>
					<!--- Get the new file path starting with '/image'. --->
					<cfset imageFilePath = mid(arguments.filePath, startPos, endPos)>
				<cfelse><!---<cfif arguments.filePath contains application.baseUrl>--->
					<cfset imageFilePath = arguments.filePath>
				</cfif><!---<cfif arguments.filePath contains application.baseUrl>--->
			</cfif>
		</cfif>
		
		<!--- Return it --->
		<cfreturn imageFilePath>
				
	</cffunction>
			
	<cffunction name="getTextFromBody" access="public" output="false" returntype="string" 
			hint="Removes everything between postData tags and the HTML found in the post content. Used by the search results template.">

		<cfargument name="postContent" required="yes" hint="The post content is typically 'RendererObj.renderBody(body,enclosure)'.">
			
		<!--- Remove the postData tag that has the directives --->
		<cfset removePostData = this.removeTag(str=arguments.postContent, tag='postData')>
		<!--- Now, remove the xml and html from result. --->
		<cfset newbody = reReplace(removePostData, "<.*?>", "", "all")>
		<cfset newBody = reReplaceNoCase(newbody,"<[^>]*>","","all")>

		<!--- Return new post content --->
		<cfreturn newbody>

	</cffunction>
			
	<!--- String formatting --->
	<cffunction name="removeEmptyLinesInStr" access="public" output="false" returntype="string">
		<cfargument name="str" required="yes">
		<cfset formattedStr = reReplace( arguments.str, "[\r\n]\s*([\r\n]|\Z)", "#chr(13)##chr(10)#", "all" )>
		<cfreturn formattedStr>
	</cffunction>
			
	<cffunction name="removeOctalsInStr" access="public" output="false" returntype="string" hint="Note: JavaScript does not like backslashes in the code. We are replacing \ with chr(92)">
		<cfargument name="str" required="yes">
		<cfset formattedStr = reReplace( arguments.str, "\", "#chr(92)#", "all" )>
		<cfreturn formattedStr>
	</cffunction>
			
	<cfscript>
		 /**
		 * Breaks a camelCased string into separate words
		 * 8-mar-2010 added option to capitalize parsed words Brian Meloche brianmeloche@gmail.com
		 * 
		 * @param str      String to use (Required)
		 * @param capitalize      Boolean to return capitalized words (Optional)
		 * @return Returns a string 
		 * @author Richard (brianmeloche@gmail.comacdhirr@trilobiet.nl) 
		 * @version 0, March 8, 2010 
		 */
		function camelToSpace(str) {
			var rtnStr=lcase(reReplace(arguments.str,"([A-Z])([a-z])","&nbsp;\1\2","ALL"));
			if (arrayLen(arguments) GT 1 AND arguments[2] EQ true) {
				rtnStr=reReplace(arguments.str,"([a-z])([A-Z])","\1&nbsp;\2","ALL");
				rtnStr=uCase(left(rtnStr,1)) & right(rtnStr,len(rtnStr)-1);
			}
			return trim(rtnStr);
		}
		
		/*
		 * function - titleCase()
		 *    accepts and returns string data this function is similar
		 *    to LCase or UCase,
		 *       See: http://livedocs.macromedia.com/coldfusion/6.1/htmldocs/functiob.htm
		 *       See: http://livedocs.macromedia.com/coldfusion/6.1/htmldocs/funca112.htm
		 * Function formats a string according to predefined rules.
		 * first it separates test so that it is formatted With All
		 * Words With Initial Capital Letters And With The Rest Of
		 * The Letters In Lowercase, then, it takes special cases
		 * and adjusts, for example, it changes some words, like Of
		 * and The to of and the, when they are not the first part
		 * of a string, also, it adjusts for names like McKenna.
		 * it was designed for the college database which was
		 * provided in ALLCAPS.
		 *
		 * Questions? https://artlung.com/feedback/
		 * 22-04-2003
		*/

		function titleCase(string)  {
			if (len(string) gt 1)
			{
				string = lcase(string);

				if (refind("^[a-z]", string))  {
				string = ucase(left(string, 1)) & right(string,
		(len(string) - 1 ));
				}

				next = refind("[[:space:][:punct:]][a-z]", string);

				while (next)  {
					if (next lt (len(string) - 1)) {
					string = left(string, (next)) & ucase(mid(string,
		next+1, 1)) &  right(string, (len(string) - (next + 1)));
					} else {
					string = left(string, (next)) &
		ucase(right(string, 1));
					}

				next = refind("[[:space:][:punct:]][a-z]", string, next);
				}
			} else {
			string = ucase(string);

			}
			/* post fixes */
			/* Recall that "Replace()" is case sensitive */
			string = Replace(string," Of "," of ","ALL");
			string = Replace(string," And "," and ","ALL");
			string = Replace(string,"'S ","'s ","ALL");
			string = Replace(string," At "," at ","ALL");
			string = Replace(string," The "," the ","ALL");
			string = Replace(string," For "," for ","ALL");
			string = Replace(string," De "," de ","ALL");
			string = Replace(string," Y "," y ","ALL");
			string = Replace(string," In "," in ","ALL");

			/* roman numerals */
			string = Replace(string," Iii"," III","ALL");
			string = Replace(string," Ii"," II","ALL");

			/* specific cases of acronyms */
			string = Replace(string,"Abc ","ABC ","ALL");
			string = Replace(string,"Abcd","ABCD ","ALL");
			string = Replace(string,"Aaa ","AAA ","ALL");
			string = Replace(string,"Cbe ","CBE ","ALL");
			string = Replace(string,"Cei ","CEI ","ALL");
			string = Replace(string,"Itt ","ITT ","ALL");
			string = Replace(string,"Mbti ","MBTI ","ALL");
			string = Replace(string,"Cuny ","CUNY ","ALL");
			string = Replace(string,"Suny ","SUNY ","ALL");
			string = Replace(string,"Mta ","MTA ","ALL");
			string = Replace(string,"Mti ","MTI ","ALL");
			string = Replace(string,"Qpe ","QPE ","ALL");
			string = Replace(string," Ogc "," OGC ","ALL");
			string = Replace(string,"Tci ","TCI ","ALL");
			string = Replace(string,"The Cdl ","The CDL ","ALL");
			string = Replace(string,"The Mbf ","The MBF","ALL");
			string = Replace(string,"Lpn","LPN","ALL");
			string = Replace(string,"Cvph ","CVPH ","ALL");
			string = Replace(string,"Dch ","DCH ","ALL");
			string = Replace(string,"Bmr ","BMR ","ALL");
			string = Replace(string,"Isim ","ISIM ","ALL");

			/* contractions */
			string = Replace(string," Mgt"," Management","ALL");
			string = Replace(string,"Trng","Training","ALL");
			string = Replace(string,"Xray","X-Ray","ALL");
			string = Replace(string," Sch "," School ","ALL");
			string = Replace(string," Dba "," dba ","ALL");

			/* specific names with special case */
			string = Replace(string,"Mcc","McC","ALL");
			string = Replace(string,"Mcd","McD","ALL");
			string = Replace(string,"Mch","McH","ALL");
			string = Replace(string,"Mcg","McG","ALL");
			string = Replace(string,"Mci","McI","ALL");
			string = Replace(string,"Mck","McK","ALL");
			string = Replace(string,"Mcl","McL","ALL");
			string = Replace(string,"Mcm","McM","ALL");
			string = Replace(string,"Mcn","McN","ALL");
			string = Replace(string,"Mcp","McP","ALL");

			/* adding punctuation */
			string = Replace(string," Inc",", Inc","ALL");
			string = Replace(string,"Ft ","Ft. ","ALL");
			string = Replace(string,"St ","St. ","ALL");
			string = Replace(string,"Mt ","Mt. ","ALL");

			/* U.S. state abbreviations */
			string = Replace(string, " Ak ", " AK ", " ALL ");
			string = Replace(string, " As ", " AS ", " ALL ");
			string = Replace(string, " Az ", " AZ ", " ALL ");
			string = Replace(string, " Ar ", " AR ", " ALL ");
			string = Replace(string, " Ca ", " CA ", " ALL ");
			string = Replace(string, " Co ", " CO ", " ALL ");
			string = Replace(string, " Ct ", " CT ", " ALL ");
			string = Replace(string, " De ", " DE ", " ALL ");
			string = Replace(string, " Dc ", " DC ", " ALL ");
			string = Replace(string, " Fl ", " FL ", " ALL ");
			string = Replace(string, " Ga ", " GA ", " ALL ");
			string = Replace(string, " Gu ", " GU ", " ALL ");
			string = Replace(string, " Hi ", " HI ", " ALL ");
			string = Replace(string, " Id ", " ID ", " ALL ");
			string = Replace(string, " Il ", " IL ", " ALL ");
			string = Replace(string, " In ", " IN ", " ALL ");
			string = Replace(string, " Ia ", " IA ", " ALL ");
			string = Replace(string, " Ks ", " KS ", " ALL ");
			string = Replace(string, " Ky ", " KY ", " ALL ");
			string = Replace(string, " La ", " LA ", " ALL ");
			string = Replace(string, " Me ", " ME ", " ALL ");
			string = Replace(string, " Md ", " MD ", " ALL ");
			string = Replace(string, " Mh ", " MH ", " ALL ");
			string = Replace(string, " Ma ", " MA ", " ALL ");
			string = Replace(string, " Mi ", " MI ", " ALL ");
			string = Replace(string, " Fm ", " FM ", " ALL ");
			string = Replace(string, " Mn ", " MN ", " ALL ");
			string = Replace(string, " Ms ", " MS ", " ALL ");
			string = Replace(string, " Mo ", " MO ", " ALL ");
			string = Replace(string, " Mt ", " MT ", " ALL ");
			string = Replace(string, " Ne ", " NE ", " ALL ");
			string = Replace(string, " Nv ", " NV ", " ALL ");
			string = Replace(string, " Nh ", " NH ", " ALL ");
			string = Replace(string, " Nj ", " NJ ", " ALL ");
			string = Replace(string, " Nm ", " NM ", " ALL ");
			string = Replace(string, " Ny ", " NY ", " ALL ");
			string = Replace(string, " Nc ", " NC ", " ALL ");
			string = Replace(string, " Nd ", " ND ", " ALL ");
			string = Replace(string, " Mp ", " MP ", " ALL ");
			string = Replace(string, " Oh ", " OH ", " ALL ");
			string = Replace(string, " Ok ", " OK ", " ALL ");
			string = Replace(string, " Or ", " OR ", " ALL ");
			string = Replace(string, " Pw ", " PW ", " ALL ");
			string = Replace(string, " Pa ", " PA ", " ALL ");
			string = Replace(string, " Pr ", " PR ", " ALL ");
			string = Replace(string, " Ri ", " RI ", " ALL ");
			string = Replace(string, " Sc ", " SC ", " ALL ");
			string = Replace(string, " Sd ", " SD ", " ALL ");
			string = Replace(string, " Tn ", " TN ", " ALL ");
			string = Replace(string, " Tx ", " TX ", " ALL ");
			string = Replace(string, " Ut ", " UT ", " ALL ");
			string = Replace(string, " Vt ", " VT ", " ALL ");
			string = Replace(string, " Va ", " VA ", " ALL ");
			string = Replace(string, " Vi ", " VI ", " ALL ");
			string = Replace(string, " Wa ", " WA ", " ALL ");
			string = Replace(string, " Wv ", " WV ", " ALL ");
			string = Replace(string, " Wi ", " WI ", " ALL ");
			string = Replace(string, " Wy ", " WY ", " ALL ");

			return string;
		}
		
		/**
		* Returns a string with words capitalized for a title.
		* Modified by Ray Camden to include var statements.
		* Modified by James Moberg to use structs, added more words, and reset-to-all-caps list.
		* 
		* @param initText      String to be modified. (Required)
		* @return Returns a string. 
		* @author Ed Hodder (ed.hodder@bowne.com) 
		* @version 3, October 7, 2011 
		*/
		function capFirstTitle(initText){
		   var j = 1; var m = 1;
		   var doCap = true;
		   var tempVar = "";
		
		   /* Make each word in text an array variable */
		   var Words = ListToArray(LCase(trim(initText)), " ");
		   var excludeWords = structNew();
		   var ResetToALLCAPS = structNew();
		
		   /* Words to never capitalize */
		   tempVar =  ListToArray("a,above,after,ain't,among,an,and,as,at,below,but,by,can't,don't,for,from,from,if,in,into,it's,nor,of,off,on,on,onto,or,over,since,the,to,under,until,up,with,won't");
		   for(j=1; j LTE (ArrayLen(tempVar)); j = j+1){
				   excludeWords[tempVar[j]] = 0;
		   }
		
		   /* Words to always capitalize */
		   tempVar = ListToArray("II,III,IV,V,VI,VII,VIII,IX,X,XI,XII,XIII,XIV,XV,XVI,XVII,XVIII,XIX,XX,XXI");
		   for(j=1; j LTE (ArrayLen(tempVar)); j = j+1){
				   ResetToALLCAPS[tempVar[j]] = 0;
		   }
		
		   /* Check words against exclude list */
		   for(j=1; j LTE (ArrayLen(Words)); j = j+1){
			   doCap = true;
			   /* Word must be less than four characters to be in the list of excluded words */
			   if(LEN(Words[j]) LT 4){
					   if(structKeyExists(excludeWords,Words[j])){ doCap = false; }
			   }
			   /* Capitalize hyphenated words */
			   if(ListLen(trim(Words[j]),"-") GT 1){
				   for(m=2; m LTE ListLen(Words[j], "-"); m=m+1){
					   tempVar = ListGetAt(Words[j], m, "-");
					   tempVar = UCase(Mid(tempVar,1, 1)) & Mid(tempVar,2, LEN(tempVar)-1);
					   Words[j] = ListSetAt(Words[j], m, tempVar, "-");
				   }
			   }
		
			   /* Automatically capitalize first and last words */
			   if(j eq 1 or j eq ArrayLen(Words)){ doCap = true; }
		
			   /* Capitalize qualifying words */
			   if(doCap){ Words[j] = UCase(Mid(Words[j],1, 1)) & Mid(Words[j],2, LEN(Words[j])-1); }
			   if (structKeyExists(ResetToALLCAPS, Words[j])) Words[j] = ucase(Words[j]);
		   }
		   return ArrayToList(Words, " ");
		}
</cfscript>
			
</cfcomponent>			