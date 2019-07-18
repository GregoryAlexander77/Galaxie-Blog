<!---
Notes: Gregory's home page design would have the following settings
<cfset blogBackgroundImage="#application.baseUrl#/images/background/gregoryalexander/grandTeton" & backgroundImageResolution & ".jpg">
<cfset headerBackgroundImage = "#application.baseUrl#/images/header/white160.png">
<cfset menuBackgroundImage = "">
<cfset coverKendoMenuWithMenuBackgroundImage = false>
<cfset logoImage = "#application.baseUrl#/images/logo/gregoryAlexanderLogo100_190.png">
<cfset logoMobileWidth = "190">
<cfset blogNameTextColor = "#chr(35)#698A50">
--->

<!--- The jsonArray function turns a native ColdFusion query into an array of structs that can be easily used with jQuery. ---> 
<!---<cfobject component="blogCfc.client.common.cfc.cfjson" name="jsonArray">--->

<!--- The proxyController is between the blog.cfc and the client. --->
<cfobject component="common.cfc.themes" name="ThemesObj">
	
<cffunction name="getKendoTheme" access="remote" returnType="string">
	<cfif isDefined("URL.theme")>
		<!---Drop a cookie to use to store the theme --->
		<cfcookie name="kendoTheme" value="#URL.theme#">
		<cfset kendoTheme = URL.theme>
	<cfelseif isDefined("cookie.kendoTheme")>
		<cfset kendoTheme = cookie.kendoTheme>
	<cfelse>
		<cfset kendoTheme = "metro">
	</cfif>
	
	<!--- Safety check in case something goes wrong. --->
	<cfif kendoTheme eq "">
		<cfset kendoTheme = "metro">
	</cfif>
		
	<!---Return it--->
	<cfreturn kendoTheme>
</cffunction>

<!--- Themes --->
<cffunction name="getKendoStyleSheetByTheme" access="remote" returntype="string">
	<cfargument name="kendoTheme" required="true" hint="Pass in the Kendo theme name."/>
	<cfargument name="kendoSourceLocation"  required="true" hint="Pass in the Kendo source location."/>
	
	<cfif arguments.kendoTheme eq 'materialblack'>
		<cfset kendoStyleSheet = arguments.kendoSourceLocation & "/styles/kendo.common-material.min.css">
	<cfelseif arguments.kendoTheme eq 'office365'>
		<cfset kendoStyleSheet = arguments.kendoSourceLocation & "/styles/kendo.common-office365.min.css">
	<cfelseif arguments.kendoTheme eq 'fiori'>
		<cfset kendoStyleSheet = arguments.kendoSourceLocation & "/styles/kendo.common-fiori.min.css">
		<!--- All of the other themes are included in the common min ss --->
	<cfelse>
		<cfset kendoStyleSheet = arguments.kendoSourceLocation & "/styles/kendo." & arguments.kendoTheme & ".min.css">
	</cfif>
		
	<!---Return the string.--->
	<cfreturn kendoStyleSheet>
</cffunction>
			
<cffunction name="getDefaultCustomThemeNameByTheme" access="remote" returntype="string">
	<cfargument name="baseKendoTheme"  required="true" hint="Pass in the Kendo theme name."/>
	<cfswitch expression="#baseKendoTheme#">
		<cfcase value="black"><cfset defaultCustomName = "Pillars of Creation"></cfcase>
		<cfcase value="blueOpal"><cfset defaultCustomName = "Blue Planet"></cfcase>
		<cfcase value="default"><cfset defaultCustomName = "Zion"></cfcase>
		<cfcase value="fiori"><cfset defaultCustomName = "Fiori"></cfcase>
		<cfcase value="flat"><cfset defaultCustomName = "Bahama Bank"></cfcase>
		<cfcase value="highcontrast"><cfset defaultCustomName = "Orion"></cfcase>
		<cfcase value="material"><cfset defaultCustomName = "Blue Wave"></cfcase>
		<cfcase value="materialblack"><cfset defaultCustomName = "Blue Wave Dark"></cfcase>
		<cfcase value="metro"><cfset defaultCustomName = "Grand Teton"></cfcase>
		<cfcase value="moonlight"><cfset defaultCustomName = "Yellowstone"></cfcase>
		<cfcase value="nova"><cfset defaultCustomName = "Sunrise"></cfcase>
		<cfcase value="office365"><cfset defaultCustomName = "Mukilteo"></cfcase>
		<cfcase value="silver"><cfset defaultCustomName = "Abstract Blue"></cfcase>
		<cfcase value="uniform"><cfset defaultCustomName = "Cobalt"></cfcase>
	</cfswitch>
	<cfreturn themeId>
