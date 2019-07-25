							<cfsilent><!--- 
							Needed arguments: session.isMobile (true/false)
							divName: either topMenu or fixedNavHeader
							This menu is used on two different div's, and each div has a different menu script for mobile and desktop. 
							We need to set a numeric value to determine what div is calling the toggleSideBarPanel javascript menu as our "javascript:toggleSideBarPanel('divName'); statement is failing with a single qouted string. Send 1 for topManu, and 2 for the fixedNavHeader.
							--->
							<cfif divName eq 'topMenu'>
								<cfset layerNumber = 1>
							<cfelseif divName eq 'fixedNavHeader'>
								<cfset layerNumber = 2>
							</cfif>
							</cfsilent>
							<script>
								// Convert the ColdFusion divName variable into something that we can use in javascript. We'll use this to determine what icons to place in the menu.
								topMenuDivName = "#<cfoutput>#divName#</cfoutput>";
								
								// Mobile clients will have the search and hamburger icons automatically whereas the desktop clients will only show the hamburger icon when the screen width exceeds the breakpoint value.
								if (isMobile || $(window).width() <= breakpoint){
									
									$("#<cfoutput>#divName#</cfoutput>").kendoMenu({
										dataSource: [
											// Note: the first menu option should not have spaces if you want the menu to be aligned with the blog text.
											{
												text: "Menu",
												items: [
													<cfif divName eq 'fixedNavHeader'>{ text: "Top", spriteCssClass: "fa fa-arrow-circle-up", url: "javascript:scrollToTop();" },</cfif>
													{ text: "<cfoutput>#htmlEditFormat(application.blog.getProperty("blogTitle"))#</cfoutput>", url: "<cfoutput>#application.rootUrl#</cfoutput>" }<cfif application.parentSiteName neq '' and application.parentSiteLink neq ''></cfif>,
													<cfif application.parentSiteName neq '' and application.parentSiteLink neq ''>{ text: "<cfoutput>#application.parentSiteName#</cfoutput>", url: "<cfoutput>#application.parentSiteLink#</cfoutput>" },</cfif>
													{ text: "Contact", url: "<cfoutput>#application.baseUrl#</cfoutput>/?contact"}<cfif divName eq 'fixedNavHeader'>,</cfif>
													<cfif divName eq 'fixedNavHeader'>{ text: "Bottom", spriteCssClass: "fa fa-arrow-circle-down", url: "javascript:scrollToBottom();" }</cfif>
												]
											},
											{
												text: "About", 
												items: [
													{ text: "About this Blog", url: "javascript:createAboutWindow(1);" },
													{ text: "Personal Biography", url: "javascript:createAboutWindow(2);" },
													{ text: "Download", url: "javascript:createAboutWindow(3);" },
												]
											},
											{
												text: "Themes",
												items: [
													<cfset themeLoopCount=1><cfloop list="#application.defaultKendoThemes#" index="defaultKendoTheme"><cfoutput>
													{ text: "#listGetAt(application.customThemeNames,themeLoopCount)#", url: "#application.baseUrl#?theme=#defaultKendoTheme#"},<cfset themeLoopCount=themeLoopCount+1></cfoutput></cfloop>
												]
											},
											{ text: "", spriteCssClass: "fa fa-search", url: "javascript:createSearchWindow();"},
											{ text: "", spriteCssClass: "fa fa-bars", url: "javascript:toggleSideBarPanel(<cfoutput>#layerNumber#</cfoutput>);" }
										]//..dataSource: [
									});//..$("#topMenu").kendoMenu({
																				   
								} else { //..if (isMobile || $(window).width() <= breakpoint){

									$("#<cfoutput>#divName#</cfoutput>").kendoMenu({
										dataSource: [
											// Note: the first menu option should not have spaces if you want the menu to be aligned with the blog text.
											{
												text: "Menu",
												items: [
													<cfif divName eq 'fixedNavHeader'>{ text: "Top", spriteCssClass: "fa fa-arrow-circle-up", url: "javascript:scrollToTop();" },</cfif>
													{ text: "<cfoutput>#htmlEditFormat(application.blog.getProperty("blogTitle"))#</cfoutput>", url: "<cfoutput>#application.rootUrl#</cfoutput>" }<cfif application.parentSiteName neq '' and application.parentSiteLink neq ''></cfif>,
													<cfif application.parentSiteName neq '' and application.parentSiteLink neq ''>{ text: "<cfoutput>#application.parentSiteName#</cfoutput>", url: "<cfoutput>#application.parentSiteLink#</cfoutput>" },</cfif>
													{ text: "Contact", url: "<cfoutput>#application.baseUrl#</cfoutput>/?contact"}<cfif divName eq 'fixedNavHeader'>,</cfif>
													<cfif divName eq 'fixedNavHeader'>{ text: "Bottom", spriteCssClass: "fa fa-arrow-circle-down", url: "javascript:scrollToBottom();" }</cfif>
												]
											},
											{
												text: "About", 
												items: [
													{ text: "About this Blog", url: "javascript:createAboutWindow(1);" },
													{ text: "Personal Biography", url: "javascript:createAboutWindow(2);" },
													{ text: "Download", url: "javascript:createAboutWindow(3);" },
												]
											},
											{
												text: "Themes",
												items: [
													<cfset themeLoopCount=1><cfloop list="#application.defaultKendoThemes#" index="defaultKendoTheme"><cfoutput>
													{ text: "#listGetAt(application.customThemeNames,themeLoopCount)#", url: "#application.baseUrl#?theme=#defaultKendoTheme#"},<cfset themeLoopCount=themeLoopCount+1></cfoutput></cfloop>
												]
											}<cfif divName eq 'fixedNavHeader'>,
											{ text: "", spriteCssClass: "fa fa-search", url: "javascript:createSearchWindow();"},
											{ text: "", spriteCssClass: "fa fa-bars", url: "javascript:toggleSideBarPanel(<cfoutput>#layerNumber#</cfoutput>);" }
											</cfif>
										]//..dataSource: [
									});//..$("#topMenu").kendoMenu({
	
								}//..if (isMobile || $(window).width() <= breakpoint){
							</script>
							<cfif session.isMobile or divName eq 'fixedNavHeader'>							
							<style>
							  .k-sprite {
								text-indent: 0;
								font-size: .75em;
							  }
							</style>
							</cfif>