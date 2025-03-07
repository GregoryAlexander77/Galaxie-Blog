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