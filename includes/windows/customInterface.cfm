<html>
<cfsilent>
<!--- Debug flag. This will print the interfaceId along with the args send via the URL --->
<cfset debug = false>
	
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

<cfif debug>	
	Debugging:<br/>
	<!---<cfdump var="#session#">--->
	<!---<cfdump var="#cgi#">--->
	<cfdump var="#getCustomWindowContent#">
	<cfdump var="#URL#">
	<cfoutput>
	screenWidth: #screenWidth#<br/>
	URL.interfaceId: #URL.interfaceId#
	URL.optArgs: #URL.optArgs# 
	smallScreen: #smallScreen#<br/>
	</cfoutput>
</cfif>
	
<!--- Display the custom window content. This will either be from the content or a cfinclude --->
<cfif arrayLen(getCustomWindowContent)>
	<cfif len(getCustomWindowContent[1]["CfincludePath"])>
		<cfinclude template="#getCustomWindowContent[1]['CfincludePath']#">
	<cfelseif len(getCustomWindowContent[1]["Content"])>
		<cfoutput>#getCustomWindowContent[1]["Content"]#</cfoutput>
	</cfif>	
</cfif><!---<cfif arrayLen(getCustomWindowContent)>--->
	
</html>
