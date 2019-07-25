<cfsetting enablecfoutputonly=true>
<cfprocessingdirective pageencoding="utf-8">

<cftry>
	
	<!--- Version 1 does not have the comprehensive information that version 1.15 has. --->
	<!--- Version is not defined in version 1.1 --->
	<cfif not isDefined("URL.version")>
	
		<cfset serviceURL = "http://www.gregoryalexander.com/common/services/gregorysBlog/version.cfm">
		<cfhttp url="#serviceURL#" result="result">
		<cfset data = xmlParse(result.fileContent)>
		<cfset latestVersion = data.version.number.xmlText>
		<cfset latestUpdate = data.version.versionDate.xmlText>
		<cfset latestDescription = data.version.description.xmlText>

		<cfif latestVersion neq application.blog.getVersion()>
			<cfoutput>
			<div style="margin: 15px 0; padding: 15px; border: 5px solid ##ffff00;; background-color: ##e4e961;">
			<p>
			<b>Your Gregory's Blog installation may be out of the date!</b><br/>
			The latest released version of Gregory's Blog is <b>#latestVersion#</b> updated on <b>#dateFormat(latestUpdate, 'long')#</b>.
			<p><b>Updates for this version include:</b></p>
			#latestDescription#
			</p>
			</cfoutput>
		<cfelse>
			<cfoutput><p>Your Gregory's Blog install is up to date!</p></cfoutput>
		</cfif>

	<!--- Version 1.15- provides more detail --->
	<cfelse>
		
			<cfset serviceURL = "http://www.gregoryalexander.com/common/services/gregorysBlog/version.cfm?version=#application.blog.getVersion()#">
			<cfhttp url="#serviceURL#" result="result">
			<cfset data = xmlParse(result.fileContent)>
			<cfset latestVersion = data.version.number.xmlText>
			<cfset latestUpdate = data.version.date.xmlText>
			<cfset latestDescription = data.version.description.xmlText>
			<cfset bugFix = data.version.bugFix.description.xmlText>
			<cfset bugFixSeverity = data.version.bugFix.severity.xmlText>
			<cfset filesChanged = data.version.filesChanged.xmlText>
			<cfset recommendedAction = data.version.recommendedAction.xmlText>
			<cfset recommendedMinimumAction = data.version.recommendedMinimumAction.xmlText>
			<cfset iniFileInstructions = data.version.iniFileInstructions.xmlText>
			<cfset actionAfterUpdate = data.version.actionAfterUpdate.xmlText>

			<cfif latestVersion neq application.blog.getVersion()>
				<cfoutput>
				<div style="margin: 15px 0; padding: 15px; border: 5px solid ##ffff00;; background-color: ##e4e961;">
				<p><b>Your Gregory's Blog version #application.blog.getVersion()# installation may be out of the date!</b><br/>
				The latest released version of Gregory's Blog is <b>#latestVersion#</b> updated on <b>#dateFormat(latestUpdate, 'long')#</b>.</p>
				<p><b>Updates for this version include:</b></p>
				<p>#latestDescription#</p>
				<cfif bugFix neq "">
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
			<cfelse>
				<cfoutput><p>Your Gregory's Blog install is up to date!</p></cfoutput>
			</cfif>
					
		</cfif>
				
	<cfcatch>
		<cfoutput><p>Unable to correctly contact the update site.</p></cfoutput>
	</cfcatch>
</cftry>