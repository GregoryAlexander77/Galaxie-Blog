<!--- Form submissions (window 85, 2026-10-13), opened with createAdminInterfaceWindow(85, webFormId). Newest first, in a grid -
Kendo when Kendo Professional is loaded, jsGrid otherwise (includes/grids/kendo|jsGrid/webFormSubmissions.cfm). Delete
removes a submission for good; Export downloads them all as CSV (ProxyController.cfc's exportWebFormSubmissions). --->
<cfset webFormId = val(URL.optArgs)>
<cfset webForm = application.webForms.getForm(webFormId = webFormId)>

<cfif structIsEmpty(webForm)>
	<p>That form no longer exists.</p>
<cfelse>
	<cfoutput>
	<p><b>#encodeForHtml(webForm.title)#</b></p>
	<p>
		<a class="k-button" href="#application.baseUrl#/common/cfc/ProxyController.cfc?method=exportWebFormSubmissions&amp;webFormId=#webForm.webFormId#&amp;csrfToken=#encodeForUrl(csrfToken)#">Export to CSV</a>
		<span class="k-form-hint">Opens in Excel or any spreadsheet. Deleting a submission removes it for good.</span>
	</p>
	</cfoutput>
	<cfif application.kendoCommercial>
		<cfinclude template="../../includes/grids/kendo/webFormSubmissions.cfm">
	<cfelse>
		<cfinclude template="../../includes/grids/jsGrid/webFormSubmissions.cfm">
	</cfif>
</cfif>
