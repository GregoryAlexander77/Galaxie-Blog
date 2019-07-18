<cfset themeVars = "useCustomTheme,customThemeName,darkTheme,contentWidth,mainContainerWidth,sideBarContainerWidth,siteOpacity,blogBackgroundImage,blogBackgroundImageRepeat,blogBackgroundImagePosition,stretchHeaderAcrossPage,alignBlogMenuWithBlogContent,topMenuAlign,headerBackgroundImage,menuBackgroundImage,coverKendoMenuWithMenuBackgroundImage,logoImageMobile,logoMobileWidth,logoImage,logoPaddingTop,logoPaddingRight,logoPaddingLeft,logoPaddingBottom,blogNameTextColor,headerBodyDividerImage,kendoThemeCssFileLocation,kendoThemeMobileCssFileLocation,customCoreLogicTemplate,customHeadTemplate,customBodyString,customFontCssTemplate,customGlobalAndBodyCssTemplate,customTopMenuCssTemplate,customTopMenuHtmlTemplate,customTopMenuJsTemplate,customBlogContentCssTemplate,customBlogJsContentTemplate,customBlogContentHtmlTemplate,customFooterHtmlTemplate">
	
<cfset kendoThemes = "default,black,blueOpal,flat,highcontrast,material,materialblack,metro,moonlight,office365,silver,uniform,fiori,nova">
	
<cfset generateFunction = "generateGetThemeSettingId">
	
<cffunction name="myTrim" returntype="string" output="false">
    <cfargument name="s" type="string" required="yes">
    <cfreturn Trim(Replace(s, chr(160), " ", "ALL"))>
</cffunction>

<cfset themeVars = myTrim(themeVars)>

<cfoutput>
<cfif generateFunction eq 'generateThemeArray'>
	
	<cfset themeLoopCount = 0>
	<cfset themeVarLoopCount = 1>
	&lt;!--- Create the array. ---><br/>
	&lt;cfset application.arrThemeSettingsFromIniStore = arrayNew(2)><br/>
	&lt;!--- Build the theme ---><br/>
	<cfloop list="#listSort(kendoThemes, 'text')#" index="theme">
		&lt;!--- ************************************************************* #theme# theme settings. ************************************************************* ---><br/><cfset themeLoopCount = themeLoopCount + 1>
		<cfloop list="#myTrim(themeVars)#" index="setting">&lt;cfset application.arrThemeSettingsFromIniStore[#themeLoopCount#][#themeVarLoopCount#] = trim(getSettingsByTheme('#theme#').#setting#)>&lt;!--- #setting# ---><br/><cfset themeVarLoopCount = themeVarLoopCount + 1></cfloop><cfset themeVarLoopCount = 1>
	</cfloop>

<cfelseif generateFunction eq 'getAllThemeSettingsFromIniStore'>
		function getAllThemeSettingsFromIniStore(themeId){<br/>
		// Get all of the theme properties stored in the ini configuration file.<br/>
		jQuery.ajax({<br/>
			type: 'post', <br/>
			url: 'displayAndTheme.cfm?method=getAllThemeSettingsFromIniStore',<br/>
			data: { // method and the arguments<br/>
				themeId: themeId<br/>
			},<br/>
			dataType: "json",<br/>
			success: function(data) {<br/>
				getAllThemeSettingsResult(<cfloop list="#myTrim(themeVars)#" index="i">#i#,</cfloop>)<br/>
			},<br/>
			error: function(ErrorMsg){<br/>
				console.log('Error' + ErrorMsg);<br/>
			)<br/>
		});){<br/>

	});<br/>
	<br/><br/>	
	// Extract the items from the json array that was returned. ***************************************************************<br/>
	function getAllThemeSettingsResult(<cfloop list="#myTrim(themeVars)#" index="i">#i#,</cfloop>){<br/>

		// Get the response from the server<br/>
		<cfloop list="#myTrim(themeVars)#" index="i">
		var #i#Value = response.#i#;<br/>
		</cfloop>
		<br/>
		// After the response has been extracted, set the new values on the admin settings form.<br/>
		<cfloop list="#myTrim(themeVars)#" index="i">
		$( "#i#" ).val( #i#Value );<br/>
		</cfloop>
	<br/>		
	} //..function <br/>
	
<cfelseif generateFunction eq 'generateGetThemeSettingId'>
	<cfset themeSettingCounter = 1>
	&lt;cffunction getThemeSettingIdBySetting(kendoTheme) access="remote" returnType="numeric" output="false" hint="Returns an Id of a theme setting."></br/>
		&lt;cfargument name="themeSetting" type="string" required="true"><br/>
		&lt;cfswitch expression="#chr(35)#arguments.themeSetting#chr(35)#"><br/>
		<cfloop list="#themeVars#" index="themeVar">
			&lt;cfcase value="#themeVar#"><br/>
				&lt;cfset themeSettingId = #themeSettingCounter#><br/>
			&lt;/cfcase><br/>
			<cfset themeSettingCounter = themeSettingCounter + 1>
		</cfloop>
		&lt;/cfswitch><br/>
		&lt;cfreturn themeSettingId><br/>
		&lt;/cffunction><br/>
</cfif>
</cfoutput>	
	


