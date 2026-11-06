	<!--- Preset the mediaHtml var --->
	<cfparam name="mediaHtml" default="">
	<!---<cfdump var="#URL#">--->
	<!--- Pre-fills the quality slider below (in the <script> block just after this) - Blog Options' own site-wide
	default, still adjustable per image. Must be set before that script block, not after it - it was originally
	placed down near isPageCollectionEnclosure, which runs AFTER the script block that reads it, leaving
	defaultImageQuality undefined and blanking the whole window. --->
	<cfset defaultImageQuality = application.BlogOptionDbObj.getDefaultImageQuality()>

	<style>
		.mce-ico.mce-i-fa {
			display: inline-block;
			font: normal normal normal 14px/1 FontAwesome;
			font-size: inherit;
			text-rendering: auto;
			-webkit-font-smoothing: antialiased;
			-moz-osx-font-smoothing: grayscale;
		}
		<!--- Space between the icon and the label on the Page Collection media buttons (Carousel, Map, etc.). --->
		.pcMediaButtons .fontAwesomeIcon {
			padding-right: 6px;
		}
		<!--- Same "smaller file <-> higher quality" gradient cue as the Blog Options default slider (blogOptions.cfm) -
		red fading to green, left to right. --->
		#imageQualitySlider .k-slider-track {
			background: linear-gradient(to right, #d9534f, #f0ad4e, #5cb85c) !important;
			height: 6px;
		}
	</style>
	<script>
		<!--- Only affects jpg/webp uploads - the server-side quality check (uploadImage) already no-ops this for
		png/gif regardless of the slider's value, so this stays simple rather than trying to detect the picked
		file's type client-side before it's even been selected inside TinyMCE's own image picker. --->
		$(document).ready(function() {
			var qualitySlider = $("#imageQualitySlider").kendoSlider({
				min: 0.1,
				max: 1.0,
				value: <cfoutput>#defaultImageQuality#</cfoutput>,
				smallStep: 0.05,
				largeStep: 0.1,
				tickPlacement: "none",
				showButtons: false,
				tooltip: { format: "{0:p0}" },
				change: function() { updateImageQualityPreview(); },
				slide: function() { updateImageQualityPreview(); }
			}).data("kendoSlider");

			<!--- Auto-loads the current enclosure image (not an arbitrary picked file - see the markup comment
			further down for why that changed). mediaType/mediaUrl themselves aren't defined yet this early in the
			page (see the defaultImageQuality comment above for the same gotcha - a CFML var referenced in this
			script block has to exist before this block or the whole window renders blank), so the URL is read from
			a hidden input placed further down instead, where those vars are safe - by the time this
			$(document).ready() callback runs, the whole DOM (including that later input) is already parsed. --->
			var previewImage = null;

			var currentMediaUrl = $("#currentMediaUrl").val();
			<!--- A .webp current enclosure only ever gets here via the Swap-in-WebP tool (pre-CF2025/Lucee-without-
			webp servers only - see application.imageEngineSupportsWebP). Re-encoding it as a JPEG estimate would be
			the wrong question entirely: there's no JPEG-quality decision left to make on an already-converted file,
			and running it through canvas.toBlob would silently misreport its real size. Report the actual saved
			file's real size directly instead (a HEAD request's Content-Length - no need to even download the image
			bytes), independent of the quality slider, which doesn't apply here at all. --->
			<!--- Same dynamic engine/version naming as the webp-swap section's own message further down (app-scope
			vars, safe to read anywhere regardless of this early script block's own position - unlike mediaType/
			mediaUrl, these aren't set partway through this template's own execution). --->
			var webpEngineDescriptionJs = "<cfoutput>#(application.serverProduct eq "Lucee") ? "This version of Lucee" : "ColdFusion " & application.cfVersion#</cfoutput>";
			if (currentMediaUrl && /\.webp(\?|$)/i.test(currentMediaUrl)) {
				fetch(currentMediaUrl, { method: "HEAD" }).then(function(resp) {
					var len = resp.headers.get("Content-Length");
					var sizeText = len ? (Math.round(parseInt(len, 10) / 1024)).toLocaleString() + " KB" : "an unknown size (couldn't be read)";
					$("#imageQualityPreviewResult").text(
						"Your current image is already WebP - " + sizeText + ". The quality slider above does not apply to it - " +
						webpEngineDescriptionJs + " can't create WebP images, so that quality was already decided outside this tool " +
						"when the file was converted. To get a smaller WebP file, resize or re-compress it in your own image editor " +
						"first, then use \"Swap in WebP Version\" again to replace it."
					);
				}).catch(function() {
					$("#imageQualityPreviewResult").text("Could not read the current WebP file's size.");
				});
			} else if (currentMediaUrl) {
				(function() {
					var img = new Image();
					img.onerror = function() {
						$("#imageQualityPreviewResult").text("Could not load the current image to estimate its size.");
					};
					img.onload = function() {
						previewImage = img;
						updateImageQualityPreview();
					};
					img.src = currentMediaUrl;
				})();
			}

			function updateImageQualityPreview() {
				if (!previewImage) { return; }
				try {
					var canvas = document.createElement("canvas");
					canvas.width = previewImage.naturalWidth;
					canvas.height = previewImage.naturalHeight;
					canvas.getContext("2d").drawImage(previewImage, 0, 0);
					canvas.toBlob(function(blob) {
						if (!blob) {
							$("#imageQualityPreviewResult").text("Preview failed - the browser didn't return a result.");
							return;
						}
						var kb = Math.round(blob.size / 1024);
						<!--- almost-equal-to via a JS unicode escape, not a literal character - this file's byte
					encoding vs how the server serves it has caused mojibake before with literal special characters
					(see &harr; used as an HTML entity in the Image Quality label above, for the same underlying
					reason). The escape is pure ASCII in the source, so it sidesteps that entirely. --->
					$("#imageQualityPreviewResult").text("Your current image " + String.fromCharCode(8776) + " " + kb.toLocaleString() + " KB at this quality (estimate, based on the already-saved file - the true original may compress somewhat differently)");
					}, "image/jpeg", qualitySlider.value());
				} catch (err) {
					$("#imageQualityPreviewResult").text("Preview error: " + err.message);
				}
			}

			<!--- Swap-in-WebP: uploads an already-converted file and repoints this post's enclosure at it directly -
			no cfimage involved at all, since this server can't read or write WebP through it either way. --->
			$("#webpSwapButton").on("click", function() {
				$("#webpSwapFile").trigger("click");
			});

			$("#webpSwapFile").on("change", function(e) {
				try {
					var file = e.target.files && e.target.files[0];
					if (!file) { return; }

					$("#webpSwapResult").text("Uploading...");

					var formData = new FormData();
					formData.append("file", file);

					$.ajax({
						url: '<cfoutput>#application.baseUrl#</cfoutput>/common/cfc/ProxyController.cfc?method=replaceEnclosureWithWebp&postId=<cfoutput>#URL.optArgs#</cfoutput>&csrfToken=<cfoutput>#csrfToken#</cfoutput>',
						type: 'POST',
						data: formData,
						processData: false,
						contentType: false,
						dataType: 'json',
						success: function(resp) {
							if (resp && resp.success) {
								$("#webpSwapResult").text("Swapped in - close and reopen this window to see it.");
							} else {
								$("#webpSwapResult").text((resp && resp.errorMessage) ? resp.errorMessage : "Swap failed.");
							}
						},
						error: function() {
							$("#webpSwapResult").text("Swap failed.");
						}
					});
				} catch (err) {
					$("#webpSwapResult").text("Error: " + err.message);
				}
			});
		});
	</script>
	
	<!--- Instantiate the Render.cfc. This will be used to build the HTML for the image if the MediaUrl is present in the database. --->
	<cfobject component="#application.rendererComponentPath#" name="RendererObj">
	<!--- This same editor is reused for a Page Collection's hero enclosure - URL.otherArgs='pageCollection' switches
	the entity it loads. getPageCollectionByPageCollectionId() returns the exact same field names getPostByPostId()
	does for every Enclosure*/MediaX field, so everything below this point needs no further branching. --->
	<cfset isPageCollectionEnclosure = (isDefined("URL.otherArgs") and URL.otherArgs eq 'pageCollection')>
	<cfif isPageCollectionEnclosure>
		<cfset getPost = application.blog.getPageCollectionByPageCollectionId(URL.optArgs)>
	<cfelse>
		<!--- Get the post ( getPostByPostId(postId, showPendingPosts, showRemovedPosts) ) --->
		<cfset getPost = application.blog.getPostByPostId(URL.optArgs,true,true)>
	</cfif>
	<!--- <cfdump var="#getPost#"> --->

	<!--- Tell the carousel/map creation windows (opened from the tinyMCE toolbar below, via createAdminInterfaceWindow
	3/19/20 - see blogJsContent.cfm's window.currentEnclosureEntityType comment) which kind of enclosure this is,
	since those windows' own argument slots are already full. Always set (including back to '' for a Post), so a
	stale value can't leak into a later, unrelated window opened in the same page. --->
	<script>
		<cfif isPageCollectionEnclosure>
			window.currentEnclosureEntityType = 'pageCollection';
		<cfelse>
			window.currentEnclosureEntityType = '';
		</cfif>
	</script>
	<cfif isPageCollectionEnclosure>
		<!--- Same try/catch window-title-override pattern postDetail.cfm uses for "Edit Page" vs "Edit Post" - the
		window's DOM id is always "postEnclosureWindow" regardless of entity type (set generically in
		blogJsContent.cfm's Id==13 branch), so the content itself has to correct the title once it knows better. --->
		<script>
			$(document).ready(function() {
				try { $("#postEnclosureWindow").data("kendoWindow").title("Page Collection Hero"); } catch(e) {}
			});
		</script>
	</cfif>

	<!---*********************     Handle media      *********************--->
	<!--- There are two references to the media, a path and a URL. We need to check if the mediaUrl is present and extract it from the path if it does not exist. --->
	<cfset mediaId = getPost[1]["MediaId"]>
	<cfset mediaUrl = getPost[1]["MediaUrl"]>
	<cfset mediaPath = getPost[1]["MediaPath"]>
	<cfset mediaType = getPost[1]["MediaType"]>
	<!--- Note: for external links, the mime type will not be available (YouTube and other media sources don't  always have a easilly read extension) --->
	<cfset mimeType = getPost[1]["MimeType"]>
	<cfif not len(mediaUrl)>
		<!--- We are only getting the path and not the entire URL --->
		<cfset mediaUrl = application.blog.getEnclosureUrlFromMediaPath(mediaPath, true)>
	</cfif>
	<!--- Carousel --->
	<cfset enclosureCarouselId = getPost[1]["EnclosureCarouselId"]>
	<!--- Optional video stuff --->
	<cfset providerVideoId = getPost[1]["ProviderVideoId"]>
	<cfset mediaVideoCoverUrl = getPost[1]["MediaVideoCoverUrl"]>
	<cfset mediaVideoVttFileUrl = getPost[1]["MediaVideoVttFileUrl"]>
		
	<cfif len(mediaUrl)>
		<!--- We don't  always have a mime type. External links for example don't  always have a readable extension --->
		<cfif mediaType eq 'Image'>
			<!--- Render the image HTML string --->
			<cfset mediaHtml = RendererObj.renderEnclosureImage(mediaUrl=#mediaUrl#, mediaId=#mediaId#)>
		<!--- The media type string for video is Video - Large, Video - YouTube URL, etc. All of the video types start with 'Video' --->
		<cfelseif left(mediaType, 5) eq 'Video'>
			<!--- Note: this will return an iframe. --->
			<cfinvoke component="#RendererObj#" method="renderEnclosureVideoPreview" returnvariable="mediaHtml">
				<cfinvokeargument name="postId" value="#URL.optArgs#">
				<cfinvokeargument name="mediaId" value="#mediaId#">
				<cfinvokeargument name="mediaUrl" value="#mediaUrl#">
				<cfinvokeargument name="providerVideoId" value="#providerVideoId#">
				<cfinvokeargument name="posterUrl" value="#mediaVideoCoverUrl#">
				<cfinvokeargument name="videoCaptionsUrl" value="#mediaVideoVttFileUrl#">
			</cfinvoke>
		</cfif>
	</cfif><!---<cfif len(mediaUrl)>--->
	<!---<cfdump var="#mediaHtml#" label="mediaHtml">--->
		
	<!---*********************    Handle the carousel    *********************--->
	<cfif len(enclosureCarouselId)>
		<!--- Render the routes. This returns a iframe --->
		<cfset mediaHtml = mediaHtml & RendererObj.renderCarouselPreview(enclosureCarouselId,'enclosureEditor')>
	</cfif>
					
	<!---*********************    Handle the map    *********************--->
	<!--- Extract the map id --->
	<cfset enclosureMapId = getPost[1]["EnclosureMapId"]>
	<cfif len(enclosureMapId)>
		<!--- Render the routes. This returns a iframe --->
		<cfset mediaHtml = mediaHtml & RendererObj.renderMapPreview(enclosureMapId)>
	</cfif>

	<!---*********************    Handle the scene, Hero Gradient, Hero Animation and Hero Cover Image    *********************--->
	<!--- A post with no picture, video, carousel or map: its scene (a moving hero or a full scene) as a still, else its gradient,
	else its animation, else its cover (Renderer.cfc renderHeroEditorFallback; history: 10-01 the gradient and animation opened a
	blank editor; 11-02 the hero comes before the cover; 11-04, owner: a cover on a post with a scene showed nothing, and neither
	did the scene). Post-only: a Page Collection's hero has no TinyMCE editor and its query doesn't return these fields. --->
	<!--- A scene comes first even when the post also has a picture under it (11-05, owner: the window opened on the picture while
	the post shows its moving hero), as on the post page. --->
	<cfif not isPageCollectionEnclosure and (mediaHtml eq '' or len(application.blog.getScenes().getPostScene(val(URL.optArgs))))>
		<cfset mediaHtml = RendererObj.renderHeroEditorFallback(getPost)>
	</cfif>

	<!---********************* Post Enclosure editor *********************--->
	<!--- Set the common vars for tinymce. --->
	<cfsilent>
	<cfset selectorId = "enclosureEditor">
	<cfif session.isMobile>
		<cfset editorHeight = "325">
	<cfelse>
		<cfset editorHeight = "650">
	</cfif>
	<!--- This string is used by the tiny mce editor to handle images uploads --->
	<cfif isPageCollectionEnclosure>
		<cfset imageHandlerUrl = application.baseUrl & "/common/cfc/ProxyController.cfc?method=uploadImage&mediaProcessType=enclosure&mediaType=image&pageCollectionId=" & URL.optArgs & "&selectorId=" & selectorId & "&csrfToken=" & csrfToken>
	<cfelse>
		<cfset imageHandlerUrl = application.baseUrl & "/common/cfc/ProxyController.cfc?method=uploadImage&mediaProcessType=enclosure&mediaType=image&postId=" & URL.optArgs & "&selectorId=" & selectorId & "&csrfToken=" & csrfToken>
	</cfif>
	<cfset contentVar = mediaHtml>
	<cfset imageMediaIdField = "mediaId">
	<cfset imageClass = "entryImage">

	<!--- PARTIALLY PAUSED 2026-09-27: for a Post/Page enclosure (this toolbarString - Page Collections don't use
	TinyMCE at all, see below), the Uppy-cropping replacement for "image" is on hold while the Dashboard experiment
	continues - back to TinyMCE's own plain insert-image dialog (images_upload_handler -> imageUploadHandler in
	tinyMce.cfm) for now, same endpoint either way. The Uppy Dashboard panel and its wiring are still in this file,
	gated on isPageCollectionEnclosure rather than removed, so picking this back up for Post/Page too doesn't mean
	rebuilding it from scratch - see the two "UPPY PIPELINE" markers further down. "editimage" edits an image
	already in the content (alt text, dimensions). --->
	<cfif session.isMobile>
		<cfset toolbarString = "undo redo | image gradient heroAnimation heroCoverImage | movingHero heroText heroStyle | media videoUpload | removeHero">
	<cfelse>
		<cfset toolbarString = "undo redo | image gradient heroAnimation heroCoverImage | carousel movingHero | heroText heroStyle | media videoUpload webVttUpload videoCoverUpload | map mapRouting | removeHero">
	</cfif>
	<!--- No TinyMCE picture tools here (11-05, owner): rotating the preview uploaded a picture of it as the hero, and it took the
	moving hero off the post. The previews here aren't the real files (a scene's still, a cover drawn as a background), so the tools
	are off, and Edit picture on the ribbon opens the real picture in the Upload Image window's editor instead. --->
	<cfset pluginList = "'advlist autolink lists hr link image charmap print preview anchor', 'searchreplace visualblocks code codesample fullscreen', 'insertdatetime media table paste wordcount iconfonts textpattern toc emoticons nonbreaking'">
	<cfset includeEditPicture = true>
	<cfset editPictureTarget = "hero">
	<cfset includeCarousel = true>
	<cfset includeVideoUpload = true>
	<cfset includeGradient = true>
	<cfset includeHeroAnimation = true>
	<cfset includeHeroCoverImage = true>
	<!--- Hero text lives here since 2026-10-20 (the post editor's own button for it is gone). No Scene button on the ribbon since
	11-02 (owner chose "two separate things"): a moving hero is made below, and a full-page scene is shown on a post from the Scenes
	window (Show this scene on) or made with Create, Scene. --->
	<cfset includeScene = false>
	<!--- The Moving hero button (11-03, owner: users expect it on the ribbon like the other heroes): jumps to the Moving hero
	section below and opens its picker (galaxieOpenMovingHero). --->
	<cfset includeMovingHero = true>
	<cfset includeHeroText = true>
	<!--- Hero style (window 120) and Remove hero (11-04, owner: they were at the bottom of this window, which made it long). --->
	<cfset includeHeroStyle = true>
	<cfset includeRemoveHero = true>
	<cfset disableVideoCoverAndWebVttButtons = true>
	</cfsilent>
	<!--- TinyMCE itself is still Post/Page-only - a Page Collection's hero enclosure supports the same underlying
	media (image, carousel, map) but through plain buttons instead of an embedded rich-text editor (see the button
	row below, and requireEditSiteAccess... no wait, see the Page Collection branch further down this file). Video
	is intentionally NOT offered yet for Page Collections: renderEnclosureVideoPreview() and galaxiePlayer.cfm both
	hard-require a real postId and have no Page Collection awareness at all, so a video "enclosure" would upload
	fine but never actually play - that needs its own follow-up, not a client-side redirect like carousel/map got. --->
	<cfif not isPageCollectionEnclosure>
		<!--- Include the tinymce js template --->
		<cfinclude template="#application.baseUrl#/includes/templates/js/tinyMce.cfm">
	</cfif>

	<!--- Include the get-video-id script. This will be used to determine the video provider and the video id --->
	<script src="<cfoutput>#application.baseUrl#</cfoutput>/common/libs/get-video-id/dist/get-video-id.umd.min.js"></script>
	<!---<cfoutput><br/>selectorId: #selectorId#</cfoutput>--->

	<!--- UPPY PIPELINE - PARTIALLY PAUSED 2026-09-27. Post/Page enclosures went back to TinyMCE's own plain
	insert-image dialog (see the restored "image" in the toolbarString above) while the Dashboard experiment
	(styling/config) is on hold - but Page Collections have no TinyMCE at all, so this Uppy panel stays their only
	way to upload a hero image; it's a real dependency for that feature, not part of what's paused. Gated on
	isPageCollectionEnclosure so it only renders there. When the Dashboard work resumes and Post/Page should get it
	back too, change this condition back to <cfif true> (or drop it) and remove "image" from the toolbarString above. --->
	<cfif isPageCollectionEnclosure>
	<!--- Upload an Image - Uppy + its ImageEditor plugin (crop/rotate/flip/zoom), the same cropping tool already
	standing in production for galleries and carousels (uppyGalleryAndCarousel.cfm), used here in place of TinyMCE's
	own plain, no-crop insert-image dialog. Single file only, since an enclosure holds exactly one image. Posts to
	the same imageHandlerUrl endpoint TinyMCE's own upload handler already used (mediaProcessType=enclosure), so
	uploadImage()'s social-crop generation and the Page Collection HeroImageUrl sync both apply unchanged - only how
	the file reaches that endpoint has changed. Uppy's own JS/CSS are already loaded globally in head.cfm for every
	logged-in admin page, same as they are for the gallery/carousel screens - no separate script tags needed here. --->
	<script>
		var enclosureUppy = Uppy.Core({
			restrictions: {
				maxNumberOfFiles: 1,
				allowedFileTypes: <cfif application.imageEngineSupportsWebP>['image/*']<cfelse>['.jpg', '.jpeg', '.png', '.gif', '.bmp']</cfif><!--- No WebP where this server can't read it (2026-10-16) --->
			}
		})

		.use(Uppy.Dashboard, {
			theme: '<cfoutput>#(darkTheme ? "dark" : "light")#</cfoutput>',
			inline: true,
			target: '#enclosureUppyUpload',
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
			<!--- This is Uppy 1.x (see uppy.min.js's own VERSION strings) - Core auto-seeds every file's meta with
			name/type from the file itself, and XHRUpload sends every meta key as its own form field when formData
			is true unless metaFields narrows it. uploadImage() is a remote CFC method with a fixed <cfargument>
			list, and ColdFusion rejects the whole request the moment an unrecognized one shows up (confirmed via
			galaxieBlogErrors.log: "Function uploadImage does not support type as an argument") - metaFields (the
			v1 option name; v3+ renamed this to allowedMetaFields) whitelists only the one meta field this upload
			actually adds. --->
			metaFields: ['quality'],
			endpoint: '<cfoutput>#imageHandlerUrl#</cfoutput>'
		});

		<!--- The per-upload quality slider below is shared with what TinyMCE's own handler used to read (see
		tinyMce.cfm) - read it fresh right as the upload starts, so whatever the admin last set it to is what's sent. --->
		enclosureUppy.on('upload', function(data) {
			var qualitySliderWidget = $("#imageQualitySlider").data("kendoSlider");
			if (qualitySliderWidget) {
				enclosureUppy.setMeta({ quality: qualitySliderWidget.value() });
			}
			$.when(kendo.ui.ExtWaitDialog.show({ title: "Please wait...", message: "Please wait while the image is uploaded.", icon: "k-ext-information" }));
		});

		var enclosureUppyResponse = null;

		enclosureUppy.on('upload-success', function(file, response) {
			if (response.body.errorMessage) {
				enclosureUppyResponse = null;
				alert("Error: " + response.body.errorMessage);
			} else {
				enclosureUppyResponse = response.body;
			}
		});

		enclosureUppy.on('upload-error', function(file, error, response) {
			setTimeout(function() { kendo.ui.ExtWaitDialog.hide(); }, 500);
			$.when(kendo.ui.ExtYesNoDialog.show({
				title: "Upload failed",
				message: "The following error was encountered: " + error + ". Do you want to retry the upload?",
				icon: "k-ext-warning",
				width: "<cfoutput>#application.kendoExtendedUiWindowWidth#</cfoutput>",
				height: "215px"
			})).done(function(response) {
				if (response['button'] == 'Yes') {
					enclosureUppy.retryUpload(file.id);
				}
			});
		});

		enclosureUppy.on('complete', function(result) {
			setTimeout(function() { kendo.ui.ExtWaitDialog.hide(); }, 500);

			if (!enclosureUppyResponse) { return; }

			$("#<cfoutput>#imageMediaIdField#</cfoutput>").val(enclosureUppyResponse.mediaId);
			<cfif isPageCollectionEnclosure>
				<!--- No TinyMCE for a Page Collection - replace the plain preview div's content directly, same as the
				carousel/map completion handlers do. --->
				$("#enclosurePreview").html('<img src="' + enclosureUppyResponse.location + '" alt="">');
			<cfelse>
				<!--- Same end state TinyMCE's own upload handler already produced - an <img> in the editor content and
				the mediaId hidden field set - onPostEnclosureSubmit() and everything downstream needs no changes. --->
				tinymce.get("<cfoutput>#selectorName#</cfoutput>").setContent('<img src="' + enclosureUppyResponse.location + '" alt="">');
			</cfif>

			<!--- Reset so uploading a second image (replacing this one before Submit) starts clean. --->
			enclosureUppy.cancelAll();
			enclosureUppyResponse = null;
			<cfif isPageCollectionEnclosure>
				<!--- 2026-09-27 per feedback: a successful upload here submits and closes the window immediately, same
				as clicking Submit by hand - onPostEnclosureSubmit() already does the right refreshes
				(pageCollectionDetailWindow/configurePageCollectionsWindow) and destroys this window. Called last, after
				Uppy's own cleanup above, since this window (and Uppy's Dashboard DOM) is about to be destroyed anyway. --->
				onPostEnclosureSubmit();
			</cfif>
		});
	</script>
	</cfif>
	<!--- end UPPY PIPELINE - PARTIALLY PAUSED 2026-09-27 --->

	<script>
		<!--- Note: the function handles enclosure images, videos, and theme images and needs to be changed according to what is being processed. This particular function handles theme images. Note: the invokedArguments is not used by CF, but shows the location where this function is being called from and the arguments for debugging purposes. When using: insert edit image: the image is retrieved from the source but this function is not called. insert media: this function is invoked as soon as the user enters a URL into the tinyMce editor. --->
		function saveExternalUrl(url, mediaType, selectorId, invokedArguments){ 
			<!--- alert('saveExternalUrl invoked'); --->
			jQuery.ajax({
				type: 'post', 
				url: '<cfoutput>#application.baseUrl#</cfoutput>/common/cfc/ProxyController.cfc?method=saveExternalMediaEnclosure&template=enclosureImageEditor',
				dataType: "json",
				data: { // arguments
					csrfToken: '<cfoutput>#csrfToken#</cfoutput>',
					selectorId: '<cfoutput>#selectorId#</cfoutput>',
					<!--- Pass the mediaId saved in the mediaId hidden form if it is available --->
					mediaId: $("#<cfoutput>#imageMediaIdField#</cfoutput>").val(),
					externalUrl: url,
					<cfif isPageCollectionEnclosure>
					pageCollectionId: <cfoutput>#URL.optArgs#</cfoutput>,
					<cfelse>
					postId: <cfoutput>#URL.optArgs#</cfoutput>,
					</cfif>
					mediaType: 'image',
					imageType: '<cfoutput>#URL.otherArgs#</cfoutput>',
					invokedArguments: invokedArguments
				},
				success: saveExternalUrlResponse,
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
			
			<!--- Refresh the media preview- pass in the postId --->
			reloadEnclosureThumbnailPreview(<cfoutput>#URL.optArgs#</cfoutput>);
	
		}
											
		function saveExternalUrlResponse(response){ 
			<!--- Note: this does not do anything. I suspect because the tinymce editor is modal mode when it is invoked. This is only used for debugging purposes now alert(response.postId) alert(response. mediaId) alert(response.externalUrl) $("#externalImageUrl").val(response.externalUrl); --->
		}
		
		<!--- Posts only (2026-10-18): it uses the post editor's selectorName, which a Page Collection's window never sets (the error broke its picture editor). --->
		<cfif not isPageCollectionEnclosure>
		<!--- Remove hero (11-04; a Remove picture button since 10-16): takes whatever hero the post has off it - picture, video, carousel,
		map, gradient, animation or moving hero (ProxyController.cfc removePostHero). Asks first; the cover and hero text stay. --->
		window.galaxieRemoveHero = function () {
			galaxieConfirm("Remove the hero?", "This takes the hero off the post: its picture, video, carousel, map, gradient, animation or moving hero. Nothing is deleted from your media library, and the cover and hero text stay.", function () {
				jQuery.ajax({
					type: 'post',
					url: '<cfoutput>#application.baseUrl#</cfoutput>/common/cfc/ProxyController.cfc?method=removePostHero',
					dataType: "json",
					data: { csrfToken: '<cfoutput>#csrfToken#</cfoutput>', postId: <cfoutput>#URL.optArgs#</cfoutput> }
				}).done(function (response) {
					if (typeof response === "string") { try { response = JSON.parse(response); } catch (e) {} }
					if (!(response && response.success)) {
						kendo.ui.ExtAlertDialog.show({ title: "The hero stays", message: (response && response.errorMessage) || "It could not be removed. Please try again.", icon: "k-ext-warning", width: "<cfoutput>#application.kendoExtendedUiWindowWidth#</cfoutput>" });
						return;
					}
					$("#externalImageUrl").val("");
					try { tinymce.get("<cfoutput>#selectorName#</cfoutput>").setContent(""); } catch (e) {}
					window.galaxieRefreshHeroEditorPreview();
					try { reloadEnclosureThumbnailPreview(<cfoutput>#URL.optArgs#</cfoutput>); } catch (e) {}
				}).fail(function (jqXHR) {
					if (jqXHR.status === 403) { createLoginWindow(); return; }
					kendo.ui.ExtAlertDialog.show({ title: "The hero stays", message: "It could not be removed. Please try again.", icon: "k-ext-warning", width: "<cfoutput>#application.kendoExtendedUiWindowWidth#</cfoutput>" });
				});
			});
		};

		<!--- Redraw the preview after the moving hero or the cover is saved in their own windows (11-04), unless it shows a picture,
		video, carousel or map, which those don't change. --->
		<!--- force: redraw even over a picture or video, for when the save took it off (11-05: a moving hero clears a video). --->
		window.galaxieRefreshHeroEditorPreview = function (force) {
			<!--- And the Hero text row at the top, for a moving hero's heading (11-05). --->
			$("#heroTextLine").load("<cfoutput>#application.baseUrl#</cfoutput>/admin/loadPreview.cfm?previewId=6&optArgs=<cfoutput>#URL.optArgs#</cfoutput>");
			$("#heroStatus").load("<cfoutput>#application.baseUrl#</cfoutput>/admin/loadPreview.cfm?previewId=5&optArgs=<cfoutput>#URL.optArgs#</cfoutput>");
			var editor = window.tinymce && tinymce.get("<cfoutput>#selectorName#</cfoutput>");
			if (!editor) { return; }
			<!--- data-mce-p-data-type too: the editor renames a frame's data-type when it wraps it (11-05). --->
			var keep = 'img:not([data-type]), img[data-type="image"][data-id]:not([data-id=""]), [data-type="video"], [data-type="carousel"], [data-type="map"], [data-type="mapRoute"], [data-mce-p-data-type="video"], [data-mce-p-data-type="carousel"], [data-mce-p-data-type="map"], [data-mce-p-data-type="mapRoute"]';
			<!--- A moving hero's layers are pictures too, but part of this preview, not a hero picture (11-05). --->
			if (!force && $(editor.getBody()).find(keep).not('[data-type="movingHero"] *, [data-type="heroAndCover"] *').length) { return; }
			jQuery.get("<cfoutput>#application.baseUrl#</cfoutput>/admin/loadPreview.cfm", { previewId: 3, optArgs: <cfoutput>#URL.optArgs#</cfoutput> }, function (html) {
				editor.setContent($.trim(html));
			});
		};
		</cfif>

		function removeMediaEnclosure(){
			jQuery.ajax({
				type: 'post',
				url: '<cfoutput>#application.baseUrl#</cfoutput>/common/cfc/ProxyController.cfc?method=removeMediaEnclosure&template=enclosureImageEditor',
				dataType: "json",
				data: { // arguments
					csrfToken: '<cfoutput>#csrfToken#</cfoutput>',
					<cfif isPageCollectionEnclosure>
					pageCollectionId: <cfoutput>#URL.optArgs#</cfoutput>
					<cfelse>
					postId: <cfoutput>#URL.optArgs#</cfoutput>
					</cfif>
				},
				error: function(ErrorMsg) {
					console.log('Error' + ErrorMsg);
				}
			<!--- Extract any errors. This is a new jQuery promise based function as of jQuery 1.8. --->
			}).fail(function (jqXHR, textStatus, error) {

				<!--- The full response is: jqXHR.responseText, but we just want to extract the error. --->
				$.when(kendo.ui.ExtAlertDialog.show({ title: "Error while consuming the removeMediaEnclosure function", message: error, icon: "k-ext-error", width: "<cfoutput>#application.kendoExtendedUiWindowWidth#</cfoutput>" }) // or k-ext-error, k-ext-information, k-ext-question, k-ext-warning.  You can also specify height.
					).done(function () {
					<!--- Do nothing --->
				});		
			});
		}
			
		<!--- Submit the data and close this window. --->
		<!--- The windows opened from this one close with it (11-05, owner: Hero style was still open after a video upload closed this
		window). The cover window is left alone: the cover reminder opens it after a hero save. --->
		window.galaxieCloseHeroChildWindows = function () {
			$.each(["postHeroStyleWindow", "postHeroTextWindow", "movingHeroWizardWindow", "gradientEditorWindow", "gradientPasteEditorWindow", "heroAnimationEditorWindow"], function (i, id) {
				var w = $("#" + id).data("kendoWindow");
				if (w) { try { w.destroy(); } catch (e) {} }
			});
		};
		$(function () {
			var heroWindow = $("#postEnclosureWindow").data("kendoWindow");
			if (heroWindow) { heroWindow.bind("close", window.galaxieCloseHeroChildWindows); }
		});

		function onPostEnclosureSubmit(){
			window.galaxieCloseHeroChildWindows();
			<cfif not isPageCollectionEnclosure>
				// Get the editor content
				// Original code that caused problems:
				// var enclosureEditorContent = $("#<cfoutput>#imageMediaIdField#</cfoutput>").val();
				var enclosureEditorContent = tinymce.get("<cfoutput>#selectorName#</cfoutput>").getContent();
				<!--- Get the media URL if it is an existing image --->
				var externalImageUrl = $("#externalImageUrl").val();
				<!--- If there are no enclosures or an existing media URL, remove any enclosures that exists in the db. --->
				if (enclosureEditorContent == "" && externalImageUrl == ""){
					removeMediaEnclosure();
				}
			</cfif>
			<!--- No TinyMCE for a Page Collection to check the content of - removal there happens immediately via its
			own explicit "Remove" button instead of being inferred from an empty editor at Submit time. --->
			<cfif isPageCollectionEnclosure>
				<!--- Lightweight hero-image-only reload of the still-open Page Collection Detail window behind this
				one - mirrors reloadEnclosureThumbnailPreview()'s own targeted approach instead of reloading that
				whole window's content (theme dropdown, member list, etc.) just to update one <img>. See
				loadPreview.cfm's previewId=2. --->
				try { reloadPageCollectionHeroPreview(<cfoutput>#URL.optArgs#</cfoutput>); } catch(e) {}
				try { $("#configurePageCollectionsWindow").data("kendoWindow").refresh(); } catch(e) {}
			<cfelse>
				<!--- Refresh the thumbnail image on the post detail page to show the none image --->
				reloadEnclosureThumbnailPreview(<cfoutput>#URL.optArgs#</cfoutput>);
			</cfif>
			<!--- Close the edit window --->
			$('#postEnclosureWindow').kendoWindow('destroy');
		}
	</script>
		
	<form id="enclosureForm" action="#" method="post" data-role="validator">
	<!-- Pass the mediaId for new images or videos that have been uploaded -->
	<input type="hidden" name="mediaId" id="mediaId" value="" />
	<!-- The mediaType will either be an empty string, image or video -->
	<input type="hidden" name="mediaType" id="mediaType" value="" />
	<!--- Pass the mapId for an enclosure map --->
	<input type="hidden" name="mapId" id="mapId" value="" />
	<!-- The map type will either be an empty string, static or route -->
	<input type="hidden" name="mapType" id="mapType" value="" />
	<!-- Pass the csrfToken -->
	<input type="hidden" name="csrfToken" id="csrfToken" value="<cfoutput>#csrfToken#</cfoutput>" />
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
	  <!--- This help text used to be identical for a Post/Page enclosure and a Page Collection's hero enclosure -
	  wrong for the Collection case, which isn't shared individually on social media (no og:image generation exists
	  for a Page Collection at all - seoMetaTags.cfm only runs for the Post/Page render path), so the whole
	  Facebook/Twitter/Google/Pinterest crop pitch was pure noise there. Reuses the isPageCollectionEnclosure switch
	  already used everywhere else in this file. --->
	  <cfif isPageCollectionEnclosure>
	  <tr height="30px">
		<td align="left" class="<cfoutput>#thisContentClass#</cfoutput>" colspan="2">
			The hero appears at the top of this Page Collection's listing and can take up to 100% of the content width. It can be a video or an image. Unlike a Post, a Page Collection isn't shared individually on social media, so none of the automatic Facebook/Twitter/Pinterest crops apply here - a single image (or video) is all you need. To upload media, click on the buttons below.
		</td>
	  </tr>
	  <cfelse>
	  <tr height="30px">
		<td align="left" class="<cfoutput>#thisContentClass#</cfoutput>" colspan="2">
			The hero shows at the top of the post: a picture, video, carousel, map, gradient, animation or moving hero (below). For a heading over it, use the H on the ribbon or Format, Hero text. Pictures are cropped for Facebook, X and Google automatically. To add media, use the buttons below. Click a picture to crop, rotate or flip it.
			<div class="k-form-hint"><small>Pinterest needs a tall (portrait) picture of at least 1000&times;1500. Wide pictures are skipped.</small></div>
		</td>
	  </tr>
	  <!--- Hero text first, at the top, the same row as the gradient and animation windows (11-05, owner). heroTextLine.cfm, drawn
	  again (loadPreview previewId 6) when the Hero text window or the moving hero saves. --->
	  <tr height="2px">
		  <td align="left" valign="top" colspan="2" class="border <cfoutput>#thisContentClass#</cfoutput>"></td>
	  </tr>
	  <tr valign="middle">
		<td align="left" id="heroTextLine" class="<cfoutput>#thisContentClass#</cfoutput>" colspan="2" style="padding: 8px 12px;">
			<cfinclude template="heroTextLine.cfm">
			<script>
				$(document).off('galaxieHeroTextSaved.heroTextLine').on('galaxieHeroTextSaved.heroTextLine', function () {
					$("#heroTextLine").load("<cfoutput>#application.baseUrl#</cfoutput>/admin/loadPreview.cfm?previewId=6&optArgs=<cfoutput>#val(URL.optArgs)#</cfoutput>");
				});
			</script>
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
	  <!--- UPPY PIPELINE - PARTIALLY PAUSED 2026-09-27: Page Collections have no TinyMCE, so this Dashboard panel
	  stays their only way to upload a hero image - see the matching marker up near the toolbarString/script. --->
	  <cfif isPageCollectionEnclosure>
	  <!-- Upload an Image (Uppy + cropping) -->
	  <tr valign="middle">
		<td align="left" class="<cfoutput>#thisContentClass#</cfoutput>" colspan="2" style="padding: 8px 12px 0px;">
			<label>Upload an Image (crop, rotate and flip before it's saved):</label>
		</td>
	  </tr>
	  <tr valign="middle">
		<td align="left" class="<cfoutput>#thisContentClass#</cfoutput>" colspan="2" style="padding: 6px 12px 12px;">
			<div id="enclosureUppyUpload"></div>
		</td>
	  </tr>
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
	  </cfif>
	  <!--- end UPPY PIPELINE - PARTIALLY PAUSED 2026-09-27 --->
	  <!-- Form content -->
	  <cfif isPageCollectionEnclosure>
	  <!--- No TinyMCE for a Page Collection - buttons that open the exact same Carousel/Map/Map Routing windows the
	  TinyMCE toolbar does, plus the Uppy upload above. Each of those windows' own completion handler already
	  branches on window.currentEnclosureEntityType to write into #enclosurePreview instead of calling
	  tinymce.activeEditor - see carouselItems.cfm, azureMap.cfm, azureMapRoute.cfm (and their Bing equivalents), and
	  enclosureUppy's own 'complete' handler above. Video is deliberately left out for now - see the comment above
	  the (skipped) tinyMce.cfm include for why.
	  2026-09-27: the visible preview here is hidden per feedback (redundant next to the Uppy Dashboard's own file
	  thumbnail, and the row was showing alongside the upload widget) - #enclosurePreview itself has to stay in the
	  DOM (display:none, not removed), since the three completion handlers above still write into it by id; deleting
	  the div would make uploading an image, or adding a carousel/map/route, silently show nothing until the window
	  is closed and reopened. --->
	  <tr valign="middle" style="display:none;">
		<td align="left" class="<cfoutput>#thisContentClass#</cfoutput>" colspan="2" style="padding: 8px 12px;">
			<div id="enclosurePreview"><cfoutput>#(len(mediaHtml) ? mediaHtml : '<img src="' & application.baseUrl & '/images/icons/noMedia.png" alt="">')#</cfoutput></div>
		</td>
	  </tr>
	  <tr valign="middle">
		<td align="left" class="pcMediaButtons <cfoutput>#thisContentClass#</cfoutput>" colspan="2" style="padding: 0px 12px 12px;">
			<button type="button" class="k-button normalFontWeight" onclick="javascript:createAdminInterfaceWindow(3,<cfoutput>#URL.optArgs#</cfoutput>,'carousel');"><i class="fontAwesomeIcon fas fa-images"></i> Carousel</button>
			<button type="button" class="k-button normalFontWeight" onclick="javascript:createAdminInterfaceWindow(19,<cfoutput>#URL.optArgs#,'#selectorId#','#enclosureMapId#'</cfoutput>);"><i class="fontAwesomeIcon fas fa-map-location-dot"></i> Map</button>
			<button type="button" class="k-button normalFontWeight" onclick="javascript:createAdminInterfaceWindow(20,<cfoutput>#URL.optArgs#,'#selectorId#'</cfoutput>);"><i class="fontAwesomeIcon fas fa-route"></i> Map Routing</button>
			<!--- window.currentEnclosureEntityType (set 'pageCollection' above) flows into window 14's own content
			URL automatically via createAdminInterfaceWindow()'s entityType param - see uppyVideoUpload.cfm. --->
			<button type="button" class="k-button normalFontWeight" onclick="javascript:createAdminInterfaceWindow(14,<cfoutput>#URL.optArgs#</cfoutput>);"><i class="fontAwesomeIcon fas fa-video"></i> Video</button>
			<!--- window.currentEnclosureEntityType (set 'pageCollection' above) flows into window 77's own content
			URL automatically, same as window 14 above - see gradientEditor.cfm. --->
			<button type="button" class="k-button normalFontWeight" onclick="javascript:createAdminInterfaceWindow(77,<cfoutput>#URL.optArgs#</cfoutput>);"><i class="fontAwesomeIcon fas fa-swatchbook"></i> Gradient</button>
			<button type="button" class="k-button normalFontWeight" onclick="javascript:galaxieConfirm('Remove the picture?', 'It comes off the hero of this collection.', function () { removeMediaEnclosure(); $('#enclosurePreview').html('<img src=&quot;<cfoutput>#application.baseUrl#</cfoutput>/images/icons/noMedia.png&quot; alt=&quot;&quot;>'); });"><i class="fontAwesomeIcon fas fa-trash-can"></i> Remove</button>
		</td>
	  </tr>
	  <cfelse>
	  <!--- 2026-10-01: a Post's Gradient/animation hero-fallback pickers are reached through TinyMCE's own toolbar
	  icon + Insert menu (tinyMce.cfm's includeGradient/includeHeroAnimation, same pattern as carousel) - no separate
	  button row needed here, consistent with every other media type (carousel/map/video are also TinyMCE-only
	  for a Post, with no duplicate plain button). Page Collections still get a real button row above since they
	  have no TinyMCE instance at all to host an Insert menu. --->
	  <tr valign="middle" height="30px">
		<td align="left" class="<cfoutput>#thisContentClass#</cfoutput>" colspan="2">
			<!--- TinyMce container - "image" (insert) and "editimage" (alt text/dimensions on an existing one) are both
			back in the toolbar above while the Uppy cropping panel is paused - see the "UPPY PIPELINE - PAUSED"
			markers in this file. --->
			<div style="position: relative;">
				<textarea id="<cfoutput>#selectorName#</cfoutput>" name="<cfoutput>#selectorName#</cfoutput>"></textarea>
			</div>
			<!--- The hero text over the picture, as a preview layer (2026-10-23, owner: "the text does not show up in the hero image
			editor's preview"). It is drawn inside the editor's frame but outside its content (a sibling of <body>), so it is never
			saved with the hero, and it follows the picture as the editor scrolls. Redrawn when the Hero text window saves
			(galaxieHeroTextSaved) and when the hero changes. A gradient draws its own copy of the text; that copy is hidden here
			so only the current text shows. --->
			<script>
				(function () {
					var editorId = "<cfoutput>#selectorName#</cfoutput>", postId = <cfoutput>#val(URL.optArgs)#</cfoutput>, html = "";
					function frameDoc(editor) { try { return editor.getDoc(); } catch (e) { return null; } }
					function place(editor) {
						var doc = frameDoc(editor); if (!doc || !doc.body) { return; }
						var layer = doc.getElementById("galaxieHeroTextLayer");
						if (!html) { if (layer) { layer.remove(); } return; }
						// A video, map or carousel hero shows no hero text on the post (a carousel has its own slide text), so none here
						// either (11-05, owner: the heading was drawn under a video). A moving hero has its own heading, already drawn
						// on its still (Renderer.renderHeroEditorFallback), so this one would be a second heading on top (11-05, owner).
						// The editor wraps a frame (video, map, carousel) in its own span and renames its data-type to data-mce-p-data-type.
						var noText = ["video", "map", "mapRoute", "carousel", "movingHero"].map(function (k) { return '[data-type="' + k + '"], [data-mce-p-data-type="' + k + '"]'; }).join(", ");
						if (doc.body.querySelector("video, " + noText)) { if (layer) { layer.remove(); } return; }
						var media = doc.body.querySelector("img, iframe, video, .galaxieHeroGradient, [style*='gradient']") || doc.body.firstElementChild;
						if (!media) { if (layer) { layer.remove(); } return; }
						// An animation preview is a frame that draws its own copy of the heading (11-03, owner: tiny and big text at once).
						// Same site, so hide that copy and keep this layer's.
						if (media.tagName === "IFRAME") {
							try {
								var inner = media.contentDocument;
								if (inner && inner.documentElement && !inner.getElementById("galaxieHeroTextHide")) {
									var innerHide = inner.createElement("style");
									innerHide.id = "galaxieHeroTextHide";
									innerHide.textContent = ".galaxieHeroText { visibility: hidden !important; }";
									(inner.head || inner.documentElement).appendChild(innerHide);
								}
							} catch (e) {}
						}
						if (!layer) {
							layer = doc.createElement("div");
							layer.id = "galaxieHeroTextLayer";
							layer.setAttribute("contenteditable", "false");
							layer.setAttribute("data-mce-bogus", "all");
							doc.documentElement.appendChild(layer);
							var hide = doc.createElement("style");
							hide.id = "galaxieHeroTextLayerStyle";
							hide.textContent = "body .galaxieHeroText { visibility: hidden; } #galaxieHeroTextLayer { font-family: Arial, Helvetica, sans-serif; position: absolute; display: flex; align-items: center; justify-content: center; pointer-events: none; overflow: hidden; z-index: 5; } #galaxieHeroTextLayer .galaxieHeroText { width: 90%; }";
							doc.documentElement.appendChild(hide);
						}
						layer.innerHTML = html;
						var r = media.getBoundingClientRect(), sx = doc.defaultView.pageXOffset, sy = doc.defaultView.pageYOffset;
						$(layer).css({ left: r.left + sx, top: r.top + sy, width: r.width, height: r.height });
						// The post page draws the heading for a page about 1100px wide; the picture here is smaller.
						var text = layer.querySelector(".galaxieHeroText");
						if (text) { text.style.zoom = Math.max(0.35, Math.min(1, r.width / 1100)); }
					}
					function load(editor) {
						jQuery.ajax({ type: "post", url: "<cfoutput>#application.baseUrl#</cfoutput>/common/cfc/ProxyController.cfc?method=getHeroTextPreview", dataType: "json",
							data: { csrfToken: "<cfoutput>#csrfToken#</cfoutput>", postId: postId } })
							.done(function (response) {
								if (typeof response === "string") { try { response = JSON.parse(response); } catch (e) {} }
								html = (response && response.html) || "";
								place(editor);
								// Pictures load after the editor; place the text again once they have their size.
								$(frameDoc(editor)).find("img, iframe").off("load.heroText").on("load.heroText", function () { place(editor); });
							});
					}
					var tries = 0;
					(function wait() {
						var editor = window.tinymce && tinymce.get(editorId);
						if (!editor || !editor.initialized) { if (tries++ < 60) { setTimeout(wait, 250); } return; }
						load(editor);
						editor.on("SetContent Change Undo Redo ResizeEditor", function () { setTimeout(function () { place(editor); }, 50); });
						$(frameDoc(editor).defaultView).on("resize", function () { place(editor); });
						$(document).off("galaxieHeroTextSaved.heroLayer").on("galaxieHeroTextSaved.heroLayer", function () { load(editor); });
					})();
				})();
			</script>
		</td>
	  </tr>
	  <!--- What the hero is and its cover, in one line (11-04, owner: the bottom of this window had "a lot of stuff"; Remove picture is now
	  Remove hero on the toolbar, and the moving hero and hero style have windows of their own). heroStatusLine.cfm. --->
	  <cfif not isPageCollectionEnclosure>
	  <tr valign="middle">
		<td align="left" class="<cfoutput>#thisContentClass#</cfoutput>" colspan="2" style="padding: 8px 12px;" id="heroStatus"><cfinclude template="heroStatusLine.cfm"></td>
	  </tr>
	  </cfif>
	  <!--- The moving hero (2026-10-25 as a section here; 11-04, owner: "the interface is quite long and can be confusing") is a wizard of
	  its own, window 119 (movingHeroWizard.cfm), opened by the Moving hero button on the toolbar; the preview above shows it. --->
	  <cfif not isPageCollectionEnclosure>
	  <script>
		window.galaxieOpenMovingHero = function () { createAdminInterfaceWindow(119, <cfoutput>#val(URL.optArgs)#</cfoutput>); };
		window.galaxieMovingHeroSaved = function () {};
	  </script>
	  </cfif>
	  <!--- The hero's style moved to a window of its own (11-04), window 120 (postHeroStyle.cfm), on the toolbar. --->
	  </cfif>
	  <!-- Border -->
	  <tr height="2px">
	    	<td align="left" valign="top" colspan="<cfoutput>#thisColSpan#</cfoutput>" class="<cfoutput>#thisContentClass#</cfoutput>"></td>
	  </tr>
	  <cfsilent>
	  <cfset thisContentClass = HtmlUtilsObj.getKendoClass(thisContentClass)>
	  </cfsilent>
	  <!--- Quality slider, moved underneath the image/enclosure editor above per feedback - label and slider each get
	  their own row rather than sharing one td, and the label lost its 12px override (way too small) so it now
	  matches the size of every other plain instructional line in this window. --->
	  <!--- On a phone the label gets its own line and the slider fills the width, up to 260px (2026-10-31, owner: a fixed
	  260px slider beside the label ran off the right of the screen). --->
	  <!--- A post's slider moved to the top of the Upload Image window (window 74, enclosureUppyUploadWindow.cfm), where the
	  picture is chosen (11-05, owner: it looked out of place here). A Page Collection keeps it: its upload panel is in this window. --->
	  <cfif isPageCollectionEnclosure>
	  <cfif session.isMobile>
	  <tr valign="middle">
		<td align="left" colspan="<cfoutput>#thisColSpan#</cfoutput>" class="<cfoutput>#thisContentClass#</cfoutput>" style="padding: 8px 12px 0 12px;">
			<label for="imageQualitySlider">Image Quality</label>
		</td>
	  </tr>
	  <tr valign="middle">
		<td align="left" colspan="<cfoutput>#thisColSpan#</cfoutput>" class="<cfoutput>#thisContentClass#</cfoutput>" style="padding: 8px 12px;">
			<!--- A fixed width: Kendo measures the slider when it is made, and a 100% width measured inside the window before it
			is shown gave a track of 0, so only the round handle showed (owner's phone, 11-02). 260px fits a phone on its own row. --->
			<div id="imageQualitySlider" style="width: 260px;"></div>
			<span class="k-form-hint" style="display: block;">Left = smaller file, right = sharper image.</span>
		</td>
	  </tr>
	  <cfelse>
	  <tr valign="middle">
		<td align="right" class="<cfoutput>#thisContentClass#</cfoutput>" style="width: 20%; padding: 8px 12px;">
			<label for="imageQualitySlider">Image Quality</label>
		</td>
		<td align="left" class="<cfoutput>#thisContentClass#</cfoutput>" style="padding: 8px 12px;">
			<div id="imageQualitySlider" style="width: 260px;"></div>
			<span class="k-form-hint" style="display: block;">Left = smaller file, right = sharper image.</span>
		</td>
	  </tr>
	  </cfif>
	  <!--- Estimates the CURRENT enclosure image's size at the slider's quality, not an arbitrary picked file - a
	  file picker here previously let you test any local file, but that read as ambiguous next to an editor full of
	  controls that genuinely do act on the current enclosure (would someone assume it was reporting on their
	  existing image?). Only shown when there's a real current image enclosure to test against; re-encodes the
	  already-live mediaUrl through the browser's own JPEG encoder (canvas.toBlob) at the slider's current value,
	  live as the slider moves - no button/click needed. Since the source is already-compressed (not the original
	  pre-upload bytes), this is a lower-bound estimate, not identical to testing the true original. Not wired into
	  the real TinyMCE upload flow at all, so it can't affect anything. --->
	  <cfif mediaType eq 'Image' and len(mediaUrl)>
	  <tr valign="middle">
		<!--- On a phone the estimate gets the full width; beside an empty first cell it was squeezed into a narrow column. --->
		<cfif not session.isMobile><td class="<cfoutput>#thisContentClass#</cfoutput>" style="width: 20%;"></td></cfif>
		<td align="left" class="<cfoutput>#thisContentClass#</cfoutput>" style="padding: 0px 12px 12px;"<cfif session.isMobile> colspan="<cfoutput>#thisColSpan#</cfoutput>"</cfif>>
			<!--- Carries mediaUrl (safe to read here - unlike the early script block up top, see that block's own
			comment) into the DOM as plain markup rather than a second <script> tag, so the early script's single
			$(document).ready() handler can just read it with jQuery - no dependency on script-tag execution order
			across two separate <script> blocks injected together via Kendo/jQuery's .html(). --->
			<input type="hidden" id="currentMediaUrl" value="<cfoutput>#encodeForHTMLAttribute(mediaUrl)#</cfoutput>">
			<span id="imageQualityPreviewResult">Loading your current image...</span>
		</td>
	  </tr>
	  </cfif>
	  </cfif><!---<cfif isPageCollectionEnclosure>--->
	  <!--- This server can't read or write WebP through cfimage at all (older ColdFusion), so there's no way to
	  generate one automatically the way createSocialMediaImages() does elsewhere. If the admin has already converted
	  this image to WebP some other way (Photoshop, an online converter, etc.), this lets them swap it in as the main
	  displayed image without hand-editing the database - the existing thumbnail and social sharing images are left
	  completely alone, since cfimage can't touch the new file to regenerate them from it anyway. Only shown for an
	  actual image enclosure, and only on a server where this is actually needed - a server that can already write
	  WebP itself has no use for this, the normal upload already produces one alongside the original. --->
	  <cfif not application.imageEngineSupportsWebP and mediaType eq 'Image' and len(mediaUrl)>
		  <!--- Named engine/version rather than a generic "this server", since knowing exactly why matters more
		  here than in most messages in this window - an admin reading this may not know their own CF version, and
		  "this server can't" reads like a mystery limitation rather than a known, named one. Dynamic rather than a
		  hardcoded "ColdFusion 2023" string so this keeps describing whatever engine actually rendered this - Lucee
		  practically never reaches this branch (every Lucee version this codebase runs on already supports WebP),
		  but the wording stays correct if that ever changes. --->
		  <cfset webpEngineDescription = (application.serverProduct eq "Lucee") ? "This version of Lucee" : "ColdFusion " & application.cfVersion>
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
		  <tr valign="middle">
			<td align="left" class="<cfoutput>#thisContentClass#</cfoutput>" colspan="2" style="padding: 8px 12px 0px;">
				<cfoutput>#webpEngineDescription#</cfoutput> can't create WebP images automatically, so this image's thumbnail and the social sharing crops made from it can't be regenerated as WebP either - only the main displayed image can be swapped, and only by hand. If you've already converted this image to WebP yourself (Photoshop, an online converter, etc.), upload it here to swap it in as the main displayed image; the thumbnail and social sharing images stay exactly as they already are.
			</td>
		  </tr>
		  <!--- Divider between the explanation and the actual upload control, so they read as two distinct steps
		  rather than one run-on block. --->
		  <tr height="2px">
			  <td align="left" valign="top" colspan="<cfoutput>#thisColSpan#</cfoutput>" class="<cfoutput>#thisContentClass#</cfoutput>"></td>
		  </tr>
		  <cfsilent>
		  <cfset thisContentClass = HtmlUtilsObj.getKendoClass(thisContentClass)>
		  </cfsilent>
		  <tr height="2px">
			  <td align="left" valign="top" colspan="2" class="border <cfoutput>#thisContentClass#</cfoutput>"></td>
		  </tr>
		  <tr valign="middle">
			<td align="left" class="<cfoutput>#thisContentClass#</cfoutput>" colspan="2" style="padding: 6px 12px 12px;">
				<input type="file" id="webpSwapFile" accept="image/webp" style="display: none;">
				<button type="button" id="webpSwapButton" class="k-button normalFontWeight">Swap in WebP Version</button>
				<span id="webpSwapResult" style="margin-left: 10px;"></span>
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
		<td valign="bottom" align="right" class="<cfoutput>#thisContentClass#</cfoutput>" style="width: 20%">&nbsp;</td>
		<td valign="bottom" align="left" class="<cfoutput>#thisContentClass#</cfoutput>">
			<button id="mediaUploadCompleteButton" name="mediaUploadCompleteButton" class="k-button k-primary" type="button" onClick="javascript:onPostEnclosureSubmit();">Submit</button>
		</td>
	  </tr>
	</table>
	</form>