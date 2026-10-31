<!--- Shared card-grid section renderer - one heading + a horizontal row-wrapping grid of cards (Kendo's .k-card-deck, 3 per row
on desktop, 1 per row on mobile/when the sidebar shows, wrapping to a new row - same mechanism blogContentHtml.cfm's own
condensed post-card grid uses, and the same one Page Collection card-listing already used). Extracted here so the curated/
additive homepage (curatedHomepageContentHtml.cfm) can stack multiple independent sections (Featured Pages, Featured
Collections, Blog Posts) without three near-duplicate templates. .k-card-deck itself does not wrap (flex-wrap: nowrap) -
each row needs its own deck div, which is why this loops in chunks of numColumns rather than one flex container.

Caller sets these local variables before including this file:
	cardGridHeading      - string, the section's <h2> heading
	cardGridItems        - array of {title, description, imageUrl, linkUrl} structs, in the order to render them
	cardGridButtonText   - string, the text on each card's action button (e.g. "View Collection...", "Read More...")
	cardGridFooterLink   - optional {text, url} struct for a link below the grid (e.g. "View All Posts"); omit/empty for none

Each item may also optionally carry a "promoted" boolean (2026-10-01) - when true, the card gets the same
highlightedWidget border + bullhorn-icon treatment renderKendoCardGrid.cfm's own promotedPost logic gives a
promoted post on the plain blog listing (blogContentCss.cfm's .highlightedWidget - a thin border in the theme's
accent color). Only blog-post items have a concept of "promoted" today (curatedHomepageContentHtml.cfm's Blog
Posts section) - Featured Pages/Collections items simply omit the key, which is treated the same as false.

Items may also carry "eventHtml" (2026-10-16): an event post's details (Events.cfc renderCardStripHtml), shown under the title;
and "eventOverlayHtml": the event's calendar page, centred over the card's picture. --->
<cfparam name="cardGridFooterLink" default="">

<h2 class="topContent"><cfoutput>#cardGridHeading#</cfoutput></h2>
<cfsilent>
	<!--- Same column logic as blogContentHtml.cfm's condensed card grid: one card per row on mobile or when the sidebar is shown, otherwise 3 across. --->
	<cfif session.isMobile or showSidebar>
		<cfset cardGridNumColumns = 1>
		<cfset cardGridCardWidth = "100">
	<cfelse>
		<cfset cardGridNumColumns = 3>
		<cfset cardGridCardWidth = "31">
	</cfif>
	<cfif not showSidebar>
		<cfset cardGridKCardClass = "k-card-deck">
	<cfelse>
		<cfset cardGridKCardClass = "k-card-list">
	</cfif>
</cfsilent>
<cfloop from="1" to="#ceiling(arrayLen(cardGridItems)/cardGridNumColumns)#" index="cardGridRowIndex">
	<div id="cardContainer" style="width: 100%">
		<div class="<cfoutput>#cardGridKCardClass#</cfoutput>" style="width:100%">
			<cfloop from="1" to="#cardGridNumColumns#" index="cardGridColIndex">
				<cfset cardGridItemIndex = ((cardGridRowIndex - 1) * cardGridNumColumns) + cardGridColIndex>
				<cfif cardGridItemIndex lte arrayLen(cardGridItems)>
					<cfset cardGridOneItem = cardGridItems[cardGridItemIndex]>
					<cfset cardGridItemPromoted = structKeyExists(cardGridOneItem, "promoted") and cardGridOneItem.promoted>
					<div class="k-card<cfif cardGridItemPromoted> highlightedWidget</cfif>" style="width: <cfoutput>#cardGridCardWidth#</cfoutput>%;">
						<div class="k-card-body">
							<a href="<cfoutput>#cardGridOneItem.linkUrl#</cfoutput>" aria-label="<cfoutput>#cardGridOneItem.title#</cfoutput>">
								<cfset cardGridOverlay = structKeyExists(cardGridOneItem, "eventOverlayHtml") ? cardGridOneItem.eventOverlayHtml : "">
								<cfif len(cardGridOverlay)><div class="galaxieEventOnPicture"></cfif>
								<!--- Priority: mediaHtml (a ready-to-insert widget, eg. a rendered hero-pool carousel) ->
								imageUrl (plain image) -> suppressImage (NoImageFallbackMode='none', show nothing) ->
								noMedia.png (today's unchanged default). --->
								<cfif len(cardGridOneItem.mediaHtml)>
									<cfoutput>#cardGridOneItem.mediaHtml#</cfoutput>
								<cfelseif len(cardGridOneItem.imageUrl)>
									<!--- The card-sized copy of the picture when there is one (2026-10-31, Image.cfc getCardImageUrl). --->
									<cfif not structKeyExists(request, "galaxieImageObj")><cfset request.galaxieImageObj = createObject("component", application.imageComponentPath)></cfif>
									<cfset thisCardImage = request.galaxieImageObj.getCardImageUrl(cardGridOneItem.imageUrl)>
									<div class="img-hover-zoom img-hover-brightzoom"><img class="fade lazied shown k-card-image" data-type="image" data-src="<cfoutput>#thisCardImage#</cfoutput>" alt="<cfoutput>#cardGridOneItem.title#</cfoutput>" data-lazied="IMG" src="<cfoutput>#thisCardImage#</cfoutput>"></div>
								<cfelseif not cardGridOneItem.suppressImage>
									<div class="img-hover-zoom img-hover-brightzoom"><img class="fade lazied shown k-card-image" data-type="image" data-src="<cfoutput>#application.baseUrl#</cfoutput>/images/icons/noMedia.png" alt="<cfoutput>#cardGridOneItem.title#</cfoutput>" data-lazied="IMG" src="<cfoutput>#application.baseUrl#</cfoutput>/images/icons/noMedia.png"></div>
								</cfif>
								<cfif len(cardGridOverlay)><cfoutput>#cardGridOverlay#</cfoutput></div></cfif>
							</a>
							<hr class="k-card-separator" />
							<h3 class="k-card-title" style="font-size: 14pt; margin: 10px 0px;"><cfif cardGridItemPromoted>&nbsp;<i class="fa fa-bullhorn" aria-hidden="true" style="font-size: 14pt" title="Announcement"></i>&nbsp;&nbsp;</cfif><a href="<cfoutput>#cardGridOneItem.linkUrl#</cfoutput>" aria-label="<cfoutput>#cardGridOneItem.title#</cfoutput>"><cfoutput>#cardGridOneItem.title#</cfoutput></a></h3>
							<cfif structKeyExists(cardGridOneItem, "eventHtml") and len(cardGridOneItem.eventHtml)><cfoutput>#cardGridOneItem.eventHtml#</cfoutput></cfif>
							<cfif len(cardGridOneItem.description)>
								<hr class="k-card-separator" />
								<span class="blog-content"><cfoutput>#cardGridOneItem.description#</cfoutput></span>
							</cfif>
						</div>
						<span class="k-card-action">
							<span class="k-button k-primary" onClick="window.open('<cfoutput>#cardGridOneItem.linkUrl#</cfoutput>')"><cfoutput>#cardGridButtonText#</cfoutput></span>
						</span>
					</div>
				</cfif>
			</cfloop>
		</div>
	</div>
</cfloop>
<cfif isStruct(cardGridFooterLink) and len(cardGridFooterLink.url)>
	<p style="text-align: center;"><a href="<cfoutput>#cardGridFooterLink.url#</cfoutput>" class="k-button normalFontWeight"><cfoutput>#cardGridFooterLink.text#</cfoutput></a></p>
</cfif>
