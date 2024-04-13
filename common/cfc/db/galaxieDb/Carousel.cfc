<cfcomponent displayName="Carousel" persistent="true" table="Carousel" output="no" hint="ORM logic for the new Carousel table. This table will have multiple records for each PostInclude record.">
	
	<cfproperty name="CarouselId" fieldtype="id" generator="native" setter="false">
	<cfproperty name="PostRef" ormtype="int" fieldtype="many-to-one" cfc="Post" fkcolumn="PostRef" cascade="all" missingrowignored="true" hint="Foreign Key to the Post.PostId">
	<!--- The CarouselItems column below is a psuedo column that is used by this object. There one gallery with many items --->
	<cfproperty name="CarouselItems" singularname="CarouselItem" ormtype="int" fieldtype="one-to-many" cfc="CarouselItem" fkcolumn="CarouselRef" type="array" cascade="all" inverse="true" missingRowIgnored="true">
	<cfproperty name="CarouselName" ormtype="string" default="" length="175" hint="The name of the carousel.">
	<cfproperty name="CarouselTitle" ormtype="string" default="" length="125" hint="The title of the fancybox thing">
	<cfproperty name="CarouselEffect" ormtype="string" default="" length="125" hint="The swiper based effect">
	<cfproperty name="CarouselShader" ormtype="string" default="" length="125" hint="The swiper based shader">
	<cfproperty name="Date" ormtype="timestamp">
		
</cfcomponent>

