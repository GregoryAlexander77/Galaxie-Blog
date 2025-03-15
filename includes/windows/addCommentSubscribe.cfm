<cfsilent>
<cfprocessingdirective pageencoding="utf-8">
<!---
	Name         : addcommentSubscribe.cfm
	Author       : Gregory Alexander 
	Created      : December 10 2018
	History      : The UI has been completely revised by Gregory. This template conbines the original addComment and subscribe templates and consolidates the features in to one template.
	Purpose		 : Adds comments and subsribes.
	Usage		 : This template requires a single argument, uiInterface. The uiInterface argument should either be 'addComment' or 'subscribe'. The inteface is essentially the same but the subscribe interface does not 		
				   require the user's name, website, and comments.
--->

<cfparam name="commenterName" default="">
<cfparam name="commenterEmail" default="">
<cfparam name="commenterWebsite" default="">
<cfparam name="comments" default="">
<cfparam name="rememberMe" default="false">
<cfparam name="subscribe" default="false">

<!---Set params--->
<cfif isDefined("cookie.blog_name")>
	<cfset commenterName = cookie.blog_name>
	<cfset rememberMe = true>
</cfif>
		
<cfif isDefined("cookie.blog_email")>
	<cfset commenterEmail = cookie.blog_email>
	<cfset rememberMe = true>
</cfif>
		
<cfif isDefined("cookie.blog_website")>
	<cfset commenterWebsite = cookie.blog_website>
	<cfset rememberMe = true>
</cfif>			
	
<cfif isDefined("URL.Id") and URL.id neq ''>
	<!--- Get the individual post ( getPostByPostId(postId, showPendingPosts, showRemovedPosts) )--->
	<cfset getPost = application.blog.getPostByPostId(URL.Id,false,false)>
		
	<!--- Set the values that we will need. Note: there should only be one element in the getPost array. --->
	<cfset postId = getPost[1]["PostId"]>
	<cfset title = getPost[1]["Title"]>
	<cfset allowComment = getPost[1]["AllowComment"]>
		
</cfif>

<!--- Set UI specific params. --->
<cfif URL.uiElement eq 'addComment'>
	<!--- I am keeping the localization labels if they exist. I may add in localization for the stuff that I coded in the next version. --->
	<cfset submitButtonLabel = "Submit Comment">
<cfelseif URL.uiElement eq 'subscribe'>
	<cfset submitButtonLabel = "Subscribe">
<cfelseif URL.uiElement eq 'contact'>
	<cfset submitButtonLabel = "Contact">
</cfif>
	
<!---Width of text forms--->
<cfif session.isMobile>
	<cfset textInputWidth = "85%">
	<cfset textAreaHeight = "100px">
<cfelse>
	<cfset textInputWidth = "55%">
	<cfset textAreaHeight = "250px">
</cfif>
		
<!--- Set the width of the button --->
<cfif session.isMobile>
	<cfset submitButtonWidth = 145>
<cfelse>
	<cfset submitButtonWidth = 125>
</cfif>
<!---The length of the first table column.--->
<cfset firstCellWidth = "20%">
	
<!---Note: we do not want duplicate doctypes, titles, and head tags here. These are already included in the layout.cfm template (ga).
This section has been completely redesigned by Gregory --->
</cfsilent>
<!---
<cfoutput>#URL.uiElement#</cfoutput>
<cfdump var="#getPost#">
--->
		
