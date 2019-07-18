<cfoutput>
<script src="#application.kendoSourceLocation#/js/jquery.min.js"></script>
<script src="#application.kendoSourceLocation#/js/kendo.all.min.js"></script>
<!--- Material black and office 365 themes require a different stylesheet. --->
<cfif getKendoTheme() eq 'materialblack'>
<link href="#application.kendoSourceLocation#/styles/kendo.common-material.min.css" rel="stylesheet">
<cfelseif getKendoTheme() eq 'office365'>
<link href="#application.kendoSourceLocation#/styles/kendo.common-office365.min.css" rel="stylesheet">
<cfelseif getKendoTheme() eq 'fiori'>
<link href="#application.kendoSourceLocation#/styles/kendo.common-fiori.min.css"  rel="stylesheet">
<!--- All of the other themes are included in the common min ss --->
<cfelse>
<link href="#application.kendoSourceLocation#/styles/kendo.common.min.css" rel="stylesheet">
</cfif>
<link href="#application.kendoSourceLocation#/styles/kendo.rtl.min.css" rel="stylesheet">
<!--- Custom themes tailored for the site. --->
<cfif getKendoTheme() eq 'nova22'>
	<link href="#application.kendoSourceLocation#/styles/customNovaTheme/kendo.custom.css" rel="stylesheet">
<cfelse>
	<link href="#application.kendoSourceLocation#/styles/kendo.<cfoutput>#getKendoTheme()#</cfoutput>.min.css" rel="stylesheet">
</cfif>
<!--- Other  libraries  --->
<!--- Kendo extended API (used for confirm and other dialogs) --->
<script src="#application.kendoUiExtendedLocation#/js/kendo.web.ext.js"></script>
<link href="#application.kendoUiExtendedLocation#/styles/#getKendoTheme()#.kendo.ext.css" rel="stylesheet">
<!--- jQuery ui component (used for notifications). This is an outdated library in the original blogcfc design. --->
<script src="#application.jQueryUiLocation#/jqueryui.js" type="text/javascript"></script>
<!--- Custom notification plugin with a title and an onclick event (which Kendo does not have). ---> 
<script language="JavaScript" src="#application.jQueryNotifyLocation#/src/jquery.notify.js" type="text/javascript"></script>
<!--- Notification .css  --->
<link type="text/css" rel="stylesheet" href="#application.jQueryNotifyLocation#/ui.notify.css">
<link type="text/css" rel="stylesheet" href="#application.jQueryNotifyLocation#/notify.css">
<!--- Optional libs --->
<!--- Needed to export to excel.  --->
<!---<script src="#application.kendoSourceLocation#js/jszip.min.js"></script>--->
</cfoutput>