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