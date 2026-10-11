	<!--- Standalone Uppy cropping uploader, opened from inside TinyMCE's own "Insert/Edit Image" dialog (its Upload
	tab) for a Post/Page enclosure - see the editor.on('OpenWindow', ...) listener in
	includes/templates/js/tinyMce.cfm that wires the tab's click to createAdminInterfaceWindow(74, postId). Per
	direct request (2026-09-27), the native Insert/Edit Image dialog is left open behind this window rather than
	closed, so this file only needs to insert the uploaded image into whichever TinyMCE editor is currently active
	and then close itself - the existing NodeChange listener in tinyMce.cfm (gated on selectorId eq
	'enclosureEditor') already detects the new <img> and calls clearPreviousEditorContent()/saveExternalUrl() exactly
	as it does for a normal TinyMCE-native upload, so none of that needs to be duplicated here. Page Collections
	never reach this file - they have no TinyMCE at all, so URL.optArgs is always a postId here, unlike
	enclosureImageEditor.cfm which branches on isPageCollectionEnclosure.

	The actual Uppy setup/event wiring lives in createStandaloneUppyUploadWindow() (includes/templates/blogJsContent.cfm),
	shared with videoCoverUppyUploadWindow.cfm and imageUploadUppyUploadWindow.cfm - see
	[[enclosure-insert-image-upload-tab-uppy-bridge]] for the full design reasoning. This file only computes the
	handful of values specific to this screen. --->
	<cfset postId = URL.optArgs>
	<cfset imageHandlerUrl = application.baseUrl & "/common/cfc/ProxyController.cfc?method=uploadImage&mediaProcessType=enclosure&mediaType=image&postId=" & postId & "&selectorId=enclosureEditor&csrfToken=" & csrfToken>

	<div id="standaloneEnclosureUppyUpload" style="padding: 12px;"></div>

	<script>
		<!--- The quality slider lives in the parent postEnclosureWindow's own DOM (#imageQualitySlider, rendered by
		enclosureImageEditor.cfm) - this is a separate Kendo window on the same page, not a separate document, so a
		plain jQuery selector reaches it directly with no extra wiring needed. --->
		createStandaloneUppyUploadWindow({
			containerId: 'standaloneEnclosureUppyUpload',
			endpoint: '<cfoutput>#imageHandlerUrl#</cfoutput>',
			windowSelector: 'enclosureUppyUploadWindow',
			qualitySliderSelector: '#imageQualitySlider',
			onComplete: function() { onPostEnclosureSubmit(); }
		});
	</script>
