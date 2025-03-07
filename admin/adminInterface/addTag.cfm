	<!--- Note: this template is used in two spots- on the post page when the category is not found when the user types ina tag on the dropdown, and on the tag grid when the user clicks on the new tag button. On the post page, the typed in tag will appear along with the suggested alias. On the tag grid, only the tag will be shown with no alias. ---> 
	
	<cfif isDefined("URL.optArgs") and len(URL.optArgs)>
		<!--- Preset the vars --->
		<!--- Get the category from the url. --->
		<cfset tag = URL.optArgs>
		<!--- Make the category alias --->
		<cfset tagAlias = application.blog.makeAlias(URL.optArgs)>
	<cfelse>
		<cfset tag = "">
		<cfset tagAlias = "">
	</cfif>
	<!--- Get a list of tag names and aliases for validation purposes --->
	<cfset tagList = application.blog.getTagList('tagList')>
	<!--- And get a list of the aliases --->
	<cfset tagAliasList = application.blog.getTagList('tagAliasList')>
		
	<script>
		
		// Create a list to validate if the tag is already in use.
		var tagList = "<cfoutput>#tagList#</cfoutput>";
		// Do the same for the alias
		var tagAliasList = "<cfoutput>#tagAliasList#</cfoutput>";
		
		// !!! Note on the validators, all forms need a name attribute, otherwise the positioning of the messages will not work. --->
		$(document).ready(function() {

			var addTagValidator = $("#tagForm").kendoValidator({
				// Set up custom validation rules 
				rules: {
					// The tag must be unique. 
					tagIsUnique:
					function(input){
						// Do not continue if the user name is found in the currentUserName list 
						if (input.is("[id='tag']") && ( listFind( tagList, input.val() ) != 0 ) ){
							// Display an error on the page.
							input.attr("data-tagIsUnique-msg", "Tag already exists");
							// Focus on the current element
							$( "#tag" ).focus();
							return false;
						}                                    
						return true;
					},
					// The alias must be unique. 
					tagAliasIsUnique:
					function(input){
						// Do not continue if the user name is found in the currentUserName list 
						if (input.is("[id='tagAlias']") && ( listFind( tagAliasList, input.val() ) != 0 ) ){
							// Display an error on the page.
							input.attr("data-tagAliasIsUnique-msg", "Tag Alias already exists");
							// Focus on the current element
							$( "#tagAlias" ).focus();
							return false;
						}                                    
						return true;
					},
				<cfif len(URL.optArgs)>
					// The alias must not contain a space. 
					tagAliasNoSpace:
					function(input){
						// Do not continue if the user name is found in the currentUserName list 
						if (input.is("[id='tagAlias']") && ( hasWhiteSpace(input.val()) ) ){
							// Display an error on the page.
							input.attr("data-tagAliasNoSpace-msg", "Alias must not contain a space");
							// Focus on the current element
							$( "#tagAlias" ).focus();
							return false;
						}                                    
						return true;
					},
					// The alias must not contain any special chars. 
					tagAliasNoSpecialChars:
					function(input){
						// Do not continue if the user name is found in the currentUserName list 
						if (input.is("[id='tagAlias']") && ( input.val().includes('&')||input.val().includes('?')||input.val().includes(',') ) ){
							// Display an error on the page.
							input.attr("data-tagAliasNoSpecialChars-msg", "Alias must not contain a comma, question mark or an ampersand.");
							// Focus on the current element
							$( "#tagAlias" ).focus();
							return false;
						}                                    
						return true;
					},
				</cfif>
				}
			}).data("kendoValidator");

			// Invoked when the submit button is clicked. Insted of using '$("form").submit(function(event) {' and 'event.preventDefault();', We are using direct binding here to speed up the event.
			var addTagSubmit = $('#addTagSubmit');
			addTagSubmit.on('click', function(e){  
				
				e.preventDefault();         
				if (addTagValidator.validate()) {
					
					// Open up a please wait dialog
					$.when(kendo.ui.ExtWaitDialog.show({ title: "Please wait...", message: "Please wait while we process the tag.", width: "<cfoutput>#application.kendoExtendedUiWindowWidth#</cfoutput>", icon: "k-ext-information" }));
					
					// Get the value of the tag that was typed in
					newTag = $("#addTag").val();

					// Send data to server after the new role was saved into the hidden form
					setTimeout(function() {
						postNewtag();
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
		function postNewtag(){

			jQuery.ajax({
				type: 'post', 
				url: '<cfoutput>#application.baseUrl#</cfoutput>/common/cfc/ProxyController.cfc?method=savetag',
				data: { // arguments
					csrfToken: '<cfoutput>#csrfToken#</cfoutput>',
					// Pass the form values
					tag: $("#tag").val()<cfif len(URL.optArgs)>,
					tagAlias: $("#tagAlias").val()
					</cfif>
				},
				dataType: "json",
				success: saveTagResult, // calls the result function.
				error: function(ErrorMsg) {
					console.log('Error' + ErrorMsg);
				}
			// Extract any errors. This is a new jQuery promise based function as of jQuery 1.8.
			}).fail(function (jqXHR, textStatus, error) {
				// The full response is: jqXHR.responseText, but we just want to extract the error.
				$.when(kendo.ui.ExtAlertDialog.show({ title: "Error while consuming the savetag function", message: error, icon: "k-ext-error", width: "<cfoutput>#application.kendoExtendedUiWindowWidth#</cfoutput>" }) // or k-ext-error, k-ext-information, k-ext-question, k-ext-warning.  You can also specify height.
					).done(function () {
					// Do nothing
				});		
			});
		};

		function saveTagResult(response){ 
			if (JSON.parse(response.success) == true){
				
				// Close the wait window that was launched in the calling function.
				kendo.ui.ExtWaitDialog.hide();
				
				try {
					// Refresh the tag grid window
					$("#tagGridWindow").data("kendoWindow").refresh();
				} catch(e){
					// tag window is not initialized. This is a normal condition when the tag grid is not open
				}
				
				// Get the tagId and tag from the response
				var tagId = response.tagId;
				var tag = response.tag;
				
				// Add the new post tag option to the multiselect when the post detail page is invoking this interface. This function is on the post detail page. It is in a try block as it is also used on the tag interface where this function is not available.
				try {
					addNewPostTag(tagId, tag);
				} catch (error) {
					// do nothing
				}

			} else {
				
				// Display the errors
				$.when(kendo.ui.ExtAlertDialog.show({ title: "Error saving tag", message: response.errorMessage, icon: "k-ext-warning", width: "<cfoutput>#application.kendoExtendedUiWindowWidth#</cfoutput>", height: "125px" }) // or k-ext-error, k-ext-question
				).done(function () {
					// Do nothing
				});
			}//..if (JSON.parse(response.success) == true){
			
			// Close this window.
			$('#addTagWindow').kendoWindow('destroy');
		}
		
	</script>
		
	<form id="tagForm" action="#" method="post" data-role="validator">
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
			Create new tag. The alias field is used when creating SES (Search Engine Safe) URLs. If wish to change the alias that was recommended, do not use any non-alphanumeric characters or spaces in the alias- spaces should be replaced with dashes.
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
			<label for="tag">tag</label>
		</td>
	   </tr>
	   <tr>
		<td class="<cfoutput>#thisContentClass#</cfoutput>" colspan="2">
			<input id="tag" name="tag" type="text" value="<cfoutput>#tag#</cfoutput>" required validationMessage="Tag is required" class="k-textbox" style="width: 66%" /> 
		</td>
	  </tr>
	<cfelse><!---<cfif session.isMobile>--->
	  <tr valign="middle" height="30px">
		<td align="right" valign="middle" class="<cfoutput>#thisContentClass#</cfoutput>">
			<label for="tage">Tag</label>
		</td>
		<td align="left" class="<cfoutput>#thisContentClass#</cfoutput>">
			<input id="tag" name="tag" type="text" value="<cfoutput>#tag#</cfoutput>" required validationMessage="Tag is required" class="k-textbox" style="width: 66%" />  
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
				<label for="tagAlias">Tag Alias</label>
			</td>
		   </tr>
		   <tr>
			<td class="<cfoutput>#thisContentClass#</cfoutput>" colspan="2">
				<input id="tagAlias" name="tagAlias" type="text" value="<cfoutput>#tagAlias#</cfoutput>" class="k-textbox" style="width: 95%" /> 
			</td>
		  </tr>
		<cfelse><!---<cfif session.isMobile>--->
	  <tr valign="middle" height="30px">
		<td align="right" valign="middle" class="<cfoutput>#thisContentClass#</cfoutput>">
			<label for="tagAlias">Tag Alias</label>
		</td>
		<td align="left" class="<cfoutput>#thisContentClass#</cfoutput>">
			<input id="tagAlias" name="tagAlias" type="text" value="<cfoutput>#tagAlias#</cfoutput>" class="k-textbox" style="width: 66%" /> 
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
			<button id="addTagSubmit" name="addTagSubmit" class="k-button k-primary" type="button">Submit</button>
		</td>
	  </tr>
	</table>
	</form>