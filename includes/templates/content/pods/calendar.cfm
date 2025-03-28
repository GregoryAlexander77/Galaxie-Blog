<cfsilent>
<cfprocessingdirective pageencoding="utf-8">
<!---
	Name         : calendar
	Author       : Raymond Camden (backend functions) / Gregory Alexander (new Kendo front end)
	Created      : November 2 2018
	Last Updated : 
	History      : Complete rewrite of BlogCfc's calendar.
				 : The UI has been completely revised by Gregory.
	Purpose		 : Handles blog calendar
--->

<!---
Notes: Raymond's getActiveDays(year, month) supplies all of the posts made for a given month and year. We will make use of this function to highlight the blog posts on the new Kendo calendar. However, the calendar allows you to disable dates, but not to set all dates as disabled and then to enable dates. The 2nd option is necessary as I don't want to carry hundreds, if not potentially thousands, of dates that did not have a blog post made. I prefer disabling the dates, but in this case, I need to highlight certain dates in order to carry a much smaller load of dates. I will use the 'select multiple' method.
Small example code to select the dates that a blog post was acutally made:
<div id="calendar"></div>
<script>
    $("#calendar").kendoCalendar({
		selectable: "multiple",
       	selectDates: [new Date(2018, 10, 10), new Date(2018, 10, 13)]
    });
</script>

I created a new function, getAllActiveDates() in the blog.cfc template to return a query object of all post dates. We will use this new function to extract all active dates and make them into a javascript date array that we will pass to the new Kendo calendar control.

And what do you know... after programming the code, there seems to be a Kendo bug. The selected dates do not appear correct for the given month. It appears that the months are one off, I need to do some research.
So, after researching, I forgot that the javascript Date object has a monthIndex. The monthIndex is an integer value representing the month, beginning with 0 for January to 11 for December, so I need to subtract one from the ColdFusion date formatting for every month. These types of issues can be perplexing, but you need to be diligent in chasing down the problem before giving up. No one said that working in our field is easy. 
 
 Note: we can control the width of the calendar like so:
 
.k-widget.k-calendar {
	width: 100%; // of the container
	height: 100%; // of the container
}

.k-widget.k-calendar .k-content tbody td {
	width: 	350px;
}
 --->
	
<!--- 
********* Content template common logic *********
Note: the following logic should not be cached as each theme may return a different content template and it would overwhelm the cache memory. Instead, I am caching the content output which is the same for most themes. Other than setting the thisTemplate var, this logic is identical for most of the content output templates --->
<cfset thisTemplate = "blogPostCalendarPod">
<!--- The following logic does not need to be modified and will work with most of the content output templates --->
<!--- Reset our display content output var --->
<cfset displayContentOutputData = false>
<!--- This template drives the navigation menu and is a unordered HTML list. This template uses the getPageContent function to determine the content. It will display custom content that is in the database or use the default code below if no custom code exists  --->
<cfinvoke component="#application.blog#" method="getContentOutputData" returnvariable="contentOutputData">
	<cfinvokeargument name="contentTemplate" value="#thisTemplate#">
	<cfinvokeargument name="isMobile" value="#session.isMobile#">
	<cfif isDefined("URL.optArgs") and len(URL.optArgs)>
		<cfinvokeargument name="themeRef" value="#URL.optArgs#">
	</cfif>
</cfinvoke>		
<!--- Determine if we should display the data or use the default HTML --->
<cfif len(contentOutputData)>
	<cfset displayContentOutputData = true>		
</cfif>
<!--- ********* End content template logic *********--->
	
<!---Note: we need to supply the sideBar type argument before including this page. --->
<cfif sideBarType eq 'div'>
	<cfset calendarDivName = "blogCalendar">
<cfelseif sideBarType eq 'panel'>
	<cfset calendarDivName = "blogCalendarPanel">
</cfif>
	
<cfset offset = application.BlogDbObj.getBlogServerTimeZoneOffset()>
<cfset now = dateAdd("h", offset, now())>
<cfparam name="month" default="#month(now)#">
<cfparam name="year" default="#year(now)#">

<cfset activeDates = application.blog.getAllActiveDates()>
<!--- Preset params--->
<cfparam name="jsDateString" default="">
	
