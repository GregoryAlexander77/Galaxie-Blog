<cfsetting enablecfoutputonly=true>
<cfprocessingdirective pageencoding="utf-8">
<!---
	Name         : calendar
	Author       : Raymond Camden + Paul Hastings 
	Created      : February 11, 2003
	Last Updated : August 2, 2006
	History      : Reset history for version 5.0
				 : Forgot to SES the links on first row. Thanks to Lucas for pointing it out. (rkc 7/4/06)
				 : Bad SES link in first row (rkc 8/2/06)
	Purpose		 : Handles blog calendar
--->


<cfset offset = application.blog.getProperty("offset")>
<cfset now = dateAdd("h", offset, now())>
<cfparam name="month" default="#month(now)#">
<cfparam name="year" default="#year(now)#">

<cfmodule template="../../tags/scopecache.cfm" cachename="pod_calendar_#month#_#year#" scope="application" timeout="#application.timeout#">

<cfmodule template="../../tags/podlayout.cfm" title="#application.resourceBundle.getResource("calendar")#">

<cfscript>					
	// no idea why this was so hard to conceive	
	function getFirstWeekPAD(firstDOW) {
		var firstWeekPad=0;
		var weekStartsOn=application.localeutils.weekStarts();
		switch (weekStartsON) {
			case 1:
				firstWeekPAD=firstDOW-1;
			break;
			case 2:
				firstWeekPAD=firstDOW-2;
				if (firstWeekPAD LT 0) firstWeekPAD=firstWeekPAD+7; // handle leap years
			break;
			case 7:
				firstWeekPAD=7-abs(firstDOW-7);
				if (firstWeekPAD EQ 7) firstWeekPAD=0;
			break;
		}
		return firstWeekPAD;
	}
	
	localizedDays=application.localeutils.getLocalizedDays();
	localizedMonth=application.localeutils.getLocalizedMonth(month);
	localizedYear=application.localeutils.getLocalizedYear(year);
	firstDay=createDate(year,month,1);
	firstDOW=dayOfWeek(firstDay);
	dim=daysInMonth(firstDay);
	firstWeekPAD=getFirstWeekPAD(firstDOW);
	lastMonth=dateAdd("m",-1,firstDay);
	nextMonth=dateAdd("m",1,firstDay);	
	dayList=application.blog.getActiveDays(year,month);
	dayCounter=1;
	rowCounter=1;
</cfscript>


<!--- swap navigation buttons if BIDI is true --->
<!---
<cfoutput>
	<div class="header">
	<cfif application.localeutils.isBIDI()>
		<a href="#application.blog.getProperty("blogurl")#/#year(nextmonth)#/#month(nextmonth)#" rel="nofollow">&lt;&lt;</a>
		<a href="#application.blog.getProperty("blogurl")#/#year#/#month#" rel="nofollow">#localizedMonth# #localizedYear#</a>
		<a href="#application.blog.getProperty("blogurl")#/#year(lastmonth)#/#month(lastmonth)#" rel="nofollow">&gt;&gt;</a>		
	<cfelse>
		<a href="#application.blog.getProperty("blogurl")#/#year(lastmonth)#/#month(lastmonth)#" rel="nofollow">&lt;&lt;</a>
		<a href="#application.blog.getProperty("blogurl")#/#year#/#month#" rel="nofollow">#localizedMonth# #localizedYear#</a>
		<a href="#application.blog.getProperty("blogurl")#/#year(nextmonth)#/#month(nextmonth)#" rel="nofollow">&gt;&gt;</a>
	</cfif>
	</div>
</cfoutput>
--->
<cfoutput>
<table border="0" id="calendar">
<thead>
<tr>
	<td colspan="7" align="center">
	<cfif application.localeutils.isBIDI()>
		<a href="#application.blog.getProperty("blogurl")#/#year(nextmonth)#/#month(nextmonth)#" rel="nofollow">&lt;&lt;</a>
		<a href="#application.blog.getProperty("blogurl")#/#year#/#month#" rel="nofollow">#localizedMonth# #localizedYear#</a>
		<a href="#application.blog.getProperty("blogurl")#/#year(lastmonth)#/#month(lastmonth)#" rel="nofollow">&gt;&gt;</a>		
	<cfelse>
		<a href="#application.blog.getProperty("blogurl")#/#year(lastmonth)#/#month(lastmonth)#" rel="nofollow">&lt;&lt;</a>
		<a href="#application.blog.getProperty("blogurl")#/#year#/#month#" rel="nofollow">#localizedMonth# #localizedYear#</a>
		<a href="#application.blog.getProperty("blogurl")#/#year(nextmonth)#/#month(nextmonth)#" rel="nofollow">&gt;&gt;</a>
	</cfif>
	</td>
</tr>
<tr>
	<!--- emit localized days in proper week start order --->
	<cfloop index="i" from="1" to="#arrayLen(localizedDays)#">
	<th>#localizedDays[i]#</th>
	</cfloop>
</tr>
</thead>
<tbody>
</cfoutput>
<!--- loop until 1st --->
<cfoutput><tr></cfoutput>
<cfloop index="x" from=1 to="#firstWeekPAD#">
	<cfoutput><td>&nbsp;</td></cfoutput>
</cfloop>

<!--- note changed loop to start w/firstWeekPAD+1 and evaluated vs dayCounter instead of X --->
<cfloop index="x" from="#firstWeekPAD+1#" to="7">
	<cfoutput><td <cfif month(now) eq month and dayCounter eq day(now) and year(now) eq year> class="calendarToday"</cfif>><cfif listFind(dayList,dayCounter)><a href="#application.blog.getProperty("blogurl")#/#year#/#month#/#dayCounter#" rel="nofollow">#dayCounter#</a><cfelse>#dayCounter#</cfif></td></cfoutput>
	<cfset dayCounter = dayCounter + 1>
</cfloop>
<cfoutput></tr></cfoutput>
<!--- now loop until month days --->
<cfloop index="x" from="#dayCounter#" to="#dim#">
	<cfif rowCounter is 1>
		<cfoutput><tr></cfoutput>
	</cfif>
	<cfoutput>
		<td <cfif month(now) eq month and x eq day(now) and year(now) eq year> class="calendarToday"</cfif>>
		<!--- the second clause here fixes an Oracle glitch where 9 comes back as 09. Should be harmless for other DBs that aren't as 'enterprise-y' as Oracle --->
		<cfif listFind(dayList,x) or listFind(dayList, "0" & x)><a href="#application.blog.getProperty("blogurl")#/#year#/#month#/#x#" rel="nofollow">#x#</a><cfelse>#x#</cfif>
		</td>
	</cfoutput>
	<cfset rowCounter = rowCounter + 1>
	<cfif rowCounter is 8>
		<cfoutput></tr></cfoutput>
		<cfset rowCounter = 1>
	</cfif>
</cfloop>
<!--- now finish up last row --->
<cfif rowCounter GT 1> <!--- test if ran out of days --->
	<cfloop index="x" from="#rowCounter#" to=7>
		<cfoutput><td>&nbsp;</td></cfoutput>
	</cfloop>
	<cfoutput></tr></cfoutput>
</cfif>
<cfoutput>
</tbody>
</table>
</cfoutput>

</cfmodule>

</cfmodule>

<cfsetting enablecfoutputonly=false>