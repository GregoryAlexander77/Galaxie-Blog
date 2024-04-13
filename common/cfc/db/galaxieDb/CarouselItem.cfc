<cfcomponent displayName="CarouselItem" persistent="true" table="CarouselItem" output="no" hint="ORM logic for the new CarouselItem table. This table will have multiple records for each Carousel record.">
	
	<cfproperty name="CarouselItemId" fieldtype="id" generator="native" setter="false">
	<cfproperty name="CarouselRef" ormtype="int" fieldtype="many-to-one" cfc="Carousel" fkcolumn="CarouselRef" cascade="all" missingrowignored="true" hint="Foreign Key to the Carousel.CarouselId">
	<cfproperty name="MediaRef" ormtype="int" fieldtype="many-to-one" cfc="Media" fkcolumn="MediaRef" cascade="all" missingrowignored="true" hint="Foreign Key to the Media.MediaId">
	<cfproperty name="CarouselItemTitle" ormtype="string" default="" length="255" hint="Specify the title that will be shown on the carousel item">
	<!--- Many fonts per carousel title --->
	<cfproperty name="CarouselItemTitleFontRef" ormtype="int" fieldtype="many-to-one" cfc="Font" fkcolumn="FontRef" missingRowIgnored="true" hint="Determines the font. This is optional">
	<cfproperty name="CarouselItemTitleFontColor" ormtype="string" default="" length="255" hint="The font color for this carousel title">
	<cfproperty name="CarouselItemTitleFontSize" ormtype="string" default="" length="255" hint="The font color for this carousel title">
	<cfproperty name="CarouselItemBody" ormtype="string" default="" length="1200" hint="Specify the body that will be shown on the carousel item">
	<cfproperty name="CarouselItemBodyFontColor" ormtype="string" default="" length="255" hint="The font color for this carousel body">
	<cfproperty name="CarouselItemBodyFontSize" ormtype="string" default="" length="255" hint="The font color for this carousel body">
	<cfproperty name="CarouselItemUrl" ormtype="string" default="" length="255" hint="Specify the URL where the image links to when clicked.">
	<cfproperty name="Date" ormtype="timestamp">
		
</cfcomponent>

