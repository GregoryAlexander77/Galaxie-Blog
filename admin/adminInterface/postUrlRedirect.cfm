	<!--- Instantiate the Render.cfc. This will be used to render our directives and create video and map thumbnails --->
	<cfobject component="#application.rendererComponentPath#" name="RendererObj">
	
	<!--- Get the post ( getPostByPostId(postId, showPendingPosts, showRemovedPosts) ). --->
	<cfset getPost = application.blog.getPostByPostId(URL.optArgs,true,true)>
	<!--- Get the current URL redirect --->
	<cfset redirectUrl = getPost[1]["RedirectUrl"]>
	<!--- Get the themes. This is a HQL array --->
	<cfset redirectType = getPost[1]["RedirectType"]>
	<!---<cfdump var="#themeNames#">--->
		
	<script>
		
		$(document).ready(function() {
			// Create the redirect type dropdown
			var postRedirectTypeDropdown = $("#postRedirectTypeDropdown").kendoDropDownList();
			// Create the validator
			var postRedirectValidator = $("#postRedirectForm").kendoValidator().data("kendoValidator");
			
			// Invoked when the submit button is clicked. Insted of using '$("form").submit(function(event) {' and 'event.preventDefault();', We are using direct binding here to speed up the event.
			var postRedirectSubmit = $('#postRedirectSubmit');
				postRedirectSubmit.on('click', function(e){      
					e.preventDefault();     
					
					if (postRedirectValidator.validate()) {
						// Submit the form
						onPostRedirectSubmit();

					} else {

						$.when(kendo.ui.ExtAlertDialog.show({ title: "There are errors", message: "Please correct the highlighted fields and try again", icon: "k-ext-warning" }) // or k-ext-error, k-ext-question
							).done(function () {
							// Do nothing
						});
					}
				});
			
			
			
		});
		
		function onPostRedirectSubmit() {
			// Change the hidden input fields on the post details page
			$("#redirectUrl").val($("#postRedirectUrl").val());
			$("#redirectType").val($("#postRedirectTypeDropdown").val());
			// Close this postUrlRedirectWindow.
			$('#postUrlRedirectWindow').kendoWindow('destroy');
		}
		
	</script>
		
	<form id="postRedirectForm" action="#" method="post" data-role="validator">
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
	  <tr>
		<td align="left" class="<cfoutput>#thisContentClass#</cfoutput>" colspan="2"> 
			<p>You can redirect this post to a new URL.</p> 
			<p>If your post is already indexed by a search engine, an HTTP Status code will be sent along with the redirect to let the search engines know that the URL has changed. This will let the search engines know that there is a new URL and you should not be penalized for the URL change. Be sure not to permenently delete the post if there is a redirect otherwise this redirect will disappear.</p>
		</td>
	  </tr>
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
	  <tr height="1px">
		  <td align="left" valign="top" colspan="2" class="<cfoutput>#thisContentClass#</cfoutput>"></td>
	  </tr>
	<cfif session.isMobile>
	  <tr valign="middle">
		<td class="<cfoutput>#thisContentClass#</cfoutput>" colspan="2">
			<label for="postRedirectUrl">Redirect URL</label>
		</td>
	   </tr>
	   <tr>
		<td class="<cfoutput>#thisContentClass#</cfoutput>" colspan="2">
			<input id="postRedirectUrl" name="postRedirectUrl" type="url" value="<cfoutput>#redirectUrl#</cfoutput>" required validationMessage="URL is required" class="k-textbox" style="width: 90%" /> 
		</td>
	  </tr>
	<cfelse><!---<cfif session.isMobile>--->
	  <tr height="30px">
		<td align="right" width="15%" class="<cfoutput>#thisContentClass#</cfoutput>"> 
			<label for="postRedirectUrl">Redirect URL</label>
		</td>
		<td width="85%" class="<cfoutput>#thisContentClass#</cfoutput>">
			<input id="postRedirectUrl" name="postRedirectUrl" type="url" value="<cfoutput>#redirectUrl#</cfoutput>" required validationMessage="URL is required" class="k-textbox" style="width: 75%" /> 
		</td>
	  </tr>
	</cfif><!---<cfif session.isMobile>--->
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
			<label for="postRedirectTypeDropdown">Redirect Type</label>
		</td>
	   </tr>
	   <tr>
		<td class="<cfoutput>#thisContentClass#</cfoutput>" colspan="2">
			<select id="postRedirectTypeDropdown" name="postRedirectTypeDropdown">
				<option value="301" <cfif redirectType eq '301'>checked</cfif>>Permanent</option>
				<option value="302" <cfif redirectType eq '301'>checked</cfif>>Temporary</option>
			</select>
		</td>
	  </tr>
	<cfelse><!---<cfif session.isMobile>--->
	  <tr valign="middle" height="30px">
		<td align="right" valign="middle" class="<cfoutput>#thisContentClass#</cfoutput>" width="20%">
			<label for="postRedirectTypeDropdown">Redirect Type</label>
		</td>
		<td align="left" class="<cfoutput>#thisContentClass#</cfoutput>">
			<select id="postRedirectTypeDropdown" name="postRedirectTypeDropdown">
				<option value="301">Permanent</option>
				<option value="302">Temporary</option>
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
			<!--- The postRedirectSubmit changes a dropdown in the post detail page.onPost --->
			<button id="postRedirectSubmit" name="postRedirectSubmit" class="k-button k-primary" type="button">Submit</button>
		</td>
	  </tr>
	</table>
	</form>