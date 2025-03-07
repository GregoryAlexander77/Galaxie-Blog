	<!---  Replace the underscore with a comma so that we can use it in the query below. --->
	<cfset mediaIdList = replaceNoCase(URL.otherArgs, '_', ',', 'all')>
	<cfset primaryColor = application.blog.getPrimaryColorsByTheme(kendoTheme:kendoTheme,setting:'accentColor')>
	<cfset fontId = getTheme[1]["BlogNameFontId"]>
	
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

	<h4>Carousel Titles and Body</h4>
	<p>This is optional and the title and body may use HTML. If you enter text or HTML, the text will overlay the images on each carousel.</p>
	<form id="carouselDetail" name="carouselDetail" data-role="validator">
	<!--- Pass the csrfToken --->
	<input type="hidden" name="csrfToken" id="csrfToken" value="<cfoutput>#csrfToken#</cfoutput>" />
	<!--- Pass the postId --->
	<input type="hidden" name="postId" id="postId" value="<cfoutput>#URL.optArgs#</cfoutput>" />
	<!--- Hidden input to pass the mediaIdList --->
	<input type="hidden" name="mediaIdList" id="mediaIdList" value="<cfoutput>#URL.otherArgs#</cfoutput>">
	<!--- Store the number of galleries that were created by the user. We'll increment this for every gallery --->
	<input type="hidden" name="numGalleries" id="numGalleries" value="1">
	<table align="left" class="k-content tableBorder" width="100%" cellpadding="5" cellspacing="0">
		<tr>
			<td><label for="carouselEffect">Effect:</label></td>
			<td>
				<script>
					$("#effect").kendoDropDownList({ });
				</script>
				<select name="effect" id="effect" name="effect">
					<option value="GL">GL</option>
					<option value="slide">slide</option>
					<option value="fade">fade</option>
					<option value="cube">cube</option>
					<option value="flip">flip</option>
					<option value="coverflow">coverflow</option>
					<option value="cards">cards</option>
					<option value="panorama">panorama</option>
					<option value="carousel">carousel</option>
					<option value="shutters">shutters</option>
					<option value="slicer">slicer</option>
					<option value="tinder">tinder</option>
					<option value="material">material</option>
					<option value="creative">creative</option>
				</select>
			</td>
		</tr>
		<tr>
			<td class="border k-alt"><label for="shader">Carousel Shader:</label></td>
			<td class="k-alt">
				<script>
					$("#shader").kendoDropDownList({
					});
				</script>
				<select name="shader" id="shader" name="shader">
					<option value="random">random</option>
					<option value="dots">dots</option>
					<option value="flyeye">flyeye</option>
					<option value="morph x">morph x</option>
					<option value="morph y">morph y</option>
					<option value="page curl">page curl</option>
					<option value="peel x">peel x</option>
					<option value="peel y">peel y</option>
					<option value="polygons fall">polygons fall</option>
					<option value="polygons morph">polygons morph</option>
					<option value="polygons wind">polygons wind</option>
					<option value="pixelize">pixelize</option>
					<option value="ripple">ripple</option>
					<option value="shutters">shutters</option>
					<option value="slices">slices</option>
					<option value="squares">squares</option>
					<option value="stretch">stretch</option>
					<option value="wave x">wave x</option>
					<option value="wind">wind</option>
				</select>
			</td>
		</tr>
		<tr>
			<td class="border"><label for="carouselFontDropdown">Carousel Font:</label></td>
			<td>
				<script>
					// ---------------------------- font dropdowns. ----------------------------
					var fontDs = new kendo.data.DataSource({
						transport: {
							read: {
								cache: false,
								// Note: since this template is in a different directory, we can't specify the cfc template without the full path name.
								url: function() { // The cfc component which processes the query and returns a json string. 
									return "<cfoutput>#application.baseUrl#</cfoutput>/common/cfc/ProxyController.cfc?method=getFontsForDropdown&csrfToken=<cfoutput>#csrfToken#</cfoutput>"; 
								}, 
								dataType: "json",
								contentType: "application/json; charset=utf-8", // Note: when posting json via the request body to a coldfusion page, we must use this content type or we will get a 'IllegalArgumentException' on the ColdFusion processing page.
								type: "GET" //Note: for large payloads coming from the server, use the get method. The post method may fail as it is less efficient.
							}
						} //...transport:
					});//...var fontDs...


					// Create the blog namedropdown
					var carouselFontDropdown = $("#carouselFontDropdown").kendoDropDownList({
						optionLabel: "Select...",
						autoBind: false,
						dataTextField: "Font",
						dataValueField: "FontId",
						template: '<label style="font-family:#:data.FontFace#">#:data.Font#</label>',
						// Template to add a new type when no data was found.
						noDataTemplate: $("#addFont").html(),
						filter: "contains",
						dataSource: fontDs,
					}).data("kendoDropDownList");
					
					var dropdownlist = $("#carouselFontDropdown").data("kendoDropDownList");
					dropdownlist.value("<cfoutput>#fontId#</cfoutput>");
				</script>
				<select id="carouselFontDropdown" name="carouselFontDropdown" style="width: 50%"></select>
			</td>
		</tr>
	
	<cfloop from="1" to="#arrayLen(getMediaUrl)#" index="i">
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
		<input type="hidden" name="mediaItemUrl<cfoutput>#i#</cfoutput>" id="mediaItemUrl<cfoutput>#i#</cfoutput>" value="<cfoutput>#mediaUrl#</cfoutput>">
		<tr class="#iif(i MOD 2,DE('k-content'),DE('k-alt'))#" height="50px;">
	<cfsilent>		
	<!--- //************************************************************************************************
			Mobile Carousel Items
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
			<td><label for="carouselTitle<cfoutput>#i#</cfoutput>">Title:</label></td>
		</tr>
		<tr>
			<td>
				<textarea name="carouselTitle<cfoutput>#i#</cfoutput>" id="carouselTitle<cfoutput>#i#</cfoutput>" value="" class="k-textbox" style="width: 100%;"></textarea>
			</td>
		</tr>
		<tr>
			<td class="border k-alt"><label for="mediaItemUrl<cfoutput>#i#</cfoutput>">Carousel Body:</label></td>
		</tr>
		<tr>
			<td class="k-alt">
				<textarea name="carouselBody<cfoutput>#i#</cfoutput>" id="carouselBody<cfoutput>#i#</cfoutput>" value="" class="k-textbox" style="width: 100%;"></textarea>
			</td>
		</tr>
		<tr>
			<td class="border k-alt"><label for="mediaItemUrl<cfoutput>#i#</cfoutput>">Carousel URL:</label></td>
		</tr>
	<cfsilent>		
	<!--- //************************************************************************************************
			Desktop Carousel Items
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
						<td><label for="carouselTitle<cfoutput>#i#</cfoutput>">Carousel Title:</label></td>
					</tr>
					<tr>
						<td>
							<textarea name="carouselTitle<cfoutput>#i#</cfoutput>" id="carouselTitle<cfoutput>#i#</cfoutput>" value="" class="k-textbox" style="width: 100%;"></textarea>
						</td>
					</tr>
					<tr>
						<td class="border k-alt"><label for="carouselBody<cfoutput>#i#</cfoutput>">Carousel Body:</label></td>
					</tr>
					<tr>
						<td class="k-alt">
							<textarea name="carouselBody<cfoutput>#i#</cfoutput>" id="carouselBody<cfoutput>#i#</cfoutput>" value="" class="k-textbox" style="width: 100%;"></textarea>
						</td>
					</tr>
					<tr>
						<td>
							<table align="left" class="k-content" width="100%" cellpadding="5" cellspacing="0" border="0">
								<tr>
									<td style="width: 15%">
										<label for="carouselFontColor<cfoutput>#i#</cfoutput>">Font Color:</label>
									</td>
									<td>
										<script>
											 $("#carouselFontColor<cfoutput>#i#</cfoutput>").kendoColorPicker({
												input: false,
												preview:false,
												value: "#<cfoutput>#primaryColor#</cfoutput>",
												buttons: false,
												views: ["gradient"]
											});
										</script>
										<input id="carouselFontColor<cfoutput>#i#</cfoutput>" name="carouselFontColor<cfoutput>#i#</cfoutput>">
									</td>
								</tr>
							</table>
						 
						</td>
					</tr>
				</table>
			</td>
		</tr>
	</cfif><!---<cfif session.isMobile>--->
	</cfloop>
		<tr>
		<!--- Create alternating rows in the table. The Kendo classes which we will use are k-alt and k-content.
		We will create a border between the rows if the current row is not the first row. --->
		<cfif i eq 1>
			<td valign="top" <cfif not session.isMobile>colspan="2"</cfif>>
		<cfelse>
			<td align="left" valign="top" <cfif not session.isMobile>colspan="2"</cfif>>
		</cfif>
				<button id="carouselDetailSubmit" class="k-button k-primary" type="button">Submit</button>
			</td>
		</tr>
	</table>
				
	</form>
				
	<script>
		$(document).ready(function() {
		
			// Invoked when the submit button is clicked. Insted of using '$("form").submit(function(event) {' and 'event.preventDefault();', We are using direct binding here to speed up the event.
			var carouselDetailSubmit = $('#carouselDetailSubmit');
			carouselDetailSubmit.on('click', function(e){      
                e.preventDefault();         

				// submit the form. There is no validation at this time
				// Note: when testing the ui validator, comment out the post line below. It will only validate and not actually do anything when you post.
				// alert('posting');
				postCarouselDetails('update');
			});
		});//...document.ready
		
		// Post method on the detail form called from the GalleryDetailFormValidator method on the detail page. The action variable will either be 'update' or 'insert'.
		function postCarouselDetails(action){
			jQuery.ajax({
				type: 'post', 
				url: '<cfoutput>#application.baseUrl#</cfoutput>/common/cfc/ProxyController.cfc?method=saveCarousel&selectorId=carousel&darkTheme=<cfoutput>#darkTheme#</cfoutput>&csrfToken=<cfoutput>#csrfToken#</cfoutput>',
				// Serialize the carouselDetail form. The csrfToken is in the form.
				data: $('#carouselDetail').serialize(),
				// This is one of the few times that we will be sending back an html response. We are going to use this directly to set the content in the editor. its easier to craft the html on the server side than to manipulate the dom with a json object on the client. Normally this is always json
				dataType: "html",
				success: carouselUpdateResult, // calls the result function.
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
					$.when(kendo.ui.ExtAlertDialog.show({ title: "Error while consuming the saveCarousel function", message: error, icon: "k-ext-error", width: "<cfoutput>#application.kendoExtendedUiWindowWidth#</cfoutput>" }) // or k-ext-error, k-ext-information, k-ext-question, k-ext-warning.  You can also specify height.
						).done(function () {
					// Do nothing
					});		
				}//...if (jqXHR.status === 403) { 
			});
		};
		
		function carouselUpdateResult(response){
			// alert(response)
			// Note: the response is an html string 
			
			// Get the numGalleries value in the hidden form. It starts at 1. This is used to determine what id we should use in our hidden inputs that are created on the fly here.
			var carouselNum = $("#numCarousels").val();
			// Insert an iframe into the editor
			// $("#dynamicGalleryLabel").append('Gallery ' + galleryNum + ' Preview');
			// Show the preview row and insert content into the preview div
			// $("#dynamicGalleryInputFields").append(response);
			// Finally insert the content into the active tinymce editor. The response here is plain HTML coming from the server
			//$('textarea.post').html('Some contents...');
			tinymce.activeEditor.insertContent(response + '<br/><br/>');
			
			// Close all of the windows associated with the gallery
			// Close the uppy dashboard. We are using the uppy galleryWindow for both galleries and carousels
			$('#galleryWindow').kendoWindow('destroy');
			// Close the carousel items window
			$('#carouselItemsWindow').kendoWindow('destroy');
			
		}
		
	</script>