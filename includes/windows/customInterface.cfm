<html>
<cfsilent>
<!--- Debug flag. This will print the interfaceId along with the args send via the URL --->
<cfset debug = 0>
	
<!--- Get the data --->
<cfset getCustomWindowContent = application.blog.getCustomWindowContentById(URL.interfaceId)>

<!--- Get the current theme --->
<cfset selectedThemeAlias= trim(application.blog.getSelectedThemeAlias())>
<!--- Get the Theme data for this theme. --->
<cfset getTheme = application.blog.getTheme(themeAlias=selectedThemeAlias)>
<!--- Get the Kendo theme. --->
<cfset kendoTheme = getTheme[1]["KendoTheme"]>
<!--- Get the current theme Id --->
<cfset themeId = getTheme[1]["ThemeId"]>
<!--- Get the body font --->
<cfset themeBodyFont = getTheme[1]["Font"]>
<!--- Is this a dark theme (such as Orion)? --->
<cfset darkTheme = getTheme[1]["DarkTheme"]>
<!--- Instantiate the HTMLUtils cfc. This is used to create alternating table rows --->
<cfobject component="#application.htmlUtilsComponentPath#" name="HtmlUtilsObj">
	
<!--- Get client properties. This will be used to set the interfaces depending upon the screen size --->
<cftry>
	<cfset screenHeight = cookie['screenHeight']>
	<cfset screenWidth = cookie['screenWidth']>
	<cfcatch type="any">
		<cfset screenHeight = 9999>
		<cfset screenWidth = 9999>	   
	</cfcatch>
</cftry>
		
<!--- Determine if we should show the interface for small screens --->
<cfif session.isMobile or session.isTablet or screenWidth lt 1280>
	<cfset smallScreen = true>
<cfelse>
	<cfset smallScreen = false>
</cfif>
</cfsilent>
		
<style>
	/* Constraining images to a max width so that they don't  push the content containers out to the right */
	.entryImage img {
		max-width: 100%;
		height: auto; 
		/* Subtle drop shadow on the image layer */
		box-shadow: 0 4px 8px 0 rgba(0, 0, 0, 0.2), 0 6px 20px 0 rgba(0, 0, 0, 0.19);
	}

	.entryMap {
		height: 564px;
		width: 100%; 
		/* Subtle drop shadow on the layer */
		box-shadow: 0 4px 8px 0 rgba(0, 0, 0, 0.2), 0 6px 20px 0 rgba(0, 0, 0, 0.19);
	}
	
	/* FancyBox Thumnails */
	.thumbnail {
		position: relative;

		width: 225px;
		height: 128px;
		padding: 5px;
		padding-top: 5px;
		padding-left: 5px;
		padding-right: 5px;
		padding-bottom: 5px;
		box-shadow: 0 2px 4px 0 rgba(0, 0, 0, 0.2), 0 4px 8px 0 rgba(0, 0, 0, 0.19);
		overflow: hidden;
	}

	.thumbnail img {
		position: absolute;
		left: 50%;
		top: 50%;
		height: 100%;
		width: auto;
		-webkit-transform: translate(-50%,-50%);
		  -ms-transform: translate(-50%,-50%);
			  transform: translate(-50%,-50%);
	}

	.thumbnail img.portrait {
	  width: 100%;
	  height: auto;
	}

	/* See https://aaronparecki.com/2016/08/13/4/css-thumbnails */
	.squareThumbnail {
		/* set the desired width/height and margin here */
		width: 128px;
		height: 128px;

		margin-right: 1px;
		position: relative;
		overflow: hidden;
		display: inline-block;
	}

	.squareThumbnail img {
		position: absolute;
		left: 50%;
		top: 50%;
		height: 100%;
		width: auto;
		-webkit-transform: translate(-50%,-50%);
		  -ms-transform: translate(-50%,-50%);
			  transform: translate(-50%,-50%);
	}
	.squareThumbnail img.portrait {
		width: 100%;
		height: auto;
	}
</style>

<cfif debug>	
	Debugging:<br/>
	<!---<cfdump var="#session#">--->
	<!---<cfdump var="#cgi#">--->
	<cfdump var="#getCustomWindowContent#">
	<cfdump var="#URL#">
	<cfoutput>
	screenWidth: #screenWidth#<br/>
	URL.interfaceId: #URL.interfaceId#
	URL.optArgs: #URL.optArgs#<br/>
	smallScreen: #smallScreen#<br/>
	CfincludePath: #getCustomWindowContent[1]['CfincludePath']#<br/>
	</cfoutput>
</cfif>
	
<!--- Display the custom window content. This will either be from the content or a cfinclude --->
<cfif arrayLen(getCustomWindowContent)>
	<!--- Set our vars --->
	<!--- Using a cfinclude --->
	<cfset customWindowId = getCustomWindowContent[1]["CustomWindowContentId"]>
	<cfset cfincludePath = getCustomWindowContent[1]["CfincludePath"]>
	<!--- TinyMce content --->
	<cfset content = getCustomWindowContent[1]["Content"]>
			
	<cfif len(cfincludePath)>
		<!--- Include the template. The URL.interfaceId is the windowId. --->
		<cfinclude template="#cfincludePath#">
	<cfelseif len(content)>
		<!--- Include the TinyMce content --->
		<cfoutput>#content#</cfoutput>
	</cfif><!---<cfif len(cfincludePath)>--->
</cfif><!---<cfif arrayLen(getCustomWindowContent)>--->
	
</html>
