<cfparam name="url.hashReference" default="">
<!--- Create the image using the hash as the image name --->
<cfimage action="captcha" width="300" height="75" text="#session.captchaText#" fonts="Verdana,Arial,Courier New,Courier" difficulty="medium" destination="#getTempDirectory()##URL.hashReference#.png" overwrite="true" format="png">
<!--- Set the content type so that this file displays the captcha image --->
<cfcontent type="image/jpg" file="#getTempDirectory()##URL.hashReference#.png" deletefile="true" reset="false" />
