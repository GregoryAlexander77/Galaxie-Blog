<!--- Which windows can be shown (2026-10-14):
	- a logged-in user: any window; Blog Options (38) and Blog Settings (39) need the EditServerSetting capability;
	- otherwise: the login window (0), and the new-user profile (11) when opened from the invite link (login.cfm passes the
	  invite key as otherArgs1). --->
<cfparam name="URL.adminInterfaceId" default="">
<cfset adminWindowAllowed = application.Udf.isLoggedIn()>
<cfif not adminWindowAllowed and URL.adminInterfaceId eq "0">
	<cfset adminWindowAllowed = true>
</cfif>
<cfif not adminWindowAllowed and URL.adminInterfaceId eq "11" and structKeyExists(URL, "optArgs") and structKeyExists(URL, "otherArgs1") and len(trim(URL.otherArgs1)) gte 20>
	<cfset invitedUserMatch = ormExecuteQuery("SELECT u.UserId FROM Users u WHERE u.UserName = :userName AND u.Password = :inviteKey AND u.Active = :active", { userName = trim(URL.optArgs), inviteKey = trim(URL.otherArgs1), active = true })>
	<cfset adminWindowAllowed = arrayLen(invitedUserMatch) gt 0>
</cfif>
<cfif adminWindowAllowed and listFind("38,39", URL.adminInterfaceId) and not (structKeyExists(session, "capabilityList") and listFindNoCase(session.capabilityList, "EditServerSetting"))>
	<cfset adminWindowAllowed = false>
</cfif>
<cfif not adminWindowAllowed>
	<cfheader statuscode="403">
	<cfcontent reset="true"><cfabort>
</cfif>
<html> 
<cfsilent>
<!--- Debug flag. This will print the interfaceId along with the args send via the URL --->
<cfset debug = false>

<!--- Generate the session Cross-Site Request Forgery (CSRF) token. This will be validated on the server prior to the login logic for security. --->
<!--- The forceNew argument does not work for versions less than 2018, however, CF2021 needs this argument or the token will change every time causing errors. Note: while the forceNew argument was not introduced until 2018, having csrfGenerateToken on the page with a forceNew argument will cause an error with 2016, even if you put it in a catch block or have two logical branches depending upon the version. --->
<cfset csrfToken = csrfGenerateToken("admin", false)><!---forceNew=false--->
<!--- Drop a cookie with the token. On occassion with Chrome, the validation on the server during and Ajax request does not work and we need to compare the validated token with the cookie as a backup approach to secure our ajax transactions  --->
<cfset cookie.csrfToken = { value="#csrfToken#", path="#application.baseUrl#", expires=30 }>

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
<cfif session.isMobile or session.isTablet>
	<cfset smallScreen = true>
<cfelse>
	<cfset smallScreen = false>
</cfif>

<!--- Clear CF Caching 
Note: the following flush line is broke with CF2023
<cfcache action="flush"></cfcache>
--->
	
<!--- Note:  --->
<!--- Include tinymce. --->
<!--- TinyMce notes: the tinymce scripts may be also placed in the head tag on the /admin/index.cfm page. 
If I place the tinymce scripts here, the setContent method does not work and the editors are not kept in memory. Nor can I get the content of the editor. This is also the case if the scripts are included here and on the index.cfm page. If I don't  place them here and keep the script in the head of the index page, the editors are preserved in memory, I can get the content and use the setContent method as well- but the editors disappear after the first use. --->
</cfsilent>
<cfif debug>
	<cfinvoke component="#application.proxyControllerComponentPath#" method="verifyCsrfToken" returnvariable="validCsrf">
		<cfinvokeargument name="csrfToken" value="#csrfToken#">	
	</cfinvoke>
	Debugging:<br/>
	<!---<cfdump var="#session#">--->
	<!---<cfdump var="#cgi#">--->
	<cfoutput>
	adminInterfaceId: #URL.adminInterfaceId# <br>
	URL.optArgs: #URL.optArgs#<br>
	<cfif isDefined("URL.otherArgs")> URL.otherArgs:  #URL.otherArgs#</cfif>
	<cfif isDefined("URL.otherArgs1")> URL.otherArgs1: #URL.otherArgs1#</cfif><br/>
	
	csrfToken: #csrfToken#<br/>
	cookie.csrfToken: #cookie.csrfToken#<br/>
	CSRFVerifyToken('admin', csrfToken): #CSRFVerifyToken(csrfToken, 'admin')#<br/>
	validCsrf: #validCsrf#<br/>
	screenHeight: #screenHeight#<br/>
	screenWidth: #screenWidth#<br/>
	smallScreen: #smallScreen#<br/>
	</cfoutput>
</cfif>
	
