	<cfsilent>
	
	<!---<cfdump var="#application.BlogOptionDbObj#">--->

	<!--- The blog object is already instantiated in the application --->
	<!--- Title and Description --->
	<cfset blogId = application.BlogDbObj.getBlogId()>
	<cfset blogName = application.BlogDbObj.getBlogName()>
	<cfset blogTitle = application.BlogDbObj.getBlogTitle()>
	<cfset blogDescription = application.BlogDbObj.getBlogDescription()>
	<!--- The blog URL contains an index.cfm at the end --->
	<cfset blogUrl = application.BlogDbObj.getBlogUrl()>
	<cfset isProd = application.BlogDbObj.getIsProd()>
	<!--- SEO --->
	<cfset blogMetaKeywords = application.BlogDbObj.getBlogMetaKeywords()>
	<!--- Parent Site Links --->
	<cfset parentSiteName = application.BlogDbObj.getBlogParentSiteName()>
	<cfset parentSiteLink = application.BlogDbObj.getBlogParentSiteUrl()>
	<!--- Location and time zone --->
	<cfset locale = application.BlogDbObj.getBlogLocale()>
	<cfset blogTimeZone = application.BlogDbObj.getBlogTimeZone()>
	<cfset blogServerTimeZone = application.BlogDbObj.getBlogServerTimeZone()>
	<cfset serverTimeZoneOffset =  application.BlogDbObj.getBlogServerTimeZoneOffset()>
	<!--- Database --->
	<cfset blogDsn = application.BlogDbObj.getBlogDsn()>
	<cfset blogDsnUserName = application.BlogDbObj.getBlogDsnUserName()>
	<cfset blogDsnPassword = application.BlogDbObj.getBlogDsnPassword()>
	<cfset blogDBType = application.BlogDbObj.getBlogDatabaseType()>
	<!--- The following 3 args are found in the blog ini file. --->
	<cfset dsn = getProfileString(application.iniFile, "default", "dsn")>
	<cfset dsnUserName = getProfileString(application.iniFile, "default", "username")>
	<cfset dsnPassword = getProfileString(application.iniFile, "default", "password")>
	<!--- Mail server settings. --->
	<cfset mailServer = application.BlogDbObj.getBlogMailServer()>
	<cfset mailusername = application.BlogDbObj.getBlogMailServerUserName()>
	<cfset mailpassword = application.BlogDbObj.getBlogMailServerPassword()>
	<cfset failTo = application.BlogDbObj.getBlogEmailFailToAddress()>
	<cfset blogEmail = application.BlogDbObj.getBlogEmail()>
	<cfset ccEmailAddress = application.BlogDbObj.getCcEmailAddress()>
	<!--- Algorithm and IP Block list --->
	<cfset saltAlgorithm = application.BlogDbObj.getSaltAlgorithm()>
	<cfset saltAlgorithmSize = application.BlogDbObj.getSaltAlgorithmSize()>
	<cfset hashAlgorithm = application.BlogDbObj.getHashAlgorithm()>
	<cfset ipBlockList = application.BlogDbObj.getIpBlockList()>
	<!--- Version --->
	<cfset blogVersion = application.BlogDbObj.getBlogVersion()>
	<cfset blogVersionName = application.BlogDbObj.getBlogVersionName()>
	<cfset isProd = application.BlogDbObj.getIsProd()>
	<cfset blogInstalled = application.BlogDbObj.getBlogInstalled()>
	
	</cfsilent>	
	<style>
		.collapsible {
			cursor: pointer;
			padding: 10px;
			width: 98%;
			border: thin;
			border-style: solid;
			text-align: left;
			outline: none;
			font-size: 15px;
			transition: max-height 0.2s ease-out;
		}

		.collapsible:after {
			content: '\25BC';
			color: white;
			font-weight: bold;
			float: right;
			margin-left: 5px;
			margin-left: 5px;
		}

		.active:after {
		  content: "\25B2";
		}

		.content {
		  padding: 0 18px;
		  display: none;
		  overflow: hidden;
		}
	</style>
		
	<script>
		
		// !!! Note on the validators, all forms need a name attribute, otherwise the positioning of the messages will not work. --->
		$(document).ready(function() {

			var settingsValidator = $("#settingsForm").kendoValidator({
				// Set up custom validation rules 
				rules: {
					// The theme must be unique. 
					themeIsUnique:
					function(input){
						// Do not continue if the theme name is found in the currentTheme list 
						if (input.is("[id='themeName']") && ( listFind( themeList, input.val() ) != 0 ) ){
							// Display an error on the page.
							input.attr("data-themeIsUnique-msg", "Theme name already exists");
							// Focus on the current element
							$( "#theme" ).focus();
							return false;
						}                                    
						return true;
					},
				}
			}).data("kendoValidator");

			// Invoked when the submit button is clicked. Insted of using '$("form").submit(function(event) {' and 'event.preventDefault();', We are using direct binding here to speed up the event.
			var settingsSubmit = $('#settingsSubmit');
			settingsSubmit.on('click', function(e){ 
				
				e.preventDefault();         
				if (settingsValidator.validate()) {
					
					// Open up a please wait dialog
					$.when(kendo.ui.ExtWaitDialog.show({ title: "Please wait...", message: "Please wait while we save the data.", width: "<cfoutput>#application.kendoExtendedUiWindowWidth#</cfoutput>", icon: "k-ext-information" }));

					// Send data to server
					setTimeout(function() {
						postSettings();
					}, 250);
					
				} else {

					$.when(kendo.ui.ExtAlertDialog.show({ title: "There are errors", message: "Please correct the highlighted fields and try again", width: "<cfoutput>#application.kendoExtendedUiWindowWidth#</cfoutput>", icon: "k-ext-warning" }) // or k-ext-error, k-ext-question
						).done(function () {
						// Do nothing
					});
				}
			});

		});//...document.ready
		
		// Post method on the detail form called from the deptDetailFormValidator method on the detail page. The action variable will either be 'update' or 'insert'.
		function postSettings(){

			jQuery.ajax({
				type: 'post', 
				url: '<cfoutput>#application.baseUrl#</cfoutput>/common/cfc/ProxyController.cfc?method=saveBlogSettings&csrfToken=<cfoutput>#csrfToken#</cfoutput>',
				// Serialize the form along with the csrfToken.
				data: $('#settingsForm').serialize(),
				dataType: "json",
				success: postSettingsResult, // calls the result function.
				error: function(ErrorMsg) {
					console.log('Error' + ErrorMsg);
				}
			// Extract any errors. This is a new jQuery promise based function as of jQuery 1.8.
			}).fail(function (jqXHR, textStatus, error) {
				// Close the wait window that was launched in the calling function.
				kendo.ui.ExtWaitDialog.hide();
				// Display the error. The full response is: jqXHR.responseText, but we just want to extract the error.
				$.when(kendo.ui.ExtAlertDialog.show({ title: "Error while consuming the saveBlogOptions function", message: error, icon: "k-ext-error", width: "<cfoutput>#application.kendoExtendedUiWindowWidth#</cfoutput>" }) // or k-ext-error, k-ext-information, k-ext-question, k-ext-warning.  You can also specify height.
					).done(function () {
					
				});		
			});
		};

		function postSettingsResult(response){
			// Close the wait window that was launched in the calling function.
			kendo.ui.ExtWaitDialog.hide();
			// Close this window.
			$('#settingsWindow').kendoWindow('destroy');
		}
	</script>
		
	<script>
		var coll = document.getElementsByClassName("collapsible");
		var i;

		for (i = 0; i < coll.length; i++) {
		  coll[i].addEventListener("click", function() {
			this.classList.toggle("active");
			var content = this.nextElementSibling;
			if (content.style.display === "block") {
			  content.style.display = "none";
			} else {
			  content.style.display = "block";
			}
		  });
		}
	</script>
		
	<form id="settingsForm" action="#" method="post" data-role="validator">
	<input type="hidden" name="csrfToken" id="csrfToken" value="<cfoutput>#csrfToken#</cfoutput>">
	<input type="hidden" name="blogId" id="blogId" value="<cfoutput>#blogId#</cfoutput>">
	<table align="center" class="k-content" width="100%" cellpadding="2" cellspacing="0">
	  <cfsilent>
		<!---The first content class in the table should be empty. --->
		<cfset thisContentClass = HtmlUtilsObj.getKendoClass('')>
		<!--- Set the colspan property for borders --->
		<cfset thisColSpan = "2">
	  </cfsilent>
	  <tr height="1px">
		  <td align="left" valign="top" colspan="2" class="<cfoutput>#thisContentClass#</cfoutput>"></td>
	  </tr>
	  <tr valign="middle" height="30px">
		<td valign="bottom" align="left" class="<cfoutput>#thisContentClass#</cfoutput>" colspan="<cfoutput>#thisColSpan#</cfoutput>">
			These settings are essential to get your blog up and running. Make sure that your settings are correct before you proceed.
		</td>
	  </tr>
	  <tr height="1px">
		  <td align="left" valign="top" colspan="2" class="border <cfoutput>#thisContentClass#</cfoutput>"></td>
	  </tr>
	  <!-- Form content -->
	  <tr valign="middle" height="30px">
		<td valign="bottom" align="left" class="<cfoutput>#thisContentClass#</cfoutput>" colspan="<cfoutput>#thisColSpan#</cfoutput>">
			The Blog Title is the title of your site. This name will be shown on top of the page and will be used as the name of the site by the search engines.
		</td>
	  </tr>
	  <tr height="1px">
		  <td align="left" valign="top" colspan="2" class="border <cfoutput>#thisContentClass#</cfoutput>"></td>
	  </tr>
	<cfif session.isMobile>
	  <tr valign="middle">
		<td class="<cfoutput>#thisContentClass#</cfoutput>" colspan="2">
		<label for="blogTitle">Blog Title:</label>
		</td>
	   </tr>
	   <tr>
		<td class="<cfoutput>#thisContentClass#</cfoutput>" colspan="2">
			<input type="textbox" id="blogTitle" name="blogTitle" value="<cfoutput>#blogTitle#</cfoutput>" class="k-textbox" style="width: 95%" required>
		</td>
	  </tr>
	<cfelse><!---<cfif session.isMobile>--->
	  <tr valign="middle" height="30px">
		<td align="right" class="<cfoutput>#thisContentClass#</cfoutput>" style="width:20%">
			<label for="blogTitle">Blog Title:</label>
		</td>
		<td align="left" class="<cfoutput>#thisContentClass#</cfoutput>" style="width:80%">
			<input type="textbox" id="blogTitle" name="blogTitle" value="<cfoutput>#blogTitle#</cfoutput>" class="k-textbox" style="width: 50%" required>
		</td>
	  </tr>
	</cfif>	  
	  <cfsilent>
	  <!--- Set the class for alternating rows. --->
	  <!---After the first row, the content class should be the current class. --->
	  <cfset thisContentClass = HtmlUtilsObj.getKendoClass(thisContentClass)>
	  </cfsilent>
	  <tr height="2px">
		  <td align="left" valign="top" colspan="2" class="border <cfoutput>#thisContentClass#</cfoutput>"></td>
	  </tr>
	  <!-- Form content -->
	  <tr valign="middle" height="30px">
		<td valign="bottom" align="left" class="<cfoutput>#thisContentClass#</cfoutput>" colspan="<cfoutput>#thisColSpan#</cfoutput>">
			The Blog Description is used by the search engines. The search engine will return your site description in the search results so it is vital that it is short and concise. It is generally recommended by various SEO sites that the description should be less than 155 characters.
		</td>
	  </tr>
	  <tr height="1px">
		  <td align="left" valign="top" colspan="2" class="border <cfoutput>#thisContentClass#</cfoutput>"></td>
	  </tr>
	<cfif session.isMobile>
	  <tr valign="middle">
		<td class="<cfoutput>#thisContentClass#</cfoutput>" colspan="2">
			<label for="blogDescription">Blog Description:</label>
		</td>
	   </tr>
	   <tr>
		<td class="<cfoutput>#thisContentClass#</cfoutput>" colspan="2">
			<input type="textbox" name="blogDescription" id="blogDescription" value="<cfoutput>#blogDescription#</cfoutput>" class="k-textbox" style="width:95%" required>
		</td>
	  </tr>
	<cfelse><!---<cfif session.isMobile>--->
	  <tr valign="middle" height="30px">
		<td align="right" class="<cfoutput>#thisContentClass#</cfoutput>">
			<label for="blogDescription">Blog Description:</label>
		</td>
		<td align="left" class="<cfoutput>#thisContentClass#</cfoutput>">
			<input type="textbox" name="blogDescription" id="blogDescription" value="<cfoutput>#blogDescription#</cfoutput>" class="k-textbox" style="width:75%" required>
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
	  <tr valign="middle" height="30px">
		<td valign="bottom" align="left" class="<cfoutput>#thisContentClass#</cfoutput>" colspan="<cfoutput>#thisColSpan#</cfoutput>">
			What is the URL to your blog? The blog URL must contain an index.cfm at the end of the URL (ie- https://www.gregoryalexander.com/index.cfm). Also, if you are using SSL, type in https:// instead of http://. 
		</td>
	  </tr>
	  <tr height="1px">
		  <td align="left" valign="top" colspan="2" class="border <cfoutput>#thisContentClass#</cfoutput>"></td>
	  </tr>
	<cfif session.isMobile>
	  <tr valign="middle">
		<td class="<cfoutput>#thisContentClass#</cfoutput>" colspan="2">
			<label for="blogUrl">Blog URL:</label>
		</td>
	   </tr>
	   <tr>
		<td class="<cfoutput>#thisContentClass#</cfoutput>" colspan="2">
			<input type="text" name="blogUrl" id="blogUrl" value="<cfoutput>#blogUrl#</cfoutput>" class="k-textbox" style="width:75%" required>
		</td>
	  </tr>
	<cfelse><!---<cfif session.isMobile>--->
	  <tr valign="middle" height="30px">
		<td align="right" class="<cfoutput>#thisContentClass#</cfoutput>">
			<label for="blogUrl">Blog URL:</label></td>
		<td align="left" class="<cfoutput>#thisContentClass#</cfoutput>">
			<input type="text" name="blogUrl" id="blogUrl" value="<cfoutput>#blogUrl#</cfoutput>" class="k-textbox" style="width:75%" required>
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
	  <tr valign="middle" height="30px">
		<td valign="bottom" align="left" class="<cfoutput>#thisContentClass#</cfoutput>" colspan="<cfoutput>#thisColSpan#</cfoutput>">
			Uncheck this box if this is a development site. When unchecked, the site will block incoming robots and not be indexed by the search engines. Make sure that this is checked if you want the site to be indexed.
		</td>
	  </tr>
	  <tr height="1px">
		  <td align="left" valign="top" colspan="2" class="border <cfoutput>#thisContentClass#</cfoutput>"></td>
	  </tr>
	<cfif session.isMobile>
	  <tr valign="middle">
		<td class="<cfoutput>#thisContentClass#</cfoutput>" colspan="2">
			<label for="isProd">Production Site:</label>
		</td>
	   </tr>
	   <tr>
		<td class="<cfoutput>#thisContentClass#</cfoutput>" colspan="2">
			<input type="checkbox" name="isProd" id="isProd" value="1" <cfif isProd>checked</cfif>>
		</td>
	  </tr>
	<cfelse><!---<cfif session.isMobile>--->
	  <tr valign="middle" height="30px">
		<td align="right" class="<cfoutput>#thisContentClass#</cfoutput>">
			<label for="isProd">Is Production:</label>
		</td>
		<td align="left" class="<cfoutput>#thisContentClass#</cfoutput>">
			<input type="checkbox" name="isProd" id="isProd" value="1" <cfif isProd>checked</cfif>>
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
	  <tr valign="middle" height="30px">
		<td valign="bottom" align="left" class="<cfoutput>#thisContentClass#</cfoutput>" colspan="<cfoutput>#thisColSpan#</cfoutput>">
			The meta keywords are used by <b>some</b> of the search engines. However, google no longer uses them. This field is optional. 
		</td>
	  </tr>
	  <tr height="1px">
		  <td align="left" valign="top" colspan="2" class="border <cfoutput>#thisContentClass#</cfoutput>"></td>
	  </tr>
	<cfif session.isMobile>
	  <tr valign="middle">
		<td class="<cfoutput>#thisContentClass#</cfoutput>" colspan="2">
			<label for="blogMetaKeywords">SEO Meta Keywords:</label>
		</td>
	   </tr>
	   <tr>
		<td class="<cfoutput>#thisContentClass#</cfoutput>" colspan="2">
			<input type="text" name="blogMetaKeywords" id="blogMetaKeywords" value="<cfoutput>##</cfoutput>" class="k-textbox" style="width: 95%">
		</td>
	  </tr>
	<cfelse><!---<cfif session.isMobile>--->
	  <tr valign="middle" height="30px">
		<td align="right" class="<cfoutput>#thisContentClass#</cfoutput>">
			<label for="blogMetaKeywords">SEO Meta Keywords:</label>
		</td>
		<td align="left" class="<cfoutput>#thisContentClass#</cfoutput>">
			<input type="text" name="blogMetaKeywords" id="blogMetaKeywords" value="<cfoutput>##</cfoutput>" class="k-textbox" style="width: 75%">
		</td>
	  </tr>
	</cfif>	  
	  <!-- Border -->
	  <tr height="2px">
		  <td align="left" valign="top" colspan="<cfoutput>#thisColSpan#</cfoutput>" class="<cfoutput>#thisContentClass#</cfoutput>"></td>
	  </tr>
	  
	</table>
	<br/>
		
	<!---//***********************************************************************************************
						Parent Site
	//************************************************************************************************--->
	<button type="button" class="collapsible k-header">Parent Site Name and Link</button>
	<div class="content k-content">
		<table align="center" class="k-content" width="100%" cellpadding="2" cellspacing="0">
			
		  <cfsilent>
			<!---The first content class in the table should be empty. --->
			<cfset thisContentClass = HtmlUtilsObj.getKendoClass('')>
			<!--- Set the colspan property for borders --->
			<cfset thisColSpan = "2">
		  </cfsilent>
	
		  <tr height="1px">
			  <td align="left" valign="top" colspan="2" class="<cfoutput>#thisContentClass#</cfoutput>">
			  	If this blog is part of a bigger site, enter the parent site name and link. This setting will allow the user to click on the icon at the top of the page to get back to your main site and will place a link inside of the menu to navigate to the parent site. These settings are optional.
			  </td>
		  </tr>
		  <!-- Border -->
		  <tr height="2px">
			  <td align="left" valign="top" colspan="<cfoutput>#thisColSpan#</cfoutput>" class="<cfoutput>#thisContentClass#</cfoutput>"></td>
		  </tr>
		<cfif session.isMobile>
		  <tr valign="middle">
			<td class="<cfoutput>#thisContentClass#</cfoutput>" colspan="2">
				<label for="parentSiteName">Parent Site Name:</label>
			</td>
		   </tr>
		   <tr>
			<td class="<cfoutput>#thisContentClass#</cfoutput>" colspan="2">
				<input type="text" id="parentSiteName" name="parentSiteName" value="<cfoutput>#parentSiteName#</cfoutput>" class="k-textbox" style="width: 95%" /> 
			</td>
		  </tr>
		<cfelse><!---<cfif session.isMobile>--->
		  <tr>
			<td align="right" class="<cfoutput>#thisContentClass#</cfoutput>" style="width: 20%"> 
				<label for="parentSiteName">Parent Site Name:</label>
			</td>
			<td class="<cfoutput>#thisContentClass#</cfoutput>" style="width: 80%">
				<input type="text" id="parentSiteName" name="parentSiteName" value="<cfoutput>#parentSiteName#</cfoutput>" class="k-textbox" style="width: 50%" />    
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
		  	<td align="left" valign="bottom" colspan="2" class="border <cfoutput>#thisContentClass#</cfoutput>"></td>
		  </tr>
		 <cfif session.isMobile>
		  <tr valign="middle">
			<td class="<cfoutput>#thisContentClass#</cfoutput>" colspan="2">
				<label for="parentSiteLink">Parent Site Link</label>
			</td>
		   </tr>
		   <tr>
			<td class="<cfoutput>#thisContentClass#</cfoutput>" colspan="2">
				<input type="text" name="parentSiteLink" id="parentSiteLink" value="<cfoutput>#parentSiteLink#</cfoutput>" class="k-textbox" style="width: 95%">
			</td>
		  </tr>
		<cfelse><!---<cfif session.isMobile>---> 
		  <tr valign="middle" height="30px">
			<td valign="bottom" align="right" class="<cfoutput>#thisContentClass#</cfoutput>">
				<label for="parentSiteLink">Parent Site Link</label>
			</td>
			<td valign="bottom" align="left" class="<cfoutput>#thisContentClass#</cfoutput>">
				<input type="text" name="parentSiteLink" id="parentSiteLink" value="<cfoutput>#parentSiteLink#</cfoutput>" class="k-textbox" style="width: 50%">
			</td>
		  </tr>
		</cfif>
		  <!-- Border -->
		  <tr height="2px">
			<td align="left" valign="top" colspan="<cfoutput>#thisColSpan#</cfoutput>" class="<cfoutput>#thisContentClass#</cfoutput>"></td>
		  </tr>
		
		</table>
	</div>
			
	<!---//***********************************************************************************************
						Server Time Zone
	//************************************************************************************************--->

	<!--- Invoke the Time Zone cfc --->
	<cfobject component="#application.timeZoneComponentPath#" name="TimeZoneObj">
		
	<!--- Get the time zone identifier on the server (ie America/Los_Angeles) from the TimeZone component --->
	<cfset serverTimeZoneId = TimeZoneObj.getServerId()>
	<cfset serverTimeZone = TimeZoneObj.getServerTZ()>
	<cfset serverTimeZoneData = TimeZoneObj.getTimeZone()>
		
	<script>
		var tzStrings = [
			{"label":"(GMT-12:00) International Date Line West","value":"Etc/GMT+12"},
			{"label":"(GMT-11:00) Midway Island, Samoa","value":"Pacific/Midway"},
			{"label":"(GMT-10:00) Hawaii","value":"Pacific/Honolulu"},
			{"label":"(GMT-09:00) Alaska","value":"US/Alaska"},
			{"label":"(GMT-08:00) Pacific Time (US & Canada)","value":"America/Los_Angeles"},
			{"label":"(GMT-08:00) Tijuana, Baja California","value":"America/Tijuana"},
			{"label":"(GMT-07:00) Arizona","value":"US/Arizona"},
			{"label":"(GMT-07:00) Chihuahua, La Paz, Mazatlan","value":"America/Chihuahua"},
			{"label":"(GMT-07:00) Mountain Time (US & Canada)","value":"US/Mountain"},
			{"label":"(GMT-06:00) Central America","value":"America/Managua"},
			{"label":"(GMT-06:00) Central Time (US & Canada)","value":"US/Central"},
			{"label":"(GMT-06:00) Guadalajara, Mexico City, Monterrey","value":"America/Mexico_City"},
			{"label":"(GMT-06:00) Saskatchewan","value":"Canada/Saskatchewan"},
			{"label":"(GMT-05:00) Bogota, Lima, Quito, Rio Branco","value":"America/Bogota"},
			{"label":"(GMT-05:00) Eastern Time (US & Canada)","value":"US/Eastern"},
			{"label":"(GMT-05:00) Indiana (East)","value":"US/East-Indiana"},
			{"label":"(GMT-04:00) Atlantic Time (Canada)","value":"Canada/Atlantic"},
			{"label":"(GMT-04:00) Caracas, La Paz","value":"America/Caracas"},
			{"label":"(GMT-04:00) Manaus","value":"America/Manaus"},
			{"label":"(GMT-04:00) Santiago","value":"America/Santiago"},
			{"label":"(GMT-03:30) Newfoundland","value":"Canada/Newfoundland"},
			{"label":"(GMT-03:00) Brasilia","value":"America/Sao_Paulo"},
			{"label":"(GMT-03:00) Buenos Aires, Georgetown","value":"America/Argentina/Buenos_Aires"},
			{"label":"(GMT-03:00) Greenland","value":"America/Godthab"},
			{"label":"(GMT-03:00) Montevideo","value":"America/Montevideo"},
			{"label":"(GMT-02:00) Mid-Atlantic","value":"America/Noronha"},
			{"label":"(GMT-01:00) Cape Verde Is.","value":"Atlantic/Cape_Verde"},
			{"label":"(GMT-01:00) Azores","value":"Atlantic/Azores"},
			{"label":"(GMT+00:00) Casablanca, Monrovia, Reykjavik","value":"Africa/Casablanca"},
			{"label":"(GMT+00:00) Greenwich Mean Time : Dublin, Edinburgh, Lisbon, London","value":"Etc/Greenwich"},
			{"label":"(GMT+01:00) Amsterdam, Berlin, Bern, Rome, Stockholm, Vienna","value":"Europe/Amsterdam"},
			{"label":"(GMT+01:00) Belgrade, Bratislava, Budapest, Ljubljana, Prague","value":"Europe/Belgrade"},
			{"label":"(GMT+01:00) Brussels, Copenhagen, Madrid, Paris","value":"Europe/Brussels"},
			{"label":"(GMT+01:00) Sarajevo, Skopje, Warsaw, Zagreb","value":"Europe/Sarajevo"},
			{"label":"(GMT+01:00) West Central Africa","value":"Africa/Lagos"},
			{"label":"(GMT+02:00) Amman","value":"Asia/Amman"},
			{"label":"(GMT+02:00) Athens, Bucharest, Istanbul","value":"Europe/Athens"},
			{"label":"(GMT+02:00) Beirut","value":"Asia/Beirut"},
			{"label":"(GMT+02:00) Cairo","value":"Africa/Cairo"},
			{"label":"(GMT+02:00) Harare, Pretoria","value":"Africa/Harare"},
			{"label":"(GMT+02:00) Helsinki, Kyiv, Riga, Sofia, Tallinn, Vilnius","value":"Europe/Helsinki"},
			{"label":"(GMT+02:00) Jerusalem","value":"Asia/Jerusalem"},
			{"label":"(GMT+02:00) Minsk","value":"Europe/Minsk"},
			{"label":"(GMT+02:00) Windhoek","value":"Africa/Windhoek"},
			{"label":"(GMT+03:00) Kuwait, Riyadh, Baghdad","value":"Asia/Kuwait"},
			{"label":"(GMT+03:00) Moscow, St. Petersburg, Volgograd","value":"Europe/Moscow"},
			{"label":"(GMT+03:00) Nairobi","value":"Africa/Nairobi"},
			{"label":"(GMT+03:00) Tbilisi","value":"Asia/Tbilisi"},
			{"label":"(GMT+03:30) Tehran","value":"Asia/Tehran"},
			{"label":"(GMT+04:00) Abu Dhabi, Muscat","value":"Asia/Muscat"},
			{"label":"(GMT+04:00) Baku","value":"Asia/Baku"},
			{"label":"(GMT+04:00) Yerevan","value":"Asia/Yerevan"},
			{"label":"(GMT+04:30) Kabul","value":"Asia/Kabul"},
			{"label":"(GMT+05:00) Yekaterinburg","value":"Asia/Yekaterinburg"},
			{"label":"(GMT+05:00) Islamabad, Karachi, Tashkent","value":"Asia/Karachi"},
			{"label":"(GMT+05:30) Chennai, Kolkata, Mumbai, New Delhi","value":"Asia/Calcutta"},
			{"label":"(GMT+05:30) Sri Jayawardenapura","value":"Asia/Calcutta"},
			{"label":"(GMT+05:45) Kathmandu","value":"Asia/Katmandu"},
			{"label":"(GMT+06:00) Almaty, Novosibirsk","value":"Asia/Almaty"},
			{"label":"(GMT+06:00) Astana, Dhaka","value":"Asia/Dhaka"},
			{"label":"(GMT+06:30) Yangon (Rangoon)","value":"Asia/Rangoon"},
			{"label":"(GMT+07:00) Bangkok, Hanoi, Jakarta","value":"Asia/Bangkok"},
			{"label":"(GMT+07:00) Krasnoyarsk","value":"Asia/Krasnoyarsk"},
			{"label":"(GMT+08:00) Beijing, Chongqing, Hong Kong, Urumqi","value":"Asia/Hong_Kong"},
			{"label":"(GMT+08:00) Kuala Lumpur, Singapore","value":"Asia/Kuala_Lumpur"},
			{"label":"(GMT+08:00) Irkutsk, Ulaan Bataar","value":"Asia/Irkutsk"},
			{"label":"(GMT+08:00) Perth","value":"Australia/Perth"},
			{"label":"(GMT+08:00) Taipei","value":"Asia/Taipei"},
			{"label":"(GMT+09:00) Osaka, Sapporo, Tokyo","value":"Asia/Tokyo"},
			{"label":"(GMT+09:00) Seoul","value":"Asia/Seoul"},
			{"label":"(GMT+09:00) Yakutsk","value":"Asia/Yakutsk"},
			{"label":"(GMT+09:30) Adelaide","value":"Australia/Adelaide"},
			{"label":"(GMT+09:30) Darwin","value":"Australia/Darwin"},
			{"label":"(GMT+10:00) Brisbane","value":"Australia/Brisbane"},
			{"label":"(GMT+10:00) Canberra, Melbourne, Sydney","value":"Australia/Canberra"},
			{"label":"(GMT+10:00) Hobart","value":"Australia/Hobart"},
			{"label":"(GMT+10:00) Guam, Port Moresby","value":"Pacific/Guam"},
			{"label":"(GMT+10:00) Vladivostok","value":"Asia/Vladivostok"},
			{"label":"(GMT+11:00) Magadan, Solomon Is., New Caledonia","value":"Asia/Magadan"},
			{"label":"(GMT+12:00) Auckland, Wellington","value":"Pacific/Auckland"},
			{"label":"(GMT+12:00) Fiji, Kamchatka, Marshall Is.","value":"Pacific/Fiji"},
			{"label":"(GMT+13:00) Nuku'alofa","value":"Pacific/Tongatapu"}
		]

		var tzInts = [
			{"label":"(GMT-12:00) International Date Line West","value":"-12"},
			{"label":"(GMT-11:00) Midway Island, Samoa","value":"-11"},
			{"label":"(GMT-10:00) Hawaii","value":"-10"},
			{"label":"(GMT-09:00) Alaska","value":"-9"},
			{"label":"(GMT-08:00) Pacific Time (US & Canada)","value":"-8"},
			{"label":"(GMT-08:00) Tijuana, Baja California","value":"-8"},
			{"label":"(GMT-07:00) Arizona","value":"-7"},
			{"label":"(GMT-07:00) Chihuahua, La Paz, Mazatlan","value":"-7"},
			{"label":"(GMT-07:00) Mountain Time (US & Canada)","value":"-7"},
			{"label":"(GMT-06:00) Central America","value":"-6"},
			{"label":"(GMT-06:00) Central Time (US & Canada)","value":"-6"},
			{"label":"(GMT-05:00) Bogota, Lima, Quito, Rio Branco","value":"-5"},
			{"label":"(GMT-05:00) Eastern Time (US & Canada)","value":"-5"},
			{"label":"(GMT-05:00) Indiana (East)","value":"-5"},
			{"label":"(GMT-04:00) Atlantic Time (Canada)","value":"-4"},
			{"label":"(GMT-04:00) Caracas, La Paz","value":"-4"},
			{"label":"(GMT-04:00) Manaus","value":"-4"},
			{"label":"(GMT-04:00) Santiago","value":"-4"},
			{"label":"(GMT-03:30) Newfoundland","value":"-3.5"},
			{"label":"(GMT-03:00) Brasilia","value":"-3"},
			{"label":"(GMT-03:00) Buenos Aires, Georgetown","value":"-3"},
			{"label":"(GMT-03:00) Greenland","value":"-3"},
			{"label":"(GMT-03:00) Montevideo","value":"-3"},
			{"label":"(GMT-02:00) Mid-Atlantic","value":"-2"},
			{"label":"(GMT-01:00) Cape Verde Is.","value":"-1"},
			{"label":"(GMT-01:00) Azores","value":"-1"},
			{"label":"(GMT+00:00) Casablanca, Monrovia, Reykjavik","value":"0"},
			{"label":"(GMT+00:00) Greenwich Mean Time : Dublin, Edinburgh, Lisbon, London","value":"0"},
			{"label":"(GMT+01:00) Amsterdam, Berlin, Bern, Rome, Stockholm, Vienna","value":"1"},
			{"label":"(GMT+01:00) Belgrade, Bratislava, Budapest, Ljubljana, Prague","value":"1"},
			{"label":"(GMT+01:00) Brussels, Copenhagen, Madrid, Paris","value":"1"},
			{"label":"(GMT+01:00) Sarajevo, Skopje, Warsaw, Zagreb","value":"1"},
			{"label":"(GMT+01:00) West Central Africa","value":"1"},
			{"label":"(GMT+02:00) Amman","value":"2"},
			{"label":"(GMT+02:00) Athens, Bucharest, Istanbul","value":"2"},
			{"label":"(GMT+02:00) Beirut","value":"2"},
			{"label":"(GMT+02:00) Cairo","value":"2"},
			{"label":"(GMT+02:00) Harare, Pretoria","value":"2"},
			{"label":"(GMT+02:00) Helsinki, Kyiv, Riga, Sofia, Tallinn, Vilnius","value":"2"},
			{"label":"(GMT+02:00) Jerusalem","value":"2"},
			{"label":"(GMT+02:00) Minsk","value":"2"},
			{"label":"(GMT+02:00) Windhoek","value":"2"},
			{"label":"(GMT+03:00) Kuwait, Riyadh, Baghdad","value":"3"},
			{"label":"(GMT+03:00) Moscow, St. Petersburg, Volgograd","value":"3"},
			{"label":"(GMT+03:00) Nairobi","value":"3"},
			{"label":"(GMT+03:00) Tbilisi","value":"3"},
			{"label":"(GMT+03:30) Tehran","value":"3.5"},
			{"label":"(GMT+04:00) Abu Dhabi, Muscat","value":"4"},
			{"label":"(GMT+04:00) Baku","value":"4"},
			{"label":"(GMT+04:00) Yerevan","value":"4"},
			{"label":"(GMT+04:30) Kabul","value":"4.5"},
			{"label":"(GMT+05:00) Yekaterinburg","value":"5"},
			{"label":"(GMT+05:00) Islamabad, Karachi, Tashkent","value":"5"},
			{"label":"(GMT+05:30) Sri Jayawardenapura","value":"5.5"},
			{"label":"(GMT+05:30) Chennai, Kolkata, Mumbai, New Delhi","value":"5.5"},
			{"label":"(GMT+05:45) Kathmandu","value":"5.75"},
			{"label":"(GMT+06:00) Almaty, Novosibirsk","value":"6"},{"label":"(GMT+06:00) Astana, Dhaka","value":"6"},
			{"label":"(GMT+06:30) Yangon (Rangoon)","value":"6.5"},
			{"label":"(GMT+07:00) Bangkok, Hanoi, Jakarta","value":"7"},
			{"label":"(GMT+07:00) Krasnoyarsk","value":"7"},
			{"label":"(GMT+08:00) Beijing, Chongqing, Hong Kong, Urumqi","value":"8"},
			{"label":"(GMT+08:00) Kuala Lumpur, Singapore","value":"8"},
			{"label":"(GMT+08:00) Irkutsk, Ulaan Bataar","value":"8"},
			{"label":"(GMT+08:00) Perth","value":"8"},
			{"label":"(GMT+08:00) Taipei","value":"8"},
			{"label":"(GMT+09:00) Osaka, Sapporo, Tokyo","value":"9"},
			{"label":"(GMT+09:00) Seoul","value":"9"},
			{"label":"(GMT+09:00) Yakutsk","value":"9"},
			{"label":"(GMT+09:30) Adelaide","value":"9.5"},
			{"label":"(GMT+09:30) Darwin","value":"9.5"},
			{"label":"(GMT+10:00) Brisbane","value":"10"},
			{"label":"(GMT+10:00) Canberra, Melbourne, Sydney","value":"10"},
			{"label":"(GMT+10:00) Hobart","value":"10"},
			{"label":"(GMT+10:00) Guam, Port Moresby","value":"10"},
			{"label":"(GMT+10:00) Vladivostok","value":"10"},
			{"label":"(GMT+11:00) Magadan, Solomon Is., New Caledonia","value":"11"},
			{"label":"(GMT+12:00) Auckland, Wellington","value":"12"},
			{"label":"(GMT+12:00) Fiji, Kamchatka, Marshall Is.","value":"12"},
			{"label":"(GMT+13:00) Nuku'alofa","value":"13"}
		]	
		
		// My timezone dropdown
		var blogTimeZone = $("#blogTimeZone").kendoDropDownList({
			//cascadeFrom: "agencyRateCompanyCode",
			optionLabel: "Select...",
			dataTextField: "label",
			dataValueField: "value",
			filter: "contains",
			dataSource: tzInts,
			change: onBlogTimeZoneChange,
		}).data("kendoDropDownList");

		// Set default value by the value (this is used when the container is populated via the datasource).
		var blogTimeZone = $("#blogTimeZone").data("kendoDropDownList");
		blogTimeZone.value( <cfoutput>'#blogTimeZone#'</cfoutput> );
		
		// Server timezone dropdown
		var serverTimeZone = $("#serverTimeZone").kendoDropDownList({
			//cascadeFrom: "agencyRateCompanyCode",
			optionLabel: "Select...",
			dataTextField: "label",
			dataValueField: "value",
			filter: "contains",
			dataSource: tzInts,
			change: onServerTimeZoneChange
		}).data("kendoDropDownList");

		// Set default value by the value (this is used when the container is populated via the datasource).
		var serverTimeZone = $("#serverTimeZone").data("kendoDropDownList");
		serverTimeZone.value(<cfoutput>'#serverTimeZoneData.offset#'</cfoutput>);
	<cfif len(blogTimeZone)>
		// Prompt a change event to populate the hidden field
		serverTimeZone.trigger("change");
	<cfelse>
		// Disable the server timezone dropdown menu if the blog time zone is not selected
		serverTimeZone.enable(false);
	</cfif>
		
		// Calculate the server offset by the blog time.
		function onBlogTimeZoneChange(e){
		<cfif !len(blogTimeZone)>
			// When the blog time zone was selected for the first time, enable the server time zone dropdown menu
			var serverTimeZone = $("#serverTimeZone").data("kendoDropDownList");
			serverTimeZone.enable(true);
		</cfif>
			// Get the selected blog time zone value
			blogTimeZone = this.value();
			// Set the value of the hidden form 
			$("#blogTimeZoneValue").val(blogTimeZone);	
			// Get the server timezone
			serverTimeZone = $("#serverTimeZoneValue").val();			
			// Calculate the offset
			serverTimeZoneOffset = parseInt(blogTimeZone)-parseInt(serverTimeZone);
			// And populate the server time offset container
			$("#serverTimeZoneOffset").val(serverTimeZoneOffset);
			
		}//...function onBlogTimeZoneChange(e)
		
		// Calculate the server offset by the server time.
		function onServerTimeZoneChange(e){
			// Get the value
			serverTimeZone = this.value();
			// Update the hidden form value
			$("#serverTimeZoneValue").val(serverTimeZone);
			// Get the blog timezone
			var blogTimeZone = $("#blogTimeZone").data("kendoDropDownList");
			blogTimeZoneValue = blogTimeZone.value();
			// Calculate the offset
			serverTimeZoneOffset = parseInt(blogTimeZoneValue)-parseInt(serverTimeZone);
			// And populate the server time offset container
			$("#serverTimeZoneOffset").val(serverTimeZoneOffset);
		}//...function onBlogTimeZoneChange(e)
			  
	</script>	
		
	<button type="button" class="collapsible k-header">Server Time Zone</button>
	<div class="content k-content">
		<table align="center" class="k-content" width="100%" cellpadding="2" cellspacing="0">
		  <input type="hidden" name="blogTimeZoneValue" id="blogTimeZoneValue" value="<cfoutput>#blogTimeZone#</cfoutput> ">
		  <input type="hidden" name="serverTimeZoneValue" id="serverTimeZoneValue" value="<cfoutput>#serverTimeZoneData.offset#</cfoutput>">
		  <cfsilent>
			<!---The first content class in the table should be empty. --->
			<cfset thisContentClass = HtmlUtilsObj.getKendoClass('')>
			<!--- Set the colspan property for borders --->
			<cfset thisColSpan = "2">
		  </cfsilent>
			 
		  <tr height="1px">
			  <td align="left" valign="top" colspan="2" class="<cfoutput>#thisContentClass#</cfoutput>"></td>
		  </tr>
		  <tr height="1px">
			  <td></td>
			  <td align="left" valign="top" class="<cfoutput>#thisContentClass#</cfoutput>">
			  	Your hosting provider or server may reside in a different time-zone. These settings are critical when this is the case.  If your server is in a different time-zone, you will want the post date to show the  time that you are in- not necessarilly where the server is.
				The server time zone is automatically selected for you. However, you may change it if necessary.
			  </td>
		  </tr>
		  <!-- Border -->
		  <tr height="2px">
			  <td align="left" valign="top" colspan="<cfoutput>#thisColSpan#</cfoutput>" class="<cfoutput>#thisContentClass#</cfoutput>"></td>
		  </tr>
		  <tr>
			<td align="right">Current Blog Time:</td>
			<td><cfoutput>#dateTimeFormat(application.blog.blogNow(), "medium")#</cfoutput> (Refresh the window to get the current time)</td>
		  </tr>
		  <!-- Border -->
		  <tr height="2px">
			  <td align="left" valign="top" colspan="<cfoutput>#thisColSpan#</cfoutput>" class="<cfoutput>#thisContentClass#</cfoutput>"></td>
		  </tr>
		<cfif session.isMobile>
		  <tr valign="middle">
			<td class="<cfoutput>#thisContentClass#</cfoutput>" colspan="2">
				<label for="blogTimeZone">Your time-zone:</label>
			</td>
		   </tr>
		   <tr>
			<td class="<cfoutput>#thisContentClass#</cfoutput>" colspan="2">
				<select id="blogTimeZone" name="blogTimeZone" style="width:95%"></select>
			</td>
		  </tr>
		<cfelse><!---<cfif session.isMobile>---> 
		  <tr>
			<td align="right" class="<cfoutput>#thisContentClass#</cfoutput>" style="width: 20%"> 
				<label for="blogTimeZone">Your time-zone:</label>
			</td>
			<td class="<cfoutput>#thisContentClass#</cfoutput>">
				<select id="blogTimeZone" name="blogTimeZone" style="width:50%"></select>
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
		<cfif session.isMobile>
		  <tr valign="middle">
			<td class="<cfoutput>#thisContentClass#</cfoutput>" colspan="2">
				<label for="serverTimeZone">Server Time Zone:</label>
			</td>
		   </tr>
		   <tr>
			<td class="<cfoutput>#thisContentClass#</cfoutput>" colspan="2">
				<select id="serverTimeZone" name="serverTimeZone" style="width:95%"></select>
			</td>
		  </tr>
		<cfelse><!---<cfif session.isMobile>---> 
		  <tr>
			<td align="right" class="<cfoutput>#thisContentClass#</cfoutput>" style="width: 20%"> 
				<label for="serverTimeZone">Server Time Zone:</label>
			</td>
			<td class="<cfoutput>#thisContentClass#</cfoutput>">
				<select id="serverTimeZone" name="serverTimeZone" style="width:50%"></select>
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
		  <!-- Border -->
		  <tr height="2px">
			  <td align="left" valign="top" colspan="<cfoutput>#thisColSpan#</cfoutput>" class="<cfoutput>#thisContentClass#</cfoutput>"></td>
		  </tr>
		<cfif session.isMobile>
		  <tr valign="middle">
			<td class="<cfoutput>#thisContentClass#</cfoutput>" colspan="2">
				<label for="serverTimeZoneOffset">Server Time Zone Offset:</label>
			</td>
		   </tr>
		   <tr>
			<td class="<cfoutput>#thisContentClass#</cfoutput>" colspan="2">
				<input type="number" id="serverTimeZoneOffset" name="serverTimeZoneOffset" value="<cfoutput>#serverTimeZoneOffset#</cfoutput>" min="-12" max="13" step="1" class="k-textbox" required> 
			</td>
		  </tr>
		<cfelse><!---<cfif session.isMobile>---> 
		  <tr>
			<td align="right" class="<cfoutput>#thisContentClass#</cfoutput>" style="width: 20%"> 
				<label for="serverTimeZoneOffset">Server Time Zone Offset:</label>
			</td>
			<td class="<cfoutput>#thisContentClass#</cfoutput>">
				<input type="number" id="serverTimeZoneOffset" name="serverTimeZoneOffset" value="<cfoutput>#serverTimeZoneOffset#</cfoutput>" min="-12" max="13" step="1" class="k-textbox" required>
			</td>
		  </tr>
		</cfif>
		</table>
	</div>
			  
	<!---//***********************************************************************************************
						Database connectivity
	//************************************************************************************************--->
				
	<button type="button" class="collapsible k-header">Database Connectivity</button>
	<div class="content k-content">
		<table align="center" class="k-content" width="100%" cellpadding="2" cellspacing="0">
			
		  <cfsilent>
			<!---The first content class in the table should be empty. --->
			<cfset thisContentClass = HtmlUtilsObj.getKendoClass('')>
			<!--- Set the colspan property for borders --->
			<cfset thisColSpan = "2">
		  </cfsilent>
			 
		  <tr height="1px">
			  <td align="left" valign="top" colspan="2" class="<cfoutput>#thisContentClass#</cfoutput>"></td>
		  </tr>
		  <tr height="1px">
			  <td align="left" valign="top" colspan="2" class="<cfoutput>#thisContentClass#</cfoutput>">
			  	The database credentials should be provided for by your DBA or your hosting provider. The ColdFusion DSN is required but the other database settings are optional.
			  </td>
		  </tr>
		  <!-- Border -->
		  <tr height="2px">
			  <td align="left" valign="top" colspan="<cfoutput>#thisColSpan#</cfoutput>" class="<cfoutput>#thisContentClass#</cfoutput>"></td>
		  </tr>
		<cfif session.isMobile>
		  <tr valign="middle">
			<td class="<cfoutput>#thisContentClass#</cfoutput>" colspan="2">
				<label for="dsn">ColdFusion Database DSN:</label>
			</td>
		   </tr>
		   <tr>
			<td class="<cfoutput>#thisContentClass#</cfoutput>" colspan="2">
				<input type="text" name="dsn" id="dsn" value="<cfoutput>#blogDsn#</cfoutput>" class="k-textbox" style="width: 95%" required />
			</td>
		  </tr>
		<cfelse><!---<cfif session.isMobile>--->
		  <tr>
			<td align="right" class="<cfoutput>#thisContentClass#</cfoutput>" style="width: 20%"> 
				<label for="dsn">Database DSN:</label>
			</td>
			<td class="<cfoutput>#thisContentClass#</cfoutput>">
				<input type="text" name="dsn" id="dsn" value="<cfoutput>#blogDsn#</cfoutput>" class="k-textbox" style="width: 50%" required />
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
		<cfif session.isMobile>
		  <tr valign="middle">
			<td class="<cfoutput>#thisContentClass#</cfoutput>" colspan="2">
				<label for="dsnUserName">DSN User Name:</label>
			</td>
		   </tr>
		   <tr>
			<td class="<cfoutput>#thisContentClass#</cfoutput>" colspan="2">
				<input type="text" name="dsnUserName" id="dsnUserName" value="<cfoutput>#blogDsnUserName#</cfoutput>" class="k-textbox" style="width: 95%" />
			</td>
		  </tr>
		<cfelse><!---<cfif session.isMobile>--->
		  <tr>
			<td align="right" class="<cfoutput>#thisContentClass#</cfoutput>" style="width: 20%"> 
				<label for="dsnUserName">DSN User Name:</label>
			</td>
			<td class="<cfoutput>#thisContentClass#</cfoutput>">
				<input type="text" name="dsnUserName" id="dsnUserName" value="<cfoutput>#blogDsnUserName#</cfoutput>" class="k-textbox" style="width: 50%" />
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
		<cfif session.isMobile>
		  <tr valign="middle">
			<td class="<cfoutput>#thisContentClass#</cfoutput>" colspan="2">
				<label for="dsnPassword">DSN Password:</label>
			</td>
		   </tr>
		   <tr>
			<td class="<cfoutput>#thisContentClass#</cfoutput>" colspan="2">
				<input type="text" name="dsnPassword" id="dsnPassword" value="<cfoutput>#blogDsnPassword#</cfoutput>" class="k-textbox" style="width: 95%" />
			</td>
		  </tr>
		<cfelse><!---<cfif session.isMobile>--->
		  <tr>
			<td align="right" class="<cfoutput>#thisContentClass#</cfoutput>" style="width: 20%"> 
				<label for="dsnPassword">DSN Password:</label>
			</td>
			<td class="<cfoutput>#thisContentClass#</cfoutput>">
				<input type="text" name="dsnPassword" id="dsnPassword" value="<cfoutput>#blogDsnPassword#</cfoutput>" class="k-textbox" style="width: 50%" />
			</td>
		  </tr>
		</cfif>
		  <!-- Border -->
		  <tr height="2px">
			  <td align="left" valign="top" colspan="<cfoutput>#thisColSpan#</cfoutput>" class="<cfoutput>#thisContentClass#</cfoutput>"></td>
		  </tr>
		
		</table>
	</div>
			  
	<!---//***********************************************************************************************
						Mail Server Settings
	//************************************************************************************************--->
				
	<button type="button" class="collapsible k-header">Mail Server Settings</button>
	<div class="content k-content">
		<table align="center" class="k-content" width="100%" cellpadding="2" cellspacing="0">
			
		  <cfsilent>
			<!---The first content class in the table should be empty. --->
			<cfset thisContentClass = HtmlUtilsObj.getKendoClass('')>
			<!--- Set the colspan property for borders --->
			<cfset thisColSpan = "2">
		  </cfsilent>
			 
		  <tr height="1px">
			  <td align="left" valign="top" colspan="2" class="<cfoutput>#thisContentClass#</cfoutput>"></td>
		  </tr>
		  <tr height="1px">
			  <td align="left" valign="top" colspan="2" class="<cfoutput>#thisContentClass#</cfoutput>">
			  	Please get the mail server settings from your server administrator or your hosting provider. All of these settings are necessary.
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
		  <tr height="1px">
			  <td align="left" valign="top" colspan="2" class="<cfoutput>#thisContentClass#</cfoutput>"></td>
		  </tr>
		<cfif session.isMobile>
		  <tr valign="middle">
			<td class="<cfoutput>#thisContentClass#</cfoutput>" colspan="2">
				<label for="mailServer">Mail Server:</label>
			</td>
		   </tr>
		   <tr>
			<td class="<cfoutput>#thisContentClass#</cfoutput>" colspan="2">
				<input type="textbox" name="mailServer" id="mailServer" value="<cfoutput>#mailServer#</cfoutput>" class="k-textbox" style="width: 50%" required />
			</td>
		  </tr>
		<cfelse><!---<cfif session.isMobile>--->
		  <tr>
			<td align="right" class="<cfoutput>#thisContentClass#</cfoutput>" style="width: 20%"> 
				<label for="mailServer">Mail Server:</label>
			</td>
			<td class="<cfoutput>#thisContentClass#</cfoutput>">
				<input type="textbox" name="mailServer" id="mailServer" value="<cfoutput>#mailServer#</cfoutput>" class="k-textbox" style="width: 50%" required />
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
		<cfif session.isMobile>
		  <tr valign="middle">
			<td class="<cfoutput>#thisContentClass#</cfoutput>" colspan="2">
				<label for="mailUserName">Mail User Name:</label>
			</td>
		   </tr>
		   <tr>
			<td class="<cfoutput>#thisContentClass#</cfoutput>" colspan="2">
				<input type="text" name="mailUserName" id="mailUserName" value="<cfoutput>#mailUserName#</cfoutput>" class="k-textbox" style="width: 95%" required/>
			</td>
		  </tr>
		<cfelse><!---<cfif session.isMobile>--->
		  <tr>
			<td align="right" class="<cfoutput>#thisContentClass#</cfoutput>" style="width: 20%"> 
				<label for="mailUserName">Mail User Name:</label>
			</td>
			<td class="<cfoutput>#thisContentClass#</cfoutput>">
				<input type="text" name="mailUserName" id="mailUserName" value="<cfoutput>#mailUserName#</cfoutput>" class="k-textbox" style="width: 50%" required/>
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
		  <tr height="1px">
			  <td align="left" valign="top" colspan="2" class="<cfoutput>#thisContentClass#</cfoutput>"></td>
		  </tr>
		<cfif session.isMobile>
		  <tr valign="middle">
			<td class="<cfoutput>#thisContentClass#</cfoutput>" colspan="2">
				<label for="mailPassword">Mail Password:</label>
			</td>
		   </tr>
		   <tr>
			<td class="<cfoutput>#thisContentClass#</cfoutput>" colspan="2">
				<input type="text" name="mailPassword" id="mailPassword" value="<cfoutput>#mailPassword#</cfoutput>" class="k-textbox" style="width: 95%" required />
			</td>
		  </tr>
		<cfelse><!---<cfif session.isMobile>--->
		  <tr>
			<td align="right" class="<cfoutput>#thisContentClass#</cfoutput>" style="width: 20%"> 
				<label for="mailPassword">Mail Password:</label>
			</td>
			<td class="<cfoutput>#thisContentClass#</cfoutput>">
				<input type="text" name="mailPassword" id="mailPassword" value="<cfoutput>#mailPassword#</cfoutput>" class="k-textbox" style="width: 50%" required /> 
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
		<cfif session.isMobile>
		  <tr valign="middle">
			<td class="<cfoutput>#thisContentClass#</cfoutput>" colspan="2">
				<label for="failTo">Mail Failto Address:</label>
			</td>
		   </tr>
		   <tr>
			<td class="<cfoutput>#thisContentClass#</cfoutput>" colspan="2">
				<input type="text" name="failTo" id="failTo" value="<cfoutput>#failTo#</cfoutput>" class="k-textbox" style="width: 95%" />
			</td>
		  </tr>
		<cfelse><!---<cfif session.isMobile>--->
		  <tr>
			<td align="right" class="<cfoutput>#thisContentClass#</cfoutput>" style="width: 20%"> 
				<label for="failTo">Mail Failto Address:</label>
			</td>
			<td class="<cfoutput>#thisContentClass#</cfoutput>">
				<input type="text" name="failTo" id="failTo" value="<cfoutput>#failTo#</cfoutput>" class="k-textbox" style="width: 50%" />
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
		<cfif session.isMobile>
		  <tr valign="middle">
			<td class="<cfoutput>#thisContentClass#</cfoutput>" colspan="2">
				<label for="blogEmail">Blog Email Address:</label>
			</td>
		   </tr>
		   <tr>
			<td class="<cfoutput>#thisContentClass#</cfoutput>" colspan="2">
				<input type="email" name="blogEmail" id="blogEmail" value="<cfoutput>#blogEmail#</cfoutput>" class="k-textbox" style="width: 95%" />
			</td>
		  </tr>
		<cfelse><!---<cfif session.isMobile>--->
		  <tr>
			<td align="right" class="<cfoutput>#thisContentClass#</cfoutput>" style="width: 20%"> 
				<label for="blogEmail">Blog Email Address:</label>
			</td>
			<td class="<cfoutput>#thisContentClass#</cfoutput>">
				<input type="email" name="blogEmail" id="blogEmail" value="<cfoutput>#blogEmail#</cfoutput>" class="k-textbox" style="width: 50%" />
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
		  <tr height="1px">
			  <td align="left" valign="top" colspan="2" class="<cfoutput>#thisContentClass#</cfoutput>"></td>
		  </tr>
		  <tr height="1px">
			  <td align="left" valign="top" colspan="2" class="<cfoutput>#thisContentClass#</cfoutput>">
			  	You may carbon copy all blog email to another email address. This field is optional.
			  </td>
		  </tr>
		<cfif session.isMobile>
		  <tr valign="middle">
			<td class="<cfoutput>#thisContentClass#</cfoutput>" colspan="2">
				<label for="ccEmailAddress">CC Email:</label>
			</td>
		   </tr>
		   <tr>
			<td class="<cfoutput>#thisContentClass#</cfoutput>" colspan="2">
				<input type="email" name="ccEmailAddress" id="ccEmailAddress" value="<cfoutput>#ccEmailAddress#</cfoutput>" class="k-textbox" style="width: 95%" />
			</td>
		  </tr>
		<cfelse><!---<cfif session.isMobile>--->
		  <tr>
			<td align="right" class="<cfoutput>#thisContentClass#</cfoutput>" style="width: 20%"> 
				<label for="mailPassword">CC Email Address:</label>
			</td>
			<td class="<cfoutput>#thisContentClass#</cfoutput>">
				<input type="email" name="ccEmailAddress" id="ccEmailAddress" value="<cfoutput>#ccEmailAddress#</cfoutput>" class="k-textbox" style="width: 50%" /> 
			</td>
		  </tr>
		</cfif>	 
			  
		  <!-- Border -->
		  <tr height="2px">
			<td align="left" valign="top" colspan="<cfoutput>#thisColSpan#</cfoutput>" class="<cfoutput>#thisContentClass#</cfoutput>"></td>
		  </tr>
		</table>
	</div>
			  
	<!---//***********************************************************************************************
						IP Block List
	//************************************************************************************************--->
	<button type="button" class="collapsible k-header">IP Block List</button>
	<div class="content k-content">
		<table align="center" class="k-content" width="100%" cellpadding="2" cellspacing="0">
		  <cfsilent>
			<!---The first content class in the table should be empty. --->
			<cfset thisContentClass = HtmlUtilsObj.getKendoClass('')>
			<!--- Set the colspan property for borders --->
			<cfset thisColSpan = "2">
		  </cfsilent>
				
		  <!-- Border -->
		  <tr height="2px">
			  <td align="left" valign="top" colspan="<cfoutput>#thisColSpan#</cfoutput>" class="<cfoutput>#thisContentClass#</cfoutput>"></td>
		  </tr>
		  <cfsilent>
		  <!--- Set the class for alternating rows. --->
		  <!---After the first row, the content class should be the current class. --->
		  <cfset thisContentClass = HtmlUtilsObj.getKendoClass(thisContentClass)>
		  </cfsilent>
		  <tr height="1px">
			  <td align="left" valign="top" colspan="2" class="<cfoutput>#thisContentClass#</cfoutput>"></td>
		  </tr>
		  <tr>
			<td colspan="2"> 
				You can block certain IP addresses from accessing this site by entering the IP address. This field is optional. 
			</td>
		  </tr>
		  <!-- Border -->
		  <tr height="2px">
			  <td align="left" valign="top" colspan="<cfoutput>#thisColSpan#</cfoutput>" class="<cfoutput>#thisContentClass#</cfoutput>"></td>
		  </tr>
		<cfif session.isMobile>
		  <tr valign="middle">
			<td class="<cfoutput>#thisContentClass#</cfoutput>" colspan="2">
				<label for="ipBlockList">IP Block List:</label>
			</td>
		   </tr>
		   <tr>
			<td class="<cfoutput>#thisContentClass#</cfoutput>" colspan="2">
				<input type="text" name="ipBlockList" id="ipBlockList" value="<cfoutput>#ipBlockList#</cfoutput>" class="k-textbox" style="width: 95%">
			</td>
		  </tr>
		<cfelse><!---<cfif session.isMobile>--->
		  <tr>
			<td align="right" class="<cfoutput>#thisContentClass#</cfoutput>" style="width: 20%"> 
				<label for="ipBlockList">IP Block List:</label>
			</td>
			<td class="<cfoutput>#thisContentClass#</cfoutput>">
				<input type="text" name="ipBlockList" id="ipBlockList" value="<cfoutput>#ipBlockList#</cfoutput>" class="k-textbox" style="width: 75%">
			</td>
		  </tr>
		</cfif>
		  <!-- Border -->
		  <tr height="2px" class="containerWidths">
			  <td align="left" valign="top" colspan="<cfoutput>#thisColSpan#</cfoutput>" class="<cfoutput>#thisContentClass#</cfoutput>"></td>
		  </tr>
			  
		</table>
	</div>
		
	<br/><br/>
	<button id="settingsSubmit" name="settingsSubmit" class="k-button k-primary" type="button">Submit</button> 