<!--- Hero Cover Image editor (window id 80 - see includes/windows/adminInterface.cfm's cfcase value=80 and
includes/templates/blogJsContent.cfm's Id==80 branch). A static uploaded photo for a post whose hero is
Gradient/animation/the auto-generated fallback art (no real Image/Video/Map/Carousel enclosure) - used on cards/
listings and to drive the social-media share images (og:image/twitter:image), but never shown on the post's own
single permalink page, where the real Gradient/animation keeps rendering live regardless (see Post.cfc's own comment
on HeroCoverImageUrl). 2026-10-01.

Mirrors videoImageEditor.cfm's structure (its own small scratch TinyMCE instance whose images_upload_url has
mediaProcessType=heroCoverImage&postId=... baked in, so the upload itself - via either TinyMCE's own plain
dialog or the Uppy bridge, window 81 - is the save; no separate submit step) - but unlike that file, includes
the #imageQualitySlider Kendo Slider UI (same markup/init as enclosureImageEditor.cfm's own), since there's no
reason a Hero Cover Image upload shouldn't get the same per-upload quality control every other enclosure image
upload already has. --->
<cfparam name="defaultImageQuality" default="">
<cfset defaultImageQuality = application.BlogOptionDbObj.getDefaultImageQuality()>

<!--- Instantiate the Render.cfc. This will be used to build the HTML for the image if HeroCoverImageUrl is present. --->
<cfobject component="#application.rendererComponentPath#" name="RendererObj">
<!--- Get the post ( getPostByPostId(postId, showPendingPosts, showRemovedPosts) ) --->
<cfset getPost = application.blog.getPostByPostId(URL.optArgs,true,true)>

<cfif len(getPost[1]["HeroCoverImageUrl"])>
	<cfset mediaUrl = getPost[1]["HeroCoverImageUrl"]>
<cfelse>
	<cfset mediaUrl = "">
</cfif>

<!--- Render the image HTML string --->
<cfset mediaHtml = RendererObj.renderEnclosureImage(mediaUrl)>

<style>
	.mce-ico.mce-i-fa {
		display: inline-block;
		font: normal normal normal 14px/1 FontAwesome;
		font-size: inherit;
		text-rendering: auto;
		-webkit-font-smoothing: antialiased;
		-moz-osx-font-smoothing: grayscale;
	}
	<!--- Same "smaller file <-> higher quality" gradient cue as enclosureImageEditor.cfm's own slider. --->
	#imageQualitySlider .k-slider-track {
		background: linear-gradient(to right, #d9534f, #f0ad4e, #5cb85c) !important;
		height: 6px;
	}
</style>

