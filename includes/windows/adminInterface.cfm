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
	
<!--- Clear the cache --->
<!--- Note: each Kendo Theme has a cache. There are too many caches to try to flush so we are going to flush them all. --->
<!--- Clear everything from the scopecache library --->
<cfmodule template="#application.baseUrl#/tags/scopecache.cfm" scope="application" clearall="true">
	
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

<!--- Clear CF Caching 
Note: this is broke with CF2023
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
	
<!--- Fancybox --->
<script src="<cfoutput>#application.baseUrl#</cfoutput>/common/libs/fancyBox/v2/source/jquery.fancybox.js"></script>
<link rel="stylesheet" href="<cfoutput>#application.baseUrl#</cfoutput>/common/libs/fancyBox/v2/source/jquery.fancybox.css">
<!--- 
TinyMce styles 
!!! This style is critical for tiny mce dialogs to work properly!!! 
--->
<style>
	/* Set the z-index of the dialogs so that they appear above any other dialog windows. This is absolutely necessary when the UI is already in a dialog, such as a Kendo window. */
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
	// Post editor scripts
	// This function reloads the media preview when new media has been uploaded
	function reloadEnclosureThumbnailPreview(postId){
		// alert('reloading thumbnail')
		$("#mediaPreview").html("<p>Retrieving media....</p>").load("loadPreview.cfm?previewId=1&optArgs=" + postId);
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
	<cfif application.kendoCommercial and 1 eq 2><!---We are not using the Kendo grids right now.--->
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
		
<cfcase value=5>
	
	<cfif application.kendoCommercial and 1 eq 2><!---We are not using the Kendo grids right now.--->
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
	
	<cfif application.kendoCommercial and 1 eq 2><!---We are not using the Kendo grids right now.--->
		<!---//***********************************************************************************************
						kendo grid Comments
		//************************************************************************************************--->
		<cfinclude template="../grids/kendo/userHistory.cfm">

	<cfelse><!---<cfif application.kendoCommercial>--->
		<!---//***********************************************************************************************
						jsGrid Comments
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
			  
	<cfif application.kendoCommercial and 1 eq 2><!---We are not using the Kendo grids right now.--->
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
			  
	<cfif application.kendoCommercial and 1 eq 2><!---We are not using the Kendo grids right now.--->
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
			  
	<cfif application.kendoCommercial and 1 eq 2><!---We are not using the Kendo grids right now.--->
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
			  
	<cfif application.kendoCommercial and 1 eq 2><!---We are not using the Kendo grids right now.--->
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
		
	<cfif application.kendoCommercial and 1 eq 2><!---We are not using the Kendo grids right now.--->
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
		  
		<cfif application.kendoCommercial and 1 eq 2><!---We are not using the Kendo grids right now.--->
		<!---//*****************************************************************************************
						kendo grid Comments
		//******************************************************************************************--->
		<cfinclude template="../grids/kendo/userHistory.cfm">

	<cfelse><!---<cfif application.kendoCommercial>--->
		<!---//*****************************************************************************************
						jsGrid Comments
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
			  
	<cfif application.kendoCommercial and 1 eq 2><!---We are not using the Kendo grids right now.--->
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
			  
	<cfif application.kendoCommercial and 1 eq 2><!---We are not using the Kendo grids right now.--->
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
			
</cfswitch>	
	
</html>