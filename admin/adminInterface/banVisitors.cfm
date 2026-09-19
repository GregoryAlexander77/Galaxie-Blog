<!---
	Name         	: banVisitors.cfm
	Author       	: Gregory Alexander
	Created/Updated : See GalaxieBlog GitHub repository

	Lets a blog administrator ban anonymous visitors by IP address or by HTTP User-Agent string.
	Invoked via javascript:createAdminInterfaceWindow(66) - see includes/templates/blogJsContent.cfm for the
	window definition and includes/windows/adminInterface.cfm (cfcase value="66") for the dispatch.

	How this works: the single text input below is a Kendo AutoComplete ("autosuggest"). As the admin types,
	it suggests matching values drawn from every unique IP address (or, when the admin switches modes, every
	unique HTTP User-Agent string) this blog has ever logged, via ProxyController.getIpAddressesForMultiSelect /
	getHttpUserAgentsForMultiSelect. Suggestions already banned are flagged "Currently Banned" in the dropdown.
	Because it is a free-text field rather than a restricted picker, the admin can also type (and ban) a value
	that has never been logged before. Clicking Ban bans just that one value; clicking Unban removes the ban
	from whatever value is currently entered/selected (it must already be banned - otherwise Unban just says
	so and does nothing). See ProxyController.saveAnonymousUserBan and blog.cfc's setIpAddressBan /
	setHttpUserAgentBan / isVisitorBanned. The ban is enforced on every blog page view in
	includes/templates/core/visitorTracking.cfm.

	To review everything currently banned, use the View Banned Users button below (createAdminInterfaceWindow(67)),
	which also links each row through to that visitor's detail screen (createAdminInterfaceWindow(63)) where the
	Ban IP Address? / Ban User Agent? checkboxes offer the same unban action.

	Note: the Ban flag lives on the IpAddress and HttpUserAgent tables themselves (new columns - see
	common/cfc/db/galaxieDb/IpAddress.cfc and HttpUserAgent.cfc), not on the AnonymousUser table, so a ban takes
	effect for every past and future anonymous visitor sharing that IP or User-Agent - including a pairing that
	has never been seen before.
--->
<form id="banVisitorsForm" name="banVisitorsForm" data-role="validator">
<input type="hidden" name="csrfToken" id="csrfToken" value="<cfoutput>#csrfToken#</cfoutput>" />

<table align="center" class="k-content" width="100%" cellpadding="2" cellspacing="0">
  <cfsilent>
	<!---The first content class in the table should be empty. --->
	<cfset thisContentClass = HtmlUtilsObj.getKendoClass('')>
	<!--- Set the colspan property for borders --->
	<cfset thisColSpan = "2">
  </cfsilent>
  <tr height="1px">
	  <td align="left" valign="top" colspan="2" class="<cfoutput>#thisContentClass#</cfoutput>"></td>
  </tr>
  <tr height="1px">
	  <td align="left" valign="top" colspan="2" class="border <cfoutput>#thisContentClass#</cfoutput>"></td>
  </tr>
  <tr valign="middle" height="30px">
	<td valign="bottom" align="left" class="<cfoutput>#thisContentClass#</cfoutput>" colspan="<cfoutput>#thisColSpan#</cfoutput>">
		<p>Ban an anonymous visitor by IP address or by HTTP User-Agent string. A ban blocks every visitor using that IP or User-Agent, including visitors GalaxieBlog has not seen yet with that value. Start typing below to pick from previously seen values, or type a new one, then click Ban. To lift an existing ban, enter (or select) the banned value and click Unban.</p>
	</td>
  </tr>
  <!-- Border -->
  <tr height="2px">
	  <td align="left" valign="top" colspan="<cfoutput>#thisColSpan#</cfoutput>" class="<cfoutput>#thisContentClass#</cfoutput>"></td>
  </tr>
  <cfsilent>
  <!--- Set the class for alternating rows. --->
  <!---After the first row, the content class should be the current class. --->
  <cfset thisContentClass = HtmlUtilsObj.getKendoClass(thisContentClass)>
  </cfsilent>
  <tr height="2px">
	  <td align="left" valign="bottom" colspan="2" class="border <cfoutput>#thisContentClass#</cfoutput>"></td>
  </tr>
