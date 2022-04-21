<cfcomponent displayName="Font" persistent="true" table="Font" output="no" hint="ORM logic for the new Font table">
	
	<cfproperty name="FontId" fieldtype="id" generator="native" setter="false">
	<cfproperty name="Font" ormtype="string" default="" length="125">
	<cfproperty name="FontAlias" ormtype="string" length="125" default="" hint="This alias will serve as the file name and the name of the font if it is hosted on the server. This is the font name with the size and italic if specified without any spaces or any special characters.">
	<cfproperty name="FontWeight" ormtype="string" length="75" default="" hint="Use this to indicate the font size if its not normal. Typical sizes are thin (100), light(300) normal (400), bold (700) or black (900). Usually you will want normal and bold.">
	<cfproperty name="Italic" ormtype="boolean" default="false">
	<cfproperty name="FontType" ormtype="string" length="75" default="">
	<cfproperty name="FileName" ormtype="string" length="125" default="">
	<cfproperty name="Woff" ormtype="boolean" default="false">
	<cfproperty name="Woff2" ormtype="boolean" default="false">
	<cfproperty name="WebSafeFont" ormtype="boolean" default="false" hint="Certain fonts, such as Arial are standard across platforms and do not need to be loaded on a web page.">
	<cfproperty name="WebSafeFallback" ormtype="string" length="250" default="" hint="If the websafe font is not installed on the users system, provide a fallback font or fonts.">
	<cfproperty name="GoogleFont" ormtype="boolean" default="false">
	<cfproperty name="SelfHosted" ormtype="boolean" default="false" hint="If true, indicates that this font resides on the web server. It is preferred to host your own fonts for performance, however, sometimes this is not possible. Some fonts, such as Candora, are only available by using the google CDN.">
	<cfproperty name="UseFont" ormtype="boolean" default="false">
	<cfproperty name="Date" ormtype="timestamp">

</cfcomponent>