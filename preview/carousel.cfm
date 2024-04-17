<!DOCTYPE html>
<!--- <cfdump var="#URL#" label="url"> --->
<!---<cfsilent>--->
<!--- Extract the carousel. --->
<cfparam name="URL.galleryId" default="">
<cfparam name="URL.interface" default="">
<cfparam name="darkTheme" default="false">
	
<!--- Set the page --->
<cfset pageId = 5>
<cfset pageName = "CarouselPreview">
<cfset pageTypeId = 1>
<cfparam name="renderCard" default="true">
	
<cfparam name="debug" default="false">
		
<cfif URL.interface eq 'postEditor' or URL.interface eq 'card'>
	<!--- The post editor gallery is small --->
	<cfset renderCard = true>
	<cfif session.isMobile>
		<cfset height = "105px">
		<cfset width = "225px">
	<cfelse>
		<cfset height = "150px">
		<cfset width = "235px">
	</cfif>
<cfelseif URL.interface eq 'enclosureEditor'>
	<cfset renderCard = true>
	<cfif session.isMobile>
		<cfset height = "147px">
		<cfset width = "290px">
	<cfelse>
		<cfset height = "534px">
		<cfset width = "800px">
	</cfif>
<cfelseif URL.interface eq 'mediumCard'>
	<cfset renderCard = false>
	<!--- Rendering the iframe in a mobile client--->
	<cfif session.isMobile>
		<cfset width="100%">
		<cfset height="390">
	<cfelse>
		<cfset width = "99%">
		<cfset height = "610px">
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

<!--- Get the HTML for this carousel in card mode renderCarousel(carouselId, card, height, width) --->
<cfset carouselHtml = RendererObj.renderCarousel(URL.carouselid,renderCard, width, height )>
	
<html>
    <head>
        <title>Carousel Preview</title>
        <meta http-equiv='Content-Type' content='text/html; charset=utf-8'/>
    </head>
    <body>
	<div class="carousel-preview">
		<cfif debug and CGI.Remote_Addr eq '76.22.103.228'>
			<cfoutput>URL.interface: #URL.interface# renderCard: #renderCard# width: #width# height: #height#</cfoutput>
		</cfif>
		<cfoutput>#carouselHtml#</cfoutput>
	</div>
	
    </body>
</html>