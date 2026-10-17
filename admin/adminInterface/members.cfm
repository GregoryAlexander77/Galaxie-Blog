<!--- Members (window 97, 2026-10-15; the combined list 2026-10-17). Everyone who isn't running the blog, in one list: member
accounts, subscribers, people who booked or signed up for an event, people who sent a form, and the profiles shown on the site,
matched by email address (Members.cfc getPeopleForAdmin; see doc/aiDraftArticles/membersCombinedListDesign.cfm). Users run the
blog and are only noted here ("Also a user"). Commenters are left out (owner).
Clicking a member with an account opens them (window 98: their bookings, sign-ups, emails, Delete). Block stops a member signing
in and signs them out everywhere; Unblock lets them sign in again (ProxyController.cfc's setMemberStatus). --->
<cfset peopleList = application.members.getPeopleForAdmin()>
<cfset memberSettings = application.members.getSettings()>
<!--- Up to 10 people: a plain list. More than that: a grid (Kendo when Kendo Professional is loaded, jsGrid otherwise), with
paging, sorting and its own search. --->
<cfset membersUseGrid = arrayLen(peopleList) gt 10>
<!--- The filters and their counts. A person can be in several. --->
<cfset memberFilters = [
	{ key: "all", label: "All", count: arrayLen(peopleList) },
	{ key: "member", label: "Members", count: 0 },
	{ key: "onsite", label: "On the site", count: 0 },
	{ key: "subscriber", label: "Subscribers", count: 0 },
	{ key: "booked", label: "Bookings", count: 0 },
	{ key: "signedup", label: "Event sign-ups", count: 0 },
	{ key: "forms", label: "Forms", count: 0 }
]>
<cfloop array="#peopleList#" index="thisPerson">
	<cfset thisPerson.filterKeys = "all">
	<cfif thisPerson.isMember><cfset thisPerson.filterKeys = listAppend(thisPerson.filterKeys, "member", " ")></cfif>
	<cfif thisPerson.onSite><cfset thisPerson.filterKeys = listAppend(thisPerson.filterKeys, "onsite", " ")></cfif>
	<cfif thisPerson.isSubscriber><cfset thisPerson.filterKeys = listAppend(thisPerson.filterKeys, "subscriber", " ")></cfif>
	<cfif thisPerson.bookings><cfset thisPerson.filterKeys = listAppend(thisPerson.filterKeys, "booked", " ")></cfif>
	<cfif thisPerson.signUps><cfset thisPerson.filterKeys = listAppend(thisPerson.filterKeys, "signedup", " ")></cfif>
	<cfif thisPerson.forms><cfset thisPerson.filterKeys = listAppend(thisPerson.filterKeys, "forms", " ")></cfif>
	<cfloop array="#memberFilters#" index="thisFilter">
		<cfif thisFilter.key neq "all" and listFind(thisPerson.filterKeys, thisFilter.key, " ")><cfset thisFilter.count++></cfif>
	</cfloop>
</cfloop>

<script>
	<!--- Opens one person (window 98) by email address, so it works for people without an account too. Encoded here because
	createAdminInterfaceWindow adds optArgs to the address as it is (a + in an address would become a space). Also used by the grids. --->
	function openMembersPerson(email) {
		createAdminInterfaceWindow(98, encodeURIComponent(email));
	}

	$(document).ready(function() {
		var memberFilter = "all";
		<!--- The list: show the rows that match the chosen filter. --->
		function showMemberRows() {
			var shown = 0;
			$("#memberRows tr.memberRow").each(function() {
				var row = $(this);
				var show = (" " + row.attr("data-filters") + " ").indexOf(" " + memberFilter + " ") >= 0;
				row.toggle(show);
				if (show) { shown++; }
			});
			$("#memberNoMatch").toggle(shown === 0);
		}
		$(".memberFilterButton").on("click", function() {
			memberFilter = $(this).attr("data-filter");
			$(".memberFilterButton").removeClass("k-primary");
			$(this).addClass("k-primary");
			<!--- The grid filters itself (includes/grids/kendo|jsGrid/members.cfm). --->
			if (typeof membersGridFilter === "function") {
				membersGridFilter(memberFilter);
			} else {
				showMemberRows();
			}
		});

		$("#memberRows").on("click", ".memberPersonLink, .memberOpenButton", function(event) {
			event.preventDefault();
			openMembersPerson($(this).attr("data-email"));
		});

		$("#memberRows").on("click", ".memberStatusButton", function() {
			var button = $(this);
			var memberId = button.attr("data-id");
			var status = button.attr("data-status");
			var question = status === "blocked"
				? "Block this member? They're signed out everywhere and can't sign in again until you unblock them."
				: "Unblock this member? They can sign in again.";
			$.when(kendo.ui.ExtYesNoDialog.show({ title: status === "blocked" ? "Block member?" : "Unblock member?", message: question, icon: "k-ext-question", width: "<cfoutput>#application.kendoExtendedUiWindowWidth#</cfoutput>" })).done(function(answer) {
				if (answer.button !== "Yes") { return; }
				jQuery.ajax({
					type: "post",
					url: "<cfoutput>#application.baseUrl#</cfoutput>/common/cfc/ProxyController.cfc?method=setMemberStatus",
					data: { csrfToken: "<cfoutput>#csrfToken#</cfoutput>", memberId: memberId, status: status },
					dataType: "json",
					success: function(response) {
						if (response && response.success) {
							var row = button.closest("tr");
							<!--- "Member" is always the first label; the others stay as they are. --->
							row.find(".memberStatusText").text(function(i, labels) {
								return status === "blocked" ? labels.replace(/^Member(?! \()/, "Member (blocked)") : labels.replace(/^Member \(blocked\)/, "Member");
							});
							button.attr("data-status", status === "blocked" ? "active" : "blocked").text(status === "blocked" ? "Unblock" : "Block");
						}
					},
					error: function(jqXHR) { if (jqXHR.status === 403) { createLoginWindow(); } }
				});
			});
		});
	});
</script>

<cfset blockClass = HtmlUtilsObj.getKendoClass('')>
<cfoutput>
<table align="center" class="k-content adminBlocks" width="100%" cellpadding="5" cellspacing="0" border="0" style="table-layout: fixed">
	<colgroup><col style="width: 20%"><col></colgroup>
	<tr><td colspan="2" class="#blockClass#">Everyone who has booked, signed up, subscribed or written to you, in one place. Each person shows once, with what they've done. People who run the blog are in Users. Members never have access to the admin site.<cfif not memberSettings.enabled> Member accounts are off, so nobody can sign in yet: turn them on in <a href="javascript:createAdminInterfaceWindow(38, 'memberAccounts');">Blog Options &gt; Member Accounts</a>.<cfelseif not application.members.canSendEmail()> Member accounts are on, but nobody can sign in until the blog's email address is filled in, in <a href="javascript:createAdminInterfaceWindow(39);">Blog Settings</a>: sign-in links are sent by email.</cfif></td></tr>
	<tr class="blockSpacer"><td colspan="2" class="border #blockClass#"></td></tr>
	<tr>
		<td class="#blockClass#"></td>
		<td class="#blockClass#"><button type="button" class="k-button" onclick="createAdminInterfaceWindow(103, 0);">Add person</button><span class="k-form-hint">Someone to show on the site who hasn't booked or signed up, eg. a presenter who hosts an event.</span></td>
	</tr>
	<tr class="blockSpacer"><td colspan="2" class="border #blockClass#"></td></tr>
	<tr>
		<td class="#blockClass#" align="right">Show:</td>
		<td class="#blockClass#">
			<cfloop array="#memberFilters#" index="thisFilter">
				<button type="button" class="k-button memberFilterButton<cfif thisFilter.key eq 'all'> k-primary</cfif>" data-filter="#thisFilter.key#" style="margin: 0 4px 4px 0;">#thisFilter.label# #thisFilter.count#</button>
			</cfloop>
		</td>
	</tr>

	<tr class="blockSpacer"><td colspan="2" class="#blockClass#"></td></tr>
	<cfset blockClass = HtmlUtilsObj.getKendoClass(blockClass)>
	<tr class="blockSpacer"><td colspan="2" class="border #blockClass#"></td></tr>
	<tr>
		<td colspan="2" class="#blockClass#">
		<cfif not arrayLen(peopleList)>
			Nobody yet. People appear here when they book, sign up for an event, subscribe, send a form or create an account.
		<cfelseif membersUseGrid>
			<!--- An included file is compiled on its own, so the grids' ## templates aren't read by this cfoutput. --->
			<cfif application.kendoCommercial>
				<cfinclude template="../../includes/grids/kendo/members.cfm">
			<cfelse>
				<cfinclude template="../../includes/grids/jsGrid/members.cfm">
			</cfif>
		<cfelse>
			<table width="100%" cellpadding="4" cellspacing="0" border="0">
				<cfif not session.isMobile>
				<thead>
					<tr>
						<th align="left">Name</th>
						<th align="left">What they've done</th>
						<th align="left">Last activity</th>
						<th align="left">Since</th>
						<th></th>
					</tr>
				</thead>
				</cfif>
				<tbody id="memberRows">
				<cfloop array="#peopleList#" index="thisPerson">
					<cfset personName = '<a href="##" class="memberPersonLink" data-email="#encodeForHtmlAttribute(thisPerson.email)#">' & (len(thisPerson.name) ? encodeForHtml(thisPerson.name) : "(no name)") & '</a>'>
					<cfset personLabels = arrayToList(thisPerson.labels, ", ")>
					<cfset personLast = len(thisPerson.lastActivityText) ? encodeForHtml(thisPerson.lastActivityText) & (isDate(thisPerson.lastActivity) ? ", " & dateFormat(thisPerson.lastActivity, "mmm d, yyyy") : "") : "">
					<cfset personSince = isDate(thisPerson.since) ? dateFormat(thisPerson.since, "mmm yyyy") : "">
					<cfif session.isMobile>
					<!--- Mobile: each person as a small card, so nothing runs off the screen. --->
					<tr class="memberRow" data-filters="#thisPerson.filterKeys#">
						<td style="border-top: 1px solid ##ddd; padding: 8px 0;">
							#personName#<br>
							<a href="mailto:#encodeForHtmlAttribute(thisPerson.email)#">#encodeForHtml(thisPerson.email)#</a><cfif len(thisPerson.phone)><br>#encodeForHtml(thisPerson.phone)#</cfif><br>
							<span class="memberStatusText">#encodeForHtml(personLabels)#</span><cfif thisPerson.isUser><br>Also a user</cfif><br>
							<cfif len(personLast)>#personLast#<br></cfif>
							<button type="button" class="k-button memberOpenButton" data-email="#encodeForHtmlAttribute(thisPerson.email)#">Open</button><cfif thisPerson.isMember> <button type="button" class="k-button memberStatusButton" data-id="#thisPerson.memberId#" data-status="#thisPerson.memberStatus eq 'blocked' ? 'active' : 'blocked'#">#thisPerson.memberStatus eq "blocked" ? "Unblock" : "Block"#</button></cfif>
						</td>
					</tr>
					<cfelse>
					<tr class="memberRow" data-filters="#thisPerson.filterKeys#">
						<td valign="top">#personName#<br><a href="mailto:#encodeForHtmlAttribute(thisPerson.email)#">#encodeForHtml(thisPerson.email)#</a></td>
						<td valign="top"><span class="memberStatusText">#encodeForHtml(personLabels)#</span><cfif thisPerson.isUser><br>Also a user</cfif></td>
						<td valign="top">#personLast#</td>
						<td valign="top">#personSince#</td>
						<td valign="top" align="right" nowrap="nowrap"><button type="button" class="k-button memberOpenButton" data-email="#encodeForHtmlAttribute(thisPerson.email)#">Open</button><cfif thisPerson.isMember> <button type="button" class="k-button memberStatusButton" data-id="#thisPerson.memberId#" data-status="#thisPerson.memberStatus eq 'blocked' ? 'active' : 'blocked'#">#thisPerson.memberStatus eq "blocked" ? "Unblock" : "Block"#</button></cfif></td>
					</tr>
					</cfif>
				</cfloop>
				</tbody>
			</table>
			<p id="memberNoMatch" style="display: none;">Nobody matches.</p>
		</cfif>
		</td>
	</tr>
</table>
</cfoutput>
