<cfsilent>
	<!--- Application.cfc creates the updater when the application starts, but the application may have been running when new files were uploaded, so create it if it is not there yet. --->
	<cfif not isDefined("application.databaseUpdater")>
		<cfif len(application.baseProxyUrl) gt 0>
			<cfset updaterComponentPath = application.baseComponentPath & ".common.cfc.DatabaseUpdater">
		<cfelse>
			<cfset updaterComponentPath = "common.cfc.DatabaseUpdater">
		</cfif>
		<cfset application.databaseUpdater = createObject("component", updaterComponentPath).init(application.rootDirectoryPath, application.blogIniPath)>
	</cfif>

	<!--- The status of the database and the update scripts that have not been run yet --->
	<cfset databaseUpdateStatus = application.databaseUpdater.getStatus()>
	<cfset dbBlogVersion = databaseUpdateStatus.databaseVersion>
	<cfset fileSystemBlogVersion = application.blog.getVersion()>
	<cfset csrfToken = csrfGenerateToken("admin", false)>
</cfsilent>

	<style>
		#recentVersionCheck {
			width:100%;
		}
		#databaseUpdateResult ul {
			margin-top: 5px;
		}
		#databaseUpdate, #databaseUpdate li, #databaseUpdateResult li, #recentVersionCheck td, #upgradeDetails, #upgradeDetails p, #upgradeDetails li, #upgradeDetails pre, #upgradeDetails code {
			overflow-wrap: anywhere;
			word-break: break-word;
		}
		#upgradeDetails pre {
			white-space: pre-wrap;
		}
		#recentVersionCheck {
			table-layout: fixed;
		}
	</style>

	<cfoutput>
	<div id="databaseUpdate">
		<cfif not databaseUpdateStatus.updateNeeded>
			<p class="k-block k-success-colored">The database is up to date (version #encodeForHTML(databaseUpdateStatus.databaseVersion)#).</p>
		<cfelse>
			<div id="databaseUpdateIntro">
			<p class="k-block k-warning-colored"><b>Galaxie Blog needs to finish updating.</b><br/>
			The files that you uploaded are version #encodeForHTML(databaseUpdateStatus.codeVersion)#, but the blog's database tables are still at version #encodeForHTML(databaseUpdateStatus.databaseVersion)#. Press the button below to bring them up to date.</p>
			<cfif arrayLen(databaseUpdateStatus.pending)>
				<p>These updates will be run, in order:</p>
				<ul>
				<cfloop array="#databaseUpdateStatus.pending#" index="pendingUpdate">
					<li><b>#encodeForHTML(pendingUpdate.version)#</b>: #encodeForHTML(pendingUpdate.description)#</li>
				</cfloop>
				</ul>
			<cfelse>
				<p>There are no data changes in this update. The database only needs to be marked with the new version.</p>
			</cfif>
			<p>As with any update, please make a backup of your database first. Your posts, settings and users are not changed by the update, and it is safe to run more than once.</p>
			<p><button type="button" id="runDatabaseUpdateButton" class="k-button k-primary">Update Galaxie Blog's database</button></p>
			</div><!---<div id="databaseUpdateIntro">--->
			<div id="databaseUpdateResult"></div>
		</cfif>
	</div>
	</cfoutput>

	<script>
		<!--- Run the database update. --- --->
		$("#runDatabaseUpdateButton").on("click", function() {
			<!--- Note: this is a custom library that I am using. The ExtYesNoDialog is not a part of Kendo but an extension. --->
			$.when(kendo.ui.ExtYesNoDialog.show({
				title: "Update Galaxie Blog's database?",
				message: "Update the blog's tables to version <cfoutput>#encodeForJavaScript(databaseUpdateStatus.codeVersion)#</cfoutput>? Your posts, comments and users are kept. Please make a backup of your database first. Click Yes to update, or No to cancel.",
				icon: "k-ext-information",
				width: "<cfoutput>#application.kendoExtendedUiWindowWidth#</cfoutput>",
				height: "250px"
			})).done(function(response) {
				if (response['button'] == 'Yes') {
					$("#runDatabaseUpdateButton").prop("disabled", true);
					$("#databaseUpdateResult").html("<p>Updating the database. Please wait, this can take a minute.</p>");
					$.ajax({
						type: 'post',
						<!--- This posts to the proxy controller as it needs to have session vars. --->
						url: "<cfoutput>#application.proxyControllerUrl#</cfoutput>?method=runDatabaseUpdate",
						data: { csrfToken: '<cfoutput>#csrfToken#</cfoutput>' },
						dataType: "json",
						cache: false
					}).done(function(data) {
						showDatabaseUpdateResult(data);
					}).fail(function() {
						$("#runDatabaseUpdateButton").prop("disabled", false);
						$("#databaseUpdateResult").html("<p class='k-block k-error-colored'>The update could not be run. Please make sure that you are still logged in and try again.</p>");
					});
				}
			});
		});

		function showDatabaseUpdateResult(data) {
			var $result = $("#databaseUpdateResult").empty();
			<!--- A failed token check returns a string, not an object. --->
			if (typeof data !== 'object' || data === null) {
				$("#runDatabaseUpdateButton").prop("disabled", false);
				$result.append($("<p class='k-block k-error-colored'>").text("The update could not be run. Please reload the page and try again."));
				return;
			}
			if (data.success) {
				<!--- The update is done, so the explanation and the button that ran it are no longer needed. --->
				$("#databaseUpdateIntro").remove();
				<!--- The icon caption on the admin page said that an update was needed. --->
				$("#BlogUpdate .caption").text("Blog Updates");
				$result.append($("<p class='k-block k-success-colored'>").text(data.message));
			} else {
				$("#runDatabaseUpdateButton").prop("disabled", false);
				$result.append($("<p class='k-block k-error-colored'>").text(data.message));
			}
			if (data.log && data.log.length) {
				var $list = $("<ul>");
				$.each(data.log, function(i, line) {
					$list.append($("<li>").text(line));
				});
				$result.append($list);
			}
			if (data.success) {
				<!--- A button at the bottom of the result to close this window. --->
				var $closeButton = $("<button type='button' id='closeUpdateWindowButton' class='k-button k-primary'>").text("Close");
				$closeButton.on("click", function() {
					var updatesWindow = $("#updatesWindow").data("kendoWindow");
					if (updatesWindow) { updatesWindow.close(); }
				});
				$result.append($("<p>").append($closeButton));
			}
		}

		<!--- Get the summary information about the latest release from the update site. --->
		$("#upgradeDetails").html("<p>Checking to see if there is a newer version of the blog. Please wait.</p>").load("latestVersionCheck.cfm?version=<cfoutput>#fileSystemBlogVersion#</cfoutput>&dbBlogVersion=<cfoutput>#dbBlogVersion#</cfoutput>", function() {
		});
	</script>

	<table id="recentVersionCheck" class="k-content" width="100%" cellpadding="0" cellspacing="0" border="0">
	  <tr class="k-alt">
		<td>
		  <span id="upgradeDetails" style="display: inline-block; width: 100%"></span>
		</td>
	  </tr>
	</table><br/>
