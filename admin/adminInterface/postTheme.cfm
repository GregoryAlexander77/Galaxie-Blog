	<!--- Instantiate the Render.cfc. This will be used to render our directives and create video and map thumbnails --->
	<cfobject component="#application.rendererComponentPath#" name="RendererObj">
	
	<!--- Get the post ( getPostByPostId(postId, showPendingPosts, showRemovedPosts) ). --->
	<cfset getPost = application.blog.getPostByPostId(URL.optArgs,true,true)>
	<!--- Get the current theme --->
	<cfset postThemeId = getPost[1]["ThemeRef"]>
	<!--- Get the themes. This is a HQL array --->
	<cfset themeNames = application.blog.getThemeNames()>
	<!---<cfdump var="#themeNames#">--->
		
	<script>
		
		$(document).ready(function() {
			// Create the top level dropdown
			var postThemeDropdown = $("#postThemeDropdown").kendoComboBox();
		});
		
		function onPostThemeSubmit() {
			// Change the hidden input field on the post details page
			$("#postThemeId").val($("#postThemeDropdown").val());
			// Close this window.
			$('#setPostThemeWindow').kendoWindow('destroy');
		}
		
	</script>
		
	<form id="postThemeForm" action="#" method="post" data-role="validator">
	<!--- Pass the csrfToken --->
	<input type="hidden" name="csrfToken" id="csrfToken" value="<cfoutput>#csrfToken#</cfoutput>" />
	<table align="center" class="k-content tableBorder" width="100%" cellpadding="2" cellspacing="0" border="0">
	  <cfsilent>
			<!---The first content class in the table should be empty. --->
			<cfset thisContentClass = HtmlUtilsObj.getKendoClass('')>
			<!--- Set the colspan property for borders --->
			<cfset thisColSpan = "2">
	  </cfsilent>
	  <tr height="1px">
		  <td align="left" valign="top" colspan="2" class="<cfoutput>#thisContentClass#</cfoutput>"></td>
	  </tr>
	  <cfif session.isMobile>
	  <tr valign="middle">
		<td class="<cfoutput>#thisContentClass#</cfoutput>" colspan="2">
			<p>You can attach a unique theme to a given post.</p> 
			<p>This does not have any impact on the main blog page, but it will display the chosen theme when the user is looking at this post.</p>
		</td>
	   </tr>
	<cfelse><!---<cfif session.isMobile>--->
	  <tr height="30px">
		<td align="left" class="<cfoutput>#thisContentClass#</cfoutput>" colspan="2"> 
			<p>You can attach a unique theme to a given post.</p> 
			<p>This was designed to allow blog owners to create a post that has a unique theme. For example, you can create your own holiday-oriented theme on your 'Happy Holidays!' post, or on a post that supports a certain cause (i.e. 'Donate to breast cancer awareness'.</p> <p>This does not have any impact on the main blog page, but it will display the chosen theme when the user is looking at this post.</p>
		</td>
	  </tr>
	</cfif>
	  <!-- Border -->
	  <tr height="2px">
		  <td align="left" valign="top" colspan="<cfoutput>#thisColSpan#</cfoutput>" class="<cfoutput>#thisContentClass#</cfoutput>"></td>
	  </tr>
	  <cfsilent>
	  <!--- Set the class for alternating rows. --->
	  <!---After the first row, the content class should be the current class. --->
	  <cfset thisContentClass = HtmlUtilsObj.getKendoClass(thisContentClass)>
	  </cfsilent>
	  <tr height="2px">
		  <td align="left" valign="top" colspan="2" class="border <cfoutput>#thisContentClass#</cfoutput>"></td>
	  </tr>
	  <!-- Form content -->
	<cfif session.isMobile>
	  <tr valign="middle">
		<td class="<cfoutput>#thisContentClass#</cfoutput>" colspan="2">
			<label for="setPostTheme">Set Post Theme</label>
		</td>
	   </tr>
	   <tr>
		<td class="<cfoutput>#thisContentClass#</cfoutput>" colspan="2">
			<select id="postThemeDropdown" name="postThemeDropdown">
				<option value="0">None Selected</option>
				<cfloop from="1" to="#arrayLen(themeNames)#" index="i"><cfoutput><option value="#themeNames[i]['ThemeId']#" <cfif postThemeId eq themeNames[i]['ThemeId']>selected</cfif>>#themeNames[i]['ThemeName']#</option></cfoutput></cfloop>
			</select>
		</td>
	  </tr>
	<cfelse><!---<cfif session.isMobile>--->
	  <tr valign="middle" height="30px">
		<td align="right" valign="middle" class="<cfoutput>#thisContentClass#</cfoutput>" width="20%">
			<label for="setPostTheme">Set Post Theme</label>
		</td>
		<td align="left" class="<cfoutput>#thisContentClass#</cfoutput>">
			<select id="postThemeDropdown" name="postThemeDropdown">
				<option value="0">None Selected</option>
				<cfloop from="1" to="#arrayLen(themeNames)#" index="i"><cfoutput><option value="#themeNames[i]['ThemeId']#" <cfif postThemeId eq themeNames[i]['ThemeId']>selected</cfif>>#themeNames[i]['ThemeName']#</option></cfoutput></cfloop>
			</select>
		</td>
	  </tr>
	</cfif>
	  <!-- Border -->
	  <tr height="2px">
		<td align="left" valign="top" colspan="<cfoutput>#thisColSpan#</cfoutput>" class="<cfoutput>#thisContentClass#</cfoutput>"></td>
	  </tr>
	  <cfsilent>
	  <!--- Set the class for alternating rows. --->
	  <!--- After the first row, the content class should be the current class. --->
	  <cfset thisContentClass = HtmlUtilsObj.getKendoClass(thisContentClass)>
	  </cfsilent>
	  <tr height="2px">
		  <td align="left" valign="top" colspan="2" class="border <cfoutput>#thisContentClass#</cfoutput>"></td>
	  </tr>
	  <!-- Form content -->
	  <tr valign="middle" height="30px">
		<td valign="bottom" align="right" class="<cfoutput>#thisContentClass#</cfoutput>">&nbsp;</td>
		<td valign="bottom" align="left" class="<cfoutput>#thisContentClass#</cfoutput>">
			<!--- The onPostThemeSubmit changes a dropdown in the post detail page. It does not trigger the saving of the theme. The save function is invoked using on onPostThemeSubmit js function --->
			<button id="postThemeSubmit" name="postThemeSubmit" class="k-button k-primary" type="button" onClick="onPostThemeSubmit()">Submit</button>
		</td>
	  </tr>
	</table>
	</form>