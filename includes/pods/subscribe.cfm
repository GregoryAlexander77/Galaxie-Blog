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
			
<!--- Set the name of the form and the text element. This template is used in two different places and I want to have unique element id's. --->
<cfif sideBarType eq "div">
	<cfset subscribeFormId = "subscribeViaDiv">
<cfelse>
	<cfset subscribeFormId = "subscribeViaPanel">
</cfif>
	
<!--- Cache notes: this is too complex, and it is unecessary to use caching as this opens up a window and the code will not load until the window is opened. --->

</cfsilent>
				
					<script type="<cfoutput>#scriptTypeString#</cfoutput>">
						// Invoked when the submit button is clicked. Instead of using '$("form").submit(function(event) {' and 'event.preventDefault();', We are using direct binding here to speed up the event.
						var subscribeSubmit = $('#<cfoutput>#subscribeFormId#Submit</cfoutput>');
						subscribeSubmit.on('click', function(e){   
							// Prevent any other action.
							e.preventDefault();     
							// Call the validator if the form is not valid.
							if (<cfoutput>#subscribeFormId#</cfoutput>FormValidator.validate()) {
								// submit the form.
								// Note: when testing the ui validator, comment out the post line below. It will only validate and not actually do anything when you post.
								//alert('posting');
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
						<input type="email" id="#subscribeFormId#" name="#subscribeFormId#" value="" class="k-textbox" 
							required validationMessage="Email is required"
							data-email-msg="Email is not valid" />
						<br/>
						<input type="button" id="#subscribeFormId#Submit" name="#subscribeFormId#Submit" value="Subscribe" class="k-button k-primary" style="<cfoutput>#kendoButtonStyle#</cfoutput>">
					</form>
					</cfoutput>
