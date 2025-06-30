<cfsetting enablecfoutputonly=true> 
<!--- Note: we are starting from version one and moving towards the latest version --->
<!--- Important note: this must have a cfoutput tag to render --->
	
<!--- Get a token --->
<cfset csrfToken = csrfGenerateToken("admin", false)>
	
<!--- The application.dbBlogVersion was not set until version 3.12 --->
<!--- Get the dbBlogVersion from the database. --->
<cfset blogDbVersion = application.blog.getDbBlogVersion()>

<cfif blogDbVersion lt application.blog.getVersion()>
	<cfset databaseUpdatedNeeded = true>
<cfelse>
	<cfset databaseUpdatedNeeded = false>
</cfif>
<!---
Debugging
<cfoutput>
	blogDbVersion: #blogDbVersion# application.blog.getVersion(): #application.blog.getVersion()# databaseUpdatedNeeded: #databaseUpdatedNeeded#
</cfoutput>
--->
<!---<cftry>--->
	
	<!--- Works with flat XML (https://www.gregoryalexander.com/common/services/gregorysBlog/version.xml) --->
		
	<cfset serviceURL = "https://www.gregoryalexander.com/common/services/gregorysBlog/version.xml">
	<cfhttp url="#serviceUrl#" result="result">
	<cfset data = xmlParse(result.fileContent)>
	<cfset latestVersion = data.version.number.xmlText>
	<cfset dbVersion = data.version.dbVersion.xmlText>
	<cfset dbUpdateInstruction = data.version.dbUpdateInstruction.xmlText>
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

	<cfif latestVersion neq application.blog.getVersion()>
		<cfoutput>
		<p class="k-block k-warning-colored">Note: when updating the file system, be sure not to overwrite your '/org/camden/blog/blog.ini.cfm' or '/admin/ApplicationProxyReference.cfc' files! Doing so will prevent you from obtaining access to the administrative site.<br/>
		Although not necessary, as with any software before an upgrade, it is probably best to backup the codebase and database to your in case of an error or other custom logic needs to be restored.</p>
		</cfoutput>
	</cfif>
	<!--- Summary --->
	<cfif latestVersion eq application.blog.getVersion()>
		<cfoutput>
			<p class="k-block k-success-colored">You're running Galaxie Blog version #latestVersion#. The file system version is up to date.</p>
			<cfif databaseUpdatedNeeded>
				<p class="k-block k-error-colored"><b>Your Galaxie Blog database is out of date.</b><br/>
				<p>#dbUpdateInstruction#</p>
			<cfelse>
				<p class="k-block k-success-colored">The database is up to date.</p>
			</cfif>
		</cfoutput>
	<cfelse>
		<cfoutput>
			<p class="k-block k-error-colored">Your Galaxie Blog version #application.blog.getVersion()# installation is out of date. Your current version is #application.blog.getVersion()# and the latest released version of Galaxie Blog is <b>#latestVersion#</b>. This version was released on #dateFormat(latestUpdate, 'long')#.</p>
			<p>#latestShortDescription#</p>
			
			<!--- Detail --->
			<cfif latestVersion neq application.blog.getVersion()>
				<p>Updates for this version include:</p>
				<p>#latestDescription#</p>
				<cfif bugFix neq "" and bugFixSeverity neq "">
					<p><b>Bug Fixes</b>:</p>
					<p>#bugFix#</p>
					<cfif bugFixSeverity neq "">
						<p>Bug Severity:</p>
						<p>#bugFixSeverity#</p>
					</cfif><!---<cfif bugFixSeverity neq "">--->
				</cfif><!---<cfif bugFix neq "">--->
				<cfif filesChanged neq "">
					<p>Files Changed:</p>
					<p>#filesChanged#</p>
				</cfif>
				<cfif recommendedAction neq "">
					<p>Recommended Action:</p>
					<p>#recommendedAction#</p>
				</cfif>
				<cfif recommendedMinimumAction neq "">
					<p>Recommended Minimum Action:</p>
					<p>#recommendedMinimumAction#</p>
				</cfif>
				<cfif iniFileInstructions neq "">
					<p>Ini File Instructions:</p>
					<p>#iniFileInstructions#</p>
				</cfif>
				<cfif actionAfterUpdate neq "">
					<p>After Updating:</p>
					<p>#actionAfterUpdate#</p>
				</cfif>
			</cfif><!---<cfif latestVersion neq application.blog.getVersion()>--->
		</cfoutput>
	</cfif><!---<cfif latestVersion eq application.blog.getVersion()>--->
		
	<cfoutput>
	<script>
		// Install the update.  -------------------------------------------------------------------------------------	
		function updateDb(){
			// Note: this is a custom library that I am using. The ExtAlertDialog is not a part of Kendo but an extension.
			 $.when(kendo.ui.ExtYesNoDialog.show({ // Alert the user and ask them if they want to double opt in
				title: "Please confirm that you want to install the update",
				message: "Do you want to continue to update the database?",
				icon: "k-ext-information",
				width: "<cfoutput>#application.kendoExtendedUiWindowWidth#</cfoutput>", 
				height: "215px"
			 })
			).done(function (response) { // If the user clicked 'yes', confirm.
				if (response['button'] == 'Yes'){// remember that js is case sensitive.
					
					// Submit form via AJAX.
					$.ajax({
						type: 'post', 
						// This posts to the proxy controller as it needs to have session vars and performs client side operations.
						url: "<cfoutput>#application.proxyControllerUrl#</cfoutput>?method=updateDb",
						data: {
							blogVersion: "4.07",//3.12
							csrfToken: '<cfoutput>#csrfToken#</cfoutput>'
						},//..data: {
						dataType: "json",
						cache: false,
						success: function(data) {
							setTimeout(function () {
								updateDbResponse(data);
							}, 500);//..setTimeout(function () {
						}//..success: function(data) {
					});//..$.ajax({

					// Open the please wait window. Note: the ExtWaitDialog's are based upon an open source project and not a part of the Kendo official library. I prefer this design over Kendo's dialog offerings. I have extended this library with some of my own designs.
					$.when(kendo.ui.ExtWaitDialog.show({ title: "Please wait...", message: "Please wait", icon: "k-ext-information" }));
					// Use a quick set timeout in order for the data to load.
					setTimeout(function() {
						// Close the wait window that was launched in the calling function.
						kendo.ui.ExtWaitDialog.hide();
					}, 1000);
					// Return false in order to prevent any potential redirection.
					return false;
				}//...if (response['button'] == 'Yes')
			});

		}//..function confirmSubscription(token){
						  
		function updateDbResponse(response){
			// Extract the data in the response.
			var message = "Updated Database";
			// Display it.			  
			$.when(kendo.ui.ExtAlertDialog.show({ title: "The database has been sucessfully updated", message: message, icon: "k-ext-information", width: "<cfoutput>#application.kendoExtendedUiWindowWidth#</cfoutput>", height: "215px"}));
			// Close the admin window
			$('#chr(35)#updatesWindow').kendoWindow('destroy');
		}
		
	</script>
	</cfoutput>
	<!---<cfcatch>
		<cfoutput><p>Unable to correctly contact the update site.</p></cfoutput>
	</cfcatch>
</cftry>--->