	<!--- Standalone Uppy cropping uploader, opened from inside TinyMCE's own "Insert/Edit Image" dialog (its Upload
	tab) for a Post/Page video cover image - see the editor.on('OpenWindow', ...) listener in
	includes/templates/js/tinyMce.cfm that wires the tab's click to createAdminInterfaceWindow(75, postId). Same
	pattern as enclosureUppyUploadWindow.cfm (window 74) - see that file's own comments and
	[[enclosure-insert-image-upload-tab-uppy-bridge]] for the full design reasoning. On successful upload, this
	closes the native Insert/Edit Image dialog, itself, and the Video Cover window (videoImageEditor.cfm's own
	onVideoImageCoverSubmit(), same page).

	The actual Uppy setup/event wiring lives in createStandaloneUppyUploadWindow() (includes/templates/blogJsContent.cfm),
	shared across all three bridge windows - this file only computes the handful of values specific to this screen. --->
	<cfset postId = URL.optArgs>
	<cfset imageHandlerUrl = application.baseUrl & "/common/cfc/ProxyController.cfc?method=uploadImage&mediaProcessType=mediaVideoCoverUrl&mediaType=image&postId=" & postId & "&selectorId=videoCoverEditor&csrfToken=" & csrfToken>

	<div id="standaloneVideoCoverUppyUpload" style="padding: 12px;"></div>

	<script>
		createStandaloneUppyUploadWindow({
			containerId: 'standaloneVideoCoverUppyUpload',
			endpoint: '<cfoutput>#imageHandlerUrl#</cfoutput>',
			windowSelector: 'videoCoverUppyUploadWindow',
			onComplete: function() { onVideoImageCoverSubmit(); }
		});
	</script>