<cfif session.isMobile>
  <tr valign="middle">
	<td class="<cfoutput>#thisContentClass#</cfoutput>" colspan="2">
		<label>Ban By:</label>
	</td>
   </tr>
   <tr>
	<td class="<cfoutput>#thisContentClass#</cfoutput>" colspan="2">
		<input type="radio" name="banMode" id="banModeIp" value="ip" checked="checked"> <label for="banModeIp">IP Address</label>
		&nbsp;&nbsp;
		<input type="radio" name="banMode" id="banModeUserAgent" value="userAgent"> <label for="banModeUserAgent">User Agent</label>
	</td>
  </tr>
<cfelse><!---<cfif session.isMobile>--->
  <tr valign="middle" height="30px">
	<td valign="bottom" align="right" class="<cfoutput>#thisContentClass#</cfoutput>">
		<label>Ban By:</label>
	</td>
	<td valign="bottom" align="left" class="<cfoutput>#thisContentClass#</cfoutput>">
		<input type="radio" name="banMode" id="banModeIp" value="ip" checked="checked"> <label for="banModeIp">IP Address</label>
		&nbsp;&nbsp;
		<input type="radio" name="banMode" id="banModeUserAgent" value="userAgent"> <label for="banModeUserAgent">User Agent</label>
	</td>
  </tr>
</cfif>
  <!-- Border -->
  <tr height="2px">
	  <td align="left" valign="top" colspan="<cfoutput>#thisColSpan#</cfoutput>" class="<cfoutput>#thisContentClass#</cfoutput>"></td>
  </tr>
  <cfsilent>
  <!--- Set the class for alternating rows. --->
  <!---After the first row, the content class should be the current class. --->
  <cfset thisContentClass = HtmlUtilsObj.getKendoClass(thisContentClass)>
  </cfsilent>
  <tr height="2px">
	  <td align="left" valign="bottom" colspan="2" class="border <cfoutput>#thisContentClass#</cfoutput>"></td>
  </tr>
<cfif session.isMobile>
  <tr valign="middle">
	<td class="<cfoutput>#thisContentClass#</cfoutput>" colspan="2">
		<label for="banValueInput" id="banValueLabel">IP Address:</label>
	</td>
   </tr>
   <tr>
	<td class="<cfoutput>#thisContentClass#</cfoutput>" colspan="2">
		<input type="text" id="banValueInput" name="value" class="k-textbox" style="width: 100%" autocomplete="off">
	</td>
  </tr>
<cfelse><!---<cfif session.isMobile>--->
  <tr valign="middle" height="30px">
	<td valign="bottom" align="right" class="<cfoutput>#thisContentClass#</cfoutput>">
		<label for="banValueInput" id="banValueLabel">IP Address:</label>
	</td>
	<td valign="bottom" align="left" class="<cfoutput>#thisContentClass#</cfoutput>">
		<input type="text" id="banValueInput" name="value" class="k-textbox" style="width: 100%" autocomplete="off">
	</td>
  </tr>
</cfif>
  <!-- Border -->
  <tr height="2px">
	<td align="left" valign="top" colspan="<cfoutput>#thisColSpan#</cfoutput>" class="<cfoutput>#thisContentClass#</cfoutput>"></td>
  </tr>
  <cfsilent>
  <!--- Set the class for alternating rows. --->
  <!---After the first row, the content class should be the current class. --->
  <cfset thisContentClass = HtmlUtilsObj.getKendoClass(thisContentClass)>
  </cfsilent>
<cfif session.isMobile>
  <tr valign="middle">
	<td class="<cfoutput>#thisContentClass#</cfoutput>" colspan="2">
		<label for="note">Reason / Notes:</label>
	</td>
   </tr>
   <tr>
	<td class="<cfoutput>#thisContentClass#</cfoutput>" colspan="2">
		<input type="textbox" id="note" name="note" value="" class="k-textbox" style="width: 100%">
	</td>
  </tr>
