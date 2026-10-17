<!--- Events (window 101, 2026-10-15), the Events icon on the admin home page. Every post that is an event: upcoming first, then
past ones. Open shows the event (window 99); Sign-ups shows who's coming (window 100). An event is made from a post: open the
post and click Event in the editor. See common/cfc/Events.cfc. --->
<cfset eventList = application.events.getEventsForAdmin()>

<script>
	$(document).ready(function() {
		<!--- Search as you type, on the event's title. --->
		$("#eventSearch").on("input", function() {
			var text = $.trim($(this).val()).toLowerCase();
			$("#eventRows tr.eventRow").each(function() {
				$(this).toggle(!text.length || $(this).attr("data-search").indexOf(text) >= 0);
			});
		});
	});
</script>

<cfset blockClass = HtmlUtilsObj.getKendoClass('')>
<cfoutput>
<table align="center" class="k-content adminBlocks" width="100%" cellpadding="5" cellspacing="0" border="0" style="table-layout: fixed">
	<colgroup><col style="width: 20%"><col></colgroup>
	<tr><td colspan="2" class="#blockClass#">Every post that is an event. To make a post an event, <a href="javascript:createAdminInterfaceWindow(5);">open it</a> and click Event in the editor: you choose when and where, and whether people sign up (RSVP). Open changes an event; Sign-ups shows who's coming.</td></tr>
	<tr class="blockSpacer"><td colspan="2" class="border #blockClass#"></td></tr>
	<tr><td colspan="2" class="#blockClass#">Visitors see every upcoming event on the Events page, in the Upcoming Events pod (switch it off in <a href="javascript:createAdminInterfaceWindow(29);">Themes</a>), and in the calendar feed they can subscribe to. New-post emails start with the event's details.</td></tr>
	<tr class="blockSpacer"><td colspan="2" class="border #blockClass#"></td></tr>
	<tr>
		<td class="#blockClass#" align="right">Events page:</td>
		<td class="#blockClass#"><a href="#encodeForHtmlAttribute(application.events.getEventsPageUrl())#" target="_blank" rel="noopener">#encodeForHtml(application.events.getEventsPageUrl())#</a></td>
	</tr>
	<tr class="blockSpacer"><td colspan="2" class="border #blockClass#"></td></tr>
	<tr>
		<td class="#blockClass#" align="right">Calendar feed:</td>
		<td class="#blockClass#">#encodeForHtml(application.events.getFeedUrl())#</td>
	</tr>
	<!--- Search finds events by title as you type; only worth showing once the list is long (owner, 10-16). --->
	<cfif arrayLen(eventList) gt 10>
	<tr class="blockSpacer"><td colspan="2" class="border #blockClass#"></td></tr>
	<tr>
		<td class="#blockClass#" align="right"><label for="eventSearch">Search:</label></td>
		<td class="#blockClass#"><input type="text" id="eventSearch" class="k-textbox" style="width: 60%;" placeholder="Event title"><span class="k-form-hint">#arrayLen(eventList)# event<cfif arrayLen(eventList) neq 1>s</cfif></span></td>
	</tr>
	</cfif>

	<tr class="blockSpacer"><td colspan="2" class="#blockClass#"></td></tr>
	<cfset blockClass = HtmlUtilsObj.getKendoClass(blockClass)>
	<tr class="blockSpacer"><td colspan="2" class="border #blockClass#"></td></tr>
	<tr>
		<td colspan="2" class="#blockClass#">
		<cfif not arrayLen(eventList)>
			No events yet. Open a post and click Event in the editor to make it one.
		<cfelse>
			<table width="100%" cellpadding="4" cellspacing="0" border="0">
				<cfif not session.isMobile>
				<thead>
					<tr>
						<th align="left">Event</th>
						<th align="left">When</th>
						<th align="left">Status</th>
						<th align="left">Sign-ups</th>
						<th></th>
					</tr>
				</thead>
				</cfif>
				<tbody id="eventRows">
				<cfloop array="#eventList#" index="thisEvent">
					<cfset thisStatus = thisEvent.isPast ? "Over" : (thisEvent.status eq "scheduled" ? "Scheduled" : (thisEvent.status eq "postponed" ? "Postponed" : "Cancelled"))>
					<cfset thisSignups = not thisEvent.hasRsvp ? "No sign-ups" : thisEvent.people & (thisEvent.capacity gt 0 ? " of " & thisEvent.capacity : "") & (thisEvent.people eq 1 and thisEvent.capacity eq 0 ? " person" : " people")>
					<cfif session.isMobile>
					<!--- Mobile: each event as a small card, so nothing runs off the screen. --->
					<tr class="eventRow" data-search="#encodeForHtmlAttribute(lCase(thisEvent.title))#">
						<td style="border-top: 1px solid ##ddd; padding: 8px 0;">
							<a href="javascript:createAdminInterfaceWindow(99, #thisEvent.postId#);">#encodeForHtml(thisEvent.title)#</a><br>
							#encodeForHtml(thisEvent.whenText)#<br>
							#thisStatus#. #thisSignups#<br>
							<button type="button" class="k-button" onclick="createAdminInterfaceWindow(99, #thisEvent.postId#);">Open</button><cfif thisEvent.hasRsvp> <button type="button" class="k-button" onclick="createAdminInterfaceWindow(100, #thisEvent.postId#);">Sign-ups</button></cfif>
						</td>
					</tr>
					<cfelse>
					<tr class="eventRow" data-search="#encodeForHtmlAttribute(lCase(thisEvent.title))#">
						<td style="border-top: 1px solid ##ddd;"><a href="javascript:createAdminInterfaceWindow(99, #thisEvent.postId#);">#encodeForHtml(thisEvent.title)#</a></td>
						<td style="border-top: 1px solid ##ddd;">#encodeForHtml(thisEvent.whenText)#</td>
						<td style="border-top: 1px solid ##ddd;">#thisStatus#</td>
						<td style="border-top: 1px solid ##ddd;">#thisSignups#</td>
						<td style="border-top: 1px solid ##ddd;" align="right" nowrap="nowrap"><button type="button" class="k-button" onclick="createAdminInterfaceWindow(99, #thisEvent.postId#);">Open</button><cfif thisEvent.hasRsvp> <button type="button" class="k-button" onclick="createAdminInterfaceWindow(100, #thisEvent.postId#);">Sign-ups</button></cfif></td>
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
