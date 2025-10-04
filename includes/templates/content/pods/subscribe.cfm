<cfsilent>
<cfprocessingdirective pageencoding="utf-8">
<!---
	Name         : subscribe.cfm
	Author       : Gregory Alexander
	Created      : Jan 4, 2025
	History      : See GitHub Repo
--->
	
<!--- 
********* Content template common logic *********
Other than setting the thisTemplate var, this logic is identical for most of the content output templates --->
<cfset thisTemplate = "subscribePod">
<!--- The following logic does not need to be modified and will work with most of the content output templates --->
<!--- Reset our display content output var --->
<cfset displayContentOutputData = false>
<!--- This template drives the navigation menu and is a unordered HTML list. This template uses the getContentOutputData function to determine the content. It will display custom content that is in the database or use the default code below if no custom code exists  --->
<cfinvoke component="#application.blog#" method="getContentOutputData" returnvariable="contentOutputData">
	<cfinvokeargument name="contentTemplate" value="#thisTemplate#">
	<cfinvokeargument name="isMobile" value="#session.isMobile#">
	<cfif isDefined("URL.optArgs") and len(URL.optArgs)>
		<cfinvokeargument name="themeRef" value="#URL.optArgs#">
	</cfif>
</cfinvoke>		
<!--- Determine if we should display the data or use the default HTML --->
<cfif len(contentOutputData)>
	<cfset displayContentOutputData = true>		
</cfif>
<!--- ********* End content template logic *********--->
	
<!--- handle: http://www.coldfusionjedi.com/forums/messages.cfm?threadid=4DF1ED1F-19B9-E658-9D12DBFBCA680CC6 --->
<cfset qs = reReplace(cgi.query_string, "<.*?>", "", "all")>
<cfset qs = reReplace(qs, "[\<\>]", "", "all")>
<cfset qs = reReplace(qs, "&", "&amp;", "all")>
			
<!--- Set the name of the form and the text element. This template is used in two different places and I want to have unique element id's. --->
<cfif sideBarType eq "div">
	<cfset subscribeFormId = "subscribeViaDiv">
<cfelse>
	<cfset subscribeFormId = "subscribeViaPanel">
</cfif>

</cfsilent>
				<cfif displayContentOutputData>
					<!--- Include the custom user defined content from the database --->
					<cfoutput>#contentOutputData#</cfoutput>
				<cfelse>
					<script type="<cfoutput>#scriptTypeString#</cfoutput>">
						// Invoked when the submit button is clicked. Instead of using '$("form").submit(function(event) {' and 'event.preventDefault();', We are using direct binding here to speed up the event.
						var subscribeSubmit = $('#<cfoutput>#subscribeFormId#Submit</cfoutput>');
						subscribeSubmit.on('click', function(e){   
							// Prevent any other action.
							e.preventDefault();     
							// Call the validator if the form is not valid.
							if (<cfoutput>#subscribeFormId#</cfoutput>FormValidator.validate()) {
								// submit the form.
								subscribeToBlog('<cfoutput>#sideBarType#</cfoutput>');
							} else {//..if (<cfoutput>#subscribeFormId#</cfoutput>FormValidator.validate())
								// Note: this is a custom library that I am using. The ExtAlertDialog is not a part of Kendo but an extension.
								$.when(kendo.ui.ExtAlertDialog.show({ title: "There are errors", message: "A valid email address is required. Please correct the highlighted fields and try again.", icon: "k-ext-warning", width: "<cfoutput>#application.kendoExtendedUiWindowWidth#</cfoutput>", height: "140px" }) // or k-ext-error, k-ext-question
									).done(function () {
									// Do nothing
								});//..$.when(kendo.ui.ExtAlertDialog.show...
							}//..if (<cfoutput>#subscribeFormId#</cfoutput>FormValidator.validate())
						});//..addCommentSubmit.on('click', function(e){ 
						
						$(document).ready(function() {
							// Note: there are no custom rules on this form. This is an empty validator.
							<cfoutput>#subscribeFormId#</cfoutput>FormValidator = $("#<cfoutput>#subscribeFormId#Form</cfoutput>").kendoValidator().data("kendoValidator");
						});//..document.ready
					</script>
					<cfoutput>
					Enter your email address to subscribe to this blog.
					<form id="#subscribeFormId#Form" name="#subscribeFormId#Form" action="#chr(35)#" method="post" data-role="validator">
						<!--- Note that this forms type is 'email'. This is an HTML5 attribute and it will automatically be validated. --->
						<input type="email" id="#subscribeFormId#" name="#subscribeFormId#" value="" class="k-textbox" aria-label="Enter your email address" required validationMessage="Email is required" data-email-msg="Email is not valid" />
						<br/>
						<input type="button" id="#subscribeFormId#Submit" name="#subscribeFormId#Submit" value="Subscribe" class="k-button k-primary" style="<cfoutput>#kendoButtonStyle#</cfoutput>">
					</form>
					</cfoutput>
				</cfif>