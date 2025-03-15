	<cfsilent>
	<!--- URL.optArgs is the postId, URL.otherArgs is the calling interface --->
	<!--- Set the uppy theme. --->
	<cfif darkTheme>
		<cfset uppyTheme = 'dark'>
	<cfelse>
		<cfset uppyTheme = 'light'>
	</cfif>
		
	<!--- The URL.otherArgs specifies whether this used for a gallery (gallery) or carousel (carousel). --->
	<cfif structKeyExists(URL, "otherArgs") and URL.otherArgs eq 'gallery'>
		<!--- Set the selectorId so that we know what interface this request is coming from --->
		<cfset selectorId = "gallery">
		<cfset divId = "galleryUppyUpload">
		<cfset adminInterfaceWindowId = 4>
	<cfelseif structKeyExists(URL, "otherArgs") and URL.otherArgs eq 'carousel'>
		<cfset selectorId = "carousel">
		<cfset divId = "carouselUppyUpload">
		<cfset adminInterfaceWindowId = 51>
	</cfif>
	</cfsilent>
	<form>
	<input type="hidden" name="mediaIdList" id="mediaIdList" value=""/>
	<input type="hidden" name="uppyFileList" id="uppyFileList" value=""/>
	</form>
    <div id="<cfoutput>#divId#</cfoutput>"></div>
    <script>
		var uppy = Uppy.Core({
			restrictions : {
				maxNumberOfFiles: 12,  // limit 12 images
				allowedFileTypes: ['image/*'] // only allow images
        	}
		})
		
		.use(Uppy.Dashboard, {
			theme: '<cfoutput>#uppyTheme#</cfoutput>',
			inline: true,
			target: '#<cfoutput>#divId#</cfoutput>', 
			metaFields: [
				{ id: 'mediaTitle', name: 'Title', placeholder: 'Please enter the image title' }
			],
			proudlyDisplayPoweredByUppy: false,
		})
		
		// Allow users to take pictures via the onboard camera
		.use(Uppy.Webcam, { target: Uppy.Dashboard })
		// Use the built in image editor
		.use(Uppy.ImageEditor, { 
			target: Uppy.Dashboard,
			quality: 0.8 // for the resulting image, 0.8 is a sensible default
		})
		
		// This is used for debugging purposes and can be removed in production
		uppy.on('file-added', (file) => {
			// Store a list of the files in order to preserve the order that they were chosen by
			appendValueToElement(file.name,'uppyFileList')
		})
		
		// Use XHR and send the media to the server for processing. The selectorId ColdFusion var will either be gallery or carousel
		.use(Uppy.XHRUpload, {  
			// Change the name of the form to files instead of the default 'files[]'
			fieldName: 'files',
			// We are using formData in order to pass additonal arguments from the form
			formData: true,
			// Send all files in a single multipart request
			bundle: true,
			endpoint: '<cfoutput>#application.baseUrl#</cfoutput>/common/cfc/ProxyController.cfc?method=uploadImage&mediaProcessType=<cfoutput>#selectorId#</cfoutput>&csrfToken=<cfoutput>#csrfToken#</cfoutput>' 
		})
		.on('upload-success', (file, response) => {
			// Display the error message if available
			if (response.body.errorMessage){
				alert("Error: " + response.body.errorMessage);
			} else {

				// The server is returning location and imageId in a json object. We need to extract these.
				//alert(response.status) // HTTP status code
				//alert(response.body.location) // The full path of the file that was just uploaded to the server
				//alert(response.body.imageId) // The ImageId value saved to the image table in the database.

				/* Unfortunately, due to a documented uppy bug, this implementation is causing this bit of code to be called for every image. We still need to get the file data here and will set the following variable that we will use on the uppy oncomplete method. We could populate a hiden input form with unique values, however, that would require that we test for the existence of the imageId on each iteration. It's more efficient to set this variable every time an image is uploaded and then use it on the on complete method to populate our hidden form. */

				// Set a variable that we will use later in the on complete method to populate the hidden form. This is populated by the json coming back from the server
				jsonResponse = response.body;
			}
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
			$.when(kendo.ui.ExtWaitDialog.show({ title: "Please wait...", message: "Please wait while the images are uploaded.", icon: "k-ext-information" }));
		})
		
		// 4) Error handling
		uppy.on('upload-error', (file, error, response) => {
			// Use a quick set timeout in order for the data to load.
			setTimeout(function() {
				// Close the wait window that was launched in the calling function.
				kendo.ui.ExtWaitDialog.hide();
			}, 500);
			
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
			
			/* The complete event does not return the file information, the result only containes information regarding the operation such as success or fail. We have however set a jsonResponse variable inside of the upload-success method above. We will use this to populate a hidden input in order to pass the image id's to the next interface. */
				
			// a) Dump in the imageId's to the hidden mediaId list and separate the values with underscores. We will use a listGetAt function on the back end to extract the imageId's
			for (i=0; i < jsonResponse.length; i++){
				// alert(jsonResponse[i]['mediaId']);
				// This appends an item to a list inside of a form: appendValueToElement(value, elementId, delimiter)*/
				appendValueToElement(jsonResponse[i]['mediaId'],'mediaIdList','_');
			}

			// b) Close the please wait dialog
			// Use a quick set timeout in order for the data to load.
			setTimeout(function() {
				// Close the wait window that was launched in the calling function.
				kendo.ui.ExtWaitDialog.hide();
			}, 500);
			
			// c) Create a new window in order to put in the fancy box group and the item details (such as the image title)
			createAdminInterfaceWindow(<cfoutput>#adminInterfaceWindowId#,#URL.optArgs#</cfoutput>,$("#mediaIdList").val());
		})		
	
    </script>