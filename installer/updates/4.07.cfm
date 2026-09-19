<!--- description: Adds any map providers and map types that are missing. --->
<!--- This used to be part of the update logic in ProxyController.cfc. It only adds the missing records, see the note in 3.12.cfm. --->
<cfset seedTables("MapProvider,MapType", false)>
