	<!--- Instantiate the sting utility object.. We are using this to remove empty strings from the code preview windows. --->
	<cfobject component="#application.stringUtilsComponentPath#" name="StringUtilsObj">
	<!--- Instantiate the default content object to get the preview --->
	<cfobject component="#application.defaultContentObjPath#" name="DefaultContentObj">
	<!--- Get the theme --->
	<cfset getTheme = application.blog.getTheme(themeId=URL.optArgs)>
	<!---<cfdump var="#getTheme#">--->
		
	<cfset themeId = getTheme[1]["ThemeId"]>
	<cfset theme = getTheme[1]["Theme"]>
	<cfset kendoThemeId = getTheme[1]["KendoThemeId"]>
	<cfset kendoTheme = getTheme[1]["KendoTheme"]>
	<!--- The library file locations --->
	<cfset kendoCommonCssFileLocation = getTheme[1]["KendoCommonCssFileLocation"]>
	<cfset kendoThemeCssFileLocation = getTheme[1]["KendoThemeCssFileLocation"]>
	<cfset kendoThemeMobileCssFileLocation = getTheme[1]["KendoThemeMobileCssFileLocation"]>
	<cfset themeGenre = getTheme[1]["ThemeGenre"]>
	<cfset breakpoint = getTheme[1]["Breakpoint"]>
	<!--- User selected themes --->
	<cfset useTheme = getTheme[1]["UseTheme"]>
	<cfset selectedTheme = getTheme[1]["SelectedTheme"]>
	<cfset darkTheme = getTheme[1]["DarkTheme"]>
	<!--- Theme settings --->
	<cfset themeSettingId = getTheme[1]["ThemeSettingId"]>
	<!--- Body Font --->
	<cfset fontId = getTheme[1]["FontId"]>
	<cfset font = getTheme[1]["Font"]>
	<cfset fontSize = getTheme[1]["FontSize"]>
	<cfset fontSizeMobile = getTheme[1]["FontSizeMobile"]>
	<!--- Containers and opacity --->
	<cfset contentWidth = getTheme[1]["ContentWidth"]>
	<cfset mainContainerWidth = getTheme[1]["MainContainerWidth"]>
	<cfset sideBarContainerWidth = getTheme[1]["SideBarContainerWidth"]>
	<cfset siteOpacity = getTheme[1]["SiteOpacity"]>
	<!--- Custom header --->
	<cfset CustomHeaderHtml = getTheme[1]["CustomHeaderHtml"]>
	<cfset CustomHeaderHtmlApplyAcrossThemes = getTheme[1]["CustomHeaderHtmlApplyAcrossThemes"]>
	<!--- FavIcon --->
	<cfset favIconHtml = getTheme[1]["FavIconHtml"]>
	<cfif structKeyExists(getTheme[1], "favIconHtmlApplyAcrossThemes")>
		<cfset favIconHtmlApplyAcrossThemes = getTheme[1]["FavIconHtmlApplyAcrossThemes"]>
	<cfelse>
		<cfset favIconHtmlApplyAcrossThemes = false>
	</cfif>
	<!--- Blog backgrounds --->
	<cfset includeBackgroundImages = getTheme[1]["IncludeBackgroundImages"]>
	<cfset blogBackgroundImage = getTheme[1]["BlogBackgroundImage"]>
	<!--- Images need to have the baseUrl (this was put in to make the blog more portable) --->
	<cfif len(blogBackgroundImage)>
		<cfset blogBackgroundImage = application.baseUrl & blogBackgroundImage>
	</cfif>
	<cfset blogBackgroundImageMobile = getTheme[1]["BlogBackgroundImageMobile"]>
	<!--- Images need to have the baseUrl (this was put in to make the blog more portable) --->
	<cfif len(blogBackgroundImageMobile)>
		<cfset blogBackgroundImageMobile = application.baseUrl & blogBackgroundImageMobile>
	</cfif>
	<cfset blogBackgroundImageRepeat = getTheme[1]["BlogBackgroundImageRepeat"]>
	<cfset blogBackgroundImagePosition = getTheme[1]["BlogBackgroundImagePosition"]>
	<cfset blogBackgroundColor = getTheme[1]["BlogBackgroundColor"]>
	<!--- Header backgrounds --->
	<cfset headerBackgroundColor = getTheme[1]["HeaderBackgroundColor"]>
	<cfset headerBackgroundImage = getTheme[1]["HeaderBackgroundImage"]>
	<!--- Images need to have the baseUrl (this was put in to make the blog more portable) --->
	<cfif len(headerBackgroundImage)>
		<cfset headerBackgroundImage = application.baseUrl & headerBackgroundImage>
	</cfif>
	<!--- Menu backgrounds --->
	<cfset menuBackgroundImage = getTheme[1]["MenuBackgroundImage"]>
	<!--- Images need to have the baseUrl (this was put in to make the blog more portable) --->
	<cfif len(menuBackgroundImage)>
		<cfset menuBackgroundImage = application.baseUrl & menuBackgroundImage>
	</cfif>
	<!--- Menu Font --->
	<cfset menuFontId = getTheme[1]["MenuFontId"]>
	<cfset coverKendoMenuWithMenuBackgroundImage = getTheme[1]["CoverKendoMenuWithMenuBackgroundImage"]>
	<!--- Top menu alignment --->
	<cfset stretchHeaderAcrossPage = getTheme[1]["StretchHeaderAcrossPage"]>
	<cfset alignBlogMenuWithBlogContent = getTheme[1]["AlignBlogMenuWithBlogContent"]>
	<cfset topMenuAlign = getTheme[1]["TopMenuAlign"]>
	<!--- Title font and text color --->
	<cfset blogNameFontId = getTheme[1]["BlogNameFontId"]>
	<cfset blogNameFont = getTheme[1]["BlogNameFont"]>
	<cfset blogNameFontSize = getTheme[1]["BlogNameFontSize"]>
	<cfset blogNameFontSizeMobile = getTheme[1]["BlogNameFontSizeMobile"]>
	<cfset blogNameTextColor = getTheme[1]["BlogNameTextColor"]>
	<cfset displayBlogName = getTheme[1]["DisplayBlogName"]>
	<!--- Dividers --->
	<cfset headerBodyDividerImage = getTheme[1]["HeaderBodyDividerImage"]>
	<!--- Logos --->
	<cfset logoImageMobile = getTheme[1]["LogoImageMobile"]>
	<!--- Images need to have the baseUrl (this was put in to make the blog more portable) --->
	<cfif len(logoImageMobile)>
		<cfset logoImageMobile = application.baseUrl & logoImageMobile>
	</cfif>
	<cfset logoMobileWidth = getTheme[1]["LogoMobileWidth"]>
	<!--- Images need to have the baseUrl (this was put in to make the blog more portable) --->
	<cfset logoImage = getTheme[1]["LogoImage"]>
	<cfif len(logoImage)>
		<cfset logoImage = application.baseUrl & logoImage>
	</cfif>
	<cfset logoPaddingTop = getTheme[1]["LogoPaddingTop"]>
	<cfset logoPaddingRight = getTheme[1]["LogoPaddingRight"]>
	<cfset logoPaddingLeft = getTheme[1]["LogoPaddingLeft"]>
	<cfset logoPaddingBottom = getTheme[1]["LogoPaddingBottom"]>
	<cfset defaultLogoImageForSocialMediaShare = getTheme[1]["DefaultLogoImageForSocialMediaShare"]>
	<!--- Images need to have the baseUrl (this was put in to make the blog more portable) --->
	<cfif len(defaultLogoImageForSocialMediaShare)>
		<cfset defaultLogoImageForSocialMediaShare = application.baseUrl & defaultLogoImageForSocialMediaShare>
	</cfif>
	<cfset blogBackgroundImagePosition = getTheme[1]["BlogBackgroundImagePosition"]>
	<cfset footerImage = getTheme[1]["FooterImage"]>
	<!--- Images need to have the baseUrl (this was put in to make the blog more portable) --->
	<cfif len(footerImage)>
		<cfset footerImage = application.baseUrl & footerImage>
	</cfif>
	<cfset customFooterApplyAcrossThemes = getTheme[1]["TailEndScriptsApplyAcrossThemes"]>
		
	<cfset getFonts = application.blog.getFont()>
		
	<!--- Load the fonts for the dropdowns --->
	<style>
	<cfloop from="1" to="#arrayLen(getFonts)#" index="i">
		/* fonts */
		@font-face {
			font-family: "<cfoutput>#getFonts[i]['FileName']#</cfoutput>";
			src: url("<cfoutput>#application.baseUrl#/common/fonts/#getFonts[i]['FileName']#</cfoutput>.woff<cfif application.serverSupportsWoff2>2</cfif>");
		}
	</cfloop>
	</style>
		
	<!--- Get a list of themes for validation purposes --->
	<cfset themeList = application.blog.getThemeList()>
	<!---<cfdump var="#themeList#">--->
		
	<script>
		
		// Create a list to validate if the theme is already in use.
		var themeList = "<cfoutput>#themeList#</cfoutput>";
		
		// !!! Note on the validators, all forms need a name attribute, otherwise the positioning of the messages will not work. --->
		$(document).ready(function() {

			var themeValidator = $("#themeForm").kendoValidator({
				// Set up custom validation rules 
				rules: {
					<!--- Only validate this when inserting a new theme. --->
					<cfif not len(themeId)>
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
					</cfif>
				}
			}).data("kendoValidator");

			// Invoked when the submit button is clicked. Insted of using '$("form").submit(function(event) {' and 'event.preventDefault();', We are using direct binding here to speed up the event.
			var themeSubmit = $('#themeSubmit');
			themeSubmit.on('click', function(e){ 
				
				e.preventDefault();         
				if (themeValidator.validate()) {
					
					// Open up a please wait dialog
					$.when(kendo.ui.ExtWaitDialog.show({ title: "Please wait...", message: "Please wait while we save the theme.", width: "<cfoutput>#application.kendoExtendedUiWindowWidth#</cfoutput>", icon: "k-ext-information" }));

					// Send data to server
					setTimeout(function() {
						postTheme();
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
		function postTheme(){

			jQuery.ajax({
				type: 'post', 
				url: '<cfoutput>#application.baseUrl#</cfoutput>/common/cfc/ProxyController.cfc?method=saveTheme',
				// Serialize the form. The csrfToken is also in the form.
				data: $('#themeForm').serialize(),
				dataType: "json",
				success: postThemeResult, // calls the result function.
				error: function(ErrorMsg) {
					console.log('Error' + ErrorMsg);
				}
			// Extract any errors. This is a new jQuery promise based function as of jQuery 1.8.
			}).fail(function (jqXHR, textStatus, error) {
				// Close the wait window that was launched in the calling function.
				kendo.ui.ExtWaitDialog.hide();
				// Display the error. The full response is: jqXHR.responseText, but we just want to extract the error.
				$.when(kendo.ui.ExtAlertDialog.show({ title: "Error while consuming the save theme function", message: error, icon: "k-ext-error", width: "425px" }) // or k-ext-error, k-ext-information, k-ext-question, k-ext-warning.  You can also specify height.
					).done(function () {
					
				});		
			});
		};

		function postThemeResult(response){
			// Close the wait window that was launched in the calling function.

			kendo.ui.ExtWaitDialog.hide();
			// Refresh the subscriber grid window
			$("#themeGridWindow").data("kendoWindow").refresh();
			// Close this window.
			$('#themeSettingsWindow').kendoWindow('destroy');
		}
	</script>
		
	<!-- Collapsable style -->
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
		
		.setting-title {
			font-size: 16px;
			padding: 8px 12px;
		}
	</style>
	
	<!-- Collapsable script -->
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
		
	<script>
		// ---------------------------- kendo theme dropdown. ----------------------------
		var kendoThemeDs = new kendo.data.DataSource({
			transport: {
				read: {
					cache: false,
					// Note: since this template is in a different directory, we can't specify the cfc template without the full path name.
					url: function() { // The cfc component which processes the query and returns a json string. 
						return "<cfoutput>#application.baseUrl#</cfoutput>/common/cfc/ProxyController.cfc?method=getKendoThemesForDropdown&csrfToken=<cfoutput>#csrfToken#</cfoutput>"; 
					}, 
					dataType: "json",
					contentType: "application/json; charset=utf-8", // Note: when posting json via the request body to a coldfusion page, we must use this content type or we will get a 'IllegalArgumentException' on the ColdFusion processing page.
					type: "GET" //Note: for large payloads coming from the server, use the get method. The post method may fail as it is less efficient.
				}
			} //...transport:
		});//...var rolesDs...

		// Create the top level dropdown
		var kendoThemeId = $("#kendoThemeId").kendoDropDownList({
			optionLabel: "Select...",
			autoBind: false,
			dataTextField: "KendoTheme",
			dataValueField: "KendoThemeId",
			filter: "contains",
			dataSource: kendoThemeDs,
		}).data("kendoDropDownList");

	<cfif isDefined("kendoThemeId")>
		// Set default value by the value (this is used when the container is populated via the datasource).
		var kendoThemeId = $("#kendoThemeId").data("kendoDropDownList");
		kendoThemeId.value( <cfoutput>#kendoThemeId#</cfoutput> );
	</cfif>
								 
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
		
		// Create the body font
		var bodyFontDropdown = $("#bodyFontDropdown").kendoDropDownList({
			autoBind: false,
			dataTextField: "Font",
			dataValueField: "FontId",
			// Templates to display the fonts 
    		template: '<label style="font-family:#:data.FontFace#">#:data.Font#</label>',
			//valueTemplate: '<label style="font-family: #:data.FontFace#">#:data.FontId#</label>',
			// Template to add a new type when no data was found.
			noDataTemplate: $("#addFont").html(),
			filter: "contains",
			dataSource: fontDs,
		}).data("kendoDropDownList");

	<cfif isDefined("fontId")>
		// Set default value by the value (this is used when the container is populated via the datasource).
		var bodyFontDropdown = $("#bodyFontDropdown").data("kendoDropDownList");
		bodyFontDropdown.value( <cfoutput>#fontId#</cfoutput> );
	</cfif>

		// Create the blog namedropdown
		var blogNameFontDropdown = $("#blogNameFontDropdown").kendoDropDownList({
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

	<cfif isDefined("BlogNameFont")>
		// Set default value by the value (this is used when the container is populated via the datasource).
		var blogNameFontDropdown = $("#blogNameFontDropdown").data("kendoDropDownList");
		blogNameFontDropdown.value( <cfoutput>#blogNameFontId#</cfoutput> );
	</cfif>
								   
		// Create the menu font
		var menuFontDropdown = $("#menuFontDropdown").kendoDropDownList({
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

	<cfif isDefined("menuFontId")>
		// Set default value by the value (this is used when the container is populated via the datasource).
		var menuFontDropdown = $("#menuFontDropdown").data("kendoDropDownList");
		menuFontDropdown.value( <cfoutput>#menuFontId#</cfoutput> );
	</cfif>
							   
		$("#blogNameTextColor").kendoColorPicker({
			value: "<cfoutput>#blogNameTextColor#</cfoutput>",
			buttons: true
		});
		
		$("#blogBackgroundColor").kendoColorPicker({
			value: "<cfoutput>#blogBackgroundColor#</cfoutput>",
			buttons: true
		});
		
		$("#headerBackgroundColor").kendoColorPicker({
			value: "<cfoutput>#headerBackgroundColor#</cfoutput>",
			buttons: true
		});
		
		// Numeric inputs
		$("#contentWidth").kendoNumericTextBox({
    		decimals: 0,
			round: true
		});
		
		$("#mainContainerWidth").kendoNumericTextBox({
    		decimals: 0,
			round: true
		});
		
		$("#sideBarContainerWidth").kendoNumericTextBox({
    		decimals: 0,
			round: true
		});
		
		$("#siteOpacity").kendoNumericTextBox({
    		decimals: 0,
			round: true
		});
		
		$("#logoMobileWidth").kendoNumericTextBox({
    		decimals: 0,
			round: true
		});
		
		$("#logoPaddingLeft").kendoNumericTextBox({
    		decimals: 0,
			round: true
		});
						   
		// When a user changes the width on one container, we need to change the value of the other container. The following function has quite a bit of casting 
		function changeContainerWidth(thisContainer, mainWidth, sidebarWidth){
			// Get the current values
			sideBarWidthVal = parseInt($("#sideBarContainerWidth").val());
			mainWidthVal = parseInt($("#mainContainerWidth").val());

			// Only make changes if the two containers don't  add up to 100
			if (parseFloat(sideBarWidthVal) + parseFloat(mainWidthVal) != 100 ){
				// Change the value of the other container
				if (thisContainer == 'sideBarContainerWidth'){
					$("#mainContainerWidth").val(parseFloat(100)-parseFloat(sideBarWidthVal));
				} else if (thisContainer == 'mainContainerWidth'){
					$("#sideBarContainerWidth").val(parseFloat(100) - parseFloat(mainWidthVal));
				}
			}
		}
		 
	</script>
	
	<cfif breakPoint eq 0>
	<!--- Hide the container width elements when in modern mode --->
	<style>
		.containerWidths {
			display: none;
		}
	</style>
	</cfif>
		
	<style>
	<cfif includeBackgroundImages>
		.backgroundColor {
			display: none;
		}
	<cfelse>
		.includeBackgroundImages {
			display: none;
		}
	</cfif>
	</style>
		
	<form id="themeForm" action="#" method="post" data-role="validator">
	<input type="hidden" name="csrfToken" id="csrfToken" value="<cfoutput>#csrfToken#</cfoutput>">
	<input type="hidden" name="themeId" id="themeId" value="<cfoutput>#themeId#</cfoutput>">
	<input type="hidden" name="themeSettingId" id="themeSettingId" value="<cfoutput>#themeSettingId#</cfoutput>">
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
	 <cfif len(themeId) eq 0>
	  <tr valign="middle" height="30px">
		<td valign="bottom" align="left" class="<cfoutput>#thisContentClass#</cfoutput>" colspan="<cfoutput>#thisColSpan#</cfoutput>">
			The theme name can be changed to anything that you want when creating a theme. However, only use text and do not include any special characters. The name that you choose will be shown on the top menu.
		</td>
	  </tr>
	  <tr height="1px">
		  <td align="left" valign="top" colspan="2" class="border <cfoutput>#thisContentClass#</cfoutput>"></td>
	  </tr>
	</cfif>
	<cfif session.isMobile>
	  <tr valign="middle">
		<td class="<cfoutput>#thisContentClass#</cfoutput>" colspan="2">
			<label for="theme">Theme:</label>
		</td>
	   </tr>
	   <tr>
		<td class="<cfoutput>#thisContentClass#</cfoutput>" colspan="2">
			<input id="theme" name="theme" type="text" value="<cfoutput>#theme#</cfoutput>" class="k-textbox" style="width: 95%" />  
		</td>
	  </tr>
	<cfelse><!---<cfif session.isMobile>--->
	  <tr>
		<td align="right" class="<cfoutput>#thisContentClass#</cfoutput>" style="width: 20%"> 
			<label for="theme">Theme:</label>
		</td>
		<td class="<cfoutput>#thisContentClass#</cfoutput>">
			<input id="theme" name="theme" type="text" value="<cfoutput>#theme#</cfoutput>" class="k-textbox" style="width: 50%" />    
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
			Themes that are used will be available to attach to a given post.
			Additionally, when a theme is in use, they will be available in the theme dropdown menu at the top of the page. You can change this setting at any time. 
		</td>
	  </tr>
	  <tr height="1px">
		  <td align="left" valign="top" colspan="2" class="<cfoutput>#thisContentClass#</cfoutput>"></td>
	  </tr>
	<cfif session.isMobile>
	  <tr valign="middle">
		<td class="<cfoutput>#thisContentClass#</cfoutput>" colspan="2">
			<label for="useTheme">Use Theme?<label></td>
		</td>
	   </tr>
	   <tr>
		<td class="<cfoutput>#thisContentClass#</cfoutput>" colspan="2">
			<input type="checkbox" name="useTheme" id="useTheme" <cfif useTheme>checked</cfif>>
		</td>
	  </tr>
	<cfelse><!---<cfif session.isMobile>--->
	  <tr valign="middle" height="30px">
		<td valign="bottom" align="right" class="<cfoutput>#thisContentClass#</cfoutput>">
			<label for="useTheme">Use Theme?<label></td>
		<td valign="bottom" align="left" class="<cfoutput>#thisContentClass#</cfoutput>">
			<input type="checkbox" name="useTheme" id="useTheme" <cfif useTheme>checked</cfif>>
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
			Selecting this theme will make this the only theme that is displayed and will remove the theme dropdowns on the top menu. You can change this setting at any time.
		</td>
	  </tr>
	  <tr height="1px">
		  <td align="left" valign="top" colspan="2" class="<cfoutput>#thisContentClass#</cfoutput>"></td>
	  </tr>
	<cfif session.isMobile>
	  <tr valign="middle">
		<td class="<cfoutput>#thisContentClass#</cfoutput>" colspan="2">
			<label for="selectedTheme">Select Theme?</label>
		</td>
	   </tr>
	   <tr>
		<td class="<cfoutput>#thisContentClass#</cfoutput>" colspan="2">
			<input type="checkbox" name="selectedTheme" id="selectedTheme" <cfif selectedTheme>checked</cfif>>
		</td>
	  </tr>
	<cfelse><!---<cfif session.isMobile>--->
	  <tr valign="middle" height="30px">
		<td valign="bottom" align="right" class="<cfoutput>#thisContentClass#</cfoutput>">
			<label for="selectedTheme">Select Theme?</label>
		</td>
		<td valign="bottom" align="left" class="<cfoutput>#thisContentClass#</cfoutput>">
			<input type="checkbox" name="selectedTheme" id="selectedTheme" <cfif selectedTheme>checked</cfif>>
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
			The Kendo Theme controls the look and feel of the interfaces that are used by the theme. You can modify the Galaxie Blog and change the underlying Kendo theme, but be aware that all of the default Galaxie Blog themes are designed with a Kendo theme in mind. As of Galaxie Blog version 3.0, we are only supporting the Kendo Less based themes, however, we will support the Kendo SASS themes in the future. You can see all of the less based Kendo themes by navigating to the Kendo Theme builder at <a href="https://demos.telerik.com/kendo-ui/themebuilder">https://demos.telerik.com/kendo-ui/themebuilder</a>
		</td>
	  </tr>
	  <tr height="1px">
		  <td align="left" valign="top" colspan="2" class="<cfoutput>#thisContentClass#</cfoutput>"></td>
	  </tr>
	<cfif session.isMobile>
	  <tr valign="middle">
		<td class="<cfoutput>#thisContentClass#</cfoutput>" colspan="2">
			<label for="kendoThemeId">Kendo Theme:</label>
		</td>
	   </tr>
	   <tr>
		<td class="<cfoutput>#thisContentClass#</cfoutput>" colspan="2">
			<select id="kendoThemeId" name="kendoThemeId" style="width: 95%"></select>
		</td>
	  </tr>
	<cfelse><!---<cfif session.isMobile>--->
	  <tr valign="middle" height="30px">
		<td align="right" class="<cfoutput>#thisContentClass#</cfoutput>">
			<label for="kendoThemeId">Kendo Theme:</label>
		</td>
		<td align="left" class="<cfoutput>#thisContentClass#</cfoutput>">
			<select id="kendoThemeId" name="kendoThemeId" style="width: 50%"></select>
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
			A dark theme is a theme with a dark background. We need to determine if this is a dark theme in order to change the appearance of the page to fit the theme. 
		</td>
	  </tr>
	  <tr height="1px">
		  <td align="left" valign="top" colspan="2" class="<cfoutput>#thisContentClass#</cfoutput>"></td>
	  </tr>
	<cfif session.isMobile>
	  <tr valign="middle">
		<td class="<cfoutput>#thisContentClass#</cfoutput>" colspan="2">
			<label for="darkTheme">Dark Theme?</label>
		</td>
	   </tr>
	   <tr>
		<td class="<cfoutput>#thisContentClass#</cfoutput>" colspan="2">
			<input type="checkbox" name="darkTheme" id="darkTheme" value="1" <cfif darkTheme>checked</cfif>>
		</td>
	  </tr>
	<cfelse><!---<cfif session.isMobile>--->
	  <tr valign="middle" height="30px">
		<td align="right" class="<cfoutput>#thisContentClass#</cfoutput>">
			<label for="darkTheme">Dark Theme?</label>
		</td>
		<td align="left" class="<cfoutput>#thisContentClass#</cfoutput>">
			<input type="checkbox" name="darkTheme" id="darkTheme" value="1" <cfif darkTheme>checked</cfif>>
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
						Themes Interface Header Custom Scripts
	//************************************************************************************************--->
	<button type="button" class="collapsible k-header">Custom Header Script</button>
	<div class="content k-content">
		<table align="center" class="k-content" width="100%" cellpadding="2" cellspacing="0">
		  <cfsilent>
			<!---The first content class in the table should be empty. --->
			<cfset thisContentClass = HtmlUtilsObj.getKendoClass('')>
			<!--- Set the colspan property for borders --->
			<cfset thisColSpan = "2">

		  <!--- Set the class for alternating rows. --->
		  <!---After the first row, the content class should be the current class. --->
		  <cfset thisContentClass = HtmlUtilsObj.getKendoClass(thisContentClass)>
		  </cfsilent>
		  <tr height="1px">
			  <td align="left" valign="top" colspan="2" class="<cfoutput>#thisContentClass#</cfoutput>"></td>
		  </tr>
		  <tr>
			<td colspan="2"> 
				<p>You can place optional custom HTML or scripts between the head tags. This is often done when you need to embed Google Adds or other custom libraries that need to have the scripts placed at the top of the page.</p>
				<p>If you want this custom script to be applied to all themes, click on the 'Apply across all themes' checkbox.</p>
			</td>
		  </tr>
		  <!-- Border -->
		  <tr height="2px">
			  <td align="left" valign="top" colspan="<cfoutput>#thisColSpan#</cfoutput>" class="border <cfoutput>#thisContentClass#</cfoutput>"></td>
		  </tr>
		  <cfsilent>
		  <!--- Set the class for alternating rows. --->
		  <!---After the first row, the content class should be the current class. --->
		  <cfset thisContentClass = HtmlUtilsObj.getKendoClass(thisContentClass)>
		  </cfsilent>
		
		  <!-- Border -->
		  <tr height="2px">
			  <td align="left" valign="top" colspan="<cfoutput>#thisColSpan#</cfoutput>" class="border <cfoutput>#thisContentClass#</cfoutput>"></td>
		  </tr>
			  
		<cfif session.isMobile>
		  <tr valign="middle">
			<td class="<cfoutput>#thisContentClass#</cfoutput>" colspan="2">
				<label for="customScripts">Custom Header HTML:</label>
			</td>
		   </tr>
		   <tr>
			<td class="<cfoutput>#thisContentClass#</cfoutput>" colspan="2">
				<!--- Hidden input to store the code from the code editor --->
				<input type="hidden" name="customHeaderHtmlCode" id="customHeaderHtmlCode" value=""/>
				<!-- Editor -->
				<button id="customScriptButton" name="customScriptButton" class="k-button k-primary" type="button" onClick="javascript:createAdminInterfaceWindow(52,<cfoutput>#themeId#</cfoutput>, 'customHeaderHtml',false)">Edit</button>
			</td>
		  </tr>
		<cfelse><!---<cfif session.isMobile>--->
		  <tr>
			<td align="right" class="<cfoutput>#thisContentClass#</cfoutput>" style="width: 20%"> 
				<label for="customScripts">Custom Header HTML:</label>
			</td>
			<td class="<cfoutput>#thisContentClass#</cfoutput>">
				<!--- Hidden input to store the code from the code editor --->
				<input type="hidden" name="customHeaderHtmlCode" id="customHeaderHtmlCode" value=""/>
				<!--- Link to tinyMce editor: createAdminInterfaceWindow(52,themeId,'template',isMobile) --->
				<!-- Editor -->
				<button id="customScriptButton" name="customScriptButton" class="k-button k-primary" type="button" onClick="javascript:createAdminInterfaceWindow(52,<cfoutput>#themeId#</cfoutput>, 'customHeaderHtml',false)">Edit</button>
			</td>
		  </tr>
		</cfif>
		  <!-- Border -->
		  <tr height="2px">
			  <td align="left" valign="top" colspan="<cfoutput>#thisColSpan#</cfoutput>" class="<cfoutput>#thisContentClass#</cfoutput>"></td>
		  </tr>
		<cfif session.isMobile>
		  <tr valign="middle">
			<td class="<cfoutput>#thisContentClass#</cfoutput>" colspan="2">
				<label for="applyCustomHeaderHtmlToAllThemes">Apply across all themes:</label>
			</td>
		   </tr>
		   <tr>
			<td class="<cfoutput>#thisContentClass#</cfoutput>" colspan="2">
				<input type="checkbox" id="applyCustomHeaderHtmlToAllThemes" name="applyCustomHeaderHtmlToAllThemes" <cfif favIconHtmlApplyAcrossThemes>checked</cfif>>
			</td>
		  </tr>
		<cfelse><!---<cfif session.isMobile>--->
		  <tr>
			<td align="right" class="<cfoutput>#thisContentClass#</cfoutput>" style="width: 20%"> 
				<label for="applyCustomHeaderHtmlToAllThemes">Apply across all themes:</label>
			</td>
			<td class="<cfoutput>#thisContentClass#</cfoutput>">
				 <input type="checkbox" id="applyCustomHeaderHtmlToAllThemes" name="applyCustomHeaderHtmlToAllThemes" <cfif favIconHtmlApplyAcrossThemes>checked</cfif>>
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
						Themes Interface Fav Icon
	//************************************************************************************************--->
	<button type="button" class="collapsible k-header">Fav Icon</button>
	<div class="content k-content">
		<table align="center" class="k-content" width="100%" cellpadding="2" cellspacing="0">
		  <cfsilent>
			<!---The first content class in the table should be empty. --->
			<cfset thisContentClass = HtmlUtilsObj.getKendoClass('')>
			<!--- Set the colspan property for borders --->
			<cfset thisColSpan = "2">

		  <!--- Set the class for alternating rows. --->
		  <!---After the first row, the content class should be the current class. --->
		  <cfset thisContentClass = HtmlUtilsObj.getKendoClass(thisContentClass)>
		  </cfsilent>
		  <tr height="1px">
			  <td align="left" valign="top" colspan="2" class="<cfoutput>#thisContentClass#</cfoutput>"></td>
		  </tr>
		  <tr>
			<td colspan="2"> 
				<p>The Favorite Icon will allow other devices to display your theme when bookmarking a page and will display the icon on the tab in the browser.</p>
				<p>There are many free favicon generators on the web, for example, <a href="https://favicon.io/">https://favicon.io/</a> that will generate the necessary files for you.</p> <p>However, each generator is unique and creates different files and the standards are fluid and not consistent. Please generate your files manually or by using a generator, and paste in the code that you want the browser to render. Once you're done, you may also click on the upload FavIcon Files button below to upload your files to the root directory of your blog site.</p>
				<p>If you want your Favorite Icon HTML to be applied to all themes, click on the 'Apply across all themes' checkbox.</p>
			</td>
		  </tr>
		  <!-- Border -->
		  <tr height="2px">
			  <td align="left" valign="top" colspan="<cfoutput>#thisColSpan#</cfoutput>" class="border <cfoutput>#thisContentClass#</cfoutput>"></td>
		  </tr>
			  
		<cfif session.isMobile>
		  <tr valign="middle">
			<td class="<cfoutput>#thisContentClass#</cfoutput>" colspan="2">
				<label for="uploadFavIcon"></label>
			</td>
		   </tr>
		   <tr>
			<td class="<cfoutput>#thisContentClass#</cfoutput>" colspan="2">				
				<button id="uploadFavIcon" class="k-button k-primary" type="button" onclick="createAdminInterfaceWindow(36, 'favIconUploader')">Upload FavIcon files</button> 
			</td>
		  </tr>
		<cfelse><!---<cfif session.isMobile>--->
		  <tr>
			<td align="right" class="<cfoutput>#thisContentClass#</cfoutput>" style="width: 20%"> 
				<label for="saveFavIcon">Upload Favorite Icons</label>
			</td>
			<td class="<cfoutput>#thisContentClass#</cfoutput>">				
				<button id="uploadFavIcon" class="k-button k-primary" type="button" onclick="createAdminInterfaceWindow(36, 'favIconUploader')">Upload FavIcon files</button>  
			</td>
		  </tr>
		</cfif>	
		  <cfsilent>
		  <!--- Set the class for alternating rows. --->
		  <!---After the first row, the content class should be the current class. --->
		  <cfset thisContentClass = HtmlUtilsObj.getKendoClass(thisContentClass)>
		  </cfsilent>
		
		  <!-- Border -->
		  <tr height="2px">
			  <td align="left" valign="top" colspan="<cfoutput>#thisColSpan#</cfoutput>" class="border <cfoutput>#thisContentClass#</cfoutput>"></td>
		  </tr>
			  
		<cfif session.isMobile>
		  <tr valign="middle">
			<td class="<cfoutput>#thisContentClass#</cfoutput>" colspan="2">
				<label for="favIconHtml">Fav Icon HTML:</label>
			</td>
		   </tr>
		   <tr>
			<td class="<cfoutput>#thisContentClass#</cfoutput>" colspan="2">
				<!--- Hidden input to store the code from the code editor --->
				<input type="hidden" name="favIconHtmlCode" id="favIconHtmlCode" value=""/>
				<!-- Editor -->
				<button id="favIconButton" name="favIconButton" class="k-button k-primary" type="button" onClick="javascript:createAdminInterfaceWindow(52,<cfoutput>#themeId#</cfoutput>, 'favIconHtml',false)">Edit</button>
			</td>
		  </tr>
		<cfelse><!---<cfif session.isMobile>--->
		  <tr>
			<td align="right" class="<cfoutput>#thisContentClass#</cfoutput>" style="width: 20%"> 
				<label for="favIconHtml">Fav Icon HTML:</label>
			</td>
			<td class="<cfoutput>#thisContentClass#</cfoutput>">
				<!--- Hidden input to store the code from the code editor --->
				<input type="hidden" name="favIconHtmlCode" id="favIconHtmlCode" value=""/>
				<!--- Link to tinyMce editor: createAdminInterfaceWindow(52,themeId,'template',isMobile) --->
				<!-- Editor -->
				<button id="favIconButton" name="favIconButton" class="k-button k-primary" type="button" onClick="javascript:createAdminInterfaceWindow(52,<cfoutput>#themeId#</cfoutput>, 'favIconHtml',false)">Edit</button>
			</td>
		  </tr>
		</cfif>
		  <!-- Border -->
		  <tr height="2px">
			  <td align="left" valign="top" colspan="<cfoutput>#thisColSpan#</cfoutput>" class="<cfoutput>#thisContentClass#</cfoutput>"></td>
		  </tr>
		<cfif session.isMobile>
		  <tr valign="middle">
			<td class="<cfoutput>#thisContentClass#</cfoutput>" colspan="2">
				<label for="applyFavIconToAllThemes">Apply across all themes:</label>
			</td>
		   </tr>
		   <tr>
			<td class="<cfoutput>#thisContentClass#</cfoutput>" colspan="2">
				<input type="checkbox" id="applyFavIconToAllThemes" name="applyFavIconToAllThemes" <cfif favIconHtmlApplyAcrossThemes>checked</cfif>>
			</td>
		  </tr>
		<cfelse><!---<cfif session.isMobile>--->
		  <tr>
			<td align="right" class="<cfoutput>#thisContentClass#</cfoutput>" style="width: 20%"> 
				<label for="applyFavIconToAllThemes">Apply across all themes:</label>
			</td>
			<td class="<cfoutput>#thisContentClass#</cfoutput>">
				 <input type="checkbox" id="applyFavIconToAllThemes" name="applyFavIconToAllThemes" <cfif favIconHtmlApplyAcrossThemes>checked</cfif>>
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
						Themes Interface Fonts
	//************************************************************************************************--->
	<button type="button" class="collapsible k-header">Fonts</button>
	<div class="content k-content">
		<table align="center" class="k-content" width="100%" cellpadding="2" cellspacing="0">
			
		  <cfsilent>
			<!---The first content class in the table should be empty. --->
			<cfset thisContentClass = HtmlUtilsObj.getKendoClass('')>
			<!--- Set the colspan property for borders --->
			<cfset thisColSpan = "2">
		  </cfsilent>
			 
		  <tr height="1px">
			  <td align="left" valign="top" colspan="2" class="border <cfoutput>#thisContentClass#</cfoutput>"></td>
		  </tr>
		<cfif session.isMobile>
		  <tr valign="middle">
			<td class="<cfoutput>#thisContentClass#</cfoutput>" colspan="2">
				<label for="blogNameFontDropdown">Title Font:</label>
			</td>
		   </tr>
		   <tr>
			<td class="<cfoutput>#thisContentClass#</cfoutput>" colspan="2">
				<select id="blogNameFontDropdown" name="blogNameFontDropdown" style="width: 95%"></select>  
				<!--- Inline template to add a new user. --->
				<script id="addFont" type="text/x-kendo-tmpl">
					<div>
						Font not found. Do you want to add '#: instance.filterInput.val() #'?
					</div>
					<br />
					<button class="k-button" onclick="createAdminInterfaceWindow(31, '#: instance.filterInput.val() #', 'addFont')">Add Font</button>
				</script> 
			</td>
		  </tr>
		<cfelse><!---<cfif session.isMobile>--->
		  <tr>
			<td align="right" class="<cfoutput>#thisContentClass#</cfoutput>" style="width: 20%"> 
				<label for="blogNameFontDropdown">Title Font:</label>
			</td>
			<td class="<cfoutput>#thisContentClass#</cfoutput>">
				<select id="blogNameFontDropdown" name="blogNameFontDropdown" style="width: 50%"></select>  
				<!--- Inline template to add a new user. --->
				<script id="addFont" type="text/x-kendo-tmpl">
					<div>
						Font not found. Do you want to add '#: instance.filterInput.val() #'?
					</div>
					<br />
					<button class="k-button" onclick="createAdminInterfaceWindow(31, '#: instance.filterInput.val() #', 'addFont')">Add Font</button>
				</script>  
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
				<label for="blogNameFontSize">Title Font Size:</label>
			</td>
		   </tr>
		   <tr>
			<td class="<cfoutput>#thisContentClass#</cfoutput>" colspan="2">
				<input type="number" id="blogNameFontSize" name="blogNameFontSize" min="8" max="36" step="1" value="<cfoutput>#blogNameFontSize#</cfoutput>" class="k-textbox" > pt
			</td>
		  </tr>
		<cfelse><!---<cfif session.isMobile>--->
		  <tr>
			<td align="right" class="<cfoutput>#thisContentClass#</cfoutput>" style="width: 20%"> 
				<label for="fontSize">Title Font Size:</label>
			</td>
			<td class="<cfoutput>#thisContentClass#</cfoutput>">
				<input type="number" id="blogNameFontSize" name="blogNameFontSize" min="8" max="36" step="1" value="<cfoutput>#blogNameFontSize#</cfoutput>" class="k-textbox" > pt 
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
				<label for="blogNameFontSizeMobile">Mobile Title Font Size:</label>
			</td>
		   </tr>
		   <tr>
			<td class="<cfoutput>#thisContentClass#</cfoutput>" colspan="2">
				<input type="number" id="blogNameFontSizeMobile" name="blogNameFontSizeMobile" min="8" max="30" step="1" value="<cfoutput>#blogNameFontSizeMobile#</cfoutput>" class="k-textbox" > pt  
			</td>
		  </tr>
		<cfelse><!---<cfif session.isMobile>--->
		  <tr>
			<td align="right" class="<cfoutput>#thisContentClass#</cfoutput>" style="width: 20%"> 
				<label for="blogNameFontSizeMobile">Mobile Title Font Size:</label>
			</td>
			<td class="<cfoutput>#thisContentClass#</cfoutput>">
				<input type="number" id="blogNameFontSizeMobile" name="blogNameFontSizeMobile" min="8" max="30" step="1" value="<cfoutput>#blogNameFontSizeMobile#</cfoutput>" class="k-textbox" > pt  
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
				<label for="menuFontDropdown">Top Menu Font:</label>
			</td>
		   </tr>
		   <tr>
			<td class="<cfoutput>#thisContentClass#</cfoutput>" colspan="2">
				<select id="menuFontDropdown" name="menuFontDropdown" style="width: 95%"></select>  
				<!--- Inline template to add a new user. --->
				<script id="addFont" type="text/x-kendo-tmpl">
					<div>
						Font not found. Do you want to add '#: instance.filterInput.val() #'?
					</div>
					<br />
					<button class="k-button" onclick="createAdminInterfaceWindow(31, '#: instance.filterInput.val() #', 'addFont')">Add Font</button>
				</script>  
			</td>
		  </tr>
		<cfelse><!---<cfif session.isMobile>--->
		  <tr>
			<td align="right" class="<cfoutput>#thisContentClass#</cfoutput>" style="width: 20%"> 
				<label for="menuFontDropdown">Top Menu Font:</label>
			</td>
			<td class="<cfoutput>#thisContentClass#</cfoutput>">
				<select id="menuFontDropdown" name="menuFontDropdown" style="width: 50%"></select>  
				<!--- Inline template to add a new user. --->
				<script id="addFont" type="text/x-kendo-tmpl">
					<div>
						Font not found. Do you want to add '#: instance.filterInput.val() #'?
					</div>
					<br />
					<button class="k-button" onclick="createAdminInterfaceWindow(31, '#: instance.filterInput.val() #', 'addFont')">Add Font</button>
				</script>  
			</td>
		  </tr>
		</cfif>	  
		  <cfsilent>
		  <!--- Set the class for alternating rows. --->
		  <!---After the first row, the content class should be the current class. --->
		  <cfset thisContentClass = HtmlUtilsObj.getKendoClass(thisContentClass)>
		  </cfsilent>
				
		  <!-- Border -->
		  <tr height="2px">
			  <td align="left" valign="top" colspan="<cfoutput>#thisColSpan#</cfoutput>" class="border <cfoutput>#thisContentClass#</cfoutput>"></td>
		  </tr>
		  <tr height="1px">
			  <td align="left" valign="top" colspan="2" class="<cfoutput>#thisContentClass#</cfoutput>"></td>
		  </tr>
		<cfif session.isMobile>
		  <tr valign="middle">
			<td class="<cfoutput>#thisContentClass#</cfoutput>" colspan="2">
				<label for="bodyFontDropdown">Body Font:</label>
			</td>
		   </tr>
		   <tr>
			<td class="<cfoutput>#thisContentClass#</cfoutput>" colspan="2">
				<select id="bodyFontDropdown" name="bodyFontDropdown" style="width: 95%"></select>  
				<!--- Inline template to add a new user. --->
				<script id="addFont" type="text/x-kendo-tmpl">
					<div>
						Font not found. Do you want to add '#: instance.filterInput.val() #'?
					</div>
					<br />
					<button class="k-button" onclick="createAdminInterfaceWindow(31, '#: instance.filterInput.val() #', 'addFont')">Add Font</button>
				</script> 
			</td>
		  </tr>
		<cfelse><!---<cfif session.isMobile>--->
		  <tr>
			<td align="right" class="<cfoutput>#thisContentClass#</cfoutput>" style="width: 20%"> 
				<label for="bodyFontDropdown">Body Font:</label>
			</td>
			<td class="<cfoutput>#thisContentClass#</cfoutput>">
				<select id="bodyFontDropdown" name="bodyFontDropdown" style="width: 50%"></select>  
				<!--- Inline template to add a new user. --->
				<script id="addFont" type="text/x-kendo-tmpl">
					<div>
						Font not found. Do you want to add '#: instance.filterInput.val() #'?
					</div>
					<br />
					<button class="k-button" onclick="createAdminInterfaceWindow(31, '#: instance.filterInput.val() #', 'addFont')">Add Font</button>
				</script>  
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
				<label for="fontSize">Desktop Body Font Size:</label>
			</td>
		   </tr>
		   <tr>
			<td class="<cfoutput>#thisContentClass#</cfoutput>" colspan="2">
				<input type="number" id="fontSize" name="fontSize" min="8" max="36" step="1" value="<cfoutput>#fontSize#</cfoutput>" class="k-textbox" > pt
			</td>
		  </tr>
		<cfelse><!---<cfif session.isMobile>--->
		  <tr>
			<td align="right" class="<cfoutput>#thisContentClass#</cfoutput>" style="width: 20%"> 
				<label for="fontSize">Desktop Body Font Size:</label>
			</td>
			<td class="<cfoutput>#thisContentClass#</cfoutput>">
				<input type="number" id="fontSize" name="fontSize" min="8" max="36" step="1" value="<cfoutput>#fontSize#</cfoutput>" class="k-textbox" > pt 
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
				<label for="fontSizeMobile">Mobile Body Font Size:</label>
			</td>
		   </tr>
		   <tr>
			<td class="<cfoutput>#thisContentClass#</cfoutput>" colspan="2">
				<input type="number" id="fontSizeMobile" name="fontSizeMobile" min="8" max="32" step="1" value="<cfoutput>#fontSizeMobile#</cfoutput>" class="k-textbox"> pt  
			</td>
		  </tr>
		<cfelse><!---<cfif session.isMobile>--->
		  <tr>
			<td align="right" class="<cfoutput>#thisContentClass#</cfoutput>" style="width: 20%"> 
				<label for="fontSizeMobile">Mobile Body Font Size:</label>
			</td>
			<td class="<cfoutput>#thisContentClass#</cfoutput>">
				<input type="number" id="fontSizeMobile" name="fontSizeMobile" min="8" max="32" step="1" value="<cfoutput>#fontSizeMobile#</cfoutput>" class="k-textbox"> pt  
			</td>
		  </tr>
		</cfif>
		  <!-- Border -->
		  <tr height="2px">
			  <td align="left" valign="top" colspan="<cfoutput>#thisColSpan#</cfoutput>" class="<cfoutput>#thisContentClass#</cfoutput>"></td>
		  </tr>
			  
		  <!-- Border -->
		  <tr height="2px">
			<td align="left" valign="top" colspan="<cfoutput>#thisColSpan#</cfoutput>" class="<cfoutput>#thisContentClass#</cfoutput>"></td>
		  </tr>
		</table>
	</div>
			  
	<!---//***********************************************************************************************
						Themes Interface Container Properties
	//************************************************************************************************--->
	<button type="button" class="collapsible k-header">Blog Theme Style and Column Display</button>
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
				<p>The main content width sets the width on the main container that holds the two sub containers below. This setting will either increase or decrease the blog content depending upon your setting.</p>
				
				<p>The main content width will dynamically be adjusted depending upon the client screen resolution. When the monitor is quite wide, the main content width will be set to a smaller percentage, conversly, when the monitor is smaller in width, this width will be automatically adjusted higher.</p>
				
				<p>This is done as you want to have a similiar content width across various monitor sizes. The baseline content width that you set will be targetted at a screen resolution betwen 1700 and 1920 pixels wide.</p>
				
				<p>You should set the main container width to at least 45% when using the modern theme style, or 66% when using the classic style as you will have extra content on the right side. Setting it larger will stretch the main container accross the page making the blog content more cumbersome to read. Generally speaking, the main blog content should be no more than 140 characters wide and focus the content in the center of the page.</p>
			</td>
		  </tr>
		  <!-- Border -->
		  <tr height="2px">
			  <td align="left" valign="top" colspan="<cfoutput>#thisColSpan#</cfoutput>" class="<cfoutput>#thisContentClass#</cfoutput>"></td>
		  </tr>
		<cfif session.isMobile>
		  <tr valign="middle">
			<td class="<cfoutput>#thisContentClass#</cfoutput>" colspan="2">
				<label for="contentWidth">Main Content Width:</label>
			</td>
		   </tr>
		   <tr>
			<td class="<cfoutput>#thisContentClass#</cfoutput>" colspan="2">
				<input type="number" id="contentWidth" name="contentWidth" min="33" max="100" step="1" value="<cfoutput>#contentWidth#</cfoutput>" class="k-textbox" >% 
			</td>
		  </tr>
		<cfelse><!---<cfif session.isMobile>--->
		  <tr>
			<td align="right" class="<cfoutput>#thisContentClass#</cfoutput>" style="width: 20%"> 
				<label for="contentWidth">Main Content Width:</label>
			</td>
			<td class="<cfoutput>#thisContentClass#</cfoutput>">
				<input type="number" id="contentWidth" name="contentWidth" min="33" max="100" step="1" value="<cfoutput>#contentWidth#</cfoutput>" class="k-textbox" >% 
			</td>
		  </tr>
		</cfif>
		  <!-- Border -->
		  <tr height="2px" class="containerWidths">
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
			<td colspan="2"> 
				<p>There are two options that dramatically affect the blog display.</p> 
				<p>The <b>Classic</b> theme style displays the column on the right of the blog containing various 'pods', such as the categories, recent posts and comments, etc. this is a useful design if you want to allow your users to quickly navigate your site or if you want include visible advertising.</p>
				<p>The <b>Modern</b> theme style removes the panel on the right, but the panel is still accessible by clicking on the hamburger at the top of the site. The Modern theme style keeps keeps the blog content center stage and is a more modern design.</p>
			</td>
		  </tr>
		  <!-- Border -->
		  <tr height="2px">
			  <td align="left" valign="top" colspan="<cfoutput>#thisColSpan#</cfoutput>" class="<cfoutput>#thisContentClass#</cfoutput>"></td>
		  </tr>
		<cfif session.isMobile>
		  <tr valign="middle">
			<td class="<cfoutput>#thisContentClass#</cfoutput>" colspan="2">
				<label for="blogStyle">Blog Theme Style:</label>
			</td>
		   </tr>
		   <tr>
			<td class="<cfoutput>#thisContentClass#</cfoutput>" colspan="2">
				<table align="center" class="<cfoutput>#thisContentClass#</cfoutput>" width="100%" cellpadding="5" cellspacing="0" border="0">
					<tr>
						<td width="50%" align="left">
							<input id="themeStyle" name="themeStyle" type="radio" value="classic" <cfif breakPoint gt 0>checked</cfif> class="normalFontWeight" onclick='javascript:$( ".containerWidths" ).show();'>
							<label for="themeStyle">classic</label>
						</td>
						<td width="50%" align="left">
							<input id="themeStyle" name="themeStyle" type="radio" value="modern" <cfif breakPoint eq 0>checked</cfif> class="normalFontWeight" onclick='javascript:$( ".containerWidths" ).hide();'>
							<label for="modern">Modern</label>
						</td>
					</tr>
				</table>
			</td>
		  </tr>
		<cfelse><!---<cfif session.isMobile>--->
		  <tr>
			<td align="right" class="<cfoutput>#thisContentClass#</cfoutput>" style="width: 20%"> 
				<label for="blogStyle">Blog Theme Style:</label>
			</td>
			<td class="<cfoutput>#thisContentClass#</cfoutput>">
				<table align="center" class="<cfoutput>#thisContentClass#</cfoutput>" width="100%" cellpadding="5" cellspacing="0" border="0">
					<tr>
						<td width="50%" align="left">
							<input id="themeStyle" name="themeStyle" type="radio" value="classic" <cfif breakPoint gt 0>checked</cfif> class="normalFontWeight" onclick='javascript:$( ".containerWidths" ).show();'>
							<label for="themeStyle">classic</label>
						</td>
						<td width="50%" align="left">
							<input id="themeStyle" name="themeStyle" type="radio" value="modern" <cfif breakPoint eq 0>checked</cfif> class="normalFontWeight" onclick='javascript:$( ".containerWidths" ).hide();'>
							<label for="modern">Modern</label>
						</td>
					</tr>
				</table>
			</td>
		  </tr>
		</cfif>
		  <!-- Border -->
		  <tr height="2px" class="containerWidths">
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
		  <tr valign="middle" class="containerWidths">
			<td class="<cfoutput>#thisContentClass#</cfoutput>" colspan="2">
				<label for="mainContainerWidth">Main Panel Container Width:</label>
			</td>
		   </tr>
		   <tr class="containerWidths">
			<td class="<cfoutput>#thisContentClass#</cfoutput>" colspan="2">
				<!--- We are passing: 35 as the adminInterfaceId, URL.optArgs is the themeId, URL.otherArgs is the theme image type, and URL.otherArgs1 is the current image being used. --->
				<cfoutput>
				<input type="number" id="mainContainerWidth" name="mainContainerWidth" min="50" max="80" step="1" value="#mainContainerWidth#" style="width: 20%" class="k-textbox" onChange="changeContainerWidth('mainContainerWidth');">% (left panel)
				</cfoutput>
			</td>
		  </tr>
		<cfelse><!---<cfif session.isMobile>--->
		  <tr class="containerWidths">
			<td align="right" class="<cfoutput>#thisContentClass#</cfoutput>" style="width: 20%"> 
				<label for="mainContainerWidth">Main Panel Container Width:</label>
			</td>
			<td class="<cfoutput>#thisContentClass#</cfoutput>">
				<!--- We are passing: 35 as the adminInterfaceId, URL.optArgs is the themeId, URL.otherArgs is the theme image type, and URL.otherArgs1 is the current image being used. --->
				<cfoutput>
				<input type="number" id="mainContainerWidth" name="mainContainerWidth" min="50" max="80" step="1" value="#mainContainerWidth#" style="width: 20%" class="k-textbox" onChange="changeContainerWidth('mainContainerWidth');">% (left panel)
				</cfoutput>
			</td>
		  </tr>
		</cfif>	  
		  <!-- Border -->
		  <tr height="2px" class="containerWidths">
			  <td align="left" valign="top" colspan="<cfoutput>#thisColSpan#</cfoutput>" class="<cfoutput>#thisContentClass#</cfoutput>"></td>
		  </tr>
		  <cfsilent>
		  <!--- Set the class for alternating rows. --->
		  <!---After the first row, the content class should be the current class. --->
		  <cfset thisContentClass = HtmlUtilsObj.getKendoClass(thisContentClass)>
		  </cfsilent>
		  <tr height="1px" class="containerWidths">
			  <td align="left" valign="top" colspan="2" class="border <cfoutput>#thisContentClass#</cfoutput>"></td>
		  </tr>
		<cfif session.isMobile>
		  <tr valign="middle" class="containerWidths">
			<td class="<cfoutput>#thisContentClass#</cfoutput>" colspan="2">
				<label for="sideBarContainerWidth">Sidebar Container Width:</label>
			</td>
		   </tr>
		   <tr class="containerWidths">
			<td class="<cfoutput>#thisContentClass#</cfoutput>" colspan="2">
				<input type="number" id="sideBarContainerWidth" name="sideBarContainerWidth" min="20" max="50" step="1" value="<cfoutput>#sideBarContainerWidth#</cfoutput>" style="width: 20%" class="k-textbox" onChange="changeContainerWidth('sideBarContainerWidth');">% (right panel)  
			</td>
		  </tr>
		<cfelse><!---<cfif session.isMobile>--->
		  <tr class="containerWidths">
			<td align="right" class="<cfoutput>#thisContentClass#</cfoutput>" style="width: 20%"> 
				<label for="sideBarContainerWidth">Sidebar Container Width:</label>
			</td>
			<td class="<cfoutput>#thisContentClass#</cfoutput>">
				<input type="number" id="sideBarContainerWidth" name="sideBarContainerWidth" min="20" max="50" step="1" value="<cfoutput>#sideBarContainerWidth#</cfoutput>" style="width: 20%" class="k-textbox" onChange="changeContainerWidth('sideBarContainerWidth');">% (right panel)
			</td>
		  </tr>
		</cfif>	  
		  <!-- Border -->
		  <tr height="2px" class="containerWidths">
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
			<td align="left" class="<cfoutput>#thisContentClass#</cfoutput>" colspan="2"> 
				<p>Site Opacity allows the blog background image to 'bleed through' the containers on the blog. I often set the opacity level around 93% in order to allow the users to see a hint of the background image. For a cleaner look, you can set the opacity to 99% to eliminate the ghosting.</p>
			</td>
		  </tr>
		  <!-- Border -->
		  <tr height="2px">
			<td align="left" valign="top" colspan="<cfoutput>#thisColSpan#</cfoutput>" class="<cfoutput>#thisContentClass#</cfoutput>"></td>
		  </tr>
		<cfif session.isMobile>
		  <tr valign="middle">
			<td class="<cfoutput>#thisContentClass#</cfoutput>" colspan="2">
				<label for="siteOpacity">Site Opacity:</label>
			</td>
		   </tr>
		   <tr>
			<td class="<cfoutput>#thisContentClass#</cfoutput>" colspan="2">
				<input type="number" id="siteOpacity" name="siteOpacity" min="75" max="100" step="1" value="<cfoutput>#siteOpacity#</cfoutput>" class="k-textbox" style="width: 30%">%
			</td>
		  </tr>
		<cfelse><!---<cfif session.isMobile>--->
		  <tr>
			<td align="right" class="<cfoutput>#thisContentClass#</cfoutput>" style="width: 20%"> 
				<label for="siteOpacity">Site Opacity:</label>
			</td>
			<td class="<cfoutput>#thisContentClass#</cfoutput>">
				<input type="number" id="siteOpacity" name="siteOpacity" min="75" max="100" step="1" value="<cfoutput>#siteOpacity#</cfoutput>" class="k-textbox" style="width: 20%">%
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
						Themes Interface Backgrounds
	//************************************************************************************************--->
	<button type="button" class="collapsible k-header">Backgrounds</button>
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
			  <td align="left" valign="top" colspan="<cfoutput>#thisColSpan#</cfoutput>" class="border <cfoutput>#thisContentClass#</cfoutput>"></td>
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
				<label for="includeBackgroundImages">Include Background Images:</label>
			</td>
		   </tr>
		   <tr>
			<td class="<cfoutput>#thisContentClass#</cfoutput>" colspan="2">
				<table align="center" class="<cfoutput>#thisContentClass#</cfoutput>" width="100%" cellpadding="5" cellspacing="0" border="0">
					<tr>
						<td width="50%" align="left">
							<input id="includeBackgroundImages" name="includeBackgroundImages" type="radio" value="true" <cfif includeBackgroundImages gt 0>checked</cfif> class="normalFontWeight" onclick='javascript:$( ".includeBackgroundImages" ).show();$( ".backgroundColor" ).hide();'>
							<label for="includeBackgroundImages">yes</label>
						</td>
						<td width="50%" align="left">
							<input id="includeBackgroundImages" name="includeBackgroundImages" type="radio" value="false" <cfif includeBackgroundImages eq 0>checked</cfif> class="normalFontWeight" onclick='javascript:$( ".includeBackgroundImages" ).hide();$( ".backgroundColor" ).show();'>
							<label for="includeBackgroundImages">No</label>
						</td>
					</tr>
				</table>
			</td>
		  </tr>
		<cfelse><!---<cfif session.isMobile>--->
		  <tr>
			<td align="right" class="<cfoutput>#thisContentClass#</cfoutput>" style="width: 20%"> 
				<label for="includeBackgroundImages">Include Background Images:</label>
			</td>
			<td class="<cfoutput>#thisContentClass#</cfoutput>">
				<table align="center" class="<cfoutput>#thisContentClass#</cfoutput>" width="100%" cellpadding="5" cellspacing="0" border="0">
					<tr>
						<td width="50%" align="left">
							<input id="includeBackgroundImages" name="includeBackgroundImages" type="radio" value="true" <cfif includeBackgroundImages gt 0>checked</cfif> class="normalFontWeight" onclick='javascript:$( ".includeBackgroundImages" ).show();$( ".backgroundColor" ).hide();'>
							<label for="includeBackgroundImages">yes</label>
						</td>
						<td width="50%" align="left">
							<input id="includeBackgroundImages" name="includeBackgroundImages" type="radio" value="false" <cfif includeBackgroundImages eq 0>checked</cfif> class="normalFontWeight" onclick='javascript:$( ".includeBackgroundImages" ).hide();$( ".backgroundColor" ).show();'>
							<label for="includeBackgroundImages">No</label>
						</td>
					</tr>
				</table>
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
		  <tr height="2px" class="includeBackgroundImages">
			  <td align="left" valign="top" colspan="<cfoutput>#thisColSpan#</cfoutput>" class="border <cfoutput>#thisContentClass#</cfoutput>"></td>
		  </tr>
		<cfif session.isMobile>
		  <tr valign="middle" class="includeBackgroundImages">
			<td class="<cfoutput>#thisContentClass#</cfoutput>" colspan="2">
				<label for="blogBackgroundImage">Desktop Background:</label>
			</td>
		   </tr>
		   <tr class="includeBackgroundImages">
			<td class="<cfoutput>#thisContentClass#</cfoutput>" colspan="2">
				<cfoutput>
				<input type="text" id="blogBackgroundImage" name="blogBackgroundImage" value="#blogBackgroundImage#" class="k-textbox" style="width:95%" onclick="createAdminInterfaceWindow(35, #themeId#,'blogBackgroundImage','#blogBackgroundImage#');">
				</cfoutput>
			</td>
		  </tr>
		<cfelse><!---<cfif session.isMobile>--->
		  <tr class="includeBackgroundImages">
			<td align="right" class="<cfoutput>#thisContentClass#</cfoutput>" style="width: 20%"> 
				<label for="blogBackgroundImage">Desktop Background:</label>
			</td>
			<td class="<cfoutput>#thisContentClass#</cfoutput>">
				<cfoutput>
				<input type="text" id="blogBackgroundImage" name="blogBackgroundImage" value="#blogBackgroundImage#" class="k-textbox" style="width:75%" onclick="createAdminInterfaceWindow(35, #themeId#,'blogBackgroundImage','#blogBackgroundImage#');">
				</cfoutput>
			</td>
		  </tr>
		</cfif>
		  <!-- Border -->
		  <tr height="2px" class="includeBackgroundImages">
			  <td align="left" valign="top" colspan="<cfoutput>#thisColSpan#</cfoutput>" class="<cfoutput>#thisContentClass#</cfoutput>"></td>
		  </tr>
		  <cfsilent>
		  <!--- Set the class for alternating rows. --->
		  <!---After the first row, the content class should be the current class. --->
		  <cfset thisContentClass = HtmlUtilsObj.getKendoClass(thisContentClass)>
		  </cfsilent>
			  
		  <tr height="1px" class="includeBackgroundImages">
			  <td align="left" valign="top" colspan="2" class="border <cfoutput>#thisContentClass#</cfoutput>"></td>
		  </tr>
		<cfif session.isMobile>
		  <tr valign="middle" class="includeBackgroundImages">
			<td class="<cfoutput>#thisContentClass#</cfoutput>" colspan="2">
				<label for="blogBackgroundImageMobile">Mobile Blog Background:</label>compo
			</td>
		   </tr>
		   <tr class="includeBackgroundImages">
			<td class="<cfoutput>#thisContentClass#</cfoutput>" colspan="2">
				<!--- We are passing: 35 as the adminInterfaceId, URL.optArgs is the themeId, URL.otherArgs is the theme image type, and URL.otherArgs1 is the current image being used. --->
				<cfoutput>
				<input type="text" id="blogBackgroundImageMobile" name="blogBackgroundImageMobile" value="#blogBackgroundImageMobile#" class="k-textbox" style="width:95%" onclick="createAdminInterfaceWindow(35, #themeId#,'blogBackgroundImageMobile','#blogBackgroundImageMobile#');">
				</cfoutput>
			</td>
		  </tr>
		<cfelse><!---<cfif session.isMobile>--->
		  <tr class="includeBackgroundImages">
			<td align="right" class="<cfoutput>#thisContentClass#</cfoutput>" style="width: 20%"> 
				<label for="blogBackgroundImageMobile">Mobile Blog Background:</label>
			</td>
			<td class="<cfoutput>#thisContentClass#</cfoutput>">
				<!--- We are passing: 35 as the adminInterfaceId, URL.optArgs is the themeId, URL.otherArgs is the theme image type, and URL.otherArgs1 is the current image being used. --->
				<cfoutput>
				<input type="text" id="blogBackgroundImageMobile" name="blogBackgroundImageMobile" value="#blogBackgroundImageMobile#" class="k-textbox" style="width:75%" onclick="createAdminInterfaceWindow(35, #themeId#,'blogBackgroundImageMobile','#blogBackgroundImageMobile#');">
				</cfoutput>
			</td>
		  </tr>
		</cfif>	  
		  <!-- Border -->
		  <tr height="2px" class="includeBackgroundImages">
			  <td align="left" valign="top" colspan="<cfoutput>#thisColSpan#</cfoutput>" class="<cfoutput>#thisContentClass#</cfoutput>"></td>
		  </tr>
		  <cfsilent>
		  <!--- Set the class for alternating rows. --->
		  <!---After the first row, the content class should be the current class. --->
		  <cfset thisContentClass = HtmlUtilsObj.getKendoClass(thisContentClass)>
		  </cfsilent>
		  <tr height="1px" class="includeBackgroundImages">
			  <td align="left" valign="top" colspan="2" class="border <cfoutput>#thisContentClass#</cfoutput>"></td>
		  </tr>
		  <tr class="includeBackgroundImages">
			<td align="left" class="<cfoutput>#thisContentClass#</cfoutput>" colspan="2"> 
				The blog background position must contain css to position the background image on the page. This is useful if you want to nudge the image around page. See <a href="https://www.w3schools.com/cssref/pr_background-position.asp">https://www.w3schools.com/cssref/pr_background-position.asp</a> or search for the background-position css property for more information.
			</td>
		  </tr>
		<cfif session.isMobile>
		  <tr valign="middle" class="includeBackgroundImages">
			<td class="<cfoutput>#blogBackgroundImagePosition#</cfoutput>" colspan="2">
				<label for="blogBackgroundImagePosition">Blog Background Position:</label>
			</td>
		   </tr>
		   <tr class="includeBackgroundImages">
			<td class="<cfoutput>#thisContentClass#</cfoutput>" colspan="2">
				<input type="text" id="blogBackgroundImagePosition" name="blogBackgroundImagePosition" value="<cfoutput>#BlogBackgroundImagePosition#</cfoutput>" class="k-textbox">
			</td>
		  </tr>
		<cfelse><!---<cfif session.isMobile>--->
		  <tr class="includeBackgroundImages">
			<td align="right" class="<cfoutput>#thisContentClass#</cfoutput>" style="width: 20%"> 
				<label for="blogBackgroundImagePosition">Blog Background Position:</label>
			</td>
			<td class="<cfoutput>#thisContentClass#</cfoutput>">
				<input type="text" id="blogBackgroundImagePosition" name="blogBackgroundImagePosition" value="<cfoutput>#BlogBackgroundImagePosition#</cfoutput>" class="k-textbox">
			</td>
		  </tr>
		</cfif>	  
		  <cfsilent>
		  <!--- Set the class for alternating rows. --->
		  <!---After the first row, the content class should be the current class. --->
		  <cfset thisContentClass = HtmlUtilsObj.getKendoClass(thisContentClass)>
		  </cfsilent>
		  <tr height="1px" class="includeBackgroundImages">
			  <td align="left" valign="top" colspan="2" class="border <cfoutput>#thisContentClass#</cfoutput>"></td>
		  </tr>
		  <tr class="includeBackgroundImages">
			<td align="left" class="<cfoutput>#thisContentClass#</cfoutput>" colspan="2"> 
				The blog background image repeat must contain css determine how a small background image will be repeated if can't fit the dimensions of the page. You can create interesting checkered tile designs that consume very little resources. See <a href="https://www.w3schools.com/cssref/pr_background-repeat.asp">https://www.w3schools.com/cssref/pr_background-repeat.asp</a> or search the web for the background-repeat css property. Unless you're after a tile based design, its suggested to leave this setting at 'no-repeat'. 
			</td>
		  </tr>
		<cfif session.isMobile>
		  <tr valign="middle" class="includeBackgroundImages">
			<td class="<cfoutput>#thisContentClass#</cfoutput>" colspan="2">
				<label for="blogBackgroundImageRepeat">Blog Background Image Repeat:</label>
			</td>
		   </tr>
		   <tr class="includeBackgroundImages">
			<td class="<cfoutput>#thisContentClass#</cfoutput>" colspan="2">
				<input type="text" id="blogBackgroundImageRepeat" name="blogBackgroundImageRepeat" value="<cfoutput>#BlogBackgroundImageRepeat#</cfoutput>" class="k-textbox" style="width:95%">
			</td>
		  </tr>
		<cfelse><!---<cfif session.isMobile>--->
		  <tr class="includeBackgroundImages">
			<td align="right" class="<cfoutput>#thisContentClass#</cfoutput>" style="width: 20%"> 
				<label for="blogBackgroundImageRepeat">Blog Background Image Repeat:</label>
			</td>
			<td class="<cfoutput>#thisContentClass#</cfoutput>">
				<input type="text" id="blogBackgroundImageRepeat" name="blogBackgroundImageRepeat" value="<cfoutput>#BlogBackgroundImageRepeat#</cfoutput>" class="k-textbox">
			</td>
		  </tr>
		</cfif>  
		  <!-- Border -->
		  <tr height="2px" class="includeBackgroundImages">
			<td align="left" valign="top" colspan="<cfoutput>#thisColSpan#</cfoutput>" class="<cfoutput>#thisContentClass#</cfoutput>"></td>
		  </tr>
			  
		  <cfsilent>
		  <!--- Set the class for alternating rows. --->
		  <!---After the first row, the content class should be the current class. --->
		  <cfset thisContentClass = HtmlUtilsObj.getKendoClass(thisContentClass)>
		  </cfsilent>
		  <tr height="1px" class="backgroundColor">
			  <td align="left" valign="top" colspan="2" class="border <cfoutput>#thisContentClass#</cfoutput>"></td>
		  </tr>
		  <tr class="backgroundColor">
			<td colspan="2" class="<cfoutput>#thisContentClass#</cfoutput>"> 
				If you don't want to have a blog background, you can have a simple blog background color. 
			</td>
		  </tr>
			  
		  <!-- Border -->
		  <tr height="2px" class="backgroundColor">
			<td align="left" valign="top" colspan="<cfoutput>#thisColSpan#</cfoutput>" class="<cfoutput>#thisContentClass#</cfoutput>"></td>
		  </tr>
		  <tr height="1px" class="backgroundColor">
			  <td align="left" valign="top" colspan="2" class="<cfoutput>#thisContentClass#</cfoutput>"></td>
		  </tr>
		<cfif session.isMobile>
		  <tr valign="middle" class="backgroundColor">
			<td class="<cfoutput>#thisContentClass#</cfoutput>" colspan="2">
				<label for="blogBackgroundColor">Blog Background Color:</label>
			</td>
		   </tr>
		   <tr class="backgroundColor">
			<td class="<cfoutput>#thisContentClass#</cfoutput>" colspan="2">
				<input id="blogBackgroundColor" name="blogBackgroundColor" value="<cfoutput>#blogBackgroundColor#</cfoutput>">
			</td>
		  </tr>
		<cfelse><!---<cfif session.isMobile>--->
		  <tr class="backgroundColor">
			<td align="right" class="<cfoutput>#thisContentClass#</cfoutput>" style="width: 20%"> 
				<label for="blogBackgroundColor">Blog Background Color:</label>
			</td>
			<td class="<cfoutput>#thisContentClass#</cfoutput>">
				<input id="blogBackgroundColor" name="blogBackgroundColor" value="<cfoutput>#blogBackgroundColor#</cfoutput>">
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
						 Header
	//************************************************************************************************--->
				
	<button type="button" class="collapsible k-header">Page Header</button>
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
		  <tr>
			<td colspan="2"> 
				* Note: the Header Background Color is used to cover a portion of the header image when sending out email. It allows for the top portion of the page to be match the webpage and be highlighted with the logo.
			</td>
		  </tr>
		  <tr height="1px">
			  <td align="left" valign="top" colspan="2" class="<cfoutput>#thisContentClass#</cfoutput>"></td>
		  </tr>
		<cfif session.isMobile>
		  <tr valign="middle">
			<td class="<cfoutput>#thisContentClass#</cfoutput>" colspan="2">
				<label for="headerBackgroundColor">Header Background Color:</label>
			</td>
		   </tr>
		   <tr>
			<td class="<cfoutput>#thisContentClass#</cfoutput>" colspan="2">
				<input id="headerBackgroundColor" name="headerBackgroundColor">
			</td>
		  </tr>
		<cfelse><!---<cfif session.isMobile>--->
		  <tr>
			<td align="right" class="<cfoutput>#thisContentClass#</cfoutput>" style="width: 20%"> 
				<label for="headerBackgroundColor">Header Background Color:</label>
			</td>
			<td class="<cfoutput>#thisContentClass#</cfoutput>">
				<input id="headerBackgroundColor" name="headerBackgroundColor">
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
		  <tr>
			<td colspan="2" class="<cfoutput>#thisContentClass#</cfoutput>"> 
				The Header Background Image is at the top of the page and it covers the menu items. <i>If there is ghosting</i> on the menu after changing this, make sure to use the same image here as the Menu Background Image found in the Menu section below. This ghosting will only occur with headers that contain a gradient.
			</td>
		  </tr>
		  <tr height="1px">
			  <td align="left" valign="top" colspan="2" class="<cfoutput>#thisContentClass#</cfoutput>"></td>
		  </tr>
		<cfif session.isMobile>
		  <tr valign="middle">
			<td class="<cfoutput>#thisContentClass#</cfoutput>" colspan="2">
				<label for="headerBackgroundImage">Header Background Image:</label>
			</td>
		   </tr>
		   <tr>
			<td class="<cfoutput>#thisContentClass#</cfoutput>" colspan="2">
				<cfoutput>
				<input type="text" id="headerBackgroundImage" name="headerBackgroundImage" value="#headerBackgroundImage#" class="k-textbox" style="width:95%" onclick="createAdminInterfaceWindow(35, #themeId#,'headerBackgroundImage','#headerBackgroundImage#');">
				</cfoutput>
			</td>
		  </tr>
		<cfelse><!---<cfif session.isMobile>--->
		  <tr>
			<td align="right" class="<cfoutput>#thisContentClass#</cfoutput>" style="width: 20%"> 
				<label for="headerBackgroundImage">Header Background Image:</label>
			</td>
			<td class="<cfoutput>#thisContentClass#</cfoutput>">
				<cfoutput>
				<input type="text" id="headerBackgroundImage" name="headerBackgroundImage" value="#headerBackgroundImage#" class="k-textbox" style="width:95%" onclick="createAdminInterfaceWindow(35, #themeId#,'headerBackgroundImage','#headerBackgroundImage#');">
				</cfoutput>
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
				<label for="headerBodyDividerImage">Header Background Divider Image:</label>
			</td>
		   </tr>
		   <tr>
			<td class="<cfoutput>#thisContentClass#</cfoutput>" colspan="2">
				<cfoutput>
				<input type="text" id="headerBodyDividerImage" name="headerBodyDividerImage" value="#headerBodyDividerImage#" class="k-textbox" style="width:95%" onclick="createAdminInterfaceWindow(35, #themeId#,'headerBodyDividerImage','#headerBodyDividerImage#');">
				</cfoutput>
			</td>
		  </tr>
		<cfelse><!---<cfif session.isMobile>--->
		  <tr>
			<td align="right" class="<cfoutput>#thisContentClass#</cfoutput>" style="width: 20%"> 
				<label for="headerBodyDividerImage">Header Background Divider Image:</label>
			</td>
			<td class="<cfoutput>#thisContentClass#</cfoutput>">
				<cfoutput>
				<input type="text" id="headerBodyDividerImage" name="headerBodyDividerImage" value="#headerBodyDividerImage#" class="k-textbox" style="width:75%" onclick="createAdminInterfaceWindow(35, #themeId#,'headerBodyDividerImage','#headerBodyDividerImage#');">
				</cfoutput>
			</td>
		  </tr>
		</cfif>
		  <!-- Border -->
		  <tr height="2px">
			  <td align="left" valign="top" colspan="<cfoutput>#thisColSpan#</cfoutput>" class="<cfoutput>#thisContentClass#</cfoutput>"></td>
		  </tr>
			  
		  <tr height="1px">
			  <td align="left" valign="top" colspan="2" class="<cfoutput>#thisContentClass#</cfoutput>"></td>
		  </tr>
		<cfif session.isMobile>
		  <tr valign="middle">
			<td class="<cfoutput>#thisContentClass#</cfoutput>" colspan="2">
				<label for="stretchHeaderAcrossPage">Stretch Header Across Page:</label>
			</td>
		   </tr>
		   <tr>
			<td class="<cfoutput>#thisContentClass#</cfoutput>" colspan="2">
				<input type="checkbox" id="stretchHeaderAcrossPage" name="stretchHeaderAcrossPage" value="1"  <cfif stretchHeaderAcrossPage> checked</cfif>>
			</td>
		  </tr>
		<cfelse><!---<cfif session.isMobile>--->
		  <tr>
			<td align="right" class="<cfoutput>#thisContentClass#</cfoutput>" style="width: 20%"> 
				<label for="stretchHeaderAcrossPage">Stretch Header Across Page:</label>
			</td>
			<td class="<cfoutput>#thisContentClass#</cfoutput>">
				<input type="checkbox" id="stretchHeaderAcrossPage" name="stretchHeaderAcrossPage" value="1"  <cfif stretchHeaderAcrossPage> checked</cfif>>
			</td>
		  </tr>
		</cfif>  
		</table>
	</div>
				
	<!---//***********************************************************************************************
						Themes Interface Logos
	//************************************************************************************************--->
				
	<button type="button" class="collapsible k-header">Logo</button>
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
		<cfif session.isMobile>
		  <tr valign="middle">
			<td class="<cfoutput>#thisContentClass#</cfoutput>" colspan="2">
				<label for="logoImage">Desktop Logo:</label>
			</td>
		   </tr>
		   <tr>
			<td class="<cfoutput>#thisContentClass#</cfoutput>" colspan="2">
				<cfoutput>
				<input type="text" id="logoImage" name="logoImage" value="#logoImage#" class="k-textbox" style="width:95%" onclick="createAdminInterfaceWindow(35, #themeId#,'logoImage','#logoImage#');">
				</cfoutput>
			</td>
		  </tr>
		<cfelse><!---<cfif session.isMobile>--->
		  <tr>
			<td align="right" class="<cfoutput>#thisContentClass#</cfoutput>" style="width: 20%"> 
				<label for="logoImage">Desktop Logo:</label>
			</td>
			<td class="<cfoutput>#thisContentClass#</cfoutput>">
				<cfoutput>
				<input type="text" id="logoImage" name="logoImage" value="#logoImage#" class="k-textbox" style="width:75%" onclick="createAdminInterfaceWindow(35, #themeId#,'logoImage','#logoImage#');">
				</cfoutput>
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
				<label for="logoImageMobile">Mobile Logo:</label>
			</td>
		   </tr>
		   <tr>
			<td class="<cfoutput>#thisContentClass#</cfoutput>" colspan="2">
				<!--- We are passing: 35 as the adminInterfaceId, URL.optArgs is the themeId, URL.otherArgs is the theme image type, and URL.otherArgs1 is the current image being used. --->
				<cfoutput>
				<input type="text" id="logoImageMobile" name="logoImageMobile" value="#logoImageMobile#" class="k-textbox" style="width:95%" onclick="createAdminInterfaceWindow(35, #themeId#,'logoImageMobile','#logoImageMobile#');">
				</cfoutput>
			</td>
		  </tr>
		<cfelse><!---<cfif session.isMobile>--->
		  <tr>
			<td align="right" class="<cfoutput>#thisContentClass#</cfoutput>" style="width: 20%"> 
				<label for="logoImageMobile">Mobile Logo:</label>
			</td>
			<td class="<cfoutput>#thisContentClass#</cfoutput>">
				<!--- We are passing: 35 as the adminInterfaceId, URL.optArgs is the themeId, URL.otherArgs is the theme image type, and URL.otherArgs1 is the current image being used. --->
				<cfoutput>
				<input type="text" id="logoImageMobile" name="logoImageMobile" value="#logoImageMobile#" class="k-textbox" style="width:75%" onclick="createAdminInterfaceWindow(35, #themeId#,'logoImageMobile','#logoImageMobile#');">
				</cfoutput>
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
		  <tr>
			<td align="left" class="<cfoutput>#thisContentClass#</cfoutput>" colspan="2"> 
				What is the default image that you want shared to social media sites when you share a link to the root blog or create a post without a header image? This image should be larger than your site logo and is recommended to be 900x900 or 1200x1200. 
			</td>
		  </tr>
		  <!-- Border -->
		  <tr height="2px">
			  <td align="left" valign="top" colspan="<cfoutput>#thisColSpan#</cfoutput>" class="<cfoutput>#thisContentClass#</cfoutput>"></td>
		  </tr>
		<cfif session.isMobile>
		  <tr valign="middle">
			<td class="<cfoutput>#thisContentClass#</cfoutput>" colspan="2">
				<label for="defaultLogoImageForSocialMediaShare">Default Logo for Social Media:</label>
			</td>
		   </tr>
		   <tr>
			<td class="<cfoutput>#thisContentClass#</cfoutput>" colspan="2">
				<!--- We are passing: 35 as the adminInterfaceId, URL.optArgs is the themeId, URL.otherArgs is the theme image type, and URL.otherArgs1 is the current image being used. --->
				<cfoutput>
				<input type="text" id="defaultLogoImageForSocialMediaShare" name="defaultLogoImageForSocialMediaShare" value="#defaultLogoImageForSocialMediaShare#" class="k-textbox" style="width:95%" onclick="createAdminInterfaceWindow(35, #themeId#,'defaultLogoImageForSocialMediaShare','#defaultLogoImageForSocialMediaShare#');">
				</cfoutput>
			</td>
		  </tr>
		<cfelse><!---<cfif session.isMobile>--->
		  <tr>
			<td align="right" class="<cfoutput>#thisContentClass#</cfoutput>" style="width: 20%"> 
				<label for="defaultLogoImageForSocialMediaShare">Default Logo for Social Media:</label>
			</td>
			<td class="<cfoutput>#thisContentClass#</cfoutput>">
				<!--- We are passing: 35 as the adminInterfaceId, URL.optArgs is the themeId, URL.otherArgs is the theme image type, and URL.otherArgs1 is the current image being used. --->
				<cfoutput>
				<input type="text" id="defaultLogoImageForSocialMediaShare" name="defaultLogoImageForSocialMediaShare" value="#defaultLogoImageForSocialMediaShare#" class="k-textbox" style="width:75%" onclick="createAdminInterfaceWindow(35, #themeId#,'defaultLogoImageForSocialMediaShare','#defaultLogoImageForSocialMediaShare#');">
				</cfoutput>
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
				<label for="logoMobileWidth">Mobile Logo Width:</label>
			</td>
		   </tr>
		   <tr>
			<td class="<cfoutput>#thisContentClass#</cfoutput>" colspan="2">
				<input type="number" id="logoMobileWidth" name="logoMobileWidth" step="1" value="<cfoutput>#logoMobileWidth#</cfoutput>" class="k-textbox" style="width:25%">px
			</td>
		  </tr>
		<cfelse><!---<cfif session.isMobile>--->
		  <tr>
			<td align="right" class="<cfoutput>#thisContentClass#</cfoutput>" style="width: 20%"> 
				<label for="logoMobileWidth">Mobile Logo Width:</label>
			</td>
			<td class="<cfoutput>#thisContentClass#</cfoutput>">
				<input type="number" id="logoMobileWidth" name="logoMobileWidth" step="1" value="<cfoutput>#logoMobileWidth#</cfoutput>" class="k-textbox">px
			</td>
		  </tr>
		</cfif>	  
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
				<label for="logoPaddingLeft">Logo Padding Left:</label>
			</td>
		   </tr>
		   <tr>
			<td class="<cfoutput>#thisContentClass#</cfoutput>" colspan="2">
				<input type="number" id="logoPaddingLeft" name="logoPaddingLeft" min="0" step="1" value="<cfoutput>#logoPaddingLeft#</cfoutput>" class="k-textbox" style="width:25%">px
			</td>
		  </tr>
		<cfelse><!---<cfif session.isMobile>--->
		  <tr>
			<td align="right" class="<cfoutput>#thisContentClass#</cfoutput>" style="width: 20%"> 
				<label for="logoPaddingLeft">Logo Padding Left:</label>
			</td>
			<td class="<cfoutput>#thisContentClass#</cfoutput>">
				<input type="number" id="logoPaddingLeft" name="logoPaddingLeft" min="0" step="1" value="<cfoutput>#logoPaddingLeft#</cfoutput>" class="k-textbox">px
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
						Themes Interface Blog Title
	//************************************************************************************************--->
				
	<button type="button" class="collapsible k-header">Blog Title</button>
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
			  <td align="left" valign="top" colspan="2" class="border <cfoutput>#thisContentClass#</cfoutput>"></td>
		  </tr>
		<cfif session.isMobile>
		  <tr valign="middle">
			<td class="<cfoutput>#thisContentClass#</cfoutput>" colspan="2">
				<label for="displayBlogName">Display Blog Title:</label>
			</td>
		   </tr>
		   <tr>
			<td class="<cfoutput>#thisContentClass#</cfoutput>" colspan="2">
				<cfoutput>
				<input type="checkbox" id="displayBlogName" name="displayBlogName"<cfif displayBlogName> checked</cfif> value="1" />
				</cfoutput>
			</td>
		  </tr>
		<cfelse><!---<cfif session.isMobile>--->
		  <tr>
			<td align="right" class="<cfoutput>#thisContentClass#</cfoutput>" style="width: 20%"> 
				<label for="displayBlogName">Display Blog Title:</label>
			</td>
			<td class="<cfoutput>#thisContentClass#</cfoutput>">
				<cfoutput>
				<input type="checkbox" id="displayBlogName" name="displayBlogName"<cfif displayBlogName> checked</cfif> value="1" />
				</cfoutput>
			</td>
		  </tr>
		</cfif>
		  <!-- Border -->
		  <tr height="2px">
			  <td align="left" valign="top" colspan="<cfoutput>#thisColSpan#</cfoutput>" class="<cfoutput>#thisContentClass#</cfoutput>"></td>
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
				<label for="blogNameTextColor">Blog Title Text Color:</label>
			</td>
		   </tr>
		   <tr>
			<td class="<cfoutput>#thisContentClass#</cfoutput>" colspan="2">
				<cfoutput>
				<input id="blogNameTextColor" name="blogNameTextColor" value="#blogNameTextColor#">
				</cfoutput>
			</td>
		  </tr>
		<cfelse><!---<cfif session.isMobile>--->
		  <tr>
			<td align="right" class="<cfoutput>#thisContentClass#</cfoutput>" style="width: 20%"> 
				<label for="blogNameTextColor">Blog Title Text Color:</label>
			</td>
			<td class="<cfoutput>#thisContentClass#</cfoutput>">
				<cfoutput>
				<input id="blogNameTextColor" name="blogNameTextColor" value="#blogNameTextColor#">
				</cfoutput>
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
						Menu's
	//************************************************************************************************--->
				
	<button type="button" class="collapsible k-header">Menu</button>
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
			  <td align="left" valign="top" colspan="2" class="border <cfoutput>#thisContentClass#</cfoutput>"></td>
		  </tr>
		<cfif session.isMobile>
		  <tr valign="middle">
			<td class="<cfoutput>#thisContentClass#</cfoutput>" colspan="2">
				<label for="alignBlogMenuWithBlogContent">Align Menu with Blog Content:</label>
			</td>
		   </tr>
		   <tr>
			<td class="<cfoutput>#thisContentClass#</cfoutput>" colspan="2">
				<input type="checkbox" id="alignBlogMenuWithBlogContent" name="alignBlogMenuWithBlogContent" value="1"  <cfif alignBlogMenuWithBlogContent> checked</cfif>>
			</td>
		  </tr>
		<cfelse><!---<cfif session.isMobile>--->
		  <tr>
			<td align="right" class="<cfoutput>#thisContentClass#</cfoutput>" style="width: 20%"> 
				<label for="alignBlogMenuWithBlogContent">Align Menu with Blog Content:</label>
			</td>
			<td class="<cfoutput>#thisContentClass#</cfoutput>">
				<input type="checkbox" id="alignBlogMenuWithBlogContent" name="alignBlogMenuWithBlogContent" value="1"  <cfif alignBlogMenuWithBlogContent> checked</cfif>>
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
		  <tr>
			<td colspan="2"> 
				* The Menu Background Image is used to cover a portion of the header image when there is ghosting that occurs after changing the Header Background Image. This is generally not used unless there is a gradient on the header. It is advises to use the same image that you used for the menu backgound image to remove the ghosting.
			</td>
		  </tr>
		  <tr height="1px">
			  <td align="left" valign="top" colspan="2" class="<cfoutput>#thisContentClass#</cfoutput>"></td>
		  </tr>
		<cfif session.isMobile>
		  <tr valign="middle">
			<td class="<cfoutput>#thisContentClass#</cfoutput>" colspan="2">
				<label for="headerBackgroundImage">Menu Background Image:</label>
			</td>
		   </tr>
		   <tr>
			<td class="<cfoutput>#thisContentClass#</cfoutput>" colspan="2">
				<cfoutput>
				<input type="text" id="headerBackgroundImage" name="menuBackgroundImage" value="#menuBackgroundImage#" class="k-textbox" style="width:95%" onclick="createAdminInterfaceWindow(35, #themeId#,'menuBackgroundImage','#menuBackgroundImage#');">
				</cfoutput>
			</td>
		  </tr>
		<cfelse><!---<cfif session.isMobile>--->
		  <tr>
			<td align="right" class="<cfoutput>#thisContentClass#</cfoutput>" style="width: 20%"> 
				<label for="headerBackgroundImage">Menu Background Image:</label>
			</td>
			<td class="<cfoutput>#thisContentClass#</cfoutput>">
				<cfoutput>
				<input type="text" id="headerBackgroundImage" name="menuBackgroundImage" value="#menuBackgroundImage#" class="k-textbox" style="width:75%" onclick="createAdminInterfaceWindow(35, #themeId#,'menuBackgroundImage','#menuBackgroundImage#');">
				</cfoutput>
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
				<label for="coverKendoMenuWithMenuBackgroundImage">Cover Menu with Background Image:</label>
			</td>
		   </tr>
		   <tr>
			<td class="<cfoutput>#thisContentClass#</cfoutput>" colspan="2">
				<input type="checkbox" id="coverKendoMenuWithMenuBackgroundImage" name="coverKendoMenuWithMenuBackgroundImage" value="1"  <cfif coverKendoMenuWithMenuBackgroundImage> checked</cfif>>
			</td>
		  </tr>
		<cfelse><!---<cfif session.isMobile>--->
		  <tr>
			<td align="right" class="<cfoutput>#thisContentClass#</cfoutput>" style="width: 20%"> 
				<label for="coverKendoMenuWithMenuBackgroundImage">Cover Menu with Background Image:</label>
			</td>
			<td class="<cfoutput>#thisContentClass#</cfoutput>">
				<input type="checkbox" id="coverKendoMenuWithMenuBackgroundImage" name="coverKendoMenuWithMenuBackgroundImage" value="1"  <cfif coverKendoMenuWithMenuBackgroundImage> checked</cfif>>
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
				<label for="topMenuAlign">Top Menu Align:</label>
			</td>
		   </tr>
		   <tr>
			<td class="<cfoutput>#thisContentClass#</cfoutput>" colspan="2">
				<script>
					// create DropDownList from select HTML element
					$("#topMenuAlign").kendoDropDownList();
				</script>
				<select name="topMenuAlign" id="topMenuAlign">
					<option value="left"<cfif topMenuAlign eq 'left'> selected</cfif>>Left</option>
					<option value="center"<cfif topMenuAlign eq 'center'> selected</cfif>>Center</option>
					<option value="right"<cfif topMenuAlign eq 'right'> selected</cfif>>Right</option>
				</select>
			</td>
		  </tr>
		<cfelse><!---<cfif session.isMobile>--->
		  <tr>
			<td align="right" class="<cfoutput>#thisContentClass#</cfoutput>" style="width: 20%"> 
				<label for="topMenuAlign">Top Menu Align:</label>
			</td>
			<td class="<cfoutput>#thisContentClass#</cfoutput>">
				<script>
					// create DropDownList from select HTML element
					$("#topMenuAlign").kendoDropDownList();
				</script>
				<select name="topMenuAlign" id="topMenuAlign">
					<option value="left"<cfif topMenuAlign eq 'left'> selected</cfif>>Left</option>
					<option value="center"<cfif topMenuAlign eq 'center'> selected</cfif>>Center</option>
					<option value="right"<cfif topMenuAlign eq 'right'> selected</cfif>>Right</option>
				</select>
			</td>
		  </tr>
		</cfif>	  
		  <!-- Border -->
		  <tr height="2px">
			<td align="left" valign="top" colspan="<cfoutput>#thisColSpan#</cfoutput>" class="<cfoutput>#thisContentClass#</cfoutput>"></td>
		  </tr>
		<cfsilent>	
		<!---//***********************************************************************************************
							Navigation Menu
		//************************************************************************************************--->
				
		<!--- This logic is easily reproducable with a small number of variables. Set them here. --->
		<cfset contentTemplateStr = "navigationMenu">
		<cfset contentTemplateLabel = "Navigation Menu">
		<cfset entityId = "ThemeId">
		<cfset entityName = "ThemeName">
		<cfset useEnableButton = true>
		
		<!--- 
		You need to enter the description and editor links manually.
		The link to the
		tinyMce editor is: createAdminInterfaceWindow(53,<cfoutput>#themeId#</cfoutput>,'<cfoutput>#contentTemplateStr#</cfoutput>Desktop',false)
		codeMirror editor is: createAdminInterfaceWindow(52,<cfoutput>#themeId#</cfoutput>,'compositeHeaderDesktop',false)
		--->
			
		<!--- Set the class for alternating rows. --->
		<!---The first content class in the table should be empty. --->
		<cfset thisContentClass = HtmlUtilsObj.getKendoClass('')>
		 </cfsilent>
		 <tr height="1px">
			  <td align="left" valign="top" colspan="2" class="<cfoutput>#thisContentClass#</cfoutput> setting-title"><b>Navigation Menu</b></td>
		 </tr>
		 <tr height="1px">
			  <td align="left" valign="top" colspan="2" class="<cfoutput>#thisContentClass#</cfoutput>"></td>
		  </tr>
		  <tr>
			<td colspan="2"> 
				The menu script uses a traditional unordered HTML list to render. To create a secondary menu, create a list within a list as you would creating indented bullets.
			</td>
		  </tr>
		  <tr height="1px">
			  <td align="left" valign="top" colspan="2" class="<cfoutput>#thisContentClass#</cfoutput>"></td>
		  </tr>
		<cfif useEnableButton>
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
				<label for="<cfoutput>#contentTemplateStr#</cfoutput>Enable">Enable:</label>
			</td>
		   </tr>
		   <tr>
			<td class="<cfoutput>#thisContentClass#</cfoutput>" colspan="2">
				<input type="checkbox" id="<cfoutput>#contentTemplateStr#</cfoutput>Enable" name="<cfoutput>#contentTemplateStr#</cfoutput>Enable" checked>
			</td>
		  </tr>
		<cfelse><!---<cfif session.isMobile>--->
		  <tr>
			<td align="right" class="<cfoutput>#thisContentClass#</cfoutput>" style="width: 20%"> 
				<label for="<cfoutput>#contentTemplateStr#</cfoutput>Enable">Enable:</label>
			</td>
			<td class="<cfoutput>#thisContentClass#</cfoutput>">
				<input type="checkbox" id="<cfoutput>#contentTemplateStr#</cfoutput>Enable" name="<cfoutput>#contentTemplateStr#</cfoutput>Enable" checked>
			</td>
		  </tr>
		</cfif><!---<cfif session.isMobile>--->	
		</cfif><!---<cfif useEnableButton>--->
		  <cfsilent>
		  <!--- Set the class for alternating rows. --->
		  <!---After the first row, the content class should be the current class. --->
		  <cfset thisContentClass = HtmlUtilsObj.getKendoClass(thisContentClass)>
		  </cfsilent>
		  <tr height="1px">
			  <td align="left" valign="top" colspan="2" class="border <cfoutput>#thisContentClass#</cfoutput>"></td>
		  </tr>
	
		<!--- Desktop header code (for both mobile and desktop devices) --->
		<cfif session.isMobile>
		  <tr valign="middle">
			<td class="<cfoutput>#thisContentClass#</cfoutput>" colspan="2">
				<label for="<cfoutput>#contentTemplateStr#</cfoutput>Desktop"><cfoutput>#contentTemplateLabel#</cfoutput> Desktop:</label>
			</td>
		   </tr>
		   <tr>
			<td class="<cfoutput>#thisContentClass#</cfoutput>" colspan="2">
				<!-- Editor -->
				<!--- Link to tinyMce editor: createAdminInterfaceWindow(53,themeId,'template',isMobile) --->
				<button id="<cfoutput>#contentTemplateStr#</cfoutput>DesktopButton" name="<cfoutput>#contentTemplateStr#</cfoutput>DesktopButton" class="k-button k-primary" type="button" onClick="createAdminInterfaceWindow(53,<cfoutput>#themeId#</cfoutput>,'<cfoutput>#contentTemplateStr#</cfoutput>Desktop',false);">Edit</button>
				
			</td>
		  </tr>
		<cfelse><!---<cfif session.isMobile>--->
		  <tr>
			<td align="right" class="<cfoutput>#thisContentClass#</cfoutput>" style="width: 20%"> 
				<label for="<cfoutput>#contentTemplateStr#</cfoutput>Desktop"><cfoutput>#contentTemplateLabel#</cfoutput> Desktop:</label>
			</td>
			<td class="<cfoutput>#thisContentClass#</cfoutput>">
				<!-- Editor -->
				<!--- Link to tinyMce editor: createAdminInterfaceWindow(53,themeId,'template',isMobile) --->
				<button id="<cfoutput>#contentTemplateStr#</cfoutput>DesktopButton" name="<cfoutput>#contentTemplateStr#</cfoutput>DesktopButton" class="k-button k-primary" type="button" onClick="createAdminInterfaceWindow(53,<cfoutput>#themeId#</cfoutput>,'<cfoutput>#contentTemplateStr#</cfoutput>Desktop',false);">Edit</button>
			</td>
		  </tr>
		</cfif>
		  <!--- Mobile header code (for both mobile and desktop devices) --->
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
				<label for="<cfoutput>#contentTemplateStr#</cfoutput>Mobile"><cfoutput>#contentTemplateLabel#</cfoutput> Mobile:</label>
			</td>
		   </tr>
		   <tr>
			<td class="<cfoutput>#thisContentClass#</cfoutput>" colspan="2">
				<!-- Editor -->
				<!--- Link to tinyMce editor: createAdminInterfaceWindow(53,themeId,'template',isMobile) --->
				<button id="<cfoutput>#contentTemplateStr#</cfoutput>DesktopButton" name="<cfoutput>#contentTemplateStr#</cfoutput>MobileButton" class="k-button k-primary" type="button" onClick="createAdminInterfaceWindow(53,<cfoutput>#themeId#</cfoutput>,'<cfoutput>#contentTemplateStr#</cfoutput>Mobile',true);">Edit</button>
			</td>

		  </tr>
		<cfelse><!---<cfif session.isMobile>--->
		  <tr>
			<td align="right" class="<cfoutput>#thisContentClass#</cfoutput>" style="width: 20%"> 
				<label for="<cfoutput>#contentTemplateStr#</cfoutput>Mobile"><cfoutput>#contentTemplateLabel#</cfoutput> Mobile</label>
			</td>
			<td class="<cfoutput>#thisContentClass#</cfoutput>">
				<!-- Editor -->
				<!--- Link to tinyMce editor: createAdminInterfaceWindow(53,themeId,'template',isMobile) --->
				<button id="<cfoutput>#contentTemplateStr#</cfoutput>MobileButton" name="<cfoutput>#contentTemplateStr#</cfoutput>MobileButton" class="k-button k-primary" type="button" onClick="createAdminInterfaceWindow(53,<cfoutput>#themeId#</cfoutput>,'<cfoutput>#contentTemplateStr#</cfoutput>Mobile',true);">Edit</button>
			</td>
		  </tr>
		</cfif> 
		</table>
	</div>
			
	<!---//***********************************************************************************************
						Windows
	//************************************************************************************************--->
			
	<button type="button" class="collapsible k-header">About & Bio Window Content</button>
	<cfsilent>
		<!--- This logic is easily reproducable with a small number of variables. Set them here. --->
		<cfset contentTemplateStr = "aboutWindow">
		<cfset contentTemplateLabel = "About Window">
		<cfset entityId = "ThemeId">
		<cfset entityName = "ThemeName">
		<cfset useEnableButton = true>
		<!--- You need to enter the description manually --->			
	</cfsilent>		
	<div class="content k-content">
		
		<table align="center" class="k-content" width="100%" cellpadding="2" cellspacing="0">
		  <cfsilent>
		  <!--- Set the class for alternating rows. --->
		  <!---The first content class in the table should be empty. --->
		  <cfset thisContentClass = HtmlUtilsObj.getKendoClass('')>
		  </cfsilent> 
		 <tr height="1px">
			  <td align="left" valign="top" colspan="2" class="<cfoutput>#thisContentClass#</cfoutput> setting-title"><b>About Window</b></td>
		 </tr>
		 <tr height="1px">
			  <td align="left" valign="top" colspan="2" class="border <cfoutput>#thisContentClass#</cfoutput>"></td>
		  </tr>
		  <tr>
			<td colspan="2"> 
				The about window is invoked via the menu at the top of the page. This window is optional and may be disabled by unchecking the enable checkbox below.
			</td>
		  </tr>
		  <tr height="1px">
			  <td align="left" valign="top" colspan="2" class="<cfoutput>#thisContentClass#</cfoutput>"></td>
		  </tr>
		<cfif useEnableButton>
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
				<label for="<cfoutput>#contentTemplateStr#</cfoutput>Enable">Enable:</label>
			</td>
		   </tr>
		   <tr>
			<td class="<cfoutput>#thisContentClass#</cfoutput>" colspan="2">
				<input type="checkbox" id="<cfoutput>#contentTemplateStr#</cfoutput>Enable" name="<cfoutput>#contentTemplateStr#</cfoutput>Enable" checked>
			</td>
		  </tr>
		<cfelse><!---<cfif session.isMobile>--->
		  <tr>
			<td align="right" class="<cfoutput>#thisContentClass#</cfoutput>" style="width: 20%"> 
				<label for="<cfoutput>#contentTemplateStr#</cfoutput>Enable">Enable:</label>
			</td>
			<td class="<cfoutput>#thisContentClass#</cfoutput>">
				<input type="checkbox" id="<cfoutput>#contentTemplateStr#</cfoutput>Enable" name="<cfoutput>#contentTemplateStr#</cfoutput>Enable" checked>
			</td>
		  </tr>
		</cfif><!---<cfif session.isMobile>--->	
		</cfif><!---<cfif useEnableButton>--->
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
	
		<!--- Desktop header code (for both mobile and desktop devices) --->
		<cfif session.isMobile>
		  <tr valign="middle">
			<td class="<cfoutput>#thisContentClass#</cfoutput>" colspan="2">
				<label for="<cfoutput>#contentTemplateStr#</cfoutput>Desktop"><cfoutput>#contentTemplateLabel#</cfoutput> Desktop:</label>
			</td>
		   </tr>
		   <tr>
			<td class="<cfoutput>#thisContentClass#</cfoutput>" colspan="2">
				<!-- Editor -->
				<!--- Link to tinyMce editor: createAdminInterfaceWindow(53,themeId,'template',isMobile) --->
				<button id="<cfoutput>#contentTemplateStr#</cfoutput>DesktopButton" name="<cfoutput>#contentTemplateStr#</cfoutput>DesktopButton" class="k-button k-primary" type="button" onClick="createAdminInterfaceWindow(53,<cfoutput>#themeId#</cfoutput>,'<cfoutput>#contentTemplateStr#</cfoutput>Desktop',false);">Edit</button>
				
			</td>
		  </tr>
		<cfelse><!---<cfif session.isMobile>--->
		  <tr>
			<td align="right" class="<cfoutput>#thisContentClass#</cfoutput>" style="width: 20%"> 
				<label for="<cfoutput>#contentTemplateStr#</cfoutput>Desktop"><cfoutput>#contentTemplateLabel#</cfoutput> Desktop:</label>
			</td>
			<td class="<cfoutput>#thisContentClass#</cfoutput>">
				<!-- Editor -->
				<!--- Link to tinyMce editor: createAdminInterfaceWindow(53,themeId,'template',isMobile) --->
				<button id="<cfoutput>#contentTemplateStr#</cfoutput>DesktopButton" name="<cfoutput>#contentTemplateStr#</cfoutput>DesktopButton" class="k-button k-primary" type="button" onClick="createAdminInterfaceWindow(53,<cfoutput>#themeId#</cfoutput>,'<cfoutput>#contentTemplateStr#</cfoutput>Desktop',false);">Edit</button>
			</td>
		  </tr>
		</cfif>
		  <!--- Mobile header code (for both mobile and desktop devices) --->
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
				<label for="<cfoutput>#contentTemplateStr#</cfoutput>Mobile"><cfoutput>#contentTemplateLabel#</cfoutput> Mobile:</label>
			</td>
		   </tr>
		   <tr>
			<td class="<cfoutput>#thisContentClass#</cfoutput>" colspan="2">
				<!-- Editor -->
				<!--- Link to tinyMce editor: createAdminInterfaceWindow(53,themeId,'template',isMobile) --->
				<button id="<cfoutput>#contentTemplateStr#</cfoutput>MobileButton" name="<cfoutput>#contentTemplateStr#</cfoutput>MobileButton" class="k-button k-primary" type="button" onClick="createAdminInterfaceWindow(53,<cfoutput>#themeId#</cfoutput>,'<cfoutput>#contentTemplateStr#</cfoutput>Mobile',true);">Edit</button>
			</td>

		  </tr>
		<cfelse><!---<cfif session.isMobile>--->
		  <tr>
			<td align="right" class="<cfoutput>#thisContentClass#</cfoutput>" style="width: 20%"> 
				<label for="<cfoutput>#contentTemplateStr#</cfoutput>Mobile"><cfoutput>#contentTemplateLabel#</cfoutput> Mobile</label>
			</td>
			<td class="<cfoutput>#thisContentClass#</cfoutput>">
				<!-- Editor -->
				<!--- Link to tinyMce editor: createAdminInterfaceWindow(53,themeId,'template',isMobile) --->
				<button id="<cfoutput>#contentTemplateStr#</cfoutput>MobileButton" name="<cfoutput>#contentTemplateStr#</cfoutput>MobileButton" class="k-button k-primary" type="button" onClick="createAdminInterfaceWindow(53,<cfoutput>#themeId#</cfoutput>,'<cfoutput>#contentTemplateStr#</cfoutput>Mobile',true);">Edit</button>
			</td>
		  </tr>
		</cfif><!---<cfif session.isMobile>--->
		<cfsilent>		
		<!---//***********************************************************************************************
							Bio Window
		//************************************************************************************************--->
			
		<!--- This logic is easily reproducable with a small number of variables. Set them here. --->
		<cfset contentTemplateStr = "bioWindow">
		<cfset contentTemplateLabel = "Biography Window">
		<cfset entityId = "ThemeId">
		<cfset entityName = "ThemeName">
		<cfset useEnableButton = true>
		<!--- You need to enter the description manually --->
	
		  <!--- Set the class for alternating rows. --->
		  <!---After the first row, the content class should be the current class. --->
		  <cfset thisContentClass = HtmlUtilsObj.getKendoClass(thisContentClass)>
		 </cfsilent> 
		 <tr height="1px">
			  <td align="left" valign="top" colspan="2" class="border <cfoutput>#thisContentClass#</cfoutput>"></td>
		 </tr>
		 <tr height="1px">
			  <td align="left" valign="top" colspan="2" class="<cfoutput>#thisContentClass#</cfoutput> setting-title"><b>Biography Window</b></td>
		 </tr>
		 <tr height="1px">
			  <td align="left" valign="top" colspan="2" class="border <cfoutput>#thisContentClass#</cfoutput>"></td>
		  </tr>
		
		  <tr>
			<td colspan="2" class="<cfoutput>#thisContentClass#</cfoutput>"> 
				The biography window is invoked using the menu at the top of the site. Each user may have their own biography that is entered in the users interface, however, this window is available on all pages of the site. This is an optional element and can be disabled.
			</td>
		  </tr>
		  <tr height="1px">
			  <td align="left" valign="top" colspan="2" class="<cfoutput>#thisContentClass#</cfoutput>"></td>
		  </tr>
		<cfif useEnableButton>
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
				<label for="<cfoutput>#contentTemplateStr#</cfoutput>Enable">Enable:</label>
			</td>
		   </tr>
		   <tr>
			<td class="<cfoutput>#thisContentClass#</cfoutput>" colspan="2">
				<input type="checkbox" id="<cfoutput>#contentTemplateStr#</cfoutput>Enable" name="<cfoutput>#contentTemplateStr#</cfoutput>Enable" checked>
			</td>
		  </tr>
		<cfelse><!---<cfif session.isMobile>--->
		  <tr>
			<td align="right" class="<cfoutput>#thisContentClass#</cfoutput>" style="width: 20%"> 
				<label for="<cfoutput>#contentTemplateStr#</cfoutput>Enable">Enable:</label>
			</td>
			<td class="<cfoutput>#thisContentClass#</cfoutput>">
				<input type="checkbox" id="<cfoutput>#contentTemplateStr#</cfoutput>Enable" name="<cfoutput>#contentTemplateStr#</cfoutput>Enable" checked>
			</td>
		  </tr>
		</cfif><!---<cfif session.isMobile>--->	
		</cfif><!---<cfif useEnableButton>--->
		  <cfsilent>
		  <!--- Set the class for alternating rows. --->
		  <!---After the first row, the content class should be the current class. --->
		  <cfset thisContentClass = HtmlUtilsObj.getKendoClass(thisContentClass)>
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
	
		<!--- Desktop header code (for both mobile and desktop devices) --->
		<cfif session.isMobile>
		  <tr valign="middle">
			<td class="<cfoutput>#thisContentClass#</cfoutput>" colspan="2">
				<label for="<cfoutput>#contentTemplateStr#</cfoutput>Desktop"><cfoutput>#contentTemplateLabel#</cfoutput> Desktop:</label>
			</td>
		   </tr>
		   <tr>
			<td class="<cfoutput>#thisContentClass#</cfoutput>" colspan="2">
				<!-- Editor -->
				<!--- Link to tinyMce editor: createAdminInterfaceWindow(53,themeId,'template',isMobile) --->
				<button id="<cfoutput>#contentTemplateStr#</cfoutput>DesktopButton" name="<cfoutput>#contentTemplateStr#</cfoutput>DesktopButton" class="k-button k-primary" type="button" onClick="createAdminInterfaceWindow(53,<cfoutput>#themeId#</cfoutput>,'<cfoutput>#contentTemplateStr#</cfoutput>Desktop',false);">Edit</button>
				
			</td>
		  </tr>
		<cfelse><!---<cfif session.isMobile>--->
		  <tr>
			<td align="right" class="<cfoutput>#thisContentClass#</cfoutput>" style="width: 20%"> 
				<label for="<cfoutput>#contentTemplateStr#</cfoutput>Desktop"><cfoutput>#contentTemplateLabel#</cfoutput> Desktop:</label>
			</td>
			<td class="<cfoutput>#thisContentClass#</cfoutput>">
				<!-- Editor -->
				<!--- Link to tinyMce editor: createAdminInterfaceWindow(53,themeId,'template',isMobile) --->
				<button id="<cfoutput>#contentTemplateStr#</cfoutput>DesktopButton" name="<cfoutput>#contentTemplateStr#</cfoutput>DesktopButton" class="k-button k-primary" type="button" onClick="createAdminInterfaceWindow(53,<cfoutput>#themeId#</cfoutput>,'<cfoutput>#contentTemplateStr#</cfoutput>Desktop',false);">Edit</button>
			</td>
		  </tr>
		</cfif>
		  <!--- Mobile header code (for both mobile and desktop devices) --->
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
				<label for="<cfoutput>#contentTemplateStr#</cfoutput>Mobile"><cfoutput>#contentTemplateLabel#</cfoutput> Mobile:</label>
			</td>
		   </tr>
		   <tr>
			<td class="<cfoutput>#thisContentClass#</cfoutput>" colspan="2">
				<!-- Editor -->
				<!--- Link to tinyMce editor: createAdminInterfaceWindow(53,themeId,'template',isMobile) --->
				<button id="<cfoutput>#contentTemplateStr#</cfoutput>DesktopButton" name="<cfoutput>#contentTemplateStr#</cfoutput>MobileButton" class="k-button k-primary" type="button" onClick="createAdminInterfaceWindow(53,<cfoutput>#themeId#</cfoutput>,'<cfoutput>#contentTemplateStr#</cfoutput>Mobile',true);">Edit</button>
			</td>

		  </tr>
		<cfelse><!---<cfif session.isMobile>--->
		  <tr>
			<td align="right" class="<cfoutput>#thisContentClass#</cfoutput>" style="width: 20%"> 
				<label for="<cfoutput>#contentTemplateStr#</cfoutput>Mobile"><cfoutput>#contentTemplateLabel#</cfoutput> Mobile</label>
			</td>
			<td class="<cfoutput>#thisContentClass#</cfoutput>">
				<!-- Editor -->
				<!--- Link to tinyMce editor: createAdminInterfaceWindow(53,themeId,'template',isMobile) --->
				<button id="<cfoutput>#contentTemplateStr#</cfoutput>MobileButton" name="<cfoutput>#contentTemplateStr#</cfoutput>MobileButton" class="k-button k-primary" type="button" onClick="createAdminInterfaceWindow(53,<cfoutput>#themeId#</cfoutput>,'<cfoutput>#contentTemplateStr#</cfoutput>Mobile',true);">Edit</button>
			</td>
		  </tr>
		</cfif><!---<cfif session.isMobile>--->
		<cfsilent>
		<!---//***********************************************************************************************
							Download Window
		//************************************************************************************************--->
	
		<!--- This logic is easily reproducable with a small number of variables. Set them here. --->
		<cfset contentTemplateStr = "downloadWindow">
		<cfset contentTemplateLabel = "Download Window">
		<cfset entityId = "ThemeId">
		<cfset entityName = "ThemeName">
		<cfset useEnableButton = true>
		<!--- You need to enter the description manually --->

		</cfsilent>
			
		<cfsilent>
		  <!--- Set the class for alternating rows. --->
		  <!---After the first row, the content class should be the current class. --->
		  <cfset thisContentClass = HtmlUtilsObj.getKendoClass(thisContentClass)>
		  </cfsilent>
		  <tr height="1px">
			  <td align="left" valign="top" colspan="2" class="border <cfoutput>#thisContentClass#</cfoutput>"></td>
		  </tr>	
		 <tr height="1px">
			  <td align="left" valign="top" colspan="2" class="<cfoutput>#thisContentClass#</cfoutput> setting-title"><b>Download Window</b></td>
		 </tr>
		 <tr height="1px">
			  <td align="left" valign="top" colspan="2" class="border <cfoutput>#thisContentClass#</cfoutput>"></td>
		  </tr>
		  <tr>
			<td colspan="2" class="<cfoutput>#thisContentClass#</cfoutput>"> 
				The download window opens up via the navigation script at the top of the site. There is a download pod on the left side of the page when the user clicks on the hamburger icon, however, this download window is also available on every page within the site. This is an optional window and can be disabled by unchecking the enable button below.
			</td>
		  </tr>
		  <tr height="1px">
			  <td align="left" valign="top" colspan="2" class="<cfoutput>#thisContentClass#</cfoutput>"></td>
		  </tr>
		<cfif useEnableButton>
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
				<label for="<cfoutput>#contentTemplateStr#</cfoutput>Enable">Enable:</label>
			</td>
		   </tr>
		   <tr>
			<td class="<cfoutput>#thisContentClass#</cfoutput>" colspan="2">
				<input type="checkbox" id="<cfoutput>#contentTemplateStr#</cfoutput>Enable" name="<cfoutput>#contentTemplateStr#</cfoutput>Enable" checked>
			</td>
		  </tr>
		<cfelse><!---<cfif session.isMobile>--->
		  <tr>
			<td align="right" class="<cfoutput>#thisContentClass#</cfoutput>" style="width: 20%"> 
				<label for="<cfoutput>#contentTemplateStr#</cfoutput>Enable">Enable:</label>
			</td>
			<td class="<cfoutput>#thisContentClass#</cfoutput>">
				<input type="checkbox" id="<cfoutput>#contentTemplateStr#</cfoutput>Enable" name="<cfoutput>#contentTemplateStr#</cfoutput>Enable" checked>
			</td>
		  </tr>
		</cfif><!---<cfif session.isMobile>--->	
		</cfif><!---<cfif useEnableButton>--->
		  
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
	
		<!--- Desktop header code (for both mobile and desktop devices) --->
		<cfif session.isMobile>
		  <tr valign="middle">
			<td class="<cfoutput>#thisContentClass#</cfoutput>" colspan="2">
				<label for="<cfoutput>#contentTemplateStr#</cfoutput>Desktop"><cfoutput>#contentTemplateLabel#</cfoutput> Desktop:</label>
			</td>
		   </tr>
		   <tr>
			<td class="<cfoutput>#thisContentClass#</cfoutput>" colspan="2">
				<!-- Editor -->
				<!--- Link to tinyMce editor: createAdminInterfaceWindow(53,themeId,'template',isMobile) --->
				<button id="<cfoutput>#contentTemplateStr#</cfoutput>DesktopButton" name="<cfoutput>#contentTemplateStr#</cfoutput>DesktopButton" class="k-button k-primary" type="button" onClick="createAdminInterfaceWindow(53,<cfoutput>#themeId#</cfoutput>,'<cfoutput>#contentTemplateStr#</cfoutput>Desktop',false);">Edit</button>
				
			</td>
		  </tr>
		<cfelse><!---<cfif session.isMobile>--->
		  <tr>
			<td align="right" class="<cfoutput>#thisContentClass#</cfoutput>" style="width: 20%"> 
				<label for="<cfoutput>#contentTemplateStr#</cfoutput>Desktop"><cfoutput>#contentTemplateLabel#</cfoutput> Desktop:</label>
			</td>
			<td class="<cfoutput>#thisContentClass#</cfoutput>">
				<!-- Editor -->
				<!--- Link to tinyMce editor: createAdminInterfaceWindow(53,themeId,'template',isMobile) --->
				<button id="<cfoutput>#contentTemplateStr#</cfoutput>DesktopButton" name="<cfoutput>#contentTemplateStr#</cfoutput>DesktopButton" class="k-button k-primary" type="button" onClick="createAdminInterfaceWindow(53,<cfoutput>#themeId#</cfoutput>,'<cfoutput>#contentTemplateStr#</cfoutput>Desktop',false);">Edit</button>
			</td>
		  </tr>
		</cfif><!---<cfif session.isMobile>--->
		  <!--- Mobile header code (for both mobile and desktop devices) --->
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
				<label for="<cfoutput>#contentTemplateStr#</cfoutput>Mobile"><cfoutput>#contentTemplateLabel#</cfoutput> Mobile:</label>
			</td>
		   </tr>
		   <tr>
			<td class="<cfoutput>#thisContentClass#</cfoutput>" colspan="2">
				<!-- Editor -->
				<!--- Link to tinyMce editor: createAdminInterfaceWindow(53,themeId,'template',isMobile) --->
				<button id="<cfoutput>#contentTemplateStr#</cfoutput>DesktopButton" name="<cfoutput>#contentTemplateStr#</cfoutput>MobileButton" class="k-button k-primary" type="button" onClick="createAdminInterfaceWindow(53,<cfoutput>#themeId#</cfoutput>,'<cfoutput>#contentTemplateStr#</cfoutput>Mobile',true);">Edit</button>
			</td>

		  </tr>
		<cfelse><!---<cfif session.isMobile>--->
		  <tr>
			<td align="right" class="<cfoutput>#thisContentClass#</cfoutput>" style="width: 20%"> 
				<label for="<cfoutput>#contentTemplateStr#</cfoutput>Mobile"><cfoutput>#contentTemplateLabel#</cfoutput> Mobile</label>
			</td>
			<td class="<cfoutput>#thisContentClass#</cfoutput>">
				<!-- Editor -->
				<!--- Link to tinyMce editor: createAdminInterfaceWindow(53,themeId,'template',isMobile) --->
				<button id="<cfoutput>#contentTemplateStr#</cfoutput>MobileButton" name="<cfoutput>#contentTemplateStr#</cfoutput>MobileButton" class="k-button k-primary" type="button" onClick="createAdminInterfaceWindow(53,<cfoutput>#themeId#</cfoutput>,'<cfoutput>#contentTemplateStr#</cfoutput>Mobile',true);">Edit</button>
			</td>
		  </tr>
		</cfif> 
		</table>
	</div>
			
	<!---//***********************************************************************************************
						Pod Content
	//************************************************************************************************--->
			
	<button type="button" class="collapsible k-header">Pod Content</button>
	<cfsilent>
		<!--- This logic is easily reproducable with a small number of variables. Set them here. --->
		<cfset contentTemplateStr = "downloadPod">
		<cfset contentTemplateLabel = "Download Pod">
		<cfset entityId = "ThemeId">
		<cfset entityName = "ThemeName">
		<cfset useEnableButton = true>
		<!--- You need to enter the description manually --->			
	</cfsilent>		
	<div class="content k-content">
		
		<table align="center" class="k-content" width="100%" cellpadding="2" cellspacing="0">
		  <cfsilent>
		  <!--- Set the class for alternating rows. --->
		  <!--- The first row should be blank --->
		  <cfset thisContentClass = HtmlUtilsObj.getKendoClass('')>
		  </cfsilent> 
		  <tr height="1px">
			  <td align="left" valign="top" colspan="2" class="<cfoutput>#thisContentClass#</cfoutput> setting-title"><b>Download Pod</b></td>
		  </tr>
		  <tr height="1px">
			  <td align="left" valign="top" colspan="2" class="border <cfoutput>#thisContentClass#</cfoutput>"></td>
		  </tr>
		  <tr>
			<td colspan="2"> 
				The default download pod opens up on the left side of the when the user clicks on the hamburger icon. This pod can be redesigned to fit your needs. This optional pod can also be disabled by unchecking the enable button below.
			</td>
		  </tr>
		  <tr height="1px">
			  <td align="left" valign="top" colspan="2" class="<cfoutput>#thisContentClass#</cfoutput>"></td>
		  </tr>
		<cfif useEnableButton>
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
				<label for="<cfoutput>#contentTemplateStr#</cfoutput>Enable">Enable:</label>
			</td>
		   </tr>
		   <tr>
			<td class="<cfoutput>#thisContentClass#</cfoutput>" colspan="2">
				<input type="checkbox" id="<cfoutput>#contentTemplateStr#</cfoutput>Enable" name="<cfoutput>#contentTemplateStr#</cfoutput>Enable" checked>
			</td>
		  </tr>
		<cfelse><!---<cfif session.isMobile>--->
		  <tr>
			<td align="right" class="<cfoutput>#thisContentClass#</cfoutput>" style="width: 20%"> 
				<label for="<cfoutput>#contentTemplateStr#</cfoutput>Enable">Enable:</label>
			</td>
			<td class="<cfoutput>#thisContentClass#</cfoutput>">
				<input type="checkbox" id="<cfoutput>#contentTemplateStr#</cfoutput>Enable" name="<cfoutput>#contentTemplateStr#</cfoutput>Enable" checked>
			</td>
		  </tr>
		</cfif><!---<cfif session.isMobile>--->	
		</cfif><!---<cfif useEnableButton>--->
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
	
		<!--- Desktop header code (for both mobile and desktop devices) --->
		<cfif session.isMobile>
		  <tr valign="middle">
			<td class="<cfoutput>#thisContentClass#</cfoutput>" colspan="2">
				<label for="<cfoutput>#contentTemplateStr#</cfoutput>Desktop"><cfoutput>#contentTemplateLabel#</cfoutput> Desktop:</label>
			</td>
		   </tr>
		   <tr>
			<td class="<cfoutput>#thisContentClass#</cfoutput>" colspan="2">
				<!-- Editor -->
				<!--- Link to tinyMce editor: createAdminInterfaceWindow(53,themeId,'template',isMobile) --->
				<button id="<cfoutput>#contentTemplateStr#</cfoutput>DesktopButton" name="<cfoutput>#contentTemplateStr#</cfoutput>DesktopButton" class="k-button k-primary" type="button" onClick="createAdminInterfaceWindow(53,<cfoutput>#themeId#</cfoutput>,'<cfoutput>#contentTemplateStr#</cfoutput>Desktop',false);">Edit</button>
				
			</td>
		  </tr>
		<cfelse><!---<cfif session.isMobile>--->
		  <tr>
			<td align="right" class="<cfoutput>#thisContentClass#</cfoutput>" style="width: 20%"> 
				<label for="<cfoutput>#contentTemplateStr#</cfoutput>Desktop"><cfoutput>#contentTemplateLabel#</cfoutput> Desktop:</label>
			</td>
			<td class="<cfoutput>#thisContentClass#</cfoutput>">
				<!-- Editor -->
				<!--- Link to tinyMce editor: createAdminInterfaceWindow(53,themeId,'template',isMobile) --->
				<button id="<cfoutput>#contentTemplateStr#</cfoutput>DesktopButton" name="<cfoutput>#contentTemplateStr#</cfoutput>DesktopButton" class="k-button k-primary" type="button" onClick="createAdminInterfaceWindow(53,<cfoutput>#themeId#</cfoutput>,'<cfoutput>#contentTemplateStr#</cfoutput>Desktop',false);">Edit</button>
			</td>
		  </tr>
		</cfif>
		  <!--- Mobile header code (for both mobile and desktop devices) --->
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
				<label for="<cfoutput>#contentTemplateStr#</cfoutput>Mobile"><cfoutput>#contentTemplateLabel#</cfoutput> Mobile:</label>
			</td>
		   </tr>
		   <tr>
			<td class="<cfoutput>#thisContentClass#</cfoutput>" colspan="2">
				<!-- Editor -->
				<!--- Link to tinyMce editor: createAdminInterfaceWindow(53,themeId,'template',isMobile) --->
				<button id="<cfoutput>#contentTemplateStr#</cfoutput>DesktopButton" name="<cfoutput>#contentTemplateStr#</cfoutput>MobileButton" class="k-button k-primary" type="button" onClick="createAdminInterfaceWindow(53,<cfoutput>#themeId#</cfoutput>,'<cfoutput>#contentTemplateStr#</cfoutput>Mobile',true);">Edit</button>
			</td>

		  </tr>
		<cfelse><!---<cfif session.isMobile>--->
		  <tr>
			<td align="right" class="<cfoutput>#thisContentClass#</cfoutput>" style="width: 20%"> 
				<label for="<cfoutput>#contentTemplateStr#</cfoutput>Mobile"><cfoutput>#contentTemplateLabel#</cfoutput> Mobile</label>
			</td>
			<td class="<cfoutput>#thisContentClass#</cfoutput>">
				<!-- Editor -->
				<!--- Link to tinyMce editor: createAdminInterfaceWindow(53,themeId,'template',isMobile) --->
				<button id="<cfoutput>#contentTemplateStr#</cfoutput>MobileButton" name="<cfoutput>#contentTemplateStr#</cfoutput>MobileButton" class="k-button k-primary" type="button" onClick="createAdminInterfaceWindow(53,<cfoutput>#themeId#</cfoutput>,'<cfoutput>#contentTemplateStr#</cfoutput>Mobile',true);">Edit</button>
			</td>
		  </tr>
		  <tr height="1px">
			  <td align="left" valign="top" colspan="2" class="<cfoutput>#thisContentClass#</cfoutput>"></td>
		  </tr>
		</cfif><!---<cfif session.isMobile>--->
		<cfsilent>
			<!---//***********************************************************************************************
								Subscribe Pod
			//************************************************************************************************--->


			<!--- This logic is easily reproducable with a small number of variables. Set them here. --->
			<cfset contentTemplateStr = "subscribePod">
			<cfset contentTemplateLabel = "Subscribe Pod">
			<cfset entityId = "ThemeId">
			<cfset entityName = "ThemeName">
			<cfset useEnableButton = true>
			<!--- You need to enter the description manually --->

		  	<!--- Set the class for alternating rows. --->
		  	<!---After the first row, the content class should be the current class. --->
		  	<cfset thisContentClass = HtmlUtilsObj.getKendoClass(thisContentClass)>
		  </cfsilent> 
		  <tr height="1px">
			  <td align="left" valign="top" colspan="2" class="border <cfoutput>#thisContentClass#</cfoutput>"></td>
		  </tr>
		  <tr height="1px">
			  <td align="left" valign="top" colspan="2" class="<cfoutput>#thisContentClass#</cfoutput> setting-title"><b>Subscribe Pod</b></td>
		  </tr>
		  <tr height="1px">
			  <td align="left" valign="top" colspan="2" class="border <cfoutput>#thisContentClass#</cfoutput>"></td>
		  </tr>
		  <tr>
			<td colspan="2" class="<cfoutput>#thisContentClass#</cfoutput>"> 
				The subscribe pod is a system related interface allowing your users to subscribe to your blog. You may redesign or disable this pod if you don't need this functionality.
			</td>
		  </tr>
		  <tr height="1px">
			  <td align="left" valign="top" colspan="2" class="<cfoutput>#thisContentClass#</cfoutput>"></td>
		  </tr>
		<cfif useEnableButton>
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
				<label for="<cfoutput>#contentTemplateStr#</cfoutput>Enable">Enable:</label>
			</td>
		   </tr>
		   <tr>
			<td class="<cfoutput>#thisContentClass#</cfoutput>" colspan="2">
				<input type="checkbox" id="<cfoutput>#contentTemplateStr#</cfoutput>Enable" name="<cfoutput>#contentTemplateStr#</cfoutput>Enable" checked>
			</td>
		  </tr>
		<cfelse><!---<cfif session.isMobile>--->
		  <tr>
			<td align="right" class="<cfoutput>#thisContentClass#</cfoutput>" style="width: 20%"> 
				<label for="<cfoutput>#contentTemplateStr#</cfoutput>Enable">Enable:</label>
			</td>
			<td class="<cfoutput>#thisContentClass#</cfoutput>">
				<input type="checkbox" id="<cfoutput>#contentTemplateStr#</cfoutput>Enable" name="<cfoutput>#contentTemplateStr#</cfoutput>Enable" checked>
			</td>
		  </tr>
		</cfif><!---<cfif session.isMobile>--->	
		</cfif><!---<cfif useEnableButton>--->
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
	
		<!--- Desktop header code (for both mobile and desktop devices) --->
		<cfif session.isMobile>
		  <tr valign="middle">
			<td class="<cfoutput>#thisContentClass#</cfoutput>" colspan="2">
				<label for="<cfoutput>#contentTemplateStr#</cfoutput>Desktop"><cfoutput>#contentTemplateLabel#</cfoutput> Desktop:</label>
			</td>
		   </tr>
		   <tr>
			<td class="<cfoutput>#thisContentClass#</cfoutput>" colspan="2">
				<!-- Editor -->
				<!--- Link to tinyMce editor: createAdminInterfaceWindow(53,themeId,'template',isMobile) --->
				<button id="<cfoutput>#contentTemplateStr#</cfoutput>DesktopButton" name="<cfoutput>#contentTemplateStr#</cfoutput>DesktopButton" class="k-button k-primary" type="button" onClick="createAdminInterfaceWindow(53,<cfoutput>#themeId#</cfoutput>,'<cfoutput>#contentTemplateStr#</cfoutput>Desktop',false);">Edit</button>
				
			</td>
		  </tr>
		<cfelse><!---<cfif session.isMobile>--->
		  <tr>
			<td align="right" class="<cfoutput>#thisContentClass#</cfoutput>" style="width: 20%"> 
				<label for="<cfoutput>#contentTemplateStr#</cfoutput>Desktop"><cfoutput>#contentTemplateLabel#</cfoutput> Desktop:</label>
			</td>
			<td class="<cfoutput>#thisContentClass#</cfoutput>">
				<!-- Editor -->
				<!--- Link to tinyMce editor: createAdminInterfaceWindow(53,themeId,'template',isMobile) --->
				<button id="<cfoutput>#contentTemplateStr#</cfoutput>DesktopButton" name="<cfoutput>#contentTemplateStr#</cfoutput>DesktopButton" class="k-button k-primary" type="button" onClick="createAdminInterfaceWindow(53,<cfoutput>#themeId#</cfoutput>,'<cfoutput>#contentTemplateStr#</cfoutput>Desktop',false);">Edit</button>
			</td>
		  </tr>
		</cfif>
		  <!--- Mobile header code (for both mobile and desktop devices) --->
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
				<label for="<cfoutput>#contentTemplateStr#</cfoutput>Mobile"><cfoutput>#contentTemplateLabel#</cfoutput> Mobile:</label>
			</td>
		   </tr>
		   <tr>
			<td class="<cfoutput>#thisContentClass#</cfoutput>" colspan="2">
				<!-- Editor -->
				<!--- Link to tinyMce editor: createAdminInterfaceWindow(53,themeId,'template',isMobile) --->
				<button id="<cfoutput>#contentTemplateStr#</cfoutput>DesktopButton" name="<cfoutput>#contentTemplateStr#</cfoutput>MobileButton" class="k-button k-primary" type="button" onClick="createAdminInterfaceWindow(53,<cfoutput>#themeId#</cfoutput>,'<cfoutput>#contentTemplateStr#</cfoutput>Mobile',true);">Edit</button>
			</td>

		  </tr>
		<cfelse><!---<cfif session.isMobile>--->
		  <tr>
			<td align="right" class="<cfoutput>#thisContentClass#</cfoutput>" style="width: 20%"> 
				<label for="<cfoutput>#contentTemplateStr#</cfoutput>Mobile"><cfoutput>#contentTemplateLabel#</cfoutput> Mobile</label>
			</td>
			<td class="<cfoutput>#thisContentClass#</cfoutput>">
				<!-- Editor -->
				<!--- Link to tinyMce editor: createAdminInterfaceWindow(53,themeId,'template',isMobile) --->
				<button id="<cfoutput>#contentTemplateStr#</cfoutput>MobileButton" name="<cfoutput>#contentTemplateStr#</cfoutput>MobileButton" class="k-button k-primary" type="button" onClick="createAdminInterfaceWindow(53,<cfoutput>#themeId#</cfoutput>,'<cfoutput>#contentTemplateStr#</cfoutput>Mobile',true);">Edit</button>
			</td>
		  </tr>
		</cfif> 
		<cfsilent>
			<!---//***********************************************************************************************
								CFBlogs Pod
			//************************************************************************************************--->


			<!--- This logic is easily reproducable with a small number of variables. Set them here. --->
			<cfset contentTemplateStr = "cfblogsFeedPod">
			<cfset contentTemplateLabel = "CfBlogs Pod">
			<cfset entityId = "ThemeId">
			<cfset entityName = "ThemeName">
			<cfset useEnableButton = true>
			<!--- You need to enter the description manually --->

		  	<!--- Set the class for alternating rows. --->
		  	<!---After the first row, the content class should be the current class. --->
		  	<cfset thisContentClass = HtmlUtilsObj.getKendoClass(thisContentClass)>
		  </cfsilent> 
		  <tr height="1px">
			  <td align="left" valign="top" colspan="2" class="border <cfoutput>#thisContentClass#</cfoutput>"></td>
		  </tr>
		  <tr height="1px">
			  <td align="left" valign="top" colspan="2" class="<cfoutput>#thisContentClass#</cfoutput> setting-title"><b>CfBlogs.org Feed Aggregate Pod</b></td>
		  </tr>
		  <tr height="1px">
			  <td align="left" valign="top" colspan="2" class="border <cfoutput>#thisContentClass#</cfoutput>"></td>
		  </tr>
		  <tr>
			<td colspan="2" class="<cfoutput>#thisContentClass#</cfoutput>"> 
				The default CfBlogs Feed pod is typically a aggregate feed of all ColdFusion/Lucee related sites. If you're blogging about ColdFusion, you should keep this pod as is and join the cfblogs.org community. Otherwise, you may redesign this to meet your needs to disable the pod by unchecking the enable button below. 
			</td>
		  </tr>
		  <tr height="1px">
			  <td align="left" valign="top" colspan="2" class="<cfoutput>#thisContentClass#</cfoutput>"></td>
		  </tr>
		<cfif useEnableButton>
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
				<label for="<cfoutput>#contentTemplateStr#</cfoutput>Enable">Enable:</label>
			</td>
		   </tr>
		   <tr>
			<td class="<cfoutput>#thisContentClass#</cfoutput>" colspan="2">
				<input type="checkbox" id="<cfoutput>#contentTemplateStr#</cfoutput>Enable" name="<cfoutput>#contentTemplateStr#</cfoutput>Enable" checked>
			</td>
		  </tr>
		<cfelse><!---<cfif session.isMobile>--->
		  <tr>
			<td align="right" class="<cfoutput>#thisContentClass#</cfoutput>" style="width: 20%"> 
				<label for="<cfoutput>#contentTemplateStr#</cfoutput>Enable">Enable:</label>
			</td>
			<td class="<cfoutput>#thisContentClass#</cfoutput>">
				
				<input type="checkbox" id="<cfoutput>#contentTemplateStr#</cfoutput>Enable" name="<cfoutput>#contentTemplateStr#</cfoutput>Enable" checked>
			</td>
		  </tr>
		</cfif><!---<cfif session.isMobile>--->	
		</cfif><!---<cfif useEnableButton>--->
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
	
		<!--- Desktop header code (for both mobile and desktop devices) --->
		<cfif session.isMobile>
		  <tr valign="middle">
			<td class="<cfoutput>#thisContentClass#</cfoutput>" colspan="2">
				<label for="<cfoutput>#contentTemplateStr#</cfoutput>Desktop"><cfoutput>#contentTemplateLabel#</cfoutput> Desktop:</label>
			</td>
		   </tr>
		   <tr>
			<td class="<cfoutput>#thisContentClass#</cfoutput>" colspan="2">
				<!-- Editor -->
				<!--- Link to tinyMce editor: createAdminInterfaceWindow(53,themeId,'template',isMobile) --->
				<button id="<cfoutput>#contentTemplateStr#</cfoutput>DesktopButton" name="<cfoutput>#contentTemplateStr#</cfoutput>DesktopButton" class="k-button k-primary" type="button" onClick="createAdminInterfaceWindow(53,<cfoutput>#themeId#</cfoutput>,'<cfoutput>#contentTemplateStr#</cfoutput>Desktop',false);">Edit</button>
				
			</td>
		  </tr>
		<cfelse><!---<cfif session.isMobile>--->
		  <tr>
			<td align="right" class="<cfoutput>#thisContentClass#</cfoutput>" style="width: 20%"> 
				<label for="<cfoutput>#contentTemplateStr#</cfoutput>Desktop"><cfoutput>#contentTemplateLabel#</cfoutput> Desktop:</label>
			</td>
			<td class="<cfoutput>#thisContentClass#</cfoutput>">
				<!-- Editor -->
				<!--- Link to tinyMce editor: createAdminInterfaceWindow(53,themeId,'template',isMobile) --->
				<button id="<cfoutput>#contentTemplateStr#</cfoutput>DesktopButton" name="<cfoutput>#contentTemplateStr#</cfoutput>DesktopButton" class="k-button k-primary" type="button" onClick="createAdminInterfaceWindow(53,<cfoutput>#themeId#</cfoutput>,'<cfoutput>#contentTemplateStr#</cfoutput>Desktop',false);">Edit</button>
			</td>
		  </tr>
		</cfif>
		  <!--- Mobile header code (for both mobile and desktop devices) --->
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
				<label for="<cfoutput>#contentTemplateStr#</cfoutput>Mobile"><cfoutput>#contentTemplateLabel#</cfoutput> Mobile:</label>
			</td>
		   </tr>
		   <tr>
			<td class="<cfoutput>#thisContentClass#</cfoutput>" colspan="2">
				<!-- Editor -->
				<!--- Link to tinyMce editor: createAdminInterfaceWindow(53,themeId,'template',isMobile) --->
				<button id="<cfoutput>#contentTemplateStr#</cfoutput>DesktopButton" name="<cfoutput>#contentTemplateStr#</cfoutput>MobileButton" class="k-button k-primary" type="button" onClick="createAdminInterfaceWindow(53,<cfoutput>#themeId#</cfoutput>,'<cfoutput>#contentTemplateStr#</cfoutput>Mobile',true);">Edit</button>
			</td>

		  </tr>
		<cfelse><!---<cfif session.isMobile>--->
		  <tr>
			<td align="right" class="<cfoutput>#thisContentClass#</cfoutput>" style="width: 20%"> 
				<label for="<cfoutput>#contentTemplateStr#</cfoutput>Mobile"><cfoutput>#contentTemplateLabel#</cfoutput> Mobile</label>
			</td>
			<td class="<cfoutput>#thisContentClass#</cfoutput>">
				<!-- Editor -->
				<!--- Link to tinyMce editor: createAdminInterfaceWindow(53,themeId,'template',isMobile) --->
				<button id="<cfoutput>#contentTemplateStr#</cfoutput>MobileButton" name="<cfoutput>#contentTemplateStr#</cfoutput>MobileButton" class="k-button k-primary" type="button" onClick="createAdminInterfaceWindow(53,<cfoutput>#themeId#</cfoutput>,'<cfoutput>#contentTemplateStr#</cfoutput>Mobile',true);">Edit</button>
			</td>
		  </tr>
		</cfif> 
		<cfsilent>
			<!---//***********************************************************************************************
								Recent Posts Pod
			//************************************************************************************************--->


			<!--- This logic is easily reproducable with a small number of variables. Set them here. --->
			<cfset contentTemplateStr = "recentPostsPod">
			<cfset contentTemplateLabel = "Recent Posts Pod">
			<cfset entityId = "ThemeId">
			<cfset entityName = "ThemeName">
			<cfset useEnableButton = true>
			<!--- You need to enter the description manually --->

		  	<!--- Set the class for alternating rows. --->
		  	<!---After the first row, the content class should be the current class. --->
		  	<cfset thisContentClass = HtmlUtilsObj.getKendoClass(thisContentClass)>
		  </cfsilent> 
		  <tr height="1px">
			  <td align="left" valign="top" colspan="2" class="border <cfoutput>#thisContentClass#</cfoutput>"></td>
		  </tr>
		  <tr height="1px">
			  <td align="left" valign="top" colspan="2" class="<cfoutput>#thisContentClass#</cfoutput> setting-title"><b>Recent Posts Pod</b></td>
		  </tr>
		  <tr height="1px">
			  <td align="left" valign="top" colspan="2" class="border <cfoutput>#thisContentClass#</cfoutput>"></td>
		  </tr>
		  <tr>
			<td colspan="2" class="<cfoutput>#thisContentClass#</cfoutput>"> 
				The recent posts pod displays the most recent blog posts. 
			</td>
		  </tr>
		  <tr height="1px">
			  <td align="left" valign="top" colspan="2" class="<cfoutput>#thisContentClass#</cfoutput>"></td>
		  </tr>
		<cfif useEnableButton>
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
				<label for="<cfoutput>#contentTemplateStr#</cfoutput>Enable">Enable:</label>
			</td>
		   </tr>
		   <tr>
			<td class="<cfoutput>#thisContentClass#</cfoutput>" colspan="2">
				
				<input type="checkbox" id="<cfoutput>#contentTemplateStr#</cfoutput>Enable" name="<cfoutput>#contentTemplateStr#</cfoutput>Enable" checked>
			</td>
		  </tr>
		<cfelse><!---<cfif session.isMobile>--->
		  <tr>
			<td align="right" class="<cfoutput>#thisContentClass#</cfoutput>" style="width: 20%"> 
				<label for="<cfoutput>#contentTemplateStr#</cfoutput>Enable">Enable:</label>
			</td>
			<td class="<cfoutput>#thisContentClass#</cfoutput>">
				
				<input type="checkbox" id="<cfoutput>#contentTemplateStr#</cfoutput>Enable" name="<cfoutput>#contentTemplateStr#</cfoutput>Enable" checked>
			</td>
		  </tr>
		</cfif><!---<cfif session.isMobile>--->	
		</cfif><!---<cfif useEnableButton>--->
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
	
		<!--- Desktop header code (for both mobile and desktop devices) --->
		<cfif session.isMobile>
		  <tr valign="middle">
			<td class="<cfoutput>#thisContentClass#</cfoutput>" colspan="2">
				<label for="<cfoutput>#contentTemplateStr#</cfoutput>Desktop"><cfoutput>#contentTemplateLabel#</cfoutput> Desktop:</label>
			</td>
		   </tr>
		   <tr>
			<td class="<cfoutput>#thisContentClass#</cfoutput>" colspan="2">
				<!-- Editor -->
				<!--- Link to tinyMce editor: createAdminInterfaceWindow(53,themeId,'template',isMobile) --->
				<button id="<cfoutput>#contentTemplateStr#</cfoutput>DesktopButton" name="<cfoutput>#contentTemplateStr#</cfoutput>DesktopButton" class="k-button k-primary" type="button" onClick="createAdminInterfaceWindow(53,<cfoutput>#themeId#</cfoutput>,'<cfoutput>#contentTemplateStr#</cfoutput>Desktop',false);">Edit</button>
				
			</td>
		  </tr>
		<cfelse><!---<cfif session.isMobile>--->
		  <tr>
			<td align="right" class="<cfoutput>#thisContentClass#</cfoutput>" style="width: 20%"> 
				<label for="<cfoutput>#contentTemplateStr#</cfoutput>Desktop"><cfoutput>#contentTemplateLabel#</cfoutput> Desktop:</label>
			</td>
			<td class="<cfoutput>#thisContentClass#</cfoutput>">
				<!-- Editor -->
				<!--- Link to tinyMce editor: createAdminInterfaceWindow(53,themeId,'template',isMobile) --->
				<button id="<cfoutput>#contentTemplateStr#</cfoutput>DesktopButton" name="<cfoutput>#contentTemplateStr#</cfoutput>DesktopButton" class="k-button k-primary" type="button" onClick="createAdminInterfaceWindow(53,<cfoutput>#themeId#</cfoutput>,'<cfoutput>#contentTemplateStr#</cfoutput>Desktop',false);">Edit</button>
			</td>
		  </tr>
		</cfif>
		  <!--- Mobile header code (for both mobile and desktop devices) --->
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
				<label for="<cfoutput>#contentTemplateStr#</cfoutput>Mobile"><cfoutput>#contentTemplateLabel#</cfoutput> Mobile:</label>
			</td>
		   </tr>
		   <tr>
			<td class="<cfoutput>#thisContentClass#</cfoutput>" colspan="2">
				<!-- Editor -->
				<!--- Link to tinyMce editor: createAdminInterfaceWindow(53,themeId,'template',isMobile) --->
				<button id="<cfoutput>#contentTemplateStr#</cfoutput>DesktopButton" name="<cfoutput>#contentTemplateStr#</cfoutput>MobileButton" class="k-button k-primary" type="button" onClick="createAdminInterfaceWindow(53,<cfoutput>#themeId#</cfoutput>,'<cfoutput>#contentTemplateStr#</cfoutput>Mobile',true);">Edit</button>
			</td>

		  </tr>
		<cfelse><!---<cfif session.isMobile>--->
		  <tr>
			<td align="right" class="<cfoutput>#thisContentClass#</cfoutput>" style="width: 20%"> 
				<label for="<cfoutput>#contentTemplateStr#</cfoutput>Mobile"><cfoutput>#contentTemplateLabel#</cfoutput> Mobile</label>
			</td>
			<td class="<cfoutput>#thisContentClass#</cfoutput>">
				<!-- Editor -->
				<!--- Link to tinyMce editor: createAdminInterfaceWindow(53,themeId,'template',isMobile) --->
				<button id="<cfoutput>#contentTemplateStr#</cfoutput>MobileButton" name="<cfoutput>#contentTemplateStr#</cfoutput>MobileButton" class="k-button k-primary" type="button" onClick="createAdminInterfaceWindow(53,<cfoutput>#themeId#</cfoutput>,'<cfoutput>#contentTemplateStr#</cfoutput>Mobile',true);">Edit</button>
			</td>
		  </tr>
		</cfif> 
		<cfsilent>
			<!---//***********************************************************************************************
								Recenet Comments Pod
			//************************************************************************************************--->


			<!--- This logic is easily reproducable with a small number of variables. Set them here. --->
			<cfset contentTemplateStr = "recentCommentsPod">
			<cfset contentTemplateLabel = "Recent Comments Pod">
			<cfset entityId = "ThemeId">
			<cfset entityName = "ThemeName">
			<cfset useEnableButton = true>
			<!--- You need to enter the description manually --->

		  	<!--- Set the class for alternating rows. --->
		  	<!---After the first row, the content class should be the current class. --->
		  	<cfset thisContentClass = HtmlUtilsObj.getKendoClass(thisContentClass)>
		  </cfsilent> 
		  <tr height="1px">
			  <td align="left" valign="top" colspan="2" class="border <cfoutput>#thisContentClass#</cfoutput>"></td>
		  </tr>
		  <tr height="1px">
			  <td align="left" valign="top" colspan="2" class="<cfoutput>#thisContentClass#</cfoutput> setting-title"><b>Recent Comments Pod</b></td>
		  </tr>
		  <tr height="1px">
			  <td align="left" valign="top" colspan="2" class="border <cfoutput>#thisContentClass#</cfoutput>"></td>
		  </tr>
		  <tr>
			<td colspan="2" class="<cfoutput>#thisContentClass#</cfoutput>"> 
				The recent comments pod displays the most recent blog comments.
			</td>
		  </tr>
		  <tr height="1px">
			  <td align="left" valign="top" colspan="2" class="<cfoutput>#thisContentClass#</cfoutput>"></td>
		  </tr>
		<cfif useEnableButton>
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
				<label for="<cfoutput>#contentTemplateStr#</cfoutput>Enable">Enable:</label>
			</td>
		   </tr>
		   <tr>
			<td class="<cfoutput>#thisContentClass#</cfoutput>" colspan="2">
				
				<input type="checkbox" id="<cfoutput>#contentTemplateStr#</cfoutput>Enable" name="<cfoutput>#contentTemplateStr#</cfoutput>Enable" checked>
			</td>
		  </tr>
		<cfelse><!---<cfif session.isMobile>--->
		  <tr>
			<td align="right" class="<cfoutput>#thisContentClass#</cfoutput>" style="width: 20%"> 
				<label for="<cfoutput>#contentTemplateStr#</cfoutput>Enable">Enable:</label>
			</td>
			<td class="<cfoutput>#thisContentClass#</cfoutput>">
				
				<input type="checkbox" id="<cfoutput>#contentTemplateStr#</cfoutput>Enable" name="<cfoutput>#contentTemplateStr#</cfoutput>Enable" checked>
			</td>
		  </tr>
		</cfif><!---<cfif session.isMobile>--->	
		</cfif><!---<cfif useEnableButton>--->
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
	
		<!--- Desktop header code (for both mobile and desktop devices) --->
		<cfif session.isMobile>
		  <tr valign="middle">
			<td class="<cfoutput>#thisContentClass#</cfoutput>" colspan="2">
				<label for="<cfoutput>#contentTemplateStr#</cfoutput>Desktop"><cfoutput>#contentTemplateLabel#</cfoutput> Desktop:</label>
			</td>
		   </tr>
		   <tr>
			<td class="<cfoutput>#thisContentClass#</cfoutput>" colspan="2">
				<!-- Editor -->
				<!--- Link to tinyMce editor: createAdminInterfaceWindow(53,themeId,'template',isMobile) --->
				<button id="<cfoutput>#contentTemplateStr#</cfoutput>DesktopButton" name="<cfoutput>#contentTemplateStr#</cfoutput>DesktopButton" class="k-button k-primary" type="button" onClick="createAdminInterfaceWindow(53,<cfoutput>#themeId#</cfoutput>,'<cfoutput>#contentTemplateStr#</cfoutput>Desktop',false);">Edit</button>
				
			</td>
		  </tr>
		<cfelse><!---<cfif session.isMobile>--->
		  <tr>
			<td align="right" class="<cfoutput>#thisContentClass#</cfoutput>" style="width: 20%"> 
				<label for="<cfoutput>#contentTemplateStr#</cfoutput>Desktop"><cfoutput>#contentTemplateLabel#</cfoutput> Desktop:</label>
			</td>
			<td class="<cfoutput>#thisContentClass#</cfoutput>">
				<!-- Editor -->
				<!--- Link to tinyMce editor: createAdminInterfaceWindow(53,themeId,'template',isMobile) --->
				<button id="<cfoutput>#contentTemplateStr#</cfoutput>DesktopButton" name="<cfoutput>#contentTemplateStr#</cfoutput>DesktopButton" class="k-button k-primary" type="button" onClick="createAdminInterfaceWindow(53,<cfoutput>#themeId#</cfoutput>,'<cfoutput>#contentTemplateStr#</cfoutput>Desktop',false);">Edit</button>
			</td>
		  </tr>
		</cfif>
		  <!--- Mobile header code (for both mobile and desktop devices) --->
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
				<label for="<cfoutput>#contentTemplateStr#</cfoutput>Mobile"><cfoutput>#contentTemplateLabel#</cfoutput> Mobile:</label>
			</td>
		   </tr>
		   <tr>
			<td class="<cfoutput>#thisContentClass#</cfoutput>" colspan="2">
				<!-- Editor -->
				<!--- Link to tinyMce editor: createAdminInterfaceWindow(53,themeId,'template',isMobile) --->
				<button id="<cfoutput>#contentTemplateStr#</cfoutput>DesktopButton" name="<cfoutput>#contentTemplateStr#</cfoutput>MobileButton" class="k-button k-primary" type="button" onClick="createAdminInterfaceWindow(53,<cfoutput>#themeId#</cfoutput>,'<cfoutput>#contentTemplateStr#</cfoutput>Mobile',true);">Edit</button>
			</td>

		  </tr>
		<cfelse><!---<cfif session.isMobile>--->
		  <tr>
			<td align="right" class="<cfoutput>#thisContentClass#</cfoutput>" style="width: 20%"> 
				<label for="<cfoutput>#contentTemplateStr#</cfoutput>Mobile"><cfoutput>#contentTemplateLabel#</cfoutput> Mobile</label>
			</td>
			<td class="<cfoutput>#thisContentClass#</cfoutput>">
				<!-- Editor -->
				<!--- Link to tinyMce editor: createAdminInterfaceWindow(53,themeId,'template',isMobile) --->
				<button id="<cfoutput>#contentTemplateStr#</cfoutput>MobileButton" name="<cfoutput>#contentTemplateStr#</cfoutput>MobileButton" class="k-button k-primary" type="button" onClick="createAdminInterfaceWindow(53,<cfoutput>#themeId#</cfoutput>,'<cfoutput>#contentTemplateStr#</cfoutput>Mobile',true);">Edit</button>
			</td>
		  </tr>
		</cfif> 
		<cfsilent>
			<!---//***********************************************************************************************
								Categories Pod
			//************************************************************************************************--->


			<!--- This logic is easily reproducable with a small number of variables. Set them here. --->
			<cfset contentTemplateStr = "categoriesPod">
			<cfset contentTemplateLabel = "Category Archive Pod">
			<cfset entityId = "ThemeId">
			<cfset entityName = "ThemeName">
			<cfset useEnableButton = true>
			<!--- You need to enter the description manually --->

		  	<!--- Set the class for alternating rows. --->
		  	<!---After the first row, the content class should be the current class. --->
		  	<cfset thisContentClass = HtmlUtilsObj.getKendoClass(thisContentClass)>
		  </cfsilent> 
		  <tr height="1px">
			  <td align="left" valign="top" colspan="2" class="border <cfoutput>#thisContentClass#</cfoutput>"></td>
		  </tr>
		  <tr height="1px">
			  <td align="left" valign="top" colspan="2" class="<cfoutput>#thisContentClass#</cfoutput> setting-title"><b>Category Archives Pod</b></td>
		  </tr>
		  <tr height="1px">
			  <td align="left" valign="top" colspan="2" class="border <cfoutput>#thisContentClass#</cfoutput>"></td>
		  </tr>
		  <tr>
			<td colspan="2" class="<cfoutput>#thisContentClass#</cfoutput>"> 
				The categories pod displays the parent blog categories along with a link to the category RSS feed. 
			</td>
		  </tr>
		  <tr height="1px">
			  <td align="left" valign="top" colspan="2" class="<cfoutput>#thisContentClass#</cfoutput>"></td>
		  </tr>
		<cfif useEnableButton>
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
				<label for="<cfoutput>#contentTemplateStr#</cfoutput>Enable">Enable:</label>
			</td>
		   </tr>
		   <tr>
			<td class="<cfoutput>#thisContentClass#</cfoutput>" colspan="2">
				
				<input type="checkbox" id="<cfoutput>#contentTemplateStr#</cfoutput>Enable" name="<cfoutput>#contentTemplateStr#</cfoutput>Enable" checked>
			</td>
		  </tr>
		<cfelse><!---<cfif session.isMobile>--->
		  <tr>
			<td align="right" class="<cfoutput>#thisContentClass#</cfoutput>" style="width: 20%"> 
				<label for="<cfoutput>#contentTemplateStr#</cfoutput>Enable">Enable:</label>
			</td>
			<td class="<cfoutput>#thisContentClass#</cfoutput>">
				
				<input type="checkbox" id="<cfoutput>#contentTemplateStr#</cfoutput>Enable" name="<cfoutput>#contentTemplateStr#</cfoutput>Enable" checked>
			</td>
		  </tr>
		</cfif><!---<cfif session.isMobile>--->	
		</cfif><!---<cfif useEnableButton>--->
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
	
		<!--- Desktop header code (for both mobile and desktop devices) --->
		<cfif session.isMobile>
		  <tr valign="middle">
			<td class="<cfoutput>#thisContentClass#</cfoutput>" colspan="2">
				<label for="<cfoutput>#contentTemplateStr#</cfoutput>Desktop"><cfoutput>#contentTemplateLabel#</cfoutput> Desktop:</label>
			</td>
		   </tr>
		   <tr>
			<td class="<cfoutput>#thisContentClass#</cfoutput>" colspan="2">
				<!-- Editor -->
				<!--- Link to tinyMce editor: createAdminInterfaceWindow(53,themeId,'template',isMobile) --->
				<button id="<cfoutput>#contentTemplateStr#</cfoutput>DesktopButton" name="<cfoutput>#contentTemplateStr#</cfoutput>DesktopButton" class="k-button k-primary" type="button" onClick="createAdminInterfaceWindow(53,<cfoutput>#themeId#</cfoutput>,'<cfoutput>#contentTemplateStr#</cfoutput>Desktop',false);">Edit</button>
				
			</td>
		  </tr>
		<cfelse><!---<cfif session.isMobile>--->
		  <tr>
			<td align="right" class="<cfoutput>#thisContentClass#</cfoutput>" style="width: 20%"> 
				<label for="<cfoutput>#contentTemplateStr#</cfoutput>Desktop"><cfoutput>#contentTemplateLabel#</cfoutput> Desktop:</label>
			</td>
			<td class="<cfoutput>#thisContentClass#</cfoutput>">
				<!-- Editor -->
				<!--- Link to tinyMce editor: createAdminInterfaceWindow(53,themeId,'template',isMobile) --->
				<button id="<cfoutput>#contentTemplateStr#</cfoutput>DesktopButton" name="<cfoutput>#contentTemplateStr#</cfoutput>DesktopButton" class="k-button k-primary" type="button" onClick="createAdminInterfaceWindow(53,<cfoutput>#themeId#</cfoutput>,'<cfoutput>#contentTemplateStr#</cfoutput>Desktop',false);">Edit</button>
			</td>
		  </tr>
		</cfif>
		  <!--- Mobile header code (for both mobile and desktop devices) --->
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
				<label for="<cfoutput>#contentTemplateStr#</cfoutput>Mobile"><cfoutput>#contentTemplateLabel#</cfoutput> Mobile:</label>
			</td>
		   </tr>
		   <tr>
			<td class="<cfoutput>#thisContentClass#</cfoutput>" colspan="2">
				<!-- Editor -->
				<!--- Link to tinyMce editor: createAdminInterfaceWindow(53,themeId,'template',isMobile) --->
				<button id="<cfoutput>#contentTemplateStr#</cfoutput>DesktopButton" name="<cfoutput>#contentTemplateStr#</cfoutput>MobileButton" class="k-button k-primary" type="button" onClick="createAdminInterfaceWindow(53,<cfoutput>#themeId#</cfoutput>,'<cfoutput>#contentTemplateStr#</cfoutput>Mobile',true);">Edit</button>
			</td>

		  </tr>
		<cfelse><!---<cfif session.isMobile>--->
		  <tr>
			<td align="right" class="<cfoutput>#thisContentClass#</cfoutput>" style="width: 20%"> 
				<label for="<cfoutput>#contentTemplateStr#</cfoutput>Mobile"><cfoutput>#contentTemplateLabel#</cfoutput> Mobile</label>
			</td>
			<td class="<cfoutput>#thisContentClass#</cfoutput>">
				<!-- Editor -->
				<!--- Link to tinyMce editor: createAdminInterfaceWindow(53,themeId,'template',isMobile) --->
				<button id="<cfoutput>#contentTemplateStr#</cfoutput>MobileButton" name="<cfoutput>#contentTemplateStr#</cfoutput>MobileButton" class="k-button k-primary" type="button" onClick="createAdminInterfaceWindow(53,<cfoutput>#themeId#</cfoutput>,'<cfoutput>#contentTemplateStr#</cfoutput>Mobile',true);">Edit</button>
			</td>
		  </tr>
		</cfif> 
		<cfsilent>
			<!---//***********************************************************************************************
								Monthly Archives Pod
			//************************************************************************************************--->


			<!--- This logic is easily reproducable with a small number of variables. Set them here. --->
			<cfset contentTemplateStr = "monthlyArchivesPod">
			<cfset contentTemplateLabel = "Monthly Archives Pod">
			<cfset entityId = "ThemeId">
			<cfset entityName = "ThemeName">
			<cfset useEnableButton = true>
			<!--- You need to enter the description manually --->

		  	<!--- Set the class for alternating rows. --->
		  	<!---After the first row, the content class should be the current class. --->
		  	<cfset thisContentClass = HtmlUtilsObj.getKendoClass(thisContentClass)>
		  </cfsilent> 
		  <tr height="1px">
			  <td align="left" valign="top" colspan="2" class="border <cfoutput>#thisContentClass#</cfoutput>"></td>
		  </tr>
		  <tr height="1px">
			  <td align="left" valign="top" colspan="2" class="<cfoutput>#thisContentClass#</cfoutput> setting-title"><b>Monthly Archives Pod</b></td>
		  </tr>
		  <tr height="1px">
			  <td align="left" valign="top" colspan="2" class="border <cfoutput>#thisContentClass#</cfoutput>"></td>
		  </tr>
		  <tr>
			<td colspan="2" class="<cfoutput>#thisContentClass#</cfoutput>"> 
				The monthly archives shows the number of blog posts within each blog category.
			</td>
		  </tr>
		  <tr height="1px">
			  <td align="left" valign="top" colspan="2" class="<cfoutput>#thisContentClass#</cfoutput>"></td>
		  </tr>
		<cfif useEnableButton>
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
				<label for="<cfoutput>#contentTemplateStr#</cfoutput>Enable">Enable:</label>
			</td>
		   </tr>
		   <tr>
			<td class="<cfoutput>#thisContentClass#</cfoutput>" colspan="2">
				
				<input type="checkbox" id="<cfoutput>#contentTemplateStr#</cfoutput>Enable" name="<cfoutput>#contentTemplateStr#</cfoutput>Enable" checked>
			</td>
		  </tr>
		<cfelse><!---<cfif session.isMobile>--->
		  <tr>
			<td align="right" class="<cfoutput>#thisContentClass#</cfoutput>" style="width: 20%"> 
				<label for="<cfoutput>#contentTemplateStr#</cfoutput>Enable">Enable:</label>
			</td>
			<td class="<cfoutput>#thisContentClass#</cfoutput>">
				
				<input type="checkbox" id="<cfoutput>#contentTemplateStr#</cfoutput>Enable" name="<cfoutput>#contentTemplateStr#</cfoutput>Enable" checked>
			</td>
		  </tr>
		</cfif><!---<cfif session.isMobile>--->	
		</cfif><!---<cfif useEnableButton>--->
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
	
		<!--- Desktop header code (for both mobile and desktop devices) --->
		<cfif session.isMobile>
		  <tr valign="middle">
			<td class="<cfoutput>#thisContentClass#</cfoutput>" colspan="2">
				<label for="<cfoutput>#contentTemplateStr#</cfoutput>Desktop"><cfoutput>#contentTemplateLabel#</cfoutput> Desktop:</label>
			</td>
		   </tr>
		   <tr>
			<td class="<cfoutput>#thisContentClass#</cfoutput>" colspan="2">
				<!-- Editor -->
				<!--- Link to tinyMce editor: createAdminInterfaceWindow(53,themeId,'template',isMobile) --->
				<button id="<cfoutput>#contentTemplateStr#</cfoutput>DesktopButton" name="<cfoutput>#contentTemplateStr#</cfoutput>DesktopButton" class="k-button k-primary" type="button" onClick="createAdminInterfaceWindow(53,<cfoutput>#themeId#</cfoutput>,'<cfoutput>#contentTemplateStr#</cfoutput>Desktop',false);">Edit</button>
				
			</td>
		  </tr>
		<cfelse><!---<cfif session.isMobile>--->
		  <tr>
			<td align="right" class="<cfoutput>#thisContentClass#</cfoutput>" style="width: 20%"> 
				<label for="<cfoutput>#contentTemplateStr#</cfoutput>Desktop"><cfoutput>#contentTemplateLabel#</cfoutput> Desktop:</label>
			</td>
			<td class="<cfoutput>#thisContentClass#</cfoutput>">
				<!-- Editor -->
				<!--- Link to tinyMce editor: createAdminInterfaceWindow(53,themeId,'template',isMobile) --->
				<button id="<cfoutput>#contentTemplateStr#</cfoutput>DesktopButton" name="<cfoutput>#contentTemplateStr#</cfoutput>DesktopButton" class="k-button k-primary" type="button" onClick="createAdminInterfaceWindow(53,<cfoutput>#themeId#</cfoutput>,'<cfoutput>#contentTemplateStr#</cfoutput>Desktop',false);">Edit</button>
			</td>
		  </tr>
		</cfif>
		  <!--- Mobile header code (for both mobile and desktop devices) --->
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
				<label for="<cfoutput>#contentTemplateStr#</cfoutput>Mobile"><cfoutput>#contentTemplateLabel#</cfoutput> Mobile:</label>
			</td>
		   </tr>
		   <tr>
			<td class="<cfoutput>#thisContentClass#</cfoutput>" colspan="2">
				<!-- Editor -->
				<!--- Link to tinyMce editor: createAdminInterfaceWindow(53,themeId,'template',isMobile) --->
				<button id="<cfoutput>#contentTemplateStr#</cfoutput>DesktopButton" name="<cfoutput>#contentTemplateStr#</cfoutput>MobileButton" class="k-button k-primary" type="button" onClick="createAdminInterfaceWindow(53,<cfoutput>#themeId#</cfoutput>,'<cfoutput>#contentTemplateStr#</cfoutput>Mobile',true);">Edit</button>
			</td>

		  </tr>
		<cfelse><!---<cfif session.isMobile>--->
		  <tr>
			<td align="right" class="<cfoutput>#thisContentClass#</cfoutput>" style="width: 20%"> 
				<label for="<cfoutput>#contentTemplateStr#</cfoutput>Mobile"><cfoutput>#contentTemplateLabel#</cfoutput> Mobile</label>
			</td>
			<td class="<cfoutput>#thisContentClass#</cfoutput>">
				<!-- Editor -->
				<!--- Link to tinyMce editor: createAdminInterfaceWindow(53,themeId,'template',isMobile) --->
				<button id="<cfoutput>#contentTemplateStr#</cfoutput>MobileButton" name="<cfoutput>#contentTemplateStr#</cfoutput>MobileButton" class="k-button k-primary" type="button" onClick="createAdminInterfaceWindow(53,<cfoutput>#themeId#</cfoutput>,'<cfoutput>#contentTemplateStr#</cfoutput>Mobile',true);">Edit</button>
			</td>
		  </tr>
		</cfif> 
		<cfsilent>
			<!---//***********************************************************************************************
								Blog Calender Pod
			//************************************************************************************************--->


			<!--- This logic is easily reproducable with a small number of variables. Set them here. --->
			<cfset contentTemplateStr = "calendarPod">
			<cfset contentTemplateLabel = "Calendar Pod">
			<cfset entityId = "ThemeId">
			<cfset entityName = "ThemeName">
			<cfset useEnableButton = true>
			<!--- You need to enter the description manually --->

		  	<!--- Set the class for alternating rows. --->
		  	<!---After the first row, the content class should be the current class. --->
		  	<cfset thisContentClass = HtmlUtilsObj.getKendoClass(thisContentClass)>
		  </cfsilent> 
		  <tr height="1px">
			  <td align="left" valign="top" colspan="2" class="border <cfoutput>#thisContentClass#</cfoutput>"></td>
		  </tr>
		  <tr height="1px">
			  <td align="left" valign="top" colspan="2" class="<cfoutput>#thisContentClass#</cfoutput> setting-title"><b>Calendar Pod</b></td>
		  </tr>
		  <tr height="1px">
			  <td align="left" valign="top" colspan="2" class="border <cfoutput>#thisContentClass#</cfoutput>"></td>
		  </tr>
		  <tr>
			<td colspan="2" class="<cfoutput>#thisContentClass#</cfoutput>"> 
				The calander pod displays your blog posts in a calendar format. You can't edit this interface as it is a JavaScript based application, however, you may disable it if you don't want it shown. 
			</td>
		  </tr>
		  <tr height="1px">
			  <td align="left" valign="top" colspan="2" class="<cfoutput>#thisContentClass#</cfoutput>"></td>
		  </tr>
		<cfif useEnableButton>
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
				<label for="<cfoutput>#contentTemplateStr#</cfoutput>Enable">Enable:</label>
			</td>
		   </tr>
		   <tr>
			<td class="<cfoutput>#thisContentClass#</cfoutput>" colspan="2">
				
				<input type="checkbox" id="<cfoutput>#contentTemplateStr#</cfoutput>Enable" name="<cfoutput>#contentTemplateStr#</cfoutput>Enable" checked>
			</td>
		  </tr>
		<cfelse><!---<cfif session.isMobile>--->
		  <tr>
			<td align="right" class="<cfoutput>#thisContentClass#</cfoutput>" style="width: 20%"> 
				<label for="<cfoutput>#contentTemplateStr#</cfoutput>Enable">Enable:</label>
			</td>
			<td class="<cfoutput>#thisContentClass#</cfoutput>">
				
				<input type="checkbox" id="<cfoutput>#contentTemplateStr#</cfoutput>Enable" name="<cfoutput>#contentTemplateStr#</cfoutput>Enable" checked>
			</td>
		  </tr>
		</cfif><!---<cfif session.isMobile>--->	
		</cfif><!---<cfif useEnableButton>--->
		  <!-- Border -->
		  <tr height="2px">
			  <td align="left" valign="top" colspan="<cfoutput>#thisColSpan#</cfoutput>" class="<cfoutput>#thisContentClass#</cfoutput>"></td>
		  </tr>
		  
		</table>
	</div>
			
	<!---//***********************************************************************************************
						Footer
	//************************************************************************************************--->
				
	<button type="button" class="collapsible k-header">Footer</button>
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
			  <td align="left" valign="top" colspan="2" class="border <cfoutput>#thisContentClass#</cfoutput>"></td>
		  </tr>
		  
		  <tr height="1px">
			  <td align="left" valign="top" colspan="2" class="<cfoutput>#thisContentClass#</cfoutput>"></td>
		  </tr>
		  <tr height="1px">
			  <td align="left" valign="top" colspan="2" class="<cfoutput>#thisContentClass#</cfoutput> setting-title"><b>Footer Image</b></td>
		  </tr>
		  <tr>
			<td colspan="2"> 
				The footer logo is typcially placed above the footer content, which may be editted below.
			</td>
		  </tr>
		  <tr height="1px">
			  <td align="left" valign="top" colspan="2" class="<cfoutput>#thisContentClass#</cfoutput>"></td>
		  </tr>
			  
		<cfif session.isMobile>
		  <tr valign="middle">
			<td class="<cfoutput>#thisContentClass#</cfoutput>" colspan="2">
				<label for="footerImage">Footer Logo:</label>
			</td>
		   </tr>
		   <tr>
			<td class="<cfoutput>#thisContentClass#</cfoutput>" colspan="2">
				<cfoutput>
				<input type="text" id="footerImage" name="footerImage" value="#footerImage#" class="k-textbox" style="width:75%" onclick="createAdminInterfaceWindow(35, #themeId#,'footerImage','#footerImage#');">
				</cfoutput>
			</td>
		  </tr>
		<cfelse><!---<cfif session.isMobile>--->
		  <tr>
			<td align="right" class="<cfoutput>#thisContentClass#</cfoutput>" style="width: 20%"> 
				<label for="footerImage">Footer Logo:</label>
			</td>
			<td class="<cfoutput>#thisContentClass#</cfoutput>">
				<cfoutput>
				<input type="text" id="footerImage" name="footerImage" value="#footerImage#" class="k-textbox" style="width:75%" onclick="createAdminInterfaceWindow(35, #themeId#,'footerImage','#footerImage#');">
				</cfoutput>
			</td>
		  </tr>
		</cfif>
		  <!-- Border -->
		  <tr height="2px">
			  <td align="left" valign="top" colspan="<cfoutput>#thisColSpan#</cfoutput>" class="<cfoutput>#thisContentClass#</cfoutput>"></td>
		  </tr>
			  
		<cfsilent>
		<!--- This logic is easily reproducable with a small number of variables. Set them here. --->
		<cfset contentTemplateStr = "compositeFooter">
		<cfset contentTemplateLabel = "Composite Footer">
		<cfset entityId = "ThemeId">
		<cfset entityName = "ThemeName">
		<cfset useEnableButton = true>
		<!--- You need to enter the description manually --->
			
	    <!--- Set the class for alternating rows. --->
	    <!--- After the first row, the content class should be the current class. --->
	    <cfset thisContentClass = HtmlUtilsObj.getKendoClass('')>
	  </cfsilent> 
		 <tr height="1px">
			  <td align="left" valign="top" colspan="2" class="<cfoutput>#thisContentClass#</cfoutput>"></td>
		  </tr>
		  <tr height="1px">
			  <td align="left" valign="top" colspan="2" class="<cfoutput>#thisContentClass#</cfoutput> setting-title"><b>Composite Footer</b></td>
		  </tr>
		  <tr>
			<td colspan="2"> 
				Typically, the composite footer has a site logo along with a site description. However, you can also edit the entire footer using the editors below. 
			</td>
		  </tr>
		  <tr height="1px">
			  <td align="left" valign="top" colspan="2" class="<cfoutput>#thisContentClass#</cfoutput>"></td>
		  </tr>
		<cfif useEnableButton>
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
				<label for="<cfoutput>#contentTemplateStr#</cfoutput>Enable">Enable:</label>
			</td>
		   </tr>
		   <tr>
			<td class="<cfoutput>#thisContentClass#</cfoutput>" colspan="2">
				<input type="checkbox" id="<cfoutput>#contentTemplateStr#</cfoutput>Enable" name="<cfoutput>#contentTemplateStr#</cfoutput>Enable" checked>
			</td>
		  </tr>
		<cfelse><!---<cfif session.isMobile>--->
		  <tr>
			<td align="right" class="<cfoutput>#thisContentClass#</cfoutput>" style="width: 20%"> 
				<label for="<cfoutput>#contentTemplateStr#</cfoutput>Enable">Enable:</label>
			</td>
			<td class="<cfoutput>#thisContentClass#</cfoutput>">
				<input type="checkbox" id="<cfoutput>#contentTemplateStr#</cfoutput>Enable" name="<cfoutput>#contentTemplateStr#</cfoutput>Enable" checked>
			</td>
		  </tr>
		</cfif><!---<cfif session.isMobile>--->	
		</cfif><!---<cfif useEnableButton>--->
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
	
		<!--- Desktop header code (for both mobile and desktop devices) --->
		<cfif session.isMobile>
		  <tr valign="middle">
			<td class="<cfoutput>#thisContentClass#</cfoutput>" colspan="2">
				<label for="<cfoutput>#contentTemplateStr#</cfoutput>Desktop"><cfoutput>#contentTemplateLabel#</cfoutput> Desktop:</label>
			</td>
		   </tr>
		   <tr>
			<td class="<cfoutput>#thisContentClass#</cfoutput>" colspan="2">
				<!-- Editor -->
				<!--- Link to tinyMce editor: createAdminInterfaceWindow(53,themeId,'template',isMobile) --->
				<button id="<cfoutput>#contentTemplateStr#</cfoutput>DesktopButton" name="<cfoutput>#contentTemplateStr#</cfoutput>DesktopButton" class="k-button k-primary" type="button" onClick="createAdminInterfaceWindow(53,<cfoutput>#themeId#</cfoutput>,'<cfoutput>#contentTemplateStr#</cfoutput>Desktop',false);">Edit</button>
				
			</td>
		  </tr>
		<cfelse><!---<cfif session.isMobile>--->
		  <tr>
			<td align="right" class="<cfoutput>#thisContentClass#</cfoutput>" style="width: 20%"> 
				<label for="<cfoutput>#contentTemplateStr#</cfoutput>Desktop"><cfoutput>#contentTemplateLabel#</cfoutput> Desktop:</label>
			</td>
			<td class="<cfoutput>#thisContentClass#</cfoutput>">
				<!-- Editor -->
				<!--- Link to tinyMce editor: createAdminInterfaceWindow(53,themeId,'template',isMobile) --->
				<button id="<cfoutput>#contentTemplateStr#</cfoutput>DesktopButton" name="<cfoutput>#contentTemplateStr#</cfoutput>DesktopButton" class="k-button k-primary" type="button" onClick="createAdminInterfaceWindow(53,<cfoutput>#themeId#</cfoutput>,'<cfoutput>#contentTemplateStr#</cfoutput>Desktop',false);">Edit</button>
			</td>
		  </tr>
		</cfif>
		  <!--- Mobile header code (for both mobile and desktop devices) --->
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
				<label for="<cfoutput>#contentTemplateStr#</cfoutput>Mobile"><cfoutput>#contentTemplateLabel#</cfoutput> Mobile:</label>
			</td>
		   </tr>
		   <tr>
			<td class="<cfoutput>#thisContentClass#</cfoutput>" colspan="2">
				<!-- Editor -->
				<!--- Link to tinyMce editor: createAdminInterfaceWindow(53,themeId,'template',isMobile) --->
				<button id="<cfoutput>#contentTemplateStr#</cfoutput>DesktopButton" name="<cfoutput>#contentTemplateStr#</cfoutput>MobileButton" class="k-button k-primary" type="button" onClick="createAdminInterfaceWindow(53,<cfoutput>#themeId#</cfoutput>,'<cfoutput>#contentTemplateStr#</cfoutput>Mobile',true);">Edit</button>
			</td>

		  </tr>
		<cfelse><!---<cfif session.isMobile>--->
		  <tr>
			<td align="right" class="<cfoutput>#thisContentClass#</cfoutput>" style="width: 20%"> 
				<label for="<cfoutput>#contentTemplateStr#</cfoutput>Mobile"><cfoutput>#contentTemplateLabel#</cfoutput> Mobile</label>
			</td>
			<td class="<cfoutput>#thisContentClass#</cfoutput>">
				<!-- Editor -->
				<!--- Link to tinyMce editor: createAdminInterfaceWindow(53,themeId,'template',isMobile) --->
				<button id="<cfoutput>#contentTemplateStr#</cfoutput>MobileButton" name="<cfoutput>#contentTemplateStr#</cfoutput>MobileButton" class="k-button k-primary" type="button" onClick="createAdminInterfaceWindow(53,<cfoutput>#themeId#</cfoutput>,'<cfoutput>#contentTemplateStr#</cfoutput>Mobile',true);">Edit</button>
			</td>
		  </tr>
		</cfif> 
		</table>
	</div>
	<!---//***********************************************************************************************
						Themes Interface Footer Custom Scripts
	//************************************************************************************************--->
	<button type="button" class="collapsible k-header">Custom Footer Scripts</button>
	<div class="content k-content">
		<table align="center" class="k-content" width="100%" cellpadding="2" cellspacing="0">
		  <cfsilent>
			<!---The first content class in the table should be empty. --->
			<cfset thisContentClass = HtmlUtilsObj.getKendoClass('')>
			<!--- Set the colspan property for borders --->
			<cfset thisColSpan = "2">

		  <!--- Set the class for alternating rows. --->
		  <!---After the first row, the content class should be the current class. --->
		  <cfset thisContentClass = HtmlUtilsObj.getKendoClass(thisContentClass)>
		  </cfsilent>
		  <tr height="1px">
			  <td align="left" valign="top" colspan="2" class="<cfoutput>#thisContentClass#</cfoutput>"></td>
		  </tr>
		  <tr>
			<td colspan="2"> 
				<p>You can place optional custom HTML or scripts at the end of the page. This is often done when you need to embed custom libraries that need to have the scripts placed at the very bottom of the page.</p>
				<p>If you want this custom script to be applied to all themes, click on the 'Apply across all themes' checkbox.</p>
			</td>
		  </tr>
		  <!-- Border -->
		  <tr height="2px">
			  <td align="left" valign="top" colspan="<cfoutput>#thisColSpan#</cfoutput>" class="border <cfoutput>#thisContentClass#</cfoutput>"></td>
		  </tr>
		  <cfsilent>
		  <!--- Set the class for alternating rows. --->
		  <!---After the first row, the content class should be the current class. --->
		  <cfset thisContentClass = HtmlUtilsObj.getKendoClass(thisContentClass)>
		  </cfsilent>
		
		  <!-- Border -->
		  <tr height="2px">
			  <td align="left" valign="top" colspan="<cfoutput>#thisColSpan#</cfoutput>" class="border <cfoutput>#thisContentClass#</cfoutput>"></td>
		  </tr>
			  
		<cfif session.isMobile>
		  <tr valign="middle">
			<td class="<cfoutput>#thisContentClass#</cfoutput>" colspan="2">
				<label for="customFooterHtml">Custom Footer HTML:</label>
			</td>
		   </tr>
		   <tr>
			<td class="<cfoutput>#thisContentClass#</cfoutput>" colspan="2">
				<!--- Hidden input to store the code from the code editor --->
				<input type="hidden" name="customFooterHtmlCode" id="customFooterHtmlCode" value=""/>
				<!-- Editor -->
				<button id="customFooterHtmlButton" name="customFooterHtmlButton" class="k-button k-primary" type="button" onClick="javascript:createAdminInterfaceWindow(52,<cfoutput>#themeId#</cfoutput>, 'customFooterHtml',false)">Edit</button>
			</td>
		  </tr>
		<cfelse><!---<cfif session.isMobile>--->
		  <tr>
			<td align="right" class="<cfoutput>#thisContentClass#</cfoutput>" style="width: 20%"> 
				<label for="customFooterHtml">Custom Footer HTML:</label>
			</td>
			<td class="<cfoutput>#thisContentClass#</cfoutput>">
				<!--- Hidden input to store the code from the code editor --->
				<input type="hidden" name="customFooterHtmlCode" id="customFooterHtmlCode" value=""/>
				<!--- Link to tinyMce editor: createAdminInterfaceWindow(52,themeId,'template',isMobile) --->
				<!-- Editor -->
				<button id="customFooterHtmlButton" name="customFooterHtmlButton" class="k-button k-primary" type="button" onClick="javascript:createAdminInterfaceWindow(52,<cfoutput>#themeId#</cfoutput>, 'customFooterHtml',false)">Edit</button>
			</td>
		  </tr>
		</cfif>
		  <!-- Border -->
		  <tr height="2px">
			  <td align="left" valign="top" colspan="<cfoutput>#thisColSpan#</cfoutput>" class="<cfoutput>#thisContentClass#</cfoutput>"></td>
		  </tr>
		<cfif session.isMobile>
		  <tr valign="middle">
			<td class="<cfoutput>#thisContentClass#</cfoutput>" colspan="2">
				<label for="applyCustomFooterHtmlToAllThemes">Apply across all themes:</label>
			</td>
		   </tr>
		   <tr>
			<td class="<cfoutput>#thisContentClass#</cfoutput>" colspan="2">
				<input type="checkbox" id="applyCustomFooterHtmlToAllThemes" name="applyCustomFooterHtmlToAllThemes" <cfif customFooterApplyAcrossThemes>checked</cfif>>
			</td>
		  </tr>
		<cfelse><!---<cfif session.isMobile>--->
		  <tr>
			<td align="right" class="<cfoutput>#thisContentClass#</cfoutput>" style="width: 20%"> 
				<label for="applyCustomFooterHtmlToAllThemes">Apply across all themes:</label>
			</td>
			<td class="<cfoutput>#thisContentClass#</cfoutput>">
				 <input type="checkbox" id="applyCustomFooterHtmlToAllThemes" name="applyCustomFooterHtmlToAllThemes" <cfif favIconHtmlApplyAcrossThemes>checked</cfif>>
			</td>
		  </tr>
		</cfif>
			  
		  <!-- Border -->
		  <tr height="2px">
			<td align="left" valign="top" colspan="<cfoutput>#thisColSpan#</cfoutput>" class="<cfoutput>#thisContentClass#</cfoutput>"></td>
		  </tr>
		</table>
	</div>
	<br/><br/>
	<button id="themeSubmit" name="themeSubmit" class="k-button k-primary" type="button">Submit</button> 
			  
	<!--- Put some space at the end of the window --->
	<br/><br/><br/>
			  
	</form>