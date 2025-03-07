	<!--- Instantiate the Render.cfc. This will be used to render our directives and create video and map thumbnails --->
	<cfobject component="#application.rendererComponentPath#" name="RendererObj">
	
	<!--- Get the post ( getPostByPostId(postId, showPendingPosts, showRemovedPosts) ) --->
	<cfset getPost = application.blog.getPostByPostId(URL.optArgs,true,true)>
	<!---<cfdump var="#getPost#">--->
		
	<!--- Get the date posted --->
	<cfset datePosted = application.Udf.jsDateFormat(getPost[1]["DatePosted"])>
	<!--- Get the sort order date --->
	<cfset blogSortDate = getPost[1]["BlogSortDate"]>
		
	<script>
		
		var todaysDate = new Date();
		var currentBlogSortDate = $("#newBlogSortDate").val();
			
		// Kendo Dropdowns
		// Date posted date/time picker			
		$("#blogSortDate").kendoDateTimePicker({
			componentType: "modern",
			value: <cfoutput>#application.Udf.jsDateFormat(getPost[1]['BlogSortDate'])#</cfoutput>,
			/* Change the  blogSortDateChanged to 1 on the postDetails page */
			change: function() {
				$("#blogSortDateChanged").val(1);
			}
		});

		function onBlogSortDateSubmit() {
			// alert("Change :: " + kendo.toString(this.value(), 'g'));
			// Check to see if the selected date is greater than today
			if ($("#blogSortDate").val() > todaysDate){
				$.when(kendo.ui.ExtYesNoDialog.show({ 
					title: "Set the sort date in the future?",
					message: "You are setting this to a date in the future. Do you want to continue?",
					icon: "k-ext-warning",
					width: "<cfoutput>#application.kendoExtendedUiWindowWidth#</cfoutput>", 
					height: "215px"
				})
				).done(function (response) { // If the user clicked 'yes'
					if (response['button'] == 'Yes'){// remember that js is case sensitive.
						// Change the hidden input field on the post details page
						$("#newBlogSortDate").val($("#blogSortDate").val());
					}//..if (response['button'] == 'Yes'){
				});
			} else {
				// Change the hidden input field on the post details page
				$("#newBlogSortDate").val($("#blogSortDate").val());
			}
			
			// Close this window.
			$('#blogSortDateWindow').kendoWindow('destroy');
		}
		
		function syncDates(el) {
			if (el.checked) {
				// Set the sortDateChanged to true as we are syncing the dates and want the current blog sort to change
				$("#blogSortDateChanged").val(1);
				// Sync the hidden form value to the posted date
				$("#newBlogSortDate").val(<cfoutput>#datePosted#</cfoutput>);
				// Close this window when the button is checked
				$('#blogSortDateWindow').kendoWindow('destroy');
			}
		}
		
	</script>
		
	<form id="postBlogSortDateForm" action="#" method="post" data-role="validator">
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
			<p>The Blog Sort Date is be used to change the sort order of the posts in a different order than the actual post date.</p>
			
			<p>To change the sort order on the main blog page, choose a sort date between the dates of two different posts. For example, if you want this to show up underneath a post with the post made on New Year's Day, but above your post made during Christmas, set the date to something between December 25th and January 1st.</p>
			
			<p>If the Sync with Postdate checkbox is checked, the blog sort date will be the same as the blog post date.</p>
		</td>
	   </tr>
	<cfelse><!---<cfif session.isMobile>--->
	  <tr height="30px">
		<td align="left" class="<cfoutput>#thisContentClass#</cfoutput>" colspan="2"> 
			<p>The Blog Sort Date is be used to change the sort order of the posts in a different order than the actual post date.</p>
			
			<p>To change the sort order on the main blog page, choose a sort date between the dates of two different posts. For example, if you want this to show up underneath a post with the post made on New Year's Day, but above your post made during Christmas, set the date to something between December 25th and January 1st.</p>
			
			<p>If the Sync with Postdate checkbox is checked, the blog sort date will be the same as the blog post date.</p>
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
			<label for="blogSortDate">Post Sort Date</label>
		</td>
	   </tr>
	   <tr>
		<td class="<cfoutput>#thisContentClass#</cfoutput>" colspan="2">
			<input id="blogSortDate" name="blogSortDate" value="<cfoutput>#dateTimeFormat(blogSortDate, 'medium')#</cfoutput>" style="width: <cfif session.isMobile>95<cfelse>45</cfif>%" /> 
		</td>
	  </tr>
	<cfelse><!---<cfif session.isMobile>--->
	  <tr valign="middle" height="30px">
		<td align="right" valign="middle" class="<cfoutput>#thisContentClass#</cfoutput>" width="20%">
			<label for="blogSortDate">Post Sort Date</label>
		</td>
		<td align="left" class="<cfoutput>#thisContentClass#</cfoutput>">
			<input id="blogSortDate" name="blogSortDate" value="<cfoutput>#dateTimeFormat(blogSortDate, 'medium')#</cfoutput>" style="width: <cfif session.isMobile>95<cfelse>45</cfif>%" /> 
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
	<cfif session.isMobile>
	  <tr valign="middle">
		<td class="<cfoutput>#thisContentClass#</cfoutput>" colspan="2">
			<label for="syncWithPostDate">Sync with Post Date</label>
		</td>
	   </tr>
	   <tr>
		<td class="<cfoutput>#thisContentClass#</cfoutput>" colspan="2">
			<input id="syncWithPostDate" name="syncWithPostDate" type="checkbox" onChange="syncDates(this)"/> 
		</td>
	  </tr>
	<cfelse><!---<cfif session.isMobile>--->
	  <tr valign="middle" height="30px">
		<td align="right" valign="middle" class="<cfoutput>#thisContentClass#</cfoutput>" width="20%">
			<label for="syncWithPostDate">Sync with Post Date</label>
		</td>
		<td align="left" class="<cfoutput>#thisContentClass#</cfoutput>">
			<input id="syncWithPostDate" name="syncWithPostDate" type="checkbox" onChange="syncDates(this)"/>  
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
			<button id="postHeaderSubmit" name="postHeaderSubmit" class="k-button k-primary" type="button" onClick="onBlogSortDateSubmit()">Submit</button>
		</td>
	  </tr>
	</table>
	</form>