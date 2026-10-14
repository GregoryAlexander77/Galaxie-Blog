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
		<span class="k-form-hint">Opens in Excel or any spreadsheet. Deleting a submission removes it for good<cfif webForm.publicList>; Hide only leaves it out of the public sign-up list, and it keeps its spot under any choice limits</cfif>.</span>
	</p>
	</cfoutput>
	<!--- The public sign-up list (2026-10-13): the grids show a Hide/Show button when the form's list is public. --->
	<cfset webFormListIsPublic = webForm.publicList>
	<script>
		function setWebFormSubmissionHidden(webFormSubmissionId, hidden) {
			jQuery.ajax({
				type: 'post',
				url: '<cfoutput>#application.baseUrl#</cfoutput>/common/cfc/ProxyController.cfc?method=setWebFormSubmissionHidden',
				data: { csrfToken: '<cfoutput>#csrfToken#</cfoutput>', webFormSubmissionId: webFormSubmissionId, hidden: hidden },
				dataType: "json",
				success: function(response) {
					if (response && JSON.parse(response.success) == true) {
						try { $("#webFormSubmissionsWindow").data("kendoWindow").refresh(); } catch (error) {}
					} else {
						$.when(kendo.ui.ExtAlertDialog.show({ title: "Could not change it", message: (response && response.errorMessage) || "The submission could not be changed.", icon: "k-ext-warning", width: "<cfoutput>#application.kendoExtendedUiWindowWidth#</cfoutput>" }));
					}
				},
				error: function(jqXHR) {
					if (jqXHR.status === 403) { createLoginWindow(); }
				}
			});
		}
	</script>
	<cfif application.kendoCommercial>
		<cfinclude template="../../includes/grids/kendo/webFormSubmissions.cfm">
	<cfelse>
		<cfinclude template="../../includes/grids/jsGrid/webFormSubmissions.cfm">
	</cfif>
</cfif>