<!--- 
TinyMce styles 
!!! This style is critical for tiny mce dialogs to work properly!!! 
--->
<style>
	<!--- Set the z-index of the dialogs so that they appear above any other dialog windows. This is absolutely necessary when the UI is already in a dialog, such as a Kendo window. --->
	.tox {
		z-index: 16000 !important;
	}
	
	.tox-tinymce-inline {
		z-index: 30050 !important;
	}
	
	.tox-silver-sink .tox-tinymce-aux {
		z-index: 30060 !important;
	}
	
	.tox-pop .tox-pop--top .tox-pop__dialog .tox-tinymce-aux .tox-toolbar {
		z-index: 30070 !important;
	}
	
	.modal {
		z-index: 30040;
	}
	.modal-backdrop {
		z-index: 30030;
	}

	label {
		font-weight: normal;
	}

	.normalFontWeight {
		font-weight: 300;
	}
</style>

<!--- Common scripts --->
<script>
	<!--- Post editor scripts This function reloads the media preview when new media has been uploaded --->
	function reloadEnclosureThumbnailPreview(postId){
		<!--- alert('reloading thumbnail') --->
		$("#mediaPreview").html("<p>Retrieving media....</p>").load("loadPreview.cfm?previewId=1&optArgs=" + postId);
	}

	<!--- Same pattern as reloadEnclosureThumbnailPreview() above, for a Page Collection's hero image - see
	loadPreview.cfm's previewId=2 and pageCollectionDetail.cfm's #pcHeroPreview-<id> div. --->
	function reloadPageCollectionHeroPreview(pageCollectionId){
		$("#pcHeroPreview-" + pageCollectionId).html("<p>Retrieving media....</p>").load("loadPreview.cfm?previewId=2&optArgs=" + pageCollectionId);
	}
</script>

<!--- This window handles many interfaces. Pass in the interfaceId. Other arguments may include the URL.optArgs, URL.otherArgs, and URL.otherArgs1. See the createAdminInterface javascript function in the /includes/templates/blogJsContent.cfm template for more information. --->

<cfswitch expression="#URL.adminInterfaceId#">
	
<!---//***********************************************************************************************
						Login
//************************************************************************************************--->
	
<cfcase value="0">
	<cfinclude template="../../admin/adminInterface/ajaxLogin.cfm">
</cfcase>
	
<!---//***********************************************************************************************
						Comments Grid
//************************************************************************************************--->
	
<cfcase value=1>
	<cfif application.kendoCommercial>
		<!---//***********************************************************************************************
						kendo grid Comments
		//************************************************************************************************--->
		<cfinclude template="../grids/kendo/comments.cfm">

	<cfelse><!---<cfif application.kendoCommercial>--->
		<!---//***********************************************************************************************
						jsGrid Comments
		//************************************************************************************************--->
		<cfinclude template="../grids/jsGrid/comments.cfm">

	</cfif><!---<cfif application.kendoCommercial>--->
</cfcase>
			
<!---//*******************************************************************************************************************
				Comment Detail Page
//********************************************************************************************************************--->
			
<cfcase value=2>
	<cfinclude template="../../admin/adminInterface/commentDetail.cfm">	  
</cfcase>
			
<!--- //************************************************************************************************
		Photo Gallery and Carousel
//**************************************************************************************************--->
			
<cfcase value=3>
	<cfinclude template="../../admin/adminInterface/uppyGalleryAndCarousel.cfm">	
</cfcase>
	
<!--- //************************************************************************************************
		Gallery Items
//**************************************************************************************************--->
		
<cfcase value=4>
	<cfinclude template="../../admin/adminInterface/galleryItems.cfm">  		
</cfcase>
		
<!---//*******************************************************************************************************************
				Post Grid
//********************************************************************************************************************--->
<cfcase value=5>
	<!--- Blog Posts / Pages / Page Collections switcher (contentGridSwitcher.cfm). --->
	<cfset currentGridWindowId = 5><cfinclude template="contentGridSwitcher.cfm">
	
	<cfif application.kendoCommercial>
		<!---//***********************************************************************************************
						kendo grid Comments
		//************************************************************************************************--->
		<cfinclude template="../grids/kendo/posts.cfm">

	<cfelse><!---<cfif application.kendoCommercial>--->
		<!---//***********************************************************************************************
						jsGrid Comments
		//************************************************************************************************--->
		<cfinclude template="../grids/jsGrid/posts.cfm">

	</cfif><!---<cfif application.kendoCommercial>--->
</cfcase>
			
<!---//*******************************************************************************************************************
				Post Detail Page
//********************************************************************************************************************--->
<cfcase value=6>
	<cfinclude template="../../admin/adminInterface/postDetail.cfm">  
</cfcase>

<!--- //************************************************************************************************
		User Detail (this is used for new and current users)
//**************************************************************************************************--->
	
<cfcase value=7>
	<cfinclude template="../../admin/adminInterface/userDetail.cfm">  
</cfcase>
				
<!--- //************************************************************************************************
		New Role
//**************************************************************************************************--->
				
<cfcase value=8>
	<cfinclude template="../../admin/adminInterface/newRole.cfm">
</cfcase>
				
<!--- //************************************************************************************************
		Confirm Password
//**************************************************************************************************--->
				
<cfcase value=9>
	<cfinclude template="../../admin/adminInterface/confirmPassword.cfm">  
