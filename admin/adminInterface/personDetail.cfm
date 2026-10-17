<!--- Person editor (window 103, 2026-10-16): a guest card - someone who doesn't sign in, eg. a guest presenter - opened from People
(102) or an event's Add a person link with createAdminInterfaceWindow(103, personCardId); 0 makes a new one. The name and the
email address are required: visitors' messages from the card are emailed there. Saved by ProxyController.cfc's savePersonCard
-> People.cfc saveGuest, which checks everything again on the server. --->
<cfset personCardId = val(URL.optArgs)>
<cfset person = personCardId gt 0 ? application.events.getPeople().getCard("guest:" & personCardId, true) : {}>
<cfset isNewPerson = structIsEmpty(person)>
<cfif isNewPerson>
	<cfset person = { id: 0, name: "", email: "", website: "", picture: "", biography: "", facebookUrl: "", linkedInUrl: "", instagramUrl: "", twitterUrl: "", active: true }>
	<!--- A person added from a dropdown starts with the name typed there (otherArgs). --->
	<cfif structKeyExists(URL, "otherArgs") and len(trim(URL.otherArgs)) and not listFindNoCase("undefined,null", trim(URL.otherArgs))>
		<cfset person.name = left(trim(URL.otherArgs), 125)>
	</cfif>
</cfif>

