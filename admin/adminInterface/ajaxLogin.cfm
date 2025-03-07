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