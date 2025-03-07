	<!--- Get the comment --->
	<cfset getComment = application.blog.getComment(URL.optArgs)>
	<!---<cfdump var="#getComment#">--->		
	
	<!---********************* Comment Detail editor *********************--->
	<!--- Set the common vars for tinymce. --->
	<cfsilent>
	<!---	We are using a new identifier every time in order to get the editors to work (see notes in other areas) and we are using cookies to store the last selector name and to eliminate stale editors and clean up the editor list --->
	<cfset selectorId = "commentEditor">
	<cfset editorHeight = "300">
	<!--- This string is used by the tiny mce editor to handle image uploads --->
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