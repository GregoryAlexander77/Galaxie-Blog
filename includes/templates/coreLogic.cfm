	<!--- Note: this is already put inside of a cfsilent tag on the index.cfm page --->
	<!--- coreLogic.cfm is the orchestrator for this page's non-output logic. It used to hold all of it directly (419 lines covering four unrelated jobs back to back); it's now split into includes/templates/core/*.cfm by concern so each piece is easy to find. Behavior is unchanged. --->

	<cfinclude template="#application.baseUrl#/includes/templates/core/securityTokens.cfm">
	<cfinclude template="#application.baseUrl#/includes/templates/core/visitorTracking.cfm">

	<!--- //**************************************************************************************************************
			Determine what to get based upon the URL and set parameters to get the articles
	//********************************************************************************************************************

	Note: in order to debug- remove the cfsilent that wraps around this and the pageSettings.cfm template on the index.cfm page.
	--->

	<cfif postFound>
		<cfinclude template="#application.baseUrl#/includes/templates/core/postViewTracking.cfm">
		<cfinclude template="#application.baseUrl#/includes/templates/core/seoMetaTags.cfm">
		<cfinclude template="#application.baseUrl#/includes/templates/core/videoMetadata.cfm">
	</cfif><!---<cfif postFound>--->
