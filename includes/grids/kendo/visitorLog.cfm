<!doctype html>
<cfsilent>
<!--- Kendo Grid version of ../jsGrid/visitorLog.cfm -- read only visitor log, optionally filtered
	by anonymousUserId (URL.optArgs), ipAddressId (URL.otherArgs), and/or postId (URL.otherArgs1),
	same as createAdminInterfaceWindow(48, anonymousUserId, ipAddressId, postId). Pass 0 for any
	argument you don't want to filter on. --->
<cfset gridName = "visitorLogGrid">
<cfset getUrl = application.baseUrl & '/common/cfc/ProxyController.cfc?method=getVisitorLogForGrid&gridType=kendo'>
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
<cfset getUrl = getUrl & '&csrfToken=' & csrfToken>
</cfsilent>
<html>
<head><cfoutput>
	<script type="text/javascript" src="#application.baseUrl#/common/libs/dayjs/dayjs.min.js"></script>
	</cfoutput>
	<cfif len(pageTitle)><h2><cfoutput>#pageTitle#</cfoutput></h2></cfif>
	<p>All columns are sortable and searchable/filterable. Note: to conserve server resources, this grid is limited to 5000 records.</p>
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
	# if (data.VisitingHomePage) { # Home # } else if (data.PostTitle !== null) { # <a href="javascript:createAdminInterfaceWindow(48,0,0,#: PostId #);">#: PostTitle #</a> # } #
</script>
</cfif>

<script>
	$(document).ready(function() {

		visitorLogDs = new kendo.data.DataSource({
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
						IpAddressId: { type: "number", editable: false, nullable: true },
						FullName: { type: "string", editable: false, nullable: true },
						PostTitle: { type: "string", editable: false, nullable: true },
						PostId: { type: "number", editable: false, nullable: true },
						VisitingHomePage: { type: "boolean", editable: false, nullable: true },
						IsBot: { type: "boolean", editable: false, nullable: true },
						Date: { type: "string", editable: false, nullable: false }
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
				width: "<cfif session.isMobile>15<cfelse>10</cfif>%",
				template: kendo.template($("#anonymousUserIdTemplate").html())
			}, {
				field: "IpAddress",
				title: "IP Address",
				filterable: true,
				width: "<cfif session.isMobile>25<cfelse>15</cfif>%",
				template: kendo.template($("#ipAddressTemplate").html())
			}, {
				field: "FullName",
				title: "Auth User",
				filterable: true,
				width: "<cfif session.isMobile>30<cfelse>20</cfif>%"
			<cfif not session.isMobile>}, {
				field: "PostTitle",
				title: "Post",
				filterable: true,
				width: "40%",
				template: kendo.template($("#postTitleTemplate").html())</cfif>
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
				width: "<cfif session.isMobile>30<cfelse>15</cfif>%",
				template: "#= dayjs(Date).format('MM/DD/YYYY h:mm A') #"
			}]
		});

	});//document ready
</script>

</body>
</html>
