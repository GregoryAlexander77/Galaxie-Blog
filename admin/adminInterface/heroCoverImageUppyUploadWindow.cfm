<!--- Standalone Uppy cropping uploader, opened from inside TinyMCE's own "Insert/Edit Image" dialog (its Upload
tab) for the Hero Cover Image editor (window 80, heroCoverImageEditor.cfm) - see the editor.on('OpenWindow', ...)
listener in includes/templates/js/tinyMce.cfm that wires the tab's click to createAdminInterfaceWindow(81,
postId). Same "own browsing context, own JS" shared bridge enclosureUppyUploadWindow.cfm/
videoCoverUppyUploadWindow.cfm already use - see those files' own comments for the full design reasoning.
2026-10-01. --->
<cfset postId = URL.optArgs>
<cfset imageHandlerUrl = application.baseUrl & "/common/cfc/ProxyController.cfc?method=uploadImage&mediaProcessType=heroCoverImage&mediaType=image&postId=" & postId & "&selectorId=heroCoverImageEditor&csrfToken=" & csrfToken>

<div id="standaloneHeroCoverImageUppyUpload" style="padding: 12px;"></div>

<script>
	<!--- The quality slider lives in the parent heroCoverImageWindow's own DOM (#imageQualitySlider, rendered by
	heroCoverImageEditor.cfm) - a separate Kendo window on the same page, not a separate document, so a plain
	jQuery selector reaches it directly, same as enclosureUppyUploadWindow.cfm's own. --->
	createStandaloneUppyUploadWindow({
		containerId: 'standaloneHeroCoverImageUppyUpload',
		endpoint: '<cfoutput>#imageHandlerUrl#</cfoutput>',
		windowSelector: 'heroCoverImageUppyUploadWindow',
		qualitySliderSelector: '#imageQualitySlider',
		onComplete: function() { onHeroCoverImageSubmit(); }
	});
</script>
