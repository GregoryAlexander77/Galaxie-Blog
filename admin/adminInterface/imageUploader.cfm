	<!--- Preset the image var --->
	<cfparam name="imageHtml" default="">
	<cfparam name="otherArgs1" default="">
	
	<!--- Set the image html in order for the editor to render the current image. --->
	<cfset imageHtml = '<img src="' & URL.otherArgs1 & '">'>
		
	<!--- This function is used to upload images for the themes and settings.
	The arguments sent to this function in the URL are:
	optArgs: the themeId
	URL.otherArgs: the column that specifies the image that we are working with, ie- blogBackgroundImageMobile
    URL.otherArgs1: the full path of the existing image---> 
	
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
	
	<!---********************* Generic image upload editor *********************--->
	<!--- Set the common vars for tinymce. ---> 
	<cfsilent>
	<cfset selectorId = "imageUploadEditor">
	<cfif session.isMobile>
		<cfset editorHeight = "325">
	<cfelse>
		<cfset editorHeight = "650">
	</cfif>
	
	<!--- We need to pass the theme, user, or page collection ID depending upon the upload type specified from the URL.otherArgs --->
	<cfif URL.otherArgs eq 'profilePicture'>
		<cfset processEntityTypeId = "userId">
	<cfelseif URL.otherArgs eq 'pageCollectionHero'>
		<cfset processEntityTypeId = "pageCollectionId">
	<cfelse>
		<!--- Standard pathway --->
		<cfset processEntityTypeId = "themeId">
	</cfif>
	<!--- This string is used by the tiny mce editor to handle image uploads --->
	<!--- The URL.otherArgs is the process type and the URL optArgs is either the theme or userId --->
	<cfset imageHandlerUrl = application.baseUrl & "/common/cfc/ProxyController.cfc?method=uploadImage&mediaProcessType=" & URL.otherArgs & "&mediaType=image&selectorId=" & selectorId & "&" & processEntityTypeId & "=" & URL.optArgs & "&csrfToken=" & csrfToken> 
	<cfset contentVar = imageHtml>
	<cfset imageMediaIdField = "mediaId">
	<cfset imageClass = "entryImage">

	<!--- PARTIALLY PAUSED 2026-09-26 (per feedback - same pattern already used in enclosureImageEditor.cfm): "image"
	is back in the toolbar, restoring TinyMCE's own native "Insert/Edit Image" dialog. That dialog's own "Upload" tab
	now opens a standalone Uppy popup instead (see includes/templates/js/tinyMce.cfm's OpenWindow listener and
	admin/adminInterface/imageUploadUppyUploadWindow.cfm, window 76) - clicking the image icon no longer shows Uppy
	immediately; it only appears once the admin explicitly clicks Upload inside that dialog. The always-visible
	inline Uppy panel below (still present, just gated off by showInlineUppyPanel, set below) was confusing next to
	the plain TinyMCE editor showing right underneath it, always visible with no need to click anything first.
	"editimage" stays either way - it edits an image already in the content. --->
	<cfset toolbarString = "undo redo | image editimage ">
	<cfset disableVideoCoverAndWebVttButtons = true>
	<cfset showInlineUppyPanel = false>

	</cfsilent>
	<!--- Include the tinymce js template --->
	<cfinclude template="#application.baseUrl#/includes/templates/js/tinyMce.cfm">
	<!---<cfoutput><br/>selectorId: #selectorId#</cfoutput>--->

	<!--- PARTIALLY PAUSED 2026-09-26 - see the toolbarString comment above. Upload an Image - Uppy + its ImageEditor
	plugin (crop/rotate/flip/zoom), the same cropping tool used for galleries/carousels and now the Enclosure Editor
	(see doc/standardizingImageUploadsWithUppy), standardized here too in place of TinyMCE's own plain, no-crop
	insert-image dialog. Single file only. Posts to the exact same imageHandlerUrl endpoint TinyMCE's own upload
	handler already used, so uploadImage()'s existing behavior for whichever mediaProcessType this screen was opened
	for applies unchanged - only how the file reaches that endpoint has changed. metaFields: [] strips Uppy's own
	auto-added name/type meta fields, which uploadImage() (a remote CFC method with a fixed argument list) would
	otherwise reject the whole request over - see the article above for the "does not support type as an argument"
	error this avoids. Change showInlineUppyPanel back to true above to reverse. --->
	<cfif showInlineUppyPanel>
	<script>
		var imageUploaderUppy = Uppy.Core({
			restrictions: {
				maxNumberOfFiles: 1,
				allowedFileTypes: ['image/*']
			}
		})

		.use(Uppy.Dashboard, {
			theme: '<cfoutput>#(darkTheme ? "dark" : "light")#</cfoutput>',
			inline: true,
			target: '#imageUploaderUppyUpload',
			height: 350,
			proudlyDisplayPoweredByUppy: false
		})

		.use(Uppy.Webcam, { target: Uppy.Dashboard })

		.use(Uppy.ImageEditor, {
			target: Uppy.Dashboard,
			quality: 0.8
		})

		.use(Uppy.XHRUpload, {
			fieldName: 'file',
			formData: true,
			bundle: false,
			metaFields: [],
			endpoint: '<cfoutput>#imageHandlerUrl#</cfoutput>'
		});

		imageUploaderUppy.on('upload', function(data) {
			$.when(kendo.ui.ExtWaitDialog.show({ title: "Please wait...", message: "Please wait while the image is uploaded.", icon: "k-ext-information" }));
		});

		var imageUploaderUppyResponse = null;

		imageUploaderUppy.on('upload-success', function(file, response) {
			if (response.body.errorMessage) {
				imageUploaderUppyResponse = null;
				alert("Error: " + response.body.errorMessage);
			} else {
				imageUploaderUppyResponse = response.body;
			}
		});

		imageUploaderUppy.on('upload-error', function(file, error, response) {
			setTimeout(function() { kendo.ui.ExtWaitDialog.hide(); }, 500);
			$.when(kendo.ui.ExtYesNoDialog.show({
				title: "Upload failed",
				message: "The following error was encountered: " + error + ". Do you want to retry the upload?",
				icon: "k-ext-warning",
				width: "<cfoutput>#application.kendoExtendedUiWindowWidth#</cfoutput>",
				height: "215px"
			})).done(function(response) {
				if (response['button'] == 'Yes') {
					imageUploaderUppy.retryUpload(file.id);
				}
			});
		});

		imageUploaderUppy.on('complete', function(result) {
			setTimeout(function() { kendo.ui.ExtWaitDialog.hide(); }, 500);

			if (!imageUploaderUppyResponse) { return; }

			<!--- Same end state TinyMCE's own upload handler already produced - an <img> in the editor content and
			the mediaId hidden field set - blogUploadSubmit() and everything downstream needs no changes. --->
			$("#<cfoutput>#imageMediaIdField#</cfoutput>").val(imageUploaderUppyResponse.mediaId);
			tinymce.get("<cfoutput>#selectorName#</cfoutput>").setContent('<img src="' + imageUploaderUppyResponse.location + '" alt="">');

			<!--- Reset so uploading a second image (replacing this one before Submit) starts clean. --->
			imageUploaderUppy.cancelAll();
			imageUploaderUppyResponse = null;
		});
	</script>
	</cfif>
	<!--- end PARTIALLY PAUSED 2026-09-26 --->

	<script>
		<!--- Note: this function handles enclosure images, videos, theme and user profile images and needs to be changed according to what is being processed. This particular function handles user and theme images. Note: the invokedArguments is not used by CF, but shows the location where this function is being called from and the arguments for debugging purposes. --->
		function saveExternalUrl(url, mediaType, selectorId, invokedArguments){ 
			jQuery.ajax({
				type: 'post', 
				selectorId: '<cfoutput>#selectorId#</cfoutput>',
				url: '<cfoutput>#application.baseUrl#</cfoutput>/common/cfc/ProxyController.cfc?method=saveExternalMediaEnclosure&template=imageUploadEditor',
				dataType: "json",
				data: { // arguments
					csrfToken: '<cfoutput>#csrfToken#</cfoutput>',
					<!--- Pass the mediaId saved in the mediaId hidden form if it is available --->
					mediaId: $("#<cfoutput>#imageMediaIdField#</cfoutput>").val(),
					externalUrl: url,
					<!--- This will either be userId or themeId depending upon the URL.optArgs string --->
					<cfoutput>#processEntityTypeId#</cfoutput>: <cfoutput>#URL.optArgs#</cfoutput>,
					mediaType: 'image',
					imageType: <cfoutput>'#URL.otherArgs#'</cfoutput>,
					selectorId: selectorId,
					invokedArguments: invokedArguments
				},
				error: function(ErrorMsg) {
					console.log('Error' + ErrorMsg);
				}
			<!--- Extract any errors. This is a new jQuery promise based function as of jQuery 1.8. --->
			}).fail(function (jqXHR, textStatus, error) {

				<!--- The full response is: jqXHR.responseText, but we just want to extract the error. --->
				$.when(kendo.ui.ExtAlertDialog.show({ title: "Error while consuming the saveExternalMediaEnclosure function", message: error, icon: "k-ext-error", width: "<cfoutput>#application.kendoExtendedUiWindowWidth#</cfoutput>" }) // or k-ext-error, k-ext-information, k-ext-question, k-ext-warning.  You can also specify height.
					).done(function () {
					<!--- Do nothing --->
				});		
			});
		}
		
		<!--- Submit the data and close this window. --->
		function blogUploadSubmit(){
			setTimeout(function() {			
				<!--- Refresh the theme settings window. Note: this is also used for the user profile images so the window may not be defined --->
				try {
					$("#themeSettingsWindow").data("kendoWindow").refresh();
				} catch(e){
					<!--- Theme setting window is not defined --->
				}
			}, 250);
		<cfif URL.otherArgs eq 'profilePicture'>
			<!--- Do the same for the user detail and user profile windows --->
			setTimeout(function() {
				try {
					<!--- Refresh the user detail window (the main user window) --->
					$("#userDetailWindow").data("kendoWindow").refresh();
					<!--- Refresh the proile window that the secondary user fills out when a new user is added. Note: this is also used for the user profile images so the window may not be defined --->
					$("#userProfileWindow").data("kendoWindow").refresh();
				} catch(e){
					<!--- Window is not defined --->
				}
			}, 250);
		</cfif>
		<cfif URL.otherArgs eq 'pageCollectionHero'>
			<!--- Refresh Configure Page Collections so the new hero image/thumbnail shows up right away, same pattern as above. --->
			setTimeout(function() {
				try {
					$("#configurePageCollectionsWindow").data("kendoWindow").refresh();
				} catch(e){
					<!--- Window is not defined --->
				}
			}, 250);
		</cfif>
			<!--- Close the edit window --->
			$('#genericImageUploadWindow').kendoWindow('destroy');
		}
	</script>
		
	<form id="imageUploadForm" action="#" method="post" data-role="validator">
	<!-- The mediaType will either be an empty string, image or video -->
	<input type="hidden" name="mediaType" id="mediaType" value="image" />
	
	<!--- The external image url will only be present if the user entered a url from an external source. We need to capture this as we don't have any native tinymce method to indicate that an external image was selected and we need to upload it and save it to the datbase. --->
	<input type="hidden" name="externalImageUrl" id="externalImageUrl" value="" />
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
			<cfswitch expression="#URL.otherArgs#">
				<cfcase value="blogBackgroundImage">
					<p>The blog background image will cover the background. Make sure that the image is compressed.</p>
					<p>Note: .webp images can be uploaded. Older browsers that do not support the .webp format will show them as a broken image in the editor.</p>
				</cfcase>
				<cfcase value="blogBackgroundImageMobile">
					The Mobile Blog Background is used to display the background image on mobile devices. This image should be about 1/3rd smaller than the blog background image.
				</cfcase>
				<cfcase value="logoImage">
					The logo image is at the top left of the page.
				</cfcase>
				<cfcase value="logoImageMobile">
					The mobile logo image should be a bit smaller than the desktop version.
				</cfcase>
				<cfcase value="defaultLogoImageForSocialMediaShare">
					For best results, the social media sharing image should be 1200x1200. It can be smaller however it needs to be larger than your normal logo. 
				</cfcase>
				<cfcase value="headerBackgroundImage">
					The header background image covers the menu at the top of the page. You don't need a wide image, the image will be expanded to cover the page.
				</cfcase>
				<cfcase value="menuBackgroundImage">
					The menu background image covers the menu at the top of the page and is only used to prevent ghosting when changing the header background images for the red based themes.
				</cfcase>
				<cfcase value="headerBodyDividerImage">
					The header divider image separates the header from the body content. It should be a couple of pixes tall and around 75 pixels in length. The image will be expanded horizontally to fit the page.
				</cfcase>
				<cfcase value="footerImage">
					The footer image is at the bottom of the page. It typically is a larger version of the icon at the top of the page.
				</cfcase>
				<cfcase value="profilePicture">
					Your profile image should be around 250x250 pixels and use landscape orientation.
				</cfcase>
				<cfcase value="pageCollectionHero">
					The hero image doubles as this Page Collection's icon and its card image wherever the Collection is listed. Only images are supported.
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
	  <!-- Upload an Image (Uppy + cropping) - PARTIALLY PAUSED 2026-09-26, see the toolbarString comment above -->
	  <cfif showInlineUppyPanel>
	  <tr valign="middle">
		<td align="left" class="<cfoutput>#thisContentClass#</cfoutput>" colspan="2" style="padding: 8px 12px 0px;">
			<label>Upload an Image (crop, rotate and flip before it's saved):</label>
		</td>
	  </tr>
	  <tr valign="middle">
		<td align="left" class="<cfoutput>#thisContentClass#</cfoutput>" colspan="2" style="padding: 6px 12px 12px;">
			<div id="imageUploaderUppyUpload"></div>
		</td>
	  </tr>
	  </cfif>
	  <!-- Border -->
	  <tr height="2px">
	    	<td align="left" valign="top" colspan="<cfoutput>#thisColSpan#</cfoutput>" class="<cfoutput>#thisContentClass#</cfoutput>"></td>
	  </tr>
	  <cfsilent>
	  <cfset thisContentClass = HtmlUtilsObj.getKendoClass(thisContentClass)>
	  </cfsilent>
	  <tr height="2px">
		  <td align="left" valign="top" colspan="2" class="border <cfoutput>#thisContentClass#</cfoutput>"></td>
	  </tr>
	  <!-- Form content -->
	  <tr valign="middle" height="30px">
		<td align="left" class="<cfoutput>#thisContentClass#</cfoutput>" colspan="2">
			<!--- TinyMce container - now only used for editing an image already inserted (alt text, dimensions via
			"editimage") - new images come from the Uppy uploader above instead. --->
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
	  <tr height="2px">
		  <td align="left" valign="top" colspan="2" class="border <cfoutput>#thisContentClass#</cfoutput>"></td>
	  </tr>
	  <!-- Form content -->
	  <tr valign="middle" height="30px">
		<td valign="bottom" align="right" class="<cfoutput>#thisContentClass#</cfoutput>" style="width: 20%">&nbsp;</td>
		<td valign="bottom" align="left" class="<cfoutput>#thisContentClass#</cfoutput>">
			<button id="blogUploadComplete" name="blogUploadComplete" class="k-button k-primary" type="button" onClick="javascript:blogUploadSubmit();">Submit</button>
		</td>
	  </tr>
	</table>
	</form>