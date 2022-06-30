<cfcomponent displayname="timezone" hint="various timezone functions not included in mx: version 2.1 jul-2005 Paul Hastings (paul@sustainbleGIS.com)" output="No">
	<!---
	author:	paul hastings <paul@sustainableGIS.com>
	date:	11-sep-2003
	revisions:
			6/23 Gregory modified around line 455 with a note as this was causing errors with cf2021
			5/26/2022 Gregory Alexander Fixed a bug and minor formatting changes
			23-oct-2003 changed to use argument dates rather than setting calendar time, forgot that
			java MONTH start with zero. kept gregorian calendar object for timezone offset in order to
			use DST_OFFSET field in calendar object.
			8-nov-2003 added castToUTC, castFromUTC to support Ray Camden's blog i18n, added castToServer
			and castFromServer at user request.
			14-feb-2005 reworked castToUTC, castFromUTC to not use gregorian calendar class,
			added init().
			16-feb-2005 fixed java/cf date bug in cast to/from functions
			6-aug-2005 fixed bug in to/from UTC methods, was using decimals hours for tz
			offsetsbut cf's dateAdd function only takes integers. thanks to Behrang Noroozinia
			<behrang@khorshidchehr.com> for finding that bug.
			30-mar-2006 added two methods (getServerTZShort,getServerId) contributed by dan
			switzer: dswitzer@pengoworks.com

			29-aug-2010 added new method (convertTZ) to return time converted from one timezone
			to another. contributed by John Thwaites: johnthwaites@logicdepot.com
			to be used by other conversion methods contributed by John Thwaites: johnthwaites@logicdepot.com
			29-aug-2010 added new method (getTZOffsetBase) to return the offset in milliseconds 
			to be used by other conversion methods contributed by John Thwaites: johnthwaites@logicdepot.com
			29-aug-2010 fixed (getTZOffset,castToUTC,castFromUTC) to use milliseconds offset to calculate 
			the correct time rather than always midnight of the day which allows for DST at the 
			correct cut over time. contributed by John Thwaites: johnthwaites@logicdepot.com
			29-aug-2010 added new method (getTimeZone) to return a structure with all details of 
			a timezone. contributed by John Thwaites: johnthwaites@logicdepot.com
			29-aug-2010 add variable "defaultTimeZoneId" to store DefaultTimezone which can be different
			from the server time zone.
			29-aug-2010 added new method (loadStandardTimeZones) which creates an internal structure 
			"standardTimeZones" that contains a set of "standard" time zones which can be used to build 
			a selection list for a time zone picker. John Thwaites: johnthwaites@logicdepot.com
			29-aug-2010 added new methods (getDefaultTimeZoneId, getStandardTimeZoneList, getStandardTimeZoneDesc,
			setDefaultTimeZone, getTimeZoneShortName, getCurrentTime John Thwaites: johnthwaites@logicdepot.com
			
			
	notes:		this cfc contains methods to handle some timezone functionality not in cfmx as well as when
			you need to "cast" to a specific timezone (cf's timezone functions are tied to server). it
			requires the use of createObject.

	methods in this CFC:
			- isDST determines if a given date & timezone are in DST. if no date or timezone is passed
			the method defaults to current date/time and server timezone. PUBLIC.
			- getAvailableTZ returns an array of available timezones on this server (ie according to
			server's JVM). PUBLIC.
			- isValidTZ determines if a given timezone is valid according to getAvailableTZ. PUBLIC.
			- usesDST determines if a given timezone uses DST. PUBLIC.
			- getRawOffset returns the raw (as opposed to DST) offset in hours for a given timezone.
			PUBLIC.
			- getTZOffset returns offset in hours for a given date/time & timezone, uses DST if timezone
			uses and is currently in DST. returns -999 if bad date or bad timezone. PUBLIC.
			- getDST returns DST savings for given timezone. returns -999 for bad timezone. PUBLIC.
			- castToUTC return UTC from given datetime in given timezone. required argument thisDate,
			optional argument thisTZ valid timezone ID, defaults to server timezone. PUBLIC.
			- castfromUTC return date in given timezone from UTC datetime. required argument thisDate,
			optional argument thisTZ valid timezone ID, defaults to server timezone. PUBLIC.
			- castToServer returns server datetime from given datetime in given timezone. required argument
			thisDate valid datetime, optional argument thisTZ valid timezone ID, defaults to server
			timezone. PUBLIC.
			- castfromServer return datetime in given timezone from server datetime. required argument
			thisDate valdi datetime, optional argument thisTZ valid timezone ID, defaults to server
			timezone. PUBLIC.
			- getServerTZ returns server timezone. PUBLIC
			- getServerTZShort returns "short" name for the server's timezone. PUBLIC
			- getServerId returns ID for the server's timezone. PUBLIC
			- convertTZ retuen time converted fom one timezone to another
			- getTZOffsetBase return the offset in milliseconds. PUBLIC.
			- getTimeZone return a structure with all details of a timezone. PUBLIC.
			- setDefaultTimeZone sets the default timezone, to override the server derrived zone.
			- getDefaultTimeZoneId returns the id of the default timezone. PUBLIC.
			- getTimeZoneShortName eturns the short name for a timezone. PUBLIC.
			- getCurrentTime returns the current time in the specified timezone, or default. PUBLIC.
			- getStandardTimeZoneList reurns a list of standard time zone id's fom internal structure. PUBLIC. 
			- getStandardTimeZoneDesc returns the description for a timezone from the internal structure. PUBLIC.
			- loadStandardTimeZones loads the internal structure of "standard" timezones. PRIVATE. 
			- addStandardTimeZone used by loadStandardTimeZones to add entries to internal structure. PRIVATE.
 	--->

	<!--- the time zone object itself --->
	<cfset variables.tzObj = createObject("java","java.util.TimeZone")>
	<!--- list of all available timezone ids --->
	<cfset variables.tzList = listsort(arrayToList(variables.tzObj.getAvailableIDs()), "textnocase")>
	<!--- default timezone on the server --->
	<cfset variables.mytz = variables.tzObj.getDefault().ID>
	<!--- load structure of standard time zones --->
	<cfset variables.standardTimeZones = loadStandardTimeZones()>
	<!--- set default time zone for instance of object, initialize to server TZ but can override --->
	<cfset variables.defaultTimeZoneId = variables.mytz>

	<!--- init --->
	<cffunction name="init" output="false" access="public" returntype="Any">
		<cfreturn this>
	</cffunction>

	<!--- isValidTZ --->
	<cffunction name="isValidTZ" output="false" returntype="boolean" access="public"
			hint="validates if a given timezone is in list of timezones available on this server">
		<cfargument name="tz" required="false" default="#variables.mytz#">
		<cfreturn IIF(listFindNoCase(variables.tzList,arguments.tz), true, false)>
	</cffunction>

	<!--- isDST --->
	<cffunction name="isDST" output="false" returntype="boolean" access="public"
			hint="determines if a given date in a given timezone is in DST">
		<cfargument name="dateToTest" required="false" type="date" default="#now()#">
		<cfargument name="tz" required="true" default="#variables.mytz#">
		<cfreturn variables.tzObj.getTimeZone(arguments.tz).inDaylightTime(arguments.dateTotest)>
	</cffunction>

	<!--- getAvailableTZ --->
	<cffunction name="getAvailableTZ" output="false" returntype="array" access="public"
			hint="returns a list of timezones available on this server">
		<cfreturn listToArray(variables.tzList)>
	</cffunction>

	<!--- getTZByOffset --->
	<cffunction name="getTZByOffset" output="false" returntype="array" access="public"
			hint="returns a list of timezones available on this server for a given raw offset">
		<cfargument name="thisOffset" required="true" type="numeric">
		<cfset var rawOffset = javacast("long", arguments.thisOffset * 3600000)>
		<cfreturn variables.tzObj.getAvailableIDs(rawOffset)>
	</cffunction>

	<!--- usesDST --->
	<cffunction name="usesDST" output="false" returntype="boolean" access="public"
			hint="determines if a given timezone uses DST">
		<cfargument name="tz" required="false" default="#variables.mytz#">
		<cfreturn variables.tzObj.getTimeZone(arguments.tz).useDaylightTime()>
	</cffunction>

	<!--- getRawOffset --->
	<cffunction name="getRawOffset" output="false" access="public" returntype="numeric"
			hint="returns rawoffset in hours">
		<cfargument name="tz" required="false" default="#variables.mytz#">
		<cfreturn variables.tzObj.getTimeZone(arguments.tz).getRawOffset() / 3600000>
	</cffunction>

	<!--- getTZOffset --->
	<!---
	Corrected by John Thwaites 08/29/2010 to return offest to nearest millisecond
	to correct the midnight problem
	--->
	<cffunction name="getTZOffset" output="false" access="public" returntype="numeric"
			hint="returns offset in hours">
		<cfargument name="thisDate" required="no" type="date" default="#now()#">
		<cfargument name="tz" required="false" default="#variables.mytz#">
	
		<cfreturn getTZOffsetBase(arguments.thisDate, arguments.tz)/3600000>
	</cffunction>

	<!--- returns base offset in milliseconds --->
	<!---
	Added by John Thwaites 08/29/2010 to correct midnight problem
	--->
	<cffunction name="getTZOffsetBase" output="No" access="private" returntype="numeric">  
		<cfargument name="thisDate" required="no" type="date" default="#now()#">
		<cfargument name="tz" required="no" default="#tzObj.getDefault().ID#">
		<cfscript>
		var timezone=tzObj.getTimeZone(arguments.tz);
		var tYear=javacast("int",Year(arguments.thisDate));
		var tMonth=javacast("int",month(arguments.thisDate)-1); //java months are 0 based
		var tDay=javacast("int",Day(thisDate));
		var tDOW=javacast("int",DayOfWeek(thisDate));	//day of week
		var tMS=javacast("int",((Hour(thisDate)*3600000)+Minute(thisDate)*60000+Second(thisDate)*1000));	//milliseconds in the day
		</cfscript>

		<cfreturn timezone.getOffset(1,tYear,tMonth,tDay,tDOW,tMS)>
	</cffunction>

	<!--- getDST --->
	<cffunction name="getDST" output="false" access="public" returntype="numeric"
			hint="returns DST savings in hours">
		<cfargument name="tz" required="false" default="#variables.mytz#">
		<cfreturn variables.tzObj.getTimeZone(arguments.tz).getDSTSavings() / 3600000>
	</cffunction>

	<!--- castToUTC --->
	<!---
	Corrected by John Thwaites 08/29/2010 to return offest to nearest millisecond
	to correct the midnight problem
	--->
	<cffunction name="castToUTC" output="false" access="public" returntype="date"
			hint="returns UTC from given date in given TZ, takes DST into account">
		<cfargument name="thisDate" required="yes" type="date">
		<cfargument name="tz" required="false" default="#variables.mytz#">

		<cfset var thisOffset=(getTZOffsetBase(arguments.thisDate, arguments.tz)/1000)*-1.00>
		<cfreturn dateAdd("s",thisOffset,arguments.thisDate)>
	</cffunction>

	<!--- castFromUTC --->
	<!---
	Corrected by John Thwaites 08/29/2010 to return offest to nearest millisecond
	to correct the midnight problem
	--->
	<cffunction name="castFromUTC" output="false" access="public" returntype="date"
			hint="returns date in given TZ from given UTC date, takes DST into account">
		<cfargument name="thisDate" required="yes" type="date">
		<cfargument name="tz" required="false" default="#variables.mytz#">

		<cfset var thisOffset=getTZOffsetBase(arguments.thisDate, arguments.tz)/1000>
		<cfreturn dateAdd("s",thisOffset,arguments.thisDate)>
	</cffunction>

	<!--- castToServer --->
	<cffunction name="castToServer" output="false" access="public" returntype="date"
			hint="returns server date in given TZ from given UTC date, takes DST into account">
		<cfargument name="thisDate" required="yes" type="date">
		<cfargument name="tz" required="false" default="#variables.mytz#">
		<cfreturn dateConvert("utc2Local",castToUTC(arguments.thisDate, arguments.tz))>
	</cffunction>

	<!--- castFromServer --->
	<cffunction name="castFromServer" output="false" access="public" returntype="date"
			hint="returns date in given TZ from given server date, takes DST into account">
		<cfargument name="thisDate" required="yes" type="date">
		<cfargument name="tz" required="false" default="#variables.mytz#">
		<cfreturn castFromUTC(dateConvert("local2UTC",arguments.thisDate),arguments.tz)>
	</cffunction>

	<!--- getServerTZ --->
	<cffunction name="getServerTZ" output="false" access="public" returntype="string"
			hint="returns server TZ (long)">
		<cfreturn variables.tzObj.getDefault().getDisplayName(true, variables.tzObj.LONG)>
	</cffunction>

	<!--- getServerTZShort --->
	<cffunction name="getServerTZShort" output="false" access="public" returntype="string"
			hint="returns server TZ (short). contributed by dan switzer: dswitzer@pengoworks.com">
		<cfreturn variables.tzObj.getDefault().getDisplayName(true, variables.tzObj.SHORT)>
	</cffunction>

	<!--- getServerId --->
	<cffunction name="getServerId" output="false" access="public" returntype="any"
			hint="returns the server timezone id. contributed by dan switzer: dswitzer@pengoworks.com">
		<cfreturn variables.mytz>
	</cffunction>
		
	<!--- convertTZ --->
	<cffunction name="convertTZ" output="No" access="public" returntype="numeric"
			hint="converts time from one TZ to another. Contributed by john thwaites: johnthwaites@logicdepot.com">
		<cfargument name="thisDate" required="no" type="date" default="#now()#">
		<cfargument name="fromTZ" required="no" default="#tzObj.getDefault().ID#">
		<cfargument name="toTZ" required="no" default="#tzObj.getDefault().ID#">
			
		<cfset var utcDate = dateAdd("s",(getTZOffsetBase(arguments.thisDate, arguments.fromTZ)/1000)*-1.00,arguments.thisDate)>
			
		<cfreturn dateAdd("s",getTZOffsetBase(utcDate, arguments.toTZ)/1000,utcDate)>
	</cffunction>

	<!--- getTimeZone --->
	<cffunction name="getTimeZone" output="false" access="public" returntype="any"
			hint="returns the timezone detail. contributed by john thwaites: johnthwaites@logicdepot.com">
		<cfargument name="tz" required="false" default="#variables.mytz#">
		<cfargument name="today" required="false" default="#now()#">

		<cfscript>
		var tmptz = variables.tzObj.getTimeZone(arguments.tz);
		var stThisTZ = structnew();
		
		stThisTZ.id = arguments.tz;
		
		// Get the display name
		
		stThisTZ.shortName = tmptz.getDisplayName(tmptz.inDaylightTime(arguments.today), variables.tzObj.SHORT);
		stThisTZ.longName = tmptz.getDisplayName(tmptz.inDaylightTime(arguments.today), variables.tzObj.LONG);
		stThisTZ.readableName = tmptz.getDisplayName();
				 
		
		// Get the number of hours from GMT
		stThisTZ.rawOffset = tmptz.getRawOffset();
		stThisTZ.offset = getTZOffset(arguments.today, arguments.tz);
		stThisTZ.offsetMinutes = abs(getTZOffset(arguments.today, arguments.tz)) /3600000 % 60;
				 
		// Does the time zone have a daylight savings time period?
		stThisTZ.hasDST = tmptz.useDaylightTime();
				 
		
		// Is the time zone currently in a daylight savings time?
		stThisTZ.inDST = tmptz.inDaylightTime(arguments.today);
		</cfscript>

		<cfreturn duplicate(stThisTZ)>
	</cffunction>

	<!--- getDefaultTimeZoneId --->
	<cffunction name="getDefaultTimeZoneId" access="public" returntype="String"
			hint="returns default timezoneid. contributed by john thwaites: johnthwaites@logicdepot.com">  
		<cfscript>
		return variables.defaultTimeZoneId;	
		</cfscript>
	</cffunction>

	<!--- getTimeZoneShortName --->
	<cffunction name="getTimeZoneShortName" access="public" returntype="String"
			hint="returns short name of TZ. contributed by john thwaites: johnthwaites@logicdepot.com">  
		<cfargument name="aDate" type="date" required="false" default="#now()#">
		<cfargument name="aTzId" type="string" required="false" default="#variables.StandardTimezones.DefaultId#">
		<cfscript>
		var tmptz = variables.tzObj.getTimeZone(aTzId);

		return tmptz.getDisplayName(tmptz.inDaylightTime(aDate), variables.tzObj.SHORT);
		</cfscript>
	</cffunction>

	<!--- getCurrentTime --->
	<cffunction name="getCurrentTime" access="public" returntype="String"
			hint="returns current time in specified TZ. contributed by john thwaites: johnthwaites@logicdepot.com">  
		<cfargument name="aTzId" type="string" required="false" default="#defaultTimeZoneId#">
		<cfscript>
		var tmptz = variables.tzObj.getTimeZone(aTzId);

		return convertTZ(now(), variables.defaultTimeZoneId, aTzId);
		</cfscript>
	</cffunction>

	<!--- setDefaultTimeZone --->
	<cffunction name="setDefaultTimeZone" access="public" returntype="String"
			hint="overrides the default TZ. contributed by john thwaites: johnthwaites@logicdepot.com">  
		<cfargument name="aTzId" type="string" required="true">
		<cfset variables.defaultTimeZoneId = aTzId>
	</cffunction>

	<!--- getStandardTimeZoneList --->
	<cffunction name="getStandardTimeZoneList" access="public" returntype="String"
			hint="returns a list of standard TZ id's. contributed by john thwaites: johnthwaites@logicdepot.com">  
		<cfscript>
		return variables.standardTimeZones.List;	
		</cfscript>
	</cffunction>

	<!--- getStandardTimeZoneDesc --->
	<cffunction name="getStandardTimeZoneDesc" access="public" returntype="String"
			hint="reurns description of a standard TZ. contributed by john thwaites: johnthwaites@logicdepot.com">  
		<cfargument name="aTzId" type="string" required="false" default="#variables.StandardTimezones.DefaultId#">
		<cfscript>
		if (structKeyExists(variables.standardTimeZones.Entry, aTzId))
			return variables.standardTimeZones.Entry[aTzId].Description;
		else	
			return "Unknown TimeZone";
		</cfscript>
	</cffunction>

	<!--- loadStandardTimeZones --->
	<cffunction name="loadStandardTimeZones" access="private" returntype="Struct">
		<cfscript>
		var vsTZ = structNew();
		vsTZ.Entry = structNew();
		vsTZ.List = "";
		vsTZ.BadList = "";
			
		addStandardTimeZone(vsTZ, "Etc/GMT+12", "GMT -12:00 Dateline");
		addStandardTimeZone(vsTZ, "Etc/GMT+11", "GMT -11:00");
		addStandardTimeZone(vsTZ, "Pacific/Honolulu", "GMT -10:00 Hawaii");
		addStandardTimeZone(vsTZ, "Etc/GMT+10", "GMT -10:00");
		addStandardTimeZone(vsTZ, "Pacific/Marquesas", "GMT -09:30 Marquesas");
		addStandardTimeZone(vsTZ, "America/Anchorage", "GMT -09:00 Alaska");
		addStandardTimeZone(vsTZ, "Etc/GMT+9", "GMT -09:00");
		addStandardTimeZone(vsTZ, "Pacific/Pitcairn", "GMT -08:30 Pitcarn");
		addStandardTimeZone(vsTZ, "Etc/GMT+8", "GMT -08:00");
		addStandardTimeZone(vsTZ, "America/Los_Angeles", "GMT -08:00 US/Canada Pacific");
		addStandardTimeZone(vsTZ, "Etc/GMT+7", "GMT -07:00");
		addStandardTimeZone(vsTZ, "America/Denver", "GMT -07:00 US/Canada Mountain");
		addStandardTimeZone(vsTZ, "America/Phoenix", "GMT -07:00 U.S. Mountain Time (Arizona)");
		addStandardTimeZone(vsTZ, "America/Mexico_City", "GMT -06:00 Mexico");
		addStandardTimeZone(vsTZ, "Etc/GMT+6", "GMT -06:00");
		addStandardTimeZone(vsTZ, "America/Chicago", "GMT -06:00 US/Canada Central");
		addStandardTimeZone(vsTZ, "America/Bogota", "GMT -05:00 Columbia");
		addStandardTimeZone(vsTZ, "America/Lima", "GMT -05:00 Peru");
		addStandardTimeZone(vsTZ, "America/New_York", "GMT -05:00 US/Canada Eastern");
		addStandardTimeZone(vsTZ, "Etc/GMT+5", "GMT -05:00");
		addStandardTimeZone(vsTZ, "America/Halifax", "GMT -04:00 Canada Atlantic");
		addStandardTimeZone(vsTZ, "Etc/GMT+4", "GMT -04:00");
		addStandardTimeZone(vsTZ, "America/Santiago", "GMT -04:00 Pacific South America");
		addStandardTimeZone(vsTZ, "America/St_Johns", "GMT -03:30 Newfoundland");
		addStandardTimeZone(vsTZ, "America/Buenos_Aires", "GMT -03:00 Argentina");
		addStandardTimeZone(vsTZ, "Etc/GMT+3", "GMT -03:00");
		addStandardTimeZone(vsTZ, "America/Sao_Paulo", "GMT -03:00 Eastern South America");
		addStandardTimeZone(vsTZ, "Etc/GMT+2", "GMT -02:00 Mid-Atlantic");
		addStandardTimeZone(vsTZ, "Etc/GMT+1", "GMT -01:00");
		addStandardTimeZone(vsTZ, "Atlantic/Azores", "GMT -01:00 Azores");
		addStandardTimeZone(vsTZ, "Etc/GMT", "GMT +00:00");
		addStandardTimeZone(vsTZ, "Europe/London", "GMT +00:00 GMT Britain, Ireland, Portugal");
		addStandardTimeZone(vsTZ, "Etc/GMT-1", "GMT +01:00");
		addStandardTimeZone(vsTZ, "Europe/Paris", "GMT +01:00 Western Europe");
		addStandardTimeZone(vsTZ, "Africa/Windhoek", "GMT +01:00 Namibia");
		addStandardTimeZone(vsTZ, "Etc/GMT-2", "GMT +02:00 Eastern Europe");
		addStandardTimeZone(vsTZ, "Asia/Amman", "GMT +02:00 Jordan");
		addStandardTimeZone(vsTZ, "Europe/Athens", "GMT +02:00 Athens, Beirut, Bucharest, Istanbul, Minsk");
		addStandardTimeZone(vsTZ, "Africa/Cairo", "GMT +02:00 Egypt");
		addStandardTimeZone(vsTZ, "Asia/Damascus", "GMT +02:00 Damascus");
		addStandardTimeZone(vsTZ, "Asia/Gaza", "GMT +02:00 Gaza");
		addStandardTimeZone(vsTZ, "Asia/Jerusalem", "GMT +02:00 Jerusalem");
		addStandardTimeZone(vsTZ, "Etc/GMT-3", "GMT +03:00 Saudia Arabia");
		addStandardTimeZone(vsTZ, "Asia/Baghdad", "GMT +03:00 Iraq");
		addStandardTimeZone(vsTZ, "Europe/Moscow", "GMT +03:00 Moscow, St. Petersburg, Volgograd");
		addStandardTimeZone(vsTZ, "Asia/Tehran", "GMT +03:30 Tehran");
		addStandardTimeZone(vsTZ, "Etc/GMT-4", "GMT +04:00 Arabian");
		addStandardTimeZone(vsTZ, "Asia/Kabul", "GMT +04:30 Kabul");
		addStandardTimeZone(vsTZ, "Etc/GMT-5", "GMT +05:00 Pakistan, West Asia");
		addStandardTimeZone(vsTZ, "Asia/Yekaterinburg", "GMT +05:00 Yekaterinburg");
		addStandardTimeZone(vsTZ, "Asia/Calcutta", "GMT +05:30 Chennai, Kolkata, Mumbai, New Delhi");
		addStandardTimeZone(vsTZ, "Asia/Katmandu", "GMT +05:45 Kathmandu");
		addStandardTimeZone(vsTZ, "Etc/GMT-6", "GMT +06:00 Bangladesh, Central Asia");
		addStandardTimeZone(vsTZ, "Asia/Novosibirsk", "GMT +06:00 Almaty, Novosibirsk");
		addStandardTimeZone(vsTZ, "Asia/Rangoon", "GMT +06:30 Rangoon");
		addStandardTimeZone(vsTZ, "Asia/Bangkok", "GMT +07:00 Bangkok, Hanoi, Jakarta");
		addStandardTimeZone(vsTZ, "Etc/GMT-7", "GMT +07:00");
		addStandardTimeZone(vsTZ, "Asia/Krasnoyarsk", "GMT +07:00 Krasnoyarsk");
		addStandardTimeZone(vsTZ, "Asia/Shanghai", "GMT +08:00 China, Taiwan");
		addStandardTimeZone(vsTZ, "Asia/Singapore", "GMT +08:00 Singapore");
		addStandardTimeZone(vsTZ, "Etc/GMT-8", "GMT +08:00 Australia (WT)");
		addStandardTimeZone(vsTZ, "Asia/Irkutsk", "GMT +08:00 Irkutsk, Ulaan Bataar");
		addStandardTimeZone(vsTZ, "Asia/Seoul", "GMT +09:00 Korea");
		addStandardTimeZone(vsTZ, "Asia/Tokyo", "GMT +09:00 Japan");
		addStandardTimeZone(vsTZ, "Etc/GMT-9", "GMT +09:00");
		addStandardTimeZone(vsTZ, "Asia/Yakutsk", "GMT +09:00 Yakutsk");
		addStandardTimeZone(vsTZ, "Australia/Adelaide", "GMT +09:30 Adelaide (CT)");
		addStandardTimeZone(vsTZ, "Australia/Darwin", "GMT +09:30 Darwin");
		addStandardTimeZone(vsTZ, "Etc/GMT-10", "GMT +10:00");
		addStandardTimeZone(vsTZ, "Asia/Vladivostok", "GMT +10:00 Vladivostok");
		addStandardTimeZone(vsTZ, "Australia/Melbourne", "GMT +10:00 Melbourne (ET)");
		addStandardTimeZone(vsTZ, "Australia/Hobart", "GMT +10:00 Hobart");
		addStandardTimeZone(vsTZ, "Australia/Lord_Howe", "GMT +10:30 Australia (Lord Howe)");
		addStandardTimeZone(vsTZ, "Etc/GMT-11", "GMT +11:00");
		addStandardTimeZone(vsTZ, "Asia/Magadan", "GMT +11:00 Magadan, Solomon Is., New Caledonia");
		addStandardTimeZone(vsTZ, "Pacific/Norfolk", "GMT +11:30 Norfolk Islands");
		addStandardTimeZone(vsTZ, "Etc/GMT-12", "GMT +12:00");
		addStandardTimeZone(vsTZ, "Pacific/Auckland", "GMT +12:00 Fiji, New Zealand");
		addStandardTimeZone(vsTZ, "Etc/GMT-13", "GMT +13:00");
		addStandardTimeZone(vsTZ, "Etc/GMT-14", "GMT +14:00");
	
		return duplicate(vsTZ);
		</cfscript>
	</cffunction>
		
	<!--- addStandardTimeZone --->
	<cffunction name="addStandardTimeZone" access="private">
		<cfargument name="aTZStruct" type="struct" required="true">
		<cfargument name="aTZ" type="string" required="true">
		<cfargument name="aTZDesc" type="string" required="true">
		
		<cfscript>
		aTZStruct.Entry[aTZ] = structNew();
		aTZStruct.Entry[aTZ].Description = aTZDesc;
		
		aTZStruct.List = ListAppend(aTZStruct.List, aTZ);
	
		if (isValidTZ(aTZ))
		{
			// Gregory modified this from 'getTimeZone(aTZ)' to 'variables.tzObj.getTimeZone(aTZ)'
			aTZStruct.Entry[aTZ].Detail = variables.tzObj.getTimeZone(aTZ);
		}
		else
		{
			application.functions.general.throw("Timezone Id '#aTZ#' invalid;", 100010);
		}
		</cfscript>
	</cffunction>

</cfcomponent>