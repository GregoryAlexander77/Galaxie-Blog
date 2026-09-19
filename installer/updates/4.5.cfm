<!--- description: Marks existing records as blog posts (not pages) and sets the visitor log options on blogs that never had them. --->
<!--- This used to be part of the update logic in ProxyController.cfc. Values are only set when they are empty, which they are when these columns were first added. It used to set them on every blog, which reset the user's own log retention settings. --->
<cfquery name="updatePost" dbtype="hql">
	UPDATE Post
	SET IsBlogPost = <cfqueryparam value="1" cfsqltype="bit">,
	IsPage = <cfqueryparam value="0" cfsqltype="bit">
	WHERE IsPage IS NULL
</cfquery>

<cfquery name="updateLogVisitors" dbtype="hql">
	UPDATE BlogOption
	SET LogVisitors = <cfqueryparam value="1" cfsqltype="bit">
	WHERE LogVisitors IS NULL
</cfquery>

<cfquery name="updateMonthsToRetainVisitorLog" dbtype="hql">
	UPDATE BlogOption
	SET MonthsToRetainVisitorLog = <cfqueryparam value="1" cfsqltype="integer">
	WHERE MonthsToRetainVisitorLog IS NULL
</cfquery>

<cfquery name="updateMonthsToRetainAdminLog" dbtype="hql">
	UPDATE BlogOption
	SET MonthsToRetainAdminLog = <cfqueryparam value="12" cfsqltype="integer">
	WHERE MonthsToRetainAdminLog IS NULL
</cfquery>

<cfquery name="updateSendDiagnostics" dbtype="hql">
	UPDATE BlogOption
	SET SendDiagnostics = <cfqueryparam value="1" cfsqltype="bit">
	WHERE SendDiagnostics IS NULL
</cfquery>
