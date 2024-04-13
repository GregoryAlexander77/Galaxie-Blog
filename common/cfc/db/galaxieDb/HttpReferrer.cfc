<cfcomponent displayName="HttpReferrer" persistent="true" table="HttpReferrer" output="no" hint="ORM logic for the new HttpReferrer table">
	
	<cfproperty name="HttpReferrerId" fieldtype="id" generator="native" setter="false">
	<!--- There are many http referrers for a blog --->
	<cfproperty name="BlogRef" ormtype="int" fieldtype="many-to-one" cfc="Blog" fkcolumn="BlogRef" cascade="all">
	<!--- There should be one HTTP referrer in many visitor log records. This is the inverse relationship of the many-to-one relationship to this table. Note: we are trying to make sure that there is only one unique referrer in this table so the relationship is a one to many here. --->
	<cfproperty name="Visitors" singularname="Visitor" ormtype="int" fieldtype="one-to-many" cfc="VisitorLog" fkcolumn="HttpReferrerRef" inverse="true" type="array" cascade="all" missingRowIgnored="true">
	<cfproperty name="HttpReferrer" ormtype="string" length="500" default="">
	<cfproperty name="Date" ormtype="timestamp">

</cfcomponent>