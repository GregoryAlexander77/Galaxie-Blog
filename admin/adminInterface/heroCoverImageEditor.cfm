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
upload already has. The slider itself moved to the top of the Upload Image window, window 81 (11-05, owner). --->

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
</style>

<script>
	function onHeroCoverImageSubmit(){
		<!--- The picture deleted from the editor removes the cover, after asking (11-05, owner: deleting it in the preview did nothing). --->
		var coverEditor = window.tinymce && tinymce.get($("#heroCoverImageWindow textarea").first().attr("id"));
		if (<cfoutput>#len(mediaUrl) ? "true" : "false"#</cfoutput> && coverEditor && !$(coverEditor.getBody()).find("img").length && !onHeroCoverImageSubmit.removing) {
			galaxieConfirm("Remove the cover?", "Cards and sharing will use the hero picture if the post has one, or your theme's logo.", function () {
				onHeroCoverImageSubmit.removing = true;
				jQuery.ajax({ type: "post", url: "<cfoutput>#application.baseUrl#</cfoutput>/common/cfc/ProxyController.cfc?method=removeHeroCoverImage", dataType: "json",
					data: { csrfToken: "<cfoutput>#csrfToken#</cfoutput>", postId: <cfoutput>#val(URL.optArgs)#</cfoutput> } })
					.always(function () { onHeroCoverImageSubmit(); onHeroCoverImageSubmit.removing = false; });
			});
			return;
		}
		<!--- Refresh the media preview - pass in the postId --->
		reloadEnclosureThumbnailPreview(<cfoutput>#URL.optArgs#</cfoutput>);
		<!--- And the Hero window's preview, when this was opened from it (11-04: the new cover didn't show there). --->
		if (typeof window.galaxieRefreshHeroEditorPreview === "function") { window.galaxieRefreshHeroEditorPreview(); }
		<!--- And anything else showing the cover, such as the Moving hero wizard's cover step (11-04). --->
		$(document).trigger("galaxieHeroCoverSaved");
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

<!--- Edit picture pops up over the picture when it is clicked (11-05, owner: no ribbon button; the hint below says so). --->
<cfset toolbarString = "undo redo | image">
<!--- No TinyMCE picture tools here (11-05, owner): rotating the preview uploaded a picture of it as the hero, and it took the
moving hero off the post. The previews here aren't the real files (a scene's still, a cover drawn as a background), so the tools
are off, and Edit picture on the ribbon opens the real picture in the Upload Image window's editor instead. --->
<cfset pluginList = "'advlist autolink lists hr link image charmap print preview anchor', 'searchreplace visualblocks code codesample fullscreen', 'insertdatetime media table paste wordcount iconfonts textpattern toc emoticons nonbreaking'">
<cfset includeEditPicture = true>
<cfset editPictureTarget = "cover">
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
		<!--- The rules as they are since the hero pipeline (11-06, owner; Hero.cfc). --->
		<span>The picture for this post's cards and for sharing on Facebook, X, Pinterest and Google. It never shows on the post's own page.</span>
		<ul style="margin: 6px 0 0 18px; padding: 0;">
			<li>A gradient, animation, moving hero or scene: the cover is the picture on cards and when shared.</li>
			<li>A video, map or carousel: cards show the video, map or carousel itself, and the cover is the picture when shared.</li>
			<li>A picture: the hero picture is used everywhere, so the cover isn't needed.</li>
		</ul>
		<div class="k-form-hint">Click the picture to crop, rotate or flip it.</div>
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
  <!-- Form content -->
  <tr valign="middle" height="30px">
	<td valign="bottom" align="right" class="<cfoutput>#thisContentClass#</cfoutput>" style="width: 20%">&nbsp;</td>
	<td valign="bottom" align="left" class="<cfoutput>#thisContentClass#</cfoutput>">
		<button id="heroCoverImageSubmit" name="heroCoverImageSubmit" class="k-button k-primary" type="button" onClick="onHeroCoverImageSubmit();">Submit</button>
	</td>
  </tr>
</table>
</form>
