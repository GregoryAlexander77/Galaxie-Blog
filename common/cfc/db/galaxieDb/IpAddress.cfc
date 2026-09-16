<cfcomponent displayName="IpAddress" persistent="true" table="IpAddress" output="no" hint="ORM logic for the new IPAddress table">
	
	<cfproperty name="IpAddressId" fieldtype="id" generator="native" setter="false">
	<!--- There are many IP addresses for a blog --->
	<cfproperty name="BlogRef" ormtype="int" fieldtype="many-to-one" cfc="Blog" fkcolumn="BlogRef" cascade="all">
	<cfproperty name="IpAddress" ormtype="string" length="25" default="">
	<!--- Added for the Ban Visitors admin interface (createAdminInterfaceWindow(66)). When true, any anonymous visitor using this IP is blocked. See application.blog.isVisitorBanned(). --->
	<cfproperty name="Ban" ormtype="boolean" default="false">
	<cfproperty name="Note" ormtype="string" default="" length="255" hint="Optional reason/notes entered by the admin when banning this IP.">
	<cfproperty name="BanDate" ormtype="timestamp" nullable="true" hint="When this IP was banned. Set by application.blog.setIpAddressBan() and shown on the Banned Users grid (createAdminInterfaceWindow(67)). Cleared when the IP is unbanned.">
	<cfproperty name="Date" ormtype="timestamp">

</cfcomponent>