<cfelse><!---<cfif session.isMobile>--->
  <tr valign="middle" height="30px">
	<td align="right" class="<cfoutput>#thisContentClass#</cfoutput>">
		<label for="note">Reason / Notes:</label>
	</td>
	<td align="left" class="<cfoutput>#thisContentClass#</cfoutput>">
		<input type="textbox" id="note" name="note" value="" class="k-textbox" style="width: 80%">
	</td>
  </tr>
</cfif>
  <!-- Border -->
  <tr height="2px">
	<td align="left" valign="top" colspan="<cfoutput>#thisColSpan#</cfoutput>" class="<cfoutput>#thisContentClass#</cfoutput>"></td>
  </tr>
  <cfsilent>
  <!--- Set the class for alternating rows. --->
  <!---After the first row, the content class should be the current class. --->
  <cfset thisContentClass = HtmlUtilsObj.getKendoClass(thisContentClass)>
  </cfsilent>
  <tr height="2px">
	  <td align="left" valign="top" colspan="2" class="border <cfoutput>#thisContentClass#</cfoutput>"></td>
  </tr>
  <tr height="2px">
	  <td align="left" valign="top" colspan="2" class="border <cfoutput>#thisContentClass#</cfoutput>"></td>
  </tr>
  <!-- Form content -->
  <tr valign="middle" height="30px">
	<td align="right" class="<cfoutput>#thisContentClass#</cfoutput>"></td>
	<td align="left" class="<cfoutput>#thisContentClass#</cfoutput>">
		<button id="banVisitorsSubmit" name="banVisitorsSubmit" class="k-button k-primary" type="button">Ban</button>
		<button id="banVisitorsUnbanSubmit" name="banVisitorsUnbanSubmit" class="k-button k-alt" type="button">Unban</button>
		<button id="viewBannedUsers" name="viewBannedUsers" class="k-button k-alt" type="button" onClick="javascript:createAdminInterfaceWindow(67);">View Banned Users</button>
	</td>
  </tr>
</table>
</form>

