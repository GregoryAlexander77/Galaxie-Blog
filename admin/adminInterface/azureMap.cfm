	<!---<cfdump var="#URL#">--->
	<cfset azureMapsKey = application.azureMapsApiKey>
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
		
	<cfif arrayLen(getMap)>
		<!--- If the map exists, set the vars. --->
		<cfset geoCoordinates = getMap[1]["GeoCoordinates"]>
		<cfset latitude = getMap[1]["Latitude"]>
		<cfset longitude = getMap[1]["Longitude"]>
		<cfset location = getMap[1]["Location"]>
		<cfset mapType = getMap[1]["MapType"]>
		<cfset zoom = getMap[1]["Zoom"]>
		<cfset customMarkerUrl = getMap[1]["CustomMarkerUrl"]>
		<cfset outlineMap = getMap[1]["OutlineMap"]>
		<cfset hasMapRoutes = getMap[1]["HasMapRoutes"]>
		<!--- Optional vars --->
		<cfset topLeftPointLat = getMap[1]["TopLeftLatitude"]>
		<cfset topLeftPointLon = getMap[1]["TopLeftLongitude"]>
		<cfset btmRightPointLat = getMap[1]["BottomRightLatitude"]>
		<cfset btmRightPointLon = getMap[1]["BottomRightLongitude"]>
	<cfelse>
		<!--- If the map exists, set the vars. --->
		<cfset geoCoordinates = "">
		<cfset latitude = "">
		<cfset longitude = "">
		<cfset location = "">
		<cfset mapType = "">
		<cfset zoom = "">
		<cfset customMarkerUrl = "">
		<cfset outlineMap = false>
		<cfset hasMapRoutes = "">
		<!--- Optional vars --->
		<cfset topLeftPointLat = "">
		<cfset topLeftPointLon = "">
		<cfset btmRightPointLat = "">
		<cfset btmRightPointLon = "">
	</cfif>
		
	<!-- Add references to the Azure Maps Map control JavaScript and CSS files. -->
	<link rel="stylesheet" href="<cfoutput>#application.azureMapsControllerCssUrl#</cfoutput>" type="text/css">
	<script src="<cfoutput>#application.azureMapsControllerUrl#</cfoutput>"></script>
		
	<script type='text/javascript'>
		$(document).ready(function(){
		
			// This is used to populate the autosuggest as well as render the map when the first input is used. Fuzzy searches include POI and addresses.
			var fuzzyGeoServiceUrl = "<cfoutput>#application.azureMapsFuzzySearchUrl#</cfoutput>"; 

			// create DropDownList from select HTML element
			$("#countrySelector").kendoDropDownList();

			function parseResponse(obj){

				// https://stackoverflow.com/questions/15009448/creating-a-json-dynamically-with-each-input-value-using-jquery
				// Instantiate the json objects
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
				console.log(jsonObj);
				// And return it...
				return jsonObj;
			}

			var locationDs = new kendo.data.DataSource({
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
									return $("#location").data("kendoAutoComplete").value();
								},//..query
								// Pass the selected country
								countrySet: function(){
									if ($("#countrySelector").data("kendoDropDownList").value() != 'all'){
										return $("#countrySelector").data("kendoDropDownList").value();
									} 
								},//..countrySet

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
			});

			$("#location").kendoAutoComplete({
				minLength: 3,
				dataSource: locationDs, 
				dataTextField: "label", // The widget is bound to the "label" 
				select: function(e) {
					// Store the selected index
					$("#selectedIndex").val(e.item.index());
					// Read the items in the datasource using the selected index
					var selectedLocation = locationDs.at( e.item.index() );
					// Save the values in a hidden form
					$("#selectedFreeformAddress").val(selectedLocation.freeformAddress);
					$("#selectedLat").val(selectedLocation.lat);
					$("#selectedLon").val(selectedLocation.lon);
					$("#selectedTopLeftPointLon").val(selectedLocation.topLeftPointLon);
					$("#selectedTopLeftPointLat").val(selectedLocation.topLeftPointLat);
					$("#selectedBtmRightPointLon").val(selectedLocation.btmRightPointLon);
					$("#selectedBtmRightPointLat").val(selectedLocation.btmRightPointLat);
					// Write the selected index to the console for debugging
					console.log(selectedLocation);

					// Render the map
					getMap();
				}
			});

		});

		function getMap() {

			// Get the necessary valus from the hidden form values
			var freeformAddress = $("#selectedFreeformAddress").val();
			var lat = $("#selectedLat").val();
			var lon = $("#selectedLon").val();
			// Camera positions
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
				// Load the custom image icon into the map resources. This must be done immediately after the ready event
				map.imageSprite.add('map-marker', '<cfoutput>#application.defaultAzureMapsCursor#</cfoutput>').then(function () {
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
					  mapStyles: ['road', 'grayscale_dark', 'night', 'road_shaded_relief', 'satellite', 'satellite_road_labels'],
					  layout: 'icons'
					}), {
					  position: 'top-right'
					});  
				});//map.imageSprite.add...
			})//map.events

		}//getMap
		
		function saveMap(){
			
			// Get the selected zoom and map style
			let mapZoom = map.getCamera().zoom;
			let mapStyle = map.getStyle().style;
			
			// Let the user know that we are processing the data
			$.when(kendo.ui.ExtWaitDialog.show({ title: "Please wait...", message: "Please wait while we create your map.", width: "<cfoutput>#application.kendoExtendedUiWindowWidth#</cfoutput>", icon: "k-ext-information" }));
			
			jQuery.ajax({
				type: 'post', 
				url: '<cfoutput>#application.baseUrl#</cfoutput>/common/cfc/ProxyController.cfc?method=saveMap',
				// Serialize the form
				data: {
					csrfToken: '<cfoutput>#csrfToken#</cfoutput>',
					provider: 'Azure Maps',
					isEnclosure: <cfif URL.otherArgs eq 'enclosureEditor'>true<cfelse>false</cfif>,
					mapId: $("#enclosureMapId").val(),
					postId: "<cfoutput>#URL.optArgs#</cfoutput>",
					mapType: mapStyle,
					mapZoom: Math.round(mapZoom),
					mapAddress: $("#selectedFreeformAddress").val(),
					mapCoordinates: $("#selectedLat").val() + ',' + $("#selectedLon").val(),
					latitude: $("#selectedLat").val(),
					longitude: $("#selectedLon").val()
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
			<input type="hidden" name="mapCoordinates" id="mapCoordinates" value="<cfoutput>#geoCoordinates#</cfoutput>"/>
			
			<!-- Hidden inputs to store user selections -->
			<input type="hidden" name="selectedFreeformAddress" id="selectedFreeformAddress" value="" /> 
			<!-- Latitute -->
			<input type="hidden" name="selectedLat" id="selectedLat" value="" />
			<!-- Longitude -->
			<input type="hidden" name="selectedLon" id="selectedLon" value="" />

			<!-- Camera Top Left Latitude -->
			<input type="hidden" name="selectedTopLeftPointLat" id="selectedTopLeftPointLat" value="" />
			<!-- Camera Top Left Longitude -->
			<input type="hidden" name="selectedTopLeftPointLon" id="selectedTopLeftPointLon" value="" />
			<!-- Camera Bottom Right Latitude -->
			<input type="hidden" name="selectedBtmRightPointLat" id="selectedBtmRightPointLat" value="" />
			<!-- Camera Bottom Right Longitude -->
			<input type="hidden" name="selectedBtmRightPointLon" id="selectedBtmRightPointLon" value="" />
			
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
						<p>If the location is a city, state, or region, you can highlight the location by clicking on the highlight checkmark below. When you're satisfied with the look and feel of the map, click on the submit button.</p>
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
					<label for="countrySelector">Country</label>
				</td>
			   </tr>
			   <tr>
				<td class="<cfoutput>#thisContentClass#</cfoutput>" colspan="2">
					<select id="countrySelector" style="width:85%">
						<option value="all">All</option>
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
			<cfelse><!---<cfif session.isMobile>--->
				<tr>
					<td align="right" class="<cfoutput>#thisContentClass#</cfoutput>"> 
						<label for="location">Country</label>
					</td>
					<td class="<cfoutput>#thisContentClass#</cfoutput>">
						<select id="countrySelector" style="width:85%">
							<option value="all">All</option>
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
					<label for="location">Location</label>
				</td>
			   </tr>
			   <tr>
				<td class="<cfoutput>#thisContentClass#</cfoutput>" colspan="2">
					<input id="location" name="location" value="<cfoutput>#location#</cfoutput>" class="k-textbox" style="width: 95%" /> 
				</td>
			  </tr>
			<cfelse><!---<cfif session.isMobile>--->
				<tr>
					<td align="right" class="<cfoutput>#thisContentClass#</cfoutput>"> 
						<label for="location">Location</label>
					</td>
					<td class="<cfoutput>#thisContentClass#</cfoutput>">
						<input id="location" name="location" value="<cfoutput>#location#</cfoutput>" class="k-textbox" style="width: 85%" />
					</td>
				</tr>
			</cfif>
				<!-- Border -->
				<tr height="2px">
				  <td align="left" valign="top" colspan="<cfoutput>#thisColSpan#</cfoutput>" class="<cfoutput>#thisContentClass#</cfoutput>"></td>
				</tr>
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