<!--- One person (window 98, 2026-10-15; anyone in the combined list 2026-10-17), opened from the Members window (97) with
createAdminInterfaceWindow(98, memberId) or openMembersPerson(email). Their details, what they've done, bookings (each opens the
booking, window 95), sign-ups and forms, email subscriptions and Download their data, all found by their email address; for a
member with an account, also Block/Unblock and Delete. See common/cfc/Members.cfc getPersonForAdmin; saved by
ProxyController.cfc's setMemberStatus, adminDeleteMember and adminExportPersonData. --->
<cfset detailEmail = "">
<cfif isValid("integer", URL.optArgs)>
	<cfset detailAccount = application.members.getMember(val(URL.optArgs))>
	<cfif not structIsEmpty(detailAccount)><cfset detailEmail = detailAccount.email></cfif>
<cfelseif isValid("email", trim(URL.optArgs))>
	<cfset detailEmail = trim(URL.optArgs)>
</cfif>
<cfset detailPerson = len(detailEmail) ? application.members.getPersonForAdmin(detailEmail) : {}>

<cfif structIsEmpty(detailPerson)>
	<p>This person isn't in Members any more. They may have deleted their account.</p>
<cfelse>
<cfset detailMember = detailPerson.member>
<cfset detailHasAccount = detailMember.memberId gt 0>
<cfset memberSettings = application.members.getSettings()>
<!--- Shown on the site (2026-10-17): their public profile (People.cfc's PersonCard), edited in window 103. --->
<cfset detailProfile = detailPerson.personCardId gt 0 ? application.events.getPeople().getCard("guest:" & detailPerson.personCardId, true) : {}>
<cfset detailHosts = structIsEmpty(detailProfile) ? [] : application.events.getPeople().getEventsUsing("guest:" & detailPerson.personCardId)>
<!--- Delete (2026-10-17): what has to be done first, shown before they try (the server checks again). --->
<cfset detailBlockers = application.members.getDeleteBlockers(detailPerson.email)>
<!--- Booking times in the blog's own time zone, like the rest of the admin site. --->
<cfset detailMemberInBlogZone = duplicate(detailMember)>
<cfset detailMemberInBlogZone.timeZone = application.blog.getBlogTimeZoneId()>
<cfset detailBookings = application.members.getAccountBookings(detailMemberInBlogZone)>
<cfset detailSignups = application.members.getAccountSignups(detailMember)>
<cfset detailSubscriptions = application.members.getAccountSubscriptions(detailMember)>
<cfset detailDevices = detailHasAccount ? application.members.countRememberedDevices(detailMember.memberId) : 0>

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

		<!--- Download their data: the server sends a JSON file (ProxyController.cfc's adminExportPersonData), saved under the name it gives. --->
		$("#memberDetailDownload").on("click", function() {
			var button = $(this);
			button.prop("disabled", true);
			var body = new URLSearchParams();
			body.append("csrfToken", "<cfoutput>#csrfToken#</cfoutput>");
			body.append("email", "<cfoutput>#encodeForJavaScript(detailPerson.email)#</cfoutput>");
			fetch("<cfoutput>#application.baseUrl#</cfoutput>/common/cfc/ProxyController.cfc?method=adminExportPersonData", { method: "POST", body: body, credentials: "same-origin", cache: "no-store" })
				.then(function(response) {
					if (response.status === 403) { createLoginWindow(); throw new Error("signed out"); }
					if (!response.ok) { throw new Error("status " + response.status); }
					var name = /filename="([^"]+)"/.exec(response.headers.get("Content-Disposition") || "");
					return response.blob().then(function(blob) { return { blob: blob, name: name ? name[1] : "data.json" }; });
				})
				.then(function(file) {
					var link = document.createElement("a");
					link.href = URL.createObjectURL(file.blob);
					link.download = file.name;
					document.body.appendChild(link);
					link.click();
					setTimeout(function() { URL.revokeObjectURL(link.href); link.remove(); }, 1000);
				})
				.catch(function(error) {
					if (error.message !== "signed out") {
						$.when(kendo.ui.ExtAlertDialog.show({ title: "Download their data", message: "Their data couldn't be downloaded. Please try again.", icon: "k-ext-error", width: "<cfoutput>#application.kendoExtendedUiWindowWidth#</cfoutput>" }));
					}
				})
				.then(function() { button.prop("disabled", false); });
		});

		<!--- Their profile on the site: edit it, or start one with their name and email filled in (personDetail.cfm, window 103). --->
		$("#memberDetailProfile").on("click", function() {
			var cardId = $(this).attr("data-card");
			if (cardId !== "0") {
				createAdminInterfaceWindow(103, cardId);
			} else {
				createAdminInterfaceWindow(103, 0, encodeURIComponent($(this).attr("data-name")), encodeURIComponent($(this).attr("data-email")));
			}
		});

		<!--- Delete everything (2026-10-17, owner's choice): ProxyController.cfc's adminDeletePerson -> Members.cfc adminDeletePerson. --->
		<!--- Remove their picture (ProxyController.cfc adminRemoveMemberPicture); their initials show again. --->
		$("#memberDetailRemovePicture").on("click", function() {
			$.when(kendo.ui.ExtYesNoDialog.show({ title: "Remove picture?", message: "Remove this member's picture? Their initials show instead. They can upload another one.", icon: "k-ext-question", width: "<cfoutput>#application.kendoExtendedUiWindowWidth#</cfoutput>" })).done(function(answer) {
				if (!answer['button'] || answer['button'] !== 'Yes') { return; }
				jQuery.ajax({
					type: "post",
					url: "<cfoutput>#application.baseUrl#</cfoutput>/common/cfc/ProxyController.cfc?method=adminRemoveMemberPicture",
					data: { csrfToken: "<cfoutput>#csrfToken#</cfoutput>", memberId: <cfoutput>#detailMember.memberId#</cfoutput> },
					dataType: "json",
					success: function(response) {
						if (response && response.success) {
							try { $("#memberDetailWindow").data("kendoWindow").refresh(); } catch (error) {}
						}
					},
					error: function(jqXHR) { if (jqXHR.status === 403) { createLoginWindow(); } }
				});
			});
		});

		$("#memberDetailDelete").on("click", function() {
			$.when(kendo.ui.ExtYesNoDialog.show({ title: "Delete everything?", message: "Delete everything about this person? This can't be undone.", icon: "k-ext-question", width: "<cfoutput>#application.kendoExtendedUiWindowWidth#</cfoutput>" })).done(function(answer) {
				if (!answer['button'] || answer['button'] !== 'Yes') { return; }
				jQuery.ajax({
					type: "post",
					url: "<cfoutput>#application.baseUrl#</cfoutput>/common/cfc/ProxyController.cfc?method=adminDeletePerson",
					data: { csrfToken: "<cfoutput>#csrfToken#</cfoutput>", email: "<cfoutput>#encodeForJavaScript(detailPerson.email)#</cfoutput>" },
					dataType: "json",
					success: function(response) {
						if (response && response.success) {
							refreshMembersList();
							try { $("#memberDetailWindow").data("kendoWindow").close(); } catch (error) {}
						} else if (response && response.blockers && response.blockers.length) {
							var list = $("<div>");
							$.each(response.blockers, function(i, text) { list.append($("<p>").text(text)); });
							$.when(kendo.ui.ExtAlertDialog.show({ title: "Not deleted yet", message: list.html(), icon: "k-ext-warning", width: "<cfoutput>#application.kendoExtendedUiWindowWidth#</cfoutput>" }));
						} else {
							$.when(kendo.ui.ExtAlertDialog.show({ title: "Not deleted", message: "They couldn't be deleted. Please try again.", icon: "k-ext-error", width: "<cfoutput>#application.kendoExtendedUiWindowWidth#</cfoutput>" }));
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
	<tr><td colspan="2" class="#blockClass#"><h4 class="adminBlockHeading">#len(detailPerson.name) ? encodeForHtml(detailPerson.name) : encodeForHtml(detailPerson.email)#</h4></td></tr>
	<tr class="blockSpacer"><td colspan="2" class="border #blockClass#"></td></tr>
	<tr>
		<td class="#blockClass#" align="right">Email:</td>
		<td class="#blockClass#"><a href="mailto:#encodeForHtmlAttribute(detailPerson.email)#">#encodeForHtml(detailPerson.email)#</a></td>
	</tr>
	<!--- Their own picture (2026-10-17), with Remove for one that isn't suitable. --->
	<cfif len(detailPerson.picture)>
	<tr class="blockSpacer"><td colspan="2" class="border #blockClass#"></td></tr>
	<tr>
		<td class="#blockClass#" align="right">Picture:</td>
		<td class="#blockClass#"><img src="#encodeForHtmlAttribute(detailPerson.picture)#" alt="" width="60" height="60" style="border-radius: 50%; object-fit: cover; vertical-align: middle;"> <button type="button" class="k-button" id="memberDetailRemovePicture">Remove picture</button></td>
	</tr>
	</cfif>
	<tr class="blockSpacer"><td colspan="2" class="border #blockClass#"></td></tr>
	<tr>
		<td class="#blockClass#" align="right">What they've done:</td>
		<td class="#blockClass#">#encodeForHtml(arrayToList(detailPerson.labels, ", "))#<cfif detailPerson.isUser><br>Also a user: they also sign in to run the blog (<a href="javascript:createAdminInterfaceWindow(28);">Users</a>).</cfif></td>
	</tr>
	<cfset detailLabels = detailHasAccount ? "Name,Phone,Time zone,Joined,Last seen,Kept signed in,Status" : "Name,Phone">
	<cfloop list="#detailLabels#" index="thisLabel">
		<cfswitch expression="#thisLabel#">
			<cfcase value="Name"><cfset thisValue = detailHasAccount ? detailMember.name : detailPerson.name></cfcase>
			<cfcase value="Phone"><cfset thisValue = detailHasAccount ? detailMember.phone : detailPerson.phone></cfcase>
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
	<tr><td colspan="2" class="#blockClass#"><h4 class="adminBlockHeading">Shown on the site</h4></td></tr>
	<tr class="blockSpacer"><td colspan="2" class="border #blockClass#"></td></tr>
	<cfif structIsEmpty(detailProfile)>
	<tr><td colspan="2" class="#blockClass#">Not shown on the site. Show them when they host an event, so visitors can see who they are: a profile with a picture, biography and links opens from their name, with a form that emails them. Their email address is never shown.</td></tr>
	<cfelse>
	<tr><td colspan="2" class="#blockClass#"><cfif detailProfile.active>Their profile opens from their name on the site, with a form that emails them. Their email address is never shown.<cfelse>Their profile is hidden: it isn't shown on the site, and they can't be chosen as an event's host.</cfif></td></tr>
	<tr class="blockSpacer"><td colspan="2" class="border #blockClass#"></td></tr>
	<tr>
		<td class="#blockClass#" align="right">Profile:</td>
		<td class="#blockClass#"><cfif len(detailProfile.picture)><img src="#encodeForHtmlAttribute(detailProfile.picture)#" alt="" width="60" height="60" style="border-radius: 50%; object-fit: cover; vertical-align: middle;"> </cfif>#encodeForHtml(detailProfile.name)#<cfif not detailProfile.active> (hidden)</cfif></td>
	</tr>
	<tr class="blockSpacer"><td colspan="2" class="border #blockClass#"></td></tr>
	<tr>
		<td class="#blockClass#" align="right">Hosts:</td>
		<td class="#blockClass#"><cfif arrayLen(detailHosts)><cfloop array="#detailHosts#" index="thisHosted"><div>#encodeForHtml(thisHosted)#</div></cfloop><cfelse>No events</cfif></td>
	</tr>
	</cfif>
	<tr class="blockSpacer"><td colspan="2" class="border #blockClass#"></td></tr>
	<tr>
		<td class="#blockClass#"></td>
		<td class="#blockClass#"><button type="button" class="k-button" id="memberDetailProfile" data-card="#structIsEmpty(detailProfile) ? 0 : detailProfile.id#" data-name="#encodeForHtmlAttribute(detailPerson.name)#" data-email="#encodeForHtmlAttribute(detailPerson.email)#"><cfif structIsEmpty(detailProfile)>Show on the site<cfelse>Edit their profile</cfif></button></td>
	</tr>

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
	<tr><td colspan="2" class="#blockClass#"><h4 class="adminBlockHeading">Sign-ups and forms</h4></td></tr>
	<tr class="blockSpacer"><td colspan="2" class="border #blockClass#"></td></tr>
	<tr>
		<td colspan="2" class="#blockClass#">
		<cfif not arrayLen(detailSignups)>
			No event sign-ups or forms.
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
	<tr><td colspan="2" class="#blockClass#"><h4 class="adminBlockHeading">Their data</h4></td></tr>
	<tr class="blockSpacer"><td colspan="2" class="border #blockClass#"></td></tr>
	<tr><td colspan="2" class="#blockClass#">Everything the blog keeps about them, as a file: <cfif detailHasAccount>their account, </cfif>bookings, sign-ups and forms with their answers, email subscriptions and comments. Send it to them if they ask what you have about them.</td></tr>
	<tr class="blockSpacer"><td colspan="2" class="border #blockClass#"></td></tr>
	<tr>
		<td class="#blockClass#"></td>
		<td class="#blockClass#"><button type="button" class="k-button" id="memberDetailDownload">Download their data</button></td>
	</tr>

	<tr class="blockSpacer"><td colspan="2" class="#blockClass#"></td></tr>
	<cfset blockClass = HtmlUtilsObj.getKendoClass(blockClass)>
	<tr class="blockSpacer"><td colspan="2" class="border #blockClass#"></td></tr>
	<tr><td colspan="2" class="#blockClass#"><h4 class="adminBlockHeading">Account</h4></td></tr>
	<tr class="blockSpacer"><td colspan="2" class="border #blockClass#"></td></tr>
	<cfif not detailHasAccount>
	<tr><td colspan="2" class="#blockClass#">No account yet.<cfif memberSettings.enabled> They can make one by signing in on the site with this email address, and everything above is there for them straight away.<cfelse> Member accounts are off, in <a href="javascript:createAdminInterfaceWindow(38, 'memberAccounts');">Blog Options &gt; Member Accounts</a>.</cfif></td></tr>
	<cfelse>
	<tr><td colspan="2" class="#blockClass#"><cfif detailMember.status eq "blocked">Unblocking lets them sign in again.<cfelse>Blocking signs them out everywhere at once and stops them signing in until you unblock them. They aren't told.</cfif></td></tr>
	<tr class="blockSpacer"><td colspan="2" class="border #blockClass#"></td></tr>
	<tr>
		<td class="#blockClass#"></td>
		<td class="#blockClass#"><button type="button" class="k-button" id="memberDetailStatus" data-status="#detailMember.status eq 'blocked' ? 'active' : 'blocked'#">#detailMember.status eq "blocked" ? "Unblock" : "Block"#</button> <button type="button" class="k-button" onclick="createAdminInterfaceWindow(105, #detailMember.memberId#);">Sign-ins</button></td>
	</tr>
	</cfif>

	<tr class="blockSpacer"><td colspan="2" class="#blockClass#"></td></tr>
	<cfset blockClass = HtmlUtilsObj.getKendoClass(blockClass)>
	<tr class="blockSpacer"><td colspan="2" class="border #blockClass#"></td></tr>
	<tr><td colspan="2" class="#blockClass#"><h4 class="adminBlockHeading">Delete</h4></td></tr>
	<tr class="blockSpacer"><td colspan="2" class="border #blockClass#"></td></tr>
	<tr><td colspan="2" class="#blockClass#">Deletes everything about them<cfif detailHasAccount>: their account (they're signed out everywhere),<cfelse>:</cfif> their email subscriptions<cfif not structIsEmpty(detailProfile)> and their profile on the site</cfif>. On past bookings, sign-ups and forms, their name, email, phone and answers become "Deleted person"; the dates and amounts stay for your records. Comments they wrote stay as they are. This can't be undone.</td></tr>
	<cfif arrayLen(detailBlockers)>
	<tr class="blockSpacer"><td colspan="2" class="border #blockClass#"></td></tr>
	<tr>
		<td class="#blockClass#" align="right">First:</td>
		<td class="#blockClass#"><cfloop array="#detailBlockers#" index="thisBlocker"><div>#encodeForHtml(thisBlocker)#</div></cfloop></td>
	</tr>
	</cfif>
	<tr class="blockSpacer"><td colspan="2" class="border #blockClass#"></td></tr>
	<tr>
		<td class="#blockClass#"></td>
		<td class="#blockClass#"><button type="button" class="k-button" id="memberDetailDelete">Delete everything</button></td>
	</tr>
</table>
</cfoutput>
</cfif>
