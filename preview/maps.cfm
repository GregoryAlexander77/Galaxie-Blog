<cfsilent>
<!--- We are going to extract the map using the mapId from the db. --->
<cfparam name="URL.mapId" default="">
<!--- Either 'static' or 'route' --->
<cfparam name="URL.mapType" default="static">
<!--- Either true or false. --->
<cfparam name="URL.thumbnail" default="false">
	
<cfset azureMapsKey = application.azureMapsApiKey>
<!--- Get the accent color of the selected theme. We will use this to color the map to match the theme. --->
<cfset accentColor = application.blog.getPrimaryColorsByTheme(kendoTheme:trim(application.blog.getSelectedKendoTheme()),setting:'accentColor')>
	
<!--- Preset our data array --->
<cfset Data = []>
	
<cfif len(URL.mapId)>
	<cfif URL.mapType eq 'route'>
		<!--- Get route data --->
		<cfset Data = application.blog.getMapRoutesByMapId(URL.mapId)>
	<cfelse>
		<!--- Get static map data --->
		<cfset Data = application.blog.getMapByMapId(URL.mapId)>
	</cfif>
</cfif>
<!---<cfdump var="#Data#">--->
<cfset mapProvider = Data[1]['MapProvider']>
<!--- Instantiate the Render.cfc. This will be used to create video and map thumbnails --->
<cfobject component="#application.rendererComponentPath#" name="RendererObj">
<!--- Get the selected theme --->
<cfset kendoTheme = application.blog.getSelectedKendoTheme()>
			
<cfif CGI.Remote_Addr eq '50.35.125.165'>
	<cfset mapProvider = 'Azure Maps'>
