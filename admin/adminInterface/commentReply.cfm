<!--- Reply to a comment (window 126, 2026-11-07, owner: "a reply button that opens up a new interface to allow admins to reply ... in
its new kendo window that will close when the submit button is pressed"). Opened from the Comments grid's Reply button and the comment's
detail window, with the comment's id in optArgs. The reply is posted as the signed-in admin (ProxyController.cfc adminReplyToComment),
appears straight away, and the person it answers gets the reply email. A waiting comment can be approved in the same step: a reply
under a comment visitors can't see would answer nothing on the page. --->
<cfsilent>
<cfset crComment = isNumeric(URL.optArgs ?: "") ? application.blog.getComment(val(URL.optArgs)) : []>
<cfset crBlockClass = HtmlUtilsObj.getKendoClass('')>
<cfset crName = "">
<cfset crEmail = "">
<cfif structKeyExists(session, "userName") and len(session.userName)>
	<cftry>
		<cfset crAdmin = entityLoad("Users", { UserName = session.userName }, true)>
		<cfif not isNull(crAdmin)>
			<cfset crName = len(trim(crAdmin.getDisplayName() ?: "")) ? trim(crAdmin.getDisplayName()) : trim(crAdmin.getFullName() ?: "")>
			<cfset crEmail = trim(crAdmin.getEmail() ?: "")>
		</cfif>
		<cfcatch type="any"></cfcatch>
	</cftry>
</cfif>
<cfif arrayLen(crComment)>
	<cfset crRow = crComment[1]>
	<cfset crApproved = crRow["Approved"] eq true>
	<cfset crPostUrl = application.blog.makeLink(crRow["PostId"])>
</cfif>
</cfsilent>
<style>
	#commentReplyWindow .k-button .fontAwesomeIcon { margin-right: 6px; }
	.crQuote { border-left: 4px solid rgba(128,128,128,.45); padding: 6px 12px; margin: 8px 0 0; max-height: 220px; overflow: auto; }
	.crQuote p:first-child { margin-top: 0; }
	.crQuote p:last-child { margin-bottom: 0; }
	#crReply { width: 100%; box-sizing: border-box; min-height: 170px; font-family: inherit; }
	.crButtons { display: flex; gap: 8px; justify-content: flex-end; margin-top: 10px; }
</style>
<cfoutput>
<cfif not arrayLen(crComment)>
	<table class="k-content adminBlocks" width="100%" cellpadding="5" cellspacing="0" border="0">
		<tr><td class="#crBlockClass#">That comment no longer exists. It may have been deleted.</td></tr>
	</table>
<cfelse>
<table class="k-content adminBlocks" width="100%" cellpadding="5" cellspacing="0" border="0">
	<tr><td class="#crBlockClass#">
		<strong>#encodeForHtml(crRow["CommenterFullName"] ?: "A visitor")#</strong> wrote<cfif isDate(crRow["DatePosted"])> on #dateFormat(crRow["DatePosted"], "mmmm d, yyyy")# at #timeFormat(crRow["DatePosted"], "h:mm tt")#</cfif>,
		on <a href="#encodeForHtmlAttribute(crPostUrl)#" target="_blank" rel="noopener">#encodeForHtml(crRow["PostTitle"])#</a>:
		<div class="crQuote">#application.Udf.formatComment(crRow["Comment"])#</div>
	</td></tr>
	<tr><td class="#crBlockClass#">
		<label for="crReply"><strong>Your reply</strong></label>
		<span class="k-form-hint">&nbsp;Posted as #encodeForHtml(len(crName) ? crName : "you")#<cfif len(crEmail)> (#encodeForHtml(crEmail)#)</cfif>. It appears straight away, and #encodeForHtml(crRow["CommenterFullName"] ?: "they")# will get an email saying you replied.</span>
		<textarea id="crReply" class="k-textbox" rows="7" aria-label="Your reply"></textarea>
		<cfif not crApproved>
			<div style="margin-top: 8px;">
				<input type="checkbox" class="k-checkbox" id="crApprove" checked>
				<label for="crApprove">Approve their comment too. It's waiting for approval, and visitors only see your reply under a comment that is showing.</label>
			</div>
		</cfif>
		<div class="crButtons">
			<button type="button" class="k-button" id="crCancel">Cancel</button>
			<button type="button" class="k-button k-primary" id="crSubmit"><i class="fontAwesomeIcon fas fa-reply"></i>Submit</button>
		</div>
	</td></tr>
</table>
</cfif>
</cfoutput>
<cfif arrayLen(crComment)>
<script>
(function () {
	var win = $("#commentReplyWindow");
	function closeWindow() { var w = win.data("kendoWindow"); if (w) { w.close(); } }
	$("#crCancel").on("click", closeWindow);
	setTimeout(function () { $("#crReply").trigger("focus"); }, 200);
	$("#crSubmit").on("click", function () {
		var text = $.trim($("#crReply").val() || "");
		if (!text) { alert2("Write your reply first", "The reply is empty."); return; }
		var button = $(this).prop("disabled", true);
		jQuery.ajax({
			type: "post", url: "<cfoutput>#application.baseUrl#</cfoutput>/common/cfc/ProxyController.cfc?method=adminReplyToComment", dataType: "json",
			data: { csrfToken: "<cfoutput>#csrfToken#</cfoutput>", commentId: <cfoutput>#val(crRow["CommentId"])#</cfoutput>,
				comments: bypassScriptProtection(text), approveComment: $("#crApprove").length ? $("#crApprove").is(":checked") : false },
			success: function (r) {
				if (typeof r === "string") { try { r = JSON.parse(r); } catch (e) {} }
				if (r && r.success) {
					<!--- The Comments grid shows the reply (and the approval) when it is open. --->
					try { if ($("#commentsGrid").data("kendoGrid")) { $("#commentsGrid").data("kendoGrid").dataSource.read(); } } catch (e) {}
					try { if ($("#commentGrid").data("JSGrid")) { $("#commentGrid").jsGrid("loadData"); } } catch (e) {}
					closeWindow();
					$.when(kendo.ui.ExtWaitDialog.show({ title: "Reply posted", message: "Your reply is showing on the post.", icon: "k-ext-information" }));
					setTimeout(function () { kendo.ui.ExtWaitDialog.hide(); }, 1600);
				} else {
					button.prop("disabled", false);
					alert2("The reply was not posted", (r && r.message) || "Please try again.");
				}
			},
			error: function (jqXHR, textStatus, error) {
				button.prop("disabled", false);
				if (jqXHR.status === 403) { createLoginWindow(); } else { alert2("The reply was not posted", error || "The server could not be reached."); }
			}
		});
	});
})();
</script>
</cfif>
