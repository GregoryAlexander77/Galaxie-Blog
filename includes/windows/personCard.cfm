<!--- Author card (2026-10-16): opened on the site from a byline or an event's organizer (galaxieOpenPersonCard in
includes/templates/tailEndScripts.cfm). Shows the person's picture, name, links and biography, a link to their posts, and a
contact form whose message is emailed straight to them (ProxyController.cfc sendPersonMessage -> People.cfc sendMessage).
Their address is never shown. URL.person is a card reference, 'user:5' or 'guest:3'. --->
<cfsilent>
	<cfparam name="URL.person" default="">
	<cfset personCard = application.events.getPeople().getCard(URL.person)>
	<cfif not structIsEmpty(personCard) and not personCard.active>
		<cfset personCard = {}>
	</cfif>
	<!--- The same rule as the contact form: no captcha for a signed-in admin or member. --->
	<cfset personCaptcha = application.useCaptcha and not application.Udf.isLoggedIn()
		and not (structKeyExists(application, "members") and not structIsEmpty(application.members.getCurrentMember()))>
	<cfset personLinks = []>
	<cfif not structIsEmpty(personCard)>
		<cfif len(personCard.website)><cfset arrayAppend(personLinks, { url: personCard.website, icon: "fa-solid fa-globe", label: "Website" })></cfif>
		<cfif len(personCard.facebookUrl)><cfset arrayAppend(personLinks, { url: personCard.facebookUrl, icon: "fa-brands fa-facebook", label: "Facebook" })></cfif>
		<cfif len(personCard.linkedInUrl)><cfset arrayAppend(personLinks, { url: personCard.linkedInUrl, icon: "fa-brands fa-linkedin", label: "LinkedIn" })></cfif>
		<cfif len(personCard.instagramUrl)><cfset arrayAppend(personLinks, { url: personCard.instagramUrl, icon: "fa-brands fa-instagram", label: "Instagram" })></cfif>
		<cfif len(personCard.twitterUrl)><cfset arrayAppend(personLinks, { url: personCard.twitterUrl, icon: "fa-brands fa-x-twitter", label: "X (Twitter)" })></cfif>
	</cfif>
</cfsilent>
<cfif structIsEmpty(personCard)>
	<p>This person's card isn't available.</p>
	<cfexit>
</cfif>
<cfoutput>
<div class="galaxiePersonCard">
	<table class="k-content" width="100%" cellpadding="5" cellspacing="0" border="0">
		<tr valign="top">
			<cfif len(personCard.picture)>
			<td width="95"><img src="#encodeForHtmlAttribute(personCard.picture)#" alt="#encodeForHtmlAttribute(personCard.name)#" width="85" height="85" style="border-radius: 50%; object-fit: cover;"></td>
			</cfif>
			<td>
				<h3 class="topContent">#encodeForHtml(personCard.name)#</h3>
				<cfif arrayLen(personLinks)>
				<p class="galaxiePersonLinks">
					<cfloop array="#personLinks#" index="thisLink"><a href="#encodeForHtmlAttribute(thisLink.url)#" target="_blank" rel="noopener" aria-label="#thisLink.label#" title="#thisLink.label#" class="k-button" style="margin: 0 6px 6px 0;"><i class="#thisLink.icon#" aria-hidden="true"></i></a></cfloop>
				</p>
				</cfif>
				<cfif len(personCard.postsUrl)><p><a href="#encodeForHtmlAttribute(personCard.postsUrl)#">See all posts by #encodeForHtml(personCard.name)#</a></p></cfif>
			</td>
		</tr>
		<cfif len(personCard.biography)>
		<tr><td colspan="2">
			<!--- A user's biography is written by the admin in their profile (HTML, shown as on the post's bio box); a guest card's is plain text. --->
			<cfif personCard.kind eq "user">#personCard.biography#<cfelse><p>#replace(encodeForHtml(personCard.biography), chr(10), "<br/>", "all")#</p></cfif>
		</td></tr>
		</cfif>
	</table>

	<h4 class="adminBlockHeading" style="margin-top: 12px;">Send #encodeForHtml(personCard.name)# a message</h4>
	<div id="personMessageDone" style="display: none;"></div>
	<form id="personMessageForm" onsubmit="return false;" novalidate>
		<table class="k-content" width="100%" cellpadding="5" cellspacing="0" border="0">
			<tr><td><label for="personFromName">Your name:</label><br/><input type="text" id="personFromName" class="k-textbox" data-member-fill="name" maxlength="125" style="width: 95%;" autocomplete="name"></td></tr>
			<tr><td><label for="personFromEmail">Your email:</label><br/><input type="email" id="personFromEmail" class="k-textbox" data-member-fill="email" maxlength="255" style="width: 95%;" autocomplete="email"><div class="k-form-hint">So they can reply. It isn't shown on the site.</div></td></tr>
			<tr><td><label for="personMessage">Message:</label><br/><textarea id="personMessage" class="k-textbox" rows="6" maxlength="5000" style="width: 95%;"></textarea></td></tr>
			<cfif personCaptcha>
			<tr><td>
				<label for="personCaptchaText">Type the letters in the picture:</label><br/>
				<img id="personCaptchaImage" alt="Letters to type" style="vertical-align: middle;"> <a href="javascript:personLoadCaptcha();">New picture</a><br/>
				<input type="text" id="personCaptchaText" class="k-textbox" maxlength="10" autocomplete="off" style="width: 160px; margin-top: 6px;">
			</td></tr>
			</cfif>
			<tr><td><button type="button" id="personMessageSend" class="k-button k-primary">Send</button> <span id="personMessageStatus" role="status"></span></td></tr>
		</table>
	</form>
