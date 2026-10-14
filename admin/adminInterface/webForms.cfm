<!--- Forms window (window 83, 2026-10-13): every form the blog owner has built, in a grid - Kendo when Kendo Professional is
loaded, jsGrid otherwise (includes/grids/kendo|jsGrid/webForms.cfm), like the other admin grids. New form and Edit open the
form editor (window 84); Submissions opens window 85. The work is done by application.webForms (common/cfc/WebForms.cfc)
through ProxyController.cfc. See doc/aiDraftArticles/eventsAndFormsDesign.cfm. --->
<script>
	<!--- Called by the form editor after a save, so the grid's titles and counts stay current. --->
	function refreshWebFormsWindow() {
		try {
			$("#webFormsWindow").data("kendoWindow").refresh();
		} catch (error) {
			<!--- The window may not be open. --->
		}
	}
</script>

<p>Forms collect information from your visitors: a signup form, a contact form, a request. Build a form here, then place it in a post or page with the Form button in the post editor. What people send is kept under Submissions.</p>
<p><button type="button" class="k-button k-primary" onclick="createAdminInterfaceWindow(84, 0);">New form</button></p>

<cfif application.kendoCommercial>
	<cfinclude template="../../includes/grids/kendo/webForms.cfm">
<cfelse>
	<cfinclude template="../../includes/grids/jsGrid/webForms.cfm">
</cfif>
