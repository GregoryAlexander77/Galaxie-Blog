<cfsilent>
	<!---<cfdump var="#URL#">--->
		
	<!--- Get the post. The last argument should also show posts that are removed ( getPostByPostId(postId, showPendingPosts, showRemovedPosts) ). --->
	<cfset getPost = application.blog.getPostByPostId(URL.optArgs,true,true)>
	<!---<cfdump var="#getPost#">--->
	<!--- Get the content  --->
	<cfset contentVar = getPost[1]["CSS"]>
	<!---Set the editor name --->
	<cfset editorName = "postCssEditor">
	<!--- Set the name of the window. This is the window specified in the blogJsContent.cfm template that opens the window interface --->
	<cfset windowInterfaceName = "postCssWindow">
	<!--- Set the name --->
	<cfset windowTitle = "Post CSS">
	<cfset description = 'You may apply custom CSS to a particular post that will over-ride ColdFusion#chr(39)#s built in Global Script Protection. Do not include the opending and ending style tag, the blog will do this for you. If you choose to create your own CSS, make sure that the CSS is not impacting other blog posts on the blog landing page. You may also want to <a href="https://jigsaw.w3.org/css-validator/validator">validate</a> your CSS.'>
	<!--- Set the processing URL, typically a cfc --->
	<cfset postUrl = application.baseUrl & "/common/cfc/ProxyController.cfc?method=savePostCss&csrfToken=" & csrfToken>
	<!--- What is the post function name? --->
	<cfset postFunctionName = "PostCss">
	<!--- The server expects a code variable used to append the code to. This is the name of the argument that the server expects to digest the code. --->
	<cfset codeVarOnServer = "postCss">
	<!--- Specify the arguments from the URL. There should be at least one argument that needs to be named. These are used to process data server-side and are typically arguments in the cfc (such as postId). If the URL variable is not used leave it blank --->
	<cfset urlOptArgsDataColumn = "postId">
	<cfset urlOtherArgsDataColumn = "">
	<cfset urlOtherArgs1DataColumn = "">
		
	<cfset editorHeight = "420">
</cfsilent>		
<cfinclude template="codeMirrorEditor.cfm">