<!--- Cache notes: We're saving this to the application scope. We need to save the sideBarPanelType. The timeout is set to 1 hour --->
<cfif sideBarType eq 'div'>
	<cfset cacheName = "calendarDiv">
<cfelseif sideBarType eq 'panel'>
	<cfset cacheName = "calendarPanel">
</cfif>
	
</cfsilent>
		
<cfmodule template="../../../../tags/scopecache.cfm" scope="application" cachename="#cacheName#" timeout="#(60*60)#" disabled="#application.disableCache#">
<cfif displayContentOutputData>
	<!--- Include the custom user defined content from the database --->
	<cfoutput>#contentOutputData#</cfoutput>
<cfelse>	
	<!--- Loop thru the query and build a javascript string that represents an array of dates--->
	<!--- Set a loop counter to mimic ColdFusion's currentRow --->
	<cfparam name="activeDatesLoopCount" default="1">
	<!--- Loop through the array --->
	<cfloop from="1" to="#arrayLen(activeDates)#" index="i">
		<cfsilent>
		<!--- Set the values. --->
		<cfset calendarDatePosted = activeDates[i]["DatePosted"]>
		</cfsilent><cfoutput>
		<!--- Date formatting is a bit different between ACF and Lucee --->
		<cfif application.serverProduct eq 'Lucee'>
			<cfset jsDate = DateAdd('m', -1, calendarDatePosted)>
		<cfelse>
			<!--- Subtract a month from the posted date in order to format a javascript date properly with a month index (0-12) --->
			<cfset jsDate = dateFormat(DateAdd('m', -1, calendarDatePosted),"yyyy, mm, dd")>
		</cfif>
		<cfif activeDatesLoopCount eq 1>
			<cfset jsDateString = '[new Date(#dateFormat(jsDate,"yyyy, mm, dd")#)'>
		<cfelseif activeDatesLoopCount gt 1>
			<cfset jsDateString = jsDateString & ',  new Date(#dateFormat(jsDate,"yyyy, mm, dd")#)'>
		</cfif>	
		</cfoutput>
		<cfset activeDatesLoopCount = activeDatesLoopCount + 1>
	</cfloop>
	<!--- If there are any blog records, append the closing array bracket and a closing semicolon at the end of the query. When the blog is first installed, the jsDateString will be empty) --->
	<cfif len(jsDateString) gt 0>
		<cfset jsDateString = jsDateString & ']'>
	</cfif>

	<!--- 
	Testing carriage:
	This should look like: selectDates: [new Date(2018, 10, 10), new Date(2018, 10, 13)]<br/>
	<cfoutput> 
	#jsDateString#<br/>
	#dateFormat(now(),"yyyy, mm, dd")# <br/>
	</cfoutput>
	--->

	<!--- Kendo calendar container. Note: to align the container, we must use 'text-align: center'. I understand that this is counter-intuitive. --->
	<div id="<cfoutput>#calendarDivName#</cfoutput>"></div>

	<script type="<cfoutput>#scriptTypeString#</cfoutput>">
		$(document).ready(function() {
			// Create a var of dates that will be highlighted on the Kendo calendar control
			<cfoutput>#jsDateString#</cfoutput>
			// create Calendar from div HTML element
			$("#<cfoutput>#calendarDivName#</cfoutput>").kendoCalendar({
				selectable: "multiple",<cfif len(jsDateString) gt 0>
				selectDates: <cfoutput>#jsDateString#</cfoutput></cfif>
			});
			// Set a reference to the calendar...
			var blogCalendar = $("#<cfoutput>#calendarDivName#</cfoutput>").data("kendoCalendar");
			// Bind the form and capture the change event with a new function.
			blogCalendar.bind("change", function() {
				// Convert the value of the selected date into the format that BlogCfc expects to navigate to a new URL.
				var selectedCalendarDate = kendo.toString(this.value(), "yyyy/MM/dd/");
				// Redirect to the index.cfm page like so: window.location.href = "index.cfm/2011/11/3"
				window.location.href = "<cfoutput>#application.baseUrl#</cfoutput>/index.cfm/" + selectedCalendarDate; 
			});
		});
	</script>
</cfif>
</cfmodule>