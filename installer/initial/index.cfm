<!---
	The Galaxie Blog installer (5.0, 2026-10-20): one page with four steps - Welcome, Your site, Database, Your account - then
	Install, in the same wizard as Site Setup (common/js/galaxieWizard.js on the free Kendo UI Core). It replaces the seven
	pages that each posted to the next (index.cfm, step2SiteInfo.cfm ... step7Post.cfm).

	Each step is saved (save.cfm) before the wizard moves on, so a mistake shows on the step it belongs to, and nothing goes
	forward until the database has been checked: a datasource that doesn't exist, doesn't connect or already holds a blog is
	refused (dsnCheck.cfm), so an existing blog can never be written over. Install then opens the blog's index.cfm?init=1&install=true,
	which builds the database, runs ../insertData.cfm and sends the new owner on to Site Setup.

	What was entered before (the session, or blog.ini.cfm) is filled in again, so a reload or a return keeps it.
--->
<cfsetting showdebugoutput="false">
<cffunction name="remembered" returntype="string" output="false" hint="A value from this install: the session first, then blog.ini.cfm.">
	<cfargument name="name" type="string" required="true">
	<cfargument name="default" type="string" required="false" default="">
	<cfset var fromIni = "">
	<cfif structKeyExists(session, arguments.name) and isSimpleValue(session[arguments.name]) and len(session[arguments.name])><cfreturn session[arguments.name]></cfif>
	<cftry>
		<cfset fromIni = getProfileString(application.iniFile, "default", arguments.name)>
		<cfif len(fromIni)><cfreturn fromIni></cfif>
		<cfcatch type="any"></cfcatch>
	</cftry>
	<cfreturn arguments.default>
