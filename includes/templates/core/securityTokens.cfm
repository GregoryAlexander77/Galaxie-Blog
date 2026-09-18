<!--- //**************************************************************************************************************
		Security token setup
//****************************************************************************************************************--->
<!--- Split out of coreLogic.cfm (item 7 of the index.cfm/coreLogic.cfm rewrite proposal) so each concern is easier to find. Assumes it is included from coreLogic.cfm, which is itself included from within a <cfsilent> block on index.cfm. --->

	<!--- Note: this is already put inside of a cfsilent tag on the index.cfm page --->
	<cfscript>
		// Preset the condensedGridView var to false. We will reset this when in category mode.
		condensedGridView = false;
		// The popular posts are shown in a scrollable card widget when on the blog landing page.
		showPopularPosts = false;
	</cfscript>
	<!--- The anonymousUserId may not be available if the user is masking stuff. Preset it --->
	<cfparam name="anonymousUserId" default="">
		
	<!--- //**************************************************************************************************************
			Create custom security token keys
	//*************************************************************************************************************** --->
		
	<!--- Use to delete the cookies for testing.
	<cfset exists= structdelete(session, 'encryptionKey', true)/>
	<cfset exists= structdelete(session, 'serviceKey', true)/>
	--->

	<!--- See if the encryptionKey and the serviceKey have been created in the session scope. If they don't exist, create them. --->
	<cfif not isDefined("session.encryptionKey") or not isDefined("session.serviceKey")>
		<!--- Create unique token keys --->
		<cfinvoke component="#ProxyControllerObj#" method="createTokenKeys" returnvariable="createTokenKeys" />
		<!--- Store the value in session cookies. --->
		<cfset session.encryptionKey = createTokenKeys.encryptionKey>
		<cfset session.serviceKey = createTokenKeys.serviceKey>
	</cfif>
			
