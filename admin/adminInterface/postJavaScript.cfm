<cfsilent>
	<!---<cfdump var="#URL#">--->
		
	<!--- Get the post. The last argument should also show posts that are removed ( getPostByPostId(postId, showPendingPosts, showRemovedPosts) ). --->
	<cfset getPost = application.blog.getPostByPostId(URL.optArgs,true,true)>
	<!---<cfdump var="#getPost#">--->
	<!--- Get the content  --->
	<cfset contentVar = getPost[1]["JavaScript"]>
	<!--- Set the editor name --->
	<cfset editorName = "postJavaScriptEditor">
	<!--- Set the name of the window. This is the window specified in the blogJsContent.cfm template that opens the window interface --->
	<cfset windowInterfaceName = "postJavaScriptWindow">
	<!--- Set the name --->
	<cfset windowTitle = "Post JavaScript">
	<cfset description = 'You may insert scripts that will over-ride ColdFusion#chr(39)#s built in Global Script Protection. Do not include the opending and ending tags, the blog will do this for you. Be careful when inserting a script, the script may interfere with the rendering of the page if there are errors. You may want to <a href="https://codebeautify.org/jsvalidate">validate</a> your script before posting.'>
	<!--- Set the processing URL, typically a cfc --->
	<cfset postUrl = application.baseUrl & "/common/cfc/ProxyController.cfc?method=savePostJavaScript&csrfToken=" & csrfToken>
	<!--- What is the post function name? --->
	<cfset postFunctionName = "SavePostJavaScript">
	<!--- The server expects a code variable used to append the code to. This is the name of the argument that the server expects to digest the code. --->
	<cfset codeVarOnServer = "postJavaScript">
	<!--- Specify the arguments from the URL. There should be at least one argument that needs to be named. These are used to process data server-side and are typically arguments in the cfc (such as postId). If the URL variable is not used leave it blank --->
	<cfset urlOptArgsDataColumn = "postId">
	<cfset urlOtherArgsDataColumn = "">
	<cfset urlOtherArgs1DataColumn = "">
		
	<cfset editorHeight = "420">
</cfsilent>	
<!--- Include the template --->
<cfinclude template="codeMirrorEditor.cfm">