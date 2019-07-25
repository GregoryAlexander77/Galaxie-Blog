<cfprocessingdirective pageencoding="utf-8">
<cfsilent>
<!--- 
Debugging 
<cfobject component="#application.themesComponentPath#" name="ThemesObj">
<cfset themeId = ThemesObj.getThemeIdByTheme(Form.defaultTheme)>
<cfoutput>Form.defaultTheme: #Form.defaultTheme# themeId: #themeId#</cfoutput>
<cfoutput>session.loggedin: #session.loggedin# loggedIn: #isUserLoggedIn()# roles: #getUserRoles()#</cfoutput>
--->
<!---
	Name         : /client/admin/index.cfm
	Author       :  : Gregory Alexander/Raymond Camden 
	Created      : 04/12/06
	Last Updated : July 25 2019
	History      : Various changes, forgotten keys, new keys (rkc 9/5/06)
				 : Comment moderation support (tr 12/7/06)
				 : support new properties (rkc 12/14/06)
				 : change moderate postings to moderate comments (rkc 4/13/07)
				 : Added a whole bunch of logic and added new settings for themes (ga)
--->
	
<!--- New form settings:
parentSiteLink
parentSiteName
blogFontSize
myThemeName
useCustomTheme
contentWidth
stretchHeaderAcrossPage
mainContainerWidth
sideBarContainerWidth
darkTheme
siteOpacity
blogBackgroundImage
blogBackgroundImageRepeat
blogBackgroundImagePosition
alignBlogMenuWithBlogContent
topMenuAlign
headerBackgroundImage
menuBackgroundImage
coverKendoMenuWithMenuBackgroundImage
logoImageMobile
logoMobileWidth
logoImage
logoPaddingTop
logoPaddingRight
logoPaddingLeft
logoPaddingBottom
blogNameTextColor
headerBodyDividerImage
--->

