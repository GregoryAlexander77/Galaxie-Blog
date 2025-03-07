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
	
	<cfparam name="detailAction" default="newProfile">
	
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
						
						// If the password is being updated, ask the user to confirm the password again
						if ( $("#updatePassword").val() == 1) {
							// This interface will not let you pass until the passwords match
							createAdminInterfaceWindow(9, 'confirmPassword');	
							// This function will send data to the server if the passwords match
						} else {
							
							// Send data to server
							// Open up a please wait dialog
							$.when(kendo.ui.ExtWaitDialog.show({ title: "Please wait...", message: "Please wait while we process the user.", width: "<cfoutput>#application.kendoExtendedUiWindowWidth#</cfoutput>", icon: "k-ext-information" }));
							// Post the data to the server
							setTimeout(function() {
								postUserDetails('newProfile');
							}, 250);
							
						}

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
						action: 'updateProfile', // either insert, newProfile, update, or updateProfile.
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
				<!--- Hidden input to determine if the password is being changed. This is used to pop up a confirm password interface when the password is being changed --->
				<input type="text" name="updatePassword" id="updatePassword" value="0"/>
				<input type="password" id="profilePassword" name="profilePassword" value="<cfoutput>#password#</cfoutput>" required validationMessage="Password is required" autocomplete="new-password" class="k-textbox" style="width: 95%" onClick="showPasswordNote()"/> 
			</td>
		  </tr>
		<cfelse><!---<cfif session.isMobile>--->
		  <tr valign="middle" height="30px">
			<td align="right" valign="middle" class="<cfoutput>#thisContentClass#</cfoutput>">
				<label for="profilePassword">Password</label>
			</td>
			<td align="left" class="<cfoutput>#thisContentClass#</cfoutput>">
				<!--- Hidden input to determine if the password is being changed. This is used to pop up a confirm password interface when the password is being changed --->
				<input type="text" name="updatePassword" id="updatePassword" value="0"/>
				<input type="password" id="profilePassword" name="profilePassword" value="<cfoutput>#password#</cfoutput>" required validationMessage="Password is required" autocomplete="new-password" class="k-textbox" style="width: 33%" onClick="showPasswordNote()/> 
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