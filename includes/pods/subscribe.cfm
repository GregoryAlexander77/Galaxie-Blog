<cfsilent>
<cfprocessingdirective pageencoding="utf-8">
<!---
	Name         : subscribe.cfm
	Author       : Raymond Camden 
	Created      : May 12, 2005
	Last Updated : November 4 2018
	History      : Send email for verification (rkc 7/7/06)
				 : JavaScript fix, thanks to Charlie (rkc 7/10/06)
				 : Make formfield dynamic, thanks Andy Jarret (rkc 8/20/06)
				 : Forgot to make JS dynamic, thanks Tom C (rkc 10/29/06)
				 : Add a return msg on subscribing. Someone else did this - I forget who.
				 : Gregory completely re-wrote this. The ony logic left is the qs vars.
--->

<!--- handle: http://www.coldfusionjedi.com/forums/messages.cfm?threadid=4DF1ED1F-19B9-E658-9D12DBFBCA680CC6 --->
<cfset qs = reReplace(cgi.query_string, "<.*?>", "", "all")>
<cfset qs = reReplace(qs, "[\<\>]", "", "all")>
<cfset qs = reReplace(qs, "&", "&amp;", "all")>
	
<cfif kendoTheme contains 'material'>
	<cfif session.isMobile>
		<cfset kendoButtonStyle = "width:90px; font-size:0.55em;">
	<cfelse>	
		<cfset kendoButtonStyle = "width:125px; font-size:0.70em;">
	</cfif>
<cfelse><!---<cfif kendoTheme contains 'material'>--->
	<cfif session.isMobile>
		<cfset kendoButtonStyle = "width:90px; font-size:0.75em;">
	<cfelse>	
		<cfset kendoButtonStyle = "width:125px; font-size:0.875em;">
	</cfif>
</cfif><!---<cfif kendoTheme contains 'material'>--->
</cfsilent>
					<script>
						// Invoked when the submit button is clicked. Instead of using '$("form").submit(function(event) {' and 'event.preventDefault();', We are using direct binding here to speed up the event.
						var subscribeSubmit = $('#subscribeSubmit');
						subscribeSubmit.on('click', function(e){      
							// Prevent any other action.
							e.preventDefault();     
							// Call the validator if the form is not valid.
							if (subscribeFormValidator.validate()) {
								// submit the form.
								// Note: when testing the ui validator, comment out the post line below. It will only validate and not actually do anything when you post.
								// alert('posting');
								subscribeToBlog();
							} else {//..if (addCommentFormValidator.validate()) {
								// Note: this is a custom library that I am using. The ExtAlertDialog is not a part of Kendo but an extension.
								$.when(kendo.ui.ExtAlertDialog.show({ title: "There are errors", message: "A valid email address is required. Please correct the highlighted fields and try again.", icon: "k-ext-warning", width: "425px", height: "140px" }) // or k-ext-error, k-ext-question
									).done(function () {
									// Do nothing
								});//..$.when(kendo.ui.ExtAlertDialog.show...
							}//..if (addCommentFormValidator.validate()) {
						});//..addCommentSubmit.on('click', function(e){ 
						
						$(document).ready(function() {
							// Note: there are no custom rules on this form. This is an empty validator.
							subscribeFormValidator = $("#subscribe").kendoValidator().data("kendoValidator");

						});//..document.ready
					</script>
					
					<cfoutput>
					#application.resourceBundle.getResource("subscribeblog")#
					<form id="subscribe" name="subscribe" action="#chr(35)#" method="post" data-role="validator">
						<!--- Note that this forms type is 'email'. This is an HTML5 attribute and it will automatically be validated. --->
						<input type="email" id="subscriberEmail" name="subscriberEmail" value="" class="k-textbox" 
							   required validationMessage="Email is required"
							   data-email-msg="Email is not valid" />
						<br/>
						<input type="button" id="subscribeSubmit" name="subscribeSubmit" value="Subscribe" class="k-button k-primary" style="<cfoutput>#kendoButtonStyle#</cfoutput>">
					</form>
					</cfoutput>
					
