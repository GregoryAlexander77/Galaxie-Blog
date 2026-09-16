<cfcomponent displayName="HttpUserAgent" persistent="true" table="HttpUserAgent" output="no" hint="ORM logic for the new HttpUserAgent table">
	
	<cfproperty name="HttpUserAgentId" fieldtype="id" generator="native" setter="false">
	<!--- There are many IP addresses for a blog --->
	<cfproperty name="BlogRef" ormtype="int" fieldtype="many-to-one" cfc="Blog" fkcolumn="BlogRef" cascade="all">
	<cfproperty name="HttpUserAgent" ormtype="string" length="500" default="">
	<!--- Added for the Ban Visitors admin interface (createAdminInterfaceWindow(66)). When true, any anonymous visitor using this User-Agent string is blocked. See application.blog.isVisitorBanned(). --->
	<cfproperty name="Ban" ormtype="boolean" default="false">
	<cfproperty name="Note" ormtype="string" default="" length="255" hint="Optional reason/notes entered by the admin when banning this User-Agent.">
	<cfproperty name="BanDate" ormtype="timestamp" nullable="true" hint="When this User-Agent was banned. Set by application.blog.setHttpUserAgentBan() and shown on the Banned Users grid (createAdminInterfaceWindow(67)). Cleared when the User-Agent is unbanned.">
	<cfproperty name="Date" ormtype="timestamp">

</cfcomponent>