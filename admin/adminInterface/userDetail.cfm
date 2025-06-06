	<!---<cfdump var="#URL#">--->
	<!--- Determine if the email has been set up --->
	<cfif not len(application.BlogDbObj.getBlogEmail())>
		<p>Blog email is not set up. Please go to <b><a href="javascript:createAdminInterfaceWindow(39)">Blog Settings<a/></b> and enter the blog email.</b></p>
		<cfabort>
	</cfif>
	
	<!--- Preset params --->
	<cfparam name="userId" default="">
	<cfparam name="firstName" default="">
	<cfparam name="lastName" default="">
	<cfparam name="displayName" default="">
	<cfparam name="userName" default="">
	<cfparam name="email" default="">
	<cfparam name="displayEmailOnBio" default="false">
	<cfparam name="biography" default="">
	<cfparam name="profilePicture" default="">
	<cfparam name="webSite" default="">
	<cfparam name="linkedInUrl" default="">
	<cfparam name="facebookUrl" default="">
	<cfparam name="twitterUrl" default="">
	<cfparam name="instagramUrl" default="">
	<cfparam name="password" default="">
	<cfparam name="securityAnswer1" default="">
	<cfparam name="securityAnswer2" default="">
	<cfparam name="securityAnswer3" default="">
	<cfparam name="roles" default="">
	
	<!--- The URL.otherArgs specifies whether this is an edit, or an insert. When editing, the URL.optArgs should be the User.UserId. --->
	<!--- Get the current role for this user (if they already exist) --->
	<cfif structKeyExists(URL, "otherArgs") and URL.otherArgs eq 'addUser'>
		<cfset detailAction = "insert">
	<cfelseif structKeyExists(URL, "optArgs") and isNumeric(URL.optArgs)>
		<cfset detailAction = "update">
	<cfelse>
		<!--- The user is opening up their own profile and there is no userId present --->
		<cfset URL.optArgs = session.userId>
		<cfset detailAction = "updateProfile">
	</cfif>
	<!---<cfoutput>detailAction: #detailAction#</cfoutput>--->
		
	<!--- Get all user names for validation. We will use client side logic (and server side) to ensure that the assigned roles are unique. --->
	<cfset currentUserNameList = application.blog.getCurrentUserNameList()>
	
	<!--- Get the data for this user (if they already exist) --->
	<cfif detailAction neq 'insert'>
		
		<!--- Get and extract user information. This is an array containing one element --->
		<cfset userDetails = application.blog.getUser(userId=URL.optArgs)>
		<!---<cfdump var="#userDetails#">--->
			
		<!--- Set a variable for the userDetails query in order to test for null values --->
		<cfset userRow = userDetails[1]><!--- There is only one row in the query --->
				
		<!--- Extract the details. The values may not be present when importing the blog from BlogCfc or the previous version of GalaxieBlog for the first time --->
		<cfset userId = URL.optArgs>
		<cfset userName = userDetails[1]["UserName"]>
		<cfset firstName = userDetails[1]["FirstName"]>
		<cfset lastName = userDetails[1]["LastName"]>
		<cfset displayName = userDetails[1]["DisplayName"]>
		<cfset email = userDetails[1]["Email"]>
		<cfset displayEmailOnBio = userDetails[1]["DisplayEmailOnBio"]>
		<cfset password = userDetails[1]["Password"]>
		<!--- The following variables may be null in the HQL array. --->
		<cfif structKeyExists(userRow, "Website")>
			<cfset website = userDetails[1]["Website"]>
		</cfif>
		<cfif structKeyExists(userRow, "Biography")>
			<cfset biography = userDetails[1]["Biography"]>
		</cfif>
		<cfif structKeyExists(userRow, "ProfilePicture")>
			<cfset profilePicture = userDetails[1]["ProfilePicture"]>
		</cfif>
		<!--- Social links --->
		<cfif structKeyExists(userRow, "LinkedInUrl")>
			<cfset linkedInUrl = userDetails[1]["LinkedInUrl"]>
		</cfif>
		<cfif structKeyExists(userRow, "FacebookUrl")>
			<cfset facebookUrl = userDetails[1]["FacebookUrl"]>
		</cfif>
		<cfif structKeyExists(userRow, "TwitterUrl")>
			<cfset twitterUrl = userDetails[1]["TwitterUrl"]>
		</cfif>
		<cfif structKeyExists(userRow, "InstagramUrl")>
			<cfset instagramUrl = userDetails[1]["InstagramUrl"]>
		</cfif>
		<!--- These should always be filled out --->
		<cfset securityAnswer1 = userDetails[1]["SecurityAnswer1"]>
		<cfset securityAnswer2 = userDetails[1]["SecurityAnswer2"]>
		<cfset securityAnswer3 = userDetails[1]["SecurityAnswer3"]>
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
			
		<!---********************* Generic image upload editor *********************--->
		<!--- Set the common vars for tinymce. ---> 
		<cfsilent>
		<cfset selectorId = "userBioEditor">
		<cfif session.isMobile>
			<cfset editorHeight = "325">
		<cfelse>
			<cfset editorHeight = "425">
		</cfif>
		<!--- This string is used by the tiny mce editor to handle image uploads --->
		<cfset imageHandlerUrl = application.baseUrl & "/common/cfc/ProxyController.cfc?method=uploadImage&mediaProcessType=userBio&mediaType=image&selectorId=" & selectorId & "&userId=" & URL.optArgs & "&csrfToken=" & csrfToken> 
		<cfset contentVar = biography>
		<cfset imageMediaIdField = "mediaId">
		<cfset imageClass = "entryImage">

		<cfset toolbarString = "undo redo | image editimage">
		<!--- Do not include maps or videos. These are not needed here --->
		<cfset includeMaps = false>
		<cfset disableVideoCoverAndWebVttButtons = true>
		<!--- We want to include common CSS --->
		<cfset includeCommonCss = true>

		</cfsilent>
		<!--- Include the tinymce js template --->
		<cfinclude template="#application.baseUrl#/includes/templates/js/tinyMce.cfm">
			
	</cfif><!---<cfif detailAction eq 'update' or detailAction eq 'updateProfile'>--->
			
	<!-- Collapsable style -->
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
	
	<!-- Collapsable script -->
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
			
	<!--- Note: roles are not displayed when updating a profile --->
	<script>
	<cfif detailAction eq 'update'>
	
		// ---------------------------- role dropdown. ----------------------------
		var roleDs = new kendo.data.DataSource({
			transport: {
				read: {
					cache: false,
					type: "GET", //Note: for large payloads coming from the server, use the get method. The post method may fail as it is less efficient.
					// Note: since this template is in a different directory, we can't specify the cfc template without the full path name.
					url: function() { // The cfc component which processes the query and returns a json string. 
						return "<cfoutput>#application.baseUrl#</cfoutput>/common/cfc/ProxyController.cfc?method=getRolesForDropdown&csrfToken=<cfoutput>#csrfToken#</cfoutput>"; 
					}, 
					dataType: "json",
					contentType: "application/json; charset=utf-8" // Note: when posting json via the request body to a coldfusion page, we must use this content type or we will get a 'IllegalArgumentException' on the ColdFusion processing page.
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
	</cfif><!---<cfif isDefined("currentUserRoleId")>--->

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
				setTimeout(function() {
					// Populate it...
					populateCapabilityDropdown();
				}, 250);
			}
		}//...function onRolechange(e)
		
		// Populate the capabilities from the datasource
		function populateCapabilityDropdown(){
			// Clear the previous value
			capabilityDropdown.value([]);
			// Clear any applied filters
			capabilityDropdown.dataSource.filter({});
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
				
				// Set the values in the multiselect after a timeout (1000ms)
				if (capabilityIdList.length > 0){
					// Get a reference to the dropdown. We will use this in the loop below to set its items.
					var capabilityDropdown = $("#capabilityDropdown").data("kendoMultiSelect");

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
			dataSource: capabilityDs,
			schema: {
				data: function (data) { //return the datasource array that contains the data
					return data.fullList;
				}
			}
		}).data("kendoMultiSelect");
	
		// Populate the control with the current values determined by the users role
		capabilityDropdown.dataSource.data([{
		<cfloop from="1" to="#arrayLen(currentUserCapabilityObject)#" index="i"><cfoutput>
		  CapabilityUiLabel: "#currentUserCapabilityObject[i]['CapabilityName']#", CapabilityId: #currentUserCapabilityObject[i]['CapabilityId']#
		<cfif i lt arrayLen(currentUserCapabilityObject)>}, {</cfif>
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
					// If the password is being updated, ask the user to confirm the password again
					if ( $("#updatePassword").val() == 1) {
						// This interface will not let you pass until the passwords match
						createAdminInterfaceWindow(9, '<cfoutput>#detailAction#</cfoutput>');	  
					} else {//..if (userDetailValidator.validate()) 		  }
					<cfif detailAction eq 'updateProfile'><!--- Roles are not used when updating the profile --->
						// Open up a please wait dialog
						$.when(kendo.ui.ExtWaitDialog.show({ title: "Please wait...", message: "Please wait while we process the user.", icon: "k-ext-information" }));
						// Post the data to the server
						setTimeout(function() {
							postUserDetails('updateProfile');
						}, 250);
					<cfelseif detailAction eq 'update'><!---<cfif detailAction eq 'updateProfile'>--->
						// Determine if there this is a new role and proceed.
						checkForNewRole();
					</cfif><!---<cfif detailAction eq 'updateProfile'>--->
					}//...if ( $("#updatePassword").val() == 1) {
								  
				} else {//...if (userDetailValidator.validate()) {

					$.when(kendo.ui.ExtAlertDialog.show({ title: "There are errors", message: "Please correct the highlighted fields and try again", width: "<cfoutput>#application.kendoExtendedUiWindowWidth#</cfoutput>", icon: "k-ext-warning" }) // or k-ext-error, k-ext-question
						).done(function () {
						// Do nothing
					});
				}//..if (userDetailValidator.validate()) {
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
					postUserDetails('update');
				}, 250);
								  
			} else {
				// Open the new role interface
				createAdminInterfaceWindow(8);
			}					  
		}

		// Post method on the detail form called from the deptDetailFormValidator method on the detail page. The action variable will either be 'update' or 'insert'.
		function postUserDetails(action){
		<cfif detailAction eq 'update'>
			// Administrators may update user roles
			// Convert the capability multiselect into a comma delimited string.
			var capabilityDropdown = $("#capabilityDropdown").data("kendoMultiSelect").value();
		</cfif><!---<cfif detailAction eq 'update'>--->
			// The biography is only available when updating a user or profile
		<cfif detailAction neq 'insert'>
			// Get the biography from the tinymce editor
			var biographyContent = tinymce.get("<cfoutput>#selectorName#</cfoutput>").getContent();
		</cfif><!---<cfif detailAction neq 'insert'>--->
								  
			jQuery.ajax({
				type: 'post', 
				url: '<cfoutput>#application.baseUrl#</cfoutput>/common/cfc/ProxyController.cfc?method=saveUser',
				data: { // arguments
					// We are going to map the extact same arguments, in order, of the method in the cfc here. Notes: we can also use 'data: $("#userDetails").serialize()' or use the stringify method to pass it as an array of values. 
					csrfToken: '<cfoutput>#csrfToken#</cfoutput>',
					action: action, // either update, updateProfile or insert.
					firstName: $("#firstName").val(),
					lastName: $("#lastName").val(),
					displayName: $("#displayName").val(),
					email: $("#email").val(),
					website: $("#webSite").val(),
				<cfif detailAction neq 'insert'>
					<!--- These are not needed when adding a new user --->
					displayEmail: $("#displayEmail").is(":checked"),
					profilePicture: $("#profilePicture").val(),
					biography: biographyContent,
					facebookUrl: $("#facebookUrl").val(),
					linkedInUrl: $("#linkedInUrl").val(),
					instagramUrl: $("#instagramUrl").val(),
					twitterUrl: $("#twitterUrl").val(),	
					securityAnswer1: $("#securityAnswer1").val(),
					securityAnswer2: $("#securityAnswer2").val(),
					securityAnswer3: $("#securityAnswer3").val(),	
				</cfif><!---<cfif detailAction neq 'insert'>--->
				// The notify checkbox is not present unless the admin is different than the logged in user. We don't need to notify ourselves if we took this action
				<cfif userName neq session.userName>
					notify: $('#notify').is(':checked'),
				<cfelse>
					notify: false,
				</cfif>
					userName: $("#userName").val(),
					password: $("#password").val(),
				// Admins can update the groups
				<cfif detailAction eq 'update'>
					// The value of the dropdown is the Id
					roleId: $("#roleDropdown").data("kendoDropDownList").value(), 
					// The new role and desc will be sent after the user types in the new role when the default capabilities have been changed.
					newRole: $("#newRole").val(),
					newRoleDesc: $("#newRoleDesc").val(),
					capabilities: capabilityDropdown.toString()
				</cfif><!---<cfif detailAction eq 'update'>--->
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
			
						// Change the updatePassword text field with a 1 to indicate that the password is being updated. This will be used to prompt the user to confirm the new password once the form is submitted
						$("#updatePassword").val(1); 
						// Clear the password input
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
			if (JSON.parse(response.success) == true){
				// Refresh the user grid. This may not be present to put it in a try block
				try {
					$("#userGridWindow").data("kendoWindow").refresh();
				} catch(e){
					// Do nothing
				}
				// Close the wait window that was launched in the calling function.
				kendo.ui.ExtWaitDialog.hide();
				// Close this interface.
				$('#userDetailWindow').kendoWindow('destroy');
				
			} else {
				
				// Close the please wait dialog
				kendo.ui.ExtWaitDialog.hide();
				// Display the errors
				$.when(kendo.ui.ExtAlertDialog.show({ title: "Error saving user", message: response.errorMessage, icon: "k-ext-warning", width: "<cfoutput>#application.kendoExtendedUiWindowWidth#</cfoutput>", height: "325px" }) // or k-ext-error, k-ext-question
				).done(function () {
					// Do nothing
				});
			}//..if (JSON.parse(response.success) == true){
			
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
			<input id="password" name="password" type="password" value="<cfoutput>#password#</cfoutput>" required validationMessage="Password is required" autocomplete="new-password" class="k-textbox" style="width: 66%" <cfif detailAction neq 'insert'>onClick="showPasswordNote()"</cfif>
		</td>
	  </tr>
	  <tr>
		<td></td>
		<td colspan="2">Note: the blog does not store the password other than in encrypted form. The actual password can't be retrieved and is not stored.</td>
	  </tr>
	<cfelse><!---<cfif session.isMobile>--->
	  <tr valign="middle" height="30px">
		<td align="right" valign="middle" class="<cfoutput>#thisContentClass#</cfoutput>">
			<label for="password"><cfif detailAction neq 'insert'>Encrypted Password<cfelse>Password</cfif></label>
		</td>
		<td align="left" class="<cfoutput>#thisContentClass#</cfoutput>">
			<!--- Create a hidden form to flag that a password is being changed. This will be used to launch a confirm password window. --->
			<input type="hidden" name="updatePassword" id="updatePassword" value="0"/>
			<input id="password" name="password" type="password" value="<cfoutput>#password#</cfoutput>" required validationMessage="Password is required" autocomplete="new-password" class="k-textbox" style="width: 33%" <cfif detailAction neq 'insert'>onClick="showPasswordNote()"</cfif> />
		</td>
	  </tr>
	  <tr>
		<td class="<cfoutput>#thisContentClass#</cfoutput>"></td>
		<td class="<cfoutput>#thisContentClass#</cfoutput>">Note: the blog does not store the password other than in encrypted form. The actual password can't be retrieved and is not stored.</td>
	  </tr>
	</cfif><!---<cfif session.isMobile>--->
		
	<!--- There is no need to notify the user if you're editing your own user details --->
	<cfif detailAction eq 'insert'>
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
	 </cfif><!---<cfif session.isMobile>--->
	</cfif><!---<cfif detailAction eq 'insert'>--->
		  
	<cfif detailAction neq 'insert'>	
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
			<label for="displayEmail">Display Email?</label>
		</td>
	   </tr>
	   <tr>
		<td class="<cfoutput>#thisContentClass#</cfoutput>" colspan="2">
			<input type="checkbox" id="displayEmail" name="displayEmail" <cfif displayEmailOnBio>checked</cfif>/>
		</td>
	  </tr>
	<cfelse><!---<cfif session.isMobile>--->
	  <tr valign="middle" height="30px">
		<td align="right" valign="middle" class="<cfoutput>#thisContentClass#</cfoutput>">
			<label for="displayEmail">Display Email?</label>
		</td>
		<td align="left" class="<cfoutput>#thisContentClass#</cfoutput>">
			<input type="checkbox" id="displayEmail" name="displayEmail" <cfif displayEmailOnBio>checked</cfif>/>
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
	</table>	
	<!---//***********************************************************************************************
						Profile Picture and Biography
	//************************************************************************************************--->
	<button type="button" class="collapsible k-header">Profile Picture and Biography</button>
	<div class="content k-content">
	<table align="center" class="k-content" width="100%" cellpadding="2" cellspacing="0">
		  
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
			<label for="profilePicture">Profile Picture:</label>
		</td>
	   </tr>
	   <tr>
		<td class="<cfoutput>#thisContentClass#</cfoutput>" colspan="2">
			<cfoutput>
			<input type="text" id="profilePicture" name="profilePicture" value="#profilePicture#" class="k-textbox" style="width:95%" onclick="createAdminInterfaceWindow(35, #userId#,'profilePicture','#profilePicture#');">
			</cfoutput>
		</td>
	  </tr>
	<cfelse><!---<cfif session.isMobile>--->
	  <tr valign="middle" height="30px">
		<td align="right" valign="middle" class="<cfoutput>#thisContentClass#</cfoutput>">
			<label for="profilePicture">Profile Picture:</label>
		</td>
		<td align="left" width="85%" class="<cfoutput>#thisContentClass#</cfoutput>">
			<cfoutput>
			<input type="text" id="profilePicture" name="profilePicture" value="#profilePicture#" class="k-textbox" style="width:95%" onclick="createAdminInterfaceWindow(35, #userId#,'profilePicture','#profilePicture#');">
			</cfoutput>
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
		  
	<!-- ****************************************** TinyMce Editor ****************************************** -->
	<cfif smallScreen>
	   <tr>
		<td class="<cfoutput>#thisContentClass#</cfoutput>" colspan="2">
			Note: the user biography is optional. If it is filled out, the biography will be displayed at the end of the posts that this author has made.
		</td>
	  </tr>
	   <tr>
		<td class="<cfoutput>#thisContentClass#</cfoutput>" colspan="2">
			<label for="<cfoutput>#selectorName#</cfoutput>">User Biography</label>   
		</td>
	  </tr>
	  <tr>
		<td class="<cfoutput>#thisContentClass#</cfoutput>" colspan="2">
			<input type="text" id="<cfoutput>#selectorName#</cfoutput>" name="<cfoutput>#selectorName#</cfoutput>" />
		</td>
	  </tr>
	<cfelse><!---<cfif smallScreen>--->
	  <tr>
		<td class="<cfoutput>#thisContentClass#</cfoutput>"></td>
		<td class="<cfoutput>#thisContentClass#</cfoutput>">
			Note: the user biography is optional. If it is filled out, the biography will be displayed at the end of the posts that this author has made.
		</td>
	  </tr>
	  <tr>
		<td align="right" class="<cfoutput>#thisContentClass#</cfoutput>"><div id="dynamicGalleryLabel"></div></td>
		<td class="<cfoutput>#thisContentClass#</cfoutput>"></td>
	  </tr>
	  <tr valign="middle">
		<td align="right" valign="middle" height="35" class="<cfoutput>#thisContentClass#</cfoutput>">
		<label for="<cfoutput>#selectorName#</cfoutput>">User Biography</label>
		</td>
		<td align="left" class="<cfoutput>#thisContentClass#</cfoutput>"> 
		<input type="text" id="<cfoutput>#selectorName#</cfoutput>" name="<cfoutput>#selectorName#</cfoutput>" />   
		</td>
	  </tr>
	</cfif><!---<cfif smallScreen>--->
	</table>
	</div>

	<!---//***********************************************************************************************
						Social Media Links
	//************************************************************************************************--->
	<button type="button" class="collapsible k-header">Social Media Links</button>
	<div class="content k-content">
	<table align="center" class="k-content" width="100%" cellpadding="2" cellspacing="0">
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
			<label for="facebookUrl">Facebook URL</label>
		</td>
	   </tr>
	   <tr>
		<td class="<cfoutput>#thisContentClass#</cfoutput>" colspan="2">
			<input type="text" id="facebookUrl" name="facebookUrl" value="<cfoutput>#facebookUrl#</cfoutput>" class="k-textbox" style="width:75%"/>
		</td>
	  </tr>
	<cfelse><!---<cfif session.isMobile>--->
	  <tr valign="middle" height="30px">
		<td align="right" valign="middle" class="<cfoutput>#thisContentClass#</cfoutput>">
			<label for="facebookUrl">Facebook URL</label>
		</td>
		<td align="left" width="85%" class="<cfoutput>#thisContentClass#</cfoutput>">
			<input type="text" id="facebookUrl" name="facebookUrl" value="<cfoutput>#facebookUrl#</cfoutput>" class="k-textbox" style="width:75%"/>
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
			<label for="linkedInUrl">LinkedIn URL</label>
		</td>
	   </tr>
	   <tr>
		<td class="<cfoutput>#thisContentClass#</cfoutput>" colspan="2">
			<input type="text" id="linkedInUrl" name="linkedInUrl" value="<cfoutput>#linkedInUrl#</cfoutput>" class="k-textbox" style="width:75%"/>
		</td>
	  </tr>
	<cfelse><!---<cfif session.isMobile>--->
	  <tr valign="middle" height="30px">
		<td align="right" valign="middle" class="<cfoutput>#thisContentClass#</cfoutput>">
			<label for="linkedInUrl">LinkedIn URL</label>
		</td>
		<td align="left" class="<cfoutput>#thisContentClass#</cfoutput>">
			<input type="text" id="linkedInUrl" name="linkedInUrl" value="<cfoutput>#linkedInUrl#</cfoutput>" class="k-textbox" style="width:75%"/>
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
			<label for="instagramUrl">Instagram URL</label>
		</td>
	   </tr>
	   <tr>
		<td class="<cfoutput>#thisContentClass#</cfoutput>" colspan="2">
			<input type="text" id="instagramUrl" name="instagramUrl" value="<cfoutput>#instagramUrl#</cfoutput>" class="k-textbox" style="width:75%"/>
		</td>
	  </tr>
	<cfelse><!---<cfif session.isMobile>--->
	  <tr valign="middle" height="30px">
		<td align="right" valign="middle" class="<cfoutput>#thisContentClass#</cfoutput>">
			<label for="instagramUrl">Instagram URL</label>
		</td>
		<td align="left" class="<cfoutput>#thisContentClass#</cfoutput>">
			<input type="text" id="instagramUrl" name="instagramUrl" value="<cfoutput>#instagramUrl#</cfoutput>" class="k-textbox" style="width:75%"/>
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
			<label for="twitterUrl">Twitter URL</label>
		</td>
	   </tr>
	   <tr>
		<td class="<cfoutput>#thisContentClass#</cfoutput>" colspan="2">
			<input type="text" id="twitterUrl" name="twitterUrl" value="<cfoutput>#twitterUrl#</cfoutput>" class="k-textbox" style="width:75%"/>
		</td>
	  </tr>
	<cfelse><!---<cfif session.isMobile>--->
	  <tr valign="middle" height="30px">
		<td align="right" valign="middle" class="<cfoutput>#thisContentClass#</cfoutput>">
			<label for="twitterUrl">Twitter URL</label>
		</td>
		<td align="left" class="<cfoutput>#thisContentClass#</cfoutput>">
			<input type="text" id="twitterUrl" name="twitterUrl" value="<cfoutput>#twitterUrl#</cfoutput>" class="k-textbox" style="width:75%"/>
		</td>
	  </tr>
	</cfif><!---<cfif session.isMobile>--->
	
  </cfif><!---<cfif detailAction neq 'insert'>--->	
		  
	</table>
	</div>

	<!---//***********************************************************************************************
						Security Questions
	//************************************************************************************************--->
	<button type="button" class="collapsible k-header">Security Questions</button>
	<div class="content k-content">
	<table align="center" class="k-content" width="100%" cellpadding="2" cellspacing="0">
		
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
		<td align="right" valign="middle" class="<cfoutput>#thisContentClass#</cfoutput>">
			<label for="securityAnswer1">What is the name of your favorite pet?</label>
		</td>
		<td align="left" width="85%" class="<cfoutput>#thisContentClass#</cfoutput>" height="30px">
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
	</div>
	<cfif detailAction eq 'update'>	
	<!---//***********************************************************************************************
						Roles
	//************************************************************************************************--->
	<button type="button" class="collapsible k-header">Roles</button>
	<div class="content k-content">
	<table align="center" class="k-content" width="100%" cellpadding="2" cellspacing="0">
	  <!-- Border -->
	  <tr height="2px">
		  <td align="left" valign="top" colspan="<cfoutput>#thisColSpan#</cfoutput>" class="<cfoutput>#thisContentClass#</cfoutput>"></td>
	  </tr>
	<!--- Roles --->
	
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
		<td align="left" width="85%" class="<cfoutput>#thisContentClass#</cfoutput>">
			<select id="roleDropdown" name="roleDropdown" required validationMessage="Role is required" style="width: 45%; font-weight: 300;"></select>   
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
	</cfif><!---<cfif session.isMobile>--->
	</table>
	</div>
	</cfif><!---<cfif detailAction eq 'update'>--->	
	<!---//***********************************************************************************************
						User Logs
	//************************************************************************************************--->
   <!--- User log in history --->
   <cfif isDefined("currentUserRole") gt 0 and (userName eq session.userName or currentUserRole eq 'Administrator')>
	<button type="button" class="collapsible k-header">User Logs</button>
	<div class="content k-content">
	<table align="center" class="k-content" width="100%" cellpadding="2" cellspacing="0">
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
		<td valign="bottom" align="left" width="85%" class="<cfoutput>#thisContentClass#</cfoutput>">
			<button id="logonHistory" class="k-button normalFontWeight" type="button" style="width: 175px" onClick="javascript:createAdminInterfaceWindow(10, '<cfoutput>#userName#</cfoutput>');">Login History</button>
		</td>
	  </tr>
	</cfif><!---<cfif session.isMobile>--->
	</table>
	</div>
   </cfif><!---<cfif isDefined("currentUserRole") gt 0 and (userName eq session.userName or currentUserRole eq 'Administrator')>--->
	
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
			<br/><br/><button id="userDetailSubmit" name="userDetailSubmit" class="k-button k-primary" type="button">Submit</button>
		</td>
	  </tr>
	</table>
	</form>