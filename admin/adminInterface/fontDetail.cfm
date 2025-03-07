	<cfsilent>
		<!--- Get the data from the db --->
		<cfset getFont = application.blog.getFont(fontId=URL.optArgs)>
	</cfsilent>
	<!---
	Debugging:<br/>
	<cfoutput>fontIdList: #fontIdList#</cfoutput>
	<cfdump var="#getUploadedFont#"></cfdump>--->

	<cfsilent>
		<!--- Set the variable values. I want to shorten the long variable names here. --->
		<cfset fontId = getFont[1]["FontId"]>
		<cfset font = getFont[1]["Font"]>
		<cfset fileName = getFont[1]["FileName"]>
		<cfset fontWeight = getFont[1]["FontWeight"]>
		<cfset italic = getFont[1]["Italic"]>
		<cfset fileName = getFont[1]["FileName"]>
		<cfset woff = getFont[1]["Woff"]>
		<cfset woff2 = getFont[1]["Woff2"]>	
		<cfset selfHosted = getFont[1]["SelfHosted"]>
		<cfset fontType = getFont[1]["FontType"]>
		<cfset webSafeFont = getFont[1]["WebSafeFont"]>
		<cfset googleFont = getFont[1]["GoogleFont"]>
		<cfset useFont = getFont[1]["UseFont"]>
			
		<cfif woff2>
			<cfset fontFileName = application.baseUrl & "/common/fonts/" & fileName & ".woff2">
		<cfelseif woff>
			<cfset fontFileName = application.baseUrl & "/common/fonts/" & fileName & ".woff">
		<cfelseif len(fileName)>
			<!--- Woff2 is our standard font --->

			<cfset fontFileName = application.baseUrl & "/common/fonts/" & fileName & ".woff2">
		<cfelse>
			<cfset fontFileName = "">
		</cfif>
	</cfsilent>
	<!---<cfoutput>woff2: #woff2# fontFileName: #fontFileName#</cfoutput> --->

	<!--- Load the font. ---> 
	<style>
		@font-face {
			font-family: "<cfoutput>#font#</cfoutput>";
			src: url('<cfoutput>#fontFileName#</cfoutput>');
		}
	</style>
		
	<form id="fontDetailForm" name="fontDetailForm" data-role="validator">	
	<input type="hidden" id="fontId" name="fontId" value="<cfoutput>#URL.optArgs#</cfoutput>"/>
	<input type="hidden" name="csrfToken" id="csrfToken" value="<cfoutput>#csrfToken#</cfoutput>" />
		
	<table align="center" class="k-content" width="100%" cellpadding="2" cellspacing="0">
	  <cfsilent>
		<!---The first content class in the table should be empty. --->
		<cfset thisContentClass = HtmlUtilsObj.getKendoClass('')>
		<!--- Set the colspan property for borders --->
		<cfset thisColSpan = "2">
	  </cfsilent>
	  <tr height="1px">
		  <td align="left" valign="top" colspan="2" class="<cfoutput>#thisContentClass#</cfoutput>"></td>
	  </tr>
	  <tr valign="middle" height="30px">
		<td valign="bottom" align="left" class="<cfoutput>#thisContentClass#</cfoutput>" colspan="<cfoutput>#thisColSpan#</cfoutput>">
			<div id="font-preview" style="font-family: <cfoutput>#font#</cfoutput>"><h4><cfoutput>#font#</cfoutput> preview: The quick brown fox jumps over the lazy dog</h4></div>
		</td>
	  </tr>
	  <tr height="1px">
		  <td align="left" valign="top" colspan="2" class="border <cfoutput>#thisContentClass#</cfoutput>"></td>
	  </tr> 
	  <tr valign="middle" height="30px">
		<td valign="bottom" align="left" class="<cfoutput>#thisContentClass#</cfoutput>" colspan="<cfoutput>#thisColSpan#</cfoutput>">
			<p>The fonts are loaded dynamically when a font is assigned to particular set of content of a theme. A font can be assigned to the body, the title header, and the menu script at the top of the page. Fonts can also be used when making a post in the post editor. If you are using different fonts using the theme interface you don't  need to load the font in your code, it will be loaded automatically.</p> 
			<p>If you are writing your own display oriented code click on the use font button to load the font automatically. However, be aware that loading too many fonts will slow the page down as they consume resources to load.</p>
		</td>
	  </tr>
	<cfif session.isMobile>
	  <tr valign="middle">
		<td class="<cfoutput>#thisContentClass#</cfoutput>" colspan="2">
		<label for="font">Font</label>
		</td>
	   </tr>
	   <tr>
		<td class="<cfoutput>#thisContentClass#</cfoutput>" colspan="2">
			<input id="font" name="font" type="text" value="<cfoutput>#font#</cfoutput>" class="k-textbox" style="width: 95%" />
		</td>
	  </tr>
	<cfelse><!---<cfif session.isMobile>--->
	  <tr>
		<td align="right" class="<cfoutput>#thisContentClass#</cfoutput>" style="width: 20%"> 
			<label for="font">Font:</label>
		</td>
		<td class="<cfoutput>#thisContentClass#</cfoutput>" align="left" style="width: 80%"> 
			<input id="font" name="font" type="text" value="<cfoutput>#font#</cfoutput>" class="k-textbox" style="width: 60%" />    
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
		  <td align="left" valign="bottom" colspan="2" class="border <cfoutput>#thisContentClass#</cfoutput>"></td>
	  </tr>
	<cfif session.isMobile>
	  <tr valign="middle">
		<td class="<cfoutput>#thisContentClass#</cfoutput>" colspan="2">
			<label for="fontWeight">Font Weight:</label>
		</td>
	   </tr>
	   <tr>
		<td class="<cfoutput>#thisContentClass#</cfoutput>" colspan="2">
			<script>
				// create DropDownList from select HTML element
				$("#fontWeight").kendoDropDownList();
			</script>
			<select name="fontWeight" id="fontWeight">
				<option value="Thin"<cfif fontWeight eq 'Thin'> selected</cfif>>thin (100)</option>
				<option value="Light"<cfif fontWeight eq 'Light'> selected</cfif>>Light (200-300)</option>
				<option value="Regular"<cfif fontWeight eq 'Regular'> selected</cfif>>Regular (400)</option>
				<option value="Semi-Bold"<cfif fontWeight eq 'Semi-Bold'> selected</cfif>>Semi-Bold (500-600)</option>
				<option value="Bold"<cfif fontWeight eq 'bold'> selected</cfif>>Bold (700-800)</option>
				<option value="Black"<cfif fontWeight eq 'black'> selected</cfif>>Black (900)</option>
			</select>
		</td>
	  </tr>
	<cfelse><!---<cfif session.isMobile>--->
	  <tr valign="middle" height="30px">
		<td valign="bottom" align="right" class="<cfoutput>#thisContentClass#</cfoutput>">
			<label for="fontWeight">Font Weight:</label>
		</td>
		<td valign="bottom" align="left" class="<cfoutput>#thisContentClass#</cfoutput>">
			<script>
				// create DropDownList from select HTML element
				$("#fontWeight").kendoDropDownList();
			</script>
			<select name="fontWeight" id="fontWeight">
				<option value="Thin"<cfif fontWeight eq 'Thin'> selected</cfif>>thin (100)</option>
				<option value="Light"<cfif fontWeight eq 'Light'> selected</cfif>>Light (200-300)</option>
				<option value="Regular"<cfif fontWeight eq 'Regular'> selected</cfif>>Regular (400)</option>
				<option value="Semi-Bold"<cfif fontWeight eq 'Semi-Bold'> selected</cfif>>Semi-Bold (500-600)</option>
				<option value="Bold"<cfif fontWeight eq 'bold'> selected</cfif>>Bold (700-800)</option>
				<option value="Black"<cfif fontWeight eq 'black'> selected</cfif>>Black (900)</option>
			</select>	
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
		  <td align="left" valign="bottom" colspan="2" class="border <cfoutput>#thisContentClass#</cfoutput>"></td>
	  </tr>
	<cfif session.isMobile>
	  <tr valign="middle">
		<td class="<cfoutput>#thisContentClass#</cfoutput>" colspan="2">
			<label for="italic">Italic?</label>
		</td>
	   </tr>
	   <tr>
		<td class="<cfoutput>#thisContentClass#</cfoutput>" colspan="2">
			<input type="checkbox" name="italic" id="italic" value="1" <cfif italic>checked</cfif>>
		</td>
	  </tr>
	<cfelse><!---<cfif session.isMobile>--->
	  <tr valign="middle" height="30px">
		<td valign="bottom" align="right" class="<cfoutput>#thisContentClass#</cfoutput>">
			<label for="italic">Italic?</label>
		</td>
		<td valign="bottom" align="left" class="<cfoutput>#thisContentClass#</cfoutput>">
			<input type="checkbox" name="italic" id="italic" value="1" <cfif italic>checked</cfif>>
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
			<label for="fontType">Font Type:</label>
		</td>
	   </tr>
	   <tr>
		<td class="<cfoutput>#thisContentClass#</cfoutput>" colspan="2">
			<input type="text" name="fontType" id="fontType" value="<cfoutput>#fontType#</cfoutput>" class="k-textbox" style="width: 95%">
		</td>
	  </tr>
	<cfelse><!---<cfif session.isMobile>--->
	  <tr valign="middle" height="30px">
		<td align="right" class="<cfoutput>#thisContentClass#</cfoutput>">
			<label for="fontType">Font Type:</label>
		</td>
		<td align="left" class="<cfoutput>#thisContentClass#</cfoutput>">
			<input type="text" name="fontType" id="fontType" value="<cfoutput>#fontType#</cfoutput>" class="k-textbox" style="width: 66%">
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
			<label for="fileName">File Name:</label>
		</td>
	   </tr>
	   <tr>
		<td class="<cfoutput>#thisContentClass#</cfoutput>" colspan="2">
			<input type="text" name="fileName" id="fileName" value="<cfoutput>#fileName#</cfoutput>" class="k-textbox" style="width: 95%">
		</td>
	  </tr>
	<cfelse><!---<cfif session.isMobile>--->
	  <tr valign="middle" height="30px">
		<td align="right" class="<cfoutput>#thisContentClass#</cfoutput>">
			<label for="fileName">File Name:</label>
		</td>
		<td align="left" class="<cfoutput>#thisContentClass#</cfoutput>">
			<input type="text" name="fileName" id="fileName" value="<cfoutput>#fileName#</cfoutput>" class="k-textbox" style="width: 66%">
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
		  <cfif not session.isMobile><td></td></cfif>
		  <td align="left" <cfif session.isMobile>colspan="2"</cfif>>
			<!--- Inner table --->
			<table align="center" class="<cfoutput>#thisContentClass#</cfoutput>" width="100%" cellpadding="4" cellspacing="0">
				<tr>
					<td width="25%" align="left">
						<label for="webSafeFont">Web Safe Font?</label>
						<input type="checkbox" name="webSafeFont" id="webSafeFont" value="1" <cfif WebSafeFont>checked</cfif>>
					</td>
					<td width="25%" align="left">
						<label for="selfHosted">Self Hosted?</label>
						<input type="checkbox" name="selfHosted" id="selfHosted" value="1" <cfif selfHosted>checked</cfif>>
					</td>
					<td width="25%" align="left">
						<label for="googleFont">Google Font?</label>
						<input type="checkbox" name="googleFont" id="googleFont" value="1" <cfif selfHosted>checked</cfif>>
					</td>
					<td width="25%" align="left">
						<label for="useFont">Use Font?</label>
						<input type="checkbox" name="useFont" id="useFont" value="1" <cfif useFont>checked</cfif>>
					</td>
				</tr>
			</table>
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
	  <tr valign="middle" height="30px">
		<td align="right" class="<cfoutput>#thisContentClass#</cfoutput>"></td>
		<td align="left" class="<cfoutput>#thisContentClass#</cfoutput>">
			<button id="fontDetailSubmit" name="fontDetailSubmit" class="k-button k-primary" type="button">Submit</button>
		</td>
	  </tr>
	</table>
	</form>
				
	<script>
		$(document).ready(function() {
			// !!! Note on the validators, all forms need a name attribute, otherwise the positioning of the messages will not work. --->
			var fontDetailFormValidator = $("#fontDetailForm").kendoValidator({
				// Set up custom validation rules 
				rules: {
					// font name
					font:
					function(input){
						if (input.is("[id='font']") && $.trim(input.val()).length < 4){
							// Display an error on the page.
							input.attr("data-fontRequired-msg", "The font field must be at least 4 characters");
							// Focus on the current element
							$( "#font" ).focus();
							return false;
						}                                    
						return true;
					}
				}
			}).data("kendoValidator");
		
			// Invoked when the submit button is clicked. Insted of using '$("form").submit(function(event) {' and 'event.preventDefault();', We are using direct binding here to speed up the event.
			var fontDetailSubmit = $('#fontDetailSubmit');
			fontDetailSubmit.on('click', function(e){     
                e.preventDefault();         
				if (fontDetailFormValidator.validate()) {
					
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
				url: '<cfoutput>#application.baseUrl#</cfoutput>/common/cfc/ProxyController.cfc?method=saveFont&csrfToken=<cfoutput>#csrfToken#</cfoutput>',
				// Serialize the form. The csrfToken is also in the form.
				data: $('#fontDetailForm').serialize(),
				// This is one of the few times that we will be sending back an html response. We are going to use this directly to set the content in the editor. its easier to craft the html on the server side than to manipulate the dom with a json object on the client. Normally this is always json
				dataType: "html",
				success: fontDetailUpdateResult, // calls the result function.
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
		
		function fontDetailUpdateResult(response){
			// alert(response)
			// Note: the response is an html string 
			
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
			// Close this window
			$('#fontDetailWindow').kendoWindow('destroy');
		}
		
	</script>