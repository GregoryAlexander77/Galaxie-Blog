<cfsilent>
<!--- The top of the Traffic Sources window (117, 2026-10-25, owner), shared by kendo/trafficSources.cfm and jsGrid/trafficSources.cfm:
the period buttons, the bar of people by type, and trafficSourcesLoad(days, render), which reads the period's sites
(ProxyController.cfc getTrafficSources, AdminHome.cfc getTrafficSources) and hands the rows to the grid. Opened with
createAdminInterfaceWindow(117, days); days is 7, 30, 90 or 0 (everything in the log). --->
<cfset trafficDays = (structKeyExists(URL, "optArgs") and listFind("7,30,90,0", URL.optArgs)) ? URL.optArgs : 30>
<cfset trafficUrl = application.baseUrl & "/common/cfc/ProxyController.cfc?method=getTrafficSources&csrfToken=" & csrfToken>
<!--- The theme's primary color, as the admin home's Where they came from card draws it. --->
<cftry>
	<cfset trafficAccent = application.blog.getPrimaryColorsByTheme(kendoTheme: kendoTheme, setting: "accentColor")>
	<cfcatch type="any"><cfset trafficAccent = ""></cfcatch>
</cftry>
<cfif not reFindNoCase("^##?[0-9a-f]{3,8}$|^rgba?\(", trim(trafficAccent))><cfset trafficAccent = "##0969da"></cfif>
<cfif reFindNoCase("^[0-9a-f]{3,8}$", trim(trafficAccent))><cfset trafficAccent = "##" & trim(trafficAccent)></cfif>
</cfsilent>
<style>
	#trafficSourcesTop { --trafficAccent: <cfoutput>#trafficAccent#</cfoutput>; margin-bottom: 10px; }
	#trafficSourcesTop .trafficPeriods .k-button { margin: 0 6px 6px 0; }
	#trafficSourcesTop .trafficStack { display: flex; height: 12px; border-radius: 6px; overflow: hidden; background: rgba(128,128,128,.2); margin: 6px 0; }
	#trafficSourcesTop .trafficLegend span { display: inline-block; margin-right: 14px; }
	#trafficSourcesTop .trafficDot { display: inline-block; width: 10px; height: 10px; border-radius: 50%; margin-right: 4px; }
	.trafficPart0 { background: var(--trafficAccent); } .trafficPart1 { background: color-mix(in srgb, var(--trafficAccent) 55%, #ffffff); }
	.trafficPart2 { background: color-mix(in srgb, var(--trafficAccent) 60%, #000000); } .trafficPart3 { background: #9aa4ae; }
</style>
<div id="trafficSourcesTop">
	<div class="trafficPeriods" role="group" aria-label="Period">
		<cfoutput><cfloop list="7,30,90,0" index="d"><button type="button" class="k-button<cfif d eq trafficDays> k-primary</cfif>" data-days="#d#">#d ? 'Last ' & d & ' days' : 'Everything in the log'#</button></cfloop></cfoutput>
	</div>
	<div class="trafficStack"></div>
	<div class="trafficLegend"></div>
	<p>People, not visits, and no bots. Click a site to see its visits in the Visitor Log.</p>
</div>
<script>
	var trafficSourcesDays = <cfoutput>#trafficDays#</cfoutput>;
	var trafficSourcesTypes = ["Search", "Social", "Other site", "Straight in"];
	function trafficSourcesText(value) { return $("<div/>").text(value === null || value === undefined ? "" : String(value)).html(); }
	// The site's name, a link to its visits; Straight in has no site.
	function trafficSourcesSite(item) {
		if (!item.site) { return "<i>Straight in</i>"; }
		// Only plain site names can be looked up in the Visitor Log (ProxyController checks them the same way).
		if (!/^[a-z0-9][a-z0-9.-]*$/.test(item.site)) { return '<span title="' + trafficSourcesText(item.address) + '">' + trafficSourcesText(item.site) + "</span>"; }
		return '<a href="javascript:void(0)" class="trafficSiteLink" data-site="' + trafficSourcesText(item.site) + '" title="' + trafficSourcesText(item.address) + '">' + trafficSourcesText(item.site) + "</a>";
	}
	function trafficSourcesDate(value) { return String(value || "").replace(/^\d\d(\d\d)-(\d\d)-(\d\d)$/, "$2/$3/$1"); }
	function trafficSourcesLoad(days, render) {
		trafficSourcesDays = days;
		$("#trafficSourcesTop .trafficPeriods .k-button").each(function () { $(this).toggleClass("k-primary", String($(this).data("days")) === String(days)); });
		$.getJSON("<cfoutput>#trafficUrl#</cfoutput>&days=" + days).done(function (result) {
			// Adobe ColdFusion sends the answer as a JSON string inside JSON (the ProxyController pattern); Lucee sends it as is.
			if (typeof result === "string") { try { result = JSON.parse(result); } catch (e) { result = {}; } }
			var types = result.types || {}, total = 0;
			$.each(trafficSourcesTypes, function (i, t) { total += Number(types[t] || 0); });
			$("#trafficSourcesTop .trafficStack").html($.map(trafficSourcesTypes, function (t, i) {
				return types[t] ? '<span class="trafficPart' + i + '" style="width:' + (types[t] / total * 100) + '%" title="' + t + '"></span>' : "";
			}).join(""));
			$("#trafficSourcesTop .trafficLegend").html($.map(trafficSourcesTypes, function (t, i) {
				return '<span><i class="trafficDot trafficPart' + i + '"></i>' + t + " " + Number(types[t] || 0) + "</span>";
			}).join(""));
			render(result.rows || []);
		}).fail(function () { $("#trafficSourcesTop .trafficLegend").text("The traffic sources couldn't be read."); });
	}
	$(document).off("click.trafficSite").on("click.trafficSite", ".trafficSiteLink", function (event) {
		event.preventDefault();
		createAdminInterfaceWindow(48, "from:" + $(this).attr("data-site") + ":" + trafficSourcesDays);
	});
</script>
