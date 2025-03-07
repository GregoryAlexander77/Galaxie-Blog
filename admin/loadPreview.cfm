<cfsetting enablecfoutputonly=true>

<!--- This is designed to be extendable similiarly to the adminInterface.cfm template and takes several arguments: URL.previewId, URL.optArgs, URL.otherArgs, and URL.otherArgs1 --->
<!--- <cfdump var="#URL#" label="url"> --->

<!--- Send the postId in via the URL. --->
<cfparam name="URL.previewId" default="">
<cfparam name="URL.optArgs" default="">
<cfparam name="URL.otherArgs" default="">
<cfparam name="URL.otherArgs1" default="">

<cfswitch expression="#URL.previewId#">
	<cfcase value="1">
		<!--- Instantiate the Render.cfc. This will be used to create video and map thumbnails --->
		<cfobject component="#application.rendererComponentPath#" name="RendererObj">

		<!--- Get the post ( getPostByPostId(postId, showPendingPosts, showRemovedPosts) ) --->
		<cfset getPost = application.blog.getPostByPostId(URL.optArgs,true,true)>
		<!---<cfdump var="#getPost#">--->

		<!--- Get the current blog theme --->
		<cfset kendoTheme = application.blog.getSelectedKendoTheme()>

		<!--- Render the thumnbail HTML. Pass in the getPost obj and if you want to render the thumbnail --->
		<cfset thumbnailHtml = RendererObj.renderMediaPreview(kendoTheme, getPost, true)>

		<cfoutput>
			<!-- Rendered by the /admin/loadPreview.cfm template -->
			#thumbnailHtml#
		</cfoutput>
	</cfcase>
	<cfcase value="2">
	</cfcase>
</cfswitch>