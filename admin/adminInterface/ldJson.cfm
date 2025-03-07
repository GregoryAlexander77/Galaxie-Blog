<cfsilent>
	<!---<cfdump var="#URL#">--->
		
	<!--- Get the post. The last argument should also show posts that are removed ( getPostByPostId(postId, showPendingPosts, showRemovedPosts) ). --->
	<cfset getPost = application.blog.getPostByPostId(URL.optArgs,true,true)>
	<!---<cfdump var="#getPost#">--->
	<!--- Get the content. This logic is unique to this temlate. Typically, I just use the contentVar  --->
	<cfif len(getPost[1]["JsonLd"])>
		<cfset contentVar = getPost[1]["JsonLd"]>	
	<cfelse>
		<!--- Render the LD JSON --->
		<cfobject component="#application.rendererComponentPath#" name="RendererObj">
		<!--- The true argument will prettify the code for the editor. --->
		<cfset contentVar = RendererObj.renderLdJson(getPost, false)>
		<!---<cfdump var="#jsonLd#">--->
	</cfif>
	<!--- Set the editor name --->
	<cfset editorName = "postJsonLdEditor">
	<!--- Set the name of the window. This is the window specified in the blogJsContent.cfm template that opens the window interface --->
	<cfset windowInterfaceName = "jsonLdWindow">
	<!--- Set the name --->
	<cfset windowTitle = "Post JSON-LD">
	<cfset description = 'LD-JSON is used by the search engines to better understand the structure of your web page. Galaxie Blog automatically generates compressed LD-JSON for your blog postings. You may edit this LD Json here.'>
	<!--- Set the processing URL, typically a cfc --->
	<cfset postUrl = application.baseUrl & "/common/cfc/ProxyController.cfc?method=saveJsonLd&csrfToken=" & csrfToken>
	<!--- What is the post function name? --->
	<cfset postFunctionName = "SaveJSONLd">
	<!--- The server expects a code variable used to append the code to. This is the name of the argument that the server expects to digest the code. --->
	<cfset codeVarOnServer = "jsonLd">
	<!--- Specify the arguments from the URL. There should be at least one argument that needs to be named. These are used to process data server-side and are typically arguments in the cfc (such as postId). If the URL variable is not used leave it blank --->
	<cfset urlOptArgsDataColumn = "postId">
	<cfset urlOtherArgsDataColumn = "">
	<cfset urlOtherArgs1DataColumn = "">
		
	<cfset editorHeight = "420">
</cfsilent>	
<!--- Include the template --->
<cfinclude template="codeMirrorEditor.cfm">