</cffunction>
<!--- The address this page was opened at, without /installer/initial/..., as the site's address to start from. --->
<cfset portPart = listFind("80,443", cgi.server_port) ? "" : ":" & cgi.server_port>
<cfset sitePath = reReplaceNoCase(cgi.script_name, "/installer/initial/.*$", "")>
<cfset guessedUrl = (cgi.https eq "on" ? "https://" : "http://") & cgi.server_name & portPart & sitePath>
<cfset blogUrl = reReplaceNoCase(remembered("blogUrl", guessedUrl), "/index\.cfm$", "")>
<cfset values = {
	"blogUrl": blogUrl, "blogTitle": remembered("blogTitle"), "dsn": remembered("dsn"), "databaseType": remembered("databaseType", "sqlServer"),
	"firstName": remembered("firstName"), "lastName": remembered("lastName"), "profileDisplayName": remembered("profileDisplayName"),
	"email": remembered("email"), "website": remembered("website"), "userName": remembered("userName"),
	"securityAnswer1": remembered("securityAnswer1"), "securityAnswer2": remembered("securityAnswer2"), "securityAnswer3": remembered("securityAnswer3")
}>
<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<meta name="robots" content="noindex, nofollow">
<title>Install Galaxie Blog</title>
<link rel="stylesheet" href="../../common/libs/kendoCore/styles/kendo.bootstrap-v4.min.css">
<script src="../../common/libs/kendoCore/js/jquery.min.js"></script>
<script src="../../common/libs/kendoCore/js/kendo.ui.core.min.js"></script>
<script src="../../common/js/galaxieWizard.js"></script>
<style>
	:root { --ink: #1f2328; --muted: #5d6670; --line: #d8dde3; --accent: #007bff; --panel: #ffffff; --page: #eef1f4; --good: #1a7f37; --bad: #b00020; }
	* { box-sizing: border-box; }
	html, body { margin: 0; min-height: 100%; font-family: Arial, Helvetica, sans-serif; color: var(--ink); background: var(--page); }
	.shell { max-width: 900px; margin: 28px auto; background: var(--panel); border-radius: 10px; box-shadow: 0 2px 14px rgba(0,0,0,.12); overflow: hidden; }
	.top { display: flex; align-items: center; gap: 14px; padding: 18px 22px 6px; }
	.top img { width: 52px; height: 52px; border-radius: 50%; object-fit: cover; }
	.top h1 { font-size: 21px; margin: 0; }
	.top .sub { margin: 2px 0 0; color: var(--muted); font-size: 14px; }
	#wizard { padding: 0 12px 14px; }
	.lead { font-size: 15px; color: var(--muted); }
	.fieldRow { display: flex; align-items: flex-start; gap: 10px; font-size: 14px; }
	.fieldRow > label { width: 25%; text-align: right; color: var(--muted); padding-top: 7px; flex: none; }
	.fieldRow .control { flex: 1; min-width: 0; }
	.fieldRow input.k-textbox { width: 100%; }
	.fieldRow input.invalid { border-color: var(--bad); }
	.hint { font-size: 13px; color: var(--muted); margin-top: 6px; }
	.check { display: flex; gap: 10px; align-items: center; padding: 10px 12px; border-radius: 6px; font-size: 14px; margin-top: 8px; }
	.check.ok { background: #e7f6ec; color: var(--good); }
	.check.no { background: #fdecee; color: var(--bad); }
	.check.wait { background: #eef1f4; color: var(--muted); }
	.welcomeGrid { display: grid; grid-template-columns: repeat(auto-fill, minmax(180px, 1fr)); gap: 12px; margin-top: 10px; }
	.welcomeItem { border: 1px solid var(--line); border-radius: 8px; padding: 12px; font-size: 14px; background: #fff; }
	.welcomeItem b { display: block; margin-bottom: 4px; }
	.needs { padding-left: 20px; font-size: 14px; line-height: 1.6; }
	.summary { list-style: none; padding: 0; font-size: 14px; }
	.summary li { display: flex; justify-content: space-between; gap: 12px; padding: 8px 4px; border-bottom: 1px solid var(--line); }
	.summary li:last-child { border-bottom: 0; }
	.summary span { color: var(--muted); text-align: right; word-break: break-all; }
	.progress { list-style: none; padding: 0; margin: 12px 0 0; font-size: 14px; }
	.progress li { padding: 5px 0; color: var(--muted); }
	.strength { height: 6px; border-radius: 3px; background: var(--line); margin-top: 6px; overflow: hidden; }
	.strength > div { height: 100%; width: 0; background: var(--bad); transition: width .2s, background .2s; }
	.stepMessage { min-height: 1em; font-size: 14px; color: var(--bad); padding: 8px 14px 0; }
	/* The admin's alternating blocks - the first k-content, then k-alt - with a line between rows and between blocks. */
	.block { padding: 10px 14px; }
	.block.k-alt { background-color: #f4f5f7; }
	.block + .block { border-top: 1px solid #c8c8c8; }
	.block > * + * { border-top: 1px solid #c8c8c8; padding-top: 10px; margin-top: 10px; }
	.block > * { margin-top: 0; margin-bottom: 0; }
	.block h4 { margin: 2px 0; font-size: 15px; }
	@media (max-width: 700px) { .fieldRow { flex-direction: column; gap: 4px; } .fieldRow > label { width: auto; text-align: left; padding-top: 0; } .shell { margin: 0; border-radius: 0; } }
</style>
</head>
<body>
<div class="shell">
	<div class="top">
		<img src="../images/welcome.jpg" alt="">
		<div><h1>Install Galaxie Blog</h1><p class="sub">Four short steps. Afterwards, Site Setup helps you make the site your own.</p></div>
	</div>
	<div id="wizard"></div>
</div>

<cfoutput>
<div style="display:none">
	<div id="stepWelcome">
		<div class="block k-content">
			<p class="lead">Welcome! This puts Galaxie Blog on your server: your site's address, its database, and your account.</p>
			<div class="welcomeGrid">
				<div class="welcomeItem"><b>1. Your site</b>Its address and name.</div>
				<div class="welcomeItem"><b>2. Database</b>Where the blog keeps its posts.</div>
				<div class="welcomeItem"><b>3. Your account</b>How you sign in.</div>
				<div class="welcomeItem"><b>4. Install</b>About a minute.</div>
			</div>
		</div>
		<div class="block k-alt">
			<h4>Before you start, you need</h4>
			<ul class="needs">
				<li>An empty database, and a ColdFusion or Lucee datasource (DSN) for it.</li>
				<li>Your site's address, ideally with an SSL certificate (https).</li>
			</ul>
		</div>
	</div>

	<div id="stepSite">
		<div class="block k-content"><p class="lead">The address people use to reach your site, and its name. Enter the address exactly; the blog builds every link from it.</p></div>
		<div class="block k-alt">
			<h4>Your site</h4>
			<div class="fieldRow"><label for="blogUrl">Address</label><div class="control"><input id="blogUrl" class="k-textbox" value="#encodeForHtmlAttribute(values.blogUrl)#"><div class="hint">Include https:// (recommended) or http://. Leave off any page name.</div></div></div>
			<div class="fieldRow"><label for="blogTitle">Site name</label><div class="control"><input id="blogTitle" class="k-textbox" maxlength="125" placeholder="My Blog" value="#encodeForHtmlAttribute(values.blogTitle)#"><div class="hint">You can change it later in Site Setup.</div></div></div>
		</div>
	</div>

	<div id="stepDatabase">
		<div class="block k-content"><p class="lead">Create an empty database and a datasource for it in the ColdFusion or Lucee administrator, then enter the datasource's name here.</p></div>
		<div class="block k-alt">
			<h4>Database</h4>
			<div class="fieldRow"><label for="dsn">Datasource</label><div class="control"><input id="dsn" class="k-textbox" maxlength="100" value="#encodeForHtmlAttribute(values.dsn)#"></div></div>
			<div class="fieldRow"><label for="databaseType">Database</label><div class="control"><select id="databaseType" style="width: 100%;">
				<cfloop list="sqlServer|Microsoft SQL Server,mySql|MySQL or MariaDB,postgre|PostgreSQL,oracle|Oracle,db2|DB2,apacheDerby|Apache Derby,sybase|Sybase" index="dbChoice">
					<option value="#listFirst(dbChoice, '|')#"<cfif listFirst(dbChoice, '|') eq values.databaseType> selected</cfif>>#listLast(dbChoice, '|')#</option>
				</cfloop>
			</select></div></div>
		</div>
		<div class="block k-content">
			<h4>Check it</h4>
			<div class="fieldRow"><label></label><div class="control"><button type="button" class="k-button k-primary" id="checkDsn">Check the connection</button>
				<div class="check" id="dsnResult" style="display:none"></div>
				<div class="hint">The installer won't go on until the connection works, and never writes over an existing blog.</div>
			</div></div>
		</div>
	</div>

	<div id="stepAccount">
		<div class="block k-content"><p class="lead">Your administrator account. You'll sign in with the user name and password.</p></div>
		<div class="block k-alt">
			<h4>About you</h4>
			<div class="fieldRow"><label for="firstName">First name</label><div class="control"><input id="firstName" class="k-textbox" value="#encodeForHtmlAttribute(values.firstName)#"></div></div>
			<div class="fieldRow"><label for="lastName">Last name</label><div class="control"><input id="lastName" class="k-textbox" value="#encodeForHtmlAttribute(values.lastName)#"></div></div>
			<div class="fieldRow"><label for="profileDisplayName">Name on posts</label><div class="control"><input id="profileDisplayName" class="k-textbox" placeholder="Optional" value="#encodeForHtmlAttribute(values.profileDisplayName)#"><div class="hint">Shown as the author. Your first and last name if left empty.</div></div></div>
			<div class="fieldRow"><label for="email">Email</label><div class="control"><input id="email" type="email" class="k-textbox" value="#encodeForHtmlAttribute(values.email)#"></div></div>
			<div class="fieldRow"><label for="website">Website</label><div class="control"><input id="website" type="url" class="k-textbox" placeholder="Optional" value="#encodeForHtmlAttribute(values.website)#"></div></div>
		</div>
		<div class="block k-content">
			<h4>Signing in</h4>
			<div class="fieldRow"><label for="userName">User name</label><div class="control"><input id="userName" class="k-textbox" autocomplete="username" value="#encodeForHtmlAttribute(values.userName)#"></div></div>
			<div class="fieldRow"><label for="password">Password</label><div class="control"><input id="password" type="password" class="k-textbox" autocomplete="new-password"><div class="strength"><div id="strengthBar"></div></div><div class="hint" id="strengthText">At least 8 characters, with a number or symbol.</div></div></div>
			<div class="fieldRow"><label for="confirmPassword">Again</label><div class="control"><input id="confirmPassword" type="password" class="k-textbox" autocomplete="new-password"></div></div>
		</div>
		<div class="block k-alt">
			<h4>If you forget your password</h4>
			<div class="fieldRow"><label for="securityAnswer1">Favorite pet</label><div class="control"><input id="securityAnswer1" class="k-textbox" value="#encodeForHtmlAttribute(values.securityAnswer1)#"></div></div>
			<div class="fieldRow"><label for="securityAnswer2">Childhood friend</label><div class="control"><input id="securityAnswer2" class="k-textbox" value="#encodeForHtmlAttribute(values.securityAnswer2)#"></div></div>
			<div class="fieldRow"><label for="securityAnswer3">Favorite place</label><div class="control"><input id="securityAnswer3" class="k-textbox" value="#encodeForHtmlAttribute(values.securityAnswer3)#"></div></div>
		</div>
	</div>

	<div id="stepInstall">
		<div class="block k-content"><p class="lead">Ready. Here's what will be installed; go back to change anything.</p></div>
		<div class="block k-alt">
			<h4>Summary</h4>
			<ul class="summary">
				<li>Address <span id="sumUrl"></span></li>
				<li>Site name <span id="sumTitle"></span></li>
				<li>Database <span id="sumDb"></span></li>
				<li>Your account <span id="sumUser"></span></li>
			</ul>
		</div>
		<div class="block k-content">
			<button type="button" class="k-button k-primary" id="installNow">Install Galaxie Blog</button>
			<ul class="progress" id="progress" style="display:none">
				<li>Installing - this takes about a minute. Please keep this page open.</li>
				<li>Next, Site Setup opens to help you make the site your own.</li>
			</ul>
		</div>
	</div>
</div>
</cfoutput>

<script>
$(function () {
	$("#databaseType").kendoDropDownList();
	var steps = [
		{ title: "Welcome", id: "stepWelcome", save: null },
		{ title: "Your site", id: "stepSite", save: "site" },
		{ title: "Database", id: "stepDatabase", save: "database" },
		{ title: "Your account", id: "stepAccount", save: "account" },
		{ title: "Install", id: "stepInstall", save: null }
	];
	// What each step sends to save.cfm.
	var fields = {
		site: ["blogUrl", "blogTitle"],
		database: ["dsn", "databaseType"],
		account: ["firstName", "lastName", "profileDisplayName", "email", "website", "userName", "password", "confirmPassword", "securityAnswer1", "securityAnswer2", "securityAnswer3"]
	};
	var saved = { site: false, database: false, account: false }, installUrl = "", busy = false;
	function value(id) { return id === "databaseType" ? $("#databaseType").data("kendoDropDownList").value() : $.trim($("#" + id).val()); }
	function message(index, text) { $("#message" + index).text(text || ""); }
	function save(index) {
		var key = steps[index].save, data = { step: key };
		$.each(fields[key], function (i, id) { data[id] = id.indexOf("assword") > 0 ? $("#" + id).val() : value(id); });
		$("#" + steps[index].id + " input").removeClass("invalid");
		return $.ajax({ type: "post", url: "save.cfm", data: data, dataType: "json" }).then(function (response) {
			if (!response || !response.success) {
				if (response && response.field) { $("#" + response.field).addClass("invalid").trigger("focus"); }
				return $.Deferred().reject((response && response.message) || "This step could not be saved.").promise();
			}
			saved[key] = true;
			if (response.installUrl) { installUrl = response.installUrl; }
			return response;
		}, function () { return $.Deferred().reject("The installer could not be reached. Please try again.").promise(); });
	}
	// Anything typed on a step means it is saved again before moving on.
	$.each(fields, function (key, ids) { $.each(ids, function (i, id) { $("#" + id).on("input change", function () { saved[key] = false; if (key === "database") { $("#dsnResult").hide(); } }); }); });

	var wizard = $("#wizard").galaxieWizard({
		steps: steps.map(function (s, i) {
			return { title: s.title, content: '<div class="stepHolder" data-id="' + s.id + '"></div><div class="stepMessage" id="message' + i + '" role="alert"></div>',
				buttons: i === 0 ? [{ name: "next", text: "Start" }] : i === steps.length - 1 ? ["previous"] : ["previous", "next"] };
		}),
		stepper: { linear: false },
		select: function (e) {
			// Going back is always fine. Going forward saves each step on the way, and stops at the first one that isn't right.
			var from = wizard.activeStep().options.index, to = e.step.options.index;
			if (busy) { e.preventDefault(); return; }
			if (to <= from) { return; }
			e.preventDefault();
			var index = from;
			function next() {
				while (index < to && (!steps[index].save || saved[steps[index].save])) { index++; }
				if (index >= to) { busy = false; wizard.select(to); return; }
				busy = true;
				if (index !== wizard.activeStep().options.index) { wizard.select(index); }
				message(index, "");
				save(index).then(function () { busy = false; message(index, ""); index++; next(); },
					function (text) { busy = false; message(index, text); });
			}
			next();
		},
		activate: function (e) {
			fill();
			if (e.step.options.index === 4) {
				$("#sumUrl").text(value("blogUrl")); $("#sumTitle").text(value("blogTitle"));
				$("#sumDb").text(value("dsn") + " (" + $("#databaseType").data("kendoDropDownList").text() + ")");
				$("#sumUser").text(value("userName"));
			}
		}
	}).data("galaxieWizard");
	function fill() { $("#wizard .stepHolder").each(function () { if (!$(this).children().length) { $(this).append($("#" + $(this).data("id"))); } }); }
	fill();

	// Database: check the connection without leaving the step.
	$("#checkDsn").on("click", function () {
		var result = $("#dsnResult").attr("class", "check wait").text("Checking...").show();
		message(2, "");
		save(2).then(function (response) { result.attr("class", "check ok").text(response.message || "Connected."); },
			function (text) { result.attr("class", "check no").text(text); });
	});

	$("#password").on("input", function () {
		var v = this.value, score = (v.length >= 8) + (v.length >= 12) + (/[0-9]/.test(v)) + (/[^A-Za-z0-9]/.test(v)) + (/[A-Z]/.test(v) && /[a-z]/.test(v));
		$("#strengthBar").css({ width: (score * 20) + "%", background: score >= 4 ? "#1a7f37" : score >= 2 ? "#d4a017" : "#b00020" });
		$("#strengthText").text(score >= 4 ? "Strong." : score >= 2 ? "Could be stronger: make it longer, or add a symbol." : "At least 8 characters, with a number or symbol.");
	});

	// Install: the blog builds its database and starter content on its own page, then opens Site Setup.
	$("#installNow").on("click", function () {
		if (!installUrl || !saved.site || !saved.database || !saved.account) {
			message(4, "A step isn't finished yet. Go back and press Next on each step.");
			return;
		}
		$(this).prop("disabled", true).text("Installing...");
		$("#progress").show();
		window.location.href = installUrl;
	});
});
</script>
</body>
</html>
