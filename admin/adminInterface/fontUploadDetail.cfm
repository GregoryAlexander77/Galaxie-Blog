	<cfsilent>
		<!---  Replace the underscore with a comma so that we can use it in the query below. --->
		<cfset fontIdList = replaceNoCase(URL.optArgs, '_', ',', 'all')>

		<!--- Get the data from the db --->
		<cfquery name="getUploadedFont" dbtype="hql">
			SELECT DISTINCT new Map (
				FontId as FontId,
				FileName as FileName
			)
			FROM Font
			WHERE FontId IN (<cfqueryparam value="#fontIdList#" cfsqltype="integer" list="yes">)
		</cfquery>
			
		<!--- Make a new fontIdList from the query --->
		<cfparam name="newFontIdList" default="" type="string">
			
		<cfif arrayLen(getUploadedFont)>
			<cfloop from="1" to="#arrayLen(getUploadedFont)#" index="i">
				<cfset newFontIdList = ListAppend(newFontIdList, getUploadedFont[i].FontId, "_")>
			</cfloop>
		</cfif>
		
	</cfsilent>
	
	<!---
	Debugging:<br/>
	<cfoutput>fontIdList: #fontIdList#</cfoutput>
	<cfdump var="#getUploadedFont#"></cfdump>--->
		
	<h3>Please enter font details for each font</h3>
	
	<form id="fontUploadDetail" name="fontUploadDetail" data-role="validator">
	<!--- Hidden input to pass the fontIdList --->
	<input type="hidden" name="fontIdList" id="fontIdList" value="<cfoutput>#newFontIdList#</cfoutput>">
	<input type="hidden" name="csrfToken" id="csrfToken" value="<cfoutput>#csrfToken#</cfoutput>" />

	<table align="left" class="k-content tableBorder" width="100%" cellpadding="5" cellspacing="0">
	<cfif not arrayLen(getUploadedFont)>
		<tr>
			<td class="k-header">
			<cfoutput>There are no recent uploads.</cfoutput>
			</td>
		</tr>
	</cfif><!---<cfif not getMediaUrl.recordCount>--->
	<cfloop from="1" to="#arrayLen(getUploadedFont)#" index="i"><cfoutput>
		<cfsilent>
			<!--- Set the variable values. I want to shorten the long variable names here. --->
			<cfset fontId = getUploadedFont[i]["FontId"]>
			<cfset fileName = getUploadedFont[i]["FileName"]>
				
			<!--- Inspect the file name to try to get the best defaults on the menu's --->
			<!--- Font weight --->
			<cfif FileName contains '100'>
				<cfset defaultWeight = 'Thin'>
			<cfelseif FileName contains '200' or FileName contains '300'>
				<cfset defaultWeight = 'Light'>
			<cfelseif FileName contains '400' or FileName contains 'Regular'>
				<cfset defaultWeight = 'Regular'>
			<cfelseif FileName contains '500' or FileName contains '600'>
				<cfset defaultWeight = 'Semi-Bold'>
			<cfelseif FileName contains '700' or FileName contains '800'>
				<cfset defaultWeight = 'Bold'>
			<cfelseif FileName contains '900'>
				<cfset defaultWeight = 'Black'>
			<cfelse>
				<cfset defaultWeight = 'Normal'>
			</cfif>
			<!--- Italic --->
			<cfif FileName contains 'italic'>
				<cfset italic = true>
			<cfelse>
				<cfset italic = false>
			</cfif>
	
		</cfsilent>

		<!--- Load the fonts. ---> 
		<style>
			/* fonts */
			@font-face {
				font-family: "<cfoutput>#fileName#</cfoutput>";
				src: url('<cfoutput>#application.baseUrl#/common/fonts/#fileName#</cfoutput>');
			}
		</style>
		<tr class="#iif(i MOD 2,DE('k-content'),DE('k-alt'))#" height="50px;">
		<!--- Create alternating rows in the table. The Kendo classes which we will use are k-alt and k-content.
		We will create a border between the rows if the current row is not the first row. --->
		<cfif i eq 1>
			<td valign="top" width="240px">
		<cfelse>
			<td align="left" valign="top" class="border" width="240px">
		</cfif>
			<div id="font-<cfoutput>#fileName#</cfoutput>-preview" style="font-family: <cfoutput>#fileName#</cfoutput>">Font Preview: The quick brown fox jumps over the lazy dog</div>
		</td>
		<cfif i eq 1>
			<td valign="top">
		<cfelse>
			<td align="left" valign="top" class="border">
		</cfif>
				<table align="left" class="k-content" width="100%" cellpadding="5" cellspacing="0" border="2">
					<tr>
						<td><label for="font<cfoutput>#i#</cfoutput>"><b>Font:</b></label></td>
					</tr>
					<tr>
						<td>
							<input type="text" name="font<cfoutput>#i#</cfoutput>" id="font<cfoutput>#i#</cfoutput>" value="<cfoutput>#fileName#</cfoutput>" class="k-textbox" required style="width: 100%;">
						</td>
					</tr>
					<tr>
						<td class="border k-alt"><label for="fileName<cfoutput>#i#</cfoutput>"><b>Filename:</b></label></td>
					</tr>
					<tr>
						<td class="k-alt"><input type="text" name="fileName<cfoutput>#i#</cfoutput>" id="fileName<cfoutput>#i#</cfoutput>" value="<cfoutput>#fileName#</cfoutput>" class="k-textbox" style="width: 100%;"></td>
					</tr>
					
					<tr>
						<td class="border k-content"><label for="fontWeight<cfoutput>#i#</cfoutput>"><b>Font Weight:</b></label></td>
					</tr>
					<tr>
						<td class="k-content">
						<script>
							// create DropDownList from select HTML element
							$("#chr(35)#fontWeight<cfoutput>#i#</cfoutput>").kendoDropDownList();
						</script>
						<select name="fontWeight<cfoutput>#i#</cfoutput>" id="fontWeight<cfoutput>#i#</cfoutput>">
							<option value="Thin"<cfif defaultWeight eq 'Thin'> selected</cfif>>thin (100)</option>
							<option value="Light"<cfif defaultWeight eq 'Light'> selected</cfif>>Light (200-300)</option>
							<option value="Regular"<cfif defaultWeight eq 'Regular'> selected</cfif>>Regular (400)</option>
							<option value="Semi-Bold"<cfif defaultWeight eq 'Semi-Bold'> selected</cfif>>Semi-Bold (500-600)</option>
							<option value="Bold"<cfif defaultWeight eq 'bold'> selected</cfif>>Bold (700-800)</option>
							<option value="Black"<cfif defaultWeight eq 'black'> selected</cfif>>Black (900)</option>
						</select>	
					</tr>
					<tr>
						<td class="border k-alt"><label for="fontType<cfoutput>#i#</cfoutput>"><b>Font Type (ie sans-serif):</b></label></td>
					</tr>
					<tr>
						<td class="k-alt">
							<script>
								// create DropDownList from select HTML element
                    			$("#chr(35)#fontType<cfoutput>#i#</cfoutput>").kendoDropDownList();
							</script>
							<select name="fontType<cfoutput>#i#</cfoutput>" id="fontType<cfoutput>#i#</cfoutput>">
								<option value="sans-serif" selected>Sans Serif</option>
								<option value="serif">Serif</option>
								<option value="slab-serif">Slab Serif</option>
								<option value="display">Display</option>
								<option value="script">Script</option>
							</select> 
						</td>
					</tr>
					<tr>
						<td class="border k-content">
						<label for="italic<cfoutput>#i#</cfoutput>"><b>Italic?:</b></label>
						<input type="checkbox" name="italic<cfoutput>#i#</cfoutput>" id="italic<cfoutput>#i#</cfoutput>"<cfif italic> checked</cfif> value="true"></td>
					</tr>
					<tr>
						<td class="k-alt">
						<label for="googleFont<cfoutput>#i#</cfoutput>"><b>Is this a Google Font?:</b></label>
						<input type="checkbox" name="googleFont<cfoutput>#i#</cfoutput>" id="googleFont<cfoutput>#i#</cfoutput>" checked value="true">
						</td>
					</tr>
				</table>
			</td>
		</tr>

	</cfoutput></cfloop>
		<tr>
		<!--- Create alternating rows in the table. The Kendo classes which we will use are k-alt and k-content.
		We will create a border between the rows if the current row is not the first row. --->
		<cfif i eq 1>
			<td valign="top" <cfif not session.isMobile>colspan="2"</cfif>>
		<cfelse>
			<td align="left" valign="top" <cfif not session.isMobile>colspan="2"</cfif>>
		</cfif>
				<button id="uploadFontDetailSubmit" class="k-button k-primary" type="button">Submit</button>
			</td>
		</tr>
	</table>
				
	</form>
				
	<script>
		$(document).ready(function() {
			// !!! Note on the validators, all forms need a name attribute, otherwise the positioning of the messages will not work. --->
			var fontUploadDetailFormValidator = $("#fontUploadDetail").kendoValidator({
				// Set up custom validation rules 
				rules: {
				<cfloop from="1" to="#arrayLen(getUploadedFont)#" index="i">
					<cfsilent>
						<!--- Set the variable values. I want to shorten the long variable names here. --->
						<cfset fontId = getUploadedFont[i]["FontId"]>
						<cfset fileName = getUploadedFont[i]["FileName"]>
					</cfsilent>
					// font name
					font<cfoutput>#i#</cfoutput>:
					function(input){
						if (input.is("[id='font<cfoutput>#i#</cfoutput>']") && $.trim(input.val()).length < 4){
							// Display an error on the page.
							input.attr("data-font<cfoutput>#i#</cfoutput>Required-msg", "The font field must be at least 4 characters");
							// Focus on the current element
							$( "#font<cfoutput>#i#</cfoutput>" ).focus();
							return false;
						}                                    
						return true;
					},
					// file name
					fileName<cfoutput>#i#</cfoutput>:
					function(input){
						if (input.is("[id='fileName<cfoutput>#i#</cfoutput>']") && $.trim(input.val()).length < 4){
							// Display an error on the page.
							input.attr("data-fileName<cfoutput>#i#</cfoutput>Required-msg", "The font field must be at least 4 characters");
							// Focus on the current element
							$( "#fileName<cfoutput>#i#</cfoutput>" ).focus();
							return false;
						}                                    
						return true;
					},
					</cfloop>
				}
			}).data("kendoValidator");
		
			// Invoked when the submit button is clicked. Insted of using '$("form").submit(function(event) {' and 'event.preventDefault();', We are using direct binding here to speed up the event.
			var uploadFontDetailSubmit = $('#uploadFontDetailSubmit');
			uploadFontDetailSubmit.on('click', function(e){      
                e.preventDefault();         
				if (fontUploadDetailFormValidator.validate()) {
					// submit the form.
					// Note: when testing the ui validator, comment out the post line below. It will only validate and not actually do anything when you post.
					// alert('posting');
					postFontDetails('update');
				} else {
					$.when(kendo.ui.ExtAlertDialog.show({ title: "There are errors", message: "Required fields are missing.", width: "<cfoutput>#application.kendoExtendedUiWindowWidth#</cfoutput>", icon: "k-ext-warning" }) // or k-ext-error, k-ext-question
						).done(function () {
						// Do nothing
					});
				}
			});
		});//...document.ready
		
		// Post method on the detail form called from the GalleryDetailFormValidator method on the detail page. The action variable will either be 'update' or 'insert'.
		function postFontDetails(action){
			jQuery.ajax({
				type: 'post', 
				url: '<cfoutput>#application.baseUrl#</cfoutput>/common/cfc/ProxyController.cfc?method=saveFontAfterUpload&csrfToken=<cfoutput>#csrfToken#</cfoutput>',
				// Serialize the form. The csrfToken is also in the form.
				data: $('#fontUploadDetail').serialize(),
				// This is one of the few times that we will be sending back an html response. We are going to use this directly to set the content in the editor. its easier to craft the html on the server side than to manipulate the dom with a json object on the client. Normally this is always json
				dataType: "html",
				success: fontUpdateResult, // calls the result function.
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
					$.when(kendo.ui.ExtAlertDialog.show({ title: "Error while consuming the saveFont function", message: error, icon: "k-ext-error", width: "<cfoutput>#application.kendoExtendedUiWindowWidth#</cfoutput>" }) // or k-ext-error, k-ext-information, k-ext-question, k-ext-warning.  You can also specify height.
						).done(function () {
					// Do nothing
					});		
				}//...if (jqXHR.status === 403) { 
			});
		};
		
		function fontUpdateResult(response){
			// alert(response)
			// Note: the response is an html string 
			
			// Alert the user
			$.when(kendo.ui.ExtYesNoDialog.show({ 

				title: "Font was uploaded",
				message: "Do you want to upload more fonts?",
				icon: "k-ext-question",
				width: "<cfoutput>#application.kendoExtendedUiWindowWidth#</cfoutput>", 
				height: "215px"
			})
			).done(function (response) { // If the user clicked 'yes'.
				if (response['button'] == 'Yes'){// remember that js is case sensitive.
					// Close this window
					$('#uploadFontDetailsWindow').kendoWindow('destroy');
					// and do it again
					createAdminInterfaceWindow(31, '', 'addFont');
				} else {
					// Refresh the <cfif application.kendoCommercial>kendo<cfelse>jsgrid</cfif> grid 
					try {
						// Refresh the font grid if it is open
					<cfif application.kendoCommercial and 1 eq 2><!---We are not using the Kendo grids right now.--->
						$('#fontsGrid').data('kendoGrid').dataSource.read();
					<cfelse>
						$("#fontsGrid").jsGrid("loadData");
					</cfif> 
						// Refresh the theme font dropdowns if the window is open
						$("#blogNameFontDropdown").data("kendoDropDownList").dataSource.read();
					} catch(e){
						// The grid or dropdown was not initialized. This is a normal error
					}
					// Close the upload font window
					$('#uploadFontWindow').kendoWindow('destroy');
					// Close this window
					$('#uploadFontDetailsWindow').kendoWindow('destroy');
				}//..if (response['button'] == 'Yes'){
			});	
		}
		
	</script>