<script>
	$(document).ready(function() {
		
		<!---// Kendo's open source version does not support the editor
		<cfif application.kendoCommercial>
		// Editor widget ******************************************************************************************************
			
		// create Editor from textarea HTML element with default set of tools
		$("#comments").kendoEditor({ resizable: {
			content: true,
			toolbar: true,
		},
		tools: [
				"bold",
				"italic",
				"underline",
				"strikethrough",
				"justifyLeft",
				"justifyCenter",
				"justifyRight",
				"justifyFull",
				"insertUnorderedList",
				"insertOrderedList",
				"indent",
				"outdent",
				"createLink",
				"unlink",
				"insertImage",
				"insertFile",
				"viewHtml",
				"formatting",
				"cleanFormatting",
				"fontName",
				"fontSize",
				"foreColor",
				"backColor",
				"print"
			]
		});
		</cfif>
		--->
		
		// Mvvm logic.
		// Create an observable model. The model will be used to bind this template to the body of the page. It is not referenced in the UI.
	    var captchaTextUiModel = kendo.observable({
			// This was a bit tricky when I first coded something like this years ago. The captchaTextUi is a js object that references the datasource. In the datasource, I have to have a name for the datasource in order to refresh the datasource when I want the contents dynamically changes (in this case, on the reloadCaptcha js method). 
			// The captchaTextObj is referenced as the 'source' in the tbody bind.  
			captchaTextObj: captchaTextDs = new kendo.data.DataSource({
			  transport: {
				read:  {
					url: "<cfoutput>#application.baseUrl#</cfoutput>/common/cfc/ProxyController.cfc?method=getCaptchaAsJson", // the cfc component which processes the query and returns a json string. 
					dataType: "json", // Use json if the template is on the current server. If not, use jsonp for cross domain reads.
					method: "post" // Note: when the method is set to "get", the query will be cached by default. This is not ideal. 
				},//..read
			  },//..transport
			  schema: {
				model: {
				  fields: {
					captchaHash: { type: "string" },
					captchaImageUrl: { type: "string" }
				  }
				}
			  },
			  serverPaging: true
	  		})
	  	});
		
		// Apply the MVVM-style binding. The model is bound to the client here.
	  	kendo.bind(document.body, captchaTextUiModel);
		
		// Validation.
		// NEW Was the post button clicked? We need to know this as the user can fill out the form, and if it validated, it will go ahead and post the form prior to the user clicking on the post button. This is due to having two exit points out of the validater. 
		sessionStorage.setItem("postButtonClicked", "false");
		// Preset our sessionStorage var. This is set to '' initially to indicate that server side validation has not yet occurred.
		sessionStorage.setItem("captchaValidated", "");
		// Set the initial value of the captchaValidatedValue form element. We need to store this in order to know when to hit the server with a new validation request. We don't  want to hit the server 3 times a second unless the text value has actually changed.
		sessionStorage.setItem("captchaValidatedValue", "");
		// Since the kendo validator occurs so quickly, it may send an erroneous value to the server the a few times before it picks up the new value that was entered. We need to allow several attempts to occur when we hit the server. This is a numeric value that will be incremented.
		sessionStorage.setItem("captchaValidatedAttempts", "0");
		
		// Invoked when the submit button is clicked. Instead of using '$("form").submit(function(event) {' and 'event.preventDefault();', We are using direct binding here to speed up the event.
		var addCommentSubmit = $('#addCommentSubmit');
		addCommentSubmit.on('click', function(e){      
			// Prevent any other action.
			e.preventDefault();   
			// NEW Store that this button was clicked.
			sessionStorage.setItem("postButtonClicked", "true");
			// Set the attempts var to 0
			sessionStorage.setItem("captchaValidatedAttempts", 0);
			// Note: when using server side logic, this function may not post the data to the server due to the time required to return the validation from the server. 
			// If the form has been successfully validated.
			if (addCommentFormValidator.validate()) {
				// Submit the form. We need to have a quick timeout function as the captcha resonse does not come back for 150 milliseconds.
				setTimeout(function () {
					// Note: when testing the ui validator, comment out the post line below. It will only validate and not actually do anything when you post.
					postCommentSubscribe(<cfoutput>'#URL.Id#'</cfoutput>, <cfoutput>'#URL.uiElement#'</cfoutput>);
				}, 300);//..setTimeout(function () {
			}//..if (addCommentFormValidator.validate()) {
		});//..addCommentSubmit.on('click', function(e){ 
		
		// !!! Note on the validators, all forms need a name attribute, otherwise the positioning of the messages will not work. Also data attributes that are dash separated become camel cased when retrieved using jQuery. --->
		addCommentFormValidator = $("#addCommentSubscribe").kendoValidator({
			// Set up custom validation rules 
			rules: {
				// Name of custom rule. 
				// This can be any name, but I typically put the name of the field and a verb to indicate what I am enforcing ('nameIsRequired'). Note: if you just want to check to see if something was entered you can specify 'required' in the form element.
				commenterName:
				function(input){
					// Trigger by the input name and set up the logic that must be enforced. Note: you can make the logic as long as you want, but I typically apply a new rule for every discreet thing that I want to enforce in order to specify a unique message. The choice is up to you.
					if (input.is("[id='commenterName']") && $.trim(input.val()).length < 6){
						// Display an error on the page. Currently, I am using 'validationMessage' as the common rule in the HTML, however, I used to use a different approach. I used to use input.attr 'data-' + name of custom rule + 'required-msg'. This will embed the custom message in the data-required-msg field on the form when there are errors. You can spedify as many rules as you want to on the form in order to show several messages at once. Remember that the data attributes that are dash separated become camel cased when retrieved using jQuery. For example, the string 'data-commenterNameRequired-msg' will be inserted into the following attribute: 'data-required-msg'. I am not sure why the rule name is inserted into this data-attr, but it is, and can be confusing at first. 
						input.attr("validationMessage", "Your name is required and must have at least 6 characters.");
						// Focus on the current element
						$( "#commenterName" ).focus();
						// Abort processing the next rule.
						return false;
					} 
					// Continue processing to the next rule.
					return true;
				},//..function(input){
				commenterNameNotNumeric:
				function(input){
					if (input.is("[id='commenterName']") && $.isNumeric(input.val())){
						// Display an error on the page.
						input.attr("data-commenterNameNotNumeric-msg", "Your name can't be numeric.");
						// Focus on the current element
						$( "#commenterName" ).focus();
						// Abort processing the next rule.
						return false;
					}  
					// Continue processing to the next rule.
					return true;
				},//..function(input){
				// Email and website are aready validated on the client side. Both fields can be validated with the HTML 5 specification. 
				// This rule is quite different as it relies upon server side processing. I used https://www.telerik.com/blogs/extending-the-kendo-ui-validator-with-custom-rules as an example to build this.
				captcha: 
					function(input) {
						if (input.is("[id='captchaText']")){
							// The captchaValidated value is set in storage session and set in the function below. Note, until the form loses focus, this function is constantly being validated until validation passes. Be careful not to go into an endless loop without exits.
							var captchaValidated = getCapthchaValidated();
							
							// If the captcha has not been validated on the server...
							if (captchaValidated == ''){
								// Check the captcha
								captchaText.check(input);
								// And stop...
								return false;
							}
							
							// If the server validation failed, try again...
							if (captchaValidated == 'no'){
								// Check the captcha
								captchaText.check(input);
								// And stop...
								return false;
							}	
							
							if (captchaValidated == 'yes'){
								// The captha text was succuessfully validated. Exit this function. 
								return true;
							}
						}//..if (input.is("[id='captchaText']")){
						// This rule does not apply to the captha text input.
						return true;
					}//..function(input) {
				}
			//..captcha:
		}).data("kendoValidator");
		
		// Create a variable for this function as we will use the properties in the captcha validation function above when it returns results.
		var captchaText = {
			check: function(element) {
				
				// Note: the validator will fire off a new request 3 times a second, and we need to make sure that we are not hitting the server with stale data every time. We are going to see if the value has changed before firing off a new request to the server.
				// Compare the input value to the value that was stored in sessionStorage. If the data has changed, and there has been fewer than 5 validation attempts that have failed, hit the server.
				if (element.val() != getCapthchaValidatedValue() || getCaptchaValidatedAttempts() <= 5){
					// Post to the server side method that will validate the captcha text.
					$.ajax({
						url: "<cfoutput>#application.proxyControllerUrl#</cfoutput>?method=validateCaptcha",
						dataType: 'json', // Use json for same domain posts. Use jsonp for crossdomain. 
						data: { 
							// Send in the arguments.
							captchaText: element.val(), 
							captchaHash: $( "#captchaHash" ).val()
						},
						success: function(data) { // The `data` object is a boolean value that is returned from the server.
							var captchaValidated = getCapthchaValidated();
							if (data){
								// debugging alert('Yes!');
								// Set the value on the cache object so that it can be referenced in the next validation run. Note: sessionStorage can only store strings.
								sessionStorage.setItem("captchaValidated", "yes");
								// At the tail end of the validation process, when the validated data is complete, post the data. Since we have passed validation, we don't  need to hit the 'captcha' custom rule above again.
								if (addCommentFormValidator.validate()) {
									// Hide the custom window message
									kendo.ui.ExtAlertDialog.hide;
									// NEW Check to see if the post button was clicked before allowing this function to post the page.
									if (wasPostButtonClicked() == 'true'){
										// Submit the form. We need to have a quick timeout function as the captcha resonse does not come back for 150 milliseconds.
										setTimeout(function () {
											// Note: when testing the ui validator, comment out the post line below. It will only validate and not actually do anything when you post.
											postCommentSubscribe(<cfoutput>'#URL.Id#'</cfoutput>, <cfoutput>'#URL.uiElement#'</cfoutput>);
										}, 300);//..setTimeout(function () {
									}//..if (wasPostButtonClicked()){
								}//..if (addCommentFormValidator.validate()) {
							} else {
								// Get the number of validation attempts.
								var captchaValidatedAttempts = getCaptchaValidatedAttempts();
								// Increment the validation attempt.
								var currentCaptchaValidatedAttempt = (captchaValidatedAttempts + 1);
								// Store the number of validation attempts in sessionStorage.
								sessionStorage.setItem("captchaValidatedAttempts", currentCaptchaValidatedAttempt);
								// After the 5th bad attempt, set the validation var and use a quick set timeout in order for the data to come back and be validated on the server before launching our custom error popup. Otherwise, if there was a previous captcha error from the server, this custom error will pop up as the new data has not had a chance to be returned from the server yet.
								if (currentCaptchaValidatedAttempt  == 6){
									// Store that we tried to validate, but it was not correct.
									sessionStorage.setItem("captchaValidated", "no");
									// Load a new captcha image (this is my own custom requirement and it has no bearing to the validator logic).
									reloadCaptcha();
									// Popup an error message.
									setTimeout(function() {
										if (getCapthchaValidated() == 'no'){
											// Note: this is a custom library that I am using. The ExtAlertDialog is not a part of Kendo but an extension.
											$.when(kendo.ui.ExtAlertDialog.show({ title: "The text did not match", message: "We have reloaded a new captcha image. If you're having issues with the captcha text, click on the 'new captcha' button to and enter the new text.", icon: "k-ext-warning", width: "<cfoutput>#application.kendoExtendedUiWindowWidth#</cfoutput>", height: "215px" }) // or k-ext-error, k-ext-question
												).done(function () {
												// Do nothing
											});//..$.when(kendo.ui.ExtAlertDialog.show...
										}//..if (addCommentFormValidator.validate()) {
									}, 250);// NEW A quarter of a second should allow the server to validate the captcha and return the result.
								}
							}
							// Store the validated value. We will use this to determine when to hit the server for validation again if the value was not correctly typed in.
							sessionStorage.setItem("captchaValidatedValue", element.val());
							// Trigger the validation routine again. We need to validate each time, even if the value is validated on the server as we need to eliminate the error message raised in the validation script and will be popped up when the form loses focus on the onBlue event.
							setTimeout(function() {
								addCommentFormValidator.validate();
							}, 2000);// Wait 2 seconds to hit the server again.
						}//..success: function(data) {
						// Notes: success() only gets called if your webserver responds with a 200 OK HTTP header - basically when everything is fine. However, complete() will always get called no matter if the ajax call was successful or not. its worth mentioning that .complete() will get called after .success() gets called - if it matters to you.
					
					});//..$.ajax({
				}//..if (element.val() != getCapthchaValidatedValue()){
			}//..check: function(element, settings) {
		};//..var captchaText = {
	
	});//...document.ready
	
	// Validation helper functions. These must be oustide of the document ready block in order to work.
	// Note: due to the latency of the data coming back from the server, we need to have two points to post a completely validated form to the server for processing. The first point is when the user clicks the submit form button, and the second point is at the tail end of the processing when the server has validated data. 
		
	// I am using sessionStorage to store the value from the server in order to effect the captach widget that I developed. I don't  want to have to ask the user to go thru the captha validation process multiple times within the same session and don't want to have to write out the logic every time.
	// NEW Determine if the post button was clicked.
	function wasPostButtonClicked(){
		return sessionStorage.getItem("postButtonClicked");
	}
	
	function getCapthchaValidated(){
		return sessionStorage.getItem("captchaValidated");
	}
	
	// Prior to validation, what did the user enter?
	function getCapthchaValidatedValue(){
		// Since sessionStorage only stores strings reliably, this will be either: '', 'no', or 'yes'.
		return sessionStorage.getItem("captchaValidatedValue");
	}
	
	// Returns the number of attempts that the server tried to validate the data. This only gets incremented when the server comes back with a false (not validated).
	function getCaptchaValidatedAttempts(){
		var attemps = sessionStorage.getItem("captchaValidatedAttempts");
		return(parseInt(attemps));
	}
		
	function reloadCaptcha(){
		// Reload the datasource that populates data in the Kendo template. This will essentially grab the data from the server and populate the captcha hash reference and image again.
		captchaTextDs.read();
		// Open the plese wait window. Note: the ExtWaitDialog's are mine and not a part of the Kendo official library. I designed them as I prefer my own dialog design over Kendo's dialog offerings.
		$.when(kendo.ui.ExtWaitDialog.show({ title: "Please wait...", message: "Please wait while the data loads.", icon: "k-ext-information" }));
		// Use a quick set timeout in order for the data to load.
		setTimeout(function() {
			// Close the wait window that was launched in the calling function.
			kendo.ui.ExtWaitDialog.hide();
		}, 500);
		// Return false in order to prevent any potential redirection.
		return false;
	}//..function reloadCaptcha(){
	
	function addCommentReset(){
		// Note: this is a custom library that I am using. The ExtAlertDialog is not a part of Kendo but an extension.
		 $.when(kendo.ui.ExtYesNoDialog.show({ // Alert the user and ask them if they want to refresh the grid
			title: "Are you sure that you want to cancel?",
			message: "You will lose any data that you entered.",
			icon: "k-ext-warning",
		 	width: "<cfoutput>#application.kendoExtendedUiWindowWidth#</cfoutput>", 
			height: "215px"
		 })
		).done(function (response) { // If the user clicked 'yes', refresh the grid.
			if (response['button'] == 'Yes'){// remember that js is case sensitive.
				// Close the window
				closeAddCommentSubscribeWindow();
			}
		});
	}		

