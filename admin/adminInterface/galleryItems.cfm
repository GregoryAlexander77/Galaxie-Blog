	<!---  Replace the underscore with a comma so that we can use it in the query below. --->
	<cfset mediaIdList = replaceNoCase(URL.otherArgs, '_', ',', 'all')>
	
	<!--- Get the data from the db --->
	<cfquery name="getMediaUrl" dbtype="hql">
		SELECT new Map (
			MediaId as MediaId,
			MediaUrl as MediaUrl,
			MediaThumbnailUrl as MediaThumbnailUrl
		)
		FROM Media
		WHERE MediaId IN (<cfqueryparam value="#mediaIdList#" cfsqltype="integer" list="yes">)
	</cfquery>
	<!--- 
	Debugging:<br/>
	<cfoutput>mediaIdList: #mediaIdList#</cfoutput>
	<cfdump var="#getMediaUrl#"></cfdump>
	--->
		
	<h4>Please enter titles for each item in this gallery</h4>
	
	<form id="galleryDetail" name="galleryDetail" data-role="validator">
	<!--- Pass the csrfToken --->
	<input type="hidden" name="csrfToken" id="csrfToken" value="<cfoutput>#csrfToken#</cfoutput>" />
	<!--- Hidden input to pass the mediaIdList --->
	<input type="hidden" name="mediaIdList" id="mediaIdList" value="<cfoutput>#URL.otherArgs#</cfoutput>">
	<!--- Store the number of galleries that were created by the user. We'll increment this for every gallery --->
	<input type="hidden" name="numGalleries" id="numGalleries" value="1">
	<table align="left" class="k-content tableBorder" width="100%" cellpadding="5" cellspacing="0">
	<cfif not arrayLen(getMediaUrl)>
		<tr>
			<td class="k-header">
			<cfoutput>There are no recent uploads.</cfoutput>
			</td>
		</tr>
	</cfif><!---<cfif not getMediaUrl.recordCount>--->
	<cfloop from="1" to="#arrayLen(getMediaUrl)#" index="i"><cfoutput>
		<cfsilent>
			<!--- Set the variable values. I want to shorten the long variable names here. --->
			<cfset mediaId = getMediaUrl[i]["MediaId"]>
			<cfset mediaUrl = getMediaUrl[i]["MediaUrl"]>
			<cfset mediaThumbnailUrl = getMediaUrl[i]["MediaThumbnailUrl"]>
			<!--- Get the thumbnail image if possible. When the blog is upgraded from version 1x, there will be no thumbnails. This is a new feature in v2. --->
			<cfif len(mediaThumbnailUrl)>
				<cfset imageUrl = mediaThumbnailUrl>
			<cfelse>
				<cfset imageUrl = mediaUrl>
			</cfif>
		</cfsilent>
		<!--- Pass along the imageUrl's in a hidden form  --->
		<input type="hidden" name="mediaUrl<cfoutput>#i#</cfoutput>" id="mediaUrl<cfoutput>#i#</cfoutput>" value="<cfoutput>#mediaUrl#</cfoutput>">
		<tr class="#iif(i MOD 2,DE('k-content'),DE('k-alt'))#" height="50px;">
	<cfsilent>		
	<!--- //************************************************************************************************
			Mobile Gallery Items
	//**************************************************************************************************--->
	</cfsilent>
	<cfif session.isMobile>
		<!--- Create alternating rows in the table. The Kendo classes which we will use are k-alt and k-content.
		We will create a border between the rows if the current row is not the first row. --->
		<cfif i eq 1>
			<td valign="top" width="90%">
		<cfelse>
			<td align="left" valign="top" class="border" width="90%">
		</cfif>
				<a class="fancybox-effects" href="<cfoutput>#imageUrl#</cfoutput>"><img data-src="<cfoutput>#imageUrl#</cfoutput>" alt="" class="fade thumbnail lazied shown" data-lazied="IMG" src="<cfoutput>#imageUrl#</cfoutput>"></a>
			</td>
		</tr>
		<tr>
			<td><label for="mediaItemTitle<cfoutput>#i#</cfoutput>">Title:</label></td>
		</tr>
		<tr>
			<td>
				<input type="text" name="mediaItemTitle<cfoutput>#i#</cfoutput>" id="mediaItemTitle<cfoutput>#i#</cfoutput>" value="" class="k-textbox" required style="width: 100%;">
			</td>
		</tr>
		<tr>
			<td class="border k-alt"><label for="mediaItemUrl<cfoutput>#i#</cfoutput>">URL Link:</label></td>
		</tr>
		<tr>
			<td class="k-alt"><input type="text" name="mediaItemUrl<cfoutput>#i#</cfoutput>" id="mediaItemUrl<cfoutput>#i#</cfoutput>" value="<cfoutput>#mediaUrl#</cfoutput>" class="k-textbox" style="width: 100%;"></td>
		</tr>
	<cfsilent>		
	<!--- //************************************************************************************************
			Desktop Gallery Items
	//**************************************************************************************************--->
	</cfsilent>
	<cfelse><!---<cfif session.isMobile>--->
		<!--- Create alternating rows in the table. The Kendo classes which we will use are k-alt and k-content.
		We will create a border between the rows if the current row is not the first row. --->
		<cfif i eq 1>
			<td valign="top" width="240px">
		<cfelse>


			<td align="left" valign="top" class="border" width="240px">
		</cfif>
			<a class="fancybox-effects" href="<cfoutput>#imageUrl#</cfoutput>"><img data-src="<cfoutput>#imageUrl#</cfoutput>" alt="" class="fade thumbnail lazied shown" data-lazied="IMG" src="<cfoutput>#imageUrl#</cfoutput>"></a>
		</td>
		<cfif i eq 1>
			<td valign="top">
		<cfelse>
			<td align="left" valign="top" class="border">
		</cfif>
				<table align="left" class="k-content" width="100%" cellpadding="5" cellspacing="0" border="2">
					<tr>
						<td><label for="mediaItemTitle<cfoutput>#i#</cfoutput>">Title:</label></td>
					</tr>
					<tr>
						<td>
							<input type="text" name="mediaItemTitle<cfoutput>#i#</cfoutput>" id="mediaItemTitle<cfoutput>#i#</cfoutput>" value="" class="k-textbox" required style="width: 100%;">
						</td>
					</tr>
					<tr>
						<td class="border k-alt"><label for="mediaItemUrl<cfoutput>#i#</cfoutput>">URL Link:</label></td>
					</tr>
					<tr>
						<td class="k-alt"><input type="text" name="mediaItemUrl<cfoutput>#i#</cfoutput>" id="mediaItemUrl<cfoutput>#i#</cfoutput>" value="<cfoutput>#mediaUrl#</cfoutput>" class="k-textbox" style="width: 100%;"></td>
					</tr>
				</table>
			</td>
		</tr>
	</cfif><!---<cfif session.isMobile>--->
	</cfoutput></cfloop>
		<tr>
		<!--- Create alternating rows in the table. The Kendo classes which we will use are k-alt and k-content.
		We will create a border between the rows if the current row is not the first row. --->
		<cfif i eq 1>
			<td valign="top" <cfif not session.isMobile>colspan="2"</cfif>>
		<cfelse>
			<td align="left" valign="top" <cfif not session.isMobile>colspan="2"</cfif>>
		</cfif>
				<button id="galleryDetailSubmit" class="k-button k-primary" type="button">Submit</button>
			</td>
		</tr>
	</table>
				
	</form>
				
	<script>
		$(document).ready(function() {
			// !!! Note on the validators, all forms need a name attribute, otherwise the positioning of the messages will not work. --->
			var GalleryDetailFormValidator = $("#galleryDetail").kendoValidator({
				// Set up custom validation rules 
				rules: {
				<cfloop from="1" to="#arrayLen(getMediaUrl)#" index="i">
					<cfsilent>
						<!--- Set the variable values. I want to shorten the long variable names here. --->
						<cfset mediaId = getMediaUrl[i]["MediaId"]>
					</cfsilent>
					// mediaTitle
					mediaItemTitle<cfoutput>#i#</cfoutput>:
					function(input){
						if (input.is("[id='mediaItemTitle<cfoutput>#i#</cfoutput>']") && $.trim(input.val()).length < 4){
							// Display an error on the page.
							input.attr("data-mediaItemTitle<cfoutput>#i#</cfoutput>Required-msg", "The title field must be at least 4 characters");
							// Focus on the current element
							$( "#mediaItemTitle<cfoutput>#i#</cfoutput>" ).focus();
							return false;
						}                                    
						return true;
					},
					</cfloop>
				}
			}).data("kendoValidator");
		
			// Invoked when the submit button is clicked. Insted of using '$("form").submit(function(event) {' and 'event.preventDefault();', We are using direct binding here to speed up the event.
			var galleryDetailSubmit = $('#galleryDetailSubmit');
			galleryDetailSubmit.on('click', function(e){      
                e.preventDefault();         
				if (GalleryDetailFormValidator.validate()) {
					// submit the form.
					// Note: when testing the ui validator, comment out the post line below. It will only validate and not actually do anything when you post.
					// alert('posting');
					postGalleryDetails('update');
				} else {
					$.when(kendo.ui.ExtAlertDialog.show({ title: "There are errors", message: "Required fields are missing.", width: "<cfoutput>#application.kendoExtendedUiWindowWidth#</cfoutput>", icon: "k-ext-warning" }) // or k-ext-error, k-ext-question
						).done(function () {
						// Do nothing
					});
				}
			});
		});//...document.ready
		
		// Post method on the detail form called from the GalleryDetailFormValidator method on the detail page. The action variable will either be 'update' or 'insert'.
		function postGalleryDetails(action){
			jQuery.ajax({
				type: 'post', 
				url: '<cfoutput>#application.baseUrl#</cfoutput>/common/cfc/ProxyController.cfc?method=saveGallery&selectorId=gallery&darkTheme=<cfoutput>#darkTheme#</cfoutput>&csrfToken=<cfoutput>#csrfToken#</cfoutput>',
				// Serialize the galleryDetail form. The csrfToken is in the form.
				data: $('#galleryDetail').serialize(),
				// This is one of the few times that we will be sending back an html response. We are going to use this directly to set the content in the editor. its easier to craft the html on the server side than to manipulate the dom with a json object on the client. Normally this is always json
				dataType: "html",
				success: galleryUpdateResult, // calls the result function.
				error: function(ErrorMsg) {
					console.log('Error' + ErrorMsg);
				}
			// Extract any errors. This is a new jQuery promise based function as of jQuery 1.8.
			}).fail(function (jqXHR, textStatus, error) {
				// This is a secured function. Display the login screen.
				if (jqXHR.status === 403) { 
					createLoginWindow(); 
				} else {//...if (jqXHR.status === 403) { 
					// The full response is: jqXHR.responseText, but we just want to extract the error.
					$.when(kendo.ui.ExtAlertDialog.show({ title: "Error while consuming the saveGallery function", message: error, icon: "k-ext-error", width: "<cfoutput>#application.kendoExtendedUiWindowWidth#</cfoutput>" }) // or k-ext-error, k-ext-information, k-ext-question, k-ext-warning.  You can also specify height.
						).done(function () {
					// Do nothing
					});		
				}//...if (jqXHR.status === 403) { 
			});
		};
		
		function galleryUpdateResult(response){
			// alert(response)
			// Note: the response is an html string 
			
			// Get the numGalleries value in the hidden form. It starts at 1. This is used to determine what id we should use in our hidden inputs that are created on the fly here.
			var galleryNum = $("#numGalleries").val();
			// Insert an iframe into the editor
			// $("#dynamicGalleryLabel").append('Gallery ' + galleryNum + ' Preview');
			// Show the preview row and insert content into the preview div
			// $("#dynamicGalleryInputFields").append(response);
			// Finally insert the content into the active tinymce editor. The response here is plain HTML coming from the server
			//$('textarea.post').html('Some contents...');
			tinymce.activeEditor.insertContent(response + '<br/><br/>');
			
			// Close all of the windows associated with the gallery
			// Close the uppy dashboard
			$('#galleryWindow').kendoWindow('destroy');
			// Close the gallery items window
			$('#galleryItemsWindow').kendoWindow('destroy');
			
			// Refresh the <cfif application.kendoCommercial>kendo<cfelse>jsgrid</cfif> grid 
		<cfif application.kendoCommercial and 1 eq 2><!---We are not using the Kendo grids right now.--->
			$('#commentsGrid').data('kendoGrid').dataSource.read();
		<cfelse>
			$("#commentsGrid").jsGrid("loadData");
		</cfif>
			// Close the comment window
			//jQuery('#commentDetailWindow').kendoWindow('destroy');
		}
		
	</script>