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
								<!--- Include the navigation menu content template --->
								<cfinclude template="navigationMenu.cfm">
								<script type="<cfoutput>#scriptTypeString#</cfoutput>">
									$(document).ready(function() {	
										$("#<cfoutput>#menuDivName#</cfoutput>").kendoMenu();
									});//..document.ready
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