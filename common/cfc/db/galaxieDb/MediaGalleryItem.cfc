<cfcomponent displayName="MediaGalleryItem" persistent="true" table="MediaGalleryItem" output="no" hint="ORM logic for the new MediaGalleryItem table. This table will have multiple records for each MediaGallery record. Each record will be an individual fancy box thing.">
	
	<cfproperty name="MediaGalleryItemId" fieldtype="id" generator="native" setter="false">
	<cfproperty name="MediaGalleryRef" ormtype="int" fieldtype="many-to-one" cfc="MediaGallery" fkcolumn="MediaGalleryRef" cascade="all" missingrowignored="true" hint="Foreign Key to the MediaGallery.MediaGalleryId">
	<cfproperty name="MediaRef" ormtype="int" fieldtype="many-to-one" cfc="Media" fkcolumn="MediaRef" cascade="all" missingrowignored="true" hint="Foreign Key to the Media.MediaId">
	<cfproperty name="MediaGalleryItemTitle" ormtype="string" default="" length="255" hint="Specify the title that will be shown when the image is loaded">
	<cfproperty name="MediaGalleryItemUrl" ormtype="string" default="" length="255" hint="Specify the URL where the image links to when clicked.">
	<cfproperty name="Date" ormtype="timestamp">
		
</cfcomponent>

