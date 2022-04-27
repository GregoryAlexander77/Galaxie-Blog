<cfcomponent displayname="JSoup" hint="Manipulate the DOM with ColdFusion" name="JSoup">
	
	<!--- Important note: if you receive a 'The xxx method was not found', either your not using the wrong object (ie the Jsoup parent object to use the clean method) or the arguments that you supplied to the method are incorrect (for example the method expects an array or .html(). This error message is not the most descriptive unfortunately. --->
	
	<cffunction name="loadJSoup" access="public" output="false" returntype="any" hint="Loads the JSoup library">
    	
		<!--- The JavaLoader already has initilized the jSoup lib within the application.cfc template. The class that we need in the jar is org.jsoup.Jsoup. There are no other methods needed to initialize. --->
		<cfset JSoupObj = application.jsoupJavaloader.create("org.jsoup.Jsoup")>
		
		<!--- Return the JSoup class. --->
		<cfreturn JSoupObj>
		
	</cffunction>
			
	<cffunction name="htmlUnescape" access="public" output="false" returntype="any" hint="Loads the JSoup library">
    	<cfargument name="str" type="string" required="yes" hint="Pass in the str to unescape">
		<!--- Init JSoup --->
		<cfset JSoupObj = loadJSoup()>
			
		<cfif len(arguments.str)>
			<!--- Parse the string and return the text --->
			<cfset newStr = JSoupObj.parse(arguments.str).html()>
		<cfelse>
			<!--- Return the original post if the iframes were not found. --->
			<cfset newStr = arguments.str>
		</cfif>
			
		<!--- Return the str. --->
		<cfreturn newStr>
		
	</cffunction>
			
	<cffunction name="loadSiteByUrl" access="public" output="false" returntype="any" hint="Load a site by the URL">
		<cfargument name="URL" type="string" required="yes" hint="Pass in the URL">
    	
		<!--- Init JSoup --->
		<cfset JSoupObj = loadJSoup()>
		<!--- Load the site --->
		<cfset SiteJSoupObj = JSoupObj.connect("#arguments.URL#").get()>
			
		<!--- Return the DOM. --->
		<cfreturn SiteJSoupObj>
		
	</cffunction>
			
	<cffunction name="removeGalleryIframes" access="public" output="true" returntype="any" 
			hint="This function will remove iframes that are generated for gallery preview for the tinymce editor and replace them with inline gallery code. This function is used to inspect the post contents when they are posted to the server to remove the iframes and store the inline code in the database.">
		<cfargument name="post" type="string" required="yes" hint="Pass in the content of the post">
			
		<cfparam name="newPostContent" default="">
	
		<!--- Instantiate the Render.cfc. This will be used to build the HTML gallery. --->
		<cfobject component="#application.rendererComponentPath#" name="RendererObj">

		<!--- Init JSoup --->
		<cfset JSoupObj = loadJSoup()>
			
		<cfif len(arguments.post)>
	
			<!--- Load the post --->
			<cfset PostJSoupObj = JSoupObj.parse(arguments.post)>

			<!--- Select div's with a data-type of gallery. --->
			<cfset GalleryObj = PostJSoupObj.select("div[data-type=gallery]")>	
			<!---<cfdump var="#GalleryObj#" label="GalleryObj"><br/>--->
			<!---<cfoutput>#GalleryObj.html()#</cfoutput>--->

			<!--- Loop through all of the gallery jsoup objects. --->
			<cfloop from="1" to="#arrayLen(GalleryObj)#" index="i">
				<!---<cfoutput>i: #i#<br/></cfoutput>--->

				<!--- Determine if this gallery div contains an iframe. --->
				<cfif GalleryObj[i].html() contains '<iframe'>
					
					<!--- Get the data-id. This is the galleryId that we need to regenerate the HTML --->
					<cfset galleryId = GalleryObj[i].attr("data-id")>
					<!---<cfoutput>galleryId: #galleryId#<br></cfoutput>--->
						
					<!--- Grab the HTML --->
					<cfset originalGalleryHtml = GalleryObj[i].html()>
					
					<!--- Isolate the code with the iframe --->
					<cfset GalleryIframeObj = GalleryObj[i].select("iframe")>
						
					<!--- Now that we have the galleryId and have removed the iframes, pass it to the database to construct the new gallery code. This function will generate the HTML for this galleryId. --->
					<cfset newGalleryHtml = RendererObj.renderImageGalleryFromDb(galleryId, true)>
					<!---newGalleryHtml: <cfoutput>#newGalleryHtml#</cfoutput>--->
						
					<!--- Set the GalleryObj's HTML. This will *replace* whatever is already there (ie the iframes with the content) with the new HTML that we generated from the database. --->
					<cfset setHtml = GalleryObj[i].html(newGalleryHtml)>
						
					<!--- At the end of the loop return the html from the PostJSoupObj object. It is important to not that everytime we modify any child object of the PostJSoupObj using JSoup, we are modifying the parent PostJSoupObj object as well. --->
					<cfif i eq arrayLen(GalleryObj)>
						<cfset newPostContent = PostJSoupObj.html()>
					</cfif>
						
				<cfelse>
					<!---There is no iframe here, return the html--->
					<cfset newPostContent = PostJSoupObj.html()>
				</cfif>
						
			</cfloop>
						
			<!--- Return the original post if iframes were not found. --->
			<cfif newPostContent eq ''>
				<cfset newPostContent = arguments.post>
			</cfif>
				
			<!--- Were done! We removed the galleries contained within the iframes and replaced it with inline code. --->
			<!--- Return new code. --->
			<cfreturn newPostContent>
			
		</cfif>
		
	</cffunction>
					
	<cffunction name="getTagFromPost" access="public" output="false" returntype="any" 
			hint="Generic function that will return content between to tags in a post.">
		<cfargument name="post" type="string" required="yes" hint="provide the post content">
		<cfargument name="tag" type="string" required="yes" default="" hint="Specify the tag that you are trying to get">
    	
		<!--- Init JSoup --->
		<cfset JSoupObj = loadJSoup()>
		<!--- Load the post --->
		<cfset PostJSoupObj = JSoupObj.parse( arguments.post )>
			
		<!--- Get the data between the tags --->
		<cfset TagJSoupObj = PostJSoupObj.getElementsByTag(arguments.tag)>
		
		<!--- Return the content. --->
		<cfreturn TagJSoupObj.html()>
		
	</cffunction>
			
	<cffunction name="removeTagFromPost" access="public" output="false" returntype="any" 
			hint="Generic function that will remove the content between to tags in a post.">
		<cfargument name="post" type="string" required="yes" hint="provide the post content">
		<cfargument name="tag" type="string" required="yes" default="" hint="Specify the tag that you are trying to get">
    	
		<!--- Init JSoup --->
		<cfset JSoupObj = loadJSoup()>
		<!--- Load the post --->
		<cfset PostJSoupObj = JSoupObj.parse( arguments.post )>
			
		<!--- Get the data between the tags --->
		<cfset PostJSoupObj.select(arguments.tag).remove()>
		
		<!--- Return the content. --->
		<cfreturn PostJSoupObj.html()>
		
	</cffunction>
			
	<cffunction name="getLdJsonFromPost" access="public" output="false" returntype="any" hint="Returns the LD Json string that may be in a post">
		<cfargument name="post" type="string" required="yes" hint="provide the post content">
		<cfargument name="action" type="string" required="no" default="get" hint="Either get or remove">
    	
		<!--- Init JSoup --->
		<cfset JSoupObj = loadJSoup()>
		<!--- Load the post --->
		<cfset PostJSoupObj = JSoupObj.parse( arguments.post )>
			
		<!--- Get the data between the postData tags --->
		<cfset LdJsonJSoupObj = PostJSoupObj.getElementsByTag('postData')>
			
		<cfif arguments.action eq 'get'>
			<cfset returnString = LdJsonJSoupObj.html()>
		<cfelseif arguments.action eq 'remove'>
			<cfset returnString = true>
		</cfif>
		
		<!--- Return sting. --->
		<cfreturn returnString>
		
	</cffunction>
			
	<cffunction name="getCodeBlocksFromPost" access="public" output="true" returntype="any" 
			hint="Returns or removes the string between code blocks that may be in a post.">
		<cfargument name="post" type="string" required="yes" hint="provide the post content">
		<cfargument name="action" type="string" required="no" default="get" hint="Either get or remove">
			
		<cfparam name="returnStr" default="">
    	
		<!--- Init JSoup --->
		<cfset JSoupObj = loadJSoup()>
		<!--- Load the post --->
		<cfset PostJSoupObj = JSoupObj.parse( arguments.post )>
			
		<cfif arguments.action eq 'get'>
			
			<!--- Get the data between the postData tags --->
			<cfset JSoupCodeObj = PostJSoupObj.getElementsByTag('code')>
			<cfset returnStr = JSoupCodeObj.html()>
				
		<cfelseif arguments.action eq 'remove'>
			
			<!--- Select and remove the code elements --->
			<cfset PostJSoupObj.select("code").remove()>
			<!--- Return nothing --->		
				
		</cfif>

		<!--- Return the string. --->
		<cfreturn returnStr>
		
	</cffunction>
				
	<cffunction name="renderCodeBlocksForPrism" access="public" output="true" returntype="any" 
			hint="Renders the content between code tags for prism">
		<cfargument name="post" type="string" required="yes" hint="provide the post content">
			
		<cfparam name="codeBlocks" default="">
			
		<!--- Note: unfortunately find and replace CF operations won't work here consistently with the code retrieved using jSoup so we need to create a new code element and populate them instead of replacing the code in the current code elements. JSoup changes the code by normailizing it and will add closing tags for any unescaped tags and will add stuff like <cfset x = 'foo'></cfset> --->
			
		<cfset debug = false>
			
		<!--- Instantiate the Render.cfc. We need to get to the simpleHtmlEscape function. --->
		<cfobject component="#application.rendererComponentPath#" name="RendererObj">
			
		<!--- Init the Whitelist object. We need this for the clean method later on --->
		<cfset WhiteListObj = application.jsoupJavaloader.create("org.jsoup.safety.Whitelist")>
		<!--- Init the parser object. We will use this to parse ColdFusion tags without Jsoup normalizing the CF code and ending end tags (ie <cfset x = 'foo'></cfset>) --->
		<cfset ParserObj = application.jsoupJavaloader.create("org.jsoup.parser.Parser")>
		
		<!--- Init JSoup --->
		<cfset JSoupObj = loadJSoup()>
		<!--- Load the post. To minimize the normalization of the code, we are using the XML parser --->
		<cfset PostJSoupObj = JSoupObj.parse( arguments.post, "", ParserObj.xmlParser() )>
			
		<!--- Create a new var holding the post content to work with --->
		<cfset cleanedPost = arguments.post>
			
		<!--- Select the code --->
		<cfset JSoupCodeObj = PostJSoupObj.select('code')>
		
		<!--- Loop through all of the code elements (there can be one or more) --->
		<cfif arrayLen(JSoupCodeObj)>
			<!--- Loop through the array and set the mediaId --->
			<cfloop from="1" to="#arrayLen(JSoupCodeObj)#" index="i">
				<!--- Get the original code. --->
				<cfset originalCode = JSoupCodeObj[i].html()>
				<cfif debug>
					<cfoutput>originalCode: #originalCode#</cfoutput><br/>
				</cfif>
				<!--- Use CF to eliminate the opening and closing brackets in the code block. We don't want to use the Jsoup clean function, we just want to remove the opening and closing tags and want to have full control here. --->
				<cfset escapedCode = RendererObj.simpleHtmlEscape(originalCode)>
				<cfif debug>
					<cfoutput>escapedCode: #escapedCode#</cfoutput><br/>
				</cfif>
				<!--- Set the escaped code as the content in this code block --->
				<cfset setNewCode = JSoupCodeObj[i].html(escapedCode)>
				<cfif debug>
					<cfoutput>setNewCode: #setNewCode#</cfoutput><br/>
				</cfif>
			</cfloop>
					
			<cfif debug>
				<cfoutput>PostJSoupObj.html(): #PostJSoupObj.html()#</cfoutput><br/>
			</cfif>
			<!--- Fix the JSoup adding closing tags with CF code. --->
			<cfset codeBlocks = this.fixJsoupCFDefects(PostJSoupObj.html())>
			<cfif debug>
				<cfoutput>codeBlocks (with escaped closing tags): #codeBlocks#</cfoutput><br/>
			</cfif>
					
		</cfif><!---<cfif arrayLen(JSoupCodeObj)>--->
		
		<!--- Return the html. --->
		<cfreturn codeBlocks>
		
	</cffunction>
					
	<cffunction name="fixJsoupCFDefects" access="public" output="true" returntype="any" 
			hint="Removes the ColdFusion closing tags that are added with Jsoup">
		<cfargument name="post" type="string" required="yes" hint="provide the post content">
			
		<cfset fixedCode = arguments.post>
			
		<!--- Fix code that has not been escaped with &lt;. --->
		<cfset fixedCode = replaceNoCase(fixedCode, '</cfset>', '', 'all')>
		<cfset fixedCode = replaceNoCase(fixedCode, '</cfabort>', '', 'all')>
		<cfset fixedCode = replaceNoCase(fixedCode, '</cfargument>', '', 'all')>
		<cfset fixedCode = replaceNoCase(fixedCode, '</cfreturn>', '', 'all')>
		<cfset fixedCode = replaceNoCase(fixedCode, '</cfparam>', '', 'all')>
		<cfset fixedCode = replaceNoCase(fixedCode, '</cfreturn>', '', 'all')>
		<cfset fixedCode = replaceNoCase(fixedCode, '</cfproperty>', '', 'all')>
		<cfset fixedCode = replaceNoCase(fixedCode, '</script>', '', 'all')>
			
		<!--- Fix code that has... --->
		<cfset fixedCode = replaceNoCase(fixedCode, '&lt;/cfset&gt;', '', 'all')>
		<cfset fixedCode = replaceNoCase(fixedCode, '&lt;/cfabort&gt;', '', 'all')>
		<cfset fixedCode = replaceNoCase(fixedCode, '&lt;/cfargument&gt;', '', 'all')>
		<cfset fixedCode = replaceNoCase(fixedCode, '&lt;/cfreturn&gt;', '', 'all')>
		<cfset fixedCode = replaceNoCase(fixedCode, '&lt;/cfparam&gt;', '', 'all')>
		<cfset fixedCode = replaceNoCase(fixedCode, '&lt;/cfreturn&gt;', '', 'all')>
		<cfset fixedCode = replaceNoCase(fixedCode, '&lt;/cfproperty&gt;', '', 'all')>
		<cfset fixedCode = replaceNoCase(fixedCode, '&lt;/script&gt;', '', 'all')>
		
		<!--- Return the code without the closing tags. --->
		<cfreturn fixedCode>
		
	</cffunction>
			
	<cffunction name="getAttachScriptsFromPost" access="public" output="true" returntype="any" 
			hint="Returns the string between the attachScript blocks that may be in a post.">
		<cfargument name="post" type="string" required="yes" hint="provide the post content">
		<cfargument name="action" type="string" required="no" default="get" hint="Either get or remove">
    	
		<!--- Init JSoup --->
		<cfset JSoupObj = loadJSoup()>
		<!--- Load the post --->
		<cfset JSoupPostObj = JSoupObj.parse( arguments.post )>
		<!--- Get the scripts --->
		<cfset JSoupDocObj = JSoupPostObj.getElementsByTag('code')>
		<!--- Don't do anything if it's code --->
		<cfif not findNoCase('<code>', JSoupDocObj.html()) and not findNoCase('</code>', JSoupDocObj.html())>
			<cfif arguments.action eq 'get'>
				<!--- Get the data between the postData tags --->
				<cfset JSoupDocObj = JSoupPostObj.getElementsByTag('code')>
			<cfelseif arguments.action eq 'remove'>
				<!--- Select and remove the code elements --->
				<cfset JSoupDocObj = JSoupPostObj.select("code").remove()>
			</cfif>
		<cfelse>
			<cfset JSoupDocObj = ''>
		</cfif>
		
		<!--- Return the html. --->
		<cfreturn JSoupDocObj.html()>
		
	</cffunction>
			
	<cffunction name="setPostEntryImageWithMediaId" access="public" output="false" returntype="any" 
		hint="Sets the data-mediaid on the entry image in order to tie the image to the image stored in the database by the Media.MediaId">
		<cfargument name="post" type="string" required="yes" hint="provide the post content">
		<cfargument name="imageUrl" type="string" required="yes" hint="Provide the url to the image.">
		<cfargument name="mediaId" type="string" required="yes" hint="Pass in the Media.MediaId">
    	
		<!--- Init JSoup --->
		<cfset JSoupObj = loadJSoup()>
		<!--- Load the post --->
		<cfset PostJSoupObj = JSoupObj.parse( arguments.post )>
			
		<!--- Get the image. --->
		<cfset PostImageJSoupObj = PostJSoupObj.getElementsByAttributeValue( 'data-src', arguments.imageUrl )>
		<!--- Set the mediaId on the image (data-mediaid=). Note: this will modify the PostSoupObj and insert the mediaid. --->
		<cfif arrayLen(PostImageJSoupObj)>
			<!--- Loop through the array and set the mediaId --->
			<cfloop from="1" to="#arrayLen(PostImageJSoupObj)#" index="i">
				<cfset void = PostImageJSoupObj[i].attr("data-mediaid", arguments.mediaId)>
			</cfloop>
		</cfif>
			
		<!--- Return the new post code --->
		<cfreturn PostJSoupObj.html()><!--- PostJSoupObj.html()--->
		
	</cffunction>
			
	<cffunction name="jsoupSanitize" access="public" output="false" returntype="any" 
		hint="Sanitizes a string in order to prevent any scripting hacks">
		<cfargument name="str" type="string" required="yes" hint="provide the string to sanitize">
    	
		<!--- Init JSoup --->
		<cfset JSoupObj = loadJSoup()>
		<!--- Init the Whitelist object --->
		<cfset WhiteListObj = application.jsoupJavaloader.create("org.jsoup.safety.Whitelist")>	
		
		<!--- Sanitize the string. Note: this method is in the JSoup parent object. --->
		<cfset sanitizedStr = JSoupObj.clean(arguments.str, WhitelistObj.relaxed())>
			
		<!--- Return the new string --->
		<cfreturn sanitizedStr>
		
	</cffunction>
			
	<cffunction name="jsoupConvertHtmlToText" access="public" output="true" returntype="any" 
		hint="Converts HTML to text. Used in the WebVTT tinymce editor.">
		<cfargument name="html" type="string" required="yes" hint="provide the html to convert">
    	
		<!--- Init JSoup --->
		<cfset JSoupObj = loadJSoup()>

		<!--- Parse the input and create a new document --->
		<cfset JSoupDocObj = JSoupObj.parse(arguments.html)>
		<!--- Set pretty print to false in the output settings so that new lines (\\n) are not removed --->
		<cfset outputSettings = JSoupDocObj.outputSettings().prettyPrint(false)>
		<!--- The whole text should retain the new lines--->
		<cfset text = JSoupDocObj.wholeText()>
			
		<!--- Return the new string --->
		<cfreturn text>
		
	</cffunction>
			
	<cffunction name="jsoupConvertHtmlToText2" access="public" output="true" returntype="any" 
			hint="Converts HTML to text. I gave up on this as it was taking too long to figure out- but I am keeping it to revisit in the future">
		<cfargument name="html" type="string" required="yes" hint="provide the html to convert. See https://www.baeldung.com/jsoup-line-breaks. Also see https://github.com/bennadel/Best-Of-ColdFusion-10/blob/master/wwwroot/model/DOMWrapper.cfc">
			
		<!--- THIS IS NOT USED YET! --->
			
		<cfset newLine = createObject("java", "java.lang.System").getProperty("line.separator")>
    	
		<!--- Init JSoup --->
		<cfset JSoupObj = loadJSoup()>
		<!--- Init the Whitelist object --->
		<cfset WhiteListObj = application.jsoupJavaloader.create("org.jsoup.safety.Whitelist")>	
			
		<!--- Parse the input and create a new document --->
		<cfset JSoupDocObj = JSoupObj.parse(arguments.html)>
		<!--- Set pretty print to false in the output settings so that new lines (\\n) are not removed. Note: after calling the output settings, this will be turned into a document here and the normal JSoup methods will not be exposed. --->
		<cfset OutputSettingsObj = JSoupDocObj.outputSettings().prettyPrint(false)>
		<!--- Get all of the HTML line breaks and replace them with new line chars --->
		<cfset JSoupDocObj.select("br").before(newLine)>
		<cfset JSoupDocObj.select("p").before(newLine)>
		<!--- Keep the current line breaks, but remove any duplicates --->
		<cfset str = JSoupDocObj.html().replaceAll("\\\\newLine", newLine)>
		<!--- Now that we have new lines, create a new JSoup object to get the whole text. I can't figure out how to get the Document.Output class to work in order to use the prettyPrint(false) statement to clean the string unfortunately, but the wholeText should preserve the new lines --->
		<cfset NewJSoupDocObj = JSoupObj.parse(str)>
		<cfset text = JSoupDocObj.wholeText()>
			
		<!--- Return the new string --->
		<cfreturn text>
		
	</cffunction>

</cfcomponent>
