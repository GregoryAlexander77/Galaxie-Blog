<!doctype html>
<cfsilent>
<!--- Kendo Grid version of ../jsGrid/bannedUsers.cfm -- read only. Shows every anonymous visitor
	whose IP address or HTTP User-Agent is currently banned via the Ban Visitors admin interface
	(createAdminInterfaceWindow(66)). Invoked via createAdminInterfaceWindow(67). Ports the same
	getFieldCI/isTruthy helpers used by the jsGrid version, since the same Adobe-vs-Lucee struct-key
	casing difference (serializeJSON() uppercases keys on Adobe CF, Lucee preserves the HQL alias
	casing) applies to Kendo template field access as well. --->
<cfset gridName = "bannedUsersGrid">
<cfparam name="pageTitle" default="Banned Users" type="string">
<cfset getUrl = application.baseUrl & '/common/cfc/ProxyController.cfc?method=getBannedUsersForGrid&gridType=kendo&csrfToken=' & csrfToken>
</cfsilent>
<html>
<head><cfoutput>
	<script type="text/javascript" src="#application.baseUrl#/common/libs/dayjs/dayjs.min.js"></script>
	</cfoutput>
	<cfif len(pageTitle)><h2><cfoutput>#pageTitle#</cfoutput></h2></cfif>
	<p>Anonymous visitors whose IP address or HTTP User-Agent string is currently banned (see the Ban Visitors admin interface). Banning an IP or User-Agent blocks every visitor using it, so this grid can list more than one row per banned entry if the same IP or User-Agent has been seen paired with different visitors. All columns are sortable and searchable/filterable.</p>
</head>

<body>

<div id="<cfoutput>#gridName#</cfoutput>"></div>