</cfcase>
		 
<!--- //************************************************************************************************
		Login history
//**************************************************************************************************--->
				
<cfcase value=10>
	
	<cfif application.kendoCommercial>
		<!---//***********************************************************************************************
						kendo grid 
		//************************************************************************************************--->
		<cfinclude template="../grids/kendo/userHistory.cfm">

	<cfelse><!---<cfif application.kendoCommercial>--->
		<!---//***********************************************************************************************
						jsGrid 
		//************************************************************************************************--->
		<cfinclude template="../grids/jsGrid/userHistory.cfm">

	</cfif><!---<cfif application.kendoCommercial>--->
		  
</cfcase>
			
<!--- //************************************************************************************************
		User Profile for new users that were invited
//**************************************************************************************************--->
	
<cfcase value=11>
	<cfinclude template="../../admin/adminInterface/invitedUsers.cfm"> 		  
</cfcase>
			  
<!--- //************************************************************************************************
		Add Category 
//**************************************************************************************************--->
	
<cfcase value=12>
	<cfinclude template="../../admin/adminInterface/addCategory.cfm">			
</cfcase>

<!--- //************************************************************************************************
		Enclosure image tiny mce editor
//**************************************************************************************************--->
				
<cfcase value=13>
	<cfinclude template="../../admin/adminInterface/enclosureImageEditor.cfm">			
</cfcase>
		  
<!--- //************************************************************************************************
		Video Upload
//**************************************************************************************************--->
		  
<cfcase value=14>
	<cfinclude template="../../admin/adminInterface/uppyVideoUpload.cfm">
</cfcase>
			
<!--- //************************************************************************************************
		LD JSON
//**************************************************************************************************--->
				
<cfcase value=15>
	<cfinclude template="../../admin/adminInterface/ldJson.cfm">			
</cfcase>
				
<!--- //************************************************************************************************
		Video WebVtt File tiny mce editor
//**************************************************************************************************--->
				
<cfcase value=16>
	<cfinclude template="../../admin/adminInterface/webVttEditor.cfm">	
</cfcase>
				
<!--- //************************************************************************************************
		Video WebVTT file uploader
//**************************************************************************************************--->
				
<cfcase value=17>
	<cfinclude template="../../admin/adminInterface/webVttFileUploader.cfm">			
</cfcase>
			
<!--- //************************************************************************************************
		Video Image Cover tiny mce editor
//**************************************************************************************************--->
				
<cfcase value=18>
	<cfinclude template="../../admin/adminInterface/videoImageEditor.cfm">	
</cfcase>
	
<!--- //************************************************************************************************
		Maps
//**************************************************************************************************--->
				
<cfcase value=19>
	<cfinclude template="../../admin/adminInterface/azureMap.cfm">
	<!--- Azure Maps replaced Bing Maps in June of 2025
	<cfinclude template="../../admin/adminInterface/bingMap.cfm">
	--->	
</cfcase>
		
<!--- //************************************************************************************************
		Map Routing
//**************************************************************************************************--->
		
<cfcase value=20>
	<cfinclude template="../../admin/adminInterface/azureMapRoute.cfm">
	<!--- Azure Maps replaced Bing Maps in June of 2025
	<cfinclude template="../../admin/adminInterface/bingMapRoute.cfm">
	--->
</cfcase>
		
<!--- //************************************************************************************************
		Map Cursor Image Uploader 
//**************************************************************************************************--->
		
<cfcase value=21>
	<cfinclude template="../../admin/adminInterface/mapCursorEditor.cfm"> 
</cfcase>
		
<!--- //************************************************************************************************
		Interface Displaying the Compressed JSON-LD String (for testing using external sites)
//**************************************************************************************************--->
		
<cfcase value=22>
	<cfinclude template="../../admin/adminInterface/jsonLdString.cfm">		
</cfcase>
		
<!--- //************************************************************************************************
		Post Alias 
//**************************************************************************************************--->
	
<cfcase value=23>
	<cfinclude template="../../admin/adminInterface/postAlias.cfm">		
</cfcase>
		  
<!---//*******************************************************************************************************************
				Create New Post
//********************************************************************************************************************--->
<cfcase value=24>
	<cfinclude template="../../admin/adminInterface/newPost.cfm">		  
</cfcase>
			  
<!---//*******************************************************************************************************************
				Categories Grid
//********************************************************************************************************************--->
			  
<cfcase value=25>
			  
	<cfif application.kendoCommercial>
		<!---//***********************************************************************************************
						kendo grid 
		//************************************************************************************************--->
		<cfinclude template="../grids/kendo/categories.cfm">

	<cfelse><!---<cfif application.kendoCommercial>--->
		<!---//***********************************************************************************************
						jsGrid 
		//************************************************************************************************--->
		<cfinclude template="../grids/jsGrid/categories.cfm">

	</cfif><!---<cfif application.kendoCommercial>--->
		
</cfcase>
			
<!---//*******************************************************************************************************************
				Subscriber Grid
