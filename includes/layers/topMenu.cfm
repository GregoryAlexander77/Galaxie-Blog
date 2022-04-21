							<cfsilent><!--- 
							Needed arguments: session.isMobile (true/false)
							divName: either topMenu or fixedNavMenu
							This menu is used on two different div's, and each div has a different menu script for mobile and desktop. 
							We need to set a numeric value to determine what div is calling the toggleSideBarPanel javascript menu as our "javascript:toggleSideBarPanel('divName'); statement is failing with a single qouted string. Send 1 for topManu, and 2 for the fixedNavMenu.
							--->
							<cfif divName eq 'topMenu'>
								<cfset layerNumber = 1>
							<cfelseif divName eq 'fixedNavMenu'>
								<cfset layerNumber = 2>
							</cfif>
								
							<!--- Get the themes. This is a HQL array --->
							<cfset themeNames = application.blog.getThemeNames()>
								
							<!--- We are not going to cache this template. There would be no gain due to the number of conditional blocks requred.--->
								
							</cfsilent>
								<ul id="<cfoutput>#divName#</cfoutput>">
								<li class="toggleSidebarPanelButton">
									<a href="javascript:toggleSideBarPanel(<cfoutput>#layerNumber#</cfoutput>)" aria-label="Menu"><span class="fa fa-bars"></span></a>
								</li>
								<li>
									Menu
									<ul>
										<!--- Note: the first menu option should not have spaces if you want the menu to be aligned with the blog text. --->
										<cfif divName eq 'fixedNavMenu'><li onclick="javascript:scrollToTop();"><span class="fa fa-arrow-circle-up"></span> Top</li></cfif>
										<li><a href="http://www.gregoryalexander.com/blog/">Gregory's Blog</a></li>
										<li><a href="http://www.gregoryalexander.com/">Gregory Alexander Web Design</a></li>
										<li><a href="javascript:createAddCommentSubscribeWindow('', 'contact', <cfoutput>#session.isMobile#</cfoutput>);">Contact</a></li>
										<!--- or <li><a href="http://www.gregoryalexander.com/blog/?contact">Contact</a></li>--->
										<cfif divName eq 'fixedNavMenu'><li onclick="javascript:scrollToBottom();"><span class="fa fa-arrow-circle-down"></span> Bottom</li></cfif>
									</ul>
								</li>
								<li>
									About
									<ul>
										
										<li><a href="javascript:createAboutWindow(1);">About this Blog</a></li>
										<li><a href="javascript:createAboutWindow(2);">Personal Biography</a></li>
										<li><a href="javascript:createAboutWindow(3);">Download</a></li>
									</ul>
								</li>
								<!--- Only show the theme menu when a theme has not yet been selected. Once a theme has been selected, that becomes the only available theme. --->
								<cfif not selectedTheme>
								<li>
									Themes
									<ul>
										<cfloop from="1" to="#arrayLen(themeNames)#" index="i"><cfoutput><li><a href="#application.baseUrl#?theme=#themeNames[i]['ThemeAlias']#">#themeNames[i]['ThemeName']#</a></li></cfoutput></cfloop>
									</ul>
								</li>
								</cfif>
								<li>
								<!--- Admin. --->
								<a href="<cfoutput>#application.baseUrl#/admin/</cfoutput>" aria-label="<cfif not application.Udf.isLoggedIn()>Login<cfelse>Blog Administration</cfif>"><span class="k-icon k-i-user"></span></a>
								<!--- Allow the user to logout. --->
								<cfif application.Udf.isLoggedIn()>
									<ul>
										<li><a href="<cfoutput>#application.baseUrl#/admin/?logout=1</cfoutput>">Logout</a></li>
									</ul>
								</cfif>
								</li>
								<li class="siteSearchButton">
									<cfsilent>
									<!--- Set the font size of the search and menu icons. This logic sets the icons to be (2 for desktop, 0 for mobile) tenths of a percentage less than the font size of the menu font's above. --->
									<cfif kendoTheme eq 'office365'>
										<cfif session.isMobile>
											<cfset searchAndMenuFontSize = ".75em">
										<cfelse>
											<cfset searchAndMenuFontSize = ".8em">
										</cfif>
									<cfelse>
										<cfif session.isMobile>
											<cfset searchAndMenuFontSize = "1em">
										<cfelse>
											<cfset searchAndMenuFontSize = ".8em">
										</cfif>
									</cfif>
									</cfsilent>
									<a href="javascript:createSearchWindow();" aria-label="Search"><span class="fa fa-search" style="font-size:<cfoutput>#searchAndMenuFontSize#</cfoutput>"></span></a>
								</li>
							</ul>
							<script type="<cfoutput>#scriptTypeString#</cfoutput>">
								$(document).ready(function() {	
									$("#<cfoutput>#divName#</cfoutput>").kendoMenu();
								});//..document.ready
							</script>

							<cfif session.isMobile or divName eq 'fixedNavMenu'>							
							<style>
							  .k-sprite {
								text-indent: 0;
								font-size: .75em;
							  }
							</style>
							</cfif>