<script>
	$(document).ready(function() {
		$("#imageQualitySlider").kendoSlider({
			min: 0.1,
			max: 1.0,
			value: <cfoutput>#defaultImageQuality#</cfoutput>,
			smallStep: 0.05,
			largeStep: 0.1,
			tickPlacement: "none",
			showButtons: false,
			tooltip: { format: "{0:p0}" }
		});
	});

	function onHeroCoverImageSubmit(){
		<!--- Refresh the media preview - pass in the postId --->
		reloadEnclosureThumbnailPreview(<cfoutput>#URL.optArgs#</cfoutput>);
		<!--- Use a quick set timeout in order for the data to load. --->
		setTimeout(function() {
			<!--- Close this window --->
			jQuery('#heroCoverImageWindow').kendoWindow('destroy');
		}, 500);
	}
</script>

<!--- ********************************** Hero Cover Image Editor ******************************** --->
<cfsilent>
<cfset selectorId = "heroCoverImageEditor">
<cfif session.isMobile>
	<cfset editorHeight = "325">
<cfelse>
	<cfset editorHeight = "650">
</cfif>
<!--- This string is used by the tiny mce editor to handle image uploads --->
<cfset imageHandlerUrl = application.baseUrl & "/common/cfc/ProxyController.cfc?method=uploadImage&mediaProcessType=heroCoverImage&mediaType=image&postId=" & URL.optArgs & "&selectorId=" & selectorId & "&csrfToken=" & csrfToken>
<cfset contentVar = mediaHtml>
<cfset imageMediaIdField = "imageMediaId">
<cfset imageClass = "entryImage">

<cfif session.isMobile>
	<cfset toolbarString = "undo redo | image | editimage">
<cfelse>
	<cfset toolbarString = "undo redo | image | editimage">
</cfif>
<cfset includeGallery = false>
</cfsilent>
<!--- Include the tinymce js template --->
<cfinclude template="#application.baseUrl#/includes/templates/js/tinyMce.cfm">

<form id="heroCoverImageForm" action="#" method="post" data-role="validator">
<!--- Pass the csrfToken --->
<input type="hidden" name="csrfToken" id="csrfToken" value="<cfoutput>#csrfToken#</cfoutput>" />
<table align="center" class="k-content tableBorder" width="100%" cellpadding="2" cellspacing="0" border="0">
  <cfsilent>
		<!---The first content class in the table should be empty. --->
		<cfset thisContentClass = HtmlUtilsObj.getKendoClass('')>
  </cfsilent>
  <tr height="2px">
	  <td align="left" valign="top" colspan="2" class="border <cfoutput>#thisContentClass#</cfoutput>"></td>
  </tr>
  <!-- Description -->
  <tr valign="middle">
	<td colspan="2" class="<cfoutput>#thisContentClass#</cfoutput>" style="padding: 8px 12px;">
		<span>A real photo to show on cards, listings, and when this post is shared on social media - for a post whose hero is a Gradient, a live Animation, or the auto-generated fallback art (none of which have a real photo of their own to show there). When set, this always takes priority over the Gradient/Animation on cards and social sharing, but never on this post's own page - the live Gradient/Animation there is unaffected. If the post has a real Image/Video/Map/Carousel enclosure instead, that enclosure is used everywhere and this cover image is ignored.</span>
	</td>
  </tr>
  <cfsilent>
  <cfset thisContentClass = HtmlUtilsObj.getKendoClass(thisContentClass)>
  </cfsilent>
  <tr height="2px">
	  <td align="left" valign="top" colspan="2" class="border <cfoutput>#thisContentClass#</cfoutput>"></td>
  </tr>
  <!-- Form content -->
  <tr valign="middle" height="30px">
	<td align="right" class="<cfoutput>#thisContentClass#</cfoutput>" style="width: 20%">Cover Image</td>
	<td align="left" class="<cfoutput>#thisContentClass#</cfoutput>">
		<!--- TinyMce container --->
		<div style="position: relative;">
			<textarea id="<cfoutput>#selectorName#</cfoutput>" name="<cfoutput>#selectorName#</cfoutput>"></textarea>
		</div>
	</td>
  </tr>
  <cfsilent>
  <cfset thisContentClass = HtmlUtilsObj.getKendoClass(thisContentClass)>
  </cfsilent>
  <tr height="2px">
	  <td align="left" valign="top" colspan="2" class="border <cfoutput>#thisContentClass#</cfoutput>"></td>
  </tr>
  <!-- Quality slider -->
  <tr valign="middle">
	<td align="right" class="<cfoutput>#thisContentClass#</cfoutput>" style="width: 20%">Image Quality</td>
	<td align="left" class="<cfoutput>#thisContentClass#</cfoutput>" style="padding: 6px 12px;">
		<div id="imageQualitySlider" style="width: 260px;"></div>
		<span class="k-form-hint">Left = smaller file, right = sharper image.</span>
	</td>
  </tr>
  <cfsilent>
  <cfset thisContentClass = HtmlUtilsObj.getKendoClass(thisContentClass)>
  </cfsilent>
  <tr height="2px">
	  <td align="left" valign="top" colspan="2" class="border <cfoutput>#thisContentClass#</cfoutput>"></td>
  </tr>
  <!-- Form content -->
  <tr valign="middle" height="30px">
	<td valign="bottom" align="right" class="<cfoutput>#thisContentClass#</cfoutput>" style="width: 20%">&nbsp;</td>
	<td valign="bottom" align="left" class="<cfoutput>#thisContentClass#</cfoutput>">
		<button id="heroCoverImageSubmit" name="heroCoverImageSubmit" class="k-button k-primary" type="button" onClick="onHeroCoverImageSubmit();">Submit</button>
	</td>
  </tr>
</table>
</form>