</cffunction>
	
<!--- Parameters by theme --->
<cffunction name="getSettingsByTheme" access="remote" returntype="struct">
	<cfargument name="uiTheme"  required="true" hint="Pass in the Kendo theme name."/>
	<cfargument name="backgroundImageResolution" default="LowRes" required="false" hint="Pass in the Kendo theme name."/>
	
	<!--- Note: the following settings can not be set as a sharable theme as it would override the owners blog settings (in this case me). These settings must be set in the Application.cfm template.
	kendoSourceLocation
	kendoUiExtendedLocation
	jQueryUiPath
	jQueryNotifyLocation
	blogFontSize
	--->
	
	<!--- There are two stores for the theme information. The default settings which are hardcoded, and user settings set in the administrative interface using the settings.cfm page. In order for a user setting to override the hardcoded setting, both the modifyDefaultThemes and useCustomTheme must be set to true. The modifyDefaultThemes is a global setting that allows a user to change all themes, and the useCustomTheme setting is applied to every theme. If both are true, pull the information out of the configuration file. 
	--->
	
	<!--- Set the themeId that is used to identify the theme in the configuration file. --->
	<cfset themeIdString = "theme" & ThemesObj.getThemeIdByTheme(arguments.uiTheme)>
	<!--- Get the modifyDefaultThemes and useCustomTheme properties in the ini file. --->
	<cfset modifyDefaultThemes = getProfileString("#application.iniFile#", "default", "modifyDefaultThemes")>
	<cfset useCustomTheme = getProfileString("#application.iniFile#", "#themeIdString#", "useCustomTheme")>

	<!--- Determine if both the modifyDefaultThemes and useCustomTheme were set to true. --->
	<!--- A true value for modifyDefaultThemes var could be returned from the config file as either: true, yes, or 1 --->
	<cfif (modifyDefaultThemes eq true) and (useCustomTheme eq true)>
		<cfset modifyDefaultThemes = true>
	<cfelse>
		<cfset modifyDefaultThemes = false>
	</cfif>
	<!--- Ditto for the useCustomTheme var --->
	<cfif useCustomTheme or useCustomTheme eq 'yes' or useCustomTheme eq 1>
		<cfset useCustomTheme = true>
	<cfelse>
		<cfset useCustomTheme = false>
	</cfif>
		
	<!--- If both modifyDefaultThemes and useCustomTheme values are true, then use the config file to get the theme variables. Otherwise, use the default variables. --->
	<cfif modifyDefaultThemes and useCustomTheme>
		<!--- Get the data from the configuration file. --->
		<!--- Note: there are too many variables in the config file and this should be cached. --->
		<cfinvoke component="#ThemesObj#" method="getAllThemeSettingsFromIniStore" returnvariable="uiSettings">
			<cfinvokeargument name="themeId" value="#themeIdString#">
		</cfinvoke>
	<cfelse>
		<!--- Get default theme data. --->
		<cfinvoke component="#ThemesObj#" method="getDefaultSettingsByTheme" returnvariable="uiSettings">
			<cfinvokeargument name="uiTheme" value="#arguments.uiTheme#">
		</cfinvoke>
		<!---<cfset uiSettings = trim(ThemesObj.getDefaultSettingsByTheme(kendoTheme)) />--->
	</cfif>
		
	<!--- Retrun the struct.--->
	<cfreturn uiSettings>
</cffunction>
		
