<html>
<cfsilent>
<!--- Debug flag. This will print the interfaceId along with the args send via the URL --->
<cfset debug = false>

<!--- Generate the session Cross-Site Request Forgery (CSRF) token. This will be validated on the server prior to the login logic for security. --->
<!--- The forceNew argument does not work for versions less than 2018, however, CF2021 needs this argument or the token will change every time causing errors. Note: while the forceNew argument was not introduced until 2018, having csrfGenerateToken on the page with a forceNew argument will cause an error with 2016, even if you put it in a catch block or have two logical branches depending upon the version. --->
<cfset csrfToken = csrfGenerateToken("admin", false)><!---forceNew=false--->

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

<!--- Clear CF Caching --->
<cfcache action="flush"></cfcache>
	
<!--- Note:  --->
<!--- Include tinymce. --->
<!--- TinyMce notes: the tinymce scripts may be also placed in the head tag on the /admin/index.cfm page. 
If I place the tinymce scripts here, the setContent method does not work and the editors are not kept in memory. Nor can I get the content of the editor. This is also the case if the scripts are included here and on the index.cfm page. If I don't  place them here and keep the script in the head of the index page, the editors are preserved in memory, I can get the content and use the setContent method as well- but the editors disappear after the first use. --->
</cfsilent>
<cfif debug>
	<cfdump var="#application.blog.getThemeFonts(4)#">
	<cfinvoke component="#application.proxyControllerComponentPath#" method="verifyCsrfToken" returnvariable="validCsrf">
		<cfinvokeargument name="csrfToken" value="#csrfToken#">	
	</cfinvoke>
	Debugging:<br/>
	<!---<cfdump var="#session#">--->
	<!---<cfdump var="#cgi#">--->
	<cfoutput>
	adminInterfaceId: #adminInterfaceId# 
	URL.optArgs: #URL.optArgs# 
	<cfif isDefined("URL.otherArgs")> URL.otherArgs:  #URL.otherArgs#</cfif>
	<cfif isDefined("URL.otherArgs1")> URL.otherArgs1: #URL.otherArgs1#</cfif><br/>
	
	csrfToken: #csrfToken#<br/>
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

<cfswitch expression="#adminInterfaceId#">
	
<!---//***********************************************************************************************
						Login
//************************************************************************************************--->
	
<cfcase value="0">
	<form id="ajaxLogin" name="ajaxLogin">
	<!--- Pass the csrfToken --->
	<input type="hidden" name="csrfToken" id="csrfToken" value="<cfoutput>#csrfToken#</cfoutput>" />
	<table align="center" class="k-content tableBorder" width="95%" cellpadding="5" cellspacing="0">
	<cfif session.isMobile>
	  <tr>
		<td align="left" valign="top" class="border k-alt"></td>
	  </tr>
	  <tr valign="middle" height="35">
		<td align="left" valign="middle" class="k-alt">
			<label for="userName">User Name</label>
		</td>
	  <tr>
		<td align="left" class="k-alt">
			<input type="text" id="userName" name="userName" value="" class="k-textbox" required style="width: 100%" />   
		</td>
	  </tr>
	  <tr valign="middle" height="35">
		<td valign="middle" class="k-alt">
			<label for="password">Password</label>
		</td>
	  </tr>
	  <tr>
		<td align="left" class="k-alt">
			<input type="password" id="password" name="password" value="" class="k-textbox" style="width: 95%" />   
		</td>
	  </tr>
	  <tr>
		<td align="left" valign="top" class="border"></td>
	  </tr>
	  <tr valign="middle">
		<td height="25" valign="bottom" align="left">
			<button id="loginButton" name="loginButton" class="k-button k-primary" type="button">Submit</button>
		</td>
	  </tr>
	<!--- Desktop --->
	<cfelse>
	  <tr>
		<td align="left" valign="top" class="border k-alt" colspan="2"></td>
	  </tr>
	  <tr valign="middle" height="35">
		<td align="right" valign="middle" class="k-alt" style="width: 25%">
			<label for="userName">User Name</label>
		</td>
		<td align="left" class="k-alt" style="width: 75%">
			<input type="text" id="userName" name="userName" value="" class="k-textbox" style="width: 50%" />   
		</td>
	  <tr>
	  </tr>
	  <tr valign="middle" height="35">
		<td valign="middle" align="right" class="k-alt" >
			<label for="post">Password</label>
		</td>
		<td align="left" class="k-alt">
			<input type="password" id="password" name="password" value="" class="k-textbox" style="width: 50%" />   
		</td>
	  </tr>
	  <tr>
		<td align="left" valign="top" class="border" colspan="2"></td>
	  </tr>
	  <tr valign="middle">
		<td></td>
		<td height="25" valign="bottom" align="left">
			<button id="loginButton" name="loginButton" class="k-button k-primary" type="button">Submit</button>
		</td>
	  </tr>
	</cfif><!---<cfif session.isMobile>--->
	</table>
	</form>
	
	<script>
		$(document).ready(function() {
			// !!! Note on the validators, all forms need a name attribute, otherwise the positioning of the messages will not work. --->
			var ajaxLoginValidater = $("#ajaxLogin").kendoValidator({
				// Set up custom validation rules 
				rules: {
					// userName
					userName:
					function(input){
						if (input.is("[id='userName']") && $.trim(input.val()).length < 5){
							// Display an error on the page.
							input.attr("data-userNameRequired-msg", "The user name must be at least 5 characters");
							// Focus on the current element
							$( "#userName" ).focus();
							return false;
						}                                    
						return true;
					},
					// password
					password:
					function(input){
						if (input.is("[id='password']") && $.trim(input.val()).length < 5){
							// Display an error on the page.
							input.attr("data-userNameRequired-msg", "The password must be at least 7 characters");
							// Focus on the current element
							$( "#password" ).focus();
							return false;
						}                                    
						return true;
					},
				}
			}).data("kendoValidator");
		
			// Invoked when the submit button is clicked. Insted of using '$("form").submit(function(event) {' and 'event.preventDefault();', We are using direct binding here to speed up the event.
			var ajaxLoginSubmit = $('#loginButton');
			ajaxLoginSubmit.on('click', function(e){      
                e.preventDefault();         
				if (ajaxLoginValidater.validate()) {
					// submit the form.
					// Note: when testing the ui validator, comment out the post line below. It will only validate and not actually do anything when you post.
					postCredentials();
				} else {
					$.when(kendo.ui.ExtAlertDialog.show({ title: "There are errors", width: "<cfoutput>#application.kendoExtendedUiWindowWidth#</cfoutput>", message: "Required fields are missing.", icon: "k-ext-warning" }) // or k-ext-error, k-ext-question
						).done(function () {
						// Do nothing
					});
				}
			});
		});//...document.ready
		
		// Post method on the detail form called from the GalleryDetailFormValidator method on the detail page. The action variable will either be 'update' or 'insert'.
		function postCredentials(){
			jQuery.ajax({
				type: 'post', 
				url: '<cfoutput>#application.baseUrl#</cfoutput>/common/cfc/ProxyController.cfc?method=ajaxLogin',
				// Serialize the ajaxLogin form. The csrfToken is in the form.
				data: $('#ajaxLogin').serialize(),
				dataType: "json",
				success: credentailsResponse, // calls the result function.
				error: function(ErrorMsg) {
					console.log('Error' + ErrorMsg);
				}
			// Extract any errors. This is a new jQuery promise based function as of jQuery 1.8.
			}).fail(function (jqXHR, textStatus, error) {

				// The full response is: jqXHR.responseText, but we just want to extract the error.
				$.when(kendo.ui.ExtAlertDialog.show({ title: "Error while consuming the ajaxLogin function", message: error, icon: "k-ext-error", width: "<cfoutput>#application.kendoExtendedUiWindowWidth#</cfoutput>" }) // or k-ext-error, k-ext-information, k-ext-question, k-ext-warning.  You can also specify height.
					).done(function () {
					// Do nothing
				});		
			});
		};
		
		function credentailsResponse(response){
			// Are the credentials correct?
			if (JSON.parse(response) == true){
				// Close the login window
				jQuery('#loginWindow').kendoWindow('destroy');	
			} else {
				// Alert the user that the login has failed.
				$.when(kendo.ui.ExtAlertDialog.show({ title: "Login Failed", message: "Please try again", width: "<cfoutput>#application.kendoExtendedUiWindowWidth#</cfoutput>", icon: "k-ext-warning" }) // or k-ext-error, k-ext-question
				).done(function () {
					// Do nothing
				});
				// Refresh the Kendo window
				$("#login").kendoWindow({
					refresh: function() {
						// Do nothing	
					}//...refresh
				});//...$("#login").kendoWindow({
			}
		}//..if (response){
		
	</script>
	
</cfcase>
	
<!---//***********************************************************************************************
						Comments Grid
//************************************************************************************************--->
	
<cfcase value="1">
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
			
<cfcase value="2">
	
	<!--- Get the comment --->
	<cfset getComment = application.blog.getComment(URL.optArgs)>
	<!---<cfdump var="#getComment#">--->		
	
	<!---********************* Comment Detail editor *********************--->
	<!--- Set the common vars for tinymce. --->
	<cfsilent>
	<!---	We are using a new identifier every time in order to get the editors to work (see notes in other areas) and we are using cookies to store the last selector name and to eliminate stale editors and clean up the editor list --->
	<cfset selectorId = "commentEditor">
	<cfset editorHeight = "300">
	<cfset imageHandlerUrl = application.baseUrl & "/common/cfc/ProxyController.cfc?method=uploadImage&mediaProcessType=comment&mediaType=image&postId=" & getComment[1]['PostId'] & "&commentId=" & URL.optArgs & "&selectorId=" & selectorId & "&csrfToken=" & csrfToken>
	<cfset contentVar = getComment[1]["Comment"]>
	<cfset imageMediaIdField = "imageMediaId">
	<cfset imageClass = "entryImage">

	<cfif session.isMobile>
		<cfset toolbarString = "undo redo | bold italic | link | image media fancyBoxGallery">
	<cfelse>
		<cfset toolbarString = "insertfile undo redo | styleselect | bold italic | alignleft aligncenter alignright alignjustify | bullist numlist outdent indent | link | image editimage | media | fancyBoxGallery | map mapRouting">
	</cfif>
	<cfset includeGallery = true>
	</cfsilent>
	<!--- Include the tinymce js template --->
	<cfinclude template="#application.baseUrl#/includes/templates/js/tinyMce.cfm">
		
	<form id="commentDetails" data-role="validator">
	  <!--- Pass the csrfToken --->
	  <input type="hidden" name="csrfToken" id="csrfToken" value="<cfoutput>#csrfToken#</cfoutput>" />
	  <input type="hidden" name="postId" id="postId" value="<cfoutput>#getComment[1]['PostId']#</cfoutput>" />
	  <input type="hidden" name="commentId" id="commentId" value="<cfoutput>#URL.optArgs#</cfoutput>" />
	  <input type="hidden" name="imageMediaId" id="imageMediaId" value="" />
<cfsilent>		
<!--- //************************************************************************************************
		Mobile comment details
//**************************************************************************************************--->
</cfsilent>
<cfif session.isMobile>
		<table align="center" class="k-content tableBorder" width="95%" cellpadding="5" cellspacing="0">
		  <tr>
			<td align="left" valign="top" colspan="2" class="border k-alt"></td>
		  </tr>
		  <tr valign="middle">
			<td align="left" valign="middle" class="k-alt">
				<label for="post">Post</label>
			</td>
		  </tr>
		  <tr>
			<td align="left" class="k-alt">
				<input type="text" id="post" name="post" value="<cfoutput>#getComment[1]['PostTitle']#</cfoutput>" class="k-textbox" style="width: 100%" disabled />   
			</td>
		  </tr>
		  <tr>
			<td align="left" valign="top" class="border"></td>
		  </tr>
		  <tr>
			<td> 
				<label for="commentPosted">Date Posted</label>
			</td>
		  </tr>
		  <tr>
			<td>
				<input type="text" id="commentPosted" name="commentPosted" value="<cfoutput>#dateTimeFormat(getComment[1]['DatePosted'], "medium")#</cfoutput>" class="k-textbox" style="width: 95%" disabled/>    
			</td>
		  </tr>
		  <tr>
			<td align="left" valign="top" class="border k-alt"></td>
		  </tr>
		  <tr valign="middle">
			<td valign="middle" class="k-alt">
				<label for="commenter">Commenter</label>
			</td>
		  </tr>
		  <tr>
			<td align="left" class="k-alt">
				<input type="text" id="commenter" name="commenter" value="<cfoutput>#getComment[1]['CommenterFullName']#</cfoutput>" class="k-textbox" style="width: 100%" required />   
			</td>
		  </tr>
		  <tr>
			<td align="left" valign="top" class="border"></td>
		  </tr>
		  <tr valign="middle">
			<td valign="middle">
				<label for="commenterEmail">Email</label>
			</td>
		  </tr>
		  <tr>
			<td align="left">
				<input type="email" id="commenterEmail" name="commenterEmail" value="<cfoutput>#getComment[1]['CommenterEmail']#</cfoutput>" class="k-textbox" style="width: 100%" placeholder="e.g. myname@example.net" required data-email-msg="Email is not valid" />   
			</td>
		  </tr>
		  <tr>
			<td align="left" valign="top" class="border k-alt"></td>
		  </tr>
		  <tr valign="middle">
			<td valign="middle" class="k-alt">
				<label for="commenterWebsite">Website</label>
			</td>
		  </tr>
		  <tr>
			<td class="k-alt">
				<input type="url" id="commenterWebsite" name="commenterWebsite" value="<cfoutput>#getComment[1]['CommenterWebsite']#</cfoutput>" class="k-textbox" style="width: 100%" />
			</td>
		  </tr>
		  <tr>
			<td align="left" valign="top" class="border"></td>
		  </tr>
		  <tr valign="middle">
			<td valign="middle">
				<label for="<cfoutput>#selectorName#</cfoutput>">Comment</label>
			</td>
		  </tr>
		  <tr>
			<td align="left"> 
				<input type="text" id="<cfoutput>#selectorName#</cfoutput>" name="<cfoutput>#selectorName#</cfoutput>" style="width:95%" /> 
			</td>
		  </tr>
		  <tr>
			<td align="left" valign="top" class="border k-alt"></td>
		  </tr>
		  <tr>
			<td align="right" class="k-alt">
				<table align="center" class="k-alt" width="100%" cellpadding="5" cellspacing="0">
					<tr>
						<td width="33%" align="left">
							<cfsilent>
								<!--- This field may not be defined (it may be null in the database) --->
								<cfif structKeyExists(getComment[1], "Approved" )>
									<cfset approved = getComment[1]["Approved"]>
								<cfelse>
									<cfset approved = 0>
								</cfif>
							</cfsilent>
							<input id="approved" name="approved" type="checkbox" <cfif approved>checked</cfif>>
							<label for="approved">Approved</label>
						</td>
						<td width="33%" align="left">
							<cfsilent>
								<!--- This field may not be defined (it may be null in the database) --->
								<cfif structKeyExists(getComment[1], "Remove")>
									<cfset remove = getComment[1]["Remove"]>
								<cfelse>
									<cfset remove = 0>
								</cfif>
							</cfsilent>
							<input id="remove" name="remove" type="checkbox" <cfif remove>checked</cfif>>
							<label for="remove">Remove</label>
						</td>
						<td width="33%" align="left">
							<cfsilent>
								<!--- This field may not be defined (it may be null in the database) --->
								<cfif structKeyExists(getComment[1], "Spam" )>
									<cfset spam = getComment[1]["Spam"]>
								<cfelse>
									<cfset spam = 0>
								</cfif>
							</cfsilent>
							<input id="spam" name="spam" type="checkbox" <cfif spam>checked</cfif>>
							<label for="spam">Spam</label>
						</td>
					</tr>
					<tr>
						<td width="33%" align="left">
							<cfsilent>
							<!--- This field may not be defined (it may be null in the database) --->
							<cfif structKeyExists(getComment[1], "Spam" )>
								<cfset subscribe = getComment[1]["Spam"]>
							<cfelse>
								<cfset spam = 0>
							</cfif>
							</cfsilent>
						<input id="subscribe" name="subscribe" type="checkbox" <cfif subscribe>checked</cfif>>
						<label for="subscribe">Subscribed</label>
						</td>
						<td width="33%" align="left">
							<cfsilent>
							<!--- This field may not be defined (it may be null in the database) --->
							<cfif structKeyExists(getComment[1], "Moderated" )>
								<cfset moderated = getComment[1]["Moderated"]>
							<cfelse>
								<cfset moderated = 0>
							</cfif>
							</cfsilent>
						<input id="moderated" name="moderated" type="checkbox" <cfif moderated>checked</cfif>>
						<label for="moderated">Moderated</label>
						</td>
						<td></td>
					</tr>
				</table>
			</td>
		  </tr>
		  <tr>
			<td align="left" valign="top" class="border"></td>
		  </tr>
		  <tr valign="middle">
			<td height="25" valign="bottom" align="left">
				<button id="commentDetailSubmit" class="k-button k-primary" type="button">Submit</button>
			</td>
		  </tr>
		</table>
<cfelse>
<!--- //************************************************************************************************
		Desktop comment details
//**************************************************************************************************--->
		<table align="center" class="k-content tableBorder" width="95%" cellpadding="5" cellspacing="0">
		  <tr>
			<td align="left" valign="top" colspan="2" class="border k-alt"></td>
		  </tr>
		  <tr valign="middle" height="35">
			<td align="right" valign="middle" width="10%" class="k-alt">
			<label for="post">Post</label>
			</td>
			<td align="left" width="90%" class="k-alt">
				<input type="text" id="post" name="post" value="<cfoutput>#getComment[1]['PostTitle']#</cfoutput>" class="k-textbox" style="width: 66%" disabled />   
			</td>
		  </tr>
		  <tr>
			<td align="left" valign="top" colspan="2" class="border"></td>
		  </tr>
		  <tr>
			<td align="right"> 
			<label for="commentPosted">Date Posted</label>
			</td>
			<td>
			<input type="text" id="commentPosted" name="commentPosted" value="<cfoutput>#dateTimeFormat(getComment[1]['DatePosted'], "medium")#</cfoutput>" class="k-textbox" style="width: 45%" disabled/>    
			</td>
		  </tr>
		  <tr>
			<td align="left" valign="top" colspan="2" class="border k-alt"></td>
		  </tr>
		  <tr valign="middle" height="35">
			<td align="right" valign="middle" width="10%" class="k-alt">
			<label for="commenter">Commenter</label>
			</td>
			<td align="left" width="90%" class="k-alt">
				<input type="text" id="commenter" name="commenter" value="<cfoutput>#getComment[1]['CommenterFullName']#</cfoutput>" class="k-textbox" style="width: 66%" required />   
			</td>
		  </tr>
		  <tr>
			<td align="left" valign="top" colspan="2" class="border"></td>
		  </tr>
		  <tr valign="middle" height="35">
			<td align="right" valign="middle" width="10%">
			<label for="commenterEmail">Email</label>
			</td>
			<td align="left" width="90%">
				<input type="email" id="commenterEmail" name="commenterEmail" value="<cfoutput>#getComment[1]['CommenterEmail']#</cfoutput>" class="k-textbox" style="width: 66%" placeholder="e.g. myname@example.net" required data-email-msg="Email is not valid" />   
			</td>
		  </tr>
		  <tr>
			<td align="left" valign="top" colspan="2" class="border k-alt"></td>
		  </tr>
		  <tr valign="middle" height="35">
			<td align="right" valign="middle" width="10%" class="k-alt">
			<label for="commenterWebsite">Website</label>
			</td>
			<td align="left" width="90%" class="k-alt">
				<input type="url" id="commenterWebsite" name="commenterWebsite" value="<cfoutput>#getComment[1]['CommenterWebsite']#</cfoutput>" class="k-textbox" style="width: 66%" />
			</td>
		  </tr>
		  <tr>
			<td align="left" valign="top" colspan="2" class="border"></td>
		  </tr>
		  <!--- Preview --->
		  <tr>
			<td align="right"><div id="dynamicGalleryLabel"></div></td>
			<td><div id="dynamicGalleryInputFields" name="dynamicGalleryInputFields"></div></td>
		  </tr>
		  <tr valign="middle">
			<td align="right" valign="middle" height="35">
				<label for="<cfoutput>#selectorName#</cfoutput>">Comment</label>
			</td>
			<td align="left"> 
				<input type="text" id="<cfoutput>#selectorName#</cfoutput>" name="<cfoutput>#selectorName#</cfoutput>" style="width:95%" />  
			</td>
		  </tr>
		  <tr>
			<td align="left" valign="top" colspan="2" class="border k-alt"></td>
		  </tr>
		  <tr>
			<td align="right" class="k-alt" colspan="2">
				<table align="center" class="k-alt" width="100%" cellpadding="5" cellspacing="0">
					<tr>
						<td width="20%" align="left">
							<label for="approved">Approved</label>
							<cfsilent>
								<!--- This field may not be defined (it may be null in the database) --->
								<cfif structKeyExists(getComment[1], "Approved" )>
									<cfset approved = getComment[1]["Approved"]>
								<cfelse>
									<cfset approved = 0>
								</cfif>
							</cfsilent>
							<input id="approved" name="approved" type="checkbox" <cfif approved>checked</cfif>>
						</td>
						<td width="20%" align="left">
							<label for="remove">Remove</label>
							<cfsilent>
								<!--- This field may not be defined (it may be null in the database) --->
								<cfif structKeyExists(getComment[1], "Remove")>
									<cfset remove = getComment[1]["Remove"]>
								<cfelse>
									<cfset remove = 0>
								</cfif>
							</cfsilent>
							<input id="remove" name="remove" type="checkbox" <cfif remove>checked</cfif>>
						</td>
						<td width="20%" align="left">
							<label for="spam">Spam</label>
							<cfsilent>
								<!--- This field may not be defined (it may be null in the database) --->
								<cfif structKeyExists(getComment[1], "Spam" )>
									<cfset spam = getComment[1]["Spam"]>
								<cfelse>
									<cfset spam = 0>
								</cfif>
							</cfsilent>
							<input id="spam" name="spam" type="checkbox" <cfif spam>checked</cfif>>
						</td>
						<td width="20%" align="left">
							<label for="subscribe">Subscribed</label>
							<cfsilent>
							<!--- This field may not be defined (it may be null in the database) --->
							<cfif structKeyExists(getComment[1], "Subscribe" )>
								<cfset subscribe = getComment[1]["Subscribe"]>
							<cfelse>
								<cfset spam = 0>
							</cfif>
							</cfsilent>
						<input id="subscribe" name="subscribe" type="checkbox" <cfif subscribe>checked</cfif>>	
						</td>
						<td width="20%" align="left">
							<label for="subscribe">Moderated</label>
							<cfsilent>
							<!--- This field may not be defined (it may be null in the database) --->
							<cfif structKeyExists(getComment[1], "Moderated" )>
								<cfset moderated = getComment[1]["Moderated"]>
							<cfelse>
								<cfset moderated = 0>
							</cfif>
							</cfsilent>
						<input id="moderated" name="moderated" type="checkbox" <cfif moderated>checked</cfif>>	
						</td>
					</tr>
				</table>
			</td>
		  </tr>
		  <tr>
			<td align="left" valign="top" colspan="2" class="border"></td>
		  </tr>
		  <tr valign="middle">
			<td height="25" valign="bottom" align="right">&nbsp;</td>
			<td height="25" valign="bottom" align="left">
				<button id="commentDetailSubmit" class="k-button k-primary" type="button">Submit</button>
			</td>
		  </tr>
		</table>
	</cfif>
	</form>
					
	<script>
		$(document).ready(function() {
		
			// !!! Note on the validators, all forms need a name attribute, otherwise the positioning of the messages will not work. --->
			var commentDetailFormValidator = $("#commentDetails").kendoValidator({
				// Set up custom validation rules 
				rules: {
					// Commenter
					commenterRequired:
					function(input){
						if (input.is("[id='commenter']") && $.trim(input.val()).length < 7){
							// Display an error on the page.
							input.attr("data-commenterRequired-msg", "The commenter field must be at least 7 characters");
							// Focus on the current element
							$( "#commenter" ).focus();
							return false;
						}                                    
						return true;
					},
					commenterIsNumeric:
					function(input){
						if (input.is("[id='commenter']") && $.isNumeric(input.val())){
							// Display an error on the page.
							input.attr("data-commenterIsNumeric-msg", "The commenter may not be numeric");
							// Focus on the current element
							$( "#commenter" ).focus();
							return false;
						}                                    
						return true;
					},
					// Email
					commenterEmailRequired:
					function(input){
						if (input.is("[id='commenterEmail']") && $.trim(input.val()).length == ''){
							// Display an error on the page.
							input.attr("data-commenterEmailRequired-msg", "Required.");
							// Focus on the current element
							$( "#commenterEmail" ).focus();
							return false;
						}                                    
						return true;
					}
				}
			}).data("kendoValidator");
		
			// Invoked when the submit button is clicked. Instead of using '$("form").submit(function(event) {' and 'event.preventDefault();', we are using direct binding here to speed up the event.
			var commentDetailSubmit = $('#commentDetailSubmit');
			commentDetailSubmit.on('click', function(e){      
                e.preventDefault();         
				if (commentDetailFormValidator.validate()) {
					
					if ( ($('#spam').is(':checked')) ) {
						// Raise a warning if the user chose to remove or make something as spam
						// Note: this is a custom library that I am using. The ExtAlertDialog is not a part of Kendo but an extension.
						$.when(kendo.ui.ExtYesNoDialog.show({ 
							title: "Mark as spam?",
							message: "Are you sure? This will remove every comment by this user and mark the IP address as spam.",
							icon: "k-ext-warning",
							width: "<cfoutput>#application.kendoExtendedUiWindowWidth#</cfoutput>", 
							height: "215px"
						})
						).done(function (response) { // If the user clicked 'yes', post it.
							if (response['button'] == 'Yes'){// remember that js is case sensitive.
								// Post it
								postCommentDetails('update');
							}//..if (response['button'] == 'Yes'){
						});
					} else if ( ($('#remove').is(':checked')) ) {
						// Raise a warning if the user chose to remove or make something as spam
						// Note: this is a custom library that I am using. The ExtAlertDialog is not a part of Kendo but an extension.
						$.when(kendo.ui.ExtYesNoDialog.show({ 
							title: "Remove post?",
							message: "Are you sure? This will delete this comment.",
							icon: "k-ext-warning",
							width: "<cfoutput>#application.kendoExtendedUiWindowWidth#</cfoutput>", 
							height: "215px"
						})
						).done(function (response) { // If the user clicked 'yes', post it.
							if (response['button'] == 'Yes'){// remember that js is case sensitive.
								// Post it
								postCommentDetails('update');
							}//..if (response['button'] == 'Yes'){
						});
					} else {//..if ( ($('#spam').is(':checked')) || ($('#remove').is(':checked')) ){
						// submit the form.
						// Note: when testing the ui validator, comment out the post line below. It will only validate and not actually do anything when you post.
						// alert('posting');
						postCommentDetails('update');
					}
				} else {
					$.when(kendo.ui.ExtAlertDialog.show({ title: "There are errors", message: "Required fields have not been filled out. Please correct the highlighted fields and try again", width: "<cfoutput>#application.kendoExtendedUiWindowWidth#</cfoutput>", icon: "k-ext-warning" }) // or k-ext-error, k-ext-question
						).done(function () {
						// Do nothing
					});
				}
			});
		});//...document.ready
		
		// Post method on the detail form called from the commentDetailFormValidator method on the detail page. The action variable will either be 'update' or 'insert'.
		function postCommentDetails(action){
			// Open up a please wait dialog
			$.when(kendo.ui.ExtWaitDialog.show({ title: "Please wait...", message: "Please wait while we process the comment.", icon: "k-ext-information" }));
			
			jQuery.ajax({
				type: 'post', 
				url: '<cfoutput>#application.baseUrl#</cfoutput>/common/cfc/ProxyController.cfc?method=saveComment',
				data: { // arguments
					// We are going to map the extact same arguments, in order, of the method in the cfc here. Notes: we can also use 'data: $("#deptDetails").serialize()' or use the stringify method to pass it as an array of values. 
					csrfToken: '<cfoutput>#csrfToken#</cfoutput>',
					action: action, // either update or insert.
					commentId: $("#commentId").val(),
					postId: $("#postId").val(),
					commenter: $("#commenter").val(),
					commenterEmail: $("#commenterEmail").val(),
					commenterWebsite:  $("#commenterWebsite").val(),
					commenterIp: '<cfoutput>#cgi.remote_addr#</cfoutput>',
					commenterHttpUserAgent: '<cfoutput>#cgi.http_user_agent#</cfoutput>',
					// Get the contents of the editor
					comment: tinymce.get("<cfoutput>#selectorName#</cfoutput>").getContent(),
					// Get the value of the checkboxes
					approved: $('#approved').is(':checked'), // checkbox boolean value.
					remove: $('#remove').is(':checked'), // checkbox boolean value.
					spam: $('#spam').is(':checked'), // checkbox boolean value.
					subscribe: $('#subscribe').is(':checked'), // checkbox boolean value.
					moderated: $('#moderated').is(':checked') // checkbox boolean value.
				},
				dataType: "json",
				success: commentUpdateResult, // calls the result function.
				error: function(ErrorMsg) {
					console.log('Error' + ErrorMsg);
				}
			// Extract any errors. This is a new jQuery promise based function as of jQuery 1.8.
			}).fail(function (jqXHR, textStatus, error) {
				// This is a secured function. Display the login screen.
				if (jqXHR.status === 403) { 
					createLoginWindow(); 
				} else {//...if (jqXHR.status === 403) { 
					// The full response is: jqXHR.responseText, but we just want to extract the error.
					$.when(kendo.ui.ExtAlertDialog.show({ title: "Error while consuming the saveComment function", message: error, icon: "k-ext-error", width: "<cfoutput>#application.kendoExtendedUiWindowWidth#</cfoutput>" }) // or k-ext-error, k-ext-information, k-ext-question, k-ext-warning.  You can also specify height.
						).done(function () {
						// Do nothing
					});
				}//...if (jqXHR.status === 403) { 
			});//...jQuery.ajax({
		};
		
		function commentUpdateResult(response){
			// Close the wait window that was launched in the calling function.
			kendo.ui.ExtWaitDialog.hide();
			// Refresh the <cfif application.kendoCommercial>kendo<cfelse>jsgrid</cfif> grid 
		<cfif application.kendoCommercial and 1 eq 2><!---We are not using the Kendo grids right now.--->
			$('#commentsGrid').data('kendoGrid').dataSource.read();
		<cfelse>
			// Refresh the entire comments window
			$("#recentCommentsGridWindow").data("kendoWindow").refresh();
		</cfif>
			// Close the detail window
			jQuery('#commentDetailWindow').kendoWindow('destroy');
		}
	</script>
</body>
		  
</cfcase>
			
<!--- //************************************************************************************************
		Photo Gallery
//**************************************************************************************************--->
			
<cfcase value="3">
	<cfsilent>
	<!--- Set the uppy theme. --->
	<cfif darkTheme>
		<cfset uppyTheme = 'dark'>
	<cfelse>
		<cfset uppyTheme = 'light'>
	</cfif>
		
	<!--- Not used yet- Get the kendo primay button color in order to reset the uppy actionBtn--upload color --->
	<cfset primaryButtonColor = application.blog.getPrimaryColorsByTheme(kendoTheme:kendoTheme,setting:'accentColor')>
	<!--- Set the selectorId so that we know what interface this request is coming from --->
	<cfset selectorId = "gallery">
	</cfsilent>
	<!---<cfoutput>primaryButtonColor: #primaryButtonColor#</cfoutput>--->
	<input type="hidden" name="mediaIdList" id="mediaIdList" value=""/>
    <div id="galleryUppyUpload"></div>
    <script>
		var uppy = Uppy.Core({
			restrictions : {
				maxNumberOfFiles: 12,  // limit 12 images
				allowedFileTypes: ['image/*'] // only allow images
        	}
		})
		.use(Uppy.Dashboard, {
			theme: '<cfoutput>#uppyTheme#</cfoutput>',
			inline: true,
			target: '#galleryUppyUpload',
			proudlyDisplayPoweredByUppy: false,
			metaFields: [
				{ id: 'mediaTitle', name: 'Title', placeholder: 'Please enter the image title' }
			]
		})
		// Allow users to take pictures via the onboard camera
		.use(Uppy.Webcam, { target: Uppy.Dashboard })
		// Use the built in image editor
		.use(Uppy.ImageEditor, { 
			target: Uppy.Dashboard,
			quality: 0.8 // for the resulting image, 0.8 is a sensible default
		})
		// Use XHR and send the media to the server for processing
		.use(Uppy.XHRUpload, { endpoint: '<cfoutput>#application.baseUrl#</cfoutput>/common/cfc/proxyController.cfc?method=uploadImage&mediaProcessType=gallery&selectorId=<cfoutput>#selectorId#</cfoutput>&csrfToken=<cfoutput>#csrfToken#</cfoutput>' })
		.on('upload-success', (file, response) => {
			// The server is returning location and mediaId in a json object. We need to extract these.
			//alert(response.status) // HTTP status code
			//alert(response.body.location) // The full path of the file that was just uploaded to the server
			//alert(response.body.mediaId) // The MediaId value saved to the Media table in the database.
			
			// Dump in the mediaId's to the hidden mediaId list and separate the values with underscores. We will use a listGetAt function on the back end to extract the mediaId's
			// If there are any mediaId's in the form, separtate the new Id with an underscore.
			mediaIdList = $("#mediaIdList").val();
			if ( mediaIdList.length > 0){
				newMediaIdList = mediaIdList + "_" + response.body.mediaId;
			} else {
				newMediaIdList = response.body.mediaId;
			}
			// Dump the list into the hidden form. This will get passed to the new media item window.
			$("#mediaIdList").val(newMediaIdList);
		})
		
		// Events
		// 1) When the dashboard icon is clicked
		// Note: there is no event when the dashboard my device button is clicked. This is a work-around. We are going to use jquery's on click event and put in the class of the button. This is required as the uppy button does not have an id.
		$(".uppy-Dashboard-input").on('click', function(event){
			$.when(kendo.ui.ExtWaitDialog.show({ title: "Please wait...", message: "Please wait for the file uploader interface to respond.", icon: "k-ext-information" }));
		});
		
		// 2) When a file has been uploaded to uppy
		uppy.on('file-added', (file) => {
		  	// Close the wait window that was launched in the calling function.
			kendo.ui.ExtWaitDialog.hide();
		})
		
		// 3) When the upload button was pressed
		uppy.on('upload', (data) => {
			$.when(kendo.ui.ExtWaitDialog.show({ title: "Please wait...", message: "Please wait while the images are uploaded.", icon: "k-ext-information" }));
		})
		
		// 4) Error handling
		uppy.on('upload-error', (file, error, response) => {
			// Alert the user
			$.when(kendo.ui.ExtYesNoDialog.show({ 
				title: "Upload failed",
				message: "The following error was encountered: " + error + ". Do you want to retry the upload?",
				icon: "k-ext-warning",
				width: "<cfoutput>#application.kendoExtendedUiWindowWidth#</cfoutput>", 
				height: "215px"
			})
			).done(function (response) { // If the user clicked 'yes', retry.
				if (response['button'] == 'Yes'){// remember that js is case sensitive.
					// Retry
					uppy.retryUpload(file.id);
				}//..if (response['button'] == 'Yes'){
			});	
		})

		// 5) When the upload is complete to the server
		uppy.on('complete', (result) => {

			// Close the please wait dialog
			// Use a quick set timeout in order for the data to load.
			setTimeout(function() {
				// Close the wait window that was launched in the calling function.
				kendo.ui.ExtWaitDialog.hide();
			}, 500);
			// Create a new window in order to put in the fancy box group and the item details (such as the image title)
			createAdminInterfaceWindow(4, $("#mediaIdList").val());
		})
	
    </script>

</cfcase>
	
<!--- //************************************************************************************************
		Gallery Items
//**************************************************************************************************--->
		
<cfcase value="4">
	<!---  Replace the underscore with a comma so that we can use it in the query below. --->
	<cfset mediaIdList = replaceNoCase(URL.optArgs, '_', ',', 'all')>
	
	<!--- Get the data from the db --->
	<cfquery name="getMediaUrl" dbtype="hql">
		SELECT new Map (
			MediaId as MediaId,
			MediaUrl as MediaUrl,
			MediaThumbnailUrl as MediaThumbnailUrl
		)
		FROM Media
		WHERE MediaId IN (<cfqueryparam value="#mediaIdList#" cfsqltype="integer" list="yes">)
	</cfquery>
	<!--- 
	Debugging:<br/>
	<cfoutput>mediaIdList: #mediaIdList#</cfoutput>
	<cfdump var="#getMediaUrl#"></cfdump>
	--->
		
	<h4>Please enter titles for each item in this gallery</h4>
	
	<form id="galleryDetail" name="galleryDetail" data-role="validator">
	<!--- Pass the csrfToken --->
	<input type="hidden" name="csrfToken" id="csrfToken" value="<cfoutput>#csrfToken#</cfoutput>" />
	<!--- Hidden input to pass the mediaIdList --->
	<input type="hidden" name="mediaIdList" id="mediaIdList" value="<cfoutput>#URL.optArgs#</cfoutput>">
	<!--- Store the number of galleries that were created by the user. We'll increment this for every gallery --->
	<input type="hidden" name="numGalleries" id="numGalleries" value="1">
	<table align="left" class="k-content tableBorder" width="100%" cellpadding="5" cellspacing="0">
	<cfif not arrayLen(getMediaUrl)>
		<tr>
			<td class="k-header">
			<cfoutput>There are no recent uploads.</cfoutput>
			</td>
		</tr>
	</cfif><!---<cfif not getMediaUrl.recordCount>--->
	<cfloop from="1" to="#arrayLen(getMediaUrl)#" index="i"><cfoutput>
		<cfsilent>
			<!--- Set the variable values. I want to shorten the long variable names here. --->
			<cfset mediaId = getMediaUrl[i]["MediaId"]>
			<cfset mediaUrl = getMediaUrl[i]["MediaUrl"]>
			<cfset mediaThumbnailUrl = getMediaUrl[i]["MediaThumbnailUrl"]>
			<!--- Get the thumbnail image if possible. When the blog is upgraded from version 1x, there will be no thumbnails. This is a new feature in v2. --->
			<cfif len(mediaThumbnailUrl)>
				<cfset imageUrl = mediaThumbnailUrl>
			<cfelse>
				<cfset imageUrl = mediaUrl>
			</cfif>
		</cfsilent>
		<!--- Pass along the imageUrl's in a hidden form  --->
		<input type="hidden" name="mediaUrl<cfoutput>#i#</cfoutput>" id="mediaUrl<cfoutput>#i#</cfoutput>" value="<cfoutput>#mediaUrl#</cfoutput>">
		<tr class="#iif(i MOD 2,DE('k-content'),DE('k-alt'))#" height="50px;">
	<cfsilent>		
	<!--- //************************************************************************************************
			Mobile Gallery Items
	//**************************************************************************************************--->
	</cfsilent>
	<cfif session.isMobile>
		<!--- Create alternating rows in the table. The Kendo classes which we will use are k-alt and k-content.
		We will create a border between the rows if the current row is not the first row. --->
		<cfif i eq 1>
			<td valign="top" width="90%">
		<cfelse>
			<td align="left" valign="top" class="border" width="90%">
		</cfif>
				<a class="fancybox-effects" href="<cfoutput>#imageUrl#</cfoutput>"><img data-src="<cfoutput>#imageUrl#</cfoutput>" alt="" class="fade thumbnail lazied shown" data-lazied="IMG" src="<cfoutput>#imageUrl#</cfoutput>"></a>
			</td>
		</tr>
		<tr>
			<td><label for="mediaItemTitle<cfoutput>#i#</cfoutput>">Title:</label></td>
		</tr>
		<tr>
			<td>
				<input type="text" name="mediaItemTitle<cfoutput>#i#</cfoutput>" id="mediaItemTitle<cfoutput>#i#</cfoutput>" value="" class="k-textbox" required style="width: 100%;">
			</td>
		</tr>
		<tr>
			<td class="border k-alt"><label for="mediaItemUrl<cfoutput>#i#</cfoutput>">URL Link:</label></td>
		</tr>
		<tr>
			<td class="k-alt"><input type="text" name="mediaItemUrl<cfoutput>#i#</cfoutput>" id="mediaItemUrl<cfoutput>#i#</cfoutput>" value="<cfoutput>#mediaUrl#</cfoutput>" class="k-textbox" style="width: 100%;"></td>
		</tr>
	<cfsilent>		
	<!--- //************************************************************************************************
			Desktop Gallery Items
	//**************************************************************************************************--->
	</cfsilent>
	<cfelse><!---<cfif session.isMobile>--->
		<!--- Create alternating rows in the table. The Kendo classes which we will use are k-alt and k-content.
		We will create a border between the rows if the current row is not the first row. --->
		<cfif i eq 1>
			<td valign="top" width="240px">
		<cfelse>
			<td align="left" valign="top" class="border" width="240px">
		</cfif>
			<a class="fancybox-effects" href="<cfoutput>#imageUrl#</cfoutput>"><img data-src="<cfoutput>#imageUrl#</cfoutput>" alt="" class="fade thumbnail lazied shown" data-lazied="IMG" src="<cfoutput>#imageUrl#</cfoutput>"></a>
		</td>
		<cfif i eq 1>
			<td valign="top">
		<cfelse>
			<td align="left" valign="top" class="border">
		</cfif>
				<table align="left" class="k-content" width="100%" cellpadding="5" cellspacing="0" border="2">
					<tr>
						<td><label for="mediaItemTitle<cfoutput>#i#</cfoutput>">Title:</label></td>
					</tr>
					<tr>
						<td>
							<input type="text" name="mediaItemTitle<cfoutput>#i#</cfoutput>" id="mediaItemTitle<cfoutput>#i#</cfoutput>" value="" class="k-textbox" required style="width: 100%;">
						</td>
					</tr>
					<tr>
						<td class="border k-alt"><label for="mediaItemUrl<cfoutput>#i#</cfoutput>">URL Link:</label></td>
					</tr>
					<tr>
						<td class="k-alt"><input type="text" name="mediaItemUrl<cfoutput>#i#</cfoutput>" id="mediaItemUrl<cfoutput>#i#</cfoutput>" value="<cfoutput>#mediaUrl#</cfoutput>" class="k-textbox" style="width: 100%;"></td>
					</tr>
				</table>
			</td>
		</tr>
	</cfif><!---<cfif session.isMobile>--->
	</cfoutput></cfloop>
		<tr>
		<!--- Create alternating rows in the table. The Kendo classes which we will use are k-alt and k-content.
		We will create a border between the rows if the current row is not the first row. --->
		<cfif i eq 1>
			<td valign="top" <cfif not session.isMobile>colspan="2"</cfif>>
		<cfelse>
			<td align="left" valign="top" <cfif not session.isMobile>colspan="2"</cfif>>
		</cfif>
				<button id="galleryDetailSubmit" class="k-button k-primary" type="button">Submit</button>
			</td>
		</tr>
	</table>
				
	</form>
				
	<script>
		$(document).ready(function() {
			// !!! Note on the validators, all forms need a name attribute, otherwise the positioning of the messages will not work. --->
			var GalleryDetailFormValidator = $("#galleryDetail").kendoValidator({
				// Set up custom validation rules 
				rules: {
				<cfloop from="1" to="#arrayLen(getMediaUrl)#" index="i">
					<cfsilent>
						<!--- Set the variable values. I want to shorten the long variable names here. --->
						<cfset mediaId = getMediaUrl[i]["MediaId"]>
					</cfsilent>
					// mediaTitle
					mediaItemTitle<cfoutput>#i#</cfoutput>:
					function(input){
						if (input.is("[id='mediaItemTitle<cfoutput>#i#</cfoutput>']") && $.trim(input.val()).length < 4){
							// Display an error on the page.
							input.attr("data-mediaItemTitle<cfoutput>#i#</cfoutput>Required-msg", "The title field must be at least 4 characters");
							// Focus on the current element
							$( "#mediaItemTitle<cfoutput>#i#</cfoutput>" ).focus();
							return false;
						}                                    
						return true;
					},
					</cfloop>
				}
			}).data("kendoValidator");
		
			// Invoked when the submit button is clicked. Insted of using '$("form").submit(function(event) {' and 'event.preventDefault();', We are using direct binding here to speed up the event.
			var galleryDetailSubmit = $('#galleryDetailSubmit');
			galleryDetailSubmit.on('click', function(e){      
                e.preventDefault();         
				if (GalleryDetailFormValidator.validate()) {
					// submit the form.
					// Note: when testing the ui validator, comment out the post line below. It will only validate and not actually do anything when you post.
					// alert('posting');
					postGalleryDetails('update');
				} else {
					$.when(kendo.ui.ExtAlertDialog.show({ title: "There are errors", message: "Required fields are missing.", width: "<cfoutput>#application.kendoExtendedUiWindowWidth#</cfoutput>", icon: "k-ext-warning" }) // or k-ext-error, k-ext-question
						).done(function () {
						// Do nothing
					});
				}
			});
		});//...document.ready
		
		// Post method on the detail form called from the GalleryDetailFormValidator method on the detail page. The action variable will either be 'update' or 'insert'.
		function postGalleryDetails(action){
			jQuery.ajax({
				type: 'post', 
				url: '<cfoutput>#application.baseUrl#</cfoutput>/common/cfc/ProxyController.cfc?method=saveGallery&selectorId=gallery&darkTheme=<cfoutput>#darkTheme#</cfoutput>&csrfToken=<cfoutput>#csrfToken#</cfoutput>',
				// Serialize the galleryDetail form. The csrfToken is in the form.
				data: $('#galleryDetail').serialize(),
				// This is one of the few times that we will be sending back an html response. We are going to use this directly to set the content in the editor. its easier to craft the html on the server side than to manipulate the dom with a json object on the client. Normally this is always json
				dataType: "html",
				success: galleryUpdateResult, // calls the result function.
				error: function(ErrorMsg) {
					console.log('Error' + ErrorMsg);
				}
			// Extract any errors. This is a new jQuery promise based function as of jQuery 1.8.
			}).fail(function (jqXHR, textStatus, error) {
				// This is a secured function. Display the login screen.
				if (jqXHR.status === 403) { 
					createLoginWindow(); 
				} else {//...if (jqXHR.status === 403) { 
					// The full response is: jqXHR.responseText, but we just want to extract the error.
					$.when(kendo.ui.ExtAlertDialog.show({ title: "Error while consuming the saveGallery function", message: error, icon: "k-ext-error", width: "<cfoutput>#application.kendoExtendedUiWindowWidth#</cfoutput>" }) // or k-ext-error, k-ext-information, k-ext-question, k-ext-warning.  You can also specify height.
						).done(function () {
					// Do nothing
					});		
				}//...if (jqXHR.status === 403) { 
			});
		};
		
		function galleryUpdateResult(response){
			// alert(response)
			// Note: the response is an html string 
			
			// Get the numGalleries value in the hidden form. It starts at 1. This is used to determine what id we should use in our hidden inputs that are created on the fly here.
			var galleryNum = $("#numGalleries").val();
			// Insert an iframe into the editor
			// $("#dynamicGalleryLabel").append('Gallery ' + galleryNum + ' Preview');
			// Show the preview row and insert content into the preview div
			// $("#dynamicGalleryInputFields").append(response);
			// Finally insert the content into the active tinymce editor. The response here is plain HTML coming from the server
			//$('textarea.post').html('Some contents...');
			tinymce.activeEditor.insertContent(response + '<br/><br/>');
			
			// Close all of the windows associated with the gallery
			// Close the uppy dashboard
			$('#galleryWindow').kendoWindow('destroy');
			// Close the gallery items window
			$('#galleryItemsWindow').kendoWindow('destroy');
			
			// Refresh the <cfif application.kendoCommercial>kendo<cfelse>jsgrid</cfif> grid 
		<cfif application.kendoCommercial and 1 eq 2><!---We are not using the Kendo grids right now.--->
			$('#commentsGrid').data('kendoGrid').dataSource.read();
		<cfelse>
			$("#commentsGrid").jsGrid("loadData");
		</cfif>
			// Close the comment window
			//jQuery('#commentDetailWindow').kendoWindow('destroy');
		}
		
	</script>
			
</cfcase>
		
<cfcase value="5">
	
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
<cfcase value="6">
	
	<!--- Instantiate the Render.cfc. This will be used to render our directives and create video and map thumbnails --->
	<cfobject component="#application.rendererComponentPath#" name="RendererObj">
	
	<!--- Get the post ( ( getPostByPostId(postId, showPendingPosts, showRemovedPosts) ) ) --->
	<cfset getPost = application.blog.getPostByPostId(URL.optArgs,true,true)>
	<!---<cfdump var="#getPost#">--->
		
	<!--- Get the Body --->
	<cfset body = getPost[1]["Body"]>
	<!--- And more body (when a <more/> tag is present) --->
	<cfset moreBody = getPost[1]["MoreBody"]>
	<!--- Set the body. We need to determine the content based upon the more tag if it exists. If the more tag exists- append the moreBody to the body ---> 
	<cfif len(moreBody)>
		<!--- Append the more body to the body. TinyMce will append an extra more tag, we might as well do it here. --->
		<cfset body = body & '<more/> ' & moreBody>
	</cfif>	
		
	<!--- If there are scripts, put HTML comments around them to escape the sript- otherwise the content will terminate at the fist script when using the tinymce setContent method. --->
	<cfset body = RendererObj.renderScriptsToTinyMce(body)>
	
	<!--- Also render the post for prism. We need to add pre and script tags here. --->
	<cfset arguments.body = RendererObj.renderCodeForPrism(body)>
	<!---<cfdump var="#getPost#">--->
		
	<!--- Determine whether to prompt to send email. The defaul is true unless the post date is in the past. --->
	<cfset promptToEmailToSubscribers = true>
	<!--- Is posted less than now? --->
	<cfif dateCompare(getPost[1]["DatePosted"], application.blog.blogNow()) is 1>
		<cfset promptToEmailToSubscribers = false>
	</cfif>
		
	<!--- Was this already mailed? --->
	<cfif getPost[1]["Mailed"]>
		<!--- The user can still email the post again --->
		<cfset promptEmailTitle = "Do you want to email the post again?">
		<cfset promptEmailMessage = "A previous email was sent, do you want to send the revised post out again?">
	<cfelse>
		<cfset promptEmailTitle = "Do you want to email the post?">
		<cfset promptEmailMessage = "Do you want to send this post out to your subscribers?">
	</cfif>

	<!--- Render the thumnbail HTML. Pass in the getPost obj and if you want to render the thumbnail --->
	<cfset thumbnailHtml = RendererObj.renderMediaPreview(kendoTheme, getPost, true)>
		
	<cfif not arrayLen(getPost)>
		<p>Post does not exist</p>
		<cfabort>
	</cfif>
	
	<!--- Drop down queries --->
	<!--- Get all of the selected categories. We need this to display the current categories in the dropdown menu --->
	<cfset getSelectedCategories = application.blog.getCategoriesForPost(URL.optArgs)>
		
	<cfset getRelatedPosts = application.blog.getRelatedPosts(postId=URL.optArgs)>
	<!---Related Posts: <cfdump var="#getRelatedPosts#">--->

	<style>
		label {
			font-weight: normal;
		}
		
		normalFontWeight {
			font-weight: normal;
		}
	</style>
		
	<!---//***************************************************************************************************************
				TinyMce Scripts
	//****************************************************************************************************************--->
		
	<!---********************* Post Detail editor *********************--->
	<!--- Set the common vars for tinymce. --->
	<cfsilent>
	<cfset selectorId = "postEditor">
	<cfif smallScreen>
		<cfset editorHeight = "600">
	<cfelse>
		<cfset editorHeight = "650">
	</cfif>
	<cfset imageHandlerUrl = application.baseUrl & "/common/cfc/ProxyController.cfc?method=uploadImage&mediaProcessType=post&mediaType=image&postId=" & getPost[1]['PostId'] & "&selectorId=" & selectorId & "&csrfToken=" & csrfToken>
	<cfset contentVar = body><!---EncodeForHTMLAttribute--->
	<cfset imageMediaIdField = "imageMediaId">
	<cfset imageClass = "entryImage">

	<cfif smallScreen>
		<cfset toolbarString = "undo redo | bold italic | link | image media fancyBoxGallery">
	<cfelse>
		<cfset toolbarString = "insertfile undo redo | styleselect | bold italic | alignleft aligncenter alignright alignjustify | bullist numlist outdent indent | tox | hr | link | image editimage | media | fancyBoxGallery | map mapRouting | customWindow | emoticons">
	</cfif>
	<cfset includeGallery = true>
	<cfset includeCustomWindow = true>
	</cfsilent>
	<!--- Include the tinymce js template --->
	<cfinclude template="#application.baseUrl#/includes/templates/js/tinyMce.cfm">
		
	<cfsilent>
	
	<!---//***************************************************************************************************************
				Kendo Scripts
	//****************************************************************************************************************--->
	</cfsilent>
	
	<script>
		$(document).ready(function() {
			
			var todaysDate = new Date();
			
			// Kendo Dropdowns
			// Date posted date/time picker			
			$("#datePosted").kendoDateTimePicker({
                componentType: "modern",
				value: <cfif len(getPost[1]['DatePosted'])><cfoutput>#application.Udf.jsDateFormat(getPost[1]['DatePosted'])#</cfoutput><cfelse>new Date()</cfif>,
				change: onDatePostedChange
            });
			
			function onDatePostedChange() {
                // alert("Change :: " + kendo.toString(this.value(), 'g'));
				
				// Check to see if the selected date is greater than today
				if (this.value() > todaysDate){
					$.when(kendo.ui.ExtYesNoDialog.show({ 
							title: "Release post in the future?",
							message: "You are posting at a later date in the future. If you continue and submit this post, it will be scheduled to be automatically published on your selected date in the future. Do you want to continue?",
						icon: "k-ext-info",
						width: "<cfoutput>#application.kendoExtendedUiWindowWidth#</cfoutput>", 
						height: "275px"
						})
					).done(function (response) { // If the user clicked 'yes'
						if (response['button'] == 'Yes'){// remember that js is case sensitive.
							// Do nothing
						} else {
							// Change the date to now
							$("#datePosted").kendoDateTimePicker({
								value: new Date(Date.now())
							});
						}
					});//).done(function (response)..
					
				} else if (this.value() < todaysDate){
					
					$.when(kendo.ui.ExtYesNoDialog.show({ 
						title: "Can we change the post date to the current time and date?",
						message: "You are using an older date and this may negatively impact the post placement and your RSS feeds. Can we change the post date using the current date?",
						icon: "k-ext-info",
						width: "<cfoutput>#application.kendoExtendedUiWindowWidth#</cfoutput>", 
						height: "275px"
						})
					).done(function (response) { // If the user clicked 'yes'
						if (response['button'] == 'Yes'){// remember that js is case sensitive.

							// Change the date posted to now
							$("#datePosted").kendoDateTimePicker({
								value: new Date(Date.now())
							});

							// And change the sort date
							$("#newBlogSortDate").kendoDateTimePicker({
								value: new Date(Date.now())
							});
						} else {
							// Do nothing
						}
					});//).done(function (response)..
				}//} else if (this.value() < todaysDate){{..
            }//..onDatePostedChange
			
			// ---------------------------- author dropdown. ----------------------------
			var authorDs = new kendo.data.DataSource({
				transport: {
					read: {
						cache: false,
						// Note: since this template is in a different directory, we can't specify the cfc template without the full path name.
						url: function() { // The cfc component which processes the query and returns a json string. 
							return "<cfoutput>#application.baseUrl#</cfoutput>/common/cfc/ProxyController.cfc?method=getAuthorsForDropdown&csrfToken=<cfoutput>#csrfToken#</cfoutput>"; 
						}, 
						dataType: "json",
						contentType: "application/json; charset=utf-8", // Note: when posting json via the request body to a coldfusion page, we must use this content type or we will get a 'IllegalArgumentException' on the ColdFusion processing page.
						type: "GET" //Note: for large payloads coming from the server, use the get method. The post method may fail as it is less efficient.
					}
				} //...transport:
			});//...var authorDs...
			
			// Create the top level dropdown
			var author = $("#author").kendoDropDownList({
				//cascadeFrom: "agencyRateCompanyCode",
				optionLabel: "Select...",
				// Template to add a new type when no data was found.
				noDataTemplate: $("#addUser").html(),
				autoBind: false,
				dataTextField: "FullName",
				dataValueField: "UserId",
				filter: "contains",
				dataSource: authorDs,
				// Use the close event to fire off events. The change event is fired off when setting the value of this dropdown list.
				close: onAuthorChange
			}).data("kendoDropDownList");

			// Set default value by the value (this is used when the container is populated via the datasource).
			var author = $("#author").data("kendoDropDownList");
			author.value( <cfoutput>#getPost[1]['UserId']#</cfoutput> );
			author.trigger("change");

			// On change function to save the selected value.
			function onAuthorChange(e){
				// Get the value
				userId = this.value();
			}//...function onAuthorChange(e)
			
			// Category datasource.
			var categoryDs = new kendo.data.DataSource({
				// serverFiltering: "true",// Since we are using serverFiltering, the values from the previous dropdown will be sent to the server for processing.
				transport: {
					read: {
						// We are using a function to pass additional selected arguments to the cfc.
						url: "<cfoutput>#application.baseUrl#</cfoutput>/common/cfc/ProxyController.cfc?method=getCategoriesForDropdown&csrfToken=<cfoutput>#csrfToken#</cfoutput>",
						dataType: "json",
						contentType: "application/json; charset=utf-8", // Note: when posting json via the request body to a coldfusion page, we must use this content type or we will get a 'IllegalArgumentException' on the ColdFusion processing page.
						type: "GET" //Note: for large payloads coming from the server, use the get method. The post method may fail as it is less efficient.
					},//...read:
				}//...transport:
			});//...var categoryDs...

			// Note: categories is a reserved Kendo word- if you name this categories, it will fail.
			$("#postCategories").kendoMultiSelect({
				autoBind: true,
				filter: "contains",
				// Template to add a new type when no data was found.
				noDataTemplate: $("#addCategoryNoData").html(),
				placeholder: "Select Category...",
				dataTextField: "Category",
				dataValueField: "CategoryId",
				dataSource: categoryDs,
				value: [<cfloop from="1" to="#arrayLen(getSelectedCategories)#" index="i">
					<cfsilent>
					<cfset categoryId = getSelectedCategories[i]['CategoryId']>
					<cfset category = getSelectedCategories[i]['Category']>
					</cfsilent>
                    { CategoryId: "<cfoutput>#categoryId#</cfoutput>", category: "<cfoutput>#category#</cfoutput>" },
                </cfloop>]
			});//...$("#postCategories")
			
			// Related Posts datasource.
			var relatedPostsDs = new kendo.data.DataSource({
				transport: {
					read: {
						// We are using a function to pass additional selected arguments to the cfc.
						url: "<cfoutput>#application.baseUrl#</cfoutput>/common/cfc/ProxyController.cfc?method=getPostsTitleAndId&csrfToken=<cfoutput>#csrfToken#</cfoutput>",
						dataType: "json",
						contentType: "application/json; charset=utf-8", // Note: when posting json via the request body to a coldfusion page, we must use this content type or we will get a 'IllegalArgumentException' on the ColdFusion processing page.
						type: "GET" //Note: for large payloads coming from the server, use the get method. The post method may fail as it is less efficient.
					},//...read:
				}//...transport:
			});//...var categoryDs...
			
			$("#relatedPosts").kendoMultiSelect({
				autoBind: true,
				placeholder: "Select Related Post...",
				dataTextField: "Title",
				dataValueField: "PostId",
				filter: "contains",
				dataSource: relatedPostsDs,
				value: [<cfloop from="1" to="#arrayLen(getRelatedPosts)#" index="i">
					<cfsilent>
					<cfset PostId = getRelatedPosts[i]["PostId"]>
					<cfset Title = getRelatedPosts[i]["Title"]>
					</cfsilent>
                    { PostId: "<cfoutput>#PostId#</cfoutput>", Title: "<cfoutput>#Title#</cfoutput>" },
                </cfloop>]
			});//...$("#relatedPosts")
		
			// !!! Note on the validators, all forms need a name attribute, otherwise the positioning of the messages will not work. --->
			var postDetailFormValidator = $("#postDetails").kendoValidator({
				// Set up custom validation rules 
				rules: {
					// title
					titleRequired:
					function(input){
						if (input.is("[id='title']") && $.trim(input.val()).length < 3){
							// Display an error on the page.
							input.attr("data-titleRequired-msg", "The title must be at least 3 characters");
							// Focus on the current element
							$( "#title" ).focus();
							return false;
						}                                    
						return true;
					},
					titleMaxLen:
					function(input){
						if (input.is("[id='title']") && $.trim(input.val()).length > 125){
							// Display an error on the page.
							input.attr("data-titleMaxLen-msg", "The title can't have more than 125 characters");
							// Focus on the current element
							$( "#title" ).focus();
							return false;
						}                                    
						return true;
					},
					// Desc
					descriptionRequired:
					function(input){
						if (input.is("[id='description']") && $.trim(input.val()).length < 3){
							// Display an error on the page.
							input.attr("data-descriptionRequired-msg", "The description is required");
							// Focus on the current element
							$( "#description" ).focus();
							return false;
						}                                    
						return true;
					},
					descriptionLen:
					function(input){
						if (input.is("[id='description']") && $.trim(input.val()).length > 1250){
							// Display an error on the page.
							input.attr("data-descriptionLen-msg", "The description needs to be under 1250 characters");
							// Focus on the current element
							$( "#description" ).focus();
							return false;
						}                                    
						return true;
					}
				}
			}).data("kendoValidator");
		
			// Invoked when the submit button is clicked. Instead of using '$("form").submit(function(event) {' and 'event.preventDefault();', we are using direct binding here to speed up the event.
			var postDetailSubmit = $('#postDetailSubmit');
			postDetailSubmit.on('click', function(e){  
                e.preventDefault();         
				if (postDetailFormValidator.validate()) {
					
					 if ( ($('#remove').is(':checked')) ) {
						// Raise a warning if the user chose to remove or make something as spam
						// Note: this is a custom library that I am using. The ExtAlertDialog is not a part of Kendo but an extension.
						$.when(kendo.ui.ExtYesNoDialog.show({ 
							title: "Remove post?",
							message: "Are you sure? This will remove the post from the blog.",
							icon: "k-ext-warning",
							width: "<cfoutput>#application.kendoExtendedUiWindowWidth#</cfoutput>", 
							height: "215px"
						})
						).done(function (response) { // If the user clicked 'yes', post it.
							if (response['button'] == 'Yes'){// remember that js is case sensitive.
								// Post it
								verifyPostEmail('update');
								//postDetails('update');
							}//..if (response['button'] == 'Yes'){
						});
					} else {
						// submit the form.
						// Note: when testing the ui validator, comment out the post line below. It will only validate and not actually do anything when you post.
						// alert('posting');
						verifyPostEmail('update');
					}
				} else {
					$.when(kendo.ui.ExtAlertDialog.show({ title: "There are errors", message: "Required fields have not been filled out. Please correct the highlighted fields and try again", icon: "k-ext-warning" }) // or k-ext-error, k-ext-question
						).done(function () {
						// Do nothing
					});
				}
			});
		});//...document.ready
		
		function verifyPostEmail(action){
			// Create a var to determine whether we sould prompt the user to email
			var promptToEmailToSubscribers = <cfoutput>#promptToEmailToSubscribers#</cfoutput>;
	
			// If the post is released and it is not being removed, prompt to see if we should send an email to the subscribers
			if ( promptToEmailToSubscribers && $('#released').is(':checked') && !$('#remove').is(':checked') ){
				$.when(kendo.ui.ExtYesNoDialog.show({ 
					title: "<cfoutput>#promptEmailTitle#</cfoutput>",
					message: "<cfoutput>#promptEmailMessage#</cfoutput>",
					icon: "k-ext-question",
					width: "<cfoutput>#application.kendoExtendedUiWindowWidth#</cfoutput>", 
					height: "215px"
				})
				).done(function (response) { // If the user clicked 'yes'
					if (response['button'] == 'Yes'){// remember that js is case sensitive.
						postDetails('update', true);
					} else {
						postDetails('update', false);
					}//..if (response['button'] == 'Yes'){
				});//..if ($('#released').is(':checked')){
			} else {
				postDetails('update', false);
			}
		}
		
		// Post method on the detail form called from the commentDetailFormValidator method on the detail page. The action variable will either be 'update' or 'insert'.
		function postDetails(action, sendEmail){
			
			// Bypass ColdFusions global script protection to allow JavaScripts in a post
			var postContent = tinymce.get("<cfoutput>#selectorName#</cfoutput>").getContent();
			// Replace '<script' with '<attachScript'. This is a modified JavaScript function.
			var postContentNoScripts = replaceNoCase(postContent,'<script','<attachScript', 'all');
			// Replace the end tag
			var postContentNoScripts = replaceNoCase(postContentNoScripts,'</script','</attachScript', 'all');

			jQuery.ajax({
				type: 'post', 
				url: '<cfoutput>#application.baseUrl#</cfoutput>/common/cfc/ProxyController.cfc?method=savePost',
				data: { // arguments
					// We are going to map the extact same arguments, in order, of the method in the cfc here. Notes: we can also use 'data: $("#formName").serialize()' or use the stringify method to pass it as an array of values. 
					csrfToken: '<cfoutput>#csrfToken#</cfoutput>',
					action: action, // either update or insert.
					postId: $("#postId").val(),
					postAlias: $("#postAlias").val(),
					// This is a hidden form field that is populated by the post sort date interface
					blogSortDate: $("#newBlogSortDate").val(),
					datePosted: kendo.toString($("#datePosted").data("kendoDateTimePicker").value(), 'MM/dd/yyyy'),
					timePosted: kendo.toString($("#datePosted").data("kendoDateTimePicker").value(), 'hh:mm tt'),
					themeId: $("#postThemeId").val(),
					author: $("#author").data("kendoDropDownList").value(),
					title: $("#title").val(),
					// Pass in the contents of the editor with all <script tags replaced with attach script
					post: postContentNoScripts,
					// Get the value of the checkboxes
					released: $('#released').is(':checked'), // checkbox boolean value.
					allowComment: $('#allowComment').is(':checked'), // checkbox boolean value.
					promote: $('#promote').is(':checked'), // checkbox boolean value.
					remove: $('#remove').is(':checked'), // checkbox boolean value.
					description: $('#description').val(), 
					// These multi-selects are in an array. We need to use the toString method to turn the array into comma separated values
					postCategories: $("#postCategories").data("kendoMultiSelect").value().toString(),
					relatedPosts: $("#relatedPosts").data("kendoMultiSelect").value().toString(),
					// The following media items are held in hidden forms. There should only be zero or one value that is sent
					imageMediaId: $("#imageMediaId").val(),
					videoMediaId: $("#videoMediaId").val(),
					videoMediaId: $("#mapId").val(),
					emailSubscriber: sendEmail
				},
				dataType: "json",
				success: postDetailsResult, // calls the result function.
				error: function(ErrorMsg) {
					console.log('Error' + ErrorMsg);
				}
			// Extract any errors. This is a new jQuery promise based function as of jQuery 1.8.
			}).fail(function (jqXHR, textStatus, error) {
				// This is a secured function. Display the login screen.
				if (jqXHR.status === 403) { 
					createLoginWindow(); 
				} else {//...if (jqXHR.status === 403) { 
					// The full response is: jqXHR.responseText, but we just want to extract the error.
					$.when(kendo.ui.ExtAlertDialog.show({ title: "Error while consuming the savePost function", message: error, icon: "k-ext-error", width: "<cfoutput>#application.kendoExtendedUiWindowWidth#</cfoutput>" }) // or k-ext-error, k-ext-information, k-ext-question, k-ext-warning.  You can also specify height.
						).done(function () {
						// Do nothing
					});
				}//...if (jqXHR.status === 403) { 
			});//...jQuery.ajax({
		};
		
		function postDetailsResult(response){
			// Are the credentials correct?
			if (JSON.parse(response.success) == true){
				// Refresh the <cfif application.kendoCommercial>kendo<cfelse>jsgrid</cfif> grid 
			<cfif application.kendoCommercial and 1 eq 2><!---We are not using the Kendo grids right now.--->
				$('#postsGrid').data('kendoGrid').dataSource.read();
			<cfelse>
				// Try to refresh the post grid by refreshing the window. It may not be open so we are using a try block
				try {
					$("#PostsWindow").data("kendoWindow").refresh();
				} catch (error) {
					// Do nothing
				}			
			</cfif>
				// Close the window
				jQuery('#postDetailWindow').kendoWindow('destroy');
			} else {
				// Alert the user that the login has failed.
				$.when(kendo.ui.ExtAlertDialog.show({ title: "Error saving post", message: response.errorMessage, icon: "k-ext-warning", width: "<cfoutput>#application.kendoExtendedUiWindowWidth#</cfoutput>", height: "125px" }) // or k-ext-error, k-ext-question
				).done(function () {
					// Do nothing
				});
			}//..if (JSON.parse(response.success) == true){
		}
		
	<cfif getPost[1]['Remove']>	
		function deletePost(){

			jQuery.ajax({
				type: 'post', 
				url: '<cfoutput>#application.baseUrl#</cfoutput>/common/cfc/ProxyController.cfc?method=deletePost',
				data: { // arguments
					// We are going to map the extact same arguments, in order, of the method in the cfc here. Notes: we can also use 'data: $("#formName").serialize()' or use the stringify method to pass it as an array of values. 
					csrfToken: '<cfoutput>#csrfToken#</cfoutput>',
					postId: <cfoutput>#getPost[1]['PostId']#</cfoutput>
				},
				dataType: "json",
				success: deletePostResult, // calls the result function.
				error: function(ErrorMsg) {
					console.log('Error' + ErrorMsg);
				}
			// Extract any errors. This is a new jQuery promise based function as of jQuery 1.8.
			}).fail(function (jqXHR, textStatus, error) {
				// This is a secured function. Display the login screen.
				if (jqXHR.status === 403) { 
					createLoginWindow(); 
				} else {//...if (jqXHR.status === 403) { 
					// The full response is: jqXHR.responseText, but we just want to extract the error.
					$.when(kendo.ui.ExtAlertDialog.show({ title: "Error while consuming the deletePost function", message: error, icon: "k-ext-error", width: "<cfoutput>#application.kendoExtendedUiWindowWidth#</cfoutput>" }) // or k-ext-error, k-ext-information, k-ext-question, k-ext-warning.  You can also specify height.
						).done(function () {
						// Do nothing
					});
				}//...if (jqXHR.status === 403) { 
			});//...jQuery.ajax({
		};
		
		function deletePostResult(response){
			// Are the credentials correct?
			if (JSON.parse(response.success) == true){
				// Refresh the <cfif application.kendoCommercial>kendo<cfelse>jsgrid</cfif> grid 
			<cfif application.kendoCommercial and 1 eq 2><!---We are not using the Kendo grids right now.--->
				$('#postsGrid').data('kendoGrid').dataSource.read();
			<cfelse>
				// Try to refresh the post grid by refreshing the window. It may not be open so we are using a try block
				try {
					$("#PostsWindow").data("kendoWindow").refresh();
				} catch (error) {
					// Do nothing
				}			
			</cfif>
				// Close the window
				jQuery('#postDetailWindow').kendoWindow('destroy');
			} else {
				// Alert the user that the login has failed.
				$.when(kendo.ui.ExtAlertDialog.show({ title: "Error deleting post", message: response.errorMessage, icon: "k-ext-warning", width: "<cfoutput>#application.kendoExtendedUiWindowWidth#</cfoutput>", height: "125px" }) // or k-ext-error, k-ext-question
				).done(function () {
					// Do nothing
				});
			}//..if (JSON.parse(response.success) == true){
		}
		
	</cfif>	
	</script>
		
	<form id="postDetails" data-role="validator">
	<input type="hidden" name="postId" id="postId" value="<cfoutput>#getPost[1]['PostId']#</cfoutput>" />
	<!--- Pass the current alias --->
	<input type="hidden" name="postAlias" id="postAlias" value="<cfoutput>#getPost[1]['PostAlias']#</cfoutput>" />
	<!--- Pass the imageMediaId for new images or videos that have been uploaded --->
	<input type="hidden" name="imageMediaId" id="imageMediaId" value="" />
	<!-- Pass the mediaId for a video -->
	<input type="hidden" name="videoMediaId" id="videoMediaId" value="" />
	<!-- Pass the mapId for a static map -->
	<input type="hidden" name="mapId" id="mapId" value="" />
	<!--- The post theme id allows authors to select a certain theme to be displayed when this post is viewed. --->
	<input type="hidden" name="postThemeId" id="postThemeId" value="<cfoutput>#getPost[1]['ThemeRef']#</cfoutput>" />
	<!--- The post sort date is used to sort the posts on the main blog page. --->
	<input type="hidden" name="newBlogSortDate" id="newBlogSortDate" value="<cfoutput>#getPost[1]['BlogSortDate']#</cfoutput>" />
	<!--- Pass the csrfToken --->
	<input type="hidden" name="csrfToken" id="csrfToken" value="<cfoutput>#csrfToken#</cfoutput>" />
	
	<table align="center" class="k-content tableBorder" width="100%" cellpadding="2" cellspacing="0">
	  <cfsilent>
		<!---The first content class in the table should be empty. --->
		<cfset thisContentClass = HtmlUtilsObj.getKendoClass('')>
		<!--- Set the colspan property for borders --->
		<cfset thisColSpan = "2">
	  </cfsilent>
	<!--- Delete post interface (only shows up when a post is removed) --->
	<cfif getPost[1]['Remove']>	
	  <tr height="1px">
		  <td align="left" valign="top" colspan="2" class="<cfoutput>#thisContentClass#</cfoutput>"></td>
	  </tr>
    <cfif session.isMobile or session.isTablet>
	  <tr valign="middle">
		<td class="<cfoutput>#thisContentClass#</cfoutput>" colspan="2">
			<p class="k-block k-error-colored" align="left">This post has been removed. You may permanently <a href="javascript:deletePost();">delete it</a>.</p>
		</td>
	   </tr>
	<cfelse><!---<cfif session.isMobile or session.isTablet>--->
	  <tr>
		<td align="right" class="<cfoutput>#thisContentClass#</cfoutput>" colspan="2">
			<p class="k-block k-error-colored" align="left">This post has been removed. You may permanently <a href="javascript:deletePost();">delete it</a>.</p>
		</td>
	  </tr>
	</cfif><!---<cfif session.isMobile or session.isTablet>--->
	  <!-- Border -->
	  <tr height="2px">
		  <td align="left" valign="top" colspan="<cfoutput>#thisColSpan#</cfoutput>" class="<cfoutput>#thisContentClass#</cfoutput>"></td>
	  </tr>
	  <cfsilent>
	  <!--- Set the class for alternating rows. --->
	  <!---After the first row, the content class should be the current class. --->
	  <cfset thisContentClass = HtmlUtilsObj.getKendoClass(thisContentClass)>
	  </cfsilent>
	</cfif>
			
	  <tr height="1px">
		  <td align="left" valign="top" colspan="2" class="<cfoutput>#thisContentClass#</cfoutput>"></td>
	  </tr>
    <cfif smallScreen>
	  <tr valign="middle">
		<td class="<cfoutput>#thisContentClass#</cfoutput>" colspan="2">
		<label for="datePosted">Date Posted</label>
		</td>
	   </tr>
	   <tr>
		<td class="<cfoutput>#thisContentClass#</cfoutput>" colspan="2">
			<input id="datePosted" name="datePosted" value="<cfoutput>#dateTimeFormat(getPost[1]['DatePosted'], "medium")#</cfoutput>" style="width: 95%" />   
		</td>
	  </tr>
	<cfelse><!---<cfif smallScreen>--->
	  <tr>
		<td align="right" class="<cfoutput>#thisContentClass#</cfoutput>"> 
			<label for="datePosted">Date Posted</label>
		</td>
		<td class="<cfoutput>#thisContentClass#</cfoutput>">
		<input id="datePosted" name="datePosted" value="<cfoutput>#dateTimeFormat(getPost[1]['DatePosted'], "medium")#</cfoutput>" style="width: 45%" /> 
		<button id="sortDate" class="k-button normalFontWeight" type="button" style="width: 105px" onClick="createAdminInterfaceWindow(43,<cfoutput>#getPost[1]['PostId']#</cfoutput>)">Sort Date</button>
		</td>
	  </tr>
	</cfif>
	  <!-- Border -->
	  <tr height="2px">
		  <td align="left" valign="top" colspan="<cfoutput>#thisColSpan#</cfoutput>" class="<cfoutput>#thisContentClass#</cfoutput>"></td>
	  </tr>
	  <cfsilent>
	  <!--- Set the class for alternating rows. --->
	  <!---After the first row, the content class should be the current class. --->
	  <cfset thisContentClass = HtmlUtilsObj.getKendoClass(thisContentClass)>
	  </cfsilent>
	  <tr height="2px">
		  <td align="left" valign="top" colspan="2" class="border <cfoutput>#thisContentClass#</cfoutput>"></td>
	  </tr>
	  <cfif smallScreen>
	  <tr valign="middle">
		<td class="<cfoutput>#thisContentClass#</cfoutput>" colspan="2">
		<label for="post">Author</label>
		</td>
	   </tr>
	   <tr>
		<td class="<cfoutput>#thisContentClass#</cfoutput>" colspan="2">
			<select id="author" style="width: 95%"></select>
			<!--- Inline template to add a new user. --->
			<script id="addUser" type="text/x-kendo-tmpl">
				<div>
					Author not found. Do you want to add '#: instance.filterInput.val() #'?
				</div>
				<br />
				<button class="k-button" onclick="createAdminInterfaceWindow(7, '#: instance.filterInput.val() #', 'addUser')">Add Author</button>
			</script> 
		</td>
	  </tr>
	<cfelse><!---<cfif smallScreen>--->
	  <!-- Form content -->
	  <tr valign="middle" height="35">
		<td align="right" valign="middle" width="10%" class="<cfoutput>#thisContentClass#</cfoutput>">
		<label for="post">Author</label>
		</td>
		<td align="left" width="90%" class="<cfoutput>#thisContentClass#</cfoutput>">
			<select id="author" style="width: 50%"></select>
			<!--- Inline template to add a new user. --->
			<script id="addUser" type="text/x-kendo-tmpl">
				<div>
					Author not found. Do you want to add '#: instance.filterInput.val() #'?
				</div>
				<br />
				<button class="k-button" onclick="createAdminInterfaceWindow(7, '#: instance.filterInput.val() #', 'addUser')">Add Author</button>
			</script>  
		</td>
	  </tr>
	</cfif>
	  <!-- Border -->
	  <tr height="2px">
		  <td align="left" valign="top" colspan="<cfoutput>#thisColSpan#</cfoutput>" class="<cfoutput>#thisContentClass#</cfoutput>"></td>
	  </tr>
	  <cfsilent>
	  <!--- Set the class for alternating rows. --->
	  <!---After the first row, the content class should be the current class. --->
	  <cfset thisContentClass = HtmlUtilsObj.getKendoClass(thisContentClass)>
	  </cfsilent>
	  <tr height="2px">
		  <td align="left" valign="top" colspan="2" class="border <cfoutput>#thisContentClass#</cfoutput>"></td>
	  </tr>
	  <!-- Form content -->
  	<cfif smallScreen>
	  <tr valign="middle">
		<td class="<cfoutput>#thisContentClass#</cfoutput>" colspan="2">
		<label for="post">Title</label>
		</td>
	   </tr>
	   <tr>
		<td class="<cfoutput>#thisContentClass#</cfoutput>" colspan="2">
			<input type="text" id="title" name="title" value="<cfoutput>#getPost[1]['Title']#</cfoutput>" class="k-textbox" style="width: 95%" />
		</td>
	  </tr>
	<cfelse><!---<cfif smallScreen>--->
	  <tr valign="middle" height="35">
		<td align="right" valign="middle" width="10%" class="<cfoutput>#thisContentClass#</cfoutput>">
		<label for="post">Title</label>
		</td>
		<td align="left" width="90%" class="<cfoutput>#thisContentClass#</cfoutput>">
			<input type="text" id="title" name="title" value="<cfoutput>#getPost[1]['Title']#</cfoutput>" class="k-textbox" style="width: 66%" />   
		</td>
	  </tr>
	</cfif>
	  <!-- Border -->
	  <tr height="2px">
		  <td align="left" valign="top" colspan="<cfoutput>#thisColSpan#</cfoutput>" class="<cfoutput>#thisContentClass#</cfoutput>"></td>
	  </tr>
	  <cfsilent>
	  <!--- Set the class for alternating rows. --->
	  <!---After the first row, the content class should be the current class. --->
	  <cfset thisContentClass = HtmlUtilsObj.getKendoClass(thisContentClass)>
	  </cfsilent>
	  <tr height="2px">
		  <td align="left" valign="top" colspan="2" class="border <cfoutput>#thisContentClass#</cfoutput>"></td>
	  </tr>
	  <!-- Enclosure thumbnail -->
	<cfif smallScreen>
	  <tr valign="middle">
		<td class="<cfoutput>#thisContentClass#</cfoutput>" colspan="2">
		<label>Enclosure</label>
		</td>
	   </tr>
	   <tr>
		<td class="<cfoutput>#thisContentClass#</cfoutput>" colspan="2">
			<div id="mediaPreview" name="mediaPreview"><cfoutput>#thumbnailHtml#</cfoutput></div>
		</td>
	  </tr>
	<cfelse><!---<cfif smallScreen>--->
	   <tr valign="middle" height="35">
		<td align="right" valign="middle" width="10%" class="<cfoutput>#thisContentClass#</cfoutput>">
			<label>Enclosure</label>
		</td>
		<td align="left" width="90%" class="<cfoutput>#thisContentClass#</cfoutput>">
			<!---<cfset mapThumbnail = RendererObj.renderMapPreview(11, true)>--->
			<!---<cfoutput>#mapThumbnail#</cfoutput>--->
			<!---<img src="<cfoutput>#thumbnailUrl#</cfoutput>">--->
			<div id="mediaPreview" name="mediaPreview"><cfoutput>#thumbnailHtml#</cfoutput></div>
		</td>
	  </tr>
	</cfif><!---<cfif smallScreen>--->
	  <!--- Editor button --->
	<cfif smallScreen>
	  <tr valign="middle">
		<td class="<cfoutput>#thisContentClass#</cfoutput>" colspan="2">
			<button id="enclosure" class="k-button normalFontWeight" type="button" style="width: 235px" onClick="createAdminInterfaceWindow(13,<cfoutput>#URL.optArgs#</cfoutput>)">Enclosure Editor</button>
		</td>
	  </tr>
	<cfelse>
	  <tr valign="middle" height="35">
		<td align="right" valign="middle" width="10%" class="<cfoutput>#thisContentClass#</cfoutput>">
		</td>
		<td align="left" width="90%" class="<cfoutput>#thisContentClass#</cfoutput>">
			<button id="enclosure" class="k-button normalFontWeight" type="button" style="width: 235px" onClick="createAdminInterfaceWindow(13,<cfoutput>#URL.optArgs#</cfoutput>)">Enclosure Editor</button>
		</td>
	  </tr>
	</cfif>
	  <!-- Border -->
	  <tr height="2px">
		  <td align="left" valign="top" colspan="<cfoutput>#thisColSpan#</cfoutput>" class="<cfoutput>#thisContentClass#</cfoutput>"></td>
	  </tr>
	  <cfsilent>
	  <!--- Set the class for alternating rows. --->
	  <!---After the first row, the content class should be the current class. --->
	  <cfset thisContentClass = HtmlUtilsObj.getKendoClass(thisContentClass)>
	  </cfsilent>
	  <tr height="2px">
		  <td align="left" valign="top" colspan="2" class="border <cfoutput>#thisContentClass#</cfoutput>"></td>
	  </tr>
	  <!-- Form content -->
	  <!-- ****************************************** TinyMce Editor ****************************************** -->
	<cfif smallScreen>
	  <tr valign="middle">
		<td class="<cfoutput>#thisContentClass#</cfoutput>" colspan="2">
			<div id="dynamicGalleryInputFields" name="dynamicGalleryInputFields"></div>
		</td>
	   </tr>
	   <tr>
		<td class="<cfoutput>#thisContentClass#</cfoutput>" colspan="2">
			<label for="<cfoutput>#selectorName#</cfoutput>">Post</label>   
		</td>
	  </tr>
	  <tr>
		<td class="<cfoutput>#thisContentClass#</cfoutput>" colspan="2">
			<input type="text" id="<cfoutput>#selectorName#</cfoutput>" name="<cfoutput>#selectorName#</cfoutput>" />
		</td>
	  </tr>
	<cfelse><!---<cfif smallScreen>--->
	  <tr>
		<td align="right" class="<cfoutput>#thisContentClass#</cfoutput>"><div id="dynamicGalleryLabel"></div></td>
		<td class="<cfoutput>#thisContentClass#</cfoutput>"><div id="dynamicGalleryInputFields" name="dynamicGalleryInputFields"></div></td>
	  </tr>
	  <tr valign="middle">
		<td align="right" valign="middle" height="35" class="<cfoutput>#thisContentClass#</cfoutput>">
		<label for="<cfoutput>#selectorName#</cfoutput>">Post</label>
		</td>
		<td align="left" class="<cfoutput>#thisContentClass#</cfoutput>"> 
		<input type="text" id="<cfoutput>#selectorName#</cfoutput>" name="<cfoutput>#selectorName#</cfoutput>" />   
		</td>
	  </tr>
	</cfif>
	  <!-- Border -->
	  <tr height="2px">
		  <td align="left" valign="top" colspan="<cfoutput>#thisColSpan#</cfoutput>" class="<cfoutput>#thisContentClass#</cfoutput>"></td>
	  </tr>
	  <cfsilent>
	  <!--- Set the class for alternating rows. --->
	  <!---After the first row, the content class should be the current class. --->
	  <cfset thisContentClass = HtmlUtilsObj.getKendoClass(thisContentClass)>
	  </cfsilent>
	  <tr height="2px">
		  <td align="left" valign="top" colspan="2" class="border <cfoutput>#thisContentClass#</cfoutput>"></td>
	  </tr>
	  <!-- Form content -->
	<cfif smallScreen>
	  <tr valign="middle">
		<td class="<cfoutput>#thisContentClass#</cfoutput>" colspan="2">
			<i class="far fa-edit"></i> 
			<label for="post">Misc.</label>
		</td>
	   </tr>
	   <tr>
		<td class="<cfoutput>#thisContentClass#</cfoutput>" colspan="2">
			<button id="jsonLd" class="k-button normalFontWeight" type="button" style="width: 175px" onClick="createAdminInterfaceWindow(15,<cfoutput>#getPost[1]['PostId']#</cfoutput>)">JSON-LD (SEO)</button>
			<button id="changeAlias" class="k-button normalFontWeight" type="button" style="width: 175px" onClick="createAdminInterfaceWindow(23,<cfoutput>#getPost[1]['PostId']#</cfoutput>)">Change Alias</button>
		</td>
	  </tr>
	<cfelse><!---<cfif smallScreen>--->
	  <tr valign="middle" height="35">
		<td align="right" valign="middle" width="10%" class="<cfoutput>#thisContentClass#</cfoutput>">
			<i class="far fa-edit"></i> 
			<label for="post">Misc.</label>
		</td>
		<td align="center" class="<cfoutput>#thisContentClass#</cfoutput>">
			<!--- Inner table --->
			<table align="center" class="<cfoutput>#thisContentClass#</cfoutput>" width="100%" cellpadding="5" cellspacing="0">
				<tr>
					<td width="20%" align="left">
						<!--- Make the link --->
						<cfset postUrl = application.blog.getPostUrlByPostId(getPost[1]['PostId'])>
						<button id="postPreview" class="k-button normalFontWeight" type="button" style="width: 165px" onClick="window.open('<cfoutput>#postUrl#</cfoutput>?showPendingPosts');">Preview</button>
					</td>
					<td width="20%" align="left">
						<button id="postHeader" class="k-button normalFontWeight" type="button" style="width: 165px" onClick="createAdminInterfaceWindow(42,<cfoutput>#getPost[1]['PostId']#</cfoutput>)">Post Header</button>
					</td>
					<td width="20%" align="left">
						<button id="changeAlias" class="k-button normalFontWeight" type="button" style="width: 165px" onClick="createAdminInterfaceWindow(23,<cfoutput>#getPost[1]['PostId']#</cfoutput>)">Change Alias</button>
					</td>
					<td width="20%" align="left">
						<button id="jsonLd" class="k-button normalFontWeight" type="button" style="width: 165px" onClick="createAdminInterfaceWindow(15,<cfoutput>#getPost[1]['PostId']#</cfoutput>)">JSON-LD (SEO)</button>
					</td>
					<td width="20%" align="left">
						<button id="setTheme" class="k-button normalFontWeight" type="button" style="width: 165px" onClick="createAdminInterfaceWindow(44,<cfoutput>#getPost[1]['PostId']#</cfoutput>)">Set Theme</button>
						<!--- Next version:
						<button id="scheduleRelease" class="k-button normalFontWeight" type="button" style="width: 175px">Schedule Release</button>
						--->
					</td>
				</tr>
			</table>
		</td>
	  </tr>
	</cfif>
	  <!-- Border -->
	  <tr height="2px">
		  <td align="left" valign="top" colspan="<cfoutput>#thisColSpan#</cfoutput>" class="<cfoutput>#thisContentClass#</cfoutput>"></td>
	  </tr>
	  <cfsilent>
	  <!--- Set the class for alternating rows. --->
	  <!---After the first row, the content class should be the current class. --->
	  <cfset thisContentClass = HtmlUtilsObj.getKendoClass(thisContentClass)>
	  </cfsilent>
	  <tr height="2px">
		  <td align="left" valign="top" colspan="2" class="border <cfoutput>#thisContentClass#</cfoutput>"></td>
	  </tr>
	  <!-- Form content -->
	  <tr>
	  <cfif not smallScreen>
		<td class="<cfoutput>#thisContentClass#</cfoutput>"></td>
	  </cfif>
		<td align="center" class="<cfoutput>#thisContentClass#</cfoutput>" <cfif smallScreen>colspan="2"</cfif>>
			<table align="center" class="<cfoutput>#thisContentClass#</cfoutput>" width="100%" cellpadding="5" cellspacing="0" border="0">
				<tr>
					<td width="25%" align="left">
						<cfsilent>
							<!--- This field may not be defined (it may be null in the database) --->
							<cfif structKeyExists(getPost[1], "Released" )>
								<cfset released = getPost[1]["Released"]>
							<cfelse>
								<cfset released = 0>
							</cfif>
						</cfsilent>
						<input id="released" name="released" type="checkbox" <cfif released>checked</cfif> class="normalFontWeight">
						<label for="released">Released</label>
					</td>
					<td width="25%" align="left">
						<cfsilent>
							<!--- This field may not be defined (it may be null in the database) --->
							<cfif structKeyExists(getPost[1], "AllowComment" )>
								<cfset allowComment = getPost[1]["AllowComment"]>
							<cfelse>
								<cfset allowComment = 0>
							</cfif>
						</cfsilent>
						<input id="allowComment" name="allowComment" type="checkbox" <cfif allowComment>checked</cfif> class="normalFontWeight">
						<label for="allowComment">Allow Comments</label>
					</td>
					<td width="25%" align="left">
						<cfsilent>
						<!--- This field may not be defined (it may be null in the database) --->
						<cfif structKeyExists(getPost[1], "Promoted" )>
							<cfset promote = getPost[1]["Promoted"]>
						<cfelse>
							<cfset promote = 0>
						</cfif>
						</cfsilent>
						<input id="promote" name="promote" type="checkbox" <cfif promote>checked</cfif> class="normalFontWeight">
						<label for="promote">Promote</label>
					</td>
					<td width="25%" align="left">
						<cfsilent>
							<!--- This field may not be defined (it may be null in the database) --->
							<cfif structKeyExists(getPost[1], "Remove")>
								<cfset remove = getPost[1]["Remove"]>
							<cfelse>
								<cfset remove = 0>
							</cfif>
						</cfsilent>
						<input id="remove" name="remove" type="checkbox" <cfif remove>checked</cfif> class="normalFontWeight">
						<label for="remove">Remove</label>
					</td>
					<td width="20%" align="left">&nbsp;

					</td>
				</tr>
			</table>
		</td>
	  </tr>			
	  <!-- Border -->
	  <tr height="2px">
		  <td align="left" valign="top" colspan="<cfoutput>#thisColSpan#</cfoutput>" class="<cfoutput>#thisContentClass#</cfoutput>"></td>
	  </tr>
	  <cfsilent>
	  <!--- Set the class for alternating rows. --->
	  <!---After the first row, the content class should be the current class. --->
	  <cfset thisContentClass = HtmlUtilsObj.getKendoClass(thisContentClass)>
	  </cfsilent>
	  <tr height="2px">
		  <td align="left" valign="top" colspan="2" class="border <cfoutput>#thisContentClass#</cfoutput>"></td>
	  </tr>
	  <!-- Form content -->
	<cfif smallScreen>
	  <tr valign="middle">
		<td class="<cfoutput>#thisContentClass#</cfoutput>" colspan="2">
			<label for="description">Description</label>
		</td>
	   </tr>
	   <tr>
		<td class="<cfoutput>#thisContentClass#</cfoutput>" colspan="2">
			<textarea id="description" name="description" maxlength="1250" class="k-textbox" style="width:95%"><cfoutput>#getPost[1]['Description']#</cfoutput></textarea>   
		</td>
	  </tr>
	<cfelse><!---<cfif smallScreen>--->
	  <tr valign="middle" height="35">
		<td align="right" valign="middle" width="10%" class="<cfoutput>#thisContentClass#</cfoutput>">
			<label for="description">Description</label>
		</td>
		<td align="left" width="90%" class="<cfoutput>#thisContentClass#</cfoutput>">
			<textarea id="description" name="description" maxlength="1250" class="k-textbox" style="width: 66%"><cfoutput>#getPost[1]['Description']#</cfoutput></textarea> 
		</td>
	  </tr>
	</cfif>
	  <!-- Border -->
	  <tr height="2px">
		  <td align="left" valign="top" colspan="<cfoutput>#thisColSpan#</cfoutput>" class="<cfoutput>#thisContentClass#</cfoutput>"></td>
	  </tr>
	  <cfsilent>
	  <!--- Set the class for alternating rows. --->
	  <!---After the first row, the content class should be the current class. --->
	  <cfset thisContentClass = HtmlUtilsObj.getKendoClass(thisContentClass)>
	  </cfsilent>
	  <tr height="2px">
		  <td align="left" valign="top" colspan="2" class="border <cfoutput>#thisContentClass#</cfoutput>"></td>
	  </tr>
	  <!-- Form content -->
	<cfif smallScreen>
	  <tr valign="middle">
		<td class="<cfoutput>#thisContentClass#</cfoutput>" colspan="2">
			<label for="postCategories">Categories</label>
		</td>
	   </tr>
	   <tr>
		<td class="<cfoutput>#thisContentClass#</cfoutput>" colspan="2">
			<!--- Inline template to add a new category. --->
			<select id="postCategories" style="width: 95%"></select>
			<!--- Inline template to add a new category. Note: the noData templates are different depending upon the widget.--->
			<script id="addCategoryNoData" type="text/x-kendo-tmpl">
				# var value = instance.input.val(); #
				# var id = instance.element[0].id; #
				<div>
					Category not found. Do you want to add new category - '#: value #' ?
				</div>
				<br />
				 <button class="k-button" onclick="createAdminInterfaceWindow(12,'#: value #')" ontouchend="createAdminInterfaceWindow(12,'#: value #')">Add new item</button>
			</script>    
		</td>
	  </tr>
	<cfelse><!---<cfif smallScreen>--->
	  <tr valign="middle" height="35">
		<td align="right" valign="middle" width="10%" class="<cfoutput>#thisContentClass#</cfoutput>">
			<label for="postCategories">Categories</label>
		</td>
		<td align="left" width="90% class="<cfoutput>#thisContentClass#</cfoutput>">
			<!--- Inline template to add a new category. --->
			<select id="postCategories" style="width: 95%"></select>
			<!--- Inline template to add a new category. Note: the noData templates are different depending upon the widget.--->
			<script id="addCategoryNoData" type="text/x-kendo-tmpl">
				# var value = instance.input.val(); #
				# var id = instance.element[0].id; #
				<div>
					Category not found. Do you want to add new category - '#: value #' ?
				</div>
				<br />
				 <button class="k-button" onclick="createAdminInterfaceWindow(12,'#: value #')" ontouchend="createAdminInterfaceWindow(12,'#: value #')">Add new item</button>
			</script> 
		</td>
	  </tr>
	</cfif>
	  <!-- Border -->
	  <tr height="2px">
		  <td align="left" valign="top" colspan="<cfoutput>#thisColSpan#</cfoutput>" class="<cfoutput>#thisContentClass#</cfoutput>"></td>
	  </tr>
	  <cfsilent>
	  <!--- Set the class for alternating rows. --->
	  <!---After the first row, the content class should be the current class. --->
	  <cfset thisContentClass = HtmlUtilsObj.getKendoClass(thisContentClass)>
	  </cfsilent>
	  <tr height="2px">
		  <td align="left" valign="top" colspan="2" class="border <cfoutput>#thisContentClass#</cfoutput>"></td>
	  </tr>
	  <!-- Form content -->
	<cfif smallScreen>
	  <tr valign="middle">
		<td class="<cfoutput>#thisContentClass#</cfoutput>" colspan="2">
			<label for="relatedPosts">Related Posts</label>
		</td>
	   </tr>
	   <tr>
		<td class="<cfoutput>#thisContentClass#</cfoutput>" colspan="2">
			<select id="relatedPosts" style="width: 95%; font-weight: 300;"></select> 
		</td>
	  </tr>
	<cfelse><!---<cfif smallScreen>--->
	  <tr valign="middle" height="35">
		<td align="right" valign="middle" width="10%" class="<cfoutput>#thisContentClass#</cfoutput>">
			<label for="relatedPosts">Related Posts</label>
		</td>
		<td align="left" width="90%" class="<cfoutput>#thisContentClass#</cfoutput>">
			<select id="relatedPosts" style="width: 100%; font-weight: 300;"></select> 
		</td>
	  </tr>	
	</cfif>
	  <!-- Border -->
	  <tr height="2px">
		  <td align="left" valign="top" colspan="<cfoutput>#thisColSpan#</cfoutput>" class="<cfoutput>#thisContentClass#</cfoutput>"></td>
	  </tr>
	  <cfsilent>
	  <!--- Set the class for alternating rows. --->
	  <!---After the first row, the content class should be the current class. --->
	  <cfset thisContentClass = HtmlUtilsObj.getKendoClass(thisContentClass)>
	  </cfsilent>
	  <tr height="2px">
		  <td align="left" valign="top" colspan="2" class="border <cfoutput>#thisContentClass#</cfoutput>"></td>
	  </tr>
	  <!-- Form content -->
	  <tr valign="middle">
		<td height="25" valign="bottom" align="right" class="<cfoutput>#thisContentClass#</cfoutput>">&nbsp;</td>
		<td height="25" valign="bottom" align="left" class="<cfoutput>#thisContentClass#</cfoutput>">
			<button id="postDetailSubmit" name="postDetailSubmit" class="k-button k-primary" type="button">Submit</button>
		</td>
	  </tr>
	</table>
	</form>
					
</body>
	  
</cfcase>

<!--- //************************************************************************************************
		User Details
//**************************************************************************************************--->
	
<cfcase value="7">
	
	<!--- Determine if the email has been set up --->
	<cfif not len(application.BlogDbObj.getBlogEmail())>
		<p>Blog email is not set up. Please go to <b><a href="javascript:createAdminInterfaceWindow(39)">Blog Settings<a/></b> and enter the blog email.</b></p>
		<cfabort>
	</cfif>
	
	<!--- Preset params --->
	<cfparam name="firstName" default="">
	<cfparam name="lastName" default="">
	<cfparam name="displayName" default="">
	<cfparam name="userName" default="">
	<cfparam name="email" default="">
	<cfparam name="password" default="">
	<cfparam name="webSite" default="">
	<cfparam name="roles" default="">
	
	<!--- The URL.otherArgs specifies whether this is an edit, or an insert. When editing, the URL.optArgs should be the User.UserId. --->
	<!--- Get the current role for this user (if they already exist) --->
	<cfif structKeyExists(URL, "otherArgs") and URL.otherArgs eq 'addUser'>
		<cfset detailAction = "insert">
	<cfelseif structKeyExists(URL, "optArgs") and isNumeric(URL.optArgs)>
		<cfset detailAction = "update">
	</cfif>
	<!---<cfoutput>detailAction: #detailAction#</cfoutput>--->
	
	<!--- Get the current role for this user (if they already exist) --->
	<cfif detailAction eq 'update'>
		
		<!--- Get and extract user information. This is an array containing one element --->
		<cfset userDetails = application.blog.getUser(userId=URL.optArgs)>
		<!---<cfdump var="#userDetails#">--->
		<!--- Extract the details. The values may not be present when importing the blog from BlogCfc or the previous version of GalaxieBlog for the first time --->
		<cfset userName = userDetails[1]["UserName"]>
		<cfset firstName = userDetails[1]["FirstName"]>
		<cfset lastName = userDetails[1]["LastName"]>
		<cfset displayName = userDetails[1]["DisplayName"]>
		<cfset email = userDetails[1]["Email"]>
		<cfset password = userDetails[1]["Password"]>
		<cfset website = userDetails[1]["Website"]>
			
		<!--- Get roles and capabilities --->
		<!--- Get the list of roles (a user should only be one role at in V2). We can either extract a roleId list, or a role list. Here, we want to get the actual role name (roleList) --->
		<cfset currentUserRole = application.blog.getUserBlogRoles(userName, 'roleList')>
		<!--- And get the current user role Id (setting the dropdown values require the id) --->
		<cfset currentUserRoleId = application.blog.getUserBlogRoles(userName, 'roleIdList')>
		<!--- Return a list of capabilities. We need this to determine whether to show the log button that displays all of the user logins (by looking at the editUser capability) --->
		<cfset currentUserCapabilityList = application.blog.getCapabilitiesByRole(currentUserRole, 'capabilityList')>
		<!--- Get a list of the users capability id's. capabilityIdList is an argument to return a list of capability id's --->
		<cfset currentUserCapabilityIdList = application.blog.getCapabilitiesByRole(currentUserRole, 'capabilityIdList')>
		<!--- And get the capabily HQL object. Here we need both the id and the name so we are getting the HQL data. --->
		<cfset currentUserCapabilityObject = application.blog.getCapabilitiesByRole(currentUserRole, 'HQL')>
			
	</cfif>
			
	<!--- Get all user names for validation. We will use client side logic (and server side) to ensure that the assigned roles are unique. --->
	<cfset currentUserNameList = application.blog.getCurrentUserNameList()>
		
	<script>
		// ---------------------------- role dropdown. ----------------------------
		var roleDs = new kendo.data.DataSource({
			transport: {
				read: {
					cache: false,
					// Note: since this template is in a different directory, we can't specify the cfc template without the full path name.
					url: function() { // The cfc component which processes the query and returns a json string. 
						return "<cfoutput>#application.baseUrl#</cfoutput>/common/cfc/ProxyController.cfc?method=getRolesForDropdown&csrfToken=<cfoutput>#csrfToken#</cfoutput>"; 
					}, 
					dataType: "json",
					contentType: "application/json; charset=utf-8", // Note: when posting json via the request body to a coldfusion page, we must use this content type or we will get a 'IllegalArgumentException' on the ColdFusion processing page.
					type: "GET" //Note: for large payloads coming from the server, use the get method. The post method may fail as it is less efficient.
				}
			} //...transport:
		});//...var rolesDs...

		// Create the top level dropdown
		var roleDropdown = $("#roleDropdown").kendoDropDownList({
			optionLabel: "Select...",
			autoBind: false,
			dataTextField: "RoleName",
			dataValueField: "RoleId",
			filter: "contains",
			dataSource: roleDs,
			// Use the change event to fire off events. The change event is fired off when setting the value of this dropdown list.
			change: onRoleChange
		}).data("kendoDropDownList");

	<cfif isDefined("currentUserRoleId")>
		// Set default value by the value (this is used when the container is populated via the datasource).
		var roleDropdown = $("#roleDropdown").data("kendoDropDownList");
		roleDropdown.value(<cfoutput>#currentUserRoleId#</cfoutput>);
		//roleDropdown.trigger("change");
	</cfif>

		// On change function to save the selected value.
		function onRoleChange(e){
			// Get the value
			roleId = this.value();
			// Save the value in a hiden form in order to get at it in the next dropdown
			$("#selectedRoleId").val(roleId);
			// Refresh the capability dropdown that is dependent upon this value
			$("#capabilityDropdown").data("kendoMultiSelect").dataSource.read();
			// Populate the next dropdown when something is chosen.
			if (roleId > 0){
				// Populate it...
				populateCapabilityDropdown();
			}
		}//...function onRolechange(e)
		
		// Populate the capabilities from the datasource
		function populateCapabilityDropdown(){
			// Get a reference to the dropdown. We will use this in the loop below to set its items.
			var capabilityDropdown = $("#capabilityDropdown").data("kendoMultiSelect");
			// Clear the previous value
			capabilityDropdown.value([]);
			// Clear the defaultCapabilities form that we store the default values in
			$("#defaultCapabilities").val("");
			// Fetch the data from the capabilityDs datasource
			capabilityDs.fetch(function(){
				// Get the data
				var capabilityDsData = capabilityDs.data();
				// Create an array in order to populate multiple values 
				var capabilityIdList = [];
				// Loop through the data to create an array to send to the capability multi-select
				for (var i = 0; i < capabilityDsData.length; i++) {
					// Get the capabilityId
					var capabilityId = capabilityDsData[i].CapabilityId;
					// Populate our array with the value surrounded by qoutes
					capabilityIdList.push(capabilityId);
				}//..for (var i = 0; i < capabilityDsData.length; i++) 
				// Set the values in the multiselect after a very short timeout (50ms)
				if (capabilityIdList.length > 0){
					setTimeout(function() {
						capabilityDropdown.value(capabilityIdList);
					}, 500);
				}
				// And populate a hidden form so that we can compare the list with what the user has chosen to determine if we should open up a dialog to save the new role name. We need to have a short timeout in order for the form to populate.
				setTimeout(function() {
					$("#defaultCapabilities").val(capabilityDropdown.value());
				}, 500);
				
			});//..capabilityDs.fetch(function(){
		}//..function populateCapabilityDropdown()
		
		// ---------------------------- Capability dropdown. ----------------------------
		var capabilityDs = new kendo.data.DataSource({
			transport: {
				read: {
					cache: false,
					// Note: since this template is in a different directory, we can't specify the cfc template without the full path name.
					url: function() { // The cfc component which processes the query and returns a json string. 
						return "<cfoutput>#application.baseUrl#</cfoutput>/common/cfc/ProxyController.cfc?method=getCapabilitiesForDropdown&csrfToken=<cfoutput>#csrfToken#</cfoutput>"
						+ "&role=" + roleDropdown.text();
					}, 
					dataType: "json",
					contentType: "application/json; charset=utf-8", // Note: when posting json via the request body to a coldfusion page, we must use this content type or we will get a 'IllegalArgumentException' on the ColdFusion processing page.
					type: "GET" //Note: for large payloads coming from the server, use the get method. The post method may fail as it is less efficient.
				}
			} //...transport:
		});//...var capabilityDs...

		// Note: there are two datasources for the capability dropdown. Above, there is a dedicated datasource right above, and this one (Inline datasource). Both of these are needed in this implementation of the cascading multi select. The capability dropdown values are populated by the chosen role.
		var capabilityDropdown = $("#capabilityDropdown").kendoMultiSelect({
			optionLabel: "Select...",
			autoBind: false,
			dataTextField: "CapabilityUiLabel",
			dataValueField: "CapabilityId",
			filter: "contains",
			// Inline datasource. This is the 2nd datasource for the capability cascading list. Both datasources are needed with this implementation.
			dataSource: {
				transport: {
					read: {
						cache: false,
						// Note: since this template is in a different directory, we can't specify the cfc template without the full path name.
						url: function() { // The cfc component which processes the query and returns a json string. 
							return "<cfoutput>#application.baseUrl#</cfoutput>/common/cfc/ProxyController.cfc?method=getCapabilitiesForDropdown&csrfToken=<cfoutput>#csrfToken#</cfoutput>&csrfToken=<cfoutput>#csrfToken#</cfoutput>"
							+ "&role=" + roleDropdown.text();
						}, 
						dataType: "json",
						contentType: "application/json; charset=utf-8", // Note: when posting json via the request body to a coldfusion page, we must use this content type or we will get a 'IllegalArgumentException' on the ColdFusion processing page.
						type: "GET" //Note: for large payloads coming from the server, use the get method. The post method may fail as it is less efficient.
					}
				} //...transport:
			},
			schema: {
				data: function (data) { //return the datasource array that contains the data
					return data.fullList;
				}
			}
		}).data("kendoMultiSelect");
	
	<cfif detailAction eq 'update'>
		// Populate the control with the current values determined by the users role
		<!--- Shorten the name --->
		<cfset capabilityArr = currentUserCapabilityObject>
		capabilityDropdown.dataSource.data([{
		<cfloop from="1" to="#arrayLen(capabilityArr)#" index="i"><cfoutput>
		  CapabilityUiLabel: "#capabilityArr[i]['CapabilityName']#", CapabilityId: #capabilityArr[i]['CapabilityId']#
		<cfif i lt arrayLen(capabilityArr)>}, {</cfif>
		</cfoutput></cfloop>
		}]);

		// Set default value by the value (this is used when the container is populated via the datasource). Note: this method does not like comma separated values and will only show the first option if you use them (ie. 1,2,3). It expects the list in an array like so: [1,2,3]
		capabilityDropdown.value([<cfoutput>#currentUserCapabilityIdList#</cfoutput>]);
	</cfif><!---<cfif detailAction eq 'update'>--->
								  
		// !!! Note on the validators, all forms need a name attribute, otherwise the positioning of the messages will not work. --->
		$(document).ready(function() {

			var userDetailValidator = $("#userDetails").kendoValidator({
				// Set up custom validation rules 
				rules: {
					// first name
					firstNameIsNumeric:
					function(input){
						if (input.is("[id='firstName']") && $.isNumeric(input.val())){
							// Display an error on the page.
							input.attr("data-firstNameIsNumeric-msg", "Must be a string");
							// Focus on the current element
							$( "#firstName" ).focus();
							return false;
						}                                    
						return true;
					},
					// last name
					lastNameIsNumeric:
					function(input){
						if (input.is("[id='lastName']") && $.isNumeric(input.val())){
							// Display an error on the page.
							input.attr("data-lastNameIsNumeric-msg", "Must be a string");
							// Focus on the current element
							$( "#lastName" ).focus();
							return false;
						}                                    
						return true;
					},
					// user name
					userNameIsNumeric:
					function(input){
						if (input.is("[id='userName']") && $.isNumeric(input.val())){
							// Display an error on the page.
							input.attr("data-userNameIsNumeric-msg", "Must be a string");
							// Focus on the current element
							$( "#userName" ).focus();
							return false;
						}                                    
						return true;
					},
					<cfif detailAction eq 'insert'>
					// The userName must be unique. 
					userNameIsUnique:
					function(input){
						// Do not continue if the user name is found in the currentUserName list 
						if (input.is("[id='userName']") && ( listFind( currentUserNameList, input.val() ) != 0 ) ){
							// Display an error on the page.
							input.attr("data-userNameIsUnique-msg", "Username already exists");
							// Focus on the current element
							$( "#userName" ).focus();
							return false;
						}                                    
						return true;
					},
					</cfif><!---<cfif detailAction eq 'insert'>--->
					// Password
					passwordMinLength: 
					function(input) {
						// Trim the string of spaces before checking  
						if (input.is("[id='password']") && $.trim(input.val()).length < 6) { //
							// Display an error on the page.
							input.attr("data-passwordMinLength-msg", "Must be at least 6 characters");
							// Focus on the current element
							$( "#password" ).focus();
							return false;
						}                                    
						return true;
					}
				}
			}).data("kendoValidator");

			// Invoked when the submit button is clicked. Insted of using '$("form").submit(function(event) {' and 'event.preventDefault();', We are using direct binding here to speed up the event.
			var userDetailSubmit = $('#userDetailSubmit');
			userDetailSubmit.on('click', function(e){      
				e.preventDefault();         
				if (userDetailValidator.validate()) {
					// Determine if there this is a new role and proceed.
					checkForNewRole();
				} else {

					$.when(kendo.ui.ExtAlertDialog.show({ title: "There are errors", message: "Please correct the highlighted fields and try again", width: "<cfoutput>#application.kendoExtendedUiWindowWidth#</cfoutput>", icon: "k-ext-warning" }) // or k-ext-error, k-ext-question
						).done(function () {
						// Do nothing
					});
				}
			});

		});//...document.ready
								  
		// Compare the capabilities held in the defaultCapabilities hidden form to the selected capabilities to see if they have changed. If they are different, pop-up an interface asking for the new role name, otherwise proceed to the postUserDetails function to send the data to the server for processing.
		function checkForNewRole(){
			// Get the default capabilities for the role in the input form
			var defaultCapabilities = $('#defaultCapabilities').val();
			// Get the selected capabilities
			var capabilityDropdown = $("#capabilityDropdown").data("kendoMultiSelect").value();				  
			var selectedCapabilities = capabilityDropdown.toString();
				
			// If the defaultCapabilities has not changed (and is empty), or if the default capabilities match the selected capabilities process the data on the server.
			if (defaultCapabilities == '' || defaultCapabilities == selectedCapabilities){
				
				// Open up a please wait dialog
				$.when(kendo.ui.ExtWaitDialog.show({ title: "Please wait...", message: "Please wait while we process the user.", icon: "k-ext-information" }));
				// Post the data to the server
				setTimeout(function() {
					postUserDetails('<cfoutput>#detailAction#</cfoutput>');
				}, 250);
								  
			} else {
				// Open the new role interface
				createAdminInterfaceWindow(8);
			}					  
		}

		// Post method on the detail form called from the deptDetailFormValidator method on the detail page. The action variable will either be 'update' or 'insert'.
		function postUserDetails(action){
			
			// Convert the capability multiselect into a comma delimited string.
			var capabilityDropdown = $("#capabilityDropdown").data("kendoMultiSelect").value();
			
			jQuery.ajax({
				type: 'post', 
				url: '<cfoutput>#application.baseUrl#</cfoutput>/common/cfc/ProxyController.cfc?method=saveUser',
				data: { // arguments
					// We are going to map the extact same arguments, in order, of the method in the cfc here. Notes: we can also use 'data: $("#userDetails").serialize()' or use the stringify method to pass it as an array of values. 
					csrfToken: '<cfoutput>#csrfToken#</cfoutput>',
					action: action, // either update or insert.
					firstName: $("#firstName").val(),
					lastName: $("#lastName").val(),
					displayName: $("#displayName").val(),
					email:  $("#email").val(),
					website: $("#webSite").val(),
				<!--- The notify checkbox is not present unless the admin is different than the logged in user. We don't  need to notify ourselves if we took this action --->
				<cfif userName neq session.userName>
					notify: $('#notify').is(':checked'),
				<cfelse>
					notify: false,
				</cfif>
					userName: $("#userName").val(),
					password: $("#password").val(),
					// The value of the dropdown is the Id
					roleId: $("#roleDropdown").data("kendoDropDownList").value(), 
					// The new role and desc will be sent after the user types in the new role when the default capabilities have been changed.
					newRole: $("#newRole").val(),
					newRoleDesc: $("#newRoleDesc").val(),
					capabilities: capabilityDropdown.toString()
				},
				dataType: "json",
				success: userUpdateResult, // calls the result function.
				error: function(ErrorMsg) {
					console.log('Error' + ErrorMsg);
				}
			// Extract any errors. This is a new jQuery promise based function as of jQuery 1.8.
			}).fail(function (jqXHR, textStatus, error) {
				// The full response is: jqXHR.responseText, but we just want to extract the error.
				$.when(kendo.ui.ExtAlertDialog.show({ title: "Error while consuming the saveUser function", message: error, icon: "k-ext-error", width: "425px" }) // or k-ext-error, k-ext-information, k-ext-question, k-ext-warning.  You can also specify height.
					).done(function () {
					// Do nothing
				});		
			});
		};
								  
		function showPasswordNote(){	
			// Determine if the note has already been seen
			var passwordNoteSeen = $("#passwordNoteSeen").val();
			// If the note has not been seen, pop it up
			if (passwordNoteSeen == '0'){
				$.when(kendo.ui.ExtOkCancelDialog.show({ 
					title: "All passwords are encrypted", 
					message: "Passwords are not retrievable. Do you want to change the password?",
					icon: "k-ext-warning" })
				).done(function (response) {
					if (response['button'] == 'OK'){
						// Clear the form
						$("#password").val(''); 
						// Focus the form
						$("#password").focus();
						// And set the hidden passwordNoteSeen form to 1 so the user does not have to keep on seeing this message when they try to change the password. 
						var passwordNoteSeen = $("#passwordNoteSeen").val(1);
					}
				});
			}
		}

		function userUpdateResult(response){
			// Refresh the user grid
			$("#userGridWindow").data("kendoWindow").refresh();
			// Close the windows.
			$('#userDetailWindow').kendoWindow('destroy');
			// Close the wait window that was launched in the calling function.
			kendo.ui.ExtWaitDialog.hide();
		}
								  
		// Create a list to validate that a user name is already in use.
		currentUserNameList = '<cfoutput>#currentUserNameList#</cfoutput>';
								  
	</script>
	
	<form id="userDetails" action="#" method="post" data-role="validator">
	<!--- Pass the csrfToken --->
	<input type="hidden" name="csrfToken" id="csrfToken" value="<cfoutput>#csrfToken#</cfoutput>" />
	<input type="hidden" name="selectedRoleId" id="selectedRoleId" value=""/>
	<input type="hidden" name="defaultCapabilities" id="defaultCapabilities" value=""/>
	<input type="hidden" name="newRole" id="newRole" value=""/>
	<input type="hidden" name="newRoleDesc" id="newRoleDesc" value=""/>
	<input type="hidden" name="passwordNoteSeen" id="passwordNoteSeen" value="0"/>
	<input type="hidden" name="confirmedPasword" id="confirmedPasword" value=""/>
	
	<table align="center" class="k-content tableBorder" width="100%" cellpadding="2" cellspacing="0" border="0">
	  <cfsilent>
			<!---The first content class in the table should be empty. --->
			<cfset thisContentClass = HtmlUtilsObj.getKendoClass('')>
			<!--- Set the colspan property for borders --->
			<cfset thisColSpan = "2">
	  </cfsilent>
	  <tr height="1px">
		  <td align="left" valign="top" colspan="2" class="<cfoutput>#thisContentClass#</cfoutput>"></td>
	  </tr>
	<cfif session.isMobile>
	  <tr valign="middle">
		<td class="<cfoutput>#thisContentClass#</cfoutput>" colspan="2">
			<label for="firstName">First Name</label>
		</td>
	   </tr>
	   <tr>
		<td class="<cfoutput>#thisContentClass#</cfoutput>" colspan="2">
			<input id="firstName" name="firstName" type="text" value="<cfoutput>#firstName#</cfoutput>" required validationMessage="First Name is required" class="k-textbox" style="width: 95%" />    
		</td>
	  </tr>
	<cfelse><!---<cfif session.isMobile>--->
	  <tr height="30px">
		<td align="right" width="15%" class="<cfoutput>#thisContentClass#</cfoutput>"> 
			<label for="firstName">First Name</label>
		</td>
		<td width="85%" class="<cfoutput>#thisContentClass#</cfoutput>">
			<input id="firstName" name="firstName" type="text" value="<cfoutput>#firstName#</cfoutput>" required validationMessage="First Name is required" class="k-textbox" style="width: 40%" />    
		</td>
	  </tr>
	</cfif>
	  <!-- Border -->
	  <tr height="2px">
		  <td align="left" valign="top" colspan="<cfoutput>#thisColSpan#</cfoutput>" class="<cfoutput>#thisContentClass#</cfoutput>"></td>
	  </tr>
	  <cfsilent>
	  <!--- Set the class for alternating rows. --->
	  <!---After the first row, the content class should be the current class. --->
	  <cfset thisContentClass = HtmlUtilsObj.getKendoClass(thisContentClass)>
	  </cfsilent>
	  <tr height="2px">
		  <td align="left" valign="top" colspan="2" class="border <cfoutput>#thisContentClass#</cfoutput>"></td>
	  </tr>
	  <!-- Form content -->
	<cfif session.isMobile>
	  <tr valign="middle">
		<td class="<cfoutput>#thisContentClass#</cfoutput>" colspan="2">
			<label for="lastName">Last Name</label>
		</td>
	   </tr>
	   <tr>
		<td class="<cfoutput>#thisContentClass#</cfoutput>" colspan="2">
			<input id="lastName" name="lastName" type="text" value="<cfoutput>#lastName#</cfoutput>" required validationMessage="Last Name is required" class="k-textbox" style="width: 95%" />  
		</td>
	  </tr>
	<cfelse><!---<cfif session.isMobile>--->
	  <tr valign="middle" height="30px">
		<td align="right" valign="middle" width="10%" class="<cfoutput>#thisContentClass#</cfoutput>">
			<label for="lastName">Last Name</label>
		</td>
		<td align="left" width="90%" class="<cfoutput>#thisContentClass#</cfoutput>">
			<input id="lastName" name="lastName" type="text" value="<cfoutput>#lastName#</cfoutput>" required validationMessage="Last Name is required" class="k-textbox" style="width: 40%" /> 
		</td>
	  </tr>
	</cfif>
	  <!-- Border -->
	  <tr height="2px">
		  <td align="left" valign="top" colspan="<cfoutput>#thisColSpan#</cfoutput>" class="<cfoutput>#thisContentClass#</cfoutput>"></td>
	  </tr>
	  <cfsilent>
	  <!--- Set the class for alternating rows. --->
	  <!---After the first row, the content class should be the current class. --->
	  <cfset thisContentClass = HtmlUtilsObj.getKendoClass(thisContentClass)>
	  </cfsilent>
	  <tr height="2px">
		  <td align="left" valign="top" colspan="2" class="border <cfoutput>#thisContentClass#</cfoutput>"></td>
	  </tr>
	<cfif session.isMobile>
	  <tr valign="middle">
		<td class="<cfoutput>#thisContentClass#</cfoutput>" colspan="2">
			<label for="displayName">Public Display Name</label>
		</td>
	   </tr>
	   <tr>
		<td class="<cfoutput>#thisContentClass#</cfoutput>" colspan="2">
			<input id="displayName" name="displayName" type="text" value="<cfoutput>#displayName#</cfoutput>" required validationMessage="Public Display Name is required" class="k-textbox" style="width: 95%" /> 
		</td>
	  </tr>
	<cfelse><!---<cfif session.isMobile>--->
	  <!-- Form content -->
	  <tr valign="middle" height="30px">
		<td align="right" valign="middle" width="10%" class="<cfoutput>#thisContentClass#</cfoutput>">
			<label for="displayName">Public Display Name</label>
		</td>
		<td align="left" width="90%" class="<cfoutput>#thisContentClass#</cfoutput>">
			<input id="displayName" name="displayName" type="text" value="<cfoutput>#displayName#</cfoutput>" required validationMessage="Public Display Name is required" class="k-textbox" style="width: 40%" /> 
		</td>
	  </tr>
	</cfif>
	  <!-- Border -->
	  <tr height="2px">
		  <td align="left" valign="top" colspan="<cfoutput>#thisColSpan#</cfoutput>" class="<cfoutput>#thisContentClass#</cfoutput>"></td>
	  </tr>
	  <cfsilent>
	  <!--- Set the class for alternating rows. --->
	  <!---After the first row, the content class should be the current class. --->
	  <cfset thisContentClass = HtmlUtilsObj.getKendoClass(thisContentClass)>
	  </cfsilent>
	  <tr height="2px">
		  <td align="left" valign="top" colspan="2" class="border <cfoutput>#thisContentClass#</cfoutput>"></td>
	  </tr>
	  <!-- Form content -->
	<cfif session.isMobile>
	  <tr valign="middle">
		<td class="<cfoutput>#thisContentClass#</cfoutput>" colspan="2">
			<label for="email">Email</label>
		</td>
	   </tr>
	   <tr>
		<td class="<cfoutput>#thisContentClass#</cfoutput>" colspan="2">
			<input id="email" name="email" type="email" value="<cfoutput>#email#</cfoutput>" required validationMessage="Email is required" class="k-textbox" style="width: 95%" /> 
		</td>
	  </tr>
	<cfelse><!---<cfif session.isMobile>--->
	  <tr valign="middle" height="30px">
		<td align="right" valign="middle" class="<cfoutput>#thisContentClass#</cfoutput>">
			<label for="email">Email</label>
		</td>
		<td align="left" class="<cfoutput>#thisContentClass#</cfoutput>">
			<input id="email" name="email" type="email" value="<cfoutput>#email#</cfoutput>" required validationMessage="Email is required" class="k-textbox" style="width: 65%" /> 
		</td>
	  </tr>
	</cfif>
	  <!-- Border -->
	  <tr height="2px">
		  <td align="left" valign="top" colspan="<cfoutput>#thisColSpan#</cfoutput>" class="<cfoutput>#thisContentClass#</cfoutput>"></td>
	  </tr>
	  <cfsilent>
	  <!--- Set the class for alternating rows. --->
	  <!---After the first row, the content class should be the current class. --->
	  <cfset thisContentClass = HtmlUtilsObj.getKendoClass(thisContentClass)>
	  </cfsilent>
	  <tr height="2px">
		  <td align="left" valign="top" colspan="2" class="border <cfoutput>#thisContentClass#</cfoutput>"></td>
	  </tr>
	  <!-- Form content -->
	<cfif session.isMobile>
	  <tr valign="middle">
		<td class="<cfoutput>#thisContentClass#</cfoutput>" colspan="2">
			<label for="webSite">Website</label>
		</td>
	   </tr>
	   <tr>
		<td class="<cfoutput>#thisContentClass#</cfoutput>" colspan="2">
			<input id="webSite" name="webSite" type="url" value="<cfoutput>#webSite#</cfoutput>" class="k-textbox" style="width: 95%" /> 
		</td>
	  </tr>
	<cfelse><!---<cfif session.isMobile>--->
	  <tr height="30px">
		<td align="right" class="<cfoutput>#thisContentClass#</cfoutput>"> 
			<label for="webSite">Website</label>
		</td>
		<td class="<cfoutput>#thisContentClass#</cfoutput>">
			<input id="webSite" name="webSite" type="url" value="<cfoutput>#webSite#</cfoutput>" class="k-textbox" style="width: 65%" />   
		</td>
	  </tr>
	</cfif>
   	  <!-- Border -->
	  <tr height="2px">
		  <td align="left" valign="top" colspan="<cfoutput>#thisColSpan#</cfoutput>" class="<cfoutput>#thisContentClass#</cfoutput>"></td>
	  </tr>
	  <cfsilent>
	  <!--- Set the class for alternating rows. --->
	  <!---After the first row, the content class should be the current class. --->
	  <cfset thisContentClass = HtmlUtilsObj.getKendoClass(thisContentClass)>
	  </cfsilent>
	  <tr height="2px">
		  <td align="left" valign="top" colspan="2" class="border <cfoutput>#thisContentClass#</cfoutput>"></td>
	  </tr>
	  <!-- Form content -->
	<cfif session.isMobile>
	  <tr valign="middle">
		<td class="<cfoutput>#thisContentClass#</cfoutput>" colspan="2">
			<label for="userName">User Name</label>
		</td>
	   </tr>
	   <tr>
		<td class="<cfoutput>#thisContentClass#</cfoutput>" colspan="2">
			<input id="userName" name="userName" type="text" value="<cfoutput>#userName#</cfoutput>" required validationMessage="Username is required" autocomplete="username" class="k-textbox" style="width: 66%" />    
		</td>
	  </tr>
	<cfelse><!---<cfif session.isMobile>--->
	  <tr height="30px">
		<td align="right" class="<cfoutput>#thisContentClass#</cfoutput>"> 
			<label for="userName">User Name</label>
		</td>
		<td class="<cfoutput>#thisContentClass#</cfoutput>">
			<input id="userName" name="userName" type="text" value="<cfoutput>#userName#</cfoutput>" required validationMessage="Username is required" autocomplete="username" class="k-textbox" style="width: 33%" />    
		</td>
	  </tr>
	</cfif>
	  <!-- Border -->
	  <tr height="2px">
		  <td align="left" valign="top" colspan="<cfoutput>#thisColSpan#</cfoutput>" class="<cfoutput>#thisContentClass#</cfoutput>"></td>
	  </tr>
	  <cfsilent>
	  <!--- Set the class for alternating rows. --->
	  <!---After the first row, the content class should be the current class. --->
	  <cfset thisContentClass = HtmlUtilsObj.getKendoClass(thisContentClass)>
	  </cfsilent>
	  <tr height="2px">
		  <td align="left" valign="top" colspan="2" class="border <cfoutput>#thisContentClass#</cfoutput>"></td>
	  </tr>
	  <!-- Form content -->
	<cfif session.isMobile>
	  <tr valign="middle">
		<td class="<cfoutput>#thisContentClass#</cfoutput>" colspan="2">
			<label for="password"><cfif detailAction eq 'update'>Encrypted Password<cfelse>Temp Password</cfif></label>
		</td>
	   </tr>
	   <tr>
		<td class="<cfoutput>#thisContentClass#</cfoutput>" colspan="2">
			<input id="password" name="password" type="password" value="<cfoutput>#password#</cfoutput>" required validationMessage="Password is required" autocomplete="new-password" class="k-textbox" style="width: 66%" <cfif detailAction eq 'update'>onClick="showPasswordNote()"</cfif> onBlur="createAdminInterfaceWindow(9, 'confirmPassword');" /><br/>
			Note: the blog does not store the password other than in encrypted form. The actual password can't be retrieved and is not stored.
		</td>
	  </tr>
	<cfelse><!---<cfif session.isMobile>--->
	  <tr valign="middle" height="30px">
		<td align="right" valign="middle" class="<cfoutput>#thisContentClass#</cfoutput>">
			<label for="password"><cfif detailAction eq 'update'>Encrypted Password<cfelse>Password</cfif></label>
		</td>
		<td align="left" class="<cfoutput>#thisContentClass#</cfoutput>">
			<input id="password" name="password" type="password" value="<cfoutput>#password#</cfoutput>" required validationMessage="Password is required" autocomplete="new-password" class="k-textbox" style="width: 33%" <cfif detailAction eq 'update'>onClick="showPasswordNote()"</cfif> onBlur="createAdminInterfaceWindow(9, 'confirmPassword');" /><br/> 
			Note: the blog does not store the password other than in encrypted form. The actual password is not stored.
		</td>
	  </tr>
	</cfif>
	  <!-- Border -->
	  <tr height="2px">
		  <td align="left" valign="top" colspan="<cfoutput>#thisColSpan#</cfoutput>" class="<cfoutput>#thisContentClass#</cfoutput>"></td>
	  </tr>
	  <cfsilent>
	  <!--- Set the class for alternating rows. --->
	  <!---After the first row, the content class should be the current class. --->
	  <cfset thisContentClass = HtmlUtilsObj.getKendoClass(thisContentClass)>
	  </cfsilent>
	  <tr height="2px">
		  <td align="left" valign="top" colspan="2" class="border <cfoutput>#thisContentClass#</cfoutput>"></td>
	  </tr>
	<cfif session.isMobile>
	  <tr valign="middle">
		<td class="<cfoutput>#thisContentClass#</cfoutput>" colspan="2">
			<label for="role">Roles</label>
		</td>
	   </tr>
	   <tr>
		<td class="<cfoutput>#thisContentClass#</cfoutput>" colspan="2">
			<select id="roleDropdown" name="roleDropdown" required validationMessage="Role is required" style="width: 95%; font-weight: 300;"></select>   
		</td>
	  </tr>
	<cfelse><!---<cfif session.isMobile>--->
	  <!-- Form content -->
	  <tr valign="middle" height="30px">
		<td align="right" valign="middle" class="<cfoutput>#thisContentClass#</cfoutput>">
			<label for="role">Roles</label>
		</td>
		<td align="left" class="<cfoutput>#thisContentClass#</cfoutput>">
			<select id="roleDropdown" name="roleDropdown" required validationMessage="Role is required" style="width: 45%; font-weight: 300;"></select>   
		</td>
	  </tr>
	</cfif>
	  <!-- Border -->
	  <tr height="2px">
		  <td align="left" valign="top" colspan="<cfoutput>#thisColSpan#</cfoutput>" class="<cfoutput>#thisContentClass#</cfoutput>"></td>
	  </tr>
	  <cfsilent>
	  <!--- Set the class for alternating rows. --->
	  <!---After the first row, the content class should be the current class. --->
	  <cfset thisContentClass = HtmlUtilsObj.getKendoClass(thisContentClass)>
	  </cfsilent>
	  <tr height="2px">
		  <td align="left" valign="top" colspan="2" class="border <cfoutput>#thisContentClass#</cfoutput>"></td>
	  </tr>
	  <!-- Form content -->
	<cfif session.isMobile>
	  <tr valign="middle">
		<td class="<cfoutput>#thisContentClass#</cfoutput>" colspan="2">
			<label for="capabilityDropdown">Site Capabilities</label>
		</td>
	   </tr>
	   <tr>
		<td class="<cfoutput>#thisContentClass#</cfoutput>" colspan="2">
			<select id="capabilityDropdown" name="capabilityDropdown" required validationMessage="Capability is required" style="width: 95%; font-weight: 300;"></select> 
		</td>
	  </tr>
	<cfelse><!---<cfif session.isMobile>--->
	  <tr valign="middle" height="30px" class="<cfoutput>#thisContentClass#</cfoutput>">
		<td align="right" valign="middle">
			<label for="capabilityDropdown">Site Capabilities</label>
		</td>
		<td align="left" class="<cfoutput>#thisContentClass#</cfoutput>">
			<select id="capabilityDropdown" name="capabilityDropdown" required validationMessage="Capability is required" style="width: 100%; font-weight: 300;"></select> 
		</td>
	  </tr>
	</cfif>
	  <!-- Border -->
	  <tr height="2px">
		  <td align="left" valign="top" colspan="<cfoutput>#thisColSpan#</cfoutput>" class="<cfoutput>#thisContentClass#</cfoutput>"></td>
	  </tr>
	  <!--- User log in history --->
<cfif isDefined("currentUserRole") gt 0 and (userName eq session.userName or currentUserRole eq 'Administrator')>
	  <cfsilent>
	  <!--- Set the class for alternating rows. --->
	  <!---After the first row, the content class should be the current class. --->
	  <cfset thisContentClass = HtmlUtilsObj.getKendoClass(thisContentClass)>
	  </cfsilent>
	  <tr height="2px">
		  <td align="left" valign="top" colspan="2" class="border <cfoutput>#thisContentClass#</cfoutput>"></td>
	  </tr>
	<cfif session.isMobile>
	  <tr valign="middle">
		<td class="<cfoutput>#thisContentClass#</cfoutput>" colspan="2">
			<label>Logs</label>
		</td>
	   </tr>
	   <tr>
		<td class="<cfoutput>#thisContentClass#</cfoutput>" colspan="2">
			<button id="logonHistory" class="k-button normalFontWeight" type="button" style="width: 175px" onClick="javascript:createAdminInterfaceWindow(10, '<cfoutput>#userName#</cfoutput>');">Login History</button>
		</td>
	  </tr>
	<cfelse><!---<cfif session.isMobile>--->
	  <!-- Form content -->  
	  <tr valign="middle" height="30px">
		<td valign="bottom" align="right" class="<cfoutput>#thisContentClass#</cfoutput>">
			<label>Logs</label>
		</td>
		<td valign="bottom" align="left" class="<cfoutput>#thisContentClass#</cfoutput>">
			<button id="logonHistory" class="k-button normalFontWeight" type="button" style="width: 175px" onClick="javascript:createAdminInterfaceWindow(10, '<cfoutput>#userName#</cfoutput>');">Login History</button>
		</td>
	  </tr>
	</cfif><!---<cfif session.isMobile>--->
</cfif><!---<cfif structKeyExists(URL, "userName")>--->
	<!--- There is no need to notify the user if you're editing your own user details --->
	<!---<cfif not structKeyExists(URL, "userName") or session.userName neq URL.userName>--->
	  <!-- Border -->
	  <tr height="2px">
		  <td align="left" valign="top" colspan="<cfoutput>#thisColSpan#</cfoutput>" class="<cfoutput>#thisContentClass#</cfoutput>"></td>
	  </tr>
	  <cfsilent>
	  <!--- Set the class for alternating rows. --->
	  <!---After the first row, the content class should be the current class. --->
	  <cfset thisContentClass = HtmlUtilsObj.getKendoClass(thisContentClass)>
	  </cfsilent>
	  <tr height="2px">
		  <td align="left" valign="top" colspan="2" class="border <cfoutput>#thisContentClass#</cfoutput>"></td>
	  </tr>
	  <!-- Form content -->
<cfif userName neq session.userName>
	<cfif session.isMobile>
	  <tr valign="middle">
		<td class="<cfoutput>#thisContentClass#</cfoutput>" colspan="2">
			<label for="notify">Notify User</label>
		</td>
	   </tr>
	   <tr>
		<td class="<cfoutput>#thisContentClass#</cfoutput>" colspan="2">
			<input type="checkbox" name="notify" id="notify" checked>  
		</td>
	  </tr>
	<cfelse><!---<cfif session.isMobile>--->
	  <tr valign="middle" height="30px">
		<td align="right" valign="middle" class="<cfoutput>#thisContentClass#</cfoutput>">
			<label for="notify">Notify User</label>
		</td>
		<td align="left" class="<cfoutput>#thisContentClass#</cfoutput>">
			<input type="checkbox" name="notify" id="notify" checked>  
		</td>
	  </tr>
	</cfif>
</cfif><!---<cfif userName neq session.userName>--->
	<!---</cfif><cfif not structKeyExists(URL, "userName") or session.userName neq URL.userName>--->
	  <!-- Border -->
	  <tr height="2px">
		  <td align="left" valign="top" colspan="<cfoutput>#thisColSpan#</cfoutput>" class="<cfoutput>#thisContentClass#</cfoutput>"></td>
	  </tr>
	  <cfsilent>
	  <!--- Set the class for alternating rows. --->
	  <!---After the first row, the content class should be the current class. --->
	  <cfset thisContentClass = HtmlUtilsObj.getKendoClass(thisContentClass)>
	  </cfsilent>
	  <tr height="2px">
		  <td align="left" valign="top" colspan="2" class="border <cfoutput>#thisContentClass#</cfoutput>"></td>
	  </tr>
	  <!-- Submit -->
	  <tr valign="middle" height="30px">
		<td valign="bottom" align="right" class="<cfoutput>#thisContentClass#</cfoutput>">&nbsp;</td>
		<td valign="bottom" align="left" class="<cfoutput>#thisContentClass#</cfoutput>">
			<button id="userDetailSubmit" name="userDetailSubmit" class="k-button k-primary" type="button">Submit</button>
		</td>
	  </tr>
	</table>
	</form>
		
</cfcase>
				
<!--- //************************************************************************************************
		New Role
//**************************************************************************************************--->
				
<cfcase value="8">
	
	<!--- Get the list of roleIds (a user should only be one role at in V2). We can either extract a roleId list, or a role list. Here, we want to get the actual role name (roleList) --->
	<cfset currentRolesList = application.blog.getBlogRolesList()>
		
	<script>
		// !!! Note on the validators, all forms need a name attribute, otherwise the positioning of the messages will not work. --->
		$(document).ready(function() {

			var newRoleValidator = $("#newRoleForm").kendoValidator({
				// Set up custom validation rules 
				rules: {
					// The role must be unique. 
					roleIsUnique:
					function(input){
						// Do not continue if the user name is found in the currentUserName list 
						if (input.is("[id='subNewRole']") && ( listFind( currentRolesList, input.val() ) != 0 ) ){
							// Display an error on the page.
							input.attr("data-roleIsUnique-msg", "Role already exists");
							// Focus on the current element
							$( "#subNewRole" ).focus();
							return false;
						}                                    
						return true;
					},
				}
			}).data("kendoValidator");

			// Invoked when the submit button is clicked. Insted of using '$("form").submit(function(event) {' and 'event.preventDefault();', We are using direct binding here to speed up the event.
			var newRoleSubmit = $('#newRoleSubmit');
			newRoleSubmit.on('click', function(e){  
				
				e.preventDefault();         
				if (newRoleValidator.validate()) {
					
					// Open up a please wait dialog
					$.when(kendo.ui.ExtWaitDialog.show({ title: "Please wait...", message: "Please wait while we process the user.", icon: "k-ext-information" }));
					
					// Get the value of the newRole that was typed in
					subNewRole = $("#subNewRole").val();
					// Get the new role desc
					subNewRoleDesc = $("#subNewRoleDesc").val();
					
					// Input the both the role name and desc in the hidden forms on the add user page. These forms all must have unique names
					$("#newRole").val(subNewRole);
					// Populate the new role desc
					$("#newRoleDesc").val(subNewRoleDesc);
					
					// Send data to server after the new role was saved into the hidden form
					setTimeout(function() {
						postUserDetails('insert');
					}, 250);
					
					// Close the window.
					$('#roleNameWindow').kendoWindow('destroy');
					
				} else {

					$.when(kendo.ui.ExtAlertDialog.show({ title: "There are errors", message: "Please correct the highlighted fields and try again", width: "<cfoutput>#application.kendoExtendedUiWindowWidth#</cfoutput>", icon: "k-ext-warning" }) // or k-ext-error, k-ext-question
						).done(function () {
						// Do nothing
					});
				}
			});

		});//...document.ready
		
		// Create a list to validate if the role is already in use.
		var currentRolesList = '<cfoutput>#currentRolesList#</cfoutput>';
		
	</script>
	
	<form id="newRoleForm" action="#" method="post" data-role="validator">
	<!--- Pass the csrfToken --->
	<input type="hidden" name="csrfToken" id="csrfToken" value="<cfoutput>#csrfToken#</cfoutput>" />
	<input type="hidden" name="currentRoles" id="currentRoles" value=""/>
	<table align="center" class="k-content tableBorder" width="100%" cellpadding="2" cellspacing="0" border="0">
	  <cfset thisContentClass = "">
	  
	  <tr height="1px">
		<td align="left" valign="top" colspan="2"></td>
	  </tr>
	  <tr height="1px">
		<td align="left" valign="top" colspan="2">You're using a new role. Please enter in a short role name and description so that you can assign this permission setting for a new user in the future.</td>
	  </tr>
	  <tr height="2px">
		<td align="left" valign="top" colspan="2"></td>
	  </tr>
	  <tr height="2px">
		<td align="left" valign="top" colspan="2" class="border"></td>
	  </tr>
	  <tr height="1px">
		<td align="left" valign="top" colspan="2"></td>
	  </tr>
	<cfif session.isMobile>
	  <tr valign="middle">
		<td class="<cfoutput>#thisContentClass#</cfoutput>" colspan="2">
			<label for="roleName">Role Name</label>
		</td>
	   </tr>
	   <tr>
		<td class="<cfoutput>#thisContentClass#</cfoutput>" colspan="2">
			<input id="subNewRole" name="subNewRole" type="text" required validationMessage="Role Name is required" style="width: 95%" />   
		</td>
	  </tr>
	<cfelse><!---<cfif session.isMobile>--->
	  <tr height="30px">
		<td align="right" width="25%"> 
			<label for="roleName">Role Name</label>
		</td>
		<td width="75%">
			<input id="subNewRole" name="subNewRole" type="text" required validationMessage="Role Name is required" style="width: 40%" />    
		</td>
	  </tr>
	</cfif>
	  <!-- Border -->
	  <tr height="2px">
		  <td align="left" valign="top" colspan="2" class="<cfoutput>#thisContentClass#</cfoutput>"></td>
	  </tr>
	  <cfsilent>
	  <!--- Set the class for alternating rows. --->
	  <!---After the first row, the content class should be the current class. --->
	  <cfset thisContentClass = HtmlUtilsObj.getKendoClass(thisContentClass)>
	  </cfsilent>
	  <tr height="2px">
		  <td align="left" valign="top" colspan="2" class="border <cfoutput>#thisContentClass#</cfoutput>"></td>
	  </tr>
	<cfif session.isMobile>
	  <tr valign="middle">
		<td class="<cfoutput>#thisContentClass#</cfoutput>" colspan="2">
			<label for="subNewRoleDesc">Description</label>
		</td>
	   </tr>
	   <tr>
		<td class="<cfoutput>#thisContentClass#</cfoutput>" colspan="2">
			<input id="subNewRoleDesc" name="subNewRoleDesc" type="text" style="width: 95%" />  
		</td>
	  </tr>
	<cfelse><!---<cfif session.isMobile>--->
	  <!-- Form content -->
	  <tr valign="middle" height="30px">
		<td align="right" valign="middle" class="<cfoutput>#thisContentClass#</cfoutput>">
			<label for="subNewRoleDesc">Description</label>
		</td>
		<td align="left" class="<cfoutput>#thisContentClass#</cfoutput>">
			<input id="subNewRoleDesc" name="subNewRoleDesc" type="text" style="width: 40%" />  
		</td>
	  </tr>
	</cfif>
	  <!-- Border -->
	  <tr height="2px">
		  <td align="left" valign="top" colspan="2" class="<cfoutput>#thisContentClass#</cfoutput>"></td>
	  </tr>
	  <cfsilent>
	  <!--- Set the class for alternating rows. --->
	  <!---After the first row, the content class should be the current class. --->
	  <cfset thisContentClass = HtmlUtilsObj.getKendoClass(thisContentClass)>
	  </cfsilent>
	  <tr height="2px">
		  <td align="left" valign="top" colspan="2" class="border <cfoutput>#thisContentClass#</cfoutput>"></td>
	  </tr>
	  <!-- Submit -->
	  <tr valign="middle" height="30px">
		<td valign="bottom" align="right" class="<cfoutput>#thisContentClass#</cfoutput>">&nbsp;</td>
		<td valign="bottom" align="left" class="<cfoutput>#thisContentClass#</cfoutput>">
			<button id="newRoleSubmit" name="newRoleSubmit" class="k-button k-primary" type="button">Submit</button>
		</td>
	  </tr>
	</table>
	</form>	
		
</cfcase>
				
<!--- //************************************************************************************************
		Confirm Password
//**************************************************************************************************--->
				
<cfcase value="9">
	
	<script>
		
		$(document).ready(function() {
			// !!! Note on the validators, all forms need a name attribute, otherwise the positioning of the messages will not work. --->

			// password that was typed in initially
			password = $("#password").val();
			// confirmed password that was typed in
			confirmPasswordVal = $("#confirmPassword").val();

			var confirmPasswordValidator = $("#confirmPasswordForm").kendoValidator({
				// Set up custom validation rules 
				rules: {
					// The value typed in must match the password in the previous add user form. 
					confirmedPasswordMatch: 
					function(input){
						// Do not continue if the user name is found in the currentUserName list 
						if (input.is("[id='confirmPassword']") && (input.val() != password)){
							// Display an error on the page.
							input.attr("data-confirmedPasswordMatch-msg", "Passwords don't  match");
							// Focus on the current element
							$( "#confirmPassword" ).focus();
							return false;
						}                                    
						return true;
					},
				}
			}).data("kendoValidator");

			// Invoked when the submit button is clicked. Insted of using '$("form").submit(function(event) {' and 'event.preventDefault();', We are using direct binding here to speed up the event.
			var confirmPasswordSubmit = $('#confirmPasswordSubmit');
			confirmPasswordSubmit.on('click', function(e){  
				e.preventDefault();         
				if (confirmPasswordValidator.validate()) {
					// Close the window.
					$('#confirmPasswordWindow').kendoWindow('destroy');
				}
			});
		});//...document.ready
	</script>
	
	<form id="confirmPasswordForm" action="#" method="post" data-role="validator">
	<!--- Pass the csrfToken --->
	<input type="hidden" name="csrfToken" id="csrfToken" value="<cfoutput>#csrfToken#</cfoutput>" />
	<table align="center" class="k-content tableBorder" width="100%" cellpadding="2" cellspacing="0" border="0">
	  <cfsilent>
			<!---The first content class in the table should be empty. --->
			<cfset thisContentClass = HtmlUtilsObj.getKendoClass('')>
			<!--- Set the colspan property for borders --->
			<cfset thisColSpan = "2">
	  </cfsilent>
	  <tr height="1px">
		  <td align="left" valign="top" colspan="2" class="<cfoutput>#thisContentClass#</cfoutput>"></td>
	  </tr>
	<cfif session.isMobile>
	  <tr valign="middle">
		<td class="<cfoutput>#thisContentClass#</cfoutput>" colspan="2">
			<label for="confirmPassword">Confirm Password</label>
		</td>
	   </tr>
	   <tr>
		<td class="<cfoutput>#thisContentClass#</cfoutput>" colspan="2">
			<input id="confirmPassword" name="confirmPassword" type="password" value="" required validationMessage="Password is required" autocomplete="new-password" style="width: 95%" />   
		</td>
	  </tr>
	<cfelse><!---<cfif session.isMobile>--->
	  <tr height="30px">
		<td align="right" width="25%" class="<cfoutput>#thisContentClass#</cfoutput>"> 
			<label for="confirmPassword">Confirm Password</label>
		</td>
		<td width="75%" class="<cfoutput>#thisContentClass#</cfoutput>">
			<input id="confirmPassword" name="confirmPassword" type="password" value="" required validationMessage="Password is required" autocomplete="new-password" style="width: 33%" />    
		</td>
	  </tr>
	</cfif>
	  <cfsilent>
	  <!--- Set the class for alternating rows. --->
	  <!--- After the first row, the content class should be the current class. --->
	  <cfset thisContentClass = HtmlUtilsObj.getKendoClass(thisContentClass)>
	  </cfsilent>
	  <tr height="2px">
		  <td align="left" valign="top" colspan="2" class="border <cfoutput>#thisContentClass#</cfoutput>"></td>
	  </tr>
	  <!-- Form content -->
	  <tr valign="middle" height="30px">
		<td valign="bottom" align="right" class="<cfoutput>#thisContentClass#</cfoutput>">&nbsp;</td>
		<td valign="bottom" align="left" class="<cfoutput>#thisContentClass#</cfoutput>">
			<button id="confirmPasswordSubmit" name="confirmPasswordSubmit" class="k-button k-primary" type="button">Submit</button>
		</td>
	  </tr>
	</table>
	</form>
		  
</cfcase>
		 
<!--- //************************************************************************************************
		Login history
//**************************************************************************************************--->
				
<cfcase value="10">
	
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
	
	<!--- Preset params --->
	<cfparam name="firstName" default="">
	<cfparam name="lastName" default="">
	<cfparam name="displayName" default="">
	<cfparam name="email" default="">
	<cfparam name="securityAnswer1" default="">
	<cfparam name="securityAnswer2" default="">
	<cfparam name="securityAnswer3" default="">
	<cfparam name="password" default="">
	<cfparam name="webSite" default="">
	
	<cfparam name="detailAction" default="update">
	
	<!--- Get user details by the username passed in the optArgs URL argument. The username and newUser will be in the URL --->
	<cfif structKeyExists(URL, "optArgs")>
		
		<!--- Get and extract user information. The optArgs should contain the user name. --->
		<cfset userDetails = application.blog.getUser(URL.optArgs)>
		<!---<cfdump var="#userDetails#">--->
		<!--- Extract the details. The values may not be present when importing the blog from BlogCfc or the previous version of GalaxieBlog for the first time --->
		<cfset userName = userDetails[1]["UserName"]>
		<cfset firstName = userDetails[1]["FirstName"]>
		<cfset lastName = userDetails[1]["LastName"]>
		<cfset displayName = userDetails[1]["DisplayName"]>
		<cfset email = userDetails[1]["Email"]>
		<cfset website = userDetails[1]["Website"]>
		<cfset securityAnswer1 = userDetails[1]["SecurityAnswer1"]>
		<cfset securityAnswer2 = userDetails[1]["SecurityAnswer2"]>
		<cfset securityAnswer3 = userDetails[1]["SecurityAnswer3"]>
		<!--- The password is needed for new users to verify on the server when populating the database --->
		<cfset tempPassword = userDetails[1]["Password"]>
			
		<script>					  
			// !!! Note on the validators, all forms need a name attribute, otherwise the positioning of the messages will not work. --->
			$(document).ready(function() {

				var userProfileValidator = $("#userProfileForm").kendoValidator({
					// Set up custom validation rules 
					rules: {
						// first name
						profileFirstNameIsNumeric:
						function(input){
							if (input.is("[id='profileFirstName']") && $.isNumeric(input.val())){
								// Display an error on the page.
								input.attr("data-profileFirstNameIsNumeric-msg", "Must be a string");
								// Focus on the current element
								$( "#profileFirstName" ).focus();
								return false;
							}                                    
							return true;
						},
						// last name
						profileLastNameIsNumeric:
						function(input){
							if (input.is("[id='profileLastName']") && $.isNumeric(input.val())){
								// Display an error on the page.
								input.attr("data-profileLastNameIsNumeric-msg", "Must be a string");
								// Focus on the current element
								$( "#profileLastName" ).focus();
								return false;
							}                                    
							return true;
						},
						// Password
						profilePasswordMinLength: 
						function(input) {
							// Trim the string of spaces before checking  
							if (input.is("[id='profilePassword']") && $.trim(input.val()).length < 6) { //
								// Display an error on the page.
								input.attr("data-profilePasswordMinLength-msg", "Must be at least 6 characters");
								// Focus on the current element
								$( "#profilePassword" ).focus();
								return false;
							}                                    
							return true;
						}
					}
				}).data("kendoValidator");

				// Invoked when the submit button is clicked. Insted of using '$("form").submit(function(event) {' and 'event.preventDefault();', We are using direct binding here to speed up the event.
				var userProfileSubmit = $('#userProfileSubmit');
				userProfileSubmit.on('click', function(e){      
					e.preventDefault();         
					if (userProfileValidator.validate()) {
						// Send data to server

						// Open up a please wait dialog
						$.when(kendo.ui.ExtWaitDialog.show({ title: "Please wait...", message: "Please wait while we process the user.", width: "<cfoutput>#application.kendoExtendedUiWindowWidth#</cfoutput>", icon: "k-ext-information" }));
						// Post the data to the server
						setTimeout(function() {
							postUserDetails('update');
						}, 250);

					} else {

						$.when(kendo.ui.ExtAlertDialog.show({ title: "There are errors", message: "Please correct the highlighted fields and try again", icon: "k-ext-warning" }) // or k-ext-error, k-ext-question
							).done(function () {
							// Do nothing
						});
					}
				});

			});//...document.ready

			// Post method on the detail form called from the deptDetailFormValidator method on the detail page. The action variable will either be 'update' or 'insert'.
			function postUserDetails(action){

				jQuery.ajax({
					type: 'post', 
					url: '<cfoutput>#application.baseUrl#</cfoutput>/common/cfc/ProxyController.cfc?method=saveUser',
					data: { // arguments
						// We are going to map the extact same arguments, in order, of the method in the cfc here. Notes: we can also use 'data: $("#userDetails").serialize()' or use the stringify method to pass it as an array of values. 
						csrfToken: '<cfoutput>#csrfToken#</cfoutput>',
						action: 'updateProfile', // either update, insert, or updateProfile.
					<cfif isDefined("URL.optArgs") and isDefined("URL.otherArgs") and URL.otherArgs eq true>
						// When a new user has been invited, we need to pass in the pkey
						pkey: '<cfoutput>#tempPassword#</cfoutput>',
						newUser: <cfoutput>#URL.otherArgs#</cfoutput>,
					</cfif>
						// Pass the form values
						firstName: $("#profileFirstName").val(),
						lastName: $("#profileLastName").val(),
						displayName: $("#profileDisplayName").val(),
						email:  $("#profileEmail").val(),
						website: $("#profileWebSite").val(),
						notify: false,
						userName: '<cfoutput>#userName#</cfoutput>',
						password: $("#profilePassword").val(),
						securityAnswer1: $("#securityAnswer1").val(),
						securityAnswer2: $("#securityAnswer2").val(),
						securityAnswer3: $("#securityAnswer3").val()
					},
					dataType: "json",
					success: userProfileUpdateResult, // calls the result function.
					error: function(ErrorMsg) {
						console.log('Error' + ErrorMsg);
					}
				// Extract any errors. This is a new jQuery promise based function as of jQuery 1.8.
				}).fail(function (jqXHR, textStatus, error) {
					// The full response is: jqXHR.responseText, but we just want to extract the error.
					$.when(kendo.ui.ExtAlertDialog.show({ title: "Error while consuming the saveUser function", message: error, icon: "k-ext-error", width: "<cfoutput>#application.kendoExtendedUiWindowWidth#</cfoutput>" }) // or k-ext-error, k-ext-information, k-ext-question, k-ext-warning.  You can also specify height.
						).done(function () {
						// Do nothing
					});		
				});
			};

			function userProfileUpdateResult(response){
				// Close the wait window that was launched in the calling function.
				kendo.ui.ExtWaitDialog.hide();
				// Prompt the user and log the user out
				$.when(kendo.ui.ExtAlertDialog.show({ title: "Your profile was saved", message: "Please log in with your new password to continue", icon: "k-ext-information", width: "425px", height: "225px"}) // or k-ext-error, k-ext-information, k-ext-question, k-ext-warning.  You can also specify height.
					).done(function () {
					window.location.href="?logout=1";
				});		
			}

		</script>
	
		<form id="userProfileForm" action="#" method="post" data-role="validator">
		<!--- Pass the csrfToken --->
		<input type="hidden" name="csrfToken" id="csrfToken" value="<cfoutput>#csrfToken#</cfoutput>" />
		<input type="hidden" name="confirmedPasword" id="confirmedPasword" value=""/>

		<table align="center" class="k-content tableBorder" width="100%" cellpadding="2" cellspacing="0" border="0">
		  <cfsilent>
				<!---The first content class in the table should be empty. --->
				<cfset thisContentClass = HtmlUtilsObj.getKendoClass('')>
				<!--- Set the colspan property for borders --->
				<cfset thisColSpan = "2">
		  </cfsilent>
		  <tr height="1px">
			  <td align="left" valign="top" colspan="2" class="<cfoutput>#thisContentClass#</cfoutput>"></td>
		  </tr>
		  <tr>
			<td align="left" class="<cfoutput>#thisContentClass#</cfoutput>" colspan="2"> 
				You have been set up with a user account to contribute to <cfoutput>#htmlEditFormat(application.BlogDbObj.getBlogTitle())#</cfoutput>. Please make any necessary changes to your profile and enter a new password to continue.
			</td>
		  </tr>
		  <!-- Border -->
		  <tr height="2px">
			  <td align="left" valign="top" colspan="<cfoutput>#thisColSpan#</cfoutput>" class="<cfoutput>#thisContentClass#</cfoutput>"></td>
		  </tr>
		  <cfsilent>
		  <!--- Set the class for alternating rows. --->
		  <!---After the first row, the content class should be the current class. --->
		  <cfset thisContentClass = HtmlUtilsObj.getKendoClass(thisContentClass)>
		  </cfsilent>
		  <tr height="2px">
			  <td align="left" valign="top" colspan="2" class="border <cfoutput>#thisContentClass#</cfoutput>"></td>
		  </tr>
		  <!-- Form content -->
		  <tr height="1px">
			  <td align="left" valign="top" colspan="2" class="<cfoutput>#thisContentClass#</cfoutput>"></td>
		  </tr>
		<cfif session.isMobile>
		  <tr valign="middle">
			<td class="<cfoutput>#thisContentClass#</cfoutput>" colspan="2">
				<label for="profileFirstName">First Name</label>
			</td>
		   </tr>
		   <tr>
			<td class="<cfoutput>#thisContentClass#</cfoutput>" colspan="2">
				<input id="profileFirstName" name="profileFirstName" type="text" value="<cfoutput>#firstName#</cfoutput>" required validationMessage="First Name is required" class="k-textbox" style="width: 95%" /> 
			</td>
		  </tr>
		<cfelse><!---<cfif session.isMobile>--->
		  <tr height="30px">
			<td align="right" width="15%" class="<cfoutput>#thisContentClass#</cfoutput>"> 
				<label for="profileFirstName">First Name</label>
			</td>
			<td width="85%" class="<cfoutput>#thisContentClass#</cfoutput>">
				<input id="profileFirstName" name="profileFirstName" type="text" value="<cfoutput>#firstName#</cfoutput>" required validationMessage="First Name is required" class="k-textbox" style="width: 40%" />    
			</td>
		  </tr>
		</cfif><!---<cfif session.isMobile>--->
		  <!-- Border -->
		  <tr height="2px">
			  <td align="left" valign="top" colspan="<cfoutput>#thisColSpan#</cfoutput>" class="<cfoutput>#thisContentClass#</cfoutput>"></td>
		  </tr>
		  <cfsilent>
		  <!--- Set the class for alternating rows. --->
		  <!---After the first row, the content class should be the current class. --->
		  <cfset thisContentClass = HtmlUtilsObj.getKendoClass(thisContentClass)>
		  </cfsilent>
		  <tr height="2px">
			  <td align="left" valign="top" colspan="2" class="border <cfoutput>#thisContentClass#</cfoutput>"></td>
		  </tr>
		  <!-- Form content -->
		<cfif session.isMobile>
		  <tr valign="middle">
			<td class="<cfoutput>#thisContentClass#</cfoutput>" colspan="2">
				<label for="profileLastName">Last Name</label>
			</td>
		   </tr>
		   <tr>
			<td class="<cfoutput>#thisContentClass#</cfoutput>" colspan="2">
				<input id="profileLastName" name="profileLastName" type="text" value="<cfoutput>#lastName#</cfoutput>" required validationMessage="Last Name is required" class="k-textbox" style="width: 95%" />
			</td>
		  </tr>
		<cfelse><!---<cfif session.isMobile>--->
		  <tr valign="middle" height="30px">
			<td align="right" valign="middle" width="10%" class="<cfoutput>#thisContentClass#</cfoutput>">
				<label for="profileLastName">Last Name</label>
			</td>
			<td align="left" width="90%" class="<cfoutput>#thisContentClass#</cfoutput>">
				<input id="profileLastName" name="profileLastName" type="text" value="<cfoutput>#lastName#</cfoutput>" required validationMessage="Last Name is required" class="k-textbox" style="width: 40%" /> 
			</td>
		  </tr>
		</cfif><!---<cfif session.isMobile>--->
		  <!-- Border -->
		  <tr height="2px">
			  <td align="left" valign="top" colspan="<cfoutput>#thisColSpan#</cfoutput>" class="<cfoutput>#thisContentClass#</cfoutput>"></td>
		  </tr>
		  <cfsilent>
		  <!--- Set the class for alternating rows. --->
		  <!---After the first row, the content class should be the current class. --->
		  <cfset thisContentClass = HtmlUtilsObj.getKendoClass(thisContentClass)>
		  </cfsilent>
		  <tr height="2px">
			  <td align="left" valign="top" colspan="2" class="border <cfoutput>#thisContentClass#</cfoutput>"></td>
		  </tr>
		  <!-- Form content -->
		<cfif session.isMobile>
		  <tr valign="middle">
			<td class="<cfoutput>#thisContentClass#</cfoutput>" colspan="2">
				<label for="profileDisplayName">Public Display Name</label>
			</td>
		   </tr>
		   <tr>
			<td class="<cfoutput>#thisContentClass#</cfoutput>" colspan="2">
				<input id="profileDisplayName" name="profileDisplayName" type="text" value="<cfoutput>#displayName#</cfoutput>" required validationMessage="Public Display Name is required" class="k-textbox" style="width: 95%" /> 
			</td>
		  </tr>
		<cfelse><!---<cfif session.isMobile>--->
		  <tr valign="middle" height="30px">
			<td align="right" valign="middle" width="20%" class="<cfoutput>#thisContentClass#</cfoutput>">
				<label for="profileDisplayName">Public Display Name</label>
			</td>
			<td align="left" width="80%" class="<cfoutput>#thisContentClass#</cfoutput>">
				<input id="profileDisplayName" name="profileDisplayName" type="text" value="<cfoutput>#displayName#</cfoutput>" required validationMessage="Public Display Name is required" class="k-textbox" style="width: 40%" /> 
			</td>
		  </tr>
		</cfif><!---<cfif session.isMobile>--->
		  <!-- Border -->
		  <tr height="2px">
			  <td align="left" valign="top" colspan="<cfoutput>#thisColSpan#</cfoutput>" class="<cfoutput>#thisContentClass#</cfoutput>"></td>
		  </tr>
		  <cfsilent>
		  <!--- Set the class for alternating rows. --->
		  <!---After the first row, the content class should be the current class. --->
		  <cfset thisContentClass = HtmlUtilsObj.getKendoClass(thisContentClass)>
		  </cfsilent>
		  <tr height="2px">
			  <td align="left" valign="top" colspan="2" class="border <cfoutput>#thisContentClass#</cfoutput>"></td>
		  </tr>
		<cfif session.isMobile>
		  <tr valign="middle">
			<td class="<cfoutput>#thisContentClass#</cfoutput>" colspan="2">
				<label for="profileEmail">Email</label>
			</td>
			</td>
		   </tr>
		   <tr>
			<td class="<cfoutput>#thisContentClass#</cfoutput>" colspan="2">
				<input type="email" id="profileEmail" name="profileEmail" value="<cfoutput>#email#</cfoutput>" required validationMessage="Email is required" class="k-textbox" style="width: 95%" /> 
			</td>
		  </tr>
		<cfelse><!---<cfif session.isMobile>--->
		  <!-- Form content -->
		  <tr valign="middle" height="30px">
			<td align="right" valign="middle" class="<cfoutput>#thisContentClass#</cfoutput>">
				<label for="profileEmail">Email</label>
			</td>
			<td align="left" class="<cfoutput>#thisContentClass#</cfoutput>">
				<input type="email" id="profileEmail" name="profileEmail" value="<cfoutput>#email#</cfoutput>" required validationMessage="Email is required" class="k-textbox" style="width: 65%" /> 
			</td>
		  </tr>
		</cfif><!---<cfif session.isMobile>--->
		  <!-- Border -->
		  <tr height="2px">
			  <td align="left" valign="top" colspan="<cfoutput>#thisColSpan#</cfoutput>" class="<cfoutput>#thisContentClass#</cfoutput>"></td>
		  </tr>
		  <cfsilent>
		  <!--- Set the class for alternating rows. --->
		  <!---After the first row, the content class should be the current class. --->
		  <cfset thisContentClass = HtmlUtilsObj.getKendoClass(thisContentClass)>
		  </cfsilent>
		  <tr height="2px">
			  <td align="left" valign="top" colspan="2" class="border <cfoutput>#thisContentClass#</cfoutput>"></td>
		  </tr>
		  <!-- Form content -->
		<cfif session.isMobile>
		  <tr valign="middle">
			<td class="<cfoutput>#thisContentClass#</cfoutput>" colspan="2">
				<label for="profileWebSite">Website</label>
			</td>
		   </tr>
		   <tr>
			<td class="<cfoutput>#thisContentClass#</cfoutput>" colspan="2">
				<input type="url" id="profileWebSite" name="profileWebSite" value="<cfoutput>#webSite#</cfoutput>" class="k-textbox" style="width: 95%" /> 
			</td>
		  </tr>
		<cfelse><!---<cfif session.isMobile>--->
		  <tr height="30px">
			<td align="right" class="<cfoutput>#thisContentClass#</cfoutput>"> 
				<label for="profileWebSite">Website</label>
			</td>
			<td class="<cfoutput>#thisContentClass#</cfoutput>">
				<input type="url" id="profileWebSite" name="profileWebSite" value="<cfoutput>#webSite#</cfoutput>" class="k-textbox" style="width: 65%" />    
			</td>
		  </tr>
		</cfif><!---<cfif session.isMobile>--->
		  <!-- Border -->
		  <tr height="2px">
			  <td align="left" valign="top" colspan="<cfoutput>#thisColSpan#</cfoutput>" class="<cfoutput>#thisContentClass#</cfoutput>"></td>
		  </tr>
		  <cfsilent>
		  <!--- Set the class for alternating rows. --->
		  <!---After the first row, the content class should be the current class. --->
		  <cfset thisContentClass = HtmlUtilsObj.getKendoClass(thisContentClass)>
		  </cfsilent>
		  <tr height="2px">
			  <td align="left" valign="top" colspan="2" class="border <cfoutput>#thisContentClass#</cfoutput>"></td>
		  </tr>
		  <!-- Form content -->
		<cfif session.isMobile>
		  <tr valign="middle">
			<td class="<cfoutput>#thisContentClass#</cfoutput>" colspan="2">
				<label for="profilePassword">Password</label>
			</td>
		   </tr>
		   <tr>
			<td class="<cfoutput>#thisContentClass#</cfoutput>" colspan="2">
				<input type="password" id="profilePassword" name="profilePassword" value="<cfoutput>#password#</cfoutput>" required validationMessage="Password is required" autocomplete="new-password" class="k-textbox" style="width: 95%" /> 
			</td>
		  </tr>
		<cfelse><!---<cfif session.isMobile>--->
		  <tr valign="middle" height="30px">
			<td align="right" valign="middle" class="<cfoutput>#thisContentClass#</cfoutput>">
				<label for="profilePassword">Password</label>
			</td>
			<td align="left" class="<cfoutput>#thisContentClass#</cfoutput>">
				<input type="password" id="profilePassword" name="profilePassword" value="<cfoutput>#password#</cfoutput>" required validationMessage="Password is required" autocomplete="new-password" class="k-textbox" style="width: 33%" /> 
			</td>
		  </tr>
		</cfif><!---<cfif session.isMobile>--->
		  <!-- Border -->
		  <tr height="2px">
			  <td align="left" valign="top" colspan="<cfoutput>#thisColSpan#</cfoutput>" class="<cfoutput>#thisContentClass#</cfoutput>"></td>
		  </tr>
		  <cfsilent>
		  <!--- Set the class for alternating rows. --->
		  <!---After the first row, the content class should be the current class. --->
		  <cfset thisContentClass = HtmlUtilsObj.getKendoClass(thisContentClass)>
		  </cfsilent>
		  <tr height="2px">
			  <td align="left" valign="top" colspan="2" class="border <cfoutput>#thisContentClass#</cfoutput>"></td>
		  </tr>
		
		  <tr height="2px">
			  <td align="center" valign="top" colspan="2" class="border <cfoutput>#thisContentClass#</cfoutput>">Security Questions</td>
		  </tr>
		  <!--- New table for security questions. --->
		  <tr height="2px">
			  <td align="left" valign="top" colspan="2" class="<cfoutput>#thisContentClass#</cfoutput>">
				  
				  <table align="center" class="k-content" width="100%" cellpadding="2" cellspacing="0" border="0">
				  	  <!-- Border -->
					  <tr height="2px">
						  <td align="left" valign="top" colspan="<cfoutput>#thisColSpan#</cfoutput>" class="<cfoutput>#thisContentClass#</cfoutput>"></td>
					  </tr>
					  <cfsilent>
					  <!--- Set the class for alternating rows. --->
					  <!---After the first row, the content class should be the current class. --->
					  <cfset thisContentClass = HtmlUtilsObj.getKendoClass(thisContentClass)>
					  </cfsilent>
					  <tr height="2px">
						  <td align="left" valign="top" colspan="2" class="border <cfoutput>#thisContentClass#</cfoutput>"></td>
					  </tr>
					  <!-- Form content -->
					<cfif session.isMobile>
					  <tr valign="middle">
						<td class="<cfoutput>#thisContentClass#</cfoutput>" colspan="2">
							<label for="securityAnswer1">What is the name of your favorite pet?</label
						</td>
					   </tr>
					   <tr>
						<td class="<cfoutput>#thisContentClass#</cfoutput>" colspan="2">
							<input type="text" id="securityAnswer1" name="securityAnswer1" value="<cfoutput>#securityAnswer1#</cfoutput>" class="k-textbox" required validationMessage="Name of favorite pet is required" style="width:95%" />
						</td>
					  </tr>
					<cfelse><!---<cfif session.isMobile>--->
					  <tr valign="middle">
						<td align="right" valign="middle" class="<cfoutput>#thisContentClass#</cfoutput>" width="60%">
							<label for="securityAnswer1">What is the name of your favorite pet?</label>
						</td>
						<td align="left" class="<cfoutput>#thisContentClass#</cfoutput>" height="30px">
							<input type="text" id="securityAnswer1" name="securityAnswer1" value="<cfoutput>#securityAnswer1#</cfoutput>" class="k-textbox" required validationMessage="Name of favorite pet is required" style="width:66%" /> 
						</td>
					  </tr>
					</cfif><!---<cfif session.isMobile>--->
					  <!-- Border -->
					  <tr height="2px">
						  <td align="left" valign="top" colspan="<cfoutput>#thisColSpan#</cfoutput>" class="<cfoutput>#thisContentClass#</cfoutput>"></td>
					  </tr>
					  <cfsilent>
					  <!--- Set the class for alternating rows. --->
					  <!---After the first row, the content class should be the current class. --->
					  <cfset thisContentClass = HtmlUtilsObj.getKendoClass(thisContentClass)>
					  </cfsilent>
					  <tr height="2px">
						  <td align="left" valign="top" colspan="2" class="border <cfoutput>#thisContentClass#</cfoutput>"></td>
					  </tr>
					  <!-- Form content -->
					<cfif session.isMobile>
					  <tr valign="middle">
						<td class="<cfoutput>#thisContentClass#</cfoutput>" colspan="2">
							<label for="securityAnswer2">What is the name of your favorite childhood friend?</label>
						</td>
					   </tr>
					   <tr>
						<td class="<cfoutput>#thisContentClass#</cfoutput>" colspan="2">
							<input id="securityAnswer2" name="securityAnswer2" type="text" value="<cfoutput>#securityAnswer2#</cfoutput>" class="k-textbox" required validationMessage="Name of favorite friend is required" style="width: 95%"/> 
						</td>
					  </tr>
					<cfelse><!---<cfif session.isMobile>--->
					  <tr valign="middle" height="30px">
						<td align="right" valign="middle" class="<cfoutput>#thisContentClass#</cfoutput>" height="30px">
							<label for="securityAnswer2">What is the name of your favorite childhood friend?</label>
						</td>
						<td align="left" class="<cfoutput>#thisContentClass#</cfoutput>">
							<input id="securityAnswer2" name="securityAnswer2" type="text" value="<cfoutput>#securityAnswer2#</cfoutput>" class="k-textbox" required validationMessage="Name of favorite friend is required" style="width: 66%"/> 
						</td>
					  </tr>
					</cfif><!---<cfif session.isMobile>--->
					  <!-- Border -->
					  <tr height="2px">
						  <td align="left" valign="top" colspan="<cfoutput>#thisColSpan#</cfoutput>" class="<cfoutput>#thisContentClass#</cfoutput>"></td>
					  </tr>
					  <cfsilent>
					  <!--- Set the class for alternating rows. --->
					  <!---After the first row, the content class should be the current class. --->
					  <cfset thisContentClass = HtmlUtilsObj.getKendoClass(thisContentClass)>
					  </cfsilent>
					  <tr height="2px">
						  <td align="left" valign="top" colspan="2" class="border <cfoutput>#thisContentClass#</cfoutput>"></td>
					  </tr>
					  <!-- Form content -->
					<cfif session.isMobile>
					  <tr valign="middle">
						<td class="<cfoutput>#thisContentClass#</cfoutput>" colspan="2">
							<label for="securityAnswer3">What is your favorite place?</label>
						</td>
					   </tr>
					   <tr>
						<td class="<cfoutput>#thisContentClass#</cfoutput>" colspan="2">
							<input id="securityAnswer3" name="securityAnswer3" type="text" value="<cfoutput>#securityAnswer3#</cfoutput>" class="k-textbox" required validationMessage="Name of favorite place is required" class="k-texbox" style="width: 95%" />  
						</td>
					  </tr>
					<cfelse><!---<cfif session.isMobile>--->
					  <tr valign="middle" height="30px">
						<td align="right" valign="middle" class="<cfoutput>#thisContentClass#</cfoutput>" height="30px">
							<label for="securityAnswer3">What is your favorite place?</label>
						</td>
						<td align="left" class="<cfoutput>#thisContentClass#</cfoutput>">
							<input id="securityAnswer3" name="securityAnswer3" type="text" value="<cfoutput>#securityAnswer3#</cfoutput>" class="k-textbox" required validationMessage="Name of favorite place is required" class="k-texbox" style="width: 66%" /> 
						</td>
					  </tr>
					</cfif><!---<cfif session.isMobile>--->
					</table>
			  </td>
		  </tr>
			
		  <!-- Submit -->
		  <tr valign="middle" height="30px">
			<td valign="bottom" align="right" class="<cfoutput>#thisContentClass#</cfoutput>">&nbsp;</td>
			<td valign="bottom" align="left" class="<cfoutput>#thisContentClass#</cfoutput>">
				<button id="userProfileSubmit" name="userProfileSubmit" class="k-button k-primary" type="button">Submit</button>
			</td>
		  </tr>
		</table>
		</form>
			  
	</cfif><!---<cfif structKeyExists(URL, "optArgs")>--->
			  
</cfcase>
			  
<!--- //************************************************************************************************
		Add Category 
//**************************************************************************************************--->
	
<cfcase value=12>
	
	<!--- Note: this template is used in two spots- on the post page when the category is not found when the user types ina category on the dropdown, and on the category grid when the user clicks on the new category button. On the post page, the typed in category will appear along with the suggested alias. On the category grid, only the category will be shown with no alias. ---> 
	
	<cfif isDefined("URL.optArgs") and len(URL.optArgs)>
		<!--- Preset the vars --->
		<!--- Get the category from the url. --->
		<cfset category = URL.optArgs>
		<!--- Make the category alias --->
		<cfset categoryAlias = application.blog.makeAlias(URL.optArgs)>
	<cfelse>
		<cfset category = "">
		<cfset categoryAlias = "">
	</cfif>
	<!--- Get a list of category names and aliases for validation purposes --->
	<cfset categoryList = application.blog.getCategoryList('categoryList')>
	<!--- And get a list of the aliases --->
	<cfset categoryAliasList = application.blog.getCategoryList('categoryAliasList')>
		
	<script>
		
		// Create a list to validate if the category is already in use.
		var categoryList = "<cfoutput>#categoryList#</cfoutput>";
		// Do the same for the alias
		var categoryAliasList = "<cfoutput>#categoryAliasList#</cfoutput>";
		
		// !!! Note on the validators, all forms need a name attribute, otherwise the positioning of the messages will not work. --->
		$(document).ready(function() {

			var addCategoryValidator = $("#categoryForm").kendoValidator({
				// Set up custom validation rules 
				rules: {
					// The category must be unique. 
					categoryIsUnique:
					function(input){
						// Do not continue if the user name is found in the currentUserName list 
						if (input.is("[id='category']") && ( listFind( categoryList, input.val() ) != 0 ) ){
							// Display an error on the page.
							input.attr("data-categoryIsUnique-msg", "Category already exists");
							// Focus on the current element
							$( "#category" ).focus();
							return false;
						}                                    
						return true;
					},
					// The alias must be unique. 
					categoryAliasIsUnique:
					function(input){
						// Do not continue if the user name is found in the currentUserName list 
						if (input.is("[id='categoryAlias']") && ( listFind( categoryAliasList, input.val() ) != 0 ) ){
							// Display an error on the page.
							input.attr("data-categoryAliasIsUnique-msg", "Category Alias already exists");
							// Focus on the current element
							$( "#categoryAlias" ).focus();
							return false;
						}                                    
						return true;
					},
				<cfif len(URL.optArgs)>
					// The alias must not contain a space. 
					categoryAliasNoSpace:
					function(input){
						// Do not continue if the user name is found in the currentUserName list 
						if (input.is("[id='categoryAlias']") && ( hasWhiteSpace(input.val()) ) ){
							// Display an error on the page.
							input.attr("data-categoryAliasNoSpace-msg", "Alias must not contain a space");
							// Focus on the current element
							$( "#categoryAlias" ).focus();
							return false;
						}                                    
						return true;
					},
					// The alias must not contain any special chars. 
					categoryAliasNoSpecialChars:
					function(input){
						// Do not continue if the user name is found in the currentUserName list 
						if (input.is("[id='categoryAlias']") && ( input.val().includes('&')||input.val().includes('?')||input.val().includes(',') ) ){
							// Display an error on the page.
							input.attr("data-categoryAliasNoSpecialChars-msg", "Alias must not contain a comma, question mark or an ampersand.");
							// Focus on the current element
							$( "#categoryAlias" ).focus();
							return false;
						}                                    
						return true;
					},
				</cfif>
				}
			}).data("kendoValidator");

			// Invoked when the submit button is clicked. Insted of using '$("form").submit(function(event) {' and 'event.preventDefault();', We are using direct binding here to speed up the event.
			var addCategorySubmit = $('#addCategorySubmit');
			addCategorySubmit.on('click', function(e){  
				
				e.preventDefault();         
				if (addCategoryValidator.validate()) {
					
					// Open up a please wait dialog
					$.when(kendo.ui.ExtWaitDialog.show({ title: "Please wait...", message: "Please wait while we process the category.", width: "<cfoutput>#application.kendoExtendedUiWindowWidth#</cfoutput>", icon: "k-ext-information" }));
					
					// Get the value of the category that was typed in
					newCategory = $("#addCategory").val();

					// Send data to server after the new role was saved into the hidden form
					setTimeout(function() {
						postNewCategory();
					}, 250);
					
				} else {

					$.when(kendo.ui.ExtAlertDialog.show({ title: "There are errors", message: "Please correct the highlighted fields and try again", icon: "k-ext-warning" }) // or k-ext-error, k-ext-question
						).done(function () {
						// Do nothing
					});
				}
			});

		});//...document.ready
		
		// Post method on the detail form called from the deptDetailFormValidator method on the detail page. The action variable will either be 'update' or 'insert'.
		function postNewCategory(){

			jQuery.ajax({
				type: 'post', 
				url: '<cfoutput>#application.baseUrl#</cfoutput>/common/cfc/ProxyController.cfc?method=saveCategory',
				data: { // arguments
					csrfToken: '<cfoutput>#csrfToken#</cfoutput>',
					// Pass the form values
					category: $("#category").val()<cfif len(URL.optArgs)>,
					categoryAlias: $("#categoryAlias").val()
					</cfif>
				},
				dataType: "json",
				success: saveCategoryResult, // calls the result function.
				error: function(ErrorMsg) {
					console.log('Error' + ErrorMsg);
				}
			// Extract any errors. This is a new jQuery promise based function as of jQuery 1.8.
			}).fail(function (jqXHR, textStatus, error) {
				// The full response is: jqXHR.responseText, but we just want to extract the error.
				$.when(kendo.ui.ExtAlertDialog.show({ title: "Error while consuming the saveCategory function", message: error, icon: "k-ext-error", width: "<cfoutput>#application.kendoExtendedUiWindowWidth#</cfoutput>" }) // or k-ext-error, k-ext-information, k-ext-question, k-ext-warning.  You can also specify height.
					).done(function () {
					// Do nothing
				});		
			});
		};

		function saveCategoryResult(response){ 
			if (JSON.parse(response.success) == true){
					// Close the wait window that was launched in the calling function.
				kendo.ui.ExtWaitDialog.hide();
				try {
					// Refresh the category grid window
					$("#categoryGridWindow").data("kendoWindow").refresh();
				} catch(e){
					// Category window is not initialized. This is a normal condition when the category grid is not open
				}
				// Close this window.
				$('#addCategoryWindow').kendoWindow('destroy');
			} else {
				// Display the errors
				$.when(kendo.ui.ExtAlertDialog.show({ title: "Error saving category", message: response.errorMessage, icon: "k-ext-warning", width: "<cfoutput>#application.kendoExtendedUiWindowWidth#</cfoutput>", height: "125px" }) // or k-ext-error, k-ext-question
				).done(function () {
					// Do nothing
				});
			}//..if (JSON.parse(response.success) == true){
		}
		
	</script>
		
	<form id="categoryForm" action="#" method="post" data-role="validator">
	<!--- Pass the csrfToken --->
	<input type="hidden" name="csrfToken" id="csrfToken" value="<cfoutput>#csrfToken#</cfoutput>" />
	<table align="center" class="k-content tableBorder" width="100%" cellpadding="2" cellspacing="0" border="0">
	  <cfsilent>
			<!---The first content class in the table should be empty. --->
			<cfset thisContentClass = HtmlUtilsObj.getKendoClass('')>
			<!--- Set the colspan property for borders --->
			<cfset thisColSpan = "2">
	  </cfsilent>
	  <tr height="1px">
		  <td align="left" valign="top" colspan="2" class="<cfoutput>#thisContentClass#</cfoutput>"></td>
	  </tr>
	  <tr height="30px">
		<td align="left" class="<cfoutput>#thisContentClass#</cfoutput>" colspan="2"> 
			Create new Category. The alias field is used when creating SES (Search Engine Safe) URLs. If wish to change the category alias yourself, do not use any non-alphanumeric characters or spaces in the alias- spaces should be replaced with dashes.
		</td>
	  </tr>
	  <!-- Border -->
	  <tr height="2px">
	    <td align="left" valign="top" colspan="<cfoutput>#thisColSpan#</cfoutput>" class="<cfoutput>#thisContentClass#</cfoutput>"></td>
	  </tr>
	  <cfsilent>
	  <!--- Set the class for alternating rows. --->
	  <!---After the first row, the content class should be the current class. --->
	  <cfset thisContentClass = HtmlUtilsObj.getKendoClass(thisContentClass)>
	  </cfsilent>
	  <tr height="2px">
		  <td align="left" valign="top" colspan="2" class="border <cfoutput>#thisContentClass#</cfoutput>"></td>
	  </tr>
	  <!-- Form content -->
	<cfif session.isMobile>
	  <tr valign="middle">
		<td class="<cfoutput>#thisContentClass#</cfoutput>" colspan="2">
			<label for="category">Category</label>
		</td>
	   </tr>
	   <tr>
		<td class="<cfoutput>#thisContentClass#</cfoutput>" colspan="2">
			<input id="category" name="category" type="text" value="<cfoutput>#category#</cfoutput>" required validationMessage="Category is required" class="k-textbox" style="width: 66%" /> 
		</td>
	  </tr>
	<cfelse><!---<cfif session.isMobile>--->
	  <tr valign="middle" height="30px">
		<td align="right" valign="middle" class="<cfoutput>#thisContentClass#</cfoutput>">
			<label for="category">Category</label>
		</td>
		<td align="left" class="<cfoutput>#thisContentClass#</cfoutput>">
			<input id="category" name="category" type="text" value="<cfoutput>#category#</cfoutput>" required validationMessage="Category is required" class="k-textbox" style="width: 66%" />  
		</td>
	  </tr>
	</cfif>
	  <!-- Border -->
	  <tr height="2px">
	    	<td align="left" valign="top" colspan="<cfoutput>#thisColSpan#</cfoutput>" class="<cfoutput>#thisContentClass#</cfoutput>"></td>
	  </tr>
<cfif len(URL.optArgs)>
	  <cfsilent>
	  <!--- Set the class for alternating rows. --->
	  <!---After the first row, the content class should be the current class. --->
	  <cfset thisContentClass = HtmlUtilsObj.getKendoClass(thisContentClass)>
	  </cfsilent>
	  <tr height="2px">
		  <td align="left" valign="top" colspan="2" class="border <cfoutput>#thisContentClass#</cfoutput>"></td>
	  </tr>
	  <!-- Form content -->
	<cfif session.isMobile>
		  <tr valign="middle">
			<td class="<cfoutput>#thisContentClass#</cfoutput>" colspan="2">
				<label for="categoryAlias">Category Alias</label>
			</td>
		   </tr>
		   <tr>
			<td class="<cfoutput>#thisContentClass#</cfoutput>" colspan="2">
				<input id="categoryAlias" name="categoryAlias" type="text" value="<cfoutput>#categoryAlias#</cfoutput>" class="k-textbox" style="width: 95%" /> 
			</td>
		  </tr>
		<cfelse><!---<cfif session.isMobile>--->
	  <tr valign="middle" height="30px">
		<td align="right" valign="middle" class="<cfoutput>#thisContentClass#</cfoutput>">
			<label for="categoryAlias">Category Alias</label>
		</td>
		<td align="left" class="<cfoutput>#thisContentClass#</cfoutput>">
			<input id="categoryAlias" name="categoryAlias" type="text" value="<cfoutput>#categoryAlias#</cfoutput>" class="k-textbox" style="width: 66%" /> 
		</td>
	  </tr>
	</cfif>
</cfif>
	  <cfsilent>
	  <!--- Set the class for alternating rows. --->
	  <!--- After the first row, the content class should be the current class. --->
	  <cfset thisContentClass = HtmlUtilsObj.getKendoClass(thisContentClass)>
	  </cfsilent>
	  <tr height="2px">
		  <td align="left" valign="top" colspan="2" class="border <cfoutput>#thisContentClass#</cfoutput>"></td>
	  </tr>
	  <!-- Form content -->
	  <tr valign="middle" height="30px">
		<td valign="bottom" align="right" class="<cfoutput>#thisContentClass#</cfoutput>">&nbsp;</td>
		<td valign="bottom" align="left" class="<cfoutput>#thisContentClass#</cfoutput>">
			<button id="addCategorySubmit" name="addCategorySubmit" class="k-button k-primary" type="button">Submit</button>
		</td>
	  </tr>
	</table>
	</form>
				
</cfcase>

<!--- //************************************************************************************************
		Enclosure image tiny mce editor
//**************************************************************************************************--->
				
<cfcase value=13>
	
	<!--- Preset the mediaHtml var --->
	<cfparam name="mediaHtml" default="">
	
	<style>
		.mce-ico.mce-i-fa {
		display: inline-block;
		font: normal normal normal 14px/1 FontAwesome;
		font-size: inherit;
		text-rendering: auto;
		-webkit-font-smoothing: antialiased;
		-moz-osx-font-smoothing: grayscale;
	}
	</style>
	
	<!--- Instantiate the Render.cfc. This will be used to build the HTML for the image if the MediaUrl is present in the database. --->
	<cfobject component="#application.rendererComponentPath#" name="RendererObj">
	<!--- Get the post ( getPostByPostId(postId, showPendingPosts, showRemovedPosts) ) --->
	<cfset getPost = application.blog.getPostByPostId(URL.optArgs,true,true)>
	<!--- <cfdump var="#getPost#"> ---> 
		
	<!---*********************     Handle media      *********************--->
	<!--- There are two references to the media, a path and a URL. We need to check if the mediaUrl is present and extract it from the path if it does not exist. --->
	<cfset mediaId = getPost[1]["MediaId"]>
	<cfset mediaUrl = getPost[1]["MediaUrl"]>
	<cfset mediaPath = getPost[1]["MediaPath"]>
	<cfset mediaType = getPost[1]["MediaType"]>
	<!--- Note: for external links, the mime type will not be available (YouTube and other media sources don't  always have a easilly read extension) --->
	<cfset mimeType = getPost[1]["MimeType"]>
	<cfif not len(mediaUrl)>
		<!--- We are only getting the path and not the entire URL --->
		<cfset mediaUrl = application.blog.getEnclosureUrlFromMediaPath(mediaPath, true)>
	</cfif>
	<!--- Optional video stuff --->
	<cfset providerVideoId = getPost[1]["ProviderVideoId"]>
	<cfset mediaVideoCoverUrl = getPost[1]["MediaVideoCoverUrl"]>
	<cfset mediaVideoVttFileUrl = getPost[1]["MediaVideoVttFileUrl"]>
		
	<cfif len(mediaUrl)>
		<!--- We don't  always have a mime type. External links for example don't  always have a readable extension --->
		<cfif mediaType eq 'Image'>
			<!--- Render the image HTML string --->
			<cfset mediaHtml = RendererObj.renderEnclosureImage(mediaUrl=#mediaUrl#, mediaId=#mediaId#)>
		<!--- The media type string for video is Video - Large, Video - YouTube URL, etc. All of the video types start with 'Video' --->
		<cfelseif left(mediaType, 5) eq 'Video'>
			<!--- Note: this will return an iframe. --->
			<cfinvoke component="#RendererObj#" method="renderEnclosureVideoPreview" returnvariable="mediaHtml">
				<cfinvokeargument name="mediaId" value="#mediaId#">
				<cfinvokeargument name="mediaUrl" value="#mediaUrl#">
				<cfinvokeargument name="providerVideoId" value="#providerVideoId#">
				<cfinvokeargument name="posterUrl" value="#mediaVideoCoverUrl#">
				<cfinvokeargument name="videoCaptionsUrl" value="#mediaVideoVttFileUrl#">
			</cfinvoke>
		</cfif>
	</cfif><!---<cfif len(mediaUrl)>--->
	<!---<cfdump var="#mediaHtml#" label="mediaHtml">--->
					
	<!---*********************    Handle the map    *********************--->
	<!--- Extract the map id --->
	<cfset enclosureMapId = getPost[1]["EnclosureMapId"]>
	<cfif len(enclosureMapId)>
		<!--- Render the routes. This returns a iframe --->
		<cfset mediaHtml = mediaHtml & RendererObj.renderMapPreview(enclosureMapId)>
	</cfif>
	
	<!---********************* Post Enclosure editor *********************--->
	<!--- Set the common vars for tinymce. --->
	<cfsilent>
	<cfset selectorId = "enclosureEditor">
	<cfif session.isMobile>
		<cfset editorHeight = "325">
	<cfelse>
		<cfset editorHeight = "650">
	</cfif>
	<cfset imageHandlerUrl = application.baseUrl & "/common/cfc/ProxyController.cfc?method=uploadImage&mediaProcessType=enclosure&mediaType=image&postId=" & URL.optArgs & "&selectorId=" & selectorId & "&csrfToken=" & csrfToken>
	<cfset contentVar = mediaHtml>
	<cfset imageMediaIdField = "mediaId">
	<cfset imageClass = "entryImage">

	<cfif session.isMobile>
		<cfset toolbarString = "undo redo | image editimage | media videoUpload">
	<cfelse>
		<cfset toolbarString = "undo redo | image editimage | media videoUpload webVttUpload videoCoverUpload | map mapRouting">
	</cfif>
	<cfset includeGallery = false>
	<cfset includeVideoUpload = true>
	<cfset disableVideoCoverAndWebVttButtons = true>
	</cfsilent>
	<!--- Include the tinymce js template --->
	<cfinclude template="#application.baseUrl#/includes/templates/js/tinyMce.cfm">
		
	<!--- Include the get-video-id script. This will be used to determine the video provider and the video id --->
	<script src="<cfoutput>#application.baseUrl#</cfoutput>/common/libs/get-video-id/getVideoId.min.js"></script>
		
	<script>
		// Note: this function handles enclosure images, videos, and theme images and needs to be changed according to what is being processed. This particular function handles theme images. Note: the invokedArguments is not used by CF, but shows the location where this function is being called from and the arguments for debugging purposes.
		function saveExternalUrl(url, mediaType, selectorId, invokedArguments){ 
			jQuery.ajax({
				type: 'post', 
				url: '<cfoutput>#application.baseUrl#</cfoutput>/common/cfc/ProxyController.cfc?method=saveExternalMediaEnclosure&template=enclosureImageEditor',
				dataType: "json",
				data: { // arguments
					csrfToken: '<cfoutput>#csrfToken#</cfoutput>',
					selectorId: '<cfoutput>#selectorId#</cfoutput>',
					// Pass the mediaId saved in the mediaId hidden form if it is available
					mediaId: $("#<cfoutput>#imageMediaIdField#</cfoutput>").val(),
					externalUrl: url,
					postId: <cfoutput>#URL.optArgs#</cfoutput>,
					mediaType: 'image',
					themeImageType: '<cfoutput>#URL.otherArgs#</cfoutput>',
					selectorId: selectorId,
					invokedArguments: invokedArguments
				},
				error: function(ErrorMsg) {
					console.log('Error' + ErrorMsg);
				}
			// Extract any errors. This is a new jQuery promise based function as of jQuery 1.8.
			}).fail(function (jqXHR, textStatus, error) {

				// The full response is: jqXHR.responseText, but we just want to extract the error.
				$.when(kendo.ui.ExtAlertDialog.show({ title: "Error while consuming the saveExternalMediaEnclosure function", message: error, icon: "k-ext-error", width: "<cfoutput>#application.kendoExtendedUiWindowWidth#</cfoutput>" }) // or k-ext-error, k-ext-information, k-ext-question, k-ext-warning.  You can also specify height.
					).done(function () {
					// Do nothing
				});		
			});
			
			// Refresh the media preview- pass in the postId
			reloadEnclosureThumbnailPreview(<cfoutput>#URL.optArgs#</cfoutput>);
			
			/* Do not raise a dialog here as this function is consumed every time that the submit button on the image editor is clicked. We need to exract the return from the server to see if it was an external image to determine what message to display in one of the next versions. 
			// Raise a dialog
			$.when(kendo.ui.ExtAlertDialog.show({ title: "Created external link", message: "The image will be displayed from an external link, however, no social media sharing images were made.", icon: "k-ext-information", width: "425px" }) // or k-ext-error, k-ext-information, k-ext-question, k-ext-warning.  You can also specify height.
				).done(function () {
				// Do nothing
			}); */
		}
		
		function removeMediaEnclosure(){ 
			jQuery.ajax({
				type: 'post', 
				url: '<cfoutput>#application.baseUrl#</cfoutput>/common/cfc/ProxyController.cfc?method=removeMediaEnclosure&template=enclosureImageEditor',
				dataType: "json",
				data: { // arguments
					csrfToken: '<cfoutput>#csrfToken#</cfoutput>',
					postId: <cfoutput>#URL.optArgs#</cfoutput>
				},
				error: function(ErrorMsg) {
					console.log('Error' + ErrorMsg);
				}
			// Extract any errors. This is a new jQuery promise based function as of jQuery 1.8.
			}).fail(function (jqXHR, textStatus, error) {

				// The full response is: jqXHR.responseText, but we just want to extract the error.
				$.when(kendo.ui.ExtAlertDialog.show({ title: "Error while consuming the removeMediaEnclosure function", message: error, icon: "k-ext-error", width: "<cfoutput>#application.kendoExtendedUiWindowWidth#</cfoutput>" }) // or k-ext-error, k-ext-information, k-ext-question, k-ext-warning.  You can also specify height.
					).done(function () {
					// Do nothing
				});		
			});
		}
			
		// Submit the data and close this window.
		function onPostEnclosureSubmit(){
			// Get the editor content
			var enclosureEditorContent = $("#<cfoutput>#imageMediaIdField#</cfoutput>").val();
			// If there are no enclosures, remove any enclosures that exists in the db.
			if (enclosureEditorContent == ""){
				removeMediaEnclosure();
			}
			// Refresh the thumbnail image on the post detail page to show the none image
			reloadEnclosureThumbnailPreview(<cfoutput>#URL.optArgs#</cfoutput>);
			// Close the edit window
			$('#postEnclosureWindow').kendoWindow('destroy');
		}
	</script>
		
	<form id="enclosureForm" action="#" method="post" data-role="validator">
	<!-- Pass the mediaId for new images or videos that have been uploaded -->
	<input type="hidden" name="mediaId" id="mediaId" value="" />
	<!-- The mediaType will either be an empty string, image or video -->
	<input type="hidden" name="mediaType" id="mediaType" value="" />
	<!--- Pass the mapId for an enclosure map --->
	<input type="hidden" name="mapId" id="mapId" value="" />
	<!-- The map type will either be an empty string, static or route -->
	<input type="hidden" name="mapType" id="mapType" value="" />
	<!-- Pass the csrfToken -->
	<input type="hidden" name="csrfToken" id="csrfToken" value="<cfoutput>#csrfToken#</cfoutput>" />
	
	<!--- The external image url will only be present if the user entered a url from an external source. We need to capture this as we don't  have any native tinymce method to indicate that an external image was selected and we need to upload it and save it to the datbase. --->
	<input type="hidden" name="externalImageUrl" id="externalImageUrl" value="" />
	<table align="center" class="k-content tableBorder" width="100%" cellpadding="2" cellspacing="0" border="0">
	  <cfsilent>
			<!---The first content class in the table should be empty. --->
			<cfset thisContentClass = HtmlUtilsObj.getKendoClass('')>
			<!--- Set the colspan property for borders --->
			<cfset thisColSpan = "2">
	  </cfsilent>
	  <tr height="1px">
		  <td align="left" valign="top" colspan="2" class="<cfoutput>#thisContentClass#</cfoutput>"></td>
	  </tr>
	  <tr height="30px">
		<td align="left" class="<cfoutput>#thisContentClass#</cfoutput>" colspan="2"> 
			The enclosure resides at the top of the blog post and it should take up to 100% of the content width of the blog post. The enclosure can either be a video or an image. Galaxie Blog will automatically adjust your images for Facebook, Twitter, LinkedIn and other social media sites. To upload media, click on the buttons below.
		</td>
	  </tr>
	  <!-- Border -->
	  <tr height="2px">
	    	<td align="left" valign="top" colspan="<cfoutput>#thisColSpan#</cfoutput>" class="<cfoutput>#thisContentClass#</cfoutput>"></td>
	  </tr>
	  <cfsilent>
	  <!--- Set the class for alternating rows. --->
	  <!---After the first row, the content class should be the current class. --->
	  <cfset thisContentClass = HtmlUtilsObj.getKendoClass(thisContentClass)>
	  </cfsilent>
	  <tr height="2px">
		  <td align="left" valign="top" colspan="2" class="border <cfoutput>#thisContentClass#</cfoutput>"></td>
	  </tr>
	  <!-- Form content -->
	  <tr valign="middle" height="30px">
		<td align="left" class="<cfoutput>#thisContentClass#</cfoutput>" colspan="2">
			<!--- TinyMce container --->
			<div style="position: relative;">
				<textarea id="<cfoutput>#selectorName#</cfoutput>" name="<cfoutput>#selectorName#</cfoutput>"></textarea>
			</div>   
		</td>
	  </tr>
	  <cfsilent>
	  <!--- Set the class for alternating rows. --->
	  <!--- After the first row, the content class should be the current class. --->
	  <cfset thisContentClass = HtmlUtilsObj.getKendoClass(thisContentClass)>
	  </cfsilent>
	  <tr height="2px">
		  <td align="left" valign="top" colspan="2" class="border <cfoutput>#thisContentClass#</cfoutput>"></td>
	  </tr>
	  <!-- Form content -->
	  <tr valign="middle" height="30px">
		<td valign="bottom" align="right" class="<cfoutput>#thisContentClass#</cfoutput>">&nbsp;</td>
		<td valign="bottom" align="left" class="<cfoutput>#thisContentClass#</cfoutput>">
			<button id="mediaUploadCompleteButton" name="mediaUploadCompleteButton" class="k-button k-primary" type="button" onClick="javascript:onPostEnclosureSubmit();">Submit</button>
		</td>
	  </tr>
	</table>
	</form>
				
</cfcase>
		  
<!--- //************************************************************************************************
		Video Upload
//**************************************************************************************************--->
		  
<!--- 
Note: to embed video from Galaxy blog use something like this:
<iframe src="/galaxiePlayer.cfm?videoUrl=/enclosures/Videos/weekndStarBoy.mp4&posterUrl=&videoCaptionsUrl=/enclosures/videos/test1.vtt" width="768" height="432" allowfullscreen="allowfullscreen"></iframe>

Custom element markup example for videos:
<galaxie-template data-type="video" data-mediaId="" data-width="" data-length=""></galaxie-template>
--->
		  
<cfcase value=14>

	<cfsilent>
	<!--- Get the current content by the mediaId if available ( getPostByPostId(postId, showPendingPosts, showRemovedPosts) ). --->
	<cfif len(URL.optArgs)>
		<cfset getPost = application.blog.getPostByPostId(URL.optArgs,true,true)>
	<!---<cfdump var="#getPost#"> --->  
		
		<!---*********************     Handle media      *********************--->
		<!--- There are two references to the media, a path and a URL. The previous versions of BlogCfc did not use the URL so we need to check if the mediaUrl is present and extract it from the path if it does not exist. --->
		<cfset mediaId = getPost[1]["MediaId"]>
	</cfif>
	
	<!--- Set the uppy theme. --->
	<cfif darkTheme>
		<cfset uppyTheme = 'dark'>
	<cfelse>
		<cfset uppyTheme = 'light'>
	</cfif>
		
	<!--- Not used yet- Get the kendo primay button color in order to reset the uppy actionBtn--upload color --->
	<cfset primaryButtonColor = application.blog.getPrimaryColorsByTheme(kendoTheme:kendoTheme,setting:'accentColor')>
	</cfsilent>
	<!---<cfoutput>primaryButtonColor: #primaryButtonColor#</cfoutput>--->
    <div id="videoUpload"></div>
    <script>
		
		var uppy = Uppy.Core({
			restrictions : {
				maxNumberOfFiles: 1,  // only one video can be uploaded at a time
				allowedFileTypes: ['video/*'] // only allow videos
        	}
		})
		
		.use(Uppy.Dashboard, {
			theme: '<cfoutput>#uppyTheme#</cfoutput>',
			inline: true,
			target: '#videoUpload',
			proudlyDisplayPoweredByUppy: false,
			metaFields: [
				{ id: 'mediaTitle', name: 'Title', placeholder: 'Please enter the image title' }
			]
		})
		// Allow users to take pictures via the onboard camera
		.use(Uppy.Webcam, { target: Uppy.Dashboard })
		// Use the built in image editor
		.use(Uppy.ImageEditor, { 
			target: Uppy.Dashboard,
			quality: 0.8 // for the resulting image, 0.8 is a sensible default
		})
		// Use XHR and send the media to the server for processing
		.use(Uppy.XHRUpload, { endpoint: '<cfoutput>#application.baseUrl#</cfoutput>/common/cfc/ProxyController.cfc?method=uploadVideo&mediaProcessType=enclosure&mediaType=largeVideo&postId=<cfoutput>#URL.optArgs#</cfoutput>&csrfToken=<cfoutput>#csrfToken#</cfoutput>' })
		.on('upload-success', (file, response) => {
			// The server is returning location and mediaId in a json object. We need to extract these.
			//alert(response.status) // HTTP status code
			//alert(response.body.location) // The full path of the file that was just uploaded to the server
			// alert(response.body.mediaId) // The MediaId value saved to the Media table in the database.
			//alert(response.body.mediaActions) // All of the actions taken for a video or image. Only present with image enclosures
			// Save the mediaId into the hidden form on the post enclosure window
			$("#mediaId").val(response.body.mediaId);
			// Insert 'video' as the mediaType to differentiate between videos and images
			$("#mediaType").val('video');
		<cfif isDefined("URL.optArgs") and len(URL.optArgs)>
			// Refresh the thumbnail image on the post detail page
			reloadEnclosureThumbnailPreview(response.body.postId);
		</cfif>
		})
		
		// Events
		// 1) When the dashboard icon is clicked
		// Note: there is no event when the dashboard my device button is clicked. This is a work-around. We are going to use jquery's on click event and put in the class of the button. This is required as the uppy button does not have an id.
		$(".uppy-Dashboard-input").on('click', function(event){
			$.when(kendo.ui.ExtWaitDialog.show({ title: "Please wait...", message: "Please wait for the file uploader interface to respond.", icon: "k-ext-information" }));
		});
		
		// 2) When a file has been uploaded to uppy
		uppy.on('file-added', (file) => {
		  	// Close the wait window that was launched in the calling function.
			kendo.ui.ExtWaitDialog.hide();
		})
		
		// 3) When the upload button was pressed
		uppy.on('upload', (data) => {
			$.when(kendo.ui.ExtWaitDialog.show({ title: "Please wait...", message: "Please wait while the video is uploaded.", icon: "k-ext-information" }));
		})
		
		// 4) When the upload is complete to the server
		uppy.on('complete', (result) => {
			
			// Close the please wait dialog
			// Use a quick set timeout in order for the data to load.
			setTimeout(function() {
				// Close the wait window that was launched in the calling function.
				kendo.ui.ExtWaitDialog.hide();
			}, 500);
			
			// After uploading the video, create the HTML and send it back to the editor. We don't  have an video image cover or webVtt file yet as this video has just been uploaded. This is the type of string that we need to create:
			// <iframe src="https://gregorysblog.org/galaxiePlayer.cfm?mediaId=xxx" width="768" height="432" allowfullscreen="allowfullscreen"></iframe>

			// Create our iframe html string
			var videoIframeHtml = '<iframe data-type="video" data-id=' + $("#mediaId").val() + ' src="<cfoutput>#application.baseUrl#</cfoutput>/galaxiePlayer.cfm?mediaId=' + $("#mediaId").val() + '" width="768" height="432" allowfullscreen="allowfullscreen"></iframe>';
			// Insert the HTML string into the active editor
			tinymce.activeEditor.setContent(videoIframeHtml);
			// Close this window
			$('#postEnclosureVideoWindow').kendoWindow('destroy');
			
			// Let the user know that they can add video captions or an image cover 
			$.when(kendo.ui.ExtAlertDialog.show({ title: "Your video has been uploaded", message: "You may also add video captions and an image cover for this video.", icon: "k-ext-information", width: "<cfoutput>#application.kendoExtendedUiWindowWidth#</cfoutput>" }) // or k-ext-error, k-ext-information, k-ext-question, k-ext-warning.  You can also specify height.
				).done(function () {
				// Do nothing
			});
		})
	
    </script>

</cfcase>
			
<!--- //************************************************************************************************
		LD JSON
//**************************************************************************************************--->
				
<cfcase value=15>
	
	<style>
		.mce-ico.mce-i-fa {
		display: inline-block;
		font: normal normal normal 14px/1 FontAwesome;
		font-size: inherit;
		text-rendering: auto;
		-webkit-font-smoothing: antialiased;
		-moz-osx-font-smoothing: grayscale;
	}
	</style>
		
	<!--- Get the post. Here we are passing the postId, true to get pending posts, and true to get the removed posts ( getPostByPostId(postId, showPendingPosts, showRemovedPosts) ). --->
	<cfset getPost = application.blog.getPostByPostId(URL.optArgs,true,true)>
	<!---<cfdump var="#getPost#">--->

	<cfif len(getPost[1]["JsonLd"])>
		<cfset jsonLd = getPost[1]["JsonLd"]>	
	<cfelse>
		<!--- Render the LD JSON --->
		<cfobject component="#application.rendererComponentPath#" name="RendererObj">
		<!--- The true argument will prettify the code for the editor. --->
		<cfset jsonLd = RendererObj.renderLdJson(getPost, false)>
		<!---<cfdump var="#jsonLd#">--->
	</cfif>

	<script>
		$(document).ready(function() {

			// Invoked when the submit button is clicked. Insted of using '$("form").submit(function(event) {' and 'event.preventDefault();', We are using direct binding here to speed up the event.
			var jsonLdSubmit = $('#jsonLdSubmit');
			jsonLdSubmit.on('click', function(e){      
				e.preventDefault();         
				// submit the form.
				saveJsonLd();
			});
		});//...document.ready

		// Save the json
		function saveJsonLd(){ 
			jQuery.ajax({
				type: 'post', 
				url: '<cfoutput>#application.baseUrl#</cfoutput>/common/cfc/ProxyController.cfc?method=saveJsonLd',
				data: { // arguments
					csrfToken: '<cfoutput>#csrfToken#</cfoutput>',
					postId: "<cfoutput>#URL.optArgs#</cfoutput>",
					jsonLd: $("#jsonLdEditor").val(),
					selectorId: 'jsonLdEditor'
				},
				dataType: "json",
				success: saveJsonLdResponse, // calls the result function.
				error: function(ErrorMsg) {
					console.log('Error' + ErrorMsg);
				}
			// Extract any errors. This is a new jQuery promise based function as of jQuery 1.8.
			}).fail(function (jqXHR, textStatus, error) {

				// The full response is: jqXHR.responseText, but we just want to extract the error.
				$.when(kendo.ui.ExtAlertDialog.show({ title: "Error while consuming the saveJsonLd function", message: error, icon: "k-ext-error", width: "<cfoutput>#application.kendoExtendedUiWindowWidth#</cfoutput>" }) // or k-ext-error, k-ext-information, k-ext-question, k-ext-warning.  You can also specify height.
					).done(function () {
					// Do nothing
				});		
			});
		};

		function saveJsonLdResponse(response){
			// Close the webVtt editor window
			jQuery('#jsonLdWindow').kendoWindow('destroy');	
		}

	</script>

	<form id="jsonLdForm" action="#" method="post" data-role="validator">
	<!--- Pass the csrfToken --->
	<input type="hidden" name="csrfToken" id="csrfToken" value="<cfoutput>#csrfToken#</cfoutput>" />
	<table align="center" class="k-content tableBorder" width="100%" cellpadding="2" cellspacing="0" border="0">
	  <cfsilent>
			<!---The first content class in the table should be empty. --->
			<cfset thisContentClass = HtmlUtilsObj.getKendoClass('')>
			<!--- Set the colspan property for borders --->
			<cfset thisColSpan = "2">
	  </cfsilent>
	  <tr height="1px">
		  <td align="left" valign="top" colspan="2" class="<cfoutput>#thisContentClass#</cfoutput>"></td>
	  </tr>
	  <cfif session.isMobile>
	  <tr valign="middle">
		<td class="<cfoutput>#thisContentClass#</cfoutput>" colspan="2">
			LD-JSON is used by the search engines to better understand the structure of your web page. Galaxie Blog automatically generates compressed LD-JSON for your blog postings. You may edit this LD Json here.
		</td>
	   </tr>
	<cfelse><!---<cfif session.isMobile>--->
	  <tr height="30px">
		<td align="left" class="<cfoutput>#thisContentClass#</cfoutput>" colspan="2"> 
			LD-JSON is used by the search engines to better understand the structure of your web page. Galaxie Blog automatically generates compressed LD-JSON for your blog postings. You may edit this LD Json here.<br/>
		</td>
	  </tr>
	</cfif>
	  <!-- Border -->
	  <tr height="2px">
		  <td align="left" valign="top" colspan="<cfoutput>#thisColSpan#</cfoutput>" class="<cfoutput>#thisContentClass#</cfoutput>"></td>
	  </tr>
	  <cfsilent>
	  <!--- Set the class for alternating rows. --->
	  <!---After the first row, the content class should be the current class. --->
	  <cfset thisContentClass = HtmlUtilsObj.getKendoClass(thisContentClass)>
	  </cfsilent>
	  <tr height="2px">
		  <td align="left" valign="top" colspan="2" class="border <cfoutput>#thisContentClass#</cfoutput>"></td>
	  </tr>
	  <!-- Form content -->
	<cfif session.isMobile>
	  <tr valign="middle">
		<td class="<cfoutput>#thisContentClass#</cfoutput>" colspan="2">
			<label for="jsonLdEditor">LD-JSON</label>
		</td>
	   </tr>
	   <tr>
		<td class="<cfoutput>#thisContentClass#</cfoutput>" colspan="2">
			<textarea id="jsonLdEditor" name="jsonLdEditor" rows="20" cols="75"><cfoutput>#jsonLd#</cfoutput></textarea>
		</td>
	  </tr>
	<cfelse><!---<cfif session.isMobile>--->
	  <tr valign="middle" height="30px">
		<td align="right" valign="middle" class="<cfoutput>#thisContentClass#</cfoutput>" width="20%">
			<label for="jsonLdEditor">LD-JSON</label>
		</td>
		<td align="left" class="<cfoutput>#thisContentClass#</cfoutput>">
			<textarea id="jsonLdEditor" name="jsonLdEditor" rows="20" cols="75"><cfoutput>#jsonLd#</cfoutput></textarea>
		</td>
	  </tr>
	</cfif>
	  <!-- Border -->
	  <tr height="2px">
		<td align="left" valign="top" colspan="<cfoutput>#thisColSpan#</cfoutput>" class="<cfoutput>#thisContentClass#</cfoutput>"></td>
	  </tr>
	  <cfsilent>
	  <!--- Set the class for alternating rows. --->
	  <!--- After the first row, the content class should be the current class. --->
	  <cfset thisContentClass = HtmlUtilsObj.getKendoClass(thisContentClass)>
	  </cfsilent>
	  <tr height="2px">
		  <td align="left" valign="top" colspan="2" class="border <cfoutput>#thisContentClass#</cfoutput>"></td>
	  </tr>
	  <!-- Form content -->
	  <tr valign="middle" height="30px">
		<td valign="bottom" align="right" class="<cfoutput>#thisContentClass#</cfoutput>">&nbsp;</td>
		<td valign="bottom" align="left" class="<cfoutput>#thisContentClass#</cfoutput>">
			<button id="jsonLdSubmit" name="jsonLdSubmit" class="k-button k-primary" type="button">Submit</button>
		</td>
	  </tr>
	</table>
	</form>
				
</cfcase>
				
<!--- //************************************************************************************************
		Video WebVtt File tiny mce editor
//**************************************************************************************************--->
				
<cfcase value=16>
	
	<style>
		.mce-ico.mce-i-fa {
		display: inline-block;
		font: normal normal normal 14px/1 FontAwesome;
		font-size: inherit;
		text-rendering: auto;
		-webkit-font-smoothing: antialiased;
		-moz-osx-font-smoothing: grayscale;
	}
	</style>
	
	<!--- Get the post ( getPostByPostId(postId, showPendingPosts, showRemovedPosts) ) --->
	<cfset getPost = application.blog.getPostByPostId(URL.optArgs,true,true)>
	<!---<cfdump var="#getPost#">--->
		
	<!--- See if there is a local video --->
	<cfif getPost[1]["MediaType"] neq 'Video - Large'>
		<p>Before adding video captions, you must have uploaded a local video. Please upload a video by clicking on the video icon in the editor.</p>
	<cfelse>	
		<!--- Get the current video VTT file location --->
		<cfif len(getPost[1]["MediaVideoVttFileUrl"])>
			<cfset videoVttFileUrl = getPost[1]["MediaVideoVttFileUrl"]>
			<!--- Read the file. We will pass back the WebVtt file contents back to the editor. We are using the paragraph2 function to take the native formattting for the system and turn it into HTML. This handles Mac, Unix, and Windows formatting. --->
			<cftry>
				<cffile action="read" file="#expandPath(videoVttFileUrl)#" variable="fileContent">
			<cfcatch type="any">
				<cfset videoVttFileUrl = "">
				<cfset fileContent = "">
			</cfcatch>
			</cftry>
		<cfelse>
			<cfset videoVttFileUrl = "">
			<cfset fileContent = "">
		</cfif>

		<!--- There are two editors on this page, the WebVtt editor and the Video Cover editor. --->

		<!---********************* WebVTT editor *********************--->
		<cfsilent>
		<!--- Note: the tinymce.cfm template will create a unique selectorName that we need to use in the textarea where we want to place the editor.--->
		<cfset selectorId = "webVttEditor">
		<cfif session.isMobile>
			<cfset editorHeight = "325">
		<cfelse>
			<cfset editorHeight = "650">
		</cfif>
		<cfset imageHandlerUrl = ""><!--- Images are not available here --->
		<cfset contentVar = application.Udf.paragraphFormat2(fileContent)>
		<cfset imageMediaIdField = ""><!--- Images are not available here --->
		<cfset imageClass = ""><!--- Images are not available here --->

		<cfif session.isMobile>
			<cfset toolbarString = "undo redo | fileUpload ">
		<cfelse>
			<cfset toolbarString = "undo redo | fileUpload ">
		</cfif>
		<cfset pluginList = "'print preview anchor',
			'searchreplace visualblocks code codesample fullscreen',
			'paste iconfonts'">
		<cfset includeGallery = false>
		<cfset includeVideoUpload = false>
		<cfset includeFileUpload = true>
		</cfsilent>
		<!--- Include the tinymce js template --->
		<cfinclude template="#application.baseUrl#/includes/templates/js/tinyMce.cfm">

		<script>
			$(document).ready(function() {

				// Invoked when the submit button is clicked. Insted of using '$("form").submit(function(event) {' and 'event.preventDefault();', We are using direct binding here to speed up the event.
				var webVttSubmit = $('#webVttSubmit');
				webVttSubmit.on('click', function(e){      
					e.preventDefault();         
					// submit the form.
					saveWebVttFile();
				});
			});//...document.ready

			// Post method on the detail form called from the GalleryDetailFormValidator method on the detail page. The action variable will either be 'update' or 'insert'.
			function saveWebVttFile(){ 
				jQuery.ajax({
					type: 'post', 
					url: '<cfoutput>#application.baseUrl#</cfoutput>/common/cfc/ProxyController.cfc?method=saveFile',
					data: { // arguments
						csrfToken: '<cfoutput>#csrfToken#</cfoutput>',
						file: "<cfoutput>#videoVttFileUrl#</cfoutput>",
						fileContent: tinymce.get("<cfoutput>#selectorName#</cfoutput>").getContent(),
						fileType: 'WebVTT',
						selectorId: '<cfoutput>#selectorId#</cfoutput>'
					},
					dataType: "json",
					success: saveWebVttResponse, // calls the result function.
					error: function(ErrorMsg) {
						console.log('Error' + ErrorMsg);
					}
				// Extract any errors. This is a new jQuery promise based function as of jQuery 1.8.
				}).fail(function (jqXHR, textStatus, error) {

					// The full response is: jqXHR.responseText, but we just want to extract the error.
					$.when(kendo.ui.ExtAlertDialog.show({ title: "Error while consuming the saveFile function", message: error, icon: "k-ext-error", width: "<cfoutput>#application.kendoExtendedUiWindowWidth#</cfoutput>" }) // or k-ext-error, k-ext-information, k-ext-question, k-ext-warning.  You can also specify height.
						).done(function () {
						// Do nothing
					});		
				});
			};

			function saveWebVttResponse(response){
				// Close the webVtt editor window
				jQuery('#webVttFileWindow').kendoWindow('destroy');	
			}

		</script>

		<form id="webVttForm" action="#" method="post" data-role="validator">
		<!--- Pass the csrfToken --->
		<input type="hidden" name="csrfToken" id="csrfToken" value="<cfoutput>#csrfToken#</cfoutput>" />
		<!--- Input for any new videos that have been uploaded --->
		<input type="hidden" name="webVttFile" id="webVttFile" value="" />
		<table align="center" class="k-content tableBorder" width="100%" cellpadding="2" cellspacing="0" border="0">
		  <cfsilent>
				<!---The first content class in the table should be empty. --->
				<cfset thisContentClass = HtmlUtilsObj.getKendoClass('')>
				<!--- Set the colspan property for borders --->
				<cfset thisColSpan = "2">
		  </cfsilent>
		  <tr height="1px">
			  <td align="left" valign="top" colspan="2" class="<cfoutput>#thisContentClass#</cfoutput>"></td>
		  </tr>
		  <tr height="30px">
			<td align="left" class="<cfoutput>#thisContentClass#</cfoutput>" colspan="2"> 
				A WebVTT file allows you to add captions and subtitles in the video. The WebVTT contains the text "WebVTT" and lines of captions with timestamps. Cascading Style sheets can be used to determine the position and the style of the caption. You can either create or edit an existing WebVTT File, or upload a new file using the upload button below.
				<div id="webVttInstructions" name="webVttInstructions"></div>
			</td>
		  </tr>
		  <!-- Border -->
		  <tr height="2px">
			  <td align="left" valign="top" colspan="<cfoutput>#thisColSpan#</cfoutput>" class="<cfoutput>#thisContentClass#</cfoutput>"></td>
		  </tr>
		  <cfsilent>
		  <!--- Set the class for alternating rows. --->
		  <!---After the first row, the content class should be the current class. --->
		  <cfset thisContentClass = HtmlUtilsObj.getKendoClass(thisContentClass)>
		  </cfsilent>
		  <tr height="2px">
			  <td align="left" valign="top" colspan="2" class="border <cfoutput>#thisContentClass#</cfoutput>"></td>
		  </tr>
		  <!-- Form content -->
		<cfif session.isMobile>
		  <tr valign="middle">
			<td class="<cfoutput>#thisContentClass#</cfoutput>" colspan="2">
				<label for="<cfoutput>#selectorName#</cfoutput>">WebVTT Captions</label>
			</td>
		   </tr>
		   <tr>
			<td class="<cfoutput>#thisContentClass#</cfoutput>" colspan="2">
				<textarea id="<cfoutput>#selectorName#</cfoutput>" name="<cfoutput>#selectorName#</cfoutput>"></textarea> 
			</td>
		  </tr>
		<cfelse><!---<cfif session.isMobile>--->
		  <tr valign="middle" height="30px">
			<td align="right" valign="middle" class="<cfoutput>#thisContentClass#</cfoutput>" width="20%">
				<label for="<cfoutput>#selectorName#</cfoutput>">WebVTT Captions</label>
			</td>
			<td align="left" class="<cfoutput>#thisContentClass#</cfoutput>">
				<textarea id="<cfoutput>#selectorName#</cfoutput>" name="<cfoutput>#selectorName#</cfoutput>"></textarea>
			</td>
		  </tr>
		</cfif>
		  <!-- Border -->
		  <tr height="2px">
			<td align="left" valign="top" colspan="<cfoutput>#thisColSpan#</cfoutput>" class="<cfoutput>#thisContentClass#</cfoutput>"></td>
		  </tr>
		  <cfsilent>
		  <!--- Set the class for alternating rows. --->
		  <!--- After the first row, the content class should be the current class. --->
		  <cfset thisContentClass = HtmlUtilsObj.getKendoClass(thisContentClass)>
		  </cfsilent>
		  <tr height="2px">
			  <td align="left" valign="top" colspan="2" class="border <cfoutput>#thisContentClass#</cfoutput>"></td>
		  </tr>
		  <!-- Form content -->
		  <tr valign="middle" height="30px">
			<td valign="bottom" align="right" class="<cfoutput>#thisContentClass#</cfoutput>">&nbsp;</td>
			<td valign="bottom" align="left" class="<cfoutput>#thisContentClass#</cfoutput>">
				<button id="webVttSubmit" name="webVttSubmit" class="k-button k-primary" type="button">Submit</button>
			</td>
		  </tr>
		</table>
		</form>
	</cfif>		
</cfcase>
				
<!--- //************************************************************************************************
		Video WebVTT file uploader
//**************************************************************************************************--->
				
<cfcase value=17>
	
	<cfsilent>
	<!--- Set the uppy theme. --->
	<cfif darkTheme>
		<cfset uppyTheme = 'dark'>
	<cfelse>
		<cfset uppyTheme = 'light'>
	</cfif>
		
	<!--- Not used yet- Get the kendo primay button color in order to reset the uppy actionBtn--upload color --->
	<cfset primaryButtonColor = application.blog.getPrimaryColorsByTheme(kendoTheme:kendoTheme,setting:'accentColor')>
	</cfsilent>
    <div id="webVttFileUpload"></div>
    <script>
		
		// Get the videos mediaId from the mediaId form field on the previous window
		var mediaId = $("#mediaId").val();
		
		var uppy = Uppy.Core({
			restrictions : {
				maxNumberOfFiles: 1,  // only one vtt file can be uploaded at a time
				allowedFileTypes: ['.vtt'] // only allow webvtt
        	}
		})
		
		.use(Uppy.Dashboard, {
			theme: '<cfoutput>#uppyTheme#</cfoutput>',
			inline: true,
			target: '#webVttFileUpload',
			proudlyDisplayPoweredByUppy: false
		})
		// Allow users to take pictures via the onboard camera
		.use(Uppy.Webcam, { target: Uppy.Dashboard })
		// Use the built in image editor
		.use(Uppy.ImageEditor, { 
			target: Uppy.Dashboard,
			quality: 0.8 // for the resulting image, 0.8 is a sensible default
		})
		// Use XHR and send the media to the server for processing
		.use(Uppy.XHRUpload, { endpoint: '<cfoutput>#application.baseUrl#</cfoutput>/common/cfc/ProxyController.cfc?method=uploadFile&mediaProcessType=enclosure&fileType=webVttFile&postId=<cfoutput>#URL.optArgs#</cfoutput>&mediaId=' + mediaId + '&csrfToken=<cfoutput>#csrfToken#</cfoutput>'})
		
		.on('upload-success', (file, response) => {
			// The server is returning location and mediaId in a json object. We need to extract these.
			//alert(response.status) // HTTP status code
			//alert(response.body.location) // The full path of the file that was just uploaded to the server
			//alert(response.body.mediaId) // The MediaId value saved to the Media table in the database.
			//alert(response.body.fileContent) // The content of the webvtt file
			
			// Add some instructions on how to edit the file
			$("#webVttInstructions").val("If this looks correct, you can also close this window to continue. You can also make further changes in the editor below and submit your changes.");
			// Set the file location into a hidden form on the vtt editor
			$("#webVttFile").val(response.body.location);
			// Set the contents of the WebVtt file into the editor. 
			tinymce.activeEditor.setContent(response.body.fileContent);
			// Close the vtt editor window
			jQuery('#webVttFileWindow').kendoWindow('destroy');	
		})
		
		// Events
		// 1) When the dashboard icon is clicked
		// Note: there is no event when the dashboard my device button is clicked. This is a work-around. We are going to use jquery's on click event and put in the class of the button. This is required as the uppy button does not have an id.
		$(".uppy-Dashboard-input").on('click', function(event){
			$.when(kendo.ui.ExtWaitDialog.show({ title: "Please wait...", message: "Please wait for the file uploader interface to respond.", icon: "k-ext-information" }));
		});
		
		// Fired when one of the restrictions failed
		uppy.on('restriction-failed', (file, error) => {
			// Close the wait window that was launched in the calling function.
			kendo.ui.ExtWaitDialog.hide();
		})
		
		// 2) When a file has been uploaded to uppy
		uppy.on('file-added', (file) => {
		  	// Close the wait window that was launched in the calling function.
			kendo.ui.ExtWaitDialog.hide();
		})
		
		// 3) When the upload button was pressed
		uppy.on('upload', (data) => {
			$.when(kendo.ui.ExtWaitDialog.show({ title: "Please wait...", message: "Please wait while the video is uploaded.", icon: "k-ext-information" }));
		})
		
		// 4) When the upload is complete to the server
		uppy.on('complete', (result) => {
			
			// Close the please wait dialog
			// Use a quick set timeout in order for the data to load.
			setTimeout(function() {
				// Close the wait window that was launched in the calling function.
				kendo.ui.ExtWaitDialog.hide();
				// Close this window
				jQuery('#uploadWebVttFileWindow').kendoWindow('destroy');	
			}, 500);	

		})
	
    </script>
				
				
</cfcase>
			
<!--- //************************************************************************************************
		Video Image Cover tiny mce editor
//**************************************************************************************************--->
				
<cfcase value=18>
	
	<!--- Instantiate the Render.cfc. This will be used to build the HTML for the image if the MediaUrl is present in the database. --->
	<cfobject component="#application.rendererComponentPath#" name="RendererObj">
	<!--- Get the post ( getPostByPostId(postId, showPendingPosts, showRemovedPosts) )--->
	<cfset getPost = application.blog.getPostByPostId(URL.optArgs,true,true)>
	<!---<cfdump var="#getPost#">--->
		
	<!--- Get the current video cover URL --->
	<cfif len(getPost[1]["MediaVideoCoverUrl"])>
		<cfset mediaUrl = getPost[1]["MediaVideoCoverUrl"]>
	<cfelse>
		<cfset mediaUrl = "">
	</cfif>
		
	<!--- Render the image HTML string --->
	<cfset mediaHtml = RendererObj.renderEnclosureImage(mediaUrl)>
	
	<!--- See if there is a local video --->
	<cfif getPost[1]["MediaType"] neq 'Video - Large'>
		<p>Before adding an image to cover a video, you must have uploaded a local video. Please upload a video by clicking on the video icon in the editor.</p>
	<cfelse>	
	
		<style>
			.mce-ico.mce-i-fa {
			display: inline-block;
			font: normal normal normal 14px/1 FontAwesome;
			font-size: inherit;
			text-rendering: auto;
			-webkit-font-smoothing: antialiased;
			-moz-osx-font-smoothing: grayscale;
		}
		</style>

		<script>
			function onVideoImageCoverSubmit(){
				// Refresh the media preview- pass in the postId
				reloadEnclosureThumbnailPreview(<cfoutput>#URL.optArgs#</cfoutput>);
				// Use a quick set timeout in order for the data to load.
				setTimeout(function() {
					// Close this window
					jQuery('#videoCoverWindow').kendoWindow('destroy');	
				}, 500);	
			}
		</script>

		<!--- ********************************** Video Cover Editor ******************************** --->
		<cfsilent>
		<cfset selectorId = "videoCoverEditor">
		<cfif session.isMobile>
			<cfset editorHeight = "325">
		<cfelse>
			<cfset editorHeight = "650">
		</cfif>
		<cfset imageHandlerUrl = application.baseUrl & "/common/cfc/ProxyController.cfc?method=uploadImage&mediaProcessType=mediaVideoCoverUrl&mediaType=image&postId=" & URL.optArgs & "&selectorId=" & selectorId & "&csrfToken=" & csrfToken>
		<cfset contentVar = mediaHtml>
		<cfset imageMediaIdField = "imageMediaId">

		<cfset imageClass = "entryImage">

		<cfif session.isMobile>
			<cfset toolbarString = "undo redo | image | editimage ">
		<cfelse>
			<cfset toolbarString = "undo redo | image | editimage">
		</cfif>
		<cfset includeGallery = false>
		<cfset includeVideoUpload = true>
		</cfsilent>
		<!--- Include the tinymce js template --->
		<cfinclude template="#application.baseUrl#/includes/templates/js/tinyMce.cfm">

		<form id="enclosureForm" action="#" method="post" data-role="validator">
		<!--- Pass the csrfToken --->
		<input type="hidden" name="csrfToken" id="csrfToken" value="<cfoutput>#csrfToken#</cfoutput>" />
		<!--- Input for any new videos that have been uploaded --->
		<input type="hidden" name="videoCoverMediaId" id="videoCoverMediaId" value="" />
		<table align="center" class="k-content tableBorder" width="100%" cellpadding="2" cellspacing="0" border="0">
		  <cfsilent>
				<!---The first content class in the table should be empty. --->
				<cfset thisContentClass = HtmlUtilsObj.getKendoClass('')>
				<!--- Set the colspan property for borders --->
				<cfset thisColSpan = "2">
		  </cfsilent>
		  <tr height="2px">
			  <td align="left" valign="top" colspan="2" class="border <cfoutput>#thisContentClass#</cfoutput>"></td>
		  </tr>
		  <!-- Form content -->
		  <tr valign="middle" height="30px">
			<td align="right" width="25%">Video Cover Image</td>
			<td align="left" width="75%" class="<cfoutput>#thisContentClass#</cfoutput>" colspan="2">
				<!--- TinyMce container --->
				<div style="position: relative;">
					<textarea id="<cfoutput>#selectorName#</cfoutput>" name="<cfoutput>#selectorName#</cfoutput>"></textarea>
				</div>    
			</td>
		  </tr>
		  <cfsilent>
		  <!--- Set the class for alternating rows. --->
		  <!--- After the first row, the content class should be the current class. --->
		  <cfset thisContentClass = HtmlUtilsObj.getKendoClass(thisContentClass)>
		  </cfsilent>
		  <tr height="2px">
			  <td align="left" valign="top" colspan="2" class="border <cfoutput>#thisContentClass#</cfoutput>"></td>
		  </tr>
		  <!-- Form content -->
		  <tr valign="middle" height="30px">
			<td valign="bottom" align="right" class="<cfoutput>#thisContentClass#</cfoutput>">&nbsp;</td>
			<td valign="bottom" align="left" class="<cfoutput>#thisContentClass#</cfoutput>">
				<button id="videoCoverSubmit" name="videoCoverSubmit" class="k-button k-primary" type="button" onClick="onVideoImageCoverSubmit();">Submit</button>
			</td>
		  </tr>
		</table>
		</form>
	</cfif>		
</cfcase>
	
<!--- //************************************************************************************************
		Maps
//**************************************************************************************************--->
				
<cfcase value=19>
	
	<!--- Instantiate the Render.cfc. This will be used to build the HTML for the image if the MediaUrl is present in the database. --->
	<cfobject component="#application.rendererComponentPath#" name="RendererObj">
	<!--- Get the post ( getPostByPostId(postId, showPendingPosts, showRemovedPosts) ) --->
	<cfset getPost = application.blog.getPostByPostId(URL.optArgs,true,true)>
	<!---<cfdump var="#getPost#">--->
	<!--- Get the mapId if already present. --->
	<cfset mapId = getPost[1]["EnclosureMapId"]>
	
	<!--- Get static map data --->
	<cfif isDefined("mapId") and len(mapId)>
		<cfset getMap = application.blog.getMapByMapId(mapId)>
	<cfelse>
		<cfset getMap = []>
	</cfif>
	<!---<cfdump var="#getMap#">--->
		
	<!--- If the map exists, set the vars. --->
	<cfif arrayLen(getMap)>
		<cfset geoCoordinates = getMap[1]["GeoCoordinates"]>
		<cfset location = getMap[1]["Location"]>
		<cfset mapType = getMap[1]["MapType"]>
		<cfset zoom = getMap[1]["Zoom"]>
		<cfset customMarkerUrl = getMap[1]["CustomMarkerUrl"]>
		<cfset outlineMap = getMap[1]["OutlineMap"]>
		<cfset hasMapRoutes = getMap[1]["HasMapRoutes"]>
	<cfelse>	
		<cfset geoCoordinates = ''>
		<cfset location = ''>
		<cfset mapType = ''>
		<cfset zoom = ''>
		<cfset customMarkerUrl = ''>
		<cfset outlineMap = false>
		<cfset hasMapRoutes = 0>
	</cfif>
		
	<script type='text/javascript'>
		var map;

		function GetMap() {
			map = new Microsoft.Maps.Map('#myMap', {});

			Microsoft.Maps.loadModule('Microsoft.Maps.AutoSuggest', function () {
				var manager = new Microsoft.Maps.AutosuggestManager({ map: map });
				manager.attachAutosuggest('#searchBox', '#searchBoxContainer', suggestionSelected);
			});
		}

		function suggestionSelected(result) {
			// Remove previously selected suggestions from the map.
			map.entities.clear();
			
		
			// Create custom Pushpin
			var pin = new Microsoft.Maps.Pushpin(result.location, {
				<cfif len(customMarkerUrl)>
				icon: 'https://www.bingmapsportal.com/Content/images/poi_custom.png',
				</cfif>
				anchor: new Microsoft.Maps.Point(12, 39)
			});
		
			// Show the suggestion as a pushpin and center map over it.
			//var pin = new Microsoft.Maps.Pushpin(result.location);
			map.entities.push(pin);
			//map.setOptions({ enableHoverStyle: true, enableClickedStyle: true });

			map.setView({ bounds: result.bestView });
			
			// Save the location data into a hidden form
			// console.log(result)
			$("#mapAddress").val(result.formattedSuggestion);
			$("#mapCoordinates").val(result.location.latitude + ',' + result.location.longitude);
		}
		
		function saveMap(){
			
			// Let the user know that we are processing the data
			$.when(kendo.ui.ExtWaitDialog.show({ title: "Please wait...", message: "Please wait while we create your map.", width: "<cfoutput>#application.kendoExtendedUiWindowWidth#</cfoutput>", icon: "k-ext-information" }));
			
			jQuery.ajax({
				type: 'post', 
				url: '<cfoutput>#application.baseUrl#</cfoutput>/common/cfc/ProxyController.cfc?method=saveMap',
				// Serialize the form
				data: {
					csrfToken: '<cfoutput>#csrfToken#</cfoutput>',
					isEnclosure: <cfif URL.otherArgs eq 'enclosureEditor'>true<cfelse>false</cfif>,
					mapId: $("#enclosureMapId").val(),
					postId: "<cfoutput>#URL.optArgs#</cfoutput>",
					mapType: map.getImageryId(),
					mapZoom: map.getZoom(),
					mapAddress: $("#mapAddress").val(),
					mapCoordinates: $("#mapCoordinates").val(),
					outlineMap: $("#outlineLocation").prop('checked'),
					customMarker: $("#customMarker").val()
				},
				dataType: "json",
				success: saveMapResponse, // calls the result function.
				error: function(ErrorMsg) {
					console.log('Error' + ErrorMsg);
				}
			// Extract any errors. This is a new jQuery promise based function as of jQuery 1.8.
			}).fail(function (jqXHR, textStatus, error) {

				// The full response is: jqXHR.responseText, but we just want to extract the error.
				$.when(kendo.ui.ExtAlertDialog.show({ title: "Error while consuming the saveMap function", message: error, icon: "k-ext-error", width: "425px" }) // or k-ext-error, k-ext-information, k-ext-question, k-ext-warning.  You can also specify height.
					).done(function () {
					// Do nothing
				});		
			});
		}
		
		function saveMapResponse(response){
			
			//alert(JSON.parse(response.postId));
			var postId = JSON.parse(response.postId);
			var mapId = JSON.parse(response.mapId);
			
			// Create our iframe html string
			var mapIframeHtml = '<iframe data-type="map" data-id=' + mapId + ' src="<cfoutput>#application.baseUrl#</cfoutput>/preview/maps.cfm?mapId=' + mapId + '&mapType=static" width="768" height="432" allowfullscreen="allowfullscreen"></iframe>';
			// Insert the HTML string into the active editor
			// If this is the enclosure content, replace the content. If it is a post editor, insert the content
			tinymce.activeEditor.<cfif URL.otherArgs eq 'enclosureEditor'>setContent<cfelse>insertContent</cfif>(mapIframeHtml);
			
			// Use a quick set timeout in order for the data to load.
			setTimeout(function() {
				// Refresh the thumbnail image on the post detail page
				reloadEnclosureThumbnailPreview(postId);
				// Close the wait window that was launched in the calling function.
				kendo.ui.ExtWaitDialog.hide();
				// Close this window
				$('#mapWindow').kendoWindow('destroy');
			}, 500);

		}
    </script>
		
	<style>
        html, body{
            padding: 0;
            margin: 0;
            height: 100%;
        }

        .directionsContainer {
            width: 450px;
			/* Set the input container at 425 pixels. Any less will cause part of the input to disappear */
            height: 100%;
            overflow-y: auto;
            float: left;
        }

        #myMap {
            position: relative;
			/* Set the dimensions of the main map */
            width:calc(100% - 450px);
            height: 100%;
            float: left;
        }
		
		/* Move the directions input container a little bit since its stuck at the left of the page margin-left: 45px;*/
		.MicrosoftMap .directionsPanel {
			margin-left: 25px;
		}
    </style>
		
	<!--- Call the mapcontrol script. --->
    <script type='text/javascript' src='https://www.bing.com/api/maps/mapcontrol?callback=GetMap&key=<cfoutput>#application.bingMapsApiKey#</cfoutput>' async defer></script>
		
	<div class="directionsContainer" class="k-content">
		<div id='searchBoxContainer' class="k-content">
			<input type="hidden" name="mapAddress" id="mapAddress" value="<cfoutput>#location#</cfoutput>"/>
			<input type="hidden" name="mapCoordinates" id="mapCoordinates" value="<cfoutput>#geoCoordinates#</cfoutput>"/>
			<table align="center" width="95%" class="k-content" cellpadding="2" cellspacing="0">
				<cfsilent>
				<!--- The first content class in the table should be empty. --->
				<cfset thisContentClass = HtmlUtilsObj.getKendoClass('')>
				<!--- Set the colspan property for borders --->
				<cfset thisColSpan = "2">
				</cfsilent>
				<tr height="1px">
					<td align="left" valign="top" colspan="2" class="<cfoutput>#thisContentClass#</cfoutput>"></td>
				</tr>
				<tr>
					<td colspan="2"> 
						<p>Type in a location or address in the location form to drop a pin. An autosuggest will appear below the location input to help you select the proper location.</p>
						<p>You can also use the map controls to the right to customize the map type (road, arial, etc) and set the zoom. If you want a different location pin, indicate the path to the image in the field below.</p> 
						<p>If the location is a city, state, or region, you can highlight the location by clicking on the highlight checkmark below. When you're satisfied with the look and feel of the map, click on the submit button below.</p>
					</td>
				</tr>
				<!-- Border -->
				<tr height="2px">
				  <td align="left" valign="top" colspan="<cfoutput>#thisColSpan#</cfoutput>" class="<cfoutput>#thisContentClass#</cfoutput>"></td>
				</tr>
				<cfsilent>
				<!--- Set the class for alternating rows. --->
				<!---After the first row, the content class should be the current class. --->
				<cfset thisContentClass = HtmlUtilsObj.getKendoClass(thisContentClass)>
				</cfsilent>
				<tr height="2px">
				  <td align="left" valign="top" colspan="2" class="border <cfoutput>#thisContentClass#</cfoutput>"></td>
				</tr>
				<!-- Form content -->
			<cfif session.isMobile>
			  <tr valign="middle">
				<td class="<cfoutput>#thisContentClass#</cfoutput>" colspan="2">
					<label for="searchBox">Location</label>
				</td>
			   </tr>
			   <tr>
				<td class="<cfoutput>#thisContentClass#</cfoutput>" colspan="2">
					<input id="searchBox" name="searchBox" value="<cfoutput>#location#</cfoutput>" class="k-textbox" style="width: 95%" /> 
				</td>
			  </tr>
			<cfelse><!---<cfif session.isMobile>--->
				<tr>
					<td align="right" class="<cfoutput>#thisContentClass#</cfoutput>"> 
						<label for="searchBox">Location</label>
					</td>
					<td class="<cfoutput>#thisContentClass#</cfoutput>">
						<input id="searchBox" name="searchBox" value="<cfoutput>#location#</cfoutput>" class="k-textbox" style="width: 85%" />
					</td>
				</tr>
			</cfif>
				<!-- Border -->
				<tr height="2px">
				  <td align="left" valign="top" colspan="<cfoutput>#thisColSpan#</cfoutput>" class="<cfoutput>#thisContentClass#</cfoutput>"></td>
				</tr>
				<cfsilent>
				<!--- Set the class for alternating rows. --->
				<!---After the first row, the content class should be the current class. --->
				<cfset thisContentClass = HtmlUtilsObj.getKendoClass(thisContentClass)>
				</cfsilent>
				<tr height="2px">
				  <td align="left" valign="top" colspan="2" class="border <cfoutput>#thisContentClass#</cfoutput>"></td>
				</tr>
				<!-- Form content -->
				<!---
				<tr valign="middle">
				  <td align="right" valign="middle" width="30%" class="<cfoutput>#thisContentClass#</cfoutput>">
					<label for="customMarker">Custom Pin Preview</label>
				  </td>
				  <td align="left" width="70%" class="<cfoutput>#thisContentClass#</cfoutput>">
					<div class="squareThumbnail"><img data-src="/images/logo/logoMaterialThemeOs.gif" alt="" class="portrait lazied shown" data-lazied="IMG" src="/images/logo/logoMaterialThemeOs.gif"></a></div>
				  </td>
				</tr>
				--->
			<cfif session.isMobile>
			  <tr valign="middle">
				<td class="<cfoutput>#thisContentClass#</cfoutput>" colspan="2">
					<label for="customMarker">Pin URL</label>
				</td>
			   </tr>
			   <tr>
				<td class="<cfoutput>#thisContentClass#</cfoutput>" colspan="2">
					<input id="customMarker" name="customMarker" value="<cfoutput>#customMarkerUrl#</cfoutput>" class="k-textbox" style="width: 95%" onClick="createAdminInterfaceWindow(21,<cfoutput>#URL.optArgs#</cfoutput>)" />  
				</td>
			  </tr>
			<cfelse><!---<cfif session.isMobile>--->
				<tr valign="middle">
				  <td align="right" valign="middle" width="30%" class="<cfoutput>#thisContentClass#</cfoutput>">
					<label for="customMarker">Pin URL</label>
				  </td>
				  <td align="left" width="70%" class="<cfoutput>#thisContentClass#</cfoutput>">
					<input id="customMarker" name="customMarker" value="<cfoutput>#customMarkerUrl#</cfoutput>" class="k-textbox" style="width: 85%" onClick="createAdminInterfaceWindow(21,<cfoutput>#URL.optArgs#</cfoutput>)" />  
				  </td>
				</tr>
			</cfif>
				<!-- Border -->
				<tr height="2px">
				  <td align="left" valign="top" colspan="<cfoutput>#thisColSpan#</cfoutput>" class="<cfoutput>#thisContentClass#</cfoutput>"></td>
				</tr>
				<cfsilent>
				<!--- Set the class for alternating rows. --->
				<!---After the first row, the content class should be the current class. --->
				<cfset thisContentClass = HtmlUtilsObj.getKendoClass(thisContentClass)>
				</cfsilent>
				<tr height="2px">
				  <td align="left" valign="top" colspan="2" class="border <cfoutput>#thisContentClass#</cfoutput>"></td>
				</tr>
				<!-- Form content -->
			<cfif session.isMobile>
			  <tr valign="middle">
				<td class="<cfoutput>#thisContentClass#</cfoutput>" colspan="2">
					<label for="post">Outline Location</label>
				</td>
			   </tr>
			   <tr>
				<td class="<cfoutput>#thisContentClass#</cfoutput>" colspan="2">
					<input type="checkbox" id="outlineLocation" name="outlineLocation" <cfif outlineMap>checked</cfif>/> 
				</td>
			  </tr>
			<cfelse><!---<cfif session.isMobile>--->
				<tr valign="middle">
				  <td align="right" valign="middle" width="30%" class="<cfoutput>#thisContentClass#</cfoutput>">
					<label for="post">Outline Location</label>
				  </td>
				  <td align="left" width="70%" class="<cfoutput>#thisContentClass#</cfoutput>">
					<input type="checkbox" id="outlineLocation" name="outlineLocation" <cfif outlineMap>checked</cfif>/> 
				  </td>
				</tr>
			</cfif>
				<!-- Border -->
				<tr height="2px">
				  <td align="left" valign="top" colspan="<cfoutput>#thisColSpan#</cfoutput>" class="<cfoutput>#thisContentClass#</cfoutput>"></td>
				</tr>
				<cfsilent>
				<!--- Set the class for alternating rows. --->
				<!---After the first row, the content class should be the current class. --->
				<cfset thisContentClass = HtmlUtilsObj.getKendoClass(thisContentClass)>
				</cfsilent>
				<tr height="2px">
				  <td align="left" valign="top" colspan="2" class="border <cfoutput>#thisContentClass#</cfoutput>"></td>
				</tr>
				<tr valign="middle">
				  <td colspan="2">
					<button id="createMap" class="k-button k-primary" type="button" onclick="saveMap()">Submit</button>
				  </td>
				</tr>   
			</table>
		</div><!---<div id='searchBoxContainer'>--->
    </div><!---<div class="directionsContainer">--->
			
	<!--- Map container to the right of the screen holding the map--->
    <div id="myMap"></div>
		
</cfcase>
		
<!--- //************************************************************************************************
		Map Routing
//**************************************************************************************************--->
		
<cfcase value=20>
	
	<!--- Instantiate the Render.cfc. This will be used to build the HTML for the image if the MediaUrl is present in the database. --->
	<cfobject component="#application.rendererComponentPath#" name="RendererObj">
	<!--- Get the post ( getPostByPostId(postId, showPendingPosts, showRemovedPosts) ) --->
	<cfset getPost = application.blog.getPostByPostId(URL.optArgs,true,true)>
	<!---<cfdump var="#getPost#">--->
		
	<!--- When the map already contains routes the location does not show up when submitting the form. This flag will turn off the existing directions so that the user has to fill out the form again. --->
	<cfset showCurrentDirections = true>
	
	<!--- Get the current routes if available --->
	<cfset enclosureMapId = getPost[1]["EnclosureMapId"]>
	<cfif len(enclosureMapId)>
		<cfset Data = application.blog.getMapRoutesByMapId(enclosureMapId)>
		<!---<cfdump var="#Data#">--->
	</cfif>
	
	<script type='text/javascript'>
        var map;
        var directionsManager;

        function GetMap()
        {
            map = new Microsoft.Maps.Map('#myMap', {});

            // Load the directions module.
            Microsoft.Maps.loadModule('Microsoft.Maps.Directions', function () {
                // Create an instance of the directions manager.
                directionsManager = new Microsoft.Maps.Directions.DirectionsManager(map);
			<cfif showCurrentDirections and len(enclosureMapId) and arrayLen(Data)><cfloop from="1" to="#arrayLen(Data)#" index="i"><cfoutput>
				// Create our waypoints
				directionsManager.addWaypoint(new Microsoft.Maps.Directions.Waypoint({ address: '#Data[i]['Location']#' }));
			</cfoutput></cfloop></cfif>				
                // Specify where to display the route instructions.
                directionsManager.setRenderOptions({ itineraryContainer: '#directionsItinerary' });
                // Specify the where to display the input panel
                directionsManager.showInputPanel('directionsPanel');
            });
        }
		
		// We need to extract the waypoints
		function getWaypoints(){
            var wp = directionsManager.getAllWaypoints();

            var text = '';
			var valuesList = '';
			var locationCoordinateList = '';

            for(var i=0; i < wp.length; i++){
                var loc = wp[i].getLocation();
				// console.log(loc)
                text += 'name ' + loc.name + ', waypoint ' + i + ': ' + loc.latitude + ', ' + loc.longitude + '\r\n';
				if (i == 0){
					valuesList += loc.name + '_' + loc.latitude + '_' + loc.longitude;
				} else {
					valuesList += '*' + loc.name + '_' + loc.latitude + '_' + loc.longitude;
				}
				
            }
			//alert(text);
			// Post the values to the server
			saveMapRoute(valuesList);
        }
		
		function saveMapRoute(locationGeoCoordinates){
			
			// Let the user know that we are processing the data
			$.when(kendo.ui.ExtWaitDialog.show({ title: "Please wait...", message: "Please wait while we create your map.", icon: "k-ext-information" }));
			
			jQuery.ajax({
				type: 'post', 
				url: '<cfoutput>#application.baseUrl#</cfoutput>/common/cfc/ProxyController.cfc?method=saveMapRoute',
				// Serialize the form
				data: {
					csrfToken: '<cfoutput>#csrfToken#</cfoutput>',
					locationGeoCoordinates: locationGeoCoordinates,
					// Is this an enclosure? The otherArgs in the URL will determine what tinymce editor instance is being used.
					isEnclosure: <cfif URL.otherArgs eq 'enclosureEditor'>true<cfelse>false</cfif>,
					mapId: $("#enclosureMapId").val(),
					mapRouteId: $("#mapRouteId").val(),
					postId: "<cfoutput>#URL.optArgs#</cfoutput>",
				},
				dataType: "json",
				success: saveMapRouteResponse, // calls the result function.
				error: function(ErrorMsg) {
					console.log('Error' + ErrorMsg);
				}
			// Extract any errors. This is a new jQuery promise based function as of jQuery 1.8.
			}).fail(function (jqXHR, textStatus, error) {

				// The full response is: jqXHR.responseText, but we just want to extract the error.
				$.when(kendo.ui.ExtAlertDialog.show({ title: "Error while consuming the saveMapRoute function", message: error, icon: "k-ext-error", width: "<cfoutput>#application.kendoExtendedUiWindowWidth#</cfoutput>" }) // or k-ext-error, k-ext-information, k-ext-question, k-ext-warning.  You can also specify height.
					).done(function () {
					// Do nothing
				});		
			});
		}
		
		function saveMapRouteResponse(response){
			
			//alert(JSON.parse(response.postId));
			var postId = JSON.parse(response.postId);
			var mapId = JSON.parse(response.mapId);
			
			// Create our iframe html string
			var mapIframeHtml = '<iframe data-type="map" data-id=' + mapId + ' src="<cfoutput>#application.baseUrl#</cfoutput>/preview/maps.cfm?mapId=' + mapId + '&mapType=route" width="768" height="432" allowfullscreen="allowfullscreen"></iframe>';
			// Insert the HTML string into the active editor
			// If this is the enclosure content, replace the content. If it is a post editor, insert the content
			tinymce.activeEditor.<cfif URL.otherArgs eq 'enclosureEditor'>setContent<cfelse>insertContent</cfif>(mapIframeHtml);
			
			// Use a quick set timeout in order for the data to load.
			setTimeout(function() {
				// Close the wait window that was launched in the calling function.
				kendo.ui.ExtWaitDialog.hide();
				// Refresh the thumbnail image on the post detail page
				reloadEnclosureThumbnailPreview(postId);
				// Close the window
				$('#mapRoutingWindow').kendoWindow('destroy');
			}, 500);

		}
		
    </script>
    <style>
        html, body{
            padding: 0;
            margin: 0;
            height: 100%;
        }

        .directionsContainer {
            width: 425px;
			/* Set the input container at 425 pixels. Any less will cause part of the input to disappear */
            height: 100%;
            overflow-y: auto;
            float: left;
			background-color: white;
        }

        #myMap{
            position: relative;
			/* Set the dimensions of the main map */
            width:calc(100% - 425px);
            height: 100%;
            float: left;
        }
		
		/* Move the directions input container a little bit since its stuck at the left of the page margin-left: 45px;*/
		.MicrosoftMap .directionsPanel {
			margin-left: 25px;
		}
    </style>
	
	<!--- Get the map UI from Bing --->
	<script type='text/javascript' src='https://www.bing.com/api/maps/mapcontrol?callback=GetMap&key=<cfoutput>#application.bingMapsApiKey#</cfoutput>' async defer></script>

	<!--- Container to the left holding the search input and directions --->
    <div class="directionsContainer">
		
		<input type="hidden" id="enclosureMapId" name="enclosureMapId" value="<cfoutput>#getPost[1]['EnclosureMapId']#</cfoutput>">
		<table align="center" class="k-content" width="95%" cellpadding="5" cellspacing="0">
			<tr>
				<td>Create a route by searching in addresses between two or more points. You can add up to 15 waypoints. When complete, click on the button below to continue.</td>
			</tr>
			<tr>
				<td>
					<button id="createRoute" class="k-button k-primary" type="button" onclick="getWaypoints()">Complete</button>
				</td>
			</tr>
		</table>
		
        <div id="directionsPanel"></div>
        <div id="directionsItinerary"></div>
		
		<div id="output"></div>
		
		
    </div><!---<div class="directionsContainer">--->
	
	<!--- Map container to the right of the screen holding the map--->
    <div id="myMap"></div>
		
</cfcase>
		
<!--- //************************************************************************************************
		Map Cursor Image Uploader 
//**************************************************************************************************--->
		
<cfcase value=21>
	
	<!--- Instantiate the Render.cfc. This will be used to build the HTML for the image if the MediaUrl is present in the database. --->
	<cfobject component="#application.rendererComponentPath#" name="RendererObj">
	
	<!--- Get the post ( getPostByPostId(postId, showPendingPosts, showRemovedPosts) ) --->
	<cfset getPost = application.blog.getPostByPostId(URL.optArgs, true, true)>
	<!---<cfdump var="#getPost#">--->
	<!--- Get the mapId if present. --->
	<cfset mapId = getPost[1]["EnclosureMapId"]>
	<cfif len(mapId)>
		<!--- Get the map --->
		<cfset getMap = application.blog.getMapByMapId(mapId)>
		<!--- Get the current video cover URL --->
		<cfset imageUrl = getMap[1]["CustomMarkerUrl"]>
		<!--- Render the image HTML string --->
		<cfset imageHtml = RendererObj.renderImage(imageUrl)>
	<cfelse>
		<cfset imageUrl = ''>
		<cfset imageHtml = ''>
	</cfif>
		
	<cfset label = "Map Cursor Image">
		
	<style>
		.mce-ico.mce-i-fa {
		display: inline-block;
		font: normal normal normal 14px/1 FontAwesome;
		font-size: inherit;
		text-rendering: auto;
		-webkit-font-smoothing: antialiased;
		-moz-osx-font-smoothing: grayscale;
	}
	</style>

	<script>
		function onImageSubmit(){
			// Use a quick set timeout in order for the data to load.
			setTimeout(function() {
				// Close this window
				jQuery('#cursorImageWindow').kendoWindow('destroy');	
			}, 500);	
		}
	</script>

	<!--- ********************************** Map Cursor Image Editor ******************************** --->
	<cfsilent>
	<cfset selectorId = "mapCursorEditor">
	<cfif session.isMobile>
		<cfset editorHeight = "325">
	<cfelse>
		<cfset editorHeight = "650">
	</cfif>
	<cfset imageHandlerUrl = application.baseUrl & "/common/cfc/ProxyController.cfc?method=uploadImage&mediaProcessType=mapCursor&mediaType=image&mapId=" & mapId & "&selectorId=" & selectorId & "&csrfToken=" & csrfToken>
	<cfset contentVar = imageHtml>
	<cfset imageMediaIdField = "mapCursorUrl">
	<cfset imageClass = "entryImage">

	<cfif session.isMobile>
		<cfset toolbarString = "undo redo | image | editimage ">
	<cfelse>
		<cfset toolbarString = "undo redo | image | editimage">
	</cfif>
	<cfset includeGallery = false>
	<cfset includeVideoUpload = true>
	</cfsilent>
	<!--- Include the tinymce js template --->
	<cfinclude template="#application.baseUrl#/includes/templates/js/tinyMce.cfm">

	<form id="enclosureForm" action="#" method="post" data-role="validator">
	<!--- Pass the csrfToken --->
	<input type="hidden" name="csrfToken" id="csrfToken" value="<cfoutput>#csrfToken#</cfoutput>" />
	<!--- Input for any new videos that have been uploaded --->
	<input type="hidden" name="videoCoverMediaId" id="videoCoverMediaId" value="" />
	<table align="center" class="k-content tableBorder" width="100%" cellpadding="2" cellspacing="0" border="0">
	  <cfsilent>
			<!---The first content class in the table should be empty. --->
			<cfset thisContentClass = HtmlUtilsObj.getKendoClass('')>
			<!--- Set the colspan property for borders --->
			<cfset thisColSpan = "2">
	  </cfsilent>
	  <tr height="2px">
		  <td align="left" valign="top" colspan="2" class="border <cfoutput>#thisContentClass#</cfoutput>"></td>
	  </tr>
	  <!-- Form content -->
	<cfif session.isMobile>
	  <tr valign="middle">
		<td class="<cfoutput>#thisContentClass#</cfoutput>" colspan="2">
			<cfoutput><label>#Label#</label></cfoutput>
		</td>
	   </tr>
	   <tr>
		<td class="<cfoutput>#thisContentClass#</cfoutput>" colspan="2">
			<!--- TinyMce container --->
			<div style="position: relative;">
				<textarea id="<cfoutput>#selectorName#</cfoutput>" name="<cfoutput>#selectorName#</cfoutput>"></textarea>
			</div>   
		</td>
	  </tr>
	<cfelse><!---<cfif session.isMobile>--->
	  <tr valign="middle" height="30px">
		  <td align="right"><cfoutput><label>#Label#</label></cfoutput></td>
		<td align="left" class="<cfoutput>#thisContentClass#</cfoutput>" colspan="2">
			<!--- TinyMce container --->
			<div style="position: relative;">
				<textarea id="<cfoutput>#selectorName#</cfoutput>" name="<cfoutput>#selectorName#</cfoutput>"></textarea>
			</div>    
		</td>
	  </tr>
	</cfif>
	  <cfsilent>
	  <!--- Set the class for alternating rows. --->
	  <!--- After the first row, the content class should be the current class. --->
	  <cfset thisContentClass = HtmlUtilsObj.getKendoClass(thisContentClass)>
	  </cfsilent>
	  <tr height="2px">
		  <td align="left" valign="top" colspan="2" class="border <cfoutput>#thisContentClass#</cfoutput>"></td>
	  </tr>
	  <!-- Form content -->
	  <tr valign="middle" height="30px">
		<td valign="bottom" align="right" class="<cfoutput>#thisContentClass#</cfoutput>">&nbsp;</td>
		<td valign="bottom" align="left" class="<cfoutput>#thisContentClass#</cfoutput>">
			<button id="imageSubmit" name="imageSubmit" class="k-button k-primary" type="button" onClick="onImageSubmit();">Submit</button>
		</td>
	  </tr>
	</table>
	</form>
		  
</cfcase>
		
<!--- //************************************************************************************************
		Interface Displaying the Compressed JSON-LD String (for testing using external sites)
//**************************************************************************************************--->
		
<cfcase value=22>
	
	<style>
		.mce-ico.mce-i-fa {
		display: inline-block;
		font: normal normal normal 14px/1 FontAwesome;
		font-size: inherit;
		text-rendering: auto;
		-webkit-font-smoothing: antialiased;
		-moz-osx-font-smoothing: grayscale;
	}
	</style>
		
	<!--- Get the post. Here we aer passing the postId, true to get removed posts, and true to get the ld-json body ( getPostByPostId(postId, showPendingPosts, showRemovedPosts) ). --->
	<cfset getPost = application.blog.getPostByPostId(URL.optArgs,true,true)>
	<!---<cfdump var="#getPost#">--->
		
	<cfif len(getPost[1]["JsonLd"])>
		<!--- Get the current LD JSON --->
		<cfset jsonLd = getPost[1]["JsonLd"]>
		<!--- Clean it up... --->
		<cfset jsonLd = application.blog.cleanJsonLd(jsonLd)>
	<cfelse>
		<!--- Render the LD JSON --->
		<cfobject component="#application.rendererComponentPath#" name="RendererObj">
		<!--- The false argument will get the actual JSON string. --->
		<cfset jsonLd = RendererObj.renderLdJson(URL.optArgs, false)>
	</cfif>
	<!---<cfdump var="#jsonLd#">--->

	<form id="jsonLdForm" action="#" method="post" data-role="validator">
	<table align="center" class="k-content tableBorder" width="100%" cellpadding="2" cellspacing="0" border="0">
	  <cfsilent>
			<!---The first content class in the table should be empty. --->
			<cfset thisContentClass = HtmlUtilsObj.getKendoClass('')>
			<!--- Set the colspan property for borders --->
			<cfset thisColSpan = "1">
	  </cfsilent>
	  <tr height="1px">
		  <td align="left" valign="top" class="<cfoutput>#thisContentClass#</cfoutput>"></td>
	  </tr>
	  <tr height="30px">
		<td align="left" class="<cfoutput>#thisContentClass#</cfoutput>"> 
			Actual JSON-LD string used for this post.
		</td>
	  </tr>
	  <!-- Border -->
	  <tr height="2px">
		  <td align="left" valign="top" class="<cfoutput>#thisContentClass#</cfoutput>"></td>
	  </tr>
	  <cfsilent>
	  <!--- Set the class for alternating rows. --->
	  <!---After the first row, the content class should be the current class. --->
	  <cfset thisContentClass = HtmlUtilsObj.getKendoClass(thisContentClass)>
	  </cfsilent>
	  <tr height="2px">
		  <td align="left" valign="top" class="border <cfoutput>#thisContentClass#</cfoutput>"></td>
	  </tr>
	  <!-- Form content -->
	  <tr valign="middle" height="30px">
		<td align="left" class="<cfoutput>#thisContentClass#</cfoutput>">
			<cfoutput>#jsonLd#</cfoutput>
		</td>
	  </tr>
	  <!-- Border -->
	  <tr height="2px">
		<td align="left" valign="top" class="<cfoutput>#thisContentClass#</cfoutput>"></td>
	  </tr>
	</table>
	</form>
				
</cfcase>
		
<!--- //************************************************************************************************
		Post Alias 
//**************************************************************************************************--->
	
<cfcase value=23>
	
	<!--- Get the post ( getPostByPostId(postId, showPendingPosts, showRemovedPosts) ) --->
	<cfset getPost = application.blog.getPostByPostId(URL.optArgs,true,true)>
	
	<!--- Get a list of titles and aliases for validation purposes --->
	<cfset postAliasList = application.blog.getPostList('postAliasList')>
		
	<script>
		
		// Create a list to validate if the postAlias is already in use.
		var postAliasList = "<cfoutput>#postAliasList#</cfoutput>";
		
		// !!! Note on the validators, all forms need a name attribute, otherwise the positioning of the messages will not work. --->
		$(document).ready(function() {

			var postAliasValidator = $("#postAliasForm").kendoValidator({
				// Set up custom validation rules 
				rules: {
					// The postAlias must be unique. 
					postAliasIsUnique:
					function(input){
						// Do not continue if the user name is found in the currentUserName list 
						if (input.is("[id='postAliasInput']") && ( listFind( postAliasList, input.val() ) != 0 ) ){
							// Display an error on the page.
							input.attr("data-postAliasIsUnique-msg", "postAlias already exists");
							// Focus on the current element
							$( "#postAliasInput" ).focus();
							return false;
						}                                    
						return true;
					},
					// The alias must not contain a space. 
					postAliasNoSpace:
					function(input){
						// Do not continue if the user name is found in the currentUserName list 
						if (input.is("[id='postAliasInput']") && ( hasWhiteSpace(input.val()) ) ){
							// Display an error on the page.
							input.attr("data-postAliasNoSpace-msg", "Alias must not contain a space");
							// Focus on the current element
							$( "#postAliasInput" ).focus();
							return false;
						}                                    
						return true;
					},
					// The alias must not contain any special chars. 
					postAliasNoSpecialChars:
					function(input){
						// Do not continue if the user name is found in the currentUserName list 
						if (input.is("[id='postAliasInput']") && ( input.val().includes('&')||input.val().includes('?')||input.val().includes(',') ) ){
							// Display an error on the page.
							input.attr("data-postAliasNoSpecialChars-msg", "Alias must not contain a comma, question mark or an ampersand.");
							// Focus on the current element
							$( "#postAliasInput" ).focus();
							return false;
						}                                    
						return true;
					},
				}
			}).data("kendoValidator");

			// Invoked when the submit button is clicked. Insted of using '$("form").submit(function(event) {' and 'event.preventDefault();', We are using direct binding here to speed up the event.
			var postAliasSubmit = $('#postAliasSubmit');
			postAliasSubmit.on('click', function(e){  
				//alert($("#postAliasInput").val())
				
				e.preventDefault();         
				if (postAliasValidator.validate()) {
					
					// Open up a please wait dialog
					$.when(kendo.ui.ExtWaitDialog.show({ title: "Please wait...", message: "Please wait while we process the Post Alias.", width: "<cfoutput>#application.kendoExtendedUiWindowWidth#</cfoutput>", icon: "k-ext-information" }));

					// Send data to server after the new role was saved into the hidden form
					setTimeout(function() {
						postNewAlias();
					}, 250);
					
				} else {

					$.when(kendo.ui.ExtAlertDialog.show({ title: "There are errors", message: "Please correct the highlighted fields and try again", width: "<cfoutput>#application.kendoExtendedUiWindowWidth#</cfoutput>", icon: "k-ext-warning" }) // or k-ext-error, k-ext-question
						).done(function () {
						// Do nothing
					});
				}
			});

		});//...document.ready
		
		// Post method on the detail form called from the deptDetailFormValidator method on the detail page. The action variable will either be 'update' or 'insert'.
		function postNewAlias(){

			jQuery.ajax({
				type: 'post', 
				url: '<cfoutput>#application.baseUrl#</cfoutput>/common/cfc/ProxyController.cfc?method=savePostAlias',
				data: { // arguments
					csrfToken: '<cfoutput>#csrfToken#</cfoutput>',
					// Pass the form values
					postId: <cfoutput>#URL.optArgs#</cfoutput>,
					postAlias: $("#postAliasInput").val()
				},
				dataType: "json",
				success: postAliasUpdateResult, // calls the result function.
				error: function(ErrorMsg) {
					console.log('Error' + ErrorMsg);
				}
			// Extract any errors. This is a new jQuery promise based function as of jQuery 1.8.
			}).fail(function (jqXHR, textStatus, error) {
				// The full response is: jqXHR.responseText, but we just want to extract the error.
				$.when(kendo.ui.ExtAlertDialog.show({ title: "Error while consuming the savePostAlias function", message: error, icon: "k-ext-error", width: "<cfoutput>#application.kendoExtendedUiWindowWidth#</cfoutput>" }) // or k-ext-error, k-ext-information, k-ext-question, k-ext-warning.  You can also specify height.
					).done(function () {
					// Do nothing
				});		
			});
		};

		function postAliasUpdateResult(response){
			if (JSON.parse(response.success) == true){
				// Close the wait window that was launched in the calling function.
				kendo.ui.ExtWaitDialog.hide();
				// Close the window
				jQuery('#postAliasWindow').kendoWindow('destroy');
			} else {
				// Close the wait window that was launched in the calling function.
				kendo.ui.ExtWaitDialog.hide();
				// Alert the user that the login has failed.
				$.when(kendo.ui.ExtAlertDialog.show({ title: "Error saving post", message: response.errorMessage, icon: "k-ext-warning", width: "425px", height: "125px" }) // or k-ext-error, k-ext-question
				).done(function () {
					// Do nothing
				});
			}//..if (JSON.parse(response.success) == true){
		}
		
	</script>
		
	<form id="postAliasForm" action="#" method="post" data-role="validator">
	<!--- Pass the csrfToken --->
	<input type="hidden" name="csrfToken" id="csrfToken" value="<cfoutput>#csrfToken#</cfoutput>" />
	<table align="center" class="k-content tableBorder" width="100%" cellpadding="2" cellspacing="0" border="0">
	  <cfsilent>
			<!---The first content class in the table should be empty. --->
			<cfset thisContentClass = HtmlUtilsObj.getKendoClass('')>
			<!--- Set the colspan property for borders --->
			<cfset thisColSpan = "2">
	  </cfsilent>
	  <tr height="1px">
		  <td align="left" valign="top" colspan="2" class="<cfoutput>#thisContentClass#</cfoutput>"></td>
	  </tr>
	  <tr height="30px">
		<td align="left" class="<cfoutput>#thisContentClass#</cfoutput>" colspan="2"> 
			The alias field is used when creating SES (Search Engine Safe) URLs. If wish to change the alias, do not use any non-alphanumeric characters or spaces in the alias- spaces should be replaced with dashes.
		</td>
	  </tr>
	  <!-- Border -->
	  <tr height="2px">
	    <td align="left" valign="top" colspan="<cfoutput>#thisColSpan#</cfoutput>" class="<cfoutput>#thisContentClass#</cfoutput>"></td>
	  </tr>
	  <cfsilent>
	  <!--- Set the class for alternating rows. --->
	  <!---After the first row, the content class should be the current class. --->
	  <cfset thisContentClass = HtmlUtilsObj.getKendoClass(thisContentClass)>
	  </cfsilent>
	  <tr height="2px">
		  <td align="left" valign="top" colspan="2" class="border <cfoutput>#thisContentClass#</cfoutput>"></td>
	  </tr>
	  <!-- Form content -->
	<cfif session.isMobile>
	  <tr valign="middle">
		<td class="<cfoutput>#thisContentClass#</cfoutput>" colspan="2">
			<label for="postAliasInput">Post Alias</label>
		</td>
	   </tr>
	   <tr>
		<td class="<cfoutput>#thisContentClass#</cfoutput>" colspan="2">
			<input id="postAliasInput" name="postAliasInput" type="text" value="<cfoutput>#getPost[1]['PostAlias']#</cfoutput>" required validationMessage="postAlias is required" class="k-textbox" style="width: 95%" />   
		</td>
	  </tr>
	<cfelse><!---<cfif session.isMobile>--->
	  <tr valign="middle" height="30px">
		<td align="right" valign="middle" class="<cfoutput>#thisContentClass#</cfoutput>">
			<label for="postAliasInput">Post Alias</label>
		</td>
		<td align="left" class="<cfoutput>#thisContentClass#</cfoutput>">
			<input id="postAliasInput" name="postAliasInput" type="text" value="<cfoutput>#getPost[1]['PostAlias']#</cfoutput>" required validationMessage="postAlias is required" class="k-textbox" style="width: 66%" />  
		</td>
	  </tr>
	</cfif>
	  <!-- Border -->
	  <tr height="2px">
	    	<td align="left" valign="top" colspan="<cfoutput>#thisColSpan#</cfoutput>" class="<cfoutput>#thisContentClass#</cfoutput>"></td>
	  </tr>
	  <cfsilent>
	  <!--- Set the class for alternating rows. --->
	  <!---After the first row, the content class should be the current class. --->
	  <cfset thisContentClass = HtmlUtilsObj.getKendoClass(thisContentClass)>
	  </cfsilent>
	  <tr height="2px">
		  <td align="left" valign="top" colspan="2" class="border <cfoutput>#thisContentClass#</cfoutput>"></td>
	  </tr>
	  <!-- Form content -->
	  <tr valign="middle" height="30px">
		<td valign="bottom" align="right" class="<cfoutput>#thisContentClass#</cfoutput>">&nbsp;</td>
		<td valign="bottom" align="left" class="<cfoutput>#thisContentClass#</cfoutput>">
			<button id="postAliasSubmit" name="postAliasSubmit" class="k-button k-primary" type="button">Submit</button>
		</td>
	  </tr>
	</table>
	</form>
				
</cfcase>
		  
<!---//*******************************************************************************************************************
				Create New Post
//********************************************************************************************************************--->
<cfcase value=24>
	
	<!--- Get the current logged in users Id --->
	<cfset userId = application.blog.getUserIdByUserName(session.userName)>

	<style>
		label {
			font-weight: normal;
		}
		
		normalFontWeight {
			font-weight: normal;
		}
	</style>
		
		
	<cfsilent>
	
	<!---//***************************************************************************************************************
				Kendo Scripts
	//****************************************************************************************************************--->
	</cfsilent>
	<script>
		$(document).ready(function() {
			
			var todaysDate = new Date();
			
			// Kendo Dropdowns
			// Date posted date/time picker
			
			$("#newDatePosted").kendoDateTimePicker({
                componentType: "modern",
				value: new Date(),
				change: onDatePostedChange
            });
			
			function onDatePostedChange() {
                // alert("Change :: " + kendo.toString(this.value(), 'g'));
				// Check to see if the selected date is greater than today
				if (this.value() > todaysDate){
					$.when(kendo.ui.ExtYesNoDialog.show({ 
						title: "Release post in the future?",
						message: "You are posting at a later date in the future.",
						icon: "k-ext-warning",
						width: "<cfoutput>#application.kendoExtendedUiWindowWidth#</cfoutput>", 
						height: "215px"
					})
					).done(function (response) { // If the user clicked 'yes'
						if (response['button'] == 'Yes'){// remember that js is case sensitive.

						}//..if (response['button'] == 'Yes'){
					});
				} else {
					// alert(todaysDate);
				}
            }
			
			// ---------------------------- author dropdown. ----------------------------
			var authorDs = new kendo.data.DataSource({
				transport: {
					read: {
						cache: false,
						// Note: since this template is in a different directory, we can't specify the cfc template without the full path name.
						url: function() { // The cfc component which processes the query and returns a json string. 
							return "<cfoutput>#application.baseUrl#</cfoutput>/common/cfc/ProxyController.cfc?method=getAuthorsForDropdown&csrfToken=<cfoutput>#csrfToken#</cfoutput>"; 
						}, 
						dataType: "json",
						contentType: "application/json; charset=utf-8", // Note: when posting json via the request body to a coldfusion page, we must use this content type or we will get a 'IllegalArgumentException' on the ColdFusion processing page.
						type: "GET" //Note: for large payloads coming from the server, use the get method. The post method may fail as it is less efficient.
					}
				} //...transport:
			});//...var authorDs...
			
			// Create the top level dropdown
			var author = $("#author").kendoDropDownList({
				//cascadeFrom: "agencyRateCompanyCode",
				optionLabel: "Select...",
				// Template to add a new type when no data was found.
				noDataTemplate: $("#addUser").html(),
				autoBind: false,
				dataTextField: "FullName",
				dataValueField: "UserId",
				filter: "contains",
				dataSource: authorDs,
				// Use the close event to fire off events. The change event is fired off when setting the value of this dropdown list.
				close: onAuthorChange
			}).data("kendoDropDownList");

			// Set default value by the value (this is used when the container is populated via the datasource).
			var author = $("#author").data("kendoDropDownList");
			author.value(<cfoutput>#userId#</cfoutput>);
			author.trigger("change");

			// On change function to save the selected value.
			function onAuthorChange(e){
				// Get the value
				userId = this.value();
			}//...function onAuthorChange(e)
		
			// !!! Note on the validators, all forms need a name attribute, otherwise the positioning of the messages will not work. --->
			var newPostFormValidator = $("#newPost").kendoValidator({
				// Set up custom validation rules 
				rules: {
					// title
					titleRequired:
					function(input){
						if (input.is("[id='title']") && $.trim(input.val()).length < 3){
							// Display an error on the page.
							input.attr("data-titleRequired-msg", "The title must be at least 3 characters");
							// Focus on the current element
							$( "#title" ).focus();
							return false;
						}                                    
						return true;
					},
					titleMaxLen:
					function(input){
						if (input.is("[id='title']") && $.trim(input.val()).length > 125){
							// Display an error on the page.
							input.attr("data-titleMaxLen-msg", "The title can't have more than 125 characters");
							// Focus on the current element
							$( "#title" ).focus();
							return false;
						}                                    
						return true;
					},
					descriptionRequired:
					function(input){
						if (input.is("[id='description']") && $.trim(input.val()).length < 3){
							// Display an error on the page.
							input.attr("data-descriptionRequired-msg", "The description is required");
							// Focus on the current element
							$( "#description" ).focus();
							return false;
						}                                    
						return true;
					},
					descriptionLen:
					function(input){
						if (input.is("[id='description']") && $.trim(input.val()).length > 1250){
							// Display an error on the page.
							input.attr("data-descriptionLen-msg", "The description needs to be under 1250 characters");
							// Focus on the current element
							$( "#description" ).focus();
							return false;
						}                                    
						return true;
					}
				}
			}).data("kendoValidator");
		
			// Invoked when the submit button is clicked. Instead of using '$("form").submit(function(event) {' and 'event.preventDefault();', we are using direct binding here to speed up the event.
			var newPostSubmit = $('#newPostSubmit');
			newPostSubmit.on('click', function(e){  
                e.preventDefault();         
				if (newPostFormValidator.validate()) {
					// submit the form.
					// Note: when testing the ui validator, comment out the post line below. It will only validate and not actually do anything when you post.
					insertNewPost();
				} else {
					$.when(kendo.ui.ExtAlertDialog.show({ title: "There are errors", message: "Required fields have not been filled out. Please correct the highlighted fields and try again", width: "<cfoutput>#application.kendoExtendedUiWindowWidth#</cfoutput>", icon: "k-ext-warning" }) // or k-ext-error, k-ext-question
						).done(function () {
						// Do nothing
					});
				}
			});
		});//...document.ready
		
		// Post method on the detail form called from the commentDetailFormValidator method on the detail page. The action variable will either be 'update' or 'insert'.
		function insertNewPost(action){
	
			jQuery.ajax({
				type: 'post', 
				url: '<cfoutput>#application.baseUrl#</cfoutput>/common/cfc/ProxyController.cfc?method=insertNewPost',
				data: { // arguments
					csrfToken: '<cfoutput>#csrfToken#</cfoutput>',
					// We are going to map the extact same arguments, in order, of the method in the cfc here. Notes: we can also use 'data: $("#deptDetails").serialize()' or use the stringify method to pass it as an array of values. 
					action: action, // either update or insert.
					datePosted: kendo.toString($("#newDatePosted").data("kendoDateTimePicker").value(), 'MM/dd/yyyy'),
					timePosted: kendo.toString($("#newDatePosted").data("kendoDateTimePicker").value(), 'hh:mm tt'),
					author: $("#author").data("kendoDropDownList").value(),
					title: $("#title").val(),
					description: $('#description').val()
				},
				dataType: "json",
				success: newPostResult, // calls the result function.
				error: function(ErrorMsg) {
					console.log('Error' + ErrorMsg);
				}
			// Extract any errors. This is a new jQuery promise based function as of jQuery 1.8.
			}).fail(function (jqXHR, textStatus, error) {
				// This is a secured function. Display the login screen.
				if (jqXHR.status === 403) { 
					createLoginWindow(); 
				} else {//...if (jqXHR.status === 403) { 
					// The full response is: jqXHR.responseText, but we just want to extract the error.
					$.when(kendo.ui.ExtAlertDialog.show({ title: "Error while consuming the insertNewPost function", message: error, icon: "k-ext-error", width: "<cfoutput>#application.kendoExtendedUiWindowWidth#</cfoutput>" }) // or k-ext-error, k-ext-information, k-ext-question, k-ext-warning.  You can also specify height.
						).done(function () {
						// Do nothing
					});
				}//...if (jqXHR.status === 403) { 
			});//...jQuery.ajax({
		};
		
		function newPostResult(response){
		
			// Are the credentials correct?
			if (JSON.parse(response.success) == true){
				// Refresh the <cfif application.kendoCommercial>kendo<cfelse>jsgrid</cfif> grid 
			<cfif application.kendoCommercial and 1 eq 2><!---We are not using the Kendo grids right now.--->
				$('#postsGrid').data('kendoGrid').dataSource.read();
			<cfelse>
				// Try to refresh the post grid by refreshing the window. It may not be open so we are using a try block
				try {
					$("#PostsWindow").data("kendoWindow").refresh();
				} catch (error) {
					// Do nothing
				}		
			</cfif>
				// Open the post detail window	
				createAdminInterfaceWindow(6, response.postId);
				// Close this window
				jQuery('#newPostWindow').kendoWindow('destroy');
			} else {
				// Alert the user that the login has failed.
				$.when(kendo.ui.ExtAlertDialog.show({ title: "Error saving post", message: response.errorMessage, icon: "k-ext-warning", width: "<cfoutput>#application.kendoExtendedUiWindowWidth#</cfoutput>", height: "125px" }) // or k-ext-error, k-ext-question
				).done(function () {
					// Do nothing
				});
			}//..if (JSON.parse(response.success) == true){
		}
			
	</script>
		
	<form id="newPost" data-role="validator">
	  <!--- Pass the csrfToken --->
	  <input type="hidden" name="csrfToken" id="csrfToken" value="<cfoutput>#csrfToken#</cfoutput>" />
		
		<table align="center" class="k-content tableBorder" width="100%" cellpadding="2" cellspacing="0">
		  <cfsilent>
			<!---The first content class in the table should be empty. --->
			<cfset thisContentClass = HtmlUtilsObj.getKendoClass('')>
			<!--- Set the colspan property for borders --->
			<cfset thisColSpan = "2">
	  	  </cfsilent>
		  <tr height="1px">
			  <td align="left" valign="top" colspan="2" class="<cfoutput>#thisContentClass#</cfoutput>"></td>
		  </tr>
		<cfif session.isMobile>
		  <tr valign="middle">
			<td class="<cfoutput>#thisContentClass#</cfoutput>" colspan="2">
			<label for="post">Date Posted</label>
			</td>
		   </tr>
		   <tr>
			<td class="<cfoutput>#thisContentClass#</cfoutput>" colspan="2">
			<input id="newDatePosted" name="newDatePosted" value="<cfoutput>#dateTimeFormat(now(), "medium")#</cfoutput>" style="width: <cfif session.isMobile>95<cfelse>45</cfif>%" />     
			</td>
		  </tr>
		<cfelse><!---<cfif session.isMobile>--->
		  <tr>
			<td align="right" class="<cfoutput>#thisContentClass#</cfoutput>"> 
			<label for="post">Date Posted</label>
			</td>
			<td class="<cfoutput>#thisContentClass#</cfoutput>">
			<input id="newDatePosted" name="newDatePosted" value="<cfoutput>#dateTimeFormat(now(), "medium")#</cfoutput>" style="width: <cfif session.isMobile>95<cfelse>45</cfif>%" />    
			</td>
		  </tr>
		</cfif>
		  <!-- Border -->
		  <tr height="2px">
			  <td align="left" valign="top" colspan="<cfoutput>#thisColSpan#</cfoutput>" class="<cfoutput>#thisContentClass#</cfoutput>"></td>
		  </tr>
		  <cfsilent>
		  <!--- Set the class for alternating rows. --->
		  <!---After the first row, the content class should be the current class. --->
		  <cfset thisContentClass = HtmlUtilsObj.getKendoClass(thisContentClass)>
		  </cfsilent>
		  <tr height="2px">
			  <td align="left" valign="top" colspan="2" class="border <cfoutput>#thisContentClass#</cfoutput>"></td>
		  </tr>
	  	  <!-- Form content -->
		<cfif session.isMobile>
		  <tr valign="middle">
			<td class="<cfoutput>#thisContentClass#</cfoutput>" colspan="2">
			<label for="post">Author</label>
			</td>
		   </tr>
		   <tr>
			<td class="<cfoutput>#thisContentClass#</cfoutput>" colspan="2">
			<select id="author" style="width: <cfif session.isMobile>95<cfelse>50</cfif>%"></select>
			<!--- Inline template to add a new user. --->
			<script id="addUser" type="text/x-kendo-tmpl">
				<div>
					Author not found. Do you want to add '#: instance.filterInput.val() #'?
				</div>
				<br />
				<button class="k-button" onclick="createAdminInterfaceWindow(7, '#: instance.filterInput.val() #', 'addUser')">Add Author</button>
			</script>   
			</td>
		  </tr>
		<cfelse><!---<cfif session.isMobile>--->
		  <tr valign="middle" height="35">
			<td align="right" valign="middle" width="10%" class="<cfoutput>#thisContentClass#</cfoutput>">
			<label for="post">Author</label>
			</td>
			<td align="left" width="90%" class="<cfoutput>#thisContentClass#</cfoutput>">
				<select id="author" style="width: <cfif session.isMobile>95<cfelse>50</cfif>%"></select>
				<!--- Inline template to add a new user. --->
				<script id="addUser" type="text/x-kendo-tmpl">
					<div>
						Author not found. Do you want to add '#: instance.filterInput.val() #'?
					</div>
					<br />
					<button class="k-button" onclick="createAdminInterfaceWindow(7, '#: instance.filterInput.val() #', 'addUser')">Add Author</button>
				</script>  
			</td>
		  </tr>
		</cfif>
		  <!-- Border -->
		  <tr height="2px">
			  <td align="left" valign="top" colspan="<cfoutput>#thisColSpan#</cfoutput>" class="<cfoutput>#thisContentClass#</cfoutput>"></td>
		  </tr>
		  <cfsilent>
		  <!--- Set the class for alternating rows. --->
		  <!---After the first row, the content class should be the current class. --->
		  <cfset thisContentClass = HtmlUtilsObj.getKendoClass(thisContentClass)>
		  </cfsilent>
		  <tr height="2px">
			  <td align="left" valign="top" colspan="2" class="border <cfoutput>#thisContentClass#</cfoutput>"></td>
		  </tr>
		  <!-- Form content -->
		<cfif session.isMobile>
		  <tr valign="middle">
			<td class="<cfoutput>#thisContentClass#</cfoutput>" colspan="2">
			<label for="post">Title</label>
			</td>
		   </tr>
		   <tr>
			<td class="<cfoutput>#thisContentClass#</cfoutput>" colspan="2">
				<input type="text" id="title" name="title" value="" class="k-textbox" style="width: <cfif session.isMobile>95<cfelse>66</cfif>%" />   
			</td>
		  </tr>
		<cfelse><!---<cfif session.isMobile>--->
		  <tr valign="middle" height="35">
			<td align="right" valign="middle" width="10%" class="<cfoutput>#thisContentClass#</cfoutput>">
			<label for="post">Title</label>
			</td>
			<td align="left" width="90%" class="<cfoutput>#thisContentClass#</cfoutput>">
				<input type="text" id="title" name="title" value="" class="k-textbox" style="width: <cfif session.isMobile>95<cfelse>66</cfif>%" />   
			</td>
		  </tr>
		</cfif><!---<cfif session.isMobile>--->
	 	  <!-- Border -->
		  <tr height="2px">
			  <td align="left" valign="top" colspan="<cfoutput>#thisColSpan#</cfoutput>" class="<cfoutput>#thisContentClass#</cfoutput>"></td>
		  </tr>
		  <cfsilent>
		  <!--- Set the class for alternating rows. --->
		  <!---After the first row, the content class should be the current class. --->
		  <cfset thisContentClass = HtmlUtilsObj.getKendoClass(thisContentClass)>
		  </cfsilent>
		  <tr height="2px">
			  <td align="left" valign="top" colspan="2" class="border <cfoutput>#thisContentClass#</cfoutput>"></td>
		  </tr>
	  	  <!-- Form content -->
		<cfif session.isMobile>
		  <tr valign="middle">
			<td class="<cfoutput>#thisContentClass#</cfoutput>" colspan="2">
			<label for="post">Description</label>
			</td>
		  </tr>
		  <tr>
			<td class="<cfoutput>#thisContentClass#</cfoutput>" colspan="2">
				<textarea id="description" name="description" maxlength="1250" class="k-textbox" style="width: <cfif session.isMobile>95<cfelse>66</cfif>%"></textarea> 
			</td>
		  </tr>
		<cfelse><!---<cfif session.isMobile>--->
		  <tr valign="middle" height="35">
			<td align="right" valign="middle" width="10%" class="<cfoutput>#thisContentClass#</cfoutput>">
			<label for="post">Description</label>
			</td>
			<td align="left" width="90%" class="<cfoutput>#thisContentClass#</cfoutput>">
				<textarea id="description" name="description" maxlength="1250" class="k-textbox" style="width: <cfif session.isMobile>95<cfelse>66</cfif>%"></textarea> 
			</td>
		  </tr>
		</cfif><!---<cfif session.isMobile>--->
		  <!-- Border -->
		  <tr height="2px">
			  <td align="left" valign="top" colspan="<cfoutput>#thisColSpan#</cfoutput>" class="<cfoutput>#thisContentClass#</cfoutput>"></td>
		  </tr>
		  <cfsilent>
		  <!--- Set the class for alternating rows. --->
		  <!---After the first row, the content class should be the current class. --->
		  <cfset thisContentClass = HtmlUtilsObj.getKendoClass(thisContentClass)>
		  </cfsilent>
	  	  <!-- Form content -->
		  <tr valign="middle">
			<td height="25" valign="bottom" align="right" class="<cfoutput>#thisContentClass#</cfoutput>">&nbsp;</td>
			<td height="25" valign="bottom" align="left" class="<cfoutput>#thisContentClass#</cfoutput>">
				<button id="newPostSubmit" name="newPostSubmit" class="k-button k-primary" type="button">Submit</button>
			</td>
		  </tr>
		</table>
	</form>
					
</body>
	  
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
			
	<!--- Get a list of emails for validation purposes --->
	<cfset subscriberEmailList = application.blog.getSubscriberEmailList()>
		
	<script>
		
		// Create a list to validate if the subscriber is already in use.
		var subscriberEmailList = "<cfoutput>#subscriberEmailList#</cfoutput>";
		
		// !!! Note on the validators, all forms need a name attribute, otherwise the positioning of the messages will not work. --->
		$(document).ready(function() {

			var addSubscriberValidator = $("#subscriberForm").kendoValidator({
				// Set up custom validation rules 
				rules: {
					// The subscriber must be unique. 
					subscriberIsUnique:
					function(input){
						// Do not continue if the user name is found in the currentUserName list 
						if (input.is("[id='subscriberEmail']") && ( listFind( subscriberEmailList, input.val() ) != 0 ) ){
							// Display an error on the page.
							input.attr("data-subscriberIsUnique-msg", "Subscriber already exists");
							// Focus on the current element
							$( "#subscriber" ).focus();
							return false;
						}                                    
						return true;
					},
				}
			}).data("kendoValidator");

			// Invoked when the submit button is clicked. Insted of using '$("form").submit(function(event) {' and 'event.preventDefault();', We are using direct binding here to speed up the event.
			var addSubscriberSubmit = $('#addSubscriberSubmit');
			addSubscriberSubmit.on('click', function(e){  
				
				e.preventDefault();         
				if (addSubscriberValidator.validate()) {
					
					// Open up a please wait dialog
					$.when(kendo.ui.ExtWaitDialog.show({ title: "Please wait...", message: "Please wait while we process the subscriber.", width: "<cfoutput>#application.kendoExtendedUiWindowWidth#</cfoutput>", icon: "k-ext-information" }));
					
					// Get the value of the subscriber that was typed in
					newSubscriber = $("#addSubscriber").val();

					// Send data to server after the new role was saved into the hidden form
					setTimeout(function() {
						postNewSubscriber();
					}, 250);
					
				} else {

					$.when(kendo.ui.ExtAlertDialog.show({ title: "There are errors", message: "Please correct the highlighted fields and try again", width: "<cfoutput>#application.kendoExtendedUiWindowWidth#</cfoutput>", icon: "k-ext-warning" }) // or k-ext-error, k-ext-question
						).done(function () {
						// Do nothing
					});
				}
			});

		});//...document.ready
		
		// Post method on the detail form called from the deptDetailFormValidator method on the detail page. The action variable will either be 'update' or 'insert'.
		function postNewSubscriber(){

			jQuery.ajax({
				type: 'post', 
				url: '<cfoutput>#application.baseUrl#</cfoutput>/common/cfc/ProxyController.cfc?method=subscribe',
				data: { // arguments
					// Pass the form values
					csrfToken: $("#csrfToken").val(),
					email: $("#subscriberEmail").val()
				},
				dataType: "json",
				success: subscribeUpdateResult, // calls the result function.
				error: function(ErrorMsg) {
					console.log('Error' + ErrorMsg);
				}
			// Extract any errors. This is a new jQuery promise based function as of jQuery 1.8.
			}).fail(function (jqXHR, textStatus, error) {
				// The full response is: jqXHR.responseText, but we just want to extract the error.
				$.when(kendo.ui.ExtAlertDialog.show({ title: "Error while consuming the subscribe function", message: error, icon: "k-ext-error", width: "425px" }) // or k-ext-error, k-ext-information, k-ext-question, k-ext-warning.  You can also specify height.
					).done(function () {
					// Do nothing
				});		
			});
		};

		function subscribeUpdateResult(response){
			// Close the wait window that was launched in the calling function.
			kendo.ui.ExtWaitDialog.hide();
			// Refresh the subscriber grid window
			$("#subscriberGridWindow").data("kendoWindow").refresh();
			// Close this window.
			$('#addSubscriberWindow').kendoWindow('destroy');
		}
		
	</script>
		
	<form id="subscriberForm" action="#" method="post" data-role="validator">
	<!--- Pass the csrfToken --->
	<input type="hidden" name="csrfToken" id="csrfToken" value="<cfoutput>#csrfToken#</cfoutput>" />
	<table align="center" class="k-content tableBorder" width="100%" cellpadding="2" cellspacing="0" border="0">
	  <cfsilent>
			<!---The first content class in the table should be empty. --->
			<cfset thisContentClass = HtmlUtilsObj.getKendoClass('')>
			<!--- Set the colspan property for borders --->
			<cfset thisColSpan = "2">
	  </cfsilent>
	  <tr height="1px">
		  <td align="left" valign="top" colspan="2" class="<cfoutput>#thisContentClass#</cfoutput>"></td>
	  </tr>
	  <tr height="30px">
		<td align="left" class="<cfoutput>#thisContentClass#</cfoutput>" colspan="2"> 
			Create new Subscriber. Note: an email will be sent to the subsriber asking them to confirm the subscription. Please make sure that they are aware of this subscription.
		</td>
	  </tr>
	  <!-- Border -->
	  <tr height="2px">
	    <td align="left" valign="top" colspan="<cfoutput>#thisColSpan#</cfoutput>" class="<cfoutput>#thisContentClass#</cfoutput>"></td>
	  </tr>
	  <cfsilent>
	  <!--- Set the class for alternating rows. --->
	  <!---After the first row, the content class should be the current class. --->
	  <cfset thisContentClass = HtmlUtilsObj.getKendoClass(thisContentClass)>
	  </cfsilent>
	  <tr height="2px">
		  <td align="left" valign="top" colspan="2" class="border <cfoutput>#thisContentClass#</cfoutput>"></td>
	  </tr>
	  <!-- Form content -->
	<cfif session.isMobile>
	  <tr valign="middle">
		<td class="<cfoutput>#thisContentClass#</cfoutput>" colspan="2">
			<label for="subscriberEmail">Subscriber Email</label>
		</td>
	   </tr>
	   <tr>
		<td class="<cfoutput>#thisContentClass#</cfoutput>" colspan="2">
			<input id="subscriberEmail" name="subscriberEmail" type="email" value="" required validationMessage="Email is required" class="k-textbox" style="width: 95%" />   
		</td>
	  </tr>
	<cfelse><!---<cfif session.isMobile>--->
	  <tr valign="middle" height="30px">
		<td align="right" valign="middle" class="<cfoutput>#thisContentClass#</cfoutput>">
			<label for="subscriberEmail">Subscriber Email</label>
		</td>
		<td align="left" class="<cfoutput>#thisContentClass#</cfoutput>">
			<input id="subscriberEmail" name="subscriberEmail" type="email" value="" required validationMessage="Email is required" class="k-textbox" style="width: 66%" />  
		</td>
	  </tr>
	</cfif>
	  <!-- Border -->
	  <tr height="2px">
	    	<td align="left" valign="top" colspan="<cfoutput>#thisColSpan#</cfoutput>" class="<cfoutput>#thisContentClass#</cfoutput>"></td>
	  </tr>
	  <cfsilent>
	  <!--- Set the class for alternating rows. --->
	  <!--- After the first row, the content class should be the current class. --->
	  <cfset thisContentClass = HtmlUtilsObj.getKendoClass(thisContentClass)>
	  </cfsilent>
	  <tr height="2px">
		  <td align="left" valign="top" colspan="2" class="border <cfoutput>#thisContentClass#</cfoutput>"></td>
	  </tr>
	  <!-- Form content -->
	  <tr valign="middle" height="30px">
		<td valign="bottom" align="right" class="<cfoutput>#thisContentClass#</cfoutput>">&nbsp;</td>
		<td valign="bottom" align="left" class="<cfoutput>#thisContentClass#</cfoutput>">
			<button id="addSubscriberSubmit" name="addSubscriberSubmit" class="k-button k-primary" type="button">Submit</button>
		</td>
	  </tr>
	</table>
	</form>
				
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
			
	<!--- Get the theme --->
	<cfset getTheme = application.blog.getTheme(themeId=#URL.optArgs#)>
	<!---<cfdump var="#getTheme#">--->
		
	<cfset themeId = getTheme[1]["ThemeId"]>
	<cfset theme = getTheme[1]["Theme"]>
	<cfset kendoThemeId = getTheme[1]["KendoThemeId"]>
	<cfset kendoTheme = getTheme[1]["KendoTheme"]>
	<!--- The library file locations --->
	<cfset kendoCommonCssFileLocation = getTheme[1]["KendoCommonCssFileLocation"]>
	<cfset kendoThemeCssFileLocation = getTheme[1]["KendoThemeCssFileLocation"]>
	<cfset kendoThemeMobileCssFileLocation = getTheme[1]["KendoThemeMobileCssFileLocation"]>
	<cfset themeGenre = getTheme[1]["ThemeGenre"]>
	<cfset breakpoint = getTheme[1]["Breakpoint"]>
	<!--- User selected themes --->
	<cfset useTheme = getTheme[1]["UseTheme"]>
	<cfset selectedTheme = getTheme[1]["SelectedTheme"]>
	<cfset darkTheme = getTheme[1]["DarkTheme"]>
	<!--- Theme settings --->
	<cfset themeSettingId = getTheme[1]["ThemeSettingId"]>
	<!--- Body Font --->
	<cfset fontId = getTheme[1]["FontId"]>
	<cfset font = getTheme[1]["Font"]>
	<cfset fontSize = getTheme[1]["FontSize"]>
	<cfset fontSizeMobile = getTheme[1]["FontSizeMobile"]>
	<!--- Containers and opacity --->
	<cfset contentWidth = getTheme[1]["ContentWidth"]>
	<cfset mainContainerWidth = getTheme[1]["MainContainerWidth"]>
	<cfset sideBarContainerWidth = getTheme[1]["SideBarContainerWidth"]>
	<cfset siteOpacity = getTheme[1]["SiteOpacity"]>
	<!--- FavIcon --->
	<cfset favIconHtml = getTheme[1]["FavIconHtml"]>
	<!--- Blog backgrounds --->
	<cfset includeBackgroundImages = getTheme[1]["IncludeBackgroundImages"]>
	<cfset blogBackgroundImage = getTheme[1]["BlogBackgroundImage"]>
	<!--- Images need to have the baseUrl (this was put in to make the blog more portable) --->
	<cfif len(blogBackgroundImage)>
		<cfset blogBackgroundImage = application.baseUrl & blogBackgroundImage>
	</cfif>
	<cfset blogBackgroundImageMobile = getTheme[1]["BlogBackgroundImageMobile"]>
	<!--- Images need to have the baseUrl (this was put in to make the blog more portable) --->
	<cfif len(blogBackgroundImageMobile)>
		<cfset blogBackgroundImageMobile = application.baseUrl & blogBackgroundImageMobile>
	</cfif>
	<cfset blogBackgroundImageRepeat = getTheme[1]["BlogBackgroundImageRepeat"]>
	<cfset blogBackgroundImagePosition = getTheme[1]["BlogBackgroundImagePosition"]>
	<cfset blogBackgroundColor = getTheme[1]["BlogBackgroundColor"]>
	<!--- Header backgrounds --->
	<cfset headerBackgroundColor = getTheme[1]["HeaderBackgroundColor"]>
	<cfset headerBackgroundImage = getTheme[1]["HeaderBackgroundImage"]>
	<!--- Images need to have the baseUrl (this was put in to make the blog more portable) --->
	<cfif len(headerBackgroundImage)>
		<cfset headerBackgroundImage = application.baseUrl & headerBackgroundImage>
	</cfif>
	<!--- Menu backgrounds --->
	<cfset menuBackgroundImage = getTheme[1]["MenuBackgroundImage"]>
	<!--- Images need to have the baseUrl (this was put in to make the blog more portable) --->
	<cfif len(menuBackgroundImage)>
		<cfset menuBackgroundImage = application.baseUrl & menuBackgroundImage>
	</cfif>
	<!--- Menu Font --->
	<cfset menuFontId = getTheme[1]["MenuFontId"]>
	<cfset coverKendoMenuWithMenuBackgroundImage = getTheme[1]["CoverKendoMenuWithMenuBackgroundImage"]>
	<!--- Top menu alignment --->
	<cfset stretchHeaderAcrossPage = getTheme[1]["StretchHeaderAcrossPage"]>
	<cfset alignBlogMenuWithBlogContent = getTheme[1]["AlignBlogMenuWithBlogContent"]>
	<cfset topMenuAlign = getTheme[1]["TopMenuAlign"]>
	<!--- Title font and text color --->
	<cfset blogNameFontId = getTheme[1]["BlogNameFontId"]>
	<cfset blogNameFont = getTheme[1]["BlogNameFont"]>
	<cfset blogNameFontSize = getTheme[1]["BlogNameFontSize"]>
	<cfset blogNameFontSizeMobile = getTheme[1]["BlogNameFontSizeMobile"]>
	<cfset blogNameTextColor = getTheme[1]["BlogNameTextColor"]>
	<!--- Dividers --->
	<cfset headerBodyDividerImage = getTheme[1]["HeaderBodyDividerImage"]>
	<!--- Logos --->
	<cfset logoImageMobile = getTheme[1]["LogoImageMobile"]>
	<!--- Images need to have the baseUrl (this was put in to make the blog more portable) --->
	<cfif len(logoImageMobile)>
		<cfset logoImageMobile = application.baseUrl & logoImageMobile>
	</cfif>
	<cfset logoMobileWidth = getTheme[1]["LogoMobileWidth"]>
	<!--- Images need to have the baseUrl (this was put in to make the blog more portable) --->
	<cfset logoImage = getTheme[1]["LogoImage"]>
	<cfif len(logoImage)>
		<cfset logoImage = application.baseUrl & logoImage>
	</cfif>
	<cfset logoPaddingTop = getTheme[1]["LogoPaddingTop"]>
	<cfset logoPaddingRight = getTheme[1]["LogoPaddingRight"]>
	<cfset logoPaddingLeft = getTheme[1]["LogoPaddingLeft"]>
	<cfset logoPaddingBottom = getTheme[1]["LogoPaddingBottom"]>
	<cfset defaultLogoImageForSocialMediaShare = getTheme[1]["DefaultLogoImageForSocialMediaShare"]>
	<!--- Images need to have the baseUrl (this was put in to make the blog more portable) --->
	<cfif len(defaultLogoImageForSocialMediaShare)>
		<cfset defaultLogoImageForSocialMediaShare = application.baseUrl & defaultLogoImageForSocialMediaShare>
	</cfif>
	<cfset blogBackgroundImagePosition = getTheme[1]["BlogBackgroundImagePosition"]>
	<cfset footerImage = getTheme[1]["FooterImage"]>
	<!--- Images need to have the baseUrl (this was put in to make the blog more portable) --->
	<cfif len(footerImage)>
		<cfset footerImage = application.baseUrl & footerImage>
	</cfif>
		
	<cfset getFonts = application.blog.getFont()>
	<!---<cfdump var="#getFonts#">--->
		
	<style>
		.collapsible {
			cursor: pointer;
			padding: 10px;
			width: 98%;
			border: thin;
			border-style: solid;
			text-align: left;
			outline: none;
			font-size: 15px;
			transition: max-height 0.2s ease-out;
		}

		.collapsible:after {
			content: '\25BC';
			color: white;
			font-weight: bold;
			float: right;
			margin-left: 5px;
			margin-left: 5px;
		}

		.active:after {
		  content: "\25B2";
		}

		.content {
		  padding: 0 18px;
		  display: none;
		  overflow: hidden;
		}
	</style>
		
	<!--- Load the fonts for the dropdowns --->
	<style>
	<cfloop from="1" to="#arrayLen(getFonts)#" index="i">
		/* fonts */
		@font-face {
			font-family: "<cfoutput>#getFonts[i]['FileName']#</cfoutput>";
			src: url("<cfoutput>#application.baseUrl#/common/fonts/#getFonts[i]['FileName']#</cfoutput>.woff<cfif application.serverSupportsWoff2>2</cfif>");
		}
	</cfloop>
	</style>
		
	<!--- Get a list of themes for validation purposes --->
	<cfset themeList = application.blog.getThemeList()>
	<!---<cfdump var="#themeList#">--->
		
	<script>
		
		// Create a list to validate if the theme is already in use.
		var themeList = "<cfoutput>#themeList#</cfoutput>";
		
		// !!! Note on the validators, all forms need a name attribute, otherwise the positioning of the messages will not work. --->
		$(document).ready(function() {

			var themeValidator = $("#themeForm").kendoValidator({
				// Set up custom validation rules 
				rules: {
					<!--- Only validate this when inserting a new theme. --->
					<cfif not len(themeId)>
					// The theme must be unique. 
					themeIsUnique:
					function(input){
						// Do not continue if the theme name is found in the currentTheme list 
						if (input.is("[id='themeName']") && ( listFind( themeList, input.val() ) != 0 ) ){
							// Display an error on the page.
							input.attr("data-themeIsUnique-msg", "Theme name already exists");
							// Focus on the current element
							$( "#theme" ).focus();
							return false;
						}                                    
						return true;
					},
					</cfif>
				}
			}).data("kendoValidator");

			// Invoked when the submit button is clicked. Insted of using '$("form").submit(function(event) {' and 'event.preventDefault();', We are using direct binding here to speed up the event.
			var themeSubmit = $('#themeSubmit');
			themeSubmit.on('click', function(e){ 
				
				e.preventDefault();         
				if (themeValidator.validate()) {
					
					// Open up a please wait dialog
					$.when(kendo.ui.ExtWaitDialog.show({ title: "Please wait...", message: "Please wait while we save the theme.", width: "<cfoutput>#application.kendoExtendedUiWindowWidth#</cfoutput>", icon: "k-ext-information" }));

					// Send data to server
					setTimeout(function() {
						postTheme();
					}, 250);
					
				} else {

					$.when(kendo.ui.ExtAlertDialog.show({ title: "There are errors", message: "Please correct the highlighted fields and try again", width: "<cfoutput>#application.kendoExtendedUiWindowWidth#</cfoutput>", icon: "k-ext-warning" }) // or k-ext-error, k-ext-question
						).done(function () {
						// Do nothing
					});
				}
			});

		});//...document.ready
		
		// Post method on the detail form called from the deptDetailFormValidator method on the detail page. The action variable will either be 'update' or 'insert'.
		function postTheme(){

			jQuery.ajax({
				type: 'post', 
				url: '<cfoutput>#application.baseUrl#</cfoutput>/common/cfc/ProxyController.cfc?method=saveTheme',
				// Serialize the form. The csrfToken is also in the form.
				data: $('#themeForm').serialize(),
				dataType: "json",
				success: postThemeResult, // calls the result function.
				error: function(ErrorMsg) {
					console.log('Error' + ErrorMsg);
				}
			// Extract any errors. This is a new jQuery promise based function as of jQuery 1.8.
			}).fail(function (jqXHR, textStatus, error) {
				// Close the wait window that was launched in the calling function.
				kendo.ui.ExtWaitDialog.hide();
				// Display the error. The full response is: jqXHR.responseText, but we just want to extract the error.
				$.when(kendo.ui.ExtAlertDialog.show({ title: "Error while consuming the save theme function", message: error, icon: "k-ext-error", width: "425px" }) // or k-ext-error, k-ext-information, k-ext-question, k-ext-warning.  You can also specify height.
					).done(function () {
					
				});		
			});
		};

		function postThemeResult(response){
			// Close the wait window that was launched in the calling function.
			kendo.ui.ExtWaitDialog.hide();
			// Refresh the subscriber grid window
			$("#themeGridWindow").data("kendoWindow").refresh();
			// Close this window.
			$('#themeSettingsWindow').kendoWindow('destroy');
		}
	</script>
		
	<script>
		var coll = document.getElementsByClassName("collapsible");
		var i;

		for (i = 0; i < coll.length; i++) {
		  coll[i].addEventListener("click", function() {
			this.classList.toggle("active");
			var content = this.nextElementSibling;
			if (content.style.display === "block") {
			  content.style.display = "none";
			} else {
			  content.style.display = "block";
			}
		  });
		}
	</script>	
		
	<script>
		// ---------------------------- kendo theme dropdown. ----------------------------
		var kendoThemeDs = new kendo.data.DataSource({
			transport: {
				read: {
					cache: false,
					// Note: since this template is in a different directory, we can't specify the cfc template without the full path name.
					url: function() { // The cfc component which processes the query and returns a json string. 
						return "<cfoutput>#application.baseUrl#</cfoutput>/common/cfc/ProxyController.cfc?method=getKendoThemesForDropdown&csrfToken=<cfoutput>#csrfToken#</cfoutput>"; 
					}, 
					dataType: "json",
					contentType: "application/json; charset=utf-8", // Note: when posting json via the request body to a coldfusion page, we must use this content type or we will get a 'IllegalArgumentException' on the ColdFusion processing page.
					type: "GET" //Note: for large payloads coming from the server, use the get method. The post method may fail as it is less efficient.
				}
			} //...transport:
		});//...var rolesDs...

		// Create the top level dropdown
		var kendoThemeId = $("#kendoThemeId").kendoDropDownList({
			optionLabel: "Select...",
			autoBind: false,
			dataTextField: "KendoTheme",
			dataValueField: "KendoThemeId",
			filter: "contains",
			dataSource: kendoThemeDs,
		}).data("kendoDropDownList");

	<cfif isDefined("kendoThemeId")>
		// Set default value by the value (this is used when the container is populated via the datasource).
		var kendoThemeId = $("#kendoThemeId").data("kendoDropDownList");
		kendoThemeId.value( <cfoutput>#kendoThemeId#</cfoutput> );
	</cfif>
								 
		// ---------------------------- font dropdowns. ----------------------------
		var fontDs = new kendo.data.DataSource({
			transport: {
				read: {
					cache: false,
					// Note: since this template is in a different directory, we can't specify the cfc template without the full path name.
					url: function() { // The cfc component which processes the query and returns a json string. 
						return "<cfoutput>#application.baseUrl#</cfoutput>/common/cfc/ProxyController.cfc?method=getFontsForDropdown&csrfToken=<cfoutput>#csrfToken#</cfoutput>"; 
					}, 
					dataType: "json",
					contentType: "application/json; charset=utf-8", // Note: when posting json via the request body to a coldfusion page, we must use this content type or we will get a 'IllegalArgumentException' on the ColdFusion processing page.
					type: "GET" //Note: for large payloads coming from the server, use the get method. The post method may fail as it is less efficient.
				}
			} //...transport:
		});//...var rolesDs...
		
		// Create the body font
		var bodyFontDropdown = $("#bodyFontDropdown").kendoDropDownList({

			autoBind: false,
			dataTextField: "Font",
			dataValueField: "FontId",
			// Templates to display the fonts 
    		template: '<label style="font-family:#:data.FontFace#">#:data.Font#</label>',
			//valueTemplate: '<label style="font-family: #:data.FontFace#">#:data.FontId#</label>',
			// Template to add a new type when no data was found.
			noDataTemplate: $("#addFont").html(),
			filter: "contains",
			dataSource: fontDs,
		}).data("kendoDropDownList");

	<cfif isDefined("fontId")>
		// Set default value by the value (this is used when the container is populated via the datasource).
		var bodyFontDropdown = $("#bodyFontDropdown").data("kendoDropDownList");
		bodyFontDropdown.value( <cfoutput>#fontId#</cfoutput> );
	</cfif>

		// Create the blog namedropdown
		var blogNameFontDropdown = $("#blogNameFontDropdown").kendoDropDownList({
			optionLabel: "Select...",
			autoBind: false,
			dataTextField: "Font",
			dataValueField: "FontId",
			template: '<label style="font-family:#:data.FontFace#">#:data.Font#</label>',
			// Template to add a new type when no data was found.
			noDataTemplate: $("#addFont").html(),
			filter: "contains",
			dataSource: fontDs,
		}).data("kendoDropDownList");

	<cfif isDefined("BlogNameFont")>
		// Set default value by the value (this is used when the container is populated via the datasource).
		var blogNameFontDropdown = $("#blogNameFontDropdown").data("kendoDropDownList");
		blogNameFontDropdown.value( <cfoutput>#blogNameFontId#</cfoutput> );
	</cfif>
								   
		// Create the menu font
		var menuFontDropdown = $("#menuFontDropdown").kendoDropDownList({
			optionLabel: "Select...",
			autoBind: false,
			dataTextField: "Font",
			dataValueField: "FontId",
			template: '<label style="font-family:#:data.FontFace#">#:data.Font#</label>',
			// Template to add a new type when no data was found.
			noDataTemplate: $("#addFont").html(),
			filter: "contains",
			dataSource: fontDs,
		}).data("kendoDropDownList");

	<cfif isDefined("menuFontId")>
		// Set default value by the value (this is used when the container is populated via the datasource).
		var menuFontDropdown = $("#menuFontDropdown").data("kendoDropDownList");
		menuFontDropdown.value( <cfoutput>#menuFontId#</cfoutput> );
	</cfif>
							   
		$("#blogNameTextColor").kendoColorPicker({
			value: "<cfoutput>#blogNameTextColor#</cfoutput>",
			buttons: true
		});
		
		$("#blogBackgroundColor").kendoColorPicker({
			value: "<cfoutput>#blogBackgroundColor#</cfoutput>",
			buttons: true
		});
		
		$("#headerBackgroundColor").kendoColorPicker({
			value: "<cfoutput>#headerBackgroundColor#</cfoutput>",
			buttons: true
		});
		
		// Numeric inputs
		$("#contentWidth").kendoNumericTextBox({
    		decimals: 0,
			round: true
		});
		
		$("#mainContainerWidth").kendoNumericTextBox({
    		decimals: 0,
			round: true
		});
		
		$("#sideBarContainerWidth").kendoNumericTextBox({
    		decimals: 0,
			round: true
		});
		
		$("#siteOpacity").kendoNumericTextBox({
    		decimals: 0,
			round: true
		});
		
		$("#logoMobileWidth").kendoNumericTextBox({
    		decimals: 0,
			round: true
		});
		
		$("#logoPaddingLeft").kendoNumericTextBox({
    		decimals: 0,
			round: true
		});
						   
		// When a user changes the width on one container, we need to change the value of the other container. The following function has quite a bit of casting 
		function changeContainerWidth(thisContainer, mainWidth, sidebarWidth){
			// Get the current values
			sideBarWidthVal = parseInt($("#sideBarContainerWidth").val());
			mainWidthVal = parseInt($("#mainContainerWidth").val());

			// Only make changes if the two containers don't  add up to 100
			if (parseFloat(sideBarWidthVal) + parseFloat(mainWidthVal) != 100 ){
				// Change the value of the other container
				if (thisContainer == 'sideBarContainerWidth'){
					$("#mainContainerWidth").val(parseFloat(100)-parseFloat(sideBarWidthVal));
				} else if (thisContainer == 'mainContainerWidth'){
					$("#sideBarContainerWidth").val(parseFloat(100) - parseFloat(mainWidthVal));
				}
			}
		}
		 
	</script>
	
	<cfif breakPoint eq 0>
	<!--- Hide the container width elements when in modern mode --->
	<style>
		.containerWidths {
			display: none;
		}
	</style>
	</cfif>
		
	<style>
	<cfif includeBackgroundImages>
		.backgroundColor {
			display: none;
		}
	<cfelse>
		.includeBackgroundImages {
			display: none;
		}
	</cfif>
	</style>
		
	<form id="themeForm" action="#" method="post" data-role="validator">
	<input type="hidden" name="csrfToken" id="csrfToken" value="<cfoutput>#csrfToken#</cfoutput>">
	<input type="hidden" name="themeId" id="themeId" value="<cfoutput>#themeId#</cfoutput>">
	<input type="hidden" name="themeSettingId" id="themeSettingId" value="<cfoutput>#themeSettingId#</cfoutput>">
	<table align="center" class="k-content" width="100%" cellpadding="2" cellspacing="0">
	  <cfsilent>
		<!---The first content class in the table should be empty. --->
		<cfset thisContentClass = HtmlUtilsObj.getKendoClass('')>
		<!--- Set the colspan property for borders --->
		<cfset thisColSpan = "2">
	  </cfsilent>
	  <tr height="1px">
		  <td align="left" valign="top" colspan="2" class="<cfoutput>#thisContentClass#</cfoutput>"></td>
	  </tr>
	 <cfif len(themeId) eq 0>
	  <tr valign="middle" height="30px">
		<td valign="bottom" align="left" class="<cfoutput>#thisContentClass#</cfoutput>" colspan="<cfoutput>#thisColSpan#</cfoutput>">
			The theme name can be changed to anything that you want when creating a theme. However, only use text and do not include any special characters. The name that you choose will be shown on the top menu.
		</td>
	  </tr>
	  <tr height="1px">
		  <td align="left" valign="top" colspan="2" class="border <cfoutput>#thisContentClass#</cfoutput>"></td>
	  </tr>
	</cfif>
	<cfif session.isMobile>
	  <tr valign="middle">
		<td class="<cfoutput>#thisContentClass#</cfoutput>" colspan="2">
			<label for="theme">Theme:</label>
		</td>
	   </tr>
	   <tr>
		<td class="<cfoutput>#thisContentClass#</cfoutput>" colspan="2">
			<input id="theme" name="theme" type="text" value="<cfoutput>#theme#</cfoutput>" class="k-textbox" style="width: 95%" />  
		</td>
	  </tr>
	<cfelse><!---<cfif session.isMobile>--->
	  <tr>
		<td align="right" class="<cfoutput>#thisContentClass#</cfoutput>" style="width: 20%"> 
			<label for="theme">Theme:</label>
		</td>
		<td class="<cfoutput>#thisContentClass#</cfoutput>">
			<input id="theme" name="theme" type="text" value="<cfoutput>#theme#</cfoutput>" class="k-textbox" style="width: 50%" />    
		</td>
	  </tr>
	</cfif>
	  <!-- Border -->
	  <tr height="2px">
		  <td align="left" valign="top" colspan="<cfoutput>#thisColSpan#</cfoutput>" class="<cfoutput>#thisContentClass#</cfoutput>"></td>
	  </tr>
	  <cfsilent>
	  <!--- Set the class for alternating rows. --->
	  <!---After the first row, the content class should be the current class. --->
	  <cfset thisContentClass = HtmlUtilsObj.getKendoClass(thisContentClass)>
	  </cfsilent>
	  <tr height="2px">
		  <td align="left" valign="bottom" colspan="2" class="border <cfoutput>#thisContentClass#</cfoutput>"></td>
	  </tr>
	  <tr valign="middle" height="30px">
		<td valign="bottom" align="left" class="<cfoutput>#thisContentClass#</cfoutput>" colspan="<cfoutput>#thisColSpan#</cfoutput>">
			Themes that are used will be available to attach to a given post.
			Additionally, when a theme is in use, they will be available in the theme dropdown menu at the top of the page. However, if a theme is selected below- no theme menu's will appear. 
		</td>
	  </tr>
	  <tr height="1px">
		  <td align="left" valign="top" colspan="2" class="border <cfoutput>#thisContentClass#</cfoutput>"></td>
	  </tr>
	<cfif session.isMobile>
	  <tr valign="middle">
		<td class="<cfoutput>#thisContentClass#</cfoutput>" colspan="2">
			<label for="useTheme">Use Theme?<label></td>
		</td>
	   </tr>
	   <tr>
		<td class="<cfoutput>#thisContentClass#</cfoutput>" colspan="2">
			<input type="checkbox" name="useTheme" id="useTheme" <cfif useTheme>checked</cfif>>
		</td>
	  </tr>
	<cfelse><!---<cfif session.isMobile>--->
	  <tr valign="middle" height="30px">
		<td valign="bottom" align="right" class="<cfoutput>#thisContentClass#</cfoutput>">
			<label for="useTheme">Use Theme?<label></td>
		<td valign="bottom" align="left" class="<cfoutput>#thisContentClass#</cfoutput>">
			<input type="checkbox" name="useTheme" id="useTheme" <cfif useTheme>checked</cfif>>
		</td>
	  </tr>
	</cfif>
	  <!-- Border -->
	  <tr height="2px">
	    <td align="left" valign="top" colspan="<cfoutput>#thisColSpan#</cfoutput>" class="<cfoutput>#thisContentClass#</cfoutput>"></td>
	  </tr>
	  <cfsilent>
	  <!--- Set the class for alternating rows. --->
	  <!---After the first row, the content class should be the current class. --->
	  <cfset thisContentClass = HtmlUtilsObj.getKendoClass(thisContentClass)>
	  </cfsilent>
	  <tr height="2px">
		  <td align="left" valign="bottom" colspan="2" class="border <cfoutput>#thisContentClass#</cfoutput>"></td>
	  </tr>
	  <tr valign="middle" height="30px">
		<td valign="bottom" align="left" class="<cfoutput>#thisContentClass#</cfoutput>" colspan="<cfoutput>#thisColSpan#</cfoutput>">
			Selecting this theme will make this the only theme that is displayed and will remove the theme dropdowns on the top menu. You can change this setting at any time.
		</td>
	  </tr>
	  <tr height="1px">
		  <td align="left" valign="top" colspan="2" class="border <cfoutput>#thisContentClass#</cfoutput>"></td>
	  </tr>
	<cfif session.isMobile>
	  <tr valign="middle">
		<td class="<cfoutput>#thisContentClass#</cfoutput>" colspan="2">
			<label for="selectedTheme">Select Theme?</label>
		</td>
	   </tr>
	   <tr>
		<td class="<cfoutput>#thisContentClass#</cfoutput>" colspan="2">
			<input type="checkbox" name="selectedTheme" id="selectedTheme" <cfif selectedTheme>checked</cfif>>
		</td>
	  </tr>
	<cfelse><!---<cfif session.isMobile>--->
	  <tr valign="middle" height="30px">
		<td valign="bottom" align="right" class="<cfoutput>#thisContentClass#</cfoutput>">
			<label for="selectedTheme">Select Theme?</label>
		</td>
		<td valign="bottom" align="left" class="<cfoutput>#thisContentClass#</cfoutput>">
			<input type="checkbox" name="selectedTheme" id="selectedTheme" <cfif selectedTheme>checked</cfif>>
		</td>
	  </tr>
	</cfif>
	  <!-- Border -->
	  <tr height="2px">
	    <td align="left" valign="top" colspan="<cfoutput>#thisColSpan#</cfoutput>" class="<cfoutput>#thisContentClass#</cfoutput>"></td>
	  </tr>
	  <cfsilent>
	  <!--- Set the class for alternating rows. --->
	  <!---After the first row, the content class should be the current class. --->
	  <cfset thisContentClass = HtmlUtilsObj.getKendoClass(thisContentClass)>
	  </cfsilent>
	  <tr height="2px">
		  <td align="left" valign="top" colspan="2" class="border <cfoutput>#thisContentClass#</cfoutput>"></td>
	  </tr>
	  <!-- Form content -->
	  <tr valign="middle" height="30px">
		<td valign="bottom" align="left" class="<cfoutput>#thisContentClass#</cfoutput>" colspan="<cfoutput>#thisColSpan#</cfoutput>">
			The Kendo Theme controls the look and feel of the interfaces that are used by the theme. You can modify the Galaxie Blog and change the underlying Kendo theme, but be aware that all of the default Galaxie Blog themes are designed with a Kendo theme in mind. As of Galaxie Blog version 3.0, we are only supporting the Kendo Less based themes, however, we will support the Kendo SASS themes in the future. You can see all of the less based Kendo themes by navigating to the Kendo Theme builder at <a href="https://demos.telerik.com/kendo-ui/themebuilder">https://demos.telerik.com/kendo-ui/themebuilder</a>
		</td>
	  </tr>
	  <tr height="1px">
		  <td align="left" valign="top" colspan="2" class="border <cfoutput>#thisContentClass#</cfoutput>"></td>
	  </tr>
	<cfif session.isMobile>
	  <tr valign="middle">
		<td class="<cfoutput>#thisContentClass#</cfoutput>" colspan="2">
			<label for="kendoThemeId">Kendo Theme:</label>
		</td>
	   </tr>
	   <tr>
		<td class="<cfoutput>#thisContentClass#</cfoutput>" colspan="2">
			<select id="kendoThemeId" name="kendoThemeId" style="width: 95%"></select>
		</td>
	  </tr>
	<cfelse><!---<cfif session.isMobile>--->
	  <tr valign="middle" height="30px">
		<td align="right" class="<cfoutput>#thisContentClass#</cfoutput>">
			<label for="kendoThemeId">Kendo Theme:</label>
		</td>
		<td align="left" class="<cfoutput>#thisContentClass#</cfoutput>">
			<select id="kendoThemeId" name="kendoThemeId" style="width: 50%"></select>
		</td>
	  </tr>
	</cfif>	  
	  <cfsilent>
	  <!--- Set the class for alternating rows. --->
	  <!---After the first row, the content class should be the current class. --->
	  <cfset thisContentClass = HtmlUtilsObj.getKendoClass(thisContentClass)>
	  </cfsilent>
	  <tr height="2px">
		  <td align="left" valign="top" colspan="2" class="border <cfoutput>#thisContentClass#</cfoutput>"></td>
	  </tr>
	  <!-- Form content -->
	  <tr valign="middle" height="30px">
		<td valign="bottom" align="left" class="<cfoutput>#thisContentClass#</cfoutput>" colspan="<cfoutput>#thisColSpan#</cfoutput>">
			A dark theme is a theme with a dark background. We need to determine if this is a dark theme in order to change the appearance of the page to fit the theme. 
		</td>
	  </tr>
	  <tr height="1px">
		  <td align="left" valign="top" colspan="2" class="border <cfoutput>#thisContentClass#</cfoutput>"></td>
	  </tr>
	<cfif session.isMobile>
	  <tr valign="middle">
		<td class="<cfoutput>#thisContentClass#</cfoutput>" colspan="2">
			<label for="darkTheme">Dark Theme?</label>
		</td>
	   </tr>
	   <tr>
		<td class="<cfoutput>#thisContentClass#</cfoutput>" colspan="2">
			<input type="checkbox" name="darkTheme" id="darkTheme" value="1" <cfif darkTheme>checked</cfif>>
		</td>
	  </tr>
	<cfelse><!---<cfif session.isMobile>--->
	  <tr valign="middle" height="30px">
		<td align="right" class="<cfoutput>#thisContentClass#</cfoutput>">
			<label for="darkTheme">Dark Theme?</label>
		</td>
		<td align="left" class="<cfoutput>#thisContentClass#</cfoutput>">
			<input type="checkbox" name="darkTheme" id="darkTheme" value="1" <cfif darkTheme>checked</cfif>>
		</td>
	  </tr>
	</cfif>	  
	  <!-- Border -->
	  <tr height="2px">
		  <td align="left" valign="top" colspan="<cfoutput>#thisColSpan#</cfoutput>" class="<cfoutput>#thisContentClass#</cfoutput>"></td>
	  </tr>
	  
	</table>
	<br/>
			  
	<!---//***********************************************************************************************
						Container Properties
	//************************************************************************************************--->
	<button type="button" class="collapsible k-header">Blog Theme Style and Column Display</button>
	<div class="content k-content">
		<table align="center" class="k-content" width="100%" cellpadding="2" cellspacing="0">
		  <cfsilent>
			<!---The first content class in the table should be empty. --->
			<cfset thisContentClass = HtmlUtilsObj.getKendoClass('')>
			<!--- Set the colspan property for borders --->
			<cfset thisColSpan = "2">
		  </cfsilent>
				
		  <!-- Border -->
		  <tr height="2px">
			  <td align="left" valign="top" colspan="<cfoutput>#thisColSpan#</cfoutput>" class="<cfoutput>#thisContentClass#</cfoutput>"></td>
		  </tr>
		  <cfsilent>
		  <!--- Set the class for alternating rows. --->
		  <!---After the first row, the content class should be the current class. --->
		  <cfset thisContentClass = HtmlUtilsObj.getKendoClass(thisContentClass)>
		  </cfsilent>
		  <tr height="1px">
			  <td align="left" valign="top" colspan="2" class="<cfoutput>#thisContentClass#</cfoutput>"></td>
		  </tr>
		  <tr>
			<td colspan="2"> 
				<p>The main content width sets the width on the main container that holds the two sub containers below. This setting will either increase or decrease the blog content depending upon your setting.</p>
				
				<p>The main content width will dynamically be adjusted depending upon the client screen resolution. When the monitor is quite wide, the main content width will be set to a smaller percentage, conversly, when the monitor is smaller in width, this width will be automatically adjusted higher.</p>
				
				<p>This is done as you want to have a similiar content width across various monitor sizes. The baseline content width that you set will be targetted at a screen resolution betwen 1700 and 1920 pixels wide.</p>
				
				<p>You should set the main container width to at least 45% when using the modern theme style, or 66% when using the classic style as you will have extra content on the right side. Setting it larger will stretch the main container accross the page making the blog content more cumbersome to read. Generally speaking, the main blog content should be no more than 140 characters wide and focus the content in the center of the page.</p>
			</td>
		  </tr>
		  <!-- Border -->
		  <tr height="2px">
			  <td align="left" valign="top" colspan="<cfoutput>#thisColSpan#</cfoutput>" class="<cfoutput>#thisContentClass#</cfoutput>"></td>
		  </tr>
		<cfif session.isMobile>
		  <tr valign="middle">
			<td class="<cfoutput>#thisContentClass#</cfoutput>" colspan="2">
				<label for="contentWidth">Main Content Width:</label>
			</td>
		   </tr>
		   <tr>
			<td class="<cfoutput>#thisContentClass#</cfoutput>" colspan="2">
				<input type="number" id="contentWidth" name="contentWidth" min="33" max="100" step="1" value="<cfoutput>#contentWidth#</cfoutput>" class="k-textbox" >% 
			</td>
		  </tr>
		<cfelse><!---<cfif session.isMobile>--->
		  <tr>
			<td align="right" class="<cfoutput>#thisContentClass#</cfoutput>" style="width: 20%"> 
				<label for="contentWidth">Main Content Width:</label>
			</td>
			<td class="<cfoutput>#thisContentClass#</cfoutput>">
				<input type="number" id="contentWidth" name="contentWidth" min="33" max="100" step="1" value="<cfoutput>#contentWidth#</cfoutput>" class="k-textbox" >% 
			</td>
		  </tr>
		</cfif>
		  <!-- Border -->
		  <tr height="2px" class="containerWidths">
			  <td align="left" valign="top" colspan="<cfoutput>#thisColSpan#</cfoutput>" class="<cfoutput>#thisContentClass#</cfoutput>"></td>
		  </tr>
		  
		  <cfsilent>
		  <!--- Set the class for alternating rows. --->
		  <!---After the first row, the content class should be the current class. --->
		  <cfset thisContentClass = HtmlUtilsObj.getKendoClass(thisContentClass)>
		  </cfsilent>
		  <tr height="1px">
			  <td align="left" valign="top" colspan="2" class="<cfoutput>#thisContentClass#</cfoutput>"></td>
		  </tr>
		  <tr>
			<td colspan="2"> 
				<p>There are two options that dramatically affect the blog display.</p> 
				<p>The <b>Classic</b> theme style displays the column on the right of the blog containing various 'pods', such as the categories, recent posts and comments, etc. this is a useful design if you want to allow your users to quickly navigate your site or if you want include visible advertising.</p>
				<p>The <b>Modern</b> theme style removes the panel on the right, but the panel is still accessible by clicking on the hamburger at the top of the site. The Modern theme style keeps keeps the blog content center stage and is a more modern design.</p>
			</td>
		  </tr>
		  <!-- Border -->
		  <tr height="2px">
			  <td align="left" valign="top" colspan="<cfoutput>#thisColSpan#</cfoutput>" class="<cfoutput>#thisContentClass#</cfoutput>"></td>
		  </tr>
		<cfif session.isMobile>
		  <tr valign="middle">
			<td class="<cfoutput>#thisContentClass#</cfoutput>" colspan="2">
				<label for="blogStyle">Blog Theme Style:</label>
			</td>
		   </tr>
		   <tr>
			<td class="<cfoutput>#thisContentClass#</cfoutput>" colspan="2">
				<table align="center" class="<cfoutput>#thisContentClass#</cfoutput>" width="100%" cellpadding="5" cellspacing="0" border="0">
					<tr>
						<td width="50%" align="left">
							<input id="themeStyle" name="themeStyle" type="radio" value="classic" <cfif breakPoint gt 0>checked</cfif> class="normalFontWeight" onclick='javascript:$( ".containerWidths" ).show();'>
							<label for="themeStyle">classic</label>
						</td>
						<td width="50%" align="left">
							<input id="themeStyle" name="themeStyle" type="radio" value="modern" <cfif breakPoint eq 0>checked</cfif> class="normalFontWeight" onclick='javascript:$( ".containerWidths" ).hide();'>
							<label for="modern">Modern</label>
						</td>
					</tr>
				</table>
			</td>
		  </tr>
		<cfelse><!---<cfif session.isMobile>--->
		  <tr>
			<td align="right" class="<cfoutput>#thisContentClass#</cfoutput>" style="width: 20%"> 
				<label for="blogStyle">Blog Theme Style:</label>
			</td>
			<td class="<cfoutput>#thisContentClass#</cfoutput>">
				<table align="center" class="<cfoutput>#thisContentClass#</cfoutput>" width="100%" cellpadding="5" cellspacing="0" border="0">
					<tr>
						<td width="50%" align="left">
							<input id="themeStyle" name="themeStyle" type="radio" value="classic" <cfif breakPoint gt 0>checked</cfif> class="normalFontWeight" onclick='javascript:$( ".containerWidths" ).show();'>
							<label for="themeStyle">classic</label>
						</td>
						<td width="50%" align="left">
							<input id="themeStyle" name="themeStyle" type="radio" value="modern" <cfif breakPoint eq 0>checked</cfif> class="normalFontWeight" onclick='javascript:$( ".containerWidths" ).hide();'>
							<label for="modern">Modern</label>
						</td>
					</tr>
				</table>
			</td>
		  </tr>
		</cfif>
		  <!-- Border -->
		  <tr height="2px" class="containerWidths">
			  <td align="left" valign="top" colspan="<cfoutput>#thisColSpan#</cfoutput>" class="<cfoutput>#thisContentClass#</cfoutput>"></td>
		  </tr>
		  <cfsilent>
		  <!--- Set the class for alternating rows. --->
		  <!---After the first row, the content class should be the current class. --->
		  <cfset thisContentClass = HtmlUtilsObj.getKendoClass(thisContentClass)>
		  </cfsilent>
			  
		  <tr height="1px">
			  <td align="left" valign="top" colspan="2" class="<cfoutput>#thisContentClass#</cfoutput>"></td>
		  </tr>
		<cfif session.isMobile>
		  <tr valign="middle" class="containerWidths">
			<td class="<cfoutput>#thisContentClass#</cfoutput>" colspan="2">
				<label for="mainContainerWidth">Main Panel Container Width:</label>
			</td>
		   </tr>
		   <tr class="containerWidths">
			<td class="<cfoutput>#thisContentClass#</cfoutput>" colspan="2">
				<!--- We are passing: 35 as the adminInterfaceId, URL.optArgs is the themeId, URL.otherArgs is the theme image type, and URL.otherArgs1 is the current image being used. --->
				<cfoutput>
				<input type="number" id="mainContainerWidth" name="mainContainerWidth" min="50" max="80" step="1" value="#mainContainerWidth#" style="width: 20%" class="k-textbox" onChange="changeContainerWidth('mainContainerWidth');">% (left panel)
				</cfoutput>
			</td>
		  </tr>
		<cfelse><!---<cfif session.isMobile>--->
		  <tr class="containerWidths">
			<td align="right" class="<cfoutput>#thisContentClass#</cfoutput>" style="width: 20%"> 
				<label for="mainContainerWidth">Main Panel Container Width:</label>
			</td>
			<td class="<cfoutput>#thisContentClass#</cfoutput>">
				<!--- We are passing: 35 as the adminInterfaceId, URL.optArgs is the themeId, URL.otherArgs is the theme image type, and URL.otherArgs1 is the current image being used. --->
				<cfoutput>
				<input type="number" id="mainContainerWidth" name="mainContainerWidth" min="50" max="80" step="1" value="#mainContainerWidth#" style="width: 20%" class="k-textbox" onChange="changeContainerWidth('mainContainerWidth');">% (left panel)
				</cfoutput>
			</td>
		  </tr>
		</cfif>	  
		  <!-- Border -->
		  <tr height="2px" class="containerWidths">
			  <td align="left" valign="top" colspan="<cfoutput>#thisColSpan#</cfoutput>" class="<cfoutput>#thisContentClass#</cfoutput>"></td>
		  </tr>
		  <cfsilent>
		  <!--- Set the class for alternating rows. --->
		  <!---After the first row, the content class should be the current class. --->
		  <cfset thisContentClass = HtmlUtilsObj.getKendoClass(thisContentClass)>
		  </cfsilent>
		  <tr height="1px" class="containerWidths">
			  <td align="left" valign="top" colspan="2" class="<cfoutput>#thisContentClass#</cfoutput>"></td>
		  </tr>
		<cfif session.isMobile>
		  <tr valign="middle" class="containerWidths">
			<td class="<cfoutput>#thisContentClass#</cfoutput>" colspan="2">
				<label for="sideBarContainerWidth">Sidebar Container Width:</label>
			</td>
		   </tr>
		   <tr class="containerWidths">
			<td class="<cfoutput>#thisContentClass#</cfoutput>" colspan="2">
				<input type="number" id="sideBarContainerWidth" name="sideBarContainerWidth" min="20" max="50" step="1" value="<cfoutput>#sideBarContainerWidth#</cfoutput>" style="width: 20%" class="k-textbox" onChange="changeContainerWidth('sideBarContainerWidth');">% (right panel)  
			</td>
		  </tr>
		<cfelse><!---<cfif session.isMobile>--->
		  <tr class="containerWidths">
			<td align="right" class="<cfoutput>#thisContentClass#</cfoutput>" style="width: 20%"> 
				<label for="sideBarContainerWidth">Sidebar Container Width:</label>
			</td>
			<td class="<cfoutput>#thisContentClass#</cfoutput>">
				<input type="number" id="sideBarContainerWidth" name="sideBarContainerWidth" min="20" max="50" step="1" value="<cfoutput>#sideBarContainerWidth#</cfoutput>" style="width: 20%" class="k-textbox" onChange="changeContainerWidth('sideBarContainerWidth');">% (right panel)
			</td>
		  </tr>
		</cfif>	  
		  <!-- Border -->
		  <tr height="2px" class="containerWidths">
			  <td align="left" valign="top" colspan="<cfoutput>#thisColSpan#</cfoutput>" class="<cfoutput>#thisContentClass#</cfoutput>"></td>
		  </tr>
		  <cfsilent>
		  <!--- Set the class for alternating rows. --->
		  <!---After the first row, the content class should be the current class. --->
		  <cfset thisContentClass = HtmlUtilsObj.getKendoClass(thisContentClass)>
		  </cfsilent>
		  <tr height="1px">
			  <td align="left" valign="top" colspan="2" class="<cfoutput>#thisContentClass#</cfoutput>"></td>
		  </tr>
		  <tr>
			<td align="left" class="<cfoutput>#thisContentClass#</cfoutput>" colspan="2"> 
				<p>Site Opacity allows the blog background image to 'bleed through' the containers on the blog. I often set the opacity level around 93% in order to allow the users to see a hint of the background image. For a cleaner look, you can set the opacity to 99% to eliminate the ghosting.</p>
			</td>
		  </tr>
		  <!-- Border -->
		  <tr height="2px">
			<td align="left" valign="top" colspan="<cfoutput>#thisColSpan#</cfoutput>" class="<cfoutput>#thisContentClass#</cfoutput>"></td>
		  </tr>
		<cfif session.isMobile>
		  <tr valign="middle">
			<td class="<cfoutput>#thisContentClass#</cfoutput>" colspan="2">
				<label for="siteOpacity">Site Opacity:</label>
			</td>
		   </tr>
		   <tr>
			<td class="<cfoutput>#thisContentClass#</cfoutput>" colspan="2">
				<input type="number" id="siteOpacity" name="siteOpacity" min="75" max="100" step="1" value="<cfoutput>#siteOpacity#</cfoutput>" class="k-textbox" style="width: 30%">%
			</td>
		  </tr>
		<cfelse><!---<cfif session.isMobile>--->
		  <tr>
			<td align="right" class="<cfoutput>#thisContentClass#</cfoutput>" style="width: 20%"> 
				<label for="siteOpacity">Site Opacity:</label>
			</td>
			<td class="<cfoutput>#thisContentClass#</cfoutput>">
				<input type="number" id="siteOpacity" name="siteOpacity" min="75" max="100" step="1" value="<cfoutput>#siteOpacity#</cfoutput>" class="k-textbox" style="width: 20%">%
			</td>
		  </tr>
		</cfif>	  
		  <!-- Border -->
		  <tr height="2px">
			<td align="left" valign="top" colspan="<cfoutput>#thisColSpan#</cfoutput>" class="<cfoutput>#thisContentClass#</cfoutput>"></td>
		  </tr>
		</table>
	</div>
		
	<!---//***********************************************************************************************
						Fonts
	//************************************************************************************************--->
	<button type="button" class="collapsible k-header">Fonts</button>
	<div class="content k-content">
		<table align="center" class="k-content" width="100%" cellpadding="2" cellspacing="0">
			
		  <cfsilent>
			<!---The first content class in the table should be empty. --->
			<cfset thisContentClass = HtmlUtilsObj.getKendoClass('')>
			<!--- Set the colspan property for borders --->
			<cfset thisColSpan = "2">
		  </cfsilent>
			 
		  <tr height="1px">
			  <td align="left" valign="top" colspan="2" class="<cfoutput>#thisContentClass#</cfoutput>"></td>
		  </tr>
		<cfif session.isMobile>
		  <tr valign="middle">
			<td class="<cfoutput>#thisContentClass#</cfoutput>" colspan="2">
				<label for="blogNameFontDropdown">Title Font:</label>
			</td>
		   </tr>
		   <tr>
			<td class="<cfoutput>#thisContentClass#</cfoutput>" colspan="2">
				<select id="blogNameFontDropdown" name="blogNameFontDropdown" style="width: 95%"></select>  
				<!--- Inline template to add a new user. --->
				<script id="addFont" type="text/x-kendo-tmpl">
					<div>
						Font not found. Do you want to add '#: instance.filterInput.val() #'?
					</div>
					<br />
					<button class="k-button" onclick="createAdminInterfaceWindow(31, '#: instance.filterInput.val() #', 'addFont')">Add Font</button>
				</script> 
			</td>
		  </tr>
		<cfelse><!---<cfif session.isMobile>--->
		  <tr>
			<td align="right" class="<cfoutput>#thisContentClass#</cfoutput>" style="width: 20%"> 
				<label for="blogNameFontDropdown">Title Font:</label>
			</td>
			<td class="<cfoutput>#thisContentClass#</cfoutput>">
				<select id="blogNameFontDropdown" name="blogNameFontDropdown" style="width: 50%"></select>  
				<!--- Inline template to add a new user. --->
				<script id="addFont" type="text/x-kendo-tmpl">
					<div>
						Font not found. Do you want to add '#: instance.filterInput.val() #'?
					</div>
					<br />
					<button class="k-button" onclick="createAdminInterfaceWindow(31, '#: instance.filterInput.val() #', 'addFont')">Add Font</button>
				</script>  
			</td>
		  </tr>
		</cfif>	
		<!-- Border -->
		  <tr height="2px">
			  <td align="left" valign="top" colspan="<cfoutput>#thisColSpan#</cfoutput>" class="<cfoutput>#thisContentClass#</cfoutput>"></td>
		  </tr>
		  <cfsilent>
		  <!--- Set the class for alternating rows. --->
		  <!---After the first row, the content class should be the current class. --->
		  <cfset thisContentClass = HtmlUtilsObj.getKendoClass(thisContentClass)>
		  </cfsilent>
			  
		   <tr height="1px">
			  <td align="left" valign="top" colspan="2" class="<cfoutput>#thisContentClass#</cfoutput>"></td>
		  </tr>
		<cfif session.isMobile>
		  <tr valign="middle">
			<td class="<cfoutput>#thisContentClass#</cfoutput>" colspan="2">
				<label for="blogNameFontSize">Title Font Size:</label>
			</td>
		   </tr>
		   <tr>
			<td class="<cfoutput>#thisContentClass#</cfoutput>" colspan="2">
				<input type="number" id="blogNameFontSize" name="blogNameFontSize" min="8" max="36" step="1" value="<cfoutput>#blogNameFontSize#</cfoutput>" class="k-textbox" > pt
			</td>
		  </tr>
		<cfelse><!---<cfif session.isMobile>--->
		  <tr>
			<td align="right" class="<cfoutput>#thisContentClass#</cfoutput>" style="width: 20%"> 
				<label for="fontSize">Title Font Size:</label>
			</td>
			<td class="<cfoutput>#thisContentClass#</cfoutput>">
				<input type="number" id="blogNameFontSize" name="blogNameFontSize" min="8" max="36" step="1" value="<cfoutput>#blogNameFontSize#</cfoutput>" class="k-textbox" > pt 
			</td>
		  </tr>
		</cfif>  
		  <!-- Border -->
		  <tr height="2px">
			  <td align="left" valign="top" colspan="<cfoutput>#thisColSpan#</cfoutput>" class="<cfoutput>#thisContentClass#</cfoutput>"></td>
		  </tr>
		  <cfsilent>
		  <!--- Set the class for alternating rows. --->
		  <!---After the first row, the content class should be the current class. --->
		  <cfset thisContentClass = HtmlUtilsObj.getKendoClass(thisContentClass)>
		  </cfsilent>
			  
		   <tr height="1px">
			  <td align="left" valign="top" colspan="2" class="<cfoutput>#thisContentClass#</cfoutput>"></td>
		  </tr>
		<cfif session.isMobile>
		  <tr valign="middle">
			<td class="<cfoutput>#thisContentClass#</cfoutput>" colspan="2">
				<label for="blogNameFontSizeMobile">Mobile Title Font Size:</label>
			</td>
		   </tr>
		   <tr>
			<td class="<cfoutput>#thisContentClass#</cfoutput>" colspan="2">
				<input type="number" id="blogNameFontSizeMobile" name="blogNameFontSizeMobile" min="8" max="30" step="1" value="<cfoutput>#blogNameFontSizeMobile#</cfoutput>" class="k-textbox" > pt  
			</td>
		  </tr>
		<cfelse><!---<cfif session.isMobile>--->
		  <tr>
			<td align="right" class="<cfoutput>#thisContentClass#</cfoutput>" style="width: 20%"> 
				<label for="blogNameFontSizeMobile">Mobile Title Font Size:</label>
			</td>
			<td class="<cfoutput>#thisContentClass#</cfoutput>">
				<input type="number" id="blogNameFontSizeMobile" name="blogNameFontSizeMobile" min="8" max="30" step="1" value="<cfoutput>#blogNameFontSizeMobile#</cfoutput>" class="k-textbox" > pt  
			</td>
		  </tr>
		</cfif>
		  <!-- Border -->
		  <tr height="2px">
			  <td align="left" valign="top" colspan="<cfoutput>#thisColSpan#</cfoutput>" class="<cfoutput>#thisContentClass#</cfoutput>"></td>
		  </tr>
		  <cfsilent>
		  <!--- Set the class for alternating rows. --->
		  <!---After the first row, the content class should be the current class. --->
		  <cfset thisContentClass = HtmlUtilsObj.getKendoClass(thisContentClass)>
		  </cfsilent>
		  <tr height="1px">
			  <td align="left" valign="top" colspan="2" class="<cfoutput>#thisContentClass#</cfoutput>"></td>
		  </tr>
		<cfif session.isMobile>
		  <tr valign="middle">
			<td class="<cfoutput>#thisContentClass#</cfoutput>" colspan="2">
				<label for="menuFontDropdown">Top Menu Font:</label>
			</td>
		   </tr>
		   <tr>
			<td class="<cfoutput>#thisContentClass#</cfoutput>" colspan="2">
				<select id="menuFontDropdown" name="menuFontDropdown" style="width: 95%"></select>  
				<!--- Inline template to add a new user. --->
				<script id="addFont" type="text/x-kendo-tmpl">
					<div>
						Font not found. Do you want to add '#: instance.filterInput.val() #'?
					</div>
					<br />
					<button class="k-button" onclick="createAdminInterfaceWindow(31, '#: instance.filterInput.val() #', 'addFont')">Add Font</button>
				</script>  
			</td>
		  </tr>
		<cfelse><!---<cfif session.isMobile>--->
		  <tr>
			<td align="right" class="<cfoutput>#thisContentClass#</cfoutput>" style="width: 20%"> 
				<label for="menuFontDropdown">Top Menu Font:</label>
			</td>
			<td class="<cfoutput>#thisContentClass#</cfoutput>">
				<select id="menuFontDropdown" name="menuFontDropdown" style="width: 50%"></select>  
				<!--- Inline template to add a new user. --->
				<script id="addFont" type="text/x-kendo-tmpl">
					<div>
						Font not found. Do you want to add '#: instance.filterInput.val() #'?
					</div>
					<br />
					<button class="k-button" onclick="createAdminInterfaceWindow(31, '#: instance.filterInput.val() #', 'addFont')">Add Font</button>
				</script>  
			</td>
		  </tr>
		</cfif>	  
		  <cfsilent>
		  <!--- Set the class for alternating rows. --->
		  <!---After the first row, the content class should be the current class. --->
		  <cfset thisContentClass = HtmlUtilsObj.getKendoClass(thisContentClass)>
		  </cfsilent>
				
		  <!-- Border -->
		  <tr height="2px">
			  <td align="left" valign="top" colspan="<cfoutput>#thisColSpan#</cfoutput>" class="<cfoutput>#thisContentClass#</cfoutput>"></td>
		  </tr>
		  <tr height="1px">
			  <td align="left" valign="top" colspan="2" class="<cfoutput>#thisContentClass#</cfoutput>"></td>
		  </tr>
		<cfif session.isMobile>
		  <tr valign="middle">
			<td class="<cfoutput>#thisContentClass#</cfoutput>" colspan="2">
				<label for="bodyFontDropdown">Body Font:</label>
			</td>
		   </tr>
		   <tr>
			<td class="<cfoutput>#thisContentClass#</cfoutput>" colspan="2">
				<select id="bodyFontDropdown" name="bodyFontDropdown" style="width: 95%"></select>  
				<!--- Inline template to add a new user. --->
				<script id="addFont" type="text/x-kendo-tmpl">
					<div>
						Font not found. Do you want to add '#: instance.filterInput.val() #'?
					</div>
					<br />
					<button class="k-button" onclick="createAdminInterfaceWindow(31, '#: instance.filterInput.val() #', 'addFont')">Add Font</button>
				</script> 
			</td>
		  </tr>
		<cfelse><!---<cfif session.isMobile>--->
		  <tr>
			<td align="right" class="<cfoutput>#thisContentClass#</cfoutput>" style="width: 20%"> 
				<label for="bodyFontDropdown">Body Font:</label>
			</td>
			<td class="<cfoutput>#thisContentClass#</cfoutput>">
				<select id="bodyFontDropdown" name="bodyFontDropdown" style="width: 50%"></select>  
				<!--- Inline template to add a new user. --->
				<script id="addFont" type="text/x-kendo-tmpl">
					<div>
						Font not found. Do you want to add '#: instance.filterInput.val() #'?
					</div>
					<br />
					<button class="k-button" onclick="createAdminInterfaceWindow(31, '#: instance.filterInput.val() #', 'addFont')">Add Font</button>
				</script>  
			</td>
		  </tr>
		</cfif>	  
		  <!-- Border -->
		  <tr height="2px">
			  <td align="left" valign="top" colspan="<cfoutput>#thisColSpan#</cfoutput>" class="<cfoutput>#thisContentClass#</cfoutput>"></td>
		  </tr>
		  <cfsilent>
		  <!--- Set the class for alternating rows. --->
		  <!---After the first row, the content class should be the current class. --->
		  <cfset thisContentClass = HtmlUtilsObj.getKendoClass(thisContentClass)>
		  </cfsilent>
			  
		   <tr height="1px">
			  <td align="left" valign="top" colspan="2" class="<cfoutput>#thisContentClass#</cfoutput>"></td>
		  </tr>
		<cfif session.isMobile>
		  <tr valign="middle">
			<td class="<cfoutput>#thisContentClass#</cfoutput>" colspan="2">
				<label for="fontSize">Desktop Body Font Size:</label>
			</td>
		   </tr>
		   <tr>
			<td class="<cfoutput>#thisContentClass#</cfoutput>" colspan="2">
				<input type="number" id="fontSize" name="fontSize" min="8" max="36" step="1" value="<cfoutput>#fontSize#</cfoutput>" class="k-textbox" > pt
			</td>
		  </tr>
		<cfelse><!---<cfif session.isMobile>--->
		  <tr>
			<td align="right" class="<cfoutput>#thisContentClass#</cfoutput>" style="width: 20%"> 
				<label for="fontSize">Desktop Body Font Size:</label>
			</td>
			<td class="<cfoutput>#thisContentClass#</cfoutput>">
				<input type="number" id="fontSize" name="fontSize" min="8" max="36" step="1" value="<cfoutput>#fontSize#</cfoutput>" class="k-textbox" > pt 
			</td>
		  </tr>
		</cfif>  
		  <!-- Border -->
		  <tr height="2px">
			  <td align="left" valign="top" colspan="<cfoutput>#thisColSpan#</cfoutput>" class="<cfoutput>#thisContentClass#</cfoutput>"></td>
		  </tr>
		  <cfsilent>
		  <!--- Set the class for alternating rows. --->
		  <!---After the first row, the content class should be the current class. --->
		  <cfset thisContentClass = HtmlUtilsObj.getKendoClass(thisContentClass)>
		  </cfsilent>
			  
		   <tr height="1px">
			  <td align="left" valign="top" colspan="2" class="<cfoutput>#thisContentClass#</cfoutput>"></td>
		  </tr>
		<cfif session.isMobile>
		  <tr valign="middle">
			<td class="<cfoutput>#thisContentClass#</cfoutput>" colspan="2">
				<label for="fontSizeMobile">Mobile Body Font Size:</label>
			</td>
		   </tr>
		   <tr>
			<td class="<cfoutput>#thisContentClass#</cfoutput>" colspan="2">
				<input type="number" id="fontSizeMobile" name="fontSizeMobile" min="8" max="32" step="1" value="<cfoutput>#fontSizeMobile#</cfoutput>" class="k-textbox"> pt  
			</td>
		  </tr>
		<cfelse><!---<cfif session.isMobile>--->
		  <tr>
			<td align="right" class="<cfoutput>#thisContentClass#</cfoutput>" style="width: 20%"> 
				<label for="fontSizeMobile">Mobile Body Font Size:</label>
			</td>
			<td class="<cfoutput>#thisContentClass#</cfoutput>">
				<input type="number" id="fontSizeMobile" name="fontSizeMobile" min="8" max="32" step="1" value="<cfoutput>#fontSizeMobile#</cfoutput>" class="k-textbox"> pt  
			</td>
		  </tr>
		</cfif>
		  <!-- Border -->
		  <tr height="2px">
			  <td align="left" valign="top" colspan="<cfoutput>#thisColSpan#</cfoutput>" class="<cfoutput>#thisContentClass#</cfoutput>"></td>
		  </tr>
			  
		  <!-- Border -->
		  <tr height="2px">
			<td align="left" valign="top" colspan="<cfoutput>#thisColSpan#</cfoutput>" class="<cfoutput>#thisContentClass#</cfoutput>"></td>
		  </tr>
		</table>
	</div>
			  
	<!---//***********************************************************************************************
						Fav Icon
	//************************************************************************************************--->
	<button type="button" class="collapsible k-header">Fav Icon</button>
	<div class="content k-content">
		<table align="center" class="k-content" width="100%" cellpadding="2" cellspacing="0">
		  <cfsilent>
			<!---The first content class in the table should be empty. --->
			<cfset thisContentClass = HtmlUtilsObj.getKendoClass('')>
			<!--- Set the colspan property for borders --->
			<cfset thisColSpan = "2">
		  </cfsilent>
				
		  <!-- Border -->
		  <tr height="2px">
			  <td align="left" valign="top" colspan="<cfoutput>#thisColSpan#</cfoutput>" class="<cfoutput>#thisContentClass#</cfoutput>"></td>
		  </tr>
		  <cfsilent>
		  <!--- Set the class for alternating rows. --->
		  <!---After the first row, the content class should be the current class. --->
		  <cfset thisContentClass = HtmlUtilsObj.getKendoClass(thisContentClass)>
		  </cfsilent>
		  <tr height="1px">
			  <td align="left" valign="top" colspan="2" class="<cfoutput>#thisContentClass#</cfoutput>"></td>
		  </tr>
		  <tr>
			<td colspan="2"> 
				<p>The Favorite Icon will allow other devices to display your theme when bookmarking a page and will display the icon on the tab in the browser.</p>
				<p>There are many free favicon generators on the web, for example, <a href="https://favicon.io/">https://favicon.io/</a> that will generate the necessary files for you.</p> <p>However, each generator is unique and creates different files and the standards are fluid and not consistent. Please generate your files manually or by using a generator, and paste in the code that you want the browser to render. Once you're done, you may also click on the upload FavIcon Files button below to upload your files to the root directory of your blog site.</p>
				<p>If you want your Favorite Icon HTML to be applied to all themes, click on the 'Apply across all themes' checkbox.</p>
			</td>
		  </tr>
		  <!-- Border -->
		  <tr height="2px">
			  <td align="left" valign="top" colspan="<cfoutput>#thisColSpan#</cfoutput>" class="<cfoutput>#thisContentClass#</cfoutput>"></td>
		  </tr>
			  
		<cfif session.isMobile>
		  <tr valign="middle">
			<td class="<cfoutput>#thisContentClass#</cfoutput>" colspan="2">
				<label for="uploadFavIcon"></label>
			</td>
		   </tr>
		   <tr>
			<td class="<cfoutput>#thisContentClass#</cfoutput>" colspan="2">				
				<button id="uploadFavIcon" class="k-button k-primary" type="button" onclick="createAdminInterfaceWindow(36, 'favIconUploader')">Upload FavIcon files</button> 
			</td>
		  </tr>
		<cfelse><!---<cfif session.isMobile>--->
		  <tr>
			<td align="right" class="<cfoutput>#thisContentClass#</cfoutput>" style="width: 20%"> 
				<label for="saveFavIcon">Upload Favorite Icons</label>
			</td>
			<td class="<cfoutput>#thisContentClass#</cfoutput>">				
				<button id="uploadFavIcon" class="k-button k-primary" type="button" onclick="createAdminInterfaceWindow(36, 'favIconUploader')">Upload FavIcon files</button>  
			</td>
		  </tr>
		</cfif>	
			
		  <cfsilent>
		  <!--- Set the class for alternating rows. --->
		  <!---After the first row, the content class should be the current class. --->
		  <cfset thisContentClass = HtmlUtilsObj.getKendoClass(thisContentClass)>
		  </cfsilent>
		  <tr height="1px">
			  <td align="left" valign="top" colspan="2" class="<cfoutput>#thisContentClass#</cfoutput>"></td>
		  </tr>
		
		  <!-- Border -->
		  <tr height="2px">
			  <td align="left" valign="top" colspan="<cfoutput>#thisColSpan#</cfoutput>" class="<cfoutput>#thisContentClass#</cfoutput>"></td>
		  </tr>
			  
		<cfif session.isMobile>
		  <tr valign="middle">
			<td class="<cfoutput>#thisContentClass#</cfoutput>" colspan="2">
				<label for="favIconHtml">Fav Icon HTML:</label>
			</td>
		   </tr>
		   <tr>
			<td class="<cfoutput>#thisContentClass#</cfoutput>" colspan="2">
				<textarea id="favIconHtml" name="favIconHtml" class="k-textbox" style="width: 66%; height: 175px;"><cfoutput>#FavIconHtml#</cfoutput></textarea> 
			</td>
		  </tr>
		<cfelse><!---<cfif session.isMobile>--->
		  <tr>
			<td align="right" class="<cfoutput>#thisContentClass#</cfoutput>" style="width: 20%"> 
				<label for="favIconHtml">Fav Icon HTML:</label>
			</td>
			<td class="<cfoutput>#thisContentClass#</cfoutput>">
				 <textarea id="favIconHtml" name="favIconHtml" class="k-textbox" style="width: 66%; height: 175px;"><cfoutput>#FavIconHtml#</cfoutput></textarea> 
			</td>
		  </tr>
		</cfif>
		  <!-- Border -->
		  <tr height="2px">
			  <td align="left" valign="top" colspan="<cfoutput>#thisColSpan#</cfoutput>" class="<cfoutput>#thisContentClass#</cfoutput>"></td>
		  </tr>
		<cfif session.isMobile>
		  <tr valign="middle">
			<td class="<cfoutput>#thisContentClass#</cfoutput>" colspan="2">
				<label for="applyFavIconToAllThemes">Apply across all themes:</label>
			</td>
		   </tr>
		   <tr>
			<td class="<cfoutput>#thisContentClass#</cfoutput>" colspan="2">
				<input type="checkbox" id="applyFavIconToAllThemes" name="applyFavIconToAllThemes">
			</td>
		  </tr>
		<cfelse><!---<cfif session.isMobile>--->
		  <tr>
			<td align="right" class="<cfoutput>#thisContentClass#</cfoutput>" style="width: 20%"> 
				<label for="applyFavIconToAllThemes">Apply across all themes:</label>
			</td>
			<td class="<cfoutput>#thisContentClass#</cfoutput>">
				 <input type="checkbox" id="applyFavIconToAllThemes" name="applyFavIconToAllThemes">
			</td>
		  </tr>
		</cfif>
			  
		  <!-- Border -->
		  <tr height="2px">
			<td align="left" valign="top" colspan="<cfoutput>#thisColSpan#</cfoutput>" class="<cfoutput>#thisContentClass#</cfoutput>"></td>
		  </tr>
		</table>
	</div>
				
	<!---//***********************************************************************************************
						Logos
	//************************************************************************************************--->
				
	<button type="button" class="collapsible k-header">Logos</button>
	<div class="content k-content">
		<table align="center" class="k-content" width="100%" cellpadding="2" cellspacing="0">
		  <cfsilent>
			<!---The first content class in the table should be empty. --->
			<cfset thisContentClass = HtmlUtilsObj.getKendoClass('')>
			<!--- Set the colspan property for borders --->
			<cfset thisColSpan = "2">
		  </cfsilent>
				
		  <!-- Border -->
		  <tr height="2px">
			  <td align="left" valign="top" colspan="<cfoutput>#thisColSpan#</cfoutput>" class="<cfoutput>#thisContentClass#</cfoutput>"></td>
		  </tr>
		  <cfsilent>
		  <!--- Set the class for alternating rows. --->
		  <!---After the first row, the content class should be the current class. --->
		  <cfset thisContentClass = HtmlUtilsObj.getKendoClass(thisContentClass)>
		  </cfsilent>
		  <tr height="1px">
			  <td align="left" valign="top" colspan="2" class="<cfoutput>#thisContentClass#</cfoutput>"></td>
		  </tr>
		<cfif session.isMobile>
		  <tr valign="middle">
			<td class="<cfoutput>#thisContentClass#</cfoutput>" colspan="2">
				<label for="logoImage">Desktop Logo:</label>
			</td>
		   </tr>
		   <tr>
			<td class="<cfoutput>#thisContentClass#</cfoutput>" colspan="2">
				<cfoutput>
				<input type="text" id="logoImage" name="logoImage" value="#logoImage#" class="k-textbox" style="width:95%" onclick="createAdminInterfaceWindow(35, #themeId#,'logoImage','#logoImage#');">
				</cfoutput>
			</td>
		  </tr>
		<cfelse><!---<cfif session.isMobile>--->
		  <tr>
			<td align="right" class="<cfoutput>#thisContentClass#</cfoutput>" style="width: 20%"> 
				<label for="logoImage">Desktop Logo:</label>
			</td>
			<td class="<cfoutput>#thisContentClass#</cfoutput>">
				<cfoutput>
				<input type="text" id="logoImage" name="logoImage" value="#logoImage#" class="k-textbox" style="width:75%" onclick="createAdminInterfaceWindow(35, #themeId#,'logoImage','#logoImage#');">
				</cfoutput>
			</td>
		  </tr>
		</cfif>
		  <!-- Border -->
		  <tr height="2px">
			  <td align="left" valign="top" colspan="<cfoutput>#thisColSpan#</cfoutput>" class="<cfoutput>#thisContentClass#</cfoutput>"></td>
		  </tr>
		  <cfsilent>
		  <!--- Set the class for alternating rows. --->
		  <!---After the first row, the content class should be the current class. --->
		  <cfset thisContentClass = HtmlUtilsObj.getKendoClass(thisContentClass)>
		  </cfsilent>
			  
		  <tr height="1px">
			  <td align="left" valign="top" colspan="2" class="<cfoutput>#thisContentClass#</cfoutput>"></td>
		  </tr>
		<cfif session.isMobile>
		  <tr valign="middle">
			<td class="<cfoutput>#thisContentClass#</cfoutput>" colspan="2">
				<label for="logoImageMobile">Mobile Logo:</label>
			</td>
		   </tr>
		   <tr>
			<td class="<cfoutput>#thisContentClass#</cfoutput>" colspan="2">
				<!--- We are passing: 35 as the adminInterfaceId, URL.optArgs is the themeId, URL.otherArgs is the theme image type, and URL.otherArgs1 is the current image being used. --->
				<cfoutput>
				<input type="text" id="logoImageMobile" name="logoImageMobile" value="#logoImageMobile#" class="k-textbox" style="width:95%" onclick="createAdminInterfaceWindow(35, #themeId#,'logoImageMobile','#logoImageMobile#');">
				</cfoutput>
			</td>
		  </tr>
		<cfelse><!---<cfif session.isMobile>--->
		  <tr>
			<td align="right" class="<cfoutput>#thisContentClass#</cfoutput>" style="width: 20%"> 
				<label for="logoImageMobile">Mobile Logo:</label>
			</td>
			<td class="<cfoutput>#thisContentClass#</cfoutput>">
				<!--- We are passing: 35 as the adminInterfaceId, URL.optArgs is the themeId, URL.otherArgs is the theme image type, and URL.otherArgs1 is the current image being used. --->
				<cfoutput>
				<input type="text" id="logoImageMobile" name="logoImageMobile" value="#logoImageMobile#" class="k-textbox" style="width:75%" onclick="createAdminInterfaceWindow(35, #themeId#,'logoImageMobile','#logoImageMobile#');">
				</cfoutput>
			</td>
		  </tr>
		</cfif>	  
		  <!-- Border -->
		  <tr height="2px">
			  <td align="left" valign="top" colspan="<cfoutput>#thisColSpan#</cfoutput>" class="<cfoutput>#thisContentClass#</cfoutput>"></td>
		  </tr>
			  
		  <cfsilent>
		  <!--- Set the class for alternating rows. --->
		  <!---After the first row, the content class should be the current class. --->
		  <cfset thisContentClass = HtmlUtilsObj.getKendoClass(thisContentClass)>
		  </cfsilent>
			  
		  <tr height="1px">
			  <td align="left" valign="top" colspan="2" class="<cfoutput>#thisContentClass#</cfoutput>"></td>
		  </tr>
		  <tr>
			<td align="left" class="<cfoutput>#thisContentClass#</cfoutput>" colspan="2"> 
				What is the default image that you want shared to social media sites when you share a link to the root blog or create a post without a header image? This image should be larger than your site logo and is recommended to be 900x900 or 1200x1200. 
			</td>
		  </tr>
		  <!-- Border -->
		  <tr height="2px">
			  <td align="left" valign="top" colspan="<cfoutput>#thisColSpan#</cfoutput>" class="<cfoutput>#thisContentClass#</cfoutput>"></td>
		  </tr>
		<cfif session.isMobile>
		  <tr valign="middle">
			<td class="<cfoutput>#thisContentClass#</cfoutput>" colspan="2">
				<label for="defaultLogoImageForSocialMediaShare">Default Logo for Social Media:</label>
			</td>
		   </tr>
		   <tr>
			<td class="<cfoutput>#thisContentClass#</cfoutput>" colspan="2">
				<!--- We are passing: 35 as the adminInterfaceId, URL.optArgs is the themeId, URL.otherArgs is the theme image type, and URL.otherArgs1 is the current image being used. --->
				<cfoutput>
				<input type="text" id="defaultLogoImageForSocialMediaShare" name="defaultLogoImageForSocialMediaShare" value="#defaultLogoImageForSocialMediaShare#" class="k-textbox" style="width:95%" onclick="createAdminInterfaceWindow(35, #themeId#,'defaultLogoImageForSocialMediaShare','#defaultLogoImageForSocialMediaShare#');">
				</cfoutput>
			</td>
		  </tr>
		<cfelse><!---<cfif session.isMobile>--->
		  <tr>
			<td align="right" class="<cfoutput>#thisContentClass#</cfoutput>" style="width: 20%"> 
				<label for="defaultLogoImageForSocialMediaShare">Default Logo for Social Media:</label>
			</td>
			<td class="<cfoutput>#thisContentClass#</cfoutput>">
				<!--- We are passing: 35 as the adminInterfaceId, URL.optArgs is the themeId, URL.otherArgs is the theme image type, and URL.otherArgs1 is the current image being used. --->
				<cfoutput>
				<input type="text" id="defaultLogoImageForSocialMediaShare" name="defaultLogoImageForSocialMediaShare" value="#defaultLogoImageForSocialMediaShare#" class="k-textbox" style="width:75%" onclick="createAdminInterfaceWindow(35, #themeId#,'defaultLogoImageForSocialMediaShare','#defaultLogoImageForSocialMediaShare#');">
				</cfoutput>
			</td>
		  </tr>
		</cfif>	  
		  <!-- Border -->
		  <tr height="2px">
			  <td align="left" valign="top" colspan="<cfoutput>#thisColSpan#</cfoutput>" class="<cfoutput>#thisContentClass#</cfoutput>"></td>
		  </tr>
			  
		  <cfsilent>
		  <!--- Set the class for alternating rows. --->
		  <!---After the first row, the content class should be the current class. --->
		  <cfset thisContentClass = HtmlUtilsObj.getKendoClass(thisContentClass)>
		  </cfsilent>
		  <tr height="1px">
			  <td align="left" valign="top" colspan="2" class="<cfoutput>#thisContentClass#</cfoutput>"></td>
		  </tr>
		<cfif session.isMobile>
		  <tr valign="middle">
			<td class="<cfoutput>#thisContentClass#</cfoutput>" colspan="2">
				<label for="logoMobileWidth">Mobile Logo Width:</label>
			</td>
		   </tr>
		   <tr>
			<td class="<cfoutput>#thisContentClass#</cfoutput>" colspan="2">
				<input type="number" id="logoMobileWidth" name="logoMobileWidth" step="1" value="<cfoutput>#logoMobileWidth#</cfoutput>" class="k-textbox" style="width:25%">px
			</td>
		  </tr>
		<cfelse><!---<cfif session.isMobile>--->
		  <tr>
			<td align="right" class="<cfoutput>#thisContentClass#</cfoutput>" style="width: 20%"> 
				<label for="logoMobileWidth">Mobile Logo Width:</label>
			</td>
			<td class="<cfoutput>#thisContentClass#</cfoutput>">
				<input type="number" id="logoMobileWidth" name="logoMobileWidth" step="1" value="<cfoutput>#logoMobileWidth#</cfoutput>" class="k-textbox">px
			</td>
		  </tr>
		</cfif>	  
		  <cfsilent>
		  <!--- Set the class for alternating rows. --->
		  <!---After the first row, the content class should be the current class. --->
		  <cfset thisContentClass = HtmlUtilsObj.getKendoClass(thisContentClass)>
		  </cfsilent>
		  <tr height="1px">
			  <td align="left" valign="top" colspan="2" class="<cfoutput>#thisContentClass#</cfoutput>"></td>
		  </tr>
		<cfif session.isMobile>
		  <tr valign="middle">
			<td class="<cfoutput>#thisContentClass#</cfoutput>" colspan="2">
				<label for="logoPaddingLeft">Logo Padding Left:</label>
			</td>
		   </tr>
		   <tr>
			<td class="<cfoutput>#thisContentClass#</cfoutput>" colspan="2">
				<input type="number" id="logoPaddingLeft" name="logoPaddingLeft" min="0" step="1" value="<cfoutput>#logoPaddingLeft#</cfoutput>" class="k-textbox" style="width:25%">px
			</td>
		  </tr>
		<cfelse><!---<cfif session.isMobile>--->
		  <tr>
			<td align="right" class="<cfoutput>#thisContentClass#</cfoutput>" style="width: 20%"> 
				<label for="logoPaddingLeft">Logo Padding Left:</label>
			</td>
			<td class="<cfoutput>#thisContentClass#</cfoutput>">
				<input type="number" id="logoPaddingLeft" name="logoPaddingLeft" min="0" step="1" value="<cfoutput>#logoPaddingLeft#</cfoutput>" class="k-textbox">px
			</td>
		  </tr>
		</cfif>	  
		  <!-- Border -->
		  <tr height="2px">
			<td align="left" valign="top" colspan="<cfoutput>#thisColSpan#</cfoutput>" class="<cfoutput>#thisContentClass#</cfoutput>"></td>
		  </tr>
			  
		</table>
	</div>
			  
	<!---//***********************************************************************************************
						Backgrounds
	//************************************************************************************************--->
	<button type="button" class="collapsible k-header">Backgrounds</button>
	<div class="content k-content">
		<table align="center" class="k-content" width="100%" cellpadding="2" cellspacing="0">
		  <cfsilent>
			<!---The first content class in the table should be empty. --->
			<cfset thisContentClass = HtmlUtilsObj.getKendoClass('')>
			<!--- Set the colspan property for borders --->
			<cfset thisColSpan = "2">
		  </cfsilent>
				
		  <!-- Border -->
		  <tr height="2px">
			  <td align="left" valign="top" colspan="<cfoutput>#thisColSpan#</cfoutput>" class="<cfoutput>#thisContentClass#</cfoutput>"></td>
		  </tr>
		  <cfsilent>
		  <!--- Set the class for alternating rows. --->
		  <!---After the first row, the content class should be the current class. --->
		  <cfset thisContentClass = HtmlUtilsObj.getKendoClass(thisContentClass)>
		  </cfsilent>
		  <tr height="1px">
			  <td align="left" valign="top" colspan="2" class="<cfoutput>#thisContentClass#</cfoutput>"></td>
		  </tr>
		<cfif session.isMobile>
		  <tr valign="middle">
			<td class="<cfoutput>#thisContentClass#</cfoutput>" colspan="2">
				<label for="includeBackgroundImages">Include Background Images:</label>
			</td>
		   </tr>
		   <tr>
			<td class="<cfoutput>#thisContentClass#</cfoutput>" colspan="2">
				<table align="center" class="<cfoutput>#thisContentClass#</cfoutput>" width="100%" cellpadding="5" cellspacing="0" border="0">
					<tr>
						<td width="50%" align="left">
							<input id="includeBackgroundImages" name="includeBackgroundImages" type="radio" value="true" <cfif includeBackgroundImages gt 0>checked</cfif> class="normalFontWeight" onclick='javascript:$( ".includeBackgroundImages" ).show();$( ".backgroundColor" ).hide();'>
							<label for="includeBackgroundImages">yes</label>
						</td>
						<td width="50%" align="left">
							<input id="includeBackgroundImages" name="includeBackgroundImages" type="radio" value="false" <cfif includeBackgroundImages eq 0>checked</cfif> class="normalFontWeight" onclick='javascript:$( ".includeBackgroundImages" ).hide();$( ".backgroundColor" ).show();'>
							<label for="includeBackgroundImages">No</label>
						</td>
					</tr>
				</table>
			</td>
		  </tr>
		<cfelse><!---<cfif session.isMobile>--->
		  <tr>
			<td align="right" class="<cfoutput>#thisContentClass#</cfoutput>" style="width: 20%"> 
				<label for="includeBackgroundImages">Include Background Images:</label>
			</td>
			<td class="<cfoutput>#thisContentClass#</cfoutput>">
				<table align="center" class="<cfoutput>#thisContentClass#</cfoutput>" width="100%" cellpadding="5" cellspacing="0" border="0">
					<tr>
						<td width="50%" align="left">
							<input id="includeBackgroundImages" name="includeBackgroundImages" type="radio" value="true" <cfif includeBackgroundImages gt 0>checked</cfif> class="normalFontWeight" onclick='javascript:$( ".includeBackgroundImages" ).show();$( ".backgroundColor" ).hide();'>
							<label for="includeBackgroundImages">yes</label>
						</td>
						<td width="50%" align="left">
							<input id="includeBackgroundImages" name="includeBackgroundImages" type="radio" value="false" <cfif includeBackgroundImages eq 0>checked</cfif> class="normalFontWeight" onclick='javascript:$( ".includeBackgroundImages" ).hide();$( ".backgroundColor" ).show();'>
							<label for="includeBackgroundImages">No</label>
						</td>
					</tr>
				</table>
			</td>
		  </tr>
		</cfif>
		  <!-- Border -->
		  <tr height="2px">
			  <td align="left" valign="top" colspan="<cfoutput>#thisColSpan#</cfoutput>" class="<cfoutput>#thisContentClass#</cfoutput>"></td>
		  </tr>
		  <cfsilent>
		  <!--- Set the class for alternating rows. --->
		  <!---After the first row, the content class should be the current class. --->
		  <cfset thisContentClass = HtmlUtilsObj.getKendoClass(thisContentClass)>
		  </cfsilent>
				
		  <!-- Border -->
		  <tr height="2px" class="includeBackgroundImages">
			  <td align="left" valign="top" colspan="<cfoutput>#thisColSpan#</cfoutput>" class="<cfoutput>#thisContentClass#</cfoutput>"></td>
		  </tr>
		<cfif session.isMobile>
		  <tr valign="middle" class="includeBackgroundImages">
			<td class="<cfoutput>#thisContentClass#</cfoutput>" colspan="2">
				<label for="blogBackgroundImage">Desktop Background:</label>
			</td>
		   </tr>
		   <tr class="includeBackgroundImages">
			<td class="<cfoutput>#thisContentClass#</cfoutput>" colspan="2">
				<cfoutput>
				<input type="text" id="blogBackgroundImage" name="blogBackgroundImage" value="#blogBackgroundImage#" class="k-textbox" style="width:95%" onclick="createAdminInterfaceWindow(35, #themeId#,'blogBackgroundImage','#blogBackgroundImage#');">
				</cfoutput>
			</td>
		  </tr>
		<cfelse><!---<cfif session.isMobile>--->
		  <tr class="includeBackgroundImages">
			<td align="right" class="<cfoutput>#thisContentClass#</cfoutput>" style="width: 20%"> 
				<label for="blogBackgroundImage">Desktop Background:</label>
			</td>
			<td class="<cfoutput>#thisContentClass#</cfoutput>">
				<cfoutput>
				<input type="text" id="blogBackgroundImage" name="blogBackgroundImage" value="#blogBackgroundImage#" class="k-textbox" style="width:75%" onclick="createAdminInterfaceWindow(35, #themeId#,'blogBackgroundImage','#blogBackgroundImage#');">
				</cfoutput>
			</td>
		  </tr>
		</cfif>
		  <!-- Border -->
		  <tr height="2px" class="includeBackgroundImages">
			  <td align="left" valign="top" colspan="<cfoutput>#thisColSpan#</cfoutput>" class="<cfoutput>#thisContentClass#</cfoutput>"></td>
		  </tr>
		  <cfsilent>
		  <!--- Set the class for alternating rows. --->
		  <!---After the first row, the content class should be the current class. --->
		  <cfset thisContentClass = HtmlUtilsObj.getKendoClass(thisContentClass)>
		  </cfsilent>
			  
		  <tr height="1px" class="includeBackgroundImages">
			  <td align="left" valign="top" colspan="2" class="<cfoutput>#thisContentClass#</cfoutput>"></td>
		  </tr>
		<cfif session.isMobile>
		  <tr valign="middle" class="includeBackgroundImages">
			<td class="<cfoutput>#thisContentClass#</cfoutput>" colspan="2">
				<label for="blogBackgroundImageMobile">Mobile Blog Background:</label>
			</td>
		   </tr>
		   <tr class="includeBackgroundImages">
			<td class="<cfoutput>#thisContentClass#</cfoutput>" colspan="2">
				<!--- We are passing: 35 as the adminInterfaceId, URL.optArgs is the themeId, URL.otherArgs is the theme image type, and URL.otherArgs1 is the current image being used. --->
				<cfoutput>
				<input type="text" id="blogBackgroundImageMobile" name="blogBackgroundImageMobile" value="#blogBackgroundImageMobile#" class="k-textbox" style="width:95%" onclick="createAdminInterfaceWindow(35, #themeId#,'blogBackgroundImageMobile','#blogBackgroundImageMobile#');">
				</cfoutput>
			</td>
		  </tr>
		<cfelse><!---<cfif session.isMobile>--->
		  <tr class="includeBackgroundImages">
			<td align="right" class="<cfoutput>#thisContentClass#</cfoutput>" style="width: 20%"> 
				<label for="blogBackgroundImageMobile">Mobile Blog Background:</label>
			</td>
			<td class="<cfoutput>#thisContentClass#</cfoutput>">
				<!--- We are passing: 35 as the adminInterfaceId, URL.optArgs is the themeId, URL.otherArgs is the theme image type, and URL.otherArgs1 is the current image being used. --->
				<cfoutput>
				<input type="text" id="blogBackgroundImageMobile" name="blogBackgroundImageMobile" value="#blogBackgroundImageMobile#" class="k-textbox" style="width:75%" onclick="createAdminInterfaceWindow(35, #themeId#,'blogBackgroundImageMobile','#blogBackgroundImageMobile#');">
				</cfoutput>
			</td>
		  </tr>
		</cfif>	  
		  <!-- Border -->
		  <tr height="2px" class="includeBackgroundImages">
			  <td align="left" valign="top" colspan="<cfoutput>#thisColSpan#</cfoutput>" class="<cfoutput>#thisContentClass#</cfoutput>"></td>
		  </tr>
		  <cfsilent>
		  <!--- Set the class for alternating rows. --->
		  <!---After the first row, the content class should be the current class. --->
		  <cfset thisContentClass = HtmlUtilsObj.getKendoClass(thisContentClass)>
		  </cfsilent>
		  <tr height="1px" class="includeBackgroundImages">
			  <td align="left" valign="top" colspan="2" class="<cfoutput>#thisContentClass#</cfoutput>"></td>
		  </tr>
		  <tr class="includeBackgroundImages">
			<td align="left" class="<cfoutput>#thisContentClass#</cfoutput>" colspan="2"> 
				The blog background position must contain css to position the background image on the page. This is useful if you want to nudge the image around page. See <a href="https://www.w3schools.com/cssref/pr_background-position.asp">https://www.w3schools.com/cssref/pr_background-position.asp</a> or search for the background-position css property for more information.
			</td>
		  </tr>
		<cfif session.isMobile>
		  <tr valign="middle" class="includeBackgroundImages">
			<td class="<cfoutput>#thisContentClass#</cfoutput>" colspan="2">
				<label for="BlogBackgroundImagePosition">Blog Background Position:</label>
			</td>
		   </tr>
		   <tr class="includeBackgroundImages">
			<td class="<cfoutput>#thisContentClass#</cfoutput>" colspan="2">
				<input type="text" id="BlogBackgroundImagePosition" name="BlogBackgroundImagePosition" value="<cfoutput>#BlogBackgroundImagePosition#</cfoutput>" class="k-textbox">
			</td>
		  </tr>
		<cfelse><!---<cfif session.isMobile>--->
		  <tr class="includeBackgroundImages">
			<td align="right" class="<cfoutput>#thisContentClass#</cfoutput>" style="width: 20%"> 
				<label for="BlogBackgroundImagePosition">Blog Background Position:</label>
			</td>
			<td class="<cfoutput>#thisContentClass#</cfoutput>">
				<input type="text" id="BlogBackgroundImagePosition" name="BlogBackgroundImagePosition" value="<cfoutput>#BlogBackgroundImagePosition#</cfoutput>" class="k-textbox">
			</td>
		  </tr>
		</cfif>	  
		  <cfsilent>
		  <!--- Set the class for alternating rows. --->
		  <!---After the first row, the content class should be the current class. --->
		  <cfset thisContentClass = HtmlUtilsObj.getKendoClass(thisContentClass)>
		  </cfsilent>
		  <tr height="1px" class="includeBackgroundImages">
			  <td align="left" valign="top" colspan="2" class="<cfoutput>#thisContentClass#</cfoutput>"></td>
		  </tr>
		  <tr class="includeBackgroundImages">
			<td align="left" class="<cfoutput>#thisContentClass#</cfoutput>" colspan="2"> 
				The blog background image repeat must contain css determine how a small background image will be repeated if can't fit the dimensions of the page. You can create interesting checkered tile designs that consume very little resources. See <a href="https://www.w3schools.com/cssref/pr_background-repeat.asp">https://www.w3schools.com/cssref/pr_background-repeat.asp</a> or search the web for the background-repeat css property. Unless you're after a tile based design, its suggested to leave this setting at 'no-repeat'. 
			</td>
		  </tr>
		<cfif session.isMobile>
		  <tr valign="middle" class="includeBackgroundImages">
			<td class="<cfoutput>#thisContentClass#</cfoutput>" colspan="2">
				<label for="BlogBackgroundImageRepeat">Blog Background Image Repeat:</label>
			</td>
		   </tr>
		   <tr class="includeBackgroundImages">
			<td class="<cfoutput>#thisContentClass#</cfoutput>" colspan="2">
				<input type="text" id="BlogBackgroundImageRepeat" name="BlogBackgroundImageRepeat" value="<cfoutput>#BlogBackgroundImageRepeat#</cfoutput>" class="k-textbox" style="width:95%">
			</td>
		  </tr>
		<cfelse><!---<cfif session.isMobile>--->
		  <tr class="includeBackgroundImages">
			<td align="right" class="<cfoutput>#thisContentClass#</cfoutput>" style="width: 20%"> 
				<label for="BlogBackgroundImageRepeat">Blog Background Image Repeat:</label>
			</td>
			<td class="<cfoutput>#thisContentClass#</cfoutput>">
				<input type="text" id="BlogBackgroundImageRepeat" name="BlogBackgroundImageRepeat" value="<cfoutput>#BlogBackgroundImageRepeat#</cfoutput>" class="k-textbox">
			</td>
		  </tr>
		</cfif>  
		  <!-- Border -->
		  <tr height="2px" class="includeBackgroundImages">
			<td align="left" valign="top" colspan="<cfoutput>#thisColSpan#</cfoutput>" class="<cfoutput>#thisContentClass#</cfoutput>"></td>
		  </tr>
			  
		  <cfsilent>
		  <!--- Set the class for alternating rows. --->
		  <!---After the first row, the content class should be the current class. --->
		  <cfset thisContentClass = HtmlUtilsObj.getKendoClass(thisContentClass)>
		  </cfsilent>
		  <tr height="1px" class="backgroundColor">
			  <td align="left" valign="top" colspan="2" class="<cfoutput>#thisContentClass#</cfoutput>"></td>
		  </tr>
		  <tr class="backgroundColor">
			<td colspan="2" class="<cfoutput>#thisContentClass#</cfoutput>"> 
				If you don't want to have a blog background, you can have a simple blog background color. 
			</td>
		  </tr>
			  
		  <!-- Border -->
		  <tr height="2px" class="backgroundColor">
			<td align="left" valign="top" colspan="<cfoutput>#thisColSpan#</cfoutput>" class="<cfoutput>#thisContentClass#</cfoutput>"></td>
		  </tr>
		  <tr height="1px" class="backgroundColor">
			  <td align="left" valign="top" colspan="2" class="<cfoutput>#thisContentClass#</cfoutput>"></td>
		  </tr>
		<cfif session.isMobile>
		  <tr valign="middle" class="backgroundColor">
			<td class="<cfoutput>#thisContentClass#</cfoutput>" colspan="2">
				<label for="blogBackgroundColor">Blog Background Color:</label>
			</td>
		   </tr>
		   <tr class="backgroundColor">
			<td class="<cfoutput>#thisContentClass#</cfoutput>" colspan="2">
				<input id="blogBackgroundColor" name="blogBackgroundColor" value="<cfoutput>#blogBackgroundColor#</cfoutput>">
			</td>
		  </tr>
		<cfelse><!---<cfif session.isMobile>--->
		  <tr class="backgroundColor">
			<td align="right" class="<cfoutput>#thisContentClass#</cfoutput>" style="width: 20%"> 
				<label for="blogBackgroundColor">Blog Background Color:</label>
			</td>
			<td class="<cfoutput>#thisContentClass#</cfoutput>">
				<input id="blogBackgroundColor" name="blogBackgroundColor" value="<cfoutput>#blogBackgroundColor#</cfoutput>">
			</td>
		  </tr>
		</cfif>	  
		  <!-- Border -->
		  <tr height="2px">
			<td align="left" valign="top" colspan="<cfoutput>#thisColSpan#</cfoutput>" class="<cfoutput>#thisContentClass#</cfoutput>"></td>
		  </tr>
		</table>
	</div>
			  
	<!---//***********************************************************************************************
						Blog Title
	//************************************************************************************************--->
				
	<button type="button" class="collapsible k-header">Blog Title</button>
	<div class="content k-content">
		<table align="center" class="k-content" width="100%" cellpadding="2" cellspacing="0">
		  <cfsilent>
			<!---The first content class in the table should be empty. --->
			<cfset thisContentClass = HtmlUtilsObj.getKendoClass('')>
			<!--- Set the colspan property for borders --->
			<cfset thisColSpan = "2">
		  </cfsilent>
				
		  <!-- Border -->
		  <tr height="2px">
			  <td align="left" valign="top" colspan="<cfoutput>#thisColSpan#</cfoutput>" class="<cfoutput>#thisContentClass#</cfoutput>"></td>
		  </tr>
		  <cfsilent>
		  <!--- Set the class for alternating rows. --->
		  <!---After the first row, the content class should be the current class. --->
		  <cfset thisContentClass = HtmlUtilsObj.getKendoClass(thisContentClass)>
		  </cfsilent>
		  <tr height="1px">
			  <td align="left" valign="top" colspan="2" class="<cfoutput>#thisContentClass#</cfoutput>"></td>
		  </tr>
		<cfif session.isMobile>
		  <tr valign="middle">
			<td class="<cfoutput>#thisContentClass#</cfoutput>" colspan="2">
				<label for="blogNameTextColor">Blog Title Text Color:</label>
			</td>
		   </tr>
		   <tr>
			<td class="<cfoutput>#thisContentClass#</cfoutput>" colspan="2">
				<cfoutput>
				<input id="blogNameTextColor" name="blogNameTextColor" value="#blogNameTextColor#">
				</cfoutput>
			</td>
		  </tr>
		<cfelse><!---<cfif session.isMobile>--->
		  <tr>
			<td align="right" class="<cfoutput>#thisContentClass#</cfoutput>" style="width: 20%"> 
				<label for="blogNameTextColor">Blog Title Text Color:</label>
			</td>
			<td class="<cfoutput>#thisContentClass#</cfoutput>">
				<cfoutput>
				<input id="blogNameTextColor" name="blogNameTextColor" value="#blogNameTextColor#">
				</cfoutput>
			</td>
		  </tr>
		</cfif>
		  <!-- Border -->
		  <tr height="2px">
			  <td align="left" valign="top" colspan="<cfoutput>#thisColSpan#</cfoutput>" class="<cfoutput>#thisContentClass#</cfoutput>"></td>
		  </tr>
			  
		</table>
	</div>
			  
	<!---//***********************************************************************************************
						Header
	//************************************************************************************************--->
				
	<button type="button" class="collapsible k-header">Header</button>
	<div class="content k-content">
		<table align="center" class="k-content" width="100%" cellpadding="2" cellspacing="0">
		  <cfsilent>
			<!---The first content class in the table should be empty. --->
			<cfset thisContentClass = HtmlUtilsObj.getKendoClass('')>
			<!--- Set the colspan property for borders --->
			<cfset thisColSpan = "2">
		  </cfsilent>
				
		  <!-- Border -->
		  <tr height="2px">
			  <td align="left" valign="top" colspan="<cfoutput>#thisColSpan#</cfoutput>" class="<cfoutput>#thisContentClass#</cfoutput>"></td>
		  </tr>
		  <cfsilent>
		  <!--- Set the class for alternating rows. --->
		  <!---After the first row, the content class should be the current class. --->
		  <cfset thisContentClass = HtmlUtilsObj.getKendoClass(thisContentClass)>
		  </cfsilent>
			  
		 <tr height="1px">
			  <td align="left" valign="top" colspan="2" class="<cfoutput>#thisContentClass#</cfoutput>"></td>
		  </tr>
		  <tr>
			<td colspan="2"> 
				* Note: the Header Background Color is used to cover a portion of the header image when sending out email. It allows for the top portion of the page to be match the webpage and be highlighted with the logo.
			</td>
		  </tr>
		  <tr height="1px">
			  <td align="left" valign="top" colspan="2" class="<cfoutput>#thisContentClass#</cfoutput>"></td>
		  </tr>
		<cfif session.isMobile>
		  <tr valign="middle">
			<td class="<cfoutput>#thisContentClass#</cfoutput>" colspan="2">
				<label for="headerBackgroundColor">Header Background Color:</label>
			</td>
		   </tr>
		   <tr>
			<td class="<cfoutput>#thisContentClass#</cfoutput>" colspan="2">
				<input id="headerBackgroundColor" name="headerBackgroundColor">
			</td>
		  </tr>
		<cfelse><!---<cfif session.isMobile>--->
		  <tr>
			<td align="right" class="<cfoutput>#thisContentClass#</cfoutput>" style="width: 20%"> 
				<label for="headerBackgroundColor">Header Background Color:</label>
			</td>
			<td class="<cfoutput>#thisContentClass#</cfoutput>">
				<input id="headerBackgroundColor" name="headerBackgroundColor">
			</td>
		  </tr>
		</cfif>
				
		  <!-- Border -->
		  <tr height="2px">
			  <td align="left" valign="top" colspan="<cfoutput>#thisColSpan#</cfoutput>" class="<cfoutput>#thisContentClass#</cfoutput>"></td>
		  </tr>
		  <cfsilent>
		  <!--- Set the class for alternating rows. --->
		  <!---After the first row, the content class should be the current class. --->
		  <cfset thisContentClass = HtmlUtilsObj.getKendoClass(thisContentClass)>
		  </cfsilent>
		  <tr height="1px">
			  <td align="left" valign="top" colspan="2" class="<cfoutput>#thisContentClass#</cfoutput>"></td>
		  </tr>
		  <tr>
			<td colspan="2"> 
				The Header Background Image is at the top of the page and it covers the menu items. <i>If there is ghosting</i> on the menu after changing this, make sure to use the same image here as the Menu Background Image found in the Menu section below. This ghosting will only occur with headers that contain a gradient.
			</td>
		  </tr>
		  <tr height="1px">
			  <td align="left" valign="top" colspan="2" class="<cfoutput>#thisContentClass#</cfoutput>"></td>
		  </tr>
		<cfif session.isMobile>
		  <tr valign="middle">
			<td class="<cfoutput>#thisContentClass#</cfoutput>" colspan="2">
				<label for="headerBackgroundImage">Header Background Image:</label>
			</td>
		   </tr>
		   <tr>
			<td class="<cfoutput>#thisContentClass#</cfoutput>" colspan="2">
				<cfoutput>
				<input type="text" id="headerBackgroundImage" name="headerBackgroundImage" value="#headerBackgroundImage#" class="k-textbox" style="width:95%" onclick="createAdminInterfaceWindow(35, #themeId#,'headerBackgroundImage','#headerBackgroundImage#');">
				</cfoutput>
			</td>
		  </tr>
		<cfelse><!---<cfif session.isMobile>--->
		  <tr>
			<td align="right" class="<cfoutput>#thisContentClass#</cfoutput>" style="width: 20%"> 
				<label for="headerBackgroundImage">Header Background Image:</label>
			</td>
			<td class="<cfoutput>#thisContentClass#</cfoutput>">
				<cfoutput>
				<input type="text" id="headerBackgroundImage" name="headerBackgroundImage" value="#headerBackgroundImage#" class="k-textbox" style="width:95%" onclick="createAdminInterfaceWindow(35, #themeId#,'headerBackgroundImage','#headerBackgroundImage#');">
				</cfoutput>
			</td>
		  </tr>
		</cfif>
		  <!-- Border -->
		  <tr height="2px">
			  <td align="left" valign="top" colspan="<cfoutput>#thisColSpan#</cfoutput>" class="<cfoutput>#thisContentClass#</cfoutput>"></td>
		  </tr>
			  
		  <cfsilent>
		  <!--- Set the class for alternating rows. --->
		  <!---After the first row, the content class should be the current class. --->
		  <cfset thisContentClass = HtmlUtilsObj.getKendoClass(thisContentClass)>
		  </cfsilent>
		  <tr height="1px">
			  <td align="left" valign="top" colspan="2" class="<cfoutput>#thisContentClass#</cfoutput>"></td>
		  </tr>
		<cfif session.isMobile>
		  <tr valign="middle">
			<td class="<cfoutput>#thisContentClass#</cfoutput>" colspan="2">
				<label for="headerBodyDividerImage">Header Background Divider Image:</label>
			</td>
		   </tr>
		   <tr>
			<td class="<cfoutput>#thisContentClass#</cfoutput>" colspan="2">
				<cfoutput>
				<input type="text" id="headerBodyDividerImage" name="headerBodyDividerImage" value="#headerBodyDividerImage#" class="k-textbox" style="width:95%" onclick="createAdminInterfaceWindow(35, #themeId#,'headerBodyDividerImage','#headerBodyDividerImage#');">
				</cfoutput>
			</td>
		  </tr>
		<cfelse><!---<cfif session.isMobile>--->
		  <tr>
			<td align="right" class="<cfoutput>#thisContentClass#</cfoutput>" style="width: 20%"> 
				<label for="headerBodyDividerImage">Header Background Divider Image:</label>
			</td>
			<td class="<cfoutput>#thisContentClass#</cfoutput>">
				<cfoutput>
				<input type="text" id="headerBodyDividerImage" name="headerBodyDividerImage" value="#headerBodyDividerImage#" class="k-textbox" style="width:75%" onclick="createAdminInterfaceWindow(35, #themeId#,'headerBodyDividerImage','#headerBodyDividerImage#');">
				</cfoutput>
			</td>
		  </tr>
		</cfif>
		  <!-- Border -->
		  <tr height="2px">
			  <td align="left" valign="top" colspan="<cfoutput>#thisColSpan#</cfoutput>" class="<cfoutput>#thisContentClass#</cfoutput>"></td>
		  </tr>
			  
		  <tr height="1px">
			  <td align="left" valign="top" colspan="2" class="<cfoutput>#thisContentClass#</cfoutput>"></td>
		  </tr>
		<cfif session.isMobile>
		  <tr valign="middle">
			<td class="<cfoutput>#thisContentClass#</cfoutput>" colspan="2">
				<label for="stretchHeaderAcrossPage">Stretch Header Across Page:</label>
			</td>
		   </tr>
		   <tr>
			<td class="<cfoutput>#thisContentClass#</cfoutput>" colspan="2">
				<input type="checkbox" id="stretchHeaderAcrossPage" name="stretchHeaderAcrossPage" value="1"  <cfif stretchHeaderAcrossPage> checked</cfif>>
			</td>
		  </tr>
		<cfelse><!---<cfif session.isMobile>--->
		  <tr>
			<td align="right" class="<cfoutput>#thisContentClass#</cfoutput>" style="width: 20%"> 
				<label for="stretchHeaderAcrossPage">Stretch Header Across Page:</label>
			</td>
			<td class="<cfoutput>#thisContentClass#</cfoutput>">
				<input type="checkbox" id="stretchHeaderAcrossPage" name="stretchHeaderAcrossPage" value="1"  <cfif stretchHeaderAcrossPage> checked</cfif>>
			</td>
		  </tr>
		</cfif>  
		</table>
	</div>
			  
	<!---//***********************************************************************************************
						Menu's
	//************************************************************************************************--->
				
	<button type="button" class="collapsible k-header">Menu's</button>
	<div class="content k-content">
		<table align="center" class="k-content" width="100%" cellpadding="2" cellspacing="0">
		  <cfsilent>
			<!---The first content class in the table should be empty. --->
			<cfset thisContentClass = HtmlUtilsObj.getKendoClass('')>
			<!--- Set the colspan property for borders --->
			<cfset thisColSpan = "2">
		  </cfsilent>
				
		  <!-- Border -->
		  <tr height="2px">
			  <td align="left" valign="top" colspan="<cfoutput>#thisColSpan#</cfoutput>" class="<cfoutput>#thisContentClass#</cfoutput>"></td>
		  </tr>
		  <cfsilent>
		  <!--- Set the class for alternating rows. --->
		  <!---After the first row, the content class should be the current class. --->
		  <cfset thisContentClass = HtmlUtilsObj.getKendoClass(thisContentClass)>
		  </cfsilent>
		  <tr height="1px">
			  <td align="left" valign="top" colspan="2" class="<cfoutput>#thisContentClass#</cfoutput>"></td>
		  </tr>
		<cfif session.isMobile>
		  <tr valign="middle">
			<td class="<cfoutput>#thisContentClass#</cfoutput>" colspan="2">
				<label for="alignBlogMenuWithBlogContent">Align Menu with Blog Content:</label>
			</td>
		   </tr>
		   <tr>
			<td class="<cfoutput>#thisContentClass#</cfoutput>" colspan="2">
				<input type="checkbox" id="alignBlogMenuWithBlogContent" name="alignBlogMenuWithBlogContent" value="1"  <cfif alignBlogMenuWithBlogContent> checked</cfif>>
			</td>
		  </tr>
		<cfelse><!---<cfif session.isMobile>--->
		  <tr>
			<td align="right" class="<cfoutput>#thisContentClass#</cfoutput>" style="width: 20%"> 
				<label for="alignBlogMenuWithBlogContent">Align Menu with Blog Content:</label>
			</td>
			<td class="<cfoutput>#thisContentClass#</cfoutput>">
				<input type="checkbox" id="alignBlogMenuWithBlogContent" name="alignBlogMenuWithBlogContent" value="1"  <cfif alignBlogMenuWithBlogContent> checked</cfif>>
			</td>
		  </tr>
		</cfif>
		  <!-- Border -->
		  <tr height="2px">
			  <td align="left" valign="top" colspan="<cfoutput>#thisColSpan#</cfoutput>" class="<cfoutput>#thisContentClass#</cfoutput>"></td>
		  </tr>
		  <cfsilent>
		  <!--- Set the class for alternating rows. --->
		  <!---After the first row, the content class should be the current class. --->
		  <cfset thisContentClass = HtmlUtilsObj.getKendoClass(thisContentClass)>
		  </cfsilent>
			  
		 <tr height="1px">
			  <td align="left" valign="top" colspan="2" class="<cfoutput>#thisContentClass#</cfoutput>"></td>
		  </tr>
		  <tr>
			<td colspan="2"> 
				* The Menu Background Image is used to cover a portion of the header image when there is ghosting that occurs after changing the Header Background Image. This is generally not used unless there is a gradient on the header. It is advises to use the same image that you used for the menu backgound image to remove the ghosting.
			</td>
		  </tr>
		  <tr height="1px">
			  <td align="left" valign="top" colspan="2" class="<cfoutput>#thisContentClass#</cfoutput>"></td>
		  </tr>
		<cfif session.isMobile>
		  <tr valign="middle">
			<td class="<cfoutput>#thisContentClass#</cfoutput>" colspan="2">
				<label for="headerBackgroundImage">Menu Background Image:</label>
			</td>
		   </tr>
		   <tr>
			<td class="<cfoutput>#thisContentClass#</cfoutput>" colspan="2">
				<cfoutput>
				<input type="text" id="headerBackgroundImage" name="menuBackgroundImage" value="#menuBackgroundImage#" class="k-textbox" style="width:95%" onclick="createAdminInterfaceWindow(35, #themeId#,'menuBackgroundImage','#menuBackgroundImage#');">
				</cfoutput>
			</td>
		  </tr>
		<cfelse><!---<cfif session.isMobile>--->
		  <tr>
			<td align="right" class="<cfoutput>#thisContentClass#</cfoutput>" style="width: 20%"> 
				<label for="headerBackgroundImage">Menu Background Image:</label>
			</td>
			<td class="<cfoutput>#thisContentClass#</cfoutput>">
				<cfoutput>
				<input type="text" id="headerBackgroundImage" name="menuBackgroundImage" value="#menuBackgroundImage#" class="k-textbox" style="width:75%" onclick="createAdminInterfaceWindow(35, #themeId#,'menuBackgroundImage','#menuBackgroundImage#');">
				</cfoutput>
			</td>
		  </tr>
		</cfif>
		  <!-- Border -->
		  <tr height="2px">
			  <td align="left" valign="top" colspan="<cfoutput>#thisColSpan#</cfoutput>" class="<cfoutput>#thisContentClass#</cfoutput>"></td>
		  </tr>
			  
		  <cfsilent>
		  <!--- Set the class for alternating rows. --->
		  <!---After the first row, the content class should be the current class. --->
		  <cfset thisContentClass = HtmlUtilsObj.getKendoClass(thisContentClass)>
		  </cfsilent>
			  
		  <tr height="1px">
			  <td align="left" valign="top" colspan="2" class="<cfoutput>#thisContentClass#</cfoutput>"></td>
		  </tr>
		<cfif session.isMobile>
		  <tr valign="middle">
			<td class="<cfoutput>#thisContentClass#</cfoutput>" colspan="2">
				<label for="coverKendoMenuWithMenuBackgroundImage">Cover Menu with Background Image:</label>
			</td>
		   </tr>
		   <tr>
			<td class="<cfoutput>#thisContentClass#</cfoutput>" colspan="2">
				<input type="checkbox" id="coverKendoMenuWithMenuBackgroundImage" name="coverKendoMenuWithMenuBackgroundImage" value="1"  <cfif coverKendoMenuWithMenuBackgroundImage> checked</cfif>>
			</td>
		  </tr>
		<cfelse><!---<cfif session.isMobile>--->
		  <tr>
			<td align="right" class="<cfoutput>#thisContentClass#</cfoutput>" style="width: 20%"> 
				<label for="coverKendoMenuWithMenuBackgroundImage">Cover Menu with Background Image:</label>
			</td>
			<td class="<cfoutput>#thisContentClass#</cfoutput>">
				<input type="checkbox" id="coverKendoMenuWithMenuBackgroundImage" name="coverKendoMenuWithMenuBackgroundImage" value="1"  <cfif coverKendoMenuWithMenuBackgroundImage> checked</cfif>>
			</td>
		  </tr>
		</cfif>  
		  <!-- Border -->
		  <tr height="2px">
			  <td align="left" valign="top" colspan="<cfoutput>#thisColSpan#</cfoutput>" class="<cfoutput>#thisContentClass#</cfoutput>"></td>
		  </tr>
		  <cfsilent>
		  <!--- Set the class for alternating rows. --->
		  <!---After the first row, the content class should be the current class. --->
		  <cfset thisContentClass = HtmlUtilsObj.getKendoClass(thisContentClass)>
		  </cfsilent>
		  <tr height="1px">
			  <td align="left" valign="top" colspan="2" class="<cfoutput>#thisContentClass#</cfoutput>"></td>
		  </tr>
		<cfif session.isMobile>
		  <tr valign="middle">
			<td class="<cfoutput>#thisContentClass#</cfoutput>" colspan="2">
				<label for="topMenuAlign">Top Menu Align:</label>
			</td>
		   </tr>
		   <tr>
			<td class="<cfoutput>#thisContentClass#</cfoutput>" colspan="2">
				<script>
					// create DropDownList from select HTML element
					$("#topMenuAlign").kendoDropDownList();
				</script>
				<select name="topMenuAlign" id="topMenuAlign">
					<option value="left"<cfif topMenuAlign eq 'left'> selected</cfif>>Left</option>
					<option value="center"<cfif topMenuAlign eq 'center'> selected</cfif>>Center</option>
					<option value="right"<cfif topMenuAlign eq 'right'> selected</cfif>>Right</option>
				</select>
			</td>
		  </tr>
		<cfelse><!---<cfif session.isMobile>--->
		  <tr>
			<td align="right" class="<cfoutput>#thisContentClass#</cfoutput>" style="width: 20%"> 
				<label for="topMenuAlign">Top Menu Align:</label>
			</td>
			<td class="<cfoutput>#thisContentClass#</cfoutput>">
				<script>
					// create DropDownList from select HTML element
					$("#topMenuAlign").kendoDropDownList();
				</script>
				<select name="topMenuAlign" id="topMenuAlign">
					<option value="left"<cfif topMenuAlign eq 'left'> selected</cfif>>Left</option>
					<option value="center"<cfif topMenuAlign eq 'center'> selected</cfif>>Center</option>
					<option value="right"<cfif topMenuAlign eq 'right'> selected</cfif>>Right</option>
				</select>
			</td>
		  </tr>
		</cfif>	  
		  <!-- Border -->
		  <tr height="2px">
			<td align="left" valign="top" colspan="<cfoutput>#thisColSpan#</cfoutput>" class="<cfoutput>#thisContentClass#</cfoutput>"></td>
		  </tr>
			  
		</table>
	</div>
	<!---//***********************************************************************************************
						Footer
	//************************************************************************************************--->
				
	<button type="button" class="collapsible k-header">Footer</button>
	<div class="content k-content">
		<table align="center" class="k-content" width="100%" cellpadding="2" cellspacing="0">
		  <cfsilent>
			<!---The first content class in the table should be empty. --->
			<cfset thisContentClass = HtmlUtilsObj.getKendoClass('')>
			<!--- Set the colspan property for borders --->
			<cfset thisColSpan = "2">
		  </cfsilent>
				
		  <!-- Border -->
		  <tr height="2px">
			  <td align="left" valign="top" colspan="<cfoutput>#thisColSpan#</cfoutput>" class="<cfoutput>#thisContentClass#</cfoutput>"></td>
		  </tr>
		  <cfsilent>
		  <!--- Set the class for alternating rows. --->
		  <!---After the first row, the content class should be the current class. --->
		  <cfset thisContentClass = HtmlUtilsObj.getKendoClass(thisContentClass)>
		  </cfsilent>
		  <tr height="1px">
			  <td align="left" valign="top" colspan="2" class="<cfoutput>#thisContentClass#</cfoutput>"></td>
		  </tr>
		<cfif session.isMobile>
		  <tr valign="middle">
			<td class="<cfoutput>#thisContentClass#</cfoutput>" colspan="2">
				<label for="footerImage">Footer Logo:</label>
			</td>
		   </tr>
		   <tr>
			<td class="<cfoutput>#thisContentClass#</cfoutput>" colspan="2">
				<cfoutput>
				<input type="text" id="footerImage" name="footerImage" value="#footerImage#" class="k-textbox" style="width:75%" onclick="createAdminInterfaceWindow(35, #themeId#,'footerImage','#footerImage#');">
				</cfoutput>
			</td>
		  </tr>
		<cfelse><!---<cfif session.isMobile>--->
		  <tr>
			<td align="right" class="<cfoutput>#thisContentClass#</cfoutput>" style="width: 20%"> 
				<label for="footerImage">Footer Logo:</label>
			</td>
			<td class="<cfoutput>#thisContentClass#</cfoutput>">
				<cfoutput>
				<input type="text" id="footerImage" name="footerImage" value="#footerImage#" class="k-textbox" style="width:75%" onclick="createAdminInterfaceWindow(35, #themeId#,'footerImage','#footerImage#');">
				</cfoutput>
			</td>
		  </tr>
		</cfif>
		  <!-- Border -->
		  <tr height="2px">
			  <td align="left" valign="top" colspan="<cfoutput>#thisColSpan#</cfoutput>" class="<cfoutput>#thisContentClass#</cfoutput>"></td>
		  </tr>
			  
		</table>
	</div>
	<br/><br/>
	<button id="themeSubmit" name="themeSubmit" class="k-button k-primary" type="button">Submit</button> 
			  
	<!--- Put some space at the end of the window --->
	<br/><br/><br/>
			  
	</form>
				
</cfcase>
				
<!--- //************************************************************************************************
		Font Uploader
//**************************************************************************************************--->
			
<cfcase value="31">
	<cfsilent>
	<!--- Set the uppy theme. --->
	<cfif darkTheme>
		<cfset uppyTheme = 'dark'>
	<cfelse>
		<cfset uppyTheme = 'light'>
	</cfif>
		
	<!--- Not used yet- Get the kendo primay button color in order to reset the uppy actionBtn--upload color --->
	<cfset primaryButtonColor = application.blog.getPrimaryColorsByTheme(kendoTheme:kendoTheme,setting:'accentColor')>
	<!--- Set the selectorId so that we know what interface this request is coming from --->
	<cfset selectorId = "font">
	</cfsilent>
	<!---<cfoutput>primaryButtonColor: #primaryButtonColor#</cfoutput>--->
	<input type="hidden" name="fontIdList" id="fontIdList" value=""/>
	<p>You may upload woff2 fonts to the server.</p>
	<p>Due to the encrypted nature and the high size of the .ttf and .otf fonts, we are not supporting uploads of these files at this time. In an upcoming version, we will be supporting more font types. If you must use another font, such as a .ttf or an .otf file, please upload these fonts manually to the /common/fonts/ folder and manually create the CSS rules in the /includes/templates/font.cfm template.</p> 
    <div id="fontUppyUpload"></div>
    <script>
		var uppy = Uppy.Core({
			restrictions : {
				maxNumberOfFiles: 36,  // limit 36 files
				allowedFileTypes: ['.woff2','.woff'] // only allow web fonts
        	}
		})
		.use(Uppy.Dashboard, {
			theme: '<cfoutput>#uppyTheme#</cfoutput>',
			inline: true,
			target: '#fontUppyUpload',
			proudlyDisplayPoweredByUppy: false
		})
		
		// Use XHR and send the media to the server for processing
		.use(Uppy.XHRUpload, { endpoint: '<cfoutput>#application.baseUrl#</cfoutput>/common/cfc/ProxyController.cfc?method=uploadFont&csrfToken=<cfoutput>#csrfToken#</cfoutput>' })
		.on('upload-success', (file, response) => {
			// The server is returning location and mediaId in a json object. We need to extract these.
			//alert(response.status) // HTTP status code
			//alert(response.body.location) // The full path of the file that was just uploaded to the server
			//alert(response.body.mediaId) // The MediaId value saved to the Media table in the database.
			
			// Dump in the font Id's to the hidden fontId list and separate the values with underscores. We will use a listGetAt function on the back end to extract the Id's
			// If there are any fontIds in the form, separtate the new Id with an underscore.
			fontIdList = $("#fontIdList").val();
			if ( fontIdList.length > 0){
				newFontIdList = newFontIdList + "_" + response.body.fontId;
			} else {
				newFontIdList = response.body.fontId;
			}
			// Dump the list into the hidden form. This will get passed to the new media item window.
			$("#fontIdList").val(newFontIdList);
		})
		
		// Events
		// 1) When the dashboard icon is clicked
		// Note: there is no event when the dashboard my device button is clicked. This is a work-around. We are going to use jquery's on click event and put in the class of the button. This is required as the uppy button does not have an id.
		$(".uppy-Dashboard-input").on('click', function(event){
			$.when(kendo.ui.ExtWaitDialog.show({ title: "Please wait...", message: "Please wait for the file uploader interface to respond.", icon: "k-ext-information" }));
		});
		
		// 2) When a file has been uploaded to uppy
		uppy.on('file-added', (file) => {
		  	// Close the wait window that was launched in the calling function.
			kendo.ui.ExtWaitDialog.hide();
		})
		
		// 3) When the upload button was pressed
		uppy.on('upload', (data) => {
			$.when(kendo.ui.ExtWaitDialog.show({ title: "Please wait...", message: "Please wait while the fonts are uploaded.", icon: "k-ext-information" }));
		})
		
		// 4) Error handling
		uppy.on('upload-error', (file, error, response) => {
			// Alert the user
			$.when(kendo.ui.ExtYesNoDialog.show({ 
				title: "Upload failed",
				message: "The following error was encountered: " + error + ". Do you want to retry the upload?",
				icon: "k-ext-warning",
				width: "<cfoutput>#application.kendoExtendedUiWindowWidth#</cfoutput>", 
				height: "215px"
			})
			).done(function (response) { // If the user clicked 'yes', retry.
				if (response['button'] == 'Yes'){// remember that js is case sensitive.
					// Retry
					uppy.retryUpload(file.id);
				}//..if (response['button'] == 'Yes'){
			});	
		})

		// 5) When the upload is complete to the server
		uppy.on('complete', (result) => {
			// Close the please wait dialog
			// Use a quick set timeout in order for the data to load.
			setTimeout(function() {
				// Close the wait window that was launched in the calling function.
				kendo.ui.ExtWaitDialog.hide();
			}, 500);
			// Create a new window in order to put in the fancy box group and the item details (such as the font name)
			createAdminInterfaceWindow(32, $("#fontIdList").val());
		})
	
    </script>

</cfcase>
	
<!--- //************************************************************************************************
		Font Items
//**************************************************************************************************--->
		
<cfcase value="32">
	<cfsilent>
		<!---  Replace the underscore with a comma so that we can use it in the query below. --->
		<cfset fontIdList = replaceNoCase(URL.optArgs, '_', ',', 'all')>

		<!--- Get the data from the db --->
		<cfquery name="getUploadedFont" dbtype="hql">
			SELECT DISTINCT new Map (
				FontId as FontId,
				FileName as FileName
			)
			FROM Font
			WHERE FontId IN (<cfqueryparam value="#fontIdList#" cfsqltype="integer" list="yes">)
		</cfquery>
			
		<!--- Make a new fontIdList from the query --->
		<cfparam name="newFontIdList" default="" type="string">
			
		<cfif arrayLen(getUploadedFont)>
			<cfloop from="1" to="#arrayLen(getUploadedFont)#" index="i">
				<cfset newFontIdList = ListAppend(newFontIdList, getUploadedFont[i].FontId, "_")>
			</cfloop>
		</cfif>
		
	</cfsilent>
	
	<!---
	Debugging:<br/>
	<cfoutput>fontIdList: #fontIdList#</cfoutput>
	<cfdump var="#getUploadedFont#"></cfdump>--->
		
	<h4>Please enter font details for each font</h4>
	
	<form id="fontUploadDetail" name="fontUploadDetail" data-role="validator">
	<!--- Hidden input to pass the fontIdList --->
	<input type="hidden" name="fontIdList" id="fontIdList" value="<cfoutput>#newFontIdList#</cfoutput>">
	<input type="hidden" name="csrfToken" id="csrfToken" value="<cfoutput>#csrfToken#</cfoutput>" />

	<table align="left" class="k-content tableBorder" width="100%" cellpadding="5" cellspacing="0">
	<cfif not arrayLen(getUploadedFont)>
		<tr>
			<td class="k-header">
			<cfoutput>There are no recent uploads.</cfoutput>
			</td>
		</tr>
	</cfif><!---<cfif not getMediaUrl.recordCount>--->
	<cfloop from="1" to="#arrayLen(getUploadedFont)#" index="i"><cfoutput>
		<cfsilent>
			<!--- Set the variable values. I want to shorten the long variable names here. --->
			<cfset fontId = getUploadedFont[i]["FontId"]>
			<cfset fileName = getUploadedFont[i]["FileName"]>
				
			<!--- Inspect the file name to try to get the best defaults on the menu's --->
			<!--- Font weight --->
			<cfif FileName contains '100'>
				<cfset defaultWeight = 'Thin'>
			<cfelseif FileName contains '200' or FileName contains '300'>
				<cfset defaultWeight = 'Light'>
			<cfelseif FileName contains '400' or FileName contains 'Regular'>
				<cfset defaultWeight = 'Regular'>
			<cfelseif FileName contains '500' or FileName contains '600'>
				<cfset defaultWeight = 'Semi-Bold'>
			<cfelseif FileName contains '700' or FileName contains '800'>
				<cfset defaultWeight = 'Bold'>
			<cfelseif FileName contains '900'>
				<cfset defaultWeight = 'Black'>
			<cfelse>
				<cfset defaultWeight = 'Normal'>
			</cfif>
			<!--- Italic --->
			<cfif FileName contains 'italic'>
				<cfset italic = true>
			<cfelse>
				<cfset italic = false>
			</cfif>
	
		</cfsilent>

		<!--- Load the fonts. ---> 
		<style>
			/* fonts */
			@font-face {
				font-family: "<cfoutput>#fileName#</cfoutput>";
				src: url('<cfoutput>#application.baseUrl#/common/fonts/#fileName#</cfoutput>');
			}
		</style>
		<tr class="#iif(i MOD 2,DE('k-content'),DE('k-alt'))#" height="50px;">
		<!--- Create alternating rows in the table. The Kendo classes which we will use are k-alt and k-content.
		We will create a border between the rows if the current row is not the first row. --->
		<cfif i eq 1>
			<td valign="top" width="240px">
		<cfelse>
			<td align="left" valign="top" class="border" width="240px">
		</cfif>
			<div id="font-<cfoutput>#fileName#</cfoutput>-preview" style="font-family: <cfoutput>#fileName#</cfoutput>">Font Preview: The quick brown fox jumps over the lazy dog</div>
		</td>
		<cfif i eq 1>
			<td valign="top">
		<cfelse>
			<td align="left" valign="top" class="border">
		</cfif>
				<table align="left" class="k-content" width="100%" cellpadding="5" cellspacing="0" border="2">
					<tr>
						<td><label for="font<cfoutput>#i#</cfoutput>"><b>Font:</b></label></td>
					</tr>
					<tr>
						<td>
							<input type="text" name="font<cfoutput>#i#</cfoutput>" id="font<cfoutput>#i#</cfoutput>" value="<cfoutput>#fileName#</cfoutput>" class="k-textbox" required style="width: 100%;">
						</td>
					</tr>
					<tr>
						<td class="border k-alt"><label for="fileName<cfoutput>#i#</cfoutput>"><b>Filename:</b></label></td>
					</tr>
					<tr>
						<td class="k-alt"><input type="text" name="fileName<cfoutput>#i#</cfoutput>" id="fileName<cfoutput>#i#</cfoutput>" value="<cfoutput>#fileName#</cfoutput>" class="k-textbox" style="width: 100%;"></td>
					</tr>
					
					<tr>
						<td class="border k-content"><label for="fontWeight<cfoutput>#i#</cfoutput>"><b>Font Weight:</b></label></td>
					</tr>
					<tr>
						<td class="k-content">
						<script>
							// create DropDownList from select HTML element
							$("#chr(35)#fontWeight<cfoutput>#i#</cfoutput>").kendoDropDownList();
						</script>
						<select name="fontWeight<cfoutput>#i#</cfoutput>" id="fontWeight<cfoutput>#i#</cfoutput>">
							<option value="Thin"<cfif defaultWeight eq 'Thin'> selected</cfif>>thin (100)</option>
							<option value="Light"<cfif defaultWeight eq 'Light'> selected</cfif>>Light (200-300)</option>
							<option value="Regular"<cfif defaultWeight eq 'Regular'> selected</cfif>>Regular (400)</option>
							<option value="Semi-Bold"<cfif defaultWeight eq 'Semi-Bold'> selected</cfif>>Semi-Bold (500-600)</option>
							<option value="Bold"<cfif defaultWeight eq 'bold'> selected</cfif>>Bold (700-800)</option>
							<option value="Black"<cfif defaultWeight eq 'black'> selected</cfif>>Black (900)</option>
						</select>	
					</tr>
					<tr>
						<td class="border k-alt"><label for="fontType<cfoutput>#i#</cfoutput>"><b>Font Type (ie sans-serif):</b></label></td>
					</tr>
					<tr>
						<td class="k-alt">
							<script>
								// create DropDownList from select HTML element
                    			$("#chr(35)#fontType<cfoutput>#i#</cfoutput>").kendoDropDownList();
							</script>
							<select name="fontType<cfoutput>#i#</cfoutput>" id="fontType<cfoutput>#i#</cfoutput>">
								<option value="sans-serif" selected>Sans Serif</option>
								<option value="serif">Serif</option>
								<option value="slab-serif">Slab Serif</option>
								<option value="display">Display</option>
								<option value="script">Script</option>
							</select> 
						</td>
					</tr>
					<tr>
						<td class="border k-content">
						<label for="italic<cfoutput>#i#</cfoutput>"><b>Italic?:</b></label>
						<input type="checkbox" name="italic<cfoutput>#i#</cfoutput>" id="italic<cfoutput>#i#</cfoutput>"<cfif italic> checked</cfif> value="true"></td>
					</tr>
					<tr>
						<td class="k-alt">
						<label for="googleFont<cfoutput>#i#</cfoutput>"><b>Is this a Google Font?:</b></label>
						<input type="checkbox" name="googleFont<cfoutput>#i#</cfoutput>" id="googleFont<cfoutput>#i#</cfoutput>" checked value="true">
						</td>
					</tr>
				</table>
			</td>
		</tr>

	</cfoutput></cfloop>
		<tr>
		<!--- Create alternating rows in the table. The Kendo classes which we will use are k-alt and k-content.
		We will create a border between the rows if the current row is not the first row. --->
		<cfif i eq 1>
			<td valign="top" <cfif not session.isMobile>colspan="2"</cfif>>
		<cfelse>
			<td align="left" valign="top" <cfif not session.isMobile>colspan="2"</cfif>>
		</cfif>
				<button id="uploadFontDetailSubmit" class="k-button k-primary" type="button">Submit</button>
			</td>
		</tr>
	</table>
				
	</form>
				
	<script>
		$(document).ready(function() {
			// !!! Note on the validators, all forms need a name attribute, otherwise the positioning of the messages will not work. --->
			var fontUploadDetailFormValidator = $("#fontUploadDetail").kendoValidator({
				// Set up custom validation rules 
				rules: {
				<cfloop from="1" to="#arrayLen(getUploadedFont)#" index="i">
					<cfsilent>
						<!--- Set the variable values. I want to shorten the long variable names here. --->
						<cfset fontId = getUploadedFont[i]["FontId"]>
						<cfset fileName = getUploadedFont[i]["FileName"]>
					</cfsilent>
					// font name
					font<cfoutput>#i#</cfoutput>:
					function(input){
						if (input.is("[id='font<cfoutput>#i#</cfoutput>']") && $.trim(input.val()).length < 4){
							// Display an error on the page.
							input.attr("data-font<cfoutput>#i#</cfoutput>Required-msg", "The font field must be at least 4 characters");
							// Focus on the current element
							$( "#font<cfoutput>#i#</cfoutput>" ).focus();
							return false;
						}                                    
						return true;
					},
					// file name
					fileName<cfoutput>#i#</cfoutput>:
					function(input){
						if (input.is("[id='fileName<cfoutput>#i#</cfoutput>']") && $.trim(input.val()).length < 4){
							// Display an error on the page.
							input.attr("data-fileName<cfoutput>#i#</cfoutput>Required-msg", "The font field must be at least 4 characters");
							// Focus on the current element
							$( "#fileName<cfoutput>#i#</cfoutput>" ).focus();
							return false;
						}                                    
						return true;
					},
					</cfloop>
				}
			}).data("kendoValidator");
		
			// Invoked when the submit button is clicked. Insted of using '$("form").submit(function(event) {' and 'event.preventDefault();', We are using direct binding here to speed up the event.
			var uploadFontDetailSubmit = $('#uploadFontDetailSubmit');
			uploadFontDetailSubmit.on('click', function(e){      
                e.preventDefault();         
				if (fontUploadDetailFormValidator.validate()) {
					// submit the form.
					// Note: when testing the ui validator, comment out the post line below. It will only validate and not actually do anything when you post.
					// alert('posting');
					postFontDetails('update');
				} else {
					$.when(kendo.ui.ExtAlertDialog.show({ title: "There are errors", message: "Required fields are missing.", width: "<cfoutput>#application.kendoExtendedUiWindowWidth#</cfoutput>", icon: "k-ext-warning" }) // or k-ext-error, k-ext-question
						).done(function () {
						// Do nothing
					});
				}
			});
		});//...document.ready
		
		// Post method on the detail form called from the GalleryDetailFormValidator method on the detail page. The action variable will either be 'update' or 'insert'.
		function postFontDetails(action){
			jQuery.ajax({
				type: 'post', 
				url: '<cfoutput>#application.baseUrl#</cfoutput>/common/cfc/ProxyController.cfc?method=saveFontAfterUpload&csrfToken=<cfoutput>#csrfToken#</cfoutput>',
				// Serialize the form. The csrfToken is also in the form.
				data: $('#fontUploadDetail').serialize(),
				// This is one of the few times that we will be sending back an html response. We are going to use this directly to set the content in the editor. its easier to craft the html on the server side than to manipulate the dom with a json object on the client. Normally this is always json
				dataType: "html",
				success: fontUpdateResult, // calls the result function.
				error: function(ErrorMsg) {
					console.log('Error' + ErrorMsg);
				}
			// Extract any errors. This is a new jQuery promise based function as of jQuery 1.8.
			}).fail(function (jqXHR, textStatus, error) {
				// This is a secured function. Display the login screen.
				if (jqXHR.status === 403) { 
					createLoginWindow(); 
				} else {//...if (jqXHR.status === 403) { 
					// The full response is: jqXHR.responseText, but we just want to extract the error.
					$.when(kendo.ui.ExtAlertDialog.show({ title: "Error while consuming the saveFont function", message: error, icon: "k-ext-error", width: "<cfoutput>#application.kendoExtendedUiWindowWidth#</cfoutput>" }) // or k-ext-error, k-ext-information, k-ext-question, k-ext-warning.  You can also specify height.
						).done(function () {
					// Do nothing
					});		
				}//...if (jqXHR.status === 403) { 
			});
		};
		
		function fontUpdateResult(response){
			// alert(response)
			// Note: the response is an html string 
			
			// Alert the user
			$.when(kendo.ui.ExtYesNoDialog.show({ 
				title: "Font was uploaded",
				message: "Do you want to upload more fonts?",
				icon: "k-ext-question",
				width: "<cfoutput>#application.kendoExtendedUiWindowWidth#</cfoutput>", 
				height: "215px"
			})
			).done(function (response) { // If the user clicked 'yes'.
				if (response['button'] == 'Yes'){// remember that js is case sensitive.
					// Close this window
					$('#uploadFontDetailsWindow').kendoWindow('destroy');
					// and do it again
					createAdminInterfaceWindow(31, '', 'addFont');
				} else {
					// Refresh the <cfif application.kendoCommercial>kendo<cfelse>jsgrid</cfif> grid 
					try {
						// Refresh the font grid if it is open
					<cfif application.kendoCommercial and 1 eq 2><!---We are not using the Kendo grids right now.--->
						$('#fontsGrid').data('kendoGrid').dataSource.read();
					<cfelse>
						$("#fontsGrid").jsGrid("loadData");
					</cfif> 
						// Refresh the theme font dropdowns if the window is open
						$("#blogNameFontDropdown").data("kendoDropDownList").dataSource.read();
					} catch(e){
						// The grid or dropdown was not initialized. This is a normal error
					}
					// Close the upload font window
					$('#uploadFontWindow').kendoWindow('destroy');
					// Close this window
					$('#uploadFontDetailsWindow').kendoWindow('destroy');
				}//..if (response['button'] == 'Yes'){
			});	
		}
		
	</script>
			
</cfcase>
		
<!--- //************************************************************************************************
		Fonts Grid
//**************************************************************************************************--->
		
<cfcase value="33">
		
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
		
<cfcase value="34">
	<cfsilent>
		<!--- Get the data from the db --->
		<cfset getFont = application.blog.getFont(fontId=URL.optArgs)>
	</cfsilent>
	<!---
	Debugging:<br/>
	<cfoutput>fontIdList: #fontIdList#</cfoutput>
	<cfdump var="#getUploadedFont#"></cfdump>--->

	<cfsilent>
		<!--- Set the variable values. I want to shorten the long variable names here. --->
		<cfset fontId = getFont[1]["FontId"]>
		<cfset font = getFont[1]["Font"]>
		<cfset fileName = getFont[1]["FileName"]>
		<cfset fontWeight = getFont[1]["FontWeight"]>
		<cfset italic = getFont[1]["Italic"]>
		<cfset fileName = getFont[1]["FileName"]>
		<cfset woff = getFont[1]["Woff"]>
		<cfset woff2 = getFont[1]["Woff2"]>	
		<cfset selfHosted = getFont[1]["SelfHosted"]>
		<cfset fontType = getFont[1]["FontType"]>
		<cfset webSafeFont = getFont[1]["WebSafeFont"]>
		<cfset googleFont = getFont[1]["GoogleFont"]>
		<cfset useFont = getFont[1]["UseFont"]>
			
		<cfif woff2>
			<cfset fontFileName = application.baseUrl & "/common/fonts/" & fileName & ".woff2">
		<cfelseif woff>
			<cfset fontFileName = application.baseUrl & "/common/fonts/" & fileName & ".woff">
		<cfelseif len(fileName)>
			<!--- Woff2 is our standard font --->
			<cfset fontFileName = application.baseUrl & "/common/fonts/" & fileName & ".woff2">
		<cfelse>
			<cfset fontFileName = "">
		</cfif>
	</cfsilent>
	<!---<cfoutput>woff2: #woff2# fontFileName: #fontFileName#</cfoutput> --->

	<!--- Load the font. ---> 
	<style>
		@font-face {
			font-family: "<cfoutput>#font#</cfoutput>";
			src: url('<cfoutput>#fontFileName#</cfoutput>');
		}
	</style>
		
	<form id="fontDetailForm" name="fontDetailForm" data-role="validator">	
	<input type="hidden" id="fontId" name="fontId" value="<cfoutput>#URL.optArgs#</cfoutput>"/>
	<input type="hidden" name="csrfToken" id="csrfToken" value="<cfoutput>#csrfToken#</cfoutput>" />
		
	<table align="center" class="k-content" width="100%" cellpadding="2" cellspacing="0">
	  <cfsilent>
		<!---The first content class in the table should be empty. --->
		<cfset thisContentClass = HtmlUtilsObj.getKendoClass('')>
		<!--- Set the colspan property for borders --->
		<cfset thisColSpan = "2">
	  </cfsilent>
	  <tr height="1px">
		  <td align="left" valign="top" colspan="2" class="<cfoutput>#thisContentClass#</cfoutput>"></td>
	  </tr>
	  <tr valign="middle" height="30px">
		<td valign="bottom" align="left" class="<cfoutput>#thisContentClass#</cfoutput>" colspan="<cfoutput>#thisColSpan#</cfoutput>">
			<div id="font-preview" style="font-family: <cfoutput>#font#</cfoutput>"><h4><cfoutput>#font#</cfoutput> preview: The quick brown fox jumps over the lazy dog</h4></div>
		</td>
	  </tr>
	  <tr height="1px">
		  <td align="left" valign="top" colspan="2" class="border <cfoutput>#thisContentClass#</cfoutput>"></td>
	  </tr> 
	  <tr valign="middle" height="30px">
		<td valign="bottom" align="left" class="<cfoutput>#thisContentClass#</cfoutput>" colspan="<cfoutput>#thisColSpan#</cfoutput>">
			<p>The fonts are loaded dynamically when a font is assigned to particular set of content of a theme. A font can be assigned to the body, the title header, and the menu script at the top of the page. Fonts can also be used when making a post in the post editor. If you are using different fonts using the theme interface you don't  need to load the font in your code, it will be loaded automatically.</p> 
			<p>If you are writing your own display oriented code click on the use font button to load the font automatically. However, be aware that loading too many fonts will slow the page down as they consume resources to load.</p>
		</td>
	  </tr>
	<cfif session.isMobile>
	  <tr valign="middle">
		<td class="<cfoutput>#thisContentClass#</cfoutput>" colspan="2">
		<label for="font">Font</label>
		</td>
	   </tr>
	   <tr>
		<td class="<cfoutput>#thisContentClass#</cfoutput>" colspan="2">
			<input id="font" name="font" type="text" value="<cfoutput>#font#</cfoutput>" class="k-textbox" style="width: 95%" />
		</td>
	  </tr>
	<cfelse><!---<cfif session.isMobile>--->
	  <tr>
		<td align="right" class="<cfoutput>#thisContentClass#</cfoutput>" style="width: 20%"> 
			<label for="font">Font:</label>
		</td>
		<td class="<cfoutput>#thisContentClass#</cfoutput>" align="left" style="width: 80%"> 
			<input id="font" name="font" type="text" value="<cfoutput>#font#</cfoutput>" class="k-textbox" style="width: 60%" />    
		</td>
	  </tr>
	</cfif>
	  <!-- Border -->
	  <tr height="2px">
		  <td align="left" valign="top" colspan="<cfoutput>#thisColSpan#</cfoutput>" class="<cfoutput>#thisContentClass#</cfoutput>"></td>
	  </tr>
	  <cfsilent>
	  <!--- Set the class for alternating rows. --->
	  <!---After the first row, the content class should be the current class. --->
	  <cfset thisContentClass = HtmlUtilsObj.getKendoClass(thisContentClass)>
	  </cfsilent>
	  <tr height="2px">
		  <td align="left" valign="bottom" colspan="2" class="border <cfoutput>#thisContentClass#</cfoutput>"></td>
	  </tr>
	<cfif session.isMobile>
	  <tr valign="middle">
		<td class="<cfoutput>#thisContentClass#</cfoutput>" colspan="2">
			<label for="fontWeight">Font Weight:</label>
		</td>
	   </tr>
	   <tr>
		<td class="<cfoutput>#thisContentClass#</cfoutput>" colspan="2">
			<script>
				// create DropDownList from select HTML element
				$("#fontWeight").kendoDropDownList();
			</script>
			<select name="fontWeight" id="fontWeight">
				<option value="Thin"<cfif fontWeight eq 'Thin'> selected</cfif>>thin (100)</option>
				<option value="Light"<cfif fontWeight eq 'Light'> selected</cfif>>Light (200-300)</option>
				<option value="Regular"<cfif fontWeight eq 'Regular'> selected</cfif>>Regular (400)</option>
				<option value="Semi-Bold"<cfif fontWeight eq 'Semi-Bold'> selected</cfif>>Semi-Bold (500-600)</option>
				<option value="Bold"<cfif fontWeight eq 'bold'> selected</cfif>>Bold (700-800)</option>
				<option value="Black"<cfif fontWeight eq 'black'> selected</cfif>>Black (900)</option>
			</select>
		</td>
	  </tr>
	<cfelse><!---<cfif session.isMobile>--->
	  <tr valign="middle" height="30px">
		<td valign="bottom" align="right" class="<cfoutput>#thisContentClass#</cfoutput>">
			<label for="fontWeight">Font Weight:</label>
		</td>
		<td valign="bottom" align="left" class="<cfoutput>#thisContentClass#</cfoutput>">
			<script>
				// create DropDownList from select HTML element
				$("#fontWeight").kendoDropDownList();
			</script>
			<select name="fontWeight" id="fontWeight">
				<option value="Thin"<cfif fontWeight eq 'Thin'> selected</cfif>>thin (100)</option>
				<option value="Light"<cfif fontWeight eq 'Light'> selected</cfif>>Light (200-300)</option>
				<option value="Regular"<cfif fontWeight eq 'Regular'> selected</cfif>>Regular (400)</option>
				<option value="Semi-Bold"<cfif fontWeight eq 'Semi-Bold'> selected</cfif>>Semi-Bold (500-600)</option>
				<option value="Bold"<cfif fontWeight eq 'bold'> selected</cfif>>Bold (700-800)</option>
				<option value="Black"<cfif fontWeight eq 'black'> selected</cfif>>Black (900)</option>
			</select>	
		</td>
	  </tr>
	</cfif>
	 <!-- Border -->
	  <tr height="2px">
		  <td align="left" valign="top" colspan="<cfoutput>#thisColSpan#</cfoutput>" class="<cfoutput>#thisContentClass#</cfoutput>"></td>
	  </tr>
	  <cfsilent>
	  <!--- Set the class for alternating rows. --->
	  <!---After the first row, the content class should be the current class. --->
	  <cfset thisContentClass = HtmlUtilsObj.getKendoClass(thisContentClass)>
	  </cfsilent>
	  <tr height="2px">
		  <td align="left" valign="bottom" colspan="2" class="border <cfoutput>#thisContentClass#</cfoutput>"></td>
	  </tr>
	<cfif session.isMobile>
	  <tr valign="middle">
		<td class="<cfoutput>#thisContentClass#</cfoutput>" colspan="2">
			<label for="italic">Italic?</label>
		</td>
	   </tr>
	   <tr>
		<td class="<cfoutput>#thisContentClass#</cfoutput>" colspan="2">
			<input type="checkbox" name="italic" id="italic" value="1" <cfif italic>checked</cfif>>
		</td>
	  </tr>
	<cfelse><!---<cfif session.isMobile>--->
	  <tr valign="middle" height="30px">
		<td valign="bottom" align="right" class="<cfoutput>#thisContentClass#</cfoutput>">
			<label for="italic">Italic?</label>
		</td>
		<td valign="bottom" align="left" class="<cfoutput>#thisContentClass#</cfoutput>">
			<input type="checkbox" name="italic" id="italic" value="1" <cfif italic>checked</cfif>>
		</td>
	  </tr>
	</cfif>
	  <!-- Border -->
	  <tr height="2px">
		<td align="left" valign="top" colspan="<cfoutput>#thisColSpan#</cfoutput>" class="<cfoutput>#thisContentClass#</cfoutput>"></td>
	  </tr>
	  <cfsilent>
	  <!--- Set the class for alternating rows. --->
	  <!---After the first row, the content class should be the current class. --->
	  <cfset thisContentClass = HtmlUtilsObj.getKendoClass(thisContentClass)>
	  </cfsilent>
	  <tr height="2px">
		  <td align="left" valign="top" colspan="2" class="border <cfoutput>#thisContentClass#</cfoutput>"></td>
	  </tr>
	  <!-- Form content -->
	<cfif session.isMobile>
	  <tr valign="middle">
		<td class="<cfoutput>#thisContentClass#</cfoutput>" colspan="2">
			<label for="fontType">Font Type:</label>
		</td>
	   </tr>
	   <tr>
		<td class="<cfoutput>#thisContentClass#</cfoutput>" colspan="2">
			<input type="text" name="fontType" id="fontType" value="<cfoutput>#fontType#</cfoutput>" class="k-textbox" style="width: 95%">
		</td>
	  </tr>
	<cfelse><!---<cfif session.isMobile>--->
	  <tr valign="middle" height="30px">
		<td align="right" class="<cfoutput>#thisContentClass#</cfoutput>">
			<label for="fontType">Font Type:</label>
		</td>
		<td align="left" class="<cfoutput>#thisContentClass#</cfoutput>">
			<input type="text" name="fontType" id="fontType" value="<cfoutput>#fontType#</cfoutput>" class="k-textbox" style="width: 66%">
	  </tr>
	</cfif>
	  <!-- Border -->
	  <tr height="2px">
		<td align="left" valign="top" colspan="<cfoutput>#thisColSpan#</cfoutput>" class="<cfoutput>#thisContentClass#</cfoutput>"></td>
	  </tr>
	  <cfsilent>
	  <!--- Set the class for alternating rows. --->
	  <!---After the first row, the content class should be the current class. --->
	  <cfset thisContentClass = HtmlUtilsObj.getKendoClass(thisContentClass)>
	  </cfsilent>
	  <tr height="2px">
		  <td align="left" valign="top" colspan="2" class="border <cfoutput>#thisContentClass#</cfoutput>"></td>
	  </tr>
	  <!-- Form content -->
	<cfif session.isMobile>
	  <tr valign="middle">
		<td class="<cfoutput>#thisContentClass#</cfoutput>" colspan="2">
			<label for="fileName">File Name:</label>
		</td>
	   </tr>
	   <tr>
		<td class="<cfoutput>#thisContentClass#</cfoutput>" colspan="2">
			<input type="text" name="fileName" id="fileName" value="<cfoutput>#fileName#</cfoutput>" class="k-textbox" style="width: 95%">
		</td>
	  </tr>
	<cfelse><!---<cfif session.isMobile>--->
	  <tr valign="middle" height="30px">
		<td align="right" class="<cfoutput>#thisContentClass#</cfoutput>">
			<label for="fileName">File Name:</label>
		</td>
		<td align="left" class="<cfoutput>#thisContentClass#</cfoutput>">
			<input type="text" name="fileName" id="fileName" value="<cfoutput>#fileName#</cfoutput>" class="k-textbox" style="width: 66%">
	  </tr>
	</cfif>
	  <!-- Border -->
	  <tr height="2px">
		<td align="left" valign="top" colspan="<cfoutput>#thisColSpan#</cfoutput>" class="<cfoutput>#thisContentClass#</cfoutput>"></td>
	  </tr>
	  <cfsilent>
	  <!--- Set the class for alternating rows. --->
	  <!---After the first row, the content class should be the current class. --->
	  <cfset thisContentClass = HtmlUtilsObj.getKendoClass(thisContentClass)>
	  </cfsilent>
	  <tr height="2px">
		  <td align="left" valign="top" colspan="2" class="border <cfoutput>#thisContentClass#</cfoutput>"></td>
	  </tr>
	  <!-- Form content -->
	  <tr valign="middle" height="30px">
		  <cfif not session.isMobile><td></td></cfif>
		  <td align="left" <cfif session.isMobile>colspan="2"</cfif>>
			<!--- Inner table --->
			<table align="center" class="<cfoutput>#thisContentClass#</cfoutput>" width="100%" cellpadding="4" cellspacing="0">
				<tr>
					<td width="25%" align="left">
						<label for="webSafeFont">Web Safe Font?</label>
						<input type="checkbox" name="webSafeFont" id="webSafeFont" value="1" <cfif WebSafeFont>checked</cfif>>
					</td>
					<td width="25%" align="left">
						<label for="selfHosted">Self Hosted?</label>
						<input type="checkbox" name="selfHosted" id="selfHosted" value="1" <cfif selfHosted>checked</cfif>>
					</td>
					<td width="25%" align="left">
						<label for="googleFont">Google Font?</label>
						<input type="checkbox" name="googleFont" id="googleFont" value="1" <cfif selfHosted>checked</cfif>>
					</td>
					<td width="25%" align="left">
						<label for="useFont">Use Font?</label>
						<input type="checkbox" name="useFont" id="useFont" value="1" <cfif useFont>checked</cfif>>
					</td>
				</tr>
			</table>
		</td>

	  </tr>
	  <!-- Border -->
	  <tr height="2px">
		<td align="left" valign="top" colspan="<cfoutput>#thisColSpan#</cfoutput>" class="<cfoutput>#thisContentClass#</cfoutput>"></td>
	  </tr>
	  <cfsilent>
	  <!--- Set the class for alternating rows. --->
	  <!---After the first row, the content class should be the current class. --->
	  <cfset thisContentClass = HtmlUtilsObj.getKendoClass(thisContentClass)>
	  </cfsilent>
	  <tr height="2px">
		  <td align="left" valign="top" colspan="2" class="border <cfoutput>#thisContentClass#</cfoutput>"></td>
	  </tr>
	  <!-- Form content -->
	  <tr valign="middle" height="30px">
		<td align="right" class="<cfoutput>#thisContentClass#</cfoutput>"></td>
		<td align="left" class="<cfoutput>#thisContentClass#</cfoutput>">
			<button id="fontDetailSubmit" name="fontDetailSubmit" class="k-button k-primary" type="button">Submit</button>
		</td>
	  </tr>
	</table>
	</form>
				
	<script>
		$(document).ready(function() {
			// !!! Note on the validators, all forms need a name attribute, otherwise the positioning of the messages will not work. --->
			var fontDetailFormValidator = $("#fontDetailForm").kendoValidator({
				// Set up custom validation rules 
				rules: {
					// font name
					font:
					function(input){
						if (input.is("[id='font']") && $.trim(input.val()).length < 4){
							// Display an error on the page.
							input.attr("data-fontRequired-msg", "The font field must be at least 4 characters");
							// Focus on the current element
							$( "#font" ).focus();
							return false;
						}                                    
						return true;
					}
				}
			}).data("kendoValidator");
		
			// Invoked when the submit button is clicked. Insted of using '$("form").submit(function(event) {' and 'event.preventDefault();', We are using direct binding here to speed up the event.
			var fontDetailSubmit = $('#fontDetailSubmit');
			fontDetailSubmit.on('click', function(e){     
                e.preventDefault();         
				if (fontDetailFormValidator.validate()) {
					
					// submit the form.
					// Note: when testing the ui validator, comment out the post line below. It will only validate and not actually do anything when you post.
					// alert('posting');
					postFontDetails('update');
				} else {
					$.when(kendo.ui.ExtAlertDialog.show({ title: "There are errors", message: "Required fields are missing.", width: "<cfoutput>#application.kendoExtendedUiWindowWidth#</cfoutput>", icon: "k-ext-warning" }) // or k-ext-error, k-ext-question
						).done(function () {
						// Do nothing
					});
				}
			});
		});//...document.ready
		
		// Post method on the detail form called from the GalleryDetailFormValidator method on the detail page. The action variable will either be 'update' or 'insert'.
		function postFontDetails(action){
			jQuery.ajax({
				type: 'post', 
				url: '<cfoutput>#application.baseUrl#</cfoutput>/common/cfc/ProxyController.cfc?method=saveFont&csrfToken=<cfoutput>#csrfToken#</cfoutput>',
				// Serialize the form. The csrfToken is also in the form.
				data: $('#fontDetailForm').serialize(),
				// This is one of the few times that we will be sending back an html response. We are going to use this directly to set the content in the editor. its easier to craft the html on the server side than to manipulate the dom with a json object on the client. Normally this is always json
				dataType: "html",
				success: fontDetailUpdateResult, // calls the result function.
				error: function(ErrorMsg) {
					console.log('Error' + ErrorMsg);
				}
			// Extract any errors. This is a new jQuery promise based function as of jQuery 1.8.
			}).fail(function (jqXHR, textStatus, error) {
				// This is a secured function. Display the login screen.
				if (jqXHR.status === 403) { 
					createLoginWindow(); 
				} else {//...if (jqXHR.status === 403) { 
					// The full response is: jqXHR.responseText, but we just want to extract the error.
					$.when(kendo.ui.ExtAlertDialog.show({ title: "Error while consuming the saveFont function", message: error, icon: "k-ext-error", width: "<cfoutput>#application.kendoExtendedUiWindowWidth#</cfoutput>" }) // or k-ext-error, k-ext-information, k-ext-question, k-ext-warning.  You can also specify height.
						).done(function () {
					// Do nothing
					});		
				}//...if (jqXHR.status === 403) { 
			});
		};
		
		function fontDetailUpdateResult(response){
			// alert(response)
			// Note: the response is an html string 
			
			// Refresh the <cfif application.kendoCommercial>kendo<cfelse>jsgrid</cfif> grid 
			try {
				// Refresh the font grid if it is open
			<cfif application.kendoCommercial and 1 eq 2><!---We are not using the Kendo grids right now.--->
				$('#fontsGrid').data('kendoGrid').dataSource.read();
			<cfelse>
				$("#fontsGrid").jsGrid("loadData");
			</cfif> 
				// Refresh the theme font dropdowns if the window is open
				$("#blogNameFontDropdown").data("kendoDropDownList").dataSource.read();
			} catch(e){
				// The grid or dropdown was not initialized. This is a normal error
			}
			// Close this window
			$('#fontDetailWindow').kendoWindow('destroy');
		}
		
	</script>
			
</cfcase>
		
<!--- //************************************************************************************************
		Generic tiny mce image editor used for themes and settings. This is used to upload all of the theme related images.
//**************************************************************************************************--->
				
<cfcase value=35>
	
	<!--- Preset the image var --->
	<cfparam name="imageHtml" default="">
	
	<!--- Set the image html in order for the editor to render the current image. --->
	<cfset imageHtml = '<img src="' & otherArgs1 & '">'>
		
	<!--- This function is used to upload images for the themes and settings.
	The arguments sent to this function in the URL are:
	optArgs: the themeId
	URL.otherArgs: the column that specifies the image that we are working with, ie- blogBackgroundImageMobile
    URL.otherArgs1: the full path of the existing image---> 
	
	<style>
		.mce-ico.mce-i-fa {
		display: inline-block;
		font: normal normal normal 14px/1 FontAwesome;
		font-size: inherit;
		text-rendering: auto;
		-webkit-font-smoothing: antialiased;
		-moz-osx-font-smoothing: grayscale;
	}
	</style>
	
	<!---********************* Generic image upload editor *********************--->
	<!--- Set the common vars for tinymce. ---> 
	<cfsilent>
	<cfset selectorId = "imageUploadEditor">
	<cfif session.isMobile>
		<cfset editorHeight = "325">
	<cfelse>
		<cfset editorHeight = "650">
	</cfif>
	<cfset imageHandlerUrl = application.baseUrl & "/common/cfc/ProxyController.cfc?method=uploadImage&mediaProcessType=" & URL.otherArgs & "&mediaType=image&selectorId=" & selectorId & "&themeId=" & URL.optArgs & "&csrfToken=" & csrfToken> 
	<cfset contentVar = imageHtml>
	<cfset imageMediaIdField = "mediaId">
	<cfset imageClass = "entryImage">

	<cfset toolbarString = "undo redo | image editimage ">
	<cfset includeGallery = false>
	<cfset includeVideoUpload = false>
	<cfset disableVideoCoverAndWebVttButtons = true>
	<cfset includeMaps = false>
	</cfsilent>
	<!--- Include the tinymce js template --->
	<cfinclude template="#application.baseUrl#/includes/templates/js/tinyMce.cfm">
		
	<script>
		// Note: this function handles enclosure images, videos, and theme images and needs to be changed according to what is being processed. This particular function handles theme images. Note: the invokedArguments is not used by CF, but shows the location where this function is being called from and the arguments for debugging purposes.
		function saveExternalUrl(url, mediaType, selectorId, invokedArguments){ 
			jQuery.ajax({
				type: 'post', 
				selectorId: '<cfoutput>#selectorId#</cfoutput>',
				url: '<cfoutput>#application.baseUrl#</cfoutput>/common/cfc/ProxyController.cfc?method=saveExternalMediaEnclosure&template=imageUploadEditor',
				dataType: "json",
				data: { // arguments
					csrfToken: '<cfoutput>#csrfToken#</cfoutput>',
					// Pass the mediaId saved in the mediaId hidden form if it is available
					mediaId: $("#<cfoutput>#imageMediaIdField#</cfoutput>").val(),
					externalUrl: url,
					themeId: <cfoutput>#URL.optArgs#</cfoutput>,
					mediaType: 'image',
					themeImageType: <cfoutput>'#URL.otherArgs#'</cfoutput>,
					selectorId: selectorId,
					invokedArguments: invokedArguments
				},
				error: function(ErrorMsg) {
					console.log('Error' + ErrorMsg);
				}
			// Extract any errors. This is a new jQuery promise based function as of jQuery 1.8.
			}).fail(function (jqXHR, textStatus, error) {

				// The full response is: jqXHR.responseText, but we just want to extract the error.
				$.when(kendo.ui.ExtAlertDialog.show({ title: "Error while consuming the saveExternalMediaEnclosure function", message: error, icon: "k-ext-error", width: "<cfoutput>#application.kendoExtendedUiWindowWidth#</cfoutput>" }) // or k-ext-error, k-ext-information, k-ext-question, k-ext-warning.  You can also specify height.
					).done(function () {
					// Do nothing
				});		
			});
			
			// Raise a dialog
			$.when(kendo.ui.ExtAlertDialog.show({ title: "Created external link", message: "The image will be displayed from an external link, however, no social media sharing images were made.", icon: "k-ext-information", width: "<cfoutput>#application.kendoExtendedUiWindowWidth#</cfoutput>" }) // or k-ext-error, k-ext-information, k-ext-question, k-ext-warning.  You can also specify height.
				).done(function () {
				// Here we are going to refresh the theme settings window to render the new content rather than building the new client side code.
				$("#themeSettingsWindow").data("kendoWindow").refresh();
			});		
		}
		
		// Submit the data and close this window.
		function blogUploadSubmit(){
			// Refresh the theme settings window
			$("#themeSettingsWindow").data("kendoWindow").refresh();
			// Close the edit window
			$('#genericImageUploadWindow').kendoWindow('destroy');
		}
	</script>
		
	<form id="imageUploadForm" action="#" method="post" data-role="validator">
	<!-- The mediaType will either be an empty string, image or video -->
	<input type="hidden" name="mediaType" id="mediaType" value="image" />
	
	<!--- The external image url will only be present if the user entered a url from an external source. We need to capture this as we don't have any native tinymce method to indicate that an external image was selected and we need to upload it and save it to the datbase. --->
	<input type="hidden" name="externalImageUrl" id="externalImageUrl" value="" />
	<table align="center" class="k-content tableBorder" width="100%" cellpadding="2" cellspacing="0" border="0">
	  <cfsilent>
			<!---The first content class in the table should be empty. --->
			<cfset thisContentClass = HtmlUtilsObj.getKendoClass('')>
			<!--- Set the colspan property for borders --->
			<cfset thisColSpan = "2">
	  </cfsilent>
	  <tr height="1px">
		  <td align="left" valign="top" colspan="2" class="<cfoutput>#thisContentClass#</cfoutput>"></td>
	  </tr>
	  <tr height="30px">
		<td align="left" class="<cfoutput>#thisContentClass#</cfoutput>" colspan="2"> 
			<cfswitch expression="#URL.otherArgs#">
				<cfcase value="blogBackgroundImage">
					<p>The blog background image will cover the background. Make sure that the image is compressed.</p>
					<p>Note: we are not yet supporting .webp file uploads. Instead upload them manually and link to them. The webp images will also show up as a broken image in the editor unfortunately.</p>
				</cfcase>
				<cfcase value="blogBackgroundImageMobile">
					The Mobile Blog Background is used to display the background image on mobile devices. This image should be about 1/3rd smaller than the blog background image.
				</cfcase>
				<cfcase value="logoImage">
					The logo image is at the top left of the page.
				</cfcase>
				<cfcase value="logoImageMobile">
					The mobile logo image should be a bit smaller than the desktop version.
				</cfcase>
				<cfcase value="defaultLogoImageForSocialMediaShare">
					For best results, the social media sharing image should be 1200x1200. It can be smaller however it needs to be larger than your normal logo. 
				</cfcase>
				<cfcase value="headerBackgroundImage">
					The header background image covers the menu at the top of the page. You don't need a wide image, the image will be expanded to cover the page.
				</cfcase>
				<cfcase value="menuBackgroundImage">
					The menu background image covers the menu at the top of the page and is only used to prevent ghosting when changing the header background images for the red based themes.
				</cfcase>
				<cfcase value="headerBodyDividerImage">
					The header divider image separates the header from the body content. It should be a couple of pixes tall and around 75 pixels in length. The image will be expanded horizontally to fit the page.
				</cfcase>
				<cfcase value="footerImage">
					The footer image is at the bottom of the page. It typically is a larger version of the icon at the top of the page.
				</cfcase>
				
			</cfswitch>
			 
		</td>
	  </tr>
	  <!-- Border -->
	  <tr height="2px">
	    	<td align="left" valign="top" colspan="<cfoutput>#thisColSpan#</cfoutput>" class="<cfoutput>#thisContentClass#</cfoutput>"></td>
	  </tr>
	  <cfsilent>
	  <!--- Set the class for alternating rows. --->
	  <!---After the first row, the content class should be the current class. --->
	  <cfset thisContentClass = HtmlUtilsObj.getKendoClass(thisContentClass)>
	  </cfsilent>
	  <tr height="2px">
		  <td align="left" valign="top" colspan="2" class="border <cfoutput>#thisContentClass#</cfoutput>"></td>
	  </tr>
	  <!-- Form content -->
	  <tr valign="middle" height="30px">
		<td align="left" class="<cfoutput>#thisContentClass#</cfoutput>" colspan="2">
			<!--- TinyMce container --->
			<div style="position: relative;">
				<textarea id="<cfoutput>#selectorName#</cfoutput>" name="<cfoutput>#selectorName#</cfoutput>"></textarea>
			</div>   
		</td>
	  </tr>
	  <cfsilent>
	  <!--- Set the class for alternating rows. --->
	  <!--- After the first row, the content class should be the current class. --->
	  <cfset thisContentClass = HtmlUtilsObj.getKendoClass(thisContentClass)>
	  </cfsilent>
	  <tr height="2px">
		  <td align="left" valign="top" colspan="2" class="border <cfoutput>#thisContentClass#</cfoutput>"></td>
	  </tr>
	  <!-- Form content -->
	  <tr valign="middle" height="30px">
		<td valign="bottom" align="right" class="<cfoutput>#thisContentClass#</cfoutput>">&nbsp;</td>
		<td valign="bottom" align="left" class="<cfoutput>#thisContentClass#</cfoutput>">
			<button id="blogUploadComplete" name="blogUploadComplete" class="k-button k-primary" type="button" onClick="javascript:blogUploadSubmit();">Submit</button>
		</td>
	  </tr>
	</table>
	</form>
				
</cfcase>
		  
<!--- //************************************************************************************************
		FavIcon Uploader
//**************************************************************************************************--->
			
<cfcase value="36">
	<cfsilent>
	<!--- Set the uppy theme. --->
	<cfif darkTheme>
		<cfset uppyTheme = 'dark'>
	<cfelse>
		<cfset uppyTheme = 'light'>
	</cfif>
		
	<!--- Not used yet- Get the kendo primay button color in order to reset the uppy actionBtn--upload color --->
	<cfset primaryButtonColor = application.blog.getPrimaryColorsByTheme(kendoTheme:kendoTheme,setting:'accentColor')>
	<!--- Set the selectorId so that we know what interface this request is coming from --->
	<cfset selectorId = "font">
	</cfsilent>
	<!---<cfoutput>primaryButtonColor: #primaryButtonColor#</cfoutput>--->
	<input type="hidden" name="fontIdList" id="fontIdList" value=""/>
	<p>You may upload png's, .ico's, .webmanifest and .json files to the server.</p>
	<p>Bs sure to copy the HTML that the generator provides for you into the FavIcon HTML text area when you are done.</p> 
    <div id="uppyFavIconUploader"></div>
    <script>
		var uppy = Uppy.Core({
			restrictions : {
				maxFileSize: 8000000, //8mb
				maxNumberOfFiles: 36, // limit 36 files
				allowedFileTypes: ['.png','.ico','.webmanifest','.json'] // only allow web fonts
        	}
		})
		.use(Uppy.Dashboard, {
			theme: '<cfoutput>#uppyTheme#</cfoutput>',
			inline: true,
			target: '#uppyFavIconUploader',
			proudlyDisplayPoweredByUppy: false
		})
		
		// Use XHR and send the media to the server for processing
		.use(Uppy.XHRUpload, { endpoint: '<cfoutput>#application.baseUrl#</cfoutput>/common/cfc/ProxyController.cfc?method=uploadFavIcon&csrfToken=<cfoutput>#csrfToken#</cfoutput>' })
		.on('upload-success', (file, response) => {
			// The server is returning location and mediaId in a json object. We need to extract these.
			//alert(response.status) // HTTP status code
			//alert(response.body.location) // The full path of the file that was just uploaded to the server
			//alert(response.body.mediaId) // The MediaId value saved to the Media table in the database.
			
		})
		
		// Events
		// 1) When the dashboard icon is clicked
		// Note: there is no event when the dashboard my device button is clicked. This is a work-around. We are going to use jquery's on click event and put in the class of the button. This is required as the uppy button does not have an id.
		$(".uppy-Dashboard-input").on('click', function(event){
			$.when(kendo.ui.ExtWaitDialog.show({ title: "Please wait...", message: "Please wait for the file uploader interface to respond.", icon: "k-ext-information" }));
		});
		
		// 2) When a file has been uploaded to uppy
		uppy.on('file-added', (file) => {
		  	// Close the wait window that was launched in the calling function.
			kendo.ui.ExtWaitDialog.hide();
		})
		
		// 3) When the upload button was pressed
		uppy.on('upload', (data) => {
			$.when(kendo.ui.ExtWaitDialog.show({ title: "Please wait...", message: "Please wait while the files are uploaded.", width: "<cfoutput>#application.kendoExtendedUiWindowWidth#</cfoutput>", icon: "k-ext-information" }));
		})
		
		// 4) Error handling
		uppy.on('upload-error', (file, error, response) => {
			//alert(response.status);
			// Alert the user
			$.when(kendo.ui.ExtYesNoDialog.show({ 
				title: "Upload failed",
				message: "The following error was encountered: " + error + ". Do you want to retry the upload?",
				icon: "k-ext-warning",
				width: "<cfoutput>#application.kendoExtendedUiWindowWidth#</cfoutput>", 
				height: "215px"
			})
			).done(function (response) { // If the user clicked 'yes', retry.
				if (response['button'] == 'Yes'){// remember that js is case sensitive.
					// Retry
					uppy.retryUpload(file.id);
				}//..if (response['button'] == 'Yes'){
			});	
		})

		// 5) When the upload is complete to the server
		uppy.on('complete', (result) => {
			// Close the please wait dialog
			// Use a quick set timeout in order for the data to load.
			setTimeout(function() {
				// Close the wait window that was launched in the calling function.
				kendo.ui.ExtWaitDialog.hide();
			}, 500);
			// Close the window
			jQuery('#favIconUploadWindow').kendoWindow('destroy');
		})
	
    </script>

</cfcase>
		
<!--- //************************************************************************************************
		New Theme
//**************************************************************************************************--->
			
<cfcase value="37">
	<cfsilent>
	<!--- Get all themes for validation. We will use client side logic (and server side) to ensure that the new theme is unique. --->
	<cfset themeList = application.blog.getThemeList()>
	
	</cfsilent>
	<script>
		
		var themeList = <cfoutput>'#lCase(themeList)#'</cfoutput>;
		
		$(document).ready(function() {
		
			// ---------------------------- theme dropdown. ----------------------------
			var themeDs = new kendo.data.DataSource({
				transport: {
					read: {
						cache: false,
						// Note: since this template is in a different directory, we can't specify the cfc template without the full path name.
						url: function() { // The cfc component which processes the query and returns a json string. 
							return "<cfoutput>#application.baseUrl#</cfoutput>/common/cfc/ProxyController.cfc?method=getThemesForDropdown&csrfToken=<cfoutput>#csrfToken#</cfoutput>"; 
						}, 
						dataType: "json",
						contentType: "application/json; charset=utf-8", // Note: when posting json via the request body to a coldfusion page, we must use this content type or we will get a 'IllegalArgumentException' on the ColdFusion processing page.
						type: "GET" //Note: for large payloads coming from the server, use the get method. The post method may fail as it is less efficient.
					}
				} //...transport:
			});//...var rolesDs...

			// Create the top level dropdown
			var copyThemeId = $("#copyThemeId").kendoDropDownList({
				optionLabel: "Select...",
				autoBind: false,
				dataTextField: "ThemeName",
				dataValueField: "ThemeId",
				filter: "contains",
				dataSource: themeDs,
			}).data("kendoDropDownList");

			// !!! Note on the validators, all forms need a name attribute, otherwise the positioning of the messages will not work. --->
		
			var newThemeValidator = $("#newThemeForm").kendoValidator({
				// Set up custom validation rules 
				rules: {
					// The theme must be unique. 
					themeIsUnique:
					function(input){
						// Do not continue if the theme name is not unique
						if (input.is("[id='themeName']") && ( listFind( themeList, input.val().toLowerCase() ) != 0 ) ){
							// Display an error on the page.
							input.attr("data-themeIsUnique-msg", "Theme name already exists");
							// Focus on the current element
							$( "#themeName" ).focus();
							return false;
						}                                    
						return true;
					}
				}
			}).data("kendoValidator");

			// Invoked when the submit button is clicked. Insted of using '$("form").submit(function(event) {' and 'event.preventDefault();', We are using direct binding here to speed up the event.
			var newThemeSubmit = $('#newThemeSubmit');
			newThemeSubmit.on('click', function(e){     
				e.preventDefault();         
				if (newThemeValidator.validate()) {
					// Determine if there this is a new role and proceed.
					postNewTheme();
				} else {

					$.when(kendo.ui.ExtAlertDialog.show({ title: "There are errors", message: "Please correct the highlighted fields and try again", width: "<cfoutput>#application.kendoExtendedUiWindowWidth#</cfoutput>", icon: "k-ext-warning" }) // or k-ext-error, k-ext-question
						).done(function () {
						// Do nothing
					});
				}
			});
			
			function postNewTheme(){ 
				jQuery.ajax({
					type: 'post', 
					url: '<cfoutput>#application.baseUrl#</cfoutput>/common/cfc/ProxyController.cfc?method=createNewThemeFromCurrentTheme',
					dataType: "json",
					data: { // arguments
						csrfToken: '<cfoutput>#csrfToken#</cfoutput>',
						themeName: $("#themeName").val(),
						themeId: $("#selectedThemeId").val()
					},
					success: newThemeResult, // calls the result function.
					error: function(ErrorMsg) {
						console.log('Error' + ErrorMsg);
					}
				// Extract any errors. This is a new jQuery promise based function as of jQuery 1.8.
				}).fail(function (jqXHR, textStatus, error) {

					// The full response is: jqXHR.responseText, but we just want to extract the error.
					$.when(kendo.ui.ExtAlertDialog.show({ title: "Error while consuming the createNewThemeFromCurrentTheme function", message: error, icon: "k-ext-error", width: "<cfoutput>#application.kendoExtendedUiWindowWidth#</cfoutput>" }) // or k-ext-error, k-ext-information, k-ext-question, k-ext-warning.  You can also specify height.
						).done(function () {
						// Do nothing
					});		
				});	
			}

			// Submit the data and close this window.
			function newThemeResult(response){
				// alert(response)
				// Note: the response is the new themeId 
				// Open the new theme in the theme detail window
				createAdminInterfaceWindow(30, response.themeId);
				// Refresh the theme settings window
				$("#themeSettingsWindow").data("kendoWindow").refresh();
				// Close the this window
				$('#newThemeWindow').kendoWindow('destroy');
			}
			
		});//...document.ready
		
		// I am having the dreaded 'Cannot read properties of undefined (reading 'value')' error when reading the copythemeid form so I am saving it when the user makes a change in the dropdown. 
		function saveThemeIdValue(themeId){
			$("#selectedThemeId").val(themeId);
		}
	</script>
	
	<form id="newThemeForm" action="#" method="post" data-role="validator">
	<input type="hidden" name="selectedThemeId" id="selectedThemeId" value="">
	<table align="center" class="k-content tableBorder" width="100%" cellpadding="2" cellspacing="0" border="0">
	  <cfsilent>
			<!---The first content class in the table should be empty. --->
			<cfset thisContentClass = HtmlUtilsObj.getKendoClass('')>
			<!--- Set the colspan property for borders --->
			<cfset thisColSpan = "2">
	  </cfsilent>
	  <tr height="1px">
		  <td align="left" valign="top" colspan="2" class="<cfoutput>#thisContentClass#</cfoutput>"></td>
	  </tr>
	  <tr height="30px">
		<td align="left" class="<cfoutput>#thisContentClass#</cfoutput>" colspan="2"> 
			A theme has scores of shared settings. In order to create a new theme, please select a <b>current theme</b> that you would like to start from. Pay attention to the primary colors of the buttons and the color of the Logos and the color at the top of the blog post calender icons when copying an existing theme. You will want to match these primary accent colors when choosing new backgrounds and Logos for your new theme. 
		</td>
	  </tr>
	  <!-- Border -->
	  <tr height="2px">
	    	<td align="left" valign="top" colspan="<cfoutput>#thisColSpan#</cfoutput>" class="<cfoutput>#thisContentClass#</cfoutput>"></td>
	  </tr>
	  <cfsilent>
	  <!--- Set the class for alternating rows. --->
	  <!---After the first row, the content class should be the current class. --->
	  <cfset thisContentClass = HtmlUtilsObj.getKendoClass(thisContentClass)>
	  </cfsilent>
	  <tr height="2px">
		  <td align="left" valign="top" colspan="2" class="border <cfoutput>#thisContentClass#</cfoutput>"></td>
	  </tr>
	  <!-- Form content -->
  <cfif session.isMobile>
	  <tr valign="middle">
		<td class="<cfoutput>#thisContentClass#</cfoutput>" colspan="2">
			<label for="themeName">Theme Name</label>
		</td>
	   </tr>
	   <tr>
		<td class="<cfoutput>#thisContentClass#</cfoutput>" colspan="2">
			<input type="text" id="themeName" name="themeName" class="k-textbox" style="width: 95%" required> 
		</td>
	  </tr>
	<cfelse><!---<cfif session.isMobile>--->
	  <tr valign="middle" height="30px">
		<td align="right" class="<cfoutput>#thisContentClass#</cfoutput>">
			<label for="themeName">Theme Name</label>
		</td>
		<td align="left" class="<cfoutput>#thisContentClass#</cfoutput>" colspan="2">
			<input type="text" id="themeName" name="themeName" class="k-textbox" style="width: 50%" required> 
		</td>
	  </tr>
	</cfif>
	  <!-- Border -->
	  <tr height="2px">
		<td align="left" valign="top" colspan="<cfoutput>#thisColSpan#</cfoutput>" class="<cfoutput>#thisContentClass#</cfoutput>"></td>
	  </tr>
	  <cfsilent>
	  <!--- Set the class for alternating rows. --->
	  <!---After the first row, the content class should be the current class. --->
	  <cfset thisContentClass = HtmlUtilsObj.getKendoClass(thisContentClass)>
	  </cfsilent>
	  <tr height="2px">
		  <td align="left" valign="top" colspan="2" class="border <cfoutput>#thisContentClass#</cfoutput>"></td>
	  </tr>
	  <!-- Form content -->
	<cfif session.isMobile>
	  <tr valign="middle">
		<td class="<cfoutput>#thisContentClass#</cfoutput>" colspan="2">
			<label for="copyThemeId">Current Theme:</label>  
		</td>
	   </tr>
	   <tr>
		<td class="<cfoutput>#thisContentClass#</cfoutput>" colspan="2">
			<select id="copyThemeId" name="copyThemeId" style="width: 95%" required onchange="saveThemeIdValue(this.value)"></select>
		</td>
	  </tr>
	<cfelse><!---<cfif session.isMobile>--->
	  <tr valign="middle" height="30px">
		<td align="right" class="<cfoutput>#thisContentClass#</cfoutput>" width="20%">
			<label for="copyThemeId">Current Theme:</label>  
		</td>
		<td align="left" class="<cfoutput>#thisContentClass#</cfoutput>" width="80%">
			<select id="copyThemeId" name="copyThemeId" style="width: 50%" required onchange="saveThemeIdValue(this.value)"></select>
		</td>
	  </tr>
	</cfif>
	  <!-- Border -->
	  <tr height="2px">
		<td align="left" valign="top" colspan="<cfoutput>#thisColSpan#</cfoutput>" class="<cfoutput>#thisContentClass#</cfoutput>"></td>
	  </tr>
	  <cfsilent>
	  <!--- Set the class for alternating rows. --->
	  <!---After the first row, the content class should be the current class. --->
	  <cfset thisContentClass = HtmlUtilsObj.getKendoClass(thisContentClass)>
	  </cfsilent>
	  <tr height="2px">
		  <td align="left" valign="top" colspan="2" class="border <cfoutput>#thisContentClass#</cfoutput>"></td>
	  </tr>
	  <!-- Form content -->
	  <tr valign="middle" height="30px">
		<td align="right" class="<cfoutput>#thisContentClass#</cfoutput>"></td>
		<td align="left" class="<cfoutput>#thisContentClass#</cfoutput>">
			<button id="newThemeSubmit" name="newThemeSubmit" class="k-button k-primary" type="button">Submit</button>
		</td>
	  </tr>
	</table>
	</form>

</cfcase>
				
<!--- //************************************************************************************************
		Blog Options
//**************************************************************************************************--->
			
<cfcase value="38">
	
	<!---<cfdump var="#application.BlogOptionDbObj#">--->
			
	<!--- Blog options --->
	<!--- Max Entries --->
	<cfset maxEntries = application.BlogOptionDbObj.getEntriesPerBlogPage()>
	<cfset commentModeration = application.BlogOptionDbObj.getBlogModerated()>
	<cfset UseCaptcha = application.BlogOptionDbObj.getUseCaptcha()>
	<cfset gravatarsAllowed = application.BlogOptionDbObj.getAllowGravatar()>
	<!--- Get the blog options from the Blog Option object --->
	<cfset blogOptionId = application.BlogOptionDbObj.getBlogOptionId()>
	<cfset jQueryCDNPath = application.BlogOptionDbObj.getJQueryCDNPath()>
	<cfset kendoCommercial = application.BlogOptionDbObj.getKendoCommercial()>
	<cfset kendoFolderPath = application.BlogOptionDbObj.getKendoFolderPath()>
	<cfset useSsl = application.BlogOptionDbObj.getUseSsl()>
	<cfset serverRewriteRuleInPlace = application.BlogOptionDbObj.getServerRewriteRuleInPlace()>
	<cfset deferScriptsAndCss = application.BlogOptionDbObj.getDeferScriptsAndCss()>
	<cfset minimizeCode = application.BlogOptionDbObj.getMinimizeCode()>
	<cfset disableCache = application.BlogOptionDbObj.getDisableCache()>
	<cfset includeGsap = application.BlogOptionDbObj.getIncludeGsap()>
	<cfset includeDisqus = application.BlogOptionDbObj.getIncludeDisqus()>
	<cfset defaultMediaPlayer = application.BlogOptionDbObj.getDefaultMediaPlayer()>
	<cfset backgroundImageResolution = application.BlogOptionDbObj.getBackgroundImageResolution()>
	<cfset googleAnalyticsString = application.BlogOptionDbObj.getGoogleAnalyticsString()>
	<cfset addThisApiKey = application.BlogOptionDbObj.getAddThisApiKey()>
	<cfset addThisToolboxString = application.BlogOptionDbObj.getAddThisToolboxString()>
	<!--- Note: the API for Disqus changed recently, now we only need the blog identifier and the API Key. I am keeping the secret field for potential future use --->
	<cfset disqusBlogIdentifier = application.BlogOptionDbObj.getDisqusBlogIdentifier()>
	<cfset disqusApiKey = application.BlogOptionDbObj.getDisqusApiKey()>
	<cfset disqusApiSecret = application.BlogOptionDbObj.getDisqusApiSecret()>
	<!--- The following 3 Disqus vars are no longer needed. --->
	<cfset disqusAuthTokenKey = application.BlogOptionDbObj.getDisqusAuthTokenKey()>
	<cfset disqusAuthUrl = application.BlogOptionDbObj.getDisqusAuthUrl()>
	<cfset disqusAuthTokenUrl = application.BlogOptionDbObj.getDisqusAuthTokenUrl()>
	<cfset bingMapsApiKey = application.BlogOptionDbObj.getBingMapsApiKey()>
	<cfset facebookAppId = application.BlogOptionDbObj.getFacebookAppId()>
	<cfset twitterAppId = application.BlogOptionDbObj.getTwitterAppId()>
		
	<style>
		.collapsible {
			cursor: pointer;
			padding: 10px;
			width: 98%;
			border: thin;
			border-style: solid;
			text-align: left;
			outline: none;
			font-size: 15px;
			transition: max-height 0.2s ease-out;
		}

		.collapsible:after {
			content: '\25BC';
			color: white;
			font-weight: bold;
			float: right;
			margin-left: 5px;
			margin-left: 5px;
		}

		.active:after {
		  content: "\25B2";
		}

		.content {
		  padding: 0 18px;
		  display: none;
		  overflow: hidden;
		}
	</style>
		
	<script>
		
		// Numeric inputs
		$("#entriesPerBlogPage").kendoNumericTextBox({
			decimals: 0,
			format: "#",
			round: true
		});
		
		// !!! Note on the validators, all forms need a name attribute, otherwise the positioning of the messages will not work. --->
		$(document).ready(function() {

			var optionsValidator = $("#optionsForm").kendoValidator({
				// Set up custom validation rules 
				rules: {
					// The theme must be unique. 
					themeIsUnique:
					function(input){
						// Do not continue if the theme name is found in the currentTheme list 
						if (input.is("[id='themeName']") && ( listFind( themeList, input.val() ) != 0 ) ){
							// Display an error on the page.
							input.attr("data-themeIsUnique-msg", "Theme name already exists");
							// Focus on the current element
							$( "#theme" ).focus();
							return false;
						}                                    
						return true;
					},
				}
			}).data("kendoValidator");

			// Invoked when the submit button is clicked. Insted of using '$("form").submit(function(event) {' and 'event.preventDefault();', We are using direct binding here to speed up the event.
			var optionsSubmit = $('#optionsSubmit');
			optionsSubmit.on('click', function(e){ 
				
				e.preventDefault();         
				if (optionsValidator.validate()) {
					
					// Open up a please wait dialog
					$.when(kendo.ui.ExtWaitDialog.show({ title: "Please wait...", message: "Please wait while we save the data.", width: "<cfoutput>#application.kendoExtendedUiWindowWidth#</cfoutput>", icon: "k-ext-information" }));

					// Send data to server
					setTimeout(function() {
						postOptions();
					}, 250);
					
				} else {

					$.when(kendo.ui.ExtAlertDialog.show({ title: "There are errors", message: "Please correct the highlighted fields and try again", width: "<cfoutput>#application.kendoExtendedUiWindowWidth#</cfoutput>", icon: "k-ext-warning" }) // or k-ext-error, k-ext-question
						).done(function () {
						// Do nothing
					});
				}
			});

		});//...document.ready
		
		// Post method on the detail form called from the deptDetailFormValidator method on the detail page. The action variable will either be 'update' or 'insert'.
		function postOptions(){

			jQuery.ajax({
				type: 'post', 
				url: '<cfoutput>#application.baseUrl#</cfoutput>/common/cfc/ProxyController.cfc?method=saveBlogOptions&csrfToken=<cfoutput>#csrfToken#</cfoutput>',
				// Serialize the form. The csrfToken is in the form.
				data: $('#optionsForm').serialize(),
				dataType: "json",
				success: postOptionsResult, // calls the result function.
				error: function(ErrorMsg) {
					console.log('Error' + ErrorMsg);
				}
			// Extract any errors. This is a new jQuery promise based function as of jQuery 1.8.
			}).fail(function (jqXHR, textStatus, error) {
				// Close the wait window that was launched in the calling function.
				kendo.ui.ExtWaitDialog.hide();
				// Display the error. The full response is: jqXHR.responseText, but we just want to extract the error.
				$.when(kendo.ui.ExtAlertDialog.show({ title: "Error while consuming the saveBlogOptions function", message: error, icon: "k-ext-error", width: "<cfoutput>#application.kendoExtendedUiWindowWidth#</cfoutput>" }) // or k-ext-error, k-ext-information, k-ext-question, k-ext-warning.  You can also specify height.
					).done(function () {
					
				});		
			});
		};

		function postOptionsResult(response){
			// Close the wait window that was launched in the calling function.
			kendo.ui.ExtWaitDialog.hide();
			// Close this window.
			$('#optionsWindow').kendoWindow('destroy');
		}
	</script>
		
	<script>
		var coll = document.getElementsByClassName("collapsible");
		var i;

		for (i = 0; i < coll.length; i++) {
		  coll[i].addEventListener("click", function() {
			this.classList.toggle("active");
			var content = this.nextElementSibling;
			if (content.style.display === "block") {
			  content.style.display = "none";
			} else {
			  content.style.display = "block";
			}
		  });
		}
	</script>	
		
	<form id="optionsForm" action="#" method="post" data-role="validator">
	<!---<input type="hidden" name="csrfToken" id="csrfToken" value="<cfoutput>#csrfToken#</cfoutput>">--->
	<input type="hidden" name="blogOptionId" id="blogOptionId" value="<cfoutput>#blogOptionId#</cfoutput>">
	<table align="center" class="k-content" width="100%" cellpadding="2" cellspacing="0">
	  <cfsilent>
		<!---The first content class in the table should be empty. --->
		<cfset thisContentClass = HtmlUtilsObj.getKendoClass('')>
		<!--- Set the colspan property for borders --->
		<cfset thisColSpan = "2">
	  </cfsilent>
	  <tr height="1px">
		  <td align="left" valign="top" colspan="2" class="<cfoutput>#thisContentClass#</cfoutput>"></td>
	  </tr>
	  <tr valign="middle" height="30px">
		<td valign="bottom" align="left" class="<cfoutput>#thisContentClass#</cfoutput>" colspan="<cfoutput>#thisColSpan#</cfoutput>">
			These Blog Options can be changed at any time. However, there may be required bits of data that are required, for example- such as obtaining and entering a Disqus key. There are a number of options here, but if you just want to get up and running as soon as possible we recommend:
			<ol>
				<li>Install a SSL certificate on your server and check the use SSL checkbox</li>
				<li>If you have a server re-write rule in place on the server to remove the index.cfm, check the server rewrite rule checkbox to make your links more concise</li>
				<li>Obtaining an AddThis Key and using the AddThis sharing library</li>
				<li>Obtaining a BingMaps Key in order to embed maps into your posts</li>
				<li>Leaving the other default settings as they are unless you really want to use the Disqus commenting system or the Greensock animation library. </li>
			</ol>
		</td>
	  </tr>
	  <tr height="1px">
		  <td align="left" valign="top" colspan="2" class="border <cfoutput>#thisContentClass#</cfoutput>"></td>
	  </tr>
	  <!-- Form content -->
	  <tr valign="middle" height="30px">
		<td valign="bottom" align="left" class="<cfoutput>#thisContentClass#</cfoutput>" colspan="<cfoutput>#thisColSpan#</cfoutput>">
			If possible, you should always try to use SSL. However, this does require a certificate on the server and the site can be used without a SSL certificate. Be aware that your SEO score will suffer without SSL, and you may not be able to use any of the third party libraries that come with the blog, such as Bing maps or Disqus. Your security my also be impacted negatively.
		</td>
	  </tr>
	  <tr height="1px">
		  <td align="left" valign="top" colspan="2" class="border <cfoutput>#thisContentClass#</cfoutput>"></td>
	  </tr>
	  <tr valign="middle" height="30px">
		<td align="right" class="<cfoutput>#thisContentClass#</cfoutput>" style="width:<cfif session.isMobile>60<cfelse>20</cfif>%">Use SSL:</td>
		<td align="left" class="<cfoutput>#thisContentClass#</cfoutput>" style="width:<cfif session.isMobile>40<cfelse>80</cfif>%">
			<input type="checkbox" id="useSsl" name="useSsl" value="1" <cfif useSsl>checked</cfif>>
		</td>
	  </tr>
	  <cfsilent>
	  <!--- Set the class for alternating rows. --->
	  <!---After the first row, the content class should be the current class. --->
	  <cfset thisContentClass = HtmlUtilsObj.getKendoClass(thisContentClass)>
	  </cfsilent>
	  <tr height="2px">
		  <td align="left" valign="top" colspan="2" class="border <cfoutput>#thisContentClass#</cfoutput>"></td>
	  </tr>
	  <!-- Rewrite rule -->
	  <tr valign="middle" height="30px">
		<td valign="bottom" align="left" class="<cfoutput>#thisContentClass#</cfoutput>" colspan="<cfoutput>#thisColSpan#</cfoutput>">
			A 'Server Rewrite Rule' essentially removes the index.cfm from all of your public pages and makes it easier for the search engines to digest the content in a SEO friendly way. The server re-write rules are placed on the server. You may have to get your server or hosting administrator involved to get it working on the server. If you have a server rewite rule on the server, and you're sure that it works, check the box below so that Galaxie Blog can generate the proper links. Be sure that your server side rewrite rules work before checking this box as you may not be able to get bck into this site unless you have direct access to the database to disable this setting once it is checked.
		</td>
	  </tr>
	  <tr height="1px">
		  <td align="left" valign="top" colspan="2" class="border <cfoutput>#thisContentClass#</cfoutput>"></td>
	  </tr>
	  <tr valign="middle" height="30px">
		<td align="right" class="<cfoutput>#thisContentClass#</cfoutput>">Server Rewrite Rule in place?</td>
		<td align="left" class="<cfoutput>#thisContentClass#</cfoutput>">
			<input type="checkbox" name="serverRewriteRuleInPlace" id="serverRewriteRuleInPlace" value="1" <cfif serverRewriteRuleInPlace>checked</cfif>>
		</td>
	  </tr>
	  <!-- Border -->
	  <tr height="2px">
		  <td align="left" valign="top" colspan="<cfoutput>#thisColSpan#</cfoutput>" class="<cfoutput>#thisContentClass#</cfoutput>"></td>
	  </tr>
	  <cfsilent>
	  <!--- Set the class for alternating rows. --->
	  <!---After the first row, the content class should be the current class. --->
	  <cfset thisContentClass = HtmlUtilsObj.getKendoClass(thisContentClass)>
	  </cfsilent>
	  <tr height="2px">
		  <td align="left" valign="top" colspan="2" class="border <cfoutput>#thisContentClass#</cfoutput>"></td>
	  </tr>
	  <!-- Defer scripts -->
	  <tr valign="middle" height="30px">
		<td valign="bottom" align="left" class="<cfoutput>#thisContentClass#</cfoutput>" colspan="<cfoutput>#thisColSpan#</cfoutput>">
			Deferring the loading of non-essential scripts speeds up the loading of the site making the initial site to load faster. It is highly recommened to keep this setting unless you absolutely need all of the scripts to load before rendering the page.
		</td>
	  </tr>
	  <tr height="1px">
		  <td align="left" valign="top" colspan="2" class="border <cfoutput>#thisContentClass#</cfoutput>"></td>
	  </tr>
	  <tr valign="middle" height="30px">
		<td align="right" class="<cfoutput>#thisContentClass#</cfoutput>">Defer non-essential scripts?</td>
		<td align="left" class="<cfoutput>#thisContentClass#</cfoutput>">
			<input type="checkbox" name="deferScriptsAndCss" id="deferScriptsAndCss" value="1" <cfif deferScriptsAndCss>checked</cfif>>
		</td>
	  </tr>
	  <!-- Border -->
	  <tr height="2px">
		  <td align="left" valign="top" colspan="<cfoutput>#thisColSpan#</cfoutput>" class="<cfoutput>#thisContentClass#</cfoutput>"></td>
	  </tr>
	  <cfsilent>
	  <!--- Set the class for alternating rows. --->
	  <!---After the first row, the content class should be the current class. --->
	  <cfset thisContentClass = HtmlUtilsObj.getKendoClass(thisContentClass)>
	  </cfsilent>
	  <tr height="2px">
		  <td align="left" valign="top" colspan="2" class="border <cfoutput>#thisContentClass#</cfoutput>"></td>
	  </tr>
	  <!-- Minimize Javascript -->
	  <tr valign="middle" height="30px">
		<td valign="bottom" align="left" class="<cfoutput>#thisContentClass#</cfoutput>" colspan="<cfoutput>#thisColSpan#</cfoutput>">
			Galaxie Blog has logic to minimize the various Javascript and CSS in order to load the page quicker. This setting should be checked when you are in a production environment to improve page performance. You may want to turn this off if you are trying to debug code as the code is much easier to read when it is not compressed.
		</td>
	  </tr>
	  <tr height="1px">
		  <td align="left" valign="top" colspan="2" class="border <cfoutput>#thisContentClass#</cfoutput>"></td>
	  </tr>
	  <tr valign="middle" height="30px">
		<td align="right" class="<cfoutput>#thisContentClass#</cfoutput>">Minimize Code?</td>
		<td align="left" class="<cfoutput>#thisContentClass#</cfoutput>">
			<input type="checkbox" name="minimizeCode" id="minimizeCode" value="1" <cfif minimizeCode>checked</cfif>>
		</td>
	  </tr>
	  <!-- Border -->
	  <tr height="2px">
		  <td align="left" valign="top" colspan="<cfoutput>#thisColSpan#</cfoutput>" class="<cfoutput>#thisContentClass#</cfoutput>"></td>
	  </tr>
	  <cfsilent>
	  <!--- Set the class for alternating rows. --->
	  <!---After the first row, the content class should be the current class. --->
	  <cfset thisContentClass = HtmlUtilsObj.getKendoClass(thisContentClass)>
	  </cfsilent>
	  <tr height="2px">
		  <td align="left" valign="top" colspan="2" class="border <cfoutput>#thisContentClass#</cfoutput>"></td>
	  </tr>
	  <!-- Caching -->
	  <tr valign="middle" height="30px">
		<td valign="bottom" align="left" class="<cfoutput>#thisContentClass#</cfoutput>" colspan="<cfoutput>#thisColSpan#</cfoutput>">
			Galaxie Blog's caching features enhances performance and should <b>be enabled in production environments</b>. However, you will want to disable caching until you are <b>completely</b> finished setting up your site. This option should be checked when you need to immediately see your changes reflected on the front end after making site changes or writing new code. 
		</td>
	  </tr>
	  <tr height="1px">
		  <td align="left" valign="top" colspan="2" class="border <cfoutput>#thisContentClass#</cfoutput>"></td>
	  </tr>
	  <tr valign="middle" height="30px">
		<td align="right" class="<cfoutput>#thisContentClass#</cfoutput>">Disable Cache?</td>
		<td align="left" class="<cfoutput>#thisContentClass#</cfoutput>">
			<input type="checkbox" name="disableCache" id="disableCache" value="1" <cfif disableCache>checked</cfif>>
		</td>
	  </tr>  
	  <!-- Border -->
	  <tr height="2px">
		  <td align="left" valign="top" colspan="<cfoutput>#thisColSpan#</cfoutput>" class="<cfoutput>#thisContentClass#</cfoutput>"></td>
	  </tr>
		
	  <!-- Border -->
	  <tr height="2px">
		  <td align="left" valign="top" colspan="<cfoutput>#thisColSpan#</cfoutput>" class="<cfoutput>#thisContentClass#</cfoutput>"></td>
	  </tr>
	  <cfsilent>
	  <!--- Set the class for alternating rows. --->
	  <!---After the first row, the content class should be the current class. --->
	  <cfset thisContentClass = HtmlUtilsObj.getKendoClass(thisContentClass)>
	  </cfsilent>
	  <tr height="2px">
		  <td align="left" valign="top" colspan="2" class="border <cfoutput>#thisContentClass#</cfoutput>"></td>
	  </tr>
	  <!-- Caching -->
	  <tr valign="middle" height="30px">
		<td valign="bottom" align="left" class="<cfoutput>#thisContentClass#</cfoutput>" colspan="<cfoutput>#thisColSpan#</cfoutput>">
			You can adjust how many blog posts will appear on the blog landing page. The default setting is ten (10) posts per page, however, if you extensively use maps and or videos, you may want to consider adjusting this to five (5) posts per page as both maps and videos consume a lot of resources and will increase the page load time. Alternatively, if you are minimal in your usage of media, or use the &lt;more&gt; tag quite often to break up the content of your posts, you can set this to a max of twenty five (25) posts.
		</td>
	  </tr>
	  <tr height="1px">
		  <td align="left" valign="top" colspan="2" class="border <cfoutput>#thisContentClass#</cfoutput>"></td>
	  </tr>
	  <tr valign="middle" height="30px">
		<td align="right" class="<cfoutput>#thisContentClass#</cfoutput>">
			<label for="entriesPerBlogPage">Number of posts per page</label>
		</td>
		<td align="left" class="<cfoutput>#thisContentClass#</cfoutput>">
			<input type="number" id="entriesPerBlogPage" name="entriesPerBlogPage" min="5" max="25" step="1" value="<cfoutput>#maxEntries#</cfoutput>" class="k-textbox" width="15%" > 
		</td>
	  </tr>  
	  <!-- Border -->
	  <tr height="2px">
		  <td align="left" valign="top" colspan="<cfoutput>#thisColSpan#</cfoutput>" class="<cfoutput>#thisContentClass#</cfoutput>"></td>
	  </tr>
	  
	</table>
	<br/>
		
	<!---//***********************************************************************************************
						Jquery and Kendo UI
	//************************************************************************************************--->
	<button type="button" class="collapsible k-header">Jquery Location and Kendo UI</button>
	<div class="content k-content">
		<table align="center" class="k-content" width="100%" cellpadding="2" cellspacing="0">
			
		  <cfsilent>
			<!---The first content class in the table should be empty. --->
			<cfset thisContentClass = HtmlUtilsObj.getKendoClass('')>
			<!--- Set the colspan property for borders --->
			<cfset thisColSpan = "2">
		  </cfsilent>
	
		  <tr height="1px">
			  <td align="left" valign="top" colspan="2" class="<cfoutput>#thisContentClass#</cfoutput>">
			  	It is generally recommended to use the google JQuery CDN. You should only change this if you want to change the JQuery version or if you want to host JQuery on your own server.
			  </td>
		  </tr>
		  <!-- Border -->
		  <tr height="2px">
			  <td align="left" valign="top" colspan="<cfoutput>#thisColSpan#</cfoutput>" class="<cfoutput>#thisContentClass#</cfoutput>"></td>
		  </tr>
		  <tr>
		<cfif session.isMobile>
		  <tr valign="middle">
			<td class="<cfoutput>#thisContentClass#</cfoutput>" colspan="2">
				<label for="jQueryCDNPath">JQuery CDN Location:</label>
			</td>
		   </tr>
		   <tr>
			<td class="<cfoutput>#thisContentClass#</cfoutput>" colspan="2">
				<input id="jQueryCDNPath" name="jQueryCDNPath" type="text" value="<cfoutput>#jQueryCDNPath#</cfoutput>" class="k-textbox" style="width: 95%" />    
			</td>
		  </tr>
		<cfelse><!---<cfif session.isMobile>--->
			<td align="right" class="<cfoutput>#thisContentClass#</cfoutput>" style="width: 25%"> 
				<label for="jQueryCDNPath">JQuery CDN Location:</label>
			</td>
			<td class="<cfoutput>#thisContentClass#</cfoutput>">
				<input id="jQueryCDNPath" name="jQueryCDNPath" type="text" value="<cfoutput>#jQueryCDNPath#</cfoutput>" class="k-textbox" style="width: 50%" />    
			</td>
		  </tr>
		</cfif>
		  <!-- Border -->
		  <tr height="2px">
			  <td align="left" valign="top" colspan="<cfoutput>#thisColSpan#</cfoutput>" class="<cfoutput>#thisContentClass#</cfoutput>"></td>
		  </tr>
		  <cfsilent>
		  <!--- Set the class for alternating rows. --->
		  <!---After the first row, the content class should be the current class. --->
		  <cfset thisContentClass = HtmlUtilsObj.getKendoClass(thisContentClass)>
		  </cfsilent>
			 
		  <tr height="2px">
		  	<td align="left" valign="bottom" colspan="2" class="border <cfoutput>#thisContentClass#</cfoutput>"></td>
		  </tr>
		  <tr valign="middle" height="30px">
			<td valign="bottom" align="left" class="<cfoutput>#thisContentClass#</cfoutput>" colspan="<cfoutput>#thisColSpan#</cfoutput>">
				There are two Kendo UI libraries available: the open sourced version: and the Proffesional Edition which requires a license. This blog is fully functional using the open source free edition. Please check the box if you are using your own license for the commercial edition. If you change this setting, make sure to enter the path to the Kendo folder location that you're using below. 
			</td>
		  </tr>
		  <tr height="1px">
			  <td align="left" valign="top" colspan="2" class="border <cfoutput>#thisContentClass#</cfoutput>"></td>
		  </tr>
		<cfif session.isMobile>
		  <tr valign="middle">
			<td class="<cfoutput>#thisContentClass#</cfoutput>" colspan="2">
				<label for="kendoCommercial">Commercial Kendo UI Edition?</label>
			</td>
		   </tr>
		   <tr>
			<td class="<cfoutput>#thisContentClass#</cfoutput>" colspan="2">
				<input type="checkbox" name="kendoCommercial" id="kendoCommercial" <cfif kendoCommercial>checked</cfif>>
			</td>
		  </tr>
		<cfelse><!---<cfif session.isMobile>--->
		  <tr valign="middle" height="30px">
			<td valign="bottom" align="right" class="<cfoutput>#thisContentClass#</cfoutput>" style="width:20%">
				<label for="kendoCommercial">Commercial Kendo UI Edition?</label>
			</td>
			<td valign="bottom" align="left" class="<cfoutput>#thisContentClass#</cfoutput>" style="width:80%">
				<input type="checkbox" name="kendoCommercial" id="kendoCommercial" <cfif kendoCommercial>checked</cfif>>
			</td>
		  </tr>
		</cfif>
		  <!-- Border -->
		  <tr height="2px">
			<td align="left" valign="top" colspan="<cfoutput>#thisColSpan#</cfoutput>" class="<cfoutput>#thisContentClass#</cfoutput>"></td>
		  </tr>
		  <cfsilent>
		  <!--- Set the class for alternating rows. --->
		  <!---After the first row, the content class should be the current class. --->
		  <cfset thisContentClass = HtmlUtilsObj.getKendoClass(thisContentClass)>
		  </cfsilent>
		  <tr height="2px">
			  <td align="left" valign="bottom" colspan="2" class="border <cfoutput>#thisContentClass#</cfoutput>"></td>
		  </tr>
		  <tr valign="middle" height="30px">
			<td valign="bottom" align="left" class="<cfoutput>#thisContentClass#</cfoutput>" colspan="<cfoutput>#thisColSpan#</cfoutput>">
				Only change this setting if you plan on moving the Kendo Core folder or if you use your own personal Kendo UI Professional license.<br/>
				Note: we have tested the blog using Kendo UI v2019.2.619, using a later version may require changes to the menu related code due to the different CSS rules.
			</td>
		  </tr>
		  <tr height="1px">
			  <td align="left" valign="top" colspan="2" class="border <cfoutput>#thisContentClass#</cfoutput>"></td>
		  </tr>
		<cfif session.isMobile>
		  <tr valign="middle">
			<td class="<cfoutput>#thisContentClass#</cfoutput>" colspan="2">
				<label for="kendoFolderPath">Kendo Folder Path:</label>
			</td>
		   </tr>
		   <tr>
			<td class="<cfoutput>#thisContentClass#</cfoutput>" colspan="2">
				<input type="text" name="kendoFolderPath" id="kendoFolderPath" value="<cfoutput>#kendoFolderPath#</cfoutput>" class="k-textbox" style="width: 95%" required />
			</td>
		  </tr>
		<cfelse><!---<cfif session.isMobile>--->
		  <tr valign="middle" height="30px">
			<td valign="center" align="right" class="<cfoutput>#thisContentClass#</cfoutput>">
				<label for="kendoFolderPath">Kendo Folder Path:</label>
			</td>
			<td valign="bottom" align="left" class="<cfoutput>#thisContentClass#</cfoutput>">
				<input type="text" name="kendoFolderPath" id="kendoFolderPath" value="<cfoutput>#kendoFolderPath#</cfoutput>" class="k-textbox" style="width: 50%" required />
			</td>
		  </tr>
		</cfif>
		  <!-- Border -->
		  <tr height="2px">
			<td align="left" valign="top" colspan="<cfoutput>#thisColSpan#</cfoutput>" class="<cfoutput>#thisContentClass#</cfoutput>"></td>
		  </tr>
		
		</table>
	</div>
			
	<!---//***********************************************************************************************
						Google Analytics GTAG String
	//************************************************************************************************--->
	<button type="button" class="collapsible k-header">Google Analytics</button>
	<div class="content k-content">
		<table align="center" class="k-content" width="100%" cellpadding="2" cellspacing="0">
		  <cfsilent>
			<!---The first content class in the table should be empty. --->
			<cfset thisContentClass = HtmlUtilsObj.getKendoClass('')>
			<!--- Set the colspan property for borders --->
			<cfset thisColSpan = "2">
		  </cfsilent>
				
		  <!-- Border -->
		  <tr height="2px">
			  <td align="left" valign="top" colspan="<cfoutput>#thisColSpan#</cfoutput>" class="<cfoutput>#thisContentClass#</cfoutput>"></td>
		  </tr>
		  <cfsilent>
		  <!--- Set the class for alternating rows. --->
		  <!---After the first row, the content class should be the current class. --->
		  <cfset thisContentClass = HtmlUtilsObj.getKendoClass(thisContentClass)>
		  </cfsilent>
		  <tr height="1px">
			  <td align="left" valign="top" colspan="2" class="<cfoutput>#thisContentClass#</cfoutput>"></td>
		  </tr>
		  <tr>
			<td colspan="2"> 
				<p>Google Analytics may be incorporated to determine your page traffic trends. To use Google Analytics, you must first obtain a free Google GTAG string, see <a href="https://developers.google.com/tag-platform/gtagjs/install">https://developers.google.com/tag-platform/gtagjs/install</a> for more information.</p>
				
				<p>To use Google Analytics, enter in the GTAG strings below (ie G-XXXXXX). If you have more than one GTAG string, separate them with comma's. You can enter as many GTAG strings below as you need. You don't need to do anything else other than to enter in your GTAG string(s), if a string is found, Galaxie Blog will configure Google Analytics for you.</p>
			</td>
		  </tr>
		  <!-- Border -->
		  <tr height="2px">
			  <td align="left" valign="top" colspan="<cfoutput>#thisColSpan#</cfoutput>" class="<cfoutput>#thisContentClass#</cfoutput>"></td>
		  </tr>
		<cfif session.isMobile>
		  <tr valign="middle">
			<td class="<cfoutput>#thisContentClass#</cfoutput>" colspan="2">
				<label for="googleAnalyticsString">Google GTAG String(s):</label>
			</td>
		   </tr>
		   <tr>
			<td class="<cfoutput>#thisContentClass#</cfoutput>" colspan="2">
				<input type="text" name="googleAnalyticsString" id="googleAnalyticsString" value="<cfoutput>#googleAnalyticsString#</cfoutput>" class="k-textbox" style="width: 50%" />
			</td>
		  </tr>
		<cfelse><!---<cfif session.isMobile>--->
		  <tr>
			<td align="right" class="<cfoutput>#thisContentClass#</cfoutput>" style="width: 20%"> 
				<label for="googleAnalyticsString">Google GTAG String(s):</label>
			</td>
			<td class="<cfoutput>#thisContentClass#</cfoutput>">
				<input type="text" name="googleAnalyticsString" id="googleAnalyticsString" value="<cfoutput>#googleAnalyticsString#</cfoutput>" class="k-textbox" style="width: 50%" />
			</td>
		  </tr>
		</cfif>
		  <!-- Border -->
		  <tr height="2px" class="containerWidths">
			  <td align="left" valign="top" colspan="<cfoutput>#thisColSpan#</cfoutput>" class="<cfoutput>#thisContentClass#</cfoutput>"></td>
		  </tr>
			  
		  <!-- Border -->
		  <tr height="2px">
			<td align="left" valign="top" colspan="<cfoutput>#thisColSpan#</cfoutput>" class="<cfoutput>#thisContentClass#</cfoutput>"></td>
		  </tr>
		</table>
	</div>
			
	<!---//***********************************************************************************************
						Add This
	//************************************************************************************************--->
	<button type="button" class="collapsible k-header">Add This Library</button>
	<div class="content k-content">
		<table align="center" class="k-content" width="100%" cellpadding="2" cellspacing="0">
			
		  <cfsilent>
			<!---The first content class in the table should be empty. --->
			<cfset thisContentClass = HtmlUtilsObj.getKendoClass('')>
			<!--- Set the colspan property for borders --->
			<cfset thisColSpan = "2">
		  </cfsilent>
			 
		  <tr height="1px">
			  <td align="left" valign="top" colspan="2" class="<cfoutput>#thisContentClass#</cfoutput>"></td>
		  </tr>
		  <tr height="1px">
			  <td align="left" valign="top" colspan="2" class="<cfoutput>#thisContentClass#</cfoutput>">
			  	AddThis is the library that the blog uses to allow others to share your posts to various social sites such as Facebook. AddThis is a free library, however, you must enter your own personal AddThis key. Once you enter in an AddThis API key, Galaxie will replace its built in commenting system with AddThis. Go to <a href="https://www.addthis.com/login?next=/dashboard">https://www.addthis.com/login?next=/dashboard</a> for more information and to sign up for a free API key.
			  </td>
		  </tr>
		  <!-- Border -->
		  <tr height="2px">
			  <td align="left" valign="top" colspan="<cfoutput>#thisColSpan#</cfoutput>" class="<cfoutput>#thisContentClass#</cfoutput>"></td>
		  </tr>
		<cfif session.isMobile>
		  <tr valign="middle">
			<td class="<cfoutput>#thisContentClass#</cfoutput>" colspan="2">
				<label for="addThisApiKey">AddThis API Key:</label>
			</td>
		   </tr>
		   <tr>
			<td class="<cfoutput>#thisContentClass#</cfoutput>" colspan="2">
				<input type="text" name="addThisApiKey" id="addThisApiKey" value="<cfoutput>#addThisApiKey#</cfoutput>" class="k-textbox" style="width: 95%" />
			</td>
		  </tr>
		<cfelse><!---<cfif session.isMobile>--->
		  <tr>
			<td align="right" class="<cfoutput>#thisContentClass#</cfoutput>" style="width: 20%"> 
				<label for="addThisApiKey">AddThis API Key:</label>
			</td>
			<td class="<cfoutput>#thisContentClass#</cfoutput>">
				<input type="text" name="addThisApiKey" id="addThisApiKey" value="<cfoutput>#addThisApiKey#</cfoutput>" class="k-textbox" style="width: 50%" />
			</td>
		  </tr>
		</cfif>  
		  <!-- Border -->
		  <tr height="2px">
			  <td align="left" valign="top" colspan="<cfoutput>#thisColSpan#</cfoutput>" class="<cfoutput>#thisContentClass#</cfoutput>"></td>
		  </tr>
		  <cfsilent>
		  <!--- Set the class for alternating rows. --->
		  <!---After the first row, the content class should be the current class. --->
		  <cfset thisContentClass = HtmlUtilsObj.getKendoClass(thisContentClass)>
		  </cfsilent>
		  <tr height="1px">
			  <td align="left" valign="top" colspan="2" class="<cfoutput>#thisContentClass#</cfoutput>"></td>
		  </tr>
		  <tr height="1px">
			  <td align="left" valign="top" colspan="2" class="<cfoutput>#thisContentClass#</cfoutput>">
			  	The AddThis Toolbox string is a string that AddThis provides to render the proper code. Type in the string exactly as it is given on the AddThis site when signing up for an API Key.
			  </td>
		  </tr>
		  <!-- Border -->
		  <tr height="2px">
			  <td align="left" valign="top" colspan="<cfoutput>#thisColSpan#</cfoutput>" class="<cfoutput>#thisContentClass#</cfoutput>"></td>
		  </tr>
		<cfif session.isMobile>
		  <tr valign="middle">
			<td class="<cfoutput>#thisContentClass#</cfoutput>" colspan="2">
				<label for="addThisToolboxString">AddThis toolbox string:</label>
			</td>
		   </tr>
		   <tr>
			<td class="<cfoutput>#thisContentClass#</cfoutput>" colspan="2">
				<input type="text" name="addThisToolboxString" id="addThisToolboxString" value="<cfoutput>#addThisToolboxString#</cfoutput>" class="k-textbox" style="width: 95%" /> 
			</td>
		  </tr>
		<cfelse><!---<cfif session.isMobile>--->
		  <tr>
			<td align="right" class="<cfoutput>#thisContentClass#</cfoutput>" style="width: 20%"> 
				<label for="addThisToolboxString">AddThis toolbox string:</label>
			</td>
			<td class="<cfoutput>#thisContentClass#</cfoutput>">
				<input type="text" name="addThisToolboxString" id="addThisToolboxString" value="<cfoutput>#addThisToolboxString#</cfoutput>" class="k-textbox" style="width: 50%" /> 
			</td>
		  </tr>
		</cfif>	  
		  <!-- Border -->
		  <tr height="2px">
			<td align="left" valign="top" colspan="<cfoutput>#thisColSpan#</cfoutput>" class="<cfoutput>#thisContentClass#</cfoutput>"></td>
		  </tr>
		</table>
	</div>
			  
	<!---//***********************************************************************************************
						Bing Maps
	//************************************************************************************************--->
	<button type="button" class="collapsible k-header">Bing Maps Library</button>
	<div class="content k-content">
		<table align="center" class="k-content" width="100%" cellpadding="2" cellspacing="0">
			
		  <cfsilent>
			<!---The first content class in the table should be empty. --->
			<cfset thisContentClass = HtmlUtilsObj.getKendoClass('')>
			<!--- Set the colspan property for borders --->
			<cfset thisColSpan = "2">
		  </cfsilent>
			 
		  <tr height="1px">
			  <td align="left" valign="top" colspan="2" class="<cfoutput>#thisContentClass#</cfoutput>"></td>
		  </tr>
		  <tr height="1px">
			  <td align="left" valign="top" colspan="2" class="<cfoutput>#thisContentClass#</cfoutput>">
			  	Galaxie Blog has the ability to generate static maps and map routes using the Bing API. To generate a static or route, create or edit a post and click on the <b>Enclosure Editor</b> button. This will bring up an editor and it will allow you to easilly generate both static and map routes using a wysiwyg interface.  You may also embed maps within any post. You will need to sign up for a free Bing maps API key to add this functionality.
			  </td>
		  </tr>
		  <!-- Border -->
		  <tr height="2px">
			  <td align="left" valign="top" colspan="<cfoutput>#thisColSpan#</cfoutput>" class="<cfoutput>#thisContentClass#</cfoutput>"></td>
		  </tr>
		<cfif session.isMobile>
		  <tr valign="middle">
			<td class="<cfoutput>#thisContentClass#</cfoutput>" colspan="2">
				<label for="bingMapsApiKey">Bing Maps API Key:</label>
			</td>
		   </tr>
		   <tr>
			<td class="<cfoutput>#thisContentClass#</cfoutput>" colspan="2">
				<input type="text" name="bingMapsApiKey" id="bingMapsApiKey" value="<cfoutput>#bingMapsApiKey#</cfoutput>" class="k-textbox" style="width: 95%" />
			</td>
		  </tr>
		<cfelse><!---<cfif session.isMobile>--->
		  <tr>
			<td align="right" class="<cfoutput>#thisContentClass#</cfoutput>" style="width: 20%"> 
				<label for="bingMapsApiKey">Bing Maps API Key:</label>
			</td>
			<td class="<cfoutput>#thisContentClass#</cfoutput>">
				<input type="text" name="bingMapsApiKey" id="bingMapsApiKey" value="<cfoutput>#bingMapsApiKey#</cfoutput>" class="k-textbox" style="width: 50%" />
			</td>
		  </tr>
		</cfif>	  
		  <!-- Border -->
		  <tr height="2px">
			  <td align="left" valign="top" colspan="<cfoutput>#thisColSpan#</cfoutput>" class="<cfoutput>#thisContentClass#</cfoutput>"></td>
		  </tr>
		
		</table>
	</div>
			  
	<!---//***********************************************************************************************
						Disqus
	//************************************************************************************************--->
	<button type="button" class="collapsible k-header">Disqus Libary</button>
	<div class="content k-content">
		<table align="center" class="k-content" width="100%" cellpadding="2" cellspacing="0">
			
		  <cfsilent>
			<!---The first content class in the table should be empty. --->
			<cfset thisContentClass = HtmlUtilsObj.getKendoClass('')>
			<!--- Set the colspan property for borders --->
			<cfset thisColSpan = "2">
		  </cfsilent>
			 
		  <tr height="1px">
			  <td align="left" valign="top" colspan="2" class="<cfoutput>#thisContentClass#</cfoutput>"></td>
		  </tr>
		  <tr height="1px">
			  <td align="left" valign="top" colspan="2" class="<cfoutput>#thisContentClass#</cfoutput>">
			  	Disqus is an optional library that you can use to allow users to interact with your site and add comments. Disqus is fully integrated into Galaxie Blog and it only needs a few free keys provided by Disqus. There are some advantages and disadvantages to consider when using Disqus. It offers numerous tools to analyze your users and can cut down on spam significantly, however, it also requires the users to log into their own social media account to interact with your site. This may limit the number of comments that you receive on your site. It also requies loading additional external libraries that may cause a small performance hit if you choose to use it. Please see the Disqus site at <a href="https://disqus.com/">https://disqus.com/</a> for more information.
			  </td>
		  </tr>
		  <!-- Border -->
		  <tr height="2px">
			  <td align="left" valign="top" colspan="<cfoutput>#thisColSpan#</cfoutput>" class="<cfoutput>#thisContentClass#</cfoutput>"></td>
		  </tr>
		  <cfsilent>
		  <!--- Set the class for alternating rows. --->
		  <!---After the first row, the content class should be the current class. --->
		  <cfset thisContentClass = HtmlUtilsObj.getKendoClass(thisContentClass)>
		  </cfsilent>
		  <tr height="1px">
			  <td align="left" valign="top" colspan="2" class="<cfoutput>#thisContentClass#</cfoutput>"></td>
		  </tr>
		<cfif session.isMobile>
		  <tr valign="middle">
			<td class="<cfoutput>#thisContentClass#</cfoutput>" colspan="2">
				<label for="includeDisqus">Include Disqus:</label>
			</td>
		   </tr>
		   <tr>
			<td class="<cfoutput>#thisContentClass#</cfoutput>" colspan="2">
				<input type="checkbox" name="includeDisqus" id="includeDisqus" value="1" <cfif includeDisqus>checked</cfif> />
			</td>
		  </tr>
		<cfelse><!---<cfif session.isMobile>--->
		  <tr>
			<td align="right" class="<cfoutput>#thisContentClass#</cfoutput>" style="width: 20%"> 
				<label for="includeDisqus">Include Disqus:</label>
			</td>
			<td class="<cfoutput>#thisContentClass#</cfoutput>">
				<input type="checkbox" name="includeDisqus" id="includeDisqus" value="1" <cfif includeDisqus>checked</cfif> />
			</td>
		  </tr>
		</cfif>
		  <!-- Border -->
		  <tr height="2px">
			  <td align="left" valign="top" colspan="<cfoutput>#thisColSpan#</cfoutput>" class="<cfoutput>#thisContentClass#</cfoutput>"></td>
		  </tr>
		  <cfsilent>
		  <!--- Set the class for alternating rows. --->
		  <!---After the first row, the content class should be the current class. --->
		  <cfset thisContentClass = HtmlUtilsObj.getKendoClass(thisContentClass)>
		  </cfsilent>
		<cfif session.isMobile>
		  <tr valign="middle">
			<td class="<cfoutput>#thisContentClass#</cfoutput>" colspan="2">
				<label for="disqusBlogIdentifier">Disqus Blog Identifier:</label>
			</td>
		   </tr>
		   <tr>
			<td class="<cfoutput>#thisContentClass#</cfoutput>" colspan="2">
				<input type="text" name="disqusBlogIdentifier" id="disqusBlogIdentifier" value="<cfoutput>#disqusBlogIdentifier#</cfoutput>" class="k-textbox" style="width: 95%" />
			</td>
		  </tr>
		<cfelse><!---<cfif session.isMobile>--->
		  <tr>
			<td align="right" class="<cfoutput>#thisContentClass#</cfoutput>" style="width: 20%"> 
				<label for="disqusBlogIdentifier">Disqus Blog Identifier:</label>
			</td>
			<td class="<cfoutput>#thisContentClass#</cfoutput>">
				<input type="text" name="disqusBlogIdentifier" id="disqusBlogIdentifier" value="<cfoutput>#disqusBlogIdentifier#</cfoutput>" class="k-textbox" style="width: 50%" />
			</td>
		  </tr>
		</cfif>	  
		  <!-- Border -->
		  <tr height="2px">
			  <td align="left" valign="top" colspan="<cfoutput>#thisColSpan#</cfoutput>" class="<cfoutput>#thisContentClass#</cfoutput>"></td>
		  </tr>
		  <cfsilent>
		  <!--- Set the class for alternating rows. --->
		  <!---After the first row, the content class should be the current class. --->
		  <cfset thisContentClass = HtmlUtilsObj.getKendoClass(thisContentClass)>
		  </cfsilent>
		  <tr height="1px">
			  <td align="left" valign="top" colspan="2" class="<cfoutput>#thisContentClass#</cfoutput>"></td>
		  </tr>
		<cfif session.isMobile>
		  <tr valign="middle">
			<td class="<cfoutput>#thisContentClass#</cfoutput>" colspan="2">
				<label for="disqusApiKey">Disqus API Key:</label>
			</td>
		   </tr>
		   <tr>
			<td class="<cfoutput>#thisContentClass#</cfoutput>" colspan="2">
				<input type="text" name="disqusApiKey" id="disqusApiKey" value="<cfoutput>#disqusApiKey#</cfoutput>" class="k-textbox" style="width: 95%" /> 
			</td>
		  </tr>
		<cfelse><!---<cfif session.isMobile>--->
		  <tr>
			<td align="right" class="<cfoutput>#thisContentClass#</cfoutput>" style="width: 20%"> 
				<label for="disqusApiKey">Disqus API Key:</label>
			</td>
			<td class="<cfoutput>#thisContentClass#</cfoutput>">
				<input type="text" name="disqusApiKey" id="disqusApiKey" value="<cfoutput>#disqusApiKey#</cfoutput>" class="k-textbox" style="width: 50%" /> 
			</td>
		  </tr>
		</cfif>	  
		  <!-- Border -->
		  <tr height="2px">
			  <td align="left" valign="top" colspan="<cfoutput>#thisColSpan#</cfoutput>" class="<cfoutput>#thisContentClass#</cfoutput>"></td>
		  </tr>
		  <cfsilent>
		  <!--- Set the class for alternating rows. --->
		  <!---After the first row, the content class should be the current class. --->
		  <cfset thisContentClass = HtmlUtilsObj.getKendoClass(thisContentClass)>
		  </cfsilent>
		<cfif session.isMobile>
		  <tr valign="middle">
			<td class="<cfoutput>#thisContentClass#</cfoutput>" colspan="2">
				<label for="disqusApiSecret">Disqus API Secret:</label>
			</td>
		   </tr>
		   <tr>
			<td class="<cfoutput>#thisContentClass#</cfoutput>" colspan="2">
				<input type="text" name="disqusApiSecret" id="disqusApiSecret" value="<cfoutput>#disqusApiSecret#</cfoutput>" class="k-textbox" style="width: 95%" />
			</td>
		  </tr>
		<cfelse><!---<cfif session.isMobile>--->
		  <tr>
			<td align="right" class="<cfoutput>#thisContentClass#</cfoutput>" style="width: 20%"> 
				<label for="disqusApiSecret">Disqus API Secret:</label>
			</td>
			<td class="<cfoutput>#thisContentClass#</cfoutput>">
				<input type="text" name="disqusApiSecret" id="disqusApiSecret" value="<cfoutput>#disqusApiSecret#</cfoutput>" class="k-textbox" style="width: 50%" />
			</td>
		  </tr>
		</cfif>	
		<!--- The following fields are no longer needed (as of 2021) --->
		<!--- Start depracted disqus fields
		  <tr height="2px">
			  <td align="left" valign="top" colspan="<cfoutput>#thisColSpan#</cfoutput>" class="<cfoutput>#thisContentClass#</cfoutput>"></td>
		  </tr>
		  <cfsilent>
		  <cfset thisContentClass = HtmlUtilsObj.getKendoClass(thisContentClass)>
		  </cfsilent>
		<cfif session.isMobile>
		  <tr valign="middle">
			<td class="<cfoutput>#thisContentClass#</cfoutput>" colspan="2">
				<label for="disqusAuthTokenKey">Disqus Auth Token Key:</label>
			</td>
		   </tr>
		   <tr>
			<td class="<cfoutput>#thisContentClass#</cfoutput>" colspan="2">
				<input type="text" name="disqusAuthTokenKey" id="disqusAuthTokenKey" value="<cfoutput>#disqusAuthTokenKey#</cfoutput>" class="k-textbox" style="width: 95%" />
			</td>
		  </tr>
		<cfelse>
		  <tr>
			<td align="right" class="<cfoutput>#thisContentClass#</cfoutput>" style="width: 20%"> 
				<label for="disqusAuthTokenKey">Disqus Auth Token Key:</label>
			</td>
			<td class="<cfoutput>#thisContentClass#</cfoutput>">
				<input type="text" name="disqusAuthTokenKey" id="disqusAuthTokenKey" value="<cfoutput>#disqusAuthTokenKey#</cfoutput>" class="k-textbox" style="width: 50%" />
			</td>
		  </tr>
		</cfif>	  
		  <tr height="2px">
			  <td align="left" valign="top" colspan="<cfoutput>#thisColSpan#</cfoutput>" class="<cfoutput>#thisContentClass#</cfoutput>"></td>
		  </tr>
		  <cfsilent>
		  <cfset thisContentClass = HtmlUtilsObj.getKendoClass(thisContentClass)>
		  </cfsilent>
		<cfif session.isMobile>
		  <tr valign="middle">
			<td class="<cfoutput>#thisContentClass#</cfoutput>" colspan="2">
				<label for="disqusAuthUrl">Disqus Auth URL:</label>
			</td>
		   </tr>
		   <tr>
			<td class="<cfoutput>#thisContentClass#</cfoutput>" colspan="2">
				<input type="text" name="disqusAuthUrl" id="disqusAuthUrl" value="<cfoutput>#disqusAuthUrl#</cfoutput>" class="k-textbox" style="width: 95%" />
			</td>
		  </tr>
		<cfelse>
		  <tr>
			<td align="right" class="<cfoutput>#thisContentClass#</cfoutput>" style="width: 20%"> 
				<label for="disqusAuthUrl">Disqus Auth URL:</label>
			</td>
			<td class="<cfoutput>#thisContentClass#</cfoutput>">
				<input type="text" name="disqusAuthUrl" id="disqusAuthUrl" value="<cfoutput>#disqusAuthUrl#</cfoutput>" class="k-textbox" style="width: 50%" />
			</td>
		  </tr>
		</cfif>	  
		  <tr height="2px">
			  <td align="left" valign="top" colspan="<cfoutput>#thisColSpan#</cfoutput>" class="<cfoutput>#thisContentClass#</cfoutput>"></td>
		  </tr>
		  <cfsilent>
		  <cfset thisContentClass = HtmlUtilsObj.getKendoClass(thisContentClass)>
		  </cfsilent>
		<cfif session.isMobile>
		  <tr valign="middle">
			<td class="<cfoutput>#thisContentClass#</cfoutput>" colspan="2">
				<label for="disqusAuthTokenUrl">Disqus Auth Token URL:</label>
			</td>
		   </tr>
		   <tr>
			<td class="<cfoutput>#thisContentClass#</cfoutput>" colspan="2">
				<input type="text" name="disqusAuthTokenUrl" id="disqusAuthTokenUrl" value="<cfoutput>#disqusAuthTokenUrl#</cfoutput>" class="k-textbox" style="width: 95%" />
			</td>
		  </tr>
		<cfelse>
		  <tr>
			<td align="right" class="<cfoutput>#thisContentClass#</cfoutput>" style="width: 20%"> 
				<label for="disqusAuthTokenUrl">Disqus Auth Token URL:</label>
			</td>
			<td class="<cfoutput>#thisContentClass#</cfoutput>">
				<input type="text" name="disqusAuthTokenUrl" id="disqusAuthTokenUrl" value="<cfoutput>#disqusAuthTokenUrl#</cfoutput>" class="k-textbox" style="width: 50%" />
			</td>
		  </tr>
		</cfif>	
		End depracated disqus fields
		--->
		  <!-- Border -->
		  <tr height="2px">
			<td align="left" valign="top" colspan="<cfoutput>#thisColSpan#</cfoutput>" class="<cfoutput>#thisContentClass#</cfoutput>"></td>
		  </tr>
		</table>
	</div>
			  
	<!---//***********************************************************************************************
						Greensock
	//************************************************************************************************--->
	<button type="button" class="collapsible k-header">Greensock Animation Library</button>
	<div class="content k-content">
		<table align="center" class="k-content" width="100%" cellpadding="2" cellspacing="0">
		  <cfsilent>
			<!---The first content class in the table should be empty. --->
			<cfset thisContentClass = HtmlUtilsObj.getKendoClass('')>
			<!--- Set the colspan property for borders --->
			<cfset thisColSpan = "2">
		  </cfsilent>
				
		  <!-- Border -->
		  <tr height="2px">
			  <td align="left" valign="top" colspan="<cfoutput>#thisColSpan#</cfoutput>" class="<cfoutput>#thisContentClass#</cfoutput>"></td>
		  </tr>
		  <cfsilent>
		  <!--- Set the class for alternating rows. --->
		  <!---After the first row, the content class should be the current class. --->
		  <cfset thisContentClass = HtmlUtilsObj.getKendoClass(thisContentClass)>
		  </cfsilent>
		  <tr height="1px">
			  <td align="left" valign="top" colspan="2" class="<cfoutput>#thisContentClass#</cfoutput>"></td>
		  </tr>
		  <tr>
			<td colspan="2"> 
				<p>Greensock is a popular animation library that you can use in your blog posts. Including this library does not require a dedicated license, and it is open source, however, it requires advanced Javascript skills and should not be loaded unless you intend to use it. For more information see <a href="https://www.greensock.com">https://greensock.com/gsap/</a></p>
			</td>
		  </tr>
		  <!-- Border -->
		  <tr height="2px">
			  <td align="left" valign="top" colspan="<cfoutput>#thisColSpan#</cfoutput>" class="<cfoutput>#thisContentClass#</cfoutput>"></td>
		  </tr>
		<cfif session.isMobile>
		  <tr valign="middle">
			<td class="<cfoutput>#thisContentClass#</cfoutput>" colspan="2">
				<label for="includeGsap">Include GSAP:</label>
			</td>
		   </tr>
		   <tr>
			<td class="<cfoutput>#thisContentClass#</cfoutput>" colspan="2">
				<input type="checkbox" name="includeGsap" id="includeGsap" value="1" <cfif includeGsap>checked</cfif>>
			</td>
		  </tr>
		<cfelse><!---<cfif session.isMobile>--->
		  <tr>
			<td align="right" class="<cfoutput>#thisContentClass#</cfoutput>" style="width: 20%"> 
				<label for="includeGsap">Include GSAP:</label>
			</td>
			<td class="<cfoutput>#thisContentClass#</cfoutput>">
				<input type="checkbox" name="includeGsap" id="includeGsap" value="1" <cfif includeGsap>checked</cfif>>
			</td>
		  </tr>
		</cfif>
		  <!-- Border -->
		  <tr height="2px" class="containerWidths">
			  <td align="left" valign="top" colspan="<cfoutput>#thisColSpan#</cfoutput>" class="<cfoutput>#thisContentClass#</cfoutput>"></td>
		  </tr>
			  
		  <!-- Border -->
		  <tr height="2px">
			<td align="left" valign="top" colspan="<cfoutput>#thisColSpan#</cfoutput>" class="<cfoutput>#thisContentClass#</cfoutput>"></td>
		  </tr>
		</table>
	</div>
		
	<br/><br/>
	<button id="optionsSubmit" name="optionsSubmit" class="k-button k-primary" type="button">Submit</button> 
			   
</cfcase>
			  
<!--- //************************************************************************************************
		Blog Settings
//**************************************************************************************************--->
			
<cfcase value="39">
	
	<!---<cfdump var="#application.BlogOptionDbObj#">--->

	<!--- The blog object is already instantiated in the application --->
	<!--- Title and Description --->
	<cfset blogId = application.BlogDbObj.getBlogId()>
	<cfset blogName = application.BlogDbObj.getBlogName()>
	<cfset blogTitle = application.BlogDbObj.getBlogTitle()>
	<cfset blogDescription = application.BlogDbObj.getBlogDescription()>
	<!--- The blog URL contains an index.cfm at the end --->
	<cfset blogUrl = application.BlogDbObj.getBlogUrl()>
	<!--- SEO --->
	<cfset blogMetaKeywords = application.BlogDbObj.getBlogMetaKeywords()>
	<!--- Parent Site Links --->
	<cfset parentSiteName = application.BlogDbObj.getBlogParentSiteName()>
	<cfset parentSiteLink = application.BlogDbObj.getBlogParentSiteUrl()>
	<!--- Location and time zone --->
	<cfset locale = application.BlogDbObj.getBlogLocale()>
	<cfset blogTimeZone = application.BlogDbObj.getBlogTimeZone()>
	<cfset blogServerTimeZone = application.BlogDbObj.getBlogServerTimeZone()>
	<cfset serverTimeZoneOffset =  application.BlogDbObj.getBlogServerTimeZoneOffset()>
	<!--- Database --->
	<cfset blogDsn = application.BlogDbObj.getBlogDsn()>
	<cfset blogDsnUserName = application.BlogDbObj.getBlogDsnUserName()>
	<cfset blogDsnPassword = application.BlogDbObj.getBlogDsnPassword()>
	<cfset blogDBType = application.BlogDbObj.getBlogDatabaseType()>
	<!--- The following 3 args are found in the blog ini file. --->
	<cfset dsn = getProfileString(application.iniFile, "default", "dsn")>
	<cfset dsnUserName = getProfileString(application.iniFile, "default", "username")>
	<cfset dsnPassword = getProfileString(application.iniFile, "default", "password")>
	<!--- Mail server settings. --->
	<cfset mailServer = application.BlogDbObj.getBlogMailServer()>
	<cfset mailusername = application.BlogDbObj.getBlogMailServerUserName()>
	<cfset mailpassword = application.BlogDbObj.getBlogMailServerPassword()>
	<cfset failTo = application.BlogDbObj.getBlogEmailFailToAddress()>
	<cfset blogEmail = application.BlogDbObj.getBlogEmail()>
	<cfset ccEmailAddress = application.BlogDbObj.getCcEmailAddress()>
	<!--- Algorithm and IP Block list --->
	<cfset saltAlgorithm = application.BlogDbObj.getSaltAlgorithm()>
	<cfset ipBlockList = application.BlogDbObj.getIpBlockList()>
	<!--- Version --->
	<cfset blogVersion = application.BlogDbObj.getBlogVersion()>
	<cfset blogVersionName = application.BlogDbObj.getBlogVersionName()>
	<cfset isProd = application.BlogDbObj.getIsProd()>
	<cfset blogInstalled = application.BlogDbObj.getBlogInstalled()>
		
	<!---
	Fields:
	blogId
	blogName
	blogTitle
	blogDescription
	blogUrl
	blogMetaKeywords
		  
	parentSiteName
	parentSiteLink
		  
	blogTimeZone
	blogServerTimeZone
	serverTimeZoneOffset
			  
	dsn
	dsnUserName
	dsnPassword
				
	mailServer
	mailusername
	mailpassword
	failTo
	blogEmail

	ipBlockList
	--->
		
	<style>
		.collapsible {
			cursor: pointer;
			padding: 10px;
			width: 98%;
			border: thin;
			border-style: solid;
			text-align: left;
			outline: none;
			font-size: 15px;
			transition: max-height 0.2s ease-out;
		}

		.collapsible:after {
			content: '\25BC';
			color: white;
			font-weight: bold;
			float: right;
			margin-left: 5px;
			margin-left: 5px;
		}

		.active:after {
		  content: "\25B2";
		}

		.content {
		  padding: 0 18px;
		  display: none;
		  overflow: hidden;
		}
	</style>
		
	<script>
		
		// !!! Note on the validators, all forms need a name attribute, otherwise the positioning of the messages will not work. --->
		$(document).ready(function() {

			var settingsValidator = $("#settingsForm").kendoValidator({
				// Set up custom validation rules 
				rules: {
					// The theme must be unique. 
					themeIsUnique:
					function(input){
						// Do not continue if the theme name is found in the currentTheme list 
						if (input.is("[id='themeName']") && ( listFind( themeList, input.val() ) != 0 ) ){
							// Display an error on the page.
							input.attr("data-themeIsUnique-msg", "Theme name already exists");
							// Focus on the current element
							$( "#theme" ).focus();
							return false;
						}                                    
						return true;
					},
				}
			}).data("kendoValidator");

			// Invoked when the submit button is clicked. Insted of using '$("form").submit(function(event) {' and 'event.preventDefault();', We are using direct binding here to speed up the event.
			var settingsSubmit = $('#settingsSubmit');
			settingsSubmit.on('click', function(e){ 
				
				e.preventDefault();         
				if (settingsValidator.validate()) {
					
					// Open up a please wait dialog
					$.when(kendo.ui.ExtWaitDialog.show({ title: "Please wait...", message: "Please wait while we save the data.", width: "<cfoutput>#application.kendoExtendedUiWindowWidth#</cfoutput>", icon: "k-ext-information" }));

					// Send data to server
					setTimeout(function() {
						postSettings();
					}, 250);
					
				} else {

					$.when(kendo.ui.ExtAlertDialog.show({ title: "There are errors", message: "Please correct the highlighted fields and try again", width: "<cfoutput>#application.kendoExtendedUiWindowWidth#</cfoutput>", icon: "k-ext-warning" }) // or k-ext-error, k-ext-question
						).done(function () {
						// Do nothing
					});
				}
			});

		});//...document.ready
		
		// Post method on the detail form called from the deptDetailFormValidator method on the detail page. The action variable will either be 'update' or 'insert'.
		function postSettings(){

			jQuery.ajax({
				type: 'post', 
				url: '<cfoutput>#application.baseUrl#</cfoutput>/common/cfc/ProxyController.cfc?method=saveBlogSettings&csrfToken=<cfoutput>#csrfToken#</cfoutput>',
				// Serialize the form along with the csrfToken.
				data: $('#settingsForm').serialize(),
				dataType: "json",
				success: postSettingsResult, // calls the result function.
				error: function(ErrorMsg) {
					console.log('Error' + ErrorMsg);
				}
			// Extract any errors. This is a new jQuery promise based function as of jQuery 1.8.
			}).fail(function (jqXHR, textStatus, error) {
				// Close the wait window that was launched in the calling function.
				kendo.ui.ExtWaitDialog.hide();
				// Display the error. The full response is: jqXHR.responseText, but we just want to extract the error.
				$.when(kendo.ui.ExtAlertDialog.show({ title: "Error while consuming the saveBlogOptions function", message: error, icon: "k-ext-error", width: "<cfoutput>#application.kendoExtendedUiWindowWidth#</cfoutput>" }) // or k-ext-error, k-ext-information, k-ext-question, k-ext-warning.  You can also specify height.
					).done(function () {
					
				});		
			});
		};

		function postSettingsResult(response){
			// Close the wait window that was launched in the calling function.
			kendo.ui.ExtWaitDialog.hide();
			// Close this window.
			$('#settingsWindow').kendoWindow('destroy');
		}
	</script>
		
	<script>
		var coll = document.getElementsByClassName("collapsible");
		var i;

		for (i = 0; i < coll.length; i++) {
		  coll[i].addEventListener("click", function() {
			this.classList.toggle("active");
			var content = this.nextElementSibling;
			if (content.style.display === "block") {
			  content.style.display = "none";
			} else {
			  content.style.display = "block";
			}
		  });
		}
	</script>
		
	<form id="settingsForm" action="#" method="post" data-role="validator">
	<input type="hidden" name="csrfToken" id="csrfToken" value="<cfoutput>#csrfToken#</cfoutput>">
	<input type="hidden" name="blogId" id="blogId" value="<cfoutput>#blogId#</cfoutput>">
	<table align="center" class="k-content" width="100%" cellpadding="2" cellspacing="0">
	  <cfsilent>
		<!---The first content class in the table should be empty. --->
		<cfset thisContentClass = HtmlUtilsObj.getKendoClass('')>
		<!--- Set the colspan property for borders --->
		<cfset thisColSpan = "2">
	  </cfsilent>
	  <tr height="1px">
		  <td align="left" valign="top" colspan="2" class="<cfoutput>#thisContentClass#</cfoutput>"></td>
	  </tr>
	  <tr valign="middle" height="30px">
		<td valign="bottom" align="left" class="<cfoutput>#thisContentClass#</cfoutput>" colspan="<cfoutput>#thisColSpan#</cfoutput>">
			These settings are essential to get your blog up and running. Make sure that your settings are correct before you proceed.
		</td>
	  </tr>
	  <tr height="1px">
		  <td align="left" valign="top" colspan="2" class="border <cfoutput>#thisContentClass#</cfoutput>"></td>
	  </tr>
	  <!-- Form content -->
	  <tr valign="middle" height="30px">
		<td valign="bottom" align="left" class="<cfoutput>#thisContentClass#</cfoutput>" colspan="<cfoutput>#thisColSpan#</cfoutput>">
			The Blog Title is the title of your site. This name will be shown on top of the page and will be used as the name of the site by the search engines.
		</td>
	  </tr>
	  <tr height="1px">
		  <td align="left" valign="top" colspan="2" class="border <cfoutput>#thisContentClass#</cfoutput>"></td>
	  </tr>
	<cfif session.isMobile>
	  <tr valign="middle">
		<td class="<cfoutput>#thisContentClass#</cfoutput>" colspan="2">
		<label for="blogTitle">Blog Title:</label>
		</td>
	   </tr>
	   <tr>
		<td class="<cfoutput>#thisContentClass#</cfoutput>" colspan="2">
			<input type="textbox" id="blogTitle" name="blogTitle" value="<cfoutput>#blogTitle#</cfoutput>" class="k-textbox" style="width: 95%" required>
		</td>
	  </tr>
	<cfelse><!---<cfif session.isMobile>--->
	  <tr valign="middle" height="30px">
		<td align="right" class="<cfoutput>#thisContentClass#</cfoutput>" style="width:20%">
			<label for="blogTitle">Blog Title:</label>
		</td>
		<td align="left" class="<cfoutput>#thisContentClass#</cfoutput>" style="width:80%">
			<input type="textbox" id="blogTitle" name="blogTitle" value="<cfoutput>#blogTitle#</cfoutput>" class="k-textbox" style="width: 50%" required>
		</td>
	  </tr>
	</cfif>	  
	  <cfsilent>
	  <!--- Set the class for alternating rows. --->
	  <!---After the first row, the content class should be the current class. --->
	  <cfset thisContentClass = HtmlUtilsObj.getKendoClass(thisContentClass)>
	  </cfsilent>
	  <tr height="2px">
		  <td align="left" valign="top" colspan="2" class="border <cfoutput>#thisContentClass#</cfoutput>"></td>
	  </tr>
	  <!-- Form content -->
	  <tr valign="middle" height="30px">
		<td valign="bottom" align="left" class="<cfoutput>#thisContentClass#</cfoutput>" colspan="<cfoutput>#thisColSpan#</cfoutput>">
			The Blog Description is used by the search engines. The search engine will return your site description in the search results so it is vital that it is short and concise. It is generally recommended by various SEO sites that the description should be less than 155 characters.
		</td>
	  </tr>
	  <tr height="1px">
		  <td align="left" valign="top" colspan="2" class="border <cfoutput>#thisContentClass#</cfoutput>"></td>
	  </tr>
	<cfif session.isMobile>
	  <tr valign="middle">
		<td class="<cfoutput>#thisContentClass#</cfoutput>" colspan="2">
			<label for="blogDescription">Blog Description:</label>
		</td>
	   </tr>
	   <tr>
		<td class="<cfoutput>#thisContentClass#</cfoutput>" colspan="2">
			<input type="textbox" name="blogDescription" id="blogDescription" value="<cfoutput>#blogDescription#</cfoutput>" class="k-textbox" style="width:95%" required>
		</td>
	  </tr>
	<cfelse><!---<cfif session.isMobile>--->
	  <tr valign="middle" height="30px">
		<td align="right" class="<cfoutput>#thisContentClass#</cfoutput>">
			<label for="blogDescription">Blog Description:</label>
		</td>
		<td align="left" class="<cfoutput>#thisContentClass#</cfoutput>">
			<input type="textbox" name="blogDescription" id="blogDescription" value="<cfoutput>#blogDescription#</cfoutput>" class="k-textbox" style="width:75%" required>
		</td>
	  </tr>
	</cfif>	  
	  <!-- Border -->
	  <tr height="2px">
		  <td align="left" valign="top" colspan="<cfoutput>#thisColSpan#</cfoutput>" class="<cfoutput>#thisContentClass#</cfoutput>"></td>
	  </tr>
		  
	  <cfsilent>
	  <!--- Set the class for alternating rows. --->
	  <!---After the first row, the content class should be the current class. --->
	  <cfset thisContentClass = HtmlUtilsObj.getKendoClass(thisContentClass)>
	  </cfsilent>
	  <tr height="2px">
		  <td align="left" valign="top" colspan="2" class="border <cfoutput>#thisContentClass#</cfoutput>"></td>
	  </tr>
	  <!-- Form content -->
	  <tr valign="middle" height="30px">
		<td valign="bottom" align="left" class="<cfoutput>#thisContentClass#</cfoutput>" colspan="<cfoutput>#thisColSpan#</cfoutput>">
			What is the URL to your blog? The blog URL must contain an index.cfm at the end of the URL (ie- https://www.gregoryalexander.com/index.cfm). Also, if you are using SSL, type in https:// instead of http://. 
		</td>
	  </tr>
	  <tr height="1px">
		  <td align="left" valign="top" colspan="2" class="border <cfoutput>#thisContentClass#</cfoutput>"></td>
	  </tr>
	<cfif session.isMobile>
	  <tr valign="middle">
		<td class="<cfoutput>#thisContentClass#</cfoutput>" colspan="2">
			<label for="blogUrl">Blog URL:</label>
		</td>
	   </tr>
	   <tr>
		<td class="<cfoutput>#thisContentClass#</cfoutput>" colspan="2">
			<input type="text" name="blogUrl" id="blogUrl" value="<cfoutput>#blogUrl#</cfoutput>" class="k-textbox" style="width:75%" required>
		</td>
	  </tr>
	<cfelse><!---<cfif session.isMobile>--->
	  <tr valign="middle" height="30px">
		<td align="right" class="<cfoutput>#thisContentClass#</cfoutput>">
			<label for="blogUrl">Blog URL:</label></td>
		<td align="left" class="<cfoutput>#thisContentClass#</cfoutput>">
			<input type="text" name="blogUrl" id="blogUrl" value="<cfoutput>#blogUrl#</cfoutput>" class="k-textbox" style="width:75%" required>
		</td>
	  </tr>
	</cfif>	
	  <!-- Border -->
	  <tr height="2px">
		  <td align="left" valign="top" colspan="<cfoutput>#thisColSpan#</cfoutput>" class="<cfoutput>#thisContentClass#</cfoutput>"></td>
	  </tr>
		
	  <cfsilent>
	  <!--- Set the class for alternating rows. --->
	  <!---After the first row, the content class should be the current class. --->
	  <cfset thisContentClass = HtmlUtilsObj.getKendoClass(thisContentClass)>
	  </cfsilent>
	  <tr height="2px">
		  <td align="left" valign="top" colspan="2" class="border <cfoutput>#thisContentClass#</cfoutput>"></td>
	  </tr>
	  <!-- Form content -->
	  <tr valign="middle" height="30px">
		<td valign="bottom" align="left" class="<cfoutput>#thisContentClass#</cfoutput>" colspan="<cfoutput>#thisColSpan#</cfoutput>">
			The meta keywords are used by <b>some</b> of the search engines. However, google no longer uses them. This field is optional. 
		</td>
	  </tr>
	  <tr height="1px">
		  <td align="left" valign="top" colspan="2" class="border <cfoutput>#thisContentClass#</cfoutput>"></td>
	  </tr>
	<cfif session.isMobile>
	  <tr valign="middle">
		<td class="<cfoutput>#thisContentClass#</cfoutput>" colspan="2">
			<label for="blogMetaKeywords">SEO Meta Keywords:</label>
		</td>
	   </tr>
	   <tr>
		<td class="<cfoutput>#thisContentClass#</cfoutput>" colspan="2">
			<input type="text" name="blogMetaKeywords" id="blogMetaKeywords" value="<cfoutput>##</cfoutput>" class="k-textbox" style="width: 95%">
		</td>
	  </tr>
	<cfelse><!---<cfif session.isMobile>--->
	  <tr valign="middle" height="30px">
		<td align="right" class="<cfoutput>#thisContentClass#</cfoutput>">
			<label for="blogMetaKeywords">SEO Meta Keywords:</label>
		</td>
		<td align="left" class="<cfoutput>#thisContentClass#</cfoutput>">
			<input type="text" name="blogMetaKeywords" id="blogMetaKeywords" value="<cfoutput>##</cfoutput>" class="k-textbox" style="width: 75%">
		</td>
	  </tr>
	</cfif>	  
	  <!-- Border -->
	  <tr height="2px">
		  <td align="left" valign="top" colspan="<cfoutput>#thisColSpan#</cfoutput>" class="<cfoutput>#thisContentClass#</cfoutput>"></td>
	  </tr>
	  
	</table>
	<br/>
		
	<!---//***********************************************************************************************
						Parent Site
	//************************************************************************************************--->
	<button type="button" class="collapsible k-header">Parent Site Name and Link</button>
	<div class="content k-content">
		<table align="center" class="k-content" width="100%" cellpadding="2" cellspacing="0">
			
		  <cfsilent>
			<!---The first content class in the table should be empty. --->
			<cfset thisContentClass = HtmlUtilsObj.getKendoClass('')>
			<!--- Set the colspan property for borders --->
			<cfset thisColSpan = "2">
		  </cfsilent>
	
		  <tr height="1px">
			  <td align="left" valign="top" colspan="2" class="<cfoutput>#thisContentClass#</cfoutput>">
			  	If this blog is part of a bigger site, enter the parent site name and link. This setting will allow the user to click on the icon at the top of the page to get back to your main site and will place a link inside of the menu to navigate to the parent site. These settings are optional.
			  </td>
		  </tr>
		  <!-- Border -->
		  <tr height="2px">
			  <td align="left" valign="top" colspan="<cfoutput>#thisColSpan#</cfoutput>" class="<cfoutput>#thisContentClass#</cfoutput>"></td>
		  </tr>
		<cfif session.isMobile>
		  <tr valign="middle">
			<td class="<cfoutput>#thisContentClass#</cfoutput>" colspan="2">
				<label for="parentSiteName">Parent Site Name:</label>
			</td>
		   </tr>
		   <tr>
			<td class="<cfoutput>#thisContentClass#</cfoutput>" colspan="2">
				<input type="text" id="parentSiteName" name="parentSiteName" value="<cfoutput>#parentSiteName#</cfoutput>" class="k-textbox" style="width: 95%" /> 
			</td>
		  </tr>
		<cfelse><!---<cfif session.isMobile>--->
		  <tr>
			<td align="right" class="<cfoutput>#thisContentClass#</cfoutput>" style="width: 20%"> 
				<label for="parentSiteName">Parent Site Name:</label>
			</td>
			<td class="<cfoutput>#thisContentClass#</cfoutput>" style="width: 80%">
				<input type="text" id="parentSiteName" name="parentSiteName" value="<cfoutput>#parentSiteName#</cfoutput>" class="k-textbox" style="width: 50%" />    
			</td>
		  </tr>
		</cfif>
		  <!-- Border -->
		  <tr height="2px">
			  <td align="left" valign="top" colspan="<cfoutput>#thisColSpan#</cfoutput>" class="<cfoutput>#thisContentClass#</cfoutput>"></td>
		  </tr>
		  <cfsilent>
		  <!--- Set the class for alternating rows. --->
		  <!---After the first row, the content class should be the current class. --->
		  <cfset thisContentClass = HtmlUtilsObj.getKendoClass(thisContentClass)>
		  </cfsilent>
			 
		  <tr height="2px">
		  	<td align="left" valign="bottom" colspan="2" class="border <cfoutput>#thisContentClass#</cfoutput>"></td>
		  </tr>
		 <cfif session.isMobile>
		  <tr valign="middle">
			<td class="<cfoutput>#thisContentClass#</cfoutput>" colspan="2">
				<label for="parentSiteLink">Parent Site Link</label>
			</td>
		   </tr>
		   <tr>
			<td class="<cfoutput>#thisContentClass#</cfoutput>" colspan="2">
				<input type="text" name="parentSiteLink" id="parentSiteLink" value="<cfoutput>#parentSiteLink#</cfoutput>" class="k-textbox" style="width: 95%">
			</td>
		  </tr>
		<cfelse><!---<cfif session.isMobile>---> 
		  <tr valign="middle" height="30px">
			<td valign="bottom" align="right" class="<cfoutput>#thisContentClass#</cfoutput>">
				<label for="parentSiteLink">Parent Site Link</label>
			</td>
			<td valign="bottom" align="left" class="<cfoutput>#thisContentClass#</cfoutput>">
				<input type="text" name="parentSiteLink" id="parentSiteLink" value="<cfoutput>#parentSiteLink#</cfoutput>" class="k-textbox" style="width: 50%">
			</td>
		  </tr>
		</cfif>
		  <!-- Border -->
		  <tr height="2px">
			<td align="left" valign="top" colspan="<cfoutput>#thisColSpan#</cfoutput>" class="<cfoutput>#thisContentClass#</cfoutput>"></td>
		  </tr>
		
		</table>
	</div>
			
	<!---//***********************************************************************************************
						Server Time Zone
	//************************************************************************************************--->
		
	<script>
		var tzStrings = [
			{"label":"(GMT-12:00) International Date Line West","value":"Etc/GMT+12"},
			{"label":"(GMT-11:00) Midway Island, Samoa","value":"Pacific/Midway"},
			{"label":"(GMT-10:00) Hawaii","value":"Pacific/Honolulu"},
			{"label":"(GMT-09:00) Alaska","value":"US/Alaska"},
			{"label":"(GMT-08:00) Pacific Time (US & Canada)","value":"America/Los_Angeles"},
			{"label":"(GMT-08:00) Tijuana, Baja California","value":"America/Tijuana"},
			{"label":"(GMT-07:00) Arizona","value":"US/Arizona"},
			{"label":"(GMT-07:00) Chihuahua, La Paz, Mazatlan","value":"America/Chihuahua"},
			{"label":"(GMT-07:00) Mountain Time (US & Canada)","value":"US/Mountain"},
			{"label":"(GMT-06:00) Central America","value":"America/Managua"},
			{"label":"(GMT-06:00) Central Time (US & Canada)","value":"US/Central"},
			{"label":"(GMT-06:00) Guadalajara, Mexico City, Monterrey","value":"America/Mexico_City"},
			{"label":"(GMT-06:00) Saskatchewan","value":"Canada/Saskatchewan"},
			{"label":"(GMT-05:00) Bogota, Lima, Quito, Rio Branco","value":"America/Bogota"},
			{"label":"(GMT-05:00) Eastern Time (US & Canada)","value":"US/Eastern"},
			{"label":"(GMT-05:00) Indiana (East)","value":"US/East-Indiana"},
			{"label":"(GMT-04:00) Atlantic Time (Canada)","value":"Canada/Atlantic"},
			{"label":"(GMT-04:00) Caracas, La Paz","value":"America/Caracas"},
			{"label":"(GMT-04:00) Manaus","value":"America/Manaus"},
			{"label":"(GMT-04:00) Santiago","value":"America/Santiago"},
			{"label":"(GMT-03:30) Newfoundland","value":"Canada/Newfoundland"},
			{"label":"(GMT-03:00) Brasilia","value":"America/Sao_Paulo"},
			{"label":"(GMT-03:00) Buenos Aires, Georgetown","value":"America/Argentina/Buenos_Aires"},
			{"label":"(GMT-03:00) Greenland","value":"America/Godthab"},
			{"label":"(GMT-03:00) Montevideo","value":"America/Montevideo"},
			{"label":"(GMT-02:00) Mid-Atlantic","value":"America/Noronha"},
			{"label":"(GMT-01:00) Cape Verde Is.","value":"Atlantic/Cape_Verde"},
			{"label":"(GMT-01:00) Azores","value":"Atlantic/Azores"},
			{"label":"(GMT+00:00) Casablanca, Monrovia, Reykjavik","value":"Africa/Casablanca"},
			{"label":"(GMT+00:00) Greenwich Mean Time : Dublin, Edinburgh, Lisbon, London","value":"Etc/Greenwich"},
			{"label":"(GMT+01:00) Amsterdam, Berlin, Bern, Rome, Stockholm, Vienna","value":"Europe/Amsterdam"},
			{"label":"(GMT+01:00) Belgrade, Bratislava, Budapest, Ljubljana, Prague","value":"Europe/Belgrade"},
			{"label":"(GMT+01:00) Brussels, Copenhagen, Madrid, Paris","value":"Europe/Brussels"},
			{"label":"(GMT+01:00) Sarajevo, Skopje, Warsaw, Zagreb","value":"Europe/Sarajevo"},
			{"label":"(GMT+01:00) West Central Africa","value":"Africa/Lagos"},
			{"label":"(GMT+02:00) Amman","value":"Asia/Amman"},
			{"label":"(GMT+02:00) Athens, Bucharest, Istanbul","value":"Europe/Athens"},
			{"label":"(GMT+02:00) Beirut","value":"Asia/Beirut"},
			{"label":"(GMT+02:00) Cairo","value":"Africa/Cairo"},
			{"label":"(GMT+02:00) Harare, Pretoria","value":"Africa/Harare"},
			{"label":"(GMT+02:00) Helsinki, Kyiv, Riga, Sofia, Tallinn, Vilnius","value":"Europe/Helsinki"},
			{"label":"(GMT+02:00) Jerusalem","value":"Asia/Jerusalem"},
			{"label":"(GMT+02:00) Minsk","value":"Europe/Minsk"},
			{"label":"(GMT+02:00) Windhoek","value":"Africa/Windhoek"},
			{"label":"(GMT+03:00) Kuwait, Riyadh, Baghdad","value":"Asia/Kuwait"},
			{"label":"(GMT+03:00) Moscow, St. Petersburg, Volgograd","value":"Europe/Moscow"},
			{"label":"(GMT+03:00) Nairobi","value":"Africa/Nairobi"},
			{"label":"(GMT+03:00) Tbilisi","value":"Asia/Tbilisi"},
			{"label":"(GMT+03:30) Tehran","value":"Asia/Tehran"},
			{"label":"(GMT+04:00) Abu Dhabi, Muscat","value":"Asia/Muscat"},
			{"label":"(GMT+04:00) Baku","value":"Asia/Baku"},
			{"label":"(GMT+04:00) Yerevan","value":"Asia/Yerevan"},
			{"label":"(GMT+04:30) Kabul","value":"Asia/Kabul"},
			{"label":"(GMT+05:00) Yekaterinburg","value":"Asia/Yekaterinburg"},
			{"label":"(GMT+05:00) Islamabad, Karachi, Tashkent","value":"Asia/Karachi"},
			{"label":"(GMT+05:30) Chennai, Kolkata, Mumbai, New Delhi","value":"Asia/Calcutta"},
			{"label":"(GMT+05:30) Sri Jayawardenapura","value":"Asia/Calcutta"},
			{"label":"(GMT+05:45) Kathmandu","value":"Asia/Katmandu"},
			{"label":"(GMT+06:00) Almaty, Novosibirsk","value":"Asia/Almaty"},
			{"label":"(GMT+06:00) Astana, Dhaka","value":"Asia/Dhaka"},
			{"label":"(GMT+06:30) Yangon (Rangoon)","value":"Asia/Rangoon"},
			{"label":"(GMT+07:00) Bangkok, Hanoi, Jakarta","value":"Asia/Bangkok"},
			{"label":"(GMT+07:00) Krasnoyarsk","value":"Asia/Krasnoyarsk"},
			{"label":"(GMT+08:00) Beijing, Chongqing, Hong Kong, Urumqi","value":"Asia/Hong_Kong"},
			{"label":"(GMT+08:00) Kuala Lumpur, Singapore","value":"Asia/Kuala_Lumpur"},
			{"label":"(GMT+08:00) Irkutsk, Ulaan Bataar","value":"Asia/Irkutsk"},
			{"label":"(GMT+08:00) Perth","value":"Australia/Perth"},
			{"label":"(GMT+08:00) Taipei","value":"Asia/Taipei"},
			{"label":"(GMT+09:00) Osaka, Sapporo, Tokyo","value":"Asia/Tokyo"},
			{"label":"(GMT+09:00) Seoul","value":"Asia/Seoul"},
			{"label":"(GMT+09:00) Yakutsk","value":"Asia/Yakutsk"},
			{"label":"(GMT+09:30) Adelaide","value":"Australia/Adelaide"},
			{"label":"(GMT+09:30) Darwin","value":"Australia/Darwin"},
			{"label":"(GMT+10:00) Brisbane","value":"Australia/Brisbane"},
			{"label":"(GMT+10:00) Canberra, Melbourne, Sydney","value":"Australia/Canberra"},
			{"label":"(GMT+10:00) Hobart","value":"Australia/Hobart"},
			{"label":"(GMT+10:00) Guam, Port Moresby","value":"Pacific/Guam"},
			{"label":"(GMT+10:00) Vladivostok","value":"Asia/Vladivostok"},
			{"label":"(GMT+11:00) Magadan, Solomon Is., New Caledonia","value":"Asia/Magadan"},
			{"label":"(GMT+12:00) Auckland, Wellington","value":"Pacific/Auckland"},
			{"label":"(GMT+12:00) Fiji, Kamchatka, Marshall Is.","value":"Pacific/Fiji"},
			{"label":"(GMT+13:00) Nuku'alofa","value":"Pacific/Tongatapu"}
		]

		var tzInts = [
			{"label":"(GMT-12:00) International Date Line West","value":"-12"},
			{"label":"(GMT-11:00) Midway Island, Samoa","value":"-11"},
			{"label":"(GMT-10:00) Hawaii","value":"-10"},
			{"label":"(GMT-09:00) Alaska","value":"-9"},
			{"label":"(GMT-08:00) Pacific Time (US & Canada)","value":"-8"},
			{"label":"(GMT-08:00) Tijuana, Baja California","value":"-8"},
			{"label":"(GMT-07:00) Arizona","value":"-7"},
			{"label":"(GMT-07:00) Chihuahua, La Paz, Mazatlan","value":"-7"},
			{"label":"(GMT-07:00) Mountain Time (US & Canada)","value":"-7"},
			{"label":"(GMT-06:00) Central America","value":"-6"},
			{"label":"(GMT-06:00) Central Time (US & Canada)","value":"-6"},
			{"label":"(GMT-05:00) Bogota, Lima, Quito, Rio Branco","value":"-5"},
			{"label":"(GMT-05:00) Eastern Time (US & Canada)","value":"-5"},
			{"label":"(GMT-05:00) Indiana (East)","value":"-5"},
			{"label":"(GMT-04:00) Atlantic Time (Canada)","value":"-4"},
			{"label":"(GMT-04:00) Caracas, La Paz","value":"-4"},
			{"label":"(GMT-04:00) Manaus","value":"-4"},
			{"label":"(GMT-04:00) Santiago","value":"-4"},
			{"label":"(GMT-03:30) Newfoundland","value":"-3.5"},
			{"label":"(GMT-03:00) Brasilia","value":"-3"},
			{"label":"(GMT-03:00) Buenos Aires, Georgetown","value":"-3"},
			{"label":"(GMT-03:00) Greenland","value":"-3"},
			{"label":"(GMT-03:00) Montevideo","value":"-3"},
			{"label":"(GMT-02:00) Mid-Atlantic","value":"-2"},
			{"label":"(GMT-01:00) Cape Verde Is.","value":"-1"},
			{"label":"(GMT-01:00) Azores","value":"-1"},
			{"label":"(GMT+00:00) Casablanca, Monrovia, Reykjavik","value":"0"},
			{"label":"(GMT+00:00) Greenwich Mean Time : Dublin, Edinburgh, Lisbon, London","value":"0"},
			{"label":"(GMT+01:00) Amsterdam, Berlin, Bern, Rome, Stockholm, Vienna","value":"1"},
			{"label":"(GMT+01:00) Belgrade, Bratislava, Budapest, Ljubljana, Prague","value":"1"},
			{"label":"(GMT+01:00) Brussels, Copenhagen, Madrid, Paris","value":"1"},
			{"label":"(GMT+01:00) Sarajevo, Skopje, Warsaw, Zagreb","value":"1"},
			{"label":"(GMT+01:00) West Central Africa","value":"1"},
			{"label":"(GMT+02:00) Amman","value":"2"},
			{"label":"(GMT+02:00) Athens, Bucharest, Istanbul","value":"2"},
			{"label":"(GMT+02:00) Beirut","value":"2"},
			{"label":"(GMT+02:00) Cairo","value":"2"},
			{"label":"(GMT+02:00) Harare, Pretoria","value":"2"},
			{"label":"(GMT+02:00) Helsinki, Kyiv, Riga, Sofia, Tallinn, Vilnius","value":"2"},
			{"label":"(GMT+02:00) Jerusalem","value":"2"},
			{"label":"(GMT+02:00) Minsk","value":"2"},
			{"label":"(GMT+02:00) Windhoek","value":"2"},
			{"label":"(GMT+03:00) Kuwait, Riyadh, Baghdad","value":"3"},
			{"label":"(GMT+03:00) Moscow, St. Petersburg, Volgograd","value":"3"},
			{"label":"(GMT+03:00) Nairobi","value":"3"},
			{"label":"(GMT+03:00) Tbilisi","value":"3"},
			{"label":"(GMT+03:30) Tehran","value":"3.5"},
			{"label":"(GMT+04:00) Abu Dhabi, Muscat","value":"4"},
			{"label":"(GMT+04:00) Baku","value":"4"},
			{"label":"(GMT+04:00) Yerevan","value":"4"},
			{"label":"(GMT+04:30) Kabul","value":"4.5"},
			{"label":"(GMT+05:00) Yekaterinburg","value":"5"},
			{"label":"(GMT+05:00) Islamabad, Karachi, Tashkent","value":"5"},
			{"label":"(GMT+05:30) Sri Jayawardenapura","value":"5.5"},
			{"label":"(GMT+05:30) Chennai, Kolkata, Mumbai, New Delhi","value":"5.5"},
			{"label":"(GMT+05:45) Kathmandu","value":"5.75"},
			{"label":"(GMT+06:00) Almaty, Novosibirsk","value":"6"},{"label":"(GMT+06:00) Astana, Dhaka","value":"6"},
			{"label":"(GMT+06:30) Yangon (Rangoon)","value":"6.5"},
			{"label":"(GMT+07:00) Bangkok, Hanoi, Jakarta","value":"7"},
			{"label":"(GMT+07:00) Krasnoyarsk","value":"7"},
			{"label":"(GMT+08:00) Beijing, Chongqing, Hong Kong, Urumqi","value":"8"},
			{"label":"(GMT+08:00) Kuala Lumpur, Singapore","value":"8"},
			{"label":"(GMT+08:00) Irkutsk, Ulaan Bataar","value":"8"},
			{"label":"(GMT+08:00) Perth","value":"8"},
			{"label":"(GMT+08:00) Taipei","value":"8"},
			{"label":"(GMT+09:00) Osaka, Sapporo, Tokyo","value":"9"},
			{"label":"(GMT+09:00) Seoul","value":"9"},
			{"label":"(GMT+09:00) Yakutsk","value":"9"},
			{"label":"(GMT+09:30) Adelaide","value":"9.5"},
			{"label":"(GMT+09:30) Darwin","value":"9.5"},
			{"label":"(GMT+10:00) Brisbane","value":"10"},
			{"label":"(GMT+10:00) Canberra, Melbourne, Sydney","value":"10"},
			{"label":"(GMT+10:00) Hobart","value":"10"},
			{"label":"(GMT+10:00) Guam, Port Moresby","value":"10"},
			{"label":"(GMT+10:00) Vladivostok","value":"10"},
			{"label":"(GMT+11:00) Magadan, Solomon Is., New Caledonia","value":"11"},
			{"label":"(GMT+12:00) Auckland, Wellington","value":"12"},
			{"label":"(GMT+12:00) Fiji, Kamchatka, Marshall Is.","value":"12"},
			{"label":"(GMT+13:00) Nuku'alofa","value":"13"}
		]	
		
		// My timezone dropdown
		var blogTimeZone = $("#blogTimeZone").kendoDropDownList({
			//cascadeFrom: "agencyRateCompanyCode",
			optionLabel: "Select...",
			dataTextField: "label",
			dataValueField: "value",
			filter: "contains",
			dataSource: tzInts,
			change: onBlogTimeZoneChange,
		}).data("kendoDropDownList");

		// Set default value by the value (this is used when the container is populated via the datasource).
		var blogTimeZone = $("#blogTimeZone").data("kendoDropDownList");
		blogTimeZone.value( <cfoutput>'#blogTimeZone#'</cfoutput> );
		blogTimeZone.trigger("change");
		
		// Server timezone dropdown
		var serverTimeZone = $("#serverTimeZone").kendoDropDownList({
			//cascadeFrom: "agencyRateCompanyCode",
			optionLabel: "Select...",
			dataTextField: "label",
			dataValueField: "value",
			filter: "contains",
			dataSource: tzInts,
			change: onServerTimeZoneChange
		}).data("kendoDropDownList");

		// Set default value by the value (this is used when the container is populated via the datasource).
		var serverTimeZone = $("#serverTimeZone").data("kendoDropDownList");
		serverTimeZone.value(<cfoutput>'#blogServerTimeZone#'</cfoutput>);
		serverTimeZone.trigger("change");
		
		// Calculate the server offset by the blog time.
		function onBlogTimeZoneChange(e){
			// Get the value
			blogTimeZone = this.value();
			// Get the server timezone
			serverTimeZone = $("#serverTimeZoneValue").val();
			// Calculate the offset
			serverTimeZoneOffset = parseInt(blogTimeZone)-parseInt(serverTimeZone);
			// And populate the server time offset container
			$("#serverTimeZoneOffset").val(serverTimeZoneOffset);
		}//...function onBlogTimeZoneChange(e)
		
		// Calculate the server offset by the server time.
		function onServerTimeZoneChange(e){
			// Get the value
			serverTimeZone = this.value();
			// Get the server timezone
			blogTimeZone = $("#blogTimeZoneValue").val();
			// Calculate the offset
			serverTimeZoneOffset = parseInt(blogTimeZone)-parseInt(serverTimeZone);
			// And populate the server time offset container
			$("#serverTimeZoneOffset").val(serverTimeZoneOffset);
		}//...function onBlogTimeZoneChange(e)
			  
	</script>	
		
	<button type="button" class="collapsible k-header">Server Time Zone</button>
	<div class="content k-content">
		<table align="center" class="k-content" width="100%" cellpadding="2" cellspacing="0">
		  <input type="hidden" name="blogTimeZoneValue" id="blogTimeZoneValue" value="<cfoutput>#blogTimeZone#</cfoutput> ">
		  <input type="hidden" name="serverTimeZoneValue" id="serverTimeZoneValue" value="<cfoutput>#blogServerTimeZone#</cfoutput>">
		  <input type="hidden" name="serverTimeOffset" id="serverTimeOffset" value="<cfoutput>#serverTimeZoneOffset#</cfoutput>">
		  <cfsilent>
			<!---The first content class in the table should be empty. --->
			<cfset thisContentClass = HtmlUtilsObj.getKendoClass('')>
			<!--- Set the colspan property for borders --->
			<cfset thisColSpan = "2">
		  </cfsilent>
			 
		  <tr height="1px">
			  <td align="left" valign="top" colspan="2" class="<cfoutput>#thisContentClass#</cfoutput>"></td>
		  </tr>
		  <tr height="1px">
			  <td></td>
			  <td align="left" valign="top" class="<cfoutput>#thisContentClass#</cfoutput>">
			  	Your hosting provider or server may reside in a different time-zone. These settings are critical when this is the case. If your server is in a different time-zone, you will want the post date to show the  time that you are in- not necessarilly where the server is.
			  </td>
		  </tr>
		  <!-- Border -->
		  <tr height="2px">
			  <td align="left" valign="top" colspan="<cfoutput>#thisColSpan#</cfoutput>" class="<cfoutput>#thisContentClass#</cfoutput>"></td>
		  </tr>
		  <tr>
			<td align="right">Current Blog Time:</td>
			<td><cfoutput>#dateTimeFormat(application.blog.blogNow(), "medium")#</cfoutput> (Refresh the window to get the current time)</td>
		  </tr>
		  <!-- Border -->
		  <tr height="2px">
			  <td align="left" valign="top" colspan="<cfoutput>#thisColSpan#</cfoutput>" class="<cfoutput>#thisContentClass#</cfoutput>"></td>
		  </tr>
		<cfif session.isMobile>
		  <tr valign="middle">
			<td class="<cfoutput>#thisContentClass#</cfoutput>" colspan="2">
				<label for="blogTimeZone">Your time-zone:</label>
			</td>
		   </tr>
		   <tr>
			<td class="<cfoutput>#thisContentClass#</cfoutput>" colspan="2">
				<select id="blogTimeZone" name="blogTimeZone" style="width:95%"></select>
			</td>
		  </tr>
		<cfelse><!---<cfif session.isMobile>---> 
		  <tr>
			<td align="right" class="<cfoutput>#thisContentClass#</cfoutput>" style="width: 20%"> 
				<label for="blogTimeZone">Your time-zone:</label>
			</td>
			<td class="<cfoutput>#thisContentClass#</cfoutput>">
				<select id="blogTimeZone" name="blogTimeZone" style="width:50%"></select>
			</td>
		  </tr>
		</cfif>	  
		  <!-- Border -->
		  <tr height="2px">
			  <td align="left" valign="top" colspan="<cfoutput>#thisColSpan#</cfoutput>" class="<cfoutput>#thisContentClass#</cfoutput>"></td>
		  </tr>
		  <cfsilent>
		  <!--- Set the class for alternating rows. --->
		  <!---After the first row, the content class should be the current class. --->
		  <cfset thisContentClass = HtmlUtilsObj.getKendoClass(thisContentClass)>
		  </cfsilent>
		<cfif session.isMobile>
		  <tr valign="middle">
			<td class="<cfoutput>#thisContentClass#</cfoutput>" colspan="2">
				<label for="serverTimeZone">Server Time Zone:</label>
			</td>
		   </tr>
		   <tr>
			<td class="<cfoutput>#thisContentClass#</cfoutput>" colspan="2">
				<select id="serverTimeZone" name="serverTimeZone" style="width:95%"></select>
			</td>
		  </tr>
		<cfelse><!---<cfif session.isMobile>---> 
		  <tr>
			<td align="right" class="<cfoutput>#thisContentClass#</cfoutput>" style="width: 20%"> 
				<label for="serverTimeZone">Server Time Zone:</label>
			</td>
			<td class="<cfoutput>#thisContentClass#</cfoutput>">
				<select id="serverTimeZone" name="serverTimeZone" style="width:50%"></select>
			</td>
		  </tr>
		</cfif>	
		  <!-- Border -->
		  <tr height="2px">
			<td align="left" valign="top" colspan="<cfoutput>#thisColSpan#</cfoutput>" class="<cfoutput>#thisContentClass#</cfoutput>"></td>
		  </tr>
		  <cfsilent>
		  <!--- Set the class for alternating rows. --->
		  <!---After the first row, the content class should be the current class. --->
		  <cfset thisContentClass = HtmlUtilsObj.getKendoClass(thisContentClass)>
		  </cfsilent>
		  <!-- Border -->
		  <tr height="2px">
			  <td align="left" valign="top" colspan="<cfoutput>#thisColSpan#</cfoutput>" class="<cfoutput>#thisContentClass#</cfoutput>"></td>
		  </tr>
		<cfif session.isMobile>
		  <tr valign="middle">
			<td class="<cfoutput>#thisContentClass#</cfoutput>" colspan="2">
				<label for="serverTimeZoneOffset">Server Time Zone Offset:</label>
			</td>
		   </tr>
		   <tr>
			<td class="<cfoutput>#thisContentClass#</cfoutput>" colspan="2">
				<input type="number" id="serverTimeZoneOffset" name="serverTimeZoneOffset" value="<cfoutput>#serverTimeZoneOffset#</cfoutput>" min="-12" max="13" step="1" class="k-textbox" required> 
			</td>
		  </tr>
		<cfelse><!---<cfif session.isMobile>---> 
		  <tr>
			<td align="right" class="<cfoutput>#thisContentClass#</cfoutput>" style="width: 20%"> 
				<label for="serverTimeZoneOffset">Server Time Zone Offset:</label>
			</td>
			<td class="<cfoutput>#thisContentClass#</cfoutput>">
				<input type="number" id="serverTimeZoneOffset" name="serverTimeZoneOffset" value="<cfoutput>#serverTimeZoneOffset#</cfoutput>" min="-12" max="13" step="1" class="k-textbox" required>
			</td>
		  </tr>
		</cfif>
		</table>
	</div>
			  
	<!---//***********************************************************************************************
						Database connectivity
	//************************************************************************************************--->
				
	<button type="button" class="collapsible k-header">Database Connectivity</button>
	<div class="content k-content">
		<table align="center" class="k-content" width="100%" cellpadding="2" cellspacing="0">
			
		  <cfsilent>
			<!---The first content class in the table should be empty. --->
			<cfset thisContentClass = HtmlUtilsObj.getKendoClass('')>
			<!--- Set the colspan property for borders --->
			<cfset thisColSpan = "2">
		  </cfsilent>
			 
		  <tr height="1px">
			  <td align="left" valign="top" colspan="2" class="<cfoutput>#thisContentClass#</cfoutput>"></td>
		  </tr>
		  <tr height="1px">
			  <td align="left" valign="top" colspan="2" class="<cfoutput>#thisContentClass#</cfoutput>">
			  	The database credentials should be provided for by your DBA or your hosting provider. The ColdFusion DSN is required but the other database settings are optional.
			  </td>
		  </tr>
		  <!-- Border -->
		  <tr height="2px">
			  <td align="left" valign="top" colspan="<cfoutput>#thisColSpan#</cfoutput>" class="<cfoutput>#thisContentClass#</cfoutput>"></td>
		  </tr>
		<cfif session.isMobile>
		  <tr valign="middle">
			<td class="<cfoutput>#thisContentClass#</cfoutput>" colspan="2">
				<label for="dsn">ColdFusion Database DSN:</label>
			</td>
		   </tr>
		   <tr>
			<td class="<cfoutput>#thisContentClass#</cfoutput>" colspan="2">
				<input type="text" name="dsn" id="dsn" value="<cfoutput>#blogDsn#</cfoutput>" class="k-textbox" style="width: 95%" required />
			</td>
		  </tr>
		<cfelse><!---<cfif session.isMobile>--->
		  <tr>
			<td align="right" class="<cfoutput>#thisContentClass#</cfoutput>" style="width: 20%"> 
				<label for="dsn">Database DSN:</label>
			</td>
			<td class="<cfoutput>#thisContentClass#</cfoutput>">
				<input type="text" name="dsn" id="dsn" value="<cfoutput>#blogDsn#</cfoutput>" class="k-textbox" style="width: 50%" required />
			</td>
		  </tr>
		</cfif>		
		  <!-- Border -->
		  <tr height="2px">
			  <td align="left" valign="top" colspan="<cfoutput>#thisColSpan#</cfoutput>" class="<cfoutput>#thisContentClass#</cfoutput>"></td>
		  </tr>
		  <cfsilent>
		  <!--- Set the class for alternating rows. --->
		  <!---After the first row, the content class should be the current class. --->
		  <cfset thisContentClass = HtmlUtilsObj.getKendoClass(thisContentClass)>
		  </cfsilent>
		<cfif session.isMobile>
		  <tr valign="middle">
			<td class="<cfoutput>#thisContentClass#</cfoutput>" colspan="2">
				<label for="dsnUserName">DSN User Name:</label>
			</td>
		   </tr>
		   <tr>
			<td class="<cfoutput>#thisContentClass#</cfoutput>" colspan="2">
				<input type="text" name="dsnUserName" id="dsnUserName" value="<cfoutput>#blogDsnUserName#</cfoutput>" class="k-textbox" style="width: 95%" />
			</td>
		  </tr>
		<cfelse><!---<cfif session.isMobile>--->
		  <tr>
			<td align="right" class="<cfoutput>#thisContentClass#</cfoutput>" style="width: 20%"> 
				<label for="dsnUserName">DSN User Name:</label>
			</td>
			<td class="<cfoutput>#thisContentClass#</cfoutput>">
				<input type="text" name="dsnUserName" id="dsnUserName" value="<cfoutput>#blogDsnUserName#</cfoutput>" class="k-textbox" style="width: 50%" />
			</td>
		  </tr>
		</cfif>	  
		  <!-- Border -->
		  <tr height="2px">
			  <td align="left" valign="top" colspan="<cfoutput>#thisColSpan#</cfoutput>" class="<cfoutput>#thisContentClass#</cfoutput>"></td>
		  </tr>
		  <cfsilent>
		  <!--- Set the class for alternating rows. --->
		  <!---After the first row, the content class should be the current class. --->
		  <cfset thisContentClass = HtmlUtilsObj.getKendoClass(thisContentClass)>
		  </cfsilent>
		<cfif session.isMobile>
		  <tr valign="middle">
			<td class="<cfoutput>#thisContentClass#</cfoutput>" colspan="2">
				<label for="dsnPassword">DSN Password:</label>
			</td>
		   </tr>
		   <tr>
			<td class="<cfoutput>#thisContentClass#</cfoutput>" colspan="2">
				<input type="text" name="dsnPassword" id="dsnPassword" value="<cfoutput>#blogDsnPassword#</cfoutput>" class="k-textbox" style="width: 95%" />
			</td>
		  </tr>
		<cfelse><!---<cfif session.isMobile>--->
		  <tr>
			<td align="right" class="<cfoutput>#thisContentClass#</cfoutput>" style="width: 20%"> 
				<label for="dsnPassword">DSN Password:</label>
			</td>
			<td class="<cfoutput>#thisContentClass#</cfoutput>">
				<input type="text" name="dsnPassword" id="dsnPassword" value="<cfoutput>#blogDsnPassword#</cfoutput>" class="k-textbox" style="width: 50%" />
			</td>
		  </tr>
		</cfif>
		  <!-- Border -->
		  <tr height="2px">
			  <td align="left" valign="top" colspan="<cfoutput>#thisColSpan#</cfoutput>" class="<cfoutput>#thisContentClass#</cfoutput>"></td>
		  </tr>
		
		</table>
	</div>
			  
	<!---//***********************************************************************************************
						Mail Server Settings
	//************************************************************************************************--->
				
	<button type="button" class="collapsible k-header">Mail Server Settings</button>
	<div class="content k-content">
		<table align="center" class="k-content" width="100%" cellpadding="2" cellspacing="0">
			
		  <cfsilent>
			<!---The first content class in the table should be empty. --->
			<cfset thisContentClass = HtmlUtilsObj.getKendoClass('')>
			<!--- Set the colspan property for borders --->
			<cfset thisColSpan = "2">
		  </cfsilent>
			 
		  <tr height="1px">
			  <td align="left" valign="top" colspan="2" class="<cfoutput>#thisContentClass#</cfoutput>"></td>
		  </tr>
		  <tr height="1px">
			  <td align="left" valign="top" colspan="2" class="<cfoutput>#thisContentClass#</cfoutput>">
			  	Please get the mail server settings from your server administrator or your hosting provider. All of these settings are necessary.
			  </td>
		  </tr>
		  <!-- Border -->
		  <tr height="2px">
			  <td align="left" valign="top" colspan="<cfoutput>#thisColSpan#</cfoutput>" class="<cfoutput>#thisContentClass#</cfoutput>"></td>
		  </tr>
		  <cfsilent>
		  <!--- Set the class for alternating rows. --->
		  <!---After the first row, the content class should be the current class. --->
		  <cfset thisContentClass = HtmlUtilsObj.getKendoClass(thisContentClass)>
		  </cfsilent>
		  <tr height="1px">
			  <td align="left" valign="top" colspan="2" class="<cfoutput>#thisContentClass#</cfoutput>"></td>
		  </tr>
		<cfif session.isMobile>
		  <tr valign="middle">
			<td class="<cfoutput>#thisContentClass#</cfoutput>" colspan="2">
				<label for="mailServer">Mail Server:</label>
			</td>
		   </tr>
		   <tr>
			<td class="<cfoutput>#thisContentClass#</cfoutput>" colspan="2">
				<input type="textbox" name="mailServer" id="mailServer" value="<cfoutput>#mailServer#</cfoutput>" class="k-textbox" style="width: 50%" required />
			</td>
		  </tr>
		<cfelse><!---<cfif session.isMobile>--->
		  <tr>
			<td align="right" class="<cfoutput>#thisContentClass#</cfoutput>" style="width: 20%"> 
				<label for="mailServer">Mail Server:</label>
			</td>
			<td class="<cfoutput>#thisContentClass#</cfoutput>">
				<input type="textbox" name="mailServer" id="mailServer" value="<cfoutput>#mailServer#</cfoutput>" class="k-textbox" style="width: 50%" required />
			</td>
		  </tr>
		</cfif>
		  <!-- Border -->
		  <tr height="2px">
			  <td align="left" valign="top" colspan="<cfoutput>#thisColSpan#</cfoutput>" class="<cfoutput>#thisContentClass#</cfoutput>"></td>
		  </tr>
		  <cfsilent>
		  <!--- Set the class for alternating rows. --->
		  <!---After the first row, the content class should be the current class. --->
		  <cfset thisContentClass = HtmlUtilsObj.getKendoClass(thisContentClass)>
		  </cfsilent>
		<cfif session.isMobile>
		  <tr valign="middle">
			<td class="<cfoutput>#thisContentClass#</cfoutput>" colspan="2">
				<label for="mailUserName">Mail User Name:</label>
			</td>
		   </tr>
		   <tr>
			<td class="<cfoutput>#thisContentClass#</cfoutput>" colspan="2">
				<input type="text" name="mailUserName" id="mailUserName" value="<cfoutput>#mailUserName#</cfoutput>" class="k-textbox" style="width: 95%" required/>
			</td>
		  </tr>
		<cfelse><!---<cfif session.isMobile>--->
		  <tr>
			<td align="right" class="<cfoutput>#thisContentClass#</cfoutput>" style="width: 20%"> 
				<label for="mailUserName">Mail User Name:</label>
			</td>
			<td class="<cfoutput>#thisContentClass#</cfoutput>">
				<input type="text" name="mailUserName" id="mailUserName" value="<cfoutput>#mailUserName#</cfoutput>" class="k-textbox" style="width: 50%" required/>
			</td>
		  </tr>
		</cfif>	  
		  <!-- Border -->
		  <tr height="2px">
			  <td align="left" valign="top" colspan="<cfoutput>#thisColSpan#</cfoutput>" class="<cfoutput>#thisContentClass#</cfoutput>"></td>
		  </tr>
		  <cfsilent>
		  <!--- Set the class for alternating rows. --->
		  <!---After the first row, the content class should be the current class. --->
		  <cfset thisContentClass = HtmlUtilsObj.getKendoClass(thisContentClass)>
		  </cfsilent>
		  <tr height="1px">
			  <td align="left" valign="top" colspan="2" class="<cfoutput>#thisContentClass#</cfoutput>"></td>
		  </tr>
		<cfif session.isMobile>
		  <tr valign="middle">
			<td class="<cfoutput>#thisContentClass#</cfoutput>" colspan="2">
				<label for="mailPassword">Mail Password:</label>
			</td>
		   </tr>
		   <tr>
			<td class="<cfoutput>#thisContentClass#</cfoutput>" colspan="2">
				<input type="text" name="mailPassword" id="mailPassword" value="<cfoutput>#mailPassword#</cfoutput>" class="k-textbox" style="width: 95%" required />
			</td>
		  </tr>
		<cfelse><!---<cfif session.isMobile>--->
		  <tr>
			<td align="right" class="<cfoutput>#thisContentClass#</cfoutput>" style="width: 20%"> 
				<label for="mailPassword">Mail Password:</label>
			</td>
			<td class="<cfoutput>#thisContentClass#</cfoutput>">
				<input type="text" name="mailPassword" id="mailPassword" value="<cfoutput>#mailPassword#</cfoutput>" class="k-textbox" style="width: 50%" required /> 
			</td>
		  </tr>
		</cfif>	  
		  <!-- Border -->
		  <tr height="2px">
			  <td align="left" valign="top" colspan="<cfoutput>#thisColSpan#</cfoutput>" class="<cfoutput>#thisContentClass#</cfoutput>"></td>
		  </tr>
		  <cfsilent>
		  <!--- Set the class for alternating rows. --->
		  <!---After the first row, the content class should be the current class. --->
		  <cfset thisContentClass = HtmlUtilsObj.getKendoClass(thisContentClass)>
		  </cfsilent>
		<cfif session.isMobile>
		  <tr valign="middle">
			<td class="<cfoutput>#thisContentClass#</cfoutput>" colspan="2">
				<label for="failTo">Mail Failto Address:</label>
			</td>
		   </tr>
		   <tr>
			<td class="<cfoutput>#thisContentClass#</cfoutput>" colspan="2">
				<input type="text" name="failTo" id="failTo" value="<cfoutput>#failTo#</cfoutput>" class="k-textbox" style="width: 95%" />
			</td>
		  </tr>
		<cfelse><!---<cfif session.isMobile>--->
		  <tr>
			<td align="right" class="<cfoutput>#thisContentClass#</cfoutput>" style="width: 20%"> 
				<label for="failTo">Mail Failto Address:</label>
			</td>
			<td class="<cfoutput>#thisContentClass#</cfoutput>">
				<input type="text" name="failTo" id="failTo" value="<cfoutput>#failTo#</cfoutput>" class="k-textbox" style="width: 50%" />
			</td>
		  </tr>
		</cfif>	  
		  <!-- Border -->
		  <tr height="2px">
			  <td align="left" valign="top" colspan="<cfoutput>#thisColSpan#</cfoutput>" class="<cfoutput>#thisContentClass#</cfoutput>"></td>
		  </tr>
		  <cfsilent>
		  <!--- Set the class for alternating rows. --->
		  <!---After the first row, the content class should be the current class. --->
		  <cfset thisContentClass = HtmlUtilsObj.getKendoClass(thisContentClass)>
		  </cfsilent>
		<cfif session.isMobile>
		  <tr valign="middle">
			<td class="<cfoutput>#thisContentClass#</cfoutput>" colspan="2">
				<label for="blogEmail">Blog Email Address:</label>
			</td>
		   </tr>
		   <tr>
			<td class="<cfoutput>#thisContentClass#</cfoutput>" colspan="2">
				<input type="email" name="blogEmail" id="blogEmail" value="<cfoutput>#blogEmail#</cfoutput>" class="k-textbox" style="width: 95%" />
			</td>
		  </tr>
		<cfelse><!---<cfif session.isMobile>--->
		  <tr>
			<td align="right" class="<cfoutput>#thisContentClass#</cfoutput>" style="width: 20%"> 
				<label for="blogEmail">Blog Email Address:</label>
			</td>
			<td class="<cfoutput>#thisContentClass#</cfoutput>">
				<input type="email" name="blogEmail" id="blogEmail" value="<cfoutput>#blogEmail#</cfoutput>" class="k-textbox" style="width: 50%" />
			</td>
		  </tr>
		</cfif>	  
		  <!-- Border -->
		  <tr height="2px">
			  <td align="left" valign="top" colspan="<cfoutput>#thisColSpan#</cfoutput>" class="<cfoutput>#thisContentClass#</cfoutput>"></td>
		  </tr>
		  <cfsilent>
		  <!--- Set the class for alternating rows. --->
		  <!---After the first row, the content class should be the current class. --->
		  <cfset thisContentClass = HtmlUtilsObj.getKendoClass(thisContentClass)>
		  </cfsilent>
		  <tr height="1px">
			  <td align="left" valign="top" colspan="2" class="<cfoutput>#thisContentClass#</cfoutput>"></td>
		  </tr>
		  <tr height="1px">
			  <td align="left" valign="top" colspan="2" class="<cfoutput>#thisContentClass#</cfoutput>">
			  	You may carbon copy all blog email to another email address. This field is optional.
			  </td>
		  </tr>
		<cfif session.isMobile>
		  <tr valign="middle">
			<td class="<cfoutput>#thisContentClass#</cfoutput>" colspan="2">
				<label for="ccEmailAddress">CC Email:</label>
			</td>
		   </tr>
		   <tr>
			<td class="<cfoutput>#thisContentClass#</cfoutput>" colspan="2">
				<input type="email" name="ccEmailAddress" id="ccEmailAddress" value="<cfoutput>#ccEmailAddress#</cfoutput>" class="k-textbox" style="width: 95%" />
			</td>
		  </tr>
		<cfelse><!---<cfif session.isMobile>--->
		  <tr>
			<td align="right" class="<cfoutput>#thisContentClass#</cfoutput>" style="width: 20%"> 
				<label for="mailPassword">CC Email Address:</label>
			</td>
			<td class="<cfoutput>#thisContentClass#</cfoutput>">
				<input type="email" name="ccEmailAddress" id="ccEmailAddress" value="<cfoutput>#ccEmailAddress#</cfoutput>" class="k-textbox" style="width: 50%" /> 
			</td>
		  </tr>
		</cfif>	 
			  
		  <!-- Border -->
		  <tr height="2px">
			<td align="left" valign="top" colspan="<cfoutput>#thisColSpan#</cfoutput>" class="<cfoutput>#thisContentClass#</cfoutput>"></td>
		  </tr>
		</table>
	</div>
			  
	<!---//***********************************************************************************************
						IP Block List
	//************************************************************************************************--->
	<button type="button" class="collapsible k-header">IP Block List</button>
	<div class="content k-content">
		<table align="center" class="k-content" width="100%" cellpadding="2" cellspacing="0">
		  <cfsilent>
			<!---The first content class in the table should be empty. --->
			<cfset thisContentClass = HtmlUtilsObj.getKendoClass('')>
			<!--- Set the colspan property for borders --->
			<cfset thisColSpan = "2">
		  </cfsilent>
				
		  <!-- Border -->
		  <tr height="2px">
			  <td align="left" valign="top" colspan="<cfoutput>#thisColSpan#</cfoutput>" class="<cfoutput>#thisContentClass#</cfoutput>"></td>
		  </tr>
		  <cfsilent>
		  <!--- Set the class for alternating rows. --->
		  <!---After the first row, the content class should be the current class. --->
		  <cfset thisContentClass = HtmlUtilsObj.getKendoClass(thisContentClass)>
		  </cfsilent>
		  <tr height="1px">
			  <td align="left" valign="top" colspan="2" class="<cfoutput>#thisContentClass#</cfoutput>"></td>
		  </tr>
		  <tr>
			<td colspan="2"> 
				You can block certain IP addresses from accessing this site by entering the IP address. This field is optional. 
			</td>
		  </tr>
		  <!-- Border -->
		  <tr height="2px">
			  <td align="left" valign="top" colspan="<cfoutput>#thisColSpan#</cfoutput>" class="<cfoutput>#thisContentClass#</cfoutput>"></td>
		  </tr>
		<cfif session.isMobile>
		  <tr valign="middle">
			<td class="<cfoutput>#thisContentClass#</cfoutput>" colspan="2">
				<label for="ipBlockList">IP Block List:</label>
			</td>
		   </tr>
		   <tr>
			<td class="<cfoutput>#thisContentClass#</cfoutput>" colspan="2">
				<input type="text" name="ipBlockList" id="ipBlockList" value="<cfoutput>#ipBlockList#</cfoutput>" class="k-textbox" style="width: 95%">
			</td>
		  </tr>
		<cfelse><!---<cfif session.isMobile>--->
		  <tr>
			<td align="right" class="<cfoutput>#thisContentClass#</cfoutput>" style="width: 20%"> 
				<label for="ipBlockList">IP Block List:</label>
			</td>
			<td class="<cfoutput>#thisContentClass#</cfoutput>">
				<input type="text" name="ipBlockList" id="ipBlockList" value="<cfoutput>#ipBlockList#</cfoutput>" class="k-textbox" style="width: 75%">
			</td>
		  </tr>
		</cfif>
		  <!-- Border -->
		  <tr height="2px" class="containerWidths">
			  <td align="left" valign="top" colspan="<cfoutput>#thisColSpan#</cfoutput>" class="<cfoutput>#thisContentClass#</cfoutput>"></td>
		  </tr>
			  
		</table>
	</div>
		
	<br/><br/>
	<button id="settingsSubmit" name="settingsSubmit" class="k-button k-primary" type="button">Submit</button> 
			   
</cfcase>
			
<!--- //************************************************************************************************
		Blog Updates
//**************************************************************************************************--->
			
<cfcase value="40">
	
	<style>
		#recentVersionCheck {
			width:100%;
		}
	</style>
	
	<script>
		// Get the summary information
		$("#summary").html("<p>Checking to see if your blog is up to date. Please wait.</p>").load("latestVersionCheck.cfm?type=summary&version=<cfoutput>#application.blog.getVersion()#</cfoutput>", function() {
		});
		
		// Get the details
		$("#upgradeDetails").html("<p>Retrieving details....</p>").load("latestVersionCheck.cfm?type=detail&version=<cfoutput>#application.blog.getVersion()#</cfoutput>");
	</script>
	<!---#application.blog.getVersion()#--->
	
	<table id="recentVersionCheck" class="k-content" width="100%" cellpadding="0" cellspacing="0" border="0">
	  <tr align="left">
		<td style="height: 25px;">
		  <span id="summary"></span>
		</td>
	  </tr>
	  <tr class="k-alt">
		<td>
		  <span id="upgradeDetails"></span>
		</td>	
	  </tr>
	</table><br/>

</cfcase>
			  
<!--- //************************************************************************************************
		Blog CFC Import
//**************************************************************************************************--->
			
<cfcase value="41">
	<table>
		<tr>
			<td valign="top"><img src="<cfoutput>#application.baseUrl#</cfoutput>/images/icons/import.jpg"></td>
			<td>
				<p>This template should be able to import and transform your BlogCFC or Galaxie Blog data into Galaxie Blog 3.0. However, you will need to perform several simple steps in order to transfer the original data to Galaxie Blog.</p>
				<p>Locate the <cfoutput>#application.baseUrl#</cfoutput>/common/data/generateBlogCfcDateFiles.cfm template in this installation and upload this ColdFusion template to a server that has access to your original BlogCFC or Galaxie Blog database. You will need to manually modify the following cfsetsettings at the very top of the template to communicate to your orginal database: </p>
				<ol>
					<li>Set the destination path on the original database server where you want the WDDX files to be generated to.</li>
					<li>Set the ColdFusion DSN to point to your original database</li>
					<li>If you're uploading images located in the 'enclosures' folder, set the oldEnclosurePath to point to original file location where the enclosure folder used to be. This template will change the original enlosure path and automatically set the new enclosure path for this Blog installation. If you are not uploading post enclosure images this step is not necessary.</li>
					<li>Run the template that you modified on the server that has access to the original BlogCFC/Galaxie database. The code should generate new WDDX files. This code is not using ORM, however, the queries are simple SELECT * queries that should be able to run on most modern databases.</li>
					<li>The generateBlogCfcDateFiles.cfm template has been tested against all of the Galaxie Blog 1x versions and BlogCFC version 6. You may need to modify this template if you are running a version less than BlogCFC 6. To the best of my recollection, BlogCFC version 5.98 is missing a single database column and you will have to set the following column output to '' to bypass the error and properly generate the WDDX files ('' as MissingColunm).</li>
					<li>After running this template, the code should generate the following files in the directory that you specified in step 1 above.</li>
					<ol>
						<li>getBlogCfcCategories.txt</li>
						<li>getBlogCfcPostCategories.txt</li>
						<li>getBlogCfcPostComments.txt</li>
						<li>getBlogCfcRelatedPosts.txt</li>
						<li>getBlogCfcSubscribers.txt</li>
					</ol>
					<li>Copy all of these files and upload them to this installation in the <cfoutput>#application.baseUrl#</cfoutput>/common/data/files/blogCfcImport directory.</li>
					<li>If you have prior enclosure images, upload all of you original images to the <cfoutput>#application.baseUrl#</cfoutput>/enclosures/ folder.</li>
					<li>Open the <cfoutput>#application.baseUrl#</cfoutput>/common/data/importBlogCfc.cfm template and enter the current blogs DSN near the top of the page. We are checking the security credentials before running this, however, this extra step reduces the chance that this template may be run inadvertently.</li>
					<li>Once your done uploading the WDDX files (and potentially the enclosures) along with entering the DSN, click on the <b>Submit</b> button below to start the database import process.</li>
				</ol>
			</td>
		</tr>
		<tr>
			<td colspan="2">
				<p>This import template has been successfully tested importing the data from Gregory's Blog at www.gregoryalexander.com. Gregory's Blog has around 150 posts and each post has an enclosure image. If you have more than 150 posts and recieve a query time-out error, you may want to modify this template and change how many records are run at a single given time. Alternatively, you can adjust the number of records in the WDDX files by changing the SQL in the generateBlogCfcDateFiles.cfm template.</p>

				<p> You can also specify what tables to import the data from by setting the tablesToPopulate argument at the top of this file. This template resides at <cfoutput>#application.baseUrl#</cfoutput>/common/data/importBlogCfc.cfm.</p>
				<p><b>You can run this template as many times as you wish</b>. This template will determine whether the record already exists and will update the record (if it exists) or insert the new record. <b>You will not have any duplicate data</b> if you run this template more than one time.</p>

				<p>Other than the user information and blog settings, this template should handle all of the original data and successfully convert the data to be used by Galaxie Blog 3. However, the content between &lt;code&gt; tags may be formatted funny. This is due to having some difficulties to  reformat the content between to code blocks to work with Prism. However, all of the code blocks should be moved over, but you may have to modify the extra tabs and lines of empty code using the post editor.</p>

				<p>You can also use this method to import data from other Blog Software as long as you are able to transform the data into your original BlogCFC database. I may add new import scripts in the future to handle other blog software.</p>

				<p>Happy Blogging!</p>
			</td>
		</tr>
	</table>
		<p><a href="<cfoutput>#application.baseUrl#</cfoutput>/common/data/importBlogCfc.cfm" target="_blank" rel="noopener noreferrer"><button class="k-button k-primary">Proceed</button></a></p>
</cfcase>
			  
<!--- //************************************************************************************************
		Post Header
//**************************************************************************************************--->
			
<cfcase value="42">
	
	<style>
		textarea { width: 90%; height: auto; }
	</style>
	
	<!--- Get the post. The last argument should also show posts that are removed ( getPostByPostId(postId, showPendingPosts, showRemovedPosts) ). --->
	<cfset getPost = application.blog.getPostByPostId(URL.optArgs,true,true)>
	<!---<cfdump var="#getPost#">--->
	<!--- Get the post header  --->
	<cfset postHeader = getPost[1]["PostHeader"]>
		
	<script>

		function postHeaderContent(){

			jQuery.ajax({
				type: 'post', 
				url: '<cfoutput>#application.baseUrl#</cfoutput>/common/cfc/ProxyController.cfc?method=savePostHeader&csrfToken=<cfoutput>#csrfToken#</cfoutput>',
				data: { // arguments
					postId: <cfoutput>#URL.optArgs#</cfoutput>,
					postHeader: $("#headerContent").val()//$("#headerContent").val()
				},
				dataType: "json",
				success: postHeaderContentResult, // calls the result function.
				error: function(ErrorMsg) {
					console.log('Error' + ErrorMsg);
				}
			// Extract any errors. This is a new jQuery promise based function as of jQuery 1.8.
			}).fail(function (jqXHR, textStatus, error) {
				// Close the wait window that was launched in the calling function.
				kendo.ui.ExtWaitDialog.hide();
				// Display the error. The full response is: jqXHR.responseText, but we just want to extract the error.
				$.when(kendo.ui.ExtAlertDialog.show({ title: "Error while consuming the postHeaderContent function", message: error, icon: "k-ext-error", width: "<cfoutput>#application.kendoExtendedUiWindowWidth#</cfoutput>" }) // or k-ext-error, k-ext-information, k-ext-question, k-ext-warning.  You can also specify height.
					).done(function () {
					
				});		
			});
		};

		function postHeaderContentResult(response){
			// Close this window.
			$('#postHeaderWindow').kendoWindow('destroy');
		}
		
	</script>
		
	<form id="postHeaderForm" action="#" method="post" data-role="validator">
	<!--- Pass the csrfToken --->
	<input type="hidden" name="csrfToken" id="csrfToken" value="<cfoutput>#csrfToken#</cfoutput>" />
	<table align="center" class="k-content tableBorder" width="100%" cellpadding="2" cellspacing="0" border="0">
	  <cfsilent>
			<!---The first content class in the table should be empty. --->
			<cfset thisContentClass = HtmlUtilsObj.getKendoClass('')>
			<!--- Set the colspan property for borders --->
			<cfset thisColSpan = "2">
	  </cfsilent>
	  <tr height="1px">
		  <td align="left" valign="top" colspan="2" class="<cfoutput>#thisContentClass#</cfoutput>"></td>
	  </tr>
	  <cfif session.isMobile>
	  <tr valign="middle">
		<td class="<cfoutput>#thisContentClass#</cfoutput>" colspan="2">
			The Post Header is used to attach optional ColdFusion cfincludes, javascripts, CSS, and Galaxie Blog Directives to a post. 
		</td>
	   </tr>
	<cfelse><!---<cfif session.isMobile>--->
	  <tr height="30px">
		<td align="left" class="<cfoutput>#thisContentClass#</cfoutput>" colspan="2"> 
			The Post Header is used to attach <b>optional</b> code, such as Javascript, CSS, ColdFusion cfincludes, and Galaxie Blog Directives to a post. It is designed to keep the logic separate from the WYSIWYG Post Editor as the editor manipulates the DOM and HTML. You may also use <a href="https://gregoryalexander.com/blog/2019/12/14/Galaxie-Blog-XML-Post-Directives">Galaxie Blog Directives</a> to override ColdFusion's the Global Script Protection if it is turned on.
		</td>
	  </tr>
	</cfif>
	  <!-- Border -->
	  <tr height="2px">
		  <td align="left" valign="top" colspan="<cfoutput>#thisColSpan#</cfoutput>" class="<cfoutput>#thisContentClass#</cfoutput>"></td>
	  </tr>
	  <cfsilent>
	  <!--- Set the class for alternating rows. --->
	  <!---After the first row, the content class should be the current class. --->
	  <cfset thisContentClass = HtmlUtilsObj.getKendoClass(thisContentClass)>
	  </cfsilent>
	  <tr height="2px">
		  <td align="left" valign="top" colspan="2" class="border <cfoutput>#thisContentClass#</cfoutput>"></td>
	  </tr>
	  <!-- Form content -->
	<cfif session.isMobile>
	  <tr valign="middle">
		<td class="<cfoutput>#thisContentClass#</cfoutput>" colspan="2">
			<label for="headerContent">Post Header</label>
		</td>
	   </tr>
	   <tr>
		<td class="<cfoutput>#thisContentClass#</cfoutput>" colspan="2">
			<textarea id="headerContent" name="headerContent" rows="10" cols="20"><cfoutput>#postHeader#</cfoutput></textarea>
		</td>
	  </tr>
	<cfelse><!---<cfif session.isMobile>--->
	  <tr valign="middle" height="30px">
		<td align="right" valign="middle" class="<cfoutput>#thisContentClass#</cfoutput>" width="20%">
			<label for="headerContent">Post Header</label>
		</td>
		<td align="left" class="<cfoutput>#thisContentClass#</cfoutput>">
			<textarea id="headerContent" name="headerContent" rows="20" cols="75"><cfoutput>#postHeader#</cfoutput></textarea>
		</td>
	  </tr>
	</cfif>
	  <!-- Border -->
	  <tr height="2px">
		<td align="left" valign="top" colspan="<cfoutput>#thisColSpan#</cfoutput>" class="<cfoutput>#thisContentClass#</cfoutput>"></td>
	  </tr>
	  <cfsilent>
	  <!--- Set the class for alternating rows. --->
	  <!--- After the first row, the content class should be the current class. --->
	  <cfset thisContentClass = HtmlUtilsObj.getKendoClass(thisContentClass)>
	  </cfsilent>
	  <tr height="2px">
		  <td align="left" valign="top" colspan="2" class="border <cfoutput>#thisContentClass#</cfoutput>"></td>
	  </tr>
	  <!-- Form content -->
	  <tr valign="middle" height="30px">
		<td valign="bottom" align="right" class="<cfoutput>#thisContentClass#</cfoutput>">&nbsp;</td>
		<td valign="bottom" align="left" class="<cfoutput>#thisContentClass#</cfoutput>">
			<button id="postHeaderSubmit" name="postHeaderSubmit" class="k-button k-primary" type="button" onClick="postHeaderContent()">Submit</button>
		</td>
	  </tr>
	</table>
	</form>
	
</cfcase>
		  
<!---//*******************************************************************************************************************
				Sort Order Date
//********************************************************************************************************************--->
		  
<cfcase value="43">
	
	<!--- Instantiate the Render.cfc. This will be used to render our directives and create video and map thumbnails --->
	<cfobject component="#application.rendererComponentPath#" name="RendererObj">
	
	<!--- Get the post ( getPostByPostId(postId, showPendingPosts, showRemovedPosts) ) --->
	<cfset getPost = application.blog.getPostByPostId(URL.optArgs,true,true)>
	<!---<cfdump var="#getPost#">--->
		
	<!--- Get the sort order date --->
	<cfset blogSortDate = getPost[1]["BlogSortDate"]>
		
	<script>
		
		var todaysDate = new Date();
		var currentBlogSortDate = $("#newBlogSortDate").val();
			
		// Kendo Dropdowns
		// Date posted date/time picker			
		$("#blogSortDate").kendoDateTimePicker({
			componentType: "modern",
			value: <cfoutput>#application.Udf.jsDateFormat(getPost[1]['BlogSortDate'])#</cfoutput>
		});

		function onBlogSortDateSubmit() {
			// alert("Change :: " + kendo.toString(this.value(), 'g'));
			// Check to see if the selected date is greater than today
			if ($("#blogSortDate").val() > todaysDate){
				$.when(kendo.ui.ExtYesNoDialog.show({ 
					title: "Set the sort date in the future?",
					message: "You are setting this to a date in the future. Do you want to continue?",
					icon: "k-ext-warning",
					width: "<cfoutput>#application.kendoExtendedUiWindowWidth#</cfoutput>", 
					height: "215px"
				})
				).done(function (response) { // If the user clicked 'yes'
					if (response['button'] == 'Yes'){// remember that js is case sensitive.
						// Change the hidden input field on the post details page
						$("#newBlogSortDate").val($("#blogSortDate").val());
					}//..if (response['button'] == 'Yes'){
				});
			} else {
				// Change the hidden input field on the post details page
				$("#newBlogSortDate").val($("#blogSortDate").val());
			}
			// Close this window.
			$('#blogSortDateWindow').kendoWindow('destroy');
		}
		
	</script>
		
	<form id="postBlogSortDateForm" action="#" method="post" data-role="validator">
	<!--- Pass the csrfToken --->
	<input type="hidden" name="csrfToken" id="csrfToken" value="<cfoutput>#csrfToken#</cfoutput>" />
	<table align="center" class="k-content tableBorder" width="100%" cellpadding="2" cellspacing="0" border="0">
	  <cfsilent>
			<!---The first content class in the table should be empty. --->
			<cfset thisContentClass = HtmlUtilsObj.getKendoClass('')>
			<!--- Set the colspan property for borders --->
			<cfset thisColSpan = "2">
	  </cfsilent>
	  <tr height="1px">
		  <td align="left" valign="top" colspan="2" class="<cfoutput>#thisContentClass#</cfoutput>"></td>
	  </tr>
	  <cfif session.isMobile>
	  <tr valign="middle">
		<td class="<cfoutput>#thisContentClass#</cfoutput>" colspan="2">
			<p>The Blog Sort Date is be used to change the sort order of the posts in a different order than the actual post date.</p>
			
			<p>To change the sort order on the main blog page, choose a sort date between the dates of two different posts. For example, if you want this to show up underneath a post with the post made on New Year's Day, but above your post made during Christmas, set the date to something between December 25th and January 1st.</p>
		</td>
	   </tr>
	<cfelse><!---<cfif session.isMobile>--->
	  <tr height="30px">
		<td align="left" class="<cfoutput>#thisContentClass#</cfoutput>" colspan="2"> 
			<p>The Blog Sort Date is be used to change the sort order of the posts in a different order than the actual post date.</p>
			
			<p>To change the sort order on the main blog page, choose a sort date between the dates of two different posts. For example, if you want this to show up underneath a post with the post made on New Year's Day, but above your post made during Christmas, set the date to something between December 25th and January 1st.</p>
		</td>
	  </tr>
	</cfif>
	  <!-- Border -->
	  <tr height="2px">
		  <td align="left" valign="top" colspan="<cfoutput>#thisColSpan#</cfoutput>" class="<cfoutput>#thisContentClass#</cfoutput>"></td>
	  </tr>
	  <cfsilent>
	  <!--- Set the class for alternating rows. --->
	  <!---After the first row, the content class should be the current class. --->
	  <cfset thisContentClass = HtmlUtilsObj.getKendoClass(thisContentClass)>
	  </cfsilent>
	  <tr height="2px">
		  <td align="left" valign="top" colspan="2" class="border <cfoutput>#thisContentClass#</cfoutput>"></td>
	  </tr>
	  <!-- Form content -->
	<cfif session.isMobile>
	  <tr valign="middle">
		<td class="<cfoutput>#thisContentClass#</cfoutput>" colspan="2">
			<label for="blogSortDate">Post Sort Date</label>
		</td>
	   </tr>
	   <tr>
		<td class="<cfoutput>#thisContentClass#</cfoutput>" colspan="2">
			<input id="blogSortDate" name="blogSortDate" value="<cfoutput>#dateTimeFormat(blogSortDate, 'medium')#</cfoutput>" style="width: <cfif session.isMobile>95<cfelse>45</cfif>%" /> 
		</td>
	  </tr>
	<cfelse><!---<cfif session.isMobile>--->
	  <tr valign="middle" height="30px">
		<td align="right" valign="middle" class="<cfoutput>#thisContentClass#</cfoutput>" width="20%">
			<label for="blogSortDate">Post Sort Date</label>
		</td>
		<td align="left" class="<cfoutput>#thisContentClass#</cfoutput>">
			<input id="blogSortDate" name="blogSortDate" value="<cfoutput>#dateTimeFormat(blogSortDate, 'medium')#</cfoutput>" style="width: <cfif session.isMobile>95<cfelse>45</cfif>%" /> 
		</td>
	  </tr>
	</cfif>
	  <!-- Border -->
	  <tr height="2px">
		<td align="left" valign="top" colspan="<cfoutput>#thisColSpan#</cfoutput>" class="<cfoutput>#thisContentClass#</cfoutput>"></td>
	  </tr>
	  <cfsilent>
	  <!--- Set the class for alternating rows. --->
	  <!--- After the first row, the content class should be the current class. --->
	  <cfset thisContentClass = HtmlUtilsObj.getKendoClass(thisContentClass)>
	  </cfsilent>
	  <tr height="2px">
		  <td align="left" valign="top" colspan="2" class="border <cfoutput>#thisContentClass#</cfoutput>"></td>
	  </tr>
	  <!-- Form content -->
	  <tr valign="middle" height="30px">
		<td valign="bottom" align="right" class="<cfoutput>#thisContentClass#</cfoutput>">&nbsp;</td>
		<td valign="bottom" align="left" class="<cfoutput>#thisContentClass#</cfoutput>">
			<button id="postHeaderSubmit" name="postHeaderSubmit" class="k-button k-primary" type="button" onClick="onBlogSortDateSubmit()">Submit</button>
		</td>
	  </tr>
	</table>
	</form>
		
</cfcase>
		  
<!---//*******************************************************************************************************************
				Set Post Theme
//********************************************************************************************************************--->
		  
<cfcase value="44">
	
	<!--- Instantiate the Render.cfc. This will be used to render our directives and create video and map thumbnails --->
	<cfobject component="#application.rendererComponentPath#" name="RendererObj">
	
	<!--- Get the post ( getPostByPostId(postId, showPendingPosts, showRemovedPosts) ). --->
	<cfset getPost = application.blog.getPostByPostId(URL.optArgs,true,true)>
	<!--- Get the current theme --->
	<cfset postThemeId = getPost[1]["ThemeRef"]>
	<!--- Get the themes. This is a HQL array --->
	<cfset themeNames = application.blog.getThemeNames()>
	<!---<cfdump var="#themeNames#">--->
		
	<script>
		
		$(document).ready(function() {
			// Create the top level dropdown
			var postThemeDropdown = $("#postThemeDropdown").kendoComboBox();
		});
		
		function onPostThemeSubmit() {
			// Change the hidden input field on the post details page
			$("#postThemeId").val($("#postThemeDropdown").val());
			// Close this window.
			$('#setPostThemeWindow').kendoWindow('destroy');
		}
		
	</script>
		
	<form id="postThemeForm" action="#" method="post" data-role="validator">
	<!--- Pass the csrfToken --->
	<input type="hidden" name="csrfToken" id="csrfToken" value="<cfoutput>#csrfToken#</cfoutput>" />
	<table align="center" class="k-content tableBorder" width="100%" cellpadding="2" cellspacing="0" border="0">
	  <cfsilent>
			<!---The first content class in the table should be empty. --->
			<cfset thisContentClass = HtmlUtilsObj.getKendoClass('')>
			<!--- Set the colspan property for borders --->
			<cfset thisColSpan = "2">
	  </cfsilent>
	  <tr height="1px">
		  <td align="left" valign="top" colspan="2" class="<cfoutput>#thisContentClass#</cfoutput>"></td>
	  </tr>
	  <cfif session.isMobile>
	  <tr valign="middle">
		<td class="<cfoutput>#thisContentClass#</cfoutput>" colspan="2">
			<p>You can attach a unique theme to a given post.</p> 
			<p>This does not have any impact on the main blog page, but it will display the chosen theme when the user is looking at this post.</p>
		</td>
	   </tr>
	<cfelse><!---<cfif session.isMobile>--->
	  <tr height="30px">
		<td align="left" class="<cfoutput>#thisContentClass#</cfoutput>" colspan="2"> 
			<p>You can attach a unique theme to a given post.</p> 
			<p>This was designed to allow blog owners to create a post that has a unique theme. For example, you can create your own holiday-oriented theme on your 'Happy Holidays!' post, or on a post that supports a certain cause (i.e. 'Donate to breast cancer awareness'.</p> <p>This does not have any impact on the main blog page, but it will display the chosen theme when the user is looking at this post.</p>
		</td>
	  </tr>
	</cfif>
	  <!-- Border -->
	  <tr height="2px">
		  <td align="left" valign="top" colspan="<cfoutput>#thisColSpan#</cfoutput>" class="<cfoutput>#thisContentClass#</cfoutput>"></td>
	  </tr>
	  <cfsilent>
	  <!--- Set the class for alternating rows. --->
	  <!---After the first row, the content class should be the current class. --->
	  <cfset thisContentClass = HtmlUtilsObj.getKendoClass(thisContentClass)>
	  </cfsilent>
	  <tr height="2px">
		  <td align="left" valign="top" colspan="2" class="border <cfoutput>#thisContentClass#</cfoutput>"></td>
	  </tr>
	  <!-- Form content -->
	<cfif session.isMobile>
	  <tr valign="middle">
		<td class="<cfoutput>#thisContentClass#</cfoutput>" colspan="2">
			<label for="setPostTheme">Set Post Theme</label>
		</td>
	   </tr>
	   <tr>
		<td class="<cfoutput>#thisContentClass#</cfoutput>" colspan="2">
			<select id="postThemeDropdown" name="postThemeDropdown">
				<option value="0">None Selected</option>
				<cfloop from="1" to="#arrayLen(themeNames)#" index="i"><cfoutput><option value="#themeNames[i]['ThemeId']#" <cfif postThemeId eq themeNames[i]['ThemeId']>selected</cfif>>#themeNames[i]['ThemeName']#</option></cfoutput></cfloop>
			</select>
		</td>
	  </tr>
	<cfelse><!---<cfif session.isMobile>--->
	  <tr valign="middle" height="30px">
		<td align="right" valign="middle" class="<cfoutput>#thisContentClass#</cfoutput>" width="20%">
			<label for="setPostTheme">Set Post Theme</label>
		</td>
		<td align="left" class="<cfoutput>#thisContentClass#</cfoutput>">
			<select id="postThemeDropdown" name="postThemeDropdown">
				<option value="0">None Selected</option>
				<cfloop from="1" to="#arrayLen(themeNames)#" index="i"><cfoutput><option value="#themeNames[i]['ThemeId']#" <cfif postThemeId eq themeNames[i]['ThemeId']>selected</cfif>>#themeNames[i]['ThemeName']#</option></cfoutput></cfloop>
			</select>
		</td>
	  </tr>
	</cfif>
	  <!-- Border -->
	  <tr height="2px">
		<td align="left" valign="top" colspan="<cfoutput>#thisColSpan#</cfoutput>" class="<cfoutput>#thisContentClass#</cfoutput>"></td>
	  </tr>
	  <cfsilent>
	  <!--- Set the class for alternating rows. --->
	  <!--- After the first row, the content class should be the current class. --->
	  <cfset thisContentClass = HtmlUtilsObj.getKendoClass(thisContentClass)>
	  </cfsilent>
	  <tr height="2px">
		  <td align="left" valign="top" colspan="2" class="border <cfoutput>#thisContentClass#</cfoutput>"></td>
	  </tr>
	  <!-- Form content -->
	  <tr valign="middle" height="30px">
		<td valign="bottom" align="right" class="<cfoutput>#thisContentClass#</cfoutput>">&nbsp;</td>
		<td valign="bottom" align="left" class="<cfoutput>#thisContentClass#</cfoutput>">
			<!--- The onPostThemeSubmit changes a dropdown in the post detail page. It does not trigger the saving of the theme. The save function is invoked using on onPostThemeSubmit js function --->
			<button id="postThemeSubmit" name="postThemeSubmit" class="k-button k-primary" type="button" onClick="onPostThemeSubmit()">Submit</button>
		</td>
	  </tr>
	</table>
	</form>
		
</cfcase>
		
<!---//*******************************************************************************************************************
				Custom Window
//********************************************************************************************************************--->
		  
<cfcase value="45">
	
	<!--- Debugging
	<cfdump var="#url#">
	<cfoutput>
		postId (URL.optArgs): #URL.optArgs#<br/>
		windowId (URL.otherArgs): #URL.otherArgs#<br/>
		isNumeric(URL.otherArgs): #isNumeric(URL.otherArgs)#<br/>
	</cfoutput>
	--->
	
	<!--- Instantiate the Render.cfc. This will be used to render our directives and create video and map thumbnails --->
	<cfobject component="#application.rendererComponentPath#" name="RendererObj">
		
	<!--- Get all custom windows for this post. --->
	<cfset getCustomWindows = application.blog.getCustomWindowContent(URL.optArgs)>
	<!---<cfdump var="#getCustomWindows#">--->
		
	<style>
		label {
			font-weight: normal;
		}

		normalFontWeight {
			font-weight: normal;
		}
	</style>
		
	<cfif arrayLen(getCustomWindows) gt 0 and not isNumeric(URL.otherArgs)>
		
		<script>
			function openCustomWindowInterface(windowId){
				// Get the selected windowId
				windowId = $('input[name="customWindowId"]:checked').val();
				// alert(windowId);
				// Create a new custom window if no radio button was clicked
				if (typeof windowId === 'undefined'){
					// alert(0);
					windowId = 0;
				}
				// Close this window 
				$('#customWindow').kendoWindow('destroy');
				// Direct the user to the detail page. The windowId is either the selected customWindowId or zero (optArgs), the last arg (otherArgs) is the postId.
				createAdminInterfaceWindow(45,<cfoutput>#URL.optArgs#</cfoutput>,windowId);
			}

		</script>
	
		<!---//***************************************************************************************************************
					Custom Window Picker 
		//****************************************************************************************************************--->
		
		<table align="center" class="k-content" width="100%" cellpadding="2" cellspacing="0">
		  <cfsilent>
			<!---The first content class in the table should be empty. --->
			<cfset thisContentClass = HtmlUtilsObj.getKendoClass('')>
			<!--- Set the colspan property for borders --->
			<cfset thisColSpan = "2">
		  </cfsilent>
		  <tr height="1px">
			  <td align="left" valign="top" colspan="2" class="<cfoutput>#thisContentClass#</cfoutput>">
				Please choose the custom window that you want to edit.
			  </td>
		  </tr>
		  <cfsilent>
		  <!--- Set the class for alternating rows. --->
		  <!--- After the first row, the content class should be the current class. --->
		  <cfset thisContentClass = HtmlUtilsObj.getKendoClass(thisContentClass)>
		  </cfsilent>
		  <!-- Border -->
		  <tr height="2px">
			  <td align="left" valign="top" colspan="<cfoutput>#thisColSpan#</cfoutput>" class="<cfoutput>#thisContentClass#</cfoutput>"></td>
		  </tr>
		  <tr>
		  <tr valign="middle">
			<td align="right" class="<cfoutput>#thisContentClass#</cfoutput>" style="width: 7%"> 
				<input type="radio" id="customWindowId" name="customWindowId" value="0">
			</td>
			<td class="<cfoutput>#thisContentClass#</cfoutput>">
				<label for="buttonLabel">Create New Custom Window</label>
			</td>
		  </tr>
		  <!-- Border -->
		  <tr height="2px">
			  <td align="left" valign="top" colspan="<cfoutput>#thisColSpan#</cfoutput>" class="<cfoutput>#thisContentClass#</cfoutput>"></td>
		  </tr>
		<!--- Loop through the windows to allow the user to select the window that they want to edit --->
		<cfloop from="1" to="#arrayLen(getCustomWindows)#" index="i">
		  <cfsilent>
		  <cfset customWindowId = getCustomWindows[i]['CustomWindowContentId']>
		  <cfset title = getCustomWindows[i]['WindowTitle']>
		  <!--- Set the class for alternating rows. --->
		  <!--- After the first row, the content class should be the current class. --->
		  <cfset thisContentClass = HtmlUtilsObj.getKendoClass(thisContentClass)>
		  </cfsilent>
		  <!-- Border -->
		  <tr height="2px">
			  <td align="left" valign="top" colspan="<cfoutput>#thisColSpan#</cfoutput>" class="<cfoutput>#thisContentClass#</cfoutput>"></td>
		  </tr>
		  <tr>
		  <tr valign="middle">
			<td align="right" class="<cfoutput>#thisContentClass#</cfoutput>" style="width: 7%"> 
				<input type="radio" id="customWindowId" name="customWindowId" value="<cfoutput>#customWindowId#</cfoutput>">
			</td>
			<td class="<cfoutput>#thisContentClass#</cfoutput>">
				<label for="buttonLabel"><cfoutput>#title#</cfoutput></label>
			</td>
		  </tr>
		  <!-- Border -->
		  <tr height="2px">
			  <td align="left" valign="top" colspan="<cfoutput>#thisColSpan#</cfoutput>" class="<cfoutput>#thisContentClass#</cfoutput>"></td>
		  </tr>
		</cfloop>
		<cfsilent>
		  <!--- Set the class for alternating rows. --->
		  <!---After the first row, the content class should be the current class. --->
		  <cfset thisContentClass = HtmlUtilsObj.getKendoClass(thisContentClass)>
		  </cfsilent>
		  <!-- Border -->
		  <tr height="2px">
			<td align="left" valign="top" colspan="<cfoutput>#thisColSpan#</cfoutput>" class="<cfoutput>#thisContentClass#</cfoutput>"></td>
		  </tr>
		  <!-- Form content -->
		  <tr valign="middle" height="30px">
			<td valign="bottom" align="right" class="<cfoutput>#thisContentClass#</cfoutput>">&nbsp;</td>
			<td valign="bottom" align="left" class="<cfoutput>#thisContentClass#</cfoutput>">
				<!--- The onPostThemeSubmit changes a dropdown in the post detail page. It does not trigger the saving of the theme. The save function is invoked using on onPostThemeSubmit js function --->
				<button id="customWindowPickerSubmit" name="customWindowPickerSubmit" class="k-button k-primary" type="button" onClick="openCustomWindowInterface()">Submit</button>
			</td>
		  </tr>
		</table>
		  
	<cfelse>
		
		<!---//***************************************************************************************************************
					Custom Window Detail 
		//****************************************************************************************************************--->
		
		<!---<cfdump var="#URL#">--->
		<!--- Get the content detail ( ( getCustomWindowContentById(customWindowId) ) ). Note: the postId here is URL.otherArgs --->
		<cfif isDefined("URL.otherArgs") and isNumeric(URL.otherArgs)>
			<cfset getCustomWindowContent = application.blog.getCustomWindowContentById(URL.otherArgs)>
			<cfset otherArgs = URL.otherArgs>
		<cfelse>
			<cfif arrayLen(getCustomWindows) eq 1>
				<!--- If there is only record in the getCustomWindows query, get the result --->
				<cfset getCustomWindowContent = application.blog.getCustomWindowContentById(getCustomWindows[1]["CustomWindowContentId"])>
				<cfset otherArgs = getCustomWindows[1]["CustomWindowContentId"]>
			<cfelse>
				<!--- This is a new record for the post. --->
				<cfset otherArgs = 0>
				<cfset getCustomWindowContent = application.blog.getCustomWindowContentById(0)>
			</cfif>
		</cfif>
		<!---<cfdump var="#getCustomWindowContent#">--->

		<!--- Get the Content if it exists --->
		<cfif arrayLen(getCustomWindowContent)>
			<cfset buttonLabel = getCustomWindowContent[1]["ButtonLabel"]>
			<cfset windowTitle = getCustomWindowContent[1]["WindowTitle"]>
			<cfset windowHeight = getCustomWindowContent[1]["WindowHeight"]>
			<cfset windowWidth = getCustomWindowContent[1]["WindowWidth"]>
			<cfset cfincludePath = getCustomWindowContent[1]["CfincludePath"]>
			<cfset content = getCustomWindowContent[1]["Content"]>
		<cfelse>
			<cfset buttonLabel = "">
			<cfset windowTitle = "">
			<cfset windowHeight = "">
			<cfset windowWidth = "">
			<cfset cfincludePath = "">
			<cfset content = "">
		</cfif>
		<!--- Determine the existing unit of measure. Will use pixels if nothing is present --->
		<cfif windowWidth contains '%'>
			<cfset userMeasurement = '%'>
		<cfelse>
			<cfset userMeasurement = 'px'>
		</cfif>
				
		<!---//***************************************************************************************************************
					TinyMce Scripts
		//****************************************************************************************************************--->

		<!---********************* Custom Content editor *********************--->
		<!--- Set the common vars for tinymce. --->
		<cfsilent>
		<cfset selectorId = "customWindowEditor">
		<cfif smallScreen>
			<cfset editorHeight = "600">
		<cfelse>
			<cfset editorHeight = "650">
		</cfif>
		<cfset imageHandlerUrl = application.baseUrl & "/common/cfc/ProxyController.cfc?method=uploadImage&mediaProcessType=post&mediaType=image&postId=" & URL.optArgs & "&selectorId=" & selectorId & "&csrfToken=" & csrfToken>
		<cfset contentVar = content><!---EncodeForHTMLAttribute--->
		<cfset imageMediaIdField = "imageMediaId">
		<cfset imageClass = "entryImage">

		<cfif smallScreen>
			<cfset toolbarString = "undo redo | bold italic | link | image media fancyBoxGallery">
		<cfelse>
			<cfset toolbarString = "insertfile undo redo | styleselect | bold italic | alignleft aligncenter alignright alignjustify | bullist numlist outdent indent | tox | hr | link | image editimage | media | fancyBoxGallery | map mapRouting | customWindow | emoticons">
		</cfif>
		<cfset includeGallery = true>
		<cfset includeCustomWindow = true>
		</cfsilent>

		<!--- Include the tinymce js template --->
		<cfinclude template="#application.baseUrl#/includes/templates/js/tinyMce.cfm">

		<script>
			
			// Numeric inputs
			$("#contentWidth").kendoNumericTextBox({
				decimals: 0,
				round: true
			});

			$("#mainContainerWidth").kendoNumericTextBox({
				decimals: 0,
				round: true
			});
			
			$(document).ready(function() {
				
				// !!! Note on the validators, all forms need a name attribute, otherwise the positioning of the messages will not work. --->
				var customWindowValidater = $("#customWindowForm").kendoValidator({
					// Set up custom validation rules 
					rules: {
						// buttonLabel
						buttonLabelRequired:
						function(input){
							if (input.is("[id='buttonLabel']") && $.trim(input.val()).length < 3){
								// Display an error on the page.
								input.attr("data-buttonLabelRequired-msg", "The label must be at least 3 characters");
								// Focus on the current element
								$( "#buttonLabel" ).focus();
								return false;
							}                                    
							return true;
						},
						// windowTitle
						windowTitleRequired:
						function(input){
							if (input.is("[id='windowTitle']") && $.trim(input.val()).length < 3){
								// Display an error on the page.
								input.attr("data-windowTitleRequired-msg", "The title must be at least 3 characters");
								// Focus on the current element
								$( "#password" ).focus();
								return false;
							}                                    
							return true;
						},
					}
				}).data("kendoValidator");
				
				// Invoked when the submit button is clicked. Insted of using '$("form").submit(function(event) {' and 'event.preventDefault();', We are using direct binding here to speed up the event.
				var customWindowSubmit = $('#customWindowSubmit');
				customWindowSubmit.on('click', function(e){      
					e.preventDefault();         
					if (customWindowValidater.validate()) {
						
						if ( !($('#active').is(':checked')) ) {
							// Raise a warning if the active checkbox is not checked
							// Note: this is a custom library that I am using. The ExtAlertDialog is not a part of Kendo but an extension.
							$.when(kendo.ui.ExtYesNoDialog.show({ 
								title: "Remove Window?",
								message: "Are you sure? This will remove this window from the blog",
								icon: "k-ext-warning",
								width: "<cfoutput>#application.kendoExtendedUiWindowWidth#</cfoutput>", 
								height: "215px"
							})
							).done(function (response) { // If the user clicked 'yes', post it.
								if (response['button'] == 'Yes'){// remember that js is case sensitive.
									// Post it
									postCustomWindowDetail();
								}//..if (response['button'] == 'Yes'){
							});
						} else {
							// submit the form.
							postCustomWindowDetail();
						}
						
					} else {
						$.when(kendo.ui.ExtAlertDialog.show({ title: "There are errors", width: "<cfoutput>#application.kendoExtendedUiWindowWidth#</cfoutput>", message: "Required fields are missing.", icon: "k-ext-warning" }) // or k-ext-error, k-ext-question
							).done(function () {
							// Do nothing
						});
					}
				});
				
			});//...document.ready
					
			function setActiveContentField(field){
				if (field == 'customWindowEditor'){
					$("#customWindowEditor").attr('disabled', false);
					$("#cfincludePath").attr('disabled', true);
				} else {
					$("#cfincludePath").attr('disabled', false);
					$("#customWindowEditor").attr('disabled', true);
				}
			}
			
			function postCustomWindowDetail(){

				jQuery.ajax({
					type: 'post', 
					url: '<cfoutput>#application.baseUrl#</cfoutput>/common/cfc/ProxyController.cfc?method=saveCustomWindow&csrfToken=<cfoutput>#csrfToken#</cfoutput>',
					data: { // arguments
						postId: $("#postId").val(),
						customWindowId: $("#customWindowId").val(),
						buttonLabel: $("#buttonLabel").val(),
						windowTitle: $("#windowTitle").val(),
						unitMeasurement: $("input[id=unitMeasurement]:checked").val(),
						windowHeight: $("#windowHeight").val(),
						windowWidth: $("#windowWidth").val(),
						cfincludePath: $("#cfincludePath").val(),
						windowContent: tinymce.get("<cfoutput>#selectorName#</cfoutput>").getContent(),
						active: $('#active').is(':checked'), // checkbox boolean value.
						selectorId: '<cfoutput>#selectorId#</cfoutput>'
					},
					// This is one of the few times that we will be sending back an html response. We are going to use this directly to set the content in the editor. its easier to craft the html on the server side than to manipulate the dom with a json object on the client. Normally this is always json
					dataType: "json",
					success: customWindowDetailResult, // calls the result function.
					error: function(ErrorMsg) {
						console.log('Error' + ErrorMsg);
					}
				// Extract any errors. This is a new jQuery promise based function as of jQuery 1.8.
				}).fail(function (jqXHR, textStatus, error) {
					// Close the wait window that was launched in the calling function.
					kendo.ui.ExtWaitDialog.hide();
					// Display the error. The full response is: jqXHR.responseText, but we just want to extract the error.
					$.when(kendo.ui.ExtAlertDialog.show({ title: "Error while consuming the saveCustomWindow function", message: error, icon: "k-ext-error", width: "<cfoutput>#application.kendoExtendedUiWindowWidth#</cfoutput>" }) // or k-ext-error, k-ext-information, k-ext-question, k-ext-warning.  You can also specify height.
						).done(function () {

					});		
				});
			};
			
			function customWindowDetailResult(response){

				// Did the server successfully process this?
				if (JSON.parse(response.success) == true){
					// Is it active?
					 if ($('#active').is(':checked')){
						// Get the titleAlias from the response. This will be appended to the URL to make the link
						titleAlias = JSON.parse(JSON.stringify(response.titleAlias));
						// To set content, typically get use the tinymce.activeEditor. However, this will not work since there are now two active editors (this one and the post editor). We need to use the editor name to set the content. The post editor name is set using the minute and seconds appended to a 'postEditor' string, and we write a cookie when we create it to get to the proper name. Get this name
						postEditorName = <cfoutput>'#evaluate("cookie.postEditor")#'</cfoutput>;
						// Insert the content into the active tinymce editor. The response is json coming from the server
						tinymce.get(postEditorName).insertContent(JSON.parse(JSON.stringify(response.buttonHtml)));
						// Display the link to the user
						$.when(kendo.ui.ExtAlertDialog.show({ title: "Your window has been created", message: 'A button has been placed in the editor to launch your custom window. You can get the source code by clicking on view source and copying the HTML. This HTML can be placed anywhere on the blog. The following link can also be used to open up your custom window:<br/> <cfoutput>#application.blogHostUrl#</cfoutput>/?customWindow=' + titleAlias, icon: "k-ext-information", width: "<cfoutput>#application.kendoExtendedUiWindowWidth#</cfoutput>", height: "325px" }) // or k-ext-error, k-ext-question
						).done(function () {
							// Do nothing
						});
					 }//..if ($('#active').is(':checked')){
					// Close this window.
					$('#customWindow').kendoWindow('destroy');
				} else {
					// Alert the user that the login has failed.
					$.when(kendo.ui.ExtAlertDialog.show({ title: "Error saving post", message: response.errorMessage, icon: "k-ext-warning", width: "<cfoutput>#application.kendoExtendedUiWindowWidth#</cfoutput>", height: "125px" }) // or k-ext-error, k-ext-question
					).done(function () {
						// Do nothing
					});
					
				}//..if (JSON.parse(response.error) == true){
			}
		
		</script>
			
		<form id="customWindowForm" action="#" method="post" data-role="validator">
		<!--- Pass the postId and customWindowId --->
		<input type="hidden" id="postId" name="postId" value="<cfoutput>#URL.optArgs#</cfoutput>">
		<input type="hidden" id="customWindowId" name="customWindowId" value="<cfoutput>#otherArgs#</cfoutput>">
		<table align="center" class="k-content" width="100%" cellpadding="2" cellspacing="0">
		  <cfsilent>
			<!---The first content class in the table should be empty. --->
			<cfset thisContentClass = HtmlUtilsObj.getKendoClass('')>
			<!--- Set the colspan property for borders --->
			<cfset thisColSpan = "2">
		  </cfsilent>

		  <tr height="1px">
			  <td align="left" valign="top" colspan="2" class="<cfoutput>#thisContentClass#</cfoutput>">
				This interface will create a button to launch a window. The custom window can use a ColdFusion include (cfinclude) or you can use the editor to create the window content for you. However, you can only use one of these options, either a cfinclude or the WYSIWYG editor. 

				If you use a ColdFusion include, you must upload your include to the server and set the path below. Custom cfincludes may require a function or cfc to handle server operations.
			  </td>
		  </tr>
		  <cfsilent>
		  <!--- Set the class for alternating rows. --->
		  <!---After the first row, the content class should be the current class. --->
		  <cfset thisContentClass = HtmlUtilsObj.getKendoClass(thisContentClass)>
		  </cfsilent>
		  <!-- Border -->
		  <tr height="2px">
			  <td align="left" valign="top" colspan="<cfoutput>#thisColSpan#</cfoutput>" class="<cfoutput>#thisContentClass#</cfoutput>"></td>
		  </tr>
		  <tr>
		<tr valign="middle" height="30px">
			<td valign="bottom" align="left" class="<cfoutput>#thisContentClass#</cfoutput>" colspan="<cfoutput>#thisColSpan#</cfoutput>">
				The button label is the string that will show on the button that is automatically inserted.
			</td>
		  </tr>
		<cfif session.isMobile>
		  <tr valign="middle">
			<td class="<cfoutput>#thisContentClass#</cfoutput>" colspan="2">
				<label for="buttonLabel">Button Label:</label>
			</td>
		   </tr>
		   <tr>
			<td class="<cfoutput>#thisContentClass#</cfoutput>" colspan="2">
				<input id="buttonLabel" name="buttonLabel" type="text" value="<cfoutput>#buttonLabel#</cfoutput>" class="k-textbox" style="width: 95%" maxlength="125" required />    
			</td>
		  </tr>
		<cfelse><!---<cfif session.isMobile>--->
			<td align="right" class="<cfoutput>#thisContentClass#</cfoutput>" style="width: 25%"> 
				<label for="buttonLabel">Button Label:</label>
			</td>
			<td class="<cfoutput>#thisContentClass#</cfoutput>">
				<input id="buttonLabel" name="buttonLabel" type="text" value="<cfoutput>#buttonLabel#</cfoutput>" class="k-textbox" style="width: 95%" maxlength="125" required />  
			</td>
		  </tr>
		</cfif>
		  <!-- Border -->
		  <tr height="2px">
			  <td align="left" valign="top" colspan="<cfoutput>#thisColSpan#</cfoutput>" class="<cfoutput>#thisContentClass#</cfoutput>"></td>
		  </tr>
		  <cfsilent>
		  <!--- Set the class for alternating rows. --->
		  <!---After the first row, the content class should be the current class. --->
		  <cfset thisContentClass = HtmlUtilsObj.getKendoClass(thisContentClass)>
		  </cfsilent>

		  <tr height="2px">
			<td align="left" valign="bottom" colspan="2" class="border <cfoutput>#thisContentClass#</cfoutput>"></td>
		  </tr>
		  <tr valign="middle" height="30px">
			<td valign="bottom" align="left" class="<cfoutput>#thisContentClass#</cfoutput>" colspan="<cfoutput>#thisColSpan#</cfoutput>">
				The window title is the title that will show at the top of the custom window. Keep this name relatively short for mobile clients. 
			</td>
		  </tr>
		  <tr height="1px">
			  <td align="left" valign="top" colspan="2" class="border <cfoutput>#thisContentClass#</cfoutput>"></td>
		  </tr>
		<cfif session.isMobile>
		  <tr valign="middle">
			<td class="<cfoutput>#thisContentClass#</cfoutput>" colspan="2">
				<label for="windoTitle">Window Title</label>
			</td>
		   </tr>
		   <tr>
			<td class="<cfoutput>#thisContentClass#</cfoutput>" colspan="2">
				<input id="windowTitle" name="windowTitle" type="text" value="<cfoutput>#windowTitle#</cfoutput>" class="k-textbox" style="width: 95%" maxlength="125" required />
			</td>
		  </tr>
		<cfelse><!---<cfif session.isMobile>--->
		  <tr valign="middle" height="30px">
			<td valign="bottom" align="right" class="<cfoutput>#thisContentClass#</cfoutput>" style="width:20%">
				<label for="windoTitle">Window Title</label>
			</td>
			<td valign="bottom" align="left" class="<cfoutput>#thisContentClass#</cfoutput>" style="width:80%">
				<input id="windowTitle" name="windowTitle" type="text" value="<cfoutput>#windowTitle#</cfoutput>" class="k-textbox" style="width: 95%" maxlength="125" required />
			</td>
		  </tr>
		</cfif>
		  <!-- Border -->
		  <tr height="2px">
			<td align="left" valign="top" colspan="<cfoutput>#thisColSpan#</cfoutput>" class="<cfoutput>#thisContentClass#</cfoutput>"></td>
		  </tr>
		  <cfsilent>
		  <!--- Set the class for alternating rows. --->
		  <!---After the first row, the content class should be the current class. --->
		  <cfset thisContentClass = HtmlUtilsObj.getKendoClass(thisContentClass)>
		  </cfsilent>
		  <tr height="2px">
			  <td align="left" valign="bottom" colspan="2" class="border <cfoutput>#thisContentClass#</cfoutput>"></td>
		  </tr>
		  <tr valign="middle" height="30px">
			<td valign="bottom" align="left" class="<cfoutput>#thisContentClass#</cfoutput>" colspan="<cfoutput>#thisColSpan#</cfoutput>">
				You can use pixels or percent to control the height and width of the window. If you use percent it will use the screen size as the container.
			</td>
		  </tr>
		  <tr height="1px">
			  <td align="left" valign="top" colspan="2" class="border <cfoutput>#thisContentClass#</cfoutput>"></td>
		  </tr>
		<cfif session.isMobile>
		  <tr valign="middle">
			<td class="<cfoutput>#thisContentClass#</cfoutput>" colspan="2">
				<label for="unitMeasurement">Unit Measurement:</label>
			</td>
		   </tr>
		   <tr>
			<td class="<cfoutput>#thisContentClass#</cfoutput>" colspan="2">
				<input type="radio" id="unitMeasurement" name="unitMeasurement" value="px" <cfif userMeasurement eq 'px'>checked</cfif>> Pixels <input type="radio" id="unitMeasurement" name="unitMeasurement" value="%" <cfif userMeasurement eq '%'>checked</cfif>> Percent
			</td>
		  </tr>
		<cfelse><!---<cfif session.isMobile>--->
		  <tr valign="middle" height="30px">
			<td valign="center" align="right" class="<cfoutput>#thisContentClass#</cfoutput>">
				<label for="unitMeasurement">Unit Measurement:</label>
			</td>
			<td valign="bottom" align="left" class="<cfoutput>#thisContentClass#</cfoutput>">
				<input type="radio" id="unitMeasurement" name="unitMeasurement" value="px" <cfif userMeasurement eq 'px'>checked</cfif>> Pixels <input type="radio" id="unitMeasurement" name="unitMeasurement" value="%" <cfif userMeasurement eq '%'>checked</cfif>> Percent
			</td>
		  </tr>
		</cfif>
		  <!-- Border -->
		  <tr height="2px">
			<td align="left" valign="top" colspan="<cfoutput>#thisColSpan#</cfoutput>" class="<cfoutput>#thisContentClass#</cfoutput>"></td>
		  </tr>
		  <cfsilent>
		  <!--- Set the class for alternating rows. --->
		  <!---After the first row, the content class should be the current class. --->
		  <cfset thisContentClass = HtmlUtilsObj.getKendoClass(thisContentClass)>
		  </cfsilent>
		  <tr height="2px">
			  <td align="left" valign="bottom" colspan="2" class="border <cfoutput>#thisContentClass#</cfoutput>"></td>
		  </tr>
		  <tr valign="middle" height="30px">
			<td valign="bottom" align="left" class="<cfoutput>#thisContentClass#</cfoutput>" colspan="<cfoutput>#thisColSpan#</cfoutput>">
				The window width and height control the window size in percent. On mobile and smaller clients the windows will take 95% of the width of the device.
			</td>
		  </tr>
		  <tr height="1px">
			  <td align="left" valign="top" colspan="2" class="border <cfoutput>#thisContentClass#</cfoutput>"></td>
		  </tr>
		<cfif session.isMobile>
		  <tr valign="middle">
			<td class="<cfoutput>#thisContentClass#</cfoutput>" colspan="2">
				<label for="windowHeight">Window Height:</label>
			</td>
		   </tr>
		   <tr>
			<td class="<cfoutput>#thisContentClass#</cfoutput>" colspan="2">
				<input type="number" id="windowHeight" name="windowHeight" value="<cfoutput>#windowHeight#</cfoutput>" class="k-textbox" >
			</td>
		  </tr>
		<cfelse><!---<cfif session.isMobile>--->
		  <tr valign="middle" height="30px">
			<td valign="center" align="right" class="<cfoutput>#thisContentClass#</cfoutput>">
				<label for="windowHeight">Window Height:</label>
			</td>
			<td valign="bottom" align="left" class="<cfoutput>#thisContentClass#</cfoutput>">
				<input type="number" id="windowHeight" name="windowHeight" value="<cfoutput>#windowHeight#</cfoutput>" class="k-textbox" >
			</td>
		  </tr>
		</cfif>
		<!-- Border -->
		  <tr height="2px">
			<td align="left" valign="top" colspan="<cfoutput>#thisColSpan#</cfoutput>" class="<cfoutput>#thisContentClass#</cfoutput>"></td>
		  </tr>
		  <cfsilent>
		  <!--- Set the class for alternating rows. --->
		  <!---After the first row, the content class should be the current class. --->
		  <cfset thisContentClass = HtmlUtilsObj.getKendoClass(thisContentClass)>
		  </cfsilent>
		  <tr height="2px">
			  <td align="left" valign="bottom" colspan="2" class="border <cfoutput>#thisContentClass#</cfoutput>"></td>
		  </tr>
		<cfif session.isMobile>
		  <tr valign="middle">
			<td class="<cfoutput>#thisContentClass#</cfoutput>" colspan="2">
				<label for="windowWidth">Window Width:</label>
			</td>
		   </tr>
		   <tr>
			<td class="<cfoutput>#thisContentClass#</cfoutput>" colspan="2">
				<input type="number" id="windowWidth" name="windowHeight" value="<cfoutput>#windowWidth#</cfoutput>" class="k-textbox" >
			</td>
		  </tr>
		<cfelse><!---<cfif session.isMobile>--->
		  <tr valign="middle" height="30px">
			<td valign="center" align="right" class="<cfoutput>#thisContentClass#</cfoutput>">
				<label for="windowWidth">Window Width:</label>
			</td>
			<td valign="bottom" align="left" class="<cfoutput>#thisContentClass#</cfoutput>">
				<input type="number" id="windowWidth" name="windowHeight" value="<cfoutput>#windowWidth#</cfoutput>" class="k-textbox" >
			</td>
		  </tr>
		</cfif>
		<!-- Border -->
		  <tr height="2px">
			<td align="left" valign="top" colspan="<cfoutput>#thisColSpan#</cfoutput>" class="<cfoutput>#thisContentClass#</cfoutput>"></td>
		  </tr>
		  <cfsilent>
		  <!--- Set the class for alternating rows. --->
		  <!--- After the first row, the content class should be the current class. --->
		  <cfset thisContentClass = HtmlUtilsObj.getKendoClass(thisContentClass)>
		  </cfsilent>
		  <tr height="2px">
			  <td align="left" valign="bottom" colspan="2" class="border <cfoutput>#thisContentClass#</cfoutput>"></td>
		  </tr>
		  <tr valign="middle" height="30px">
			<td valign="bottom" align="left" class="<cfoutput>#thisContentClass#</cfoutput>" colspan="<cfoutput>#thisColSpan#</cfoutput>">
				A cfinclude is a ColdFusion include programmed using the ColdFusion markup or cfscript langauge. You can also use plain Javascript or HTML. You must upload the template to the server and have the path to the location for this to work. Use the editor below if you want to use a WYSIWYG interface.
			</td>
		  </tr>
		  <tr height="1px">
			  <td align="left" valign="top" colspan="2" class="border <cfoutput>#thisContentClass#</cfoutput>"></td>
		  </tr>
		<cfif session.isMobile>
		  <tr valign="middle">
			<td class="<cfoutput>#thisContentClass#</cfoutput>" colspan="2">
				<label for="cfincludePath">Cfinclude Path:</label>
			</td>
		   </tr>
		   <tr>
			<td class="<cfoutput>#thisContentClass#</cfoutput>" colspan="2">
				<input type="text" name="cfincludePath" id="cfincludePath" value="<cfoutput>#cfincludePath#</cfoutput>" class="k-textbox" style="width: 95%" onClick="setActiveContentField('cfincludePath');" />
			</td>
		  </tr>
		<cfelse><!---<cfif session.isMobile>--->
		  <tr valign="middle" height="30px">
			<td valign="center" align="right" class="<cfoutput>#thisContentClass#</cfoutput>">
				<label for="cfincludePath">Cfinclude Path:</label>
			</td>
			<td valign="bottom" align="left" class="<cfoutput>#thisContentClass#</cfoutput>">
				<input type="text" name="cfincludePath" id="cfincludePath" value="<cfoutput>#cfincludePath#</cfoutput>" class="k-textbox" style="width: 95%" onClick="setActiveContentField('cfincludePath');" />
			</td>
		  </tr>
		</cfif>
		<!-- Border -->
		  <tr height="2px">
			<td align="left" valign="top" colspan="<cfoutput>#thisColSpan#</cfoutput>" class="<cfoutput>#thisContentClass#</cfoutput>"></td>
		  </tr>
		  <cfsilent>
		  <!--- Set the class for alternating rows. --->
		  <!---After the first row, the content class should be the current class. --->
		  <cfset thisContentClass = HtmlUtilsObj.getKendoClass(thisContentClass)>
		  </cfsilent>
		<cfif session.isMobile>
		  <tr valign="middle">
			<td class="<cfoutput>#thisContentClass#</cfoutput>" colspan="2">
				<label for="windowContent">Content:</label>
			</td>
		   </tr>
		   <tr>
			<td class="<cfoutput>#thisContentClass#</cfoutput>" colspan="2">
				<input type="text" id="<cfoutput>#selectorName#</cfoutput>" name="<cfoutput>#selectorName#</cfoutput>" onClick="setActiveContentField('cfincludePath')" />
			</td>
		  </tr>
		<cfelse><!---<cfif session.isMobile>--->
		  <tr valign="middle" height="30px">
			<td valign="center" align="right" class="<cfoutput>#thisContentClass#</cfoutput>">
				<label for="windowContent">Content:</label>
			</td>
			<td valign="bottom" align="left" class="<cfoutput>#thisContentClass#</cfoutput>">
				<input type="text" id="<cfoutput>#selectorName#</cfoutput>" name="<cfoutput>#selectorName#</cfoutput>" onClick="setActiveContentField('cfincludePath')" />
			</td>
		  </tr>
		</cfif>
		  <cfsilent>
		  <!--- Set the class for alternating rows. --->
		  <!---After the first row, the content class should be the current class. --->
		  <cfset thisContentClass = HtmlUtilsObj.getKendoClass(thisContentClass)>
		  </cfsilent>
		  <tr height="2px">
			<td align="left" valign="bottom" colspan="2" class="border <cfoutput>#thisContentClass#</cfoutput>"></td>
		  </tr>
		  <tr valign="middle" height="30px">
			<td valign="bottom" align="left" class="<cfoutput>#thisContentClass#</cfoutput>" colspan="<cfoutput>#thisColSpan#</cfoutput>">
				Unchecking the active checkbox will remove the listener from the main blog page and disable the window. Please manually delete all of the buttons that you may have placed to launch this window.
			</td>
		  </tr>
		  <tr height="1px">
			  <td align="left" valign="top" colspan="2" class="border <cfoutput>#thisContentClass#</cfoutput>"></td>
		  </tr>
		<cfif session.isMobile>
		  <tr valign="middle">
			<td class="<cfoutput>#thisContentClass#</cfoutput>" colspan="2">
				<label for="active">Active</label>
			</td>
		   </tr>
		   <tr>
			<td class="<cfoutput>#thisContentClass#</cfoutput>" colspan="2">
				<input type="checkbox" name="active" id="active" checked>
			</td>
		  </tr>
		<cfelse><!---<cfif session.isMobile>--->
		  <tr valign="middle" height="30px">
			<td valign="bottom" align="right" class="<cfoutput>#thisContentClass#</cfoutput>" style="width:20%">
				<label for="active">Active</label>
			</td>
			<td valign="bottom" align="left" class="<cfoutput>#thisContentClass#</cfoutput>" style="width:80%">
				<input type="checkbox" name="active" id="active" checked>
			</td>
		  </tr>
		</cfif>
		  <!-- Border -->
		  <tr height="2px">
			<td align="left" valign="top" colspan="<cfoutput>#thisColSpan#</cfoutput>" class="<cfoutput>#thisContentClass#</cfoutput>"></td>
		  </tr>
		  <cfsilent>
		  <!--- Set the class for alternating rows. --->
		  <!---After the first row, the content class should be the current class. --->
		  <cfset thisContentClass = HtmlUtilsObj.getKendoClass(thisContentClass)>
		  </cfsilent>
		  <!-- Border -->
		  <tr height="2px">
			<td align="left" valign="top" colspan="<cfoutput>#thisColSpan#</cfoutput>" class="<cfoutput>#thisContentClass#</cfoutput>"></td>
		  </tr>
		  <!-- Form content -->
		  <tr valign="middle" height="30px">
			<td valign="bottom" align="right" class="<cfoutput>#thisContentClass#</cfoutput>">&nbsp;</td>
			<td valign="bottom" align="left" class="<cfoutput>#thisContentClass#</cfoutput>">
				<!--- The onPostThemeSubmit changes a dropdown in the post detail page. It does not trigger the saving of the theme. The save function is invoked using on onPostThemeSubmit js function --->
				<button id="customWindowSubmit" name="customWindowSubmit" class="k-button k-primary" type="button">Submit</button>
			</td>
		  </tr>

		</table>
		</form>
		
	</cfif>
	
</cfcase>
	
</cfswitch>	
	
</html>
