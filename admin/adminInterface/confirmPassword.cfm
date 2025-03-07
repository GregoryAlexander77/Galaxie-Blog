	<!--- OptArgs is the detailAction --->
	
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
					// Send data to server
					// Open up a please wait dialog
					$.when(kendo.ui.ExtWaitDialog.show({ title: "Please wait...", message: "Please wait while we process the user.", width: "<cfoutput>#application.kendoExtendedUiWindowWidth#</cfoutput>", icon: "k-ext-information" }));
					// Post the data to the server
					setTimeout(function() {
						postUserDetails('<cfoutput>#URL.optArgs#</cfoutput>');
						// Close the interface.
						setTimeout(function() {
							$('#confirmPasswordWindow').kendoWindow('destroy');
						}, 250);
					}, 250);
					
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
			<input id="confirmPassword" name="confirmPassword" type="password" value="" class="k-textbox" required validationMessage="Password is required" autocomplete="new-password" style="width: 95%" />   
		</td>
	  </tr>
	<cfelse><!---<cfif session.isMobile>--->
	  <tr height="30px">
		<td align="right" width="25%" class="<cfoutput>#thisContentClass#</cfoutput>"> 
			<label for="confirmPassword">Confirm Password</label>
		</td>
		<td width="75%" class="<cfoutput>#thisContentClass#</cfoutput>">
			<input id="confirmPassword" name="confirmPassword" type="password" value="" class="k-textbox" required validationMessage="Password is required" autocomplete="new-password" style="width: 33%" />    
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