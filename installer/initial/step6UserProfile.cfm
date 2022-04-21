<html lang="en-US"><head> <title>Your Profile</title>
<cfsilent>
<!--- We are storing the info in the session as the user may click on the back button or try again. --->
<cfif isDefined("session.firstName")>
	<cfset firstName = session.firstName>
	<cfset lastName = session.lastName>
	<cfset email = session.email>
	<cfset website = session.website>
	<cfset userName = session.userName>
	<cfset password = session.password>
<cfelse>
	<cfset firstName = "">
	<cfset lastName = "">
	<cfset email = "">
	<cfset website = "">
	<cfset userName = "">
	<cfset password = "">
</cfif>
	
<cfif isDefined("session.profileDisplayName")>
	<cfset profileDisplayName = session.profileDisplayName>
<cfelse>
	<cfset profileDisplayName = "">
</cfif>

<cfif isDefined("session.securityAnswer1") and isDefined("session.securityAnswer2") and isDefined("session.securityAnswer3")>
	<cfset securityAnswer1 = session.securityAnswer1>
	<cfset securityAnswer2 = session.securityAnswer2>
	<cfset securityAnswer3 = session.securityAnswer3>
<cfelse>
	<cfset securityAnswer1 = "">
	<cfset securityAnswer2 = "">
	<cfset securityAnswer3 = "">	
</cfif>
	
</cfsilent>
<meta http-equiv="content-type" content="text/html; charset=utf-8" />
<meta name="viewport" content="width=device-width, initial-scale=1">
<meta name="title" content="Welcome to Galaxie Blog" />
<cfsilent>
<cfparam name="kendoTheme" default="default">
</cfsilent>
<html>
<head>
    <style>html { font-size: 14px; font-family: Arial, Helvetica, sans-serif; }</style>
    <title></title>
    <link rel="stylesheet" href="https://kendo.cdn.telerik.com/2020.3.1021/styles/kendo.common.min.css" />
	<!--- Attach the style for the theme --->
	<a href=""></a>
    <cfoutput>
	<link rel="stylesheet" href="../../common/libs/kendoCore/styles/kendo.#kendoTheme#.min.css" />
    <link rel="stylesheet" href="../../common/libs/kendoCore/styles/kendo.#kendoTheme#.mobile.min.css" />
	</cfoutput>

    <script src="../../common/libs/kendoCore/js/jquery.min.js"></script>
    <script src="../../common/libs/kendoCore/js/kendo.ui.core.min.js"></script>
	
	<script type="text/javascript" src="../../common/libs/momentJs/moments.js"></script>
</head>
<style>
	
	/* Table classes */
	/* Applies a border on the outside of the table */
	table.tableBorder {
		border: 1px solid black;
		width: 100%;
		border-radius: 3px; 
		border-spacing: 0;
	}
	
	td.border {
		border-top: 1px solid #ddd;
	}
	
	label {
		font-weight: 400;
	}
	
	p {
		font-weight: 400;
	}
</style>
<body>
<script src="//cdnjs.cloudflare.com/ajax/libs/jszip/2.4.0/jszip.min.js"></script>

