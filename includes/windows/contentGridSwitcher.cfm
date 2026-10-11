<cfsilent>
<!--- Switcher shown at the top of the Blog Posts (window 5), Pages (57) and Page Collections (68) grids, so you can move
between them without closing one window and finding the other in the menu. 2026-10-09: added after repeatedly opening
the Posts grid when the Pages grid was the one needed.
Uses Kendo's own button-group classes (k-button-group, k-button, k-state-active) rather than the ButtonGroup widget,
since the trimmed admin Kendo bundle may not include that widget - the classes are in every Kendo theme.
Include with currentGridWindowId set to 5, 57 or 68. --->
<cfparam name="currentGridWindowId" default="5">
<cfset contentGrids = [
	{ id: 5, label: "Blog Posts", windowName: "PostsWindow" },
	{ id: 57, label: "Pages", windowName: "PageWindow" },
	{ id: 68, label: "Page Collections", windowName: "configurePageCollectionsWindow" }
]>
<cfset currentGridWindowName = "">
<cfloop array="#contentGrids#" item="thisGrid">
	<cfif thisGrid.id eq currentGridWindowId>
		<cfset currentGridWindowName = thisGrid.windowName>
	</cfif>
</cfloop>
</cfsilent>
<div class="k-button-group" role="group" aria-label="Switch grid">
<cfoutput><cfloop array="#contentGrids#" item="thisGrid">
	<button type="button" class="k-button<cfif thisGrid.id eq currentGridWindowId> k-state-active</cfif>"<cfif thisGrid.id eq currentGridWindowId> aria-pressed="true"<cfelse> onclick="switchContentGrid(#thisGrid.id#, '#currentGridWindowName#');"</cfif>>#thisGrid.label#</button>
</cfloop></cfoutput>
</div>
<br/><br/>
<script>
	<!--- Opens the other grid first, then closes this one (closing destroys the window - see createAdminInterfaceWindow),
	so the new window is already on its way while the old one goes. --->
	function switchContentGrid(targetWindowId, currentWindowName) {
		createAdminInterfaceWindow(targetWindowId);
		var currentWindow = $("#" + currentWindowName).data("kendoWindow");
		if (currentWindow) {
			currentWindow.close();
		}
	}
</script>
