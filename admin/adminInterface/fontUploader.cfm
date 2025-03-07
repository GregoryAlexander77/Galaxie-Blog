	<cfsilent>
	<!--- Set the uppy theme. --->
	<cfif darkTheme>
		<cfset uppyTheme = 'dark'>
	<cfelse>
		<cfset uppyTheme = 'light'>
	</cfif>
		
	<!--- Not used yet- Get the kendo primay button color in order to reset the uppy actionBtn--upload color --->
	<cfset primaryButtonColor = application.blog.getPrimaryColorsByTheme(kendoTheme:kendoTheme,setting:'accentColor')>
	<!--- Set the selectorId so that we know what interface this request is coming from --->
	<cfset selectorId = "font">
	</cfsilent>
	<!---<cfoutput>primaryButtonColor: #primaryButtonColor#</cfoutput>--->
	<input type="hidden" name="fontIdList" id="fontIdList" value=""/>
	<p>You may upload woff2 fonts to the server.</p>
	<p>Due to the encrypted nature and the high size of the .ttf and .otf fonts, we are not supporting uploads of these files at this time. In an upcoming version, we will be supporting more font types. If you must use another font, such as a .ttf or an .otf file, please upload these fonts manually to the /common/fonts/ folder and manually create the CSS rules in the /includes/templates/font.cfm template.</p> 
    <div id="fontUppyUpload"></div>
    <script>
		var uppy = Uppy.Core({
			restrictions : {
				maxNumberOfFiles: 36,  // limit 36 files
				allowedFileTypes: ['.woff2','.woff'] // only allow web fonts
        	}
		})
		.use(Uppy.Dashboard, {
			theme: '<cfoutput>#uppyTheme#</cfoutput>',
			inline: true,
			target: '#fontUppyUpload',
			proudlyDisplayPoweredByUppy: false
		})
		
		// Use XHR and send the media to the server for processing
		.use(Uppy.XHRUpload, { endpoint: '<cfoutput>#application.baseUrl#</cfoutput>/common/cfc/ProxyController.cfc?method=uploadFont&csrfToken=<cfoutput>#csrfToken#</cfoutput>' })
		.on('upload-success', (file, response) => {
			// The server is returning location and mediaId in a json object. We need to extract these.
			//alert(response.status) // HTTP status code
			//alert(response.body.location) // The full path of the file that was just uploaded to the server
			//alert(response.body.mediaId) // The MediaId value saved to the Media table in the database.
			
			// Dump in the font Id's to the hidden fontId list and separate the values with underscores. We will use a listGetAt function on the back end to extract the Id's
			// If there are any fontIds in the form, separtate the new Id with an underscore.
			fontIdList = $("#fontIdList").val();
			if ( fontIdList.length > 0){
				newFontIdList = newFontIdList + "_" + response.body.fontId;
			} else {
				newFontIdList = response.body.fontId;
			}
			// Dump the list into the hidden form. This will get passed to the new media item window.
			$("#fontIdList").val(newFontIdList);
		})
		
		// Events
		// 1) When the dashboard icon is clicked
		// Note: there is no event when the dashboard my device button is clicked. This is a work-around. We are going to use jquery's on click event and put in the class of the button. This is required as the uppy button does not have an id.
		$(".uppy-Dashboard-input").on('click', function(event){
			$.when(kendo.ui.ExtWaitDialog.show({ title: "Please wait...", message: "Please wait for the file uploader interface to respond.", icon: "k-ext-information" }));
		});
		
		// 2) When a file has been uploaded to uppy
		uppy.on('file-added', (file) => {
		  	// Close the wait window that was launched in the calling function.
			kendo.ui.ExtWaitDialog.hide();
		})
		
		// 3) When the upload button was pressed
		uppy.on('upload', (data) => {
			$.when(kendo.ui.ExtWaitDialog.show({ title: "Please wait...", message: "Please wait while the fonts are uploaded.", icon: "k-ext-information" }));
		})
		
		// 4) Error handling
		uppy.on('upload-error', (file, error, response) => {
			// Alert the user
			$.when(kendo.ui.ExtYesNoDialog.show({ 
				title: "Upload failed",
				message: "The following error was encountered: " + error + ". Do you want to retry the upload?",
				icon: "k-ext-warning",
				width: "<cfoutput>#application.kendoExtendedUiWindowWidth#</cfoutput>", 
				height: "215px"
			})
			).done(function (response) { // If the user clicked 'yes', retry.
				if (response['button'] == 'Yes'){// remember that js is case sensitive.
					// Retry
					uppy.retryUpload(file.id);
				}//..if (response['button'] == 'Yes'){
			});	
		})

		// 5) When the upload is complete to the server
		uppy.on('complete', (result) => {
			// Close the please wait dialog
			// Use a quick set timeout in order for the data to load.
			setTimeout(function() {
				// Close the wait window that was launched in the calling function.
				kendo.ui.ExtWaitDialog.hide();
			}, 500);
			// Create a new window in order to put in the fancy box group and the item details (such as the font name)
			createAdminInterfaceWindow(32, $("#fontIdList").val());
		})
	
    </script>