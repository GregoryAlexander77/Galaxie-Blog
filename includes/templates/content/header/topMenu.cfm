							<cfsilent><!--- 
							Needed arguments: 
							pageId: using the pageId found in the root index.cfm template
							menuDivName: either topMenu or fixedNavMenu
							session.isMobile (true/false)
							This menu is used on two different div's, and each div has a different menu script for mobile and desktop. The topMenu is invoked when the page initially loads and is at the top of the page underneath the title, and the fixedNavMenu is fixed to the very top of the page when the user scrolls down the page. The menu's should be identical but there are two different scripts.
							We need to set a numeric value to determine what div is calling the toggleSideBarPanel javascript menu as our "javascript:toggleSideBarPanel('menuDivName'); statement is failing with a single qouted string. Send 1 for topMenu, and 2 for the fixedNavMenu.
							--->
							<cfif menuDivName eq 'topMenu'>
								<cfset layerNumber = 1>
							<cfelseif menuDivName eq 'fixedNavMenu'>
								<cfset layerNumber = 2>
							<cfelse>
								<!--- Used in the admin interface when previewing output --->
								<cfset layerNumber = 3>
							</cfif>
							<!--- Don't defer the script when in preview mode --->
							<cfif menuDivName eq 'topMenuPreview'>
								<cfset scriptTypeString = "text/javascript">
							</cfif>
								
							<!--- Get the parent categories --->
							<cfset parentCategories = application.blog.getCategories(parentCategory=1)>
							<!--- Get the themes. This is a HQL array --->
							<cfset themeNames = application.blog.getThemeNames()>
							<!--- Note: do not cache this template. There would be no gain due to the number of conditional blocks requred.--->
							</cfsilent>
							<nav>
								<!--- Include the navigation menu content template. Note: the Kendo menu should not be lazy loaded and needs to be loaded immediately. --->
								<cfinclude template="navigationMenu.cfm">
								<script type="text/javascript">
									$(document).ready(function() {	
										$("#<cfoutput>#menuDivName#</cfoutput>").kendoMenu();
									});//..document.ready
									<!--- A desktop menu that wraps (a narrow window or a tablet, 2026-10-22, owner): Categories and the collections menu
									become the phone's one combined dropdown, and the admin icon goes when the member Sign in is there. Tried again
									whenever the window changes size, so the full menu comes back when there is room. Defined once for both menus. --->
									if (!window.galaxieCompactMenus) {
										window.galaxieCompactMenus = function() {
											function wraps(menu) {
												var items = menu.children("li:visible");
												if (items.length < 2) { return false; }
												var top = items.first()[0].getBoundingClientRect().top;
												var wrapped = false;
												items.each(function() { if (this.getBoundingClientRect().top > top + 5) { wrapped = true; } });
												return wrapped;
											}
											<!--- Still too wide beside a wide logo, such as the Site Wizard's name logo (2026-10-25, owner): the logo stops
											spanning both rows of the desktop header, so the menu row runs the full width under it rather than one icon
											wrapping. Only the header under the title; the bar fixed to the top when scrolling has no logo row. --->
											function menuBelowLogo(below) {
												var logo = document.getElementById("logo"), holder = document.getElementById("topMenuContainer");
												if (!logo || !holder || logo.parentNode === holder.parentNode) { return; }
												logo.rowSpan = below ? 1 : 2;
												holder.colSpan = below ? 2 : 1;
											}
											$("#topMenu, #fixedNavMenu").each(function() {
												var menu = $(this), isTop = this.id === "topMenu";
												menu.find("> li.galaxieMenuSplit, > li.galaxieAdminMenuItem").show();
												menu.find("> li.galaxieMenuCombined").hide();
												if (isTop) { menuBelowLogo(false); }
												if (!wraps(menu)) { return; }
												if (menu.find("> li.galaxieMenuCombined").length) {
													menu.find("> li.galaxieMenuSplit").hide();
													menu.find("> li.galaxieMenuCombined").show();
												}
												if (menu.find("> li.galaxieMemberMenuItem").length) {
													menu.find("> li.galaxieAdminMenuItem").hide();
												}
												if (isTop && wraps(menu)) { menuBelowLogo(true); }
											});
										};
										var galaxieCompactTimer = null;
										$(window).on("load", function() { galaxieCompactMenus(); setTimeout(galaxieCompactMenus, 1500); });
										$(window).on("resize", function() { clearTimeout(galaxieCompactTimer); galaxieCompactTimer = setTimeout(galaxieCompactMenus, 250); });
									}
								</script>
							<cfif session.isMobile or menuDivName eq 'fixedNavMenu'>				
								<style>
								  .k-sprite {
									text-indent: 0;
									font-size: .75em;
								  }
								</style>
							</cfif>
							</nav>