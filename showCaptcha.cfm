<cfparam name="url.hashReference" default="">
<!--- Create the image using the hash as the image name --->
<!--- The temporary image gets its own random name (2026-10-14); hashReference only keeps browsers from reusing an old image. --->
<cfset captchaImageFile = getTempDirectory() & "captcha-" & createUUID() & ".png">
<cfimage action="captcha" width="300" height="75" text="#session.captchaText#" fonts="Verdana,Arial,Courier New,Courier" difficulty="medium" destination="#captchaImageFile#" overwrite="true" format="png">
<!--- Set the content type so that this file displays the captcha image --->
<cfcontent type="image/jpg" file="#captchaImageFile#" deletefile="true" reset="false" />
