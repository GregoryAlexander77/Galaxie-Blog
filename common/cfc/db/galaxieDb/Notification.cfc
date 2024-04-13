<cfcomponent displayName="Notification" persistent="true" table="Notification" output="no" hint="ORM logic for the new Notification table.">
	
	<cfproperty name="NotificationId" fieldtype="id" generator="native" setter="false">
	<!--- Many Pods for one blog. --->
	<cfproperty name="BlogRef" ormtype="int" fieldtype="many-to-one" cfc="Blog" fkcolumn="BlogRef" cascade="all">
	<!--- Many notifications for a user --->
	<cfproperty name="UserRef" ormtype="int" fieldtype="many-to-one" cfc="Users" fkcolumn="UserRef" cascade="all" missingRowIgnored="true">
	<!--- There are many notifications to one kendo theme --->
	<cfproperty name="ThemeRef" ormtype="int" fieldtype="many-to-one" cfc="Theme" fkcolumn="ThemeRef" missingRowIgnored="true">
	<!--- Many notifications for one post --->
	<cfproperty name="PostRef" ormtype="int" fieldtype="many-to-one" cfc="Post" fkcolumn="PostRef" cascade="all">
	<cfproperty name="NotificationTitle" ormtype="string" default="" length="240" hint="The title shown on the notification">
	<cfproperty name="Notification" ormtype="string" default="" length="500" hint="The notification body">
	<cfproperty name="NotificationAction" ormtype="string" default="" length="240" hint="">
	<cfproperty name="NotificationLink" ormtype="string" default="" length="240" hint="Optional link that occurs when the user clicks on a link">
	<cfproperty name="Date" ormtype="timestamp">

</cfcomponent>