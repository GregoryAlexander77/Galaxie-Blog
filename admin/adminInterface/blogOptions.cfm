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
	<cfset deferKendoCommercialOnPublicSite = application.deferKendoCommercialOnPublicSite>
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
	<cfset defaultImageQuality = application.BlogOptionDbObj.getDefaultImageQuality()>
	<cfset videoMaxFileSizeMB = application.BlogOptionDbObj.getVideoMaxFileSizeMB()>
	<cfset noImageFallbackMode = application.BlogOptionDbObj.getNoImageFallbackMode()>
	<cfset heroCarouselImageCount = application.BlogOptionDbObj.getHeroCarouselImageCount()>
	<cfset heroPoolDisplayMode = application.BlogOptionDbObj.getHeroPoolDisplayMode()>
	<cfset releasedPostEmailMode = application.blog.getReleasedPostEmailMode()>
	<!--- Payments (2026-10-14): never includes a secret - see Payments.cfc getSettings. --->
	<cfset paymentSettings = application.payments.getSettings()>
	<!--- Member accounts (2026-10-15) - see Members.cfc. --->
	<cfset memberSettings = application.members.getSettings()>
	<cfset paymentCurrencies = application.payments.getCurrencies()>
	<cfset paymentStatus = application.payments.getStatus()>
		
	<!--- The azureMapsApiKey is a new variable and it may be null. --->
	<cfif !isDefined("azureMapsApiKey")>
		<cfset azureMapsApiKey = "">
	</cfif>
		
	<style>
		<!--- Hide the default Kendo borders/lines around each item/header/content area for a flat, borderless look. Covers both the older (k-item/k-link/k-content) and newer (k-panelbar-*) Kendo class names, and resets box-shadow/background-image too since some Kendo skins draw the separator line that way instead of with a plain border. Scoped to direct structural children of each item so the real form content (tables, inputs, etc.) nested inside isn't affected. --->
		#blogOptionsPanelBar,
		#blogOptionsPanelBar .k-item,
		#blogOptionsPanelBar .k-link,
		#blogOptionsPanelBar .k-header,
		#blogOptionsPanelBar .k-content,
		#blogOptionsPanelBar .k-panelbar-content,
		#blogOptionsPanelBar .k-panelbar-content-wrapper,
		#blogOptionsPanelBar .k-panelbar-item,
		#blogOptionsPanelBar .k-panelbar-link,
		#blogOptionsPanelBar .k-group,
		#blogOptionsPanelBar > .k-item > *,
		#blogOptionsPanelBar > .k-item > * > * {
			border: none !important;
			box-shadow: none !important;
			background-image: none !important;
		}
		<!--- Admin window look (2026-10-15): the reset above also removes the thin line of the 'border' rows that divide the
		settings in the tables below (td.border.k-content); put it back. --->
		#blogOptionsPanelBar td.border { border-top: 1px solid #ddd !important; }

		<!--- The compression slider's track - a visual "smaller file <-> higher quality" cue, red fading to green
		left to right, matching the 0.1-1.0 min/max the slider itself is initialized with above. Kendo draws its
		own default track first; this overrides it. --->
		#defaultImageQuality .k-slider-track {
			background: linear-gradient(to right, #d9534f, #f0ad4e, #5cb85c) !important;
			height: 6px;
		}
	</style>

	<script>
		
		<!--- Numeric inputs --->
		$("#entriesPerBlogPage").kendoNumericTextBox({
			decimals: 0,
			format: "#",
			round: true
		});

		$("#videoMaxFileSizeMB").kendoNumericTextBox({
			decimals: 0,
			format: "#",
			round: true,
			min: 1
		});

		$("#heroCarouselImageCount").kendoNumericTextBox({
			decimals: 0,
			format: "#",
			round: true,
			min: 1,
			max: 10
		});

		<!--- The default-quality slider - matches cfimage's own 0.1-1.0 "quality" attribute range, shown as a
		percentage. tickPlacement none + the gradient track CSS below (see #defaultImageQuality .k-slider-track)
		is the "easy to see gradient" cue: red/small-file at the low end fading to green/high-quality at the high
		end, so the tradeoff reads at a glance without needing a live image preview. --->
		$("#defaultImageQuality").kendoSlider({
			min: 0.1,
			max: 1.0,
			smallStep: 0.05,
			largeStep: 0.1,
			tickPlacement: "none",
			showButtons: false,
			tooltip: {
				format: "{0:p0}"
			}
		});
		
		// !!! Note on the validators, all forms need a name attribute, otherwise the positioning of the messages will not work. --->
		$(document).ready(function() {

			var optionsValidator = $("#optionsForm").kendoValidator({
				<!--- Set up custom validation rules --->
				rules: {
					<!--- The theme must be unique. --->
					themeIsUnique:
					function(input){
						<!--- Do not continue if the theme name is found in the currentTheme list --->
						if (input.is("[id='themeName']") && ( listFind( themeList, input.val() ) != 0 ) ){
							<!--- Display an error on the page. --->
							input.attr("data-themeIsUnique-msg", "Theme name already exists");
							<!--- Focus on the current element --->
							$( "#theme" ).focus();
							return false;
						}                                    
						return true;
					},
				}
			}).data("kendoValidator");

			<!--- Invoked when the submit button is clicked. Insted of using '$("form").submit(function(event) {' and 'event.preventDefault();', We are using direct binding here to speed up the event. --->
			var optionsSubmit = $('#optionsSubmit');
			optionsSubmit.on('click', function(e){ 
				
				e.preventDefault();         
				if (optionsValidator.validate()) {
					
					<!--- Open up a please wait dialog --->
					$.when(kendo.ui.ExtWaitDialog.show({ title: "Please wait...", message: "Please wait while we save the data.", width: "<cfoutput>#application.kendoExtendedUiWindowWidth#</cfoutput>", icon: "k-ext-information" }));

					<!--- Send data to server --->
					setTimeout(function() {
						postOptions();
					}, 250);
					
				} else {

					<!--- 2026-10-14: a missing field is often inside a section that is closed, so nothing looked highlighted. Open
					each section that holds one, name the fields in the message, and go to the first. --->
					var invalidFields = $("#optionsForm").find(".k-invalid");
					var panelBar = $("#blogOptionsPanelBar").data("kendoPanelBar");
					var fieldNames = [];
					invalidFields.each(function(){
						var section = $(this).closest("#blogOptionsPanelBar > li");
						if (panelBar && section.length && !section.hasClass("k-state-active") && !section.hasClass("k-expanded")) { panelBar.expand(section); }
						var labelText = $.trim($('label[for="' + this.id + '"]').first().text()).replace(/:$/, "");
						var name = labelText || this.name;
						if (name && $.inArray(name, fieldNames) == -1) { fieldNames.push(name); }
					});
					setTimeout(function(){
						if (invalidFields.length) { invalidFields[0].scrollIntoView({ block: "center" }); invalidFields.first().focus(); }
					}, 400);
					$.when(kendo.ui.ExtAlertDialog.show({ title: "There are errors", message: "Please correct the highlighted fields and try again" + (fieldNames.length ? ": " + $("<div>").text(fieldNames.join(", ")).html() : "") + ".", width: "<cfoutput>#application.kendoExtendedUiWindowWidth#</cfoutput>", icon: "k-ext-warning" }) // or k-ext-error, k-ext-question
						).done(function () {
						<!--- Do nothing --->
					});
				}
			});

		});//...document.ready
		
		<!--- Post method on the detail form called from the deptDetailFormValidator method on the detail page. The action variable will either be 'update' or 'insert'. --->
		function postOptions(){

			jQuery.ajax({
				type: 'post', 
				url: '<cfoutput>#application.baseUrl#</cfoutput>/common/cfc/ProxyController.cfc?method=saveBlogOptions&csrfToken=<cfoutput>#csrfToken#</cfoutput>',
				<!--- Serialize the form. The csrfToken is in the form. --->
				data: $('#optionsForm').serialize(),
				dataType: "json",
				success: postOptionsResult, // calls the result function.
				error: function(ErrorMsg) {
					console.log('Error' + ErrorMsg);
				}
			<!--- Extract any errors. This is a new jQuery promise based function as of jQuery 1.8. --->
			}).fail(function (jqXHR, textStatus, error) {
				<!--- Close the wait window that was launched in the calling function. --->
				kendo.ui.ExtWaitDialog.hide();
				<!--- Display the error. The full response is: jqXHR.responseText, but we just want to extract the error. --->
				$.when(kendo.ui.ExtAlertDialog.show({ title: "Error while consuming the saveBlogOptions function", message: error, icon: "k-ext-error", width: "<cfoutput>#application.kendoExtendedUiWindowWidth#</cfoutput>" }) // or k-ext-error, k-ext-information, k-ext-question, k-ext-warning.  You can also specify height.

					).done(function () {
					
				});		
			});
		};

		function postOptionsResult(response){
			<!--- Close the wait window that was launched in the calling function. --->
			kendo.ui.ExtWaitDialog.hide();
			<!--- Payments (2026-10-14): nothing is saved when a payment setting is wrong (eg. a key pasted into the wrong box). --->
			if (response && response.paymentErrors && response.paymentErrors.length){
				$.when(kendo.ui.ExtAlertDialog.show({ title: "Please check the payment settings", message: $("<div>").text(response.paymentErrors.join(" ")).html(), icon: "k-ext-warning", width: "<cfoutput>#application.kendoExtendedUiWindowWidth#</cfoutput>" }));
				return;
			}
			<!--- Close this window. --->
			$('#optionsWindow').kendoWindow('destroy');
		}
	</script>
		
	<script>
		$(document).ready(function() {
			<!--- Create an accordian style panel for each blog options section. --->
			$("#blogOptionsPanelBar").kendoPanelBar({
				expandMode: "multiple"
			});
			<!--- Payments: a searchable currency list (2026-10-14). --->
			$("#paymentCurrency").kendoDropDownList({ filter: "contains" });

		});//..document.ready
	</script>
		
	<form id="optionsForm" action="#" method="post" data-role="validator">
	<!---<input type="hidden" name="csrfToken" id="csrfToken" value="<cfoutput>#csrfToken#</cfoutput>">--->
	<input type="hidden" name="blogOptionId" id="blogOptionId" value="<cfoutput>#blogOptionId#</cfoutput>">
	<!--- The same side padding as the panel sections below, so every label column lines up. --->
	<div style="padding: 0 15px;">
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
			<input type="checkbox" class="k-checkbox" id="useSsl" name="useSsl" value="1" <cfif useSsl>checked</cfif>>
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
			<input type="checkbox" class="k-checkbox" name="serverRewriteRuleInPlace" id="serverRewriteRuleInPlace" value="1" <cfif serverRewriteRuleInPlace>checked</cfif>>
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
			<input type="checkbox" class="k-checkbox" name="deferScriptsAndCss" id="deferScriptsAndCss" value="1" <cfif deferScriptsAndCss>checked</cfif>>
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
			Galaxie Blog removes the comments and unneeded white space from the html, JavaScript and CSS of the page in order to load the page quicker (see /common/cfc/HtmlMinifier.cfc). This setting should be checked when you are in a production environment to improve page performance. You may want to turn this off if you are trying to debug code as the code is much easier to read when it is not compressed.
		</td>
	  </tr>
	  <tr height="1px">
		  <td align="left" valign="top" colspan="2" class="border <cfoutput>#thisContentClass#</cfoutput>"></td>
	  </tr>
	  <tr valign="middle" height="30px">
		<td align="right" class="<cfoutput>#thisContentClass#</cfoutput>">Minimize Code?</td>
		<td align="left" class="<cfoutput>#thisContentClass#</cfoutput>">
			<input type="checkbox" class="k-checkbox" name="minimizeCode" id="minimizeCode" value="1" <cfif minimizeCode>checked</cfif>>
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
	  <!-- Errors -->
	  <tr valign="middle" height="30px">
		<td valign="bottom" align="left" class="<cfoutput>#thisContentClass#</cfoutput>" colspan="<cfoutput>#thisColSpan#</cfoutput>">
			To help us improve the blog, you can let your blog send the blog developer, Gregory Alexander, error related information. These errors only contain data related to the error and do not contain any personal information.
		</td>
	  </tr>
	  <tr height="1px">
		  <td align="left" valign="top" colspan="2" class="border <cfoutput>#thisContentClass#</cfoutput>"></td>
	  </tr>
	  <!--- 2026-10-03: mobile's narrow single-column width crammed the checkbox and this whole description into
	  one shared cell, which read as cluttered - moved the description to its own full-width row above the
	  checkbox instead, same "label row, then content row" stacking convention this file already uses elsewhere
	  (eg. noImageFallbackMode above). Desktop's wider two-column layout had room for both in one cell, so it's
	  unchanged. --->
	  <cfif session.isMobile>
	  <tr valign="middle">
		<td class="<cfoutput>#thisContentClass#</cfoutput>" colspan="2">Send Diagnostics?</td>
	  </tr>
	  <tr>
		<td class="<cfoutput>#thisContentClass#</cfoutput>" colspan="2" style="padding: 0px 12px 8px;">
			<span style="font-size:smaller">Email new errors to the blog owner. A copy also goes to the developer of Galaxie Blog to help to find bugs: the error, its address and the stack trace, never form values. To send the copy to someone else, or not at all, set developerEmail in blog.ini.cfm.</span>
		</td>
	  </tr>
	  <tr valign="middle" height="30px">
		<td class="<cfoutput>#thisContentClass#</cfoutput>" colspan="2">
			<input type="checkbox" class="k-checkbox" name="sendDiagnostics" id="sendDiagnostics" value="1" <cfif application.SendDiagnostics>checked</cfif>>
		</td>
	  </tr>
	  <cfelse><!---<cfif session.isMobile>--->
	  <tr valign="middle" height="30px">
		<td colspan="2" class="<cfoutput>#thisContentClass#</cfoutput>">
			Email new errors to the blog owner. A copy also goes to the developer of Galaxie Blog to help to find bugs: the error, its address and the stack trace, never form values. To send the copy to someone else, or not at all, set developerEmail in blog.ini.cfm.
		</td>
	  </tr>
	  <tr height="1px">
		  <td align="left" valign="top" colspan="2" class="border <cfoutput>#thisContentClass#</cfoutput>"></td>
	  </tr>
	  <tr valign="middle" height="30px">
		<td align="right" class="<cfoutput>#thisContentClass#</cfoutput>">Send Diagnostics?</td>
		<td align="left" class="<cfoutput>#thisContentClass#</cfoutput>">
			<input type="checkbox" class="k-checkbox" name="sendDiagnostics" id="sendDiagnostics" value="1" <cfif application.SendDiagnostics>checked</cfif>>
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
			<input type="checkbox" class="k-checkbox" name="disableCache" id="disableCache" value="1" <cfif disableCache>checked</cfif>>
		</td>
	  </tr>  
	  <!-- Border -->
	  <tr height="2px">
		  <td align="left" valign="top" colspan="<cfoutput>#thisColSpan#</cfoutput>" class="<cfoutput>#thisContentClass#</cfoutput>"></td>
	  </tr>
	  
	</table>
	</div>
	<br/>
		
	<!--- Section order (2026-10-15): set-up first (Kendo, media, email, payments), then optional services, retired ones last. --->
	<ul id="blogOptionsPanelBar">
	<li>
		Jquery Location and Kendo UI
	<div class="k-content">
	<div style="padding: 15px;">
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
			  <td align="left" valign="top" colspan="<cfoutput>#thisColSpan#</cfoutput>" class="border <cfoutput>#thisContentClass#</cfoutput>"></td>
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
			<td align="right" class="<cfoutput>#thisContentClass#</cfoutput>" style="width: 20%"> 
				<label for="jQueryCDNPath">JQuery CDN Location:</label>
			</td>
			<td class="<cfoutput>#thisContentClass#</cfoutput>"  style="width: 80%">
				<input id="jQueryCDNPath" name="jQueryCDNPath" type="text" value="<cfoutput>#jQueryCDNPath#</cfoutput>" class="k-textbox" style="width: 95%" />    
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
				<input type="checkbox" class="k-checkbox" name="kendoCommercial" id="kendoCommercial" <cfif kendoCommercial>checked</cfif>>
			</td>
		  </tr>
		<cfelse><!---<cfif session.isMobile>--->
		  <tr valign="middle" height="30px">
			<td valign="bottom" align="right" class="<cfoutput>#thisContentClass#</cfoutput>" style="width:20%">
				<label for="kendoCommercial">Commercial Kendo UI Edition?</label>
			</td>
			<td valign="bottom" align="left" class="<cfoutput>#thisContentClass#</cfoutput>" style="width:80%">
				<input type="checkbox" class="k-checkbox" name="kendoCommercial" id="kendoCommercial" <cfif kendoCommercial>checked</cfif>>
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
				Kendo UI Professional is a much larger download than Kendo Core. Defer it on public-facing pages and only load it when a post actually needs it (e.g. it embeds a Kendo Grid)? Admin pages always get Kendo Professional regardless of this setting. 
			</td>
		  </tr>
		  <tr height="1px">
			  <td align="left" valign="top" colspan="2" class="border <cfoutput>#thisContentClass#</cfoutput>"></td>
		  </tr>
		<cfif session.isMobile>
		  <tr valign="middle">
			<td class="<cfoutput>#thisContentClass#</cfoutput>" colspan="2">
				<label for="deferKendoCommercialOnPublicSite">Defer Kendo Commercial on Public Site?</label>
			</td>
		   </tr>
		   <tr>
			<td class="<cfoutput>#thisContentClass#</cfoutput>" colspan="2">
				<input type="checkbox" class="k-checkbox" name="deferKendoCommercialOnPublicSite" id="deferKendoCommercialOnPublicSite" <cfif deferKendoCommercialOnPublicSite>checked</cfif>>
			</td>
		  </tr>
		<cfelse><!---<cfif session.isMobile>--->
		  <tr valign="middle" height="30px">
			<td valign="bottom" align="right" class="<cfoutput>#thisContentClass#</cfoutput>" style="width:20%">
				<label for="deferKendoCommercialOnPublicSite">Defer Kendo Commercial on Public Site?</label>
			</td>
			<td valign="bottom" align="left" class="<cfoutput>#thisContentClass#</cfoutput>" style="width:80%">
				<input type="checkbox" class="k-checkbox" name="deferKendoCommercialOnPublicSite" id="deferKendoCommercialOnPublicSite" <cfif deferKendoCommercialOnPublicSite>checked</cfif>>
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
				It is the web address of the folder that holds Kendo's js and styles folders, from the site root, eg. /blog/common/libs/kendo/2021R1/ (or /common/libs/kendo/2021R1/ when the blog is at the site root).<br/>
				Note: the blog is tested with Kendo UI Professional 2021 R1 (2021.1.119). Use 2020 or later: earlier versions (eg. 2019) draw checkboxes and radio buttons differently, so the admin site shows plain ones.
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
			<td valign="bottom" align="right" class="<cfoutput>#thisContentClass#</cfoutput>" style="width:20%">
				<label for="kendoFolderPath">Kendo Folder Path:</label>
			</td>
			<td valign="bottom" align="left" class="<cfoutput>#thisContentClass#</cfoutput>" style="width:80%">
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
	</div>
	</li>
	<!---//***********************************************************************************************
						Media Uploads
	//************************************************************************************************--->
	<li>
		Media Uploads
	<div class="k-content">
	<div style="padding: 15px;">
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
		  <cfset thisContentClass = HtmlUtilsObj.getKendoClass(thisContentClass)>
		  </cfsilent>
		  <tr height="1px">
			  <td align="left" valign="top" colspan="2" class="border <cfoutput>#thisContentClass#</cfoutput>"></td>
		  </tr>
		  <tr>
			<td colspan="2" class="<cfoutput>#thisContentClass#</cfoutput>">
				<p>Sets the site-wide defaults for image and video uploads. The image quality slider pre-fills the same slider shown on each upload - admins can still nudge it per image, but this is where it starts. It only affects JPG/WebP; PNG/GIF uploads ignore it since those formats don't have a lossy quality dial. The video size limit rejects an enclosure video upload outright once it crosses this size, before it ever reaches the site's videos folder.</p>
			</td>
		  </tr>
		  <!-- Border -->
		  <tr height="2px">
			  <td align="left" valign="top" colspan="<cfoutput>#thisColSpan#</cfoutput>" class="border <cfoutput>#thisContentClass#</cfoutput>"></td>
		  </tr>
		<cfif session.isMobile>
		  <tr valign="middle">
			<td class="<cfoutput>#thisContentClass#</cfoutput>" colspan="2">
				<label for="defaultImageQuality">Default Image Quality:</label>
			</td>
		   </tr>
		   <tr>
			<td class="<cfoutput>#thisContentClass#</cfoutput>" colspan="2" style="padding: 8px 12px;">
				<input id="defaultImageQuality" name="defaultImageQuality" value="<cfoutput>#defaultImageQuality#</cfoutput>" /><div class="k-form-hint">Left = smaller files, right = sharper images.</div>
			</td>
		  </tr>
		<cfelse><!---<cfif session.isMobile>--->
		  <tr>
		  	<td colspan="2" class="">Left = smaller files, right = sharper images.</td>
		  </tr>
		  <tr height="2px">
		  	<td align="left" valign="top" colspan="2" class="border "></td>
		  </tr>
		  <tr>
			<td align="right" class="<cfoutput>#thisContentClass#</cfoutput>" style="width: 20%">
				<label for="defaultImageQuality">Default Image Quality:</label>
			</td>
			<td class="<cfoutput>#thisContentClass#</cfoutput>" style="padding: 8px 40px 8px 12px;">
				<input id="defaultImageQuality" name="defaultImageQuality" value="<cfoutput>#defaultImageQuality#</cfoutput>" />
			</td>
		  </tr>
		</cfif>
		  <!-- Border -->
		  <tr height="2px">
			  <td align="left" valign="top" colspan="<cfoutput>#thisColSpan#</cfoutput>" class="<cfoutput>#thisContentClass#</cfoutput>"></td>
		  </tr>
		<cfsilent>
		<cfset thisContentClass = HtmlUtilsObj.getKendoClass(thisContentClass)>
		</cfsilent>
		  <tr height="2px">
			  <td align="left" valign="top" colspan="2" class="border <cfoutput>#thisContentClass#</cfoutput>"></td>
		  </tr>
		<cfif session.isMobile>
		  <tr valign="middle">
			<td class="<cfoutput>#thisContentClass#</cfoutput>" colspan="2">
				<label for="videoMaxFileSizeMB">Max Video Upload Size (MB):</label>
			</td>
		   </tr>
		   <tr>
			<td class="<cfoutput>#thisContentClass#</cfoutput>" colspan="2">
				<input id="videoMaxFileSizeMB" name="videoMaxFileSizeMB" value="<cfoutput>#videoMaxFileSizeMB#</cfoutput>" />
			</td>
		  </tr>
		<cfelse><!---<cfif session.isMobile>--->
		  <tr>
			<td align="right" class="<cfoutput>#thisContentClass#</cfoutput>" style="width: 20%">
				<label for="videoMaxFileSizeMB">Max Video Upload Size (MB):</label>
			</td>
			<td class="<cfoutput>#thisContentClass#</cfoutput>">
				<input id="videoMaxFileSizeMB" name="videoMaxFileSizeMB" value="<cfoutput>#videoMaxFileSizeMB#</cfoutput>" />
			</td>
		  </tr>
		</cfif>
		  <!-- Border -->
		  <tr height="2px">
			<td align="left" valign="top" colspan="<cfoutput>#thisColSpan#</cfoutput>" class="<cfoutput>#thisContentClass#</cfoutput>"></td>
		  </tr>
		<cfsilent>
		<cfset thisContentClass = HtmlUtilsObj.getKendoClass(thisContentClass)>
		</cfsilent>
		  <tr height="2px">
			  <td align="left" valign="top" colspan="2" class="border <cfoutput>#thisContentClass#</cfoutput>"></td>
		  </tr>
		  <tr>
			<td colspan="2" class="<cfoutput>#thisContentClass#</cfoutput>">
				<h4 class="adminBlockHeading">No-Image Fallback</h4>
			</td>
		  </tr>
		  <tr height="2px">
			  <td align="left" valign="top" colspan="2" class="border <cfoutput>#thisContentClass#</cfoutput>"></td>
		  </tr>
		  <tr>
			<td colspan="2" class="<cfoutput>#thisContentClass#</cfoutput>">
				<p>What shows in place of a post's missing image, for posts with no enclosure at all. "Generic" keeps today's plain placeholder image. "Generated CSS Gradients" shows a unique color-gradient banner per post - a deterministic gradient built from the post itself, not an AI-generated image, and nothing to upload or manage. "Pool Photo" shows either a single photo or a small carousel (see Pool Display below) drawn from a shared pool you upload once (Manage Hero Image Pool, elsewhere in the admin) - which image(s) a post gets is picked deterministically from the post's own ID, not randomly, so the same post always shows the same picture(s) instead of reshuffling on every visit. Pool Image Count controls how many images the carousel shows per post. "None" removes the image area entirely, for a text-only look. Pool falls back to Generated CSS Gradients automatically until that pool has at least one image in it.</p>
			</td>
		  </tr>
		  <tr height="2px">
			  <td align="left" valign="top" colspan="2" class="border <cfoutput>#thisContentClass#</cfoutput>"></td>
		  </tr>
		<cfif session.isMobile>
		  <tr valign="middle">
			<td class="<cfoutput>#thisContentClass#</cfoutput>" colspan="2">
				<label for="noImageFallbackMode">No-Image Fallback:</label>
			</td>
		   </tr>
		   <tr>
			<td class="<cfoutput>#thisContentClass#</cfoutput>" colspan="2" style="padding: 8px 12px;">
				<script>
					<!--- Kendo's own width init option silently ignores a percentage in this version - it falls
					back to its default calculated size (confirmed live at 206x40) instead of resolving against the
					cell. Setting the rendered wrapper's CSS width directly after init, instead of through Kendo's
					own option, is the standard workaround and isn't subject to that bug. --->
					$("#noImageFallbackMode").kendoDropDownList({
						change: function() {
							$("#manageHeroImagePoolWrapper").toggle(this.value() === "pool");
							$("#configureAnimationDefaultsWrapper").toggle(this.value() === "animation");
							$(".poolDisplayModeRow, .poolImageCountRow").toggle(this.value() === "pool");
						}
					}).data("kendoDropDownList").wrapper.css("width", "95%");
				</script>
				<select name="noImageFallbackMode" id="noImageFallbackMode">
					<option value="generic" <cfif noImageFallbackMode eq "generic">selected</cfif>>Generic (today's placeholder image)</option>
					<option value="generated" <cfif noImageFallbackMode eq "generated">selected</cfif>>Generated CSS Gradients (no AI)</option>
					<option value="pool" <cfif noImageFallbackMode eq "pool">selected</cfif>>Pool Photo (same each time, not random)</option>
					<option value="animation" <cfif noImageFallbackMode eq "animation">selected</cfif>>Animated Background (single-post pages only)</option>
					<option value="none" <cfif noImageFallbackMode eq "none">selected</cfif>>None (no image area)</option>
				</select>
				<!--- Only meaningful once No-Image Fallback is actually set to Pool - shown/hidden by the dropdown's
				own change handler above, matching its initial state here so there's no flash of the wrong state on load. --->
				<div id="manageHeroImagePoolWrapper" style="margin-top: 8px;<cfif noImageFallbackMode neq 'pool'> display: none;</cfif>">
					<button type="button" class="k-button k-primary" onclick="createAdminInterfaceWindow(73)" ontouchend="createAdminInterfaceWindow(73)">Manage Hero Image Pool</button>
				</div>
				<!--- Same shown-once-relevant pattern as the pool button above, just for 'animation'. Sets
				window.currentEnclosureEntityType='blogOption' right before opening window 79 so
				heroAnimationEditor.cfm/saveBlogOptionAnimation save the SITE-WIDE default (BlogOption.AnimationEffect/AnimationOptions),
				not a per-post override - see heroAnimationEditor.cfm's own file-header comment on the two contexts. --->
				<div id="configureAnimationDefaultsWrapper" style="margin-top: 8px;<cfif noImageFallbackMode neq 'animation'> display: none;</cfif>">
					<button type="button" class="k-button k-primary" onclick="window.currentEnclosureEntityType='blogOption';createAdminInterfaceWindow(79,<cfoutput>#blogOptionId#</cfoutput>);" ontouchend="window.currentEnclosureEntityType='blogOption';createAdminInterfaceWindow(79,<cfoutput>#blogOptionId#</cfoutput>);">Configure Animation Defaults</button>
				</div>
			</td>
		  </tr>
		<cfelse><!---<cfif session.isMobile>--->
		  <tr>
			<td align="right" class="<cfoutput>#thisContentClass#</cfoutput>" style="width: 20%">
				<label for="noImageFallbackMode">No-Image Fallback:</label>
			</td>
			<td class="<cfoutput>#thisContentClass#</cfoutput>" style="padding: 8px 40px 8px 12px;">
				<script>
					<!--- Kendo's own width init option silently ignores a percentage in this version - it falls
					back to its default calculated size (confirmed live at 206x40) instead of resolving against the
					cell. Setting the rendered wrapper's CSS width directly after init, instead of through Kendo's
					own option, is the standard workaround and isn't subject to that bug. --->
					$("#noImageFallbackMode").kendoDropDownList({
						change: function() {
							$("#manageHeroImagePoolWrapper").toggle(this.value() === "pool");
							$("#configureAnimationDefaultsWrapper").toggle(this.value() === "animation");
							$(".poolDisplayModeRow, .poolImageCountRow").toggle(this.value() === "pool");
						}
					}).data("kendoDropDownList").wrapper.css("width", "60%");
				</script>
				<select name="noImageFallbackMode" id="noImageFallbackMode">
					<option value="generic" <cfif noImageFallbackMode eq "generic">selected</cfif>>Generic (today's placeholder image)</option>
					<option value="generated" <cfif noImageFallbackMode eq "generated">selected</cfif>>Generated CSS Gradients (no AI)</option>
					<option value="pool" <cfif noImageFallbackMode eq "pool">selected</cfif>>Pool Photo (same each time, not random)</option>
					<option value="animation" <cfif noImageFallbackMode eq "animation">selected</cfif>>Animated Background (single-post pages only)</option>
					<option value="none" <cfif noImageFallbackMode eq "none">selected</cfif>>None (no image area)</option>
				</select>
				<!--- Only meaningful once No-Image Fallback is actually set to Pool - shown/hidden by the dropdown's
				own change handler above, matching its initial state here so there's no flash of the wrong state on load. --->
				<div id="manageHeroImagePoolWrapper" style="margin-top: 8px;<cfif noImageFallbackMode neq 'pool'> display: none;</cfif>">
					<button type="button" class="k-button k-primary" onclick="createAdminInterfaceWindow(73)" ontouchend="createAdminInterfaceWindow(73)">Manage Hero Image Pool</button>
				</div>
				<!--- Same shown-once-relevant pattern as the pool button above, just for 'animation'. Sets
				window.currentEnclosureEntityType='blogOption' right before opening window 79 so
				heroAnimationEditor.cfm/saveBlogOptionAnimation save the SITE-WIDE default (BlogOption.AnimationEffect/AnimationOptions),
				not a per-post override - see heroAnimationEditor.cfm's own file-header comment on the two contexts. --->
				<div id="configureAnimationDefaultsWrapper" style="margin-top: 8px;<cfif noImageFallbackMode neq 'animation'> display: none;</cfif>">
					<button type="button" class="k-button k-primary" onclick="window.currentEnclosureEntityType='blogOption';createAdminInterfaceWindow(79,<cfoutput>#blogOptionId#</cfoutput>);" ontouchend="window.currentEnclosureEntityType='blogOption';createAdminInterfaceWindow(79,<cfoutput>#blogOptionId#</cfoutput>);">Configure Animation Defaults</button>
				</div>
			</td>
		  </tr>
		</cfif>
		  <!-- Border -->
		  <tr height="2px">
			  <td align="left" valign="top" colspan="<cfoutput>#thisColSpan#</cfoutput>" class="<cfoutput>#thisContentClass#</cfoutput>"></td>
		  </tr>
		<cfsilent>
		<cfset thisContentClass = HtmlUtilsObj.getKendoClass(thisContentClass)>
		</cfsilent>
		  <tr height="2px" class="poolDisplayModeRow" <cfif noImageFallbackMode neq 'pool'>style="display:none;"</cfif>>
			  <td align="left" valign="top" colspan="2" class="border <cfoutput>#thisContentClass#</cfoutput>"></td>
		  </tr>
		<!--- 2026-10-03: only meaningful when noImageFallbackMode is actually 'pool' - shown/hidden by that
		dropdown's own change handler above, matching its initial state here so there's no flash of the wrong
		state on load (same shown-once-relevant pattern as manageHeroImagePoolWrapper/
		configureAnimationDefaultsWrapper, just applied to whole table rows instead of a div). --->
		<cfif session.isMobile>
		  <tr valign="middle" class="poolDisplayModeRow" <cfif noImageFallbackMode neq 'pool'>style="display:none;"</cfif>>
			<td class="<cfoutput>#thisContentClass#</cfoutput>" colspan="2">
				<label for="heroPoolDisplayMode">Pool Display:</label>
			</td>
		   </tr>
		   <tr class="poolDisplayModeRow" <cfif noImageFallbackMode neq 'pool'>style="display:none;"</cfif>>
			<td class="<cfoutput>#thisContentClass#</cfoutput>" colspan="2" style="padding: 8px 12px;">
				<script>
					<!--- See noImageFallbackMode's own comment above - Kendo's width init option ignores a
					percentage here, so the wrapper's CSS width is set directly after init instead. --->
					$("#heroPoolDisplayMode").kendoDropDownList({}).data("kendoDropDownList").wrapper.css("width", "95%");
				</script>
				<select name="heroPoolDisplayMode" id="heroPoolDisplayMode">
					<option value="carousel" <cfif heroPoolDisplayMode eq "carousel">selected</cfif>>Carousel (rotates through Pool Image Count images)</option>
					<option value="single" <cfif heroPoolDisplayMode eq "single">selected</cfif>>Single Image (one photo, no carousel widget)</option>
				</select>
			</td>
		  </tr>
		<cfelse><!---<cfif session.isMobile>--->
		  <tr class="poolDisplayModeRow" <cfif noImageFallbackMode neq 'pool'>style="display:none;"</cfif>>
			<td align="right" class="<cfoutput>#thisContentClass#</cfoutput>" style="width: 20%">
				<label for="heroPoolDisplayMode">Pool Display:</label>
			</td>
			<td class="<cfoutput>#thisContentClass#</cfoutput>" style="padding: 8px 40px 8px 12px;">
				<script>
					<!--- See noImageFallbackMode's own comment above - Kendo's width init option ignores a
					percentage here, so the wrapper's CSS width is set directly after init instead. --->
					$("#heroPoolDisplayMode").kendoDropDownList({}).data("kendoDropDownList").wrapper.css("width", "60%");
				</script>
				<select name="heroPoolDisplayMode" id="heroPoolDisplayMode">
					<option value="carousel" <cfif heroPoolDisplayMode eq "carousel">selected</cfif>>Carousel (rotates through Pool Image Count images)</option>
					<option value="single" <cfif heroPoolDisplayMode eq "single">selected</cfif>>Single Image (one photo, no carousel widget)</option>
				</select>
			</td>
		  </tr>
		</cfif>
		  <!-- Border -->
		  <tr height="2px" class="poolDisplayModeRow" <cfif noImageFallbackMode neq 'pool'>style="display:none;"</cfif>>
			  <td align="left" valign="top" colspan="<cfoutput>#thisColSpan#</cfoutput>" class="<cfoutput>#thisContentClass#</cfoutput>"></td>
		  </tr>
		<cfsilent>
		<cfset thisContentClass = HtmlUtilsObj.getKendoClass(thisContentClass)>
		</cfsilent>
		  <tr height="2px" class="poolImageCountRow" <cfif noImageFallbackMode neq 'pool'>style="display:none;"</cfif>>
			  <td align="left" valign="top" colspan="2" class="border <cfoutput>#thisContentClass#</cfoutput>"></td>
		  </tr>
		<cfif session.isMobile>
		  <tr valign="middle" class="poolImageCountRow" <cfif noImageFallbackMode neq 'pool'>style="display:none;"</cfif>>
			<td class="<cfoutput>#thisContentClass#</cfoutput>" colspan="2">
				<label for="heroCarouselImageCount">Pool Image Count:</label>
			</td>
		   </tr>
		   <tr class="poolImageCountRow" <cfif noImageFallbackMode neq 'pool'>style="display:none;"</cfif>>
			<td class="<cfoutput>#thisContentClass#</cfoutput>" colspan="2">
				<input id="heroCarouselImageCount" name="heroCarouselImageCount" value="<cfoutput>#heroCarouselImageCount#</cfoutput>" /><div class="k-form-hint">How many pool pictures each post shows.</div>
			</td>
		  </tr>
		<cfelse><!---<cfif session.isMobile>--->
		  <tr class="poolImageCountRow" <cfif noImageFallbackMode neq 'pool'>style="display:none;"</cfif>>
			<td align="right" class="<cfoutput>#thisContentClass#</cfoutput>" style="width: 20%">
				<label for="heroCarouselImageCount">Pool Image Count:</label>
			</td>
			<td class="<cfoutput>#thisContentClass#</cfoutput>">
				<input id="heroCarouselImageCount" name="heroCarouselImageCount" value="<cfoutput>#heroCarouselImageCount#</cfoutput>" /><div class="k-form-hint">How many pool pictures each post shows.</div>
			</td>
		  </tr>
		</cfif>
		  <!-- Border -->
		  <tr height="2px">
			<td align="left" valign="top" colspan="<cfoutput>#thisColSpan#</cfoutput>" class="<cfoutput>#thisContentClass#</cfoutput>"></td>
		  </tr>
		</table>
	</div>
	</div>
	</li>

	<!---//***********************************************************************************************
						Subscriber Email (2026-10-12)
	//************************************************************************************************--->
	<li>
		Subscriber Email
	<div class="k-content">
	<div style="padding: 15px;">
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
		  <tr>
			<td colspan="2" class="<cfoutput>#thisContentClass#</cfoutput>">
				<p>Choose what happens when you save a blog post with Released checked. A post scheduled for a later date is always emailed to your subscribers when it goes live, whatever you choose here. Pages are never emailed.</p>
			</td>
		  </tr>
		  <!-- Border -->
		  <tr height="2px">
			  <td align="left" valign="top" colspan="<cfoutput>#thisColSpan#</cfoutput>" class="border <cfoutput>#thisContentClass#</cfoutput>"></td>
		  </tr>
		  <tr>
			<td align="right" class="<cfoutput>#thisContentClass#</cfoutput>" style="width: 20%">When a post is released:</td>
			<td class="<cfoutput>#thisContentClass#</cfoutput>">
				<label><input type="radio" class="k-radio" name="releasedPostEmailMode" value="prompt" <cfif releasedPostEmailMode neq "auto">checked</cfif>> Ask me each time I save a released post</label><br/>
				<label><input type="radio" class="k-radio" name="releasedPostEmailMode" value="auto" <cfif releasedPostEmailMode eq "auto">checked</cfif>> Email my subscribers automatically the first time a post is released</label>
			</td>
		  </tr>
		  <!-- Border -->
		  <tr height="2px">
			  <td align="left" valign="top" colspan="<cfoutput>#thisColSpan#</cfoutput>" class="<cfoutput>#thisContentClass#</cfoutput>"></td>
		  </tr>
		</table>
	</div>
	</div>
	</li>
	<!--- Payments (2026-10-14): the currency, tax, test or live mode, and the owner's own Stripe keys - see common/cfc/Payments.cfc.
	Saved with the rest of Blog Options (saveBlogOptions; moved here from Blog Settings at the owner's request). The secret fields are always empty here: a saved secret is never
	sent to the browser, only that it is saved and its last 4 characters, and a blank field keeps it. --->
	<li>
		Payments
	<div class="k-content">
	<div style="padding: 15px;">
		<input type="hidden" name="paymentSettingsPosted" value="1">
		<!--- The admin block look is in blogContentCss.cfm (table.adminBlocks). The panel bar style at the top of this page clears
		borders and padding inside Blog Options by id, so the block rules need the id here. --->
		<style>
			#blogOptionsPanelBar table.adminBlocks td { padding: 5px 10px !important; }
			#blogOptionsPanelBar table.adminBlocks > tbody > tr > td[align="right"]:not([colspan]) { padding-right: 7px !important; }
			#blogOptionsPanelBar table.adminBlocks tr.blockSpacer td { padding: 0 !important; }
			#blogOptionsPanelBar table.adminBlocks td.border { border-top: 1px solid #ddd !important; }
		</style>
		<cfset blockClass = HtmlUtilsObj.getKendoClass('')>
		<table id="paymentSettingsTable" align="center" class="k-content adminBlocks" width="100%" cellpadding="5" cellspacing="0" style="table-layout: fixed">
		<colgroup><col style="width: 20%"><col></colgroup>
		<cfoutput>
		  <tr>
			<td class="#blockClass#" colspan="2">
				Take payment for bookings through your own Stripe account. The money goes straight to your account; Galaxie Blog takes no cut, and only Stripe's normal fees apply. Visitors pay on Stripe's own checkout page, so card details never reach your server.
			</td>
		  </tr>
		<cfif paymentSettings.secretsUnreadable>
		  <tr class="blockSpacer"><td colspan="2" class="border #blockClass#"></td></tr>
		  <tr>
			<td class="#blockClass#" colspan="2"><b>Your saved Stripe secrets can't be read any more</b> (blog.ini.cfm, which holds the key they were saved with, was replaced). Enter them again below.</td>
		  </tr>
		</cfif>
		  <tr class="blockSpacer"><td colspan="2" class="border #blockClass#"></td></tr>
		  <tr><td colspan="2" class="#blockClass#">Every price on the blog is in this currency.</td></tr>
		  <tr class="blockSpacer"><td colspan="2" class="border #blockClass#"></td></tr>
		  <tr>
			<td class="#blockClass#" align="right"><label for="paymentCurrency">Currency:</label></td>
			<td class="#blockClass#">
				<select id="paymentCurrency" name="paymentCurrency" style="width: #session.isMobile ? '95%' : '50%'#">
				<cfloop array="#paymentCurrencies#" index="thisCurrency">
					<option value="#thisCurrency.code#"<cfif thisCurrency.code eq paymentSettings.currency> selected</cfif>>#encodeForHtml(thisCurrency.name)#</option>
				</cfloop>
				</select>				
			</td>
		  </tr>
		  <tr class="blockSpacer"><td colspan="2" class="border #blockClass#"></td></tr>
		  <tr><td colspan="2" class="#blockClass#">Whether your sessions or events are taxable depends on where you and your clients are; check with your accountant.</td></tr>
		  <tr class="blockSpacer"><td colspan="2" class="border #blockClass#"></td></tr>
		  <tr>
			<td class="#blockClass#" align="right" valign="top">Tax:</td>
			<td class="#blockClass#">
				<label><input type="radio" class="k-radio" name="paymentTaxMode" value="included"<cfif paymentSettings.taxMode neq "add"> checked</cfif>> Prices include tax</label><br>
				<label><input type="radio" class="k-radio" name="paymentTaxMode" value="add"<cfif paymentSettings.taxMode eq "add"> checked</cfif>> Add tax at checkout:</label>
				<input type="text" id="paymentTaxName" name="paymentTaxName" value="#encodeForHtmlAttribute(paymentSettings.taxName)#" maxlength="50" placeholder="Sales tax" class="k-textbox" style="width: 200px;" aria-label="Tax name">
				<input type="number" id="paymentTaxRate" name="paymentTaxRate" value="#paymentSettings.taxRate gt 0 ? paymentSettings.taxRate : ''#" min="0" max="99.999" step="0.001" placeholder="8.25" class="k-textbox" style="width: 90px;" aria-label="Tax rate in percent"> %
			</td>
		  </tr>
		  <tr class="blockSpacer"><td colspan="2" class="border #blockClass#"></td></tr>
		  <tr><td colspan="2" class="#blockClass#">While test mode is checked, the test keys are used and no real money moves: pay with Stripe's test card 4242 4242 4242 4242, any future date and any 3 digits. Uncheck it when you're ready to take real payments.</td></tr>
		  <tr class="blockSpacer"><td colspan="2" class="border #blockClass#"></td></tr>
		  <tr><td colspan="2" class="#blockClass#"><cfif paymentStatus.ready>Ready to take #paymentStatus.testMode ? 'test' : 'real'# payments.<cfelse>Still needed for #paymentStatus.testMode ? 'test' : 'real'# payments: #encodeForHtml(arrayToList(paymentStatus.missing, ', '))#.</cfif></td></tr>
		  <tr class="blockSpacer"><td colspan="2" class="border #blockClass#"></td></tr>
		  <tr>
			<td class="#blockClass#" align="right" valign="top"><label for="paymentTestMode">Test mode:</label></td>
			<td class="#blockClass#">
				<input type="checkbox" class="k-checkbox" id="paymentTestMode" name="paymentTestMode" value="1"<cfif paymentSettings.testMode> checked</cfif>>				
			</td>
		  </tr>
		</cfoutput>
		<!--- The same three keys for each mode. --->
		<cfloop list="Test,Live" index="paymentMode">
			<cfset modeKeys = paymentMode eq "Test" ? paymentSettings.test : paymentSettings.live>
			<cfset modePrefix = paymentMode eq "Test" ? "test" : "live">
		<cfoutput>
		  <tr class="blockSpacer"><td colspan="2" class="#blockClass#"></td></tr>
		  <cfset blockClass = HtmlUtilsObj.getKendoClass(blockClass)>
		  <tr class="blockSpacer"><td colspan="2" class="border #blockClass#"></td></tr>
		  <tr><td colspan="2" class="#blockClass#"><h4 class="adminBlockHeading">Stripe #lCase(paymentMode)# keys</h4></td></tr>
		<cfif paymentMode eq "Test">
		  <tr class="blockSpacer"><td colspan="2" class="border #blockClass#"></td></tr>
		  <tr>
			<td class="#blockClass#" colspan="2">In your Stripe dashboard, under Developers &gt; API keys, with "Test mode" switched on. The test and live keys are separate, so you can try everything with the test keys first.</td>
		  </tr>
		</cfif>
		  <tr class="blockSpacer"><td colspan="2" class="border #blockClass#"></td></tr>
		  <tr>
			<td class="#blockClass#" align="right"><label for="stripe#paymentMode#PublishableKey">Publishable key:</label></td>
			<td class="#blockClass#"><!--- A textarea: the key is about 107 characters and would be cut off in a one-line box. ---><textarea id="stripe#paymentMode#PublishableKey" name="stripe#paymentMode#PublishableKey" rows="3" placeholder="pk_#modePrefix#_..." autocomplete="off" spellcheck="false" class="k-textbox" style="width: 95%; resize: none; word-break: break-all;">#encodeForHtml(modeKeys.publishableKey)#</textarea></td>
		  </tr>
		  <tr class="blockSpacer"><td colspan="2" class="border #blockClass#"></td></tr>
		  <tr>
			<td class="#blockClass#" align="right"><label for="stripe#paymentMode#SecretKey">Secret key:</label></td>
			<td class="#blockClass#">
				<input type="password" id="stripe#paymentMode#SecretKey" name="stripe#paymentMode#SecretKey" value="" placeholder="<cfif modeKeys.hasSecretKey and len(modeKeys.secretKeyHint)>Saved, #modeKeys.secretKeyHint# - leave blank to keep it<cfelse>sk_#modePrefix#_...</cfif>" autocomplete="new-password" spellcheck="false" class="k-textbox" style="width: 95%">
			</td>
		  </tr>
		  <tr class="blockSpacer"><td colspan="2" class="border #blockClass#"></td></tr>
		  <tr>
			<td class="#blockClass#" align="right"><label for="stripe#paymentMode#WebhookSecret">Webhook signing secret:</label></td>
			<td class="#blockClass#">
				<input type="password" id="stripe#paymentMode#WebhookSecret" name="stripe#paymentMode#WebhookSecret" value="" placeholder="<cfif modeKeys.hasWebhookSecret and len(modeKeys.webhookSecretHint)>Saved, #modeKeys.webhookSecretHint# - leave blank to keep it<cfelse>whsec_...</cfif>" autocomplete="new-password" spellcheck="false" class="k-textbox" style="width: 95%">
			</td>
		  </tr>
		<cfif len(modeKeys.publishableKey) or modeKeys.hasSecretKey or modeKeys.hasWebhookSecret>
		  <tr class="blockSpacer"><td colspan="2" class="border #blockClass#"></td></tr>
		  <tr>
			<td class="#blockClass#" align="right"></td>
			<td class="#blockClass#"><label><input type="checkbox" class="k-checkbox" name="clear#paymentMode#Keys" value="1"> Remove the saved #lCase(paymentMode)# keys</label></td>
		  </tr>
		</cfif>
		</cfoutput>
		</cfloop>
		<cfoutput>
		  <tr class="blockSpacer"><td colspan="2" class="#blockClass#"></td></tr>
		  <cfset blockClass = HtmlUtilsObj.getKendoClass(blockClass)>
		  <tr class="blockSpacer"><td colspan="2" class="border #blockClass#"></td></tr>
		  <tr><td colspan="2" class="#blockClass#"><h4 class="adminBlockHeading">Webhook</h4></td></tr>
		  <tr class="blockSpacer"><td colspan="2" class="border #blockClass#"></td></tr>
		  <tr>
			<td colspan="2" class="#blockClass#">Stripe tells the blog when a payment goes through by sending a signed message to the address below; a booking is only confirmed as paid when one arrives. In your Stripe dashboard, under Developers &gt; Webhooks, add an endpoint with this address and the events checkout.session.completed, checkout.session.async_payment_succeeded, checkout.session.expired and charge.refunded. Stripe then shows its signing secret (whsec_...) to paste above.</td>
		  </tr>
		  <tr class="blockSpacer"><td colspan="2" class="border #blockClass#"></td></tr>
		  <tr><td colspan="2" class="#blockClass#">Click it to select it for copying.</td></tr>
		  <tr class="blockSpacer"><td colspan="2" class="border #blockClass#"></td></tr>
		  <tr>
			<td class="#blockClass#" align="right"><label for="paymentWebhookUrl">Webhook address:</label></td>
			<td class="#blockClass#"><textarea id="paymentWebhookUrl" rows="2" readonly class="k-textbox" style="width: 95%; resize: none; word-break: break-all;" onclick="this.select();">#encodeForHtml(paymentSettings.webhookUrl)#</textarea></td>
		  </tr>
		  <tr class="blockSpacer"><td colspan="2" class="border #blockClass#"></td></tr>
		  <tr>
			<td colspan="2" class="#blockClass#">Testing on your own computer? Stripe can't reach it, so use the Stripe CLI instead. This command prints the signing secret to use for testing:<br><code style="word-break: break-all; white-space: normal;">stripe listen --forward-to #encodeForHtml(paymentSettings.webhookUrl)#</code></td>
		  </tr>
		</cfoutput>
		</table>
	</div>
	</div>
	</li>
			
	<!---//***********************************************************************************************
						Member Accounts
	//************************************************************************************************--->
	<!--- Member accounts (2026-10-15): visitors sign in with a one-time emailed link, no passwords - see common/cfc/Members.cfc.
	Saved with the rest of Blog Options (saveBlogOptions, memberSettingsPosted). --->
	<li>
		Member Accounts
	<div class="k-content">
	<div style="padding: 15px;">
		<input type="hidden" name="memberSettingsPosted" value="1">
		<cfset blockClass = HtmlUtilsObj.getKendoClass('')>
		<table id="memberSettingsTable" align="center" class="k-content adminBlocks" width="100%" cellpadding="5" cellspacing="0" style="table-layout: fixed">
		<colgroup><col style="width: 20%"><col></colgroup>
		<cfoutput>
		  <tr>
			<td colspan="2" class="#blockClass#">Let visitors sign in to see their bookings and sign-ups in one place, and have their name, email and phone filled in for them. There are no passwords: a visitor enters their email address and clicks the one-time link the blog emails them. Members never have access to the admin site.</td>
		  </tr>
		  <tr class="blockSpacer"><td colspan="2" class="border #blockClass#"></td></tr>
		  <tr>
			<td colspan="2" class="#blockClass#">When this is on, a "Sign in" link appears in the menu. Sign-in emails use the blog's email settings in <a href="javascript:createAdminInterfaceWindow(39);">Blog Settings</a>.</td>
		  </tr>
		  <tr class="blockSpacer"><td colspan="2" class="border #blockClass#"></td></tr>
		  <tr>
			<td class="#blockClass#" align="right"><label for="memberAccountsEnabled">Member accounts:</label></td>
			<td class="#blockClass#"><input type="checkbox" class="k-checkbox" id="memberAccountsEnabled" name="memberAccountsEnabled" value="1"<cfif memberSettings.enabled> checked</cfif>></td>
		  </tr>
		  <tr class="blockSpacer"><td colspan="2" class="border #blockClass#"></td></tr>
		  <tr>
			<td colspan="2" class="#blockClass#">Members can choose "Keep me signed in on this device" when they sign in. This is how long that lasts before they're asked to sign in again.</td>
		  </tr>
		  <tr class="blockSpacer"><td colspan="2" class="border #blockClass#"></td></tr>
		  <tr>
			<td class="#blockClass#" align="right"><label for="memberRememberDays">Keep signed in:</label></td>
			<td class="#blockClass#"><input type="number" id="memberRememberDays" name="memberRememberDays" class="k-textbox" min="1" max="365" value="#memberSettings.rememberDays#" style="width: 90px;"><span class="k-form-hint">days</span></td>
		  </tr>
		  <tr class="blockSpacer"><td colspan="2" class="border #blockClass#"></td></tr>
		  <tr>
			<td class="#blockClass#" align="right">Members:</td>
			<td class="#blockClass#"><button type="button" class="k-button" onclick="createAdminInterfaceWindow(97);">See members</button></td>
		  </tr>
		</cfoutput>
		</table>
	</div>
	</div>
	</li>
			
	<!---//***********************************************************************************************
						Logging
	//************************************************************************************************--->
	<li>
		Logging
	<div class="k-content">
	<div style="padding: 15px;">
		<table align="center" class="k-content" width="100%" cellpadding="2" cellspacing="0">
			
		  <cfsilent>
			<!---The first content class in the table should be empty. --->
			<cfset thisContentClass = HtmlUtilsObj.getKendoClass('')>
			<!--- Set the colspan property for borders --->
			<cfset thisColSpan = "2">
		  </cfsilent>
	
		  <tr height="1px">
			  <td align="left" valign="top" colspan="2" class="<cfoutput>#thisContentClass#</cfoutput>">
			  	Galaxie Blog logs all administrative login's and may optionally create log files for all visitors.
			  </td>
		  </tr>
		  <!-- Border -->
		  <tr height="2px">
			  <td align="left" valign="top" colspan="<cfoutput>#thisColSpan#</cfoutput>" class="border <cfoutput>#thisContentClass#</cfoutput>"></td>
		  </tr>
		  <tr>
		<cfif session.isMobile>
		  <tr valign="middle">
			<td class="<cfoutput>#thisContentClass#</cfoutput>" colspan="2">
				<label for="enableVisitorLog">Enable Visitor Logging:</label>
			</td>
		   </tr>
		   <tr>
			<td class="<cfoutput>#thisContentClass#</cfoutput>" colspan="2">
				<input id="enableVisitorLog" name="enableVisitorLog" type="checkbox" class="k-checkbox" value="1" <cfif application.logVisitors>checked</cfif> />    
			</td>
		  </tr>
		<cfelse><!---<cfif session.isMobile>--->
			<td align="right" class="<cfoutput>#thisContentClass#</cfoutput>" style="width: 20%"> 
				<label for="enableVisitorLog">Enable Visitor Logging:</label>
			</td>
			<td valign="bottom" align="left" class="<cfoutput>#thisContentClass#</cfoutput>" style="width:80%">
				<input id="enableVisitorLog" name="enableVisitorLog" type="checkbox" class="k-checkbox" value="1" <cfif application.logVisitors>checked</cfif> />    
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
				Visitor logs will fill up pretty quickly and and it is recommended that you only retain the logs several months. Setting this too high may impact blog performance as it floods your database with records; be careful when changing this setting.
			</td>
		  </tr>
		  <tr height="1px">
			  <td align="left" valign="top" colspan="2" class="border <cfoutput>#thisContentClass#</cfoutput>"></td>
		  </tr>
		<cfif session.isMobile>
		  <tr valign="middle">
			<td class="<cfoutput>#thisContentClass#</cfoutput>" colspan="2">
				<label for="visitorLogMonths">Months to retain visitor logs:</label>
			</td>
		   </tr>
		   <tr>
			<td valign="bottom" align="left" class="<cfoutput>#thisContentClass#</cfoutput>">
				<script>
					$("#visitorLogMonths").kendoDropDownList({
					});
				</script>
				<select name="visitorLogMonths" id="visitorLogMonths">
					<option value="1" <cfif application.monthsToRetainVisitorLog eq 1>selected</cfif>>1</option>
					<option value="2" <cfif application.monthsToRetainVisitorLog eq 2>selected</cfif>>2</option>
					<option value="3" <cfif application.monthsToRetainVisitorLog eq 3>selected</cfif>>3</option>
					<option value="4" <cfif application.monthsToRetainVisitorLog eq 4>selected</cfif>>4</option>
					<option value="5" <cfif application.monthsToRetainVisitorLog eq 5>selected</cfif>>5</option>
					<option value="6" <cfif application.monthsToRetainVisitorLog eq 6>selected</cfif>>6</option>
				</select>
			</td>
		  </tr>
		<cfelse><!---<cfif session.isMobile>--->
		   <tr valign="middle" height="30px">
			<td align="right" class="<cfoutput>#thisContentClass#</cfoutput>" style="width: 20%">
				<label for="visitorLogMonths">Months to retain visitor logs:</label>
			</td>
			<td valign="bottom" align="left" class="<cfoutput>#thisContentClass#</cfoutput>" style="width:80%">
				<script>
					$("#visitorLogMonths").kendoDropDownList({
					});
				</script>
				<select name="visitorLogMonths" id="visitorLogMonths">
					<option value="1" <cfif application.monthsToRetainVisitorLog eq 1>selected</cfif>>1</option>
					<option value="2" <cfif application.monthsToRetainVisitorLog eq 2>selected</cfif>>2</option>
					<option value="3" <cfif application.monthsToRetainVisitorLog eq 3>selected</cfif>>3</option>
					<option value="4" <cfif application.monthsToRetainVisitorLog eq 4>selected</cfif>>4</option>
					<option value="5" <cfif application.monthsToRetainVisitorLog eq 5>selected</cfif>>5</option>
					<option value="6" <cfif application.monthsToRetainVisitorLog eq 6>selected</cfif>>6</option>
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
			  <td align="left" valign="bottom" colspan="2" class="border <cfoutput>#thisContentClass#</cfoutput>"></td>
		  </tr>
		  <tr valign="middle" height="30px">
			<td valign="bottom" align="left" class="<cfoutput>#thisContentClass#</cfoutput>" colspan="<cfoutput>#thisColSpan#</cfoutput>">
				Site errors administrative logins are automatically logged to your database. The default retention period for the error and administrative logs is one year. Since the frequency of administrative logins is generally low, setting this to a higher setting should not impact blog performance.
			</td>
		  </tr>
		  <tr height="1px">
			  <td align="left" valign="top" colspan="2" class="border <cfoutput>#thisContentClass#</cfoutput>"></td>
		  </tr>
		<cfif session.isMobile>
		  <tr valign="middle">
			<td class="<cfoutput>#thisContentClass#</cfoutput>" colspan="2">
				<label for="adminLogMonths">Retain error and administrative logs for:</label>
			</td>
		   </tr>
		   <tr>
			<td class="<cfoutput>#thisContentClass#</cfoutput>" colspan="2">
				<script>
					$("#adminLogMonths").kendoDropDownList({
					});
				</script>
				<select name="adminLogMonths" id="adminLogMonths">
					<option value="1" <cfif application.monthsToRetainAdminLog eq 1>selected</cfif>>1 month</option>
					<option value="2" <cfif application.monthsToRetainAdminLog eq 2>selected</cfif>>2 months</option>
					<option value="3" <cfif application.monthsToRetainAdminLog eq 3>selected</cfif>>3 months</option>
					<option value="4" <cfif application.monthsToRetainAdminLog eq 4>selected</cfif>>4 months</option>
					<option value="5" <cfif application.monthsToRetainAdminLog eq 5>selected</cfif>>5 months</option>
					<option value="6" <cfif application.monthsToRetainAdminLog eq 6>selected</cfif>>6 months</option>
					<option value="7" <cfif application.monthsToRetainAdminLog eq 7>selected</cfif>>7 months</option>
					<option value="8" <cfif application.monthsToRetainAdminLog eq 8>selected</cfif>>8 months</option>
					<option value="9" <cfif application.monthsToRetainAdminLog eq 9>selected</cfif>>9 months</option>
					<option value="10" <cfif application.monthsToRetainAdminLog eq 10>selected</cfif>>10 months</option>
					<option value="11" <cfif application.monthsToRetainAdminLog eq 11>selected</cfif>>11 months</option>
					<option value="12" <cfif application.monthsToRetainAdminLog eq 12>selected</cfif>>12 months</option>
					<option value="15" <cfif application.monthsToRetainAdminLog eq 15>selected</cfif>>1 year and 3 months</option>
					<option value="18" <cfif application.monthsToRetainAdminLog eq 18>selected</cfif>>1 year and 6 months</option>
					<option value="21" <cfif application.monthsToRetainAdminLog eq 21>selected</cfif>>1 year and 9 months</option>
					<option value="24" <cfif application.monthsToRetainAdminLog eq 24>selected</cfif>>2 years</option>
				</select>
			</td>
		  </tr>
		<cfelse><!---<cfif session.isMobile>--->
		  <tr valign="middle" height="30px">
			<td align="right" class="<cfoutput>#thisContentClass#</cfoutput>" style="width: 20%">
				<label for="adminLogMonths">Months to retain error and administrative logs:</label>
			</td>
			<td valign="bottom" align="left" class="<cfoutput>#thisContentClass#</cfoutput>">
				<script>
					$("#adminLogMonths").kendoDropDownList({
					});
				</script>
				<select name="adminLogMonths" id="adminLogMonths">
					<option value="1" <cfif application.monthsToRetainAdminLog eq 1>selected</cfif>>1 month</option>
					<option value="2" <cfif application.monthsToRetainAdminLog eq 2>selected</cfif>>2 months</option>
					<option value="3" <cfif application.monthsToRetainAdminLog eq 3>selected</cfif>>3 months</option>
					<option value="4" <cfif application.monthsToRetainAdminLog eq 4>selected</cfif>>4 months</option>
					<option value="5" <cfif application.monthsToRetainAdminLog eq 5>selected</cfif>>5 months</option>
					<option value="6" <cfif application.monthsToRetainAdminLog eq 6>selected</cfif>>6 months</option>
					<option value="7" <cfif application.monthsToRetainAdminLog eq 7>selected</cfif>>7 months</option>
					<option value="8" <cfif application.monthsToRetainAdminLog eq 8>selected</cfif>>8 months</option>
					<option value="9" <cfif application.monthsToRetainAdminLog eq 9>selected</cfif>>9 months</option>
					<option value="10" <cfif application.monthsToRetainAdminLog eq 10>selected</cfif>>10 months</option>
					<option value="11" <cfif application.monthsToRetainAdminLog eq 11>selected</cfif>>11 months</option>
					<option value="12" <cfif application.monthsToRetainAdminLog eq 12>selected</cfif>>12 months</option>
					<option value="15" <cfif application.monthsToRetainAdminLog eq 15>selected</cfif>>1 year and 3 months</option>
					<option value="18" <cfif application.monthsToRetainAdminLog eq 18>selected</cfif>>1 year and 6 months</option>
					<option value="21" <cfif application.monthsToRetainAdminLog eq 21>selected</cfif>>1 year and 9 months</option>
					<option value="24" <cfif application.monthsToRetainAdminLog eq 24>selected</cfif>>2 years</option>
				</select>
			</td>
		  </tr>
		</cfif>
		  <!-- Border -->
		  <tr height="2px">
			<td align="left" valign="top" colspan="<cfoutput>#thisColSpan#</cfoutput>" class="<cfoutput>#thisContentClass#</cfoutput>"></td>
		  </tr>
		</table>
	</div>
	</div>		
	</li>
			
	<!---//***********************************************************************************************
						Google Analytics GTAG String
	//************************************************************************************************--->
	<li>
		Google Analytics
	<div class="k-content">
	<div style="padding: 15px;">
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
			  <td align="left" valign="top" colspan="2" class="border <cfoutput>#thisContentClass#</cfoutput>"></td>
		  </tr>
		  <tr>
			<td colspan="2" class="<cfoutput>#thisContentClass#</cfoutput>"> 
				<p>Google Analytics may be incorporated to determine your page traffic trends. To use Google Analytics, you must first obtain a free Google GTAG string, see <a href="https://developers.google.com/tag-platform/gtagjs/install">https://developers.google.com/tag-platform/gtagjs/install</a> for more information.</p>
				
				<p>To use Google Analytics, enter in the GTAG strings below (ie G-XXXXXX). If you have more than one GTAG string, separate them with comma's. You can enter as many GTAG strings below as you need. You don't need to do anything else other than to enter in your GTAG string(s), if a string is found, Galaxie Blog will configure Google Analytics for you.</p>
			</td>
		  </tr>
		  <!-- Border -->
		  <tr height="2px">
			  <td align="left" valign="top" colspan="<cfoutput>#thisColSpan#</cfoutput>" class="border <cfoutput>#thisContentClass#</cfoutput>"></td>
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
	</div>
	</li>
		
					
	<!---//***********************************************************************************************
						Azure Maps
	//************************************************************************************************--->
	<li>
		Azure Maps Library
	<div class="k-content">
	<div style="padding: 15px;">
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
			  <td align="left" valign="top" colspan="<cfoutput>#thisColSpan#</cfoutput>" class="border <cfoutput>#thisContentClass#</cfoutput>"></td>
		  </tr>
		<cfif session.isMobile>
		  <tr valign="middle">
			<td class="<cfoutput>#thisContentClass#</cfoutput>" colspan="2">
				<label for="azureMapsApiKey">Azure Maps API Key:</label>
			</td>
		   </tr>
		   <tr>
			<td class="<cfoutput>#thisContentClass#</cfoutput>" colspan="2">
				<textarea name="azureMapsApiKey" id="azureMapsApiKey" rows="2" class="k-textbox" style="width: 95%; resize: none; word-break: break-all;"><cfoutput>#encodeForHtml(azureMapsApiKey)#</cfoutput></textarea>
			</td>
		  </tr>
		<cfelse><!---<cfif session.isMobile>--->
		  <tr>
			<td align="right" class="<cfoutput>#thisContentClass#</cfoutput>" style="width: 20%"> 
				<label for="azureMapsApiKey">Azure Maps API Key:</label>
			</td>
			<td class="<cfoutput>#thisContentClass#</cfoutput>">
				<textarea name="azureMapsApiKey" id="azureMapsApiKey" rows="2" class="k-textbox" style="width: 95%; resize: none; word-break: break-all;"><cfoutput>#encodeForHtml(azureMapsApiKey)#</cfoutput></textarea>
			</td>
		  </tr>
		</cfif>	  
		  <!-- Border -->
		  <tr height="2px">
			  <td align="left" valign="top" colspan="<cfoutput>#thisColSpan#</cfoutput>" class="<cfoutput>#thisContentClass#</cfoutput>"></td>
		  </tr>
		
		</table>
	</div>
	</div>
	</li>
			  
	<!---//***********************************************************************************************
						Disqus
	//************************************************************************************************--->
	<li>
		Disqus Library
	<div class="k-content">
	<div style="padding: 15px;">
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
			  <td align="left" valign="top" colspan="2" class="border <cfoutput>#thisContentClass#</cfoutput>"></td>
		  </tr>
		<cfif session.isMobile>
		  <tr valign="middle">
			<td class="<cfoutput>#thisContentClass#</cfoutput>" colspan="2">
				<label for="includeDisqus">Include Disqus:</label>
			</td>
		   </tr>
		   <tr>
			<td class="<cfoutput>#thisContentClass#</cfoutput>" colspan="2">
				<input type="checkbox" class="k-checkbox" name="includeDisqus" id="includeDisqus" value="1" <cfif includeDisqus>checked</cfif> />
			</td>
		  </tr>
		<cfelse><!---<cfif session.isMobile>--->
		  <tr>
			<td align="right" class="<cfoutput>#thisContentClass#</cfoutput>" style="width: 20%"> 
				<label for="includeDisqus">Include Disqus:</label>
			</td>
			<td class="<cfoutput>#thisContentClass#</cfoutput>">
				<input type="checkbox" class="k-checkbox" name="includeDisqus" id="includeDisqus" value="1" <cfif includeDisqus>checked</cfif> />
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
			  <td align="left" valign="top" colspan="2" class="border <cfoutput>#thisContentClass#</cfoutput>"></td>
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
				<input type="text" name="disqusApiKey" id="disqusApiKey" value="<cfoutput>#disqusApiKey#</cfoutput>" class="k-textbox" style="width: 95%" /> 
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
				<input type="text" name="disqusApiSecret" id="disqusApiSecret" value="<cfoutput>#disqusApiSecret#</cfoutput>" class="k-textbox" style="width: 95%" />
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
	</div>
	</li>
			  
	<!---//***********************************************************************************************
						Greensock
	//************************************************************************************************--->
	<li>
		Greensock Animation Library
	<div class="k-content">
	<div style="padding: 15px;">
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
			  <td align="left" valign="top" colspan="2" class="border <cfoutput>#thisContentClass#</cfoutput>"></td>
		  </tr>
		  <tr>
			<td colspan="2" class="<cfoutput>#thisContentClass#</cfoutput>"> 
				<p>Greensock is a popular animation library that you can use in your blog posts. Including this library does not require a dedicated license, and it is open source, however, it requires advanced Javascript skills and should not be loaded unless you intend to use it. For more information see <a href="https://www.greensock.com">https://greensock.com/gsap/</a></p>
			</td>
		  </tr>
		  <!-- Border -->
		  <tr height="2px">
			  <td align="left" valign="top" colspan="<cfoutput>#thisColSpan#</cfoutput>" class="border <cfoutput>#thisContentClass#</cfoutput>"></td>
		  </tr>
		<cfif session.isMobile>
		  <tr valign="middle">
			<td class="<cfoutput>#thisContentClass#</cfoutput>" colspan="2">
				<label for="includeGsap">Include GSAP:</label>
			</td>
		   </tr>
		   <tr>
			<td class="<cfoutput>#thisContentClass#</cfoutput>" colspan="2">
				<input type="checkbox" class="k-checkbox" name="includeGsap" id="includeGsap" value="1" <cfif includeGsap>checked</cfif>>
			</td>
		  </tr>
		<cfelse><!---<cfif session.isMobile>--->
		  <tr>
			<td align="right" class="<cfoutput>#thisContentClass#</cfoutput>" style="width: 20%"> 
				<label for="includeGsap">Include GSAP:</label>
			</td>
			<td class="<cfoutput>#thisContentClass#</cfoutput>">
				<input type="checkbox" class="k-checkbox" name="includeGsap" id="includeGsap" value="1" <cfif includeGsap>checked</cfif>>
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
	</div>
	</li>
			  
	<!---//***********************************************************************************************
						Bing Maps
	//************************************************************************************************--->
	<li>
		Bing Maps Library (retired)
	<div class="k-content">
	<div style="padding: 15px;">
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
			  	Bing Maps will retire for free user accounts on June 30th 2025. If you have an enterprise account, Bing Maps for enterprise clients can still be used until June 30th 2028. If you're looking for map capabilities and you're not an enterprise customer, create an Azure Maps account and enter your key in the Azure Maps field above.
			  </td>
		  </tr>
		  <!-- Border -->
		  <tr height="2px">
			  <td align="left" valign="top" colspan="<cfoutput>#thisColSpan#</cfoutput>" class="border <cfoutput>#thisContentClass#</cfoutput>"></td>
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
				<input type="text" name="bingMapsApiKey" id="bingMapsApiKey" value="<cfoutput>#bingMapsApiKey#</cfoutput>" class="k-textbox" style="width: 95%" />
			</td>
		  </tr>
		</cfif>	  
		  <!-- Border -->
		  <tr height="2px">
			  <td align="left" valign="top" colspan="<cfoutput>#thisColSpan#</cfoutput>" class="<cfoutput>#thisContentClass#</cfoutput>"></td>
		  </tr>
		
		</table>
	</div>
	</div>
	</li>
	</ul>

	<br/><br/>
	<button id="optionsSubmit" name="optionsSubmit" class="k-button k-primary" type="button">Submit</button>
