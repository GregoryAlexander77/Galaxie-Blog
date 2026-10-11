	<cfsilent>
	<!--- 
		Note: to embed video from Galaxy blog use something like this:
		<iframe src="/galaxiePlayer.cfm?postId=1&videoUrl=/enclosures/videos/weekndStarBoy.mp4&posterUrl=&videoCaptionsUrl=/enclosures/videos/test1.vtt" width="768" height="432" allowfullscreen="allowfullscreen"></iframe>

		Custom element markup example for videos:
		<galaxie-template data-type="video" data-mediaId="" data-width="" data-length=""></galaxie-template>
	--->
		
	<!--- Opened from enclosureImageEditor.cfm's own "Video" button for a Page Collection hero - see that file's
	window.currentEnclosureEntityType comment, which is what puts 'pageCollection' into URL.entityType here (this
	window's own optArgs slot is already the pageCollectionId in that case, same slot Post/Page uses for postId). --->
	<cfset isPageCollectionEnclosure = (isDefined("URL.entityType") and URL.entityType eq 'pageCollection')>

	<!--- Get the current content by the mediaId if available ( getPostByPostId(postId, showPendingPosts, showRemovedPosts) ). Not meaningful for a Page Collection - it has no TinyMCE content to pre-fill, see below. --->
	<cfif not isPageCollectionEnclosure and len(URL.optArgs)>
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
		
		// 2026-09-26: set inside upload-success when the server rejects the file (bad MIME type/too large) and
		// checked inside 'complete' below - Uppy's 'complete' event fires regardless of whether the individual
		// file actually succeeded, so without this flag the "video uploaded" success flow (insert iframe, close
		// window, success alert) ran even on a rejected file, right after the "Oops" dialog from upload-success.
		var videoUploadRejected = false;

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
		.use(Uppy.XHRUpload, { endpoint: '<cfoutput>#application.baseUrl#</cfoutput>/common/cfc/ProxyController.cfc?method=uploadVideo&mediaProcessType=enclosure&mediaType=largeVideo&<cfif isPageCollectionEnclosure>pageCollectionId<cfelse>postId</cfif>=<cfoutput>#URL.optArgs#</cfoutput>&csrfToken=<cfoutput>#csrfToken#</cfoutput>', fieldName: 'files', metaFields: [] })
		.on('upload-success', (file, response) => {
			// The server is returning location and mediaId in a json object. We need to extract these.
			//alert(response.status) // HTTP status code
			//alert(response.body.location) // The full path of the file that was just uploaded to the server
			// alert(response.body.mediaId) // The MediaId value saved to the Media table in the database.
			//alert(response.body.mediaActions) // All of the actions taken for a video or image. Only present with image enclosures

			// 2026-09-26: uploadVideo() returns HTTP 200 with an errorMessage in the body (not an HTTP error
			// status) whenever the file itself is rejected - an unsupported MIME type (the case this was
			// originally added for) or an oversized file both take this same early-return path server-side, so
			// one generic check/dialog here covers both. Confirmed via the browser's own Network tab that this
			// remote method's real JSON response preserves the struct's original (lowercase) key casing - unlike
			// a raw serializeJSON() call elsewhere in this codebase, which uppercases keys; don't assume the two
			// behave the same way again.
			if (response.body.errorMessage && response.body.errorMessage.length) {
				videoUploadRejected = true;
				$.when(kendo.ui.ExtAlertDialog.show({ title: "Oops - we couldn't upload this video", message: response.body.errorMessage, icon: "k-ext-warning", width: "<cfoutput>#application.kendoExtendedUiWindowWidth#</cfoutput>" }));
				return;
			}

			// Save the mediaId into the hidden form on the post enclosure window
			$("#mediaId").val(response.body.mediaId);
			// Insert 'video' as the mediaType to differentiate between videos and images
			$("#mediaType").val('video');
		<cfif not isPageCollectionEnclosure and isDefined("URL.optArgs") and len(URL.optArgs)>
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
			// Reset in case this is a retry after a previous rejection in the same window.
			videoUploadRejected = false;
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

			// 2026-09-26: the file was rejected server-side (upload-success already showed the "Oops" dialog) -
			// this event still fires either way. Skip the success-only steps (insert iframe, submit the Post
			// Enclosure window, "video uploaded" alert), since there's nothing to insert - but still close this
			// Uppy window itself, per feedback: leaving it open showed Uppy's own "Upload complete" state right
			// next to our "Oops" dialog, which read as a contradiction. The Post Enclosure window underneath is
			// left open either way, so the admin can just try again.
			if (videoUploadRejected) {
				$('#postEnclosureVideoWindow').kendoWindow('destroy');
				return;
			}

		<cfif not isPageCollectionEnclosure>
			// After uploading the video, create the HTML and send it back to the editor. We don't  have an video image cover or webVtt file yet as this video has just been uploaded. This is the type of string that we need to create:
			// <iframe src="https://gregoryalexander.com/blog/galaxiePlayer.cfm?postId=x&mediaId=xxx" width="768" height="432" allowfullscreen="allowfullscreen"></iframe>

			// Create our iframe html string
			var videoIframeHtml = '<iframe data-type="video" data-id=' + $("#mediaId").val() + ' src="<cfoutput>#application.baseUrl#</cfoutput>/galaxiePlayer.cfm?postId=<cfoutput>#URL.optArgs#</cfoutput>&mediaId=' + $("#mediaId").val() + '" width="768" height="432" allowfullscreen="allowfullscreen"></iframe>';
			// Insert the HTML string into the active editor
			tinymce.activeEditor.setContent(videoIframeHtml);
		</cfif>
			// No TinyMCE content to set for a Page Collection - the video is already persisted server-side
			// (uploadVideo() -> insertMediaRecord/updateMediaRecord already set the PageCollection's EnclosureMedia
			// relationship when pageCollectionId is passed, same as an image upload does). onPostEnclosureSubmit()
			// below picks it up via reloadPageCollectionHeroPreview() once this window closes.

			// Close this window
			$('#postEnclosureVideoWindow').kendoWindow('destroy');

			// 2026-09-26 per feedback: close the Post Enclosure window too, on success - same auto-close pattern
			// the carousel upload and the Uppy image bridge windows already use.
			try { onPostEnclosureSubmit(); } catch(e) {}

			// Let the user know that they can add video captions or an image cover - reworded 2026-09-26 since the
			// Post Enclosure window (where those buttons live) now closes automatically right above, rather than
			// staying open for immediate follow-up like it used to.
			$.when(kendo.ui.ExtAlertDialog.show({ title: "Your video has been uploaded", message: "You can add video captions and an image cover for this video by reopening the enclosure editor.", icon: "k-ext-information", width: "<cfoutput>#application.kendoExtendedUiWindowWidth#</cfoutput>" }) // or k-ext-error, k-ext-information, k-ext-question, k-ext-warning.  You can also specify height.
				).done(function () {
				// Do nothing
			});
		})
	
    </script>