	<!--- Instantiate the Render.cfc. This will be used to build the HTML for the image if the MediaUrl is present in the database. --->
	<cfobject component="#application.rendererComponentPath#" name="RendererObj">
	<!--- Get the post ( getPostByPostId(postId, showPendingPosts, showRemovedPosts) )--->
	<cfset getPost = application.blog.getPostByPostId(URL.optArgs,true,true)>
	<!---<cfdump var="#getPost#">--->
		
	<!--- Get the current video cover URL --->
	<cfif len(getPost[1]["MediaVideoCoverUrl"])>
		<cfset mediaUrl = getPost[1]["MediaVideoCoverUrl"]>
	<cfelse>
		<cfset mediaUrl = "">
	</cfif>
		
	<!--- Render the image HTML string --->
	<cfset mediaHtml = RendererObj.renderEnclosureImage(mediaUrl)>
	
	<!--- See if there is a local video --->
	<cfif getPost[1]["MediaType"] neq 'Video - Large'>
		<p>Before adding an image to cover a video, you must have uploaded a local video. Please upload a video by clicking on the video icon in the editor.</p>
	<cfelse>	
	
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
			function onVideoImageCoverSubmit(){
				// Refresh the media preview- pass in the postId
				reloadEnclosureThumbnailPreview(<cfoutput>#URL.optArgs#</cfoutput>);
				// Use a quick set timeout in order for the data to load.
				setTimeout(function() {
					// Close this window
					jQuery('#videoCoverWindow').kendoWindow('destroy');	
				}, 500);	
			}
		</script>

		<!--- ********************************** Video Cover Editor ******************************** --->
		<cfsilent>
		<cfset selectorId = "videoCoverEditor">
		<cfif session.isMobile>
			<cfset editorHeight = "325">
		<cfelse>
			<cfset editorHeight = "650">
		</cfif>
		<!--- This string is used by the tiny mce editor to handle image uploads --->
		<cfset imageHandlerUrl = application.baseUrl & "/common/cfc/ProxyController.cfc?method=uploadImage&mediaProcessType=mediaVideoCoverUrl&mediaType=image&postId=" & URL.optArgs & "&selectorId=" & selectorId & "&csrfToken=" & csrfToken>
		<cfset contentVar = mediaHtml>
		<cfset imageMediaIdField = "imageMediaId">

		<cfset imageClass = "entryImage">

		<cfif session.isMobile>
			<cfset toolbarString = "undo redo | image | editimage ">
		<cfelse>
			<cfset toolbarString = "undo redo | image | editimage">
		</cfif>
		<cfset includeGallery = false>
		<cfset includeVideoUpload = true>
		</cfsilent>
		<!--- Include the tinymce js template --->
		<cfinclude template="#application.baseUrl#/includes/templates/js/tinyMce.cfm">

		<form id="enclosureForm" action="#" method="post" data-role="validator">
		<!--- Pass the csrfToken --->
		<input type="hidden" name="csrfToken" id="csrfToken" value="<cfoutput>#csrfToken#</cfoutput>" />
		<!--- Input for any new videos that have been uploaded --->
		<input type="hidden" name="videoCoverMediaId" id="videoCoverMediaId" value="" />
		<table align="center" class="k-content tableBorder" width="100%" cellpadding="2" cellspacing="0" border="0">
		  <cfsilent>
				<!---The first content class in the table should be empty. --->
				<cfset thisContentClass = HtmlUtilsObj.getKendoClass('')>
				<!--- Set the colspan property for borders --->
				<cfset thisColSpan = "2">
		  </cfsilent>
		  <tr height="2px">
			  <td align="left" valign="top" colspan="2" class="border <cfoutput>#thisContentClass#</cfoutput>"></td>
		  </tr>
		  <!-- Form content -->
		  <tr valign="middle" height="30px">
			<td align="right" width="25%">Video Cover Image</td>
			<td align="left" width="75%" class="<cfoutput>#thisContentClass#</cfoutput>" colspan="2">
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
				<button id="videoCoverSubmit" name="videoCoverSubmit" class="k-button k-primary" type="button" onClick="onVideoImageCoverSubmit();">Submit</button>
			</td>
		  </tr>
		</table>
		</form>
	</cfif>	