<script>
	<!--- Adobe ColdFusion's serializeJSON() uppercases struct keys while Lucee preserves the original case of the HQL "as X" aliases. Since GalaxieBlog supports both engines, look fields up case-insensitively rather than assuming one casing. --->
	function getFieldCI(item, fieldName) {
		var lowerFieldName = fieldName.toLowerCase();
		for (var key in item) {
			if (item.hasOwnProperty(key) && key.toLowerCase() === lowerFieldName) {
				return item[key];
			}
		}
		return undefined;
	}

	function isTruthy(value) {
		return value === true || value === 1 || value === '1' || value === 'true';
	}

	function bannedUsersIpAddressHtml(item) {
		var ipAddress = getFieldCI(item, 'IpAddress');
		var ipAddressId = getFieldCI(item, 'IpAddressId');
		if (ipAddress === null || ipAddress === undefined || ipAddress === '') {
			return '';
		}
		return '<a href="javascript:createAdminInterfaceWindow(64,0,' + ipAddressId + ',0);">' + kendo.htmlEncode(ipAddress) + '</a>';
	}

	function bannedUsersUserAgentHtml(item) {
		var value = getFieldCI(item, 'HttpUserAgent');
		if (value === null || value === undefined || value === '') {
			return '';
		}
		var displayText = value.length > 80 ? (value.substring(0, 80) + '...') : value;
		return $('<span>').attr('title', value).text(displayText).prop('outerHTML');
	}

	function bannedUsersBannedByText(item) {
		var ipBanned = isTruthy(getFieldCI(item, 'IpBanned'));
		var userAgentBanned = isTruthy(getFieldCI(item, 'UserAgentBanned'));
		if (ipBanned && userAgentBanned) {
			return 'IP &amp; User Agent';
		} else if (ipBanned) {
			return 'IP Address';
		} else if (userAgentBanned) {
			return 'User Agent';
		}
		return '';
	}

	function bannedUsersReasonText(item) {
		var ipBanned = isTruthy(getFieldCI(item, 'IpBanned'));
		var userAgentBanned = isTruthy(getFieldCI(item, 'UserAgentBanned'));
		var ipNote = getFieldCI(item, 'IpNote') || '';
		var userAgentNote = getFieldCI(item, 'UserAgentNote') || '';
		var reasons = [];
		if (ipBanned && ipNote) {
			reasons.push(ipNote);
		}
		if (userAgentBanned && userAgentNote) {
			reasons.push(userAgentNote);
		}
		return kendo.htmlEncode(reasons.join('; '));
	}

	function bannedUsersDateText(item) {
		var ipBanned = isTruthy(getFieldCI(item, 'IpBanned'));
		var bannedDate = ipBanned ? getFieldCI(item, 'IpBanDate') : getFieldCI(item, 'UserAgentBanDate');
		if (!bannedDate) {
			return '';
		}
		return dayjs(bannedDate).format('MM/DD/YYYY h:mm A');
	}

	$(document).ready(function() {

		bannedUsersDs = new kendo.data.DataSource({
			transport: {
				read: {
					url: "<cfoutput>#getUrl#</cfoutput>",
					dataType: "json",
					method: "post"
				}
			},
			cache: false,
			pageSize: <cfif session.isMobile>7<cfelse>15</cfif>,
			schema: {
				model: {
					id: "uid",
					fields: {
						AnonymousUserId: { type: "number", editable: false, nullable: true },
						IpAddress: { type: "string", editable: false, nullable: true },
						HttpUserAgent: { type: "string", editable: false, nullable: true },
						FullName: { type: "string", editable: false, nullable: true },
						BannedBy: { type: "string", editable: false, nullable: true },
						BanReason: { type: "string", editable: false, nullable: true },
						BannedDate: { type: "string", editable: false, nullable: true }
					}
				}
			}
		});

		$("#<cfoutput>#gridName#</cfoutput>").kendoGrid({
			dataSource: bannedUsersDs,
			<cfif session.isMobile>mobile: true,</cfif>
			height: 725,
			navigatable: true,
			filterable: true,
			sortable: { mode: "multiple", allowUnsort: true, showIndexes: true },
			pageable: { pageSizes: [10,20,50,100,"All"], refresh: true },
			groupable: true,
			selectable: "<cfif session.isMobile>cell<cfelse>multiple cell</cfif>",
			allowCopy: true,
			reorderable: true,
			resizable: true,
			columnMenu: true,
			columns: [{
				field: "AnonymousUserId",
				title: "UserId",
				filterable: true,
				width: "<cfif session.isMobile>15<cfelse>8</cfif>%",
				template: function(item) {
					var value = getFieldCI(item, 'AnonymousUserId');
					return '<a href="javascript:createAdminInterfaceWindow(63, ' + value + ');">' + value + '</a>';
				}
			}, {
				field: "IpAddress",
				title: "IP Address",
				filterable: true,
				width: "<cfif session.isMobile>25<cfelse>13</cfif>%",
				template: function(item) { return bannedUsersIpAddressHtml(item); }
			<cfif not session.isMobile>}, {
				field: "HttpUserAgent",
				title: "User Agent",
				filterable: true,
				width: "30%",
				template: function(item) { return bannedUsersUserAgentHtml(item); }</cfif>
			}, {
				field: "FullName",
				title: "Auth User",
				filterable: true,
				width: "<cfif session.isMobile>20<cfelse>10</cfif>%"
			}, {
				field: "BannedBy",
				title: "Banned By",
				filterable: true,
				width: "<cfif session.isMobile>20<cfelse>10</cfif>%",
				template: function(item) { return bannedUsersBannedByText(item); }
			}, {
				field: "BanReason",
				title: "Reason",
				filterable: true,
				width: "<cfif session.isMobile>25<cfelse>15</cfif>%",
				template: function(item) { return bannedUsersReasonText(item); }
			}, {
				field: "BannedDate",
				title: "Banned Date",
				filterable: true,
				width: "<cfif session.isMobile>30<cfelse>14</cfif>%",
				template: function(item) { return bannedUsersDateText(item); }
			}]
		});

	});//document ready
</script>

</body>
</html>
