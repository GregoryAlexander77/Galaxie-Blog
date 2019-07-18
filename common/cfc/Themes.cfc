<cfcomponent displayName="Themes" output="no" hint="Theme related component. Use the initThemeVars method to set the application variables needed for the application.">
	
	<!---*****************************************************************************************************************************************  
	Theme related functions
	***************************************************************************************************************************************** --->

	<!--- This function is consumed on the admin settings page in order to get all of the settings --->
	<cffunction name="initThemes" access="public" hint="This function will create a theme array in the application scope that will retain our theme variables. It is to be used during the initialization of the applicatoin.">
		
		<cfinclude template="../function/displayAndTheme.cfm">
			
		<!---Note: use the following line to create or regenerate the array:
		<cfset ThemesObj.initThemeVars()>
		--->
			
		<!--- Create the array. --->
		<cfset application.themeSettingsArray = arrayNew(2)>
		<!--- Build the theme --->
		<!--- ************************************************************* black theme settings. ************************************************************* --->
		<cfset application.themeSettingsArray[1][1] = trim(getSettingsByTheme('black').useCustomTheme)><!--- useCustomTheme --->
		<cfset application.themeSettingsArray[1][2] = trim(getSettingsByTheme('black').customThemeName)><!--- customThemeName --->
		<cfset application.themeSettingsArray[1][3] = trim(getSettingsByTheme('black').darkTheme)><!--- darkTheme --->
		<cfset application.themeSettingsArray[1][4] = trim(getSettingsByTheme('black').contentWidth)><!--- contentWidth --->
		<cfset application.themeSettingsArray[1][5] = trim(getSettingsByTheme('black').mainContainerWidth)><!--- mainContainerWidth --->
		<cfset application.themeSettingsArray[1][6] = trim(getSettingsByTheme('black').sideBarContainerWidth)><!--- sideBarContainerWidth --->
		<cfset application.themeSettingsArray[1][7] = trim(getSettingsByTheme('black').siteOpacity)><!--- siteOpacity --->
		<cfset application.themeSettingsArray[1][8] = trim(getSettingsByTheme('black').blogBackgroundImage)><!--- blogBackgroundImage --->
		<cfset application.themeSettingsArray[1][9] = trim(getSettingsByTheme('black').blogBackgroundImageRepeat)><!--- blogBackgroundImageRepeat --->
		<cfset application.themeSettingsArray[1][10] = trim(getSettingsByTheme('black').blogBackgroundImagePosition)><!--- blogBackgroundImagePosition --->
		<cfset application.themeSettingsArray[1][11] = trim(getSettingsByTheme('black').stretchHeaderAcrossPage)><!--- stretchHeaderAcrossPage --->
		<cfset application.themeSettingsArray[1][12] = trim(getSettingsByTheme('black').alignBlogMenuWithBlogContent)><!--- alignBlogMenuWithBlogContent --->
		<cfset application.themeSettingsArray[1][13] = trim(getSettingsByTheme('black').topMenuAlign)><!--- topMenuAlign --->
		<cfset application.themeSettingsArray[1][14] = trim(getSettingsByTheme('black').headerBackgroundImage)><!--- headerBackgroundImage --->
		<cfset application.themeSettingsArray[1][15] = trim(getSettingsByTheme('black').menuBackgroundImage)><!--- menuBackgroundImage --->
		<cfset application.themeSettingsArray[1][16] = trim(getSettingsByTheme('black').coverKendoMenuWithMenuBackgroundImage)><!--- coverKendoMenuWithMenuBackgroundImage --->
		<cfset application.themeSettingsArray[1][17] = trim(getSettingsByTheme('black').logoImageMobile)><!--- logoImageMobile --->
		<cfset application.themeSettingsArray[1][18] = trim(getSettingsByTheme('black').logoMobileWidth)><!--- logoMobileWidth --->
		<cfset application.themeSettingsArray[1][19] = trim(getSettingsByTheme('black').logoImage)><!--- logoImage --->
		<cfset application.themeSettingsArray[1][20] = trim(getSettingsByTheme('black').logoPaddingTop)><!--- logoPaddingTop --->
		<cfset application.themeSettingsArray[1][21] = trim(getSettingsByTheme('black').logoPaddingRight)><!--- logoPaddingRight --->
		<cfset application.themeSettingsArray[1][22] = trim(getSettingsByTheme('black').logoPaddingLeft)><!--- logoPaddingLeft --->
		<cfset application.themeSettingsArray[1][23] = trim(getSettingsByTheme('black').logoPaddingBottom)><!--- logoPaddingBottom --->
		<cfset application.themeSettingsArray[1][24] = trim(getSettingsByTheme('black').blogNameTextColor)><!--- blogNameTextColor --->
		<cfset application.themeSettingsArray[1][25] = trim(getSettingsByTheme('black').headerBodyDividerImage)><!--- headerBodyDividerImage --->
		<cfset application.themeSettingsArray[1][26] = trim(getSettingsByTheme('black').kendoThemeCssFileLocation)><!--- kendoThemeCssFileLocation --->
		<cfset application.themeSettingsArray[1][27] = trim(getSettingsByTheme('black').kendoThemeMobileCssFileLocation)><!--- kendoThemeMobileCssFileLocation --->
		<cfset application.themeSettingsArray[1][28] = trim(getSettingsByTheme('black').customCoreLogicTemplate)><!--- customCoreLogicTemplate --->
		<cfset application.themeSettingsArray[1][29] = trim(getSettingsByTheme('black').customHeadTemplate)><!--- customHeadTemplate --->
		<cfset application.themeSettingsArray[1][30] = trim(getSettingsByTheme('black').customBodyString)><!--- customBodyString --->
		<cfset application.themeSettingsArray[1][31] = trim(getSettingsByTheme('black').customFontCssTemplate)><!--- customFontCssTemplate --->
		<cfset application.themeSettingsArray[1][32] = trim(getSettingsByTheme('black').customGlobalAndBodyCssTemplate)><!--- customGlobalAndBodyCssTemplate --->
		<cfset application.themeSettingsArray[1][33] = trim(getSettingsByTheme('black').customTopMenuCssTemplate)><!--- customTopMenuCssTemplate --->
		<cfset application.themeSettingsArray[1][34] = trim(getSettingsByTheme('black').customTopMenuHtmlTemplate)><!--- customTopMenuHtmlTemplate --->
		<cfset application.themeSettingsArray[1][35] = trim(getSettingsByTheme('black').customTopMenuJsTemplate)><!--- customTopMenuJsTemplate --->
		<cfset application.themeSettingsArray[1][36] = trim(getSettingsByTheme('black').customBlogContentCssTemplate)><!--- customBlogContentCssTemplate --->
		<cfset application.themeSettingsArray[1][37] = trim(getSettingsByTheme('black').customBlogJsContentTemplate)><!--- customBlogJsContentTemplate --->
		<cfset application.themeSettingsArray[1][38] = trim(getSettingsByTheme('black').customBlogContentHtmlTemplate)><!--- customBlogContentHtmlTemplate --->
		<cfset application.themeSettingsArray[1][39] = trim(getSettingsByTheme('black').customFooterHtmlTemplate)><!--- customFooterHtmlTemplate --->
		<!--- ************************************************************* blueOpal theme settings. ************************************************************* --->
		<cfset application.themeSettingsArray[2][1] = trim(getSettingsByTheme('blueOpal').useCustomTheme)><!--- useCustomTheme --->
		<cfset application.themeSettingsArray[2][2] = trim(getSettingsByTheme('blueOpal').customThemeName)><!--- customThemeName --->
		<cfset application.themeSettingsArray[2][3] = trim(getSettingsByTheme('blueOpal').darkTheme)><!--- darkTheme --->
		<cfset application.themeSettingsArray[2][4] = trim(getSettingsByTheme('blueOpal').contentWidth)><!--- contentWidth --->
		<cfset application.themeSettingsArray[2][5] = trim(getSettingsByTheme('blueOpal').mainContainerWidth)><!--- mainContainerWidth --->
		<cfset application.themeSettingsArray[2][6] = trim(getSettingsByTheme('blueOpal').sideBarContainerWidth)><!--- sideBarContainerWidth --->
		<cfset application.themeSettingsArray[2][7] = trim(getSettingsByTheme('blueOpal').siteOpacity)><!--- siteOpacity --->
		<cfset application.themeSettingsArray[2][8] = trim(getSettingsByTheme('blueOpal').blogBackgroundImage)><!--- blogBackgroundImage --->
		<cfset application.themeSettingsArray[2][9] = trim(getSettingsByTheme('blueOpal').blogBackgroundImageRepeat)><!--- blogBackgroundImageRepeat --->
		<cfset application.themeSettingsArray[2][10] = trim(getSettingsByTheme('blueOpal').blogBackgroundImagePosition)><!--- blogBackgroundImagePosition --->
		<cfset application.themeSettingsArray[2][11] = trim(getSettingsByTheme('blueOpal').stretchHeaderAcrossPage)><!--- stretchHeaderAcrossPage --->
		<cfset application.themeSettingsArray[2][12] = trim(getSettingsByTheme('blueOpal').alignBlogMenuWithBlogContent)><!--- alignBlogMenuWithBlogContent --->
		<cfset application.themeSettingsArray[2][13] = trim(getSettingsByTheme('blueOpal').topMenuAlign)><!--- topMenuAlign --->
		<cfset application.themeSettingsArray[2][14] = trim(getSettingsByTheme('blueOpal').headerBackgroundImage)><!--- headerBackgroundImage --->
		<cfset application.themeSettingsArray[2][15] = trim(getSettingsByTheme('blueOpal').menuBackgroundImage)><!--- menuBackgroundImage --->
		<cfset application.themeSettingsArray[2][16] = trim(getSettingsByTheme('blueOpal').coverKendoMenuWithMenuBackgroundImage)><!--- coverKendoMenuWithMenuBackgroundImage --->
		<cfset application.themeSettingsArray[2][17] = trim(getSettingsByTheme('blueOpal').logoImageMobile)><!--- logoImageMobile --->
		<cfset application.themeSettingsArray[2][18] = trim(getSettingsByTheme('blueOpal').logoMobileWidth)><!--- logoMobileWidth --->
		<cfset application.themeSettingsArray[2][19] = trim(getSettingsByTheme('blueOpal').logoImage)><!--- logoImage --->
		<cfset application.themeSettingsArray[2][20] = trim(getSettingsByTheme('blueOpal').logoPaddingTop)><!--- logoPaddingTop --->
		<cfset application.themeSettingsArray[2][21] = trim(getSettingsByTheme('blueOpal').logoPaddingRight)><!--- logoPaddingRight --->
		<cfset application.themeSettingsArray[2][22] = trim(getSettingsByTheme('blueOpal').logoPaddingLeft)><!--- logoPaddingLeft --->
		<cfset application.themeSettingsArray[2][23] = trim(getSettingsByTheme('blueOpal').logoPaddingBottom)><!--- logoPaddingBottom --->
		<cfset application.themeSettingsArray[2][24] = trim(getSettingsByTheme('blueOpal').blogNameTextColor)><!--- blogNameTextColor --->
		<cfset application.themeSettingsArray[2][25] = trim(getSettingsByTheme('blueOpal').headerBodyDividerImage)><!--- headerBodyDividerImage --->
		<cfset application.themeSettingsArray[2][26] = trim(getSettingsByTheme('blueOpal').kendoThemeCssFileLocation)><!--- kendoThemeCssFileLocation --->
		<cfset application.themeSettingsArray[2][27] = trim(getSettingsByTheme('blueOpal').kendoThemeMobileCssFileLocation)><!--- kendoThemeMobileCssFileLocation --->
		<cfset application.themeSettingsArray[2][28] = trim(getSettingsByTheme('blueOpal').customCoreLogicTemplate)><!--- customCoreLogicTemplate --->
		<cfset application.themeSettingsArray[2][29] = trim(getSettingsByTheme('blueOpal').customHeadTemplate)><!--- customHeadTemplate --->
		<cfset application.themeSettingsArray[2][30] = trim(getSettingsByTheme('blueOpal').customBodyString)><!--- customBodyString --->
		<cfset application.themeSettingsArray[2][31] = trim(getSettingsByTheme('blueOpal').customFontCssTemplate)><!--- customFontCssTemplate --->
		<cfset application.themeSettingsArray[2][32] = trim(getSettingsByTheme('blueOpal').customGlobalAndBodyCssTemplate)><!--- customGlobalAndBodyCssTemplate --->
		<cfset application.themeSettingsArray[2][33] = trim(getSettingsByTheme('blueOpal').customTopMenuCssTemplate)><!--- customTopMenuCssTemplate --->
		<cfset application.themeSettingsArray[2][34] = trim(getSettingsByTheme('blueOpal').customTopMenuHtmlTemplate)><!--- customTopMenuHtmlTemplate --->
		<cfset application.themeSettingsArray[2][35] = trim(getSettingsByTheme('blueOpal').customTopMenuJsTemplate)><!--- customTopMenuJsTemplate --->
		<cfset application.themeSettingsArray[2][36] = trim(getSettingsByTheme('blueOpal').customBlogContentCssTemplate)><!--- customBlogContentCssTemplate --->
		<cfset application.themeSettingsArray[2][37] = trim(getSettingsByTheme('blueOpal').customBlogJsContentTemplate)><!--- customBlogJsContentTemplate --->
		<cfset application.themeSettingsArray[2][38] = trim(getSettingsByTheme('blueOpal').customBlogContentHtmlTemplate)><!--- customBlogContentHtmlTemplate --->
		<cfset application.themeSettingsArray[2][39] = trim(getSettingsByTheme('blueOpal').customFooterHtmlTemplate)><!--- customFooterHtmlTemplate --->
		<!--- ************************************************************* default theme settings. ************************************************************* --->
		<cfset application.themeSettingsArray[3][1] = trim(getSettingsByTheme('default').useCustomTheme)><!--- useCustomTheme --->
		<cfset application.themeSettingsArray[3][2] = trim(getSettingsByTheme('default').customThemeName)><!--- customThemeName --->
		<cfset application.themeSettingsArray[3][3] = trim(getSettingsByTheme('default').darkTheme)><!--- darkTheme --->
		<cfset application.themeSettingsArray[3][4] = trim(getSettingsByTheme('default').contentWidth)><!--- contentWidth --->
		<cfset application.themeSettingsArray[3][5] = trim(getSettingsByTheme('default').mainContainerWidth)><!--- mainContainerWidth --->
		<cfset application.themeSettingsArray[3][6] = trim(getSettingsByTheme('default').sideBarContainerWidth)><!--- sideBarContainerWidth --->
		<cfset application.themeSettingsArray[3][7] = trim(getSettingsByTheme('default').siteOpacity)><!--- siteOpacity --->
		<cfset application.themeSettingsArray[3][8] = trim(getSettingsByTheme('default').blogBackgroundImage)><!--- blogBackgroundImage --->
		<cfset application.themeSettingsArray[3][9] = trim(getSettingsByTheme('default').blogBackgroundImageRepeat)><!--- blogBackgroundImageRepeat --->
		<cfset application.themeSettingsArray[3][10] = trim(getSettingsByTheme('default').blogBackgroundImagePosition)><!--- blogBackgroundImagePosition --->
		<cfset application.themeSettingsArray[3][11] = trim(getSettingsByTheme('default').stretchHeaderAcrossPage)><!--- stretchHeaderAcrossPage --->
		<cfset application.themeSettingsArray[3][12] = trim(getSettingsByTheme('default').alignBlogMenuWithBlogContent)><!--- alignBlogMenuWithBlogContent --->
		<cfset application.themeSettingsArray[3][13] = trim(getSettingsByTheme('default').topMenuAlign)><!--- topMenuAlign --->
		<cfset application.themeSettingsArray[3][14] = trim(getSettingsByTheme('default').headerBackgroundImage)><!--- headerBackgroundImage --->
		<cfset application.themeSettingsArray[3][15] = trim(getSettingsByTheme('default').menuBackgroundImage)><!--- menuBackgroundImage --->
		<cfset application.themeSettingsArray[3][16] = trim(getSettingsByTheme('default').coverKendoMenuWithMenuBackgroundImage)><!--- coverKendoMenuWithMenuBackgroundImage --->
		<cfset application.themeSettingsArray[3][17] = trim(getSettingsByTheme('default').logoImageMobile)><!--- logoImageMobile --->
		<cfset application.themeSettingsArray[3][18] = trim(getSettingsByTheme('default').logoMobileWidth)><!--- logoMobileWidth --->
		<cfset application.themeSettingsArray[3][19] = trim(getSettingsByTheme('default').logoImage)><!--- logoImage --->
		<cfset application.themeSettingsArray[3][20] = trim(getSettingsByTheme('default').logoPaddingTop)><!--- logoPaddingTop --->
		<cfset application.themeSettingsArray[3][21] = trim(getSettingsByTheme('default').logoPaddingRight)><!--- logoPaddingRight --->
		<cfset application.themeSettingsArray[3][22] = trim(getSettingsByTheme('default').logoPaddingLeft)><!--- logoPaddingLeft --->
		<cfset application.themeSettingsArray[3][23] = trim(getSettingsByTheme('default').logoPaddingBottom)><!--- logoPaddingBottom --->
		<cfset application.themeSettingsArray[3][24] = trim(getSettingsByTheme('default').blogNameTextColor)><!--- blogNameTextColor --->
		<cfset application.themeSettingsArray[3][25] = trim(getSettingsByTheme('default').headerBodyDividerImage)><!--- headerBodyDividerImage --->
		<cfset application.themeSettingsArray[3][26] = trim(getSettingsByTheme('default').kendoThemeCssFileLocation)><!--- kendoThemeCssFileLocation --->
		<cfset application.themeSettingsArray[3][27] = trim(getSettingsByTheme('default').kendoThemeMobileCssFileLocation)><!--- kendoThemeMobileCssFileLocation --->
		<cfset application.themeSettingsArray[3][28] = trim(getSettingsByTheme('default').customCoreLogicTemplate)><!--- customCoreLogicTemplate --->
		<cfset application.themeSettingsArray[3][29] = trim(getSettingsByTheme('default').customHeadTemplate)><!--- customHeadTemplate --->
		<cfset application.themeSettingsArray[3][30] = trim(getSettingsByTheme('default').customBodyString)><!--- customBodyString --->
		<cfset application.themeSettingsArray[3][31] = trim(getSettingsByTheme('default').customFontCssTemplate)><!--- customFontCssTemplate --->
		<cfset application.themeSettingsArray[3][32] = trim(getSettingsByTheme('default').customGlobalAndBodyCssTemplate)><!--- customGlobalAndBodyCssTemplate --->
		<cfset application.themeSettingsArray[3][33] = trim(getSettingsByTheme('default').customTopMenuCssTemplate)><!--- customTopMenuCssTemplate --->
		<cfset application.themeSettingsArray[3][34] = trim(getSettingsByTheme('default').customTopMenuHtmlTemplate)><!--- customTopMenuHtmlTemplate --->
		<cfset application.themeSettingsArray[3][35] = trim(getSettingsByTheme('default').customTopMenuJsTemplate)><!--- customTopMenuJsTemplate --->
		<cfset application.themeSettingsArray[3][36] = trim(getSettingsByTheme('default').customBlogContentCssTemplate)><!--- customBlogContentCssTemplate --->
		<cfset application.themeSettingsArray[3][37] = trim(getSettingsByTheme('default').customBlogJsContentTemplate)><!--- customBlogJsContentTemplate --->
		<cfset application.themeSettingsArray[3][38] = trim(getSettingsByTheme('default').customBlogContentHtmlTemplate)><!--- customBlogContentHtmlTemplate --->
		<cfset application.themeSettingsArray[3][39] = trim(getSettingsByTheme('default').customFooterHtmlTemplate)><!--- customFooterHtmlTemplate --->
		<!--- ************************************************************* fiori theme settings. ************************************************************* --->
		<cfset application.themeSettingsArray[4][1] = trim(getSettingsByTheme('fiori').useCustomTheme)><!--- useCustomTheme --->
		<cfset application.themeSettingsArray[4][2] = trim(getSettingsByTheme('fiori').customThemeName)><!--- customThemeName --->
		<cfset application.themeSettingsArray[4][3] = trim(getSettingsByTheme('fiori').darkTheme)><!--- darkTheme --->
		<cfset application.themeSettingsArray[4][4] = trim(getSettingsByTheme('fiori').contentWidth)><!--- contentWidth --->
		<cfset application.themeSettingsArray[4][5] = trim(getSettingsByTheme('fiori').mainContainerWidth)><!--- mainContainerWidth --->
		<cfset application.themeSettingsArray[4][6] = trim(getSettingsByTheme('fiori').sideBarContainerWidth)><!--- sideBarContainerWidth --->
		<cfset application.themeSettingsArray[4][7] = trim(getSettingsByTheme('fiori').siteOpacity)><!--- siteOpacity --->
		<cfset application.themeSettingsArray[4][8] = trim(getSettingsByTheme('fiori').blogBackgroundImage)><!--- blogBackgroundImage --->
		<cfset application.themeSettingsArray[4][9] = trim(getSettingsByTheme('fiori').blogBackgroundImageRepeat)><!--- blogBackgroundImageRepeat --->
		<cfset application.themeSettingsArray[4][10] = trim(getSettingsByTheme('fiori').blogBackgroundImagePosition)><!--- blogBackgroundImagePosition --->
		<cfset application.themeSettingsArray[4][11] = trim(getSettingsByTheme('fiori').stretchHeaderAcrossPage)><!--- stretchHeaderAcrossPage --->
		<cfset application.themeSettingsArray[4][12] = trim(getSettingsByTheme('fiori').alignBlogMenuWithBlogContent)><!--- alignBlogMenuWithBlogContent --->
		<cfset application.themeSettingsArray[4][13] = trim(getSettingsByTheme('fiori').topMenuAlign)><!--- topMenuAlign --->
		<cfset application.themeSettingsArray[4][14] = trim(getSettingsByTheme('fiori').headerBackgroundImage)><!--- headerBackgroundImage --->
		<cfset application.themeSettingsArray[4][15] = trim(getSettingsByTheme('fiori').menuBackgroundImage)><!--- menuBackgroundImage --->
		<cfset application.themeSettingsArray[4][16] = trim(getSettingsByTheme('fiori').coverKendoMenuWithMenuBackgroundImage)><!--- coverKendoMenuWithMenuBackgroundImage --->
		<cfset application.themeSettingsArray[4][17] = trim(getSettingsByTheme('fiori').logoImageMobile)><!--- logoImageMobile --->
		<cfset application.themeSettingsArray[4][18] = trim(getSettingsByTheme('fiori').logoMobileWidth)><!--- logoMobileWidth --->
		<cfset application.themeSettingsArray[4][19] = trim(getSettingsByTheme('fiori').logoImage)><!--- logoImage --->
		<cfset application.themeSettingsArray[4][20] = trim(getSettingsByTheme('fiori').logoPaddingTop)><!--- logoPaddingTop --->
		<cfset application.themeSettingsArray[4][21] = trim(getSettingsByTheme('fiori').logoPaddingRight)><!--- logoPaddingRight --->
		<cfset application.themeSettingsArray[4][22] = trim(getSettingsByTheme('fiori').logoPaddingLeft)><!--- logoPaddingLeft --->
		<cfset application.themeSettingsArray[4][23] = trim(getSettingsByTheme('fiori').logoPaddingBottom)><!--- logoPaddingBottom --->
		<cfset application.themeSettingsArray[4][24] = trim(getSettingsByTheme('fiori').blogNameTextColor)><!--- blogNameTextColor --->
		<cfset application.themeSettingsArray[4][25] = trim(getSettingsByTheme('fiori').headerBodyDividerImage)><!--- headerBodyDividerImage --->
		<cfset application.themeSettingsArray[4][26] = trim(getSettingsByTheme('fiori').kendoThemeCssFileLocation)><!--- kendoThemeCssFileLocation --->
		<cfset application.themeSettingsArray[4][27] = trim(getSettingsByTheme('fiori').kendoThemeMobileCssFileLocation)><!--- kendoThemeMobileCssFileLocation --->
		<cfset application.themeSettingsArray[4][28] = trim(getSettingsByTheme('fiori').customCoreLogicTemplate)><!--- customCoreLogicTemplate --->
		<cfset application.themeSettingsArray[4][29] = trim(getSettingsByTheme('fiori').customHeadTemplate)><!--- customHeadTemplate --->
		<cfset application.themeSettingsArray[4][30] = trim(getSettingsByTheme('fiori').customBodyString)><!--- customBodyString --->
		<cfset application.themeSettingsArray[4][31] = trim(getSettingsByTheme('fiori').customFontCssTemplate)><!--- customFontCssTemplate --->
		<cfset application.themeSettingsArray[4][32] = trim(getSettingsByTheme('fiori').customGlobalAndBodyCssTemplate)><!--- customGlobalAndBodyCssTemplate --->
		<cfset application.themeSettingsArray[4][33] = trim(getSettingsByTheme('fiori').customTopMenuCssTemplate)><!--- customTopMenuCssTemplate --->
		<cfset application.themeSettingsArray[4][34] = trim(getSettingsByTheme('fiori').customTopMenuHtmlTemplate)><!--- customTopMenuHtmlTemplate --->
		<cfset application.themeSettingsArray[4][35] = trim(getSettingsByTheme('fiori').customTopMenuJsTemplate)><!--- customTopMenuJsTemplate --->
		<cfset application.themeSettingsArray[4][36] = trim(getSettingsByTheme('fiori').customBlogContentCssTemplate)><!--- customBlogContentCssTemplate --->
		<cfset application.themeSettingsArray[4][37] = trim(getSettingsByTheme('fiori').customBlogJsContentTemplate)><!--- customBlogJsContentTemplate --->
		<cfset application.themeSettingsArray[4][38] = trim(getSettingsByTheme('fiori').customBlogContentHtmlTemplate)><!--- customBlogContentHtmlTemplate --->
		<cfset application.themeSettingsArray[4][39] = trim(getSettingsByTheme('fiori').customFooterHtmlTemplate)><!--- customFooterHtmlTemplate --->
		<!--- ************************************************************* flat theme settings. ************************************************************* --->
		<cfset application.themeSettingsArray[5][1] = trim(getSettingsByTheme('flat').useCustomTheme)><!--- useCustomTheme --->
		<cfset application.themeSettingsArray[5][2] = trim(getSettingsByTheme('flat').customThemeName)><!--- customThemeName --->
		<cfset application.themeSettingsArray[5][3] = trim(getSettingsByTheme('flat').darkTheme)><!--- darkTheme --->
		<cfset application.themeSettingsArray[5][4] = trim(getSettingsByTheme('flat').contentWidth)><!--- contentWidth --->
		<cfset application.themeSettingsArray[5][5] = trim(getSettingsByTheme('flat').mainContainerWidth)><!--- mainContainerWidth --->
		<cfset application.themeSettingsArray[5][6] = trim(getSettingsByTheme('flat').sideBarContainerWidth)><!--- sideBarContainerWidth --->
		<cfset application.themeSettingsArray[5][7] = trim(getSettingsByTheme('flat').siteOpacity)><!--- siteOpacity --->
		<cfset application.themeSettingsArray[5][8] = trim(getSettingsByTheme('flat').blogBackgroundImage)><!--- blogBackgroundImage --->
		<cfset application.themeSettingsArray[5][9] = trim(getSettingsByTheme('flat').blogBackgroundImageRepeat)><!--- blogBackgroundImageRepeat --->
		<cfset application.themeSettingsArray[5][10] = trim(getSettingsByTheme('flat').blogBackgroundImagePosition)><!--- blogBackgroundImagePosition --->
		<cfset application.themeSettingsArray[5][11] = trim(getSettingsByTheme('flat').stretchHeaderAcrossPage)><!--- stretchHeaderAcrossPage --->
		<cfset application.themeSettingsArray[5][12] = trim(getSettingsByTheme('flat').alignBlogMenuWithBlogContent)><!--- alignBlogMenuWithBlogContent --->
		<cfset application.themeSettingsArray[5][13] = trim(getSettingsByTheme('flat').topMenuAlign)><!--- topMenuAlign --->
		<cfset application.themeSettingsArray[5][14] = trim(getSettingsByTheme('flat').headerBackgroundImage)><!--- headerBackgroundImage --->
		<cfset application.themeSettingsArray[5][15] = trim(getSettingsByTheme('flat').menuBackgroundImage)><!--- menuBackgroundImage --->
		<cfset application.themeSettingsArray[5][16] = trim(getSettingsByTheme('flat').coverKendoMenuWithMenuBackgroundImage)><!--- coverKendoMenuWithMenuBackgroundImage --->
		<cfset application.themeSettingsArray[5][17] = trim(getSettingsByTheme('flat').logoImageMobile)><!--- logoImageMobile --->
		<cfset application.themeSettingsArray[5][18] = trim(getSettingsByTheme('flat').logoMobileWidth)><!--- logoMobileWidth --->
		<cfset application.themeSettingsArray[5][19] = trim(getSettingsByTheme('flat').logoImage)><!--- logoImage --->
		<cfset application.themeSettingsArray[5][20] = trim(getSettingsByTheme('flat').logoPaddingTop)><!--- logoPaddingTop --->
		<cfset application.themeSettingsArray[5][21] = trim(getSettingsByTheme('flat').logoPaddingRight)><!--- logoPaddingRight --->
		<cfset application.themeSettingsArray[5][22] = trim(getSettingsByTheme('flat').logoPaddingLeft)><!--- logoPaddingLeft --->
		<cfset application.themeSettingsArray[5][23] = trim(getSettingsByTheme('flat').logoPaddingBottom)><!--- logoPaddingBottom --->
		<cfset application.themeSettingsArray[5][24] = trim(getSettingsByTheme('flat').blogNameTextColor)><!--- blogNameTextColor --->
		<cfset application.themeSettingsArray[5][25] = trim(getSettingsByTheme('flat').headerBodyDividerImage)><!--- headerBodyDividerImage --->
		<cfset application.themeSettingsArray[5][26] = trim(getSettingsByTheme('flat').kendoThemeCssFileLocation)><!--- kendoThemeCssFileLocation --->
		<cfset application.themeSettingsArray[5][27] = trim(getSettingsByTheme('flat').kendoThemeMobileCssFileLocation)><!--- kendoThemeMobileCssFileLocation --->
		<cfset application.themeSettingsArray[5][28] = trim(getSettingsByTheme('flat').customCoreLogicTemplate)><!--- customCoreLogicTemplate --->
		<cfset application.themeSettingsArray[5][29] = trim(getSettingsByTheme('flat').customHeadTemplate)><!--- customHeadTemplate --->
		<cfset application.themeSettingsArray[5][30] = trim(getSettingsByTheme('flat').customBodyString)><!--- customBodyString --->
		<cfset application.themeSettingsArray[5][31] = trim(getSettingsByTheme('flat').customFontCssTemplate)><!--- customFontCssTemplate --->
		<cfset application.themeSettingsArray[5][32] = trim(getSettingsByTheme('flat').customGlobalAndBodyCssTemplate)><!--- customGlobalAndBodyCssTemplate --->
		<cfset application.themeSettingsArray[5][33] = trim(getSettingsByTheme('flat').customTopMenuCssTemplate)><!--- customTopMenuCssTemplate --->
		<cfset application.themeSettingsArray[5][34] = trim(getSettingsByTheme('flat').customTopMenuHtmlTemplate)><!--- customTopMenuHtmlTemplate --->
		<cfset application.themeSettingsArray[5][35] = trim(getSettingsByTheme('flat').customTopMenuJsTemplate)><!--- customTopMenuJsTemplate --->
		<cfset application.themeSettingsArray[5][36] = trim(getSettingsByTheme('flat').customBlogContentCssTemplate)><!--- customBlogContentCssTemplate --->
		<cfset application.themeSettingsArray[5][37] = trim(getSettingsByTheme('flat').customBlogJsContentTemplate)><!--- customBlogJsContentTemplate --->
		<cfset application.themeSettingsArray[5][38] = trim(getSettingsByTheme('flat').customBlogContentHtmlTemplate)><!--- customBlogContentHtmlTemplate --->
		<cfset application.themeSettingsArray[5][39] = trim(getSettingsByTheme('flat').customFooterHtmlTemplate)><!--- customFooterHtmlTemplate --->
		<!--- ************************************************************* highcontrast theme settings. ************************************************************* --->
		<cfset application.themeSettingsArray[6][1] = trim(getSettingsByTheme('highcontrast').useCustomTheme)><!--- useCustomTheme --->
		<cfset application.themeSettingsArray[6][2] = trim(getSettingsByTheme('highcontrast').customThemeName)><!--- customThemeName --->
		<cfset application.themeSettingsArray[6][3] = trim(getSettingsByTheme('highcontrast').darkTheme)><!--- darkTheme --->
		<cfset application.themeSettingsArray[6][4] = trim(getSettingsByTheme('highcontrast').contentWidth)><!--- contentWidth --->
		<cfset application.themeSettingsArray[6][5] = trim(getSettingsByTheme('highcontrast').mainContainerWidth)><!--- mainContainerWidth --->
		<cfset application.themeSettingsArray[6][6] = trim(getSettingsByTheme('highcontrast').sideBarContainerWidth)><!--- sideBarContainerWidth --->
		<cfset application.themeSettingsArray[6][7] = trim(getSettingsByTheme('highcontrast').siteOpacity)><!--- siteOpacity --->
		<cfset application.themeSettingsArray[6][8] = trim(getSettingsByTheme('highcontrast').blogBackgroundImage)><!--- blogBackgroundImage --->
		<cfset application.themeSettingsArray[6][9] = trim(getSettingsByTheme('highcontrast').blogBackgroundImageRepeat)><!--- blogBackgroundImageRepeat --->
		<cfset application.themeSettingsArray[6][10] = trim(getSettingsByTheme('highcontrast').blogBackgroundImagePosition)><!--- blogBackgroundImagePosition --->
		<cfset application.themeSettingsArray[6][11] = trim(getSettingsByTheme('highcontrast').stretchHeaderAcrossPage)><!--- stretchHeaderAcrossPage --->
		<cfset application.themeSettingsArray[6][12] = trim(getSettingsByTheme('highcontrast').alignBlogMenuWithBlogContent)><!--- alignBlogMenuWithBlogContent --->
		<cfset application.themeSettingsArray[6][13] = trim(getSettingsByTheme('highcontrast').topMenuAlign)><!--- topMenuAlign --->
		<cfset application.themeSettingsArray[6][14] = trim(getSettingsByTheme('highcontrast').headerBackgroundImage)><!--- headerBackgroundImage --->
		<cfset application.themeSettingsArray[6][15] = trim(getSettingsByTheme('highcontrast').menuBackgroundImage)><!--- menuBackgroundImage --->
		<cfset application.themeSettingsArray[6][16] = trim(getSettingsByTheme('highcontrast').coverKendoMenuWithMenuBackgroundImage)><!--- coverKendoMenuWithMenuBackgroundImage --->
		<cfset application.themeSettingsArray[6][17] = trim(getSettingsByTheme('highcontrast').logoImageMobile)><!--- logoImageMobile --->
		<cfset application.themeSettingsArray[6][18] = trim(getSettingsByTheme('highcontrast').logoMobileWidth)><!--- logoMobileWidth --->
		<cfset application.themeSettingsArray[6][19] = trim(getSettingsByTheme('highcontrast').logoImage)><!--- logoImage --->
		<cfset application.themeSettingsArray[6][20] = trim(getSettingsByTheme('highcontrast').logoPaddingTop)><!--- logoPaddingTop --->
		<cfset application.themeSettingsArray[6][21] = trim(getSettingsByTheme('highcontrast').logoPaddingRight)><!--- logoPaddingRight --->
		<cfset application.themeSettingsArray[6][22] = trim(getSettingsByTheme('highcontrast').logoPaddingLeft)><!--- logoPaddingLeft --->
		<cfset application.themeSettingsArray[6][23] = trim(getSettingsByTheme('highcontrast').logoPaddingBottom)><!--- logoPaddingBottom --->
		<cfset application.themeSettingsArray[6][24] = trim(getSettingsByTheme('highcontrast').blogNameTextColor)><!--- blogNameTextColor --->
		<cfset application.themeSettingsArray[6][25] = trim(getSettingsByTheme('highcontrast').headerBodyDividerImage)><!--- headerBodyDividerImage --->
		<cfset application.themeSettingsArray[6][26] = trim(getSettingsByTheme('highcontrast').kendoThemeCssFileLocation)><!--- kendoThemeCssFileLocation --->
		<cfset application.themeSettingsArray[6][27] = trim(getSettingsByTheme('highcontrast').kendoThemeMobileCssFileLocation)><!--- kendoThemeMobileCssFileLocation --->
		<cfset application.themeSettingsArray[6][28] = trim(getSettingsByTheme('highcontrast').customCoreLogicTemplate)><!--- customCoreLogicTemplate --->
		<cfset application.themeSettingsArray[6][29] = trim(getSettingsByTheme('highcontrast').customHeadTemplate)><!--- customHeadTemplate --->
		<cfset application.themeSettingsArray[6][30] = trim(getSettingsByTheme('highcontrast').customBodyString)><!--- customBodyString --->
		<cfset application.themeSettingsArray[6][31] = trim(getSettingsByTheme('highcontrast').customFontCssTemplate)><!--- customFontCssTemplate --->
		<cfset application.themeSettingsArray[6][32] = trim(getSettingsByTheme('highcontrast').customGlobalAndBodyCssTemplate)><!--- customGlobalAndBodyCssTemplate --->
		<cfset application.themeSettingsArray[6][33] = trim(getSettingsByTheme('highcontrast').customTopMenuCssTemplate)><!--- customTopMenuCssTemplate --->
		<cfset application.themeSettingsArray[6][34] = trim(getSettingsByTheme('highcontrast').customTopMenuHtmlTemplate)><!--- customTopMenuHtmlTemplate --->
		<cfset application.themeSettingsArray[6][35] = trim(getSettingsByTheme('highcontrast').customTopMenuJsTemplate)><!--- customTopMenuJsTemplate --->
		<cfset application.themeSettingsArray[6][36] = trim(getSettingsByTheme('highcontrast').customBlogContentCssTemplate)><!--- customBlogContentCssTemplate --->
		<cfset application.themeSettingsArray[6][37] = trim(getSettingsByTheme('highcontrast').customBlogJsContentTemplate)><!--- customBlogJsContentTemplate --->
		<cfset application.themeSettingsArray[6][38] = trim(getSettingsByTheme('highcontrast').customBlogContentHtmlTemplate)><!--- customBlogContentHtmlTemplate --->
		<cfset application.themeSettingsArray[6][39] = trim(getSettingsByTheme('highcontrast').customFooterHtmlTemplate)><!--- customFooterHtmlTemplate --->
		<!--- ************************************************************* material theme settings. ************************************************************* --->
		<cfset application.themeSettingsArray[7][1] = trim(getSettingsByTheme('material').useCustomTheme)><!--- useCustomTheme --->
		<cfset application.themeSettingsArray[7][2] = trim(getSettingsByTheme('material').customThemeName)><!--- customThemeName --->
		<cfset application.themeSettingsArray[7][3] = trim(getSettingsByTheme('material').darkTheme)><!--- darkTheme --->
		<cfset application.themeSettingsArray[7][4] = trim(getSettingsByTheme('material').contentWidth)><!--- contentWidth --->
		<cfset application.themeSettingsArray[7][5] = trim(getSettingsByTheme('material').mainContainerWidth)><!--- mainContainerWidth --->
		<cfset application.themeSettingsArray[7][6] = trim(getSettingsByTheme('material').sideBarContainerWidth)><!--- sideBarContainerWidth --->
		<cfset application.themeSettingsArray[7][7] = trim(getSettingsByTheme('material').siteOpacity)><!--- siteOpacity --->
		<cfset application.themeSettingsArray[7][8] = trim(getSettingsByTheme('material').blogBackgroundImage)><!--- blogBackgroundImage --->
		<cfset application.themeSettingsArray[7][9] = trim(getSettingsByTheme('material').blogBackgroundImageRepeat)><!--- blogBackgroundImageRepeat --->
		<cfset application.themeSettingsArray[7][10] = trim(getSettingsByTheme('material').blogBackgroundImagePosition)><!--- blogBackgroundImagePosition --->
		<cfset application.themeSettingsArray[7][11] = trim(getSettingsByTheme('material').stretchHeaderAcrossPage)><!--- stretchHeaderAcrossPage --->
		<cfset application.themeSettingsArray[7][12] = trim(getSettingsByTheme('material').alignBlogMenuWithBlogContent)><!--- alignBlogMenuWithBlogContent --->
		<cfset application.themeSettingsArray[7][13] = trim(getSettingsByTheme('material').topMenuAlign)><!--- topMenuAlign --->
		<cfset application.themeSettingsArray[7][14] = trim(getSettingsByTheme('material').headerBackgroundImage)><!--- headerBackgroundImage --->
		<cfset application.themeSettingsArray[7][15] = trim(getSettingsByTheme('material').menuBackgroundImage)><!--- menuBackgroundImage --->
		<cfset application.themeSettingsArray[7][16] = trim(getSettingsByTheme('material').coverKendoMenuWithMenuBackgroundImage)><!--- coverKendoMenuWithMenuBackgroundImage --->
		<cfset application.themeSettingsArray[7][17] = trim(getSettingsByTheme('material').logoImageMobile)><!--- logoImageMobile --->
		<cfset application.themeSettingsArray[7][18] = trim(getSettingsByTheme('material').logoMobileWidth)><!--- logoMobileWidth --->
		<cfset application.themeSettingsArray[7][19] = trim(getSettingsByTheme('material').logoImage)><!--- logoImage --->
		<cfset application.themeSettingsArray[7][20] = trim(getSettingsByTheme('material').logoPaddingTop)><!--- logoPaddingTop --->
		<cfset application.themeSettingsArray[7][21] = trim(getSettingsByTheme('material').logoPaddingRight)><!--- logoPaddingRight --->
		<cfset application.themeSettingsArray[7][22] = trim(getSettingsByTheme('material').logoPaddingLeft)><!--- logoPaddingLeft --->
		<cfset application.themeSettingsArray[7][23] = trim(getSettingsByTheme('material').logoPaddingBottom)><!--- logoPaddingBottom --->
		<cfset application.themeSettingsArray[7][24] = trim(getSettingsByTheme('material').blogNameTextColor)><!--- blogNameTextColor --->
		<cfset application.themeSettingsArray[7][25] = trim(getSettingsByTheme('material').headerBodyDividerImage)><!--- headerBodyDividerImage --->
		<cfset application.themeSettingsArray[7][26] = trim(getSettingsByTheme('material').kendoThemeCssFileLocation)><!--- kendoThemeCssFileLocation --->
		<cfset application.themeSettingsArray[7][27] = trim(getSettingsByTheme('material').kendoThemeMobileCssFileLocation)><!--- kendoThemeMobileCssFileLocation --->
		<cfset application.themeSettingsArray[7][28] = trim(getSettingsByTheme('material').customCoreLogicTemplate)><!--- customCoreLogicTemplate --->
		<cfset application.themeSettingsArray[7][29] = trim(getSettingsByTheme('material').customHeadTemplate)><!--- customHeadTemplate --->
		<cfset application.themeSettingsArray[7][30] = trim(getSettingsByTheme('material').customBodyString)><!--- customBodyString --->
		<cfset application.themeSettingsArray[7][31] = trim(getSettingsByTheme('material').customFontCssTemplate)><!--- customFontCssTemplate --->
		<cfset application.themeSettingsArray[7][32] = trim(getSettingsByTheme('material').customGlobalAndBodyCssTemplate)><!--- customGlobalAndBodyCssTemplate --->
		<cfset application.themeSettingsArray[7][33] = trim(getSettingsByTheme('material').customTopMenuCssTemplate)><!--- customTopMenuCssTemplate --->
		<cfset application.themeSettingsArray[7][34] = trim(getSettingsByTheme('material').customTopMenuHtmlTemplate)><!--- customTopMenuHtmlTemplate --->
		<cfset application.themeSettingsArray[7][35] = trim(getSettingsByTheme('material').customTopMenuJsTemplate)><!--- customTopMenuJsTemplate --->
		<cfset application.themeSettingsArray[7][36] = trim(getSettingsByTheme('material').customBlogContentCssTemplate)><!--- customBlogContentCssTemplate --->
		<cfset application.themeSettingsArray[7][37] = trim(getSettingsByTheme('material').customBlogJsContentTemplate)><!--- customBlogJsContentTemplate --->
		<cfset application.themeSettingsArray[7][38] = trim(getSettingsByTheme('material').customBlogContentHtmlTemplate)><!--- customBlogContentHtmlTemplate --->
		<cfset application.themeSettingsArray[7][39] = trim(getSettingsByTheme('material').customFooterHtmlTemplate)><!--- customFooterHtmlTemplate --->
		<!--- ************************************************************* materialblack theme settings. ************************************************************* --->
		<cfset application.themeSettingsArray[8][1] = trim(getSettingsByTheme('materialblack').useCustomTheme)><!--- useCustomTheme --->
		<cfset application.themeSettingsArray[8][2] = trim(getSettingsByTheme('materialblack').customThemeName)><!--- customThemeName --->
		<cfset application.themeSettingsArray[8][3] = trim(getSettingsByTheme('materialblack').darkTheme)><!--- darkTheme --->
		<cfset application.themeSettingsArray[8][4] = trim(getSettingsByTheme('materialblack').contentWidth)><!--- contentWidth --->
		<cfset application.themeSettingsArray[8][5] = trim(getSettingsByTheme('materialblack').mainContainerWidth)><!--- mainContainerWidth --->
		<cfset application.themeSettingsArray[8][6] = trim(getSettingsByTheme('materialblack').sideBarContainerWidth)><!--- sideBarContainerWidth --->
		<cfset application.themeSettingsArray[8][7] = trim(getSettingsByTheme('materialblack').siteOpacity)><!--- siteOpacity --->
		<cfset application.themeSettingsArray[8][8] = trim(getSettingsByTheme('materialblack').blogBackgroundImage)><!--- blogBackgroundImage --->
		<cfset application.themeSettingsArray[8][9] = trim(getSettingsByTheme('materialblack').blogBackgroundImageRepeat)><!--- blogBackgroundImageRepeat --->
		<cfset application.themeSettingsArray[8][10] = trim(getSettingsByTheme('materialblack').blogBackgroundImagePosition)><!--- blogBackgroundImagePosition --->
		<cfset application.themeSettingsArray[8][11] = trim(getSettingsByTheme('materialblack').stretchHeaderAcrossPage)><!--- stretchHeaderAcrossPage --->
		<cfset application.themeSettingsArray[8][12] = trim(getSettingsByTheme('materialblack').alignBlogMenuWithBlogContent)><!--- alignBlogMenuWithBlogContent --->
		<cfset application.themeSettingsArray[8][13] = trim(getSettingsByTheme('materialblack').topMenuAlign)><!--- topMenuAlign --->
		<cfset application.themeSettingsArray[8][14] = trim(getSettingsByTheme('materialblack').headerBackgroundImage)><!--- headerBackgroundImage --->
		<cfset application.themeSettingsArray[8][15] = trim(getSettingsByTheme('materialblack').menuBackgroundImage)><!--- menuBackgroundImage --->
		<cfset application.themeSettingsArray[8][16] = trim(getSettingsByTheme('materialblack').coverKendoMenuWithMenuBackgroundImage)><!--- coverKendoMenuWithMenuBackgroundImage --->
		<cfset application.themeSettingsArray[8][17] = trim(getSettingsByTheme('materialblack').logoImageMobile)><!--- logoImageMobile --->
		<cfset application.themeSettingsArray[8][18] = trim(getSettingsByTheme('materialblack').logoMobileWidth)><!--- logoMobileWidth --->
		<cfset application.themeSettingsArray[8][19] = trim(getSettingsByTheme('materialblack').logoImage)><!--- logoImage --->
		<cfset application.themeSettingsArray[8][20] = trim(getSettingsByTheme('materialblack').logoPaddingTop)><!--- logoPaddingTop --->
		<cfset application.themeSettingsArray[8][21] = trim(getSettingsByTheme('materialblack').logoPaddingRight)><!--- logoPaddingRight --->
		<cfset application.themeSettingsArray[8][22] = trim(getSettingsByTheme('materialblack').logoPaddingLeft)><!--- logoPaddingLeft --->
		<cfset application.themeSettingsArray[8][23] = trim(getSettingsByTheme('materialblack').logoPaddingBottom)><!--- logoPaddingBottom --->
		<cfset application.themeSettingsArray[8][24] = trim(getSettingsByTheme('materialblack').blogNameTextColor)><!--- blogNameTextColor --->
		<cfset application.themeSettingsArray[8][25] = trim(getSettingsByTheme('materialblack').headerBodyDividerImage)><!--- headerBodyDividerImage --->
		<cfset application.themeSettingsArray[8][26] = trim(getSettingsByTheme('materialblack').kendoThemeCssFileLocation)><!--- kendoThemeCssFileLocation --->
		<cfset application.themeSettingsArray[8][27] = trim(getSettingsByTheme('materialblack').kendoThemeMobileCssFileLocation)><!--- kendoThemeMobileCssFileLocation --->
		<cfset application.themeSettingsArray[8][28] = trim(getSettingsByTheme('materialblack').customCoreLogicTemplate)><!--- customCoreLogicTemplate --->
		<cfset application.themeSettingsArray[8][29] = trim(getSettingsByTheme('materialblack').customHeadTemplate)><!--- customHeadTemplate --->
		<cfset application.themeSettingsArray[8][30] = trim(getSettingsByTheme('materialblack').customBodyString)><!--- customBodyString --->
		<cfset application.themeSettingsArray[8][31] = trim(getSettingsByTheme('materialblack').customFontCssTemplate)><!--- customFontCssTemplate --->
		<cfset application.themeSettingsArray[8][32] = trim(getSettingsByTheme('materialblack').customGlobalAndBodyCssTemplate)><!--- customGlobalAndBodyCssTemplate --->
		<cfset application.themeSettingsArray[8][33] = trim(getSettingsByTheme('materialblack').customTopMenuCssTemplate)><!--- customTopMenuCssTemplate --->
		<cfset application.themeSettingsArray[8][34] = trim(getSettingsByTheme('materialblack').customTopMenuHtmlTemplate)><!--- customTopMenuHtmlTemplate --->
		<cfset application.themeSettingsArray[8][35] = trim(getSettingsByTheme('materialblack').customTopMenuJsTemplate)><!--- customTopMenuJsTemplate --->
		<cfset application.themeSettingsArray[8][36] = trim(getSettingsByTheme('materialblack').customBlogContentCssTemplate)><!--- customBlogContentCssTemplate --->
		<cfset application.themeSettingsArray[8][37] = trim(getSettingsByTheme('materialblack').customBlogJsContentTemplate)><!--- customBlogJsContentTemplate --->
		<cfset application.themeSettingsArray[8][38] = trim(getSettingsByTheme('materialblack').customBlogContentHtmlTemplate)><!--- customBlogContentHtmlTemplate --->
		<cfset application.themeSettingsArray[8][39] = trim(getSettingsByTheme('materialblack').customFooterHtmlTemplate)><!--- customFooterHtmlTemplate --->
		<!--- ************************************************************* metro theme settings. ************************************************************* --->
		<cfset application.themeSettingsArray[9][1] = trim(getSettingsByTheme('metro').useCustomTheme)><!--- useCustomTheme --->
		<cfset application.themeSettingsArray[9][2] = trim(getSettingsByTheme('metro').customThemeName)><!--- customThemeName --->
		<cfset application.themeSettingsArray[9][3] = trim(getSettingsByTheme('metro').darkTheme)><!--- darkTheme --->
		<cfset application.themeSettingsArray[9][4] = trim(getSettingsByTheme('metro').contentWidth)><!--- contentWidth --->
		<cfset application.themeSettingsArray[9][5] = trim(getSettingsByTheme('metro').mainContainerWidth)><!--- mainContainerWidth --->
		<cfset application.themeSettingsArray[9][6] = trim(getSettingsByTheme('metro').sideBarContainerWidth)><!--- sideBarContainerWidth --->
		<cfset application.themeSettingsArray[9][7] = trim(getSettingsByTheme('metro').siteOpacity)><!--- siteOpacity --->
		<cfset application.themeSettingsArray[9][8] = trim(getSettingsByTheme('metro').blogBackgroundImage)><!--- blogBackgroundImage --->
		<cfset application.themeSettingsArray[9][9] = trim(getSettingsByTheme('metro').blogBackgroundImageRepeat)><!--- blogBackgroundImageRepeat --->
		<cfset application.themeSettingsArray[9][10] = trim(getSettingsByTheme('metro').blogBackgroundImagePosition)><!--- blogBackgroundImagePosition --->
		<cfset application.themeSettingsArray[9][11] = trim(getSettingsByTheme('metro').stretchHeaderAcrossPage)><!--- stretchHeaderAcrossPage --->
		<cfset application.themeSettingsArray[9][12] = trim(getSettingsByTheme('metro').alignBlogMenuWithBlogContent)><!--- alignBlogMenuWithBlogContent --->
		<cfset application.themeSettingsArray[9][13] = trim(getSettingsByTheme('metro').topMenuAlign)><!--- topMenuAlign --->
		<cfset application.themeSettingsArray[9][14] = trim(getSettingsByTheme('metro').headerBackgroundImage)><!--- headerBackgroundImage --->
		<cfset application.themeSettingsArray[9][15] = trim(getSettingsByTheme('metro').menuBackgroundImage)><!--- menuBackgroundImage --->
		<cfset application.themeSettingsArray[9][16] = trim(getSettingsByTheme('metro').coverKendoMenuWithMenuBackgroundImage)><!--- coverKendoMenuWithMenuBackgroundImage --->
		<cfset application.themeSettingsArray[9][17] = trim(getSettingsByTheme('metro').logoImageMobile)><!--- logoImageMobile --->
		<cfset application.themeSettingsArray[9][18] = trim(getSettingsByTheme('metro').logoMobileWidth)><!--- logoMobileWidth --->
		<cfset application.themeSettingsArray[9][19] = trim(getSettingsByTheme('metro').logoImage)><!--- logoImage --->
		<cfset application.themeSettingsArray[9][20] = trim(getSettingsByTheme('metro').logoPaddingTop)><!--- logoPaddingTop --->
		<cfset application.themeSettingsArray[9][21] = trim(getSettingsByTheme('metro').logoPaddingRight)><!--- logoPaddingRight --->
		<cfset application.themeSettingsArray[9][22] = trim(getSettingsByTheme('metro').logoPaddingLeft)><!--- logoPaddingLeft --->
		<cfset application.themeSettingsArray[9][23] = trim(getSettingsByTheme('metro').logoPaddingBottom)><!--- logoPaddingBottom --->
		<cfset application.themeSettingsArray[9][24] = trim(getSettingsByTheme('metro').blogNameTextColor)><!--- blogNameTextColor --->
		<cfset application.themeSettingsArray[9][25] = trim(getSettingsByTheme('metro').headerBodyDividerImage)><!--- headerBodyDividerImage --->
		<cfset application.themeSettingsArray[9][26] = trim(getSettingsByTheme('metro').kendoThemeCssFileLocation)><!--- kendoThemeCssFileLocation --->
		<cfset application.themeSettingsArray[9][27] = trim(getSettingsByTheme('metro').kendoThemeMobileCssFileLocation)><!--- kendoThemeMobileCssFileLocation --->
		<cfset application.themeSettingsArray[9][28] = trim(getSettingsByTheme('metro').customCoreLogicTemplate)><!--- customCoreLogicTemplate --->
		<cfset application.themeSettingsArray[9][29] = trim(getSettingsByTheme('metro').customHeadTemplate)><!--- customHeadTemplate --->
		<cfset application.themeSettingsArray[9][30] = trim(getSettingsByTheme('metro').customBodyString)><!--- customBodyString --->
		<cfset application.themeSettingsArray[9][31] = trim(getSettingsByTheme('metro').customFontCssTemplate)><!--- customFontCssTemplate --->
		<cfset application.themeSettingsArray[9][32] = trim(getSettingsByTheme('metro').customGlobalAndBodyCssTemplate)><!--- customGlobalAndBodyCssTemplate --->
		<cfset application.themeSettingsArray[9][33] = trim(getSettingsByTheme('metro').customTopMenuCssTemplate)><!--- customTopMenuCssTemplate --->
		<cfset application.themeSettingsArray[9][34] = trim(getSettingsByTheme('metro').customTopMenuHtmlTemplate)><!--- customTopMenuHtmlTemplate --->
		<cfset application.themeSettingsArray[9][35] = trim(getSettingsByTheme('metro').customTopMenuJsTemplate)><!--- customTopMenuJsTemplate --->
		<cfset application.themeSettingsArray[9][36] = trim(getSettingsByTheme('metro').customBlogContentCssTemplate)><!--- customBlogContentCssTemplate --->
		<cfset application.themeSettingsArray[9][37] = trim(getSettingsByTheme('metro').customBlogJsContentTemplate)><!--- customBlogJsContentTemplate --->
		<cfset application.themeSettingsArray[9][38] = trim(getSettingsByTheme('metro').customBlogContentHtmlTemplate)><!--- customBlogContentHtmlTemplate --->
		<cfset application.themeSettingsArray[9][39] = trim(getSettingsByTheme('metro').customFooterHtmlTemplate)><!--- customFooterHtmlTemplate --->
		<!--- ************************************************************* moonlight theme settings. ************************************************************* --->
		<cfset application.themeSettingsArray[10][1] = trim(getSettingsByTheme('moonlight').useCustomTheme)><!--- useCustomTheme --->
		<cfset application.themeSettingsArray[10][2] = trim(getSettingsByTheme('moonlight').customThemeName)><!--- customThemeName --->
		<cfset application.themeSettingsArray[10][3] = trim(getSettingsByTheme('moonlight').darkTheme)><!--- darkTheme --->
		<cfset application.themeSettingsArray[10][4] = trim(getSettingsByTheme('moonlight').contentWidth)><!--- contentWidth --->
		<cfset application.themeSettingsArray[10][5] = trim(getSettingsByTheme('moonlight').mainContainerWidth)><!--- mainContainerWidth --->
		<cfset application.themeSettingsArray[10][6] = trim(getSettingsByTheme('moonlight').sideBarContainerWidth)><!--- sideBarContainerWidth --->
		<cfset application.themeSettingsArray[10][7] = trim(getSettingsByTheme('moonlight').siteOpacity)><!--- siteOpacity --->
		<cfset application.themeSettingsArray[10][8] = trim(getSettingsByTheme('moonlight').blogBackgroundImage)><!--- blogBackgroundImage --->
		<cfset application.themeSettingsArray[10][9] = trim(getSettingsByTheme('moonlight').blogBackgroundImageRepeat)><!--- blogBackgroundImageRepeat --->
		<cfset application.themeSettingsArray[10][10] = trim(getSettingsByTheme('moonlight').blogBackgroundImagePosition)><!--- blogBackgroundImagePosition --->
		<cfset application.themeSettingsArray[10][11] = trim(getSettingsByTheme('moonlight').stretchHeaderAcrossPage)><!--- stretchHeaderAcrossPage --->
		<cfset application.themeSettingsArray[10][12] = trim(getSettingsByTheme('moonlight').alignBlogMenuWithBlogContent)><!--- alignBlogMenuWithBlogContent --->
		<cfset application.themeSettingsArray[10][13] = trim(getSettingsByTheme('moonlight').topMenuAlign)><!--- topMenuAlign --->
		<cfset application.themeSettingsArray[10][14] = trim(getSettingsByTheme('moonlight').headerBackgroundImage)><!--- headerBackgroundImage --->
		<cfset application.themeSettingsArray[10][15] = trim(getSettingsByTheme('moonlight').menuBackgroundImage)><!--- menuBackgroundImage --->
		<cfset application.themeSettingsArray[10][16] = trim(getSettingsByTheme('moonlight').coverKendoMenuWithMenuBackgroundImage)><!--- coverKendoMenuWithMenuBackgroundImage --->
		<cfset application.themeSettingsArray[10][17] = trim(getSettingsByTheme('moonlight').logoImageMobile)><!--- logoImageMobile --->
		<cfset application.themeSettingsArray[10][18] = trim(getSettingsByTheme('moonlight').logoMobileWidth)><!--- logoMobileWidth --->
		<cfset application.themeSettingsArray[10][19] = trim(getSettingsByTheme('moonlight').logoImage)><!--- logoImage --->
		<cfset application.themeSettingsArray[10][20] = trim(getSettingsByTheme('moonlight').logoPaddingTop)><!--- logoPaddingTop --->
		<cfset application.themeSettingsArray[10][21] = trim(getSettingsByTheme('moonlight').logoPaddingRight)><!--- logoPaddingRight --->
		<cfset application.themeSettingsArray[10][22] = trim(getSettingsByTheme('moonlight').logoPaddingLeft)><!--- logoPaddingLeft --->
		<cfset application.themeSettingsArray[10][23] = trim(getSettingsByTheme('moonlight').logoPaddingBottom)><!--- logoPaddingBottom --->
		<cfset application.themeSettingsArray[10][24] = trim(getSettingsByTheme('moonlight').blogNameTextColor)><!--- blogNameTextColor --->
		<cfset application.themeSettingsArray[10][25] = trim(getSettingsByTheme('moonlight').headerBodyDividerImage)><!--- headerBodyDividerImage --->
		<cfset application.themeSettingsArray[10][26] = trim(getSettingsByTheme('moonlight').kendoThemeCssFileLocation)><!--- kendoThemeCssFileLocation --->
		<cfset application.themeSettingsArray[10][27] = trim(getSettingsByTheme('moonlight').kendoThemeMobileCssFileLocation)><!--- kendoThemeMobileCssFileLocation --->
		<cfset application.themeSettingsArray[10][28] = trim(getSettingsByTheme('moonlight').customCoreLogicTemplate)><!--- customCoreLogicTemplate --->
		<cfset application.themeSettingsArray[10][29] = trim(getSettingsByTheme('moonlight').customHeadTemplate)><!--- customHeadTemplate --->
		<cfset application.themeSettingsArray[10][30] = trim(getSettingsByTheme('moonlight').customBodyString)><!--- customBodyString --->
		<cfset application.themeSettingsArray[10][31] = trim(getSettingsByTheme('moonlight').customFontCssTemplate)><!--- customFontCssTemplate --->
		<cfset application.themeSettingsArray[10][32] = trim(getSettingsByTheme('moonlight').customGlobalAndBodyCssTemplate)><!--- customGlobalAndBodyCssTemplate --->
		<cfset application.themeSettingsArray[10][33] = trim(getSettingsByTheme('moonlight').customTopMenuCssTemplate)><!--- customTopMenuCssTemplate --->
		<cfset application.themeSettingsArray[10][34] = trim(getSettingsByTheme('moonlight').customTopMenuHtmlTemplate)><!--- customTopMenuHtmlTemplate --->
		<cfset application.themeSettingsArray[10][35] = trim(getSettingsByTheme('moonlight').customTopMenuJsTemplate)><!--- customTopMenuJsTemplate --->
		<cfset application.themeSettingsArray[10][36] = trim(getSettingsByTheme('moonlight').customBlogContentCssTemplate)><!--- customBlogContentCssTemplate --->
		<cfset application.themeSettingsArray[10][37] = trim(getSettingsByTheme('moonlight').customBlogJsContentTemplate)><!--- customBlogJsContentTemplate --->
		<cfset application.themeSettingsArray[10][38] = trim(getSettingsByTheme('moonlight').customBlogContentHtmlTemplate)><!--- customBlogContentHtmlTemplate --->
		<cfset application.themeSettingsArray[10][39] = trim(getSettingsByTheme('moonlight').customFooterHtmlTemplate)><!--- customFooterHtmlTemplate --->
		<!--- ************************************************************* nova theme settings. ************************************************************* --->
		<cfset application.themeSettingsArray[11][1] = trim(getSettingsByTheme('nova').useCustomTheme)><!--- useCustomTheme --->
		<cfset application.themeSettingsArray[11][2] = trim(getSettingsByTheme('nova').customThemeName)><!--- customThemeName --->
		<cfset application.themeSettingsArray[11][3] = trim(getSettingsByTheme('nova').darkTheme)><!--- darkTheme --->
		<cfset application.themeSettingsArray[11][4] = trim(getSettingsByTheme('nova').contentWidth)><!--- contentWidth --->
		<cfset application.themeSettingsArray[11][5] = trim(getSettingsByTheme('nova').mainContainerWidth)><!--- mainContainerWidth --->
		<cfset application.themeSettingsArray[11][6] = trim(getSettingsByTheme('nova').sideBarContainerWidth)><!--- sideBarContainerWidth --->
		<cfset application.themeSettingsArray[11][7] = trim(getSettingsByTheme('nova').siteOpacity)><!--- siteOpacity --->
		<cfset application.themeSettingsArray[11][8] = trim(getSettingsByTheme('nova').blogBackgroundImage)><!--- blogBackgroundImage --->
		<cfset application.themeSettingsArray[11][9] = trim(getSettingsByTheme('nova').blogBackgroundImageRepeat)><!--- blogBackgroundImageRepeat --->
		<cfset application.themeSettingsArray[11][10] = trim(getSettingsByTheme('nova').blogBackgroundImagePosition)><!--- blogBackgroundImagePosition --->
		<cfset application.themeSettingsArray[11][11] = trim(getSettingsByTheme('nova').stretchHeaderAcrossPage)><!--- stretchHeaderAcrossPage --->
		<cfset application.themeSettingsArray[11][12] = trim(getSettingsByTheme('nova').alignBlogMenuWithBlogContent)><!--- alignBlogMenuWithBlogContent --->
		<cfset application.themeSettingsArray[11][13] = trim(getSettingsByTheme('nova').topMenuAlign)><!--- topMenuAlign --->
		<cfset application.themeSettingsArray[11][14] = trim(getSettingsByTheme('nova').headerBackgroundImage)><!--- headerBackgroundImage --->
		<cfset application.themeSettingsArray[11][15] = trim(getSettingsByTheme('nova').menuBackgroundImage)><!--- menuBackgroundImage --->
		<cfset application.themeSettingsArray[11][16] = trim(getSettingsByTheme('nova').coverKendoMenuWithMenuBackgroundImage)><!--- coverKendoMenuWithMenuBackgroundImage --->
		<cfset application.themeSettingsArray[11][17] = trim(getSettingsByTheme('nova').logoImageMobile)><!--- logoImageMobile --->
		<cfset application.themeSettingsArray[11][18] = trim(getSettingsByTheme('nova').logoMobileWidth)><!--- logoMobileWidth --->
		<cfset application.themeSettingsArray[11][19] = trim(getSettingsByTheme('nova').logoImage)><!--- logoImage --->
		<cfset application.themeSettingsArray[11][20] = trim(getSettingsByTheme('nova').logoPaddingTop)><!--- logoPaddingTop --->
		<cfset application.themeSettingsArray[11][21] = trim(getSettingsByTheme('nova').logoPaddingRight)><!--- logoPaddingRight --->
		<cfset application.themeSettingsArray[11][22] = trim(getSettingsByTheme('nova').logoPaddingLeft)><!--- logoPaddingLeft --->
		<cfset application.themeSettingsArray[11][23] = trim(getSettingsByTheme('nova').logoPaddingBottom)><!--- logoPaddingBottom --->
		<cfset application.themeSettingsArray[11][24] = trim(getSettingsByTheme('nova').blogNameTextColor)><!--- blogNameTextColor --->
		<cfset application.themeSettingsArray[11][25] = trim(getSettingsByTheme('nova').headerBodyDividerImage)><!--- headerBodyDividerImage --->
		<cfset application.themeSettingsArray[11][26] = trim(getSettingsByTheme('nova').kendoThemeCssFileLocation)><!--- kendoThemeCssFileLocation --->
		<cfset application.themeSettingsArray[11][27] = trim(getSettingsByTheme('nova').kendoThemeMobileCssFileLocation)><!--- kendoThemeMobileCssFileLocation --->
		<cfset application.themeSettingsArray[11][28] = trim(getSettingsByTheme('nova').customCoreLogicTemplate)><!--- customCoreLogicTemplate --->
		<cfset application.themeSettingsArray[11][29] = trim(getSettingsByTheme('nova').customHeadTemplate)><!--- customHeadTemplate --->
		<cfset application.themeSettingsArray[11][30] = trim(getSettingsByTheme('nova').customBodyString)><!--- customBodyString --->
		<cfset application.themeSettingsArray[11][31] = trim(getSettingsByTheme('nova').customFontCssTemplate)><!--- customFontCssTemplate --->
		<cfset application.themeSettingsArray[11][32] = trim(getSettingsByTheme('nova').customGlobalAndBodyCssTemplate)><!--- customGlobalAndBodyCssTemplate --->
		<cfset application.themeSettingsArray[11][33] = trim(getSettingsByTheme('nova').customTopMenuCssTemplate)><!--- customTopMenuCssTemplate --->
		<cfset application.themeSettingsArray[11][34] = trim(getSettingsByTheme('nova').customTopMenuHtmlTemplate)><!--- customTopMenuHtmlTemplate --->
		<cfset application.themeSettingsArray[11][35] = trim(getSettingsByTheme('nova').customTopMenuJsTemplate)><!--- customTopMenuJsTemplate --->
		<cfset application.themeSettingsArray[11][36] = trim(getSettingsByTheme('nova').customBlogContentCssTemplate)><!--- customBlogContentCssTemplate --->
		<cfset application.themeSettingsArray[11][37] = trim(getSettingsByTheme('nova').customBlogJsContentTemplate)><!--- customBlogJsContentTemplate --->
		<cfset application.themeSettingsArray[11][38] = trim(getSettingsByTheme('nova').customBlogContentHtmlTemplate)><!--- customBlogContentHtmlTemplate --->
		<cfset application.themeSettingsArray[11][39] = trim(getSettingsByTheme('nova').customFooterHtmlTemplate)><!--- customFooterHtmlTemplate --->
		<!--- ************************************************************* office365 theme settings. ************************************************************* --->
		<cfset application.themeSettingsArray[12][1] = trim(getSettingsByTheme('office365').useCustomTheme)><!--- useCustomTheme --->
		<cfset application.themeSettingsArray[12][2] = trim(getSettingsByTheme('office365').customThemeName)><!--- customThemeName --->
		<cfset application.themeSettingsArray[12][3] = trim(getSettingsByTheme('office365').darkTheme)><!--- darkTheme --->
		<cfset application.themeSettingsArray[12][4] = trim(getSettingsByTheme('office365').contentWidth)><!--- contentWidth --->
		<cfset application.themeSettingsArray[12][5] = trim(getSettingsByTheme('office365').mainContainerWidth)><!--- mainContainerWidth --->
		<cfset application.themeSettingsArray[12][6] = trim(getSettingsByTheme('office365').sideBarContainerWidth)><!--- sideBarContainerWidth --->
		<cfset application.themeSettingsArray[12][7] = trim(getSettingsByTheme('office365').siteOpacity)><!--- siteOpacity --->
		<cfset application.themeSettingsArray[12][8] = trim(getSettingsByTheme('office365').blogBackgroundImage)><!--- blogBackgroundImage --->
		<cfset application.themeSettingsArray[12][9] = trim(getSettingsByTheme('office365').blogBackgroundImageRepeat)><!--- blogBackgroundImageRepeat --->
		<cfset application.themeSettingsArray[12][10] = trim(getSettingsByTheme('office365').blogBackgroundImagePosition)><!--- blogBackgroundImagePosition --->
		<cfset application.themeSettingsArray[12][11] = trim(getSettingsByTheme('office365').stretchHeaderAcrossPage)><!--- stretchHeaderAcrossPage --->
		<cfset application.themeSettingsArray[12][12] = trim(getSettingsByTheme('office365').alignBlogMenuWithBlogContent)><!--- alignBlogMenuWithBlogContent --->
		<cfset application.themeSettingsArray[12][13] = trim(getSettingsByTheme('office365').topMenuAlign)><!--- topMenuAlign --->
		<cfset application.themeSettingsArray[12][14] = trim(getSettingsByTheme('office365').headerBackgroundImage)><!--- headerBackgroundImage --->
		<cfset application.themeSettingsArray[12][15] = trim(getSettingsByTheme('office365').menuBackgroundImage)><!--- menuBackgroundImage --->
		<cfset application.themeSettingsArray[12][16] = trim(getSettingsByTheme('office365').coverKendoMenuWithMenuBackgroundImage)><!--- coverKendoMenuWithMenuBackgroundImage --->
		<cfset application.themeSettingsArray[12][17] = trim(getSettingsByTheme('office365').logoImageMobile)><!--- logoImageMobile --->
		<cfset application.themeSettingsArray[12][18] = trim(getSettingsByTheme('office365').logoMobileWidth)><!--- logoMobileWidth --->
		<cfset application.themeSettingsArray[12][19] = trim(getSettingsByTheme('office365').logoImage)><!--- logoImage --->
		<cfset application.themeSettingsArray[12][20] = trim(getSettingsByTheme('office365').logoPaddingTop)><!--- logoPaddingTop --->
		<cfset application.themeSettingsArray[12][21] = trim(getSettingsByTheme('office365').logoPaddingRight)><!--- logoPaddingRight --->
		<cfset application.themeSettingsArray[12][22] = trim(getSettingsByTheme('office365').logoPaddingLeft)><!--- logoPaddingLeft --->
		<cfset application.themeSettingsArray[12][23] = trim(getSettingsByTheme('office365').logoPaddingBottom)><!--- logoPaddingBottom --->
		<cfset application.themeSettingsArray[12][24] = trim(getSettingsByTheme('office365').blogNameTextColor)><!--- blogNameTextColor --->
		<cfset application.themeSettingsArray[12][25] = trim(getSettingsByTheme('office365').headerBodyDividerImage)><!--- headerBodyDividerImage --->
		<cfset application.themeSettingsArray[12][26] = trim(getSettingsByTheme('office365').kendoThemeCssFileLocation)><!--- kendoThemeCssFileLocation --->
		<cfset application.themeSettingsArray[12][27] = trim(getSettingsByTheme('office365').kendoThemeMobileCssFileLocation)><!--- kendoThemeMobileCssFileLocation --->
		<cfset application.themeSettingsArray[12][28] = trim(getSettingsByTheme('office365').customCoreLogicTemplate)><!--- customCoreLogicTemplate --->
		<cfset application.themeSettingsArray[12][29] = trim(getSettingsByTheme('office365').customHeadTemplate)><!--- customHeadTemplate --->
		<cfset application.themeSettingsArray[12][30] = trim(getSettingsByTheme('office365').customBodyString)><!--- customBodyString --->
		<cfset application.themeSettingsArray[12][31] = trim(getSettingsByTheme('office365').customFontCssTemplate)><!--- customFontCssTemplate --->
		<cfset application.themeSettingsArray[12][32] = trim(getSettingsByTheme('office365').customGlobalAndBodyCssTemplate)><!--- customGlobalAndBodyCssTemplate --->
		<cfset application.themeSettingsArray[12][33] = trim(getSettingsByTheme('office365').customTopMenuCssTemplate)><!--- customTopMenuCssTemplate --->
		<cfset application.themeSettingsArray[12][34] = trim(getSettingsByTheme('office365').customTopMenuHtmlTemplate)><!--- customTopMenuHtmlTemplate --->
		<cfset application.themeSettingsArray[12][35] = trim(getSettingsByTheme('office365').customTopMenuJsTemplate)><!--- customTopMenuJsTemplate --->
		<cfset application.themeSettingsArray[12][36] = trim(getSettingsByTheme('office365').customBlogContentCssTemplate)><!--- customBlogContentCssTemplate --->
		<cfset application.themeSettingsArray[12][37] = trim(getSettingsByTheme('office365').customBlogJsContentTemplate)><!--- customBlogJsContentTemplate --->
		<cfset application.themeSettingsArray[12][38] = trim(getSettingsByTheme('office365').customBlogContentHtmlTemplate)><!--- customBlogContentHtmlTemplate --->
		<cfset application.themeSettingsArray[12][39] = trim(getSettingsByTheme('office365').customFooterHtmlTemplate)><!--- customFooterHtmlTemplate --->
		<!--- ************************************************************* silver theme settings. ************************************************************* --->
		<cfset application.themeSettingsArray[13][1] = trim(getSettingsByTheme('silver').useCustomTheme)><!--- useCustomTheme --->
		<cfset application.themeSettingsArray[13][2] = trim(getSettingsByTheme('silver').customThemeName)><!--- customThemeName --->
		<cfset application.themeSettingsArray[13][3] = trim(getSettingsByTheme('silver').darkTheme)><!--- darkTheme --->
		<cfset application.themeSettingsArray[13][4] = trim(getSettingsByTheme('silver').contentWidth)><!--- contentWidth --->
		<cfset application.themeSettingsArray[13][5] = trim(getSettingsByTheme('silver').mainContainerWidth)><!--- mainContainerWidth --->
		<cfset application.themeSettingsArray[13][6] = trim(getSettingsByTheme('silver').sideBarContainerWidth)><!--- sideBarContainerWidth --->
		<cfset application.themeSettingsArray[13][7] = trim(getSettingsByTheme('silver').siteOpacity)><!--- siteOpacity --->
		<cfset application.themeSettingsArray[13][8] = trim(getSettingsByTheme('silver').blogBackgroundImage)><!--- blogBackgroundImage --->
		<cfset application.themeSettingsArray[13][9] = trim(getSettingsByTheme('silver').blogBackgroundImageRepeat)><!--- blogBackgroundImageRepeat --->
		<cfset application.themeSettingsArray[13][10] = trim(getSettingsByTheme('silver').blogBackgroundImagePosition)><!--- blogBackgroundImagePosition --->
		<cfset application.themeSettingsArray[13][11] = trim(getSettingsByTheme('silver').stretchHeaderAcrossPage)><!--- stretchHeaderAcrossPage --->
		<cfset application.themeSettingsArray[13][12] = trim(getSettingsByTheme('silver').alignBlogMenuWithBlogContent)><!--- alignBlogMenuWithBlogContent --->
		<cfset application.themeSettingsArray[13][13] = trim(getSettingsByTheme('silver').topMenuAlign)><!--- topMenuAlign --->
		<cfset application.themeSettingsArray[13][14] = trim(getSettingsByTheme('silver').headerBackgroundImage)><!--- headerBackgroundImage --->
		<cfset application.themeSettingsArray[13][15] = trim(getSettingsByTheme('silver').menuBackgroundImage)><!--- menuBackgroundImage --->
		<cfset application.themeSettingsArray[13][16] = trim(getSettingsByTheme('silver').coverKendoMenuWithMenuBackgroundImage)><!--- coverKendoMenuWithMenuBackgroundImage --->
		<cfset application.themeSettingsArray[13][17] = trim(getSettingsByTheme('silver').logoImageMobile)><!--- logoImageMobile --->
		<cfset application.themeSettingsArray[13][18] = trim(getSettingsByTheme('silver').logoMobileWidth)><!--- logoMobileWidth --->
		<cfset application.themeSettingsArray[13][19] = trim(getSettingsByTheme('silver').logoImage)><!--- logoImage --->
		<cfset application.themeSettingsArray[13][20] = trim(getSettingsByTheme('silver').logoPaddingTop)><!--- logoPaddingTop --->
		<cfset application.themeSettingsArray[13][21] = trim(getSettingsByTheme('silver').logoPaddingRight)><!--- logoPaddingRight --->
		<cfset application.themeSettingsArray[13][22] = trim(getSettingsByTheme('silver').logoPaddingLeft)><!--- logoPaddingLeft --->
		<cfset application.themeSettingsArray[13][23] = trim(getSettingsByTheme('silver').logoPaddingBottom)><!--- logoPaddingBottom --->
		<cfset application.themeSettingsArray[13][24] = trim(getSettingsByTheme('silver').blogNameTextColor)><!--- blogNameTextColor --->
		<cfset application.themeSettingsArray[13][25] = trim(getSettingsByTheme('silver').headerBodyDividerImage)><!--- headerBodyDividerImage --->
		<cfset application.themeSettingsArray[13][26] = trim(getSettingsByTheme('silver').kendoThemeCssFileLocation)><!--- kendoThemeCssFileLocation --->
		<cfset application.themeSettingsArray[13][27] = trim(getSettingsByTheme('silver').kendoThemeMobileCssFileLocation)><!--- kendoThemeMobileCssFileLocation --->
		<cfset application.themeSettingsArray[13][28] = trim(getSettingsByTheme('silver').customCoreLogicTemplate)><!--- customCoreLogicTemplate --->
		<cfset application.themeSettingsArray[13][29] = trim(getSettingsByTheme('silver').customHeadTemplate)><!--- customHeadTemplate --->
		<cfset application.themeSettingsArray[13][30] = trim(getSettingsByTheme('silver').customBodyString)><!--- customBodyString --->
		<cfset application.themeSettingsArray[13][31] = trim(getSettingsByTheme('silver').customFontCssTemplate)><!--- customFontCssTemplate --->
		<cfset application.themeSettingsArray[13][32] = trim(getSettingsByTheme('silver').customGlobalAndBodyCssTemplate)><!--- customGlobalAndBodyCssTemplate --->
		<cfset application.themeSettingsArray[13][33] = trim(getSettingsByTheme('silver').customTopMenuCssTemplate)><!--- customTopMenuCssTemplate --->
		<cfset application.themeSettingsArray[13][34] = trim(getSettingsByTheme('silver').customTopMenuHtmlTemplate)><!--- customTopMenuHtmlTemplate --->
		<cfset application.themeSettingsArray[13][35] = trim(getSettingsByTheme('silver').customTopMenuJsTemplate)><!--- customTopMenuJsTemplate --->
		<cfset application.themeSettingsArray[13][36] = trim(getSettingsByTheme('silver').customBlogContentCssTemplate)><!--- customBlogContentCssTemplate --->
		<cfset application.themeSettingsArray[13][37] = trim(getSettingsByTheme('silver').customBlogJsContentTemplate)><!--- customBlogJsContentTemplate --->
		<cfset application.themeSettingsArray[13][38] = trim(getSettingsByTheme('silver').customBlogContentHtmlTemplate)><!--- customBlogContentHtmlTemplate --->
		<cfset application.themeSettingsArray[13][39] = trim(getSettingsByTheme('silver').customFooterHtmlTemplate)><!--- customFooterHtmlTemplate --->
		<!--- ************************************************************* uniform theme settings. ************************************************************* --->
		<cfset application.themeSettingsArray[14][1] = trim(getSettingsByTheme('uniform').useCustomTheme)><!--- useCustomTheme --->
		<cfset application.themeSettingsArray[14][2] = trim(getSettingsByTheme('uniform').customThemeName)><!--- customThemeName --->
		<cfset application.themeSettingsArray[14][3] = trim(getSettingsByTheme('uniform').darkTheme)><!--- darkTheme --->
		<cfset application.themeSettingsArray[14][4] = trim(getSettingsByTheme('uniform').contentWidth)><!--- contentWidth --->
		<cfset application.themeSettingsArray[14][5] = trim(getSettingsByTheme('uniform').mainContainerWidth)><!--- mainContainerWidth --->
		<cfset application.themeSettingsArray[14][6] = trim(getSettingsByTheme('uniform').sideBarContainerWidth)><!--- sideBarContainerWidth --->
		<cfset application.themeSettingsArray[14][7] = trim(getSettingsByTheme('uniform').siteOpacity)><!--- siteOpacity --->
		<cfset application.themeSettingsArray[14][8] = trim(getSettingsByTheme('uniform').blogBackgroundImage)><!--- blogBackgroundImage --->
		<cfset application.themeSettingsArray[14][9] = trim(getSettingsByTheme('uniform').blogBackgroundImageRepeat)><!--- blogBackgroundImageRepeat --->
		<cfset application.themeSettingsArray[14][10] = trim(getSettingsByTheme('uniform').blogBackgroundImagePosition)><!--- blogBackgroundImagePosition --->
		<cfset application.themeSettingsArray[14][11] = trim(getSettingsByTheme('uniform').stretchHeaderAcrossPage)><!--- stretchHeaderAcrossPage --->
		<cfset application.themeSettingsArray[14][12] = trim(getSettingsByTheme('uniform').alignBlogMenuWithBlogContent)><!--- alignBlogMenuWithBlogContent --->
		<cfset application.themeSettingsArray[14][13] = trim(getSettingsByTheme('uniform').topMenuAlign)><!--- topMenuAlign --->
		<cfset application.themeSettingsArray[14][14] = trim(getSettingsByTheme('uniform').headerBackgroundImage)><!--- headerBackgroundImage --->
		<cfset application.themeSettingsArray[14][15] = trim(getSettingsByTheme('uniform').menuBackgroundImage)><!--- menuBackgroundImage --->
		<cfset application.themeSettingsArray[14][16] = trim(getSettingsByTheme('uniform').coverKendoMenuWithMenuBackgroundImage)><!--- coverKendoMenuWithMenuBackgroundImage --->
		<cfset application.themeSettingsArray[14][17] = trim(getSettingsByTheme('uniform').logoImageMobile)><!--- logoImageMobile --->
		<cfset application.themeSettingsArray[14][18] = trim(getSettingsByTheme('uniform').logoMobileWidth)><!--- logoMobileWidth --->
		<cfset application.themeSettingsArray[14][19] = trim(getSettingsByTheme('uniform').logoImage)><!--- logoImage --->
		<cfset application.themeSettingsArray[14][20] = trim(getSettingsByTheme('uniform').logoPaddingTop)><!--- logoPaddingTop --->
		<cfset application.themeSettingsArray[14][21] = trim(getSettingsByTheme('uniform').logoPaddingRight)><!--- logoPaddingRight --->
		<cfset application.themeSettingsArray[14][22] = trim(getSettingsByTheme('uniform').logoPaddingLeft)><!--- logoPaddingLeft --->
		<cfset application.themeSettingsArray[14][23] = trim(getSettingsByTheme('uniform').logoPaddingBottom)><!--- logoPaddingBottom --->
		<cfset application.themeSettingsArray[14][24] = trim(getSettingsByTheme('uniform').blogNameTextColor)><!--- blogNameTextColor --->
		<cfset application.themeSettingsArray[14][25] = trim(getSettingsByTheme('uniform').headerBodyDividerImage)><!--- headerBodyDividerImage --->
		<cfset application.themeSettingsArray[14][26] = trim(getSettingsByTheme('uniform').kendoThemeCssFileLocation)><!--- kendoThemeCssFileLocation --->
		<cfset application.themeSettingsArray[14][27] = trim(getSettingsByTheme('uniform').kendoThemeMobileCssFileLocation)><!--- kendoThemeMobileCssFileLocation --->
		<cfset application.themeSettingsArray[14][28] = trim(getSettingsByTheme('uniform').customCoreLogicTemplate)><!--- customCoreLogicTemplate --->
		<cfset application.themeSettingsArray[14][29] = trim(getSettingsByTheme('uniform').customHeadTemplate)><!--- customHeadTemplate --->
		<cfset application.themeSettingsArray[14][30] = trim(getSettingsByTheme('uniform').customBodyString)><!--- customBodyString --->
		<cfset application.themeSettingsArray[14][31] = trim(getSettingsByTheme('uniform').customFontCssTemplate)><!--- customFontCssTemplate --->
		<cfset application.themeSettingsArray[14][32] = trim(getSettingsByTheme('uniform').customGlobalAndBodyCssTemplate)><!--- customGlobalAndBodyCssTemplate --->
		<cfset application.themeSettingsArray[14][33] = trim(getSettingsByTheme('uniform').customTopMenuCssTemplate)><!--- customTopMenuCssTemplate --->
		<cfset application.themeSettingsArray[14][34] = trim(getSettingsByTheme('uniform').customTopMenuHtmlTemplate)><!--- customTopMenuHtmlTemplate --->
		<cfset application.themeSettingsArray[14][35] = trim(getSettingsByTheme('uniform').customTopMenuJsTemplate)><!--- customTopMenuJsTemplate --->
		<cfset application.themeSettingsArray[14][36] = trim(getSettingsByTheme('uniform').customBlogContentCssTemplate)><!--- customBlogContentCssTemplate --->
		<cfset application.themeSettingsArray[14][37] = trim(getSettingsByTheme('uniform').customBlogJsContentTemplate)><!--- customBlogJsContentTemplate --->
		<cfset application.themeSettingsArray[14][38] = trim(getSettingsByTheme('uniform').customBlogContentHtmlTemplate)><!--- customBlogContentHtmlTemplate --->
		<cfset application.themeSettingsArray[14][39] = trim(getSettingsByTheme('uniform').customFooterHtmlTemplate)><!--- customFooterHtmlTemplate --->
		<cfset application.themeSettingsArray[15][1] = now()>
		<!--- Drop a cookie with the data so we can inspect when the initialization took place. --->
		<cfcookie name="themeVarsInitialized" value="#now()#"/>
			
	</cffunction>
					
	<!--- Set the theme setting by the theme Id. Note: this function can't be accessed remotely for security purposes. --->
	<cffunction name="setThemeSettingInIniStore" access="public" returntype="string" hint="Provides the theme setting stored in the configuration file.">
		<cfargument name="themeId"  required="true" hint="Pass in the theme Id."/>
		<cfargument name="themeSetting" required="true" hint="Pass in the setting."/>
		<cfargument name="themeValue" required="true" hint="Pass in the setting."/>

		<!--- Get the setting using the getProfileString method. --->
		<cfswitch expression="#arguments.themeSetting#">	
			<cfcase value="useCustomTheme">
				<cfset setting = setProfileString("#application.iniFile#", "#arguments.themeId#", "useCustomTheme", arguments.themeValue)>
			</cfcase>
			<cfcase value="customThemeName">
				<cfset setting = setProfileString("#application.iniFile#", "#arguments.themeId#", "customThemeName", arguments.themeValue)>
			</cfcase>
			<cfcase value="darkTheme">
				<cfset setting = setProfileString("#application.iniFile#", "#arguments.themeId#", "darkTheme", arguments.themeValue)>
			</cfcase>
			<cfcase value="contentWidth">
				<cfset setting = setProfileString("#application.iniFile#", "#arguments.themeId#", "contentWidth", arguments.themeValue)>
			</cfcase>
			<cfcase value="mainContainerWidth">
				<cfset setting = setProfileString("#application.iniFile#", "#arguments.themeId#", "mainContainerWidth", arguments.themeValue)>
			</cfcase>
			<cfcase value="sideBarContainerWidth">
				<cfset setting = setProfileString("#application.iniFile#", "#arguments.themeId#", "sideBarContainerWidth", arguments.themeValue)>
			</cfcase>
			<cfcase value="siteOpacity">
				<cfset setting = setProfileString("#application.iniFile#", "#arguments.themeId#", "siteOpacity", arguments.themeValue)>
			</cfcase>
			<cfcase value="blogBackgroundImage">
				<cfset setting = setProfileString("#application.iniFile#", "#arguments.themeId#", "blogBackgroundImage", arguments.themeValue)>
			</cfcase>
			<cfcase value="blogBackgroundImageRepeat">
				<cfset setting = setProfileString("#application.iniFile#", "#arguments.themeId#", "blogBackgroundImageRepeat", arguments.themeValue)>
			</cfcase>
			<cfcase value="blogBackgroundImagePosition">
				<cfset setting = setProfileString("#application.iniFile#", "#arguments.themeId#", "blogBackgroundImagePosition", arguments.themeValue)>
			</cfcase>
			<cfcase value="stretchHeaderAcrossPage">
				<cfset setting = setProfileString("#application.iniFile#", "#arguments.themeId#", "stretchHeaderAcrossPage", arguments.themeValue)>
			</cfcase>
			<cfcase value="alignBlogMenuWithBlogContent">
				<cfset setting = setProfileString("#application.iniFile#", "#arguments.themeId#", "alignBlogMenuWithBlogContent", arguments.themeValue)>
			</cfcase>
			<cfcase value="topMenuAlign">
				<cfset setting = setProfileString("#application.iniFile#", "#arguments.themeId#", "topMenuAlign", arguments.themeValue)>
			</cfcase>
			<cfcase value="headerBackgroundImage">
				<cfset setting = setProfileString("#application.iniFile#", "#arguments.themeId#", "headerBackgroundImage", arguments.themeValue)>
			</cfcase>
			<cfcase value="menuBackgroundImage">
				<cfset setting = setProfileString("#application.iniFile#", "#arguments.themeId#", "menuBackgroundImage", arguments.themeValue)>
			</cfcase>
			<cfcase value="coverKendoMenuWithMenuBackgroundImage">
				<cfset setting = setProfileString("#application.iniFile#", "#arguments.themeId#", "coverKendoMenuWithMenuBackgroundImage", arguments.themeValue)>
			</cfcase>
			<cfcase value="logoImageMobile">
				<cfset setting = setProfileString("#application.iniFile#", "#arguments.themeId#", "logoImageMobile", arguments.themeValue)>
			</cfcase>
			<cfcase value="logoMobileWidth">
				<cfset setting = setProfileString("#application.iniFile#", "#arguments.themeId#", "logoMobileWidth", arguments.themeValue)>
			</cfcase>
			<cfcase value="logoImage">
				<cfset setting = setProfileString("#application.iniFile#", "#arguments.themeId#", "logoImage", arguments.themeValue)>
			</cfcase>
			<cfcase value="logoPaddingTop">
				<cfset setting = setProfileString("#application.iniFile#", "#arguments.themeId#", "logoPaddingTop", arguments.themeValue)>
			</cfcase>
			<cfcase value="logoPaddingRight">
				<cfset setting = setProfileString("#application.iniFile#", "#arguments.themeId#", "logoPaddingRight", arguments.themeValue)>
			</cfcase>
			<cfcase value="logoPaddingLeft">
				<cfset setting = setProfileString("#application.iniFile#", "#arguments.themeId#", "logoPaddingLeft", arguments.themeValue)>
			</cfcase>
			<cfcase value="logoPaddingBottom">
				<cfset setting = setProfileString("#application.iniFile#", "#arguments.themeId#", "logoPaddingBottom", arguments.themeValue)>
			</cfcase>
			<cfcase value="blogNameTextColor">
				<cfset setting = setProfileString("#application.iniFile#", "#arguments.themeId#", "blogNameTextColor", arguments.themeValue)>
			</cfcase>
			<cfcase value="headerBodyDividerImage">
				<cfset setting = setProfileString("#application.iniFile#", "#arguments.themeId#", "headerBodyDividerImage", arguments.themeValue)>
			</cfcase>
			<cfcase value="kendoThemeCssFileLocation">
				<cfset setting = setProfileString("#application.iniFile#", "#arguments.themeId#", "kendoThemeCssFileLocation", arguments.themeValue)>
			</cfcase>
			<cfcase value="kendoThemeMobileCssFileLocation">
				<cfset setting = setProfileString("#application.iniFile#", "#arguments.themeId#", "kendoThemeMobileCssFileLocation", arguments.themeValue)>
			</cfcase>
			<cfcase value="customCoreLogicTemplate">
				<cfset setting = setProfileString("#application.iniFile#", "#arguments.themeId#", "customCoreLogicTemplate", arguments.themeValue)>
			</cfcase>
			<cfcase value="customHeadTemplate">
				<cfset setting = setProfileString("#application.iniFile#", "#arguments.themeId#", "customHeadTemplate", arguments.themeValue)>
			</cfcase>
			<cfcase value="customBodyString">
				<cfset setting = setProfileString("#application.iniFile#", "#arguments.themeId#", "customBodyString", arguments.themeValue)>
			</cfcase>
			<cfcase value="customFontCssTemplate">
				<cfset setting = setProfileString("#application.iniFile#", "#arguments.themeId#", "customFontCssTemplate", arguments.themeValue)>
			</cfcase>
			<cfcase value="customGlobalAndBodyCssTemplate">
				<cfset setting = setProfileString("#application.iniFile#", "#arguments.themeId#", "customGlobalAndBodyCssTemplate", arguments.themeValue)>
			</cfcase>
			<cfcase value="customTopMenuCssTemplate">
				<cfset setting = setProfileString("#application.iniFile#", "#arguments.themeId#", "customTopMenuCssTemplate", arguments.themeValue)>
			</cfcase>
			<cfcase value="customTopMenuHtmlTemplate">
				<cfset setting = setProfileString("#application.iniFile#", "#arguments.themeId#", "customTopMenuHtmlTemplate", arguments.themeValue)>
			</cfcase>
			<cfcase value="customTopMenuJsTemplate">
				<cfset setting = setProfileString("#application.iniFile#", "#arguments.themeId#", "customTopMenuJsTemplate", arguments.themeValue)>
			</cfcase>
			<cfcase value="customBlogContentCssTemplate">
				<cfset setting = setProfileString("#application.iniFile#", "#arguments.themeId#", "customBlogContentCssTemplate", arguments.themeValue)>
			</cfcase>
			<cfcase value="customBlogJsContentTemplate">
				<cfset setting = setProfileString("#application.iniFile#", "#arguments.themeId#", "customBlogJsContentTemplate", arguments.themeValue)>
			</cfcase>
			<cfcase value="customBlogContentHtmlTemplate">
				<cfset setting = setProfileString("#application.iniFile#", "#arguments.themeId#", "customBlogContentHtmlTemplate", arguments.themeValue)>
			</cfcase>
			<cfcase value="customFooterHtmlTemplate">
				<cfset setting = setProfileString("#application.iniFile#", "#arguments.themeId#", "customFooterHtmlTemplate", arguments.themeValue)>
			</cfcase>
		</cfswitch>
		<!--- Return it. --->	
		<cfreturn setting>
	</cffunction>
					
	<!--- This function is consumed on the admin settings page in order to get all of the settings --->
	<cffunction name="getAllThemeSettingsFromIniStore" returnType="struct" output="false" access="remote" hint="Provides all theme settings stored in the configuration file. This function will return a json array.">
		<cfargument name="themeId"  required="true" hint="Pass in the theme Id."/>

		<!--- Get the data from the configuration file. --->
		<cfset useCustomTheme = getProfileString("#application.iniFile#", "#arguments.themeId#", "useCustomTheme") />
		<cfset customThemeName = getProfileString("#application.iniFile#", "#arguments.themeId#", "customThemeName") />
		<cfset darkTheme = getProfileString("#application.iniFile#", "#arguments.themeId#", "darkTheme") />
		<cfset contentWidth = getProfileString("#application.iniFile#", "#arguments.themeId#", "contentWidth") />
		<cfset mainContainerWidth = getProfileString("#application.iniFile#", "#arguments.themeId#", "mainContainerWidth") />
		<cfset sideBarContainerWidth = getProfileString("#application.iniFile#", "#arguments.themeId#", "sideBarContainerWidth") />
		<cfset siteOpacity = getProfileString("#application.iniFile#", "#arguments.themeId#", "siteOpacity") />
		<cfset blogBackgroundImage = getProfileString("#application.iniFile#", "#arguments.themeId#", "blogBackgroundImage") />
		<cfset blogBackgroundImageRepeat = getProfileString("#application.iniFile#", "#arguments.themeId#", "blogBackgroundImageRepeat") />
		<cfset blogBackgroundImagePosition = getProfileString("#application.iniFile#", "#arguments.themeId#", "blogBackgroundImagePosition") />
		<cfset stretchHeaderAcrossPage = getProfileString("#application.iniFile#", "#arguments.themeId#", "stretchHeaderAcrossPage") />
		<cfset alignBlogMenuWithBlogContent = getProfileString("#application.iniFile#", "#arguments.themeId#", "alignBlogMenuWithBlogContent") />
		<cfset topMenuAlign = getProfileString("#application.iniFile#", "#arguments.themeId#", "topMenuAlign") />
		<cfset headerBackgroundImage = getProfileString("#application.iniFile#", "#arguments.themeId#", "headerBackgroundImage") />
		<cfset menuBackgroundImage = getProfileString("#application.iniFile#", "#arguments.themeId#", "menuBackgroundImage") />
		<cfset coverKendoMenuWithMenuBackgroundImage = getProfileString("#application.iniFile#", "#arguments.themeId#", "coverKendoMenuWithMenuBackgroundImage") />
		<cfset logoImageMobile = getProfileString("#application.iniFile#", "#arguments.themeId#", "logoImageMobile") />
		<cfset logoMobileWidth = getProfileString("#application.iniFile#", "#arguments.themeId#", "logoMobileWidth") />
		<cfset logoImage = getProfileString("#application.iniFile#", "#arguments.themeId#", "logoImage") />
		<cfset logoPaddingTop = getProfileString("#application.iniFile#", "#arguments.themeId#", "logoPaddingTop") />
		<cfset logoPaddingRight = getProfileString("#application.iniFile#", "#arguments.themeId#", "logoPaddingRight") />
		<cfset logoPaddingLeft = getProfileString("#application.iniFile#", "#arguments.themeId#", "logoPaddingLeft") />
		<cfset logoPaddingBottom = getProfileString("#application.iniFile#", "#arguments.themeId#", "logoPaddingBottom") />
		<cfset blogNameTextColor = getProfileString("#application.iniFile#", "#arguments.themeId#", "blogNameTextColor") />
		<cfset headerBodyDividerImage = getProfileString("#application.iniFile#", "#arguments.themeId#", "headerBodyDividerImage") />
		<!--- Note: this is harcoded. The user can't change this using an interface (GA fixed 1.0 bug, I had /sytles/kendoCore', core was eliminated). --->
		<cfset kendoCommonCssFileLocation = application.kendoSourceLocation & "/styles/kendo.common.min.css" />
		<cfset kendoThemeCssFileLocation = getProfileString("#application.iniFile#", "#arguments.themeId#", "kendoThemeCssFileLocation") />
		<cfset kendoThemeMobileCssFileLocation = getProfileString("#application.iniFile#", "#arguments.themeId#", "kendoThemeMobileCssFileLocation") />
		<cfset customCoreLogicTemplate = getProfileString("#application.iniFile#", "#arguments.themeId#", "customCoreLogicTemplate") />
		<cfset customHeadTemplate = getProfileString("#application.iniFile#", "#arguments.themeId#", "customHeadTemplate") />
		<cfset customBodyString = getProfileString("#application.iniFile#", "#arguments.themeId#", "customBodyString") />
		<cfset customFontCssTemplate = getProfileString("#application.iniFile#", "#arguments.themeId#", "customFontCssTemplate") />
		<cfset customGlobalAndBodyCssTemplate = getProfileString("#application.iniFile#", "#arguments.themeId#", "customGlobalAndBodyCssTemplate") />
		<cfset customTopMenuCssTemplate = getProfileString("#application.iniFile#", "#arguments.themeId#", "customTopMenuCssTemplate") />
		<cfset customTopMenuHtmlTemplate = getProfileString("#application.iniFile#", "#arguments.themeId#", "customTopMenuHtmlTemplate") />
		<cfset customTopMenuJsTemplate = getProfileString("#application.iniFile#", "#arguments.themeId#", "customTopMenuJsTemplate") />
		<cfset customBlogContentCssTemplate = getProfileString("#application.iniFile#", "#arguments.themeId#", "customBlogContentCssTemplate") />
		<cfset customBlogJsContentTemplate = getProfileString("#application.iniFile#", "#arguments.themeId#", "customBlogJsContentTemplate") />
		<cfset customBlogContentHtmlTemplate = getProfileString("#application.iniFile#", "#arguments.themeId#", "customBlogContentHtmlTemplate") />
		<cfset customFooterHtmlTemplate = getProfileString("#application.iniFile#", "#arguments.themeId#", "customFooterHtmlTemplate") />
		
		<cfset uiSettings = {
			   useCustomTheme=#useCustomTheme#,
			   customThemeName=#customThemeName#,
			   darkTheme=#darkTheme#,
			   siteOpacity=#siteOpacity#,
			   contentWidth=#contentWidth#,
			   mainContainerWidth=#mainContainerWidth#,
			   sideBarContainerWidth=#sideBarContainerWidth#,
			   blogBackgroundImage=#blogBackgroundImage#,
			   blogBackgroundImageRepeat=#blogBackgroundImageRepeat#,
			   blogBackgroundImagePosition=#blogBackgroundImagePosition#,
			   stretchHeaderAcrossPage=#stretchHeaderAcrossPage#,
			   alignBlogMenuWithBlogContent=#alignBlogMenuWithBlogContent#,
			   topMenuAlign=#topMenuAlign#,
			   headerBackgroundImage=#headerBackgroundImage#,
			   menuBackgroundImage=#menuBackgroundImage#, 
			   coverKendoMenuWithMenuBackgroundImage=#coverKendoMenuWithMenuBackgroundImage#,
			   logoImageMobile=#logoImageMobile#,
			   logoMobileWidth=#logoMobileWidth#,
			   logoImage=#logoImage#,
			   logoPaddingTop=#logoPaddingTop#,
			   logoPaddingRight=#logoPaddingRight#,
			   logoPaddingLeft=#logoPaddingLeft#,
			   logoPaddingBottom=#logoPaddingBottom#,
			   blogNameTextColor=#blogNameTextColor#,
			   headerBodyDividerImage=#headerBodyDividerImage#,
			   kendoCommonCssFileLocation=#kendoCommonCssFileLocation#,
			   kendoThemeCssFileLocation=#kendoThemeCssFileLocation#,
			   kendoThemeMobileCssFileLocation=#kendoThemeMobileCssFileLocation#,
			   customCoreLogicTemplate=#customCoreLogicTemplate#,
			   customHeadTemplate=#customHeadTemplate#,
			   customBodyString=#customBodyString#,
			   customFontCssTemplate=#customFontCssTemplate#,
			   customGlobalAndBodyCssTemplate=#customGlobalAndBodyCssTemplate#,
			   customTopMenuCssTemplate=#customTopMenuCssTemplate#,
			   customTopMenuHtmlTemplate=#customTopMenuHtmlTemplate#,
			   customTopMenuJsTemplate=#customTopMenuJsTemplate#,
			   customBlogContentCssTemplate=#customBlogContentCssTemplate#,
			   customBlogJsContentTemplate=#customBlogJsContentTemplate#,
			   customBlogContentHtmlTemplate=#customBlogContentHtmlTemplate#,
			   customFooterHtmlTemplate=#customFooterHtmlTemplate#
		}>

		<!--- Return the struct. --->
		<cfreturn uiSettings>

	</cffunction>
		
	<cffunction name="getAllThemeSettingsFromIniStoreAsJson" returnFormat="json" output="false" access="remote" hint="Provides all theme settings stored in the configuration file. This function will return a json array.">
		<cfargument name="themeId"  required="true" hint="Pass in the theme Id."/>
		<!--- Supress whitespace. --->
		<cfsetting enablecfoutputonly="true" />
		<!--- Get the settings using the getDefaultSettingsByTheme method ---> 
		<cfinvoke component="#this#" method="getAllThemeSettingsFromIniStore" returnvariable="themeSettings">
			<cfinvokeargument name="themeId" value="#arguments.themeId#">
		</cfinvoke>
			
		<!--- Serialize the structure. --->
		<cfset serializedResponse = serializeJSON( themeSettings ) />
		<!--- Send the response back to the client. --->
		<cfreturn serializedResponse>

	</cffunction>
		
	<!--- Provides the default theme settings for version 1. --->
	<cffunction name="getDefaultSettingsByTheme" returntype="struct" access="remote" hint="Provides all theme settings stored in the configuration file. The function is consumed in the admin settings template, and will return a structure.">
		<cfargument name="uiTheme" required="true" hint="Pass in the Kendo theme name."/>
		<!--- This setting allows me to use different resolution for the background images. It is intended to be used in later versions when I create the new interface that is similiar to my home site at gregoryalexander.com. --->
		<cfset backgroundImageResolution = "LowRes">

		<!--- Note: the following settings can not be set as a sharable theme as it would override the owners blog settings (in this case me). These settings must be set in the Application.cfm template.
		kendoSourceLocation
		kendoUiExtendedLocation
		jQueryUiPath
		jQueryNotifyLocation
		blogFontSize
		--->

		<cfswitch expression="#arguments.uiTheme#">
			<cfcase value="default">
				<!---We don't have to use certain themes. If this is set to true, it will show up in the theme drop down menu's. If set to false, it won't be available.--->
				<cfset useCustomTheme = false>
				<!--- What is your custom theme name? You probably don't want to create a fancy theme and then call it by the Kendo theme name (ie default), but it  you want- you can. It is up to you. --->
				<cfset customThemeName = "Zion">
				<!--- Specify whether this is a dark theme. In the themes that I am s using, 'Orion' is a darkTheme, whereas 'Zion' is not. We need to set this in order to match the theme with the proper formatter skin when we display code using the <code></code> tags when making an entry. --->
				<cfset darkTheme = false>
				<!--- The site opacity will make the blog content semi-transparent so that you can see the background image. If you change this, be sure to set this between 80 and 100 as this will impact the readability of the entire site. Site opacity settings show the background image underneath. Each setting is individually set by the theme to ensure better readability. ---> 
				<cfset siteOpacity = 90>
				<!--- The default width of the containers that hold the blog content at a resolution between 1700 to 1920 pixels. Thus site is responsive, so the content width will expand as the screen dimensions get smaller, and decrease to 50% for extra wide moniters. I am using a bigger font than most of the blogCfc sites, so I am setting this at 66%, which is a bit wider than 50% which looks the best. This setting also affects the seach and searchResults windows which subtract 10% from this setting. Important note: if you want to fine tune the content width setting, you can also adjust the responsive web design that changes depending upon the client's screen size. This must be done manually by hand editing the 'setScreenProperties();' javascript function.--->
				<cfset contentWidth = "66">
				<!--- Properties of the blog content. There are two sections that display the main blog content. The 'blogContent' div on the left holds the blog posts, interactive buttons and comments, and the side-bar on the right contains the pods, such as the calendar control and recent comments. I designed the page carefully to use 65% of the space for the blogContent, and 35% is used for the side bar, which contain the pods. You can change these settings if you wish, but be careful.
				Note: this setting only applies to desktop devices. On mobile devices, the blog content width is set at 95% and the side bar is a responsive flyout panel. --->
				<cfset mainContainerWidth = "65">
				<!--- The sidebar is where the BlogCfc 'pods' are (calendar, subscribe, etc). The sidebar container width does not exist in the mobile design. Instead, it is a responsive panel. --->
				<cfset sideBarContainerWidth = "35">
				<!--- What is the base url path to the themes background image? Note: this can also be blank if you don't want to assign an image. --->
				<cfset blogBackgroundImage= application.baseUrl & "/images/background/gregoryAlexander/weepingRock" & backgroundImageResolution & ".jpg">
				<!--- Do you want the blogBackgroundImage to repeat across the screen? The default value is false, however, you may set this to true if you want to assign a small background as a pattern. See https://www.w3schools.com/cssref/pr_background-repeat.asp. --->
				<cfset blogBackgroundImageRepeat = "no-repeat">
				<!--- Set the background image position. See https://www.w3schools.com/cssref/pr_background-position.asp for a full description. --->
				<cfset blogBackgroundImagePosition = "50% 25%">
				<!--- Set true to stretch the top banner across the page. We can either stretch it out across the entire page, or leave it at false to make the header identical to the width of the contentWidth. I am adding this setting as some users may want to put more stuff into the header banner and stretching it out allows more room. --->
				<cfset stretchHeaderAcrossPage = false>
				<!--- Note: this setting is only applicable when the stretchHeaderAcrossPage setting is true. If the header is streched out across the screen, set this to true if you want to justify a left or right aligned menu with the blog content. If this setting is true, the menu will be aligned with the blog content container. I am allowing this to be changed as the user may want to use the same header on their own site and I want to allow them to modify the placement as the end user sees fit. The values are: true or false. --->
				<cfset alignBlogMenuWithBlogContent = true>
				<!--- Top menu alignment. This aligns the menu *inside* of the header. The top menu contains the logo as well as the menu scripts and search button. Accepted values are left, center, and right.--->
				<cfset topMenuAlign = "left"><!---Either left, center, or right--->
				<!--- The header background image. You can also leave this blank if you want the blogBackgroundImage to be shown instead of a colored banner on the header. If you choose to leave this blank and not display a colored banner, also leave the menuBackgroundImage blank, otherwise, a ghosted colored bar will be displayed. Note: I put a gradient on the banner image, however, the top of the image, which is darker than the bottom, can't be used for the menu as it will look off. So I am separating the background images for the banner and the menu. --->
				<cfset headerBackgroundImage = application.baseUrl & "/images/bg/redSatinSmallGradient130.png">
				<!--- The background image for the top menu. This should be a consistent color and not gradiated. --->
				<cfset menuBackgroundImage = application.baseUrl & "/images/bg/redSatinSmall130.png">
				<!--- This setting determines if the whole image should be shown on screen, or if the image should be captured from the left until the image is cut off at the end of the screen. Essentially, setting this to true set the image width to be 100%, whereas setting this to false will left justify the image and cut off any overflow. The resolution is quite high, so setting this to false will cut off the right part of most of the images. --->
				<cfset coverKendoMenuWithMenuBackgroundImage = true>
				<cfset logoImageMobile = application.baseUrl & "/images/logo/logoZionMobileTheme.gif"><!---newMountainMobile.gif, logoOrangeBgMobile.gif--->
				<!--- What is the width of the mobile logo? Set as narrow as possible in order to fit the blog name text to the right of the logo. --->
				<cfset logoMobileWidth = "60">
				<cfset logoImage = application.baseUrl & "/images/logo/logoZionThemeOs.gif">
				<!--- Logo Padding. The most important setting here is logoPaddingRight which gives space between the logo and the blog text and menu. I have designed the logo image with padding on the right to take care of this without applying this setting. Padding top left and bottom can be used to fine tune the placement of the logo but I am not using them currently in my theme designs. --->
				<cfset logoPaddingTop = "0px">
				<cfset logoPaddingRight = "0px">
				<cfset logoPaddingLeft = "0px">
				<cfset logoPaddingBottom = "0px">
				<!--- The color of the blog name that is shown (ie 'Gregory's Blog'). The color may be different than white when you use a light custom header. This setting also affects the menu text color. --->
				<cfset blogNameTextColor = "whitesmoke">
				<!--- This is the divider between the header and the body. It is an optional argument. --->
				<cfset headerBodyDividerImage = application.baseUrl & "/images/divider/headerBodyDivider.png">
				<!--- Kendo File locations. You should *not* change these settings unless you have created a custom kendo theme (you can create one easily enough using the Kendo theme builder at https://demos.telerik.com/kendo-ui/themebuilder/). --->
				<!--- Where is the Kendo common css file located? Note: other than material black, office 365, and fiori, all of the the other less based themes are included in the common.min.css file. --->
				<cfset kendoCommonCssFileLocation = application.kendoSourceLocation & "/styles/kendo.common.min.css">
				<!--- Where is the specific theme based less css file? Only change this setting if you have created a custom theme. --->
				<cfset kendoThemeCssFileLocation = application.kendoSourceLocation & "/styles/kendo." & arguments.uiTheme & ".min.css">
				<!--- Where is the mobile specific theme based less css file? Only change this setting if you have created a custom theme. --->
				<cfset kendoThemeMobileCssFileLocation = application.kendoSourceLocation & "/styles/kendo." & arguments.uiTheme & ".mobile.min.css">
			</cfcase>
			<cfcase value="highcontrast">
				<cfset useCustomTheme = false>
				<cfset customThemeName = "">
				<cfset darkTheme = true>
				<cfset siteOpacity = 85>
				<cfset contentWidth = "66">
				<cfset mainContainerWidth = "65">
				<cfset sideBarContainerWidth = "35">
				<cfset blogBackgroundImage= application.baseUrl & "/images/background/nasa/orionNebula" & backgroundImageResolution & ".jpg">
				<cfset blogBackgroundImageRepeat = "no-repeat">
				<cfset blogBackgroundImagePosition = "center center">
				<cfset stretchHeaderAcrossPage = false>
				<cfset alignBlogMenuWithBlogContent = true>
				<cfset topMenuAlign = "left">
				<cfset headerBackgroundImage = application.baseUrl & "/images/bg/redSatinSmallGradient130.png">
				<cfset menuBackgroundImage = application.baseUrl & "/images/bg/redSatinSmall130.png">
				<cfset coverKendoMenuWithMenuBackgroundImage = true>
				<cfset logoImageMobile = application.baseUrl & "/images/logo/logoHighContrastMobileTheme.gif">
				<cfset logoMobileWidth = "60">
				<cfset logoImage = application.baseUrl & "/images/logo/logoHighConstrastThemeOs.gif">
				<cfset logoPaddingTop = "0px">
				<cfset logoPaddingRight = "0px">
				<cfset logoPaddingLeft = "0px">
				<cfset logoPaddingBottom = "0px">
				<cfset blogNameTextColor = "whitesmoke">
				<cfset headerBodyDividerImage = application.baseUrl & "/images/divider/headerBodyDivider.png">
				<!--- Kendo File locations. --->
				<cfset kendoCommonCssFileLocation = application.kendoSourceLocation & "/styles/kendo.common.min.css">
				<cfset kendoThemeCssFileLocation = application.kendoSourceLocation & "/styles/kendo." & arguments.uiTheme & ".min.css">
				<cfset kendoThemeMobileCssFileLocation = application.kendoSourceLocation & "/styles/kendo." & arguments.uiTheme & ".mobile.min.css">
			</cfcase>
			<cfcase value="black">
				<cfset useCustomTheme = false>
				<cfset customThemeName = "">
				<cfset darkTheme = true>
				<cfset siteOpacity = 95>
				<cfset contentWidth = "66">
				<cfset mainContainerWidth = "65">
				<cfset sideBarContainerWidth = "35">
				<cfset blogBackgroundImage= application.baseUrl & "/images/background/hubble/pillarsOfCreation" & backgroundImageResolution & ".jpg">
				<cfset blogBackgroundImageRepeat = "no-repeat">
				<cfset blogBackgroundImagePosition = "center center">
				<cfset stretchHeaderAcrossPage = false>
				<cfset alignBlogMenuWithBlogContent = false>
				<cfset topMenuAlign = "left">
				<cfset headerBackgroundImage = application.baseUrl & "/images/header/pillarsSmallGradient140.png">
				<cfset menuBackgroundImage = "">
				<cfset coverKendoMenuWithMenuBackgroundImage = false>
				<cfset logoImageMobile = application.baseUrl & "/images/logo/logoBlackMobileTheme.gif">
				<cfset logoMobileWidth = "60">
				<cfset logoImage = application.baseUrl & "/images/logo/logoBlackThemeOs.gif">
				<cfset logoPaddingTop = "0px">
				<cfset logoPaddingRight = "0px">
				<cfset logoPaddingLeft = "0px">
				<cfset logoPaddingBottom = "0px">
				<cfset blogNameTextColor = "whitesmoke">
				<cfset headerBodyDividerImage = application.baseUrl & "/images/divider/headerBodyDivider.png">
				<!--- Kendo File locations. --->
				<cfset kendoCommonCssFileLocation = application.kendoSourceLocation & "/styles/kendo.common.min.css">
				<cfset kendoThemeCssFileLocation = application.kendoSourceLocation & "/styles/kendo." & arguments.uiTheme & ".min.css">
				<cfset kendoThemeMobileCssFileLocation = application.kendoSourceLocation & "/styles/kendo." & arguments.uiTheme & ".mobile.min.css">
			</cfcase>
			<cfcase value="blueOpal">
				<cfset useCustomTheme = false>
				<cfset customThemeName = "">
				<cfset darkTheme = false>
				<cfset siteOpacity = 95>
				<cfset contentWidth = "66">
				<cfset mainContainerWidth = "65">
				<cfset sideBarContainerWidth = "35">
				<cfset blogBackgroundImage= application.baseUrl & "/images/background/nasa/bluePlanet" & backgroundImageResolution & ".jpg">
				<cfset blogBackgroundImageRepeat = "no-repeat">
				<cfset blogBackgroundImagePosition = "center top">
				<cfset stretchHeaderAcrossPage = false>
				<cfset alignBlogMenuWithBlogContent = true>
				<cfset topMenuAlign = "left">
				<cfset headerBackgroundImage = application.baseUrl & "/images/header/midnightBlueSmallGradient130.png">
				<cfset menuBackgroundImage = "">
				<cfset coverKendoMenuWithMenuBackgroundImage = false>
				<cfset logoImageMobile = application.baseUrl & "/images/logo/logoBlueOpalMobileTheme.gif">
				<cfset logoMobileWidth = "60">
				<cfset logoImage = application.baseUrl & "/images/logo/logoBlueOpalThemeOs.gif">
				<cfset logoPaddingTop = "0px">
				<cfset logoPaddingRight = "0px">
				<cfset logoPaddingLeft = "0px">
				<cfset logoPaddingBottom = "0px">
				<cfset blogNameTextColor = "whitesmoke">
				<cfset headerBodyDividerImage = application.baseUrl & "/images/divider/headerBodyDivider.png">
				<!--- Kendo File locations. --->
				<cfset kendoCommonCssFileLocation = application.kendoSourceLocation & "/styles/kendo.common.min.css">
				<cfset kendoThemeCssFileLocation = application.kendoSourceLocation & "/styles/kendo." & arguments.uiTheme & ".min.css">
				<cfset kendoThemeMobileCssFileLocation = application.kendoSourceLocation & "/styles/kendo." & arguments.uiTheme & ".mobile.min.css">
			</cfcase>
			<cfcase value="flat">
				<cfset useCustomTheme = false>
				<cfset customThemeName = "">
				<cfset darkTheme = false>
				<cfset siteOpacity = 90>
				<cfset contentWidth = "66">
				<cfset mainContainerWidth = "65">
				<cfset sideBarContainerWidth = "35">
				<cfset blogBackgroundImage= application.baseUrl & "/images/background/nasa/bahamaBank" & backgroundImageResolution & ".jpg">
				<cfset blogBackgroundImageRepeat = "no-repeat">
				<cfset blogBackgroundImagePosition = "center top">
				<cfset stretchHeaderAcrossPage = false>
				<cfset alignBlogMenuWithBlogContent = false>
				<cfset topMenuAlign = "left">
				<cfset headerBackgroundImage = application.baseUrl & "/images/header/midnightBlueSmallGradient130.png">
				<cfset menuBackgroundImage = "">
				<cfset coverKendoMenuWithMenuBackgroundImage = false>
				<cfset logoImageMobile = application.baseUrl & "/images/logo/logoFlatMobileTheme.gif">
				<cfset logoMobileWidth = "60">
				<cfset logoImage = application.baseUrl & "/images/logo/logoFlatThemeOs.gif">
				<cfset logoPaddingTop = "0px">
				<cfset logoPaddingRight = "0px">
				<cfset logoPaddingLeft = "0px">
				<cfset logoPaddingBottom = "0px">
				<cfset blogNameTextColor = "whitesmoke">
				<cfset headerBodyDividerImage = application.baseUrl & "/images/divider/headerBodyDivider.png">
				<!--- Kendo File locations. --->
				<cfset kendoCommonCssFileLocation = application.kendoSourceLocation & "/styles/kendo.common.min.css">
				<cfset kendoThemeCssFileLocation = application.kendoSourceLocation & "/styles/kendo." & arguments.uiTheme & ".min.css">
				<cfset kendoThemeMobileCssFileLocation = application.kendoSourceLocation & "/styles/kendo." & arguments.uiTheme & ".mobile.min.css">
			</cfcase>
			<cfcase value="material">
				<cfset useCustomTheme = false>
				<cfset customThemeName = "">
				<cfset darkTheme = false>
				<cfset siteOpacity = 90>
				<cfset contentWidth = "66">
				<cfset mainContainerWidth = "65">
				<cfset sideBarContainerWidth = "35">
				<cfset blogBackgroundImage= application.baseUrl & "/images/background/gregoryalexander/purchased/blueWave" & backgroundImageResolution & ".jpg">
				<cfset blogBackgroundImageRepeat = "no-repeat">
				<cfset blogBackgroundImagePosition = "center center">
				<cfset stretchHeaderAcrossPage = false>
				<cfset alignBlogMenuWithBlogContent = false>
				<cfset topMenuAlign = "left">
				<cfset headerBackgroundImage = application.baseUrl & "/images/header/BlueWaveSmallGradient140.png">
				<cfset menuBackgroundImage = application.baseUrl & "/images/header/blueWaveLightMenuBackgroundImage.png">
				<cfset coverKendoMenuWithMenuBackgroundImage = true>
				<cfset logoImageMobile = application.baseUrl & "/images/logo/logoMaterialMobileTheme.gif">
				<cfset logoMobileWidth = "60">
				<cfset logoImage = application.baseUrl & "/images/logo/logoMaterialThemeOs.gif">
				<cfset logoPaddingTop = "0px">
				<cfset logoPaddingRight = "0px">
				<cfset logoPaddingLeft = "0px">
				<cfset logoPaddingBottom = "0px">
				<cfset blogNameTextColor = "whitesmoke">
				<cfset headerBodyDividerImage = application.baseUrl & "/images/divider/headerBodyDivider.png">
				<!--- Kendo File locations. --->
				<cfset kendoCommonCssFileLocation = application.kendoSourceLocation & "/styles/kendo.common.min.css">
				<cfset kendoThemeCssFileLocation = application.kendoSourceLocation & "/styles/kendo." & arguments.uiTheme & ".min.css">
				<cfset kendoThemeMobileCssFileLocation = application.kendoSourceLocation & "/styles/kendo." & arguments.uiTheme & ".mobile.min.css">
			</cfcase>
			<cfcase value="materialblack">
				<cfset useCustomTheme = false>
				<cfset customThemeName = "">
				<cfset darkTheme = true>
				<cfset siteOpacity = 91>
				<cfset contentWidth = "66">
				<cfset mainContainerWidth = "65">
				<cfset sideBarContainerWidth = "35">
				<cfset blogBackgroundImage= application.baseUrl & "/images/background/gregoryalexander/purchased/blueWave" & backgroundImageResolution & ".jpg">
				<cfset blogBackgroundImageRepeat = "no-repeat">
				<cfset blogBackgroundImagePosition = "center center">
				<cfset stretchHeaderAcrossPage = false>
				<cfset alignBlogMenuWithBlogContent = false>
				<cfset topMenuAlign = "left">
				<cfset headerBackgroundImage = application.baseUrl & "/images/header/midnightBlueSmallGradient147.png"><!---Note: the kendo menu for material black is 7 pixels larger than the rest of the themes and it uses a larger background image to deal with the extra height. --->
				<cfset menuBackgroundImage = "">
				<cfset coverKendoMenuWithMenuBackgroundImage = false>
				<cfset logoImageMobile = application.baseUrl & "/images/logo/logoMaterialBlackMobileTheme.gif">
				<cfset logoMobileWidth = "60">
				<cfset logoImage = application.baseUrl & "/images/logo/logoMaterialBlackThemeOs.gif">
				<cfset logoPaddingTop = "0px">
				<cfset logoPaddingRight = "0px">
				<cfset logoPaddingLeft = "0px">
				<cfset logoPaddingBottom = "0px">
				<cfset blogNameTextColor = "whitesmoke">
				<cfset headerBodyDividerImage = application.baseUrl & "/images/divider/headerBodyDivider.png">
				<!--- Locations. The css file for the material black theme is found in a separate location. --->
				<cfset kendoCommonCssFileLocation = application.kendoSourceLocation & "/styles/kendo.common-material.min.css">
				<cfset kendoThemeCssFileLocation = application.kendoSourceLocation & "/styles/kendo." & arguments.uiTheme & ".min.css">
				<cfset kendoThemeMobileCssFileLocation = application.kendoSourceLocation & "/styles/kendo." & arguments.uiTheme & ".mobile.min.css">
			</cfcase>
			<cfcase value="metro">
				<cfset useCustomTheme = false>
				<cfset customThemeName = "">
				<cfset darkTheme = false>
				<cfset siteOpacity = 93>
				<cfset contentWidth = "66">
				<cfset mainContainerWidth = "65">
				<cfset sideBarContainerWidth = "35">
				<cfset blogBackgroundImage= application.baseUrl & "/images/background/gregoryalexander/grandTeton" & backgroundImageResolution & ".jpg">
				<cfset blogBackgroundImageRepeat = "no-repeat">
				<cfset blogBackgroundImagePosition = "center top">
				<cfset stretchHeaderAcrossPage = false>
				<cfset alignBlogMenuWithBlogContent = false>
				<cfset topMenuAlign = "left">
				<cfset headerBackgroundImage = application.baseUrl & "/images/header/white160.png">
				<cfset menuBackgroundImage = "">
				<cfset coverKendoMenuWithMenuBackgroundImage = false>
				<cfset logoImageMobile = application.baseUrl & "/images/logo/gregorysBlogMobile.png">
				<cfset logoMobileWidth = "60">
				<cfset logoImage = application.baseUrl & "/images/logo/gregorysBlogLogo.gif">
				<cfset logoPaddingTop = "0px">
				<cfset logoPaddingRight = "0px">
				<cfset logoPaddingLeft = "0px">
				<cfset logoPaddingBottom = "0px">
				<cfset blogNameTextColor = "#chr(35)#698A50">
				<cfset headerBodyDividerImage = application.baseUrl & "/images/divider/headerBodyDivider.png">
				<!--- Kendo File locations. --->
				<cfset kendoCommonCssFileLocation = application.kendoSourceLocation & "/styles/kendo.common.min.css">
				<cfset kendoThemeCssFileLocation = application.kendoSourceLocation & "/styles/kendo." & arguments.uiTheme & ".min.css">
				<cfset kendoThemeMobileCssFileLocation = application.kendoSourceLocation & "/styles/kendo." & arguments.uiTheme & ".mobile.min.css">
			</cfcase>
			<cfcase value="moonlight">
				<cfset useCustomTheme = false>
				<cfset customThemeName = "">
				<cfset darkTheme = true>
				<cfset siteOpacity = 94>
				<cfset contentWidth = "66">
				<cfset mainContainerWidth = "65">
				<cfset sideBarContainerWidth = "35">
				<cfset blogBackgroundImage= application.baseUrl & "/images/background/gregoryalexander/yellowStone" & backgroundImageResolution & ".jpg">
				<cfset blogBackgroundImageRepeat = "no-repeat">
				<cfset blogBackgroundImagePosition = "center center">
				<cfset stretchHeaderAcrossPage = false>
				<cfset alignBlogMenuWithBlogContent = false>
				<cfset topMenuAlign = "left">
				<cfset headerBackgroundImage = application.baseUrl & "/images/header/midnightBlueSmallGradient140.png">
				<cfset menuBackgroundImage = "">
				<cfset coverKendoMenuWithMenuBackgroundImage = false>
				<cfset logoImageMobile = application.baseUrl & "/images/logo/logoMoonlightMobileTheme.gif">
				<cfset logoMobileWidth = "60">
				<cfset logoImage = application.baseUrl & "/images/logo/logoMoonlightThemeOs.gif">
				<cfset logoPaddingTop = "0px">
				<cfset logoPaddingRight = "0px">
				<cfset logoPaddingLeft = "0px">
				<cfset logoPaddingBottom = "0px">
				<cfset blogNameTextColor = "whitesmoke">
				<cfset headerBodyDividerImage = application.baseUrl & "/images/divider/headerBodyDivider.png">
				<!--- Kendo File locations. --->
				<cfset kendoCommonCssFileLocation = application.kendoSourceLocation & "/styles/kendo.common.min.css">
				<cfset kendoThemeCssFileLocation = application.kendoSourceLocation & "/styles/kendo." & arguments.uiTheme & ".min.css">
				<cfset kendoThemeMobileCssFileLocation = application.kendoSourceLocation & "/styles/kendo." & arguments.uiTheme & ".mobile.min.css">
			</cfcase>
			<cfcase value="office365">
				<cfset useCustomTheme = false>
				<cfset customThemeName = "">
				<cfset darkTheme = false>
				<cfset siteOpacity = 93>
				<cfset contentWidth = "66">
				<cfset mainContainerWidth = "65">
				<cfset sideBarContainerWidth = "35">
				<cfset blogBackgroundImage= application.baseUrl & "/images/background/gregoryalexander/mukilteoBeach" & backgroundImageResolution & ".jpg">
				<cfset blogBackgroundImageRepeat = "no-repeat">
				<cfset blogBackgroundImagePosition = "left top">
				<cfset stretchHeaderAcrossPage = false>
				<cfset alignBlogMenuWithBlogContent = false>
				<cfset topMenuAlign = "left">
				<cfset headerBackgroundImage = application.baseUrl & "/images/header/midnightBlueSmallGradient140.png">
				<cfset menuBackgroundImage = "">
				<cfset coverKendoMenuWithMenuBackgroundImage = false>
				<cfset logoImageMobile = application.baseUrl & "/images/logo/logoOfficeMobileTheme.gif">
				<cfset logoMobileWidth = "60">
				<cfset logoImage = application.baseUrl & "/images/logo/logoOfficeThemeOs.gif">
				<cfset logoPaddingTop = "0px">
				<cfset logoPaddingRight = "0px">
				<cfset logoPaddingLeft = "0px">
				<cfset logoPaddingBottom = "0px">
				<cfset blogNameTextColor = "whitesmoke">
				<cfset headerBodyDividerImage = application.baseUrl & "/images/divider/headerBodyDivider.png">
				<!--- Locations --->
				<!--- The css file for Office 365 is in its own location. --->
				<cfset kendoCommonCssFileLocation = application.kendoSourceLocation & "/styles/kendo.common-office365.min.css">
				<cfset kendoThemeCssFileLocation = application.kendoSourceLocation & "/styles/kendo." & arguments.uiTheme & ".min.css">
				<cfset kendoThemeMobileCssFileLocation = application.kendoSourceLocation & "/styles/kendo." & arguments.uiTheme & ".mobile.min.css">
			</cfcase>
			<cfcase value="silver">
				<cfset useCustomTheme = false>
				<cfset customThemeName = "">
				<cfset darkTheme = false>
				<cfset siteOpacity = 93>
				<cfset contentWidth = "66">
				<cfset mainContainerWidth = "65">
				<cfset sideBarContainerWidth = "35">
				<cfset blogBackgroundImage= application.baseUrl & "/images/background/gregoryalexander/purchased/depositPhotos/silver.jpg">
				<cfset blogBackgroundImageRepeat = "no-repeat">
				<cfset blogBackgroundImagePosition = "center center">
				<cfset stretchHeaderAcrossPage = false>
				<cfset alignBlogMenuWithBlogContent = false>
				<cfset topMenuAlign = "left">
				<cfset headerBackgroundImage = application.baseUrl & "/images/header/BlueWaveSmallGradient140.png">
				<cfset menuBackgroundImage = application.baseUrl & "/images/header/blueWaveLightMenuBackgroundImage.png">
				<cfset coverKendoMenuWithMenuBackgroundImage = true>
				<cfset logoImageMobile = application.baseUrl & "/images/logo/logoSilverMobileTheme.gif">
				<cfset logoMobileWidth = "60">
				<cfset logoImage = application.baseUrl & "/images/logo/logoSilverThemeOs.gif">
				<cfset logoPaddingTop = "0px">
				<cfset logoPaddingRight = "0px">
				<cfset logoPaddingLeft = "0px">
				<cfset logoPaddingBottom = "0px">
				<cfset blogNameTextColor = "whitesmoke">
				<cfset headerBodyDividerImage = application.baseUrl & "/images/divider/headerBodyDivider.png">
				<!--- Kendo File locations. --->
				<cfset kendoCommonCssFileLocation = application.kendoSourceLocation & "/styles/kendo.common.min.css">
				<cfset kendoThemeCssFileLocation = application.kendoSourceLocation & "/styles/kendo." & arguments.uiTheme & ".min.css">
				<cfset kendoThemeMobileCssFileLocation = application.kendoSourceLocation & "/styles/kendo." & arguments.uiTheme & ".mobile.min.css">
			</cfcase>
			<cfcase value="uniform">
				<cfset useCustomTheme = false>
				<cfset customThemeName = "">
				<cfset darkTheme = false>
				<cfset siteOpacity = 93>
				<cfset contentWidth = "66">
				<cfset mainContainerWidth = "65">
				<cfset sideBarContainerWidth = "35">
				<cfset blogBackgroundImage= application.baseUrl & "/images/background/gregoryalexander/purchased/depositPhotos/chrome.jpg">
				<cfset blogBackgroundImageRepeat = "no-repeat">
				<cfset blogBackgroundImagePosition = "center center">
				<cfset stretchHeaderAcrossPage = false>
				<cfset alignBlogMenuWithBlogContent = false>
				<cfset topMenuAlign = "left">
				<cfset headerBackgroundImage = application.baseUrl & "/images/header/midnightBlueSmallGradient140.png">
				<cfset menuBackgroundImage = "">
				<cfset coverKendoMenuWithMenuBackgroundImage = false>
				<cfset blogNameTextColor = "whitesmoke">
				<cfset logoImageMobile = application.baseUrl & "/images/logo/logoUniformMobileTheme.gif">
				<cfset logoMobileWidth = "60">
				<cfset logoImage = application.baseUrl & "/images/logo/logoUniformThemeOs.gif">
				<cfset logoPaddingTop = "0px">
				<cfset logoPaddingRight = "0px">
				<cfset logoPaddingLeft = "0px">
				<cfset logoPaddingBottom = "0px">
				<cfset headerBodyDividerImage = application.baseUrl & "/images/divider/headerBodyDivider.png">
				<!--- Kendo File locations. --->
				<cfset kendoCommonCssFileLocation = application.kendoSourceLocation & "/styles/kendo.common.min.css">
				<cfset kendoThemeCssFileLocation = application.kendoSourceLocation & "/styles/kendo." & arguments.uiTheme & ".min.css">
				<cfset kendoThemeMobileCssFileLocation = application.kendoSourceLocation & "/styles/kendo." & arguments.uiTheme & ".mobile.min.css">
			</cfcase>
			<cfcase value="nova">
				<cfset useCustomTheme = false>
				<cfset customThemeName = "">
				<cfset darkTheme = false>
				<cfset siteOpacity = 94>
				<cfset contentWidth = "66">
				<cfset mainContainerWidth = "65">
				<cfset sideBarContainerWidth = "35">
				<cfset blogBackgroundImage= application.baseUrl & "/images/background/gregoryalexander/purchased/depositPhotos/sunrise.jpg">
				<cfset blogBackgroundImageRepeat = "no-repeat">
				<cfset blogBackgroundImagePosition = "center center">
				<cfset stretchHeaderAcrossPage = false>
				<cfset alignBlogMenuWithBlogContent = false>
				<cfset topMenuAlign = "left">
				<cfset headerBackgroundImage = application.baseUrl & "/images/header/novaSmallGradient140.png">
				<cfset menuBackgroundImage = "">
				<cfset coverKendoMenuWithMenuBackgroundImage = false>
				<cfset logoImageMobile = application.baseUrl & "/images/logo/logoNovaMobileTheme.gif">
				<cfset logoMobileWidth = "60">
				<cfset logoImage = application.baseUrl & "/images/logo/logoNovaThemeOs.gif">
				<cfset logoPaddingTop = "0px">
				<cfset logoPaddingRight = "0px">
				<cfset logoPaddingLeft = "0px">
				<cfset logoPaddingBottom = "0px">
				<cfset blogNameTextColor = "whitesmoke">
				<cfset headerBodyDividerImage = application.baseUrl & "/images/divider/headerBodyDivider.png">
				<!--- Kendo File locations. --->
				<cfset kendoCommonCssFileLocation = application.kendoSourceLocation & "/styles/kendo.common.min.css">
				<cfset kendoThemeCssFileLocation = application.kendoSourceLocation & "/styles/kendo." & arguments.uiTheme & ".min.css">
				<cfset kendoThemeMobileCssFileLocation = application.kendoSourceLocation & "/styles/kendo." & arguments.uiTheme & ".mobile.min.css">
			</cfcase>
			<cfdefaultcase>
				<cfset useCustomTheme = false>
				<cfset customThemeName = "">
				<cfset darkTheme = false>
				<cfset siteOpacity = 92>
				<cfset contentWidth = "66">
				<cfset mainContainerWidth = "65">
				<cfset sideBarContainerWidth = "35">
				<cfset blogBackgroundImage = "">
				<cfset blogBackgroundImageRepeat = "no-repeat">
				<cfset blogBackgroundImagePosition = "center center">
				<cfset stretchHeaderAcrossPage = false>
				<cfset alignBlogMenuWithBlogContent = false>
				<cfset topMenuAlign = "left">
				<cfset headerBackgroundImage = "">
				<cfset menuBackgroundImage = "">
				<cfset coverKendoMenuWithMenuBackgroundImage = false>
				<cfset logoImageMobile = "">
				<cfset logoMobileWidth = "">
				<cfset logoImage = "">
				<cfset logoPaddingTop = "0px">
				<cfset logoPaddingRight = "0px">
				<cfset logoPaddingLeft = "0px">
				<cfset logoPaddingBottom = "0px">
				<cfset blogNameTextColor = "whitesmoke">
				<cfset headerBodyDividerImage = application.baseUrl & "/images/divider/headerBodyDivider.png">
				<!--- Kendo File locations. --->
				<cfset kendoCommonCssFileLocation = application.kendoSourceLocation & "/styles/kendo.common.min.css">
				<cfset kendoThemeCssFileLocation = application.kendoSourceLocation & "/styles/kendo." & arguments.uiTheme & ".min.css">
				<cfset kendoThemeMobileCssFileLocation = application.kendoSourceLocation & "/styles/kendo." & arguments.uiTheme & ".mobile.min.css">
			</cfdefaultcase>
		</cfswitch>
			
		<!---Note: the following elements can be set by an individual theme, however, they are not set as a default theme, so we don't need this block of code in the switch statement. They are set to null as default.--->
		<cfset customCoreLogicTemplate = "" />
		<cfset customHeadTemplate = "" />
		<cfset customBodyString = "" />
		<cfset customFontCssTemplate = "" />
		<cfset customGlobalAndBodyCssTemplate = "" />
		<cfset customTopMenuCssTemplate = "" />
		<cfset customTopMenuHtmlTemplate = "" />
		<cfset customTopMenuJsTemplate = "" />
		<cfset customBlogContentCssTemplate = "" />
		<cfset customBlogJsContentTemplate = "" />
		<cfset customBlogContentHtmlTemplate = "" />
		<cfset customFooterHtmlTemplate = "" />
					
		<!---Build the shorthand struct --->
		<cfset uiSettings = {
			   useCustomTheme=#useCustomTheme#,
			   customThemeName=#customThemeName#,
			   darkTheme=#darkTheme#,
			   siteOpacity=#siteOpacity#,
			   contentWidth=#contentWidth#,
			   mainContainerWidth=#mainContainerWidth#,
			   sideBarContainerWidth=#sideBarContainerWidth#,
			   blogBackgroundImage=#blogBackgroundImage#,
			   blogBackgroundImageRepeat=#blogBackgroundImageRepeat#,
			   blogBackgroundImagePosition=#blogBackgroundImagePosition#,
			   stretchHeaderAcrossPage=#stretchHeaderAcrossPage#,
			   alignBlogMenuWithBlogContent=#alignBlogMenuWithBlogContent#,
			   topMenuAlign=#topMenuAlign#,
			   headerBackgroundImage=#headerBackgroundImage#,
			   menuBackgroundImage=#menuBackgroundImage#, 
			   coverKendoMenuWithMenuBackgroundImage=#coverKendoMenuWithMenuBackgroundImage#,
			   logoImageMobile=#logoImageMobile#,
			   logoMobileWidth=#logoMobileWidth#,
			   logoImage=#logoImage#,
			   logoPaddingTop=#logoPaddingTop#,
			   logoPaddingRight=#logoPaddingRight#,
			   logoPaddingLeft=#logoPaddingLeft#,
			   logoPaddingBottom=#logoPaddingBottom#,
			   blogNameTextColor=#blogNameTextColor#,
			   headerBodyDividerImage=#headerBodyDividerImage#,
			   kendoCommonCssFileLocation=#kendoCommonCssFileLocation#,
			   kendoThemeCssFileLocation=#kendoThemeCssFileLocation#,
			   kendoThemeMobileCssFileLocation=#kendoThemeMobileCssFileLocation#,
			   customCoreLogicTemplate=#customCoreLogicTemplate#,
			   customHeadTemplate=#customHeadTemplate#,
			   customBodyString=#customBodyString#,
			   customFontCssTemplate=#customFontCssTemplate#,
			   customGlobalAndBodyCssTemplate=#customGlobalAndBodyCssTemplate#,
			   customTopMenuCssTemplate=#customTopMenuCssTemplate#,
			   customTopMenuHtmlTemplate=#customTopMenuHtmlTemplate#,
			   customTopMenuJsTemplate=#customTopMenuJsTemplate#,
			   customBlogContentCssTemplate=#customBlogContentCssTemplate#,
			   customBlogJsContentTemplate=#customBlogJsContentTemplate#,
			   customBlogContentHtmlTemplate=#customBlogContentHtmlTemplate#,
			   customFooterHtmlTemplate=#customFooterHtmlTemplate# 
		}>
		<!---Retrun the struct.--->
		<cfreturn uiSettings>
	</cffunction>
			
	<!---This function is consumed on the admin settings page in order to get all of the settings --->
	<cffunction name="getDefaultSettingsByThemeAsJson" returnFormat="json" output="true" access="remote" hint="This function will consume the getDefaultSettingsByTheme method above, and will convert the data into a json array.">
		<cfargument name="uiTheme"  required="true" hint="Pass in the theme Id."/>
		<!--- Supress whitespace. --->
		<cfsetting enablecfoutputonly="true" />
		<!--- Get the settings using the getDefaultSettingsByTheme method ---> 
		<cfinvoke component="#this#" method="getDefaultSettingsByTheme" returnvariable="themeSettings">
			<cfinvokeargument name="uiTheme" value="#arguments.uiTheme#">
		</cfinvoke>
			
		<cfset serializedResponse = serializeJSON( themeSettings ) />
		<!--- Send the response back to the client. --->
		<cfreturn serializedResponse>

	</cffunction>
			
	<!--- Note: we are no longer using this function. It is too slow due to the large amount of stuff in the array.
	This function is consumed on the admin settings page in order to get all of the settings. --->
	<cffunction name="getThemeSettingValueFromArray" returnType="string" access="public" hint="This function will create a theme array in the application scope that will retain our theme variables.">
		<cfargument name="uiTheme"  required="true" hint="Pass in the theme name."/>
		<cfargument name="uiSetting"  required="true" hint="Pass in the theme name."/>
		
		<!--- We need to access the array with the themeId and the settingId. Get these values. --->
		<cfset themeId = getThemeIdByTheme(arguments.uiTheme)>
		<cfset settingId = getThemeSettingIdBySetting(arguments.uiSetting)>
		
		<!--- Grab the value inside our array. --->
		<cfset arrayValue = application.themeSettingsArray[themeId][settingId]>
			
		<!--- Return it. --->
		<cfreturn arrayValue>
			
	</cffunction>
			
<cffunction name="getThemeIdByTheme" access="remote" returntype="numeric">
	<cfargument name="baseKendoTheme"  required="true" hint="Pass in the Kendo theme name."/>
	<cfswitch expression="#baseKendoTheme#">
		<cfcase value="black"><cfset themeId = 1></cfcase>
		<cfcase value="blueOpal"><cfset themeId = 2></cfcase>
		<cfcase value="default"><cfset themeId = 3></cfcase>
		<cfcase value="fiori"><cfset themeId = 4></cfcase>
		<cfcase value="flat"><cfset themeId = 5></cfcase>
		<cfcase value="highcontrast"><cfset themeId = 6></cfcase>
		<cfcase value="material"><cfset themeId = 7></cfcase>
		<cfcase value="materialblack"><cfset themeId = 8></cfcase>
		<cfcase value="metro"><cfset themeId = 9></cfcase>
		<cfcase value="moonlight"><cfset themeId = 10></cfcase>
		<cfcase value="nova"><cfset themeId = 11></cfcase>
		<cfcase value="office365"><cfset themeId = 12></cfcase>
		<cfcase value="silver"><cfset themeId = 13></cfcase>
		<cfcase value="uniform"><cfset themeId = 14></cfcase>
	</cfswitch>
	<!--- Safety check --->
	<cfif not isDefined("themeId")>
		<cfset themeId = 9>
	</cfif>
	<cfreturn themeId>
</cffunction>
			
<cffunction name="getThemeSettingIdBySetting" access="remote" returnType="numeric" output="false" hint="Returns an Id of a theme setting. This is  used to find the index of the setting in the arrThemeSettingsFromIniStore array.">
	<cfargument name="themeSetting" type="string" required="true">
	
	<!--- Find the id --->
	<cfswitch expression="#arguments.themeSetting#">
		<cfcase value="useCustomTheme">
			<cfset themeSettingId = 1>
		</cfcase>
		<cfcase value="customThemeName">
			<cfset themeSettingId = 2>
		</cfcase>
		<cfcase value="darkTheme">
			<cfset themeSettingId = 3>
		</cfcase>
		<cfcase value="contentWidth">
			<cfset themeSettingId = 4>
		</cfcase>
		<cfcase value="mainContainerWidth">
			<cfset themeSettingId = 5>
		</cfcase>
		<cfcase value="sideBarContainerWidth">
			<cfset themeSettingId = 6>
		</cfcase>
		<cfcase value="siteOpacity">
			<cfset themeSettingId = 7>
		</cfcase>
		<cfcase value="blogBackgroundImage">
			<cfset themeSettingId = 8>
		</cfcase>
		<cfcase value="blogBackgroundImageRepeat">
			<cfset themeSettingId = 9>
		</cfcase>
		<cfcase value="blogBackgroundImagePosition">
			<cfset themeSettingId = 10>
		</cfcase>
		<cfcase value="stretchHeaderAcrossPage">
			<cfset themeSettingId = 11>
		</cfcase>
		<cfcase value="alignBlogMenuWithBlogContent">
			<cfset themeSettingId = 12>
		</cfcase>
		<cfcase value="topMenuAlign">
			<cfset themeSettingId = 13>
		</cfcase>
		<cfcase value="headerBackgroundImage">
			<cfset themeSettingId = 14>
		</cfcase>
		<cfcase value="menuBackgroundImage">
			<cfset themeSettingId = 15>
		</cfcase>
		<cfcase value="coverKendoMenuWithMenuBackgroundImage">
			<cfset themeSettingId = 16>
		</cfcase>
		<cfcase value="logoImageMobile">
			<cfset themeSettingId = 17>
		</cfcase>
		<cfcase value="logoMobileWidth">
			<cfset themeSettingId = 18>
		</cfcase>
		<cfcase value="logoImage">
			<cfset themeSettingId = 19>
		</cfcase>
		<cfcase value="logoPaddingTop">
			<cfset themeSettingId = 20>
		</cfcase>
		<cfcase value="logoPaddingRight">
			<cfset themeSettingId = 21>
		</cfcase>
		<cfcase value="logoPaddingLeft">
			<cfset themeSettingId = 22>
		</cfcase>
		<cfcase value="logoPaddingBottom">
			<cfset themeSettingId = 23>
		</cfcase>
		<cfcase value="blogNameTextColor">
			<cfset themeSettingId = 24>
		</cfcase>
		<cfcase value="headerBodyDividerImage">
			<cfset themeSettingId = 25>
		</cfcase>
		<cfcase value="kendoThemeCssFileLocation">
			<cfset themeSettingId = 26>
		</cfcase>
		<cfcase value="kendoThemeMobileCssFileLocation">
			<cfset themeSettingId = 27>
		</cfcase>
		<cfcase value="customCoreLogicTemplate">
			<cfset themeSettingId = 28>
		</cfcase>
		<cfcase value="customHeadTemplate">
			<cfset themeSettingId = 29>
		</cfcase>
		<cfcase value="customBodyString">
			<cfset themeSettingId = 30>
		</cfcase>
		<cfcase value="customFontCssTemplate">
			<cfset themeSettingId = 31>
		</cfcase>
		<cfcase value="customGlobalAndBodyCssTemplate">
			<cfset themeSettingId = 32>
		</cfcase>
		<cfcase value="customTopMenuCssTemplate">
			<cfset themeSettingId = 33>
		</cfcase>
		<cfcase value="customTopMenuHtmlTemplate">
			<cfset themeSettingId = 34>
		</cfcase>
		<cfcase value="customTopMenuJsTemplate">
			<cfset themeSettingId = 35>
		</cfcase>
		<cfcase value="customBlogContentCssTemplate">
			<cfset themeSettingId = 36>
		</cfcase>
		<cfcase value="customBlogJsContentTemplate">
			<cfset themeSettingId = 37>
		</cfcase>
		<cfcase value="customBlogContentHtmlTemplate">
			<cfset themeSettingId = 38>
		</cfcase>
		<cfcase value="customFooterHtmlTemplate">
			<cfset themeSettingId = 39>
		</cfcase>
	</cfswitch>

	<!---Return the themeSettingId.--->
	<cfreturn themeSettingId>
</cffunction>

<!--- Default base kendo themes. --->
<cffunction name="getDefaultThemes" access="remote" returntype="string">
	<cfreturn "default,black,blueOpal,flat,highcontrast,material,materialblack,metro,moonlight,office365,silver,silver,uniform,nova">
</cffunction>
			
</cfcomponent>