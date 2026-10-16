<!--- Members (window 97, 2026-10-15), opened from Blog Options > Member Accounts. Visitors who signed in with an emailed link
(see common/cfc/Members.cfc). Clicking a member opens them (window 98: their bookings, sign-ups, emails, Delete). Block stops a member signing in and signs them out everywhere; Unblock lets them sign in again.
Saved by ProxyController.cfc's setMemberStatus. Members are not admin users and never appear in Users. --->
<cfset memberList = application.members.getMembersForAdmin()>
<cfset memberSettings = application.members.getSettings()>

<script>
	$(document).ready(function() {
		<!--- Search as you type: name, email or phone. --->
		$("#memberSearch").on("input", function() {
			var text = $.trim($(this).val()).toLowerCase();
			$("#memberRows tr.memberRow").each(function() {
				$(this).toggle(!text.length || $(this).attr("data-search").indexOf(text) >= 0);
			});
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
							row.find(".memberStatusText").text(status === "blocked" ? "Blocked" : "Active");
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
	<tr><td colspan="2" class="#blockClass#">Visitors who have signed in with an emailed link. Click a member to see their bookings, sign-ups and emails, or to delete them. They can see their own bookings and sign-ups, and have their details filled in; they never have access to the admin site.<cfif not memberSettings.enabled> Member accounts are off: turn them on in <a href="javascript:createAdminInterfaceWindow(38);">Blog Options &gt; Member Accounts</a>.</cfif></td></tr>
	<tr class="blockSpacer"><td colspan="2" class="border #blockClass#"></td></tr>
	<tr>
		<td class="#blockClass#" align="right"><label for="memberSearch">Search:</label></td>
		<td class="#blockClass#"><input type="text" id="memberSearch" class="k-textbox" style="width: 60%;" placeholder="Name, email or phone"><span class="k-form-hint">#arrayLen(memberList)# member<cfif arrayLen(memberList) neq 1>s</cfif></span></td>
	</tr>

	<tr class="blockSpacer"><td colspan="2" class="#blockClass#"></td></tr>
	<cfset blockClass = HtmlUtilsObj.getKendoClass(blockClass)>
	<tr class="blockSpacer"><td colspan="2" class="border #blockClass#"></td></tr>
	<tr>
		<td colspan="2" class="#blockClass#">
		<cfif not arrayLen(memberList)>
			No members yet.
		<cfelse>
			<table width="100%" cellpadding="4" cellspacing="0" border="0">
				<cfif not session.isMobile>
				<thead>
					<tr>
						<th align="left">Name</th>
						<th align="left">Email</th>
						<th align="left">Phone</th>
						<th align="left">Joined</th>
						<th align="left">Last seen</th>
						<th align="left">Status</th>
						<th></th>
					</tr>
				</thead>
				</cfif>
				<tbody id="memberRows">
				<cfloop array="#memberList#" index="thisMember">
					<cfif session.isMobile>
					<!--- Mobile: each member as a small card, so nothing runs off the screen. --->
					<tr class="memberRow" data-search="#encodeForHtmlAttribute(lCase(thisMember.name & ' ' & thisMember.email & ' ' & thisMember.phone))#">
						<td style="border-top: 1px solid ##ddd; padding: 8px 0;">
							<a href="javascript:createAdminInterfaceWindow(98, #thisMember.memberId#);">#len(thisMember.name) ? encodeForHtml(thisMember.name) : "(no name)"#</a><br>
							#encodeForHtml(thisMember.email)#<cfif len(thisMember.phone)><br>#encodeForHtml(thisMember.phone)#</cfif><br>
							Joined #isDate(thisMember.created) ? dateFormat(thisMember.created, "mmm d, yyyy") : ""#<cfif isDate(thisMember.lastSeen)>, last seen #dateFormat(thisMember.lastSeen, "mmm d, yyyy")#</cfif><br>
							<span class="memberStatusText">#thisMember.status eq "blocked" ? "Blocked" : "Active"#</span><br>
							<button type="button" class="k-button" onclick="createAdminInterfaceWindow(98, #thisMember.memberId#);">Open</button> <button type="button" class="k-button memberStatusButton" data-id="#thisMember.memberId#" data-status="#thisMember.status eq 'blocked' ? 'active' : 'blocked'#">#thisMember.status eq "blocked" ? "Unblock" : "Block"#</button>
						</td>
					</tr>
					<cfelse>
					<tr class="memberRow" data-search="#encodeForHtmlAttribute(lCase(thisMember.name & ' ' & thisMember.email & ' ' & thisMember.phone))#">
						<td><a href="javascript:createAdminInterfaceWindow(98, #thisMember.memberId#);">#len(thisMember.name) ? encodeForHtml(thisMember.name) : "(no name)"#</a></td>
						<td>#encodeForHtml(thisMember.email)#</td>
						<td>#encodeForHtml(thisMember.phone)#</td>
						<td>#isDate(thisMember.created) ? dateFormat(thisMember.created, "mmm d, yyyy") : ""#</td>
						<td>#isDate(thisMember.lastSeen) ? dateFormat(thisMember.lastSeen, "mmm d, yyyy") : ""#</td>
						<td class="memberStatusText">#thisMember.status eq "blocked" ? "Blocked" : "Active"#</td>
						<td align="right" nowrap="nowrap"><button type="button" class="k-button" onclick="createAdminInterfaceWindow(98, #thisMember.memberId#);">Open</button> <button type="button" class="k-button memberStatusButton" data-id="#thisMember.memberId#" data-status="#thisMember.status eq 'blocked' ? 'active' : 'blocked'#">#thisMember.status eq "blocked" ? "Unblock" : "Block"#</button></td>
					</tr>
					</cfif>
				</cfloop>
				</tbody>
			</table>
		</cfif>
		</td>
	</tr>
</table>
</cfoutput>