</cfif>
</cfsilent>
<cfif mapProvider eq 'Azure Maps'>
	<cfif URL.mapType eq 'route'>
		<cfsilent>
			<!--- Get route data --->
			<cfset Data = application.blog.getMapRoutesByMapId(#URL.mapId#)>
			<!---<cfdump var="#Data#">---> 

			<!--- Create a list of waypoints. We need this list to populate the datasource  --->
			<cfparam name="wayPointList" default="">
			<cfparam name="geoCoordinatesList" default="">
			<cfloop from="1" to="#arrayLen(Data)#" index="i">
				<cfset wayPointList = listAppend(wayPointList, 'waypoint' & i)>
				<cfset geoCoordinatesList = listAppend(geoCoordinatesList, 'geoCoordinates' & i)>
			</cfloop>	
		</cfsilent>
		<head>
			<meta charset="utf-8" />
			<meta name="viewport" content="width=device-width, initial-scale=1, shrink-to-fit=no" />
			<!-- Add references to the Azure Maps Map control JavaScript and CSS files. -->
			<link rel="stylesheet" href="<cfoutput>#application.azureMapsControllerCssUrl#</cfoutput>" type="text/css">
			<script src="<cfoutput>#application.azureMapsControllerUrl#</cfoutput>"></script>
			<!-- Add a reference to the Azure Maps Rest Helper JavaScript file. -->
			<script src="https://samples.azuremaps.com/lib/azure-maps/azure-maps-helper.min.js"></script>

			<script>
				var map, datasource;

				// URL for the Azure Maps Route API.
				var routeUrl = 'https://{azMapsDomain}/route/directions/json?api-version=1.0&query={query}&routeRepresentation=polyline&travelMode=car&view=Auto';

				function getMap() {
					// Initialize a map instance.
					map = new atlas.Map('myMap', {
						// Azure Maps reverses the order of the geocoordinates used with Bing Maps and uses lon,lat instead of lat,long
						center: [<cfoutput>#listLast(Data[1]["GeoCoordinates"])#,#listFirst(Data[1]["GeoCoordinates"])#</cfoutput>],
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

						// Create our waypoints
						// Note the GeoJSON objects have been switched from Bing Maps to Azure Maps. Now we are using longitude first then latitude instead of the other way around.
					<cfloop from="1" to="#arrayLen(Data)#" index="i"><cfoutput>
						// Set the vars
						var geoCoordinates#i# = [#listLast(Data[i]["GeoCoordinates"])#,#listFirst(Data[i]["GeoCoordinates"])#];
						var location#i# = '#Data[i]["Location"]#';
						// Create our waypoints
						var waypoint#i# = new atlas.data.Feature(new atlas.data.Point(geoCoordinates#i#), {
							title: location#i#,
							iconImage: <cfif i eq arrayLen(Data)>'pin-red'<cfelse>'pin-blue'</cfif>
						});
					</cfoutput></cfloop>

						// Add the waypoints to the data source.
						datasource.add([<cfoutput>#wayPointList#</cfoutput>]);

						// Fit the map window to the bounding box defined by the start and end positions.
						map.setCamera({
							bounds: atlas.data.BoundingBox.fromPositions([<cfoutput>#geoCoordinatesList#</cfoutput>]),
							// Padding will essentially zoom out a bit. The default is 50, I am using 100 as I want the destinations on the map to be clearly shown
							padding: 100
						});

						// Create the route request with the query using the following format 'startLongitude,startLatitude:endLongitude,endLatitude'.
						var routeRequestURL = routeUrl
							.replace('{query}', `<cfloop from="1" to="#arrayLen(Data)#" index="i"><cfoutput>${geoCoordinates#i#[1]},${geoCoordinates#i#[0]}<cfif i lt arrayLen(Data)>:</cfif></cfoutput></cfloop>`);  

						// Process the request and render the route result on the map. This method is in the Azure Maps resources that was loaded to the page.
						processRequest(routeRequestURL).then(directions => {
							// Extract the first route from the directions.
							const route = directions.routes[0];
							// Combine all leg coordinates into a single array.
							const routeCoordinates = route.legs.flatMap(leg => leg.points.map(point => [point.longitude, point.latitude]));
							// Create a LineString from the route path points.
							const routeLine = new atlas.data.LineString(routeCoordinates);
							// Add it to the data source.
							datasource.add(routeLine);
						});//processRequest

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

					});//map.events
				}
			</script>
			<style>
				html,
				body {
					width: 100%;
					height: 100%;
					padding: 0;
					margin: 0;
				}

				<cfoutput>#chr(35)#</cfoutput>myMap {
					width: 100%;
					height: 100%;
				}
			</style>
		</head>

		<body onload="getMap()">
			<div id="myMap"></div>
		</body>
		
	<cfelse><!---<cfif URL.mapType eq 'route'>--->
		<cfsilent>
			<cfparam name="URL.mapId" default="22">

			<cfset getMap = application.blog.getMapByMapId(URL.mapId)>

			<!--- Set the vars. --->
			<cfset mapId = getMap[1]["MapId"]>
			<cfset location = getMap[1]["Location"]>
			<cfset geoCoordinates = getMap[1]["GeoCoordinates"]>
			<cfset latitude = getMap[1]["Latitude"]>
			<cfset longitude = getMap[1]["Longitude"]>
			<cfset zoom = getMap[1]["Zoom"]>
			<cfset customMarkerUrl = getMap[1]["CustomMarkerUrl"]>
			<cfset outlineMap = getMap[1]["OutlineMap"]>
			<cfset hasMapRoutes = getMap[1]["HasMapRoutes"]>

			<!--- These vars may not be present --->
			<cfset topLeftPointLat = getMap[1]["TopLeftLatitude"]>
			<cfset topLeftPointLon = getMap[1]["TopLeftLongitude"]>
			<cfset btmRightPointLat = getMap[1]["BottomRightLatitude"]>
			<cfset btmRightPointLon = getMap[1]["BottomRightLongitude"]>
		</cfsilent>
		<head>
			<meta charset="utf-8" />
			<meta name="viewport" content="width=device-width, initial-scale=1, shrink-to-fit=no" />
			<!-- Add references to the Azure Maps Map control JavaScript and CSS files. -->
			<link rel="stylesheet" href="<cfoutput>#application.azureMapsControllerCssUrl#</cfoutput>" type="text/css">
			<script src="<cfoutput>#application.azureMapsControllerUrl#</cfoutput>"></script>

			<script>

				function getMap<cfoutput>#mapId#</cfoutput>() {

					// Set the necessary valus from the database
					var location<cfoutput>#mapId#</cfoutput> = '<cfoutput>#location#</cfoutput>';
					var lat = <cfoutput>#latitude#</cfoutput>;
					var lon = <cfoutput>#longitude#</cfoutput>;
				<cfif len(topLeftPointLat)>
					// Camera positions
					var topLeftPointLat = <cfoutput>#topLeftPointLat#</cfoutput>;
					var topLeftPointLon = <cfoutput>#topLeftPointLon#</cfoutput>;
					var btmRightPointLat = <cfoutput>#btmRightPointLat#</cfoutput>;
					var btmRightPointLon = <cfoutput>#btmRightPointLon#</cfoutput>;
				</cfif>

					// Initialize a map instance.
					map<cfoutput>#mapId#</cfoutput> = new atlas.Map('staticMap<cfoutput>#mapId#</cfoutput>', {
					<cfif !len(topLeftPointLat)>center: [Number(lon),Number(lat)],// Use the number function to ensure that the coordinates are numeric!
						zoom: 12,</cfif>
						view: 'Auto',
						authOptions: {
							 authType: 'subscriptionKey',
							 subscriptionKey: '<cfoutput>#azureMapsKey#</cfoutput>'
						 }
					});

					// Wait until the map resources are ready.
					map<cfoutput>#mapId#</cfoutput>.events.add('ready', function () {
						// Load the custom image icon into the map resources. This must be done immediately after the ready event
						map<cfoutput>#mapId#</cfoutput>.imageSprite.add('map-marker', '<cfoutput>#application.defaultAzureMapsCursor#</cfoutput>').then(function () {
							// Create a data source to store the data in.
							datasource = new atlas.source.DataSource();
							// Add the datasource
							map<cfoutput>#mapId#</cfoutput>.sources.add(datasource);
							// Add a layer for rendering point data.
							map<cfoutput>#mapId#</cfoutput>.layers.add(new atlas.layer.SymbolLayer(datasource));
							// Remove any previous added data from the map.
							datasource.clear();
							// Create a point feature to mark the selected location.
							datasource.add(new atlas.data.Feature(new atlas.data.Point([lon,lat])));
						<cfif len(topLeftPointLat)>
							// Zoom the map into the selected location.
							map<cfoutput>#mapId#</cfoutput>.setCamera({
								bounds: [
									topLeftPointLon, btmRightPointLat,
									btmRightPointLon, topLeftPointLat
								],
								padding: 0
							});//map<cfoutput>#mapId#</cfoutput>.setCamera
						</cfif>
							// Add the controls --------------------------------------------
							// Create a zoom control.
							map<cfoutput>#mapId#</cfoutput>.controls.add(new atlas.control.ZoomControl({
								zoomDelta: parseFloat(1),
								style: "light"
						   }), {
							  position: 'top-right'
							}); 

							// Create the style control
							map<cfoutput>#mapId#</cfoutput>.controls.add(new atlas.control.StyleControl({
							  mapStyles: ['road', 'grayscale_dark', 'night', 'road_shaded_relief', 'satellite', 'satellite_road_labels'],
							  layout: 'icons'
							}), {
							  position: 'top-right'
							});  

							// Add the custom marker and label.
							map<cfoutput>#mapId#</cfoutput>.layers.add(new atlas.layer.SymbolLayer(datasource, null, {
								iconOptions: {
									// Pass in the id of the custom icon that was loaded into the map resources.
									image: 'map-marker',
									// Scale the size of the icon.
									size: 0.5
								},
								textOptions: {
								// Get the label 
								textField: location<cfoutput>#mapId#</cfoutput>,
								// Offset the text so that it appears below the icon.
								offset: [0, 2] 
								}
							}));//map<cfoutput>#mapId#</cfoutput>.layers...
						});//map<cfoutput>#mapId#</cfoutput>.imageSprite.add...
					})//map<cfoutput>#mapId#</cfoutput>.events
				}//getMap<cfoutput>#mapId#</cfoutput>

			</script>
			<style>
				html,
				body {
					width: 100%;
					height: 100%;
					padding: 0;
					margin: 0;
				}

				#staticMap<cfoutput>#mapId#</cfoutput> {
					width: 100%;
					height: 100%;
				}
			</style>
			
		</head>

		<!-- Load the map using the body -->
		<body onload="getMap<cfoutput>#mapId#</cfoutput>()">
			<div id="staticMap<cfoutput>#mapId#</cfoutput>"></div>
		</body>
		
	</cfif><!---<cfif URL.mapType eq 'route'>--->	
	