//********************************************************************************************************************--->
<cfcase value=26>
			  
	<cfif application.kendoCommercial>
		<!---//***********************************************************************************************
						kendo grid 
		//************************************************************************************************--->
		<cfinclude template="../grids/kendo/subscribers.cfm">

	<cfelse><!---<cfif application.kendoCommercial>--->
		<!---//***********************************************************************************************
						jsGrid 
		//************************************************************************************************--->
		<cfinclude template="../grids/jsGrid/subscribers.cfm">

	</cfif><!---<cfif application.kendoCommercial>--->
		
</cfcase>
			
<!--- //************************************************************************************************
		Add Subscriber 
//**************************************************************************************************--->
	
<cfcase value=27>
	<cfinclude template="../../admin/adminInterface/addSubscriber.cfm">				
</cfcase>
		  
<!---//*******************************************************************************************************************
				User Grid
//********************************************************************************************************************--->
		  
<cfcase value=28>
			  
	<cfif application.kendoCommercial>
		<!---//***********************************************************************************************
						kendo grid 
		//************************************************************************************************--->
		<cfinclude template="../grids/kendo/users.cfm">

	<cfelse><!---<cfif application.kendoCommercial>--->
		<!---//***********************************************************************************************
						jsGrid 
		//************************************************************************************************--->
		<cfinclude template="../grids/jsGrid/users.cfm">

	</cfif><!---<cfif application.kendoCommercial>--->
		
</cfcase>
	
<!---//*******************************************************************************************************************
				Themes Grid
//********************************************************************************************************************--->
			
<cfcase value=29>
	
	<!--- The themes grid is used for multiple purposes differentiated by the themeType --->
	<cfset themeGridType = "themeProperty">
			  
	<cfif application.kendoCommercial>
		<!---//***********************************************************************************************
						kendo grid 
		//************************************************************************************************--->
		<cfinclude template="../grids/kendo/themes.cfm">

	<cfelse><!---<cfif application.kendoCommercial>--->
		<!---//***********************************************************************************************
						jsGrid 
		//************************************************************************************************--->
		<cfinclude template="../grids/jsGrid/themes.cfm">

	</cfif><!---<cfif application.kendoCommercial>--->
		
</cfcase>
			
<!--- //************************************************************************************************
		Theme Settings
//**************************************************************************************************--->
	
<cfcase value=30>
	<cfinclude template="../../admin/adminInterface/themeSettings.cfm">				
</cfcase>
				
<!--- //************************************************************************************************
		Font Uploader
//**************************************************************************************************--->
			
<cfcase value=31>
	<cfinclude template="../../admin/adminInterface/fontUploader.cfm">	
</cfcase>
	
<!--- //************************************************************************************************
		Font Items
//**************************************************************************************************--->
		

<cfcase value=32>
	<cfinclude template="../../admin/adminInterface/fontUploadDetail.cfm">
</cfcase>
		
<!--- //************************************************************************************************
		Fonts Grid
//**************************************************************************************************--->
		
<cfcase value=33>
		
	<cfif application.kendoCommercial>
		<!---//***********************************************************************************************
						kendo grid Comments
		//************************************************************************************************--->
		<cfinclude template="../grids/kendo/fonts.cfm">

	<cfelse><!---<cfif application.kendoCommercial>--->
		<!---//***********************************************************************************************
						jsGrid Comments
		//************************************************************************************************--->
		<cfinclude template="../grids/jsGrid/fonts.cfm">

	</cfif><!---<cfif application.kendoCommercial>--->
		
</cfcase>
			
