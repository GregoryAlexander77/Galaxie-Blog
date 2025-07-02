	<!---<cfdump var="#application.BlogOptionDbObj#">--->
			
	<!--- Blog options --->
	<cfset maxEntries = application.BlogOptionDbObj.getEntriesPerBlogPage()>
	<cfset commentModeration = application.BlogOptionDbObj.getBlogModerated()>
	<cfset UseCaptcha = application.BlogOptionDbObj.getUseCaptcha()>
	<cfset gravatarsAllowed = application.BlogOptionDbObj.getAllowGravatar()>
	<!--- Get the blog options from the Blog Option object --->
	<cfset blogOptionId = application.BlogOptionDbObj.getBlogOptionId()>
	<cfset jQueryCDNPath = application.BlogOptionDbObj.getJQueryCDNPath()>
	<cfset kendoCommercial = application.BlogOptionDbObj.getKendoCommercial()>
	<cfset kendoFolderPath = application.BlogOptionDbObj.getKendoFolderPath()>
	<cfset useSsl = application.BlogOptionDbObj.getUseSsl()>
	<cfset serverRewriteRuleInPlace = application.BlogOptionDbObj.getServerRewriteRuleInPlace()>
	<cfset deferScriptsAndCss = application.BlogOptionDbObj.getDeferScriptsAndCss()>
	<cfset minimizeCode = application.BlogOptionDbObj.getMinimizeCode()>
	<cfset disableCache = application.BlogOptionDbObj.getDisableCache()>
	<cfset includeGsap = application.BlogOptionDbObj.getIncludeGsap()>
	<cfset includeDisqus = application.BlogOptionDbObj.getIncludeDisqus()>
	<cfset defaultMediaPlayer = application.BlogOptionDbObj.getDefaultMediaPlayer()>
	<cfset backgroundImageResolution = application.BlogOptionDbObj.getBackgroundImageResolution()>
	<cfset googleAnalyticsString = application.BlogOptionDbObj.getGoogleAnalyticsString()>
	<cfset addThisApiKey = application.BlogOptionDbObj.getAddThisApiKey()>
	<cfset addThisToolboxString = application.BlogOptionDbObj.getAddThisToolboxString()>
	<!--- Note: the API for Disqus changed recently, now we only need the blog identifier and the API Key. I am keeping the secret field for potential future use --->
	<cfset disqusBlogIdentifier = application.BlogOptionDbObj.getDisqusBlogIdentifier()>
	<cfset disqusApiKey = application.BlogOptionDbObj.getDisqusApiKey()>
	<cfset disqusApiSecret = application.BlogOptionDbObj.getDisqusApiSecret()>
	<!--- The following 3 Disqus vars are no longer needed. --->
	<cfset disqusAuthTokenKey = application.BlogOptionDbObj.getDisqusAuthTokenKey()>
	<cfset disqusAuthUrl = application.BlogOptionDbObj.getDisqusAuthUrl()>
	<cfset disqusAuthTokenUrl = application.BlogOptionDbObj.getDisqusAuthTokenUrl()>
	<cfset azureMapsApiKey = application.BlogOptionDbObj.getAzureMapsApiKey()>
	<cfset bingMapsApiKey = application.BlogOptionDbObj.getBingMapsApiKey()>
	<cfset facebookAppId = application.BlogOptionDbObj.getFacebookAppId()>
	<cfset twitterAppId = application.BlogOptionDbObj.getTwitterAppId()>
		
	<!--- The azureMapsApiKey is a new variable and it may be null. --->
	<cfif !isDefined("azureMapsApiKey")>
		<cfset azureMapsApiKey = "">
	</cfif>
		
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
		
		// Numeric inputs
		$("#entriesPerBlogPage").kendoNumericTextBox({
			decimals: 0,
			format: "#",
			round: true
		});
		
		// !!! Note on the validators, all forms need a name attribute, otherwise the positioning of the messages will not work. --->
		$(document).ready(function() {

			var optionsValidator = $("#optionsForm").kendoValidator({
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
			var optionsSubmit = $('#optionsSubmit');
			optionsSubmit.on('click', function(e){ 
				
				e.preventDefault();         
				if (optionsValidator.validate()) {
					
					// Open up a please wait dialog
					$.when(kendo.ui.ExtWaitDialog.show({ title: "Please wait...", message: "Please wait while we save the data.", width: "<cfoutput>#application.kendoExtendedUiWindowWidth#</cfoutput>", icon: "k-ext-information" }));

					// Send data to server
					setTimeout(function() {
						postOptions();
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
		function postOptions(){

			jQuery.ajax({
				type: 'post', 
				url: '<cfoutput>#application.baseUrl#</cfoutput>/common/cfc/ProxyController.cfc?method=saveBlogOptions&csrfToken=<cfoutput>#csrfToken#</cfoutput>',
				// Serialize the form. The csrfToken is in the form.
				data: $('#optionsForm').serialize(),
				dataType: "json",
				success: postOptionsResult, // calls the result function.
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

		function postOptionsResult(response){
			// Close the wait window that was launched in the calling function.
			kendo.ui.ExtWaitDialog.hide();
			// Close this window.
			$('#optionsWindow').kendoWindow('destroy');
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
		
	<form id="optionsForm" action="#" method="post" data-role="validator">
	<!---<input type="hidden" name="csrfToken" id="csrfToken" value="<cfoutput>#csrfToken#</cfoutput>">--->
	<input type="hidden" name="blogOptionId" id="blogOptionId" value="<cfoutput>#blogOptionId#</cfoutput>">
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
			These Blog Options can be changed at any time. However, there may be required bits of data that are required, for example- such as obtaining and entering a Disqus key. There are a number of options here, but if you just want to get up and running as soon as possible we recommend:
			<ol>
				<li>Install a SSL certificate on your server and check the use SSL checkbox</li>
				<li>If you have a server re-write rule in place on the server to remove the index.cfm, check the server rewrite rule checkbox to make your links more concise</li>
				<!--- <li>Obtaining an AddThis Key and using the AddThis sharing library</li> --->
				<li>Obtaining a Azure Maps API Key in order to embed maps into your posts</li>
				<li>Leaving the other default settings as they are unless you really want to use the Disqus commenting system or the Greensock animation library. </li>
			</ol>
		</td>
	  </tr>
	  <tr height="1px">
		  <td align="left" valign="top" colspan="2" class="border <cfoutput>#thisContentClass#</cfoutput>"></td>
	  </tr>
	  <!-- Form content -->
	  <tr valign="middle" height="30px">
		<td valign="bottom" align="left" class="<cfoutput>#thisContentClass#</cfoutput>" colspan="<cfoutput>#thisColSpan#</cfoutput>">
			If possible, you should always try to use SSL. However, this does require a certificate on the server and the site can be used without a SSL certificate. Be aware that your SEO score will suffer without SSL, and you may not be able to use any of the third party libraries that come with the blog, such as Bing maps or Disqus. Your security my also be impacted negatively.
		</td>
	  </tr>
	  <tr height="1px">
		  <td align="left" valign="top" colspan="2" class="border <cfoutput>#thisContentClass#</cfoutput>"></td>
	  </tr>
	  <tr valign="middle" height="30px">
		<td align="right" class="<cfoutput>#thisContentClass#</cfoutput>" style="width:<cfif session.isMobile>60<cfelse>20</cfif>%">Use SSL:</td>
		<td align="left" class="<cfoutput>#thisContentClass#</cfoutput>" style="width:<cfif session.isMobile>40<cfelse>80</cfif>%">
			<input type="checkbox" id="useSsl" name="useSsl" value="1" <cfif useSsl>checked</cfif>>
		</td>
	  </tr>
	  <cfsilent>
	  <!--- Set the class for alternating rows. --->
	  <!---After the first row, the content class should be the current class. --->
	  <cfset thisContentClass = HtmlUtilsObj.getKendoClass(thisContentClass)>
	  </cfsilent>
	  <tr height="2px">
		  <td align="left" valign="top" colspan="2" class="border <cfoutput>#thisContentClass#</cfoutput>"></td>
	  </tr>
	  <!-- Rewrite rule -->
	  <tr valign="middle" height="30px">
		<td valign="bottom" align="left" class="<cfoutput>#thisContentClass#</cfoutput>" colspan="<cfoutput>#thisColSpan#</cfoutput>">
			A 'Server Rewrite Rule' essentially removes the index.cfm from all of your public pages and makes it easier for the search engines to digest the content in a SEO friendly way. The server re-write rules are placed on the server. You may have to get your server or hosting administrator involved to get it working on the server. If you have a server rewite rule on the server, and you're sure that it works, check the box below so that Galaxie Blog can generate the proper links. Be sure that your server side rewrite rules work before checking this box as you may not be able to get bck into this site unless you have direct access to the database to disable this setting once it is checked.
		</td>
	  </tr>
	  <tr height="1px">
		  <td align="left" valign="top" colspan="2" class="border <cfoutput>#thisContentClass#</cfoutput>"></td>
	  </tr>
	  <tr valign="middle" height="30px">
		<td align="right" class="<cfoutput>#thisContentClass#</cfoutput>">Server Rewrite Rule in place?</td>
		<td align="left" class="<cfoutput>#thisContentClass#</cfoutput>">
			<input type="checkbox" name="serverRewriteRuleInPlace" id="serverRewriteRuleInPlace" value="1" <cfif serverRewriteRuleInPlace>checked</cfif>>
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
	  <!-- Defer scripts -->
	  <tr valign="middle" height="30px">
		<td valign="bottom" align="left" class="<cfoutput>#thisContentClass#</cfoutput>" colspan="<cfoutput>#thisColSpan#</cfoutput>">
			Deferring the loading of non-essential scripts speeds up the loading of the site making the initial site to load faster. It is highly recommened to keep this setting unless you absolutely need all of the scripts to load before rendering the page.
		</td>
	  </tr>
	  <tr height="1px">
		  <td align="left" valign="top" colspan="2" class="border <cfoutput>#thisContentClass#</cfoutput>"></td>
	  </tr>
	  <tr valign="middle" height="30px">
		<td align="right" class="<cfoutput>#thisContentClass#</cfoutput>">Defer non-essential scripts?</td>
		<td align="left" class="<cfoutput>#thisContentClass#</cfoutput>">
			<input type="checkbox" name="deferScriptsAndCss" id="deferScriptsAndCss" value="1" <cfif deferScriptsAndCss>checked</cfif>>
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
	  <!-- Minimize c-->
	  <tr valign="middle" height="30px">
		<td valign="bottom" align="left" class="<cfoutput>#thisContentClass#</cfoutput>" colspan="<cfoutput>#thisColSpan#</cfoutput>">
			Galaxie Blog has logic to minimize the various Javascript and CSS in order to load the page quicker. This setting should be checked when you are in a production environment to improve page performance. You may want to turn this off if you are trying to debug code as the code is much easier to read when it is not compressed.
		</td>
	  </tr>
	  <tr height="1px">
		  <td align="left" valign="top" colspan="2" class="border <cfoutput>#thisContentClass#</cfoutput>"></td>
	  </tr>
	  <tr valign="middle" height="30px">
		<td align="right" class="<cfoutput>#thisContentClass#</cfoutput>">Minimize Code?</td>
		<td align="left" class="<cfoutput>#thisContentClass#</cfoutput>">
			<input type="checkbox" name="minimizeCode" id="minimizeCode" value="1" <cfif minimizeCode>checked</cfif>>
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
	  <!-- Caching -->
	  <tr valign="middle" height="30px">
		<td valign="bottom" align="left" class="<cfoutput>#thisContentClass#</cfoutput>" colspan="<cfoutput>#thisColSpan#</cfoutput>">
			Galaxie Blog's caching features enhances performance and should <b>be enabled in production environments</b>. However, you will want to disable caching until you are <b>completely</b> finished setting up your site. This option should be checked when you need to immediately see your changes reflected on the front end after making site changes or writing new code. 
		</td>
	  </tr>
	  <tr height="1px">
		  <td align="left" valign="top" colspan="2" class="border <cfoutput>#thisContentClass#</cfoutput>"></td>
	  </tr>
	  <tr valign="middle" height="30px">
		<td align="right" class="<cfoutput>#thisContentClass#</cfoutput>">Disable Cache?</td>
		<td align="left" class="<cfoutput>#thisContentClass#</cfoutput>">
			<input type="checkbox" name="disableCache" id="disableCache" value="1" <cfif disableCache>checked</cfif>>
		</td>
	  </tr>  
	  <!-- Border -->
	  <tr height="2px">
		  <td align="left" valign="top" colspan="<cfoutput>#thisColSpan#</cfoutput>" class="<cfoutput>#thisContentClass#</cfoutput>"></td>
	  </tr>
	  
	</table>
	<br/>
		
	<!---//***********************************************************************************************
						Jquery and Kendo UI
	//************************************************************************************************--->
	<button type="button" class="collapsible k-header">Jquery Location and Kendo UI</button>
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
			  	It is generally recommended to use the google JQuery CDN. You should only change this if you want to change the JQuery version or if you want to host JQuery on your own server.
			  </td>
		  </tr>
		  <!-- Border -->
		  <tr height="2px">
			  <td align="left" valign="top" colspan="<cfoutput>#thisColSpan#</cfoutput>" class="<cfoutput>#thisContentClass#</cfoutput>"></td>
		  </tr>
		  <tr>
		<cfif session.isMobile>
		  <tr valign="middle">
			<td class="<cfoutput>#thisContentClass#</cfoutput>" colspan="2">
				<label for="jQueryCDNPath">JQuery CDN Location:</label>
			</td>
		   </tr>
		   <tr>
			<td class="<cfoutput>#thisContentClass#</cfoutput>" colspan="2">
				<input id="jQueryCDNPath" name="jQueryCDNPath" type="text" value="<cfoutput>#jQueryCDNPath#</cfoutput>" class="k-textbox" style="width: 95%" />    
			</td>
		  </tr>
		<cfelse><!---<cfif session.isMobile>--->
			<td align="right" class="<cfoutput>#thisContentClass#</cfoutput>" style="width: 25%"> 
				<label for="jQueryCDNPath">JQuery CDN Location:</label>
			</td>
			<td class="<cfoutput>#thisContentClass#</cfoutput>">
				<input id="jQueryCDNPath" name="jQueryCDNPath" type="text" value="<cfoutput>#jQueryCDNPath#</cfoutput>" class="k-textbox" style="width: 50%" />    
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
		  <tr valign="middle" height="30px">
			<td valign="bottom" align="left" class="<cfoutput>#thisContentClass#</cfoutput>" colspan="<cfoutput>#thisColSpan#</cfoutput>">
				There are two Kendo UI libraries available: the open sourced version: and the Proffesional Edition which requires a license. This blog is fully functional using the open source free edition. Please check the box if you are using your own license for the commercial edition. If you change this setting, make sure to enter the path to the Kendo folder location that you're using below. 
			</td>
		  </tr>
		  <tr height="1px">
			  <td align="left" valign="top" colspan="2" class="border <cfoutput>#thisContentClass#</cfoutput>"></td>
		  </tr>
		<cfif session.isMobile>
		  <tr valign="middle">
			<td class="<cfoutput>#thisContentClass#</cfoutput>" colspan="2">
				<label for="kendoCommercial">Commercial Kendo UI Edition?</label>
			</td>
		   </tr>
		   <tr>
			<td class="<cfoutput>#thisContentClass#</cfoutput>" colspan="2">
				<input type="checkbox" name="kendoCommercial" id="kendoCommercial" <cfif kendoCommercial>checked</cfif>>
			</td>
		  </tr>
		<cfelse><!---<cfif session.isMobile>--->
		  <tr valign="middle" height="30px">
			<td valign="bottom" align="right" class="<cfoutput>#thisContentClass#</cfoutput>" style="width:20%">
				<label for="kendoCommercial">Commercial Kendo UI Edition?</label>
			</td>
			<td valign="bottom" align="left" class="<cfoutput>#thisContentClass#</cfoutput>" style="width:80%">
				<input type="checkbox" name="kendoCommercial" id="kendoCommercial" <cfif kendoCommercial>checked</cfif>>
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
		  <tr valign="middle" height="30px">
			<td valign="bottom" align="left" class="<cfoutput>#thisContentClass#</cfoutput>" colspan="<cfoutput>#thisColSpan#</cfoutput>">
				Only change this setting if you plan on moving the Kendo Core folder or if you use your own personal Kendo UI Professional license.<br/>
				Note: we have tested the blog using Kendo UI v2019.2.619, using a later version may require changes to the menu related code due to the different CSS rules.
			</td>
		  </tr>
		  <tr height="1px">
			  <td align="left" valign="top" colspan="2" class="border <cfoutput>#thisContentClass#</cfoutput>"></td>
		  </tr>
		<cfif session.isMobile>
		  <tr valign="middle">
			<td class="<cfoutput>#thisContentClass#</cfoutput>" colspan="2">
				<label for="kendoFolderPath">Kendo Folder Path:</label>
			</td>
		   </tr>
		   <tr>
			<td class="<cfoutput>#thisContentClass#</cfoutput>" colspan="2">
				<input type="text" name="kendoFolderPath" id="kendoFolderPath" value="<cfoutput>#kendoFolderPath#</cfoutput>" class="k-textbox" style="width: 95%" required />
			</td>
		  </tr>
		<cfelse><!---<cfif session.isMobile>--->
		  <tr valign="middle" height="30px">
			<td valign="center" align="right" class="<cfoutput>#thisContentClass#</cfoutput>">
				<label for="kendoFolderPath">Kendo Folder Path:</label>
			</td>
			<td valign="bottom" align="left" class="<cfoutput>#thisContentClass#</cfoutput>">
				<input type="text" name="kendoFolderPath" id="kendoFolderPath" value="<cfoutput>#kendoFolderPath#</cfoutput>" class="k-textbox" style="width: 50%" required />
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
						Google Analytics GTAG String
	//************************************************************************************************--->
	<button type="button" class="collapsible k-header">Google Analytics</button>
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
				<p>Google Analytics may be incorporated to determine your page traffic trends. To use Google Analytics, you must first obtain a free Google GTAG string, see <a href="https://developers.google.com/tag-platform/gtagjs/install">https://developers.google.com/tag-platform/gtagjs/install</a> for more information.</p>
				
				<p>To use Google Analytics, enter in the GTAG strings below (ie G-XXXXXX). If you have more than one GTAG string, separate them with comma's. You can enter as many GTAG strings below as you need. You don't need to do anything else other than to enter in your GTAG string(s), if a string is found, Galaxie Blog will configure Google Analytics for you.</p>
			</td>
		  </tr>
		  <!-- Border -->
		  <tr height="2px">
			  <td align="left" valign="top" colspan="<cfoutput>#thisColSpan#</cfoutput>" class="<cfoutput>#thisContentClass#</cfoutput>"></td>
		  </tr>
		<cfif session.isMobile>
		  <tr valign="middle">
			<td class="<cfoutput>#thisContentClass#</cfoutput>" colspan="2">
				<label for="googleAnalyticsString">Google GTAG String(s):</label>
			</td>
		   </tr>
		   <tr>
			<td class="<cfoutput>#thisContentClass#</cfoutput>" colspan="2">
				<input type="text" name="googleAnalyticsString" id="googleAnalyticsString" value="<cfoutput>#googleAnalyticsString#</cfoutput>" class="k-textbox" style="width: 50%" />
			</td>
		  </tr>
		<cfelse><!---<cfif session.isMobile>--->
		  <tr>
			<td align="right" class="<cfoutput>#thisContentClass#</cfoutput>" style="width: 20%"> 
				<label for="googleAnalyticsString">Google GTAG String(s):</label>
			</td>
			<td class="<cfoutput>#thisContentClass#</cfoutput>">
				<input type="text" name="googleAnalyticsString" id="googleAnalyticsString" value="<cfoutput>#googleAnalyticsString#</cfoutput>" class="k-textbox" style="width: 50%" />
			</td>
		  </tr>
		</cfif>
		  <!-- Border -->
		  <tr height="2px" class="containerWidths">
			  <td align="left" valign="top" colspan="<cfoutput>#thisColSpan#</cfoutput>" class="<cfoutput>#thisContentClass#</cfoutput>"></td>
		  </tr>
			  
		  <!-- Border -->
		  <tr height="2px">
			<td align="left" valign="top" colspan="<cfoutput>#thisColSpan#</cfoutput>" class="<cfoutput>#thisContentClass#</cfoutput>"></td>
		  </tr>
		</table>
	</div>
		
	<cfif 1 eq 2>
		<!---//***********************************************************************************************
							Add This (depracated as of March 2023)
		//************************************************************************************************--->

		<button type="button" class="collapsible k-header">Add This Library</button>
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
					AddThis is the library that the blog uses to allow others to share your posts to various social sites such as Facebook. AddThis is a free library, however, you must enter your own personal AddThis key. Once you enter in an AddThis API key, Galaxie will replace its built in commenting system with AddThis. Go to <a href="https://www.addthis.com/login?next=/dashboard">https://www.addthis.com/login?next=/dashboard</a> for more information and to sign up for a free API key.
				  </td>
			  </tr>
			  <!-- Border -->
			  <tr height="2px">
				  <td align="left" valign="top" colspan="<cfoutput>#thisColSpan#</cfoutput>" class="<cfoutput>#thisContentClass#</cfoutput>"></td>
			  </tr>
			<cfif session.isMobile>
			  <tr valign="middle">
				<td class="<cfoutput>#thisContentClass#</cfoutput>" colspan="2">
					<label for="addThisApiKey">AddThis API Key:</label>
				</td>
			   </tr>
			   <tr>
				<td class="<cfoutput>#thisContentClass#</cfoutput>" colspan="2">
					<input type="text" name="addThisApiKey" id="addThisApiKey" value="<cfoutput>#addThisApiKey#</cfoutput>" class="k-textbox" style="width: 95%" />
				</td>
			  </tr>
			<cfelse><!---<cfif session.isMobile>--->
			  <tr>
				<td align="right" class="<cfoutput>#thisContentClass#</cfoutput>" style="width: 20%"> 
					<label for="addThisApiKey">AddThis API Key:</label>
				</td>
				<td class="<cfoutput>#thisContentClass#</cfoutput>">
					<input type="text" name="addThisApiKey" id="addThisApiKey" value="<cfoutput>#addThisApiKey#</cfoutput>" class="k-textbox" style="width: 50%" />
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
					The AddThis Toolbox string is a string that AddThis provides to render the proper code. Type in the string exactly as it is given on the AddThis site when signing up for an API Key.
				  </td>
			  </tr>
			  <!-- Border -->
			  <tr height="2px">
				  <td align="left" valign="top" colspan="<cfoutput>#thisColSpan#</cfoutput>" class="<cfoutput>#thisContentClass#</cfoutput>"></td>
			  </tr>
			<cfif session.isMobile>
			  <tr valign="middle">
				<td class="<cfoutput>#thisContentClass#</cfoutput>" colspan="2">
					<label for="addThisToolboxString">AddThis toolbox string:</label>
				</td>
			   </tr>
			   <tr>
				<td class="<cfoutput>#thisContentClass#</cfoutput>" colspan="2">
					<input type="text" name="addThisToolboxString" id="addThisToolboxString" value="<cfoutput>#addThisToolboxString#</cfoutput>" class="k-textbox" style="width: 95%" /> 
				</td>
			  </tr>
			<cfelse><!---<cfif session.isMobile>--->
			  <tr>
				<td align="right" class="<cfoutput>#thisContentClass#</cfoutput>" style="width: 20%"> 
					<label for="addThisToolboxString">AddThis toolbox string:</label>
				</td>
				<td class="<cfoutput>#thisContentClass#</cfoutput>">
					<input type="text" name="addThisToolboxString" id="addThisToolboxString" value="<cfoutput>#addThisToolboxString#</cfoutput>" class="k-textbox" style="width: 50%" /> 
				</td>
			  </tr>
			</cfif>	  
			  <!-- Border -->
			  <tr height="2px">
				<td align="left" valign="top" colspan="<cfoutput>#thisColSpan#</cfoutput>" class="<cfoutput>#thisContentClass#</cfoutput>"></td>
			  </tr>
			</table>
		</div>
	</cfif>
					
	<!---//***********************************************************************************************
						Azure Maps
	//************************************************************************************************--->
	<button type="button" class="collapsible k-header">Azure Maps Library</button>
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
			  	Galaxie Blog has the ability to generate static maps and map routes using the Azure Maps API. To generate a static or route, create or edit a post and click on the <b>Enclosure Editor</b> button. This will bring up an editor and it will allow you to easilly generate both static and map routes using a wysiwyg interface.  You may also embed maps within any post. You will need to sign up for an Azure maps API key to add this functionality. With moderate usage, this key is free, however, you should check the Azure Maps site for pricing information.
			  </td>
		  </tr>
		  <!-- Border -->
		  <tr height="2px">
			  <td align="left" valign="top" colspan="<cfoutput>#thisColSpan#</cfoutput>" class="<cfoutput>#thisContentClass#</cfoutput>"></td>
		  </tr>
		<cfif session.isMobile>
		  <tr valign="middle">
			<td class="<cfoutput>#thisContentClass#</cfoutput>" colspan="2">
				<label for="azureMapsApiKey">Azure Maps API Key:</label>
			</td>
		   </tr>
		   <tr>
			<td class="<cfoutput>#thisContentClass#</cfoutput>" colspan="2">
				<input type="text" name="azureMapsApiKey" id="azureMapsApiKey" value="<cfoutput>#azureMapsApiKey#</cfoutput>" class="k-textbox" style="width: 95%" />
			</td>
		  </tr>
		<cfelse><!---<cfif session.isMobile>--->
		  <tr>
			<td align="right" class="<cfoutput>#thisContentClass#</cfoutput>" style="width: 20%"> 
				<label for="bingMapsApiKey">Azure Maps API Key:</label>
			</td>
			<td class="<cfoutput>#thisContentClass#</cfoutput>">
				<input type="text" name="azureMapsApiKey" id="azureMapsApiKey" value="<cfoutput>#azureMapsApiKey#</cfoutput>" class="k-textbox" style="width: 50%" />
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
						Bing Maps
	//************************************************************************************************--->
	<button type="button" class="collapsible k-header">Bing Maps Library</button>
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
			  	Bing Maps will retire for free user accounts on June 30th 2025. If you have an enterprise account, Bing Maps for entrerprise clients can still be used until June 30th 2028. If you're looking for map capabililties and you're not an enterprise customer, create an Azure Maps account and enter your key in the Azure Maps field above.
			  </td>
		  </tr>
		  <!-- Border -->
		  <tr height="2px">
			  <td align="left" valign="top" colspan="<cfoutput>#thisColSpan#</cfoutput>" class="<cfoutput>#thisContentClass#</cfoutput>"></td>
		  </tr>
		<cfif session.isMobile>
		  <tr valign="middle">
			<td class="<cfoutput>#thisContentClass#</cfoutput>" colspan="2">
				<label for="bingMapsApiKey">Bing Maps API Key:</label>
			</td>
		   </tr>
		   <tr>
			<td class="<cfoutput>#thisContentClass#</cfoutput>" colspan="2">
				<input type="text" name="bingMapsApiKey" id="bingMapsApiKey" value="<cfoutput>#bingMapsApiKey#</cfoutput>" class="k-textbox" style="width: 95%" />
			</td>
		  </tr>
		<cfelse><!---<cfif session.isMobile>--->
		  <tr>
			<td align="right" class="<cfoutput>#thisContentClass#</cfoutput>" style="width: 20%"> 
				<label for="bingMapsApiKey">Bing Maps API Key:</label>
			</td>
			<td class="<cfoutput>#thisContentClass#</cfoutput>">
				<input type="text" name="bingMapsApiKey" id="bingMapsApiKey" value="<cfoutput>#bingMapsApiKey#</cfoutput>" class="k-textbox" style="width: 50%" />
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
						Disqus
	//************************************************************************************************--->
	<button type="button" class="collapsible k-header">Disqus Libary</button>
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
			  	Disqus is an optional library that you can use to allow users to interact with your site and add comments. Disqus is fully integrated into Galaxie Blog and it only needs a few free keys provided by Disqus. There are some advantages and disadvantages to consider when using Disqus. It offers numerous tools to analyze your users and can cut down on spam significantly, however, it also requires the users to log into their own social media account to interact with your site. This may limit the number of comments that you receive on your site. It also requies loading additional external libraries that may cause a small performance hit if you choose to use it. Please see the Disqus site at <a href="https://disqus.com/">https://disqus.com/</a> for more information.
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
				<label for="includeDisqus">Include Disqus:</label>
			</td>
		   </tr>
		   <tr>
			<td class="<cfoutput>#thisContentClass#</cfoutput>" colspan="2">
				<input type="checkbox" name="includeDisqus" id="includeDisqus" value="1" <cfif includeDisqus>checked</cfif> />
			</td>
		  </tr>
		<cfelse><!---<cfif session.isMobile>--->
		  <tr>
			<td align="right" class="<cfoutput>#thisContentClass#</cfoutput>" style="width: 20%"> 
				<label for="includeDisqus">Include Disqus:</label>
			</td>
			<td class="<cfoutput>#thisContentClass#</cfoutput>">
				<input type="checkbox" name="includeDisqus" id="includeDisqus" value="1" <cfif includeDisqus>checked</cfif> />
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
				<label for="disqusBlogIdentifier">Disqus Blog Identifier:</label>
			</td>
		   </tr>
		   <tr>
			<td class="<cfoutput>#thisContentClass#</cfoutput>" colspan="2">
				<input type="text" name="disqusBlogIdentifier" id="disqusBlogIdentifier" value="<cfoutput>#disqusBlogIdentifier#</cfoutput>" class="k-textbox" style="width: 95%" />
			</td>
		  </tr>
		<cfelse><!---<cfif session.isMobile>--->
		  <tr>
			<td align="right" class="<cfoutput>#thisContentClass#</cfoutput>" style="width: 20%"> 
				<label for="disqusBlogIdentifier">Disqus Blog Identifier:</label>
			</td>
			<td class="<cfoutput>#thisContentClass#</cfoutput>">
				<input type="text" name="disqusBlogIdentifier" id="disqusBlogIdentifier" value="<cfoutput>#disqusBlogIdentifier#</cfoutput>" class="k-textbox" style="width: 50%" />
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
				<label for="disqusApiKey">Disqus API Key:</label>
			</td>
		   </tr>
		   <tr>
			<td class="<cfoutput>#thisContentClass#</cfoutput>" colspan="2">
				<input type="text" name="disqusApiKey" id="disqusApiKey" value="<cfoutput>#disqusApiKey#</cfoutput>" class="k-textbox" style="width: 95%" /> 
			</td>
		  </tr>
		<cfelse><!---<cfif session.isMobile>--->
		  <tr>
			<td align="right" class="<cfoutput>#thisContentClass#</cfoutput>" style="width: 20%"> 
				<label for="disqusApiKey">Disqus API Key:</label>
			</td>
			<td class="<cfoutput>#thisContentClass#</cfoutput>">
				<input type="text" name="disqusApiKey" id="disqusApiKey" value="<cfoutput>#disqusApiKey#</cfoutput>" class="k-textbox" style="width: 50%" /> 
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
				<label for="disqusApiSecret">Disqus API Secret:</label>
			</td>
		   </tr>
		   <tr>
			<td class="<cfoutput>#thisContentClass#</cfoutput>" colspan="2">
				<input type="text" name="disqusApiSecret" id="disqusApiSecret" value="<cfoutput>#disqusApiSecret#</cfoutput>" class="k-textbox" style="width: 95%" />
			</td>
		  </tr>
		<cfelse><!---<cfif session.isMobile>--->
		  <tr>
			<td align="right" class="<cfoutput>#thisContentClass#</cfoutput>" style="width: 20%"> 
				<label for="disqusApiSecret">Disqus API Secret:</label>
			</td>
			<td class="<cfoutput>#thisContentClass#</cfoutput>">
				<input type="text" name="disqusApiSecret" id="disqusApiSecret" value="<cfoutput>#disqusApiSecret#</cfoutput>" class="k-textbox" style="width: 50%" />
			</td>
		  </tr>
		</cfif>	
		<!--- The following fields are no longer needed (as of 2021) --->
		<!--- Start depracted disqus fields
		  <tr height="2px">
			  <td align="left" valign="top" colspan="<cfoutput>#thisColSpan#</cfoutput>" class="<cfoutput>#thisContentClass#</cfoutput>"></td>
		  </tr>
		  <cfsilent>
		  <cfset thisContentClass = HtmlUtilsObj.getKendoClass(thisContentClass)>
		  </cfsilent>
		<cfif session.isMobile>
		  <tr valign="middle">
			<td class="<cfoutput>#thisContentClass#</cfoutput>" colspan="2">
				<label for="disqusAuthTokenKey">Disqus Auth Token Key:</label>
			</td>
		   </tr>
		   <tr>
			<td class="<cfoutput>#thisContentClass#</cfoutput>" colspan="2">
				<input type="text" name="disqusAuthTokenKey" id="disqusAuthTokenKey" value="<cfoutput>#disqusAuthTokenKey#</cfoutput>" class="k-textbox" style="width: 95%" />
			</td>
		  </tr>
		<cfelse>
		  <tr>
			<td align="right" class="<cfoutput>#thisContentClass#</cfoutput>" style="width: 20%"> 
				<label for="disqusAuthTokenKey">Disqus Auth Token Key:</label>
			</td>
			<td class="<cfoutput>#thisContentClass#</cfoutput>">
				<input type="text" name="disqusAuthTokenKey" id="disqusAuthTokenKey" value="<cfoutput>#disqusAuthTokenKey#</cfoutput>" class="k-textbox" style="width: 50%" />
			</td>
		  </tr>
		</cfif>	  
		  <tr height="2px">
			  <td align="left" valign="top" colspan="<cfoutput>#thisColSpan#</cfoutput>" class="<cfoutput>#thisContentClass#</cfoutput>"></td>
		  </tr>
		  <cfsilent>
		  <cfset thisContentClass = HtmlUtilsObj.getKendoClass(thisContentClass)>
		  </cfsilent>
		<cfif session.isMobile>
		  <tr valign="middle">
			<td class="<cfoutput>#thisContentClass#</cfoutput>" colspan="2">
				<label for="disqusAuthUrl">Disqus Auth URL:</label>
			</td>
		   </tr>
		   <tr>
			<td class="<cfoutput>#thisContentClass#</cfoutput>" colspan="2">
				<input type="text" name="disqusAuthUrl" id="disqusAuthUrl" value="<cfoutput>#disqusAuthUrl#</cfoutput>" class="k-textbox" style="width: 95%" />
			</td>
		  </tr>
		<cfelse>
		  <tr>
			<td align="right" class="<cfoutput>#thisContentClass#</cfoutput>" style="width: 20%"> 
				<label for="disqusAuthUrl">Disqus Auth URL:</label>
			</td>
			<td class="<cfoutput>#thisContentClass#</cfoutput>">
				<input type="text" name="disqusAuthUrl" id="disqusAuthUrl" value="<cfoutput>#disqusAuthUrl#</cfoutput>" class="k-textbox" style="width: 50%" />
			</td>
		  </tr>
		</cfif>	  
		  <tr height="2px">
			  <td align="left" valign="top" colspan="<cfoutput>#thisColSpan#</cfoutput>" class="<cfoutput>#thisContentClass#</cfoutput>"></td>
		  </tr>
		  <cfsilent>
		  <cfset thisContentClass = HtmlUtilsObj.getKendoClass(thisContentClass)>
		  </cfsilent>
		<cfif session.isMobile>
		  <tr valign="middle">
			<td class="<cfoutput>#thisContentClass#</cfoutput>" colspan="2">
				<label for="disqusAuthTokenUrl">Disqus Auth Token URL:</label>
			</td>
		   </tr>
		   <tr>
			<td class="<cfoutput>#thisContentClass#</cfoutput>" colspan="2">
				<input type="text" name="disqusAuthTokenUrl" id="disqusAuthTokenUrl" value="<cfoutput>#disqusAuthTokenUrl#</cfoutput>" class="k-textbox" style="width: 95%" />
			</td>
		  </tr>
		<cfelse>
		  <tr>
			<td align="right" class="<cfoutput>#thisContentClass#</cfoutput>" style="width: 20%"> 
				<label for="disqusAuthTokenUrl">Disqus Auth Token URL:</label>
			</td>
			<td class="<cfoutput>#thisContentClass#</cfoutput>">
				<input type="text" name="disqusAuthTokenUrl" id="disqusAuthTokenUrl" value="<cfoutput>#disqusAuthTokenUrl#</cfoutput>" class="k-textbox" style="width: 50%" />
			</td>
		  </tr>
		</cfif>	
		End depracated disqus fields
		--->
		  <!-- Border -->
		  <tr height="2px">
			<td align="left" valign="top" colspan="<cfoutput>#thisColSpan#</cfoutput>" class="<cfoutput>#thisContentClass#</cfoutput>"></td>
		  </tr>
		</table>
	</div>
			  
	<!---//***********************************************************************************************
						Greensock
	//************************************************************************************************--->
	<button type="button" class="collapsible k-header">Greensock Animation Library</button>
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
				<p>Greensock is a popular animation library that you can use in your blog posts. Including this library does not require a dedicated license, and it is open source, however, it requires advanced Javascript skills and should not be loaded unless you intend to use it. For more information see <a href="https://www.greensock.com">https://greensock.com/gsap/</a></p>
			</td>
		  </tr>
		  <!-- Border -->
		  <tr height="2px">
			  <td align="left" valign="top" colspan="<cfoutput>#thisColSpan#</cfoutput>" class="<cfoutput>#thisContentClass#</cfoutput>"></td>
		  </tr>
		<cfif session.isMobile>
		  <tr valign="middle">
			<td class="<cfoutput>#thisContentClass#</cfoutput>" colspan="2">
				<label for="includeGsap">Include GSAP:</label>
			</td>
		   </tr>
		   <tr>
			<td class="<cfoutput>#thisContentClass#</cfoutput>" colspan="2">
				<input type="checkbox" name="includeGsap" id="includeGsap" value="1" <cfif includeGsap>checked</cfif>>
			</td>
		  </tr>
		<cfelse><!---<cfif session.isMobile>--->
		  <tr>
			<td align="right" class="<cfoutput>#thisContentClass#</cfoutput>" style="width: 20%"> 
				<label for="includeGsap">Include GSAP:</label>
			</td>
			<td class="<cfoutput>#thisContentClass#</cfoutput>">
				<input type="checkbox" name="includeGsap" id="includeGsap" value="1" <cfif includeGsap>checked</cfif>>
			</td>
		  </tr>
		</cfif>
		  <!-- Border -->
		  <tr height="2px" class="containerWidths">
			  <td align="left" valign="top" colspan="<cfoutput>#thisColSpan#</cfoutput>" class="<cfoutput>#thisContentClass#</cfoutput>"></td>
		  </tr>
			  
		  <!-- Border -->
		  <tr height="2px">
			<td align="left" valign="top" colspan="<cfoutput>#thisColSpan#</cfoutput>" class="<cfoutput>#thisContentClass#</cfoutput>"></td>
		  </tr>
		</table>
	</div>
		
	<br/><br/>
	<button id="optionsSubmit" name="optionsSubmit" class="k-button k-primary" type="button">Submit</button> 