<cfelseif mapProvider eq 'Bing Maps'>
	<!---*********************************************************** Bing Maps ***********************************************************--->
	<!---*********************************************************** Map Route ***********************************************************--->
	<cfif URL.mapType eq 'route'>
		<script type='text/javascript'>
            function loadMapScenario() {
                var map = new Microsoft.Maps.Map(document.getElementById('map<cfoutput>#URL.mapId#</cfoutput>'), {
                <cfif arrayLen(Data)>
                    center: new Microsoft.Maps.Location(<cfoutput>#Data[1]['GeoCoordinates']#</cfoutput>),
				</cfif>
                    zoom: 12
                });
				
			<cfif isDefined("URL.thumbnail") and URL.thumbnail eq 'true'>
				map.setOptions({
					showLocateMeButton: false,
					showMapTypeSelector: false,
					showZoomButtons: false,
					showScalebar: false
                });
			</cfif>
				
                Microsoft.Maps.loadModule('Microsoft.Maps.Directions', function () {
                    var directionsManager = new Microsoft.Maps.Directions.DirectionsManager(map);
                    // Set Route Mode to driving
                    directionsManager.setRequestOptions({ routeMode: Microsoft.Maps.Directions.RouteMode.driving });
                    // Create our waypoints
				<cfloop from="1" to="#arrayLen(Data)#" index="i"><cfoutput>
                    var waypoint#i# = new Microsoft.Maps.Directions.Waypoint({ address: '#Data[i]["Location"]#', location: new Microsoft.Maps.Location(#Data[i]['GeoCoordinates']#) });
					directionsManager.addWaypoint(waypoint#i#);
				</cfoutput></cfloop>
                    // Set the element in which the itinerary will be rendered
                    //directionsManager.setRenderOptions({ itineraryContainer: document.getElementById('printoutPanel') });
                    directionsManager.calculateDirections();
                });
                
            }
        </script>
		
		<!--- Content containers --->
        <div id='printoutPanel'></div>
        <div id='map<cfoutput>#URL.mapId#</cfoutput>' style='width: 100vw; height: 100vh;'></div>
		
        <script type='text/javascript' src='https://www.bing.com/api/maps/mapcontrol?key=<cfoutput>#application.bingMapsApiKey#</cfoutput>&callback=loadMapScenario' async defer></script>
	<cfelse><!---<cfif URL.mapType eq 'route'>--->
		<!---*********************************************************** Static Map ***********************************************************--->
		<script type='text/javascript'>
			function GetMap() {
				var map = new Microsoft.Maps.Map(document.getElementById('map<cfoutput>#URL.mapId#</cfoutput>'), {
				<cfif arrayLen(Data)>
					center: new Microsoft.Maps.Location(<cfoutput>#Data[1]['GeoCoordinates']#</cfoutput>),
					<cfif len(Data[1]['MapType'])>mapTypeId: Microsoft.Maps.MapTypeId.<cfoutput>#Data[1]['MapType']#</cfoutput>,</cfif>
				</cfif>
					zoom: 12
				});

				var center = map.getCenter();

			<cfif isDefined("URL.thumbnail") and URL.thumbnail eq 'true'>
				map.setOptions({
					showLocateMeButton: false,
					showMapTypeSelector: false,
					showZoomButtons: false,
					showScalebar: false
				});
			</cfif>

			<cfif arrayLen(Data) and len(Data[1]["CustomMarkerUrl"])>
				// Create custom Pushpin
				var pin = new Microsoft.Maps.Pushpin(center, {
					icon: '<cfoutput>Data[1]["CustomMarkerUrl"]</cfoutput>',
					anchor: new Microsoft.Maps.Point(12, 39)
				});
			<cfelse>
				// Create custom Pushpin
				var pin = new Microsoft.Maps.Pushpin(center, {
					anchor: new Microsoft.Maps.Point(12, 39)
				});
			</cfif>

				//Add the pushpin to the map
				map.entities.push(pin);

				var geoDataRequestOptions = {
					entityType: 'PopulatedPlace',
					getAllPolygons: true
				};
				Microsoft.Maps.loadModule('Microsoft.Maps.SpatialDataService', function () {
					//Use the GeoData API manager to get the boundary
					var polygonStyle = {
						fillColor: 'rgba(161,224,255,0.4)',
						strokeColor: '#a495b2',
						strokeThickness: 2
					};

				<cfif arrayLen(Data)>
					Microsoft.Maps.SpatialDataService.GeoDataAPIManager.getBoundary('<cfoutput>#Data[1]['Location']#</cfoutput>', geoDataRequestOptions, map, function (data) {
						if (data.results && data.results.length > 0) {
							map.entities.push(data.results[0].Polygons);
						}
					}, polygonStyle, function errCallback(networkStatus, statusMessage) {
						console.log(networkStatus);
						console.log(statusMessage);
					});
				</cfif>
				});
			}
		</script>
		<script type='text/javascript' src='https://www.bing.com/api/maps/mapcontrol?callback=GetMap&key=<cfoutput>#application.bingMapsApiKey#</cfoutput>' async defer></script>

		<div id="map<cfoutput>#URL.mapId#</cfoutput>" style="width:100vw;height:100vh;"></div>
	</cfif><!---<cfif URL.mapType eq 'route'>--->
</cfif>