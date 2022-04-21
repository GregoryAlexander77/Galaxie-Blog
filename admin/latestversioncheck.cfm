<cfsetting enablecfoutputonly=true>
<cfprocessingdirective pageencoding="utf-8">
	
<!--- Note: we are starting from version one and moving towards the latest version --->

<!---<cftry>--->
		
	<cfset serviceURL = "http://www.gregoryalexander.com/common/services/gregorysBlog/version.cfm?version=<cfoutput>#application.blog.getVersion()#</cfoutput>">
	<cfhttp url="#serviceURL#" result="result">
	<cfset data = xmlParse(result.fileContent)>
	<cfset latestVersion = data.version.number.xmlText>
	<cfset latestUpdate = data.version.date.xmlText>
	<cfset latestShortDescription = data.version.shortDescription.xmlText>
	<cfset latestDescription = data.version.description.xmlText>
	<cfset bugFix = data.version.bugFix.description.xmlText>
	<cfset bugFixSeverity = data.version.bugFix.severity.xmlText>
	<cfset filesChanged = data.version.filesChanged.xmlText>
	<cfset recommendedAction = data.version.recommendedAction.xmlText>
	<cfset recommendedMinimumAction = data.version.recommendedMinimumAction.xmlText>
	<cfset iniFileInstructions = data.version.iniFileInstructions.xmlText>
	<cfset actionAfterUpdate = data.version.actionAfterUpdate.xmlText>
	<!---<cfset stringClass = data.version.stringClass.xmlText>--->
	<cfset nextUpdate = data.version.nextUpdate.xmlText>

	<cfif URL.type eq 'summary'>
		<cfif latestVersion eq application.blog.getVersion()>
			<cfoutput>
				<p class="k-block k-success-colored">You're running Galaxie Blog version #latestVersion#. Your version is up to date.</p>
			</cfoutput>
		<cfelse>
			<cfoutput>
				The latest released version of Galaxie Blog is <b>#latestVersion#</b> updated on <b>#dateFormat(latestUpdate, 'long')#
			</cfoutput>
		</cfif>
		<p>#latestShortDescription#</p>

	<cfelse><!---<cfif URL.type eq 'summary'>--->

		<cfif latestVersion neq application.blog.getVersion()>
			<cfoutput>
			<p><b>Your Galaxie Blog version #application.blog.getVersion()# installation is out of date.</b><br/>
			The latest released version of Galaxie Blog is <b>#latestVersion#</b> updated on <b>#dateFormat(latestUpdate, 'long')#</b>.</p>
			<p><b>Updates for this version include:</b></p>
			<p>#latestDescription#</p>
			<cfif bugFix neq "" and bugFixSeverity neq "">
				<p><b>Bug Fixes</b>:</p>
				<p>#bugFix#</p>
				<cfif bugFixSeverity neq "">
					<p><b>Bug Severity</b>:</p>
					<p>#bugFixSeverity#</p>
				</cfif><!---<cfif bugFixSeverity neq "">--->
			</cfif><!---<cfif bugFix neq "">--->
			<cfif filesChanged neq "">
				<p><b>Files Changed</b>:</p>
				<p>#filesChanged#</p>
			</cfif>
			<cfif recommendedAction neq "">
				<p><b>Recommended Action</b>:</p>
				<p>#recommendedAction#</p>
			</cfif>
			<cfif recommendedMinimumAction neq "">
				<p><b>Recommended Minimum Action</b>:</p>
				<p>#recommendedMinimumAction#</p>
			</cfif>
			<cfif iniFileInstructions neq "">
				<p><b>Ini File Instructions</b>:</p>
				<p>#iniFileInstructions#</p>
			</cfif>
			<cfif actionAfterUpdate neq "">
				<p><b>After Updating:</b>:</p>
				<p>#actionAfterUpdate#</p>
			</cfif>
			</cfoutput>
		</cfif>	

	</cfif><!---<cfif URL.type eq 'summary'>--->
				
	<!---<cfcatch>
		<cfoutput><p>Unable to correctly contact the update site.</p></cfoutput>
	</cfcatch>
</cftry>--->