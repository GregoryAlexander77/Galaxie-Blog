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
			author.value(<cfoutput>#session.userId#</cfoutput>);
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