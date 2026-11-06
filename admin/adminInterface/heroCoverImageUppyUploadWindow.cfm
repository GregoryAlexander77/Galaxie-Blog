<!--- Standalone Uppy cropping uploader, opened from inside TinyMCE's own "Insert/Edit Image" dialog (its Upload
tab) for the Hero Cover Image editor (window 80, heroCoverImageEditor.cfm) - see the editor.on('OpenWindow', ...)
listener in includes/templates/js/tinyMce.cfm that wires the tab's click to createAdminInterfaceWindow(81,
postId). Same "own browsing context, own JS" shared bridge enclosureUppyUploadWindow.cfm/
videoCoverUppyUploadWindow.cfm already use - see those files' own comments for the full design reasoning.
2026-10-01. --->
<cfset postId = URL.optArgs>
<cfset imageHandlerUrl = application.baseUrl & "/common/cfc/ProxyController.cfc?method=uploadImage&mediaProcessType=heroCoverImage&mediaType=image&postId=" & postId & "&selectorId=heroCoverImageEditor&csrfToken=" & csrfToken>

<!--- The Image Quality slider and its size estimate, at the top (11-05, owner: it looked out of place in the Cover window). --->
<cfset sliderId = "heroCoverUploadQualitySlider">
<cfinclude template="uploadQualitySlider.cfm">

<div id="standaloneHeroCoverImageUppyUpload" style="padding: 12px;"></div>

<script>
	createStandaloneUppyUploadWindow({
		containerId: 'standaloneHeroCoverImageUppyUpload',
		endpoint: '<cfoutput>#imageHandlerUrl#</cfoutput>',
		windowSelector: 'heroCoverImageUppyUploadWindow',
		qualitySliderSelector: '#heroCoverUploadQualitySlider',
		qualityEstimateSelector: '#heroCoverUploadQualitySliderEstimate',
		onComplete: function() { onHeroCoverImageSubmit(); }
	});
</script>
