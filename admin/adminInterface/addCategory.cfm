	<!---<cfdump var="#URL#">--->
	<!--- Note: this template is used in two spots- on the post page when the category is not found when the user types a category on the dropdown, and on the category grid when the user clicks on the new category button. On the post page, the typed in category will appear along with the suggested alias. On the category grid, only the category will be shown with no alias. ---> 
	
	<cfif isDefined("URL.optArgs") and len(URL.optArgs)>
		<!--- Preset the vars --->
		<!--- Get the category from the url. --->
		<cfset category = URL.optArgs>
		<!--- Make the category alias --->
		<cfset categoryAlias = application.blog.makeAlias(URL.optArgs)>
	<cfelse>
		<cfset category = "">
		<cfset categoryAlias = "">
	</cfif>
	<!--- Get a list of category names and aliases for validation purposes --->
	<cfset categoryList = application.blog.getCategoryList('categoryList')>
	<!--- Get a list of the aliases --->
	<cfset categoryAliasList = application.blog.getCategoryList('categoryAliasList')>
		
	<script>
		
		// Create a list to validate if the category is already in use.
		var categoryList = "<cfoutput>#categoryList#</cfoutput>";
		// Do the same for the alias
		var categoryAliasList = "<cfoutput>#categoryAliasList#</cfoutput>";
		
		// !!! Note on the validators, all forms need a name attribute, otherwise the positioning of the messages will not work. --->
		$(document).ready(function() {

			var addCategoryValidator = $("#categoryForm").kendoValidator({
				// Set up custom validation rules 
				rules: {
					// The category must be unique. 
					categoryIsUnique:
					function(input){
						// Do not continue if the category is found in the category list 
						if (input.is("[id='category']") && ( listFind( categoryList, input.val() ) != 0 ) ){
							// Display an error on the page.
							input.attr("data-categoryIsUnique-msg", "Category already exists");
							// Focus on the current element
							$( "#category" ).focus();
							return false;
						}                                    
						return true;
					},
					// The alias must be unique. 
					categoryAliasIsUnique:
					function(input){
						// Do not continue if the user name is found in the currentUserName list 
						if (input.is("[id='categoryAlias']") && ( listFind( categoryAliasList, input.val() ) != 0 ) ){
							// Display an error on the page.
							input.attr("data-categoryAliasIsUnique-msg", "Category Alias already exists");
							// Focus on the current element
							$( "#categoryAlias" ).focus();
							return false;
						}                                    
						return true;
					},
				<cfif len(URL.optArgs)>
					// The alias must not contain a space. 
					categoryAliasNoSpace:
					function(input){
						// Do not continue if the user name is found in the currentUserName list 
						if (input.is("[id='categoryAlias']") && ( hasWhiteSpace(input.val()) ) ){
							// Display an error on the page.
							input.attr("data-categoryAliasNoSpace-msg", "Alias must not contain a space");
							// Focus on the current element
							$( "#categoryAlias" ).focus();
							return false;
						}                                    
						return true;
					},
					// The alias must not contain any special chars. 
					categoryAliasNoSpecialChars:
					function(input){
						// Do not continue if the user name is found in the currentUserName list 
						if (input.is("[id='categoryAlias']") && ( input.val().includes('&')||input.val().includes('?')||input.val().includes(',') ) ){
							// Display an error on the page.
							input.attr("data-categoryAliasNoSpecialChars-msg", "Alias must not contain a comma, question mark or an ampersand.");
							// Focus on the current element
							$( "#categoryAlias" ).focus();
							return false;
						}                                    
						return true;
					},
				</cfif>
				}
			}).data("kendoValidator");

			// Invoked when the submit button is clicked. Insted of using '$("form").submit(function(event) {' and 'event.preventDefault();', We are using direct binding here to speed up the event.
			var addCategorySubmit = $('#addCategorySubmit');
			addCategorySubmit.on('click', function(e){  
				
				e.preventDefault();         
				if (addCategoryValidator.validate()) {
					
					// Open up a please wait dialog
					$.when(kendo.ui.ExtWaitDialog.show({ title: "Please wait...", message: "Please wait while we process the category.", width: "<cfoutput>#application.kendoExtendedUiWindowWidth#</cfoutput>", icon: "k-ext-information" }));
					
					// Get the value of the category that was typed in
					newCategory = $("#addCategory").val();

					// Send data to server after the new role was saved into the hidden form
					setTimeout(function() {
						postNewCategory();
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
		function postNewCategory(){

			jQuery.ajax({
				type: 'post', 
				url: '<cfoutput>#application.baseUrl#</cfoutput>/common/cfc/ProxyController.cfc?method=saveCategory',
				data: { // arguments
					csrfToken: '<cfoutput>#csrfToken#</cfoutput>',
					// Pass the form values
					category: $("#category").val()<cfif len(URL.optArgs)>,
					categoryAlias: $("#categoryAlias").val()
					</cfif>
				},
				dataType: "json",
				success: saveCategoryResult, // calls the result function.
				error: function(ErrorMsg) {
					console.log('Error' + ErrorMsg);
				}
			// Extract any errors. This is a new jQuery promise based function as of jQuery 1.8.
			}).fail(function (jqXHR, textStatus, error) {
				// The full response is: jqXHR.responseText, but we just want to extract the error.
				$.when(kendo.ui.ExtAlertDialog.show({ title: "Error while consuming the saveCategory function", message: error, icon: "k-ext-error", width: "<cfoutput>#application.kendoExtendedUiWindowWidth#</cfoutput>" }) // or k-ext-error, k-ext-information, k-ext-question, k-ext-warning.  You can also specify height.
					).done(function () {
					// Do nothing
				});		
			});
		};

		function saveCategoryResult(response){ 
			
			// Close the wait window that was launched in the calling function.
			kendo.ui.ExtWaitDialog.hide();
			
			if (JSON.parse(response.success) == true){
					
				try {
					// Refresh the category grid window
					$("#categoryGridWindow").data("kendoWindow").refresh();
				} catch(e){
					// Category grid is not initialized. This is a normal condition when the category grid is not open
				}
				
				// Get the categoryId and category from the response
				var categoryId = response.categoryId;
				var category = response.category;
				
				// Add the new post category option to the multiselect. This function is on the post detail page and not on the add category page
				try {
					addNewPostCategory(categoryId, category);
				} catch(e){
					// Do nothing. This is expected on the add category window
				}
				
			} else {
				
				// Display the errors
				$.when(kendo.ui.ExtAlertDialog.show({ title: "Error saving category", message: response.errorMessage, icon: "k-ext-warning", width: "<cfoutput>#application.kendoExtendedUiWindowWidth#</cfoutput>", height: "125px" }) // or k-ext-error, k-ext-question
				).done(function () {
					// Do nothing
				});
			}//..if (JSON.parse(response.success) == true){
			
			// Close this window.
			$('#addCategoryWindow').kendoWindow('destroy');
		}
		
	</script>
		
	<form id="categoryForm" action="#" method="post" data-role="validator">
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
			Create new category. <cfif len(URL.optArgs)>The alias field is used when creating SES (Search Engine Safe) URLs. If wish to change the category alias that was recommended, do not use any non-alphanumeric characters or spaces in the alias- spaces should be replaced with dashes.</cfif>
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
			<label for="category">Category</label>
		</td>
	   </tr>
	   <tr>
		<td class="<cfoutput>#thisContentClass#</cfoutput>" colspan="2">
			<input id="category" name="category" type="text" value="<cfoutput>#category#</cfoutput>" required validationMessage="Category is required" class="k-textbox" style="width: 66%" /> 
		</td>
	  </tr>
	<cfelse><!---<cfif session.isMobile>--->
	  <tr valign="middle" height="30px">
		<td align="right" valign="middle" class="<cfoutput>#thisContentClass#</cfoutput>">
			<label for="category">Category</label>
		</td>
		<td align="left" class="<cfoutput>#thisContentClass#</cfoutput>">
			<input id="category" name="category" type="text" value="<cfoutput>#category#</cfoutput>" required validationMessage="Category is required" class="k-textbox" style="width: 66%" />  
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
				<label for="categoryAlias">Category Alias</label>
			</td>
		   </tr>
		   <tr>
			<td class="<cfoutput>#thisContentClass#</cfoutput>" colspan="2">
				<input id="categoryAlias" name="categoryAlias" type="text" value="<cfoutput>#categoryAlias#</cfoutput>" class="k-textbox" style="width: 95%" /> 
			</td>
		  </tr>
		<cfelse><!---<cfif session.isMobile>--->
	  <tr valign="middle" height="30px">
		<td align="right" valign="middle" class="<cfoutput>#thisContentClass#</cfoutput>">
			<label for="categoryAlias">Category Alias</label>
		</td>
		<td align="left" class="<cfoutput>#thisContentClass#</cfoutput>">
			<input id="categoryAlias" name="categoryAlias" type="text" value="<cfoutput>#categoryAlias#</cfoutput>" class="k-textbox" style="width: 66%" /> 
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
			<button id="addCategorySubmit" name="addCategorySubmit" class="k-button k-primary" type="button">Submit</button>
		</td>
	  </tr>
	</table>
	</form>