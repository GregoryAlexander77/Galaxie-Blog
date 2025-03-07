	<cfsilent>
		<!--- Get all themes for validation. We will use client side logic (and server side) to ensure that the new theme is unique. --->
		<cfset themeList = application.blog.getThemeList()>
	</cfsilent>
	<script>
		
		var themeList = <cfoutput>'#lCase(themeList)#'</cfoutput>;
		
		$(document).ready(function() {
		
			// ---------------------------- theme dropdown. ----------------------------
			var themeDs = new kendo.data.DataSource({
				transport: {
					read: {
						cache: false,
						// Note: since this template is in a different directory, we can't specify the cfc template without the full path name.
						url: function() { // The cfc component which processes the query and returns a json string. 
							return "<cfoutput>#application.baseUrl#</cfoutput>/common/cfc/ProxyController.cfc?method=getThemesForDropdown&includeAllLabel=true&csrfToken=<cfoutput>#csrfToken#</cfoutput>"; 
						}, 
						dataType: "json",
						contentType: "application/json; charset=utf-8", // Note: when posting json via the request body to a coldfusion page, we must use this content type or we will get a 'IllegalArgumentException' on the ColdFusion processing page.
						type: "GET" //Note: for large payloads coming from the server, use the get method. The post method may fail as it is less efficient.
					}
				} //...transport:
			});//...var rolesDs...

			// Create the top level dropdown
			var copyThemeId = $("#copyThemeId").kendoDropDownList({
				optionLabel: "Select...",
				autoBind: false,
				dataTextField: "ThemeName",
				dataValueField: "ThemeId",
				filter: "contains",
				dataSource: themeDs,
			}).data("kendoDropDownList");

			// !!! Note on the validators, all forms need a name attribute, otherwise the positioning of the messages will not work. --->
		
			var newThemeValidator = $("#newThemeForm").kendoValidator({
				// Set up custom validation rules 
				rules: {
					// The theme must be unique. 
					themeIsUnique:
					function(input){
						// Do not continue if the theme name is not unique
						if (input.is("[id='themeName']") && ( listFind( themeList, input.val().toLowerCase() ) != 0 ) ){
							// Display an error on the page.
							input.attr("data-themeIsUnique-msg", "Theme name already exists");
							// Focus on the current element
							$( "#themeName" ).focus();
							return false;
						}                                    
						return true;
					}
				}
			}).data("kendoValidator");

			// Invoked when the submit button is clicked. Insted of using '$("form").submit(function(event) {' and 'event.preventDefault();', We are using direct binding here to speed up the event.
			var newThemeSubmit = $('#newThemeSubmit');
			newThemeSubmit.on('click', function(e){     
				e.preventDefault();         
				if (newThemeValidator.validate()) {
					// Determine if there this is a new role and proceed.
					postNewTheme();
				} else {

					$.when(kendo.ui.ExtAlertDialog.show({ title: "There are errors", message: "Please correct the highlighted fields and try again", width: "<cfoutput>#application.kendoExtendedUiWindowWidth#</cfoutput>", icon: "k-ext-warning" }) // or k-ext-error, k-ext-question
						).done(function () {
						// Do nothing
					});
				}
			});
			
			function postNewTheme(){ 
				jQuery.ajax({
					type: 'post', 
					url: '<cfoutput>#application.baseUrl#</cfoutput>/common/cfc/ProxyController.cfc?method=createNewThemeFromCurrentTheme',
					dataType: "json",
					data: { // arguments
						csrfToken: '<cfoutput>#csrfToken#</cfoutput>',
						themeName: $("#themeName").val(),
						themeId: $("#selectedThemeId").val()
					},
					success: newThemeResult, // calls the result function.
					error: function(ErrorMsg) {
						console.log('Error' + ErrorMsg);
					}
				// Extract any errors. This is a new jQuery promise based function as of jQuery 1.8.
				}).fail(function (jqXHR, textStatus, error) {

					// The full response is: jqXHR.responseText, but we just want to extract the error.
					$.when(kendo.ui.ExtAlertDialog.show({ title: "Error while consuming the createNewThemeFromCurrentTheme function", message: error, icon: "k-ext-error", width: "<cfoutput>#application.kendoExtendedUiWindowWidth#</cfoutput>" }) // or k-ext-error, k-ext-information, k-ext-question, k-ext-warning.  You can also specify height.
						).done(function () {
						// Do nothing
					});		
				});	
			}

			// Submit the data and close this window.
			function newThemeResult(response){
				// alert(response)
				// Note: the response is the new themeId 
				// Open the new theme in the theme detail window
				createAdminInterfaceWindow(30, response.themeId);
				// Refresh the theme settings window
				$("#themeSettingsWindow").data("kendoWindow").refresh();
				// Close the this window
				$('#newThemeWindow').kendoWindow('destroy');
			}
			
		});//...document.ready
		
		// I am having the dreaded 'Cannot read properties of undefined (reading 'value')' error when reading the copythemeid form so I am saving it when the user makes a change in the dropdown. 
		function saveThemeIdValue(themeId){
			$("#selectedThemeId").val(themeId);
		}
	</script>
	
	<form id="newThemeForm" action="#" method="post" data-role="validator">
	<input type="hidden" name="selectedThemeId" id="selectedThemeId" value="">
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
			A theme has scores of shared settings. In order to create a new theme, please select a <b>current theme</b> that you would like to start from. Pay attention to the primary colors of the buttons and the color of the Logos and the color at the top of the blog post calender icons when copying an existing theme. You will want to match these primary accent colors when choosing new backgrounds and Logos for your new theme. 
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
			<label for="themeName">Theme Name</label>
		</td>
	   </tr>
	   <tr>
		<td class="<cfoutput>#thisContentClass#</cfoutput>" colspan="2">
			<input type="text" id="themeName" name="themeName" class="k-textbox" style="width: 95%" required> 
		</td>
	  </tr>
	<cfelse><!---<cfif session.isMobile>--->
	  <tr valign="middle" height="30px">
		<td align="right" class="<cfoutput>#thisContentClass#</cfoutput>">
			<label for="themeName">Theme Name</label>
		</td>
		<td align="left" class="<cfoutput>#thisContentClass#</cfoutput>" colspan="2">
			<input type="text" id="themeName" name="themeName" class="k-textbox" style="width: 50%" required> 
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
			<label for="copyThemeId">Current Theme:</label>  
		</td>
	   </tr>
	   <tr>
		<td class="<cfoutput>#thisContentClass#</cfoutput>" colspan="2">
			<select id="copyThemeId" name="copyThemeId" style="width: 95%" required onchange="saveThemeIdValue(this.value)"></select>
		</td>
	  </tr>
	<cfelse><!---<cfif session.isMobile>--->
	  <tr valign="middle" height="30px">
		<td align="right" class="<cfoutput>#thisContentClass#</cfoutput>" width="20%">
			<label for="copyThemeId">Current Theme:</label>  
		</td>

		<td align="left" class="<cfoutput>#thisContentClass#</cfoutput>" width="80%">
			<select id="copyThemeId" name="copyThemeId" style="width: 50%" required onchange="saveThemeIdValue(this.value)"></select>
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
		<td align="right" class="<cfoutput>#thisContentClass#</cfoutput>"></td>
		<td align="left" class="<cfoutput>#thisContentClass#</cfoutput>">
			<button id="newThemeSubmit" name="newThemeSubmit" class="k-button k-primary" type="button">Submit</button>
		</td>
	  </tr>
	</table>
	</form>