<!--- Most read (window 124, 11-07, owner: "the 2nd (most read) card ... open up a grid that shows the results"), from the admin home's
Most read card: every post read in the last 7 days, most read first, with its reads this week and in the last 30 days, people only
(AdminHome.cfc getMostRead, counted as the card counts them). Click a column heading to sort; click a post to see its visits in the
Visitor Log. --->
<cfsilent>
<cfset mrRows = application.blog.getAdminHome().getMostRead()>
<cfset blockClass = HtmlUtilsObj.getKendoClass('')>
</cfsilent>
<style>
	#mostReadTable { width: 100%; border-collapse: collapse; }
	#mostReadTable th { text-align: left; padding: 6px 8px; cursor: pointer; white-space: nowrap; }
	#mostReadTable th.mrNum, #mostReadTable td.mrNum { text-align: right; }
	#mostReadTable td { padding: 6px 8px; border-top: 1px solid rgba(128,128,128,.3); }
	#mostReadTable th .fontAwesomeIcon { margin-left: 4px; opacity: .6; }
</style>
<cfoutput>
<table class="k-content adminBlocks" width="100%" cellpadding="5" cellspacing="0" border="0">
	<tr><td class="#blockClass#">Every post read in the last 7 days, by people (bots left out), most read first. Click a heading to sort, or a post to see its visits in the Visitor Log.</td></tr>
	<tr><td class="#blockClass#">
	<cfif not arrayLen(mrRows)>
		No reads yet this week.
	<cfelse>
		<table id="mostReadTable">
			<thead><tr>
				<th data-sort="text">Post</th>
				<th class="mrNum" data-sort="week">This week <i class="fontAwesomeIcon fas fa-arrow-down"></i></th>
				<th class="mrNum" data-sort="month">Last 30 days</th>
			</tr></thead>
			<tbody>
			<cfloop array="#mrRows#" index="mrRow">
				<tr data-week="#mrRow.week#" data-month="#mrRow.month#" data-text="#encodeForHtmlAttribute(lCase(mrRow.title))#">
					<td><a href="javascript:createAdminInterfaceWindow(48, 0, 0, #mrRow.postId#);" title="See its visits in the Visitor Log">#encodeForHtml(mrRow.title)#</a><cfif mrRow.isPage> <span class="k-form-hint">(page)</span></cfif></td>
					<td class="mrNum">#numberFormat(mrRow.week)#</td>
					<td class="mrNum">#numberFormat(mrRow.month)#</td>
				</tr>
			</cfloop>
			</tbody>
		</table>
	</cfif>
	</td></tr>
</table>
</cfoutput>
<script>
(function () {
	var table = $("#mostReadTable"), by = "week", down = true;
	table.find("th").on("click", function () {
		var key = $(this).attr("data-sort");
		down = key === by ? !down : key !== "text";
		by = key;
		var rows = table.find("tbody tr").get();
		rows.sort(function (a, b) {
			var x = $(a).attr("data-" + by), y = $(b).attr("data-" + by);
			var c = by === "text" ? x.localeCompare(y) : (+x) - (+y);
			return down ? -c : c;
		});
		table.find("tbody").append(rows);
		table.find("th .fontAwesomeIcon").remove();
		$(this).append('<i class="fontAwesomeIcon fas fa-arrow-' + (down ? "down" : "up") + '"></i>');
	});
})();
</script>
