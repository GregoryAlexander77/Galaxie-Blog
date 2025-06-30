	<!--- The application.dbBlogVersion was not set until version 3.12 --->
	<cfif not isDefined("application.dbBlogVersion")>
		<cfset dbBlogVersion = 3>
	<cfelse>
		<cfset dbBlogVersion = application.dbBlogVersion>
	</cfif>
	<cfset fileSystemBlogVersion = application.blog.getVersion()>
	<!---
	Debugging
	<cfoutput>
		dbBlogVersion: #dbBlogVersion#<br/>
		fileSystemBlogVersion: #fileSystemBlogVersion#<br/>
	</cfoutput>
	--->	

	<style>
		#recentVersionCheck {
			width:100%;
		}
	</style>
	
	<script>
		// Get the summary information
		$("#upgradeDetails").html("<p>Checking to see if your blog is up to date. Please wait.</p>").load("latestVersionCheck.cfm?version=<cfoutput>#fileSystemBlogVersion#</cfoutput>&dbBlogVersion=<cfoutput>#dbBlogVersion#</cfoutput>", function() {
		});
	</script>	
	
	<table id="recentVersionCheck" class="k-content" width="100%" cellpadding="0" cellspacing="0" border="0">
	  <tr class="k-alt">
		  <span id="upgradeDetails" style="display: inline-block; width: 100%"></span>
		</td>	
	  </tr>
	</table><br/>