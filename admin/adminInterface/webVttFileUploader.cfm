	<cfsilent>
	<!--- Set the uppy theme. --->
	<cfif darkTheme>
		<cfset uppyTheme = 'dark'>
	<cfelse>
		<cfset uppyTheme = 'light'>
	</cfif>
		
	<!--- Not used yet- Get the kendo primay button color in order to reset the uppy actionBtn--upload color --->
	<cfset primaryButtonColor = application.blog.getPrimaryColorsByTheme(kendoTheme:kendoTheme,setting:'accentColor')>
	</cfsilent>
    <div id="webVttFileUpload"></div>
    <script>
		
		// Get the videos mediaId from the mediaId form field on the previous window
		var mediaId = $("#mediaId").val();
		
		var uppy = Uppy.Core({
			restrictions : {
				maxNumberOfFiles: 1,  // only one vtt file can be uploaded at a time
				allowedFileTypes: ['.vtt'] // only allow webvtt
        	}
		})
		
		.use(Uppy.Dashboard, {
			theme: '<cfoutput>#uppyTheme#</cfoutput>',
			inline: true,
			target: '#webVttFileUpload',
			proudlyDisplayPoweredByUppy: false
		})
		// Allow users to take pictures via the onboard camera
		.use(Uppy.Webcam, { target: Uppy.Dashboard })
		// Use the built in image editor
		.use(Uppy.ImageEditor, { 
			target: Uppy.Dashboard,
			quality: 0.8 // for the resulting image, 0.8 is a sensible default
		})
		// Use XHR and send the media to the server for processing
		.use(Uppy.XHRUpload, { endpoint: '<cfoutput>#application.baseUrl#</cfoutput>/common/cfc/ProxyController.cfc?method=uploadFile&mediaProcessType=enclosure&fileType=webVttFile&postId=<cfoutput>#URL.optArgs#</cfoutput>&mediaId=' + mediaId + '&csrfToken=<cfoutput>#csrfToken#</cfoutput>'})
		
		.on('upload-success', (file, response) => {
			// The server is returning location and mediaId in a json object. We need to extract these.
			//alert(response.status) // HTTP status code
			//alert(response.body.location) // The full path of the file that was just uploaded to the server
			//alert(response.body.mediaId) // The MediaId value saved to the Media table in the database.
			//alert(response.body.fileContent) // The content of the webvtt file
			
			// Add some instructions on how to edit the file
			$("#webVttInstructions").val("If this looks correct, you can also close this window to continue. You can also make further changes in the editor below and submit your changes.");
			// Set the file location into a hidden form on the vtt editor
			$("#webVttFile").val(response.body.location);
			// Set the contents of the WebVtt file into the editor. 
			tinymce.activeEditor.setContent(response.body.fileContent);
			// Close the vtt editor window
			jQuery('#webVttFileWindow').kendoWindow('destroy');	
		})
		
		// Events
		// 1) When the dashboard icon is clicked
		// Note: there is no event when the dashboard my device button is clicked. This is a work-around. We are going to use jquery's on click event and put in the class of the button. This is required as the uppy button does not have an id.
		$(".uppy-Dashboard-input").on('click', function(event){
			$.when(kendo.ui.ExtWaitDialog.show({ title: "Please wait...", message: "Please wait for the file uploader interface to respond.", icon: "k-ext-information" }));
		});
		
		// Fired when one of the restrictions failed
		uppy.on('restriction-failed', (file, error) => {
			// Close the wait window that was launched in the calling function.
			kendo.ui.ExtWaitDialog.hide();
		})
		
		// 2) When a file has been uploaded to uppy
		uppy.on('file-added', (file) => {
		  	// Close the wait window that was launched in the calling function.
			kendo.ui.ExtWaitDialog.hide();
		})
		
		// 3) When the upload button was pressed
		uppy.on('upload', (data) => {
			$.when(kendo.ui.ExtWaitDialog.show({ title: "Please wait...", message: "Please wait while the video is uploaded.", icon: "k-ext-information" }));
		})
		
		// 4) When the upload is complete to the server
		uppy.on('complete', (result) => {
			
			// Close the please wait dialog
			// Use a quick set timeout in order for the data to load.
			setTimeout(function() {
				// Close the wait window that was launched in the calling function.
				kendo.ui.ExtWaitDialog.hide();
				// Close this window
				jQuery('#uploadWebVttFileWindow').kendoWindow('destroy');	
			}, 500);	

		})
	
    </script>