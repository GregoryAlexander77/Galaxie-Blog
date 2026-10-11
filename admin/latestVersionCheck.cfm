<cfsetting enablecfoutputonly=true>
<!---
	Compares the installed version of the blog with the releases that are published on gregoryalexander.com.
	This is loaded into the Blog Updates window (blogUpdate.cfm), which also shows the state of the database and has the 'Update the database' button.

	There is only one file to read: /common/services/gregorysBlog/version.xml. It holds a list of every release and looks like this:

	<version>
		<!-- The flat elements below describe the latest release. They are only used by versions of the blog before 4.66, which read this file the old way. -->
		<number>4.66</number> ... <date>...</date>
		<releases>
			<release>
				<number>4.66</number>
				<date>9/30/2026</date>
				<shortDescription/> <description/> <bugFix><description/><severity/></bugFix> <filesChanged/> <recommendedAction/> <iniFileInstructions/> <recommendedMinimumAction/> <actionAfterUpdate/>
			</release>
			<release> ...the previous release... </release>
		</releases>
	</version>

	Nothing here is hardcoded to a version. The installed version is compared to every release in the list, so someone who is several versions behind sees the notes of every release that they have missed. To publish a new release, add a <release> to the list, and change the flat elements at the top to match.
	Note: versions are compared as decimals (4.5 is 4.50), like the database update scripts. Never release a 4.10 after a 4.9.
--->

<cfset installedVersion = application.blog.getVersion()>
<cfset serviceUrl = "https://www.gregoryalexander.com/common/services/gregorysBlog/version.xml">

<cfscript>
	// Returns the text of a child node, or an empty string if it is not there.
	function childText(node, name) {
		if (structKeyExists(arguments.node, arguments.name)) {
			return trim(arguments.node[arguments.name].xmlText);
		}
		return "";
	}

	// Turn a <release> node (or the flat <version> node of the old format) into a struct.
	function parseRelease(node) {
		var bugFixDescription = "";
		var bugFixSeverity = "";
		if (structKeyExists(arguments.node, "bugFix")) {
			bugFixDescription = childText(arguments.node.bugFix, "description");
			bugFixSeverity = childText(arguments.node.bugFix, "severity");
		}
		return {
			number: childText(arguments.node, "number"),
			date: childText(arguments.node, "date"),
			shortDescription: childText(arguments.node, "shortDescription"),
			description: childText(arguments.node, "description"),
			bugFix: bugFixDescription,
			bugFixSeverity: bugFixSeverity,
			filesChanged: childText(arguments.node, "filesChanged"),
			recommendedAction: childText(arguments.node, "recommendedAction"),
			recommendedMinimumAction: childText(arguments.node, "recommendedMinimumAction"),
			iniFileInstructions: childText(arguments.node, "iniFileInstructions"),
			actionAfterUpdate: childText(arguments.node, "actionAfterUpdate")
		};
	}
</cfscript>

<cftry>
	<cfhttp url="#serviceUrl#" result="result" method="get" timeout="10" redirect="true" throwOnError="false">
	<cfif left(result.statusCode, 3) neq "200">
		<cfthrow message="The update site returned '#result.statusCode#'.">
	</cfif>
	<!--- Remove anything before the first tag (ie a byte order mark), which the XML parser will not accept --->
	<cfset data = xmlParse(reReplace(result.fileContent, "^[^<]+", ""))>

	<!--- Read the list of releases. A file in the old flat format only describes the latest release, so use that as the only release. --->
	<cfset releases = []>
	<cfif structKeyExists(data.version, "releases")>
		<cfloop array="#data.version.releases.xmlChildren#" index="releaseNode">
			<cfset arrayAppend(releases, parseRelease(releaseNode))>
		</cfloop>
	<cfelse>
		<cfset arrayAppend(releases, parseRelease(data.version))>
	</cfif>
	<cfif not arrayLen(releases)>
		<cfthrow message="The update site did not list any releases.">
	</cfif>
	<!--- Newest first --->
	<cfset arraySort(releases, function(a, b) { return sgn(val(b.number) - val(a.number)); })>

	<cfset latest = releases[1]>
	<cfset missedReleases = []>
	<cfloop array="#releases#" index="release">
		<cfif val(release.number) gt val(installedVersion)>
			<cfset arrayAppend(missedReleases, release)>
		</cfif>
	</cfloop>

	<cfif arrayLen(missedReleases)>
		<cfoutput>
			<p class="k-block k-error-colored">Your Galaxie Blog installation is out of date. You are running version #encodeForHTML(installedVersion)# and the latest release is <b>#encodeForHTML(latest.number)#</b><cfif isDate(latest.date)>, which was released on #dateFormat(latest.date, 'long')#</cfif>.</p>
			<p class="k-block k-warning-colored">When updating the files, be sure not to overwrite your '/org/camden/blog/blog.ini.cfm' file! Doing so will reset your blog's settings and start the installer again.<br/>
			As with any software update, please back up the codebase and the database first.</p>

			<cfloop array="#missedReleases#" index="release">
				<h4>Version #encodeForHTML(release.number)#<cfif isDate(release.date)> (#dateFormat(release.date, 'long')#)</cfif></h4>
				<cfif len(release.shortDescription)><p>#release.shortDescription#</p></cfif>
				<cfif len(release.description)>#release.description#</cfif>
				<cfif len(release.bugFix)>
					<p><b>Bug fixes</b><cfif len(release.bugFixSeverity)> (severity: #encodeForHTML(release.bugFixSeverity)#)</cfif>:</p>
					<p>#release.bugFix#</p>
				</cfif>
				<cfif len(release.filesChanged)>
					<p><b>Files changed:</b></p>
					#release.filesChanged#
				</cfif>
				<cfif len(release.recommendedAction)>
					<p><b>Recommended action:</b></p>
					#release.recommendedAction#
				</cfif>
				<cfif len(release.recommendedMinimumAction)>
					<p><b>Recommended minimum action:</b></p>
					#release.recommendedMinimumAction#
				</cfif>
				<cfif len(release.iniFileInstructions)>
					<p><b>Ini file instructions:</b></p>
					#release.iniFileInstructions#
				</cfif>
				<cfif len(release.actionAfterUpdate)>
					<p><b>After updating:</b></p>
					#release.actionAfterUpdate#
				</cfif>
			</cfloop>
			<p>After the new files are uploaded, use the <b>Update the database</b> button at the top of this window, if it is shown.</p>
		</cfoutput>
	<cfelseif val(installedVersion) eq val(latest.number)>
		<cfoutput>
			<p class="k-block k-success-colored">You're running Galaxie Blog version #encodeForHTML(installedVersion)#, the latest version.</p>
		</cfoutput>
	<cfelse>
		<!--- The installed version is newer than the newest release that is published (ie a version that is being tested). --->
		<cfoutput>
			<p class="k-block k-success-colored">You're running Galaxie Blog version #encodeForHTML(installedVersion)#, which is newer than the latest published release (#encodeForHTML(latest.number)#).</p>
		</cfoutput>
	</cfif>

	<cfcatch>
		<cfoutput><p>Unable to correctly contact the update site. (#encodeForHTML(cfcatch.message)#)</p></cfoutput>
	</cfcatch>
</cftry>