</script>
<cfsilent>
<!--- Notes: this form serves two purposes, 1) to make a comment, 2) and to subscribe. It has separate interfaces for 1) the desktop web application, 2) and an interface for mobile. The desktop design puts the label to the right of the form, and the mobile puts the label on a separate row above the form. --->
</cfsilent>
<!-- Notes: 
1) Kendo generally requires that the form is outside of the container.
2) The Kendo window is not responsive, and has its own internal properties that are hardcoded, so I need to reset properties using inline styles, such as font-size.
-->
<form id="addCommentSubscribe" name="addCommentSubscribe" action="addCommentSubscribe.cfm" method="post" data-role="validator">
<table align="center" class="k-content" width="100%" cellpadding="0" cellspacing="0" style="font-size: 16px;">
	<cfif URL.uiElement neq 'contact'>
		<!--- Hidden form elements to pass in required vars --->
		<input type="hidden" id="postTitle" name="postTitle" value="<cfoutput>#title#</cfoutput>" />
	</cfif>
	<cfif URL.uiElement eq 'contact' or allowComment>
	<cfsilent>
		<!--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
		Mobile design 
		--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------->
	</cfsilent>
	<cfif session.isMobile>
		<cfoutput>
	<cfif URL.uiElement neq 'subscribe'>
		<!-- Name -->
		<tr class="k-content">
			<td>
				<label for="commenterName">Name:</label>
			</td>
		</tr>
		<tr class="k-content">
			<td>
				<!--- Important note: when using Kendo and Ajax, all forms should have both an ID and a name attribute! --->
				<input type="text" id="commenterName" name="commenterName" value="#commenterName#" class="k-textbox" style="width: <cfoutput>#textInputWidth#</cfoutput>;" required validationMessage="Enter your name." />
			</td>
		</tr>
		<!-- Border and spacer. -->
		<tr>
			<td height="5px"></td>
		</tr>
		<tr>
			<td class="border"></td>
		</tr>
		<tr class="<cfif URL.uiElement neq 'subscribe'>k-alt<cfelse>k-content</cfif>">
			<td height="5px"></td>
		</tr>
	</cfif><!---<cfif URL.uiElement neq 'subscribe'>--->
		<!-- Email -->
		<tr class="<cfif URL.uiElement neq 'subscribe'>k-alt<cfelse>k-content</cfif>">
			<td>
				<label for="commenterEmail">Email:</label>
			</td>
		</tr>
		<tr class="<cfif URL.uiElement neq 'subscribe'>k-alt<cfelse>k-content</cfif>">
			<td>
				<!--- Note that this forms type is 'email'. This is an HTML5 attribute and it will automatically be validated. --->
				<input type="email" id="commenterEmail" name="commenterEmail" value="#commenterEmail#" class="k-textbox" 
					   required validationMessage="Enter your email." aria-label="Enter your email address"
					   style="width: <cfoutput>#textInputWidth#</cfoutput>;" />
			</td>
		</tr>
	<cfif URL.uiElement neq 'subscribe'>
		<!-- Border and spacer. -->
		<tr class="k-alt">
			<td height="5px"></td>
		</tr>
		<tr>
			<td class="border"></td>
		</tr>
		<tr>
			<td height="5px"></td>
		</tr>
		<!-- Comments -->
		<tr height="35px" class="k-content">
			<td>
				<label for="comments">Comment:</label>
			</td>
		</tr>
		<tr height="35px" class="k-content">
			<td>
				<textarea name="comments" id="comments" rows="5" cols="25" style="height: #textAreaHeight#; width:<cfoutput>#textInputWidth#</cfoutput>; font-family: 'Arial', Lucida Grande', 'Lucida Sans Unicode', 'Lucida Sans', 'DejaVu Sans', Verdana, 'sans-serif'" required validationMessage="Enter comment."></textarea>
			</td>
		</tr>
	</cfif><!---<cfif URL.uiElement neq 'subscribe'>--->
		<!-- Border and spacer. -->
		<tr class="k-content">
			<td height="5px"></td>
		</tr>
		<tr>
			<td class="border"></td>
		</tr>
		<tr class="k-alt">
			<td height="5px"></td>
		</tr>
		</cfoutput>
		<cfif ( application.useCaptcha and not application.Udf.isLoggedIn() ) or 1 eq 1>
		<!-- Captcha -->
		<tr height="35px" class="k-alt">
			<td>
				<!--- Captcha logic in its own table. This is a Kendo Mvvm template.  --->
				<div id="captchaImage" class="k-alt">
					<table align="left" class="k-alt" width="100%" cellpadding="0" cellspacing="0">
						<!--- The source refers to the javascript code that will be used to populate the control, the template is the UI and it is not associated with the javascript code. --->
						<tbody data-bind="source: captchaTextObj" data-template="captchaTemplate" data-visible="true"></tbody>
					</table>
					<!---Create a Kendo template. We will use this to refresh the captcha hash and image on the page.--->
					<script type="text/x-kendo-template" id="captchaTemplate">
						<tr class='k-alt'>
							<td><label for="captchaText">Enter image text:</label></td>
						</tr>
						<tr class='k-alt'>
							<td>
							<input type="hidden" id="captchaHash" name="captchaHash" value="#: captchaHash #" />
							<input type="text" name="captchaText" id="captchaText" size="6" class="k-textbox" style="width: 250px" 
								placeholder="Enter Captcha Text" required 
								data-required-msg="Captcha text is required." 
								data-captcha-msg="The text does not match." />
							</td>
						</tr>
						<tr class='k-alt'>
							<td>
								<img src="#: captchaImageUrl #" alt="Captcha" align="left" vspace="5" border="1" />
							</td>
						</tr>
						<tr class='k-alt'>
							<td>
								<button type="button" class="k-button" onClick="reloadCaptcha()">
									<i class="fas fa-redo" style="alignment-baseline:middle;"></i>&nbsp;&nbsp;New Captcha
								</button>
							</td>
						</tr>	
					</script>
				</div><!---<div id="captchaImage" class="k-alt">--->
			</td>
		</tr>
		</cfif><!---<cfif application.useCaptcha and not application.Udf.isLoggedIn()>--->	
		<!-- Border and spacer. -->
		<tr class="k-alt">
			<td height="5px"></td>
		</tr>
		<tr>
			<td class="border"></td>
		</tr>
		<tr  class="k-content">
			<td height="5px"></td>
		</tr>
		<cfoutput>
		<!-- Checkboxes -->
		<tr class="k-content">
			<td>
				<input type="checkbox" id="rememberMe" name="rememberMe" value="1" <cfif URL.uiElement eq 'subscribe' or (isBoolean(rememberMe) and rememberMe)>checked="checked"</cfif> /> <label for="rememberMe">Remember me</label>
			</td>
		</tr>
	<cfif URL.uiElement neq 'contact'>
		<tr class="k-content">
			<td>
				<input type="checkbox" id="subscribe" name="subscribe" aria-label="Subscribe" value="1" <cfif uiElement eq 'subscribe' or (isBoolean(subscribe) and subscribe)>checked="checked"</cfif> /> <label for="subscribe">Subscribe</label>
			</td>
		</tr>
	</cfif><!---<cfif URL.uiElement neq 'contact'>--->
		<!-- Border and spacer. -->
		<tr class="k-content">
			<td height="5px"></td>
		</tr>
		<tr>
			<td class="border"></td>
		</tr>
		<tr class="k-alt">
			<td height="5px"></td>
		</tr>
		<!-- Buttons -->
		<tr height="35px" class="k-alt">
			<td>
				<!--- Note: the onclick event is defined in the javascript on this page. --->
				<input id="addCommentSubmit" name="addCommentSubmit" value="#submitButtonLabel#" class="k-button k-primary" style="width: #submitButtonWidth#px;" />
				<input type="reset" id="reset" value="Cancel" class="k-button" onClick="addCommentReset();"  style="width: #submitButtonWidth#px;" />
				<!---
				<input type="close" id="close" value="close" class="k-button" onClick="closeAddCommentSubscribeWindow();"  style="width: #submitButtonWidth#px;" />
				--->
			</td>
		</tr>
		</cfoutput>
		<tr>
			<td class="border"></td>
		</tr>
	<cfsilent>
		<!--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
		Desktop design 
		--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------->
	</cfsilent>
	<cfelse>
	<cfoutput>
	<cfif URL.uiElement neq 'subscribe'>
		<tr height="35px" class="k-content">
			<td align="right" width="<cfoutput>#firstCellWidth#</cfoutput>">
				<label for="commenterName">Name:</label>
			</td>
			<td width="5px"></td>
			<td align="left" width="*">
				<!---Important note: when using Kendo and Ajax, all forms must have both an ID and a name attribute!--->
				<input type="text" id="commenterName" name="commenterName" value="#commenterName#" class="k-textbox" style="width: <cfoutput>#textInputWidth#</cfoutput>;" 
					   required data-required-msg="Enter your name." />
			</td>
		</tr>
	</cfif><!---<cfif URL.uiElement neq 'subscribe'>--->
		<tr height="35px" class="k-content">
			<td align="right" width="<cfoutput>#firstCellWidth#</cfoutput>px">
				<label for="commenterEmail">Email:</label>
			</td>
			<td width="5px"></td>
			<td align="left">
				<!--- Note that this forms type is 'email'. This is an HTML5 attribute and it will automatically be validated. --->
				<input type="email" id="commenterEmail" name="commenterEmail" value="#commenterEmail#" class="k-textbox" required validationMessage="Enter your email." aria-label="Enter your email address" style="width: <cfoutput>#textInputWidth#</cfoutput>;" />
			</td>
		</tr>
	<cfif URL.uiElement neq 'subscribe'>
		<tr height="35px" class="k-content">
			<td align="right" width="<cfoutput>#firstCellWidth#</cfoutput>">
				<label for="commenterWebSite">Website:</label>
			</td>
			<td width="5px"></td>
			<td align="left">
				<!---Note: URL is HTML5 validated if the type is URL.--->
				<input type="url" id="commenterWebSite" name="commenterWebSite" value="#commenterWebsite#" class="k-textbox" style="width: <cfoutput>#textInputWidth#</cfoutput>;" />
			</td>
		</tr>
	</cfif><!---<cfif URL.uiElement neq 'subscribe'>--->
		<tr>
			<td colspan="3" height="5px"></td>
		</tr>
		<tr>
			<td class="border" colspan="3"></td>
		</tr>
	<cfif URL.uiElement neq 'subscribe'>
		<tr>
			<td colspan="3" height="5px" class="k-alt"></td>
		</tr>
		<tr height="35px" class="k-alt">
			<td align="right" width="<cfoutput>#firstCellWidth#</cfoutput>">
				<label for="comments">Comment:</label>
			</td>
			<td width="5px"></td>
			<td align="left">
				<textarea name="comments" id="comments" rows="5" cols="45" style="height:250px; width:66%;" required 
						  validationMessage="Enter comments."></textarea>
			</td>
		</tr>
	</cfif><!---<cfif URL.uiElement neq 'subscribe'>--->
		</cfoutput>
		<cfif ( application.useCaptcha and not application.Udf.isLoggedIn() )>
		<tr class="k-alt">
			<td colspan="3" align="left">
				<!--- Captcha logic in its own table. This is a Kendo Mvvm template.  --->
				<div id="captchaImage" class="k-alt">
					<table align="left" class="k-alt" width="100%" cellpadding="0" cellspacing="0">
						<!--- The source refers to the javascript code that will be used to populate the control, the template is the UI and it is not associated with the javascript code. --->
						<tbody data-bind="source: captchaTextObj" data-template="captchaTemplate" data-visible="true"></tbody>
					</table>
					<!---Create a Kendo template. We will use this to refresh the captcha hash and image on the page.--->
					<script type="text/x-kendo-template" id="captchaTemplate">
					 <tr height="35px" class='k-alt'>
						<td align="right" width="<cfoutput>#firstCellWidth#</cfoutput>"><label for="captchaText">Enter image text:</label></td>
						<td width="5px"></td>
						<td align="left" width="*">
						<input type="hidden" id="captchaHash" name="captchaHash" value="#: captchaHash #" />
						<input type="text" name="captchaText" id="captchaText" size="6" class="k-textbox" style="width: 250px" 
							placeholder="Enter Captcha Text" required 
							data-required-msg="Captcha text is required." 
							data-captcha-msg="The text does not match." />
						</td>
					</tr>
					<tr class='k-alt'>
						<td align="right"></td>
						<td></td>
						<td align="left">
							<img src="#: captchaImageUrl #" alt="Captcha" align="left" vspace="5" border="1" />
						</td> 
					</tr>
					<tr class='k-alt'>
						<td align="right"></td>
						<td></td>
						<td>
							<button type="button" class="k-button" onClick="reloadCaptcha()">
								<i class="fas fa-redo" style="alignment-baseline:middle;"></i>&nbsp;&nbsp;New Captcha
							</button>
						</td>
					</tr>
				 </script>
				</div><!---<div id="captchaImage" class="k-alt">--->
			</td>
		</tr>
		</cfif><!---<cfif application.useCaptcha and not application.Udf.isLoggedIn()>--->
		<cfoutput>
		<tr>
			<td colspan="3" height="5px" class="k-alt"></td>
		</tr>
		<tr>
			<td class="border" colspan="3" class="k-alt"></td>
		</tr>
		<tr>
			<td colspan="3" height="5px"></td>
		</tr>
		<tr height="35px" class="k-content">
			<td align="right" width="<cfoutput>#firstCellWidth#</cfoutput>"></td>
			<td></td>
			<td>
				<input type="checkbox" id="rememberMe" name="rememberMe" value="1" <cfif URL.uiElement eq 'subscribe' or (isBoolean(rememberMe) and rememberMe)>checked="checked"</cfif> /> <label for="rememberMe">Remember me</label>
			</td>
		</tr>
	<cfif URL.uiElement neq 'contact'>
		<tr  height="35px" class="k-content">
			<td align="right" width="<cfoutput>#firstCellWidth#</cfoutput>"></td>
			<td></td>
			<td>
				<input type="checkbox" id="subscribe" name="subscribe" aria-label="Subscribe" value="1" <cfif uiElement eq 'subscribe' or (isBoolean(subscribe) and subscribe)>checked="checked"</cfif> /> <label for="subscribe">Subscribe</label>
			</td>
		</tr>
	</cfif><!---<cfif URL.uiElement neq 'contact'>--->
		<tr>
			<td colspan="3" height="5px"></td>
		</tr>
		<tr>
			<td class="border" colspan="3"></td>
		</tr>
		<tr class="k-alt">
			<td colspan="3" height="5px"></td>
		</tr>
		<tr height="35px" class="k-alt">
			<td width="<cfoutput>#firstCellWidth#</cfoutput>"></td>
			<td></td>
			<td>
				<!--- Note: the onclick event is defined in the javascript on this page. --->
				<input id="addCommentSubmit" name="addCommentSubmit" value="#submitButtonLabel#" class="k-button k-primary" style="width: #submitButtonWidth#px;" />
				<input type="reset" id="reset" value="Cancel" class="k-button" onClick="addCommentReset();"  style="width: #submitButtonWidth#px;" />
				<!---
				<input type="close" id="close" value="close" class="k-button" onClick="closeAddCommentSubscribeWindow();"  style="width: #submitButtonWidth#px;" />
				--->
			</td>
		</tr>
		<tr class="k-alt">
			<td colspan="3" height="5px"></td>
		</tr>
		<tr class="k-alt">
			<td class="border" colspan="3"></td>
		</tr>
		</cfoutput>
	</cfif>
	<cfelse><!---<cfif allowComment>--->
		<cfoutput>
		<p>Comments are not allowed</p>
		</cfoutput>
	</cfif><!---<cfif allowComment>--->
</table>
</form>
