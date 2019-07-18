<!--- This path should start from the web root and work forward from
			there, if you don't have it in the web root --->
<cfset cffpPath = "cfformprotect">

<!--- load the file that grabs all values from the ini file --->
<cfinclude template="cffpConfig.cfm">

<!--- check the config (from the ini file)to see if each test is turned on --->
<cfif cffpConfig.mouseMovement>
	<!--- If the user moves their mouse, put the distance in this field (JavaScript function handles this).
				cffpVerify.cfm will make sure the user at least used their keyboard. A spam
				bot won't trigger this --->
	<input type="hidden" name="formfield1234567891" id="formfield1234567891" value="">
	<cfhtmlhead text="<script type='text/javascript' src='#cffpPath#/js/mouseMovement.js'></script>">
</cfif>

<cfif cffpConfig.usedKeyboard>
	<!--- If the types on their keyboard, put the amount of keys pressed in this field.
				cffpVerify.cfm will make sure the user at least used their keyboard. A spam
				bot won't trigger this --->
	<input type="hidden" name="formfield1234567892" id="formfield1234567892" value="">
	<cfhtmlhead text="<script type='text/javascript' src='#cffpPath#/js/usedKeyboard.js'></script>">
</cfif>

<cfif cffpConfig.timedFormSubmission>
	<!--- in cffpVerify.cfm I will verify that the amount of time it took to
				fill out this form is 'normal' (the time limits are set in the ini file)--->
	<!--- get the current time, obfuscate it and load it to this hidden field --->
	<cfset currentDate = dateFormat(now(),'yyyymmdd')>
	<cfset currentTime = timeFormat(now(),'HHmmss')>
	<!--- Add an arbitrary number to the date/time values to mask them from prying eyes --->
	<cfset blurredDate = currentDate+19740206>
	<cfset blurredTime = currentTime+19740206>
	<input type="hidden" name="formfield1234567893" value="<cfoutput>#blurredDate#,#blurredTime#</cfoutput>">
</cfif>

<cfif cffpConfig.hiddenFormField>
	<!--- A lot of spam bots automatically fill in all form fields.  cffpVerify.cfm will
				test to see if this field is blank. The "leave this empty" text is there for blind people,
				who might see this hidden field --->
	<span style="display:none">Leave this field empty <input type="text" name="formfield1234567894" value=""></span>
</cfif>