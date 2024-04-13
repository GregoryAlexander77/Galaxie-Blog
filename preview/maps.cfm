<!DOCTYPE html>
<cfsilent>
<!--- We are going to extract the map using the mapId from the db. --->
<cfparam name="URL.mapId" default="">
<!--- Either 'static' or 'route' --->
<cfparam name="URL.mapType" default="static">
<!--- Either true or false. --->
<cfparam name="URL.thumbnail" default="false">
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
</cfsilent>
<!---<cfdump var="#Data#"><cfabort>--->

<html>

    <head>
        <title>Map Preview</title>
        <meta http-equiv='Content-Type' content='text/html; charset=utf-8'/>
        <style type='text/css'>body{margin:0;padding:0;overflow:hidden;font-family:'Segoe UI',Helvetica,Arial,Sans-Serif}</style>
	</head>
	<body>
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
	<cfelse>
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
    
</cfif>
</body>
</html>