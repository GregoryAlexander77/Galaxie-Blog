<!--- People (window 102, 2026-10-16): the cards that open from a byline or an event's organizer on the site - picture, name,
biography, links and a contact form that emails the person directly (common/cfc/People.cfc, includes/windows/personCard.cfm).
Every admin user has a card made from their profile (Edit profile opens the user window, 7). Guest cards are for people who
don't sign in, eg. a guest presenter; New person and Edit open the editor (window 103). --->
<cfset peopleCards = application.events.getPeople().getCards(includeInactiveGuests = true)>
<cfset peopleUsers = arrayFilter(peopleCards, function(card) { return card.kind eq "user"; })>
<cfset peopleGuests = arrayFilter(peopleCards, function(card) { return card.kind eq "guest"; })>

<script>
	<!--- Called by the person editor after a save or delete, so the list stays current. --->
	function refreshPeopleWindow() {
		try {
			$("#peopleWindow").data("kendoWindow").refresh();
		} catch (error) {
			<!--- The window may not be open. --->
		}
	}
</script>

<cfset blockClass = HtmlUtilsObj.getKendoClass('')>
<cfoutput>
<table align="center" class="k-content adminBlocks" width="100%" cellpadding="5" cellspacing="0" border="0" style="table-layout: fixed">
	<colgroup><col style="width: 20%"><col></colgroup>
	<tr><td colspan="2" class="#blockClass#">People are the names visitors see on your site: the author of each post (shown in its byline) and the organizer of each event. When a visitor clicks one of those names, a card opens with that person's picture, biography and links, and a form for sending them a message. The message is emailed straight to the person; visitors never see their email address.</td></tr>
	<tr class="blockSpacer"><td colspan="2" class="border #blockClass#"></td></tr>
	<tr><td colspan="2" class="#blockClass#">There are two kinds of people, and the difference is whether they can sign in. <b>Users</b> are admins: they sign in to this admin site to write posts and run the blog, and their card is made from their profile. <b>Guests</b> never sign in and can't change anything; a guest card only lets you name someone, such as a guest presenter, as an event's organizer, so visitors can read about them and write to them.</td></tr>

	<tr class="blockSpacer"><td colspan="2" class="#blockClass#"></td></tr>
	<cfset blockClass = HtmlUtilsObj.getKendoClass(blockClass)>
	<tr class="blockSpacer"><td colspan="2" class="border #blockClass#"></td></tr>
	<tr><td colspan="2" class="#blockClass#"><h4 class="adminBlockHeading">Users</h4></td></tr>
	<tr class="blockSpacer"><td colspan="2" class="border #blockClass#"></td></tr>
	<tr><td colspan="2" class="#blockClass#">Everyone who can sign in to this admin site. Each user's card is made from their own personal user profile. Edit profile opens that one person's profile: changing the picture, biography or links there changes only their card, not anyone else's and not the rest of the blog.</td></tr>
	<cfloop array="#peopleUsers#" index="thisPerson">
	<tr class="blockSpacer"><td colspan="2" class="border #blockClass#"></td></tr>
	<tr>
		<td class="#blockClass#"><button type="button" class="k-button" style="width: 100%;" onclick="createAdminInterfaceWindow(7, #thisPerson.id#);">Edit profile</button></td>
		<td class="#blockClass#">#encodeForHtml(thisPerson.name)#<cfif not len(thisPerson.biography)> <span class="k-form-hint">No biography yet: add one to their profile.</span></cfif></td>
	</tr>
	</cfloop>

	<tr class="blockSpacer"><td colspan="2" class="#blockClass#"></td></tr>
	<cfset blockClass = HtmlUtilsObj.getKendoClass(blockClass)>
	<tr class="blockSpacer"><td colspan="2" class="border #blockClass#"></td></tr>
	<tr><td colspan="2" class="#blockClass#"><h4 class="adminBlockHeading">Guests</h4></td></tr>
	<tr class="blockSpacer"><td colspan="2" class="border #blockClass#"></td></tr>
	<tr><td colspan="2" class="#blockClass#">People who don't sign in to this admin site, but whom you want to present on yours: a guest presenter or speaker, a co-host, a partner. Add them here so you can name them as an event's organizer; visitors can read about them and write to them, and messages go to the email address on their card. Guests aren't your customers: your customers are your <a href="javascript:createAdminInterfaceWindow(97);">Members</a>, who sign in to book or sign up. A guest card can't book anything, and the same person can be both.</td></tr>
	<cfloop array="#peopleGuests#" index="thisPerson">
	<tr class="blockSpacer"><td colspan="2" class="border #blockClass#"></td></tr>
	<tr>
		<td class="#blockClass#"><button type="button" class="k-button" style="width: 100%;" onclick="createAdminInterfaceWindow(103, #thisPerson.id#);">Edit</button></td>
		<td class="#blockClass#">#encodeForHtml(thisPerson.name)#<cfif not thisPerson.active> <span class="k-form-hint">(not active)</span></cfif></td>
	</tr>
	</cfloop>
	<cfif not arrayLen(peopleGuests)>
	<tr class="blockSpacer"><td colspan="2" class="border #blockClass#"></td></tr>
	<tr><td colspan="2" class="#blockClass#">No guests yet.</td></tr>
	</cfif>
	<tr class="blockSpacer"><td colspan="2" class="border #blockClass#"></td></tr>
	<tr>
		<td class="#blockClass#"></td>
		<td class="#blockClass#"><button type="button" class="k-button k-primary" onclick="createAdminInterfaceWindow(103, 0);">New person</button></td>
	</tr>
</table>
</cfoutput>
