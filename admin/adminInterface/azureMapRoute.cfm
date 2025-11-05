	<!---<cfdump var="#URL#">--->
	<cfset azureMapsKey = application.azureMapsApiKey>
	<!--- Get the accent color of the selected theme. We will use this to color the map to match the theme. --->
	<cfset accentColor = application.blog.getPrimaryColorsByTheme(kendoTheme:'default',setting:'accentColor')>
	<!--- Instantiate the Render.cfc. This will be used to build the HTML for the image if the MediaUrl is present in the database. --->
	<cfobject component="#application.rendererComponentPath#" name="RendererObj">
	<!--- Get the post ( getPostByPostId(postId, showPendingPosts, showRemovedPosts) ) --->
	<cfset getPost = application.blog.getPostByPostId(URL.optArgs,true,true)>
	<!---<cfdump var="#getPost#">--->
		
	<!--- When the map already contains routes the location does not show up when submitting the form. This flag will turn off the existing directions so that the user has to fill out the form again. --->
	<cfset showCurrentDirections = false>
	
	<cfset mapId = URL.optArgs>
	<!--- Get the current routes if available --->
	<cfset enclosureMapId = getPost[1]["EnclosureMapId"]>
	<cfif len(enclosureMapId)>
		<cfset Data = application.blog.getMapRoutesByMapId(enclosureMapId)>
		<cfset mapRouteId = Data[1]["MapRouteId"]>
		<!---<cfdump var="#Data#">--->
	<cfelse>
		<cfset mapRouteId = 0>
	</cfif>
		
	<!-- Add references to the Azure Maps Map control JavaScript and CSS files. -->
	<link rel="stylesheet" href="<cfoutput>#application.azureMapsControllerCssUrl#</cfoutput>" type="text/css">
	<script src="<cfoutput>#application.azureMapsControllerUrl#</cfoutput>"></script>
	<!-- Add a reference to the Azure Maps Rest Helper JavaScript file. This script contains the processRequest function that is used to create the map route -->
	<script src="https://samples.azuremaps.com/lib/azure-maps/azure-maps-helper.min.js"></script>
	
	<script>	
	$(document).ready(function(){
		
		// This is used to populate the autosuggest as well as render the map when the first input is used. Fuzzy searches include POI and addresses.
		var fuzzyGeoServiceUrl = "<cfoutput>#application.azureMapsFuzzySearchUrl#</cfoutput>"; 
		
		// URL for the Azure Maps Route API. Used when two or more locations are selected to render the route.
        var routeGeoServiceUrl = 'https://atlas.microsoft.com/route/directions/json?api-version=1.0language=en-US&query={query}&routeRepresentation=polyline&travelMode=car&view=Auto';
		
		// create DropDownList from select HTML element
        $("#countrySelector").kendoMultiSelect({
			filter: "contains",
			placeholder: "Please select countries...",
			downArrow: true 
		});
		
		$("#travelMode").kendoDropDownList();
		
		// Kendo UI Datasources		
		function getLocationDataSource(locationIndex){
			return new kendo.data.DataSource({
				transport: {
					read: function(options) {

						// Perform a custom the AJAX request to the Azure Maps API
						$.ajax({
							url: fuzzyGeoServiceUrl, // the URL of the API endpoint.
							type: "get",// Azure maps require the get method and posts will fail with a 505 eror
							data: {
								// Pass the key. The dash will cause an error if the arg is not enclosed in a string
								'subscription-key': <cfoutput>'#azureMapsKey#'</cfoutput>,
								 // Pass the value typed in to the form for the query parameter
								query: function(){
									return $("#location" + locationIndex).data("kendoAutoComplete").value();
								},//..query
								// Pass the selected country
								countrySet: function(){
									return $("#countrySelector").data("kendoMultiSelect").value();
								}
							},//..data
							dataType: "json", // Use json if the template is on the current server. If not, use jsonp for cross domain reads.
							success: function(result) {
								// If the request is successful, call the options.success callback
								options.success( parseResponse(result) );
							},
							error: function(error) {
								// If the request fails, call the options.error callback
								options.error(error);
							}
						});//ajax

					},//read
					schema: {
						model: {
							fields: {
								freeformAddress: {type: "string" },
								lat: {type: "string" },
								lon: {type: "string" },
								topLeftPointLon: {type: "string" },
								topLeftPointLat: {type: "string" },
								btmRightPointLon: {type: "string" },
								btmRightPointLat: {type: "string" }
							}//fields
						}//model
					}//schema
				},//transport
				cache: false,
				serverFiltering: true // without this argument, the autocomplete will not work and only fire the ajax request once
			});//..return new kendo.data.DataSource({
		}//..function getLocationDataSource(locationIndex){
		
		// The parseResponse manipulates the returned JSON to make it compatible with the Kendo UI autosuggest widget.
		function parseResponse(obj){

			// Instantiate the json object
			jsonObj = [];

			// Loop through the items in the object
			for (var i = 0; i < obj.results.length; i++) {
				if (obj.results[i]) {
					// Get the data from the object
					var results = obj.results[i];// Results is an array in the json returned from the server
					
					// The POI is only available if the type is POI 
					var poi = '';
					var label = results.address.freeformAddress;
					if (results.type === 'POI'){
						poi = results.poi.name;	
						// Now that we have the POI when it exists, set the label that we will use. We will use the POI Name if it exists, otherwise we will use the freeFormAddress
						label = poi;
					}
					
					// Create the struct. We need the latitute, longitude and the POI if it exists. 
					let jsonItems = {
						freeformAddress: results.address.freeformAddress,
						poi: poi,
						label: label,
						lat: results.position.lat,
						lon: results.position.lon,
						topLeftPointLon: results.viewport.topLeftPoint.lon,
						topLeftPointLat: results.viewport.topLeftPoint.lat,
						btmRightPointLon: results.viewport.btmRightPoint.lon, 
						btmRightPointLat: results.viewport.btmRightPoint.lat
					};
					// Push the items into the new json object
					jsonObj.push(jsonItems);
				}
			}//..for
			// Write the object out for testing
			console.log('jsonObj:' + jsonObj);
			// And return it...
			return jsonObj;
		}//..function parseResponse(obj){
		
		// saveSelection(event, index)
		function saveSelection(e,locationIndex){
			
			// Since the Kendo DataSource is dynamic, we can't read the data from this DataSource, however, we can get the data from the jsonObj that we created using the selected index from the Kendo autosuggest widget.
			var selectedLocation = jsonObj[e.item.index()];
			
			// console.log('e.item.index():' + e.item.index());
			// Write the selected index to the console for debugging
			console.log('selectedLocation' + selectedLocation);
			
			// Save the values in a hidden form. The forms change according to the location index that is passed in
			$("#selectedFreeformAddress" + locationIndex).val(selectedLocation.freeformAddress);
			$("#selectedLat" + locationIndex).val(selectedLocation.lat);
			$("#selectedLon" + locationIndex).val(selectedLocation.lon);
			
			// Camera positions (only used for static maps)
			if (locationIndex == 1){
				$("#selectedTopLeftPointLon").val(selectedLocation.topLeftPointLon);
				$("#selectedTopLeftPointLat").val(selectedLocation.topLeftPointLat);
				$("#selectedBtmRightPointLon").val(selectedLocation.btmRightPointLon);
				$("#selectedBtmRightPointLat").val(selectedLocation.btmRightPointLat);
			}//if (locationIndex == 1){
			
			// Render the static map once the first location is filled out, or render the map route when multiple locations are selected.
			if (locationIndex == 1){
				// Render the static map. This function does not need the locationIndex as it only uses the first index to render the static map
				getStaticMap<cfoutput>#mapId#</cfoutput>();
			} else {
				setTimeout(function() {
					renderMapRoute(locationIndex);
				}, 250);
			}
		}//..function saveSelection(e,locationIndex){

		// Kendo UI autocomplete widgets
		$("#location1").kendoAutoComplete({
			minLength: 3,
			dataSource: getLocationDataSource(1), // We are binding the widget to a dynamic datasource
			dataTextField: "label", // The widget is bound to the "label" 
			select: function(e) {
				saveSelection(e,"1");//aveSelection(event,step). There are a dozen different steps, 1 through 16
			}
		});//..$("#location1").kendoAutoComplete({
		
		$("#location2").kendoAutoComplete({
			minLength: 3,
			dataSource: getLocationDataSource(2), // We are binding the widget to a dynamic datasource
			dataTextField: "label", // The widget is bound to the "label" 
			select: function(e) {
				saveSelection(e,"2");//saveSelection(event,step). there are a dozen different steps, 1 through 16
			}
		});//..$("#location2").kendoAutoComplete({
		
	<!--- Loop through the optional locations --->
	<cfloop from="3" to="16" index="i"><cfoutput>
		$("#chr(35)#location#i#").kendoAutoComplete({
			minLength: 3,
			dataSource: getLocationDataSource(#i#), // We are binding the widget to a dynamic datasource
			dataTextField: "label", // The widget is bound to the "label" 
			select: function(e) {
				saveSelection(e,"#i#");//saveSelection(event,step). there are a dozen different steps, 1 through 16
			}
		});//..$("#chr(35)#location#i#").kendoAutoComplete({
	</cfoutput></cfloop>

	});
	
	// This function is used to render a static map once the first form is filled out and a location is selected.
	function getStaticMap<cfoutput>#mapId#</cfoutput>() {
		
		// Get the necessary values from the hidden form values. Here, we are only using the selected values for the first location.
		var freeformAddress = $("#selectedFreeformAddress1").val();
		var lat = $("#selectedLat1").val();
		var lon = $("#selectedLon1").val();
		
		// Camera positions. These are only used when rendering the static map once the first location is selected.
		var topLeftPointLat = $("#selectedTopLeftPointLat").val();
		var topLeftPointLon = $("#selectedTopLeftPointLon").val();
		var btmRightPointLat = $("#selectedBtmRightPointLat").val();
		var btmRightPointLon = $("#selectedBtmRightPointLon").val();
		
		// Initialize a map instance.
		map = new atlas.Map('myMap', {
			view: 'Auto',
			authOptions: {
				 authType: 'subscriptionKey',
				 subscriptionKey: '<cfoutput>#azureMapsKey#</cfoutput>'
			 }
		});

		// Wait until the map resources are ready.
		map.events.add('ready', function () {
			// Create a data source to store the data in.
			datasource = new atlas.source.DataSource();
			// Add the datasource
			map.sources.add(datasource);
			// Add a layer for rendering point data.
			map.layers.add(new atlas.layer.SymbolLayer(datasource));
			// Remove any previous added data from the map.
			datasource.clear();
			// Create a point feature to mark the selected location.
			datasource.add(new atlas.data.Feature(new atlas.data.Point([lon,lat])));
			//datasource.add(new atlas.data.Feature(new atlas.data.Point([lon,lat]), ui.item));

			// Zoom the map into the selected location.
			map.setCamera({
				bounds: [
					topLeftPointLon, btmRightPointLat,
					btmRightPointLon, topLeftPointLat
				],
				padding: 0
			});//map.setCamera
			
			// Add the controls
			// Create a zoom control.
            map.controls.add(new atlas.control.ZoomControl({
                zoomDelta: parseFloat(1),
                style: "light"
            }), {
			  position: 'top-right'
			}); 
			
			// Create the style control
			map.controls.add(new atlas.control.StyleControl({
			  mapStyles: ['road', 'road_shaded_relief', 'satellite', 'satellite_road_labels'],
			  layout: 'icons'
			}), {
			  position: 'top-right'
			});  
			
		})//..map.events
		
	}//..getStaticMap<cfoutput>#mapId#</cfoutput>		
		
	function renderMapRoute(locationIndex) {

		// URL for the Azure Maps Route API.
		var routeUrl = 'https://{azMapsDomain}/route/directions/json?api-version=1.0&query={query}&routeRepresentation=polyline&travelMode={travelMode}&view=Auto';
		
		// Get the travel mode (car, bus, etc.)
		var travelMode = $("#travelMode").val();
		
		// Get the necessary values from the hidden form v}:alues. Here, we are only using the selected values for the first location.
		// Get the starting point
		var address1 = $("#selectedFreeformAddress1").val();
		var lat1 = $("#selectedLat1").val();
		var lon1 = $("#selectedLon1").val();
		
		// And the destination
		// Get the necessary values from the hidden form values. Here, we are only using the selected values for the first location.
		var address2 = $("#selectedFreeformAddress2").val();
		var lat2 = $("#selectedLat2").val();
		var lon2 = $("#selectedLon2").val();
		
		// Important note: in this example we must cast the longitude and latitude values, stored in the form, to a number otherwise the setCamera function will not work!
		var geoCoordinates1 = [Number(lon1),Number(lat1)];
		var geoCoordinates2 = [Number(lon2),Number(lat2)];
		
		// Set the geocoordinates to set the map boundary. 
		geoCoordinatePositionArray = [geoCoordinates1, geoCoordinates2];
		
		// Initialize a map instance.
		map = new atlas.Map('myMap', {
			center: geoCoordinates1,
			zoom: 12,
			view: 'Auto',
			style: 'road_shaded_relief',// Note: satellite_with_roads does not work on it's own when using directions

			authOptions: {
				 authType: 'subscriptionKey',
				 subscriptionKey: '<cfoutput>#azureMapsKey#</cfoutput>'
			 }
		});

		// Wait until the map resources are ready.
		map.events.add('ready', function () {
			// Create a data source and add it to the map.
			datasource = new atlas.source.DataSource();
			map.sources.add(datasource);

			// Add a layer for rendering the route line and have it render under the map labels.
			map.layers.add(new atlas.layer.LineLayer(datasource, null, {
				strokeColor: '#<cfoutput>#accentColor#</cfoutput>',
				strokeWidth: 5,
				lineJoin: 'round',
				lineCap: 'round'
			}), 'labels');

			// Add a layer for rendering point data.
			map.layers.add(new atlas.layer.SymbolLayer(datasource, null, {
				iconOptions: {
					image: ['get', 'iconImage'],
					allowOverlap: true,
					ignorePlacement: true
				},
				textOptions: {
					textField: ['get', 'title'],
					offset: [0, 1]
				},
				filter: ['any', ['==', ['geometry-type'], 'Point'], ['==', ['geometry-type'], 'MultiPoint']] //Only render Point or MultiPoints in this layer.
			}));
			
			// Create the GeoJSON objects which represent the start and end point of the route
			var waypoint1 = new atlas.data.Feature(new atlas.data.Point(geoCoordinates1), {
				title: address1,
				iconImage: 'pin-blue'
			});
			
			// Set the marker color to the 2nd waypoint. I want the default color to be blue and the final destination to be red
			if (locationIndex == 2){
				var thisMarkerColor = 'pin-red';
			} else {
				var thisMarkerColor = 'pin-blue';
			}

			// Create the GeoJSON objects which represent the start and end point of the route
			var waypoint2 = new atlas.data.Feature(new atlas.data.Point(geoCoordinates2), {
				title: address2,
				iconImage: thisMarkerColor// The following svg based markers can be used: https://learn.microsoft.com/en-us/azure/azure-maps/how-to-use-image-templates-web-sdk
			});
			
			// Note the GeoJSON objects have been switched from Bing Maps to Azure Maps. Now we are using longitude first then latitude instead of the other way around.
			// Add the origin and destination coordinates to the data source.
			datasource.add([waypoint1, waypoint2]);
			
			var geoCoordinateStr = `${geoCoordinates1[1]},${geoCoordinates1[0]}:${geoCoordinates2[1]},${geoCoordinates2[0]}`;
			
			// Loop through the hidden form fields and create the geocoordinates that we will use to render the route
			for (var i = 3; i <= locationIndex; i++) {
				
				var thisAddress = $("#selectedFreeformAddress" + i).val();
				var thisLat = $("#selectedLat" + i).val();
				var thisLon = $("#selectedLon" + i).val();
				var thisGeoCoordinates = [Number(thisLon),Number(thisLat)];
				// Append the geocoordinates to the geoCoordinatePositionArray. This array is used to calculate the map boundaries
				geoCoordinatePositionArray.push(thisGeoCoordinates);
				
				// console.log('thisLat:' + thisLat);
				// console.log('thisLon:' + thisLon);
				// console.log('thisGeoCoordinates:' + thisGeoCoordinates);
				
				// Set the marker color to this waypoint. I want the default color to be blue and the final destination to be red
				if (i == locationIndex){
					var thisMarkerColor = 'pin-red';
				} else {
					var thisMarkerColor = 'pin-blue';
				}
				
				// Create the GeoJSON objects which represent the start and end point of the route
				var thisWayPoint = new atlas.data.Feature(new atlas.data.Point(thisGeoCoordinates), {
					title: thisAddress,
					iconImage: thisMarkerColor
				});
				
				// Add the new waypoint
				datasource.add([thisWayPoint]);
				
				// Append the new latitude and latitude to the geoCoordinateStr. Note: this is in reverse order of the waypoint!
				geoCoordinateStr = geoCoordinateStr.concat(`:${thisLat},${thisLon}`); 
				// geoCoordinatePositionStr = geoCoordinates1, geoCoordinates2;
				// console.log('geoCoordinateStr:' + geoCoordinateStr);
			
			}//for

			// Fit the map window to the bounding box defined by the start and end positions. 
			map.setCamera({
				bounds: atlas.data.BoundingBox.fromPositions(geoCoordinatePositionArray),
				// Padding will essentially zoom out a bit. The default is 50, I am using 100 as I want the destinations on the map to be clearly shown
				padding: 100
			});

			// Create the route request with the query being the start and end point in the format 'startLongitude,startLatitude:endLongitude,endLatitude'. The replace function is a JavaScript function that uses backticks and the dollar signs indicate the expression.
			var routeRequestURL = routeUrl
				.replace('{query}', geoCoordinateStr);
			
			// Set the travel mode
			var routeRequestURL = routeRequestURL
				.replace('{travelMode}', `${travelMode}`);

			// Process the request and render the route result on the map.
			processRequest(routeRequestURL).then(directions => {
				// Extract the first route from the directions.
				const route = directions.routes[0];

				// Combine all leg coordinates into a single array.
				const routeCoordinates = route.legs.flatMap(leg => leg.points.map(point => [point.longitude, point.latitude]));

				// Create a LineString from the route path points.
				const routeLine = new atlas.data.LineString(routeCoordinates);

				// Add it to the data source.
				datasource.add(routeLine);
			});//..processRequest(routeRequestURL).then(directions => {
			
			// Add the controls
			// Create a zoom control.
            map.controls.add(new atlas.control.ZoomControl({
                zoomDelta: parseFloat(1),
                style: "light"
           }), {
			  position: 'top-right'
			}); 
			
			// Create the style control
			map.controls.add(new atlas.control.StyleControl({
			  mapStyles: ['road', 'road_shaded_relief', 'satellite', 'satellite_road_labels'],
			  layout: 'icons'
			}), {
			  position: 'top-right'
			});  
			
		});//..map.events.add('ready', function () {
	}//..function renderMapRoute(locationIndex) {
		
	function saveMapRoute(locationGeoCoordinates){
		
		// Create a list of coordinates
		//alert(getWaypoints());  
		
		// Get the selected zoom and map style from the map
		let mapZoom = map.getCamera().zoom;
		let mapStyle = map.getStyle().style;
		
		// Let the user know that we are processing the data
		$.when(kendo.ui.ExtWaitDialog.show({ title: "Please wait...", message: "Please wait while we create your map.", icon: "k-ext-information" }));

		jQuery.ajax({
			type: 'post', 
			url: '<cfoutput>#application.baseUrl#</cfoutput>/common/cfc/ProxyController.cfc?method=saveMapRoute&csrfToken=<cfoutput>#csrfToken#</cfoutput>',
			data: {
				provider: 'Azure Maps',
				locationGeoCoordinates: getWaypoints(),
				// Is this an enclosure? The otherArgs in the URL will determine what tinymce editor instance is being used.
				isEnclosure: <cfif URL.otherArgs eq 'enclosureEditor'>true<cfelse>false</cfif>,
				mapId: $("#enclosureMapId").val(),
				mapRouteId: $("#mapRouteId").val(),
				postId: "<cfoutput>#URL.optArgs#</cfoutput>",
				mapZoom: mapZoom,
				mapType: mapStyle
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
		
	// We need to extract the waypoints. We are going to format a string using address_latitude_longitude and separate each row with a coloon (:). I am using an underscore as the address may contain a comma. I am treating this as a ColdFusion like list.
	function getWaypoints(){
		
		var wayPointList = '';
		
		// Loop from 1 to 16 and get the selected location, latitude and longitude
		for (let i = 1; i < 16; i++) {
			var thisAddress = $("#selectedFreeformAddress" + i).val();
			var thisLat = $("#selectedLat" + i).val();
			var thisLon = $("#selectedLon" + i).val();
			if ((thisAddress) && (thisLat) && (thisLon)){ 
				var thisGeoCoordinates = [Number(thisLon),Number(thisLat)];
				if (i == 0){
					wayPointList += thisAddress + '_' + thisLat + '_' + thisLon;
				} else {
					wayPointList += ':' + thisAddress + '_' + thisLat + '_' + thisLon;
				}
			}
		}

		return wayPointList;
	}
	
	// functions to determine what fields should be shown and hidden.
	// Function to show a menu
	function showLayer(id) {
		var e = document.getElementById(id);
		e.style.display = "table-row"; 
	}
	
	// Function to hide a menu
	function hideLayer(id) { 
		try{
			var e = document.getElementById(id);
			e.style.display = 'none';
		} catch(e){
			error = id + 'is not defined';
		}
	}
	
	// function to toggle the layers on and off.
	function toggleLayers(id) {
       var e = document.getElementById(id);
       if(e.style.display == 'table-row')
          e.style.display = 'none';
       else
          e.style.display = 'table-row';
    }

	// New functions to hide and show a div using jquery. 7/27/2017
	function showDiv(divId) {
	   $("#"+divId).show();
	}
	
	function hideDiv(divId) {
	   $("#"+divId).hide();
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

<!-- Load the map using the body -->
<body onload="getStaticMap<cfoutput>#mapId#</cfoutput>()">
	
	<div class="directionsContainer">
		
		<form id="mapRoute" name="mapRoute" data-role="validator">
		<table cellpadding="0" cellspacing="0" style="width:320px;">
			<!--- Hidden forms to persist db related vars --->
			<!--- Is this an enclosure? The otherArgs in the URL will determine what tinymce editor instance is being used. --->
			<input type="hidden" name="isEnclosure" id="isEnclosure" value="<cfif URL.otherArgs eq 'enclosureEditor'>true<cfelse>false</cfif>" />
			<input type="hidden" name="enclosureMapId" id="enclosureMapId" value="<cfoutput>#enclosureMapId#</cfoutput>" /> 
			<input type="hidden" name="mapRouteId" id="mapRouteId" value="<cfoutput>#mapRouteId#</cfoutput>" /> 
			<input type="hidden" name="postId" id="postId" value="<cfoutput>#URL.optArgs#</cfoutput>" /> 
			<!-- Hidden inputs to store user selections -->
			<!--- Persist the selected values --->
			<input type="hidden" name="selectedFreeformAddress1" id="selectedFreeformAddress1" value="" /> 
			<!-- Latitute -->
			<input type="hidden" name="selectedLat1" id="selectedLat1" value="" />
			<!-- Longitude -->
			<input type="hidden" name="selectedLon1" id="selectedLon1" value="" />
			
			<!-- Freeform address 2 -->
			<input type="hidden" name="selectedFreeformAddress2" id="selectedFreeformAddress2" value="" /> 
			<!-- Latitute 2 -->
			<input type="hidden" name="selectedLat2" id="selectedLat2" value="" />
			<!-- Longitude 2 -->
			<input type="hidden" name="selectedLon2" id="selectedLon2" value="" />
			<!-- Optional layers -->
		<cfloop from="3" to="16" index="i"><cfoutput>
			<!-- Freeform address #i# -->
			<input type="hidden" name="selectedFreeformAddress#i#" id="selectedFreeformAddress#i#" value="" /> 
			<!-- Latitute 2 -->
			<input type="hidden" name="selectedLat#i#" id="selectedLat#i#" value="" />
			<!-- Longitude 2 -->
			<input type="hidden" name="selectedLon#i#" id="selectedLon#i#" value="" />
		</cfoutput></cfloop>

			<tr style="height: 35px;">
				<td width="10%" align="right">
				</td>
				<td width="*">
					<select id="countrySelector" name="countrySelector">
						<option value="AF">Afghanistan</option>
						<option value="AX">Åland Islands</option>
						<option value="AL">Albania</option>
						<option value="DZ">Algeria</option>
						<option value="AS">American Samoa</option>
						<option value="AD">Andorra</option>
						<option value="AO">Angola</option>
						<option value="AI">Anguilla</option>
						<option value="AQ">Antarctica</option>
						<option value="AG">Antigua and Barbuda</option>
						<option value="AR">Argentina</option>
						<option value="AM">Armenia</option>
						<option value="AW">Aruba</option>
						<option value="AU">Australia</option>
						<option value="AT">Austria</option>
						<option value="AZ">Azerbaijan</option>
						<option value="BS">Bahamas</option>
						<option value="BH">Bahrain</option>
						<option value="BD">Bangladesh</option>
						<option value="BB">Barbados</option>
						<option value="BY">Belarus</option>
						<option value="BE">Belgium</option>
						<option value="BZ">Belize</option>
						<option value="BJ">Benin</option>
						<option value="BM">Bermuda</option>
						<option value="BT">Bhutan</option>
						<option value="BO">Bolivia (Plurinational State of)</option>
						<option value="BQ">Bonaire, Sint Eustatius and Saba</option>
						<option value="BA">Bosnia and Herzegovina</option>
						<option value="BW">Botswana</option>
						<option value="BV">Bouvet Island</option>
						<option value="BR">Brazil</option>
						<option value="IO">British Indian Ocean Territory</option>
						<option value="BN">Brunei Darussalam</option>
						<option value="BG">Bulgaria</option>
						<option value="BF">Burkina Faso</option>
						<option value="BI">Burundi</option>
						<option value="CV">Cabo Verde</option>
						<option value="KH">Cambodia</option>
						<option value="CM">Cameroon</option>
						<option value="CA">Canada</option>
						<option value="KY">Cayman Islands</option>
						<option value="CF">Central African Republic</option>
						<option value="TD">Chad</option>
						<option value="CL">Chile</option>
						<option value="CN">China</option>
						<option value="CX">Christmas Island</option>
						<option value="CC">Cocos (Keeling) Islands</option>
						<option value="CO">Colombia</option>
						<option value="KM">Comoros</option>
						<option value="CG">Congo</option>
						<option value="CD">Congo, Democratic Republic of the</option>
						<option value="CK">Cook Islands</option>
						<option value="CR">Costa Rica</option>
						<option value="CI">Côte d'Ivoire</option>
						<option value="HR">Croatia</option>
						<option value="CU">Cuba</option>
						<option value="CW">Curaçao</option>
						<option value="CY">Cyprus</option>
						<option value="CZ">Czechia</option>
						<option value="DK">Denmark</option>
						<option value="DJ">Djibouti</option>
						<option value="DM">Dominica</option>
						<option value="DO">Dominican Republic</option>
						<option value="EC">Ecuador</option>
						<option value="EG">Egypt</option>
						<option value="SV">El Salvador</option>
						<option value="GQ">Equatorial Guinea</option>
						<option value="ER">Eritrea</option>
						<option value="EE">Estonia</option>
						<option value="SZ">Eswatini</option>
						<option value="ET">Ethiopia</option>
						<option value="FK">Falkland Islands (Malvinas)</option>
						<option value="FO">Faroe Islands</option>
						<option value="FJ">Fiji</option>
						<option value="FI">Finland</option>
						<option value="FR">France</option>
						<option value="GF">French Guiana</option>
						<option value="PF">French Polynesia</option>
						<option value="TF">French Southern Territories</option>
						<option value="GA">Gabon</option>
						<option value="GM">Gambia</option>
						<option value="GE">Georgia</option>
						<option value="DE">Germany</option>
						<option value="GH">Ghana</option>
						<option value="GI">Gibraltar</option>
						<option value="GR">Greece</option>
						<option value="GL">Greenland</option>
						<option value="GD">Grenada</option>
						<option value="GP">Guadeloupe</option>
						<option value="GU">Guam</option>
						<option value="GT">Guatemala</option>
						<option value="GG">Guernsey</option>
						<option value="GN">Guinea</option>
						<option value="GW">Guinea-Bissau</option>
						<option value="GY">Guyana</option>
						<option value="HT">Haiti</option>
						<option value="HM">Heard Island and McDonald Islands</option>
						<option value="VA">Holy See</option>
						<option value="HN">Honduras</option>
						<option value="HK">Hong Kong</option>
						<option value="HU">Hungary</option>
						<option value="IS">Iceland</option>
						<option value="IN">India</option>
						<option value="ID">Indonesia</option>
						<option value="IR">Iran (Islamic Republic of)</option>
						<option value="IQ">Iraq</option>
						<option value="IE">Ireland</option>
						<option value="IM">Isle of Man</option>
						<option value="IL">Israel</option>
						<option value="IT">Italy</option>
						<option value="JM">Jamaica</option>
						<option value="JP">Japan</option>
						<option value="JE">Jersey</option>
						<option value="JO">Jordan</option>
						<option value="KZ">Kazakhstan</option>
						<option value="KE">Kenya</option>
						<option value="KI">Kiribati</option>
						<option value="KP">Korea (Democratic People's Republic of)</option>
						<option value="KR">Korea, Republic of</option>
						<option value="KW">Kuwait</option>
						<option value="KG">Kyrgyzstan</option>
						<option value="LA">Lao People's Democratic Republic</option>
						<option value="LV">Latvia</option>
						<option value="LB">Lebanon</option>
						<option value="LS">Lesotho</option>
						<option value="LR">Liberia</option>
						<option value="LY">Libya</option>
						<option value="LI">Liechtenstein</option>
						<option value="LT">Lithuania</option>
						<option value="LU">Luxembourg</option>
						<option value="MO">Macao</option>
						<option value="MK">Macedonia, the former Yugoslav Republic of</option>
						<option value="MG">Madagascar</option>
						<option value="MW">Malawi</option>
						<option value="MY">Malaysia</option>
						<option value="MV">Maldives</option>
						<option value="ML">Mali</option>
						<option value="MT">Malta</option>
						<option value="MH">Marshall Islands</option>
						<option value="MQ">Martinique</option>
						<option value="MR">Mauritania</option>
						<option value="MU">Mauritius</option>
						<option value="YT">Mayotte</option>
						<option value="MX">Mexico</option>
						<option value="FM">Micronesia (Federated States of)</option>
						<option value="MD">Moldova, Republic of</option>
						<option value="MC">Monaco</option>
						<option value="MN">Mongolia</option>
						<option value="ME">Montenegro</option>
						<option value="MS">Montserrat</option>
						<option value="MA">Morocco</option>
						<option value="MZ">Mozambique</option>
						<option value="MM">Myanmar</option>
						<option value="NA">Namibia</option>
						<option value="NR">Nauru</option>
						<option value="NP">Nepal</option>
						<option value="NL">Netherlands</option>
						<option value="NC">New Caledonia</option>
						<option value="NZ">New Zealand</option>
						<option value="NI">Nicaragua</option>
						<option value="NE">Niger</option>
						<option value="NG">Nigeria</option>
						<option value="NU">Niue</option>
						<option value="NF">Norfolk Island</option>
						<option value="MP">Northern Mariana Islands</option>
						<option value="NO">Norway</option>
						<option value="OM">Oman</option>
						<option value="PK">Pakistan</option>
						<option value="PW">Palau</option>
						<option value="PS">Palestine, State of</option>
						<option value="PA">Panama</option>
						<option value="PG">Papua New Guinea</option>
						<option value="PY">Paraguay</option>
						<option value="PE">Peru</option>
						<option value="PH">Philippines</option>
						<option value="PN">Pitcairn</option>
						<option value="PL">Poland</option>
						<option value="PT">Portugal</option>
						<option value="PR">Puerto Rico</option>
						<option value="QA">Qatar</option>
						<option value="RE">Réunion</option>
						<option value="RO">Romania</option>
						<option value="RU">Russian Federation</option>
						<option value="RW">Rwanda</option>
						<option value="BL">Saint Barthélemy</option>
						<option value="SH">Saint Helena, Ascension and Tristan da Cunha</option>
						<option value="KN">Saint Kitts and Nevis</option>
						<option value="LC">Saint Lucia</option>
						<option value="MF">Saint Martin (French part)</option>
						<option value="PM">Saint Pierre and Miquelon</option>
						<option value="VC">Saint Vincent and the Grenadines</option>
						<option value="WS">Samoa</option>
						<option value="SM">San Marino</option>
						<option value="ST">Sao Tome and Principe</option>
						<option value="SA">Saudi Arabia</option>
						<option value="SN">Senegal</option>
						<option value="RS">Serbia</option>
						<option value="SC">Seychelles</option>
						<option value="SL">Sierra Leone</option>
						<option value="SG">Singapore</option>
						<option value="SX">Sint Maarten (Dutch part)</option>
						<option value="SK">Slovakia</option>
						<option value="SI">Slovenia</option>
						<option value="SB">Solomon Islands</option>
						<option value="SO">Somalia</option>
						<option value="ZA">South Africa</option>
						<option value="GS">South Georgia and the South Sandwich Islands</option>
						<option value="SS">South Sudan</option>
						<option value="ES">Spain</option>
						<option value="LK">Sri Lanka</option>
						<option value="SD">Sudan</option>
						<option value="SR">Suriname</option>
						<option value="SJ">Svalbard and Jan Mayen</option>
						<option value="SE">Sweden</option>
						<option value="CH">Switzerland</option>
						<option value="SY">Syrian Arab Republic</option>
						<option value="TW">Taiwan, Province of China</option>
						<option value="TJ">Tajikistan</option>
						<option value="TZ">Tanzania, United Republic of</option>
						<option value="TH">Thailand</option>
						<option value="TL">Timor-Leste</option>
						<option value="TG">Togo</option>
						<option value="TK">Tokelau</option>
						<option value="TO">Tonga</option>
						<option value="TT">Trinidad and Tobago</option>
						<option value="TN">Tunisia</option>
						<option value="TR">Turkey</option>
						<option value="TM">Turkmenistan</option>
						<option value="TC">Turks and Caicos Islands</option>
						<option value="TV">Tuvalu</option>
						<option value="UG">Uganda</option>
						<option value="UA">Ukraine</option>
						<option value="AE">United Arab Emirates</option>
						<option value="GB">United Kingdom of Great Britain and Northern Ireland</option>
						<option value="UM">United States Minor Outlying Islands</option>
						<option value="US" selected="selected">United States of America</option>
						<option value="UY">Uruguay</option>
						<option value="UZ">Uzbekistan</option>
						<option value="VU">Vanuatu</option>
						<option value="VE">Venezuela (Bolivarian Republic of)</option>
						<option value="VN">Viet Nam</option>
						<option value="VG">Virgin Islands (British)</option>
						<option value="VI">Virgin Islands (U.S.)</option>
						<option value="WF">Wallis and Futuna</option>
						<option value="EH">Western Sahara</option>
						<option value="YE">Yemen</option>
						<option value="ZM">Zambia</option>
						<option value="ZW">Zimbabwe</option>
					</select>
				</td>
			</tr>	
			<tr style="height: 35px;">
				<td width="10%" align="middle">
				</td>
				<td width="*">
					<select id="travelMode" name="travelMode">
						<option value="bicycle">Bicycle</option>
						<option value="bus">Bus</option>
						<option value="car" selected>Car</option>
						<option value="motorcycle">Motorcycle</option>
						<option value="pedestrian">Pedestrian</option>
					</select>
				</td>
			</tr>
			<tr style="height: 35px;">
				<td width="10%" align="middle">
					<i class="fa-solid fa-a"></i>
				</td>
				<td width="*">
					<input id="location1" name="location1" placeholder="From" style="width:100%" class="k-content"/>
				</td>
			</tr>
			<tr style="height: 35px;">
				<td width="10%" align="middle">
					<i class="fa-solid fa-b"></i>
				</td>
				<td width="*">
					<input id="location2" name="location2" placeholder="To" style="width:100%" class="k-content"/>
				</td>
			</tr> 
			<tr id="addDestinationRow2" name="addDestinationRow2" style="height: 35px;">
				<td width="10%" align="middle">
					<i class="fa-regular fa-square-plus"></i>
				</td>
				<td width="*">
					<a href="#chr(35)#" onClick="hideLayer('addDestinationRow2'); showLayer('locationRow3'); showLayer('addDestinationRow3');">Add Destination</a>
				</td>
			</tr>
			<!-- Optional layers -->
		<cfloop from="3" to="12" index="i"><cfsilent>
			
			<!--- Determine if the row should be initially hidden or shown. This is set as a variable as I use it to populate the forms with existing records. --->
			<cfset layerDisplay = 'none'><!--- either table-row or none --->
			<!--- Hide the current plus (+) icon and show the next destination and plus + icon --->
			
			<cfset addDestinationOnClickEvent = "hideLayer('addDestinationRow#i#'); showLayer('locationRow#round(i+1)#'); showLayer('addDestinationRow#round(i+1)#');">
				
			</cfsilent><cfoutput>
			<tr id="locationRow#i#" name="locationRow#i#" style="display:#layerDisplay#; height: 35px;">
				<td width="10%" align="middle">
					<i class="fa-solid fa-#getLetterByLoopCount(i)#"></i>
				</td>
				<td width="*">
					<input id="location#i#" name="location#i#" placeholder="Destination" style="width:100%" class="k-content"/>
				</td>
			</tr> 
			<tr id="addDestinationRow#i#" name="addDestinationRow#i#" style="display:#layerDisplay#; height: 35px;">
				<td width="10%" align="middle">
					<i class="fa-solid fa-plus" onClick="#addDestinationOnClickEvent#"></i>
				</td>
				<td width="*"> 
					<a href="#chr(35)#" onClick="#addDestinationOnClickEvent#">Add Destination</a>
				</td>
			</tr>
			</cfoutput>
		</cfloop>	
			<tr style="height: 35px;">
				<td width="10%" align="middle">
				</td>
				<td width="*">
					<button id="createRoute" class="k-button k-primary" type="button" onclick="saveMapRoute()">Submit</button>
				</td>
			</tr>
		</table>
		</form>
		
	</div>
	
	<!--- Map container to the right of the screen holding the map--->
    <div id="myMap"></div>
			
	<cfsilent>
		<!--- Determine which letter to show in the optional rows. I am using a loop from 3 to 12 and need to put its corresponding letter (c,d,e, etc.) --->
		<cffunction name="getLetterByLoopCount" access="public" returntype="any" output="no">
			<cfargument name="loopCount" required="true" type="numeric">

			<cfswitch expression="#arguments.loopCount#">
				<cfcase value="3">
					<cfset destinationLetter = "c">
				</cfcase>
				<cfcase value="4">
					<cfset destinationLetter = "d">
				</cfcase>
				<cfcase value="5">
					<cfset destinationLetter = "e">
				</cfcase>
				<cfcase value="6">
					<cfset destinationLetter = "f">
				</cfcase>
				<cfcase value="7">
					<cfset destinationLetter = "g">
				</cfcase>
				<cfcase value="8">
					<cfset destinationLetter = "h">
				</cfcase>
				<cfcase value="9">
					<cfset destinationLetter = "i">
				</cfcase>
				<cfcase value="10">
					<cfset destinationLetter = "j">
				</cfcase>
				<cfcase value="11">
					<cfset destinationLetter = "k">
				</cfcase>
				<cfcase value="12">
					<cfset destinationLetter = "l">
				</cfcase>
				<cfcase value="13">
					<cfset destinationLetter = "m">
				</cfcase>
				<cfcase value="14">
					<cfset destinationLetter = "n">
				</cfcase>
				<cfcase value="15">
					<cfset destinationLetter = "o">
				</cfcase>
				<cfcase value="16">
					<cfset destinationLetter ="p">
				</cfcase>
			</cfswitch>

			<cfreturn trim(destinationLetter)>

		</cffunction>	
	</cfsilent>