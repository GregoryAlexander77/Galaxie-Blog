<!doctype html>
<cfsilent>
<!--- Kendo Grid for Member sign-ins (window 105, 2026-10-17); the jsGrid version is ../jsGrid/memberSignIns.cfm. Read-only.
	Expects signInsMemberId (0 = everyone) from admin/adminInterface/memberSignIns.cfm. --->
<cfset gridName = "memberSignInsGrid">
</cfsilent>
<html>
<head></head>
<body>

<div id="<cfoutput>#gridName#</cfoutput>"></div>

<script>
	<!--- The member: their round picture (or initials) and name, opening their page in Members (window 98). --->
	function memberSignInWho(item) {
		var text = function(value) { return $("<div/>").text(value === null || value === undefined ? "" : String(value)).html(); };
		var words = String(item.MemberName || "").split(/\s+/).filter(function(word) { return word.length; });
		var initials = words.length > 1 ? words[0].charAt(0) + words[words.length - 1].charAt(0) : String(item.MemberName || "").charAt(0);
		var circle = item.MemberPicture
			? '<img src="' + text(item.MemberPicture) + '" alt="" style="width: 24px; height: 24px; border-radius: 50%; object-fit: cover; vertical-align: middle;">'
			: '<span class="k-state-selected" style="display: inline-flex; align-items: center; justify-content: center; width: 24px; height: 24px; border-radius: 50%; font-size: 10px; font-weight: bold; vertical-align: middle;">' + text(initials.toUpperCase()) + '</span>';
		return '<a href="javascript:void(0);" class="memberSignInLink" data-email="' + text(item.MemberEmail) + '">' + circle + ' ' + text(item.MemberName) + '</a>';
	}
	$(document).off("click.memberSignIn").on("click.memberSignIn", ".memberSignInLink", function(event) {
		event.preventDefault();
		createAdminInterfaceWindow(98, encodeURIComponent($(this).attr("data-email")));
	});

	$(document).ready(function() {

		memberSignInsDs = new kendo.data.DataSource({
			transport: {
				read: {
					url: "<cfoutput>#application.baseUrl#</cfoutput>/common/cfc/ProxyController.cfc?method=getMemberSignInsForGrid&gridType=kendo&memberId=<cfoutput>#signInsMemberId#</cfoutput>&csrfToken=<cfoutput>#csrfToken#</cfoutput>",
					dataType: "json",
					method: "post"
				},
				parameterMap: function(options, operation) {
					return {};
				}
			},
			cache: false,
			batch: false,
			pageSize: <cfif session.isMobile>7<cfelse>15</cfif>,
			schema: {
				model: {
					fields: {
						MemberId: { type: "number", editable: false },
						MemberName: { type: "string", editable: false },
						MemberEmail: { type: "string", editable: false },
						MemberPicture: { type: "string", editable: false },
						IpAddress: { type: "string", editable: false },
						HttpUserAgent: { type: "string", editable: false },
						Method: { type: "string", editable: false },
						SignedIn: { type: "string", editable: false }
					}
				}
			},
			sort: { field: "SignedIn", dir: "desc" }
		});

		$("#<cfoutput>#gridName#</cfoutput>").kendoGrid({
			dataSource: memberSignInsDs,
			editable: false,
			<cfif session.isMobile>mobile: true,</cfif>
			height: 500,
			navigatable: true,
			filterable: true,
			sortable: true,
			pageable: { pageSizes: [10,20,50,"All"], refresh: true },
			resizable: true,
			columns: [{
				field: "MemberName",
				title: "Member",
				width: "<cfif session.isMobile>45<cfelse>24</cfif>%",
				template: function(item) { return memberSignInWho(item); }
			}, {
				field: "IpAddress",
				title: "IP address",
				width: "<cfif session.isMobile>30<cfelse>14</cfif>%"
			<cfif not session.isMobile>}, {
				field: "HttpUserAgent",
				title: "Browser"
			}, {
				field: "Method",
				title: "How",
				width: "11%"</cfif>
			}, {
				field: "SignedIn",
				title: "Signed in",
				width: "<cfif session.isMobile>25<cfelse>15</cfif>%"
			}]
		});

	});//document ready
</script>

</body>
</html>
