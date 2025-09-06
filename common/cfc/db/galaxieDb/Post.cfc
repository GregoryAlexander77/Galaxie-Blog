<cfcomponent displayName="Post" persistent="true" table="Post" output="no" hint="ORM logic for the new Post table">
	<cfproperty name="PostId" fieldtype="id" generator="native" setter="false">
	<!--- Many posts for one blog. --->
	<cfproperty name="BlogRef" ormtype="int" fieldtype="many-to-one" cfc="Blog" fkcolumn="BlogRef" cascade="all">
	<!--- UserRef is the db key to attach a post to a user (right now the person that created the post) --->
	<cfproperty name="UserRef" ormtype="int" fieldtype="many-to-one" cfc="Users" fkcolumn="UserRef" cascade="all">
	
	<!--- There can many posts that have one enclosure (from the media table). Generally, this is a one to one relationship, but many posts can share the same image. --->
	<cfproperty name="EnclosureMedia" singularname="Enclosure" ormtype="int" fieldtype="many-to-one" cfc="Media" fkcolumn="EnclosureMediaRef" inversejoincolumn="PostRef" inverse="true" cascade="all" missingRowIgnored="true">
	<!--- There can be many posts to one map. If there was a unique map for every post, this would be a one to one relationship. However, many posts don't have maps (where there would be multipe nulls) and many posts can share the same map. --->
	<cfproperty name="EnclosureMap" ormtype="int" fieldtype="many-to-one" cfc="Map" fkcolumn="EnclosureMapRef" inversejoincolumn="PostRef" inverse="true" cascade="all" missingRowIgnored="true">
	<!--- There can be many posts to one carousel. If there was a unique carousel for every post, this would be a one to one relationship. However, many posts don't have carousels (where there would be multipe nulls) and many posts can share the same carousel. --->
	<cfproperty name="EnclosureCarousel" ormtype="int" fieldtype="many-to-one" cfc="Carousel" fkcolumn="EnclosureCarouselRef" inversejoincolumn="PostRef" inverse="true" cascade="all" missingRowIgnored="true">
	<!--- The PostAssests column below is a psuedo column that is used by this object. The PostMedia table is our link table. There are many posts with many different types of media (images and video) --->
	<cfproperty name="PostAssets" singularname="PostAsset" ormtype="int" fieldtype="one-to-many" cfc="PostMedia" fkcolumn="PostRef" inversejoincolumn="MediaRef" inverse="true" cascade="all" missingRowIgnored="true">
	<!--- Psuedo column that will not be placed into the actual database. We are using the PostCategoryLookup table as an intermediatory table to store the many to many relationships between a post and a category.  --->
	<cfproperty name="Categories" singularname="Category" ormtype="int" fieldtype="many-to-many" cfc="Category" fkcolumn="PostRef" inversejoincolumn="CategoryRef" inverse="true" linktable="PostCategoryLookup" type="array" cascade="all" missingRowIgnored="true">
	<!--- Psuedo column that will not be placed into the actual database. We are using the PostTagLookup table as an intermediatory table to store the many to many relationships between a post and a tag.  --->
	<cfproperty name="Tags" singularname="Tag" ormtype="int" fieldtype="many-to-many" cfc="Tag" fkcolumn="PostRef" inversejoincolumn="TagRef" inverse="true" linktable="PostTagLookup" type="array" cascade="all" missingRowIgnored="true">
	<!--- A psuedo column to determine related posts. --->
	<cfproperty name="RelatedPosts" singularname="RelatedPost" ormtype="int" fieldtype="many-to-many" cfc="Post" fkcolumn="PostRef" inversejoincolumn="RelatedPostRef" inverse="true" linktable="RelatedPost" type="array" missingRowIgnored="true">
	<cfproperty name="Comments" singularname="Comment" ormtype="int" fieldtype="one-to-many" cfc="Comment" fkcolumn="PostRef" type="array" inverse="true" missingRowIgnored="true">
	<!--- The ThemeRef is optional. I am not going to make a relationship here as it will make a required constraint. --->
	<cfproperty name="ThemeRef" ormtype="int" default="0">
	<cfproperty name="PostUuid" ormtype="string" length="35" default="">
	<cfproperty name="PostAlias" ormtype="string" length="100" default="">
	<cfproperty name="Title" ormtype="string" length="125" default="">
	<cfproperty name="Description" ormtype="string" length="1250" default="This should be set to a lenght of 160 in the future">
	<!--- SEO Stuff (I will break this into it's own table in a future version) --->
	<cfproperty name="NoIndex" ormtype="boolean" default="false">
	<cfproperty name="DisplayOnRss" ormtype="boolean" default="true">
	<cfproperty name="CanonicalURL" ormtype="string" length="1000" default="">
	<!--- The following 6 items are configured for SQL Server. Change these depending upon your db --->
	<cfproperty name="JsonLd" ormtype="string" sqltype="varchar(max)" default="">
	<cfproperty name="PostHeader" ormtype="string" sqltype="varchar(max)" default="">
	<cfproperty name="CSS" ormtype="string" sqltype="varchar(max)" default="">
	<cfproperty name="JavaScript" ormtype="string" sqltype="varchar(max)" default="">
	<cfproperty name="Body" ormtype="string" sqltype="varchar(max)" default="">
	<cfproperty name="MoreBody" ormtype="clob" default="">
	<cfproperty name="Released" ormtype="boolean" default="false">
	<cfproperty name="Promote" ormtype="boolean" default="false">
	<cfproperty name="AllowComment" ormtype="boolean" default="true">
	<cfproperty name="Remove" ormtype="boolean" default="false">
	<cfproperty name="RedirectUrl" ormtype="string" length="250" default="" hint="A post can be redirected when removed">
	<cfproperty name="RedirectType" ormtype="string" length="35" default="" hint="Either permanent or tempoary">
	<cfproperty name="NumViews" ormtype="int" default="0">
	<cfproperty name="Mailed" ormtype="boolean" default="false">
	<cfproperty name="BlogSortDate" ormtype="timestamp" default="" hint="This is used change the sort order of the articles on the main blog.">
	<cfproperty name="DatePosted" ormtype="timestamp" default="">
	<!--- We need an actual date property without the timestamp for the date search. --->
	<cfproperty name="Date" ormtype="date" default="">

</cfcomponent>