</div>
</cfoutput>

<script>
	(function() {
		var person = <cfoutput>#serializeJson(personCard.ref)#</cfoutput>;
		var personName = <cfoutput>#serializeJson(personCard.name)#</cfoutput>;
		var useCaptcha = <cfoutput>#personCaptcha ? "true" : "false"#</cfoutput>;
		var proxyUrl = "<cfoutput>#application.baseUrl#</cfoutput>/common/cfc/ProxyController.cfc";

		<!--- The captcha picture (getCaptchaAsJson, as for the contact form). The word is checked on the server. --->
		window.personLoadCaptcha = function() {
			if (!useCaptcha) { return; }
			jQuery.ajax({ type: "post", url: proxyUrl + "?method=getCaptchaAsJson", dataType: "json" }).done(function(data) {
				var rows = $.isArray(data) ? data : (data && $.isArray(data.data) ? data.data : [data]);
				var row = rows[0] || {};
				var imageUrl = "";
				$.each(row, function(key, value) { if (/captchaImageUrl/i.test(key)) { imageUrl = value; } });
				$("#personCaptchaImage").attr("src", imageUrl);
				$("#personCaptchaText").val("");
			});
		};
		personLoadCaptcha();

		<!--- A signed-in member's name and email fill in by themselves: common/js/members.js watches for data-member-fill fields. --->

		function status(text) { $("#personMessageStatus").text(text); }

		$("#personMessageSend").on("click", function() {
			var fromName = $.trim($("#personFromName").val());
			var fromEmail = $.trim($("#personFromEmail").val());
			var message = $.trim($("#personMessage").val());
			if (!fromName) { status("Enter your name."); $("#personFromName").focus(); return; }
			if (!/^[^@\s]+@[^@\s]+\.[^@\s]+$/.test(fromEmail)) { status("Enter a valid email address, so they can reply."); $("#personFromEmail").focus(); return; }
			if (!message) { status("Enter your message."); $("#personMessage").focus(); return; }
			if (useCaptcha && !$.trim($("#personCaptchaText").val())) { status("Type the letters in the picture."); $("#personCaptchaText").focus(); return; }
			$("#personMessageSend").prop("disabled", true);
			status("Sending...");
			jQuery.ajax({
				type: "post",
				url: proxyUrl + "?method=sendPersonMessage",
				data: { person: person, fromName: fromName, fromEmail: fromEmail, message: message, captchaText: useCaptcha ? $.trim($("#personCaptchaText").val()) : "" },
				dataType: "json"
			}).done(function(response) {
				$("#personMessageSend").prop("disabled", false);
				if (response && response.success) {
					$("#personMessageForm").hide();
					$("#personMessageDone").text("Your message was sent to " + personName + ".").show();
				} else {
					status(((response && response.errors) || ["The message could not be sent."]).join(" "));
					if (response && response.validCaptcha === false) { personLoadCaptcha(); }
				}
			}).fail(function() {
				$("#personMessageSend").prop("disabled", false);
				status("The message could not be sent. Please try again.");
			});
		});
	})();
</script>