<script>
	$(document).ready(function() {

		<!--- Holds the mode ('ip' or 'userAgent') and the raw list of values already banned for that mode, so a single Ban click can be checked against it and the whole list can be refreshed after a successful ban. --->
		var banVisitorsState = {
			mode: 'ip',
			bannedValues: []
		};

		<!--- Initialize the Kendo AutoComplete ("autosuggest"). The dataSource is swapped out each time the mode (IP vs User Agent) changes or the list is (re)loaded. Unlike a MultiSelect or DropDownList, AutoComplete never restricts the input to items in its dataSource - the admin can always type (and ban) a value that has never been logged before. --->
		var banValueAutoComplete = $("#banValueInput").kendoAutoComplete({
			dataTextField: "text",
			filter: "contains",
			minLength: 1,
			<!--- The dropdown highlights entries already banned; the underlying "text" field (what actually fills the input on selection) is always just the plain value. --->
			template: '# if (data.banned) { #<span>#: data.text #</span> <span style="color:crimson;">— Currently Banned</span># } else { #<span>#: data.text #</span># } #',
			dataSource: []
		}).data("kendoAutoComplete");

		<!--- Adobe ColdFusion's serializeJSON() uppercases struct keys (a well known CF quirk) while Lucee preserves the original case of the HQL "as X" aliases. Since GalaxieBlog supports both engines (see application.serverProduct branches throughout ProxyController.cfc), look fields up case-insensitively rather than assuming one casing. --->
		function getFieldCI(obj, fieldName) {
			var lowerFieldName = fieldName.toLowerCase();
			for (var key in obj) {
				if (obj.hasOwnProperty(key) && key.toLowerCase() === lowerFieldName) {
					return obj[key];
				}
			}
			return undefined;
		}

		function isTruthy(value) {
			return value === true || value === 1 || value === '1' || value === 'true';
		}

		<!--- Loads the autosuggest with either the IP address list or the User-Agent list, depending on the mode ('ip' or 'userAgent'), and records which of them are already banned. --->
		function loadBanValueList(mode) {

			banVisitorsState.mode = mode;

			var proxyMethod = (mode === 'userAgent') ? 'getHttpUserAgentsForMultiSelect' : 'getIpAddressesForMultiSelect';

			jQuery.ajax({
				type: 'post',
				url: '<cfoutput>#application.baseUrl#</cfoutput>/common/cfc/ProxyController.cfc?method=' + proxyMethod + '&csrfToken=<cfoutput>#csrfToken#</cfoutput>',
				dataType: "json",
				success: function(response) {

					var items = [];
					var bannedValues = [];

					<!--- Response is an array of structs: {IpAddressId, IpAddress, Ban, Note} or {HttpUserAgentId, HttpUserAgent, Ban, Note}. --->
					$.each(response, function(index, item) {
						var rawValue = getFieldCI(item, (mode === 'userAgent') ? 'HttpUserAgent' : 'IpAddress');
						if (rawValue === null || rawValue === undefined || rawValue === '') {
							return; // skip blank entries
						}
						var banned = isTruthy(getFieldCI(item, 'Ban'));
						if (banned) {
							bannedValues.push(rawValue);
						}
						items.push({ text: rawValue, banned: banned });
					});

					banVisitorsState.bannedValues = bannedValues;

					banValueAutoComplete.setDataSource(items);
					banValueAutoComplete.value('');

					<!--- Update the label and placeholder so it is clear which list is currently loaded. --->
					var fieldLabel = mode === 'userAgent' ? 'User Agent' : 'IP Address';
					$("#banValueLabel").text(fieldLabel + ':');
					$("#banValueInput").attr('placeholder', 'Start typing a ' + fieldLabel + '...');
				},
				error: function(ErrorMsg) {
					console.log('Error' + ErrorMsg);
				}
			}).fail(function (jqXHR, textStatus, error) {
				<!--- This is a secured function. Display the login screen. --->
				if (jqXHR.status === 403) {
					createLoginWindow();
				} else {//...if (jqXHR.status === 403) {
					$.when(kendo.ui.ExtAlertDialog.show({ title: "Error while consuming the " + proxyMethod + " function", message: error, icon: "k-ext-error", width: "<cfoutput>#application.kendoExtendedUiWindowWidth#</cfoutput>" })
						).done(function () {
					<!--- Do nothing --->
					});
				}//...if (jqXHR.status === 403) {
			});
		}//..function loadBanValueList(mode)

		<!--- Load the initial (IP address) list. --->
		loadBanValueList('ip');

		<!--- Switch between banning by IP address and banning by User Agent. --->
		$('input[name="banMode"]').on('change', function() {
			loadBanValueList($('input[name="banMode"]:checked').val());
		});

		<!--- Invoked when the Ban button is clicked. --->
		var banVisitorsSubmit = $('#banVisitorsSubmit');
		banVisitorsSubmit.on('click', function(e){
			e.preventDefault();

			var value = $.trim(banValueAutoComplete.value());

			if (value === '') {
				$.when(kendo.ui.ExtAlertDialog.show({ title: "Nothing to Ban", message: "Please enter (or select) an " + (banVisitorsState.mode === 'userAgent' ? 'HTTP User-Agent string' : 'IP address') + " to ban.", icon: "k-ext-information", width: "<cfoutput>#application.kendoExtendedUiWindowWidth#</cfoutput>" })
					).done(function () {
					<!--- Do nothing --->
				});
				return;
			}

			if ($.inArray(value, banVisitorsState.bannedValues) !== -1) {
				$.when(kendo.ui.ExtAlertDialog.show({ title: "Already Banned", message: "That value is already banned.", icon: "k-ext-information", width: "<cfoutput>#application.kendoExtendedUiWindowWidth#</cfoutput>" })
					).done(function () {
					<!--- Do nothing --->
				});
				return;
			}

			postBanChange(banVisitorsState.mode, [value], [], 'ban');
		});

		<!--- Invoked when the Unban button is clicked. Reuses whatever value is currently entered/selected in the same autosuggest field. --->
		var banVisitorsUnbanSubmit = $('#banVisitorsUnbanSubmit');
		banVisitorsUnbanSubmit.on('click', function(e){
			e.preventDefault();

			var value = $.trim(banValueAutoComplete.value());

			if (value === '') {
				$.when(kendo.ui.ExtAlertDialog.show({ title: "Nothing to Unban", message: "Please enter (or select) the " + (banVisitorsState.mode === 'userAgent' ? 'HTTP User-Agent string' : 'IP address') + " you want to unban.", icon: "k-ext-information", width: "<cfoutput>#application.kendoExtendedUiWindowWidth#</cfoutput>" })
					).done(function () {
					<!--- Do nothing --->
				});
				return;
			}

			if ($.inArray(value, banVisitorsState.bannedValues) === -1) {
				$.when(kendo.ui.ExtAlertDialog.show({ title: "Not Banned", message: "That value is not currently banned.", icon: "k-ext-information", width: "<cfoutput>#application.kendoExtendedUiWindowWidth#</cfoutput>" })
					).done(function () {
					<!--- Do nothing --->
				});
				return;
			}

			postBanChange(banVisitorsState.mode, [], [value], 'unban');
		});

		<!--- Posts a ban and/or unban change to the server. action is 'ban' or 'unban', purely for the success/error messaging below. --->
		function postBanChange(mode, banValues, unbanValues, action){
			jQuery.ajax({
				type: 'post',
				url: '<cfoutput>#application.baseUrl#</cfoutput>/common/cfc/ProxyController.cfc?method=saveAnonymousUserBan&csrfToken=<cfoutput>#csrfToken#</cfoutput>',
				data: {
					csrfToken: $('#csrfToken').val(),
					banType: mode,
					banValues: JSON.stringify(banValues),
					unbanValues: JSON.stringify(unbanValues),
					note: $('#note').val()
				},
				dataType: "json",
				success: function(response) {
					banVisitorsSaveResult(response, action);
				},
				error: function(ErrorMsg) {
					console.log('Error' + ErrorMsg);
				}
			}).fail(function (jqXHR, textStatus, error) {
				<!--- This is a secured function. Display the login screen. --->
				if (jqXHR.status === 403) {
					createLoginWindow();
				} else {//...if (jqXHR.status === 403) {
					$.when(kendo.ui.ExtAlertDialog.show({ title: "Error while consuming the saveAnonymousUserBan function", message: error, icon: "k-ext-error", width: "<cfoutput>#application.kendoExtendedUiWindowWidth#</cfoutput>" })
						).done(function () {
					<!--- Do nothing --->
					});
				}//...if (jqXHR.status === 403) {
			});
		};

		function banVisitorsSaveResult(response, action){
			var isUnban = (action === 'unban');
			if (response) {
				$.when(kendo.ui.ExtAlertDialog.show({ title: isUnban ? "Unbanned" : "Banned", message: isUnban ? "The value has been unbanned." : "The ban has been saved.", icon: "k-ext-information", width: "<cfoutput>#application.kendoExtendedUiWindowWidth#</cfoutput>" })
					).done(function () {
					<!--- Refresh the list so the "Currently Banned" flags and the bannedValues baseline reflect what was just saved, and clear the input/note for the next entry. --->
					loadBanValueList(banVisitorsState.mode);
					$('#note').val('');
				});
			} else {
				$.when(kendo.ui.ExtAlertDialog.show({ title: "Error", message: isUnban ? "There was a problem unbanning that value. Please try again." : "There was a problem saving the ban. Please try again.", icon: "k-ext-error", width: "<cfoutput>#application.kendoExtendedUiWindowWidth#</cfoutput>" })
					).done(function () {
					<!--- Do nothing --->
				});
			}
		}

	});//...document.ready
</script>
