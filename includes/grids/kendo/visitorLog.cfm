<!doctype html>
<cfsilent>
<!--- Kendo Grid version of ../jsGrid/visitorLog.cfm -- read only visitor log, optionally filtered
	by anonymousUserId (URL.optArgs), ipAddressId (URL.otherArgs), and/or postId (URL.otherArgs1),
	same as createAdminInterfaceWindow(48, anonymousUserId, ipAddressId, postId). Pass 0 for any
	argument you don't want to filter on. --->
<cfset gridName = "visitorLogGrid">
<!--- A virtual grid (2026-10-23, owner): rows are fetched a page at a time as you scroll, sorted and filtered on the server
(ProxyController.cfc getVisitorLogForVirtualGrid, blog.cfc getVisitorLogPage). --->
<cfset getUrl = application.baseUrl & '/common/cfc/ProxyController.cfc?method=getVisitorLogForVirtualGrid'>
<cfparam name="pageTitle" default="" type="string">

<cfif structKeyExists(URL, "optArgs") and isNumeric(URL.optArgs) and URL.optArgs gt 0>
	<cfset getUrl = getUrl & '&anonymousUserId=' & URL.optArgs>
	<cfset pageTitle = "Visitor Statistics by User " & URL.optArgs>
</cfif>
<cfif structKeyExists(URL, "otherArgs") and isNumeric(URL.otherArgs) and URL.otherArgs gt 0>
	<cfset getUrl = getUrl & '&ipAddressId=' & URL.otherArgs>
	<cfset pageTitle = "Visitor Statistics By IP">
</cfif>
<cfif structKeyExists(URL, "otherArgs1") and isNumeric(URL.otherArgs1) and URL.otherArgs1 gt 0>
	<cfset getUrl = getUrl & '&postId=' & URL.otherArgs1>
	<cfset pageTitle = "Visitor Statistics By Page">
</cfif>
<!--- From the admin home's Visitors card (2026-10-20): createAdminInterfaceWindow(48, 'people') shows people only (no bots) from the
last 7 days, as the card counts them. --->
<cfif structKeyExists(URL, "optArgs") and URL.optArgs eq "people">
	<cfset getUrl = getUrl & '&peopleOnly=1&sinceDays=7'>
	<cfset pageTitle = "Visitors this week (bots left out)">
</cfif>
<cfset getUrl = getUrl & '&csrfToken=' & csrfToken>
</cfsilent>
<html>
<head><cfoutput>
	<script type="text/javascript" src="#application.baseUrl#/common/libs/dayjs/dayjs.min.js"></script>
	</cfoutput>
	<cfif len(pageTitle)><h2><cfoutput>#pageTitle#</cfoutput></h2></cfif>
	<p>All columns are sortable and filterable. Scroll to load more: rows are fetched from the server as you go.</p>
</head>

<body>

<div id="<cfoutput>#gridName#</cfoutput>"></div>

<script type="text/x-kendo-template" id="anonymousUserIdTemplate">
	<a href="javascript:createAdminInterfaceWindow(63, #: AnonymousUserId #);">#: AnonymousUserId #</a>
</script>
<script type="text/x-kendo-template" id="ipAddressTemplate">
	<a href="javascript:createAdminInterfaceWindow(64,0,#: IpAddressId #,0);">#: IpAddress #</a>
</script>
<cfif not session.isMobile>
<script type="text/x-kendo-template" id="postTitleTemplate">
	# if (data.VisitingHomePage) { # Home # } else if (data.PostTitle) { # <a href="javascript:createAdminInterfaceWindow(48,0,0,#: PostId #);">#: PostTitle #</a> # } #
</script>
</cfif>