<script>
	$(document).ready(function() {
		function personData() {
			return {
				personCardId: <cfoutput>#person.id#</cfoutput>,
				displayName: $.trim($("#personDisplayName").val()),
				email: $.trim($("#personEmail").val()),
				website: $.trim($("#personWebsite").val()),
				profilePicture: $.trim($("#personPicture").val()),
				biography: $.trim($("#personBiography").val()),
				facebookUrl: $.trim($("#personFacebook").val()),
				linkedInUrl: $.trim($("#personLinkedIn").val()),
				instagramUrl: $.trim($("#personInstagram").val()),
				twitterUrl: $.trim($("#personTwitter").val()),
				active: $("#personActive").is(":checked")
			};
		}

		<!--- Picture upload (2026-10-16): saved to /images/photo/guest/ by ProxyController uploadGuestPicture; its address goes in the field. --->
		$("#personPictureUpload").on("click", function() { $("#personPictureFile").val("").trigger("click"); });
		$("#personPictureFile").on("change", function() {
			var file = this.files && this.files[0];
			if (!file) { return; }
			var form = new FormData();
			form.append("csrfToken", "<cfoutput>#csrfToken#</cfoutput>");
			form.append("guestPicture", file);
			$("#personPictureStatus").text("Uploading...");
			jQuery.ajax({
				type: "post",
				url: "<cfoutput>#application.baseUrl#</cfoutput>/common/cfc/ProxyController.cfc?method=uploadGuestPicture",
				data: form,
				processData: false,
				contentType: false,
				dataType: "json",
				success: function(response) {
					if (response && response.success) {
						$("#personPicture").val(response.url);
						$("#personPicturePreview").attr("src", response.url).show();
						$("#personPictureStatus").text("Uploaded. Save the card to keep it.");
					} else {
						$("#personPictureStatus").text((response && response.errorMessage) || "The picture could not be uploaded.");
					}
				},
				error: function(jqXHR) {
					$("#personPictureStatus").text("The picture could not be uploaded.");
					if (jqXHR.status === 403) { createLoginWindow(); }
				}
			});
		});
		$("#personPicture").on("change", function() {
			var url = $.trim($(this).val());
			$("#personPicturePreview").attr("src", url).toggle(url.length > 0);
		});

		$("#personSubmit").on("click", function() {
			var data = personData();
			if (!data.displayName || !/^[^@\s]+@[^@\s]+\.[^@\s]+$/.test(data.email)) {
				$.when(kendo.ui.ExtAlertDialog.show({ title: "Name and email", message: "Enter the person's name and a valid email address: visitors' messages are sent there.", icon: "k-ext-warning", width: "<cfoutput>#application.kendoExtendedUiWindowWidth#</cfoutput>" }));
				return;
			}
			$.when(kendo.ui.ExtWaitDialog.show({ title: "Please wait...", message: "Saving the card.", width: "<cfoutput>#application.kendoExtendedUiWindowWidth#</cfoutput>", icon: "k-ext-information" }));
			jQuery.ajax({
				type: "post",
				url: "<cfoutput>#application.baseUrl#</cfoutput>/common/cfc/ProxyController.cfc?method=savePersonCard",
				data: { csrfToken: "<cfoutput>#csrfToken#</cfoutput>", personJson: JSON.stringify(data) },
				dataType: "json",
				success: function(response) {
					kendo.ui.ExtWaitDialog.hide();
					if (response && JSON.parse(response.success) == true) {
						try { refreshPeopleWindow(); } catch (error) {}
						<!--- An event's Person dropdown adds the new card and selects it (eventDetail.cfm). --->
						$(document).trigger("galaxiePersonSaved", [{ ref: response.ref, name: response.name }]);
						$.when(kendo.ui.ExtAlertDialog.show({ title: "Saved", message: "The card was saved.", icon: "k-ext-information" })).done(function() {
							$('#personDetailWindow').kendoWindow('destroy');
						});
					} else {
						$.when(kendo.ui.ExtAlertDialog.show({ title: "Could not save", message: (response && response.errorMessage) || "The card could not be saved.", icon: "k-ext-warning", width: "<cfoutput>#application.kendoExtendedUiWindowWidth#</cfoutput>" }));
					}
				},
				error: function(jqXHR) {
					kendo.ui.ExtWaitDialog.hide();
					if (jqXHR.status === 403) { createLoginWindow(); }
				}
			});
		});

		$("#personDelete").on("click", function() {
			$.when(kendo.ui.ExtYesNoDialog.show({ title: "Delete this card?", message: "Visitors won't be able to see it or write to this person any more.", icon: "k-ext-question", width: "<cfoutput>#application.kendoExtendedUiWindowWidth#</cfoutput>" })).done(function(answer) {
				if (answer['button'] !== 'Yes') { return; }
				jQuery.ajax({
					type: "post",
					url: "<cfoutput>#application.baseUrl#</cfoutput>/common/cfc/ProxyController.cfc?method=deletePersonCard",
					data: { csrfToken: "<cfoutput>#csrfToken#</cfoutput>", personCardId: <cfoutput>#person.id#</cfoutput> },
					dataType: "json",
					success: function(response) {
						if (response && response.success) {
							try { refreshPeopleWindow(); } catch (error) {}
							$('#personDetailWindow').kendoWindow('destroy');
						} else {
							kendo.ui.ExtAlertDialog.show({ title: "The card stays", message: $("<div>").text((response && response.errorMessage) || "The card could not be deleted.").html(), icon: "k-ext-warning", width: "<cfoutput>#application.kendoExtendedUiWindowWidth#</cfoutput>" });
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
	<tr><td colspan="2" class="#blockClass#">A card for someone who doesn't sign in, eg. a guest presenter. It opens from their name on an event: picture, biography, links, and a form that emails them. Their address is never shown on the site.</td></tr>
	<tr class="blockSpacer"><td colspan="2" class="border #blockClass#"></td></tr>
	<tr>
		<td class="#blockClass#" align="right"><label for="personDisplayName">Name:</label></td>
		<td class="#blockClass#"><input type="text" id="personDisplayName" class="k-textbox" maxlength="125" value="#encodeForHtmlAttribute(person.name)#" style="width: 95%;"></td>
	</tr>
	<tr class="blockSpacer"><td colspan="2" class="border #blockClass#"></td></tr>
	<tr><td colspan="2" class="#blockClass#">Required. Messages from visitors are emailed here, with their address to reply to; make sure this person agrees.</td></tr>
	<tr class="blockSpacer"><td colspan="2" class="border #blockClass#"></td></tr>
	<tr>
		<td class="#blockClass#" align="right"><label for="personEmail">Email:</label></td>
		<td class="#blockClass#"><input type="email" id="personEmail" class="k-textbox" maxlength="255" value="#encodeForHtmlAttribute(structKeyExists(person, 'email') ? person.email : '')#" style="width: 95%;"></td>
	</tr>

	<tr class="blockSpacer"><td colspan="2" class="#blockClass#"></td></tr>
	<cfset blockClass = HtmlUtilsObj.getKendoClass(blockClass)>
	<tr class="blockSpacer"><td colspan="2" class="border #blockClass#"></td></tr>
	<tr><td colspan="2" class="#blockClass#"><h4 class="adminBlockHeading">About them</h4></td></tr>
	<tr class="blockSpacer"><td colspan="2" class="border #blockClass#"></td></tr>
	<tr><td colspan="2" class="#blockClass#">Upload a picture (JPG, PNG, GIF or WebP, up to 5 MB; a square one looks best), or paste the web address of one that's already online.</td></tr>
	<tr class="blockSpacer"><td colspan="2" class="border #blockClass#"></td></tr>
	<tr>
		<td class="#blockClass#" align="right"><label for="personPicture">Picture:</label></td>
		<td class="#blockClass#">
			<input type="text" id="personPicture" class="k-textbox" maxlength="500" placeholder="https://" value="#encodeForHtmlAttribute(person.picture)#" style="width: calc(95% - 160px);">
			<button type="button" class="k-button" id="personPictureUpload">Upload a picture</button>
			<input type="file" id="personPictureFile" accept="image/jpeg,image/png,image/gif<cfif application.imageEngineSupportsWebP>,image/webp</cfif>" style="display: none;">
			<div style="margin-top: 6px;"><img id="personPicturePreview" src="#encodeForHtmlAttribute(person.picture)#" alt="" width="85" height="85" style="border-radius: 50%; object-fit: cover;<cfif not len(person.picture)> display: none;</cfif>"> <span id="personPictureStatus" role="status"></span></div>
		</td>
	</tr>
	<tr class="blockSpacer"><td colspan="2" class="border #blockClass#"></td></tr>
	<tr>
		<td class="#blockClass#" align="right"><label for="personBiography">Biography:</label></td>
		<td class="#blockClass#"><textarea id="personBiography" class="k-textbox" rows="5" maxlength="4000" style="width: 95%;">#encodeForHtml(person.biography)#</textarea></td>
	</tr>

	<tr class="blockSpacer"><td colspan="2" class="#blockClass#"></td></tr>
	<cfset blockClass = HtmlUtilsObj.getKendoClass(blockClass)>
	<tr class="blockSpacer"><td colspan="2" class="border #blockClass#"></td></tr>
	<tr><td colspan="2" class="#blockClass#"><h4 class="adminBlockHeading">Links</h4></td></tr>
	<tr class="blockSpacer"><td colspan="2" class="border #blockClass#"></td></tr>
	<tr><td colspan="2" class="#blockClass#">Optional. Each link you fill in shows as its icon on the card.</td></tr>
	<!--- The same Font Awesome icons the card on the site shows for each link (includes/windows/personCard.cfm). --->
	<cfloop array="#[ { id: 'personWebsite', label: 'Website', icon: 'fa-solid fa-globe', value: person.website }, { id: 'personFacebook', label: 'Facebook', icon: 'fa-brands fa-facebook', value: person.facebookUrl }, { id: 'personLinkedIn', label: 'LinkedIn', icon: 'fa-brands fa-linkedin', value: person.linkedInUrl }, { id: 'personInstagram', label: 'Instagram', icon: 'fa-brands fa-instagram', value: person.instagramUrl }, { id: 'personTwitter', label: 'Twitter', icon: 'fa-brands fa-twitter', value: person.twitterUrl } ]#" index="thisField">
	<tr class="blockSpacer"><td colspan="2" class="border #blockClass#"></td></tr>
	<tr>
		<td class="#blockClass#" align="right"><label for="#thisField.id#"><i class="#thisField.icon#" aria-hidden="true"></i> #thisField.label#:</label></td>
		<td class="#blockClass#"><input type="text" id="#thisField.id#" class="k-textbox" maxlength="500" placeholder="https://" value="#encodeForHtmlAttribute(thisField.value)#" style="width: 95%;"></td>
	</tr>
	</cfloop>

	<tr class="blockSpacer"><td colspan="2" class="#blockClass#"></td></tr>
	<cfset blockClass = HtmlUtilsObj.getKendoClass(blockClass)>
	<tr class="blockSpacer"><td colspan="2" class="border #blockClass#"></td></tr>
	<tr><td colspan="2" class="#blockClass#">An inactive card isn't shown on the site and can't be chosen as an organizer.</td></tr>
	<tr class="blockSpacer"><td colspan="2" class="border #blockClass#"></td></tr>
	<tr>
		<td class="#blockClass#" align="right"><label for="personActive">Active:</label></td>
		<td class="#blockClass#"><input type="checkbox" class="k-checkbox" id="personActive"<cfif person.active> checked</cfif>></td>
	</tr>
	<tr class="blockSpacer"><td colspan="2" class="border #blockClass#"></td></tr>
	<tr>
		<td class="#blockClass#"></td>
		<td class="#blockClass#"><button id="personSubmit" type="button" class="k-button k-primary">Save</button><cfif not isNewPerson> <button id="personDelete" type="button" class="k-button">Delete</button></cfif></td>
	</tr>
</table>
</cfoutput>