<!--- //************************************************************************************************
		Font Details (note: use https://google-webfonts-helper.herokuapp.com/fonts/oswald?subsets=latin to download new fonts)
//**************************************************************************************************--->
		
<cfcase value=34>
	<cfinclude template="../../admin/adminInterface/fontDetail.cfm">	
</cfcase>
		
<!--- //************************************************************************************************
		Generic tiny mce image editor used for themes and settings. This is used to upload all of the theme related images.
//**************************************************************************************************--->
				
<cfcase value=35>
	<cfinclude template="../../admin/adminInterface/imageUploader.cfm">			
</cfcase>
		  
<!--- //************************************************************************************************
		FavIcon Uploader
//**************************************************************************************************--->
			
<cfcase value=36>
	<cfinclude template="../../admin/adminInterface/favIconUploader.cfm">	
</cfcase>
		
<!--- //************************************************************************************************
		New Theme
//**************************************************************************************************--->
			
<cfcase value=37>
	<cfinclude template="../../admin/adminInterface/newTheme.cfm">
</cfcase>
				
<!--- //************************************************************************************************
		Blog Options
//**************************************************************************************************--->
			
<cfcase value=38>
	<cfinclude template="../../admin/adminInterface/blogOptions.cfm">	   
</cfcase>
			  
<!--- //************************************************************************************************
		Blog Settings
//**************************************************************************************************--->
			
<cfcase value=39>
	<cfinclude template="../../admin/adminInterface/blogSettings.cfm">   
</cfcase>
			
<!--- //************************************************************************************************
		Blog Updates
//**************************************************************************************************--->
			
<cfcase value=40>
	<cfinclude template="../../admin/adminInterface/blogUpdate.cfm">  
</cfcase>
			  
<!--- //************************************************************************************************
		Blog CFC Import
//**************************************************************************************************--->
			
<cfcase value=41>
	<cfinclude template="../../admin/adminInterface/blogCfcImport.cfm">  
</cfcase>
			  
<!--- //************************************************************************************************
		Post Header
//**************************************************************************************************--->
			
<cfcase value=42>
	<cfinclude template="../../admin/adminInterface/postHeader.cfm">  
</cfcase>
		  
<!---//*************************************************************************************************
				Sort Order Date
//**************************************************************************************************--->
		  
<cfcase value=43>
	<cfinclude template="../../admin/adminInterface/blogSortDate.cfm"> 	
</cfcase>
		  
<!---//*************************************************************************************************
				Set Post Theme
//**************************************************************************************************--->
		  
<cfcase value=44>
	<cfinclude template="../../admin/adminInterface/postTheme.cfm"> 	
</cfcase>
		
<!---//*************************************************************************************************
				Custom Window
//**************************************************************************************************--->
		  
<cfcase value=45>
	<cfinclude template="../../admin/adminInterface/customWindow.cfm"> 
</cfcase>
	
<!--- //************************************************************************************************
		Post CSS
//**************************************************************************************************--->

			
<cfcase value=46>
	<cfinclude template="../../admin/adminInterface/postCss.cfm"> 
</cfcase>
		  
<!--- //************************************************************************************************
		Post JavaScript
//**************************************************************************************************--->
			
<cfcase value=47>
	<cfinclude template="../../admin/adminInterface/postJavaScript.cfm"> 
</cfcase>
		  
<cfcase value="48">
		  
		<cfif application.kendoCommercial>
		<!---//*****************************************************************************************
						jsGrid visitor log
		//******************************************************************************************--->
		<cfinclude template="../grids/kendo/visitorLog.cfm">

	<cfelse><!---<cfif application.kendoCommercial>--->
		<!---//*****************************************************************************************
						jsGrid visitor log
		//******************************************************************************************--->
		<cfinclude template="../grids/jsGrid/visitorLog.cfm">

	</cfif><!---<cfif application.kendoCommercial>--->  
		  
</cfcase>
			
<!--- //************************************************************************************************
		Add Tag 
//**************************************************************************************************--->
	
<cfcase value=49>
	<cfinclude template="../../admin/adminInterface/addTag.cfm"> 		
</cfcase>
		
<!---//*******************************************************************************************************************
				Tags Grid
//********************************************************************************************************************--->
			  
<cfcase value=50>
			  
	<cfif application.kendoCommercial>
		<!---//***********************************************************************************************
						kendo grid 
		//************************************************************************************************--->
		<cfinclude template="../grids/kendo/tags.cfm">

	<cfelse><!---<cfif application.kendoCommercial>--->
		<!---//***********************************************************************************************
						jsGrid 
		//************************************************************************************************--->
		<cfinclude template="../grids/jsGrid/tags.cfm">

	</cfif><!---<cfif application.kendoCommercial>--->
		
</cfcase>
			
<!--- //************************************************************************************************
		Carousel Items
//**************************************************************************************************--->
			
<cfcase value=51>
	<cfinclude template="../../admin/adminInterface/carouselItems.cfm"> 		
</cfcase>
			
<!--- //************************************************************************************************
		Code Mirror
//**************************************************************************************************--->
	
<cfcase value=52>
	<cfinclude template="../../admin/adminInterface/codeMirrorTemplateEditor.cfm"> 
</cfcase>
		
<!--- //************************************************************************************************
		Content Template Editor
//**************************************************************************************************--->
				
<cfcase value=53>
	<cfinclude template="../../admin/adminInterface/contentTemplateEditor.cfm"> 			
</cfcase>
		  
<!---//*******************************************************************************************************************
				Content Themes Grid
//********************************************************************************************************************--->
			
<cfcase value=54>
	
	<!--- The themes grid is used for multiple purposes differentiated by the themeType --->
	<cfset themeGridType = "contentTemplate">
			  
	<cfif application.kendoCommercial>
		<!---//***********************************************************************************************
						kendo grid 
		//************************************************************************************************--->
		<cfinclude template="../grids/kendo/themes.cfm">

	<cfelse><!---<cfif application.kendoCommercial>--->
		<!---//***********************************************************************************************
						jsGrid 
		//************************************************************************************************--->
		<cfinclude template="../grids/jsGrid/themes.cfm">

	</cfif><!---<cfif application.kendoCommercial>--->
		
</cfcase>
			
<!---//*******************************************************************************************************************
				Content Templates
//********************************************************************************************************************--->
			
<cfcase value=55>
	<!--- Instantiate the sting utility object.. We are using this to remove empty strings from the code preview windows. --->
	<cfobject component="#application.stringUtilsComponentPath#" name="StringUtilsObj">
	<!--- Not used yet --->
			
</cfcase>
	
<!--- //************************************************************************************************
		Content Template Editor
//**************************************************************************************************--->
				
<cfcase value=56>
	<cfinclude template="../../admin/adminInterface/postUrlRedirect.cfm"> 			
</cfcase>
	
<!---//*******************************************************************************************************************
				Page Grid
//********************************************************************************************************************--->
<cfcase value=57>
	<!--- Blog Posts / Pages / Page Collections switcher (contentGridSwitcher.cfm). --->
	<cfset currentGridWindowId = 57><cfinclude template="contentGridSwitcher.cfm">
	
	<cfif application.kendoCommercial>
		<!---//***********************************************************************************************
						kendo grid 
		//************************************************************************************************--->
		<cfinclude template="../grids/kendo/pages.cfm">

	<cfelse><!---<cfif application.kendoCommercial>--->
		<!---//***********************************************************************************************
						jsGrid 
		//************************************************************************************************--->
		<cfinclude template="../grids/jsGrid/pages.cfm">

	</cfif><!---<cfif application.kendoCommercial>--->
</cfcase>
			
<!---//*******************************************************************************************************************
				Admin Grid
//********************************************************************************************************************--->
<cfcase value=58>
	
	<cfif application.kendoCommercial>
		<!---//***********************************************************************************************
						kendo grid 
		//************************************************************************************************--->
		<cfinclude template="../grids/kendo/adminLog.cfm">

	<cfelse><!---<cfif application.kendoCommercial>--->
		<!---//***********************************************************************************************
						jsGrid 
		//************************************************************************************************--->
		<cfinclude template="../grids/jsGrid/adminLog.cfm">

	</cfif><!---<cfif application.kendoCommercial>--->
</cfcase>
			
<!---//*******************************************************************************************************************
				Error Grid
//********************************************************************************************************************--->
<cfcase value=59>
	
	<cfif application.kendoCommercial>
		<!---//***********************************************************************************************
						kendo grid 
		//************************************************************************************************--->
		<cfinclude template="../grids/kendo/errorLog.cfm">

	<cfelse><!---<cfif application.kendoCommercial>--->
		<!---//***********************************************************************************************
						jsGrid 
		//************************************************************************************************--->
		<cfinclude template="../grids/jsGrid/errorLog.cfm">

	</cfif><!---<cfif application.kendoCommercial>--->
</cfcase>
			
<!--- //************************************************************************************************
		Error Details 
//**************************************************************************************************--->
		
<cfcase value=60>
	<cfinclude template="../../admin/adminInterface/errorDetail.cfm">	
</cfcase>
	
<!--- //************************************************************************************************
		Search Query Grid 
//**************************************************************************************************--->
		
<cfcase value=61>
	<cfif application.kendoCommercial>
		<!---//*****************************************************************************************
						Kendo Grid
		//******************************************************************************************--->
		<cfinclude template="../grids/kendo/searchQuery.cfm">

	<cfelse><!---<cfif application.kendoCommercial>--->
		<!---//*****************************************************************************************
						jSGrid
		//******************************************************************************************--->
		<cfinclude template="../grids/jsGrid/searchQuery.cfm">

	</cfif><!---<cfif application.kendoCommercial>--->
</cfcase>

<!--- //************************************************************************************************
		Reaction Log Grid
//**************************************************************************************************--->

<cfcase value=62>
	<cfif application.kendoCommercial>
		<!---//*****************************************************************************************
						Kendo Grid
		//******************************************************************************************--->
		<cfinclude template="../grids/kendo/rating.cfm">

	<cfelse><!---<cfif application.kendoCommercial>--->
		<!---//*****************************************************************************************
						jSGrid
		//******************************************************************************************--->
		<cfinclude template="../grids/jsGrid/rating.cfm">

	</cfif><!---<cfif application.kendoCommercial>--->
</cfcase>
	
<!--- //************************************************************************************************
		Anonymous User Detail
//**************************************************************************************************--->
	
<cfcase value=63>
	<cfinclude template="../../admin/adminInterface/anonymousUserDetail.cfm">	
</cfcase>
	
<cfcase value="64">
		  
	<cfif application.kendoCommercial>
		<!---//*****************************************************************************************
						jsGrid visitor log
		//******************************************************************************************--->
		<cfinclude template="../grids/kendo/userVisits.cfm">

	<cfelse><!---<cfif application.kendoCommercial>--->
		<!---//*****************************************************************************************
						jsGrid visitor log
		//******************************************************************************************--->
		<cfinclude template="../grids/jsGrid/userVisits.cfm">

	</cfif><!---<cfif application.kendoCommercial>--->  
		  
</cfcase>
			
<cfcase value="65">
		  
	<cfif application.kendoCommercial>
		<!---//*****************************************************************************************
						Kendo Grid
		//******************************************************************************************--->
		<cfinclude template="../grids/kendo/rating.cfm">

	<cfelse><!---<cfif application.kendoCommercial>--->
		<!---//*****************************************************************************************
						jSGrid
		//******************************************************************************************--->
		<cfinclude template="../grids/jsGrid/rating.cfm">

	</cfif><!---<cfif application.kendoCommercial>--->

</cfcase>

<!--- //************************************************************************************************
		Ban Visitors (by IP address or HTTP User-Agent, via a Kendo MultiSelect)
//**************************************************************************************************--->

<cfcase value="66">
	<cfinclude template="../../admin/adminInterface/banVisitors.cfm">
</cfcase>

<!--- //************************************************************************************************
		Banned Users grid (read only) - shows anonymous visitors whose IP or User-Agent is currently banned
//**************************************************************************************************--->

<cfcase value="67">

	<cfif application.kendoCommercial>
		<!---//*****************************************************************************************
						Kendo Grid
		//******************************************************************************************--->
		<cfinclude template="../grids/kendo/bannedUsers.cfm">

	<cfelse><!---<cfif application.kendoCommercial>--->
		<!---//*****************************************************************************************
						jsGrid
		//******************************************************************************************--->
		<cfinclude template="../grids/jsGrid/bannedUsers.cfm">

	</cfif><!---<cfif application.kendoCommercial>--->

</cfcase>

<!--- //************************************************************************************************
		Schedule Release (the post editor's Schedule Release button)
//**************************************************************************************************--->

<cfcase value="69">
	<cfinclude template="../../admin/adminInterface/scheduleRelease.cfm">
</cfcase>

<cfcase value="68">
	<!--- Blog Posts / Pages / Page Collections switcher (contentGridSwitcher.cfm). --->
	<cfset currentGridWindowId = 68><cfinclude template="contentGridSwitcher.cfm">

	<cfif application.kendoCommercial>
		<!---//***********************************************************************************************
						kendo grid
		//************************************************************************************************--->
		<cfinclude template="../grids/kendo/pageCollections.cfm">

	<cfelse><!---<cfif application.kendoCommercial>--->
		<!---//***********************************************************************************************
						jsGrid
		//************************************************************************************************--->
		<cfinclude template="../grids/jsGrid/pageCollections.cfm">

	</cfif><!---<cfif application.kendoCommercial>--->

</cfcase>

<cfcase value="70">
	<cfinclude template="../../admin/adminInterface/configureHomepage.cfm">
</cfcase>

<cfcase value="71">
	<cfinclude template="../../admin/adminInterface/addPagesToCollection.cfm">
</cfcase>

<cfcase value="72">
	<cfinclude template="../../admin/adminInterface/pageCollectionDetail.cfm">
</cfcase>

<cfcase value="73">
	<cfinclude template="../../admin/adminInterface/heroImagePool.cfm">
</cfcase>

<!--- //************************************************************************************************
		Standalone Uppy cropping uploader - bridges TinyMCE's native "Insert/Edit Image" dialog (Upload tab) to
		the Uppy Dashboard for a Post/Page enclosure. See includes/templates/js/tinyMce.cfm's OpenWindow listener.
		2026-09-26: renumbered 68/69/70 -> 74/75/76 after discovering those numbers were already in use by
		Page Collections (scheduleRelease/pageCollections grid/configureHomepage) - a same-day file sync from D:
		master (which never had the Page Collections cases) had overwritten them. Restored above from git history
		(CF2025 dev's own local repo) - see galaxie-blog-environment-gotchas memory for why D: master and CF2025
		dev are NOT simply "one is newer than the other" for every file.
//**************************************************************************************************--->

<cfcase value=74>
	<cfinclude template="../../admin/adminInterface/enclosureUppyUploadWindow.cfm">
</cfcase>

<!--- //************************************************************************************************
		Standalone Uppy cropping uploader - same bridge as 74, for a Post/Page video cover image.
//**************************************************************************************************--->

<cfcase value=75>
	<cfinclude template="../../admin/adminInterface/videoCoverUppyUploadWindow.cfm">
</cfcase>

<!--- //************************************************************************************************
		Standalone Uppy cropping uploader - same bridge as 74, for imageUploader.cfm's generic theme/profile
		image screens.
//**************************************************************************************************--->

<cfcase value=76>
	<cfinclude template="../../admin/adminInterface/imageUploadUppyUploadWindow.cfm">
</cfcase>

<!--- //************************************************************************************************
		Insert/Edit Gradient - Grapick + Pickr popup, for either a Page Collection's hero
		(URL.entityType eq 'pageCollection') or a TinyMCE Insert > Gradient body-content insert.
//**************************************************************************************************--->

<cfcase value=77>
	<cfinclude template="../../admin/adminInterface/gradientEditor.cfm">
</cfcase>

<!--- //************************************************************************************************
		Paste Custom Gradient - plain textarea popup for pasting a raw CSS gradient() string from an
		external tool, opened from within window 77 (see gradientEditor.cfm's Paste Custom Gradient button).
//**************************************************************************************************--->

<cfcase value=78>
	<cfinclude template="../../admin/adminInterface/gradientPasteEditor.cfm">
</cfcase>

<!--- //************************************************************************************************
		Choose Animation - animation effect picker popup (currently Vanta.js), for a Post's per-post hero
		override (URL.entityType eq 'post') or the site-wide default (URL.entityType eq 'blogOption', from
		Blog Options' "Configure Animation Defaults" button). 2026-10-03: renamed from vantaEditor.cfm
		while still dev-only/unmigrated.
//**************************************************************************************************--->

<cfcase value=79>
	<cfinclude template="../../admin/adminInterface/heroAnimationEditor.cfm">
</cfcase>

<!--- //************************************************************************************************
		Hero Cover Image editor - static uploaded photo for a post whose hero is Gradient/the animation/the
		generated fallback art, used on cards/listings and for social-media share images. URL.optArgs is
		the postId. See heroCoverImageEditor.cfm.
//**************************************************************************************************--->

<cfcase value=80>
	<cfinclude template="../../admin/adminInterface/heroCoverImageEditor.cfm">
</cfcase>

<!--- //************************************************************************************************
		Same Uppy cropping bridge as 74/75/76, for the Hero Cover Image editor above.
//**************************************************************************************************--->

<cfcase value=81>
	<cfinclude template="../../admin/adminInterface/heroCoverImageUppyUploadWindow.cfm">
</cfcase>

<!--- //************************************************************************************************
		Configure Menu (2026-10-10, 4.8) - the owner's own Menu links and the names of the collections menu and the
		combined mobile menu. See admin/adminInterface/configureMenu.cfm.
//**************************************************************************************************--->

<cfcase value=82>
	<cfinclude template="../../admin/adminInterface/configureMenu.cfm">
</cfcase>

<!--- //************************************************************************************************
		Forms (2026-10-13): 83 the list of forms, 84 the form editor (optArgs = webFormId, 0 for a new form), 85 a form's
		submissions (optArgs = webFormId). See admin/adminInterface/webForms*.cfm and common/cfc/WebForms.cfc.
//**************************************************************************************************--->

<cfcase value=83>
	<cfinclude template="../../admin/adminInterface/webForms.cfm">
</cfcase>

<cfcase value=84>
	<cfinclude template="../../admin/adminInterface/webFormDetail.cfm">
</cfcase>

<cfcase value=85>
	<cfinclude template="../../admin/adminInterface/webFormSubmissions.cfm">
</cfcase>

<!--- Insert Form (2026-10-13): opened by the post editor's Insert Form button. See admin/adminInterface/insertWebForm.cfm. --->
<cfcase value=86>
	<cfinclude template="../../admin/adminInterface/insertWebForm.cfm">
</cfcase>

<!--- Bookings (2026-10-14): 87 the Bookings window (from the admin icon), 88 Locations, 89 the location editor (optArgs =
locationOptionId, 0 for a new one). See admin/adminInterface/bookings.cfm and common/cfc/Locations.cfc. --->
<cfcase value=87>
	<cfinclude template="../../admin/adminInterface/bookings.cfm">
</cfcase>
<cfcase value=88>
	<cfinclude template="../../admin/adminInterface/locations.cfm">
</cfcase>
<cfcase value=89>
	<cfinclude template="../../admin/adminInterface/locationDetail.cfm">
</cfcase>
<!--- Bookings (2026-10-14): 90 Booking types, 91 the booking type editor (optArgs = bookingTypeId, 0 for a new one), 92 Hours and
days off. See common/cfc/Bookings.cfc. --->
<cfcase value=90>
	<cfinclude template="../../admin/adminInterface/bookingTypes.cfm">
</cfcase>
<cfcase value=91>
	<cfinclude template="../../admin/adminInterface/bookingTypeDetail.cfm">
</cfcase>
<cfcase value=92>
	<cfinclude template="../../admin/adminInterface/bookingHours.cfm">
</cfcase>
<!--- Insert Booking (2026-10-14): opened by the post editor's Insert Booking button. See admin/adminInterface/insertBooking.cfm. --->
<cfcase value=93>
	<cfinclude template="../../admin/adminInterface/insertBooking.cfm">
</cfcase>
<!--- Bookings (2026-10-14): 94 the bookings list (optArgs = upcoming, past or all), 95 one booking (optArgs = bookingId). --->
<cfcase value=94>
	<cfinclude template="../../admin/adminInterface/bookingsList.cfm">
</cfcase>
<cfcase value=95>
	<cfinclude template="../../admin/adminInterface/bookingDetail.cfm">
</cfcase>
<!--- Bookings (2026-10-15): 96 the bookings calendar. --->
<cfcase value=96>
	<cfinclude template="../../admin/adminInterface/bookingsCalendar.cfm">
</cfcase>
<!--- Member accounts (2026-10-15): 97 the members list. --->
<cfcase value=97>
	<cfinclude template="../../admin/adminInterface/members.cfm">
</cfcase>
<!--- 98 one member. --->
<cfcase value=98>
	<cfinclude template="../../admin/adminInterface/memberDetail.cfm">
</cfcase>

</cfswitch>

</html>