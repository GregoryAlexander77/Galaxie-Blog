<cfparam name="url.hashReference" default="">
<cfset variables.captcha = application.captcha.createCaptchaFromHashReference("file",url.hashReference) />
<cfcontent type="image/jpg" file="#variables.captcha.fileLocation#" deletefile="true" reset="false" />