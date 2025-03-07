	<!--- Instantiate the Render.cfc. This will be used to build the HTML for the image if the MediaUrl is present in the database. --->
	<cfobject component="#application.rendererComponentPath#" name="RendererObj">
	<!--- Get the post ( getPostByPostId(postId, showPendingPosts, showRemovedPosts) ) --->
	<cfset getPost = application.blog.getPostByPostId(URL.optArgs,true,true)>
	<!---<cfdump var="#getPost#">--->
	<!--- Get the mapId if already present. --->
	<cfset mapId = getPost[1]["EnclosureMapId"]>
	
	<!--- Get static map data --->
	<cfif isDefined("mapId") and len(mapId)>
		<cfset getMap = application.blog.getMapByMapId(mapId)>
	<cfelse>
		<cfset getMap = []>
	</cfif>
	<!---<cfdump var="#getMap#">--->
		
	<!--- If the map exists, set the vars. --->
	<cfif arrayLen(getMap)>
		<cfset geoCoordinates = getMap[1]["GeoCoordinates"]>
		<cfset location = getMap[1]["Location"]>
		<cfset mapType = getMap[1]["MapType"]>
		<cfset zoom = getMap[1]["Zoom"]>
		<cfset customMarkerUrl = getMap[1]["CustomMarkerUrl"]>
		<cfset outlineMap = getMap[1]["OutlineMap"]>
		<cfset hasMapRoutes = getMap[1]["HasMapRoutes"]>
	<cfelse>	
		<cfset geoCoordinates = ''>
		<cfset location = ''>
		<cfset mapType = ''>
		<cfset zoom = ''>
		<cfset customMarkerUrl = ''>
		<cfset outlineMap = false>
		<cfset hasMapRoutes = 0>
	</cfif>
		
	<script type='text/javascript'>
		var map;

		function GetMap() {
			map = new Microsoft.Maps.Map('#myMap', {});

			Microsoft.Maps.loadModule('Microsoft.Maps.AutoSuggest', function () {
				var manager = new Microsoft.Maps.AutosuggestManager({ map: map });
				manager.attachAutosuggest('#searchBox', '#searchBoxContainer', suggestionSelected);
			});
		}

		function suggestionSelected(result) {
			// Remove previously selected suggestions from the map.
			map.entities.clear();
			
		
			// Create custom Pushpin
			var pin = new Microsoft.Maps.Pushpin(result.location, {
				<cfif len(customMarkerUrl)>
				icon: 'https://www.bingmapsportal.com/Content/images/poi_custom.png',
				</cfif>
				anchor: new Microsoft.Maps.Point(12, 39)
			});
		
			// Show the suggestion as a pushpin and center map over it.
			//var pin = new Microsoft.Maps.Pushpin(result.location);
			map.entities.push(pin);
			//map.setOptions({ enableHoverStyle: true, enableClickedStyle: true });

			map.setView({ bounds: result.bestView });
			
			// Save the location data into a hidden form
			// console.log(result)
			$("#mapAddress").val(result.formattedSuggestion);
			$("#mapCoordinates").val(result.location.latitude + ',' + result.location.longitude);
		}
		
		function saveMap(){
			
			// Let the user know that we are processing the data
			$.when(kendo.ui.ExtWaitDialog.show({ title: "Please wait...", message: "Please wait while we create your map.", width: "<cfoutput>#application.kendoExtendedUiWindowWidth#</cfoutput>", icon: "k-ext-information" }));
			
			jQuery.ajax({
				type: 'post', 
				url: '<cfoutput>#application.baseUrl#</cfoutput>/common/cfc/ProxyController.cfc?method=saveMap',
				// Serialize the form
				data: {
					csrfToken: '<cfoutput>#csrfToken#</cfoutput>',
					isEnclosure: <cfif URL.otherArgs eq 'enclosureEditor'>true<cfelse>false</cfif>,
					mapId: $("#enclosureMapId").val(),
					postId: "<cfoutput>#URL.optArgs#</cfoutput>",
					mapType: map.getImageryId(),
					mapZoom: map.getZoom(),
					mapAddress: $("#mapAddress").val(),
					mapCoordinates: $("#mapCoordinates").val(),
					outlineMap: $("#outlineLocation").prop('checked'),
					customMarker: $("#customMarker").val()
				},
				dataType: "json",
				success: saveMapResponse, // calls the result function.
				error: function(ErrorMsg) {
					console.log('Error' + ErrorMsg);
				}
			// Extract any errors. This is a new jQuery promise based function as of jQuery 1.8.
			}).fail(function (jqXHR, textStatus, error) {

				// The full response is: jqXHR.responseText, but we just want to extract the error.
				$.when(kendo.ui.ExtAlertDialog.show({ title: "Error while consuming the saveMap function", message: error, icon: "k-ext-error", width: "425px" }) // or k-ext-error, k-ext-information, k-ext-question, k-ext-warning.  You can also specify height.
					).done(function () {
					// Do nothing
				});		
			});
		}
		
		function saveMapResponse(response){
			
			//alert(JSON.parse(response.postId));
			var postId = JSON.parse(response.postId);
			var mapId = JSON.parse(response.mapId);
			
			// Create our iframe html string
			var mapIframeHtml = '<iframe data-type="map" data-id=' + mapId + ' src="<cfoutput>#application.baseUrl#</cfoutput>/preview/maps.cfm?mapId=' + mapId + '&mapType=static" width="768" height="432" allowfullscreen="allowfullscreen"></iframe>';
			// Insert the HTML string into the active editor
			// If this is the enclosure content, replace the content. If it is a post editor, insert the content
			tinymce.activeEditor.<cfif URL.otherArgs eq 'enclosureEditor'>setContent<cfelse>insertContent</cfif>(mapIframeHtml);
			
			// Use a quick set timeout in order for the data to load.
			setTimeout(function() {
				// Refresh the thumbnail image on the post detail page
				reloadEnclosureThumbnailPreview(postId);
				// Close the wait window that was launched in the calling function.
				kendo.ui.ExtWaitDialog.hide();
				// Close this window
				$('#mapWindow').kendoWindow('destroy');
			}, 500);

		}
    </script>
		
	<style>
        html, body{
            padding: 0;
            margin: 0;
            height: 100%;
        }

        .directionsContainer {
            width: 450px;
			/* Set the input container at 425 pixels. Any less will cause part of the input to disappear */
            height: 100%;
            overflow-y: auto;
            float: left;
        }

        #myMap {
            position: relative;
			/* Set the dimensions of the main map */
            width:calc(100% - 450px);
            height: 100%;
            float: left;
        }
		
		/* Move the directions input container a little bit since its stuck at the left of the page margin-left: 45px;*/
		.MicrosoftMap .directionsPanel {
			margin-left: 25px;
		}
    </style>
		
	<!--- Call the mapcontrol script. --->
    <script type='text/javascript' src='https://www.bing.com/api/maps/mapcontrol?callback=GetMap&key=<cfoutput>#application.bingMapsApiKey#</cfoutput>' async defer></script>
		
	<div class="directionsContainer" class="k-content">
		<div id='searchBoxContainer' class="k-content">
			<input type="hidden" name="mapAddress" id="mapAddress" value="<cfoutput>#location#</cfoutput>"/>
			<input type="hidden" name="mapCoordinates" id="mapCoordinates" value="<cfoutput>#geoCoordinates#</cfoutput>"/>
			<table align="center" width="95%" class="k-content" cellpadding="2" cellspacing="0">
				<cfsilent>
				<!--- The first content class in the table should be empty. --->
				<cfset thisContentClass = HtmlUtilsObj.getKendoClass('')>
				<!--- Set the colspan property for borders --->
				<cfset thisColSpan = "2">
				</cfsilent>
				<tr height="1px">
					<td align="left" valign="top" colspan="2" class="<cfoutput>#thisContentClass#</cfoutput>"></td>
				</tr>
				<tr>
					<td colspan="2"> 
						<p>Type in a location or address in the location form to drop a pin. An autosuggest will appear below the location input to help you select the proper location.</p>

						<p>You can also use the map controls to the right to customize the map type (road, arial, etc) and set the zoom. If you want a different location pin, indicate the path to the image in the field below.</p> 
						<p>If the location is a city, state, or region, you can highlight the location by clicking on the highlight checkmark below. When you're satisfied with the look and feel of the map, click on the submit button below.</p>
					</td>
				</tr>
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
			  <tr valign="middle">
				<td class="<cfoutput>#thisContentClass#</cfoutput>" colspan="2">
					<label for="searchBox">Location</label>
				</td>
			   </tr>
			   <tr>
				<td class="<cfoutput>#thisContentClass#</cfoutput>" colspan="2">
					<input id="searchBox" name="searchBox" value="<cfoutput>#location#</cfoutput>" class="k-textbox" style="width: 95%" /> 
				</td>
			  </tr>
			<cfelse><!---<cfif session.isMobile>--->
				<tr>
					<td align="right" class="<cfoutput>#thisContentClass#</cfoutput>"> 
						<label for="searchBox">Location</label>
					</td>
					<td class="<cfoutput>#thisContentClass#</cfoutput>">
						<input id="searchBox" name="searchBox" value="<cfoutput>#location#</cfoutput>" class="k-textbox" style="width: 85%" />
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
				<!---
				<tr valign="middle">
				  <td align="right" valign="middle" width="30%" class="<cfoutput>#thisContentClass#</cfoutput>">
					<label for="customMarker">Custom Pin Preview</label>
				  </td>
				  <td align="left" width="70%" class="<cfoutput>#thisContentClass#</cfoutput>">
					<div class="squareThumbnail"><img data-src="/images/logo/logoMaterialThemeOs.gif" alt="" class="portrait lazied shown" data-lazied="IMG" src="/images/logo/logoMaterialThemeOs.gif"></a></div>
				  </td>
				</tr>
				--->
			<cfif session.isMobile>
			  <tr valign="middle">
				<td class="<cfoutput>#thisContentClass#</cfoutput>" colspan="2">
					<label for="customMarker">Pin URL</label>
				</td>
			   </tr>
			   <tr>
				<td class="<cfoutput>#thisContentClass#</cfoutput>" colspan="2">
					<input id="customMarker" name="customMarker" value="<cfoutput>#customMarkerUrl#</cfoutput>" class="k-textbox" style="width: 95%" onClick="createAdminInterfaceWindow(21,<cfoutput>#URL.optArgs#</cfoutput>)" />  
				</td>
			  </tr>
			<cfelse><!---<cfif session.isMobile>--->
				<tr valign="middle">
				  <td align="right" valign="middle" width="30%" class="<cfoutput>#thisContentClass#</cfoutput>">
					<label for="customMarker">Pin URL</label>
				  </td>
				  <td align="left" width="70%" class="<cfoutput>#thisContentClass#</cfoutput>">
					<input id="customMarker" name="customMarker" value="<cfoutput>#customMarkerUrl#</cfoutput>" class="k-textbox" style="width: 85%" onClick="createAdminInterfaceWindow(21,<cfoutput>#URL.optArgs#</cfoutput>)" />  
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
			  <tr valign="middle">
				<td class="<cfoutput>#thisContentClass#</cfoutput>" colspan="2">
					<label for="post">Outline Location</label>
				</td>
			   </tr>
			   <tr>
				<td class="<cfoutput>#thisContentClass#</cfoutput>" colspan="2">
					<input type="checkbox" id="outlineLocation" name="outlineLocation" <cfif outlineMap>checked</cfif>/> 
				</td>
			  </tr>
			<cfelse><!---<cfif session.isMobile>--->
				<tr valign="middle">
				  <td align="right" valign="middle" width="30%" class="<cfoutput>#thisContentClass#</cfoutput>">
					<label for="post">Outline Location</label>
				  </td>
				  <td align="left" width="70%" class="<cfoutput>#thisContentClass#</cfoutput>">
					<input type="checkbox" id="outlineLocation" name="outlineLocation" <cfif outlineMap>checked</cfif>/> 
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
				<tr valign="middle">
				  <td colspan="2">
					<button id="createMap" class="k-button k-primary" type="button" onclick="saveMap()">Submit</button>
				  </td>
				</tr>   
			</table>
		</div><!---<div id='searchBoxContainer'>--->
    </div><!---<div class="directionsContainer">--->
			
	<!--- Map container to the right of the screen holding the map--->
    <div id="myMap"></div>