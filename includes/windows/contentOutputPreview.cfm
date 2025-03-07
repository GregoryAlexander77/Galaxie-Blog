<cfsilent>
<!--- Debug flag. This will print the interfaceId along with the args send via the URL --->
<cfset debug = 0>

<!--- Get the current theme --->
<cfset selectedThemeAlias= trim(application.blog.getSelectedThemeAlias())>
<!--- Get the Theme data for this theme. --->
<cfset getTheme = application.blog.getTheme(themeAlias=selectedThemeAlias)>
<!--- Get the Kendo theme. --->
<cfset kendoTheme = getTheme[1]["KendoTheme"]>
<!--- Also set the selectedTheme var for the menu. This should always be false here --->
<cfset selectedTheme = false>
<!--- Get the current theme Id --->
<cfset themeId = getTheme[1]["ThemeId"]>
<!--- Get the body font --->
<cfset themeBodyFont = getTheme[1]["Font"]>
<!--- Is this a dark theme (such as Orion)? --->
<cfset darkTheme = getTheme[1]["DarkTheme"]>
	
<!--- Instantiate the default content object --->
<cfobject component="#application.defaultContentObjPath#" name="DefaultContentObj">
<!--- Instantiate the sting utility object --->
<cfobject component="#application.stringUtilsComponentPath#" name="StringUtilsObj">
	
<cfif application.deferScriptsAndCss>
	<!--- Defers the loading of the script and css using the deferjs library. --->
	<cfset scriptTypeString = "deferjs">
<cfelse>
	<cfset scriptTypeString = "text/javascript">
</cfif>
	
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
	
<!--- Instantiate the HTMLUtils cfc. This is used to create alternating table rows --->
<cfobject component="#application.htmlUtilsComponentPath#" name="HtmlUtilsObj">
<!--- Instantiate the sting utility object. We are using this to remove empty strings from the code preview. --->
<cfobject component="#application.stringUtilsComponentPath#" name="StringUtilsObj">
<!--- Instantiate the default content object to get the preview --->
<cfobject component="#application.defaultContentObjPath#" name="DefaultContentObj">
</cfsilent>
<cfif debug>
	<cfdump var="#URL#">
</cfif>
<!--- This window handles many interfaces. Pass in the interfaceId. Other arguments may include the URL.optArgs, URL.otherArgs, and URL.otherArgs1. See the createAdminInterface javascript function in the /includes/templates/blogJsContent.cfm template for more information. --->
<cfswitch expression="#URL.otherArgs#">
	
<!---//***********************************************************************************************
						Header with Navigation Menu
//************************************************************************************************--->
<cfcase value="compositeHeaderDesktop">
	<!--- Output the content and remote any empty lines --->
	<cfoutput>#StringUtilsObj.removeEmptyLinesInStr(DefaultContentObj.getDefaultContentPreview(getTheme,URL.otherArgs))#</cfoutput>
</cfcase>
									   
</cfswitch>
