	<!---
	<cfdump var="#URL#">
	URL.optArgs is the themeId 
	URL.otherArgs is the content template being edited
	URL.otherArgs1 determines the device. If it is a 1, its mobile, if its a 0 its desktop
	--->
	
	<!--- Instantiate the sting utility object. We are using this to remove empty strings from the code preview. --->
	<cfobject component="#application.stringUtilsComponentPath#" name="StringUtilsObj">
	<!--- Instantiate the default content object to get the preview --->
	<cfobject component="#application.defaultContentObjPath#" name="DefaultContentObj">
	<!--- Set the default content var. --->
	<cfparam name="contentVar" default="">
	
	<style>
		.mce-ico.mce-i-fa {
		display: inline-block;
		font: normal normal normal 14px/1 FontAwesome;
		font-size: inherit;
		text-rendering: auto;
		-webkit-font-smoothing: antialiased;
		-moz-osx-font-smoothing: grayscale;
	}
	</style>
	
	<!---********************* Generic content template editor *********************--->
	<!--- Set the common vars for tinymce. ---> 
	<cfsilent>
	<cfset selectorId = "contentTemplateEditor">
	<cfif session.isMobile>
		<cfset editorHeight = "325">
	<cfelse>
		<cfset editorHeight = "650">
	</cfif>
	
	<!--- The URL.otherArgs is the content template type. This string appends either 'Desktop' or 'Mobile' to the content template name and we need strip this device string to determine which content to get --->	
	<cfif findNoCase( 'Mobile', URL.otherArgs )>
		<cfset contentTemplateName = replaceNoCase(URL.otherArgs, 'Mobile', '')>
		<cfset device = 'mobile'>
	<cfelseif findNoCase( 'Desktop', URL.otherArgs ) >
		<cfset contentTemplateName = replaceNoCase(URL.otherArgs, 'Desktop', '')>
		<cfset device = 'desktop'>
	</cfif>
	<!--- Set the content var label --->	
	<cfset contentVarLabel = StringUtilsObj.camelToSpace( contentTemplateName )>
	<cfset contentVarLabel = StringUtilsObj.titleCase( contentVarLabel ) & " " & StringUtilsObj.titleCase( device )>
	<cfset contentVarLabel = replaceNoCase(contentVarLabel, '&Nbsp;', ' ', 'all')>
	
	<!--- These vars are used by the tiny mce editor included below --->
	<!--- Get the current content if it exists --->
	<cfinvoke component="#application.blog#" method="getContentOutputByContentTemplate" returnvariable="getOutputContent">
		<cfinvokeargument name="pageId" value="2"><!--- Note: pageId 1 is the landing blog page, 2 is a blog post --->
		<cfinvokeargument name="contentTemplate" value="#contentTemplateName#">
		<cfinvokeargument name="device" value="#device#">
		<cfif len(URL.optArgs)>
			<cfinvokeargument name="themeRef" value="#URL.optArgs#">
		</cfif>
	</cfinvoke>
	
	<!--- If there is data, set the conet var and label --->
	<cfif arrayLen(getOutputContent)>
		<!--- Set the content var. The columns in the db are either ContentOutputMobile or ContentOutput. Note: the contentVar may be empty when the user reverts back to the orginal code using the revert button in the editor --->
		<cfif findNoCase( 'Mobile', URL.otherArgs )>
			<cfset contentVar = getOutputContent[1]["ContentOutputMobile"]>
		<cfelseif findNoCase( 'Desktop', URL.otherArgs ) >
			<cfset contentVar = getOutputContent[1]["ContentOutput"]>
		</cfif>
		<!--- Set the label --->
		<cfset label ="Current " & contentVarLabel & " Content">
	</cfif>
	<!--- If the contentVar is empty- get the default content --->
	<cfif !isDefined("contentVar") or !len(contentVar)>
		<!--- Set the label --->
		<cfset label ="Sample " & contentVarLabel & " Content">
		<!--- Get the default content if the content template is not stored in the db (getTheme, type, isMobileDisplay) --->
		<cfset contentVar = StringUtilsObj.removeEmptyLinesInStr(DefaultContentObj.getDefaultContentPreview( getTheme, URL.otherArgs, URL.otherArgs1 ) )>
	</cfif>
	
	<!--- Set the toolbar string to determine what tools are availbable in the editor. --->
	<cfif URL.otherArgs eq 'navigationMenuDesktop' or URL.otherArgs eq 'navigationMenuMobile'>
		<!--- Set the toobar to determine what tools are availbable in the editor --->
		<cfset toolbarString = "undo redo | link | bullist outdent indent">
		<!--- We are not uploading images here --->
		<cfset imageHandlerUrl = "">
		<!--- There are no images in this editor --->
		<cfset imageMediaIdField = "">
		<cfset imageClass = "">
		<!--- Don't include the common css when previewing the navigation menu --->
		<cfset includeCommonCss = false>
	<cfelse>
		<!--- Set the toobar to determine what tools are availbable in the editor --->
		<cfif session.isMobile>
			<cfset toolbarString = "undo redo | bold italic | link | image media fancyBoxGallery">
		<cfelse>
			<cfset toolbarString = "insertfile undo redo | styleselect | bold italic | alignleft aligncenter alignright alignjustify | bullist numlist outdent indent | tox | hr | link | image editimage | media | fancyBoxGallery | map mapRouting | customWindow | emoticons">
		</cfif>
		<cfset imageHandlerUrl = "#application.baseUrl#/common/cfc/ProxyController.cfc?method=uploadImage&mediaProcessType=" & URL.otherArgs & "&csrfToken=" & csrfToken>
		<cfset imageMediaIdField = "imageMediaId">
		<cfset imageClass = "entryImage">
		<!--- We want to include common CSS --->
		<cfset includeCommonCss = true>
	</cfif>
			
	<!--- We are not using video captions here --->
	<cfset disableVideoCoverAndWebVttButtons = true>
	</cfsilent>

	<!--- Include the tinymce js template --->
	<cfinclude template="#application.baseUrl#/includes/templates/js/tinyMce.cfm">
		
	<!--- Get the theme and themeId as a JSON string to populate the theme dropdown. --->
	<cfset themeDropdownValue = application.blog.getContentOutputThemesAsJson(pageId=2, contentTemplate='#contentTemplateName#', includeAllLabel=true)>
		
	<script>
		
		// Note: this function passes the template name and code to save the code to the db. action is either updateCode or revertCode.
		function saveContentTemplate(action){ 
			
			// Get the selected themes
			var contentTemplateThemes = $("#contentTemplateThemes").data("kendoMultiSelect").value().toString();
			// Get the contents of the editor
			var contentTemplateCode = tinymce.get("<cfoutput>#selectorName#</cfoutput>").getContent();
			// Modify any tags that may be deleted by ColdFusion on the server when using Global Script Protection and place an attach string in front of scripts, styles and meta tags. These will get cleaned up prior to the data being inserted into the db.
			var contentTemplateCode = bypassScriptProtection(contentTemplateCode);
			
			// Send the data to the service controller. 			
			jQuery.ajax({
				type: 'post', 
				url: '<cfoutput>#application.baseUrl#</cfoutput>/common/cfc/ProxyController.cfc?method=saveContentTemplate',
				dataType: "json",
				success: saveContentTemplateResult(action), // calls the result function.
				data: { // arguments
					csrfToken: '<cfoutput>#csrfToken#</cfoutput>',
					// The action arg is either updateCode or revertCode. It is needed as the processing template needs to determine whether to update the code or revert.
					action: action,
					// Pass the selected theme Id. This will be 0 when all themes is selected. We are usign the toString method to pass the id's in a comma separated list
					selectedContentThemes: contentTemplateThemes,
					// Pass the template 
					contentTemplate: <cfoutput>'#contentTemplateName#'</cfoutput>,
					// Users can update both mobile and desktop columns
					applyAcrossDevices: $('#applyAcrossDevices').prop('checked'),
					// Pass in the code type (either contentTemplateName + 'Desktop' or 'Mobile')
					codeColumn: <cfoutput>'#URL.otherArgs#'</cfoutput>,
					// Pass the actual code
					code: contentTemplateCode
					
				},
				error: function(ErrorMsg) {
					console.log('Error' + ErrorMsg);
				}
			// Extract any errors. This is a new jQuery promise based function as of jQuery 1.8.
			}).fail(function (jqXHR, textStatus, error) {

				// The full response is: jqXHR.responseText, but we just want to extract the error.
				$.when(kendo.ui.ExtAlertDialog.show({ title: "Error while consuming the saveContentTemplate function", message: error, icon: "k-ext-error", width: "<cfoutput>#application.kendoExtendedUiWindowWidth#</cfoutput>" }) // or k-ext-error, k-ext-information, k-ext-question, k-ext-warning.  You can also specify height.
					).done(function () {
					// Do nothing
				});		
			});
		}
		
		// Submit the data and close this window.
		function saveContentTemplateResult(action){
			setTimeout(function () {
				$('#contentTemplateEditor').kendoWindow('destroy');
			}, 250);//..setTimeout(function () {
		}
		
		// Invoked when the preview button is clicked. 
		var previewContentTemplate = $('#previewContentTemplateButton');
		previewContentTemplate.on('click', function(e){ 
			e.preventDefault();  
			// Get the contents of the editor
			var contentTemplateCode = compositeHeaderDesktop.getValue();
			// Stuff the value into a hidden form
			$("#compositeHeaderDesktopPreviewCode").val( <cfoutput>#selectorId#</cfoutput> );
			// Open the preview window
			createContentOutputPreviewWindow(<cfoutput>#URL.optArgs#,'#URL.otherArgs#',#URL.otherArgs1#</cfoutput>)
		});
			
		// Invoked when the submit button is clicked. 
		var saveContentSubmit = $('#saveContentSubmitButton');
		saveContentSubmit.on('click', function(e){ 
			e.preventDefault();  
			// Send the data
			saveContentTemplate('updateCode');											  
		});		
		
		function revertBackToOriginalCode(template){
			
			// Raise the prompt
			$.when(kendo.ui.ExtYesNoDialog.show({ 
				title: "Revert Changes?",
				message: "Do you want to revert back to the original code? If you select yes, you will delete any previous custom changes that were made.",
				icon: "k-ext-warning",
				width: "<cfoutput>#application.kendoExtendedUiWindowWidth#</cfoutput>", 
				height: "215px"
			})
			).done(function (response) { // If the user clicked 'yes', retry.
				if (response['button'] == 'Yes'){// remember that js is case sensitive.
					// Send the data to update the database column with an empty string
					saveContentTemplate('revertCode');
				}//..if (response['button'] == 'Yes'){
				
			});	
		}
	</script>
		
	<form id="tinyMceContentEditor" action="#" method="post" data-role="validator">
	<!-- The mediaType will either be an empty string, image or video -->
	<input type="hidden" name="mediaType" id="mediaType" value="image" />
	<input type="hidden" name="csrfToken" id="csrfToken" value="<cfoutput>#csrfToken#</cfoutput>">
	<input type="hidden" name="themeId" id="themeId" value="<cfoutput>#URL.optArgs#</cfoutput>">
	<input type="hidden" name="contentTemplateName" id="themeId" value="<cfoutput>#URL.otherArgs#</cfoutput>">
	
	<!--- The external image url will only be present if the user entered a url from an external source. We need to capture this as we don't have any native tinymce method to indicate that an external image was selected and we need to upload it and save it to the datbase. --->
	<input type="hidden" name="externalImageUrl" id="externalImageUrl" value="" />
	<table align="center" class="k-content tableBorder" width="100%" cellpadding="2" cellspacing="0" border="0">
	  	<cfsilent>
			<!---The first content class in the table should be empty. --->
			<cfset thisContentClass = 'k-alt'>
			<!--- Set the colspan property for borders --->
			<cfset thisColSpan = "2">
	  	</cfsilent>		
	  <tr height="1px">
		  <td align="left" valign="top" colspan="2" class="border <cfoutput>#thisContentClass#</cfoutput>"></td>
	  </tr>
	  <tr height="30px">
		<td align="left" class="<cfoutput>#thisContentClass#</cfoutput>" colspan="2"> 
			<cfoutput><b>#label#</b></cfoutput><br/>
			<cfswitch expression="#URL.otherArgs#">
				
				<cfcase value="compositeHeaderDesktop">
					<p>The blog background image will cover the background. Make sure that the image is compressed.</p>
					<p>Note: we are not yet supporting .webp file uploads. Instead upload them manually and link to them. The webp images will also show up as a broken image in the editor unfortunately.</p>
				</cfcase>
				<cfcase value="compositeHeaderMobile">
					<p>The blog background image will cover the background. Make sure that the image is compressed.</p>
					<p>Note: we are not yet supporting .webp file uploads. Instead upload them manually and link to them. The webp images will also show up as a broken image in the editor unfortunately.</p>
				</cfcase>
				<cfcase value="navigationMenuDesktop">
					The menu at the top of the blog is driven by a simple unordered HTML list. The outer bullets drive the menu and indented bullets within a menu option are the submenu's. Make sure that an anchor link surrounds each item in the list.
				</cfcase>
				<cfcase value="navigationMenuMobile">
					The menu at the top of the blog is driven by a simple unordered HTML list. The outer bullets drive the menu and indented bullets within a menu option are the submenu's. Make sure that an anchor link surrounds each item in the list. You will want to test any changes as mobile devices are limited in width.
				</cfcase>
				
			</cfswitch>
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
		<td align="left" class="<cfoutput>#thisContentClass#</cfoutput>" colspan="2">
			<!--- TinyMce container --->
			<div style="position: relative;">
				<textarea id="<cfoutput>#selectorName#</cfoutput>" name="<cfoutput>#selectorName#</cfoutput>"></textarea>
			</div>  
		</td>
	  </tr>
	  <cfsilent>
	  <!--- Set the class for alternating rows. --->
	  <!--- After the first row, the content class should be the current class. --->
	  <cfset thisContentClass = HtmlUtilsObj.getKendoClass(thisContentClass)>
	  </cfsilent>
	  <!-- Border -->
	  <tr height="2px">
		  <td align="left" valign="top" colspan="<cfoutput>#thisColSpan#</cfoutput>" class="border <cfoutput>#thisContentClass#</cfoutput>"></td>
	  </tr>
	  <tr height="2px">
		  <td align="left" valign="top" colspan="2" class="border <cfoutput>#thisContentClass#</cfoutput>"></td>
	  </tr>
	  <script>
		  //$(document).ready(function() {

			// ---------------------------- theme dropdown. ----------------------------
			var contentTemplateThemesDs = new kendo.data.DataSource({
				transport: {
					read: {
						cache: false,
						// Note: since this template is in a different directory, we can't specify the cfc template without the full path name.
						url: function() { // The cfc component which processes the query and returns a json string. 
							return "<cfoutput>#application.baseUrl#</cfoutput>/common/cfc/ProxyController.cfc?method=getThemesForDropdown&includeAllThemes=true&includeAllLabel=true&csrfToken=<cfoutput>#csrfToken#</cfoutput>"; 
						}, 
						dataType: "json",
						contentType: "application/json; charset=utf-8", // Note: when posting json via the request body to a coldfusion page, we must use this content type or we will get a 'IllegalArgumentException' on the ColdFusion processing page.
						type: "GET" //Note: for large payloads coming from the server, use the get method. The post method may fail as it is less efficient.
					}
				} //...transport:
			});//...var themeDs...

			// Create the theme multiselect
			var contentTemplateThemes = $("#contentTemplateThemes").kendoMultiSelect({
				optionLabel: "Select...",
				autoBind: false,
				dataTextField: "ThemeName",
				dataValueField: "ThemeId",
				filter: "contains",
				dataSource: contentTemplateThemesDs,
				value: [<cfoutput>#themeDropdownValue#</cfoutput>]
			}).data("kendoMultiSelect");

		 //});//document.ready  

	  </script>
		  
		<cfif session.isMobile>
		  <tr valign="middle">
			<td class="<cfoutput>#thisContentClass#</cfoutput>" colspan="2">
				<label for="contentTemplateThemes">Theme(s):</label>
			</td>
		   </tr>
		   <tr>
			<td class="<cfoutput>#thisContentClass#</cfoutput>" colspan="2">
				<select id="contentTemplateThemes" name="contentTemplateThemes" data-placeholder="You may select one or more themes..."></select>
			</td>
		  </tr>
		<cfelse><!---<cfif session.isMobile>--->
		  <tr>
			<td align="right" class="<cfoutput>#thisContentClass#</cfoutput>" style="width: 20%"> 
				<label for="contentTemplateThemes">Theme(s):</label>
			</td>
			<td class="<cfoutput>#thisContentClass#</cfoutput>">
				<select id="contentTemplateThemes" name="contentTemplateThemes" data-placeholder="You may select one or more themes..."></select>
			</td>
		  </tr>
		</cfif>	
	  <!-- Border -->
	  <tr height="2px">
		  <td align="left" valign="top" colspan="<cfoutput>#thisColSpan#</cfoutput>" class="border <cfoutput>#thisContentClass#</cfoutput>"></td>
	  </tr>
			
	  <cfsilent>
	  <!--- Set the class for alternating rows. --->
	  <!--- After the first row, the content class should be the current class. --->
	  <cfset thisContentClass = HtmlUtilsObj.getKendoClass(thisContentClass)>
	  </cfsilent>
	  <!-- Border -->
	  <tr height="2px">
		  <td align="left" valign="top" colspan="<cfoutput>#thisColSpan#</cfoutput>" class="border <cfoutput>#thisContentClass#</cfoutput>"></td>
	  </tr>
	  <tr height="2px">
		  <td align="left" valign="top" colspan="2" class="border <cfoutput>#thisContentClass#</cfoutput>"></td>
	  </tr>
	  <!-- Form content -->
	  <tr valign="middle" height="30px">
		<td valign="bottom" align="right" class="<cfoutput>#thisContentClass#</cfoutput>">Apply to Mobile and Desktop</td>
		<td valign="bottom" align="left" class="<cfoutput>#thisContentClass#</cfoutput>">
			<input type="checkbox" name="applyAcrossDevices" id="applyAcrossDevices" value="0">
		</td>
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
		<td valign="bottom" align="right" class="<cfoutput>#thisContentClass#</cfoutput>">&nbsp;</td>
		<td valign="bottom" align="left" class="<cfoutput>#thisContentClass#</cfoutput>">
			<button id="saveContentSubmitButton" name="saveContentSubmitButton" class="k-button k-primary" type="button">Submit</button>
			&nbsp;
			<button id="discardContentButton" name="discardContentButton" class="k-button" type="button" onclick="revertBackToOriginalCode('<cfoutput>#URL.otherArgs#</cfoutput>')">Discard Changes</button>
		</td>
	  </tr>
	</table>
	</form>