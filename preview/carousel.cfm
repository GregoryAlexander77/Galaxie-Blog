<!DOCTYPE html>
<!--- <cfdump var="#URL#" label="url"> --->
<!---<cfsilent>--->
<!--- Extract the carousel. --->
<cfparam name="URL.galleryId" default="">
<cfparam name="URL.editorType" default="">
<cfparam name="darkTheme" default="false">
	
<!--- Set the page --->
<cfset pageId = 5>
<cfset pageName = "CarouselPreview">
<cfset pageTypeId = 1>
		
<cfif URL.editorType eq 'postEditor'>
	<!--- The post editor gallery is small --->
	<cfset renderCard = true>
	<cfif session.isMobile>
		<cfset height = "105px">
		<cfset width = "225px">
	<cfelse>
		<cfset height = "150px">
		<cfset width = "300px">
	</cfif>
<cfelse>
	<cfset renderCard = false>
	<cfif session.isMobile>
		<cfset height = "147px">
		<cfset width = "290px">
	<cfelse>
		<cfset height = "534px">
		<cfset width = "800px">
	</cfif>
</cfif>
	
<!--- Instantiate the Render.cfc. This will be used to build the HTML for the image if the MediaUrl is present in the database. --->
<cfobject component="#application.rendererComponentPath#" name="RendererObj">
	
<style>
	.carousel-preview {
		position: relative;
		width: <cfoutput>#width#</cfoutput>!important;
		height: <cfoutput>#height#</cfoutput>!important;
		padding: 5px;
		padding-top: 5px;
		padding-left: 5px;
		padding-right: 5px;
		padding-bottom: 5px;
		box-shadow: 0 2px 4px 0 rgba(0, 0, 0, 0.2), 0 4px 8px 0 rgba(0, 0, 0, 0.19);
		overflow: hidden;
		}
</style>

<!--- Get the HTML for this carousel in card mode --->
<cfset carouselHtml = RendererObj.renderCarousel(URL.carouselid,renderCard)>
	
<html>
    <head>
        <title>Carousel Preview</title>
        <meta http-equiv='Content-Type' content='text/html; charset=utf-8'/>
    </head>
    <body>
	<div class="carousel-preview">
		<cfoutput>#carouselHtml#</cfoutput>
	</div>
	
    </body>
</html>