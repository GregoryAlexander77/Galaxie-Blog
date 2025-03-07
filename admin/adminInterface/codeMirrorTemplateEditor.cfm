	<!---<cfdump var="#URL#">--->
	<!--- The URL.optArg variable determines the themeId for this setting. The URL.otherArgs is a string that indicates the setting being read or modified. --->
	<cfset editorHeight = "420">
	<cfset fileLines = "">
	<!--- Get the theme --->
	<cfset getTheme = application.blog.getTheme(URL.optArgs)>	
	
	<!--- Some of the interfaces have no preview --->
	<cfparam name="showPreviewButton" default="true">
		
	<cfif URL.otherArgs eq 'FavIconHtml' or URL.otherArgs eq 'customHeaderHtml' or URL.otherArgs eq 'customFooterHtml'>
		<cfset showPreviewButton = false>
	</cfif>
	
	<!--- 
	Note: this template can either read a template or get the content using the default content object
	--->
		
	<!--- Instantiate the sting utility object. We are using this to remove empty strings from the code preview. --->
	<cfobject component="#application.stringUtilsComponentPath#" name="StringUtilsObj">
	<!--- Instantiate the default content object to get the preview --->
	<cfobject component="#application.defaultContentObjPath#" name="DefaultContentObj">
	
	<!--- We are not reading a file in for the composite header --->
	<cfset templatePath = ""/>
	<!--- Get the default content. The arguments are: getTheme HQL query, type, isMobileDevice --->
	<cfset fileLines = StringUtilsObj.removeEmptyLinesInStr( DefaultContentObj.getDefaultContentPreview( getTheme, URL.otherArgs, URL.otherArgs1 ) )>	
	<!--- Set the hidden form that we will stuff the the editor value with --->
	<cfset hiddenFormName = URL.otherArgs & "Code">
		
	<!--- This logical branch is only excuted when reading a file --->
	<cfif len(templatePath)>
	
		<!--- Preset vars --->
		<cfset filePath = expandPath(  "#templatePath#" ) />
		<cfset FileLines = "">

		<!--- Open and read the file. --->
		<cfset fileTemplate = fileOpen( filePath, "read" ) />

		<!--- Loop through the contents of the file. --->
		<cfloop condition="!fileIsEOF( fileTemplate )">
			<!--- Read the line and append the data. --->
			<cfset fileLines = fileLines & chr(10) & fileReadLine( fileTemplate ) >
		</cfloop>

		<!--- Close the file. --->
		<cfset fileClose( fileTemplate ) />

	</cfif><!---<cfif len(templatePath)>--->

	<script>
		// Instantiate code mirror
		CodeMirrorEditor = CodeMirror.fromTextArea(document.getElementById("code"), {
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
				// Get the contents of the editor
				var codeMirrorCode = CodeMirrorEditor.getValue();
				// Modify any tags that may be deleted by ColdFusion on the server when using Global Script Protection and place an attach string in front of scripts, styles and meta tags.
				codeMirrorCode = bypassScriptProtection(codeMirrorCode);
				// Stuff the value into a hidden form. 
				$("#<cfoutput>#URL.otherArgs#</cfoutput>Code").val( codeMirrorCode );
				// Close this window
				$('#codeMirrorEditor').kendoWindow('destroy');												  

			});		
			
			// Invoked when the preview button is clicked. 
			var previewCode = $('#previewCodeButton');
			previewCode.on('click', function(e){ 
				e.preventDefault();  
				// Get the contents of the editor
				var newCode = CodeMirrorEditor.getValue();
				// Stuff the value into a hidden form. This hidden form is
				$("#<cfoutput>#URL.otherArgs#</cfoutput>Code").val(newCode);
				// Open the preview window
				createContentOutputPreviewWindow(<cfoutput>#URL.optArgs#,'#URL.otherArgs#',#session.isMobile#</cfoutput>)
			});
		});
	</script>

	<table align="center" width="100%" cellpadding="2" cellspacing="0">
	  <tr>
		<td align="right" style="width: 5%"> 
		</td>
		<td>
			<!-- Editor -->
			<textarea id="code"><cfoutput>#fileLines#</cfoutput></textarea> 
		</td>
		<td align="right" style="width: 5%"> 
		</td>
	  </tr>
	  <tr>
		<td></td>
		<td><hr noshade></td>
		<td></td>
	  </tr>
	  <tr>
		<td></td>
		<td>
		  <button id="saveCodeMirrorCodeSubmit" name="saveCodeMirrorCodeSubmit" class="k-button k-primary" type="button">Submit</button>&nbsp;&nbsp;
		  <cfif showPreviewButton>
			<!--- Preview --->
		  	<button id="previewCodeButton" name="previewCodeButton" class="k-button" type="button">Preview</button>
		  </cfif>
		</td>
		<td>
		  
		</td>
	  </tr>
	  <tr>
		<td></td>
		<td><hr noshade></td>
		<td></td>
	  </tr>
	</table>