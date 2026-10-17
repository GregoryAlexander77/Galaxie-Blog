<!--- Hero Image Pool management - the blog-wide shared photo pool for BlogOption.NoImageFallbackMode='pool'
(see Renderer.cfc's getHeroFallbackHtml()). Each post with no image of its own shows a small carousel of
HeroCarouselImageCount images, deterministically drawn from this pool by PostId. This screen is a standalone
grid + upload button, not a form with a Save button - every add/delete is its own immediate save, and the
window content is refreshed from the server after each one rather than patched client-side. --->
<cfset poolCarouselId = application.blog.getHeroImagePoolCarouselId()>
<cfset poolItems = len(poolCarouselId) ? application.blog.getCarousel(poolCarouselId) : []>
<!--- Kept in sync with ProxyController.cfc's addHeroImagePoolItem, which is the actual enforcement point -
this is just what lets the button disable itself instead of waiting on a server round trip to say no. --->
<cfset maxHeroImagePoolItems = 75>
<cfset atHeroImagePoolLimit = arrayLen(poolItems) gte maxHeroImagePoolItems>

<style>
	#heroImagePoolGrid {
		display: flex;
		flex-wrap: wrap;
		gap: 12px;
		padding: 12px;
	}
	.heroImagePoolItem {
		width: 140px;
	}
	.heroImagePoolItem img {
		width: 140px;
		height: 105px;
		object-fit: cover;
		display: block;
	}
	.heroImagePoolItem button {
		width: 100%;
		margin-top: 4px;
	}
</style>

<p style="padding: 0px 12px;">These images are the shared pool used when Blog Options' No-Image Fallback is set to "Rotating pool" - each post with no image of its own shows a small carousel of images, drawn deterministically from here so the same post always shows the same picks. Add a few photos below - there's no separate save step, each add or remove takes effect immediately.</p>
<p style="padding: 0px 12px;" id="heroImagePoolCountMessage"><cfoutput>#arrayLen(poolItems)# of #maxHeroImagePoolItems# images used.<cfif atHeroImagePoolLimit> The pool is full - remove one before adding another.</cfif></cfoutput></p>

<div id="heroImagePoolGrid">
	<cfif not arrayLen(poolItems)>
		<p id="heroImagePoolEmptyMessage">No images in the pool yet - add one below.</p>
	<cfelse>
		<cfloop array="#poolItems#" index="poolItem">
			<div class="heroImagePoolItem" data-carousel-item-id="<cfoutput>#poolItem["CarouselItemId"]#</cfoutput>">
				<img src="<cfoutput>#len(poolItem["MediaThumbnailUrl"]) ? poolItem["MediaThumbnailUrl"] : poolItem["MediaUrl"]#</cfoutput>" alt="">
				<button type="button" class="k-button heroImagePoolDeleteBtn" data-id="<cfoutput>#poolItem["CarouselItemId"]#</cfoutput>">Remove</button>
			</div>
		</cfloop>
	</cfif>
</div>

<div style="padding: 12px;">
	<!--- No WebP where this server can't read it (2026-10-16). --->
	<input type="file" id="heroImagePoolFile" accept="<cfif application.imageEngineSupportsWebP>image/*<cfelse>image/jpeg,image/png,image/gif,image/bmp</cfif>" style="display: none;">
	<button type="button" id="heroImagePoolAddBtn" class="k-button k-primary" <cfif atHeroImagePoolLimit>disabled</cfif>>Add Photo</button>
	<span id="heroImagePoolStatus" style="margin-left: 10px;"></span>
</div>

<script>
	$(document).ready(function() {

		function refreshPoolWindow() {
			var win = $("#heroImagePoolWindow").data("kendoWindow");
			if (win) { win.refresh(); }
		}

		$("#heroImagePoolAddBtn").on("click", function() {
			$("#heroImagePoolFile").trigger("click");
		});

		$("#heroImagePoolFile").on("change", function(e) {
			try {
				var file = e.target.files && e.target.files[0];
				if (!file) { return; }

				$("#heroImagePoolStatus").text("Uploading...");

				var formData = new FormData();
				formData.append("file", file);

				$.ajax({
					url: '<cfoutput>#application.baseUrl#</cfoutput>/common/cfc/ProxyController.cfc?method=uploadImage&mediaProcessType=post&csrfToken=<cfoutput>#csrfToken#</cfoutput>',
					type: 'POST',
					data: formData,
					processData: false,
					contentType: false,
					dataType: 'json',
					success: function(uploadResp) {
						if (!uploadResp || !uploadResp.mediaId) {
							$("#heroImagePoolStatus").text("Upload failed - no image was returned.");
							return;
						}
						$.ajax({
							url: '<cfoutput>#application.baseUrl#</cfoutput>/common/cfc/ProxyController.cfc?method=addHeroImagePoolItem&csrfToken=<cfoutput>#csrfToken#</cfoutput>&mediaId=' + uploadResp.mediaId,
							type: 'POST',
							dataType: 'json',
							success: function(response) {
								if (JSON.parse(response.success) == true) {
									$("#heroImagePoolStatus").text("");
									refreshPoolWindow();
								} else {
									$("#heroImagePoolStatus").text(response.errorMessage || "Could not add that photo to the pool.");
								}
							},
							error: function() {
								$("#heroImagePoolStatus").text("The photo uploaded, but could not be added to the pool.");
							}
						});
					},
					error: function() {
						$("#heroImagePoolStatus").text("Upload failed.");
					}
				});
			} catch (err) {
				$("#heroImagePoolStatus").text("Error: " + err.message);
			}
		});

		$(document).on("click", ".heroImagePoolDeleteBtn", function() {
			var carouselItemId = $(this).data("id");
			$("#heroImagePoolStatus").text("Removing...");
			$.ajax({
				url: '<cfoutput>#application.baseUrl#</cfoutput>/common/cfc/ProxyController.cfc?method=deleteHeroImagePoolItem&csrfToken=<cfoutput>#csrfToken#</cfoutput>&carouselItemId=' + carouselItemId,
				type: 'POST',
				dataType: 'json',
				success: function() {
					$("#heroImagePoolStatus").text("");
					refreshPoolWindow();
				},
				error: function() {
					$("#heroImagePoolStatus").text("Could not remove that image.");
				}
			});
		});

	});
</script>
