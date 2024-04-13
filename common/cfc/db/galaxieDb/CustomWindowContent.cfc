<cfcomponent displayName="CustomWindowContent" persistent="true" table="CustomWindowContent" output="no" hint="ORM logic for the new Custom Window Content table, used to provide custom content in a new Kendo window.">
	
	<cfproperty name="CustomWindowContentId" fieldtype="id" generator="native" setter="false">
	<!--- Many windows for one blog --->
	<cfproperty name="BlogRef" ormtype="int" fieldtype="many-to-one" cfc="Blog" fkcolumn="BlogRef" cascade="all">
	<!--- A PostId is not required. This is only a place holder to get the the post and there is no ORM relationship here. --->
	<cfproperty name="PostRef" ormtype="int" default="0">
	<cfproperty name="CustomWindowShortDesc" ormtype="string"  length="75" default="" hint="This is used for the user to select the appropriate window if they want to edit an existing custom window. We will not know the ID in the TinyMce post editor as the button is created automatically">
	<cfproperty name="ButtonName" ormtype="string"  length="75" default="">
	<cfproperty name="ButtonLabel" ormtype="string"  length="125" default="">
	<cfproperty name="ButtonOptArgs" ormtype="string"  length="225" default="">
	<cfproperty name="WindowName" ormtype="string"  length="75" default="">
	<cfproperty name="WindowTitle" ormtype="string"  length="125" default="">
	<cfproperty name="WindowHeight" ormtype="string"  length="15" default="">
	<cfproperty name="WindowWidth" ormtype="string"  length="15" default="">
	<!--- The content is either an include or content. --->
	<cfproperty name="CfincludePath" ormtype="string"  length="225" default="">
	<cfproperty name="Content" ormtype="string" sqltype="varchar(max)" default="">
	<cfproperty name="OtherArgs" ormtype="string"  length="225" default="" hint="Used to specify optional custom arguments for the otherArgs property">
	<cfproperty name="OtherArgs1" ormtype="string"  length="225" default="" hint="Used to specify optional custom arguments for the otherArgs1 property">
	<cfproperty name="Active" ormtype="boolean" default="true">
	<cfproperty name="Date" ormtype="timestamp" default="" >

</cfcomponent>