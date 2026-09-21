<cfsilent>
<!---
	update.cfm

	A stand-alone page that brings the database up to the version of the files that were uploaded. It does not use the rest of the administrative site (no Kendo, no jQuery, none of the admin windows), so it still works when the database is too old for the administrative site or the public site to run, which is the case right after files were uploaded over a very old version of the blog. Application.cfc sends the administrator here in that situation (see databaseUpdateGate). The same update is available inside the administrative site in the Blog Updates window.

	Note: the logon is handled by Application.cfc (adminRequestStart) before this page is run, so only a logged in user can see this page. The update itself is run by ProxyController.cfc (runDatabaseUpdate), which checks the CSRF token and the EditServerSetting capability.
--->

<!--- The blog folder, taken from the URL of this page (for example /blog/admin/update.cfm gives /blog). This does not depend on any application variable, as the application may not have been initialized yet. --->
<cfset blogBaseUrl = left(cgi.script_name, len(cgi.script_name) - len("/admin/update.cfm"))>
<cfset blogIsRunning = isDefined("application.blog") and isDefined("application.rootDirectoryPath") and isDefined("application.blogIniPath")>
<cfset status = {}>
<cfset errorMessage = "">

<cfif blogIsRunning>
	<cftry>
		<!--- The application may have been running when the files were uploaded, so create the updater if it is not there yet. --->
		<cfif not isDefined("application.databaseUpdater")>
			<cfif len(application.baseProxyUrl) gt 0>
				<cfset updaterComponentPath = application.baseComponentPath & ".common.cfc.DatabaseUpdater">
			<cfelse>
				<cfset updaterComponentPath = "common.cfc.DatabaseUpdater">
			</cfif>
			<cfset application.databaseUpdater = createObject("component", updaterComponentPath).init(application.rootDirectoryPath, application.blogIniPath)>
		</cfif>
		<cfset status = application.databaseUpdater.getStatus()>
		<cfset csrfToken = csrfGenerateToken("admin", false)>
		<cfcatch type="any">
			<cfset blogIsRunning = false>
			<cfset errorMessage = cfcatch.message>
		</cfcatch>
	</cftry>
</cfif>
</cfsilent><!doctype html>
<html lang="en">
<head>
	<meta charset="utf-8">
	<meta name="viewport" content="width=device-width, initial-scale=1">
	<meta name="robots" content="noindex">
	<title>Update the database</title>
	<style>
		body { font-family: Arial, Helvetica, sans-serif; max-width: 760px; margin: 40px auto; padding: 0 20px; color: #333; line-height: 1.45; }
		.box { padding: 12px 16px; border-radius: 4px; margin: 16px 0; }
		.warning { background: #fff4ce; border: 1px solid #e0c14a; }
		.success { background: #e3f6e3; border: 1px solid #7cc47c; }
		.error { background: #fde2e2; border: 1px solid #d77; }
		button { font-size: 16px; padding: 8px 18px; cursor: pointer; }
		li { margin: 3px 0; }
	</style>
</head>
<body>
<cfoutput>
	<img src="#encodeForHTMLAttribute(blogBaseUrl)#/installer/images/docking.jpg" alt="" width="375" height="300" style="display:block;max-width:100%;height:auto;margin:0 0 20px 0;border-radius:6px;">
	<h1>Update the database</h1>

	<cfif not blogIsRunning>
		<div class="box warning">
			<p>The blog has not finished starting yet.<cfif len(errorMessage)> (#encodeForHTML(errorMessage)#)</cfif></p>
			<p>Please open the <a href="#encodeForHTMLAttribute(blogBaseUrl)#/">home page</a> once (it will show a page that says the site is being updated, and that is expected), then reload this page.</p>
		</div>
	<cfelseif not status.updateNeeded>
		<div class="box success">
			<p>The database is up to date (version #encodeForHTML(status.databaseVersion)#).</p>
		</div>
		<p><a href="#encodeForHTMLAttribute(blogBaseUrl)#/admin/">Go to the administrative site</a></p>
	<cfelse>
		<div class="box warning">
			<p><b>The database needs to be updated.</b></p>
			<p>The files are version #encodeForHTML(status.codeVersion)# and the database is version #encodeForHTML(status.databaseVersion)#.</p>
		</div>
		<cfif arrayLen(status.pending)>
			<p>These updates will be run, in order:</p>
			<ul>
			<cfloop array="#status.pending#" index="pendingUpdate">
				<li><b>#encodeForHTML(pendingUpdate.version)#</b>: #encodeForHTML(pendingUpdate.description)#</li>
			</cfloop>
			</ul>
		<cfelse>
			<p>There are no data changes in this update. The database only needs to be marked with the new version.</p>
		</cfif>
		<p>As with any update, please make a backup of your database first. Your posts, settings and users are not changed by the update, and it is safe to run more than once.</p>
		<p><button type="button" id="runUpdateButton">Update the database</button></p>
		<div id="updateResult"></div>

		<script>
			document.getElementById("runUpdateButton").addEventListener("click", function () {
				if (!confirm("Have you backed up your database? Do you want to update it now?")) { return; }
				var button = this;
				var result = document.getElementById("updateResult");
				button.disabled = true;
				result.textContent = "Updating the database. Please wait, this can take a minute.";

				function show(kind, text, log) {
					result.textContent = "";
					var box = document.createElement("div");
					box.className = "box " + kind;
					box.textContent = text;
					result.appendChild(box);
					if (log && log.length) {
						var list = document.createElement("ul");
						log.forEach(function (line) {
							var item = document.createElement("li");
							item.textContent = line;
							list.appendChild(item);
						});
						result.appendChild(list);
					}
				}

				fetch("#encodeForJavaScript(blogBaseUrl)#/common/cfc/ProxyController.cfc?method=runDatabaseUpdate", {
					method: "POST",
					credentials: "same-origin",
					headers: { "Content-Type": "application/x-www-form-urlencoded" },
					body: "csrfToken=" + encodeURIComponent("#encodeForJavaScript(csrfToken)#")
				}).then(function (response) {
					return response.json();
				}).then(function (data) {
					if (typeof data !== "object" || data === null) {
						button.disabled = false;
						show("error", "The update could not be run. Please reload the page and try again.");
						return;
					}
					if (data.success) {
						show("success", data.message, data.log);
						var link = document.createElement("p");
						var anchor = document.createElement("a");
						anchor.href = "#encodeForJavaScript(blogBaseUrl)#/admin/";
						anchor.textContent = "Go to the administrative site";
						link.appendChild(anchor);
						result.appendChild(link);
					} else {
						button.disabled = false;
						show("error", data.message, data.log);
					}
				}).catch(function () {
					button.disabled = false;
					show("error", "The update could not be run. Please make sure that you are still logged in and try again.");
				});
			});
		</script>
	</cfif>
</cfoutput>
</body>
</html>
