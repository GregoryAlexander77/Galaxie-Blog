<!--- Export to Excel (5.0.x, 2026-10-31, owner): one button above an admin grid, for both the jsGrid and Kendo versions.
The grid sets exportUrl first: its ProxyController export method (exportErrorLog, exportVisitorLog, exportSubscribers,
exportComments) with the grid's own limits and the csrfToken. A download, so it is a plain link. ExcelExport.cfc writes the file. --->
<cfparam name="exportUrl" default="">
<cfif len(exportUrl)>
<p class="gridExport"><a class="k-button" href="<cfoutput>#exportUrl#</cfoutput>" download><i class="fas fa-file-excel"></i>&nbsp; Export to Excel</a></p>
</cfif>
