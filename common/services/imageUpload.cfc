<cfcomponent displayName="imageUpload" output="false" hint="Handles tinymce image uploads">
	
<cffunction name="handleImage" access="remote" returnformat="json" hint="Generates an key to use for encryption. This is a private function only available to other functions on this page.">
	<cfsilent>
	<!--- Set the destination. --->
	<cfset destination = expandPath("#application.baseUrl#/enclosures")>

	<!--- Upload it (GA) --->
	<cffile action="upload" filefield="file" mode="644" destination="#destination#" nameconflict="makeunique">

	<!--- Get the full path and the name of the file --->
	<cfset imageUrl = "/enclosures/" & cffile.serverFile>
	<!---<cfset imageUrl = "/enclosures/preview/mobile/test.png">--->

	<!--- Create a new location struct with the new image URL. --->
	<cfset imageUrlSting = { location="#imageUrl#" }>

	<!--- Return the structure with the image back to the client --->
	</cfsilent>	
	<cfcontent type="application/json; charset=UTF-8" />
	<cfheader name="Access-Control-Allow-Origin" value="*" />
	<cfheader name="Access-Control-Allow-Headers" value="Content-Type" />
	<cfoutput>#serializeJson(imageUrlSting)#</cfoutput><cfabort>
</cffunction>
</cfcomponent>