	<!---<cfdump var="#URL#">--->
		
	<!-- Note: this editor is meant to be generic and used for various purposes. It passes the URL variables (otherArgs, optArgs and optArgs1) to the server. --->
	<!--- 
	Example usage. See codeMirrorEditor.cfm for detailed comments 
	<cfset getPost = application.blog.getPostByPostId(URL.optArgs,true,true)>
	<cfset editorName = "postCss">
	<cfset windowInterfaceName = "postCssWindow">
	<cfset windowTitle = "Post CSS Window">
	<cfset description = 'You may apply custom CSS to a particular post that will over-ride ColdFusion#chr(39)#s built in Global Script Protection. Do not include the opending and ending style tag, the blog will do this for you. If you choose to create your own CSS, make sure that the CSS is not impacting other blog posts on the blog landing page. You may also want to <a href="https://jigsaw.w3.org/css-validator/validator">validate</a> your CSS.'>
	<cfset contentVar = getPost[1]["CSS"]>
	<cfset postUrl = application.baseUrl & "/common/cfc/ProxyController.cfc?method=savePostCss&csrfToken=" & csrfToken>
	<cfset postFunctionName = "PostCss">
	<cfset codeVarOnServer = "postCss">
	<cfset urlOptArgsDataColumn = "postId">
	<cfset urlOtherArgsDataColumn = "">
	<cfset urlOtherArgs1DataColumn = "">
	<cfset editorHeight = "420">
	--->
	
	<!--- Begin generic code editor template --->
	<script>
		// Instantiate code mirror
		CodeMirrorEditor = CodeMirror.fromTextArea(document.getElementById("<cfoutput>#editorName#</cfoutput>"), {
			mode: "text/html",
			autoRefresh: true,
			styleActiveLine: true,
			matchBrackets: true,
			autoCloseBrackets: true,
			smartIndent: true,
			tabSize: 3,
			indentWithTabs: true,
			lineWrapping: true,
			lineNumbers: true,
			readOnly: false,
			autofocus: true
		});
		// setSize( width, height ). An empty string will set the width to 100% of the container
		CodeMirrorEditor.setSize('', <cfoutput>#editorHeight#</cfoutput>); 
		
		$(document).ready(function() {
			
			// Invoked when the submit button is clicked. 
			var saveCodeMirrorCodeSubmit = $('#saveCodeMirrorCodeSubmit');
			saveCodeMirrorCodeSubmit.on('click', function(e){ 
				e.preventDefault();  
				// Post the content
				postCodeMirrorContent();
			});		
			
			function postCodeMirrorContent(){
				
				// Get the contents of the editor
				var codeMirrorCode = CodeMirrorEditor.getValue();
				// Modify any tags that may be deleted by ColdFusion on the server when using Global Script Protection and place an attach string in front of scripts, styles and meta tags.
				codeMirrorCode = bypassScriptProtection(codeMirrorCode);

				jQuery.ajax({
					type: 'post', 
					url: '<cfoutput>#postUrl#</cfoutput>',
					data: { // arguments
						<cfoutput>#urlOptArgsDataColumn#</cfoutput>: <cfoutput>#URL.optArgs#</cfoutput>,
						<cfif len(urlOtherArgsDataColumn)><cfoutput>#urlOtherArgsDataColumn#</cfoutput>: <cfoutput>#URL.otherArgs#</cfoutput>,</cfif>
						<cfif len(urlOtherArgs1DataColumn)><cfoutput>#urlOtherArgs1DataColumn#</cfoutput>: <cfoutput>#URL.otherArgs1#</cfoutput>,</cfif>
						<cfoutput>#codeVarOnServer#</cfoutput>: codeMirrorCode
					},
					dataType: "json",
					success: postCodeMirrorResult, // calls the result function.
					error: function(ErrorMsg) {
						console.log('Error' + ErrorMsg);
					}
				// Extract any errors. This is a new jQuery promise based function as of jQuery 1.8.
				}).fail(function (jqXHR, textStatus, error) {
					// Close the wait window that was launched in the calling function.
					kendo.ui.ExtWaitDialog.hide();
					// Display the error. The full response is: jqXHR.responseText, but we just want to extract the error.
					$.when(kendo.ui.ExtAlertDialog.show({ title: "Error while consuming the <cfoutput>#postFunctionName#</cfoutput> function", message: error, icon: "k-ext-error", width: "<cfoutput>#application.kendoExtendedUiWindowWidth#</cfoutput>" }) // or k-ext-error, k-ext-information, k-ext-question, k-ext-warning.  You can also specify height.
						).done(function () {

					});		
				});
			};

			function postCodeMirrorResult(response){
				// Close this window.
				$('#<cfoutput>#windowInterfaceName#</cfoutput>').kendoWindow('destroy');
			}
		
		});//..document ready
	</script>

	<style>
		textarea {
			border:1px solid #999999;
			width:98%;
			margin:5px 0;
			padding:1%;
		}
	</style>
		
	<form id="codeMirrorEditorForm" action="#" method="post" data-role="validator">
	<!--- Pass the csrfToken --->
	<input type="hidden" name="csrfToken" id="csrfToken" value="<cfoutput>#csrfToken#</cfoutput>" />
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
	  <cfif session.isMobile>
	  <tr valign="middle">
		<td class="<cfoutput>#thisContentClass#</cfoutput>" colspan="2">
			<cfoutput>#windowTitle#</cfoutput>
		</td>
	   </tr>
	<cfelse><!---<cfif session.isMobile>--->
	  <tr height="30px">
		<td align="left" class="<cfoutput>#thisContentClass#</cfoutput>" colspan="2"> 
			<cfoutput>#description#</cfoutput>
		</td>
	  </tr>
	</cfif>
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
	<cfif session.isMobile>
	   <tr>
		<td class="<cfoutput>#thisContentClass#</cfoutput>" colspan="2">
			<!-- Editor -->
			<textarea id="<cfoutput>#editorName#</cfoutput>" name="<cfoutput>#editorName#</cfoutput>"><cfoutput>#contentVar#</cfoutput></textarea> 
		</td>
	  </tr>
	<cfelse><!---<cfif session.isMobile>--->
	  <tr valign="middle">
		<td align="left" colspan="2" class="<cfoutput>#thisContentClass#</cfoutput>">
			<!-- Editor -->
			<textarea id="<cfoutput>#editorName#</cfoutput>" name="<cfoutput>#editorName#</cfoutput>"><cfoutput>#contentVar#</cfoutput></textarea> 
		</td>
	  </tr>
	</cfif>
	  <!-- Border -->
	  <tr height="2px">
		<td align="left" valign="top" colspan="<cfoutput>#thisColSpan#</cfoutput>" class="<cfoutput>#thisContentClass#</cfoutput>"></td>
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
			<button id="saveCodeMirrorCodeSubmit" name="saveCodeMirrorCodeSubmit" class="k-button k-primary" type="button">Submit</button>
		</td>
	  </tr>
	</table>
	</form>