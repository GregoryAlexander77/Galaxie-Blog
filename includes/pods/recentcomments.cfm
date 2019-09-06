<cfsilent>
<cfprocessingdirective pageencoding="utf-8">
<!---
	Name         : recent.cfm
	Author       : Sam Farmer
	Created      : April 13, 2006
	Last Updated : November 4, 2018
	History      : left was cropping off links mid html. (rkc 6/9/06)
				 : Pass 25 as the max length for links in comments (rkc 7/21/06)
				 : Wasn't properly localized (rkc 8/24/06)
				 : forgot to disable cfoutputonly (rkc 11/17/07)
				 : Gregory put a new Kendo front end on the pod. The UI has been completely revised.
	Purpose		 : Display recent comments
--->

<cfset numComments = 5>
<cfset lenComment = 100>
	
<!---Include the UDF (Raymonds code) --->
<cfinclude template="#application.baseUrl#/includes/udf.cfm">
<!--- This template is needed in order to secure the admin portions of the site. Note: the cflogin code below the udf was coded by Raymond and is essentially unchanged. --->
<!---Include the resource bundle.--->
<cfset getResourceBundle = application.utils.getResource>

<cfset getComments = application.blog.getRecentComments(numComments)>
</cfsilent>
					<table align="center" class="k-content fixedPodTableWithWrap" width="100%" cellpadding="0" cellspacing="0">
						<cfif not getComments.recordCount>
							<tr>
								<td class="k-header">
								<cfoutput>#application.resourceBundle.getResource("norecentcomments")#</cfoutput>
								</td>
							</tr>
						</cfif>
						<cfoutput query="getComments">
						<cfset formattedComment = comment>
						<cfif len(formattedComment) gt len(lenComment)>
							<cfset formattedComment = left(formattedComment, lenComment)>
						</cfif>
						<cfset formattedComment = replaceLinks(formattedComment,25)>
						<tr class="#iif(currentRow MOD 2,DE('k-content'),DE('k-alt'))#" height="50px;">
							<!--- Create alternating rows in the table. The Kendo classes which we will use are k-alt and k-content.
							We will create a border between the rows if the current row is not the first row. --->
							<cfif currentRow eq 1>
								<td valign="top">
							<cfelse>
								<td align="left" valign="top" class="border">
							</cfif>
							<cfinvoke component="#application.blog#" method="makeLink" returnVariable="commentLink">
								<cfinvokeargument name="entryid" value="#getComments.entryID#">
								<cfinvokeargument name="commentId" value="#getComments.id#">
							</cfinvoke>	
							<!--- Note: Raymond is hiding the URL arguments. See notes above the showComment function on index.cfm template for more information. 
							Bugs?: the alias appears to be wrong on several occasions. Not sure why. --->
							<a href="#application.blog.makeLink(getComments.entryID)#" aria-label="#application.blog.makeLink(getComments.entryID)#" <cfif darkTheme>style="color:whitesmoke"</cfif>>#getComments.title#</a>:<br/>
							<a href="#application.blog.makeLink(getComments.entryID)###c#getComments.id#" aria-label="#application.blog.makeLink(getComments.entryID)###c#getComments.id#" <cfif darkTheme>style="color:whitesmoke"</cfif>>#getComments.name# #application.resourceBundle.getResource("said")#: #formattedComment#<cfif len(comment) gt lenComment>...</cfif></a>
							</td>
						</tr>	
						</cfoutput>
					</table>
					<br/>