	<cfsilent>
	<!--- Get the custom windows from the db --->
	<cfset getCustomWindows = application.blog.getCustomWindowContent()>
	</cfsilent>
	<!---<cfdump var="#getCustomWindows#">--->

	<!--- Defer this script --->
	<script type="<cfoutput>#scriptTypeString#</cfoutput>">	
		<cfsilent>
		//**************************************************************************************************************
		// Standard listener scripts (custom windows are down the page a bit)
		// Scripts to listen to the URL to determine if we should perform any action after the page loads.
		//**************************************************************************************************************
		
		<!--- We are using this now to open the comments section when a recent comment entry was clicked. I want this to be elegant and seemless as possible to gently expand the comment section.
		Notes: Raymond (et-al) have developed a creative way to hide the URL properties. We are looking for a URL arg 'alias' containing 'Add-comment-interface', and we are getting the 'entry' URL argument as the postId. --->
		</cfsilent>
		<cfif postFound and isDefined("URL.alias")>
		showComment(<cfoutput>'#getPost[1]['PostId']#'</cfoutput>);

		// When we show the comments, we need to change the down arrow to an up arrow, and expand the comments div.
		function showComment(postId){
			// Get the name of the element that we want to change.
			openComment = setTimeout(function(){ 
				// Use a try block. 
				try {
					// Set the elements that we are going to modify.
					var spanElement = "#commentControl" + postId;
					var spanLabelElement = "#commentControlLabel" + postId;
					// Remove the down arrow.
					$(spanElement).removeClass("k-i-sort-desc-sm").addClass('k-i-sort-asc-sm');
					// Add the up arrow.
					$(spanElement).addClass("k-i-sort-asc-sm").addClass('k-i-sort-asc-sm');
					// Change the text of the label
					$(spanLabelElement).text("Hide Comments");
					// Expand the table. See 'fx effects' on the Terlik website.
					kendo.fx($("#comment" + postId)).expand("vertical").play();
				} catch(e){
					// Do nothing. There is a style error that occurs on rare occassions but it does not affect the functionality of the site ('Cannot read property 'style' of undefined').
				}
			}, 500);

			// Get the URL fragment in the url. The fragment is the id of the comment.
			var commentIdInUrlFragment = window.location.hash;
			// Remove the pound sign in the fragment. 
			var commentId = commentIdInUrlFragment.replace('#','');
			// If the commentId is found in the URL fragment...
			if (commentId != '') {
				// After the comment section has opened, scroll to the anchor 
				// Scroll to the anchor. We are using a helper function below. The functions args are: anchorScroll(fromObj, toObj, animateSpeed)
				scrollToComment = setTimeout(function(){ 
					//anchorScroll($("html, body"), $("#addCommentButton"), 500);
					// Scroll to the comment location.
					anchorScroll($("html, body"), $("#" + commentId), 500);
				}, 1000);
			}//..if (commentId != '') {
		}//..function showComment(postId){
		</cfif>
					  
		<cfsilent>
		//**************************************************************************************************************
		// Contact form. We want to resuse this contact form for other purposes, so for now, we are using the URL to let the application know to open up the contact form, which is the same form used for adding comments and to subscribe. 
		//**************************************************************************************************************
		<cfif isDefined("URL.contact")>
			<cfset openContactForm = true>
		<cfelse>
			<cfset openContactForm = false>
		</cfif>
		</cfsilent>
		<cfif openContactForm>
		// Open up the contact form.
		createAddCommentSubscribeWindow('', 'contact', <cfoutput>#session.isMobile#</cfoutput>);
		</cfif>
		<cfsilent>
		//**************************************************************************************************************
		// Subscribe
		//**************************************************************************************************************
		<cfif isDefined("URL.subscribe")>
			<cfset openSubscribeForm = true>
		<cfelse>
			<cfset openSubscribeForm = false>
		</cfif>
		</cfsilent>
		<cfif openSubscribeForm>
		// Open up the subscribe form.
		createAddCommentSubscribeWindow('', 'subscribe', <cfoutput>#session.isMobile#</cfoutput>);
		</cfif>
		<cfsilent>
		//**************************************************************************************************************
		// Subscribe Confirmation
		//**************************************************************************************************************
		</cfsilent>
		<cfif isDefined("URL.confirmSubscription") and isDefined("URL.token")>
		confirmSubscription('<cfoutput>#URL.token#</cfoutput>');
		</cfif>
		<cfsilent>
		//**************************************************************************************************************
		// Unsubscribe
		//**************************************************************************************************************
		<cfif isDefined("URL.unsubscribe")>
			<cfset openUnsubscribeForm = true>
			alert(<cfoutput>#URL.email#</cfoutput>)
		<cfelse>
			<cfset openUnsubscribeForm = false>
		</cfif>
		</cfsilent>
		<cfif openUnsubscribeForm>
		// Invoke the unsubscribe script
		unsubscribe();
		</cfif>
		<cfsilent>				  
		//**************************************************************************************************************
		// Search template 
		//**************************************************************************************************************
		</cfsilent>
		<cfif isDefined("URL.search")>
			createSearchWindow();
		</cfif>			  
		<cfsilent>
		//**************************************************************************************************************
		// About template 
		//**************************************************************************************************************
		</cfsilent>
		<cfif isDefined("URL.about")>
			createAboutWindow(1);
		</cfif>
		<cfif isDefined("URL.aboutMe")><!---TODO put in blog owner in admin interface.--->
			createAboutWindow(2);
		</cfif>
		// End listeners.
		
		//*************************************************************************************************************
		// Kendo window scripts
		//*************************************************************************************************************
		
		// Login window (used in the admin area) --_-------------------------------------------------------------------
		function createLoginWindow(){
			// Open up the login window
			createAdminInterfaceWindow(0, 'login');
		}
		
		// About window -----------------------------------------------------------------------------------------------
		function createAboutWindow(Id) {

			// Remove the window if it already exists
			if ($("#aboutWindow").length > 0) {
				$("#aboutWindow").parent().remove();
			}
			
			// Set the window title
			if (Id == 1){
				var windowTitle = "About <cfoutput>#htmlEditFormat(application.blog.getProperty('blogTitle'))#</cfoutput>";
			} else if (Id == 2){
				var windowTitle = "About Gregory Alexander";//TODO put in an owner name in the admin section.
			} else if (Id == 3){
				var windowTitle = "Download Galaxie Blog";
			}

			// Typically we would use a div outside of the script to attach the window to, however, since this is inside of a function call, we are going to dynamically create a div via the append js method. If we were to use a div outside of this script, lets say underneath the 'mainBlog' container, it would cause wierd problems, such as the page disappearing behind the window.
			$(document.body).append('<div id="aboutWindow"></div>');
			$('#aboutWindow').kendoWindow({
				title: windowTitle,
				// The search window can't be set to full screen per design.
				actions: [<cfoutput>#kendoWindowIcons#</cfoutput>],
				modal: false,
				resizable: true,
				draggable: true,
				// For desktop, we are subtracting 5% off of the content width setting found near the top of this template.
				width: <cfif session.isMobile>getContentWidthPercent()<cfelse>(getContentWidthPercentAsInt()-5 + '%')</cfif>,
				height: '85%',// We must leave room if the user wants to select a bunch of categories.
				iframe: false, // don't  use iframes unless it is content derived outside of your own site. 
				content: "<cfoutput>#application.baseUrl#</cfoutput>/about.cfm?aboutWhat=" + Id,// Make sure to create an absolute path here. I had problems with a cached index.cfm page being inserted into the Kendo window probably due to the blogCfc caching logic. 
			<cfif session.isMobile>
				animation: {
					close: {
						effects: "slideIn:right",
						reverse: true,
						duration: 500
					},
				}
			<cfelse>
				close: function() {
					$('#aboutWindow').kendoWindow('destroy');
				}
			</cfif>
			}).data('kendoWindow').center();// Center the window.
						  
		}//..function createAboutWindow(Id) {

		// The mobile app has a dedicated button to close the window as the x at the top of the window is small and hard to see 
		function closeAboutWindow(){
			$("#aboutWindow").kendoWindow();
			var aboutWindow = $("#aboutWindow").data("kendoWindow");
			setTimeout(function() {
			  aboutWindow.destroy();
			}, 500);
		}
		
		// Search window -----------------------------------------------------------------------------------------------
		// Search window script
		function createSearchWindow() {

			// Remove the window if it already exists
			if ($("#searchWindow").length > 0) {
				$("#searchWindow").parent().remove();
			}

			// Typically we would use a div outside of the script to attach the window to, however, since this is inside of a function call, we are going to dynamically create a div via the append js method. If we were to use a div outside of this script, lets say underneath the 'mainBlog' container, it would cause wierd problems, such as the page disappearing behind the window.
			$(document.body).append('<div id="searchWindow"></div>');
			$('#searchWindow').kendoWindow({

				title: "Search",
				// The search window can't be set to full screen per design.
				actions: [<cfoutput>#kendoWindowIcons#</cfoutput>],
				modal: false,
				resizable: true,
				draggable: true,
				// For desktop, we are subtracting 5% off of the content width setting found near the top of this template.
				width: <cfif session.isMobile>getContentWidthPercent()<cfelse>(getContentWidthPercentAsInt()-5 + '%')</cfif>,
				height: '315px',// We must leave room if the user wants to select a bunch of categories.
				iframe: false, // don't  use iframes unless it is content derived outside of your own site. 
				content: "<cfoutput>#application.baseUrl#</cfoutput>/search.cfm",// Make sure to create an absolute path here. I had problems with a cached index.cfm page being inserted into the Kendo window probably due to the blogCfc caching logic. 
			<cfif session.isMobile>
				animation: {
					close: {
						effects: "slideIn:right",
						reverse: true,
						duration: 500
					},
				}
			<cfelse>
				close: function() {
					$('#searchWindow').kendoWindow('destroy');
				}
			</cfif>
			}).data('kendoWindow').center();// Center the window.
						  
		}//..function searchWindow(Id) {

		// The mobile app has a dedicated button to close the window as the x at the top of the window is small and hard to see 
		function closeSearchWindow(){
			$("#searchWindow").kendoWindow();
			var searchWindow = $("#searchWindow").data("kendoWindow");
			setTimeout(function() {
			  searchWindow.destroy();
			}, 500);
		}

		// Search Results Window. This will be placed underneath the search window.  -----------------------------------
		// Search results script
		function createSearchResultWindow(searchTerm, category, startRow) {

			// Remove the window if it already exists
			if ($("#searchResultsWindow").length > 0) {
				$("#searchResultsWindow").parent().remove();
			}

			$(document.body).append('<div id="searchResultsWindow"></div>');
			$('#searchResultsWindow').kendoWindow({
				title: "Search Results",
				actions: [<cfoutput>#kendoWindowIcons#</cfoutput>],
				modal: false,
				resizable: true,
				draggable: true,
				// For desktop, we are subtracting 5% off of the content width setting found near the top of this template.

				width: <cfif session.isMobile>getContentWidthPercent()<cfelse>(getContentWidthPercentAsInt()-5 + '%')</cfif>,
				height: "85%",
				iframe: false, // don't  use iframes unless it is content derived outside of your own site. 
				content: "<cfoutput>#application.baseUrl#</cfoutput>/searchResults.cfm?searchTerm=" + searchTerm + "&category=" + category,// Make sure to create an absolute path here. I had problems with a cached index.cfm page being inserted into the Kendo window probably due to the blogCfc caching logic. 
			<cfif session.isMobile>
				animation: {
					close: {
						effects: "slideIn:right",
						reverse: true,
						duration: 500
					},
				}
			<cfelse>
				close: function() {
					closeSearchResultsWindow();
				}
			</cfif>
			}).data('kendoWindow').center();// Center the window.
		}

		// Script to close the window using a button at the end of the page.
		function closeSearchResultsWindow(){
			try {
				$("#searchResultsWindow").kendoWindow();
				var searchResultsWindow = $("#searchResultsWindow").data("kendoWindow");
				searchResultsWindow.close();
			} catch(e) {
				error = 'window no longer initialized';
			}
		}
		
		// Notes: https://fellowtuts.com/jquery/get-query-string-values-url-parameters-javascript/
		function getUrlParameter(name) {
			name = name.replace(/[\[]/, "\\[").replace(/[\]]/, "\\]");
			var regex = new RegExp("[\\?&]" + name + "=([^&#]*)"),
			results = regex.exec(location.search);
			return results === null ? "" : decodeURIComponent(results[1].replace(/\+/g, " "));
		}
		
		// Method to create a notification. -------------------------------------------------------   
        function createNotification( template, vars, opts, processId ){
            return $container.notify("create", template, vars, opts);
        }
        
        // Function to initialize a notifcation. 
        $(function(){
            // initialize widget on a container, passing in all the defaults.
            // the defaults will apply to any notification created within this
            // container, but can be overwritten on notification-by-notification
            // basis.
            $container = $("#notification").notify(); 
        });
		
<cfif arrayLen(getCustomWindows)>		
		// Custom windows --------------------------------------------------------------------------
		
		// Custom window listeners
		// Get the param
		customWindow = getUrlParameter('customWindow');
	<cfloop from="1" to="#arrayLen(getCustomWindows)#" index="i">
		<cfsilent>
		<cfset customWindowId = getCustomWindows[i]['CustomWindowContentId']>
		<cfset customWindowName = getCustomWindows[i]['WindowName']>
		<cfset postId = getCustomWindows[i]['PostRef']>
		</cfsilent>
		<cfif i eq 1>// Is the customWindow URL parameter present and does it match a known window name?</cfif>
		if (customWindow.length && customWindow == '<cfoutput>#customWindowName#</cfoutput>'){
			// Open the custom window
			createCustomInterfaceWindow(<cfoutput>#customWindowId#,#postId#</cfoutput>);
		}
	</cfloop>
		// Custom window logic to open the custom window
		function createCustomInterfaceWindow(Id, optArgs, otherArgs, otherArgs1) {
			/* Note: the Id is the windowId, optArgs generally is the postId. These arguments were meant to be generic. */
			// Initialize non required args
			otherArgs1 = typeof otherArgs1 !== 'undefined' ? otherArgs1 : '';
	<cfloop from="1" to="#arrayLen(getCustomWindows)#" index="i">
	<cfoutput>
		<cfif i eq 1>
			if (Id == #i#){
				var postId = "#getCustomWindows[i]['PostRef']#";
				var windowName = "#getCustomWindows[i]['WindowName']#";
				var windowTitle = "#getCustomWindows[i]['WindowTitle']#";
				var windowHeight = "#getCustomWindows[i]['WindowHeight']#";
				var windowWidth = "<cfif session.isMobile>95%<cfelse>#getCustomWindows[i]['WindowWidth']#</cfif>";
		<cfelse>
			} else if (Id == #i#){
				var postId = "#getCustomWindows[i]['PostRef']#";
				var windowName = "#getCustomWindows[i]['WindowName']#";
				var windowTitle = "#getCustomWindows[i]['WindowTitle']#";
				var windowHeight = "#getCustomWindows[i]['WindowHeight']#";
				var windowWidth = "<cfif session.isMobile>95%<cfelse>#getCustomWindows[i]['WindowWidth']#</cfif>";
		</cfif>
			<cfif i eq arrayLen(getCustomWindows)>
			}
			</cfif>
	</cfoutput>
	</cfloop>
			// Typically we would use a div outside of the script to attach the window to, however, since this is inside of a function call, we are going to dynamically create a div via the append js method. If we were to use a div outside of this script, lets say underneath the 'mainBlog' container, it would cause wierd problems, such as the page disappearing behind the window.
			$(document.body).append('<div id="' + windowName + '"></div>');
			$("#" + windowName).kendoWindow({
				title: windowTitle,
				// The search window can't be set to full screen per design.
				actions: [<cfoutput>#kendoWindowIcons#</cfoutput>],
				modal: false,
				iframe: false,
				resizable: <cfif session.isMobile>false<cfelse>true</cfif>,
				draggable: <cfif session.isMobile>false<cfelse>true</cfif>,
				// For desktop, we are subtracting 5% off of the content width setting found near the top of this template.
				width: windowWidth,
				height: windowHeight,// We must leave room if the user wants to select a bunch of categories.
				iframe: false, // don't  use iframes unless it is content derived outside of your own site. 
				content: "<cfoutput>#application.baseUrl#</cfoutput>/includes/windows/customInterface.cfm?interfaceId=" + Id + "&optArgs=" + optArgs + "&otherArgs=" + otherArgs + "&otherArgs1=" + otherArgs1,// Make sure to create an absolute path here. I had problems with a cached index.cfm page being inserted into the Kendo window probably due to the blogCfc caching logic. 
			<cfif session.isMobile>
				animation: {
					close: {
						effects: "slideIn:right",
						reverse: true,
						duration: 500
					},
				}
			<cfelse>
				close: function() {
					$("#" + windowName).kendoWindow('destroy');
				}
			</cfif>
			}).data('kendoWindow').center();// Center the window.
						  
		}//..function createCustomInterfaceWindow(Id, optArgs, otherArgs, otherArgs1) {
</cfif><!---<cfif arrayLen(getCustomWindows)>--->
	
	<cfif pageTypeId eq 2>
	
		// Administrative Interface window --------------------------------------------------------------------------
		function createAdminInterfaceWindow(Id, optArgs, otherArgs, otherArgs1) {
			/* Note: the Id is the window, optArgs generally is the post or comment id, otherArgs typically is the name of the tinymce widget, and otherArgs 1 is generally the id of the widget in the database (ie. the mapId). The arguments were meant to be generic. */
			
			// Initialize non required args
			otherArgs1 = typeof otherArgs1 !== 'undefined' ? otherArgs1 : '';
			
			// Set the window name, title, height and width
			if (Id == 0){
				var windowName = "loginWindow";
				var windowTitle = "Log In";
				var windowHeight = "33%";
				var windowWidth = "<cfif session.isMobile>95%<cfelse>33%</cfif>";
			} else if (Id == 1){
				var windowName = "recentCommentsGridWindow";
				var windowTitle = "Blog Comments";
				var windowHeight = "<cfif session.isMobile>85%<cfelse>75%</cfif>%";
				var windowWidth = "<cfif session.isMobile>95%<cfelse>85%</cfif>";
			} else if (Id == 2){
				var windowName = "commentDetailWindow";
				var windowTitle = "Edit Comment";
				var windowHeight = "66%";
				var windowWidth = "<cfif session.isMobile>95%<cfelse>75%</cfif>";
			} else if (Id == 3){
				/* This window is shared by the gallery and carousel */
				var windowName = "galleryWindow";
				if (otherArgs == "gallery"){
					var windowTitle = "Create Gallery";
				} else {
					var windowTitle = "Create Carousel";
				}
				var windowHeight = "640px";
				var windowWidth = "<cfif session.isMobile>95%<cfelse>732px</cfif>";
			} else if (Id == 4){
				var windowName = "galleryItemsWindow";
				var windowTitle = "Gallery Items";
				var windowHeight = "85%";
				var windowWidth = "<cfif session.isMobile>95%<cfelse>60%</cfif>";
			} else if (Id == 5){
				var windowName = "PostsWindow";
				var windowTitle = "Blog Posts";
				var windowHeight = "<cfif session.isMobile>80%<cfelse>75%</cfif>%";
				var windowWidth = "<cfif session.isMobile>95%<cfelse>85%</cfif>";
			} else if (Id == 6){
				var windowName = "postDetailWindow";
				var windowTitle = "Edit Post";
				var windowHeight = "<cfif session.isMobile>90%<cfelse>66%</cfif>";
				var windowWidth = "<cfif session.isMobile>95%<cfelse>75%</cfif>";
			} else if (Id == 7){
				var windowName = "userDetailWindow";
				var windowHeight = "85%";
				var windowWidth = "<cfif session.isMobile>95%<cfelse>66%</cfif>";
				// This window handles updates and inserts. If the otherArgs is 'addUser', we will insert data. Otherwise, the optArgs should be the numeric User.UserId.
				if (otherArgs == 'addUser'){
					var windowTitle = "Add User";
				} else {
				 	var windowTitle = "Edit User";
				}
			} else if (Id == 8){
				var windowName = "roleNameWindow";
				var windowHeight = "33%";
				var windowWidth = "<cfif session.isMobile>95%<cfelse>33%</cfif>";
				var windowTitle = "Add New Role";
			} else if (Id == 9){
				var windowName = "confirmPasswordWindow";
				var windowHeight = "33%";
				var windowWidth = "<cfif session.isMobile>95%<cfelse>33%</cfif>";
				var windowTitle = "Confirm Password";
			} else if (Id == 10){
				var windowName = "userLoginHistoryWindow";
				var windowHeight = "66%";
				var windowWidth = "<cfif session.isMobile>95%<cfelse>66%</cfif>";
				var windowTitle = "Log-in History";
			} else if (Id == 11){
				var windowName = "userProfileWindow";
				var windowHeight = "70%";
				var windowWidth = "<cfif session.isMobile>95%<cfelse>66%</cfif>";
				var windowTitle = "Edit Profile";
			} else if (Id == 12){
				var windowName = "addCategoryWindow";
				var windowHeight = "33%";
				var windowWidth = "<cfif session.isMobile>95%<cfelse>33%</cfif>";
				var windowTitle = "Add Category";
			} else if (Id == 13){
				var windowName = "postEnclosureWindow";
				var windowHeight = "85%";
				var windowWidth = "<cfif session.isMobile>95%<cfelse>66%</cfif>";
				var windowTitle = "Post Enclosure";
			} else if (Id == 14){
				var windowName = "postEnclosureVideoWindow";
				var windowHeight = "85%";
				var windowWidth = "<cfif session.isMobile>95%<cfelse>732px</cfif>";
				var windowTitle = "Post Video";
			} else if (Id == 15){
				var windowName = "jsonLdWindow";
				var windowHeight = "85%";
				var windowWidth = "<cfif session.isMobile>95%<cfelse>66%</cfif>";
				var windowTitle = "Post JSON-LD (Prettified)";
			} else if (Id == 16){
				var windowName = "webVttFileWindow";
				var windowHeight = "640px";
				var windowWidth = "<cfif session.isMobile>95%<cfelse>66%</cfif>";
				var windowTitle = "WebVTT File";
			} else if (Id == 17){
				var windowName = "uploadWebVttFileWindow";
				var windowHeight = "640px";
				var windowWidth = "<cfif session.isMobile>95%<cfelse>732px</cfif>";
				var windowTitle = "Upload WebVTT File";
			} else if (Id == 18){
				var windowName = "videoCoverWindow";
				var windowHeight = "640px";
				var windowWidth = "<cfif session.isMobile>95%<cfelse>66%</cfif>";
				var windowTitle = "Video Cover";
			} else if (Id == 19){
				var windowName = "mapWindow";
				var windowHeight = "75%";
				var windowWidth = "<cfif session.isMobile>95%<cfelse>85%</cfif>";
				var windowTitle = "Create Map";
			} else if (Id == 20){
				var windowName = "mapRoutingWindow";
				var windowHeight = "75%";
				var windowWidth = "<cfif session.isMobile>95%<cfelse>85%</cfif>";
				var windowTitle = "Create Map Routes";
			} else if (Id == 21){
				var windowName = "cursorImageWindow";
				var windowHeight = "75%";
				var windowWidth = "<cfif session.isMobile>95%<cfelse>85%</cfif>";
				var windowTitle = "Create Map Cursor";
			} else if (Id == 22){
				var windowName = "cleanedJsonLdWindow";
				var windowHeight = "75%";
				var windowWidth = "<cfif session.isMobile>95%<cfelse>85%</cfif>";
				var windowTitle = "Actual JSON LD";
			} else if (Id == 23){ 
				var windowName = "postAliasWindow";
				var windowHeight = "33%";
				var windowWidth = "<cfif session.isMobile>95%<cfelse>33%</cfif>";
				var windowTitle = "Edit Alias"; 
			} else if (Id == 24){
				var windowName = "newPostWindow";
				var windowTitle = "Create Post";
				var windowHeight = "<cfif session.isMobile>66%<cfelse>40%</cfif>";
				var windowWidth = "<cfif session.isMobile>95%<cfelse>75%</cfif>";
			} else if (Id == 25){
				var windowName = "categoryGridWindow";
				var windowTitle = "Categories";
				var windowWidth = "<cfif session.isMobile>95%<cfelse>75%</cfif>";
				var windowHeight = "<cfif session.isMobile>85%<cfelse>75%</cfif>%";
			} else if (Id == 26){
				var windowName = "subscriberGridWindow";
				var windowTitle = "Subscribers";
				var windowWidth = "<cfif session.isMobile>95%<cfelse>75%</cfif>";
				var windowHeight = "75%";
			} else if (Id == 27){
				var windowName = "addSubscriberWindow";
				var windowTitle = "Add Subscriber";
				var windowWidth = "<cfif session.isMobile>95%<cfelse>40%</cfif>";
				var windowHeight = "30%";
			} else if (Id == 28){
				var windowName = "userGridWindow";
				var windowTitle = "Users";
				var windowWidth = "<cfif session.isMobile>95%<cfelse>75%</cfif>";
				var windowHeight = "75%";
			} else if (Id == 29){
				var windowName = "themeGridWindow";
				var windowTitle = "Themes";
				var windowWidth = "<cfif session.isMobile>95%<cfelse>75%</cfif>";
				var windowHeight = "75%";
			} else if (Id == 30){
				var windowName = "themeSettingsWindow";
				var windowTitle = "Theme Settings";
				var windowWidth = "<cfif session.isMobile>95%<cfelse>75%</cfif>";
				var windowHeight = "85%";
			} else if (Id == 31){
				var windowName = "uploadFontWindow";
				var windowTitle = "Upload Font";
				var windowHeight = "640px";
				var windowWidth = "<cfif session.isMobile>95%<cfelse>732px</cfif>";
			} else if (Id == 32){
				var windowName = "uploadFontDetailsWindow";
				var windowTitle = "Font Details";
				var windowWidth = "<cfif session.isMobile>95%<cfelse>75%</cfif>";
				var windowHeight = "85%";
			} else if (Id == 33){
				var windowName = "fontGridWindow";
				var windowTitle = "Fonts";
				var windowWidth = "<cfif session.isMobile>95%<cfelse>75%</cfif>";
				var windowHeight = "<cfif session.isMobile>85%<cfelse>75%</cfif>";
			} else if (Id == 34){
				var windowName = "fontDetailWindow";
				var windowTitle = "Font Detail";
				var windowWidth = "<cfif session.isMobile>95%<cfelse>75%</cfif>";
				var windowHeight = "60%";
			} else if (Id == 35){
				var windowName = "genericImageUploadWindow";
				var windowHeight = "85%";
				var windowWidth = "<cfif session.isMobile>95%<cfelse>732px</cfif>";
				var windowTitle = "Upload Image";
			} else if (Id == 36){
				var windowName = "favIconUploadWindow";
				var windowHeight = "85%";
				var windowHeight = "640px";
				var windowWidth = "<cfif session.isMobile>95%<cfelse>732px</cfif>";
			} else if (Id == 37){
				var windowName = "newThemeWindow";
				var windowHeight = "85%";
				var windowWidth = "<cfif session.isMobile>95%<cfelse>66%</cfif>";
				var windowTitle = "Create New Theme";
			} else if (Id == 38){
				var windowName = "optionsWindow";
				var windowHeight = "85%";
				var windowWidth = "<cfif session.isMobile>95%<cfelse>66%</cfif>";
				var windowTitle = "Blog Options";
			} else if (Id == 39){
				var windowName = "settingsWindow";
				var windowHeight = "85%";
				var windowWidth = "<cfif session.isMobile>95%<cfelse>66%</cfif>";
				var windowTitle = "Blog Settings";
			} else if (Id == 40){
				var windowName = "updatesWindow";
				var windowHeight = "65%";
				var windowWidth = "<cfif session.isMobile>95%<cfelse>45%</cfif>";
				var windowTitle = "Checking for Blog Updates";
			} else if (Id == 41){
				var windowName = "dataImportWindow";
				var windowHeight = "65%";
				var windowWidth = "<cfif session.isMobile>95%<cfelse>45%</cfif>";
				var windowTitle = "BlogCFC/Galaxie Blog Data Import";
			} else if (Id == 42){
				var windowName = "postHeaderWindow";
				var windowHeight = "65%";
				var windowWidth = "<cfif session.isMobile>95%<cfelse>45%</cfif>";
				var windowTitle = "Post Header";
			} else if (Id == 43){
				var windowName = "blogSortDateWindow";
				var windowHeight = "35%";
				var windowWidth = "<cfif session.isMobile>95%<cfelse>45%</cfif>";
				var windowTitle = "Change Post Sort Date";
			} else if (Id == 44){
				var windowName = "setPostThemeWindow";
				var windowHeight = "35%";
				var windowWidth = "<cfif session.isMobile>95%<cfelse>45%</cfif>";
				var windowTitle = "Set Post Theme";
			} else if (Id == 45){
				var windowName = "customWindow";
				var windowHeight = "70%";
				var windowWidth = "<cfif session.isMobile>95%<cfelse>75%</cfif>";
				var windowTitle = "Create Custom Window";
			} else if (Id == 46){
				var windowName = "postCssWindow";
				var windowHeight = "70%";
				var windowWidth = "<cfif session.isMobile>95%<cfelse>75%</cfif>";
				var windowTitle = "Post CSS";
			} else if (Id == 47){
				var windowName = "postJavaScriptWindow";
				var windowHeight = "70%";
				var windowWidth = "<cfif session.isMobile>95%<cfelse>75%</cfif>";
				var windowTitle = "Post JavaScript";
			} else if (Id == 48){
				var windowName = "visitorLogWindow";
				var windowHeight = "70%";
				var windowWidth = "<cfif session.isMobile>95%<cfelse>75%</cfif>";
				var windowTitle = "Visitor Logs";
			} else if (Id == 49){
				var windowName = "addTagWindow";
				var windowHeight = "33%";
				var windowWidth = "<cfif session.isMobile>95%<cfelse>33%</cfif>";
				var windowTitle = "Add Tag";
			} else if (Id == 50){
				var windowName = "tagGridWindow";
				var windowTitle = "Tags";
				var windowWidth = "<cfif session.isMobile>95%<cfelse>75%</cfif>";
				var windowHeight = "<cfif session.isMobile>85%<cfelse>75%</cfif>%";
			} else if (Id == 51){
				var windowName = "carouselItemsWindow";
				var windowTitle = "Carousel Images";
				var windowHeight = "85%";
				var windowWidth = "<cfif session.isMobile>95%<cfelse>60%</cfif>";
			}
			
			// Remove the window if it already exists
			if ($("#" + windowName).length > 0) {
				$("#" + windowName).parent().remove();
			}

			// Typically we would use a div outside of the script to attach the window to, however, since this is inside of a function call, we are going to dynamically create a div via the append js method. If we were to use a div outside of this script, lets say underneath the 'mainBlog' container, it would cause wierd problems, such as the page disappearing behind the window.
			$(document.body).append('<div id="' + windowName + '"></div>');
			$("#" + windowName).kendoWindow({
				title: windowTitle,
				// The search window can't be set to full screen per design.
				actions: [<cfoutput>#kendoWindowIcons#</cfoutput>],
				modal: false,
				iframe: false,
				resizable: <cfif session.isMobile>false<cfelse>true</cfif>,
				draggable: <cfif session.isMobile>false<cfelse>true</cfif>,
				// For desktop, we are subtracting 5% off of the content width setting found near the top of this template.
				width: windowWidth,
				height: windowHeight,// We must leave room if the user wants to select a bunch of categories.
				iframe: false, // don't  use iframes unless it is content derived outside of your own site. 
				content: "../includes/windows/adminInterface.cfm?adminInterfaceId=" + Id + "&optArgs=" + optArgs + "&otherArgs=" + otherArgs + "&otherArgs1=" + otherArgs1,// Make sure to create an absolute path here. I had problems with a cached index.cfm page being inserted into the Kendo window probably due to the blogCfc caching logic. 
			<cfif session.isMobile>
				animation: {
					close: {
						effects: "slideIn:right",
						reverse: true,
						duration: 500
					},
				}
			<cfelse>
				close: function() {
					$("#" + windowName).kendoWindow('destroy');
				}
			</cfif>
			}).data('kendoWindow').center();// Center the window.
						  
		}//..function createAdminInterfaceWindow(Id, optArgs, otherArgs, otherArgs1) {
		
		// Administrative Interface window helpers --------------------------------------------------------------------

		// The mobile app has a dedicated button to close the window as the x at the top of the window is small and hard to see 
		function closeAdminInterfaceWindow(Id){
			
			// Get the window name (id)
			if (Id == 1){
				var windowName = "recentCommentsGridWindow";
			} else if (Id == 2){
				var windowName = "commentDetailWindow";
			} else if (Id == 3){
				var windowName = "galleryWindow";
			} else if (Id == 4){
				var windowName = "galleryItemsWindow";
			} else if (Id == 5){
				var windowName = "postsWindow";
			}
			
			// Close the window
			$("#adminInterfaceWindow").kendoWindow();
			var adminInterfaceWindow = $("#" + windowName).data("kendoWindow");
			setTimeout(function() {
			  $("#" + windowName).kendoWindow('destroy');
			}, 500);
		}
	</cfif><!---<cfif pageTypeId eq 2>--->
		
		// Note: comments are either provided with the Galaxi Blog interface, or disqus. We need to open up new kendo windows for each interface.
	<cfif application.includeDisqus>
		// Disqus comment window ---------------------------------------------------------------------------------------
		function createDisqusWindow(Id, alias, url) {

			// Remove the window if it already exists
			if ($("#disqusWindow").length > 0) {
				$("#disqusWindow").parent().remove();
			}


			// Typically we would use a div outside of the script to attach the window to, however, since this is inside of a function call, we are going to dynamically create a div via the append js method. If we were to use a div outside of this script, lets say underneath the 'mainBlog' container, it would cause wierd problems, such as the page disappearing behind the window.
			$(document.body).append('<div id="disqusWindow"></div>');
			$('#disqusWindow').kendoWindow({
				title: "Comments",
				actions: [<cfoutput>#kendoWindowIcons#</cfoutput>],
				modal: false,
				resizable: <cfif session.isMobile>false<cfelse>true</cfif>,
				draggable: <cfif session.isMobile>false<cfelse>true</cfif>,
				// For desktop, we are subtracting 5% off of the content width setting found near the top of this template.
				width: <cfif session.isMobile>getContentWidthPercent()<cfelse>(getContentWidthPercentAsInt()-5 + '%')</cfif>,
				height: "<cfif session.isMobile>95<cfelse>60</cfif>%",
				iframe: false, // don't  use iframes unless it is content derived outside of your own site. 
				content: "<cfoutput>#application.baseUrl#</cfoutput>/disqus.cfm?id=" + Id + '&alias=' + alias + '&url=' + url,// Make sure to create an absolute path here. I had problems with a cached index.cfm page being inserted into the Kendo window probably due to the blogCfc caching logic. 
			<cfif session.isMobile>
				animation: {
					close: {
						effects: "slideIn:right",
						reverse: true,
						duration: 500
					},
				}
			<cfelse>
				close: function() {
					$('#disqusWindow').kendoWindow('destroy');
				}
			</cfif>
			}).data('kendoWindow').center();
		}//..function createDisqusWindow(Id, alias, url) {
		
		// The mobile app has a dedicated button to close the window as the x at the top of the window is small and hard to see 
		function closeDisqusWindow(){
			$("#disqusWindow").kendoWindow();
			var disqusWindow = $("#disqusWindow").data("kendoWindow");
			setTimeout(function() {
			  disqusWindow.destroy();
			}, 500);
		}
	</cfif><!---<cfif application.includeDisqus>--->
		// Add comment window (note: even when including Disqus, this must be here as it is used for the contact form. ------------------------------------------------
		function createAddCommentSubscribeWindow(Id, uiElement, isMobile) {

			// Remove the window if it already exists
			if ($("#addCommentWindow").length > 0) {
				$("#addCommentWindow").parent().remove();
			}

			// Set uiElement vars
			if (uiElement == 'addComment'){
				if (isMobile){
					var windowHeight = '95%'
					var windowTitle = 'Add Comment';
				} else {  
					var windowHeight = '65%'
					var windowTitle = 'Add Comment';
				}
			} else if (uiElement == 'subscribe') {
				if (isMobile){
					var windowHeight = '60%'
					var windowTitle = 'Subscribe';
				} else {
					var windowHeight = '35%'
					var windowTitle = 'Subscribe';
				}
			} else if (uiElement == 'contact') {
				if (isMobile){
					var windowHeight = '95%'
					var windowTitle = 'Contact';
				} else {
					var windowHeight = '65%'
					var windowTitle = 'Contact';
				}
			}

			// Typically we would use a div outside of the script to attach the window to, however, since this is inside of a function call, we are going to dynamically create a div via the append js method. If we were to use a div outside of this script, lets say underneath the 'mainBlog' container, it would cause wierd problems, such as the page disappearing behind the window.
			$(document.body).append('<div id="addCommentWindow"></div>');
			$('#addCommentWindow').kendoWindow({
				title: windowTitle,
				actions: [<cfoutput>#kendoWindowIcons#</cfoutput>],
				modal: false,
				resizable: <cfif session.isMobile>false<cfelse>true</cfif>,
				draggable: <cfif session.isMobile>false<cfelse>true</cfif>,
				// For desktop, we are subtracting 5% off of the content width setting found near the top of this template.
				width: <cfif session.isMobile>getContentWidthPercent()<cfelse>(getContentWidthPercentAsInt()-5 + '%')</cfif>,
				height: windowHeight,
				iframe: false, // don't  use iframes unless it is content derived outside of your own site. 
				content: "<cfoutput>#application.baseUrl#</cfoutput>/addCommentSubscribe.cfm?id=" + Id + '&uiElement=' + uiElement,// Make sure to create an absolute path here. I had problems with a cached index.cfm page being inserted into the Kendo window probably due to the blogCfc caching logic. 
			<cfif session.isMobile>
				animation: {
					close: {
						effects: "slideIn:right",
						reverse: true,
						duration: 500
					},
				}
			<cfelse>
				close: function() {
					$('#addCommentWindow').kendoWindow('destroy');
				}
			</cfif>
			}).data('kendoWindow').center();// Center the window.
		}//..function createAddCommentSubscribeWindow(Id, uiElement, isMobile) {
		
		// The mobile app has a dedicated button to close the window as the x at the top of the window is small and hard to see 
		function closeAddCommentSubscribeWindow(){
			$("#addCommentWindow").kendoWindow();
			var addCommentWindow = $("#addCommentWindow").data("kendoWindow");
			setTimeout(function() {
			  addCommentWindow.destroy();
			}, 500);
		}
						  
		//**************************************************************************************************************
		// Ajax functions 
		//**************************************************************************************************************

		// Captcha -----------------------------------------------------------------------------------------------------
		// This function is used by multiple templates, including the add comments and subscribe interfaces.
		function checkCaptcha(captchaText, captchaHash){
			// Submit form via AJAX.
			$.ajax(
				{
					type: "get",
					url: "<cfoutput>#application.proxyControllerUrl#</cfoutput>?method=validateCaptcha",
					data: {
						captchaText: captchaText,
						captchaHash: captchaHash
					},
					dataType: "json",
					cache: false,
					success: function(data) {
						setTimeout(function () {
							checkCaptchaResult(data);
						// Setting this lower than 500 causes some issues.
						}, 500);
					}
				}
			);
		}//..function checkCaptcha(captchaText, captchaHash){

		// Post Comment ------------------------------------------------------------------------------------------------
		// Invoked via the addCommentSubscribe.cfm window after Kendo validation occurs.
		function postCommentSubscribe(postId, uiInterface){
			//alert(uiInterface);
			// Note: the subscribe functionality uses the same logic as postComment with an empty comment and a comment only flag.
			// Get the value of the forms
			var postTitle = $( "#postTitle" ).val();
			var uiInterface = uiInterface;
			var commenterName = $( "#commenterName" ).val();
			var commenterEmail = $( "#commenterEmail" ).val();
			var commenterWebSite = $( "#commenterWebSite" ).val();
			var comments = $( "#comments" ).val();
			<cfif application.useCaptcha and not application.Udf.isLoggedIn()>
			var captchaText = $( "#captchaText" ).val();
			var captchaHash = $( "#captchaHash" ).val();
			</cfif>
			var rememberMe = $('#rememberMe').is(':checked')
			var subscribe = $('#subscribe').is(':checked')  // checkbox boolean value.

			// Handle specific uiInteface arguments
			if (uiInterface == 'addComment'){
				windowName = "addCommentWindow";
				pleaseWaitMessage = "Posting Comment.";
			} else if (uiInterface == 'subscribe'){
				windowName = "addCommentSubWindow";
				pleaseWaitMessage = "Subscribing.";
			} else if (uiInterface == 'contact'){
				windowName = "contactWindow";
				pleaseWaitMessage = "Sending Message.";
			}

			// Submit form via AJAX.
			$.ajax({
				type: 'post', 
				// This posts to the proxy controller as it needs to have session vars and performs client side operations.
				url: "<cfoutput>#application.proxyControllerUrl#</cfoutput>?method=postCommentSubscribe",
				data: {
					postId: postId,
					uiInterface: uiInterface,
					postTitle: postTitle,
					commenterName: commenterName,
					commenterEmail: commenterEmail,
					commenterWebSite: commenterWebSite,
					comments: comments,
					<!---user: "<cfoutput>#getAuthUser()#</cfoutput>", CF2023 Cache issue, replace this with application.blog.getUsersId() --->
					ipAddress: "<cfoutput>#CGI.Remote_Addr#</cfoutput>",
					httpUserAgent: "<cfoutput>#CGI.Http_User_Agent#</cfoutput>",
					<cfif application.useCaptcha and not application.Udf.isLoggedIn()>
					captchaText: captchaText,
					captchaHash: captchaHash,
					</cfif>
					subscribe: subscribe,
					rememberMe: rememberMe
				},//..data: {
				dataType: "json",
				cache: false,
				success: function(data) {
					// Note: allow around 1/4 of a second before posting.
					setTimeout(function () {
						postCommentSubscribeResponse(data, uiInterface);
					}, 250);//..setTimeout(function () {
				}//..success: function(data) {
			});//..$.ajax({

			// Open the please wait window. Note: the ExtWaitDialog's are based upon an open source project and not a part of the Kendo official library. I prefer this design over Kendo's dialog offerings. I have extended this library with some of my own designs.
			$.when(kendo.ui.ExtWaitDialog.show({ title: "Please wait...", message: pleaseWaitMessage, icon: "k-ext-information" }));
			// Use a quick set timeout in order for the data to load.
			setTimeout(function() {
				// Close the wait window that was launched in the calling function.
				kendo.ui.ExtWaitDialog.hide();
			}, 2000);
			// Return false in order to prevent any potential redirection.
			return false;
		}//..function postCommentSubscribe(postId, uiInterface){

		function postCommentSubscribeResponse(response, uiInterface){
			//alert(uiInterface);
			// Extract the data in the response.
			// General vars	
			var postId = response.postId;
			var success = response.success;
			// Error vars
			var validName = response.validName;
			var validEmail = response.validEmail;
			var validWebsite = response.validWebsite;
			var validComment = response.validComment;
			var errorMessage = response.errorMessage;
			// Database vars (placeholder for the next version).
			var dbSuccess = response.dbSuccess;
			var dbErrorMessage = response.dbErrorMessage;
			// Subscribe args
			var alreadySubscribed = response.alreadySubscribed;
			// Email args
			var adminEmailedNewComment = response.adminEmailedNewComment;
			var confirmationEmailSent = response.confirmationEmailSent;
			var newCommentEmailSentToPostSubscribers = response.newCommentEmailSentToPostSubscribers;

			// Catch errors
			if (!success){
				// Set the error message
				var errorMessage = 'Errors were found.';
				if (!validName){
					var errorMessage = errorMessage + ' Name is required<br/>.';
				}
				if (!validEmail){
					var errorMessage = errorMessage + ' Valid email is required.<br/>';
				}
				if (!validWebsite){
					var errorMessage = errorMessage + ' Website URL is not valid.<br/>';
				}
				if (!validWebsite){
					var errorMessage = errorMessage + ' Comment required.<br/>';
				}
				if (!errorMessage){
					var errorMessage = errorMessage + ' ' + errorMessage + '<br/>';
				}
				// Raise the error message.
				$.when(kendo.ui.ExtAlertDialog.show({ title: "Errors were found.", message: errorMessage, icon: "k-ext-error", width: "<cfoutput>#application.kendoExtendedUiWindowWidth#</cfoutput>" }) // or k-ext-error, k-ext-information, k-ext-question, k-ext-warning.  You can also specify height.
					).done(function () {
					// Do nothing
				});		
			
			// Display a success message.	
			} else { 
				// Create the success message.
				// The moderateComments will be returned either as 'YES/NO'. 
				var moderateComments = '<cfoutput>#application.commentmoderation#</cfoutput>'; 
				if (uiInterface == 'addComment'){
					if (moderateComments == 'YES'){
						var successTitle = 'Email Sent to moderator';
						var successMessage = 'Your comment has been sent to the administrator for approval.';
					} else  {
							var successTitle = 'Your comment has been posted';
						var successMessage = 'Your comment has been posted. Refresh the page to display.';
					}
				} else if (uiInterface == 'addComment'){
					var successTitle = 'Subscribed';
					var successMessage = 'You are now subscribed to this thread.';
				} else if (uiInterface == 'contact'){
					var successTitle = 'Email Sent';
					var successMessage = 'Your message was sent.';
				} else if (uiInterface == 'subscribe'){
					// Determine the message based upon the data sent from the server
					if (alreadySubscribed){
						var successTitle = 'Subscribed';
						var successMessage = 'Thank you for subscribing!';
					} else if (confirmationEmailSent){
						var successTitle = 'Please check your email';
						var successMessage = 'Please check your email to verify your subscription.';
					}
				}

				// Raise the message.
				$.when(kendo.ui.ExtWaitDialog.show({ title: successTitle, message: successMessage, icon: "k-ext-information" }));
				// Use a quick set timeout in order for the data to load.
				setTimeout(function() {
					// Close the success message window.
					kendo.ui.ExtWaitDialog.hide();
					// Close the window
					closeAddCommentSubscribeWindow();
				}, 2000);
			}
		}//..function postCommentSubscribeResponse(response, uiInterface){
						  
		// Subscribe to the blog.  -------------------------------------------------------------------------------------
		// Invoked via the addCommentSubscribe.cfm window after Kendo validation occurs.
		function subscribeToBlog(sideBarType){
			if (sideBarType == 'div'){
				subscribeFormName = 'subscribeViaDiv';
			} else {
				subscribeFormName = 'subscribeViaPanel';
			}

			// Get the email address that was typed in.
			var email = $( "#" + subscribeFormName ).val();
			// alert(email);
			// Submit form via AJAX.
			$.ajax({
				type: 'post', 
				// This posts to the proxy controller as it needs to have session vars and performs client side operations.
				url: "<cfoutput>#application.proxyControllerUrl#</cfoutput>?method=subscribe",
				data: {
					email: email
				},//..data: {
				dataType: "json",
				cache: false,
				success: function(data) {
					setTimeout(function () {
						subscribeResponse(data);
					}, 500);//..setTimeout(function () {
				}//..success: function(data) {
			});//..$.ajax({

			// Open the please wait window. Note: the ExtWaitDialog's are based upon an open source project and not a part of the Kendo official library. I prefer this design over Kendo's dialog offerings. I have extended this library with some of my own designs.
			$.when(kendo.ui.ExtWaitDialog.show({ title: "Please wait...", message: "Please wait", icon: "k-ext-information" }));
			// Use a quick set timeout in order for the data to load.
			setTimeout(function() {
				// Close the wait window that was launched in the calling function.
				kendo.ui.ExtWaitDialog.hide();
			}, 500);
			// Return false in order to prevent any potential redirection.
			return false;
		}//..function subscribeToBlog(email){
						  
		function subscribeResponse(response){
			//alert(uiInterface);
			// Extract the data in the response.
			var message = response.message;
			// Display it.			  
			$.when(kendo.ui.ExtAlertDialog.show({ title: "Subscribe", message: message, icon: "k-ext-information", width: "<cfoutput>#application.kendoExtendedUiWindowWidth#</cfoutput>", height: "215px"}));
		}
	<cfif isDefined("URL.confirmSubscription") and isDefined("URL.token")>
		// Confirm blog subscription.  -------------------------------------------------------------------------------------	
		// Invoked via ta listener from this template.
		function confirmSubscription(token){
			// Note: this is a custom library that I am using. The ExtAlertDialog is not a part of Kendo but an extension.
			 $.when(kendo.ui.ExtYesNoDialog.show({ // Alert the user and ask them if they want to double opt in
				title: "Please confirm your subscription",
				message: "Do you want to subscribe to <cfoutput>#htmlEditFormat(application.BlogDbObj.getBlogTitle())#</cfoutput>?",
				icon: "k-ext-information",
				width: "<cfoutput>#application.kendoExtendedUiWindowWidth#</cfoutput>", 
				height: "215px"
			 })
			).done(function (response) { // If the user clicked 'yes', confirm.
				if (response['button'] == 'Yes'){// remember that js is case sensitive.
					
					// Get the token via the URL.
					var token = <cfoutput>'#url.token#'</cfoutput>;
					
					// Submit form via AJAX.
					$.ajax({
						type: 'post', 
						// This posts to the proxy controller as it needs to have session vars and performs client side operations.
						url: "<cfoutput>#application.proxyControllerUrl#</cfoutput>?method=confirmSubscriptionViaToken",
						data: {
							token: token
						},//..data: {
						dataType: "json",
						cache: false,
						success: function(data) {
							setTimeout(function () {
								confirmSubscriptionResponse(data);
							}, 500);//..setTimeout(function () {
						}//..success: function(data) {
					});//..$.ajax({

					// Open the please wait window. Note: the ExtWaitDialog's are based upon an open source project and not a part of the Kendo official library. I prefer this design over Kendo's dialog offerings. I have extended this library with some of my own designs.
					$.when(kendo.ui.ExtWaitDialog.show({ title: "Please wait...", message: "Please wait", icon: "k-ext-information" }));
					// Use a quick set timeout in order for the data to load.
					setTimeout(function() {
						// Close the wait window that was launched in the calling function.
						kendo.ui.ExtWaitDialog.hide();
					}, 500);
					// Return false in order to prevent any potential redirection.
					return false;
				}//...if (response['button'] == 'Yes')
			});

		}//..function confirmSubscription(token){
						  
		function confirmSubscriptionResponse(response){
			//alert(uiInterface);
			// Extract the data in the response.
			var message = "Thank-you for subscribing to the blog!";
			// Display it.			  
			$.when(kendo.ui.ExtAlertDialog.show({ title: "Subscribed", message: message, icon: "k-ext-information", width: "<cfoutput>#application.kendoExtendedUiWindowWidth#</cfoutput>", height: "215px"}));
		}

	</cfif><!---<cfif isDefined("URL.email") and isDefined("URL.token")>--->	
	<cfif isDefined("URL.email") and isDefined("URL.token")>
		// Unsubscribe to the blog.  -------------------------------------------------------------------------------------	
		// Invoked via ta listener from this template.
		function unsubscribe(){
		
			// Note: this is a custom library that I am using. The ExtAlertDialog is not a part of Kendo but an extension.
			 $.when(kendo.ui.ExtYesNoDialog.show({ // Alert the user and ask them if they want to unsubscribe
				title: "Are you sure that you want to unsubscribe?",
				message: "You will no longer receive email from <cfoutput>#htmlEditFormat(application.BlogDbObj.getBlogTitle())#</cfoutput>",
				icon: "k-ext-warning",
				width: "<cfoutput>#application.kendoExtendedUiWindowWidth#</cfoutput>", 
				height: "215px"
			 })
			).done(function (response) { // If the user clicked 'yes', unsubscribe.
				if (response['button'] == 'Yes'){// remember that js is case sensitive.
					
					// Get the email address and token via the URL.
					var email = <cfoutput>'#url.email#'</cfoutput>;
					var token = <cfoutput>'#url.token#'</cfoutput>;
					<cfif isDefined("URL.commentId")>commentId: <cfoutput>#URL.commentId#</cfoutput></cfif>;
					// alert(email);
					
					// Submit form via AJAX.
					$.ajax({
						type: 'post', 
						// This posts to the proxy controller as it needs to have session vars and performs client side operations.
						url: "<cfoutput>#application.proxyControllerUrl#</cfoutput>?method=unsubscribe",
						data: {
							email: email,
							token: token
						},//..data: {
						dataType: "json",
						cache: false,
						success: function(data) {
							setTimeout(function () {
								unsubscribeResponse(data);
							}, 500);//..setTimeout(function () {
						}//..success: function(data) {
					});//..$.ajax({

					// Open the please wait window. Note: the ExtWaitDialog's are based upon an open source project and not a part of the Kendo official library. I prefer this design over Kendo's dialog offerings. I have extended this library with some of my own designs.
					$.when(kendo.ui.ExtWaitDialog.show({ title: "Please wait...", message: "Please wait", icon: "k-ext-information" }));
					// Use a quick set timeout in order for the data to load.
					setTimeout(function() {
						// Close the wait window that was launched in the calling function.
						kendo.ui.ExtWaitDialog.hide();
					}, 500);
					// Return false in order to prevent any potential redirection.
					return false;
				}//...if (response['button'] == 'Yes')
			});

		}//..function unsubscribe(email){
						  
		function unsubscribeResponse(response){
			//alert(uiInterface);
			// Extract the data in the response.
			var message = "You have unsubscribed";
			// Display it.			  
			$.when(kendo.ui.ExtAlertDialog.show({ title: "Unsubscribed", message: message, icon: "k-ext-information", width: "<cfoutput>#application.kendoExtendedUiWindowWidth#</cfoutput>", height: "215px"}));
		}
	</cfif><!---<cfif isDefined("URL.email") and isDefined("URL.token")>--->		  
		//**************************************************************************************************************
		// Helper functions 
		//**************************************************************************************************************
		
		// Functions to create various links
		function makePostLink(datePosted, postAlias){
			var dt = new Date(datePosted);
			var yyyy = dt.getFullYear();
			var m = dt.getMonth()+1;
			var d = dt.getDay()+1;
			return yyyy + "/" + m + "/" + d + "/" + postAlias;
		}
		
		// The comment link is the post link with a ''#c' + commentId 
		function makeCommentLink(datePosted, postAlias, commentId){
			var postLink = makePostLink(datePosted, postAlias);
			var commentLink = postLink + "#c" + commentId;
			return commentLink;
		}

		// Used to scroll to a particular comment.
		function anchorScroll(fromObj, toObj, animateSpeed) {
			var fromOffset = fromObj.offset();
			var toOffset = toObj.offset();
			var offsetDiff = Math.abs(toObj.top - fromObj.top);

			var speed = (offsetDiff * animateSpeed) / 1000;
			$("html,body").animate({
				scrollTop: toOffset.top
			}, animateSpeed);
		}//..function anchorScroll(fromObj, toObj, animateSpeed) {

		//**************************************************************************************************************
		// Widget UI settings 
		//**************************************************************************************************************

		// Document read block. Note: functions inside will not be available.
		$(document).ready(function() {
						  
			/* Kendo FX */
			/* To place an expading image into the blog content with an entry, use the following code in the entry editor:
			<div id="fxZoom">
				<img src="../../blog/doc/settings/adminUserLink.png" />
			</div>
			*/
			$("#fxZoom img").hover(function() {
				kendo.fx(this).zoom("in").startValue(.5).endValue(1).play();
			}, function() {
				kendo.fx(this).zoom("out").endValue(.5).startValue(1).play();
			});
			
		});//..document ready

	</script>
	<cfsilent>
	<!--- End windows --->
	
	<!--- Fancybox and Kendo Panel Bar custom scripts. The panel bar is a fancy widget for the table of contents. Fancy Box is used to place expanding thumnail images that take up very little space within the blog content. Use the following example and type this into the blog entry editor (in the admin section):
	<a class="fancybox-effects" href="/blog/doc/addThis/2addNewTool.png" data-fancybox-group="steps12" title="Add New Tool"><img src="/blog/doc/addThis/2addNewToolThumb.png" alt="" /></a>
	I may build this functionality in with a new editor.
	--->
	</cfsilent>
	<script type="<cfoutput>#scriptTypeString#</cfoutput>">
	
		$(document).ready(function() {
		
			// Create an accordian style panel for all table of contents. 
			// Append a gtoc id to *all* ul elements inside a mce-toc class
			try {
				// Create a loop counter
				var tocLoop = 0;
				// Loop through all classes with mce-toc
				$('.mce-toc').each(function(index,el){
					// Find the ul
					var selectedDiv = $(el).find('ul');
					// Append the ul with a gtoc + loopCounter
					selectedDiv =  selectedDiv.attr('id', 'gtoc' + tocLoop);

					// Create the panel bar
					$("#gtoc" + tocLoop).kendoPanelBar({
						expandMode: "single"
					});
					// Increment the loop
					tocLoop++;
				});
			} catch(err) {
  				error = "Error generating Kendo Panel for TOC";
			}
			
			// Load fancyBox */
			$('.fancybox').fancybox();

			// Set fancybox custom properties (I am over-riding basic functionality).
			$(".fancybox-effects").fancybox({
				wrapCSS    : 'fancybox-custom', //ga
				padding: 5,
				openEffect : 'elastic',
				openSpeed  : 150,
				closeEffect : 'elastic',
				closeSpeed  : 150,
				closeClick : false,
				helpers : {
					title : {
						 type: 'outside'
					},
					overlay : null
				}
			});

			$('.fancybox-media')
			.attr('rel', 'media-gallery')
			.fancybox({
				openEffect : 'none',
				closeEffect : 'none',
				prevEffect : 'none',
				nextEffect : 'none',
				arrows : false,
				helpers : {
					media : {},
					buttons : {}
				}
			});

		});//..document.ready
		
		// Script that will allow us to expand the post containers to allow the user to see the comments.
		function handleComments(){
			// Expand the comments
			// When the ascending arrow is clicked on...
			$(".flexParent").on("click", "span.k-i-sort-desc-sm", function(e) {	
				// We need to get the associated postId to properly expand the right containter. Here, we will get the id of this emement. It should be commentControl + postId. 
				var clickedSpan = $(this).attr('id');
				// Remove the 'commentControl' string from the id to just get the Id.
				var postId = clickedSpan.replace("commentControl", "");
				// The content element's id will be 'comment' + postId 
				var contentElement = 'comment' + postId;
				// We also want to change the label. The label has the postId appended to it as well.
				var spanLabelElement = "#commentControlLabel" + postId;
				// Change the label text
				$(spanLabelElement).text("Hide Comments");
				// Change the class of the span (ie change the arrow direction), and expand the table.
				$(e.target)
					.removeClass("k-i-sort-desc-sm")
					.addClass("k-i-sort-asc-sm");
					// Expand the table. See 'fx effects' on the Terlik website.
					kendo.fx($("#" + contentElement)).expand("vertical").play();
			});

			// Collapse the widget. 
			// When the ascending arrow is clicked on...
			$(".flexParent").on("click", "span.k-i-sort-asc-sm", function(e) {
				// We need to get the associated postId to properly expand the right containter. Here, we will get the id of this emement. It should be commentControl + postId. 
				var clickedSpan = $(this).attr('id');
				// Remove the 'commentControl' string from the id to just get the Id.
				var postId = clickedSpan.replace("commentControl", "");
				// The content element's id will be 'comment' + postId
				var contentElement = 'comment' + postId;
				// We also want to change the label. The lable has the postId appended to it as well.
				var spanLabelElement = "#commentControlLabel" + postId;
				// Change the label text
				$(spanLabelElement).text("Show Comments");
				// Change the class of the span (ie change the arrow direction), and shrink the table. I am doing this as I don't  want to have to traverse the dom and write a bug.
				$(e.target)
					.removeClass("k-i-sort-asc-sm")
					.addClass("k-i-sort-desc-sm");
					// 'reverse' the table. See 'fx effects' on the Telerik website.
					kendo.fx($("#" + contentElement)).expand("vertical").stop().reverse();
			});
		}
		
		/* Javascript utilities */
		// Helper function to determine if the numer is even or odd. This is used to create alternating row colors.
		function isOdd(num) {
			return num % 2;
		}
		
		// Dom utilities
		/* This function appends a value to a specified element in the DOM. Delimiter is optional and defaults to a comma */
		function appendValueToElement(value,elementId,delimiter){
			// Written by Gregory Alexander
			// The delimiter is optional and defaults to a comma
			if (delimiter == null){
				var delimiter = ",";
			}
			
			// Get the element
			el = $("#" + elementId);
			// Does the value contain anything?
			if (el.val().length > 0){
				// Append the new value to the existing form
				el.val(el.val() + delimiter + value);
			} else { 
				// Insert the value into the empty form
				el.val(value);
			}
		}
		
		// String utilities
		/* 
		Generic remove function using jQuery. This is the fastest and cleanest approach that I have found and I don't have to use regex. It will remove content between tags (<postData>), elements using an ID, and classes if you use a '.' to prefix the class name.
		Usage to remove our postData tag that indicates that LD+Json is being used: removeStr(value, "postData") 
		Usage to remove the 'foo' class from a string: removeStrBetween(str, '.foo');
		*/
		var removeStrBetween = function(str, selector) {
			// Create a new container to operate on
			var wrapped = $("<div>" + str + "</div>");
			// Remove the content between the tags.
			wrapped.find(selector).remove();
			// Return it
			return wrapped.html();
		}
		
		// Function to truncate and add an elipsis if the text exceeds a certain value
		function truncateWithEllipses(text, max) {
			return text.substr(0,max-1)+(text.length>max?'...':''); 
		}

		function stripHtml(html){
			html.replace(/<[^>]*>?/gm, '');
			return html;
		}
		
		// Determine if a string has a space 
		function hasWhiteSpace(s) {
			const whitespaceChars = [' ', '\t', '\n'];
			return whitespaceChars.some(char => s.includes(char));
		}
		
		// ColdFusion like string functions
		
		// ReplaceNoCase, scope is either 'all' or 'one'. 
		// Gregory Alexander <www.gregoryalexander.com>
		function replaceNoCase(string,subString,replacement, scope){
			if (scope == 'all'){
				// i is a RegEx ignore case flag, g is global flag
				var regEx = new RegExp(subString, "ig");
			} else {
				// i is an RegEx ignore case flag
				var regEx = new RegExp(subString, "i");
			}
			// i is an ignore case flag, g is global flag
			var regEx = new RegExp(subString, "ig");
			var result = string.replace(regEx, replacement);
			return result;
		}

		// ColdFusion like list functions

		function listLen(list, delimiter){
			// Gregory Alexander <www.gregoryalexander.com>
			if(delimiter == null) { delimiter = ','; }
			var thisLen = list.split(delimiter);
			return thisLen.length;
		}
		
		function listGetAt(list, position, delimiter, zeroIndex) {
			// Gregory Alexander <www.gregoryalexander.com>
			if(delimiter == null) { delimiter = ','; }
			if(zeroIndex == null) { zeroIndex = true; }
			list = list.split(delimiter);
			if(list.length > position) {
				if(zeroIndex){
					// Better handling for JavaScript arrays
					return list[position];
				} else {
					// Handles like the CF version without a zero-index
					return list[position-1];
				}
			} else {
				return 0;
			}
		}

		function listFind(list, value, delimiter) {
			// Adapted from a variety of sources by Gregory Alexander <www.gregoryalexander.com>
			var result = 0;
			if(delimiter == null) delimiter = ',';
			list = list.split(delimiter);
			for ( var i = 0; i < list.length; i++ ) {
				if ( value == list[i] ) {
					result = i + 1;
					return result;
				}
			}
			return result;
		}
		
		// Compares two lists of comma seperated strings. Used to determine if the selected capabilities match the default capabilities for a given role. Function based on the listCompare method found in cflib.
		function listCompare(string1, string2){
			// Adapted from a variety of sources by Gregory Alexander <www.gregoryalexander.com>
			var s = string1.split(",");
			for(var k = 0 ;k < s.length; k++){
				if(string2.indexOf("," + s[k] + ",") ){ 
				  return true;
				}
			}
			return false;
		}
		
		// Adds a value to a comma separated list. Will not add the value if the list already contains the value.
		function listAppend(list, value) {
		  // Adapted from a variety of sources by Gregory Alexander <www.gregoryalexander.com>
		  var re = new RegExp('(^|\\b)' + value + '(\\b|$)');
		  if (!re.test(list)) {
			return list + (list.length? ',' : '') + value;
		  }
		  return list;
		}
		
		// Removes a value to a comma separated list. Based on the ListDeleteValue function by Ben Nadel CF fuction https://gist.github.com/bennadel/9753040
		var listDeleteValue = function(list, value){
			// Adapted from a variety of sources by Gregory Alexander <www.gregoryalexander.com>
			var values = list.split(",");
			for(var i = 0 ; i < values.length ; i++) {
				if (values[i] == value) {
					values.splice(i, 1);
					return values.join(",");
				}
			}
			return list;
		}
		
		// URL functions
		
		// 
		// parseUri 1.2.2
		// (c) Steven Levithan <stevenlevithan.com>
		// MIT License
		/*
		Splits any well-formed URI into the following parts (all are optional):
		----------------------
		- source (since the exec method returns the entire match as key 0, we might as well use it)
		- protocol (i.e., scheme)
		- authority (includes both the domain and port)
		  - domain (i.e., host; can be an IP address)
		  - port
		- path (includes both the directory path and filename)
		  - directoryPath (supports directories with periods, and without a trailing backslash)
		  - fileName
		- query (does not include the leading question mark)
		- anchor (i.e., fragment) */

		function parseUri (str) {
			var	o   = parseUri.options,
				m   = o.parser[o.strictMode ? "strict" : "loose"].exec(str),
				uri = {},
				i   = 14;

			while (i--) uri[o.key[i]] = m[i] || "";

			uri[o.q.name] = {};
			uri[o.key[12]].replace(o.q.parser, function ($0, $1, $2) {
				if ($1) uri[o.q.name][$1] = $2;
			});

			return uri;
		};

		parseUri.options = {
			strictMode: false,
			key: ["source","protocol","authority","userInfo","user","password","host","port","relative","path","directory","file","query","anchor"],
			q:   {
				name:   "queryKey",
				parser: /(?:^|&)([^&=]*)=?([^&]*)/g
			},
			parser: {
				strict: /^(?:([^:\/?#]+):)?(?:\/\/((?:(([^:@]*)(?::([^:@]*))?)?@)?([^:\/?#]*)(?::(\d*))?))?((((?:[^?#\/]*\/)*)([^?#]*))(?:\?([^#]*))?(?:#(.*))?)/,
				loose:  /^(?:(?![^:@]+:[^:@\/]*@)([^:\/?#.]+):)?(?:\/\/)?((?:(([^:@]*)(?::([^:@]*))?)?@)?([^:\/?#]*)(?::(\d*))?)(((\/(?:[^?#](?![^?#\/]*\.[^?#\/.]+(?:[?#]|$)))*\/?)?([^?#\/]*))(?:\?([^#]*))?(?:#(.*))?)/
			}
		};
		
		// Dump function. Use like you would with cfdump.
	
		// function to dump out a a javascript object.
		function mydump(arr,level) {
			var dumped_text = "";
			if(!level) level = 0;

			var level_padding = "";
			for(var j=0;j<level+1;j++) level_padding += "    ";

			if(typeof(arr) == 'object') {  
				for(var item in arr) {
					var value = arr[item];

					if(typeof(value) == 'object') { 
						dumped_text += level_padding + "'" + item + "' ...\n";
						dumped_text += mydump(value,level+1);
					} else {
						dumped_text += level_padding + "'" + item + "' => \"" + value + "\"\n";
					}
				}
			} else { 
				dumped_text = "===>"+arr+"<===("+typeof(arr)+")";
			}
			console.log(dumped_text);
		}
		
	</script>