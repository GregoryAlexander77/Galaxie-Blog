<!--- Schedule Release window, opened from the "Schedule Release" button in the post editor's Misc section (createAdminInterfaceWindow(69, postId)). Manages the same automatic future-post mechanism savePost() already creates when Date Posted is set to a future date (see blog.cfc, the "Handle future posts" block in savePost(), and releaseFuturePosts()); this window just gives it a dedicated, visible place instead of only working as a side effect of changing Date Posted. --->
<cfset postId = URL.optArgs>
<cfset getPost = application.blog.getPostByPostId(postId, true, true)>
<cfset scheduleInfo = application.blog.getScheduledReleaseInfo(postId)>
<cfset alreadyReleased = arrayLen(getPost) and getPost[1]["Released"]>

<script>

	$(document).ready(function() {

		<cfif not alreadyReleased>
		<!--- A single combined date+time widget, same as the Post Sort Date window (blogSortDate.cfm) uses - Kendo Core doesn't reliably support the separate TimePicker widget, and this is the pattern already proven to work elsewhere in the admin. --->
		$("#scheduleReleaseDateTime").kendoDateTimePicker({
			componentType: "modern",
			min: new Date()
		});

		var scheduleReleaseSubmit = $('#scheduleReleaseSubmit');
		scheduleReleaseSubmit.on('click', function(e) {
			e.preventDefault();

			var releaseDateTime = $("#scheduleReleaseDateTime").data("kendoDateTimePicker").value();
			if (!releaseDateTime) {
				$.when(kendo.ui.ExtAlertDialog.show({ title: "Pick a date and time", message: "Choose a date and time to schedule this for.", icon: "k-ext-warning" }));
				return;
			}

			$.when(kendo.ui.ExtWaitDialog.show({ title: "Please wait...", message: "Scheduling the release.", width: "<cfoutput>#application.kendoExtendedUiWindowWidth#</cfoutput>", icon: "k-ext-information" }));

			jQuery.ajax({
				type: 'post',
				url: '<cfoutput>#application.baseUrl#</cfoutput>/common/cfc/ProxyController.cfc?method=scheduleRelease',
				data: {
					csrfToken: '<cfoutput>#csrfToken#</cfoutput>',
					postId: <cfoutput>#postId#</cfoutput>,
					releaseDate: kendo.toString(releaseDateTime, "MM/dd/yyyy"),
					releaseTime: kendo.toString(releaseDateTime, "HH:mm")
				},
				dataType: "json",
				success: function(response) {
					kendo.ui.ExtWaitDialog.hide();
					if (JSON.parse(response.success) == true) {
						$.when(kendo.ui.ExtAlertDialog.show({ title: "Scheduled", message: "The post will release itself automatically at that date and time.", icon: "k-ext-information" })).done(function() {
							$('#scheduleReleaseWindow').kendoWindow('destroy');
						});
					} else {
						$.when(kendo.ui.ExtAlertDialog.show({ title: "Could not schedule the release", message: response.errorMessage, icon: "k-ext-warning", width: "<cfoutput>#application.kendoExtendedUiWindowWidth#</cfoutput>" }));
					}
				},
				error: function(jqXHR, textStatus, error) {
					kendo.ui.ExtWaitDialog.hide();
					if (jqXHR.status === 403) {
						createLoginWindow();
					} else {
						$.when(kendo.ui.ExtAlertDialog.show({ title: "Error while consuming the scheduleRelease function", message: error, icon: "k-ext-error", width: "<cfoutput>#application.kendoExtendedUiWindowWidth#</cfoutput>" }));
					}
				}
			});
		});
		</cfif>

		<cfif scheduleInfo.scheduled>
		var scheduleReleaseCancel = $('#scheduleReleaseCancel');
		scheduleReleaseCancel.on('click', function(e) {
			e.preventDefault();
			jQuery.ajax({
				type: 'post',
				url: '<cfoutput>#application.baseUrl#</cfoutput>/common/cfc/ProxyController.cfc?method=cancelScheduledRelease',
				data: { csrfToken: '<cfoutput>#csrfToken#</cfoutput>', postId: <cfoutput>#postId#</cfoutput> },
				dataType: "json",
				success: function(response) {
					if (JSON.parse(response.success) == true) {
						$.when(kendo.ui.ExtAlertDialog.show({ title: "Cancelled", message: "The scheduled release was cancelled. The post itself was not changed.", icon: "k-ext-information" })).done(function() {
							$('#scheduleReleaseWindow').kendoWindow('destroy');
						});
					} else {
						$.when(kendo.ui.ExtAlertDialog.show({ title: "Could not cancel", message: response.errorMessage, icon: "k-ext-warning" }));
					}
				}
			});
		});
		</cfif>

	});//...document.ready

</script>

<form id="scheduleReleaseForm" action="#" method="post" data-role="validator">
<input type="hidden" name="csrfToken" id="csrfToken" value="<cfoutput>#csrfToken#</cfoutput>" />
<table align="center" class="k-content tableBorder" width="100%" cellpadding="2" cellspacing="0" border="0">
  <cfsilent>
	<cfset thisContentClass = HtmlUtilsObj.getKendoClass('')>
	<cfset thisColSpan = "2">
  </cfsilent>
  <tr height="1px">
	  <td align="left" valign="top" colspan="2" class="<cfoutput>#thisContentClass#</cfoutput>"></td>
  </tr>

<cfif alreadyReleased>
  <tr height="30px">
	<td align="left" class="<cfoutput>#thisContentClass#</cfoutput>" colspan="2">
		This post is already released, so there is nothing to schedule. Uncheck Released on the post first if you want to take it down and schedule it for later instead.
	</td>
  </tr>
<cfelse>

  <cfif scheduleInfo.scheduled>
	  <tr height="30px">
		<td align="left" class="<cfoutput>#thisContentClass#</cfoutput>" colspan="2">
			This post is currently scheduled to release itself on <strong><cfoutput>#scheduleInfo.startDate#</cfoutput></strong> at <strong><cfoutput>#scheduleInfo.startTime#</cfoutput></strong>. Pick a new date and time below to reschedule it, or cancel it below.
		</td>
	  </tr>
	  <tr height="2px"><td colspan="2" class="<cfoutput>#thisContentClass#</cfoutput>"></td></tr>
	  <cfsilent><cfset thisContentClass = HtmlUtilsObj.getKendoClass(thisContentClass)></cfsilent>
	  <tr height="2px"><td colspan="2" class="border <cfoutput>#thisContentClass#</cfoutput>"></td></tr>
  <cfelse>
	  <tr height="30px">
		<td align="left" class="<cfoutput>#thisContentClass#</cfoutput>" colspan="2">
			Pick a date and time for this post to release itself automatically. This does the same thing as setting Date Posted to a future date on the main post form and checking Released, just from its own window.
		</td>
	  </tr>
	  <tr height="2px"><td colspan="2" class="<cfoutput>#thisContentClass#</cfoutput>"></td></tr>
	  <cfsilent><cfset thisContentClass = HtmlUtilsObj.getKendoClass(thisContentClass)></cfsilent>
	  <tr height="2px"><td colspan="2" class="border <cfoutput>#thisContentClass#</cfoutput>"></td></tr>
  </cfif>

<cfif session.isMobile>
  <tr valign="middle">
	<td class="<cfoutput>#thisContentClass#</cfoutput>" colspan="2">
		<label for="scheduleReleaseDateTime">Release Date &amp; Time</label><br>
		<input id="scheduleReleaseDateTime" name="scheduleReleaseDateTime" style="width: 60%" />
		<div class="k-form-hint">The post goes live by itself at this time.</div>
	</td>
  </tr>
<cfelse><!---<cfif session.isMobile>--->
  <tr valign="middle" height="30px">
	<td align="right" valign="middle" class="<cfoutput>#thisContentClass#</cfoutput>" style="width: 20%">
		<label for="scheduleReleaseDateTime">Release Date &amp; Time</label>
	</td>
	<td align="left" class="<cfoutput>#thisContentClass#</cfoutput>">
		<input id="scheduleReleaseDateTime" name="scheduleReleaseDateTime" style="width: 60%" />
		<span class="k-form-hint">The post goes live by itself at this time.</span>
	</td>
  </tr>
</cfif><!---<cfif session.isMobile>--->

  <tr height="2px"><td colspan="2" class="<cfoutput>#thisContentClass#</cfoutput>"></td></tr>
  <cfsilent><cfset thisContentClass = HtmlUtilsObj.getKendoClass(thisContentClass)></cfsilent>
  <tr height="2px"><td colspan="2" class="border <cfoutput>#thisContentClass#</cfoutput>"></td></tr>

  <tr valign="middle" height="30px">
	<td valign="bottom" align="right" class="<cfoutput>#thisContentClass#</cfoutput>" style="width: 20%">&nbsp;</td>
	<td valign="bottom" align="left" class="<cfoutput>#thisContentClass#</cfoutput>">
		<button id="scheduleReleaseSubmit" name="scheduleReleaseSubmit" class="k-button k-primary" type="button"><cfif scheduleInfo.scheduled>Reschedule<cfelse>Schedule</cfif></button>
		<cfif scheduleInfo.scheduled>
			<button id="scheduleReleaseCancel" name="scheduleReleaseCancel" class="k-button" type="button">Cancel Scheduled Release</button>
		</cfif>
	</td>
  </tr>

</cfif>
</table>
</form>
