	<!--- Preset the mediaHtml var --->
	<cfparam name="mediaHtml" default="">
	<!---<cfdump var="#URL#">---> 
	
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
	
	<!--- Instantiate the Render.cfc. This will be used to build the HTML for the image if the MediaUrl is present in the database. --->
	<cfobject component="#application.rendererComponentPath#" name="RendererObj">
	<!--- Get the post ( getPostByPostId(postId, showPendingPosts, showRemovedPosts) ) --->
	<cfset getPost = application.blog.getPostByPostId(URL.optArgs,true,true)>
	<!--- <cfdump var="#getPost#"> ---> 
		
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
	<cfset imageHandlerUrl = application.baseUrl & "/common/cfc/ProxyController.cfc?method=uploadImage&mediaProcessType=enclosure&mediaType=image&postId=" & URL.optArgs & "&selectorId=" & selectorId & "&csrfToken=" & csrfToken>
	<cfset contentVar = mediaHtml>
	<cfset imageMediaIdField = "mediaId">
	<cfset imageClass = "entryImage">

	<cfif session.isMobile>
		<cfset toolbarString = "undo redo | image editimage | media videoUpload">
	<cfelse>
		<cfset toolbarString = "undo redo | image editimage | carousel | media videoUpload webVttUpload videoCoverUpload | map mapRouting">
	</cfif>
	<cfset includeCarousel = true>
	<cfset includeVideoUpload = true>
	<cfset disableVideoCoverAndWebVttButtons = true>
	</cfsilent>
	<!--- Include the tinymce js template --->
	<cfinclude template="#application.baseUrl#/includes/templates/js/tinyMce.cfm">
		
	<!--- Include the get-video-id script. This will be used to determine the video provider and the video id --->
	<script src="<cfoutput>#application.baseUrl#</cfoutput>/common/libs/get-video-id/getVideoId.min.js"></script>
	<!---<cfoutput><br/>selectorId: #selectorId#</cfoutput>--->
		
	<script>
		/* Note: the function handles enclosure images, videos, and theme images and needs to be changed according to what is being processed. This particular function handles theme images. Note: the invokedArguments is not used by CF, but shows the location where this function is being called from and the arguments for debugging purposes.
		When using:
		insert edit image:
		the image is retrieved from the source but this function is not called.
		insert media:
		this function is invoked as soon as the user enters a URL into the tinyMce editor. 
		*/
		function saveExternalUrl(url, mediaType, selectorId, invokedArguments){ 
			//alert('saveExternalUrl invoked');
			jQuery.ajax({
				type: 'post', 
				url: '<cfoutput>#application.baseUrl#</cfoutput>/common/cfc/ProxyController.cfc?method=saveExternalMediaEnclosure&template=enclosureImageEditor',
				dataType: "json",
				data: { // arguments
					csrfToken: '<cfoutput>#csrfToken#</cfoutput>',
					selectorId: '<cfoutput>#selectorId#</cfoutput>',
					// Pass the mediaId saved in the mediaId hidden form if it is available
					mediaId: $("#<cfoutput>#imageMediaIdField#</cfoutput>").val(),
					externalUrl: url,
					postId: <cfoutput>#URL.optArgs#</cfoutput>,
					mediaType: 'image',
					imageType: '<cfoutput>#URL.otherArgs#</cfoutput>',
					invokedArguments: invokedArguments
				},
				success: saveExternalUrlResponse,
				error: function(ErrorMsg) {
					console.log('Error' + ErrorMsg);
				}
			// Extract any errors. This is a new jQuery promise based function as of jQuery 1.8.
			}).fail(function (jqXHR, textStatus, error) {

				// The full response is: jqXHR.responseText, but we just want to extract the error.
				$.when(kendo.ui.ExtAlertDialog.show({ title: "Error while consuming the saveExternalMediaEnclosure function", message: error, icon: "k-ext-error", width: "<cfoutput>#application.kendoExtendedUiWindowWidth#</cfoutput>" }) // or k-ext-error, k-ext-information, k-ext-question, k-ext-warning.  You can also specify height.
					).done(function () {
					// Do nothing
				});		
			});
			
			// Refresh the media preview- pass in the postId
			reloadEnclosureThumbnailPreview(<cfoutput>#URL.optArgs#</cfoutput>);
	
		}
											
		function saveExternalUrlResponse(response){ 
			// Note: this does not do anything. I suspect because the tinymce editor is modal mode when it is invoked. This is only used for debugging purposes now
			//alert(response.postId)
			//alert(response. mediaId)
			//alert(response.externalUrl)
			//$("#externalImageUrl").val(response.externalUrl);
		}
		
		function removeMediaEnclosure(){ 
			jQuery.ajax({
				type: 'post', 
				url: '<cfoutput>#application.baseUrl#</cfoutput>/common/cfc/ProxyController.cfc?method=removeMediaEnclosure&template=enclosureImageEditor',
				dataType: "json",
				data: { // arguments
					csrfToken: '<cfoutput>#csrfToken#</cfoutput>',
					postId: <cfoutput>#URL.optArgs#</cfoutput>
				},
				error: function(ErrorMsg) {
					console.log('Error' + ErrorMsg);
				}
			// Extract any errors. This is a new jQuery promise based function as of jQuery 1.8.
			}).fail(function (jqXHR, textStatus, error) {

				// The full response is: jqXHR.responseText, but we just want to extract the error.
				$.when(kendo.ui.ExtAlertDialog.show({ title: "Error while consuming the removeMediaEnclosure function", message: error, icon: "k-ext-error", width: "<cfoutput>#application.kendoExtendedUiWindowWidth#</cfoutput>" }) // or k-ext-error, k-ext-information, k-ext-question, k-ext-warning.  You can also specify height.
					).done(function () {
					// Do nothing
				});		
			});
		}
			
		// Submit the data and close this window.
		function onPostEnclosureSubmit(){
			// Get the editor content
			// Original code that caused problems:
			// var enclosureEditorContent = $("#<cfoutput>#imageMediaIdField#</cfoutput>").val();
			var enclosureEditorContent = tinymce.get("<cfoutput>#selectorName#</cfoutput>").getContent();
			// Get the media URL if it is an existing image
			var externalImageUrl = $("#externalImageUrl").val();
			// If there are no enclosures or an existing media URL, remove any enclosures that exists in the db.
			if (enclosureEditorContent == "" && externalImageUrl == ""){
				removeMediaEnclosure();
			}
			// Refresh the thumbnail image on the post detail page to show the none image
			reloadEnclosureThumbnailPreview(<cfoutput>#URL.optArgs#</cfoutput>);
			// Close the edit window
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
	  <tr height="30px">
		<td align="left" class="<cfoutput>#thisContentClass#</cfoutput>" colspan="2"> 
			The enclosure resides at the top of the blog post and it should take up to 100% of the content width of the blog post. The enclosure can either be a video or an image. Galaxie Blog will automatically adjust your images for Facebook, Twitter, LinkedIn and other social media sites. To upload media, click on the buttons below.
		</td>
	  </tr>
	  <!-- Border -->
	  <tr height="2px">
	    	<td align="left" valign="top" colspan="<cfoutput>#thisColSpan#</cfoutput>" class="<cfoutput>#thisContentClass#</cfoutput>"></td>
	  </tr>
	  <cfsilent>
	  <!--- Set the class for alternating rows. --->
	  <!---After the first row, the content class should be the current class. --->
	  <cfset thisContentClass = HtmlUtilsObj.getKendoClass(thisContentClass)>
	  </cfsilent>
	  <tr height="2px">
		  <td align="left" valign="top" colspan="2" class="border <cfoutput>#thisContentClass#</cfoutput>"></td>
	  </tr>
	  <!-- Form content -->
	  <tr valign="middle" height="30px">
		<td align="left" class="<cfoutput>#thisContentClass#</cfoutput>" colspan="2">
			<!--- TinyMce container --->
			<div style="position: relative;">
				<textarea id="<cfoutput>#selectorName#</cfoutput>" name="<cfoutput>#selectorName#</cfoutput>"></textarea>
			</div>   
		</td>
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
		<td valign="bottom" align="right" class="<cfoutput>#thisContentClass#</cfoutput>">&nbsp;</td>
		<td valign="bottom" align="left" class="<cfoutput>#thisContentClass#</cfoutput>">
			<button id="mediaUploadCompleteButton" name="mediaUploadCompleteButton" class="k-button k-primary" type="button" onClick="javascript:onPostEnclosureSubmit();">Submit</button>
		</td>
	  </tr>
	</table>
	</form>