<!--- Trusted Commenters (window 125, 2026-11-07, owner: "allow admins to auto approve posts from certain members that have used the
login process ... I don't want to allow everyone to auto approve, we need another interface to select certain users"). The owner picks
members here; a comment from one of them is approved straight away while they are signed in as that member (ProxyController.cfc
postCommentSubscribe, Members.cfc getTrustedCommenter). The email typed in the comment form never counts, because anyone can type it.
The list starts empty. Only members who have signed in (so their address is confirmed) can be added. --->
<cfsilent>
<cfset tcBlockClass = HtmlUtilsObj.getKendoClass('')>
<cfset tcModerated = application.BlogOptionDbObj.getBlogModerated()>
<cfset tcMembersOn = structKeyExists(application, "members") and application.members.isEnabled()>
</cfsilent>
<style>
	#trustedCommentersWindow .k-button .fontAwesomeIcon { margin-right: 6px; }
	.tcSearch { display: flex; gap: 8px; align-items: center; flex-wrap: wrap; }
	.tcSearch .k-textbox { flex: 1 1 260px; max-width: 420px; }
	.tcFound { margin-top: 6px; }
	.tcFound div, .tcList div.tcRow { display: flex; align-items: center; gap: 10px; padding: 6px 4px; border-top: 1px solid rgba(128,128,128,.25); }
	.tcFound div span, .tcRow .tcWho { flex: 1 1 auto; }
	.tcRow .tcMeta { opacity: .75; font-size: 90%; white-space: nowrap; }
	.tcEmpty { padding: 8px 4px; opacity: .8; }
</style>
<cfoutput>
<table class="k-content adminBlocks" width="100%" cellpadding="5" cellspacing="0" border="0">
	<tr><td class="#tcBlockClass#">
		Comments from the people on this list appear straight away, without waiting for your approval, but only while they are signed
		in with their member account. If they post without signing in, or someone else types their email address, the comment waits
		for approval as usual. Nobody is on the list until you add them.
		<cfif not tcModerated><br><br><strong>Comment moderation is off on this blog</strong>, so every comment appears straight away
		anyway; the list only matters while comments wait for approval.</cfif>
		<cfif not tcMembersOn><br><br><strong>Member accounts are off</strong>, so nobody can sign in as a member and the list has no effect.
		Turn them on in <a href="javascript:createAdminInterfaceWindow(38);">Blog Options</a> (Member Accounts).</cfif>
	</td></tr>
	<tr><td class="#tcBlockClass#">
		<strong>Add a person</strong><br>
		<span class="k-form-hint">Only members who have signed in at least once are found: signing in confirms their email address.</span>
		<div class="tcSearch" style="margin-top: 6px;">
			<input type="text" id="tcSearchBox" class="k-textbox" placeholder="Type part of a name or email address" aria-label="Find a member by name or email" autocomplete="off">
		</div>
		<div class="tcFound" id="tcFound"></div>
	</td></tr>
	<tr><td class="#tcBlockClass#">
		<strong>Trusted commenters</strong>
		<div class="tcList" id="tcList"><div class="tcEmpty">Loading...</div></div>
	</td></tr>
</table>
</cfoutput>
<script>
(function () {
	var BASE = "<cfoutput>#application.baseUrl#</cfoutput>";
	var CSRF = "<cfoutput>#csrfToken#</cfoutput>";
	function esc(s) { return $("<div/>").text(String(s == null ? "" : s)).html(); }
	function call(method, data, done) {
		jQuery.ajax({
			type: "post", url: BASE + "/common/cfc/ProxyController.cfc?method=" + method, dataType: "json",
			data: $.extend({ csrfToken: CSRF }, data || {}),
			success: function (r) {
				if (typeof r === "string") { try { r = JSON.parse(r); } catch (e) {} }
				done(r && typeof r === "object" ? r : { success: false, message: "Unexpected answer from the server." });
			},
			error: function (jqXHR) { if (jqXHR.status === 403) { createLoginWindow(); } else { done({ success: false, message: "The server could not be reached." }); } }
		});
	}

	function drawList() {
		call("getTrustedCommenters", {}, function (r) {
			var box = $("#tcList").empty();
			var rows = (r && r.data) || [];
			if (!rows.length) { box.append('<div class="tcEmpty">Nobody yet. Find a member above to add them.</div>'); return; }
			$.each(rows, function (i, m) {
				var row = $('<div class="tcRow"></div>');
				var who = $('<span class="tcWho"></span>').append($("<strong></strong>").text(m.name), " ", $('<span class="k-form-hint"></span>').text(m.email));
				if (m.status !== "active") { who.append(' <span class="k-form-hint">(blocked: their comments wait)</span>'); }
				var meta = $('<span class="tcMeta"></span>').text("Added " + m.added + (m.addedBy ? " by " + m.addedBy : "") + " · " + m.comments + (m.comments === 1 ? " comment" : " comments") + " showing since");
				var remove = $('<button type="button" class="k-button normalFontWeight"><i class="fontAwesomeIcon fas fa-user-minus"></i>Remove</button>');
				remove.on("click", function () {
					galaxieConfirm("Take " + m.name + " off the list?", "Their next comments will wait for your approval again. Comments already showing stay as they are.", function () {
						call("removeTrustedCommenter", { memberId: m.memberId }, function (res) {
							if (res.success) { drawList(); search(); } else { alert2("Not removed", res.message || "Please try again."); }
						});
					});
				});
				row.append(who, meta, remove);
				box.append(row);
			});
		});
	}

	var searchTimer = null, lastTerm = null;
	function search() {
		var term = $.trim($("#tcSearchBox").val() || "");
		lastTerm = term;
		var box = $("#tcFound");
		if (term.length < 2) { box.empty(); return; }
		call("findMembersToTrust", { term: term }, function (r) {
			if (term !== lastTerm) { return; }
			box.empty();
			var rows = (r && r.data) || [];
			if (!rows.length) { box.append('<div class="tcEmpty">No member who has signed in matches &ldquo;' + esc(term) + '&rdquo;.</div>'); return; }
			$.each(rows, function (i, m) {
				var add = $('<button type="button" class="k-button k-primary normalFontWeight"><i class="fontAwesomeIcon fas fa-user-check"></i>Add</button>');
				add.on("click", function () {
					add.prop("disabled", true);
					call("addTrustedCommenter", { memberId: m.memberId }, function (res) {
						if (res.success) { drawList(); search(); } else { add.prop("disabled", false); alert2("Not added", res.message || "Please try again."); }
					});
				});
				box.append($("<div></div>").append($("<span></span>").append($("<strong></strong>").text(m.name), " ", $('<span class="k-form-hint"></span>').text(m.email)), add));
			});
		});
	}
	$("#tcSearchBox").on("input", function () { clearTimeout(searchTimer); searchTimer = setTimeout(search, 250); });
	drawList();
})();
</script>
