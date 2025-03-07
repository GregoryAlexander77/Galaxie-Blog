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
	
	<!--- Get the post ( getPostByPostId(postId, showPendingPosts, showRemovedPosts) ) --->
	<cfset getPost = application.blog.getPostByPostId(URL.optArgs,true,true)>
	<!---<cfdump var="#getPost#">--->
		
	<!--- See if there is a local video --->
	<cfif getPost[1]["MediaType"] neq 'Video - Large'>
		<p>Before adding video captions, you must have uploaded a local video. Please upload a video by clicking on the video icon in the editor.</p>
	<cfelse>	
		<!--- Get the current video VTT file location --->
		<cfif len(getPost[1]["MediaVideoVttFileUrl"])>
			<cfset videoVttFileUrl = getPost[1]["MediaVideoVttFileUrl"]>
			<!--- Read the file. We will pass back the WebVtt file contents back to the editor. We are using the paragraph2 function to take the native formattting for the system and turn it into HTML. This handles Mac, Unix, and Windows formatting. --->
			<cftry>
				<cffile action="read" file="#expandPath(videoVttFileUrl)#" variable="fileContent">
			<cfcatch type="any">
				<cfset videoVttFileUrl = "">
				<cfset fileContent = "">
			</cfcatch>
			</cftry>
		<cfelse>
			<cfset videoVttFileUrl = "">
			<cfset fileContent = "">
		</cfif>

		<!--- There are two editors on this page, the WebVtt editor and the Video Cover editor. --->

		<!---********************* WebVTT editor *********************--->
		<cfsilent>
		<!--- Note: the tinymce.cfm template will create a unique selectorName that we need to use in the textarea where we want to place the editor.--->
		<cfset selectorId = "webVttEditor">
		<cfif session.isMobile>
			<cfset editorHeight = "325">
		<cfelse>
			<cfset editorHeight = "650">
		</cfif>
		<!--- This string is used by the tiny mce editor to handle image uploads --->
		<cfset imageHandlerUrl = ""><!--- Images are not available here --->
		<cfset contentVar = application.Udf.paragraphFormat2(fileContent)>
		<cfset imageMediaIdField = ""><!--- Images are not available here --->
		<cfset imageClass = ""><!--- Images are not available here --->

		<cfif session.isMobile>
			<cfset toolbarString = "undo redo | fileUpload ">
		<cfelse>
			<cfset toolbarString = "undo redo | fileUpload ">
		</cfif>
		<cfset pluginList = "'print preview anchor',
			'searchreplace visualblocks code codesample fullscreen',
			'paste iconfonts'">
		<cfset includeGallery = false>
		<cfset includeFileUpload = true>
		</cfsilent>
		<!--- Include the tinymce js template --->
		<cfinclude template="#application.baseUrl#/includes/templates/js/tinyMce.cfm">

		<script>
			$(document).ready(function() {

				// Invoked when the submit button is clicked. Insted of using '$("form").submit(function(event) {' and 'event.preventDefault();', We are using direct binding here to speed up the event.
				var webVttSubmit = $('#webVttSubmit');
				webVttSubmit.on('click', function(e){      
					e.preventDefault();         
					// submit the form.
					saveWebVttFile();
				});
			});//...document.ready

			// Post method on the detail form called from the GalleryDetailFormValidator method on the detail page. The action variable will either be 'update' or 'insert'.
			function saveWebVttFile(){ 
				jQuery.ajax({
					type: 'post', 
					url: '<cfoutput>#application.baseUrl#</cfoutput>/common/cfc/ProxyController.cfc?method=saveFile',
					data: { // arguments
						csrfToken: '<cfoutput>#csrfToken#</cfoutput>',
						file: "<cfoutput>#videoVttFileUrl#</cfoutput>",
						fileContent: tinymce.get("<cfoutput>#selectorName#</cfoutput>").getContent(),
						fileType: 'WebVTT',
						selectorId: '<cfoutput>#selectorId#</cfoutput>'
					},
					dataType: "json",
					success: saveWebVttResponse, // calls the result function.
					error: function(ErrorMsg) {
						console.log('Error' + ErrorMsg);
					}
				// Extract any errors. This is a new jQuery promise based function as of jQuery 1.8.
				}).fail(function (jqXHR, textStatus, error) {

					// The full response is: jqXHR.responseText, but we just want to extract the error.
					$.when(kendo.ui.ExtAlertDialog.show({ title: "Error while consuming the saveFile function", message: error, icon: "k-ext-error", width: "<cfoutput>#application.kendoExtendedUiWindowWidth#</cfoutput>" }) // or k-ext-error, k-ext-information, k-ext-question, k-ext-warning.  You can also specify height.
						).done(function () {
						// Do nothing
					});		
				});
			};

			function saveWebVttResponse(response){
				// Close the webVtt editor window
				jQuery('#webVttFileWindow').kendoWindow('destroy');	
			}

		</script>

		<form id="webVttForm" action="#" method="post" data-role="validator">
		<!--- Pass the csrfToken --->
		<input type="hidden" name="csrfToken" id="csrfToken" value="<cfoutput>#csrfToken#</cfoutput>" />
		<!--- Input for any new videos that have been uploaded --->
		<input type="hidden" name="webVttFile" id="webVttFile" value="" />
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
				A WebVTT file allows you to add captions and subtitles in the video. The WebVTT contains the text "WebVTT" and lines of captions with timestamps. Cascading Style sheets can be used to determine the position and the style of the caption. You can either create or edit an existing WebVTT File, or upload a new file using the upload button below.
				<div id="webVttInstructions" name="webVttInstructions"></div>
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
				<label for="<cfoutput>#selectorName#</cfoutput>">WebVTT Captions</label>
			</td>
		   </tr>
		   <tr>
			<td class="<cfoutput>#thisContentClass#</cfoutput>" colspan="2">
				<textarea id="<cfoutput>#selectorName#</cfoutput>" name="<cfoutput>#selectorName#</cfoutput>"></textarea> 
			</td>
		  </tr>
		<cfelse><!---<cfif session.isMobile>--->
		  <tr valign="middle" height="30px">
			<td align="right" valign="middle" class="<cfoutput>#thisContentClass#</cfoutput>" width="20%">
				<label for="<cfoutput>#selectorName#</cfoutput>">WebVTT Captions</label>
			</td>
			<td align="left" class="<cfoutput>#thisContentClass#</cfoutput>">
				<textarea id="<cfoutput>#selectorName#</cfoutput>" name="<cfoutput>#selectorName#</cfoutput>"></textarea>
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
				<button id="webVttSubmit" name="webVttSubmit" class="k-button k-primary" type="button">Submit</button>
			</td>
		  </tr>
		</table>
		</form>
	</cfif>		