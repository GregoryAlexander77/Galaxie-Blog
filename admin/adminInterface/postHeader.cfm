<cfsilent>
	<!---<cfdump var="#URL#">--->
		
	<!--- Get the post. The last argument should also show posts that are removed ( getPostByPostId(postId, showPendingPosts, showRemovedPosts) ). --->
	<cfset getPost = application.blog.getPostByPostId(URL.optArgs,true,true)>
	<!---<cfdump var="#getPost#">--->
	<!--- Get the content  --->
	<cfset contentVar = getPost[1]["PostHeader"]>
	<!--- Set the editor name --->
	<cfset editorName = "postHeaderEditor">
	<!--- Set the name of the window. This is the window specified in the blogJsContent.cfm template that opens the window interface --->
	<cfset windowInterfaceName = "postHeaderWindow">
	<!--- Set the name --->
	<cfset windowTitle = "Post Header">
	<cfset description = 'The Post Header is used to attach <b>optional</b> code, such as Javascript, CSS, ColdFusion cfincludes, and Galaxie Blog Directives to a post. It is designed to keep the logic separate from the WYSIWYG Post Editor as the editor manipulates the DOM and HTML. You may also use <a href="https://gregoryalexander.com/blog/2019/12/14/Galaxie-Blog-XML-Post-Directives">Galaxie Blog Directives</a> to override ColdFusion#chr(39)#s the Global Script Protection if it is turned on.<br/>Including scripts requires an opening and closing <attachSript></attachSript> tags to avoid the global script protection, however, you can use CSS style tags without any modifications'>
	<!--- Set the processing URL, typically a cfc --->
	<cfset postUrl = application.baseUrl & "/common/cfc/ProxyController.cfc?method=savePostHeader&csrfToken=" & csrfToken>
	<!--- What is the post function name? --->
	<cfset postFunctionName = "SavePostHeader">
	<!--- The server expects a code variable used to append the code to. This is the name of the argument that the server expects to digest the code. --->
	<cfset codeVarOnServer = "postHeader">
	<!--- Specify the arguments from the URL. There should be at least one argument that needs to be named. These are used to process data server-side and are typically arguments in the cfc (such as postId). If the URL variable is not used leave it blank --->
	<cfset urlOptArgsDataColumn = "postId">
	<cfset urlOtherArgsDataColumn = "">
	<cfset urlOtherArgs1DataColumn = "">
		
	<cfset editorHeight = "420">
</cfsilent>	
<!--- Include the template --->
<cfinclude template="codeMirrorEditor.cfm">