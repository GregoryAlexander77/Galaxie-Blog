<cfcomponent displayName="MediaGallery" persistent="true" table="MediaGallery" output="no" hint="ORM logic for the new Gallery table. This table will have multiple records for each PostInclude record. Each record will be an individual fancy box thing.">
	
	<cfproperty name="MediaGalleryId" fieldtype="id" generator="native" setter="false">
	<!--- The MediaGalleryItems column below is a psuedo column that is used by this object. There one gallery with many items --->
	<cfproperty name="MediaGalleryItems" singularname="MediaGalleryItem" ormtype="int" fieldtype="one-to-many" cfc="MediaGalleryItem" fkcolumn="MediaGalleryRef" type="array" cascade="all" inverse="true" missingRowIgnored="true">
	<cfproperty name="MediaGalleryName" ormtype="string" default="" length="175" hint="The fancy box group. This name is the mediaId's separated by an underscore and the name can be quite long.">
	<cfproperty name="MediaGalleryTitle" ormtype="string" default="" length="125" hint="The title of the fancybox thing">
	<cfproperty name="Date" ormtype="timestamp">
		
</cfcomponent>