<!--- The Themes component interacts with the Blog themes. --->
<cfobject component="#application.themesComponentPath#" name="ThemesObj">
<!---<cfset ThemesObj.initThemeVars()>--->
<!--- Include the theme functions. --->
<cfinclude template="../common/function/displayAndTheme.cfm">
<!--- Create a list of the default themes. --->
<cfset defaultKendoThemes = "default,black,blueOpal,flat,highcontrast,material,materialblack,metro,moonlight,office365,silver,uniform,nova">
<!--- Default custom theme names. --->
<cfset customThemeNames = "Zion,Pillars of Creation,Blue Planet,Bahama Bank,Orion,Blue Wave,Blue Wave Dark,Grand Teton,Yellowstone,Mukilteo,Abstract Blue,Cobalt,Sunrise">
<!--- If necessary, include the UDF (Raymond's code) --->
<cfif application.adminApplicationTemplateType eq "cfc">
	<cftry>
		<cfinclude template="../includes/udf.cfm">
		<cfcatch type="any">
			<cfset error = "UDF declared twice. This occurs when I am using the cfc for error reporting">
		</cfcatch>
	</cftry>
</cfif>

<cfif not application.settings>
	<cflocation url="index.cfm" addToken="false">
</cfif>

<!--- quick utility func to change foo,moo to foo<newline>moo and reverse --->
<cfscript>
function toLines(str) { return replace(str, ",", chr(10), "all"); }
function toList(str) {
	str = replace(str, chr(10), "", "all");
	str = replace(str, chr(13), ",", "all");
	return str;
}
</cfscript>
	
</cfsilent>

<cfset settings = application.blog.getProperties()>
<cfset settingsUpdated = false>
<cfset validDBTypes = application.blog.getValidDBTypes()>
<!--- Create the default form values. --->
<cfloop item="setting" collection="#settings#">
	<cfparam name="form.#setting#" default="#settings[setting]#">
</cfloop>

<!---
we can use all the settings, but username and password may get overwritten
by a login attempt, see this bug report:
http://blogcfc.riaforge.org/index.cfm?event=page.issue&issueid=4CEC3A8A-C919-ED1E-17FD790A1A7DE997
--->
<cfparam name="form.dsn_username" default="#settings.username#">
<cfparam name="form.dsn_password" default="#settings.password#">

<cfif structKeyExists(form, "cancel")>
	<cflocation url="index.cfm" addToken="false">
</cfif>

<cfif structKeyExists(form, "save")>
	<cfset errors = arrayNew(1)>

	<cfif not len(trim(form.blogtitle))>
		<cfset arrayAppend(errors, "Your blog must have a title.")>
	</cfif>

	<cfif not len(trim(form.blogurl))>
		<cfset arrayAppend(errors, "Your blog url cannot be blank.")>
	<cfelseif right(form.blogurl, 9) is not "index.cfm">
		<cfset arrayAppend(errors, "The blogurl setting must end with index.cfm.")>

	</cfif>

	<cfif len(trim(form.commentsfrom)) and not isEmail(form.commentsfrom)>
		<cfset arrayAppend(errors, "The commentsfrom setting must be a valid email address.")>
	</cfif>

	<cfif len(trim(form.failto)) and not isEmail(form.failto)>
		<cfset arrayAppend(errors, "The failto setting must be a valid email address.")>
	</cfif>

	<cfif len(trim(form.maxentries)) and not isNumeric(form.maxentries)>
		<cfset arrayAppend(errors, "Max entries must be numeric.")>
	</cfif>

	<cfif len(trim(form.offset)) and not isNumeric(form.offset)>
		<cfset arrayAppend(errors, "Offset must be numeric.")>
	</cfif>

	<cfset form.pingurls = toList(form.pingurls)>

	<cfif not len(trim(form.dsn))>
		<cfset arrayAppend(errors, "Your blog must have a dsn.")>
	</cfif>

	<cfif not len(trim(form.locale))>
		<cfset arrayAppend(errors, "Your blog must have a locale.")>
	</cfif>

	<cfset form.ipblocklist = toList(form.ipblocklist)>
	<cfset form.trackbackspamlist = listSort(toList(form.trackbackspamlist),"textnocase")>

	<cfif not arrayLen(errors)>
		<!--- copy dsn_* --->
		<cfset form.username = form.dsn_username>
		<cfset form.password = form.dsn_password>

		<!--- Note: there are 3 sections that we need to update: 'default', 'themes', and 'theme1, theme2, theme3, etc.'--->
			
		<!--- Update the 'default' section of the ini tile. Make a list of the keys we will send. --->
		<cfset keylist = "blogtitle,blogdescription,blogkeywords,blogurl,parentSiteName,parentSiteLink,modifyDefaultThemes,blogFontSize,addThisApiKey,commentsfrom,maxentries,offset,pingurls,dsn,blogdbtype,locale,ipblocklist,moderate,usetweetbacks,trackbackspamlist,mailserver,mailusername,mailpassword,usecaptcha,allowgravatars,owneremail,username,password,filebrowse,imageroot,itunessubtitle,itunessummary,ituneskeywords,itunesauthor,itunesimage,itunesexplicit,usecfp,failto,encryptionPhrase">
		<cfloop index="key" list="#trim(keylist)#">
			<cfif structKeyExists(form, key)>
				<cfset application.blog.setProperty(key, trim(form[key]))>
			</cfif>
		</cfloop>
			
		<!--- Set the basic theme settings (there is only one general theme setting right now, the 'defaultKendoThemes'). This logic allows the user to select and deselect the default themes. --->
		<cfparam name="selectedKendoThemeString" default="">
		<cfparam name="selectedCustomThemeString" default="">
		<cfparam name="selectedKendoThemeLoopCount" default="1">
		<!--- The selectedKendoTheme for contains two elements, the kendo name and the custom name. We need to have both items as we also need to set the customThemeNames setting in the ini file. --->
		<!--- Loop through the selected forms. --->
		<cfloop list="#Form.selectedKendoTheme#" index="kendoTheme">
			<!--- Retrive the kendo and custom theme name out of the list. The separator is an underscore. --->
			<cfif selectedKendoThemeLoopCount neq 1 and selectedKendoThemeLoopCount lte listLen(Form.selectedKendoTheme, ",")>
				<cfset selectedKendoThemeString = selectedKendoThemeString & "," & listGetAt(kendoTheme, 1, "_")>
				<cfset selectedCustomThemeString = selectedCustomThemeString & "," & listGetAt(kendoTheme, 2, "_")>
			<cfelse>
				<cfset selectedKendoThemeString = selectedKendoThemeString & listGetAt(kendoTheme, 1, "_")>
				<cfset selectedCustomThemeString = selectedCustomThemeString & listGetAt(kendoTheme, 2, "_")>
			</cfif>
			<cfset selectedKendoThemeLoopCount = selectedKendoThemeLoopCount+1>
		</cfloop>
		<!--- Now that we have our strings built, update the defaultKendoThemes string inside the file. --->
		<cfset setting = setProfileString("#application.iniFile#", "themes", "defaultKendoThemes", "#trim(selectedKendoThemeString)#")>
		<!--- Update the customThemeNames string inside the file. --->
		<cfset setting = setProfileString("#application.iniFile#", "themes", "customThemeNames", "#trim(selectedCustomThemeString)#")>
			
		<!--- Set the unique settings by themeId. The themes need a theme id string (ie theme1).--->
		<!--- Get the theme id --->
		<cfset themeId = ThemesObj.getThemeIdByTheme(Form.defaultTheme)>
		<!--- Preset the themeLoopCount --->
		<cfset themeLoopCount = 1>
		<!--- Set the theme string that is expected in the ini file. --->
		<cfset themeIdString = 'theme' & themeId>
		<cfset themeKeyList = "useCustomTheme,customThemeName,darkTheme,contentWidth,mainContainerWidth,sideBarContainerWidth,siteOpacity,blogBackgroundImage,blogBackgroundImageRepeat,blogBackgroundImagePosition,stretchHeaderAcrossPage,alignBlogMenuWithBlogContent,topMenuAlign,headerBackgroundImage,menuBackgroundImage,coverKendoMenuWithMenuBackgroundImage,logoImageMobile,logoMobileWidth,logoImage,logoPaddingTop,logoPaddingRight,logoPaddingLeft,logoPaddingBottom,blogNameTextColor,headerBodyDividerImage,kendoThemeCssFileLocation,kendoThemeMobileCssFileLocation,breakpoint,customCoreLogicTemplate,customHeadTemplate,customBodyString,customFontCssTemplate,customGlobalAndBodyCssTemplate,customTopMenuCssTemplate,customTopMenuHtmlTemplate,customTopMenuJsTemplate,customBlogContentCssTemplate,customBlogJsContentTemplate,customBlogContentHtmlTemplate,customFooterHtmlTemplate">
			
		<cfloop index="key" list="#trim(themeKeylist)#">
			<cfif structKeyExists(form, key)>
				<!---<cfoutput>#themeIdString#, #key#, #trim(form[key])#</cfoutput>--->
				<!--- Save the value in the ini file. --->
				<cfset setting = setProfileString("#application.iniFile#", "#themeIdString#", "#trim(key)#", "#trim(form[key])#")>
				<!--- Save the value in the application's theme array. I don't want to reset this array from scratch as working with the ini flat file is just too slow. --->
				<cfset application.themeSettingsArray[themeId][themeLoopCount] = "#trim(form[key])#">
			</cfif>
			<cfset themeLoopCount = themeLoopCount + 1>
		</cfloop>
		<!--- Inform the user that the main page will reload next time that it is launched. --->
		<cfset settingsUpdated = true>

	</cfif><!---<cfif not arrayLen(errors)>--->
</cfif><!---<cfif structKeyExists(form, "save")>--->
  
<cfmodule template="../tags/adminlayout.cfm" title="Settings">
	
	<!---<cfoutput>rootUrl: #application.baseUrl# loggedIn: #isLoggedIn()# isAdmin: #cookie.isAdmin#</cfoutput>--->
	
	<cfif settingsUpdated>
		<cfoutput>
			<div style="margin: 15px 0; padding: 15px; border: 5px solid ##008000; background-color: ##80ff00; color: ##000000; font-weight: bold; text-align: center;">
				Your settings have been updated. 
			</div>
		</cfoutput>
	</cfif>
		
	<script>
		// Determine if the particular theme has been modified. For efficiency, we will be using ColdFusion application variables to output the results for javascript.
		function isThemeModified(themeId){
			// Get the custom name
			switch(themeId) {
				case 1:
					var themeWasModified = <cfoutput>#application.themeSettingsArray[1][1]#</cfoutput>;
				break;	
				case 2:
					var themeWasModified = <cfoutput>#application.themeSettingsArray[2][1]#</cfoutput>;
				break;
				case 3:
					var themeWasModified = <cfoutput>#application.themeSettingsArray[3][1]#</cfoutput>;
				break;
				case 4:
					var themeWasModified = <cfoutput>#application.themeSettingsArray[4][1]#</cfoutput>;
				break;
				case 5:
					var themeWasModified = <cfoutput>#application.themeSettingsArray[5][1]#</cfoutput>;
				break;
				case 6:
					var themeWasModified = <cfoutput>#application.themeSettingsArray[6][1]#</cfoutput>;		  
				break;
				case 7:
					var themeWasModified = <cfoutput>#application.themeSettingsArray[7][1]#</cfoutput>;  
				break;
				case 8:
					var themeWasModified = <cfoutput>#application.themeSettingsArray[8][1]#</cfoutput>;  
				break;
				case 9:
					var themeWasModified = <cfoutput>#application.themeSettingsArray[9][1]#</cfoutput>;	  
				break;
				case 10:
					var themeWasModified = <cfoutput>#application.themeSettingsArray[10][1]#</cfoutput>;		  
				break;
				case 11:
					var themeWasModified = <cfoutput>#application.themeSettingsArray[11][1]#</cfoutput>;	  
				break;
				case 12:
					var themeWasModified = <cfoutput>#application.themeSettingsArray[12][1]#</cfoutput>;	  
				break;
				case 13:
					var themeWasModified = <cfoutput>#application.themeSettingsArray[13][1]#</cfoutput>;  
				break;
				case 14:
					var themeWasModified = <cfoutput>#application.themeSettingsArray[14][1]#</cfoutput>;		  
				break;
			}//.. switch
			return themeWasModified;
		}//.. function
		
		// Populate the theme settings.
		$(document).ready(function() {
			getThemeSettingsFromProperStore();
		});//..document.ready
		
		// Determine if we should get the default theme settings, or the settings that are store in the ini config file. This is necessary as many users won't change the theme settings at all. 
		function getThemeSettingsFromProperStore(){
			// Get the selected theme.
			var uiTheme = $('#defaultTheme').val();
			// Get the themeId
			var themeId = 'theme' + getThemeIdByTheme(uiTheme);
			// Also determine if the selected theme has been modified. Whenever a theme has been modified, the useCustomTheme setting will be set to true (this fixes a bug found in version 1.1).
			var thisThemeWasModified = isThemeModified(themeId);

			// See if the selected theme was modified. 
			if (thisThemeWasModified){
				// Call the getAllThemeSettingsFromIniStore method to populate the initial form
				getAllThemeSettingsFromIniStore(themeId);//The theme id is actually a string and is a section in the config file. 'theme3' is the default Kendo theme.
			} else {
				// Get the default themes.
				getDefaultThemeSettings(uiTheme);
			}
		}
		
		// For safety, the themes can't be modified unless the user checks the use custom theme checkbox. Disable or enable the forms based upon whether the user checked this box (in the past, or now).
		<cfif getProfileString(application.iniFile, "themes", "modifyDefaultThemes") eq true>disableThemeForms(false);<cfelse>disableThemeForms(true);</cfif>
		
		// Function to enable theme properties when the modify themes button is checked (note: the admin site is still using an older version of jQuery).
		function disableThemeForms(){
			
			// Determine if the modifyDefaultThemes checkbox was checked.
			modifyThemesChecked = $("#modifyDefaultThemes").attr("checked"); 
			
			if (modifyThemesChecked){
				$(document).ready(function() {
					//$("#fname").removeAttr("disabled");
					//$("#hname").attr("disabled",true);
					$("#customThemeName").removeAttr("disabled");
					$("#darkTheme").removeAttr("disabled");
					$("#contentWidth").removeAttr("disabled");
					$("#mainContainerWidth").removeAttr("disabled");
					$("#sideBarContainerWidth").removeAttr("disabled");
					$("#siteOpacity").removeAttr("disabled");
					$("#blogBackgroundImage").removeAttr("disabled");
					$("#blogBackgroundImageRepeat").removeAttr("disabled");
					$("#blogBackgroundImagePosition").removeAttr("disabled");
					$("#stretchHeaderAcrossPage").removeAttr("disabled");
					$("#alignBlogMenuWithBlogContent").removeAttr("disabled");
					$("#topMenuAlign").removeAttr("disabled");
					$("#headerBackgroundImage").removeAttr("disabled");
					$("#menuBackgroundImage").removeAttr("disabled");
					$("#coverKendoMenuWithMenuBackgroundImage").removeAttr("disabled");
					$("#logoImageMobile").removeAttr("disabled");
					$("#logoMobileWidth").removeAttr("disabled");
					$("#logoImage").removeAttr("disabled");
					$("#logoPaddingTop").removeAttr("disabled");
					$("#logoPaddingRight").removeAttr("disabled");
					$("#logoPaddingLeft").removeAttr("disabled");
					$("#logoPaddingBottom").removeAttr("disabled");
					$("#blogNameTextColor").removeAttr("disabled");
					$("#headerBodyDividerImage").removeAttr("disabled");
					$("#kendoThemeCssFileLocation").removeAttr("disabled");
					$("#kendoThemeMobileCssFileLocation").removeAttr("disabled");
					$("#breakpoint").removeAttr("disabled");
					$("#customCoreLogicTemplate").removeAttr("disabled");
					$("#customHeadTemplate").removeAttr("disabled");
					$("#customBodyString").removeAttr("disabled");
					$("#customFontCssTemplate").removeAttr("disabled");
					$("#customGlobalAndBodyCssTemplate").removeAttr("disabled");
					$("#customTopMenuCssTemplate").removeAttr("disabled");
					$("#customTopMenuHtmlTemplate").removeAttr("disabled");
					$("#customTopMenuJsTemplate").removeAttr("disabled");
					$("#customBlogContentCssTemplate").removeAttr("disabled");
					$("#customBlogJsContentTemplate").removeAttr("disabled");
					$("#customBlogContentHtmlTemplate").removeAttr("disabled");
					$("#customFooterHtmlTemplate").removeAttr("disabled");
				});//..document.ready
			} else {
				$(document).ready(function() {
					$("#customThemeName").attr("disabled", true);
					$("#darkTheme").attr("disabled", true);
					$("#contentWidth").attr("disabled", true);
					$("#mainContainerWidth").attr("disabled", true);
					$("#sideBarContainerWidth").attr("disabled", true);
					$("#siteOpacity").attr("disabled", true);
					$("#blogBackgroundImage").attr("disabled", true);
					$("#blogBackgroundImageRepeat").attr("disabled", true);
					$("#blogBackgroundImagePosition").attr("disabled", true);
					$("#stretchHeaderAcrossPage").attr("disabled", true);
					$("#alignBlogMenuWithBlogContent").attr("disabled", true);
					$("#topMenuAlign").attr("disabled", true);
					$("#headerBackgroundImage").attr("disabled", true);
					$("#menuBackgroundImage").attr("disabled", true);
					$("#coverKendoMenuWithMenuBackgroundImage").attr("disabled", true);
					$("#logoImageMobile").attr("disabled", true);
					$("#logoMobileWidth").attr("disabled", true);
					$("#logoImage").attr("disabled", true);
					$("#logoPaddingTop").attr("disabled", true);
					$("#logoPaddingRight").attr("disabled", true);
					$("#logoPaddingLeft").attr("disabled", true);
					$("#logoPaddingBottom").attr("disabled", true);
					$("#blogNameTextColor").attr("disabled", true);
					$("#headerBodyDividerImage").attr("disabled", true);
					$("#kendoThemeCssFileLocation").attr("disabled", true);
					$("#kendoThemeMobileCssFileLocation").attr("disabled", true);
					$("#breakpoint").attr("disabled", true);
					$("#customCoreLogicTemplate").attr("disabled", true);
					$("#customHeadTemplate").attr("disabled", true);
					$("#customBodyString").attr("disabled", true);
					$("#customFontCssTemplate").attr("disabled", true);
					$("#customGlobalAndBodyCssTemplate").attr("disabled", true);
					$("#customTopMenuCssTemplate").attr("disabled", true);
					$("#customTopMenuHtmlTemplate").attr("disabled", true);
					$("#customTopMenuJsTemplate").attr("disabled", true);
					$("#customBlogContentCssTemplate").attr("disabled", true);
					$("#customBlogJsContentTemplate").attr("disabled", true);
					$("#customBlogContentHtmlTemplate").attr("disabled", true);
					$("#customFooterHtmlTemplate").attr("disabled", true);
				});//..document.ready
			}
		}
		
		// Gets the default theme settings. This function is used when the useCustomTheme radio button is NOT checked. If the button is checked, the getAllThemeSettingsFromIniStore function will be used to populate teh forms instead. 
		function getDefaultThemeSettings(uiTheme){
			// alert('Getting default themes.');
			// Get all of the theme properties stored in the ini configuration file.
			$.ajax({
				type: "get",
				url: "<cfoutput>#application.themeComponentUrl#?</cfoutput>method=getDefaultSettingsByThemeAsJson",
				data: { // method and the arguments
					uiTheme: uiTheme
				},
				dataType: "json",
				cache: false,
				success: function (data){
					// Pass the data to the getDefaultThemeSettingsResult function. 
					defaultThemeSettingsResult(data);
				},
				error: function(xhr, textStatus, error){
					console.log(xhr.statusText);
					console.log(textStatus);
					console.log(error);
				}
			});
		}//... function
	
		// Extract the items from the json array that was returned. ***************************************************************
		function defaultThemeSettingsResult(response){
			// Get the response from the server
			var useCustomThemeValue = response.useCustomTheme;
			var customThemeNameValue = response.customThemeName;
			var darkThemeValue = response.darkTheme;
			var contentWidthValue = response.contentWidth;
			var mainContainerWidthValue = response.mainContainerWidth;
			var sideBarContainerWidthValue = response.sideBarContainerWidth;
			var siteOpacityValue = response.siteOpacity;
			var blogBackgroundImageValue = response.blogBackgroundImage;
			var blogBackgroundImageRepeatValue = response.blogBackgroundImageRepeat;
			var blogBackgroundImagePositionValue = response.blogBackgroundImagePosition;
			var stretchHeaderAcrossPageValue = response.stretchHeaderAcrossPage;
			var alignBlogMenuWithBlogContentValue = response.alignBlogMenuWithBlogContent;
			var topMenuAlignValue = response.topMenuAlign;
			var headerBackgroundImageValue = response.headerBackgroundImage;
			var menuBackgroundImageValue = response.menuBackgroundImage;
			var coverKendoMenuWithMenuBackgroundImageValue = response.coverKendoMenuWithMenuBackgroundImage;
			var logoImageMobileValue = response.logoImageMobile;
			var logoMobileWidthValue = response.logoMobileWidth;
			var logoImageValue = response.logoImage;
			var logoPaddingTopValue = response.logoPaddingTop;
			var logoPaddingRightValue = response.logoPaddingRight;
			var logoPaddingLeftValue = response.logoPaddingLeft;
			var logoPaddingBottomValue = response.logoPaddingBottom;
			var blogNameTextColorValue = response.blogNameTextColor;
			var headerBodyDividerImageValue = response.headerBodyDividerImage;
			var kendoThemeCssFileLocationValue = response.kendoThemeCssFileLocation;
			var kendoThemeMobileCssFileLocationValue = response.kendoThemeMobileCssFileLocation;
			var breakpoint = response.breakpoint;
			var customCoreLogicTemplateValue = response.customCoreLogicTemplate;
			var customHeadTemplateValue = response.customHeadTemplate;
			var customBodyStringValue = response.customBodyString;
			var customFontCssTemplateValue = response.customFontCssTemplate;
			var customGlobalAndBodyCssTemplateValue = response.customGlobalAndBodyCssTemplate;
			var customTopMenuCssTemplateValue = response.customTopMenuCssTemplate;
			var customTopMenuHtmlTemplateValue = response.customTopMenuHtmlTemplate;
			var customTopMenuJsTemplateValue = response.customTopMenuJsTemplate;
			var customBlogContentCssTemplateValue = response.customBlogContentCssTemplate;
			var customBlogJsContentTemplateValue = response.customBlogJsContentTemplate;
			var customBlogContentHtmlTemplateValue = response.customBlogContentHtmlTemplate;
			var customFooterHtmlTemplateValue = response.customFooterHtmlTemplate;

			// After the response has been extracted, set the new values on the admin settings form. Important note- out of necessity, the admin interface is using an older version of jQuery. This may need to be changed when I put in the new Kendo interface with an updated version of jquery. 
			// useCustomTheme is a radio button. Note: the value is interpreted as a booleand (yes: true, no: false).
			// Important note: the useCustomThemeValue can either be a boolean when consumed via ajax, or a yes no string when consumed from ColdFusion.
			
			/* This code will be used in a later version. Right now, the useCustomTheme is a hidden form that is set to true. 
			if (useCustomThemeValue || useCustomThemeValue == 'yes'){
				// Altneratively we could use:
				//$('input:radio[name=useCustomTheme]')[0].checked = true;
				//$('input:radio[name=useCustomTheme]')[1].checked = false
				$("input[type='radio'][name='useCustomTheme'][value='true']").attr('checked', true);
				$("input[type='radio'][name='useCustomTheme'][value='false']").attr('checked', false);
			} else {
				$("input[type='radio'][name='useCustomTheme'][value='true']").attr('checked', false);
				$("input[type='radio'][name='useCustomTheme'][value='false']").attr('checked', true);
			}
			*/
			// Theme name
			// Theme name. If it is blank, insert the default custom theme name.
			if (customThemeNameValue != ''){
				$( "#customThemeName" ).val( customThemeNameValue );
			} else {
				$( "#customThemeName" ).val( getCustomThemeNameByKendoTheme( $('#defaultTheme').val() ) );
			}
			// Dark theme radio button
			// Can be boolean (ajax) or string (ColdFusion inline code)
			if (darkThemeValue || darkThemeValue == 'yes'){
				$("input[type='radio'][name='darkTheme'][value='true']").attr('checked', true);
				$("input[type='radio'][name='darkTheme'][value='false']").attr('checked', false);
			} else {
				$("input[type='radio'][name='darkTheme'][value='true']").attr('checked', false);
				$("input[type='radio'][name='darkTheme'][value='false']").attr('checked', true);
			}
			// Dropdown menu
			$( "#contentWidth" ).val( contentWidthValue );
			$( "#mainContainerWidth" ).val( mainContainerWidthValue );
			$( "#sideBarContainerWidth" ).val( sideBarContainerWidthValue );
			$( "#siteOpacity" ).val( siteOpacityValue );
			$( "#blogBackgroundImage" ).val( blogBackgroundImageValue );
			$( "#blogBackgroundImageRepeat" ).val( blogBackgroundImageRepeatValue );
			$( "#blogBackgroundImagePosition" ).val( blogBackgroundImagePositionValue );
			// Radio button
			if (stretchHeaderAcrossPageValue || stretchHeaderAcrossPageValue == 'yes'){
				$("input[type='radio'][name='stretchHeaderAcrossPage'][value='true']").attr('checked', true);
				$("input[type='radio'][name='stretchHeaderAcrossPage'][value='false']").attr('checked', false);
			} else {
				$("input[type='radio'][name='stretchHeaderAcrossPage'][value='true']").attr('checked', false);
				$("input[type='radio'][name='stretchHeaderAcrossPage'][value='false']").attr('checked', true);
			}
			$( "#alignBlogMenuWithBlogContent" ).val( alignBlogMenuWithBlogContentValue );
			$( "#topMenuAlign" ).val( topMenuAlignValue );
			$( "#headerBackgroundImage" ).val( headerBackgroundImageValue );
			$( "#menuBackgroundImage" ).val( menuBackgroundImageValue );
			// Radio button
			if (coverKendoMenuWithMenuBackgroundImageValue || coverKendoMenuWithMenuBackgroundImageValue == 'yes'){
				$("input[type='radio'][name='coverKendoMenuWithMenuBackgroundImage'][value='true']").attr('checked', true);
				$("input[type='radio'][name='coverKendoMenuWithMenuBackgroundImage'][value='false']").attr('checked', false);
			} else {
				$("input[type='radio'][name='coverKendoMenuWithMenuBackgroundImage'][value='true']").attr('checked', false);
				$("input[type='radio'][name='coverKendoMenuWithMenuBackgroundImage'][value='false']").attr('checked', true);
			}
			$( "#logoImageMobile" ).val( logoImageMobileValue );
			$( "#logoMobileWidth" ).val( logoMobileWidthValue );
			$( "#logoImage" ).val( logoImageValue );
			$( "#logoPaddingTop" ).val( logoPaddingTopValue );
			$( "#logoPaddingRight" ).val( logoPaddingRightValue );
			$( "#logoPaddingLeft" ).val( logoPaddingLeftValue );
			$( "#logoPaddingBottom" ).val( logoPaddingBottomValue );
			$( "#blogNameTextColor" ).val( blogNameTextColorValue );
			$( "#headerBodyDividerImage" ).val( headerBodyDividerImageValue );
			$( "#kendoThemeCssFileLocation" ).val( kendoThemeCssFileLocationValue );
			$( "#kendoThemeMobileCssFileLocation" ).val( kendoThemeMobileCssFileLocationValue );
			$( "#breakpoint" ).val( breakpoint );
			$( "#customCoreLogicTemplate" ).val( customCoreLogicTemplateValue );
			$( "#customHeadTemplate" ).val( customHeadTemplateValue );
			$( "#customBodyString" ).val( customBodyStringValue );
			$( "#customFontCssTemplate" ).val( customFontCssTemplateValue );
			$( "#customGlobalAndBodyCssTemplate" ).val( customGlobalAndBodyCssTemplateValue );
			$( "#customTopMenuCssTemplate" ).val( customTopMenuCssTemplateValue );
			$( "#customTopMenuHtmlTemplate" ).val( customTopMenuHtmlTemplateValue );
			$( "#customTopMenuJsTemplate" ).val( customTopMenuJsTemplateValue );
			$( "#customBlogContentCssTemplate" ).val( customBlogContentCssTemplateValue );
			$( "#customBlogJsContentTemplate" ).val( customBlogJsContentTemplateValue );
			$( "#customBlogContentHtmlTemplate" ).val( customBlogContentHtmlTemplateValue );
			$( "#customFooterHtmlTemplate" ).val( customFooterHtmlTemplateValue );
			//alert('done');
		} //..function 
		
		// Gets the detheme settings stored in the ini file. This function is used when the useCustomTheme radio button IS checked. If the button is checked, the getDefaultThemeSettings function will be used to populate teh forms instead. IN ADDITION, if the useCustomTheme form value is not true, then this function will exit and call the getDefaultThemeSettings as well. This is needed as I want to make sure that if the user meant to have changed the theme.
		function getAllThemeSettingsFromIniStore(themeId){
			// Get all of the theme properties stored in the ini configuration file.
			$.ajax({
				type: "get",
				url: "<cfoutput>#application.themeComponentUrl#?</cfoutput>method=getAllThemeSettingsFromIniStoreAsJson",
				data: { // method and the arguments
					themeId: themeId
				},
				dataType: "json",
				cache: false,
				success: function (data){
					// Pass the data to the getAllThemeSettingsResult function. 
					getAllThemeSettingsResult(data);
				},
				error: function(xhr, textStatus, error){
					console.log(xhr.statusText);
					console.log(textStatus);
					console.log(error);
				}
			});
		}//... function
		
		// Extract the items from the json array that was returned. ***************************************************************
		function getAllThemeSettingsResult(response){
				
			// Get the response from the server
			var useCustomThemeValue = response.useCustomTheme;
			var customThemeNameValue = response.customThemeName;
			var darkThemeValue = response.darkTheme;
			var contentWidthValue = response.contentWidth;
			var mainContainerWidthValue = response.mainContainerWidth;
			var sideBarContainerWidthValue = response.sideBarContainerWidth;
			var siteOpacityValue = response.siteOpacity;
			var blogBackgroundImageValue = response.blogBackgroundImage;
			var blogBackgroundImageRepeatValue = response.blogBackgroundImageRepeat;
			var blogBackgroundImagePositionValue = response.blogBackgroundImagePosition;
			var stretchHeaderAcrossPageValue = response.stretchHeaderAcrossPage;
			var alignBlogMenuWithBlogContentValue = response.alignBlogMenuWithBlogContent;
			var topMenuAlignValue = response.topMenuAlign;
			var headerBackgroundImageValue = response.headerBackgroundImage;
			var menuBackgroundImageValue = response.menuBackgroundImage;
			var coverKendoMenuWithMenuBackgroundImageValue = response.coverKendoMenuWithMenuBackgroundImage;
			var logoImageMobileValue = response.logoImageMobile;
			var logoMobileWidthValue = response.logoMobileWidth;
			var logoImageValue = response.logoImage;
			var logoPaddingTopValue = response.logoPaddingTop;
			var logoPaddingRightValue = response.logoPaddingRight;
			var logoPaddingLeftValue = response.logoPaddingLeft;
			var logoPaddingBottomValue = response.logoPaddingBottom;
			var blogNameTextColorValue = response.blogNameTextColor;
			var headerBodyDividerImageValue = response.headerBodyDividerImage;
			var kendoThemeCssFileLocationValue = response.kendoThemeCssFileLocation;
			var kendoThemeMobileCssFileLocationValue = response.kendoThemeMobileCssFileLocation;
			var breakpoint = response.breakpoint;
			var customCoreLogicTemplateValue = response.customCoreLogicTemplate;
			var customHeadTemplateValue = response.customHeadTemplate;
			var customBodyStringValue = response.customBodyString;
			var customFontCssTemplateValue = response.customFontCssTemplate;
			var customGlobalAndBodyCssTemplateValue = response.customGlobalAndBodyCssTemplate;
			var customTopMenuCssTemplateValue = response.customTopMenuCssTemplate;
			var customTopMenuHtmlTemplateValue = response.customTopMenuHtmlTemplate;
			var customTopMenuJsTemplateValue = response.customTopMenuJsTemplate;
			var customBlogContentCssTemplateValue = response.customBlogContentCssTemplate;
			var customBlogJsContentTemplateValue = response.customBlogJsContentTemplate;
			var customBlogContentHtmlTemplateValue = response.customBlogContentHtmlTemplate;
			var customFooterHtmlTemplateValue = response.customFooterHtmlTemplate;

			// After the response has been extracted, set the new values on the admin settings form. Important note- out of necessity, the admin interface is using an older version of jQuery. This may need to be changed when I put in the new Kendo interface with an updated version of jquery. 
			// useCustomTheme is a radio button. Note: the value is interpreted as a booleand (yes: true, no: false).
			// Important notes: this function will call the getDefaultThemeSettings if the useCustomTheme buton was not checked. 
			
			/* This code will be used in a later version. Right now, the useCustomTheme is a hidden form that is set to true. 
			if (useCustomThemeValue || useCustomThemeValue == 'yes'){
				// Altneratively we could use:
				//$('input:radio[name=useCustomTheme]')[0].checked = true;
				//$('input:radio[name=useCustomTheme]')[1].checked = false
				$("input[type='radio'][name='useCustomTheme'][value='true']").attr('checked', true);
				$("input[type='radio'][name='useCustomTheme'][value='false']").attr('checked', false);
			} else {
				// Call the getDefaultThemeSettings method.
				getDefaultThemeSettings($('#defaultTheme').val());
				// Exit function
				return;
			}
			*/
			
			// Theme name. If it is blank, insert the default custom theme name.
			if (customThemeNameValue != ''){
				$( "#customThemeName" ).val( customThemeNameValue );
			} else {
				$( "#customThemeName" ).val( getCustomThemeNameByKendoTheme( $('#defaultTheme').val() ) );
			}
			// Dark theme radio button
			// Can be boolean (ajax) or string (ColdFusion inline code)
			if (darkThemeValue || darkThemeValue == 'yes'){
				$("input[type='radio'][name='darkTheme'][value='true']").attr('checked', true);
				$("input[type='radio'][name='darkTheme'][value='false']").attr('checked', false);
			} else {
				$("input[type='radio'][name='darkTheme'][value='true']").attr('checked', false);
				$("input[type='radio'][name='darkTheme'][value='false']").attr('checked', true);
			}
			// Dropdown menu
			$( "#contentWidth" ).val( contentWidthValue );
			$( "#mainContainerWidth" ).val( mainContainerWidthValue );
			$( "#sideBarContainerWidth" ).val( sideBarContainerWidthValue );
			$( "#siteOpacity" ).val( siteOpacityValue );
			$( "#blogBackgroundImage" ).val( blogBackgroundImageValue );
			$( "#blogBackgroundImageRepeat" ).val( blogBackgroundImageRepeatValue );
			$( "#blogBackgroundImagePosition" ).val( blogBackgroundImagePositionValue );
			// Radio button
			if (stretchHeaderAcrossPageValue || stretchHeaderAcrossPageValue == 'yes'){
				$("input[type='radio'][name='stretchHeaderAcrossPage'][value='true']").attr('checked', true);
				$("input[type='radio'][name='stretchHeaderAcrossPage'][value='false']").attr('checked', false);
			} else {
				$("input[type='radio'][name='stretchHeaderAcrossPage'][value='true']").attr('checked', false);
				$("input[type='radio'][name='stretchHeaderAcrossPage'][value='false']").attr('checked', true);
			}
			$( "#alignBlogMenuWithBlogContent" ).val( alignBlogMenuWithBlogContentValue );
			$( "#topMenuAlign" ).val( topMenuAlignValue );
			$( "#headerBackgroundImage" ).val( headerBackgroundImageValue );
			$( "#menuBackgroundImage" ).val( menuBackgroundImageValue );
			// Radio button
			if (coverKendoMenuWithMenuBackgroundImageValue || coverKendoMenuWithMenuBackgroundImageValue == 'yes'){
				$("input[type='radio'][name='coverKendoMenuWithMenuBackgroundImage'][value='true']").attr('checked', true);
				$("input[type='radio'][name='coverKendoMenuWithMenuBackgroundImage'][value='false']").attr('checked', false);
			} else {
				$("input[type='radio'][name='coverKendoMenuWithMenuBackgroundImage'][value='true']").attr('checked', false);
				$("input[type='radio'][name='coverKendoMenuWithMenuBackgroundImage'][value='false']").attr('checked', true);
			}
			$( "#logoImageMobile" ).val( logoImageMobileValue );
			$( "#logoMobileWidth" ).val( logoMobileWidthValue );
			$( "#logoImage" ).val( logoImageValue );
			$( "#logoPaddingTop" ).val( logoPaddingTopValue );
			$( "#logoPaddingRight" ).val( logoPaddingRightValue );
			$( "#logoPaddingLeft" ).val( logoPaddingLeftValue );
			$( "#logoPaddingBottom" ).val( logoPaddingBottomValue );
			$( "#blogNameTextColor" ).val( blogNameTextColorValue );
			$( "#headerBodyDividerImage" ).val( headerBodyDividerImageValue );
			$( "#kendoThemeCssFileLocation" ).val( kendoThemeCssFileLocationValue );
			$( "#kendoThemeMobileCssFileLocation" ).val( kendoThemeMobileCssFileLocationValue );
			$( "#breakpoint" ).val( breakpoint );
			$( "#customCoreLogicTemplate" ).val( customCoreLogicTemplateValue );
			$( "#customHeadTemplate" ).val( customHeadTemplateValue );
			$( "#customBodyString" ).val( customBodyStringValue );
			$( "#customFontCssTemplate" ).val( customFontCssTemplateValue );
			$( "#customGlobalAndBodyCssTemplate" ).val( customGlobalAndBodyCssTemplateValue );
			$( "#customTopMenuCssTemplate" ).val( customTopMenuCssTemplateValue );
			$( "#customTopMenuHtmlTemplate" ).val( customTopMenuHtmlTemplateValue );
			$( "#customTopMenuJsTemplate" ).val( customTopMenuJsTemplateValue );
			$( "#customBlogContentCssTemplate" ).val( customBlogContentCssTemplateValue );
			$( "#customBlogJsContentTemplate" ).val( customBlogJsContentTemplateValue );
			$( "#customBlogContentHtmlTemplate" ).val( customBlogContentHtmlTemplateValue );
			$( "#customFooterHtmlTemplate" ).val( customFooterHtmlTemplateValue );

			//alert('Getting themes from configuration file.');
		} //..function 
		
		// Helper functions
		// Get the custom theme name.
		function getCustomThemeNameByKendoTheme(kendoTheme){
			
			// Lower case the kendoTheme string. 
			var kendoTheme = kendoTheme.toLowerCase();
			
			// Get the custom name
			switch (kendoTheme) {
				case "black":
					customThemeName = "Pillars of Creation";
					break;
				case "blueopal":
					customThemeName = "Blue Planet";
					break;
				case "default":
					customThemeName = "Zion";
					break;
				case "fiori":
					customThemeName = "Fiori";
					break;
				case "flat":
					customThemeName = "Bahama Bank";
					break;
				case "highcontrast":
					customThemeName = "Orion";
					break;
				case "material":
					customThemeName = "Blue Wave";
					break;
				case "materialblack":
					customThemeName = "Blue Wave Dark";
					break;
				case "metro":
					customThemeName = "Grand Teton";
					break;
				case "moonlight":
					customThemeName = "Yellowstone";
					break;
				case "nova":
					customThemeName = "Sunrise";
					break;
				case "office365":
					customThemeName = "Mukilteo";
					break;
				case "silver":
					customThemeName = "Abstract Blue";
					break;
				case "uniform":
					customThemeName = "Cobalt";
					break;
			}//.. switch
			return customThemeName;
		}//.. function
		
		// Function to determine the base kendo theme by the id (I built this thinking that the user may change the actual base theme).
		function getThemeIdByTheme(baseKendoTheme){
			switch(baseKendoTheme) {
				case "black":
					var themeId = 1;
				break;	
				case "blueOpal":
					var themeId = 2;
				break;
				case "default":
					var themeId = 3;
				break;
				case "fiori":
					var themeId = 4;
				break;
				case "flat":
					var themeId = 5;
				break;
				case "highcontrast":
					var themeId = 6;		  
				break;
				case "material":
					var themeId = 7;	  
				break;
				case "materialblack":
					var themeId = 8;	  
				break;
				case "metro":
					var themeId = 9;	  
				break;
				case "moonlight":
					var themeId = 10;		  
				break;
				case "nova":
					var themeId = 11;	  
				break;
				case "office365":
					var themeId = 12;		  
				break;
				case "silver":
					var themeId = 13;	  
				break;
				case "uniform":
					var themeId = 14;		  
				break;
			}

			return themeId;
		}	
		
		// This adjusts the side bar width based upon the main container width settings.
		function setSidebarContainerWidth(mainContainerWidth){
			sideBarWidth = 100 - mainContainerWidth;
			$( "#sideBarContainerWidth" ).val( sideBarWidth );
		}
	</script>
	<p>
	Please edit your settings below. <b>Be warned:</b> A mistake here can make both the blog and this
	administrator unreachable. Be careful! ("Here be dragons...")
	</p>

	<cfif structKeyExists(variables, "errors") and arrayLen(errors)>
		<cfoutput>
		<div class="errors">
		Please correct the following error(s):
		<ul>
		<cfloop index="x" from="1" to="#arrayLen(errors)#">
		<li>#errors[x]#</li>
		</cfloop>
		</ul>
		</div>
		</cfoutput>
	</cfif>

	<cfoutput>
	<script>
		function editDatasource() {
			document.getElementById('datasource_edit').style.display='block';
			document.getElementById('datasource_ro').style.display='none';
			document.getElementById('datasource_editbutton').style.display='none';
		}
	</script>
	<form action="settings.cfm" method="post" name="settingsForm">
	<!--- Hidden inputs on settings that are no longer available with Gregory's Blog. --->
	<input type="hidden" id="cfFormProtect" name="cfFormProtect" value="no" />
	<input type="hidden" id="usecfp" name="usecfp" value="no" />
	<input type="hidden" id="usetweetbacks" name="usetweetbacks" value="no" />
			
	<fieldset>
		<legend>Blog Information</legend>
		<ul>
			<li><label for="blogtitle">Blog title:</label><input type="text" name="blogtitle" value="#htmlEditFormat(form.blogtitle)#" class="txtField" maxlength="255"></li>
			<li><label for="blogdescription">Blog description:</label><textarea name="blogdescription" class="txtAreaShort">#htmlEditFormat(form.blogdescription)#</textarea></li>
			<li><label for="blogkeywords">Blog keywords:</label><input type="text" name="blogkeywords" value="#htmlEditFormat(form.blogkeywords)#" class="txtField" maxlength="255"></li>
			<li><label for="owneremail">Owner email:</label><input type="text" name="owneremail" value="#htmlEditFormat(form.owneremail)#" class="txtField" maxlength="255"></li>
			<li><label for="failto">Fail to:</label><input type="text" name="failto" value="#htmlEditFormat(form.failto)#" class="txtField" maxlength="255"></li>
			<li><label for="blogurl">Blog url:</label><input type="text" name="blogurl" value="#form.blogurl#" class="txtField" maxlength="255"></li>
			<li><label for="parentSiteName">Parent site name:</label><input type="text" name="parentSiteName" id="parentSiteName" value="#Form.parentSiteName#" class="txtField" maxlength="255"></li>
			<li><label for="parentSiteLink">Parent site link:</label><input type="text" name="parentSiteLink" id="parentSiteLink" value="#Form.parentSiteLink#" class="txtField" maxlength="255"></li>
			<li><label for="blogFontSize">Default font size:</label>
			<select id="blogFontSize" name="blogFontSize">
				<cfloop from="8" to="26" index="i">
				<option value="#i#" <cfif i eq Form.blogFontSize>selected</cfif>>#i#pt</option>
			</cfloop>
			</select> 
		</li><br/>
		</ul>
	</fieldset>
		
	<fieldset>
		<legend>Default Kendo Themes:</legend>
		<ul>
		<cfset defaultKendoThemeLoopCount = 1>
		<!--- What are the currently active themes? --->
		<cfset currentSelectedThemes = getProfileString(application.iniFile, "themes", "defaultKendoThemes")>
		<!--- Note: the string produced by this interface is found under the themes section in the configuration file, not in default.--->
		<cfloop list="#defaultKendoThemes#" index="kendoTheme">
			<cfif listFindNoCase(currentSelectedThemes, kendoTheme) gt 0>
				<cfset themeCheckedString = "checked">
			<cfelse>
				<cfset themeCheckedString = "">
			</cfif>
			<li>
				<!--- We are going to create a list with two items, the kendo theme name, and the custom name that I used. This is necessary to minimize logic as I also need to set the custom theme name in the ini settings for the next release. --->
				<label for="kendoTheme">Use theme?</label><input type="checkbox" id="selectedKendoTheme" name="selectedKendoTheme" value="#kendoTheme#_#listGetAt(customThemeNames,defaultKendoThemeLoopCount)#" #themeCheckedString#>
				#kendoTheme# (#listGetAt(customThemeNames,defaultKendoThemeLoopCount)#)
			</li>
			<cfset defaultKendoThemeLoopCount = defaultKendoThemeLoopCount + 1>
		</cfloop>
		</ul>
	</fieldset>

	<fieldset>
		<legend>Customize Kendo Themes:</legend>
		<ul>
			<li><label for="modifyDefaultThemes">Modify default themes</label><input type="checkbox" name="modifyDefaultThemes" id="modifyDefaultThemes" value="true" <cfif getProfileString(application.iniFile, "themes", "modifyDefaultThemes") eq true>checked</cfif> onclick="disableThemeForms(false)"></li><br/>
			<!--- Intented for future use. 
				<li><label for="useCustomTheme">Use custom theme?</label>
				<input name="useCustomTheme" type="radio" value="true"/> Yes
				<input name="useCustomTheme" type="radio" value="false" /> No
			</li><br/>
			--->
			<!--- For now, the useCustomTheme is always set to true. --->
			<input type="hidden" name="useCustomTheme" value="true">
			<li><label for="defaultTheme">Default Kendo Base Theme</label>
				<select id="defaultTheme" name="defaultTheme" onChange="getThemeSettingsFromProperStore();">
					<option value="default" <cfif isDefined("Form.defaultTheme") and Form.defaultTheme eq 'default'>selected</cfif>>Default (Zion)</option>
					<option value="black" <cfif isDefined("Form.defaultTheme") and Form.defaultTheme eq 'black'>selected</cfif>>Black (Pillars of Creation)</option>
					<option value="blueOpal" <cfif isDefined("Form.defaultTheme") and Form.defaultTheme eq 'blueOpal'>selected</cfif>>Blue Opal (Blue Planet)</option>
					<option value="flat" <cfif isDefined("Form.defaultTheme") and Form.defaultTheme eq 'flat'>selected</cfif>>Flat (Bahama Bank)</option>
					<option value="highcontrast" <cfif isDefined("Form.defaultTheme") and Form.defaultTheme eq 'highcontrast'>selected</cfif>>High Contrast (Orion)</option>
					<option value="material" <cfif isDefined("Form.defaultTheme") and Form.defaultTheme eq 'material'>selected</cfif>>Material (Blue Wave)</option>
					<option value="materialblack" <cfif isDefined("Form.defaultTheme") and Form.defaultTheme eq 'materialblack'>selected</cfif>>Material Black (Blue Wave Dark)</option>
					<option value="metro" <cfif isDefined("Form.defaultTheme") and Form.defaultTheme eq 'metro'>selected</cfif>>Metro (Grand Teton)</option>
					<option value="moonlight" <cfif isDefined("Form.defaultTheme") and Form.defaultTheme eq 'moonlight'>selected</cfif>>Moonlight (Yellowstone)</option>
					<option value="office365" <cfif isDefined("Form.defaultTheme") and Form.defaultTheme eq 'office365'>selected</cfif>>Office 365 (Mukilteo)</option>
					<option value="silver" <cfif isDefined("Form.defaultTheme") and Form.defaultTheme eq 'silver'>selected</cfif>>Silver (Abstract Blue)</option>
					<option value="uniform" <cfif isDefined("Form.defaultTheme") and Form.defaultTheme eq 'uniform'>selected</cfif>>Uniform (Cobalt)</option>
					<option value="Fiori" <cfif isDefined("Form.defaultTheme") and Form.defaultTheme eq 'Fiori'>selected</cfif>>Fiori (Fiori)</option>
					<option value="Nova" <cfif isDefined("Form.defaultTheme") and Form.defaultTheme eq 'nova'>selected</cfif>>Nova (Sunrise)</option>
					<option value="myCustomTheme" <cfif isDefined("Form.defaultTheme") and Form.defaultTheme eq 'myCustomTheme'>selected</cfif>>Custom Theme</option>
				</select>
			</li><br/>
			<li><label for="kendoThemeCssFileLocation">Kendo Theme .css Location</label><input type="text" name="kendoThemeCssFileLocation" id="kendoThemeCssFileLocation" value="#application.kendoSourceLocation & "/styles/kendo." & kendoTheme & ".min.css"#" placeholder="myTheme" class="txtField" maxlength="255"></li><br/>	
			<li><label for="kendoThemeMobileCssFileLocation">Kendo Mobile Theme .css Location</label><input type="text" name="kendoThemeMobileCssFileLocation" id="kendoThemeMobileCssFileLocation" value="#trim(getSettingsByTheme(kendoTheme).kendoCommonCssFileLocation)#" placeholder="css location" class="txtField" maxlength="255"></li><br/>
			<li><label for="customThemeName">Custom Theme Name</label><input type="text" name="customThemeName" id="customThemeName" value="" placeholder="Theme name" class="txtField" maxlength="255"></li><br/>
			<li><label for="darkTheme">Dark Theme?</label>
				<input type="radio" id="darkTheme" name="darkTheme" value="true" /> Yes
				<input type="radio" id="darkTheme" name="darkTheme" value="false" /> No
			</li><br/>
			<li><label for="contentWidth">Blog content width:</label>
				<select id="contentWidth" name="contentWidth">
					<cfloop from="50" to="100" index="i">
					<option value="#i#">#i#%</option>
				</cfloop>
				</select> 
			</li><br/>
			<li><label for="mainContainerWidth">Main container width:</label>
				<select id="mainContainerWidth" name="mainContainerWidth" onChange="setSidebarContainerWidth(this.value)">
				<cfloop from="50" to="100" index="i">
					<option value="#i#">#i#%</option>
				</cfloop>
				</select> 
			</li><br/>
			<li><label for="sideBarContainerWidth">Pod container width:</label>
				<select id="sideBarContainerWidth" name="sideBarContainerWidth">
				<cfloop from="0" to="50" index="i">
					<option value="#i#">#i#%</option>
				</cfloop>
				</select>
			</li><br/>
			<li><label for="breakpoint">Breakpoint:</label>
				<input type="text" name="breakpoint" id="breakpoint" value="" class="txtField" maxlength="255">px</li><br/>
			<li><label for="siteOpacity">Opacity:</label>
				<select id="siteOpacity" name="siteOpacity">
					<cfloop from="80" to="100" index="i">
					<option value="#i#">#i#%</option>
				</cfloop>
				</select> 
			</li><br/>
			<li><label for="blogBackgroundImage">Background image:</label>
				<input type="text" name="blogBackgroundImage" id="blogBackgroundImage" value="" class="txtField" maxlength="255"></li><br/>
			<li><label for="blogBackgroundImageRepeat">Background image repeat CSS:</label>
				<select id="blogBackgroundImageRepeat" name="blogBackgroundImageRepeat">
					<option value="repeat">repeat</option>
					<option value="repeat-x">repeat-x</option>
					<option value="repeat-y">repeat-y</option>
					<option value="no-repeat">no-repeat</option>
					<option value="space">space</option>
					<option value="round">round</option>	
					<option value="initial">initial</option>
					<option value="inherit">inherit</option>
				</select> 
			</li><br/>	
			<li><label for="blogBackgroundImagePosition">Background image position CSS:</label>
				<input type="text" name="blogBackgroundImagePosition" id="blogBackgroundImagePosition" value="" class="txtField" maxlength="255">
			</li><br/>
			<li><label for="stretchHeaderAcrossPage">Stretch header across page?</label>
				<input type="radio" id="stretchHeaderAcrossPage" name="stretchHeaderAcrossPage" value="true" /> Yes
				<input type="radio" id="stretchHeaderAcrossPage" name="stretchHeaderAcrossPage" value="false" checked/> No
			</li><br/>
			<!--- The following is only relevant when the stretchHeaderAcrossPage is set to true.--->
			<li><label for="alignBlogMenuWithBlogContent">Align header with content?</label>
				<input type="radio" id="alignBlogMenuWithBlogContent" name="alignBlogMenuWithBlogContent" value="true" checked /> Yes
				<input type="radio" id="alignBlogMenuWithBlogContent" name="alignBlogMenuWithBlogContent" value="false" /> No
			</li><br/>
			<li><label for="topMenuAlign">Menu align:</label>
				<input type="radio" id="topMenuAlign" name="topMenuAlign" value="left" checked /> Left
				<input type="radio" id="topMenuAlign" name="topMenuAlign" value="center" /> Center
				<input type="radio" id="topMenuAlign" name="topMenuAlign" value="right" /> Right
			</li><br/>
			
			<li><label for="headerBackgroundImage">Header background image:</label>
				<input type="text" name="headerBackgroundImage" id="headerBackgroundImage" value="" class="txtField" maxlength="255"></li><br/>
			<li><label for="menuBackgroundImage">Menu background image:</label><input type="text" name="menuBackgroundImage" id="menuBackgroundImage" value="" class="txtField" maxlength="255"></li><br/>
			<li><label for="coverKendoMenuWithMenuBackgroundImage">Cover menu with menu background image:</label>
				<input type="radio" id="coverKendoMenuWithMenuBackgroundImage" name="coverKendoMenuWithMenuBackgroundImage" value="true" /> Yes
				<input type="radio" id="coverKendoMenuWithMenuBackgroundImage" name="coverKendoMenuWithMenuBackgroundImage" value="false" /> No
			</li><br/><br/>
			<li><label for="logoImageMobile">Mobile logo image:</label><input type="text" name="logoImageMobile" id="logoImageMobile" value="" class="txtField" maxlength="255"></li><br/>
			<li><label for="logoMobileWidth">Mobile logo image width:</label><input type="text" name="logoMobileWidth" id="logoMobileWidth" value="" class="txtField" maxlength="255"></li><br/>
			<li><label for="logoImage">Desktop logo image:</label><input type="text" name="logoImage" id="logoImage" value="" class="txtField" maxlength="255"></li><br/>
			<li><label for="logoPaddingTop">Logo top padding</label>
				<select id="logoPaddingTop" name="logoPaddingTop">
				<cfloop from="0" to="15" index="i">
					<option value="#i#">#i#px</option>
				</cfloop>
				</select>
			</li><br/>
			<li><label for="logoPaddingRight">Logo right padding:</label>
				<select id="logoPaddingRight" name="logoPaddingRight">
				<cfloop from="0" to="75" index="i">
					<option value="#i#">#i#px</option>
				</cfloop>
				</select>
			</li><br/>
			<li><label for="logoPaddingLeft">Logo left padding:</label>
				<select id="logoPaddingLeft" name="logoPaddingLeft">
				<cfloop from="0" to="75" index="i">
					<option value="#i#">#i#px</option>
				</cfloop>
				</select>
			</li><br/>
			<li><label for="logoPaddingBottom">Logo bottom padding:</label>
				<select id="logoPaddingBottom" name="logoPaddingBottom">
				<cfloop from="0" to="15" index="i">
					<option value="#i#">#i#px</option>
				</cfloop>
				</select>
			</li><br/>
			<li><label for="blogNameTextColor">Blog name text color:</label><input type="text" name="blogNameTextColor" id="blogNameTextColor" class="txtField" maxlength="255"></li><br/>
			<li><label for="headerBodyDividerImage">Header divider image:</label><input type="text" name="headerBodyDividerImage" id="headerBodyDividerImage" value="" class="txtField" maxlength="255"></li><br/>
		</ul>
	</fieldset>
	
	<fieldset>
		<legend>Custom Logic Templates (set by theme)</legend>
		<ul>
			<li><label for="customCoreLogicTemplate">Custom Core Logic Template:</label><input type="text" name="customCoreLogicTemplate" id="customCoreLogicTemplate" value="" class="txtField" maxlength="255"></li><br/>
			<li><label for="customHeadTemplate">Custom Header Template:</label><input type="text" name="customHeadTemplate" id="customHeadTemplate" value="" class="txtField" maxlength="255"></li><br/>
			<li><label for="customBodyString">Custom Body String:</label><input type="text" name="customBodyString" id="customBodyString" value="" class="txtField" maxlength="255"></li><br/>
			<li><label for="customFontCssTemplate">Custom Font Template:</label><input type="text" name="customFontCssTemplate" id="customFontCssTemplate" value="" class="txtField" maxlength="255"></li><br/>
			<li><label for="customGlobalAndBodyCssTemplate">Custom Css Template (affects entire body):</label><input type="text" name="customGlobalAndBodyCssTemplate" id="customGlobalAndBodyCssTemplate" value="" class="txtField" maxlength="255"></li><br/>
			<li><label for="customTopMenuCssTemplate">Custom Menu Css Template:</label><input type="text" name="customTopMenuCssTemplate" id="customTopMenuCssTemplate" value="" class="txtField" maxlength="255"></li><br/>
			<li><label for="customTopMenuJsTemplate">Custom Menu Javascript Template:</label><input type="text" name="customTopMenuJsTemplate" id="customTopMenuJsTemplate" value="" class="txtField" maxlength="255"></li><br/>
			<li><label for="customBlogContentCssTemplate">Custom Blog Content Css Template:</label><input type="text" name="customBlogContentCssTemplate" id="customBlogContentCssTemplate" value="" class="txtField" maxlength="255"></li><br/>
			<li><label for="customBlogJsContentTemplate">Custom Blog Content Javascript Template:</label><input type="text" name="customBlogJsContentTemplate" id="customBlogJsContentTemplate" value="" class="txtField" maxlength="255"></li><br/>
			<li><label for="customBlogContentHtmlTemplate">Custom Blog Content HTML Template:</label><input type="text" name="customBlogContentHtmlTemplate" id="customBlogContentHtmlTemplate" value="" class="txtField" maxlength="255"></li><br/>
			<li><label for="customFooterHtmlTemplate">Custom Footer HTML Template:</label><input type="text" name="customFooterHtmlTemplate" id="customFooterHtmlTemplate" value="" class="txtField" maxlength="255"></li><br/>
		</ul>
	</fieldset>
	
	<input type="button" value="Reset theme" onClick="getDefaultThemeSettings($('#chr(35)#defaultTheme').val());">
	
	<fieldset>
		<legend>Add This Social Integration</legend>
		<ul>
			<li><label for="addThisApiKey">Add This API Key:</label><input type="text" name="addThisApiKey" id="addThisApiKey" value="#application.blog.getProperty("addThisApiKey")#" class="txtField" maxlength="255"></li>
		</ul>
	</fieldset>
	
	<fieldset>
		<legend>Content Settings</legend>
		<ul>		
			<li><label for="commentsfrom">Comments sent from:</label><input type="text" name="commentsfrom" value="#form.commentsfrom#" class="txtField" maxlength="255"></li>
			<li><label for="maxentries">Max entries:</label><input type="text" name="maxentries" value="#form.maxentries#" class="txtField" maxlength="255"></li>
			<li><label for="offset">Timezone offset:</label><input type="text" name="offset" value="#form.offset#" class="txtField" maxlength="25"></li>
			<li><label for="pingurls">Ping urls:</label><textarea name="pingurls" class="txtAreaShort">#toLines(form.pingurls)#</textarea></li>
			<li><label for="locale">Locale:</label><input type="text" name="locale" value="#form.locale#" class="txtField" maxlength="50"></li>
		</ul>
	</fieldset>
	<fieldset>
		<legend>Content Controls / Security</legend>
		<ul>
			<li><label for="ipblocklist">ip block list:</label><textarea name="ipblocklist" class="txtAreaShort">#toLines(form.ipblocklist)#</textarea></li>
			<li><label for="moderate">moderate comments:</label>
				<input type="radio" name="moderate" value="true" <cfif form.moderate>checked</cfif>/> Yes
				<input type="radio" name="moderate" value="false" <cfif not form.moderate>checked</cfif>/> No
			</li>
			<li><label for="">use captcha:</label>
				<input type="radio" name="usecaptcha" value="true" <cfif form.usecaptcha>checked</cfif>/> Yes
				<input type="radio" name="usecaptcha" value="false" <cfif not form.usecaptcha>checked</cfif>/> No
			</li>
			<li><label for="trackbackspamlist">spamlist:</label><textarea name="trackbackspamlist" class="txtAreaShort">#toLines(form.trackbackspamlist)#</textarea></li>
			<li><label for="allowgravatars">allow gravatars:</label>

				<input type="radio" name="allowgravatars" value="true" <cfif form.allowgravatars>checked</cfif>/> Yes
				<input type="radio" name="allowgravatars" value="false" <cfif not form.allowgravatars>checked</cfif>/> No
			</li>
			<li><label for="filebrowse">show file manager:</label>
				<input type="radio" name="filebrowse" value="true" <cfif form.filebrowse>checked</cfif>/> Yes
				<input type="radio" name="filebrowse" value="false" <cfif not form.filebrowse>checked</cfif>/> No
			</li>
			<li><label for="imageroot">image root for dynamic images:</label><input type="text" name="imageroot" value="#form.imageroot#" class="txtField" maxlength="50"></li>
		</ul>
	</fieldset>
	<fieldset id="datasource_edit" style='display:none'>
		<legend>Data Source (Edit mode)</legend>
		<ul>
			<li><label for="dsn">dsn:</label><input type="text" name="dsn" value="#form.dsn#" class="txtField" maxlength="50"></li>
			<li><label for="blogdbtype">blog database type:</label>
				<select name="blogdbtype">
				<cfloop index="dbtype" list="#validDBTypes#">
				<option value="#dbtype#" <cfif form.blogdbtype is dbtype>selected</cfif>>#dbtype#</option>
				</cfloop>
				</select>
			</li>
			<li><label for="dsn_username">dsn username:</label><input type="text" name="dsn_username" value="#form.dsn_username#" class="txtField" maxlength="255"></li>
			<li><label for="dsn_password">dsn password:</label><input type="text" name="dsn_password" value="#form.dsn_password#" class="txtField" maxlength="255"></li>
		</ul>
	</fieldset>
	<fieldset id="datasource_ro">
		<legend>Data Source</legend>
		<ul>
			<li><label>dsn:</label>#htmleditformat(form.dsn)#&nbsp;</li>
			<li><label>blog database type:</label>#htmleditformat(form.blogdbtype)#&nbsp;</li>
			<li><label>dsn username:</label>#htmleditformat(form.dsn_username)#&nbsp;</li>
			<li><label>dsn password:</label>#htmleditformat(form.dsn_password)#&nbsp;</li>
		</ul>
		<div class="buttonbar" id="datasource_editbutton">
			<a href="javascript:editDatasource();" class="button">Edit Data Source</a>
		</div>
	</fieldset>
	
	<fieldset>
		<legend>Mail Settings</legend>
		<ul>
			<li><label for="mailserver">mail server:</label><input type="text" name="mailserver" value="#form.mailserver#" class="txtField" maxlength="50"></li>
			<li><label for="mailusername">mail username:</label><input type="text" name="mailusername" value="#form.mailusername#" class="txtField" maxlength="50"></li>
			<li><label for="mailpassword">mail password:</label><input type="text" name="mailpassword" value="#form.mailpassword#" class="txtField" maxlength="50"></li>
		</ul>
	</fieldset>
	<fieldset>
		<legend>Podcasting</legend>
		<ul>
			<li><label for="itunessubtitle">itunes Subtitle:</label><input type="text" name="itunessubtitle" value="#form.itunessubtitle#" class="txtField" maxlength="50"></li>
			<li><label for="itunessummary">itunes Summary:</label><input type="text" name="itunessummary" value="#form.itunessummary#" class="txtField" maxlength="50"></li>
			<li><label for="ituneskeywords">itunes Keywords:</label><input type="text" name="ituneskeywords" value="#form.ituneskeywords#" class="txtField" maxlength="50"></li>
			<li><label for="itunesauthor">itunes Author:</label><input type="text" name="itunesauthor" value="#form.itunesauthor#" class="txtField" maxlength="50"></li>
			<li><label for="itunesimage">itunes Image:</label><input type="text" name="itunesimage" value="#form.itunesimage#" class="txtField" maxlength="50"></li>
			<li><label for="itunesexplicit">itunes Explicit:</label>
				<input type="radio" name="itunesexplicit" value="true" <cfif isDefined("form.itunesexplicit") and isBoolean(form.itunesexplicit) and form.itunesexplicit>checked</cfif>/> Yes
				<input type="radio" name="itunesexplicit" value="false" <cfif isDefined("form.itunesexplicit") and isBoolean(form.itunesexplicit) and not form.itunesexplicit>checked</cfif>/> No
			</li>
		</ul>
	</fieldset>
	<fieldset>
		<legend>Security encryption phrase</legend>
		<ul>		
			<li><label for="encryptionPhrase">Ecryption phrase:</label><input type="text" name="encryptionPhrase" value="#form.encryptionPhrase#" class="txtField" maxlength="255"></li>
		</ul>
	</fieldset>
	<fieldset>
		<div class="buttonbar">
			<a href="settings.cfm" class="button">Cancel Changes</a> <a href="javascript:document.settingsForm.submit();" class="button">Save Settings</a>
		</div>
		<input type="hidden" name="save" value="1">
	</fieldset>
	</form>
	</cfoutput>

</cfmodule>

<cfsetting enablecfoutputonly=false>