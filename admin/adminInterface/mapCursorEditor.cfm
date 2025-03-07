	<!--- Instantiate the Render.cfc. This will be used to build the HTML for the image if the MediaUrl is present in the database. --->
	<cfobject component="#application.rendererComponentPath#" name="RendererObj">
	
	<!--- Get the post ( getPostByPostId(postId, showPendingPosts, showRemovedPosts) ) --->
	<cfset getPost = application.blog.getPostByPostId(URL.optArgs, true, true)>
	<!---<cfdump var="#getPost#">--->
	<!--- Get the mapId if present. --->
	<cfset mapId = getPost[1]["EnclosureMapId"]>
	<cfif len(mapId)>
		<!--- Get the map --->
		<cfset getMap = application.blog.getMapByMapId(mapId)>
		<!--- Get the current video cover URL --->
		<cfset imageUrl = getMap[1]["CustomMarkerUrl"]>
		<!--- Render the image HTML string --->
		<cfset imageHtml = RendererObj.renderImage(imageUrl)>
	<cfelse>
		<cfset imageUrl = ''>
		<cfset imageHtml = ''>
	</cfif>
		
	<cfset label = "Map Cursor Image">
		
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
		function onImageSubmit(){
			// Use a quick set timeout in order for the data to load.
			setTimeout(function() {
				// Close this window
				jQuery('#cursorImageWindow').kendoWindow('destroy');	
			}, 500);	
		}
	</script>

	<!--- ********************************** Map Cursor Image Editor ******************************** --->
	<cfsilent>
	<cfset selectorId = "mapCursorEditor">
	<cfif session.isMobile>
		<cfset editorHeight = "325">
	<cfelse>
		<cfset editorHeight = "650">
	</cfif>
	<!--- This string is used by the tiny mce editor to handle image uploads --->
	<cfset imageHandlerUrl = application.baseUrl & "/common/cfc/ProxyController.cfc?method=uploadImage&mediaProcessType=mapCursor&mediaType=image&mapId=" & mapId & "&selectorId=" & selectorId & "&csrfToken=" & csrfToken>
	<cfset contentVar = imageHtml>
	<cfset imageMediaIdField = "mapCursorUrl">
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
	<cfif session.isMobile>
	  <tr valign="middle">
		<td class="<cfoutput>#thisContentClass#</cfoutput>" colspan="2">
			<cfoutput><label>#Label#</label></cfoutput>
		</td>
	   </tr>
	   <tr>
		<td class="<cfoutput>#thisContentClass#</cfoutput>" colspan="2">
			<!--- TinyMce container --->
			<div style="position: relative;">
				<textarea id="<cfoutput>#selectorName#</cfoutput>" name="<cfoutput>#selectorName#</cfoutput>"></textarea>
			</div>   
		</td>
	  </tr>
	<cfelse><!---<cfif session.isMobile>--->
	  <tr valign="middle" height="30px">
		  <td align="right"><cfoutput><label>#Label#</label></cfoutput></td>
		<td align="left" class="<cfoutput>#thisContentClass#</cfoutput>" colspan="2">
			<!--- TinyMce container --->
			<div style="position: relative;">
				<textarea id="<cfoutput>#selectorName#</cfoutput>" name="<cfoutput>#selectorName#</cfoutput>"></textarea>
			</div>    
		</td>
	  </tr>
	</cfif>
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
			<button id="imageSubmit" name="imageSubmit" class="k-button k-primary" type="button" onClick="onImageSubmit();">Submit</button>
		</td>
	  </tr>
	</table>
	</form>