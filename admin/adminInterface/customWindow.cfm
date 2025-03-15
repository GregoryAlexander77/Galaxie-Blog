	<!--- Debugging
	<cfdump var="#url#">
	<cfoutput>
		postId (URL.optArgs): #URL.optArgs#<br/>
		windowId (URL.otherArgs): #URL.otherArgs#<br/>
		isNumeric(URL.otherArgs): #isNumeric(URL.otherArgs)#<br/>
	</cfoutput>
	--->
	
	<!--- Instantiate the Render.cfc. This will be used to render our directives and create video and map thumbnails --->
	<cfobject component="#application.rendererComponentPath#" name="RendererObj">
		
	<!--- Get all custom windows for this post. --->
	<cfset getCustomWindows = application.blog.getCustomWindowContent(URL.optArgs)>
	<!---<cfdump var="#getCustomWindows#">--->
		
	<style>
		label {
			font-weight: normal;
		}

		normalFontWeight {
			font-weight: normal;
		}
	</style>
		
	<cfif arrayLen(getCustomWindows) gt 0 and not isNumeric(URL.otherArgs)>
		
		<script>
			function openCustomWindowInterface(windowId){
				// Get the selected windowId
				windowId = $('input[name="customWindowId"]:checked').val();
				// alert(windowId);
				// Create a new custom window if no radio button was clicked
				if (typeof windowId === 'undefined'){
					// alert(0);
					windowId = 0;
				}
				// Close this window 
				$('#customWindow').kendoWindow('destroy');
				// Direct the user to the detail page. The windowId is either the selected customWindowId or zero (optArgs), the last arg (otherArgs) is the postId.
				createAdminInterfaceWindow(45,<cfoutput>#URL.optArgs#</cfoutput>,windowId);
			}

		</script>
	
		<!---//***************************************************************************************************************
					Custom Window Picker 
		//****************************************************************************************************************--->
		
		<table align="center" class="k-content" width="100%" cellpadding="2" cellspacing="0">
		  <cfsilent>
			<!---The first content class in the table should be empty. --->
			<cfset thisContentClass = HtmlUtilsObj.getKendoClass('')>
			<!--- Set the colspan property for borders --->
			<cfset thisColSpan = "2">
		  </cfsilent>
		  <tr height="1px">
			  <td align="left" valign="top" colspan="2" class="<cfoutput>#thisContentClass#</cfoutput>">
				Please choose the custom window that you want to edit.
			  </td>
		  </tr>
		  <cfsilent>
		  <!--- Set the class for alternating rows. --->
		  <!--- After the first row, the content class should be the current class. --->
		  <cfset thisContentClass = HtmlUtilsObj.getKendoClass(thisContentClass)>
		  </cfsilent>
		  <!-- Border -->
		  <tr height="2px">
			  <td align="left" valign="top" colspan="<cfoutput>#thisColSpan#</cfoutput>" class="<cfoutput>#thisContentClass#</cfoutput>"></td>
		  </tr>
		  <tr>
		  <tr valign="middle">
			<td align="right" class="<cfoutput>#thisContentClass#</cfoutput>" style="width: 7%"> 
				<input type="radio" id="customWindowId" name="customWindowId" value="0">
			</td>
			<td class="<cfoutput>#thisContentClass#</cfoutput>">
				<label for="buttonLabel">Create New Custom Window</label>
			</td>
		  </tr>
		  <!-- Border -->
		  <tr height="2px">
			  <td align="left" valign="top" colspan="<cfoutput>#thisColSpan#</cfoutput>" class="<cfoutput>#thisContentClass#</cfoutput>"></td>
		  </tr>
		<!--- Loop through the windows to allow the user to select the window that they want to edit --->
		<cfloop from="1" to="#arrayLen(getCustomWindows)#" index="i">
		  <cfsilent>
		  <cfset customWindowId = getCustomWindows[i]['CustomWindowContentId']>
		  <cfset title = getCustomWindows[i]['WindowTitle']>
		  <!--- Set the class for alternating rows. --->
		  <!--- After the first row, the content class should be the current class. --->
		  <cfset thisContentClass = HtmlUtilsObj.getKendoClass(thisContentClass)>
		  </cfsilent>
		  <!-- Border -->
		  <tr height="2px">
			  <td align="left" valign="top" colspan="<cfoutput>#thisColSpan#</cfoutput>" class="<cfoutput>#thisContentClass#</cfoutput>"></td>
		  </tr>
		  <tr>
		  <tr valign="middle">
			<td align="right" class="<cfoutput>#thisContentClass#</cfoutput>" style="width: 7%"> 
				<input type="radio" id="customWindowId" name="customWindowId" value="<cfoutput>#customWindowId#</cfoutput>">
			</td>
			<td class="<cfoutput>#thisContentClass#</cfoutput>">
				<label for="buttonLabel"><cfoutput>#title#</cfoutput></label>
			</td>
		  </tr>
		  <!-- Border -->
		  <tr height="2px">
			  <td align="left" valign="top" colspan="<cfoutput>#thisColSpan#</cfoutput>" class="<cfoutput>#thisContentClass#</cfoutput>"></td>
		  </tr>
		</cfloop>
		<cfsilent>
		  <!--- Set the class for alternating rows. --->
		  <!---After the first row, the content class should be the current class. --->
		  <cfset thisContentClass = HtmlUtilsObj.getKendoClass(thisContentClass)>
		  </cfsilent>
		  <!-- Border -->
		  <tr height="2px">
			<td align="left" valign="top" colspan="<cfoutput>#thisColSpan#</cfoutput>" class="<cfoutput>#thisContentClass#</cfoutput>"></td>
		  </tr>
		  <!-- Form content -->
		  <tr valign="middle" height="30px">
			<td valign="bottom" align="right" class="<cfoutput>#thisContentClass#</cfoutput>">&nbsp;</td>
			<td valign="bottom" align="left" class="<cfoutput>#thisContentClass#</cfoutput>">
				<!--- The onPostThemeSubmit changes a dropdown in the post detail page. It does not trigger the saving of the theme. The save function is invoked using on onPostThemeSubmit js function --->
				<button id="customWindowPickerSubmit" name="customWindowPickerSubmit" class="k-button k-primary" type="button" onClick="openCustomWindowInterface()">Submit</button>
			</td>
		  </tr>
		</table>
		  
	<cfelse>
		
		<!---//***************************************************************************************************************
					Custom Window Detail 
		//****************************************************************************************************************--->
		
		<!---<cfdump var="#URL#">--->
		<!--- Get the content detail ( ( getCustomWindowContentById(customWindowId) ) ). Note: the postId here is URL.otherArgs --->
		<cfif isDefined("URL.otherArgs") and isNumeric(URL.otherArgs)>
			<cfset getCustomWindowContent = application.blog.getCustomWindowContentById(URL.otherArgs)>
			<cfset otherArgs = URL.otherArgs>
		<cfelse>
			<cfif arrayLen(getCustomWindows) eq 1>
				<!--- If there is only record in the getCustomWindows query, get the result --->
				<cfset getCustomWindowContent = application.blog.getCustomWindowContentById(getCustomWindows[1]["CustomWindowContentId"])>
				<cfset otherArgs = getCustomWindows[1]["CustomWindowContentId"]>
			<cfelse>
				<!--- This is a new record for the post. --->
				<cfset otherArgs = 0>
				<cfset getCustomWindowContent = application.blog.getCustomWindowContentById(0)>
			</cfif>
		</cfif>
		<!---<cfdump var="#getCustomWindowContent#">--->

		<!--- Get the Content if it exists --->
		<cfif arrayLen(getCustomWindowContent)>
			<cfset buttonLabel = getCustomWindowContent[1]["ButtonLabel"]>
			<cfset windowTitle = getCustomWindowContent[1]["WindowTitle"]>
			<cfset windowHeight = getCustomWindowContent[1]["WindowHeight"]>
			<cfset windowWidth = getCustomWindowContent[1]["WindowWidth"]>
			<cfset cfincludePath = getCustomWindowContent[1]["CfincludePath"]>
			<cfset content = getCustomWindowContent[1]["Content"]>
		<cfelse>
			<cfset buttonLabel = "">
			<cfset windowTitle = "">
			<cfset windowHeight = "">
			<cfset windowWidth = "">
			<cfset cfincludePath = "">
			<cfset content = "">
		</cfif>
		<!--- Determine the existing unit of measure. Will use pixels if nothing is present --->
		<cfif windowWidth contains '%'>
			<cfset userMeasurement = '%'>
		<cfelse>
			<cfset userMeasurement = 'px'>
		</cfif>
				
		<!---//***************************************************************************************************************
					TinyMce Scripts
		//****************************************************************************************************************--->

		<!---********************* Custom Content editor *********************--->
		<!--- Set the common vars for tinymce. --->
		<cfsilent>
		<cfset selectorId = "customWindowEditor">
		<cfif smallScreen>
			<cfset editorHeight = "600">
		<cfelse>
			<cfset editorHeight = "650">
		</cfif>
		<!--- This string is used by the tiny mce editor to handle image uploads --->
		<cfset imageHandlerUrl = application.baseUrl & "/common/cfc/ProxyController.cfc?method=uploadImage&mediaProcessType=post&mediaType=image&postId=" & URL.optArgs & "&selectorId=" & selectorId & "&csrfToken=" & csrfToken>
		<cfset contentVar = content><!---EncodeForHTMLAttribute--->
		<cfset imageMediaIdField = "imageMediaId">
		<cfset imageClass = "entryImage">

		<cfif smallScreen>
			<cfset toolbarString = "undo redo | bold italic | link | image media fancyBoxGallery">
		<cfelse>
			<cfset toolbarString = "insertfile undo redo | styleselect | bold italic | alignleft aligncenter alignright alignjustify | bullist numlist outdent indent | tox | hr | link | image editimage | media | fancyBoxGallery | map mapRouting | customWindow | emoticons">
		</cfif>
		<cfset includeGallery = true>
		<cfset includeCustomWindow = true>
		</cfsilent>

		<!--- Include the tinymce js template --->
		<cfinclude template="#application.baseUrl#/includes/templates/js/tinyMce.cfm">

		<script>
			
			// Numeric inputs
			$("#contentWidth").kendoNumericTextBox({
				decimals: 0,
				round: true
			});

			$("#mainContainerWidth").kendoNumericTextBox({
				decimals: 0,
				round: true
			});
			
			$(document).ready(function() {
				
				// !!! Note on the validators, all forms need a name attribute, otherwise the positioning of the messages will not work. --->
				var customWindowValidater = $("#customWindowForm").kendoValidator({
					// Set up custom validation rules 
					rules: {
						// buttonLabel
						buttonLabelRequired:
						function(input){
							if (input.is("[id='buttonLabel']") && $.trim(input.val()).length < 3){
								// Display an error on the page.
								input.attr("data-buttonLabelRequired-msg", "The label must be at least 3 characters");
								// Focus on the current element
								$( "#buttonLabel" ).focus();
								return false;
							}                                    
							return true;
						},
						// windowTitle
						windowTitleRequired:
						function(input){
							if (input.is("[id='windowTitle']") && $.trim(input.val()).length < 3){
								// Display an error on the page.
								input.attr("data-windowTitleRequired-msg", "The title must be at least 3 characters");
								// Focus on the current element
								$( "#password" ).focus();
								return false;
							}                                    
							return true;
						},
					}
				}).data("kendoValidator");
				
				// Invoked when the submit button is clicked. Insted of using '$("form").submit(function(event) {' and 'event.preventDefault();', We are using direct binding here to speed up the event.
				var customWindowSubmit = $('#customWindowSubmit');
				customWindowSubmit.on('click', function(e){      
					e.preventDefault();         
					if (customWindowValidater.validate()) {
						
						if ( !($('#active').is(':checked')) ) {
							// Raise a warning if the active checkbox is not checked
							// Note: this is a custom library that I am using. The ExtAlertDialog is not a part of Kendo but an extension.
							$.when(kendo.ui.ExtYesNoDialog.show({ 
								title: "Remove Window?",
								message: "Are you sure? This will remove this window from the blog",
								icon: "k-ext-warning",
								width: "<cfoutput>#application.kendoExtendedUiWindowWidth#</cfoutput>", 
								height: "215px"
							})
							).done(function (response) { // If the user clicked 'yes', post it.
								if (response['button'] == 'Yes'){// remember that js is case sensitive.
									// Post it
									postCustomWindowDetail();
								}//..if (response['button'] == 'Yes'){
							});
						} else {
							// submit the form.
							postCustomWindowDetail();
						}
						
					} else {
						$.when(kendo.ui.ExtAlertDialog.show({ title: "There are errors", width: "<cfoutput>#application.kendoExtendedUiWindowWidth#</cfoutput>", message: "Required fields are missing.", icon: "k-ext-warning" }) // or k-ext-error, k-ext-question
							).done(function () {
							// Do nothing
						});
					}
				});
				
			});//...document.ready
					
			function setActiveContentField(field){
				if (field == 'customWindowEditor'){
					$("#customWindowEditor").attr('disabled', false);
					$("#cfincludePath").attr('disabled', true);
				} else {
					$("#cfincludePath").attr('disabled', false);
					$("#customWindowEditor").attr('disabled', true);
				}
			}
			
			function postCustomWindowDetail(){
				
				// Get the contents of the editor
				var customWindowCode = tinymce.get("<cfoutput>#selectorName#</cfoutput>").getContent();
				// Modify any tags that may be deleted by ColdFusion on the server when using Global Script Protection and place an attach string in front of scripts, styles and meta tags.
				customWindowCode = bypassScriptProtection(customWindowCode);

				jQuery.ajax({
					type: 'post', 
					url: '<cfoutput>#application.baseUrl#</cfoutput>/common/cfc/ProxyController.cfc?method=saveCustomWindow&csrfToken=<cfoutput>#csrfToken#</cfoutput>',
					data: { // arguments
						postId: $("#postId").val(),
						customWindowId: $("#customWindowId").val(),
						buttonLabel: $("#buttonLabel").val(),
						windowTitle: $("#windowTitle").val(),
						unitMeasurement: $("input[id=unitMeasurement]:checked").val(),
						windowHeight: $("#windowHeight").val(),
						windowWidth: $("#windowWidth").val(),
						cfincludePath: $("#cfincludePath").val(),
						windowContent: customWindowCode,
						active: $('#active').is(':checked'), // checkbox boolean value.
						selectorId: '<cfoutput>#selectorId#</cfoutput>'
					},
					// This is one of the few times that we will be sending back an html response. We are going to use this directly to set the content in the editor. its easier to craft the html on the server side than to manipulate the dom with a json object on the client. Normally this is always json
					dataType: "json",
					success: customWindowDetailResult, // calls the result function.
					error: function(ErrorMsg) {
						console.log('Error' + ErrorMsg);
					}
				// Extract any errors. This is a new jQuery promise based function as of jQuery 1.8.
				}).fail(function (jqXHR, textStatus, error) {
					// Close the wait window that was launched in the calling function.
					kendo.ui.ExtWaitDialog.hide();
					// Display the error. The full response is: jqXHR.responseText, but we just want to extract the error.
					$.when(kendo.ui.ExtAlertDialog.show({ title: "Error while consuming the saveCustomWindow function", message: error, icon: "k-ext-error", width: "<cfoutput>#application.kendoExtendedUiWindowWidth#</cfoutput>" }) // or k-ext-error, k-ext-information, k-ext-question, k-ext-warning.  You can also specify height.
						).done(function () {

					});		
				});
			};
			
			function customWindowDetailResult(response){

				// Did the server successfully process this?
				if (JSON.parse(response.success) == true){
					// Is it active?
					 if ($('#active').is(':checked')){
						// Get the titleAlias from the response. This will be appended to the URL to make the link
						titleAlias = JSON.parse(JSON.stringify(response.titleAlias));
						// To set content, typically get use the tinymce.activeEditor. However, this will not work since there are now two active editors (this one and the post editor). We need to use the editor name to set the content. The post editor name is set using the minute and seconds appended to a 'postEditor' string, and we write a cookie when we create it to get to the proper name. Get this name
						postEditorName = <cfoutput>'#evaluate("cookie.postEditor")#'</cfoutput>;
						// Insert the content into the active tinymce editor. The response is json coming from the server
						tinymce.get(postEditorName).insertContent(JSON.parse(JSON.stringify(response.buttonHtml)));
						// Display the link to the user
						$.when(kendo.ui.ExtAlertDialog.show({ title: "Your window has been created", message: 'A button has been placed in the editor to launch your custom window. You can get the source code by clicking on view source and copying the HTML. This HTML can be placed anywhere on the blog. The following link can also be used to open up your custom window:<br/> <cfoutput>#application.blogHostUrl#</cfoutput>/?customWindow=' + titleAlias, icon: "k-ext-information", width: "<cfoutput>#application.kendoExtendedUiWindowWidth#</cfoutput>", height: "325px" }) // or k-ext-error, k-ext-question
						).done(function () {
							// Do nothing
						});
					 }//..if ($('#active').is(':checked')){
					// Close this window.
					$('#customWindow').kendoWindow('destroy');
				} else {
					// Alert the user that the login has failed.
					$.when(kendo.ui.ExtAlertDialog.show({ title: "Error saving post", message: response.errorMessage, icon: "k-ext-warning", width: "<cfoutput>#application.kendoExtendedUiWindowWidth#</cfoutput>", height: "125px" }) // or k-ext-error, k-ext-question
					).done(function () {
						// Do nothing
					});
					
				}//..if (JSON.parse(response.error) == true){
			}
		
		</script>
			
		<form id="customWindowForm" action="#" method="post" data-role="validator">
		<!--- Pass the postId and customWindowId --->
		<input type="hidden" id="postId" name="postId" value="<cfoutput>#URL.optArgs#</cfoutput>">
		<input type="hidden" id="customWindowId" name="customWindowId" value="<cfoutput>#otherArgs#</cfoutput>">
		<table align="center" class="k-content" width="100%" cellpadding="2" cellspacing="0">
		  <cfsilent>
			<!---The first content class in the table should be empty. --->
			<cfset thisContentClass = HtmlUtilsObj.getKendoClass('')>
			<!--- Set the colspan property for borders --->
			<cfset thisColSpan = "2">
		  </cfsilent>

		  <tr height="1px">
			  <td align="left" valign="top" colspan="2" class="<cfoutput>#thisContentClass#</cfoutput>">
				This interface will create a button to launch a window. The custom window can use a ColdFusion include (cfinclude) or you can use the editor to create the window content for you. However, you can only use one of these options, either a cfinclude or the WYSIWYG editor. 

				If you use a ColdFusion include, you must upload your include to the server and set the path below. Custom cfincludes may require a function or cfc to handle server operations.
			  </td>
		  </tr>
		  <cfsilent>
		  <!--- Set the class for alternating rows. --->
		  <!---After the first row, the content class should be the current class. --->
		  <cfset thisContentClass = HtmlUtilsObj.getKendoClass(thisContentClass)>
		  </cfsilent>
		  <!-- Border -->
		  <tr height="2px">
			  <td align="left" valign="top" colspan="<cfoutput>#thisColSpan#</cfoutput>" class="<cfoutput>#thisContentClass#</cfoutput>"></td>
		  </tr>
		  <tr>
		<tr valign="middle" height="30px">
			<td valign="bottom" align="left" class="<cfoutput>#thisContentClass#</cfoutput>" colspan="<cfoutput>#thisColSpan#</cfoutput>">
				The button label is the string that will show on the button that is automatically inserted.
			</td>
		  </tr>
		<cfif session.isMobile>
		  <tr valign="middle">
			<td class="<cfoutput>#thisContentClass#</cfoutput>" colspan="2">
				<label for="buttonLabel">Button Label:</label>
			</td>
		   </tr>
		   <tr>
			<td class="<cfoutput>#thisContentClass#</cfoutput>" colspan="2">
				<input id="buttonLabel" name="buttonLabel" type="text" value="<cfoutput>#buttonLabel#</cfoutput>" class="k-textbox" style="width: 95%" maxlength="125" required />    
			</td>
		  </tr>
		<cfelse><!---<cfif session.isMobile>--->
			<td align="right" class="<cfoutput>#thisContentClass#</cfoutput>" style="width: 25%"> 
				<label for="buttonLabel">Button Label:</label>
			</td>
			<td class="<cfoutput>#thisContentClass#</cfoutput>">
				<input id="buttonLabel" name="buttonLabel" type="text" value="<cfoutput>#buttonLabel#</cfoutput>" class="k-textbox" style="width: 95%" maxlength="125" required />  
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
		  <tr valign="middle" height="30px">
			<td valign="bottom" align="left" class="<cfoutput>#thisContentClass#</cfoutput>" colspan="<cfoutput>#thisColSpan#</cfoutput>">
				The window title is the title that will show at the top of the custom window. Keep this name relatively short for mobile clients. 
			</td>
		  </tr>
		  <tr height="1px">
			  <td align="left" valign="top" colspan="2" class="border <cfoutput>#thisContentClass#</cfoutput>"></td>
		  </tr>
		<cfif session.isMobile>
		  <tr valign="middle">
			<td class="<cfoutput>#thisContentClass#</cfoutput>" colspan="2">
				<label for="windoTitle">Window Title</label>
			</td>
		   </tr>
		   <tr>
			<td class="<cfoutput>#thisContentClass#</cfoutput>" colspan="2">
				<input id="windowTitle" name="windowTitle" type="text" value="<cfoutput>#windowTitle#</cfoutput>" class="k-textbox" style="width: 95%" maxlength="125" required />
			</td>
		  </tr>
		<cfelse><!---<cfif session.isMobile>--->
		  <tr valign="middle" height="30px">
			<td valign="bottom" align="right" class="<cfoutput>#thisContentClass#</cfoutput>" style="width:20%">
				<label for="windoTitle">Window Title</label>
			</td>
			<td valign="bottom" align="left" class="<cfoutput>#thisContentClass#</cfoutput>" style="width:80%">
				<input id="windowTitle" name="windowTitle" type="text" value="<cfoutput>#windowTitle#</cfoutput>" class="k-textbox" style="width: 95%" maxlength="125" required />
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
		  <tr valign="middle" height="30px">
			<td valign="bottom" align="left" class="<cfoutput>#thisContentClass#</cfoutput>" colspan="<cfoutput>#thisColSpan#</cfoutput>">
				You can use pixels or percent to control the height and width of the window. If you use percent it will use the screen size as the container.
			</td>
		  </tr>
		  <tr height="1px">
			  <td align="left" valign="top" colspan="2" class="border <cfoutput>#thisContentClass#</cfoutput>"></td>
		  </tr>
		<cfif session.isMobile>
		  <tr valign="middle">
			<td class="<cfoutput>#thisContentClass#</cfoutput>" colspan="2">
				<label for="unitMeasurement">Unit Measurement:</label>
			</td>
		   </tr>
		   <tr>
			<td class="<cfoutput>#thisContentClass#</cfoutput>" colspan="2">
				<input type="radio" id="unitMeasurement" name="unitMeasurement" value="px" <cfif userMeasurement eq 'px'>checked</cfif>> Pixels <input type="radio" id="unitMeasurement" name="unitMeasurement" value="%" <cfif userMeasurement eq '%'>checked</cfif>> Percent
			</td>
		  </tr>
		<cfelse><!---<cfif session.isMobile>--->
		  <tr valign="middle" height="30px">
			<td valign="center" align="right" class="<cfoutput>#thisContentClass#</cfoutput>">
				<label for="unitMeasurement">Unit Measurement:</label>
			</td>
			<td valign="bottom" align="left" class="<cfoutput>#thisContentClass#</cfoutput>">
				<input type="radio" id="unitMeasurement" name="unitMeasurement" value="px" <cfif userMeasurement eq 'px'>checked</cfif>> Pixels <input type="radio" id="unitMeasurement" name="unitMeasurement" value="%" <cfif userMeasurement eq '%'>checked</cfif>> Percent
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
		  <tr valign="middle" height="30px">
			<td valign="bottom" align="left" class="<cfoutput>#thisContentClass#</cfoutput>" colspan="<cfoutput>#thisColSpan#</cfoutput>">
				The window width and height control the window size in percent. On mobile and smaller clients the windows will take 95% of the width of the device.
			</td>
		  </tr>
		  <tr height="1px">
			  <td align="left" valign="top" colspan="2" class="border <cfoutput>#thisContentClass#</cfoutput>"></td>
		  </tr>
		<cfif session.isMobile>
		  <tr valign="middle">
			<td class="<cfoutput>#thisContentClass#</cfoutput>" colspan="2">
				<label for="windowHeight">Window Height:</label>
			</td>
		   </tr>
		   <tr>
			<td class="<cfoutput>#thisContentClass#</cfoutput>" colspan="2">
				<input type="number" id="windowHeight" name="windowHeight" value="<cfoutput>#windowHeight#</cfoutput>" class="k-textbox" >
			</td>
		  </tr>
		<cfelse><!---<cfif session.isMobile>--->
		  <tr valign="middle" height="30px">
			<td valign="center" align="right" class="<cfoutput>#thisContentClass#</cfoutput>">
				<label for="windowHeight">Window Height:</label>
			</td>
			<td valign="bottom" align="left" class="<cfoutput>#thisContentClass#</cfoutput>">
				<input type="number" id="windowHeight" name="windowHeight" value="<cfoutput>#windowHeight#</cfoutput>" class="k-textbox" >
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
				<label for="windowWidth">Window Width:</label>
			</td>
		   </tr>
		   <tr>
			<td class="<cfoutput>#thisContentClass#</cfoutput>" colspan="2">
				<input type="number" id="windowWidth" name="windowHeight" value="<cfoutput>#windowWidth#</cfoutput>" class="k-textbox" >
			</td>
		  </tr>
		<cfelse><!---<cfif session.isMobile>--->
		  <tr valign="middle" height="30px">
			<td valign="center" align="right" class="<cfoutput>#thisContentClass#</cfoutput>">
				<label for="windowWidth">Window Width:</label>
			</td>
			<td valign="bottom" align="left" class="<cfoutput>#thisContentClass#</cfoutput>">
				<input type="number" id="windowWidth" name="windowHeight" value="<cfoutput>#windowWidth#</cfoutput>" class="k-textbox" >
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
			  <td align="left" valign="bottom" colspan="2" class="border <cfoutput>#thisContentClass#</cfoutput>"></td>
		  </tr>
		  <tr valign="middle" height="30px">
			<td valign="bottom" align="left" class="<cfoutput>#thisContentClass#</cfoutput>" colspan="<cfoutput>#thisColSpan#</cfoutput>">
				A cfinclude is a ColdFusion include programmed using the ColdFusion markup or cfscript langauge. You can also use plain Javascript or HTML. You must upload the template to the server and have the path to the location for this to work. Use the editor below if you want to use a WYSIWYG interface.
			</td>
		  </tr>
		  <tr height="1px">
			  <td align="left" valign="top" colspan="2" class="border <cfoutput>#thisContentClass#</cfoutput>"></td>
		  </tr>
		<cfif session.isMobile>
		  <tr valign="middle">
			<td class="<cfoutput>#thisContentClass#</cfoutput>" colspan="2">
				<label for="cfincludePath">Cfinclude Path:</label>
			</td>
		   </tr>
		   <tr>
			<td class="<cfoutput>#thisContentClass#</cfoutput>" colspan="2">
				<input type="text" name="cfincludePath" id="cfincludePath" value="<cfoutput>#cfincludePath#</cfoutput>" class="k-textbox" style="width: 95%" onClick="setActiveContentField('cfincludePath');" />
			</td>
		  </tr>
		<cfelse><!---<cfif session.isMobile>--->
		  <tr valign="middle" height="30px">
			<td valign="center" align="right" class="<cfoutput>#thisContentClass#</cfoutput>">
				<label for="cfincludePath">Cfinclude Path:</label>
			</td>
			<td valign="bottom" align="left" class="<cfoutput>#thisContentClass#</cfoutput>">
				<input type="text" name="cfincludePath" id="cfincludePath" value="<cfoutput>#cfincludePath#</cfoutput>" class="k-textbox" style="width: 95%" onClick="setActiveContentField('cfincludePath');" />
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
		<cfif session.isMobile>
		  <tr valign="middle">
			<td class="<cfoutput>#thisContentClass#</cfoutput>" colspan="2">
				<label for="windowContent">Content:</label>
			</td>
		   </tr>
		   <tr>
			<td class="<cfoutput>#thisContentClass#</cfoutput>" colspan="2">
				<input type="text" id="<cfoutput>#selectorName#</cfoutput>" name="<cfoutput>#selectorName#</cfoutput>" onClick="setActiveContentField('cfincludePath')" />
			</td>
		  </tr>
		<cfelse><!---<cfif session.isMobile>--->
		  <tr valign="middle" height="30px">
			<td valign="center" align="right" class="<cfoutput>#thisContentClass#</cfoutput>">
				<label for="windowContent">Content:</label>
			</td>
			<td valign="bottom" align="left" class="<cfoutput>#thisContentClass#</cfoutput>">
				<input type="text" id="<cfoutput>#selectorName#</cfoutput>" name="<cfoutput>#selectorName#</cfoutput>" onClick="setActiveContentField('cfincludePath')" />
			</td>
		  </tr>
		</cfif>
		  <cfsilent>
		  <!--- Set the class for alternating rows. --->
		  <!---After the first row, the content class should be the current class. --->
		  <cfset thisContentClass = HtmlUtilsObj.getKendoClass(thisContentClass)>
		  </cfsilent>
		  <tr height="2px">
			<td align="left" valign="bottom" colspan="2" class="border <cfoutput>#thisContentClass#</cfoutput>"></td>
		  </tr>
		  <tr valign="middle" height="30px">
			<td valign="bottom" align="left" class="<cfoutput>#thisContentClass#</cfoutput>" colspan="<cfoutput>#thisColSpan#</cfoutput>">
				Unchecking the active checkbox will remove the listener from the main blog page and disable the window. Please manually delete all of the buttons that you may have placed to launch this window.
			</td>
		  </tr>
		  <tr height="1px">
			  <td align="left" valign="top" colspan="2" class="border <cfoutput>#thisContentClass#</cfoutput>"></td>
		  </tr>
		<cfif session.isMobile>
		  <tr valign="middle">
			<td class="<cfoutput>#thisContentClass#</cfoutput>" colspan="2">
				<label for="active">Active</label>
			</td>
		   </tr>
		   <tr>
			<td class="<cfoutput>#thisContentClass#</cfoutput>" colspan="2">
				<input type="checkbox" name="active" id="active" checked>
			</td>
		  </tr>
		<cfelse><!---<cfif session.isMobile>--->
		  <tr valign="middle" height="30px">
			<td valign="bottom" align="right" class="<cfoutput>#thisContentClass#</cfoutput>" style="width:20%">
				<label for="active">Active</label>
			</td>
			<td valign="bottom" align="left" class="<cfoutput>#thisContentClass#</cfoutput>" style="width:80%">
				<input type="checkbox" name="active" id="active" checked>
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
		  <!-- Border -->
		  <tr height="2px">
			<td align="left" valign="top" colspan="<cfoutput>#thisColSpan#</cfoutput>" class="<cfoutput>#thisContentClass#</cfoutput>"></td>
		  </tr>
		  <!-- Form content -->
		  <tr valign="middle" height="30px">
			<td valign="bottom" align="right" class="<cfoutput>#thisContentClass#</cfoutput>">&nbsp;</td>
			<td valign="bottom" align="left" class="<cfoutput>#thisContentClass#</cfoutput>">
				<!--- The onPostThemeSubmit changes a dropdown in the post detail page. It does not trigger the saving of the theme. The save function is invoked using on onPostThemeSubmit js function --->
				<button id="customWindowSubmit" name="customWindowSubmit" class="k-button k-primary" type="button">Submit</button>
			</td>
		  </tr>

		</table>
		</form>
		
	</cfif>