<!--- Get the theme setting by the theme Id. --->
<cffunction name="getThemeSettingFromIniStore" access="remote" returntype="string" hint="Provides the theme setting stored in the configuration file.">
	<cfargument name="themeId"  required="true" hint="Pass in the theme Id."/>
	<cfargument name="themeSetting" required="true" hint="Pass in the setting."/>
	
	<!--- Get the setting using the getProfileString method. --->
	<cfswitch expression="#arguments.themeSetting#">
		<cfcase value="useCustomTheme">
			<cfset setting = getProfileString("#application.iniFile#", "#arguments.themeId#", "useCustomTheme")>
		</cfcase>
		<cfcase value="customThemeName">
			<cfset setting = getProfileString("#application.iniFile#", "#arguments.themeId#", "customThemeName")>
		</cfcase>
		<cfcase value="darkTheme">
			<cfset setting = getProfileString("#application.iniFile#", "#arguments.themeId#", "darkTheme")>
		</cfcase>
		<cfcase value="contentWidth">
			<cfset setting = getProfileString("#application.iniFile#", "#arguments.themeId#", "contentWidth")>
		</cfcase>
		<cfcase value="mainContainerWidth">
			<cfset setting = getProfileString("#application.iniFile#", "#arguments.themeId#", "mainContainerWidth")>
		</cfcase>
		<cfcase value="sideBarContainerWidth">
			<cfset setting = getProfileString("#application.iniFile#", "#arguments.themeId#", "sideBarContainerWidth")>
		</cfcase>
		<cfcase value="siteOpacity">
			<cfset setting = getProfileString("#application.iniFile#", "#arguments.themeId#", "siteOpacity")>
		</cfcase>
		<cfcase value="blogBackgroundImage">
			<cfset setting = getProfileString("#application.iniFile#", "#arguments.themeId#", "blogBackgroundImage")>
		</cfcase>
		<cfcase value="blogBackgroundImageRepeat">
			<cfset setting = getProfileString("#application.iniFile#", "#arguments.themeId#", "blogBackgroundImageRepeat")>
		</cfcase>
		<cfcase value="blogBackgroundImagePosition">
			<cfset setting = getProfileString("#application.iniFile#", "#arguments.themeId#", "blogBackgroundImagePosition")>
		</cfcase>
		<cfcase value="stretchHeaderAcrossPage">
			<cfset setting = getProfileString("#application.iniFile#", "#arguments.themeId#", "stretchHeaderAcrossPage")>
		</cfcase>
		<cfcase value="alignBlogMenuWithBlogContent">
			<cfset setting = getProfileString("#application.iniFile#", "#arguments.themeId#", "alignBlogMenuWithBlogContent")>
		</cfcase>
		<cfcase value="topMenuAlign">
			<cfset setting = getProfileString("#application.iniFile#", "#arguments.themeId#", "topMenuAlign")>
		</cfcase>
		<cfcase value="headerBackgroundImage">
			<cfset setting = getProfileString("#application.iniFile#", "#arguments.themeId#", "headerBackgroundImage")>
		</cfcase>
		<cfcase value="menuBackgroundImage">
			<cfset setting = getProfileString("#application.iniFile#", "#arguments.themeId#", "menuBackgroundImage")>
		</cfcase>
		<cfcase value="coverKendoMenuWithMenuBackgroundImage">
			<cfset setting = getProfileString("#application.iniFile#", "#arguments.themeId#", "coverKendoMenuWithMenuBackgroundImage")>
		</cfcase>
		<cfcase value="logoImageMobile">
			<cfset setting = getProfileString("#application.iniFile#", "#arguments.themeId#", "logoImageMobile")>
		</cfcase>
		<cfcase value="logoMobileWidth">
			<cfset setting = getProfileString("#application.iniFile#", "#arguments.themeId#", "logoMobileWidth")>
		</cfcase>
		<cfcase value="logoImage">
			<cfset setting = getProfileString("#application.iniFile#", "#arguments.themeId#", "logoImage")>
		</cfcase>
		<cfcase value="logoPaddingTop">
			<cfset setting = getProfileString("#application.iniFile#", "#arguments.themeId#", "logoPaddingTop")>
		</cfcase>
		<cfcase value="logoPaddingRight">
			<cfset setting = getProfileString("#application.iniFile#", "#arguments.themeId#", "logoPaddingRight")>
		</cfcase>
		<cfcase value="logoPaddingLeft">
			<cfset setting = getProfileString("#application.iniFile#", "#arguments.themeId#", "logoPaddingLeft")>
		</cfcase>
		<cfcase value="logoPaddingBottom">
			<cfset setting = getProfileString("#application.iniFile#", "#arguments.themeId#", "logoPaddingBottom")>
		</cfcase>
		<cfcase value="blogNameTextColor">
			<cfset setting = getProfileString("#application.iniFile#", "#arguments.themeId#", "blogNameTextColor")>
		</cfcase>
		<cfcase value="headerBodyDividerImage">
			<cfset setting = getProfileString("#application.iniFile#", "#arguments.themeId#", "headerBodyDividerImage")>
		</cfcase>
		<cfcase value="kendoThemeCssFileLocation">
			<cfset setting = getProfileString("#application.iniFile#", "#arguments.themeId#", "kendoThemeCssFileLocation")>
		</cfcase>
		<cfcase value="kendoThemeMobileCssFileLocation">
			<cfset setting = getProfileString("#application.iniFile#", "#arguments.themeId#", "kendoThemeMobileCssFileLocation")>
		</cfcase>
		<cfcase value="customCoreLogicTemplate">
			<cfset setting = getProfileString("#application.iniFile#", "#arguments.themeId#", "customCoreLogicTemplate")>
		</cfcase>
		<cfcase value="customHeadTemplate">
			<cfset setting = getProfileString("#application.iniFile#", "#arguments.themeId#", "customHeadTemplate")>
		</cfcase>
		<cfcase value="customBodyString">
			<cfset setting = getProfileString("#application.iniFile#", "#arguments.themeId#", "customBodyString")>
		</cfcase>
		<cfcase value="customFontCssTemplate">
			<cfset setting = getProfileString("#application.iniFile#", "#arguments.themeId#", "customFontCssTemplate")>
		</cfcase>
		<cfcase value="customGlobalAndBodyCssTemplate">
			<cfset setting = getProfileString("#application.iniFile#", "#arguments.themeId#", "customGlobalAndBodyCssTemplate")>
		</cfcase>
		<cfcase value="customTopMenuCssTemplate">
			<cfset setting = getProfileString("#application.iniFile#", "#arguments.themeId#", "customTopMenuCssTemplate")>
		</cfcase>
		<cfcase value="customTopMenuHtmlTemplate">
			<cfset setting = getProfileString("#application.iniFile#", "#arguments.themeId#", "customTopMenuHtmlTemplate")>
		</cfcase>
		<cfcase value="customTopMenuJsTemplate">
			<cfset setting = getProfileString("#application.iniFile#", "#arguments.themeId#", "customTopMenuJsTemplate")>
		</cfcase>
		<cfcase value="customBlogContentCssTemplate">
			<cfset setting = getProfileString("#application.iniFile#", "#arguments.themeId#", "customBlogContentCssTemplate")>
		</cfcase>
		<cfcase value="customBlogJsContentTemplate">
			<cfset setting = getProfileString("#application.iniFile#", "#arguments.themeId#", "customBlogJsContentTemplate")>
		</cfcase>
		<cfcase value="customBlogContentHtmlTemplate">
			<cfset setting = getProfileString("#application.iniFile#", "#arguments.themeId#", "customBlogContentHtmlTemplate")>
		</cfcase>
		<cfcase value="customFooterHtmlTemplate">
			<cfset setting = getProfileString("#application.iniFile#", "#arguments.themeId#", "customFooterHtmlTemplate")>
		</cfcase>
	</cfswitch>
	<!--- Return it. --->	
	<cfreturn setting>
</cffunction>
		