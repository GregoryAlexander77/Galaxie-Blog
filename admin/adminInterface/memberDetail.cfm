<!--- One member (window 98, 2026-10-15), opened from the Members window (97) with createAdminInterfaceWindow(98, memberId). Their
details, bookings (each opens the booking, window 95), form sign-ups and email subscriptions, all found by their email address,
and Block/Unblock and Delete. See common/cfc/Members.cfc; saved by ProxyController.cfc's setMemberStatus and adminDeleteMember. --->
<cfset detailMember = application.members.getMember(val(URL.optArgs))>

<cfif structIsEmpty(detailMember)>
	<p>This member no longer exists. They may have deleted their account.</p>
<cfelse>
<!--- Booking times in the blog's own time zone, like the rest of the admin site. --->
<cfset detailMemberInBlogZone = duplicate(detailMember)>
<cfset detailMemberInBlogZone.timeZone = application.blog.getBlogTimeZoneId()>
<cfset detailBookings = application.members.getAccountBookings(detailMemberInBlogZone)>
<cfset detailSignups = application.members.getAccountSignups(detailMember)>
<cfset detailSubscriptions = application.members.getAccountSubscriptions(detailMember)>
<cfset detailDevices = application.members.countRememberedDevices(detailMember.memberId)>

<script>
	$(document).ready(function() {
		function refreshMembersList() {
			try { $("#membersWindow").data("kendoWindow").refresh(); } catch (error) {}
		}

		$("#memberDetailStatus").on("click", function() {
			var status = $(this).attr("data-status");
			var question = status === "blocked"
				? "Block this member? They're signed out everywhere and can't sign in again until you unblock them."
				: "Unblock this member? They can sign in again.";
			$.when(kendo.ui.ExtYesNoDialog.show({ title: status === "blocked" ? "Block member?" : "Unblock member?", message: question, icon: "k-ext-question", width: "<cfoutput>#application.kendoExtendedUiWindowWidth#</cfoutput>" })).done(function(answer) {
				if (!answer['button'] || answer['button'] !== 'Yes') { return; }
				jQuery.ajax({
					type: "post",
					url: "<cfoutput>#application.baseUrl#</cfoutput>/common/cfc/ProxyController.cfc?method=setMemberStatus",
					data: { csrfToken: "<cfoutput>#csrfToken#</cfoutput>", memberId: <cfoutput>#detailMember.memberId#</cfoutput>, status: status },
					dataType: "json",
					success: function(response) {
						if (response && response.success) {
							refreshMembersList();
							try { $("#memberDetailWindow").data("kendoWindow").refresh(); } catch (error) {}
						}
					},
					error: function(jqXHR) { if (jqXHR.status === 403) { createLoginWindow(); } }
				});
			});
		});

		$("#memberDetailDelete").on("click", function() {
			var stopEmails = $("#memberDetailStopEmails").is(":checked");
			$.when(kendo.ui.ExtYesNoDialog.show({ title: "Delete member?", message: "Delete this member's account? They're signed out everywhere. Their bookings, payments, sign-ups and comments are kept." + (stopEmails ? " Their email subscriptions are removed too." : ""), icon: "k-ext-question", width: "<cfoutput>#application.kendoExtendedUiWindowWidth#</cfoutput>" })).done(function(answer) {
				if (!answer['button'] || answer['button'] !== 'Yes') { return; }
				jQuery.ajax({
					type: "post",
					url: "<cfoutput>#application.baseUrl#</cfoutput>/common/cfc/ProxyController.cfc?method=adminDeleteMember",
					data: { csrfToken: "<cfoutput>#csrfToken#</cfoutput>", memberId: <cfoutput>#detailMember.memberId#</cfoutput>, stopEmails: stopEmails },
					dataType: "json",
					success: function(response) {
						if (response && response.success) {
							refreshMembersList();
							try { $("#memberDetailWindow").data("kendoWindow").close(); } catch (error) {}
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
	<tr><td colspan="2" class="#blockClass#"><h4 class="adminBlockHeading">#len(detailMember.name) ? encodeForHtml(detailMember.name) : encodeForHtml(detailMember.email)#</h4></td></tr>
	<cfloop list="Email,Name,Phone,Time zone,Joined,Last seen,Kept signed in,Status" index="thisLabel">
		<cfswitch expression="#thisLabel#">
			<cfcase value="Email"><cfset thisValue = detailMember.email></cfcase>
			<cfcase value="Name"><cfset thisValue = detailMember.name></cfcase>
			<cfcase value="Phone"><cfset thisValue = detailMember.phone></cfcase>
			<cfcase value="Time zone"><cfset thisValue = replace(detailMember.timeZone, "_", " ", "all")></cfcase>
			<cfcase value="Joined"><cfset thisValue = isDate(detailMember.created) ? dateFormat(detailMember.created, "mmmm d, yyyy") : ""></cfcase>
			<cfcase value="Last seen"><cfset thisValue = isDate(detailMember.lastSeen) ? dateFormat(detailMember.lastSeen, "mmmm d, yyyy") & " " & timeFormat(detailMember.lastSeen, "h:mm tt") : ""></cfcase>
			<cfcase value="Kept signed in"><cfset thisValue = detailDevices eq 0 ? "No devices" : detailDevices & " device" & (detailDevices eq 1 ? "" : "s")></cfcase>
			<cfcase value="Status"><cfset thisValue = detailMember.status eq "blocked" ? "Blocked" : "Active"></cfcase>
		</cfswitch>
	<tr class="blockSpacer"><td colspan="2" class="border #blockClass#"></td></tr>
	<tr>
		<td class="#blockClass#" align="right">#thisLabel#:</td>
		<td class="#blockClass#">#len(thisValue) ? encodeForHtml(thisValue) : "-"#</td>
	</tr>
	</cfloop>

	<tr class="blockSpacer"><td colspan="2" class="#blockClass#"></td></tr>
	<cfset blockClass = HtmlUtilsObj.getKendoClass(blockClass)>
	<tr class="blockSpacer"><td colspan="2" class="border #blockClass#"></td></tr>
	<tr><td colspan="2" class="#blockClass#"><h4 class="adminBlockHeading">Bookings</h4></td></tr>
	<tr class="blockSpacer"><td colspan="2" class="border #blockClass#"></td></tr>
	<tr>
		<td colspan="2" class="#blockClass#">
		<cfif not arrayLen(detailBookings)>
			No bookings.
		<cfelse>
			<table width="100%" cellpadding="4" cellspacing="0" border="0">
				<cfloop array="#detailBookings#" index="thisBooking">
				<tr>
					<td>#encodeForHtml(thisBooking.when)#<br>#encodeForHtml(thisBooking.typeName)#<cfif len(thisBooking.location)>, #encodeForHtml(thisBooking.location)#</cfif></td>
					<td width="25%">#encodeForHtml(thisBooking.statusText)#<cfif len(thisBooking.paid)><br>Paid #encodeForHtml(thisBooking.paid)#</cfif><cfif len(thisBooking.stillToPay)><br>Still to pay #encodeForHtml(thisBooking.stillToPay)#</cfif></td>
					<td width="12%" align="right"><button type="button" class="k-button" onclick="createAdminInterfaceWindow(95, #thisBooking.bookingId#);">Open</button></td>
				</tr>
				</cfloop>
			</table>
		</cfif>
		</td>
	</tr>

	<tr class="blockSpacer"><td colspan="2" class="#blockClass#"></td></tr>
	<cfset blockClass = HtmlUtilsObj.getKendoClass(blockClass)>
	<tr class="blockSpacer"><td colspan="2" class="border #blockClass#"></td></tr>
	<tr><td colspan="2" class="#blockClass#"><h4 class="adminBlockHeading">Sign-ups</h4></td></tr>
	<tr class="blockSpacer"><td colspan="2" class="border #blockClass#"></td></tr>
	<tr>
		<td colspan="2" class="#blockClass#">
		<cfif not arrayLen(detailSignups)>
			No sign-ups.
		<cfelse>
			<cfloop array="#detailSignups#" index="thisSignup">
				<div>#encodeForHtml(thisSignup.formTitle)#<cfif len(thisSignup.postTitle)>, on #encodeForHtml(thisSignup.postTitle)#</cfif> (#encodeForHtml(thisSignup.date)#)</div>
			</cfloop>
			<div class="k-form-hint">Their answers are under <a href="javascript:createAdminInterfaceWindow(83);">Forms &gt; Submissions</a>.</div>
		</cfif>
		</td>
	</tr>

	<tr class="blockSpacer"><td colspan="2" class="#blockClass#"></td></tr>
	<cfset blockClass = HtmlUtilsObj.getKendoClass(blockClass)>
	<tr class="blockSpacer"><td colspan="2" class="border #blockClass#"></td></tr>
	<tr><td colspan="2" class="#blockClass#"><h4 class="adminBlockHeading">Emails</h4></td></tr>
	<tr class="blockSpacer"><td colspan="2" class="border #blockClass#"></td></tr>
	<tr>
		<td class="#blockClass#" align="right">New posts:</td>
		<td class="#blockClass#">#detailSubscriptions.newPosts eq "on" ? "Subscribed" : (detailSubscriptions.newPosts eq "unconfirmed" ? "Waiting for them to confirm" : "Not subscribed")#</td>
	</tr>
	<tr class="blockSpacer"><td colspan="2" class="border #blockClass#"></td></tr>
	<tr>
		<td class="#blockClass#" align="right">New comments on:</td>
		<td class="#blockClass#"><cfif not arrayLen(detailSubscriptions.posts)>No posts<cfelse><cfloop array="#detailSubscriptions.posts#" index="thisPost"><div>#encodeForHtml(thisPost.title)#</div></cfloop></cfif></td>
	</tr>

	<tr class="blockSpacer"><td colspan="2" class="#blockClass#"></td></tr>
	<cfset blockClass = HtmlUtilsObj.getKendoClass(blockClass)>
	<tr class="blockSpacer"><td colspan="2" class="border #blockClass#"></td></tr>
	<tr><td colspan="2" class="#blockClass#"><h4 class="adminBlockHeading">Account</h4></td></tr>
	<tr class="blockSpacer"><td colspan="2" class="border #blockClass#"></td></tr>
	<tr><td colspan="2" class="#blockClass#"><cfif detailMember.status eq "blocked">Unblocking lets them sign in again.<cfelse>Blocking signs them out everywhere at once and stops them signing in until you unblock them. They aren't told.</cfif></td></tr>
	<tr class="blockSpacer"><td colspan="2" class="border #blockClass#"></td></tr>
	<tr>
		<td class="#blockClass#"></td>
		<td class="#blockClass#"><button type="button" class="k-button" id="memberDetailStatus" data-status="#detailMember.status eq 'blocked' ? 'active' : 'blocked'#">#detailMember.status eq "blocked" ? "Unblock" : "Block"#</button></td>
	</tr>
	<tr class="blockSpacer"><td colspan="2" class="border #blockClass#"></td></tr>
	<tr><td colspan="2" class="#blockClass#">Deleting removes their account, so they can't see their bookings or sign-ups here any more (they can make a new account by signing in again). Their bookings, payments, form sign-ups and comments are kept for your records.</td></tr>
	<tr class="blockSpacer"><td colspan="2" class="border #blockClass#"></td></tr>
	<tr>
		<td class="#blockClass#" align="right"><label for="memberDetailStopEmails">Remove emails:</label></td>
		<td class="#blockClass#"><input type="checkbox" class="k-checkbox" id="memberDetailStopEmails"><span class="k-form-hint">Also remove their email subscriptions.</span></td>
	</tr>
	<tr class="blockSpacer"><td colspan="2" class="border #blockClass#"></td></tr>
	<tr>
		<td class="#blockClass#"></td>
		<td class="#blockClass#"><button type="button" class="k-button" id="memberDetailDelete">Delete member</button></td>
	</tr>
</table>
</cfoutput>
</cfif>
