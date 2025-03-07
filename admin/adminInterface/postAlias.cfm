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