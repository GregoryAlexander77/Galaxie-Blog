<cfsilent>
	<!---
	Notes on css files: I typically use internal stylesheets as I have access to variables in a .cfm page that uses them. If I externalize the css files, I lose the ability to easilly use ColdFusion dynamic variables. --->
		
	<!--- Get the fonts that need to be loaded from the db --->
	<cfinvoke component="#application.blog#" method="getThemeFonts" returnvariable="getSelfHostedFonts">
		<cfinvokeargument name="themeId" value="#themeId#">
		<cfinvokeargument name="selfHosted" value="1">
	</cfinvoke>
		
	<!--- Future use 
	<cfinvoke component="#application.blog#" method="getFont" returnvariable="getGoogleFonts">
		<cfinvokeargument name="googleFont" value="true">
		<cfinvokeargument name="SelfHosted" value="false">
		<cfinvokeargument name="webSafe" value="false">
		<cfinvokeargument name="useFont" value="true">
	</cfinvoke>--->

	<!--- If the server has the woff2 mime type setup, we will use the next gen font format, otherwise we will fallback to the woff font. --->
	<cfif  application.serverSupportsWoff2>
		<cfset fontExtension = "woff2">
	<cfelse>
		<cfset fontExtension = "woff">
	</cfif>
	</cfsilent>
<cfif application.minimizeCode>
	<cfif arrayLen(getSelfHostedFonts)><style rel="preload" as="font"><cfloop from="1" to="#arrayLen(getSelfHostedFonts)#" index="i"><cfoutput>@font-face{font-family:"#getSelfHostedFonts[i]['Font']#";src:url(#application.baseUrl#/common/fonts/#getSelfHostedFonts[i]['FileName']#.#fontExtension#) format("#fontExtension#");font-display:swap;}</cfoutput></cfloop></style></cfif>
<cfelse><!---<cfif application.minimizeCode>--->
	<cfif arrayLen(getSelfHostedFonts)>
	<!--- Preload the fonts. --->
	<style rel="preload" as="font"><cfloop from="1" to="#arrayLen(getSelfHostedFonts)#" index="i"><cfoutput>
		/* #getSelfHostedFonts[i]['Font']# */
		@font-face {
			font-family: "#getSelfHostedFonts[i]['Font']#";
			src: url(#application.baseUrl#/common/fonts/#getSelfHostedFonts[i]['FileName']#.#fontExtension#) format("#fontExtension#")<cfif getSelfHostedFonts[i]['Woff']>, url(#application.baseUrl#/common/fonts/#getSelfHostedFonts[i]['FileName']#.#fontExtension#) format("woff")</cfif>;
			font-display:swap;
		}
	</cfoutput></cfloop></style>
	</cfif><!---<cfif arrayLen(getSelfHostedFonts)>--->
</cfif><!---<cfif application.minimizeCode>--->
<cfif 1 eq 2 and arrayLen(getGoogleFonts)>
	<cfsilent>
	<!--- This will never be invoked (see 1 eq 2 above) and will be implemented in another version. It is not used in this version.  --->
	<!--- Load the google fonts. We want to make sure that there is only once call to the google font api so we need to concatenate our link with multiple fonts like so: 'family=Roboto|Open+Sans'. We are aso going to try to load the bold and italic versions of the font by appending ':bold,bolditalic' to our string --->
	<cfif arrayLen(getGoogleFonts) eq 1>
		<cfset fontFamilyStr = encodeForUrl(getGoogleFonts[1]["Font"])>
	<cfelse>
		<cfset fontLoopCounter = 1>
		<cfloop from="1" to="#arrayLen(getGoogleFonts)#" index="i">
			<cfif fontLoopCounter eq 1>
				<cfset fontFamilyStr = encodeForUrl(getGoogleFonts[i]["Font"])>
			<cfelse>
				<cfset fontFamilyStr = fontFamilyStr & "|" & encodeForUrl(getGoogleFonts[i]["Font"])>
			</cfif>
			<!--- Increment our counter --->
			<cfset fontLoopCounter = fontLoopCounter + 1>
		</cfloop>
	</cfif>	
	</cfsilent>
	<!-- Get google fonts -->
	<link href="https://fonts.googleapis.com/css?family=<cfoutput>#fontFamilyStr#</cfoutput>:bold,bolditalic" rel="stylesheet">
</cfif>