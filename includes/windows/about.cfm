<cfsilent>	
<!--- Get the current theme --->
<cfset selectedThemeAlias = trim(application.blog.getSelectedThemeAlias())>
<!--- Get the Theme data for this theme. --->
<cfset getTheme = application.blog.getTheme(themeAlias=selectedThemeAlias)>	
<!--- Set the Kendo theme --->
<cfset kendoTheme = getTheme[1]["KendoTheme"]>
<!--- Is this a dark theme (such as Orion)? --->
<cfset darkTheme = getTheme[1]["DarkTheme"]>
</cfsilent>
<style>
	#about {
		/* Subtle drop shadow on the header banner that stretches across the page. */
		box-shadow: 0 4px 8px 0 rgba(0, 0, 0, 0.2), 0 6px 20px 0 rgba(0, 0, 0, 0.19);	
	}
</style>
<cfif URL.aboutWhat eq 1>
	<cfinclude  template="#application.baseUrl#/includes/templates/content/windows/about.cfm">
<cfelseif URL.aboutWhat eq 2>
	<cfinclude  template="#application.baseUrl#/includes/templates/content/windows/bio.cfm">
<cfelseif URL.aboutWhat eq 3>
	<cfinclude  template="#application.baseUrl#/includes/templates/content/windows/download.cfm">	
</cfif>