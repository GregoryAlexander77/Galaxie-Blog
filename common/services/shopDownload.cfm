<cfsetting enablecfoutputonly="true" showdebugoutput="false">
<!---
	A digital product's download (2026-10-20). The link in the buyer's email and My account carries a random token for one product in
	one paid order; it works until it expires or has been used too often (Blog Options > Shop). The file itself lives in the shop's
	private folder under a random name (Shop.cfc getFileFolder) and is only ever sent from here.
--->
<cfparam name="url.t" default="">
<cfset shopDownload = application.shop.prepareDownload(trim(url.t))>
<cfif not shopDownload.success>
	<cfheader statuscode="404">
	<cfcontent type="text/html; charset=utf-8" reset="true">
	<cfoutput><!doctype html><html lang="en"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width, initial-scale=1"><meta name="robots" content="noindex"><title>Download</title></head><body style="font-family:Arial,sans-serif;max-width:560px;margin:60px auto;padding:0 16px;line-height:1.5"><h1 style="font-size:22px">This download isn't available</h1><p>#encodeForHtml(shopDownload.message)#</p><p><a href="#encodeForHtmlAttribute(application.blogHostUrl)#">Back to #encodeForHtml(application.BlogDbObj.getBlogTitle())#</a></p></body></html></cfoutput>
	<cfabort>
</cfif>
<cfheader name="Cache-Control" value="no-store">
<cfheader name="X-Content-Type-Options" value="nosniff">
<cfheader name="Content-Disposition" value="attachment; filename=""#replace(shopDownload.displayName, '"', '', 'all')#""">
<cfcontent type="application/octet-stream" file="#shopDownload.path#" deletefile="false" reset="true">
