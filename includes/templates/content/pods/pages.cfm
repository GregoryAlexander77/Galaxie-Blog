<cfsetting enablecfoutputonly=true>
<cfprocessingdirective pageencoding="utf-8">
<!---
   Name : pages.cfm
   Author : William Haun (based on archives.cfm by Raymond Camden) (mods by Hatton)
   Created : August 19, 2006
   Last Updated :
   History :
--->


<cfmodule template="../../tags/scopecache.cfm" cachename="pod_pages" scope="application" timeout="#application.timeout#">

<cfset pages_qry = application.page.getPages() />

   
<cfmodule template="../../tags/podlayout.cfm" title="NAVIGATION">
	<cfoutput><a href="#thisUrl#" class="k-content">Home</a><br /></cfoutput>

	<cfloop query="pages_qry">
		<cfoutput><a href="#thisUrl#/page.cfm/#alias#" class="k-content">#title#</a><br /></cfoutput>
	</cfloop>
      
</cfmodule>
      
</cfmodule>

<cfsetting enablecfoutputonly=false />
