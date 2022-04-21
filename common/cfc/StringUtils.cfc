<cfcomponent displayname="StringUtils" hint="String utilities" name="StringUtils">
	
	<!---******************************************************************************************************
		String Utils 
	******************************************************************************************************--->
	
	<cffunction name="trimStr" returntype="string" output="false">
		<cfargument name="s" type="string" required="yes">
		<cfreturn Trim(Replace(s, chr(160), " ", "ALL"))>
	</cffunction>
			
	<cffunction name="replaceStringInContent" access="public" output="true" returntype="string" 
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
				
	<cffunction name="removeTag" access="public" output="true" returntype="string" 
			hint="Removes everything between to tags. Used by the search results and rss templates. You should use this instead of the Jsoup functions to remove stuff between tags when you don't want JSoup to format the html including adding end tags for ColdFusion tags (ie <cfset x = 'foo'></cfset>)">

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
			<cfcatch type="any">
				<cfset strippedContent = arguments.str>
			</cfcatch>
		</cftry>

		<!--- Return new post content --->
		<cfreturn strippedContent>

	</cffunction>
				
	<cffunction name="removeXmlDirective" access="public" output="true" returntype="string" 
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
			
	<cffunction name="getTextFromBody" access="public" output="true" returntype="string" hint="Removes everything between postData tags and the HTML found in the post content. Used by the search results template.">

		<cfargument name="postContent" required="yes" hint="The post content is typically 'RendererObj.renderBody(body,enclosure)'.">
			
		<!--- Remove the postData tag that has the directives --->
		<cfset removePostData = this.removeTag(str=arguments.postContent, tag='postData')>
		<!--- Now, remove the xml and html from result. --->
		<cfset newbody = reReplace(removePostData, "<.*?>", "", "all")>
		<cfset newBody = reReplaceNoCase(newbody,"<[^>]*>","","all")>

		<!--- Return new post content --->
		<cfreturn newbody>

	</cffunction>
			
</cfcomponent>			