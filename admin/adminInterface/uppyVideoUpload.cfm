	<cfsilent>
	<!--- 
		Note: to embed video from Galaxy blog use something like this:
		<iframe src="/galaxiePlayer.cfm?postId=1&videoUrl=/enclosures/videos/weekndStarBoy.mp4&posterUrl=&videoCaptionsUrl=/enclosures/videos/test1.vtt" width="768" height="432" allowfullscreen="allowfullscreen"></iframe>

		Custom element markup example for videos:
		<galaxie-template data-type="video" data-mediaId="" data-width="" data-length=""></galaxie-template>
	--->
		
	<!--- Get the current content by the mediaId if available ( getPostByPostId(postId, showPendingPosts, showRemovedPosts) ). --->
	<cfif len(URL.optArgs)>
		<cfset getPost = application.blog.getPostByPostId(URL.optArgs,true,true)>
	<!---<cfdump var="#getPost#"> --->  
		
		<!---*********************     Handle media      *********************--->
		<!--- There are two references to the media, a path and a URL. The previous versions of BlogCfc did not use the URL so we need to check if the mediaUrl is present and extract it from the path if it does not exist. --->
		<cfset mediaId = getPost[1]["MediaId"]>
	</cfif>
	
	<!--- Set the uppy theme. --->
	<cfif darkTheme>
		<cfset uppyTheme = 'dark'>
	<cfelse>
		<cfset uppyTheme = 'light'>
	</cfif>
		
	<!--- Not used yet- Get the kendo primay button color in order to reset the uppy actionBtn--upload color --->
	<cfset primaryButtonColor = application.blog.getPrimaryColorsByTheme(kendoTheme:kendoTheme,setting:'accentColor')>
	</cfsilent>
	<!---<cfoutput>primaryButtonColor: #primaryButtonColor#</cfoutput>--->
    <div id="videoUpload"></div>
    <script>
		
		var uppy = Uppy.Core({
			restrictions : {
				maxNumberOfFiles: 1,  // only one video can be uploaded at a time
				allowedFileTypes: ['video/*'] // only allow videos
        	}
		})
		
		.use(Uppy.Dashboard, {
			theme: '<cfoutput>#uppyTheme#</cfoutput>',
			inline: true,
			target: '#videoUpload',
			proudlyDisplayPoweredByUppy: false,
			metaFields: [
				{ id: 'mediaTitle', name: 'Title', placeholder: 'Please enter the image title' }
			]
		})
		// Allow users to take pictures via the onboard camera
		.use(Uppy.Webcam, { target: Uppy.Dashboard })
		// Use the built in image editor
		.use(Uppy.ImageEditor, { 
			target: Uppy.Dashboard,
			quality: 0.8 // for the resulting image, 0.8 is a sensible default
		})
		// Use XHR and send the media to the server for processing
		.use(Uppy.XHRUpload, { endpoint: '<cfoutput>#application.baseUrl#</cfoutput>/common/cfc/ProxyController.cfc?method=uploadVideo&mediaProcessType=enclosure&mediaType=largeVideo&postId=<cfoutput>#URL.optArgs#</cfoutput>&csrfToken=<cfoutput>#csrfToken#</cfoutput>' })
		.on('upload-success', (file, response) => {
			// The server is returning location and mediaId in a json object. We need to extract these.
			//alert(response.status) // HTTP status code
			//alert(response.body.location) // The full path of the file that was just uploaded to the server
			// alert(response.body.mediaId) // The MediaId value saved to the Media table in the database.
			//alert(response.body.mediaActions) // All of the actions taken for a video or image. Only present with image enclosures
			// Save the mediaId into the hidden form on the post enclosure window
			$("#mediaId").val(response.body.mediaId);
			// Insert 'video' as the mediaType to differentiate between videos and images
			$("#mediaType").val('video');
		<cfif isDefined("URL.optArgs") and len(URL.optArgs)>
			// Refresh the thumbnail image on the post detail page
			reloadEnclosureThumbnailPreview(response.body.postId);
		</cfif>
		})
		
		// Events
		// 1) When the dashboard icon is clicked
		// Note: there is no event when the dashboard my device button is clicked. This is a work-around. We are going to use jquery's on click event and put in the class of the button. This is required as the uppy button does not have an id.
		$(".uppy-Dashboard-input").on('click', function(event){
			$.when(kendo.ui.ExtWaitDialog.show({ title: "Please wait...", message: "Please wait for the file uploader interface to respond.", icon: "k-ext-information" }));
		});
		
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
			}, 500);
			
			// After uploading the video, create the HTML and send it back to the editor. We don't  have an video image cover or webVtt file yet as this video has just been uploaded. This is the type of string that we need to create:
			// <iframe src="https://gregoryalexander.com/blog/galaxiePlayer.cfm?postId=x&mediaId=xxx" width="768" height="432" allowfullscreen="allowfullscreen"></iframe>

			// Create our iframe html string
			var videoIframeHtml = '<iframe data-type="video" data-id=' + $("#mediaId").val() + ' src="<cfoutput>#application.baseUrl#</cfoutput>/galaxiePlayer.cfm?postId=<cfoutput>#URL.optArgs#</cfoutput>&mediaId=' + $("#mediaId").val() + '" width="768" height="432" allowfullscreen="allowfullscreen"></iframe>';
			// Insert the HTML string into the active editor
			tinymce.activeEditor.setContent(videoIframeHtml);
			// Close this window
			$('#postEnclosureVideoWindow').kendoWindow('destroy');
			
			// Let the user know that they can add video captions or an image cover 
			$.when(kendo.ui.ExtAlertDialog.show({ title: "Your video has been uploaded", message: "You may also add video captions and an image cover for this video.", icon: "k-ext-information", width: "<cfoutput>#application.kendoExtendedUiWindowWidth#</cfoutput>" }) // or k-ext-error, k-ext-information, k-ext-question, k-ext-warning.  You can also specify height.
				).done(function () {
				// Do nothing
			});
		})
	
    </script>