<script>
	<!--- Signed-in members (2026-10-17, owner): their round picture (or initials) and name instead of only a browser; it opens
	their page in Members. Admins keep their name. MemberName, MemberEmail and MemberPicture come from getVisitorLogForGrid. --->
	<!--- Where a visitor came from (2026-10-25, owner): the referring site's name (google.com), the full address when pointed at,
	empty for a direct visit. Text only: the address comes from outside the blog. --->
	function visitorReferrer(item) {
		var full = String(item.HttpReferrer || "");
		if (!full) { return ""; }
		var host = full.replace(/^[a-z]+:\/\//i, "").replace(/^www\./i, "").split(/[\/?#:]/)[0];
		var esc = function (v) { return $("<div/>").text(v).html(); };
		return '<span title="' + esc(full) + '">' + esc(host || full) + '</span>';
	}
	function visitorSignedInAs(item) {
		var text = function(value) { return $("<div/>").text(value === null || value === undefined ? "" : String(value)).html(); };
		if (item.MemberName) {
			var words = String(item.MemberName).split(/\s+/).filter(function(word) { return word.length; });
			var initials = words.length > 1 ? words[0].charAt(0) + words[words.length - 1].charAt(0) : String(item.MemberName).charAt(0);
			var circle = item.MemberPicture
				? '<img src="' + text(item.MemberPicture) + '" alt="" style="width: 24px; height: 24px; border-radius: 50%; object-fit: cover; vertical-align: middle;">'
				: '<span class="k-state-selected" style="display: inline-flex; align-items: center; justify-content: center; width: 24px; height: 24px; border-radius: 50%; font-size: 10px; font-weight: bold; vertical-align: middle;">' + text(initials.toUpperCase()) + '</span>';
			return '<a href="javascript:void(0);" class="visitorMemberLink" data-email="' + text(item.MemberEmail) + '">' + circle + ' ' + text(item.MemberName) + '</a>';
		}
		return text(item.FullName);
	}
	$(document).off("click.visitorMember").on("click.visitorMember", ".visitorMemberLink", function(event) {
		event.preventDefault();
		createAdminInterfaceWindow(98, encodeURIComponent($(this).attr("data-email")));
	});

	$(document).ready(function() {

		visitorLogDs = new kendo.data.DataSource({
			// Server paging, sorting and filtering: the grid posts { take, skip, sort, filter } as JSON.
			serverPaging: true,
			serverSorting: true,
			serverFiltering: true,
			pageSize: 100,
			transport: {
				read: {
					url: "<cfoutput>#getUrl#</cfoutput>",
					dataType: "json",
					// ColdFusion needs this content type for a JSON request body.
					contentType: "application/json; charset=utf-8",
					type: "POST"
				},
				parameterMap: function (options) {
					// Dates go as the visitor's own time (yyyy-MM-dd HH:mm:ss), not UTC, so "is equal to" a day means that day.
					(function localDates(filter) {
						if (!filter || !filter.filters) { return; }
						$.each(filter.filters, function (i, f) {
							if (f.filters) { localDates(f); } else if (f.value instanceof Date) { f.value = kendo.toString(f.value, "yyyy-MM-dd HH:mm:ss"); }
						});
					})(options.filter);
					return JSON.stringify(options);
				}
			},
			cache: false,
			schema: {
				data: "data",
				total: "total",
				model: {
					id: "uid",
					fields: {
						AnonymousUserId: { type: "number", editable: false, nullable: true },
						IpAddress: { type: "string", editable: false, nullable: true },
						IpAddressId: { type: "number", editable: false, nullable: true },
						FullName: { type: "string", editable: false, nullable: true },
						PostTitle: { type: "string", editable: false, nullable: true },
						PostId: { type: "number", editable: false, nullable: true },
						VisitingHomePage: { type: "boolean", editable: false, nullable: true },
						IsBot: { type: "boolean", editable: false, nullable: true },
						HttpReferrer: { type: "string", editable: false, nullable: true },
						Date: { type: "date", editable: false, nullable: false }
					}
				}
			}
		});

		$("#<cfoutput>#gridName#</cfoutput>").kendoGrid({
			dataSource: visitorLogDs,
			<cfif session.isMobile>mobile: true,</cfif>
			height: 725,
			navigatable: true,
			filterable: true,
			sortable: { mode: "multiple", allowUnsort: true, showIndexes: true },
			// Virtual scrolling: rows load as you scroll (no page numbers). Grouping is off - it would only group the rows loaded so far.
			scrollable: { virtual: true },
			pageable: { numeric: false, previousNext: false, refresh: true },
			groupable: false,
			selectable: "<cfif session.isMobile>cell<cfelse>multiple cell</cfif>",
			allowCopy: true,
			reorderable: true,
			resizable: true,
			columnMenu: true,
			columns: [{
				field: "AnonymousUserId",
				title: "UserId",
				filterable: true,
				width: "<cfif session.isMobile>15<cfelse>7</cfif>%",
				template: kendo.template($("#anonymousUserIdTemplate").html())
			}, {
				field: "IpAddress",
				title: "IP Address",
				filterable: true,
				width: "<cfif session.isMobile>25<cfelse>12</cfif>%",
				template: kendo.template($("#ipAddressTemplate").html())
			}, {
				field: "FullName",
				title: "Signed in as",
				filterable: true,
				width: "<cfif session.isMobile>30<cfelse>15</cfif>%",
				template: function(item) { return visitorSignedInAs(item); }
			<cfif not session.isMobile>}, {
				field: "PostTitle",
				title: "Post",
				filterable: true,
				width: "28%",
				template: kendo.template($("#postTitleTemplate").html())
			}, {
				field: "HttpReferrer",
				title: "Came from",
				filterable: true,
				width: "20%",
				template: function(item) { return visitorReferrer(item); }</cfif>
			}, {
				field: "IsBot",
				title: "Bot?",
				filterable: true,
				width: "<cfif session.isMobile>10<cfelse>5</cfif>%",
				template: "#= IsBot ? 'Yes' : 'No' #"
			}, {
				field: "Date",
				title: "Date",
				filterable: true,
				width: "<cfif session.isMobile>30<cfelse>13</cfif>%",
				<!--- A short date (2026-10-25), to make room for Came from. --->
				template: "#= dayjs(Date).format('MM/DD/YY h:mm A') #"
			}]
		});

	});//document ready
</script>

</body>
</html>
