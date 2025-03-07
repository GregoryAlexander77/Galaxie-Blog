	<style>
		.mce-ico.mce-i-fa {
		display: inline-block;
		font: normal normal normal 14px/1 FontAwesome;
		font-size: inherit;
		text-rendering: auto;
		-webkit-font-smoothing: antialiased;
		-moz-osx-font-smoothing: grayscale;
	}
	</style>
		
	<!--- Get the post. Here we aer passing the postId, true to get removed posts, and true to get the ld-json body ( getPostByPostId(postId, showPendingPosts, showRemovedPosts) ). --->
	<cfset getPost = application.blog.getPostByPostId(URL.optArgs,true,true)>
	<!---<cfdump var="#getPost#">--->
		
	<cfif len(getPost[1]["JsonLd"])>
		<!--- Get the current LD JSON --->
		<cfset jsonLd = getPost[1]["JsonLd"]>
		<!--- Clean it up... --->
		<cfset jsonLd = application.blog.cleanJsonLd(jsonLd)>
	<cfelse>
		<!--- Render the LD JSON --->
		<cfobject component="#application.rendererComponentPath#" name="RendererObj">
		<!--- The false argument will get the actual JSON string. --->
		<cfset jsonLd = RendererObj.renderLdJson(URL.optArgs, false)>
	</cfif>
	<!---<cfdump var="#jsonLd#">--->

	<form id="jsonLdForm" action="#" method="post" data-role="validator">
	<table align="center" class="k-content tableBorder" width="100%" cellpadding="2" cellspacing="0" border="0">
	  <cfsilent>
			<!---The first content class in the table should be empty. --->
			<cfset thisContentClass = HtmlUtilsObj.getKendoClass('')>
			<!--- Set the colspan property for borders --->
			<cfset thisColSpan = "1">
	  </cfsilent>
	  <tr height="1px">
		  <td align="left" valign="top" class="<cfoutput>#thisContentClass#</cfoutput>"></td>
	  </tr>
	  <tr height="30px">
		<td align="left" class="<cfoutput>#thisContentClass#</cfoutput>"> 
			Actual JSON-LD string used for this post.
		</td>
	  </tr>
	  <!-- Border -->
	  <tr height="2px">
		  <td align="left" valign="top" class="<cfoutput>#thisContentClass#</cfoutput>"></td>
	  </tr>
	  <cfsilent>
	  <!--- Set the class for alternating rows. --->
	  <!---After the first row, the content class should be the current class. --->
	  <cfset thisContentClass = HtmlUtilsObj.getKendoClass(thisContentClass)>
	  </cfsilent>
	  <tr height="2px">
		  <td align="left" valign="top" class="border <cfoutput>#thisContentClass#</cfoutput>"></td>
	  </tr>
	  <!-- Form content -->
	  <tr valign="middle" height="30px">
		<td align="left" class="<cfoutput>#thisContentClass#</cfoutput>">
			<cfoutput>#jsonLd#</cfoutput>
		</td>
	  </tr>
	  <!-- Border -->
	  <tr height="2px">
		<td align="left" valign="top" class="<cfoutput>#thisContentClass#</cfoutput>"></td>
	  </tr>
	</table>
	</form>