<form action="step7Post.cfm" name="userProfileForm" id="userProfileForm" method="post">
<table align="center" class="k-content tableBorder" width="100%" cellpadding="5" cellspacing="5">
	<tr>
		<td>
			<table align="center" class="k-content" width="100%" cellpadding="2" cellspacing="0">
			  <!-- Border -->
			  <tr height="2px">
				  <td align="left" valign="top" colspan="2" class="k-header border"></td>
			  </tr>
			  <tr>
				  <td align="left" valign="top" colspan="2" class="k-header" style="font-weight: bold">
					User Profile<br/>
					(Step 6 of 6)
				  </td>
			  </tr>
			  <!-- Border -->
			  <tr height="2px">
				  <td align="left" valign="top" colspan="2" class="k-content border"></td>
			  </tr>
			  <tr>
				  <td style="width:400px">
				  	<img src="../images/userProfile.jpg" alt="Welcome!" style="float: left; padding:5px;">
				  </td>
				  <td align="left" valign="top">
					  
					  <table align="center" class="k-content" width="100%" cellpadding="2" cellspacing="0">
						<!-- Border -->
					    <tr height="2px">
						  	<td align="left" valign="middle" colspan="2" class="k-content border"></td>
					    </tr>
						<tr>
							<td></td>
							<td align="left" style="vertical-align:middle">
							  Before we continue, you must create a user profile. Please fill out all of the form fields and click submit.
							</td>
						</tr>
						<!-- Border -->
					    <tr height="2px">
						  	<td align="left" valign="middle" colspan="2" class="k-content border"></td>
					    </tr>
						<tr>
							<td align="right" valign="middle" style="width:175px;vertical-align:middle">
								<label for="firstName">First Name</label>
							</td>
							<td align="left" style="vertical-align:middle">
							  <input id="firstName" name="firstName" type="text" value="<cfoutput>#firstName#</cfoutput>" required validationMessage="First Name is required" class="k-textbox" style="width: 66%" />    
							</td>
						</tr>
						<!-- Border -->
					    <tr height="2px">
						  	<td align="left" valign="middle" colspan="2" class="k-alt border"></td>
					    </tr>
					    <tr valign="middle" height="30px">
						  <td align="right" valign="middle" width="10%" class="k-alt">
							<label for="lastName">Last Name</label>
						  </td>
						  <td align="left" width="90%" class="k-alt">
							<input id="lastName" name="lastName" type="text" value="<cfoutput>#lastName#</cfoutput>" required validationMessage="Last Name is required" class="k-textbox" style="width: 66%" /> 
						  </td>
					    </tr>
						<!-- Border -->
					    <tr height="2px">
						  	<td align="left" valign="middle" colspan="2" class="k-content border"></td>
					    </tr>
					    <tr valign="middle" height="30px">
						  <td align="right" valign="middle" width="10%" class="k-content">
							<label for="profileDisplayName">Public Display Name</label>
						  </td>
						  <td align="left" width="90%" class="k-content">
							<input id="profileDisplayName" name="profileDisplayName" type="text" value="<cfoutput>#profileDisplayName#</cfoutput>" class="k-textbox" style="width: 66%" /> 
						  </td>
					    </tr>
						<!-- Border -->
					    <tr height="2px">
						  	<td align="left" valign="middle" colspan="2" class="k-content border"></td>
					    </tr>
						<tr valign="middle" height="30px">
						  <td align="right" valign="middle" class="k-content">
							<label for="email">Email</label>
						  </td>
						  <td align="left" class="k-content">
							<input id="email" name="email" type="email" value="<cfoutput>#email#</cfoutput>" required validationMessage="Email is required" class="k-textbox" style="width: 66%" /> 
						  </td>
					    </tr>
						<!-- Border -->
					    <tr height="2px">
						  	<td align="left" valign="middle" colspan="2" class="k-alt border"></td>
					    </tr>
					    <tr valign="middle" height="30px">
						  <td align="right" valign="middle" width="10%" class="k-alt">
							<label for="website">Website</label>
						  </td>
						  <td align="left" width="90%" class="k-alt">
							<input id="website" name="website" type="url" value="<cfoutput>#website#</cfoutput>" class="k-textbox" style="width: 66%" /> 
						  </td>
					    </tr>
						<!-- Border -->
					    <tr height="2px">
						  	<td align="left" valign="middle" colspan="2" class="k-content border"></td>
					    </tr>
						<tr valign="middle" height="30px">
						  <td align="right" valign="middle" class="k-content">
							<label for="userName">User Name</label>
						  </td>
						  <td align="left" class="k-content">
							<input id="userName" name="userName" type="text" value="<cfoutput>#userName#</cfoutput>" required validationMessage="Username is required" autocomplete="username" class="k-textbox" style="width: 35%" />  
						  </td>
					    </tr>
						<!-- Border -->
					    <tr height="2px">
						  	<td align="left" valign="middle" colspan="2" class="k-alt border"></td>
					    </tr>
						<!-- Border -->
					    <tr height="2px">
							<td class="k-alt"></td>
						  	<td align="left" valign="middle" colspan="2" class="k-alt">
								<p>Note: your password must contain one special character and be at least 8 characters in length.</p>
							</td>
					    </tr>
						<!-- Border -->
					    <tr height="2px">
						  	<td align="left" valign="middle" colspan="2" class="k-alt border"></td>
					    </tr>
						<tr valign="middle" height="30px" class="k-alt">
						  <td align="right" valign="middle" class="k-conalttent">
							<label for="password">Password</label>
						  </td>
						  <td align="left" class="k-alt">
							<!--- Pattern matching notes: At least one upper case English letter (?=.*?[A-Z]), at least one special character (?=.*?[#?!@$%^&*-]), and minimum eight in length .{8,} (with the anchors) --->
							<input id="password" name="password" type="password" value="<cfoutput>#password#</cfoutput>" required validationMessage="Password is required" autocomplete="new-password" placeholder="Enter Password" title="Password must be at least eight characters long" required pattern="^(.{8,})$" class="k-textbox" style="width: 66%" />
						  </td>
					    </tr>
						<!-- Border -->
					    <tr height="2px">
						  	<td align="left" valign="middle" colspan="2" class="k-alt border"></td>
					    </tr>
						<tr valign="middle" height="30px" class="k-content">
						  <td align="right" valign="middle" class="k-content">
							<label for="confirmPasword">Confirm Password</label>
						  </td>
						  <td align="left" class="k-content">
							<input id="confirmPassword" name="confirmPassword" type="password" value="<cfoutput>#password#</cfoutput>" required validationMessage="Password is required" autocomplete="new-password" placeholder="Enter Password" title="Password must be at least 8 characters long" required pattern="^(.{8,})$" class="k-textbox" style="width: 66%" data-rule-email="true" data-rule-equalTo="#email"/>
							<div id="checkPasswordMatch" name="checkPasswordMatch"></div>
						  </td>
					    </tr>
						<!-- Border -->
					    <tr height="2px">
						  	<td align="left" valign="middle" colspan="2" class="k-alt content"></td>
					    </tr>
						<tr height="2px" style="height: 30px">
							<td class="k-alt"></td>
			  				<td align="left" valign="top" class="border k-alt">Security Questions</td>
		  				</tr>
		  				<!--- New table for security questions. --->
		  				<tr height="2px">
			  				<td align="left" valign="top" colspan="2" class="k-alt">
				  
							  <table align="left" class="k-content" width="100%" cellpadding="2" cellspacing="0" border="0">
								  <!-- Border -->
								  <tr height="2px">
									  <td align="left" valign="top" colspan="k-content" class="k-content"></td>
								  </tr>
								  <tr valign="middle">
									<td align="right" valign="middle" class="k-content" width="20%">
										<label for="securityAnswer1">What is the name of your favorite pet?</label>
									</td>
									<td align="left" class="k-content">
										<input type="text" id="securityAnswer1" name="securityAnswer1" value="<cfoutput>#securityAnswer1#</cfoutput>" required validationMessage="Name of favorite pet is required" class="k-textbox" style="width:33%" /> 
									</td>
								  </tr>
								  <!-- Border -->
								  <tr height="2px">
									  <td align="left" valign="top" colspan="2" class="k-alt"></td>
								  </tr>
								  <tr valign="middle" height="30px">
									<td align="right" valign="middle" class="k-alt">
										<label for="securityAnswer2">What is the name of your favorite childhood friend?</label>
									</td>
									<td align="left" class="k-alt">
										<input id="securityAnswer2" name="securityAnswer2" type="text" value="<cfoutput>#securityAnswer2#</cfoutput>" required validationMessage="Name of favorite friend is required" class="k-textbox" style="width: 33%" /> 
									</td>
								  </tr>
								  <!-- Border -->
								  <tr height="2px">
									  <td align="left" valign="top" colspan="2" class="k-content"></td>
								  </tr>
								  <tr valign="middle" height="30px">
									<td align="right" valign="middle" class="k-content">
										<label for="securityAnswer3">What is your favorite place?</label>
									</td>
									<td align="left" class="k-content">
										<input id="securityAnswer3" name="securityAnswer3" type="text" value="<cfoutput>#securityAnswer2#</cfoutput>" required validationMessage="Name of favorite place is required" class="k-textbox" style="width: 33%"/>
									</td>
								  </tr>
								</table>
						  </td>
					    </tr>
						<!-- Border -->
					    <tr height="2px">
						  	<td align="left" valign="middle" colspan="2" class="k-content border"></td>
					    </tr>
						<tr>
						  <td></td>
						  <td>
							  <input type="button" name="SubmitProfile" id="submitProfile" value="Save Profile" class="k-button k-primary" onClick="validatePasswords()"/>
					 	  </td>
						</tr>
					</table> 
				  </td>
			  </tr>
			</table>
		</td>
	</tr>
</table>
</form>
	
<script>
	function validatePasswords(){
		
		var password = $("#password").val();
		var confirmPassword = $("#confirmPassword").val();
		
		if (password != confirmPassword){
			alert("The passwords don't match!");
			$("#checkPasswordMatch").html("Passwords do not match !").css("color","red");
		} else {
			document.getElementById("userProfileForm").submit();
		}
	}
</script>
