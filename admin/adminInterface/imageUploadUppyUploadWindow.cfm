	<!--- Standalone Uppy cropping uploader, opened from inside TinyMCE's own "Insert/Edit Image" dialog (its Upload
	tab) for imageUploader.cfm's generic theme/profile image screens - see the editor.on('OpenWindow', ...) listener
	in includes/templates/js/tinyMce.cfm that wires the tab's click to createAdminInterfaceWindow(76, entityId,
	imageType). Same pattern as enclosureUppyUploadWindow.cfm (window 74) - see that file's own comments and
	[[enclosure-insert-image-upload-tab-uppy-bridge]] for the full design reasoning. URL.optArgs/URL.otherArgs here
	mirror imageUploader.cfm's own usage exactly (optArgs = themeId or userId, otherArgs = the image type/column
	being uploaded, eg. blogBackgroundImage, logoImage, profilePicture). On successful upload, this closes the
	native Insert/Edit Image dialog, itself, and the generic image upload window (imageUploader.cfm's own
	blogUploadSubmit(), same page).

	The actual Uppy setup/event wiring lives in createStandaloneUppyUploadWindow() (includes/templates/blogJsContent.cfm),
	shared across all three bridge windows - this file only computes the handful of values specific to this screen. --->
	<cfset entityId = URL.optArgs>
	<cfset imageType = URL.otherArgs>
	<cfif imageType eq 'profilePicture'>
		<cfset processEntityTypeId = "userId">
	<cfelse>
		<cfset processEntityTypeId = "themeId">
	</cfif>
	<cfset imageHandlerUrl = application.baseUrl & "/common/cfc/ProxyController.cfc?method=uploadImage&mediaProcessType=" & imageType & "&mediaType=image&selectorId=imageUploadEditor&" & processEntityTypeId & "=" & entityId & "&csrfToken=" & csrfToken>

	<div id="standaloneImageUploadUppyUpload" style="padding: 12px;"></div>

	<script>
		createStandaloneUppyUploadWindow({
			containerId: 'standaloneImageUploadUppyUpload',
			endpoint: '<cfoutput>#imageHandlerUrl#</cfoutput>',
			windowSelector: 'imageUploadUppyUploadWindow',
			onComplete: function() { blogUploadSubmit(); }
		});
	</script>
