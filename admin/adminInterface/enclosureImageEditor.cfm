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
						"Your current image is already WebP - " + sizeText + ". The quality slider below does not apply to it - " +
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
				try { $("#postEnclosureWindow").data("kendoWindow").title("Page Collection Hero Enclosure"); } catch(e) {}
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

	<!---*********************    Handle the Hero Cover Image    *********************--->
	<!--- 2026-10-01: a static uploaded photo for a post with no real Image/Video/Map/Carousel - takes priority
	over Gradient/the live animation's own placeholder/iframe, same as it does in Renderer.cfc's renderMediaPreview() and
	every card-grid template, so what the admin sees here always matches what cards/social will actually use.
	Post-only, same isPageCollectionEnclosure guard as the Gradient/animation block below. --->
	<cfif not isPageCollectionEnclosure and mediaHtml eq '' and len(getPost[1]["HeroCoverImageUrl"])>
		<cfset mediaHtml = RendererObj.renderEnclosureImage(mediaUrl=getPost[1]["HeroCoverImageUrl"])>
	</cfif>

	<!---*********************    Handle the Hero Gradient / Hero Animation    *********************--->
	<!--- 2026-10-01: a Post whose hero is a picked Gradient or animation effect (not an Image/Video/Carousel/Map)
	used to open this editor to a BLANK TinyMCE content area - this file never had a branch for either field,
	only the four plain media types above. Post-only (not isPageCollectionEnclosure): a Page Collection's hero
	has no TinyMCE editor at all (see azureMap.cfm's window.currentEnclosureEntityType branch, which writes
	straight to #enclosurePreview instead) and getPageCollectionByPageCollectionId()'s own SELECT doesn't even
	return these fields, so reading them here for a Page Collection would throw an undefined-key error, not just
	render wrong. Mirrors renderMediaPreview()'s own Gradient/animation branches (Renderer.cfc) - same priority
	order, Gradient checked first since the two are mutually exclusive on Post.cfc. --->
	<cfif not isPageCollectionEnclosure and mediaHtml eq '' and len(getPost[1]["HeroGradient"])>
		<cfset mediaHtml = RendererObj.renderHeroGradientHtml(getPost[1]["HeroGradient"], getPost[1]["HeroOverlayText"], getPost[1]["HeroOverlayTextColor"], getPost[1]["HeroOverlayFont"], getPost[1]["HeroOverlayFontSize"])>
	<cfelseif not isPageCollectionEnclosure and mediaHtml eq '' and len(getPost[1]["HeroAnimationEffect"])>
		<!--- Same live iframe heroAnimationEditor.cfm's own submit handler sets into TinyMCE right after picking
		(preview/heroAnimation.cfm) - this is what makes reopening the editor later show the same thing instead
		of resetting to blank. 2026-10-03: renamed from HeroVantaEffect/vantaEditor.cfm/preview/vanta.cfm while
		still dev-only/unmigrated. --->
		<!--- 2026-10-04: bumped from 235x130 - this window has plenty of room (66%/85% Kendo Window) and the
		admin asked for a larger preview specifically here, while keeping the small postDetail.cfm admin-list
		thumbnail (Renderer.cfc's renderMediaPreview()) unchanged. Same size bump mirrored in
		heroAnimationEditor.cfm's own submit-handler iframe string - keep both in sync, same reasoning as the
		comment above (reopening this editor later has to show the same size as right after picking). --->
		<cfset mediaHtml = '<iframe data-type="animation" data-id="' & URL.optArgs & '" src="' & application.baseUrl & '/preview/heroAnimation.cfm?postId=' & URL.optArgs & '" width="470" height="260" style="border:0;" scrolling="no"></iframe>'>
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
		<cfset toolbarString = "undo redo | image editimage gradient heroAnimation heroCoverImage | media videoUpload">
	<cfelse>
		<cfset toolbarString = "undo redo | image editimage gradient heroAnimation heroCoverImage | carousel | media videoUpload webVttUpload videoCoverUpload | map mapRouting">
	</cfif>
	<cfset includeCarousel = true>
	<cfset includeVideoUpload = true>
	<cfset includeGradient = true>
	<cfset includeHeroAnimation = true>
	<cfset includeHeroCoverImage = true>
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
				allowedFileTypes: ['image/*']
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
		
		<!--- Remove the picture (owner, 10-16: a post had no visible way to take its hero picture off - only emptying the editor
		box and pressing Submit did it). Asks first, removes it, refreshes the post editor's preview and closes this window. --->
		function removePostHero(){
			$.when(kendo.ui.ExtYesNoDialog.show({ title: "Remove the picture?", message: "This takes the picture off the post. Nothing is deleted from your media library.", icon: "k-ext-question", width: "<cfoutput>#application.kendoExtendedUiWindowWidth#</cfoutput>" })).done(function(answer) {
				if (answer['button'] !== 'Yes') { return; }
				jQuery.ajax({
					type: 'post',
					url: '<cfoutput>#application.baseUrl#</cfoutput>/common/cfc/ProxyController.cfc?method=removeMediaEnclosure&template=enclosureImageEditor',
					dataType: "json",
					data: { csrfToken: '<cfoutput>#csrfToken#</cfoutput>', postId: <cfoutput>#URL.optArgs#</cfoutput> }
				}).done(function() {
					try { tinymce.get("<cfoutput>#selectorName#</cfoutput>").setContent(""); } catch (e) {}
					$("#externalImageUrl").val("");
					try { reloadEnclosureThumbnailPreview(<cfoutput>#URL.optArgs#</cfoutput>); } catch (e) {}
					$('#postEnclosureWindow').kendoWindow('destroy');
				}).fail(function(jqXHR) {
					if (jqXHR.status === 403) { createLoginWindow(); return; }
					kendo.ui.ExtAlertDialog.show({ title: "The picture stays", message: "It could not be removed. Please try again.", icon: "k-ext-warning", width: "<cfoutput>#application.kendoExtendedUiWindowWidth#</cfoutput>" });
				});
			});
		}

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
		function onPostEnclosureSubmit(){
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
			The hero enclosure appears at the top of this Page Collection's listing and can take up to 100% of the content width. It can be a video or an image. Unlike a Post, a Page Collection isn't shared individually on social media, so none of the automatic Facebook/Twitter/Pinterest crops apply here - a single image (or video) is all you need. To upload media, click on the buttons below.
		</td>
	  </tr>
	  <cfelse>
	  <tr height="30px">
		<td align="left" class="<cfoutput>#thisContentClass#</cfoutput>" colspan="2">
			The enclosure resides at the top of the blog post and it should take up to 100% of the content width of the blog post. The enclosure can either be a video or an image. Galaxie Blog will automatically crop your image for Facebook, Twitter, Google, and a classic 1200&times;900 fallback used whenever a platform-specific crop isn't available. To upload media, click on the buttons below.
		</td>
	  </tr>
	  <tr height="30px">
		<td align="left" class="<cfoutput>#thisContentClass#</cfoutput>" colspan="2">
			Pinterest is only generated when your image is at least 1000&times;1500 and taller than it is wide - a wide/landscape photo will clear the pixel count but still get skipped, since the resulting crop would look bad regardless of resolution. Upload a portrait-oriented image if you want Pinterest support for this post.
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
			<button type="button" class="k-button normalFontWeight" onclick="javascript:removeMediaEnclosure(); $('#enclosurePreview').html('<img src=&quot;<cfoutput>#application.baseUrl#</cfoutput>/images/icons/noMedia.png&quot; alt=&quot;&quot;>');"><i class="fontAwesomeIcon fas fa-trash-can"></i> Remove</button>
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
		</td>
	  </tr>
	  <!--- Remove the picture (2026-10-16), only when the post has one. --->
	  <cfif len(mediaUrl)>
	  <tr valign="middle">
		<td align="left" class="<cfoutput>#thisContentClass#</cfoutput>" colspan="2" style="padding: 8px 12px;">
			<button type="button" class="k-button normalFontWeight" onclick="removePostHero();"><i class="fontAwesomeIcon fas fa-trash-can"></i> Remove picture</button>
			<span class="k-form-hint">Takes the picture off the post. The post then shows your no-picture choice in Blog Options; an event shows its calendar tile on the front page.</span>
		</td>
	  </tr>
	  </cfif>
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
	  <tr valign="middle">
		<td align="right" class="<cfoutput>#thisContentClass#</cfoutput>" style="width: 20%; padding: 8px 12px;">
			<label for="imageQualitySlider">Image Quality</label>
		</td>
		<td align="left" class="<cfoutput>#thisContentClass#</cfoutput>" style="padding: 8px 12px;">
			<div id="imageQualitySlider" style="width: 260px;"></div>
			<span class="k-form-hint">Left = smaller file, right = sharper image.</span>
		</td>
	  </tr>
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
		<td class="<cfoutput>#thisContentClass#</cfoutput>" style="width: 20%;"></td>
		<td align="left" class="<cfoutput>#thisContentClass#</cfoutput>" style="padding: 0px 12px 12px;">
			<!--- Carries mediaUrl (safe to read here - unlike the early script block up top, see that block's own
			comment) into the DOM as plain markup rather than a second <script> tag, so the early script's single
			$(document).ready() handler can just read it with jQuery - no dependency on script-tag execution order
			across two separate <script> blocks injected together via Kendo/jQuery's .html(). --->
			<input type="hidden" id="currentMediaUrl" value="<cfoutput>#encodeForHTMLAttribute(mediaUrl)#</cfoutput>">
			<span id="imageQualityPreviewResult">Loading your current image...</span>
		</td>
	  </tr>
	  </cfif>
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