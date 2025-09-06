	<!--- Instantiate the Render.cfc. This will be used to build the HTML for the image if the MediaUrl is present in the database. --->
	<cfobject component="#application.rendererComponentPath#" name="RendererObj">
	<!--- Get the post ( getPostByPostId(postId, showPendingPosts, showRemovedPosts) ) --->
	<cfset getPost = application.blog.getPostByPostId(URL.optArgs,true,true)>
	<!---<cfdump var="#getPost#">--->
		
	<!--- When the map already contains routes the location does not show up when submitting the form. This flag will turn off the existing directions so that the user has to fill out the form again. --->
	<cfset showCurrentDirections = true>
	
	<!--- Get the current routes if available --->
	<cfset enclosureMapId = getPost[1]["EnclosureMapId"]>
	<cfif len(enclosureMapId)>
		<cfset Data = application.blog.getMapRoutesByMapId(enclosureMapId)>
	</cfif>
	
	<script type='text/javascript'>
        var map;
        var directionsManager;

        function GetMap()
        {
            map = new Microsoft.Maps.Map('#myMap', {});

            // Load the directions module.
            Microsoft.Maps.loadModule('Microsoft.Maps.Directions', function () {
                // Create an instance of the directions manager.
                directionsManager = new Microsoft.Maps.Directions.DirectionsManager(map);
			<cfif showCurrentDirections and len(enclosureMapId) and arrayLen(Data)><cfloop from="1" to="#arrayLen(Data)#" index="i"><cfoutput>
				// Create our waypoints
				directionsManager.addWaypoint(new Microsoft.Maps.Directions.Waypoint({ address: '#Data[i]['Location']#' }));
			</cfoutput></cfloop></cfif>				
                // Specify where to display the route instructions.
                directionsManager.setRenderOptions({ itineraryContainer: '#directionsItinerary' });
                // Specify the where to display the input panel
                directionsManager.showInputPanel('directionsPanel');
            });
        }
		
		// We need to extract the waypoints
		function getWaypoints(){
            var wp = directionsManager.getAllWaypoints();

            var text = '';
			var valuesList = '';
			var locationCoordinateList = '';

            for(var i=0; i < wp.length; i++){
                var loc = wp[i].getLocation();
				// console.log(loc)
                text += 'name ' + loc.name + ', waypoint ' + i + ': ' + loc.latitude + ', ' + loc.longitude + '\r\n';
				if (i == 0){
					valuesList += loc.name + '_' + loc.latitude + '_' + loc.longitude;
				} else {
					valuesList += '*' + loc.name + '_' + loc.latitude + '_' + loc.longitude;
				}
				
            }
			//alert(text);
			// Post the values to the server
			saveMapRoute(valuesList);
        }
		
		function saveMapRoute(locationGeoCoordinates){ 
			
			// Let the user know that we are processing the data
			$.when(kendo.ui.ExtWaitDialog.show({ title: "Please wait...", message: "Please wait while we create your map.", icon: "k-ext-information" }));
			
			jQuery.ajax({
				type: 'post', 
				url: '<cfoutput>#application.baseUrl#</cfoutput>/common/cfc/ProxyController.cfc?method=saveMapRoute',
				// Serialize the form
				data: {
					csrfToken: '<cfoutput>#csrfToken#</cfoutput>',
					locationGeoCoordinates: locationGeoCoordinates,
					// Is this an enclosure? The otherArgs in the URL will determine what tinymce editor instance is being used.
					isEnclosure: <cfif URL.otherArgs eq 'enclosureEditor'>true<cfelse>false</cfif>,
					mapId: $("#enclosureMapId").val(),
					mapRouteId: $("#mapRouteId").val(),
					postId: "<cfoutput>#URL.optArgs#</cfoutput>",
				},
				dataType: "json",
				success: saveMapRouteResponse, // calls the result function.
				error: function(ErrorMsg) {
					console.log('Error' + ErrorMsg);
				}
			// Extract any errors. This is a new jQuery promise based function as of jQuery 1.8.
			}).fail(function (jqXHR, textStatus, error) {

				// The full response is: jqXHR.responseText, but we just want to extract the error.
				$.when(kendo.ui.ExtAlertDialog.show({ title: "Error while consuming the saveMapRoute function", message: error, icon: "k-ext-error", width: "<cfoutput>#application.kendoExtendedUiWindowWidth#</cfoutput>" }) // or k-ext-error, k-ext-information, k-ext-question, k-ext-warning.  You can also specify height.
					).done(function () {
					// Do nothing
				});		
			});
		}
		
		function saveMapRouteResponse(response){
			
			//alert(JSON.parse(response.postId));
			var postId = JSON.parse(response.postId);
			var mapId = JSON.parse(response.mapId);
			
			// Create our iframe html string
			var mapIframeHtml = '<iframe data-type="map" data-id=' + mapId + ' src="<cfoutput>#application.baseUrl#</cfoutput>/preview/maps.cfm?mapId=' + mapId + '&mapType=route" width="768" height="432" allowfullscreen="allowfullscreen"></iframe>';
			// Insert the HTML string into the active editor
			// If this is the enclosure content, replace the content. If it is a post editor, insert the content
			tinymce.activeEditor.<cfif URL.otherArgs eq 'enclosureEditor'>setContent<cfelse>insertContent</cfif>(mapIframeHtml);
			
			// Use a quick set timeout in order for the data to load.
			setTimeout(function() {
				// Close the wait window that was launched in the calling function.
				kendo.ui.ExtWaitDialog.hide();
				// Refresh the thumbnail image on the post detail page
				reloadEnclosureThumbnailPreview(postId);
				// Close the window
				$('#mapRoutingWindow').kendoWindow('destroy');
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
            width: 425px;
			/* Set the input container at 425 pixels. Any less will cause part of the input to disappear */
            height: 100%;
            overflow-y: auto;
            float: left;
			background-color: white;
        }

        #myMap{
            position: relative;
			/* Set the dimensions of the main map */
            width:calc(100% - 425px);
            height: 100%;
            float: left;
        }
		
		/* Move the directions input container a little bit since its stuck at the left of the page margin-left: 45px;*/
		.MicrosoftMap .directionsPanel {
			margin-left: 25px;
		}
    </style>
	
	<!--- Get the map UI from Bing --->
	<script type='text/javascript' src='https://www.bing.com/api/maps/mapcontrol?callback=GetMap&key=<cfoutput>#application.bingMapsApiKey#</cfoutput>' async defer></script>

	<!--- Container to the left holding the search input and directions --->
    <div class="directionsContainer">
		
		<input type="hidden" id="enclosureMapId" name="enclosureMapId" value="<cfoutput>#getPost[1]['EnclosureMapId']#</cfoutput>">
		<table align="center" class="k-content" width="95%" cellpadding="5" cellspacing="0">
			<tr>
				<td>Create a route by searching in addresses between two or more points. You can add up to 15 waypoints. When complete, click on the button below to continue.</td>
			</tr>
			<tr>
				<td>
					<button id="createRoute" class="k-button k-primary" type="button" onclick="getWaypoints()">Complete</button>
				</td>
			</tr>
		</table>
		
        <div id="directionsPanel"></div>
        <div id="directionsItinerary"></div>
		
		<div id="output"></div>
		
		
    </div><!---<div class="directionsContainer">--->
	
	<!--- Map container to the right of the screen holding the map--->
    <div id="myMap"></div>