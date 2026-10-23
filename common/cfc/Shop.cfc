<cfcomponent displayName="Shop" output="false" hint="The shop (2026-10-20): products placed in posts, pages and scenes, a small cart, Stripe's hosted checkout through Payments.cfc, orders, emails and expiring download links. Headless and simple: there is no storefront of its own, one price per product, and nothing changes for a blog that doesn't sell anything. Tables: Product, ShopOrder, ShopOrderItem (and Payment.ShopOrderRef). Settings are kept in BlogEventSetting (Events.cfc getSetting/setSetting, post 0). See the proposal 'Galaxie Blog Shop, First Version'.">

<cfset variables.kinds = "physical,digital,service">
<!--- Order statuses that mean the buyer paid (some of it may have been refunded since). --->
<cfset variables.paidStatuses = "paid,shipped,partlyRefunded,refunded">

<cffunction name="init" access="public" returntype="any" output="false">
	<cfreturn this>
</cffunction>

<!---//*****************************************************************************************
		Settings
//******************************************************************************************--->

<cffunction name="getSettings" access="public" returntype="struct" output="false"
		hint="{ enabled, promotionCodes, downloadDays, downloadLimit, currency, paymentsReady, testMode }">
	<cfset var status = application.payments.getStatus()>
	<cfreturn {
		enabled: application.events.getSetting(0, "shopEnabled", "0") eq "1",
		promotionCodes: application.events.getSetting(0, "shopPromotionCodes", "0") eq "1",
		downloadDays: max(1, val(application.events.getSetting(0, "shopDownloadDays", "7"))),
		downloadLimit: max(1, val(application.events.getSetting(0, "shopDownloadLimit", "5"))),
		currency: application.payments.getCurrency(),
		paymentsReady: status.ready,
		testMode: status.testMode
	}>
</cffunction>

<cffunction name="saveSettings" access="public" returntype="void" output="false">
	<cfargument name="enabled" type="boolean" required="true">
	<cfargument name="promotionCodes" type="boolean" required="true">
	<cfargument name="downloadDays" required="false" default="7">
	<cfargument name="downloadLimit" required="false" default="5">
	<cfset application.events.setSetting(0, "shopEnabled", arguments.enabled ? "1" : "0")>
	<cfset application.events.setSetting(0, "shopPromotionCodes", arguments.promotionCodes ? "1" : "0")>
	<cfset application.events.setSetting(0, "shopDownloadDays", min(max(int(val(arguments.downloadDays)), 1), 365))>
	<cfset application.events.setSetting(0, "shopDownloadLimit", min(max(int(val(arguments.downloadLimit)), 1), 100))>
</cffunction>

<!---//*****************************************************************************************
		Labels (2026-10-22, owner): the words visitors see in the shop, changed in the Shop window's Labels section. Each one the
		owner changed is a setting 'shopLabel.<key>' (BlogEventSetting, post 0); an empty or unchanged one uses the default below.
		{count}, {date}, {amount} and {email} are filled in by common/js/shop.js.
//******************************************************************************************--->

<cfset variables.labelGroups = [
	{ heading: "On the product", intro: "What visitors see on a product in a post or on a shop page.", labels: [
		{ key: "addToCart", label: "Add to cart button", text: "Add to cart" },
		{ key: "soldOut", label: "Sold out", text: "Sold out" },
		{ key: "shopClosed", label: "Shop closed", text: "The shop is closed right now." },
		{ key: "notAvailable", label: "Not for sale yet", text: "Not available right now." },
		{ key: "freeShipping", label: "Free shipping", text: "Free shipping" },
		{ key: "shippingCost", label: "Shipping cost", text: "+ {amount} shipping" },
		{ key: "download", label: "Downloads", text: "A download, emailed to you right after you pay" },
		{ key: "nothingForSale", label: "Nothing for sale", text: "Nothing for sale here right now." }
	] },
	{ heading: "When they come back", intro: "The line above Add to cart for someone who has bought the product before: a signed-in member anywhere, a guest on the browser they bought with.", labels: [
		{ key: "boughtOne", label: "Bought one", text: "You bought this on {date}." },
		{ key: "boughtSeveral", label: "Bought several", text: "You bought {count} of these on {date}." },
		{ key: "boughtAgain", label: "Bought more than once", text: "You've bought {count} of these, most recently on {date}." },
		{ key: "booked", label: "A service", text: "You booked this on {date}." },
		{ key: "downloadAgain", label: "Download link", text: "Download it again" }
	] },
	{ heading: "After they pay", intro: "The thank-you window when they come back from Stripe.", labels: [
		{ key: "thanksHeading", label: "Heading", text: "Thank you!" },
		{ key: "paid", label: "Paid", text: "Your order is paid. A receipt is on its way to {email}." },
		{ key: "ships", label: "Shipping", text: "We'll email you when it ships." },
		{ key: "join", label: "Make an account", text: "Make a free account with {email} to see this order, and anything you buy later, from any device." },
		{ key: "joinButton", label: "Account button", text: "Create your account" },
		{ key: "saved", label: "Signed in", text: "This order is saved in your account." },
		{ key: "ordersLink", label: "Account link", text: "See your orders" }
	] }
]>

<cffunction name="getLabels" access="public" returntype="struct" output="false" hint="Every shop label by key: the owner's text, or the default. Kept until the labels are saved again.">
	<cfset var labels = {}>
	<cfset var group = "">
	<cfset var item = "">
	<cfset var saved = "">
	<cfif structKeyExists(variables, "labelCache")>
		<cfreturn duplicate(variables.labelCache)>
	</cfif>
	<cfloop array="#variables.labelGroups#" index="group">
		<cfloop array="#group.labels#" index="item">
			<cfset saved = trim(application.events.getSetting(0, "shopLabel." & item.key, ""))>
			<!--- Bracket keys keep their case in the JSON on Adobe ColdFusion. --->
			<cfset labels[ item.key ] = len(saved) ? saved : item.text>
		</cfloop>
	</cfloop>
	<cfset variables.labelCache = labels>
	<cfreturn duplicate(labels)>
</cffunction>

<cffunction name="getLabelGroups" access="public" returntype="array" output="false" hint="The Labels section of the Shop window: [{ heading, intro, labels: [{ key, label, text, default }] }].">
	<cfset var current = getLabels()>
	<cfset var groups = duplicate(variables.labelGroups)>
	<cfset var group = "">
	<cfset var item = "">
	<cfloop array="#groups#" index="group">
		<cfloop array="#group.labels#" index="item">
			<cfset item.default = item.text>
			<cfset item.text = current[item.key]>
		</cfloop>
	</cfloop>
	<cfreturn groups>
</cffunction>

<cffunction name="saveLabels" access="public" returntype="void" output="false" hint="Saves the labels from the Shop window. One left empty or the same as the default goes back to the default.">
	<cfargument name="labels" type="struct" required="true" hint="{ key: text }; unknown keys are ignored.">
	<cfset var group = "">
	<cfset var item = "">
	<cfset var text = "">
	<cfloop array="#variables.labelGroups#" index="group">
		<cfloop array="#group.labels#" index="item">
			<cfif structKeyExists(arguments.labels, item.key) and isSimpleValue(arguments.labels[item.key])>
				<cfset text = left(trim(reReplace(arguments.labels[item.key], "[\r\n\t]+", " ", "all")), 300)>
				<cfset application.events.setSetting(0, "shopLabel." & item.key, compare(text, item.text) eq 0 ? "" : text)>
			</cfif>
		</cfloop>
	</cfloop>
	<cfset structDelete(variables, "labelCache")>
</cffunction>

<!---//*****************************************************************************************
		Products
//******************************************************************************************--->

<cffunction name="listProducts" access="public" returntype="array" output="false" hint="This blog's products, by name.">
	<cfargument name="activeOnly" type="boolean" required="false" default="false">
	<cfset var list = []>
	<cfset var e = "">
	<cfset var found = ormExecuteQuery("FROM Product WHERE BlogRef = :blogId #arguments.activeOnly ? 'AND Active = :on' : ''# ORDER BY Name",
		arguments.activeOnly ? { blogId = blogId(), on = true } : { blogId = blogId() })>
	<cfloop array="#found#" index="e">
		<cfset arrayAppend(list, productToStruct(e))>
	</cfloop>
	<cfreturn list>
</cffunction>

<cffunction name="getProduct" access="public" returntype="struct" output="false" hint="A product by id or alias, or an empty struct.">
	<cfargument name="productId" required="false" default="0">
	<cfargument name="alias" type="string" required="false" default="">
	<cfset var e = loadProduct(arguments.productId, arguments.alias)>
	<cfreturn isNull(e) ? {} : productToStruct(e)>
</cffunction>

<cffunction name="saveProduct" access="public" returntype="struct" output="false"
		hint="Adds or changes a product. data: { productId, name, alias, description, imageUrl, kind, price, shippingPrice, trackStock, stock, active }. Returns { success, productId, errors }.">
	<cfargument name="data" type="struct" required="true">
	<cfset var result = { success: false, productId: 0, errors: {} }>
	<cfset var d = arguments.data>
	<cfset var e = "">
	<cfset var name = trim(d.name ?: "")>
	<cfset var kind = lCase(trim(d.kind ?: "physical"))>
	<cfset var price = trim(d.price ?: "")>
	<cfset var shipping = trim(d.shippingPrice ?: "")>
	<cfset var productAlias = makeAlias(len(trim(d.alias ?: "")) ? d.alias : name)>
	<cfset var clash = []>
	<cfset var productId = val(d.productId ?: 0)>
	<cfif not len(name)><cfset result.errors.name = "Please give the product a name."></cfif>
	<cfif not listFind(variables.kinds, kind)><cfset kind = "physical"></cfif>
	<cfif not isNumeric(price) or price lt 0><cfset result.errors.price = "Please enter a price, such as 19.99."></cfif>
	<cfif len(shipping) and (not isNumeric(shipping) or shipping lt 0)><cfset result.errors.shippingPrice = "Please enter a shipping price, or leave it empty for free shipping."></cfif>
	<cfif not len(productAlias)><cfset productAlias = "product"></cfif>
	<cfset clash = ormExecuteQuery("SELECT ProductId FROM Product WHERE BlogRef = :blogId AND Alias = :alias AND ProductId <> :id", { blogId = blogId(), alias = productAlias, id = javacast("int", productId) })>
	<cfif arrayLen(clash)><cfset productAlias = left(productAlias, 90) & "-" & lCase(left(hash(createUUID()), 4))></cfif>
	<cfif not structIsEmpty(result.errors)>
		<cfreturn result>
	</cfif>
	<cftransaction>
		<cfif productId gt 0>
			<cfset e = loadProduct(productId, "")>
			<cfif isNull(e)>
				<cfset result.errors.name = "This product no longer exists.">
				<cfreturn result>
			</cfif>
		<cfelse>
			<cfset e = entityNew("Product")>
			<cfset e.setBlogRef(javacast("int", blogId()))>
			<cfset e.setFileName("")>
			<cfset e.setFileDisplayName("")>
			<cfset e.setCreated(now())>
		</cfif>
		<cfset e.setName(left(name, 255))>
		<cfset e.setAlias(productAlias)>
		<cfset e.setDescription(trim(d.description ?: ""))>
		<cfset e.setImageUrl(left(trim(d.imageUrl ?: ""), 500))>
		<cfset e.setKind(kind)>
		<cfset e.setPrice(javacast("bigdecimal", round(val(price) * 100) / 100))>
		<cfset e.setShippingPrice(javacast("bigdecimal", kind eq "physical" ? round(val(shipping) * 100) / 100 : 0))>
		<cfset e.setTrackStock(isTrue(d.trackStock ?: false))>
		<cfset e.setStock(javacast("int", max(0, int(val(d.stock ?: 0)))))>
		<cfset e.setActive(isTrue(d.active ?: true))>
		<cfset e.setDate(now())>
		<cfset entitySave(e)>
	</cftransaction>
	<cfset result.success = true>
	<cfset result.productId = e.getProductId()>
	<cfreturn result>
</cffunction>

<cffunction name="deleteProduct" access="public" returntype="struct" output="false"
		hint="Deletes a product that was never ordered; one that was is switched off instead, so its orders keep their history. Returns { success, deleted, message }.">
	<cfargument name="productId" type="numeric" required="true">
	<cfset var e = loadProduct(arguments.productId, "")>
	<cfset var ordered = 0>
	<cfif isNull(e)>
		<cfreturn { success: false, deleted: false, message: "This product no longer exists." }>
	</cfif>
	<cfset ordered = ormExecuteQuery("SELECT count(*) FROM ShopOrderItem WHERE ProductRef = :id", { id = javacast("int", arguments.productId) }, true)>
	<cftransaction>
		<cfif ordered gt 0>
			<cfset e.setActive(false)>
			<cfset e.setDate(now())>
			<cfset entitySave(e)>
		<cfelse>
			<cfset deleteStoredFile(valueOrEmpty(e.getFileName()))>
			<cfset entityDelete(e)>
		</cfif>
	</cftransaction>
	<cfreturn { success: true, deleted: ordered eq 0, message: ordered gt 0 ? "This product has orders, so it was switched off instead of deleted." : "" }>
</cffunction>

<cffunction name="saveProductFile" access="public" returntype="struct" output="false"
		hint="Stores a digital product's file in the shop's private folder under a random name, replacing the old one. Returns { success, message, displayName }.">
	<cfargument name="productId" type="numeric" required="true">
	<cfargument name="tempPath" type="string" required="true">
	<cfargument name="originalName" type="string" required="true">
	<cfset var e = loadProduct(arguments.productId, "")>
	<cfset var folder = getFileFolder()>
	<cfset var ext = lCase(listLast(arguments.originalName, "."))>
	<cfset var storedName = lCase(hash(createUUID() & arguments.originalName, "SHA-256")) & ".bin">
	<cfset var displayName = reReplace(getFileFromPath(arguments.originalName), "[^A-Za-z0-9._ -]", "_", "all")>
	<cfif isNull(e)>
		<cfreturn { success: false, message: "Save the product first.", displayName: "" }>
	</cfif>
	<!--- Never anything the server could run. --->
	<cfif listFindNoCase("cfm,cfc,cfml,jsp,php,asp,aspx,exe,bat,cmd,sh,js,html,htm,svg", ext) or not len(displayName)>
		<cfreturn { success: false, message: "This kind of file can't be sold as a download. Zip it first.", displayName: "" }>
	</cfif>
	<cfif not len(folder)>
		<cfreturn { success: false, message: "The shop's private folder couldn't be made. Check the folder permissions.", displayName: "" }>
	</cfif>
	<cffile action="move" source="#arguments.tempPath#" destination="#folder##storedName#">
	<cfset deleteStoredFile(valueOrEmpty(e.getFileName()))>
	<cftransaction>
		<cfset e.setFileName(storedName)>
		<cfset e.setFileDisplayName(left(displayName, 255))>
		<cfset e.setDate(now())>
		<cfset entitySave(e)>
	</cftransaction>
	<cfreturn { success: true, message: "", displayName: displayName }>
</cffunction>

<cffunction name="saveProductImage" access="public" returntype="struct" output="false"
		hint="Stores a product picture in /images/shop/ (public) and returns { success, message, url }. Booking types' pictures use the same, in /images/bookings/ (2026-10-22).">
	<cfargument name="tempPath" type="string" required="true">
	<cfargument name="originalName" type="string" required="true">
	<cfargument name="pictureFolder" type="string" required="false" default="shop" hint="shop or bookings.">
	<cfset var ext = lCase(listLast(arguments.originalName, "."))>
	<cfset var folderName = arguments.pictureFolder eq "bookings" ? "bookings" : "shop">
	<cfset var folder = expandPath(application.baseUrl & "/images/" & folderName & "/")>
	<cfset var fileName = lCase(left(hash(createUUID()), 16)) & "." & ext>
	<cfif not listFind("jpg,jpeg,png,webp,gif", ext) or not isImageFile(arguments.tempPath)>
		<cfreturn { success: false, message: "Please choose a picture (jpg, png, webp or gif).", url: "" }>
	</cfif>
	<cfif not directoryExists(folder)><cfdirectory action="create" directory="#folder#"></cfif>
	<cffile action="move" source="#arguments.tempPath#" destination="#folder##fileName#">
	<cfif server.os.name does not contain "Windows">
		<cftry><cfset fileSetAccessMode(folder & fileName, "644")><cfcatch type="any"></cfcatch></cftry>
	</cfif>
	<cfreturn { success: true, message: "", url: application.baseUrl & "/images/" & folderName & "/" & fileName }>
</cffunction>

<cffunction name="getProductsForPage" access="public" returntype="array" output="false"
		hint="What a visitor's page needs to show products (by alias): name, picture, price and whether it can be bought. Nothing private (no file names, no stock count).">
	<cfargument name="aliases" type="string" required="true" hint="A comma-separated list, or * for every product shown on the site (a shop page).">
	<cfset var list = []>
	<cfset var a = "">
	<cfset var p = "">
	<cfset var settings = getSettings()>
	<cfset var found = []>
	<cfif trim(arguments.aliases) eq "*">
		<cfset found = listProducts(activeOnly = true)>
	<cfelse>
		<cfloop list="#arguments.aliases#" index="a">
			<cfset arrayAppend(found, getProduct(alias = left(trim(a), 100)))>
		</cfloop>
	</cfif>
	<cfloop array="#found#" index="p">
		<cfif not structIsEmpty(p) and p.active>
			<cfset arrayAppend(list, {
				"alias": p.alias, "name": p.name, "description": p.description, "imageUrl": p.imageUrl, "kind": p.kind,
				"price": p.price, "priceText": p.priceText, "soldOut": p.soldOut,
				"shippingText": p.kind eq "physical" ? (p.shippingPrice gt 0 ? money(p.shippingPrice) : "Free") : "",
				"available": settings.enabled and settings.paymentsReady and not p.soldOut
			})>
		</cfif>
	</cfloop>
	<cfreturn list>
</cffunction>

<!---//*****************************************************************************************
		Shop pages (2026-10-21, owner): like a booking page, a Page whose text is followed by products - every product (*) or
		the ones picked (their aliases, comma separated). The offer is the page's own setting 'shopOffer' in BlogEventSetting.
		Made from New post > Shop, or a page's Post Type in the post editor; set up in the Shop page window (116,
		admin/adminInterface/shopPageDetail.cfm). Ordinary posts and pages can still hold products, with Insert > Product.
//******************************************************************************************--->

<cffunction name="getPageOffer" access="public" returntype="string" output="false" hint="What a shop page offers (* or product aliases), or '' when the page isn't a shop page.">
	<cfargument name="postId" type="numeric" required="true">
	<cfreturn application.events.getSetting(arguments.postId, "shopOffer", "")>
</cffunction>

<cffunction name="setPageOffer" access="public" returntype="struct" output="false" hint="Makes a page a shop page, or changes what it offers. Returns { success, errors[] }.">
	<cfargument name="postId" type="numeric" required="true">
	<cfargument name="offer" type="string" required="true" hint="* or a comma-separated list of product aliases.">
	<cfset var result = { success: false, errors: [] }>
	<cfset var cleanOffer = "">
	<cfset var alias = "">
	<cfif trim(arguments.offer) eq "*">
		<cfset cleanOffer = "*">
	<cfelse>
		<!--- Only this blog's products, each once. --->
		<cfloop list="#arguments.offer#" index="alias">
			<cfif not structIsEmpty(getProduct(alias = left(trim(alias), 100))) and not listFind(cleanOffer, trim(alias))>
				<cfset cleanOffer = listAppend(cleanOffer, trim(alias))>
			</cfif>
		</cfloop>
	</cfif>
	<cfif not len(cleanOffer)>
		<cfset arrayAppend(result.errors, "Choose what the page offers: every product, or the ones to show.")>
		<cfreturn result>
	</cfif>
	<cfset application.events.setSetting(arguments.postId, "shopOffer", left(cleanOffer, 500))>
	<cfset result.success = true>
	<cfreturn result>
</cffunction>

<cffunction name="removePage" access="public" returntype="void" output="false" hint="Makes a shop page an ordinary page again (its text stays).">
	<cfargument name="postId" type="numeric" required="true">
	<cfset application.events.deleteSetting(arguments.postId, "shopOffer")>
</cffunction>

<cffunction name="offerLabel" access="public" returntype="string" output="false" hint="A shop page's offer in words: 'All products', or the products' names.">
	<cfargument name="offer" type="string" required="true">
	<cfset var names = []>
	<cfset var alias = "">
	<cfset var p = "">
	<cfif arguments.offer eq "*"><cfreturn "All products"></cfif>
	<cfloop list="#arguments.offer#" index="alias">
		<cfset p = getProduct(alias = alias)>
		<cfif not structIsEmpty(p)><cfset arrayAppend(names, p.name)></cfif>
	</cfloop>
	<cfreturn arrayLen(names) gt 3 ? arrayLen(names) & " products" : arrayToList(names, ", ")>
</cffunction>

<cffunction name="getShopPages" access="public" returntype="array" output="false" hint="This blog's shop pages, for the Products window: [{ postId, title, url, released, offer, label }].">
	<cfset var pages = []>
	<cfset var rows = "">
	<cftry>
		<cfset rows = queryExecute("
			SELECT s.PostRef, s.SettingValue, p.Title, p.PostAlias, p.DatePosted, p.Released
			FROM BlogEventSetting s INNER JOIN Post p ON p.PostId = s.PostRef
			WHERE s.BlogRef = :blogId AND s.SettingName = 'shopOffer' AND p.Remove = 0
			ORDER BY p.Title", { blogId = { value = blogId(), cfsqltype = "cf_sql_integer" } })>
		<cfcatch type="any"><cfreturn pages></cfcatch>
	</cftry>
	<cfloop query="rows">
		<cfif len(rows.SettingValue)>
			<cfset arrayAppend(pages, {
				postId: rows.PostRef, title: rows.Title,
				url: application.blog.makeLink(isPage = true, postAlias = rows.PostAlias, datePosted = rows.DatePosted),
				released: isBoolean(rows.Released) and rows.Released, offer: rows.SettingValue, label: offerLabel(rows.SettingValue)
			})>
		</cfif>
	</cfloop>
	<cfreturn pages>
</cffunction>

<cffunction name="renderPageWidgetHtml" access="public" returntype="string" output="false" hint="The products under a shop page's text, or '' for any other page. common/js/shop.js fills them in.">
	<cfargument name="postId" type="numeric" required="true">
	<cfset var offer = "">
	<cftry>
		<cfset offer = getPageOffer(arguments.postId)>
		<cfcatch type="any"><cfreturn ""></cfcatch>
	</cftry>
	<cfif not len(offer)><cfreturn ""></cfif>
	<cfreturn '<div class="galaxieProduct galaxieShopPage" data-product="' & encodeForHtmlAttribute(offer) & '"></div>'>
</cffunction>

<!---//*****************************************************************************************
		Cart and checkout
//******************************************************************************************--->

<cffunction name="priceCart" access="public" returntype="struct" output="false"
		hint="Checks a cart against the products as they are now. items: [{ alias, quantity }]. Returns { lines, subtotal, shipping, tax, taxLabel, total, needsShipping, currency, errors, and the same amounts as text }. Shipping is the highest flat shipping price among the physical products, once per order.">
	<cfargument name="items" type="array" required="true">
	<cfset var result = { lines: [], subtotal: 0, shipping: 0, tax: 0, taxLabel: "", total: 0, needsShipping: false, currency: application.payments.getCurrency(), errors: [] }>
	<cfset var item = "">
	<cfset var p = "">
	<cfset var qty = 0>
	<cfset var taxInfo = "">
	<cfset var seen = {}>
	<cfloop array="#arguments.items#" index="item">
		<cfif isStruct(item) and structKeyExists(item, "alias") and not structKeyExists(seen, item.alias)>
			<cfset seen[item.alias] = true>
			<cfset p = getProduct(alias = left(trim(item.alias), 100))>
			<cfset qty = min(max(int(val(item.quantity ?: 1)), 1), 99)>
			<cfif structIsEmpty(p) or not p.active>
				<cfset arrayAppend(result.errors, "One of the products in your cart is no longer for sale, so it was taken out.")>
			<cfelseif p.soldOut>
				<cfset arrayAppend(result.errors, p.name & " is sold out, so it was taken out of your cart.")>
			<cfelse>
				<cfif p.trackStock and qty gt p.stock>
					<cfset qty = p.stock>
					<cfset arrayAppend(result.errors, "Only " & p.stock & " of " & p.name & " " & (p.stock eq 1 ? "is" : "are") & " left, so your cart now has " & p.stock & ".")>
				</cfif>
				<cfset arrayAppend(result.lines, {
					"productId": p.productId, "alias": p.alias, "name": p.name, "kind": p.kind, "imageUrl": p.imageUrl,
					"unitPrice": p.price, "quantity": qty, "lineTotal": round(p.price * qty * 100) / 100,
					"unitPriceText": p.priceText, "lineTotalText": money(p.price * qty)
				})>
				<cfset result.subtotal = result.subtotal + p.price * qty>
				<cfif p.kind eq "physical">
					<cfset result.needsShipping = true>
					<cfset result.shipping = max(result.shipping, p.shippingPrice)>
				</cfif>
			</cfif>
		</cfif>
	</cfloop>
	<cfset result.subtotal = round(result.subtotal * 100) / 100>
	<cfset taxInfo = application.payments.getTax(result.subtotal)>
	<cfset result.tax = taxInfo.amount>
	<cfset result.taxLabel = taxInfo.label>
	<cfset result.total = round((result.subtotal + result.shipping + result.tax) * 100) / 100>
	<cfset result.subtotalText = money(result.subtotal)>
	<cfset result.shippingText = result.needsShipping ? (result.shipping gt 0 ? money(result.shipping) : "Free") : "">
	<cfset result.taxText = result.tax gt 0 ? money(result.tax) : "">
	<cfset result.totalText = money(result.total)>
	<cfreturn result>
</cffunction>

<cffunction name="startCheckout" access="public" returntype="struct" output="false"
		hint="Makes a pending order from the cart and opens Stripe's checkout for it. Returns { success, checkoutUrl, message, cart } (cart: the checked cart, when it changed).">
	<cfargument name="items" type="array" required="true">
	<cfargument name="email" type="string" required="false" default="">
	<cfargument name="returnUrl" type="string" required="true" hint="Already checked to be on this blog.">
	<cfset var result = { success: false, checkoutUrl: "", message: "", cart: {} }>
	<cfset var settings = getSettings()>
	<cfset var cart = priceCart(arguments.items)>
	<cfset var member = application.members.getCurrentMember()>
	<cfset var buyerEmail = trim(arguments.email)>
	<cfset var order = "">
	<cfset var line = "">
	<cfset var orderItem = "">
	<cfset var lines = []>
	<cfset var checkout = "">
	<cfset var backTo = arguments.returnUrl & (find("?", arguments.returnUrl) ? "&" : "?")>
	<cfif not settings.enabled or not settings.paymentsReady>
		<cfset result.message = "The shop isn't open right now.">
		<cfreturn result>
	</cfif>
	<cfif arrayLen(cart.errors) or not arrayLen(cart.lines)>
		<cfset result.message = arrayLen(cart.errors) ? arrayToList(cart.errors, " ") : "Your cart is empty.">
		<cfset result.cart = cart>
		<cfreturn result>
	</cfif>
	<cfif not isValid("email", buyerEmail) and not structIsEmpty(member)><cfset buyerEmail = member.email></cfif>
	<cftransaction>
		<cfset order = entityNew("ShopOrder")>
		<cfset order.setBlogRef(javacast("int", blogId()))>
		<cfset order.setOrderToken(lCase(hash(createUUID() & now() & rand(), "SHA-256")))>
		<cfset order.setName(structIsEmpty(member) ? "" : left(member.name, 255))>
		<cfset order.setEmail(isValid("email", buyerEmail) ? left(buyerEmail, 255) : "")>
		<cfset order.setMemberRef(javacast("int", structIsEmpty(member) ? 0 : member.memberId))>
		<cfset order.setNeedsShipping(cart.needsShipping)>
		<cfset order.setShipName("")>
		<cfset order.setShipLine1("")>
		<cfset order.setShipLine2("")>
		<cfset order.setShipCity("")>
		<cfset order.setShipState("")>
		<cfset order.setShipPostalCode("")>
		<cfset order.setShipCountry("")>
		<cfset order.setSubtotal(javacast("bigdecimal", cart.subtotal))>
		<cfset order.setShippingAmount(javacast("bigdecimal", cart.shipping))>
		<cfset order.setTaxAmount(javacast("bigdecimal", cart.tax))>
		<cfset order.setDiscountAmount(javacast("bigdecimal", 0))>
		<cfset order.setTotal(javacast("bigdecimal", cart.total))>
		<cfset order.setCurrency(uCase(cart.currency))>
		<cfset order.setStatus("pending")>
		<cfset order.setTestMode(settings.testMode)>
		<cfset order.setCreated(now())>
		<cfset order.setDate(now())>
		<cfset entitySave(order)>
		<cfloop array="#cart.lines#" index="line">
			<cfset orderItem = entityNew("ShopOrderItem")>
			<cfset orderItem.setShopOrderRef(javacast("int", order.getShopOrderId()))>
			<cfset orderItem.setProductRef(javacast("int", line.productId))>
			<cfset orderItem.setProductName(left(line.name, 255))>
			<cfset orderItem.setKind(line.kind)>
			<cfset orderItem.setUnitPrice(javacast("bigdecimal", line.unitPrice))>
			<cfset orderItem.setQuantity(javacast("int", line.quantity))>
			<cfset orderItem.setDownloadToken("")>
			<cfset orderItem.setDownloadCount(javacast("int", 0))>
			<cfset entitySave(orderItem)>
			<cfset arrayAppend(lines, { name: line.name, description: "", unitPrice: line.unitPrice, quantity: line.quantity })>
		</cfloop>
	</cftransaction>
	<cfset checkout = application.payments.createShopCheckout(
		shopOrderId = order.getShopOrderId(),
		lines = lines,
		shippingAmount = cart.shipping,
		collectShipping = cart.needsShipping,
		allowPromotionCodes = settings.promotionCodes,
		currencyCode = cart.currency,
		email = order.getEmail(),
		successUrl = backTo & "shopCheckout={CHECKOUT_SESSION_ID}",
		cancelUrl = backTo & "shopCancelled=" & order.getOrderToken()
	)>
	<cfif not checkout.success>
		<cfset setOrderStatus(order.getShopOrderId(), "cancelled")>
		<cfset result.message = checkout.message>
		<cfreturn result>
	</cfif>
	<cfset result.success = true>
	<cfset result.checkoutUrl = checkout.url>
	<cfreturn result>
</cffunction>

<cffunction name="getCheckoutResult" access="public" returntype="struct" output="false"
		hint="For the buyer coming back from Stripe: { success, paid, status, needsShipping, downloads, itemsHtml, email }. If the webhook hasn't arrived yet, the blog asks Stripe itself (with its secret key), so a paid order is confirmed either way.">
	<cfargument name="sessionId" type="string" required="true">
	<cfset var result = { "success": false, "paid": false, "status": "", "needsShipping": false, "downloads": [], "itemsHtml": "", "email": "" }>
	<cfset var payment = application.payments.getPaymentBySession(trim(arguments.sessionId))>
	<cfset var order = {}>
	<cfif structIsEmpty(payment) or payment.shopOrderId lte 0>
		<cfreturn result>
	</cfif>
	<cfif payment.status eq "pending">
		<cfset confirmFromStripe(trim(arguments.sessionId))>
	</cfif>
	<cfset order = getOrder(payment.shopOrderId)>
	<cfif structIsEmpty(order)>
		<cfreturn result>
	</cfif>
	<cfset result[ "success" ] = true>
	<cfset result[ "status" ] = order.status>
	<cfset result[ "paid" ] = listFind(variables.paidStatuses, order.status) gt 0>
	<cfset result[ "needsShipping" ] = order.needsShipping>
	<cfset result[ "email" ] = order.email>
	<cfif result.paid>
		<cfset result[ "itemsHtml" ] = order.itemsHtml>
		<!--- The buyer's browser keeps it, so the product shows "You bought..." when they come back (getBought, 2026-10-22). --->
		<cfset result[ "orderToken" ] = order.orderToken>
		<!--- Quoted keys: Adobe ColdFusion sends unquoted ones in capitals (NAME, URL), which the page wouldn't find. --->
		<cfloop array="#order.downloads#" index="local.download">
			<cfset arrayAppend(result.downloads, { "name": local.download.name, "url": local.download.url, "expires": local.download.expires })>
		</cfloop>
	</cfif>
	<cfreturn result>
</cffunction>

<cffunction name="cancelCheckout" access="public" returntype="boolean" output="false"
		hint="The buyer came back without paying: closes their checkout and drops the pending order.">
	<cfargument name="orderToken" type="string" required="true">
	<cfset var found = []>
	<cfset var payment = "">
	<cfif not reFind("^[a-f0-9]{64}$", arguments.orderToken)>
		<cfreturn false>
	</cfif>
	<cfset found = ormExecuteQuery("FROM ShopOrder WHERE OrderToken = :t AND BlogRef = :blogId AND Status = 'pending'", { t = arguments.orderToken, blogId = blogId() })>
	<cfif not arrayLen(found)>
		<cfreturn false>
	</cfif>
	<cfset found = ormExecuteQuery("FROM Payment WHERE ShopOrderRef = :id AND BlogRef = :blogId AND Status = 'pending'", { id = javacast("int", found[1].getShopOrderId()), blogId = blogId() })>
	<cfloop array="#found#" index="payment">
		<cfset application.payments.expireCheckout(payment.getProviderSessionId())>
		<cfset application.payments.setPaymentStatus(payment.getProviderSessionId(), "cancelled", 0, "")>
		<cfset setOrderStatus(val(payment.getShopOrderRef()), "cancelled")>
	</cfloop>
	<cfreturn true>
</cffunction>

<cffunction name="confirmFromStripe" access="public" returntype="boolean" output="false"
		hint="Asks Stripe about a checkout and, if it was paid, confirms the order as the webhook would. Safe to call more than once.">
	<cfargument name="sessionId" type="string" required="true">
	<cfset var cs = application.payments.getCheckoutSession(arguments.sessionId)>
	<cfset var payment = "">
	<cfif structIsEmpty(cs) or (cs.payment_status ?: "") neq "paid">
		<cfreturn false>
	</cfif>
	<cfset payment = application.payments.getPaymentBySession(arguments.sessionId)>
	<cfif structIsEmpty(payment) or payment.shopOrderId lte 0>
		<cfreturn false>
	</cfif>
	<cfif payment.status eq "pending">
		<cfset application.payments.setPaymentStatus(arguments.sessionId, "paid", application.payments.fromMinorUnits(cs.amount_total ?: 0, cs.currency ?: payment.currency), cs.payment_intent ?: "")>
	</cfif>
	<cfreturn confirmPaidOrder(payment.shopOrderId, cs)>
</cffunction>

<cffunction name="confirmPaidOrder" access="public" returntype="boolean" output="false"
		hint="Called once Stripe confirms the payment (the webhook, or confirmFromStripe): marks the order paid, keeps the shipping address and what was paid, takes the products off the stock count, makes the download links and sends the emails. Does nothing the second time.">
	<cfargument name="shopOrderId" type="numeric" required="true">
	<cfargument name="checkoutSession" type="struct" required="false" default="#{}#" hint="Stripe's Checkout Session object.">
	<cfset var cs = arguments.checkoutSession>
	<cfset var order = "">
	<cfset var items = "">
	<cfset var item = "">
	<cfset var product = "">
	<cfset var ship = {}>
	<cfset var address = {}>
	<cfset var settings = getSettings()>
	<cfset var details = {}>
	<cflock name="galaxieShopOrder#arguments.shopOrderId#" type="exclusive" timeout="20">
		<cfset order = loadOrder(arguments.shopOrderId)>
		<cfif isNull(order) or listFind(variables.paidStatuses, valueOrEmpty(order.getStatus()))>
			<cfreturn false>
		</cfif>
		<!--- Stripe has moved the shipping details over the years: collected_information.shipping_details, then shipping_details. --->
		<cfif structKeyExists(cs, "collected_information") and isStruct(cs.collected_information) and structKeyExists(cs.collected_information, "shipping_details") and isStruct(cs.collected_information.shipping_details)>
			<cfset ship = cs.collected_information.shipping_details>
		<cfelseif structKeyExists(cs, "shipping_details") and isStruct(cs.shipping_details)>
			<cfset ship = cs.shipping_details>
		</cfif>
		<cfif structKeyExists(ship, "address") and isStruct(ship.address)><cfset address = ship.address></cfif>
		<cfif structKeyExists(cs, "customer_details") and isStruct(cs.customer_details)>
			<cfset details = cs.customer_details>
		</cfif>
		<cftransaction>
			<cfset order.setStatus("paid")>
			<cfset order.setPaidAt(now())>
			<cfif not len(valueOrEmpty(order.getEmail())) and isValid("email", details.email ?: "")><cfset order.setEmail(left(details.email, 255))></cfif>
			<cfif not len(valueOrEmpty(order.getName())) and len(details.name ?: "")><cfset order.setName(left(details.name, 255))></cfif>
			<cfif structCount(address)>
				<cfset order.setShipName(left(ship.name ?: "", 255))>
				<cfset order.setShipLine1(left(address.line1 ?: "", 255))>
				<cfset order.setShipLine2(left(address.line2 ?: "", 255))>
				<cfset order.setShipCity(left(address.city ?: "", 255))>
				<cfset order.setShipState(left(address.state ?: "", 255))>
				<cfset order.setShipPostalCode(left(address.postal_code ?: "", 50))>
				<cfset order.setShipCountry(left(address.country ?: "", 10))>
			</cfif>
			<cfif structKeyExists(cs, "amount_total") and isNumeric(cs.amount_total)>
				<cfset order.setTotal(javacast("bigdecimal", application.payments.fromMinorUnits(cs.amount_total, valueOrEmpty(order.getCurrency()))))>
			</cfif>
			<cfif structKeyExists(cs, "total_details") and isStruct(cs.total_details) and isNumeric(cs.total_details.amount_discount ?: "")>
				<cfset order.setDiscountAmount(javacast("bigdecimal", application.payments.fromMinorUnits(cs.total_details.amount_discount, valueOrEmpty(order.getCurrency()))))>
			</cfif>
			<cfset order.setDate(now())>
			<cfset entitySave(order)>
			<cfset items = ormExecuteQuery("FROM ShopOrderItem WHERE ShopOrderRef = :id", { id = javacast("int", arguments.shopOrderId) })>
			<cfloop array="#items#" index="item">
				<cfset product = loadProduct(val(item.getProductRef()), "")>
				<cfif not isNull(product) and isTrue(product.getTrackStock())>
					<!--- Stock goes down when the payment is confirmed; two buyers paying for the last one at once can take it below
					zero, which shows as 0 (Sold out) and the owner sees both orders. --->
					<cfset product.setStock(javacast("int", max(0, val(product.getStock()) - val(item.getQuantity()))))>
					<cfset entitySave(product)>
				</cfif>
				<cfif valueOrEmpty(item.getKind()) eq "digital">
					<cfset item.setDownloadToken(lCase(hash(createUUID() & item.getShopOrderItemId() & rand(), "SHA-256")))>
					<cfset item.setDownloadCount(javacast("int", 0))>
					<cfset item.setDownloadExpiresAt(dateAdd("d", settings.downloadDays, now()))>
					<cfset entitySave(item)>
				</cfif>
			</cfloop>
		</cftransaction>
	</cflock>
	<cfset sendOrderEmails(arguments.shopOrderId)>
	<cfset clearAdminCounts()>
	<cfreturn true>
</cffunction>

<cffunction name="expireOrder" access="public" returntype="void" output="false" hint="An unpaid checkout closed (webhook checkout.session.expired): the pending order is dropped.">
	<cfargument name="shopOrderId" type="numeric" required="true">
	<cfset var order = loadOrder(arguments.shopOrderId)>
	<cfif not isNull(order) and valueOrEmpty(order.getStatus()) eq "pending">
		<cfset setOrderStatus(arguments.shopOrderId, "expired")>
	</cfif>
</cffunction>

<!---//*****************************************************************************************
		Orders (admin)
//******************************************************************************************--->

<cffunction name="getOrdersForGrid" access="public" returntype="array" output="false"
		hint="Orders for the Orders window, newest first. Unpaid checkouts (pending, expired, cancelled) only when asked for.">
	<cfargument name="includeUnpaid" type="boolean" required="false" default="false">
	<cfset var list = []>
	<cfset var q = queryExecute("
		SELECT o.ShopOrderId, o.Name, o.Email, o.Status, o.Total, o.Currency, o.NeedsShipping, o.TestMode, o.Created, o.PaidAt, o.ShippedAt,
			(SELECT COUNT(*) FROM ShopOrderItem i WHERE i.ShopOrderRef = o.ShopOrderId) AS ItemCount,
			(SELECT i2.ProductName FROM ShopOrderItem i2 WHERE i2.ShopOrderItemId = (SELECT MIN(i3.ShopOrderItemId) FROM ShopOrderItem i3 WHERE i3.ShopOrderRef = o.ShopOrderId)) AS FirstItem
		FROM ShopOrder o
		WHERE o.BlogRef = :blogId #arguments.includeUnpaid ? '' : "AND o.Status IN ('paid','shipped','partlyRefunded','refunded')"#
		ORDER BY o.ShopOrderId DESC",
		{ blogId = { value = blogId(), cfsqltype = "cf_sql_integer" } }, { datasource = application.dsn, maxrows = 2000 })>
	<cfloop query="q">
		<cfset arrayAppend(list, [
			"ShopOrderId": q.ShopOrderId,
			"OrderNumber": orderNumber(q.ShopOrderId),
			"Name": toString(q.Name),
			"Email": toString(q.Email),
			"Items": toString(q.FirstItem) & (q.ItemCount gt 1 ? " and " & (q.ItemCount - 1) & " more" : ""),
			"Total": money(val(q.Total), toString(q.Currency)),
			"Status": statusLabel(toString(q.Status), isTrue(q.NeedsShipping), isDate(q.ShippedAt)),
			"TestMode": isTrue(q.TestMode),
			"Date": isDate(q.PaidAt) ? dateFormat(q.PaidAt, "yyyy-mm-dd") & " " & timeFormat(q.PaidAt, "HH:nn") : dateFormat(q.Created, "yyyy-mm-dd") & " " & timeFormat(q.Created, "HH:nn")
		])>
	</cfloop>
	<cfreturn list>
</cffunction>

<cffunction name="getOrder" access="public" returntype="struct" output="false"
		hint="One order with its products, amounts, shipping address, payments and download links, or an empty struct.">
	<cfargument name="shopOrderId" type="numeric" required="true">
	<cfset var o = loadOrder(arguments.shopOrderId)>
	<cfset var result = {}>
	<cfset var items = []>
	<cfset var item = "">
	<cfset var cur = "">
	<cfset var html = "">
	<cfif isNull(o)>
		<cfreturn {}>
	</cfif>
	<cfset cur = valueOrEmpty(o.getCurrency())>
	<cfset result = {
		shopOrderId: o.getShopOrderId(),
		orderNumber: orderNumber(o.getShopOrderId()),
		orderToken: valueOrEmpty(o.getOrderToken()),
		name: valueOrEmpty(o.getName()),
		email: valueOrEmpty(o.getEmail()),
		memberId: val(valueOrEmpty(o.getMemberRef())),
		status: valueOrEmpty(o.getStatus()),
		statusLabel: statusLabel(valueOrEmpty(o.getStatus()), isTrue(o.getNeedsShipping()), not isNull(o.getShippedAt())),
		needsShipping: isTrue(o.getNeedsShipping()),
		address: [],
		subtotal: val(valueOrEmpty(o.getSubtotal())),
		shipping: val(valueOrEmpty(o.getShippingAmount())),
		tax: val(valueOrEmpty(o.getTaxAmount())),
		discount: val(valueOrEmpty(o.getDiscountAmount())),
		total: val(valueOrEmpty(o.getTotal())),
		currency: cur,
		testMode: isTrue(o.getTestMode()),
		created: o.getCreated(),
		paidAt: isNull(o.getPaidAt()) ? "" : o.getPaidAt(),
		shippedAt: isNull(o.getShippedAt()) ? "" : o.getShippedAt(),
		items: [],
		downloads: [],
		refundable: 0,
		refunded: 0
	}>
	<cfloop array="#[valueOrEmpty(o.getShipName()), valueOrEmpty(o.getShipLine1()), valueOrEmpty(o.getShipLine2())]#" index="item">
		<cfif len(trim(item))><cfset arrayAppend(result.address, trim(item))></cfif>
	</cfloop>
	<cfset html = trim(valueOrEmpty(o.getShipCity()) & " " & valueOrEmpty(o.getShipState()) & " " & valueOrEmpty(o.getShipPostalCode()))>
	<cfif len(html)><cfset arrayAppend(result.address, html)></cfif>
	<cfif len(valueOrEmpty(o.getShipCountry()))><cfset arrayAppend(result.address, valueOrEmpty(o.getShipCountry()))></cfif>
	<cfset items = ormExecuteQuery("FROM ShopOrderItem WHERE ShopOrderRef = :id ORDER BY ShopOrderItemId", { id = javacast("int", arguments.shopOrderId) })>
	<cfloop array="#items#" index="item">
		<cfset arrayAppend(result.items, {
			name: valueOrEmpty(item.getProductName()), kind: valueOrEmpty(item.getKind()), quantity: val(item.getQuantity()),
			unitPrice: val(valueOrEmpty(item.getUnitPrice())), lineTotalText: money(val(valueOrEmpty(item.getUnitPrice())) * val(item.getQuantity()), cur),
			downloadCount: val(valueOrEmpty(item.getDownloadCount()))
		})>
		<cfif len(valueOrEmpty(item.getDownloadToken()))>
			<cfset arrayAppend(result.downloads, {
				name: valueOrEmpty(item.getProductName()),
				url: application.blogHostUrl & "/common/services/shopDownload.cfm?t=" & item.getDownloadToken(),
				expires: isNull(item.getDownloadExpiresAt()) ? "" : dateFormat(item.getDownloadExpiresAt(), "mmmm d, yyyy"),
				used: val(valueOrEmpty(item.getDownloadCount()))
			})>
		</cfif>
	</cfloop>
	<cfset result.itemsHtml = itemsTable(result)>
	<cfif listFind(variables.paidStatuses, result.status)>
		<cfset item = application.payments.getShopOrderPaymentTotals(arguments.shopOrderId)>
		<cfset result.refundable = item.refundable>
		<cfset result.refunded = item.refunded>
	</cfif>
	<cfreturn result>
</cffunction>

<cffunction name="markShipped" access="public" returntype="struct" output="false" hint="Marks a paid order as shipped (or back to paid), and tells the buyer the first time.">
	<cfargument name="shopOrderId" type="numeric" required="true">
	<cfargument name="shipped" type="boolean" required="false" default="true">
	<cfargument name="tellBuyer" type="boolean" required="false" default="true">
	<cfset var o = loadOrder(arguments.shopOrderId)>
	<cfset var wasShipped = false>
	<cfif isNull(o) or not listFind("paid,shipped,partlyRefunded", valueOrEmpty(o.getStatus()))>
		<cfreturn { success: false, message: "Only a paid order can be marked as shipped." }>
	</cfif>
	<cfset wasShipped = not isNull(o.getShippedAt())>
	<cftransaction>
		<!--- A partly refunded order keeps its status (2026-10-21): the rest of it may still go out, and ShippedAt says it went. --->
		<cfif valueOrEmpty(o.getStatus()) neq "partlyRefunded">
			<cfset o.setStatus(arguments.shipped ? "shipped" : "paid")>
		<cfelseif not arguments.shipped>
			<cfset o.setShippedAt(javacast("null", ""))>
		</cfif>
		<cfif arguments.shipped and not wasShipped><cfset o.setShippedAt(now())></cfif>
		<cfset o.setDate(now())>
		<cfset entitySave(o)>
	</cftransaction>
	<cfif arguments.shipped and not wasShipped and arguments.tellBuyer>
		<cfset sendShippedEmail(arguments.shopOrderId)>
	</cfif>
	<cfset clearAdminCounts()>
	<cfreturn { success: true, message: "" }>
</cffunction>

<cffunction name="refundOrder" access="public" returntype="struct" output="false" hint="Refunds an order through Stripe (all of it, or up to amount). Returns { success, refunded, message }.">
	<cfargument name="shopOrderId" type="numeric" required="true">
	<cfargument name="amount" required="false" default="0">
	<cfset var result = application.payments.refundShopOrder(arguments.shopOrderId, arguments.amount)>
	<cfif result.success><cfset applyRefund(arguments.shopOrderId)></cfif>
	<cfreturn result>
</cffunction>

<cffunction name="applyRefund" access="public" returntype="void" output="false" hint="Sets the order's status from its payments after a refund (here or in the Stripe dashboard).">
	<cfargument name="shopOrderId" type="numeric" required="true">
	<cfset var totals = application.payments.getShopOrderPaymentTotals(arguments.shopOrderId)>
	<cfset var o = loadOrder(arguments.shopOrderId)>
	<cfif isNull(o) or totals.refunded lte 0>
		<cfreturn>
	</cfif>
	<cfset setOrderStatus(arguments.shopOrderId, totals.refundable lte 0 ? "refunded" : "partlyRefunded")>
</cffunction>

<cffunction name="getOrdersCsv" access="public" returntype="string" output="false" hint="The paid orders, one row per product, for a spreadsheet.">
	<cfset var rows = ["Order,Date,Name,Email,Product,Kind,Quantity,Unit price,Order total,Currency,Status,Ship to,Test"]>
	<cfset var q = queryExecute("
		SELECT o.ShopOrderId, o.PaidAt, o.Name, o.Email, o.Total, o.Currency, o.Status, o.NeedsShipping, o.TestMode, o.ShippedAt,
			o.ShipName, o.ShipLine1, o.ShipLine2, o.ShipCity, o.ShipState, o.ShipPostalCode, o.ShipCountry,
			i.ProductName, i.Kind, i.Quantity, i.UnitPrice
		FROM ShopOrder o JOIN ShopOrderItem i ON i.ShopOrderRef = o.ShopOrderId
		WHERE o.BlogRef = :blogId AND o.Status IN ('paid','shipped','partlyRefunded','refunded')
		ORDER BY o.ShopOrderId DESC, i.ShopOrderItemId",
		{ blogId = { value = blogId(), cfsqltype = "cf_sql_integer" } }, { datasource = application.dsn })>
	<cfloop query="q">
		<cfset arrayAppend(rows, arrayToList([
			csvCell(orderNumber(q.ShopOrderId)), csvCell(isDate(q.PaidAt) ? dateFormat(q.PaidAt, "yyyy-mm-dd") & " " & timeFormat(q.PaidAt, "HH:nn") : ""),
			csvCell(q.Name), csvCell(q.Email), csvCell(q.ProductName), csvCell(q.Kind), csvCell(q.Quantity), csvCell(numberFormat(val(q.UnitPrice), "0.00")),
			csvCell(numberFormat(val(q.Total), "0.00")), csvCell(q.Currency), csvCell(statusLabel(toString(q.Status), isTrue(q.NeedsShipping), isDate(q.ShippedAt))),
			csvCell(reReplace(trim(listChangeDelims(trim(q.ShipName & "|" & q.ShipLine1 & "|" & q.ShipLine2 & "|" & q.ShipCity & " " & q.ShipState & " " & q.ShipPostalCode & "|" & q.ShipCountry), ", ", "|")), "\s+", " ", "all")),
			csvCell(isTrue(q.TestMode) ? "test" : "")
		], ","))>
	</cfloop>
	<cfreturn arrayToList(rows, chr(13) & chr(10))>
</cffunction>

<cffunction name="getAdminCounts" access="public" returntype="struct" output="false" hint="For the admin home: { toShip, newThisWeek } (paid orders). Kept for a minute.">
	<cfset var key = "galaxieShopCounts" & blogId()>
	<cfset var q = "">
	<cfset var result = { toShip: 0, newThisWeek: 0 }>
	<cfif structKeyExists(application, key) and dateDiff("s", application[key].made, now()) lt 60>
		<cfreturn application[key].data>
	</cfif>
	<cftry>
		<cfset q = queryExecute("
			SELECT
				SUM(CASE WHEN NeedsShipping = :on AND (Status = 'paid' OR (Status = 'partlyRefunded' AND ShippedAt IS NULL)) THEN 1 ELSE 0 END) AS ToShip,
				SUM(CASE WHEN PaidAt >= :weekAgo THEN 1 ELSE 0 END) AS NewThisWeek
			FROM ShopOrder WHERE BlogRef = :blogId AND Status IN ('paid','shipped','partlyRefunded','refunded')",
			{ on = { value = true, cfsqltype = "cf_sql_bit" }, weekAgo = { value = dateAdd("d", -7, now()), cfsqltype = "cf_sql_timestamp" }, blogId = { value = blogId(), cfsqltype = "cf_sql_integer" } },
			{ datasource = application.dsn })>
		<cfset result = { toShip: val(q.ToShip), newThisWeek: val(q.NewThisWeek) }>
		<cfcatch type="any"></cfcatch>
	</cftry>
	<cfset application[key] = { made: now(), data: result }>
	<cfreturn result>
</cffunction>

<!---//*****************************************************************************************
		Members and downloads
//******************************************************************************************--->

<cffunction name="getMemberOrders" access="public" returntype="array" output="false"
		hint="A signed-in member's paid orders (bought while signed in, or with their email), newest first, with any download links that still work.">
	<cfargument name="member" type="struct" required="true" hint="Members.cfc getCurrentMember().">
	<cfset var list = []>
	<cfset var found = []>
	<cfset var o = "">
	<cfset var order = "">
	<cfif structIsEmpty(arguments.member)>
		<cfreturn list>
	</cfif>
	<!--- Guest orders have MemberRef 0, so 0 never matches by member (only by email). --->
	<cfset found = ormExecuteQuery("FROM ShopOrder WHERE BlogRef = :blogId AND ((MemberRef = :memberId AND MemberRef > 0) OR lower(Email) = :email) AND Status IN ('paid','shipped','partlyRefunded','refunded') ORDER BY ShopOrderId DESC",
		{ blogId = blogId(), memberId = javacast("int", val(arguments.member.memberId)), email = lCase(arguments.member.email) }, false, { maxResults = 50 })>
	<cfloop array="#found#" index="o">
		<cfset order = getOrder(o.getShopOrderId())>
		<cfset arrayAppend(list, {
			"orderNumber": order.orderNumber,
			"date": isDate(order.paidAt) ? dateFormat(order.paidAt, "mmmm d, yyyy") : "",
			"status": order.statusLabel,
			"totalText": money(order.total, order.currency),
			"itemsHtml": order.itemsHtml,
			"downloads": downloadsStillWorking(order.downloads)
		})>
	</cfloop>
	<cfreturn list>
</cffunction>

<cffunction name="getBought" access="public" returntype="struct" output="false"
		hint="What the visitor has bought before, by product alias, for the 'You bought...' line on a product (2026-10-22, owner): { alias: { count, orders, kind, dateText, downloadUrl } }. A signed-in member's orders, and a guest's by the order tokens their own browser kept after paying (never by email alone: anyone can type an email). Refunded orders don't count.">
	<cfargument name="orderTokens" type="string" required="false" default="" hint="Comma separated, from common/js/shop.js.">
	<cfset var bought = {}>
	<cfset var result = {}>
	<cfset var tokens = []>
	<cfset var token = "">
	<cfset var member = application.members.getCurrentMember()>
	<cfset var where = []>
	<cfset var params = { blogId = blogId() }>
	<cfset var orders = []>
	<cfset var order = "">
	<cfset var paidAt = {}>
	<cfset var orderIds = []>
	<cfset var items = []>
	<cfset var item = "">
	<cfset var aliases = {}>
	<cfset var product = "">
	<cfset var alias = "">
	<cfset var entry = "">
	<cfset var limit = getSettings().downloadLimit>
	<cfloop list="#arguments.orderTokens#" index="token">
		<cfif reFind("^[a-f0-9]{64}$", trim(token)) and arrayLen(tokens) lt 30><cfset arrayAppend(tokens, trim(token))></cfif>
	</cfloop>
	<cfif arrayLen(tokens)>
		<cfset arrayAppend(where, "OrderToken IN (:tokens)")>
		<cfset params.tokens = tokens>
	</cfif>
	<!--- Guest orders have MemberRef 0, so 0 never matches by member (only by email), as in getMemberOrders. --->
	<cfif not structIsEmpty(member)>
		<cfset arrayAppend(where, "(MemberRef = :memberId AND MemberRef > 0) OR lower(Email) = :email")>
		<cfset params.memberId = javacast("int", val(member.memberId))>
		<cfset params.email = lCase(member.email)>
	</cfif>
	<cfif not arrayLen(where)>
		<cfreturn result>
	</cfif>
	<cfset orders = ormExecuteQuery("FROM ShopOrder WHERE BlogRef = :blogId AND (" & arrayToList(where, " OR ") & ") AND Status IN ('paid','shipped','partlyRefunded') ORDER BY ShopOrderId DESC", params, false, { maxResults = 100 })>
	<cfif not arrayLen(orders)>
		<cfreturn result>
	</cfif>
	<cfloop array="#orders#" index="order">
		<cfset paidAt[order.getShopOrderId()] = isNull(order.getPaidAt()) ? order.getCreated() : order.getPaidAt()>
		<cfset arrayAppend(orderIds, javacast("int", order.getShopOrderId()))>
	</cfloop>
	<cfloop array="#listProducts()#" index="product">
		<cfset aliases[product.productId] = product.alias>
	</cfloop>
	<!--- Newest order first, so the first download link found is the newest. --->
	<cfset items = ormExecuteQuery("FROM ShopOrderItem WHERE ShopOrderRef IN (:ids) ORDER BY ShopOrderRef DESC", { ids = orderIds })>
	<cfloop array="#items#" index="item">
		<cfif structKeyExists(aliases, val(item.getProductRef()))>
			<cfset alias = aliases[val(item.getProductRef())]>
			<cfif not structKeyExists(bought, alias)>
				<cfset bought[alias] = { count: 0, orders: 0, kind: valueOrEmpty(item.getKind()), last: paidAt[item.getShopOrderRef()], downloadUrl: "" }>
			</cfif>
			<cfset entry = bought[alias]>
			<cfset entry.count += val(item.getQuantity())>
			<cfset entry.orders++>
			<cfif dateCompare(paidAt[item.getShopOrderRef()], entry.last) gt 0><cfset entry.last = paidAt[item.getShopOrderRef()]></cfif>
			<cfif not len(entry.downloadUrl) and len(valueOrEmpty(item.getDownloadToken())) and not isNull(item.getDownloadExpiresAt())
				and dateCompare(item.getDownloadExpiresAt(), now()) gt 0 and val(valueOrEmpty(item.getDownloadCount())) lt limit>
				<cfset entry.downloadUrl = application.blogHostUrl & "/common/services/shopDownload.cfm?t=" & item.getDownloadToken()>
			</cfif>
		</cfif>
	</cfloop>
	<!--- Quoted keys: Adobe ColdFusion sends unquoted ones in capitals. The year only when it isn't this year. --->
	<cfloop collection="#bought#" item="alias">
		<cfset entry = bought[alias]>
		<cfset result[alias] = {
			"count": entry.count, "orders": entry.orders, "kind": entry.kind, "downloadUrl": entry.downloadUrl,
			"dateText": dateFormat(entry.last, year(entry.last) eq year(now()) ? "mmmm d" : "mmmm d, yyyy")
		}>
	</cfloop>
	<cfreturn result>
</cffunction>

<cffunction name="prepareDownload" access="public" returntype="struct" output="false"
		hint="Checks a download link and counts the use. Returns { success, path, displayName, message }.">
	<cfargument name="token" type="string" required="true">
	<cfset var result = { success: false, path: "", displayName: "", message: "This download link isn't valid." }>
	<cfset var settings = getSettings()>
	<cfset var found = []>
	<cfset var item = "">
	<cfset var o = "">
	<cfset var product = "">
	<cfset var path = "">
	<cfif not reFind("^[a-f0-9]{64}$", arguments.token)>
		<cfreturn result>
	</cfif>
	<cflock name="galaxieShopDownload#arguments.token#" type="exclusive" timeout="10">
		<cfset found = ormExecuteQuery("FROM ShopOrderItem WHERE DownloadToken = :t", { t = arguments.token })>
		<cfif not arrayLen(found)><cfreturn result></cfif>
		<cfset item = found[1]>
		<cfset o = loadOrder(val(item.getShopOrderRef()))>
		<cfif isNull(o) or not listFind("paid,shipped,partlyRefunded", valueOrEmpty(o.getStatus()))>
			<cfset result.message = "This order was refunded, so the download is no longer available.">
			<cfreturn result>
		</cfif>
		<cfif isNull(item.getDownloadExpiresAt()) or item.getDownloadExpiresAt() lt now()>
			<cfset result.message = "This download link has expired. Please contact us and we'll send a new one.">
			<cfreturn result>
		</cfif>
		<cfif val(item.getDownloadCount()) gte settings.downloadLimit>
			<cfset result.message = "This download link has been used #settings.downloadLimit# times, which is the limit. Please contact us if you need it again.">
			<cfreturn result>
		</cfif>
		<cfset product = loadProduct(val(item.getProductRef()), "")>
		<cfif not isNull(product) and len(valueOrEmpty(product.getFileName()))>
			<cfset path = getFileFolder() & product.getFileName()>
		</cfif>
		<cfif not len(path) or not fileExists(path)>
			<cfset result.message = "The file for this download is missing. Please contact us.">
			<cflog file="galaxieBlogErrors" type="error" text="Shop: the file for product #item.getProductRef()# is missing (order #item.getShopOrderRef()#).">
			<cfreturn result>
		</cfif>
		<cftransaction>
			<cfset item.setDownloadCount(javacast("int", val(item.getDownloadCount()) + 1))>
			<cfset entitySave(item)>
		</cftransaction>
	</cflock>
	<cfreturn { success: true, path: path, displayName: len(valueOrEmpty(product.getFileDisplayName())) ? product.getFileDisplayName() : "download", message: "" }>
</cffunction>

<!---//*****************************************************************************************
		Emails
//******************************************************************************************--->

<cffunction name="sendOrderEmails" access="public" returntype="void" output="false" hint="The buyer's thank-you (Stripe sends the receipt) and the owner's New order email.">
	<cfargument name="shopOrderId" type="numeric" required="true">
	<cfset var order = getOrder(arguments.shopOrderId)>
	<cfset var blogName = application.BlogDbObj.getBlogTitle()>
	<cfset var html = "">
	<cfset var d = "">
	<cfif structIsEmpty(order)><cfreturn></cfif>
	<cfset html = order.itemsHtml>
	<cfif arrayLen(order.downloads)>
		<cfset html = html & "<p><strong>Your downloads</strong> (each link works until " & encodeForHtml(order.downloads[1].expires) & "):</p><ul>">
		<cfloop array="#order.downloads#" index="d">
			<cfset html = html & '<li><a href="' & encodeForHtmlAttribute(d.url) & '">' & encodeForHtml(d.name) & '</a></li>'>
		</cfloop>
		<cfset html = html & "</ul>">
	</cfif>
	<cfif arrayLen(order.address)>
		<cfset html = html & "<p><strong>Shipping to</strong><br>" & arrayToList(arrayMap(order.address, function(x) { return encodeForHtml(x); }), "<br>") & "</p>">
	</cfif>
	<cfif isValid("email", order.email)>
		<cftry>
			<cfset sendOneEmail(
				to = order.email,
				subject = "Thank you for your order (" & order.orderNumber & ")",
				title = "Thank you for your order",
				intro = order.needsShipping ? "We've got your order and will let you know when it ships. Stripe sends your receipt separately." : "Your order is ready. Stripe sends your receipt separately.",
				detailsHtml = html & application.members.invitationHtml(order.email)
			)>
			<cfcatch type="any"><cflog file="galaxieBlogErrors" type="error" text="Shop order #arguments.shopOrderId#: the buyer's email failed: #cfcatch.message#"></cfcatch>
		</cftry>
	</cfif>
	<cftry>
		<cfset sendOneEmail(
			to = application.BlogDbObj.getBlogEmail(),
			subject = "New order " & order.orderNumber & ": " & money(order.total, order.currency) & (order.testMode ? " (test)" : ""),
			title = "New order " & order.orderNumber,
			intro = encodeForHtml(len(order.name) ? order.name : order.email) & " bought from " & encodeForHtml(blogName) & (order.needsShipping ? ". It needs shipping." : "."),
			detailsHtml = html & "<p>" & encodeForHtml(order.email) & "</p><p>Open Orders in the blog's administration to see it" & (order.needsShipping ? " and mark it as shipped" : "") & ".</p>"
		)>
		<cfcatch type="any"><cflog file="galaxieBlogErrors" type="error" text="Shop order #arguments.shopOrderId#: the owner's email failed: #cfcatch.message#"></cfcatch>
	</cftry>
</cffunction>

<cffunction name="sendShippedEmail" access="private" returntype="void" output="false">
	<cfargument name="shopOrderId" type="numeric" required="true">
	<cfset var order = getOrder(arguments.shopOrderId)>
	<cfif structIsEmpty(order) or not isValid("email", order.email)><cfreturn></cfif>
	<cftry>
		<cfset sendOneEmail(
			to = order.email,
			subject = "Your order has shipped (" & order.orderNumber & ")",
			title = "Your order is on its way",
			intro = "Good news: your order has shipped.",
			detailsHtml = order.itemsHtml & (arrayLen(order.address) ? "<p><strong>Shipping to</strong><br>" & arrayToList(arrayMap(order.address, function(x) { return encodeForHtml(x); }), "<br>") & "</p>" : "")
		)>
		<cfcatch type="any"><cflog file="galaxieBlogErrors" type="error" text="Shop order #arguments.shopOrderId#: the shipped email failed: #cfcatch.message#"></cfcatch>
	</cftry>
</cffunction>

<cffunction name="sendOneEmail" access="private" returntype="void" output="false">
	<cfargument name="to" type="string" required="true">
	<cfargument name="subject" type="string" required="true">
	<cfargument name="title" type="string" required="true">
	<cfargument name="intro" type="string" required="true">
	<cfargument name="detailsHtml" type="string" required="true">
	<cfset var renderer = createObject("component", application.rendererComponentPath)>
	<cfset var utils = createObject("component", application.utilsComponentPath)>
	<cfset var emailBody = renderer.renderEmail(
		email = arguments.to,
		emailTitle = arguments.title,
		emailDesc = arguments.intro,
		emailBody = arguments.detailsHtml,
		callToActionText = "",
		callToActionLink = ""
	)>
	<cfset utils.mail(to = arguments.to, subject = arguments.subject, body = emailBody, cc = "", attachmentName = "", attachmentContent = "", attachmentType = "")>
</cffunction>

<!---//*****************************************************************************************
		Helpers
//******************************************************************************************--->

<cffunction name="getFileFolder" access="public" returntype="string" output="false"
		hint="The private folder for digital products, ending in a slash: galaxieShopFiles/<blog id>/ next to the web site's root folder (out of the web's reach) when it can be made there, otherwise common/data/shopFiles inside the blog. Both are closed to the web (.htaccess and web.config) and hold only randomly named files. Empty if neither can be made.">
	<cfset var webRoot = expandPath("/")>
	<cfset var blogRoot = getDirectoryFromPath(expandPath(application.baseUrl & "/index.cfm"))>
	<cfset var outside = "">
	<cfset var inside = blogRoot & "common/data/shopFiles/">
	<cfif structKeyExists(variables, "fileFolder")><cfreturn variables.fileFolder></cfif>
	<!--- Without its last slash, so the folder above it can be found. --->
	<cfloop condition="len(webRoot) gt 3 and listFind('\,/', right(webRoot, 1))">
		<cfset webRoot = left(webRoot, len(webRoot) - 1)>
	</cfloop>
	<cfset outside = getDirectoryFromPath(webRoot) & "galaxieShopFiles/" & blogId() & "/">
	<cftry>
		<cfif not directoryExists(outside)><cfdirectory action="create" directory="#outside#"></cfif>
		<cfset closeToWeb(outside)>
		<cfset variables.fileFolder = outside>
		<cfreturn outside>
		<cfcatch type="any"></cfcatch>
	</cftry>
	<cftry>
		<cfif not directoryExists(inside)><cfdirectory action="create" directory="#inside#"></cfif>
		<cfset closeToWeb(inside)>
		<cfset variables.fileFolder = inside>
		<cfreturn inside>
		<cfcatch type="any"></cfcatch>
	</cftry>
	<cfreturn "">
</cffunction>

<cffunction name="closeToWeb" access="private" returntype="void" output="false" hint="Puts an Apache and an IIS deny-all file in a folder.">
	<cfargument name="folder" type="string" required="true">
	<cfif not fileExists(arguments.folder & ".htaccess")><cffile action="write" file="#arguments.folder#.htaccess" output="Require all denied#chr(10)#Deny from all"></cfif>
	<cfif not fileExists(arguments.folder & "web.config")><cffile action="write" file="#arguments.folder#web.config" output='<?xml version="1.0" encoding="UTF-8"?><configuration><system.webServer><authorization><deny users="*" /></authorization></system.webServer></configuration>'></cfif>
</cffunction>

<cffunction name="money" access="public" returntype="string" output="false">
	<cfargument name="amount" required="true">
	<cfargument name="currencyCode" type="string" required="false" default="">
	<cfreturn application.payments.formatMoney(val(arguments.amount), arguments.currencyCode)>
</cffunction>

<cffunction name="orderNumber" access="public" returntype="string" output="false" hint="How an order is named to people: ##1001 for ShopOrderId 1.">
	<cfargument name="shopOrderId" type="numeric" required="true">
	<cfreturn "##" & (1000 + arguments.shopOrderId)>
</cffunction>

<cffunction name="statusLabel" access="public" returntype="string" output="false">
	<cfargument name="status" type="string" required="true">
	<cfargument name="needsShipping" type="boolean" required="false" default="false">
	<cfargument name="shipped" type="boolean" required="false" default="false" hint="It has a ShippedAt: a partly refunded order still needs shipping (2026-10-21).">
	<cfswitch expression="#arguments.status#">
		<cfcase value="paid"><cfreturn arguments.needsShipping ? "Paid, to ship" : "Paid"></cfcase>
		<cfcase value="shipped"><cfreturn "Shipped"></cfcase>
		<cfcase value="refunded"><cfreturn "Refunded"></cfcase>
		<cfcase value="partlyRefunded"><cfreturn "Partly refunded" & (arguments.needsShipping ? (arguments.shipped ? ", shipped" : ", to ship") : "")></cfcase>
		<cfcase value="pending"><cfreturn "Not paid yet"></cfcase>
		<cfcase value="expired"><cfreturn "Not paid (closed)"></cfcase>
		<cfcase value="cancelled"><cfreturn "Not paid (went back)"></cfcase>
	</cfswitch>
	<cfreturn arguments.status>
</cffunction>

<cffunction name="itemsTable" access="private" returntype="string" output="false" hint="An order's products and amounts as a small table, for emails and windows.">
	<cfargument name="order" type="struct" required="true">
	<cfset var o = arguments.order>
	<cfset var html = '<table cellpadding="4" cellspacing="0" style="border-collapse:collapse;width:100%;max-width:520px">'>
	<cfset var item = "">
	<cfloop array="#o.items#" index="item">
		<cfset html = html & '<tr><td>' & encodeForHtml(item.name) & (item.quantity gt 1 ? ' &times; ' & item.quantity : '') & '</td><td style="text-align:right">' & item.lineTotalText & '</td></tr>'>
	</cfloop>
	<cfif o.needsShipping>
		<cfset html = html & '<tr><td>Shipping</td><td style="text-align:right">' & (o.shipping gt 0 ? money(o.shipping, o.currency) : 'Free') & '</td></tr>'>
	</cfif>
	<cfif o.tax gt 0>
		<cfset html = html & '<tr><td>Tax</td><td style="text-align:right">' & money(o.tax, o.currency) & '</td></tr>'>
	</cfif>
	<cfif o.discount gt 0>
		<cfset html = html & '<tr><td>Discount</td><td style="text-align:right">-' & money(o.discount, o.currency) & '</td></tr>'>
	</cfif>
	<cfset html = html & '<tr><td style="border-top:1px solid ##ccc"><strong>Total</strong></td><td style="text-align:right;border-top:1px solid ##ccc"><strong>' & money(o.total, o.currency) & '</strong></td></tr></table>'>
	<cfreturn html>
</cffunction>

<cffunction name="downloadsStillWorking" access="private" returntype="array" output="false">
	<cfargument name="downloads" type="array" required="true">
	<cfset var list = []>
	<cfset var d = "">
	<cfset var limit = getSettings().downloadLimit>
	<cfloop array="#arguments.downloads#" index="d">
		<cfif isDate(d.expires) and parseDateTime(d.expires) gte dateAdd("d", -1, now()) and d.used lt limit>
			<cfset arrayAppend(list, { "name": d.name, "url": d.url, "expires": d.expires })>
		</cfif>
	</cfloop>
	<cfreturn list>
</cffunction>

<cffunction name="productToStruct" access="private" returntype="struct" output="false">
	<cfargument name="e" type="any" required="true">
	<cfset var price = val(valueOrEmpty(arguments.e.getPrice()))>
	<cfset var trackStock = isTrue(arguments.e.getTrackStock())>
	<cfset var stock = val(valueOrEmpty(arguments.e.getStock()))>
	<cfreturn {
		productId: arguments.e.getProductId(),
		name: valueOrEmpty(arguments.e.getName()),
		alias: valueOrEmpty(arguments.e.getAlias()),
		description: valueOrEmpty(arguments.e.getDescription()),
		imageUrl: valueOrEmpty(arguments.e.getImageUrl()),
		kind: valueOrEmpty(arguments.e.getKind()),
		price: price,
		priceText: money(price),
		shippingPrice: val(valueOrEmpty(arguments.e.getShippingPrice())),
		trackStock: trackStock,
		stock: stock,
		soldOut: trackStock and stock lte 0,
		hasFile: len(valueOrEmpty(arguments.e.getFileName())) gt 0,
		fileDisplayName: valueOrEmpty(arguments.e.getFileDisplayName()),
		active: isTrue(arguments.e.getActive(), true)
	}>
</cffunction>

<cffunction name="loadProduct" access="private" returntype="any" output="false" hint="This blog's Product entity by id or alias, or null.">
	<cfargument name="productId" required="true">
	<cfargument name="alias" type="string" required="true">
	<cfset var found = []>
	<cfif val(arguments.productId) gt 0>
		<cfset found = ormExecuteQuery("FROM Product WHERE ProductId = :id AND BlogRef = :blogId", { id = javacast("int", val(arguments.productId)), blogId = blogId() })>
	<cfelseif len(trim(arguments.alias))>
		<cfset found = ormExecuteQuery("FROM Product WHERE Alias = :alias AND BlogRef = :blogId", { alias = trim(arguments.alias), blogId = blogId() })>
	</cfif>
	<cfif arrayLen(found)><cfreturn found[1]></cfif>
</cffunction>

<cffunction name="loadOrder" access="private" returntype="any" output="false" hint="This blog's ShopOrder entity, or null.">
	<cfargument name="shopOrderId" type="numeric" required="true">
	<cfset var found = ormExecuteQuery("FROM ShopOrder WHERE ShopOrderId = :id AND BlogRef = :blogId", { id = javacast("int", arguments.shopOrderId), blogId = blogId() })>
	<cfif arrayLen(found)><cfreturn found[1]></cfif>
</cffunction>

<cffunction name="setOrderStatus" access="private" returntype="void" output="false">
	<cfargument name="shopOrderId" type="numeric" required="true">
	<cfargument name="status" type="string" required="true">
	<cfset var o = loadOrder(arguments.shopOrderId)>
	<cfif isNull(o)><cfreturn></cfif>
	<cftransaction>
		<cfset o.setStatus(arguments.status)>
		<cfset o.setDate(now())>
		<cfset entitySave(o)>
	</cftransaction>
	<cfset clearAdminCounts()>
</cffunction>

<cffunction name="deleteStoredFile" access="private" returntype="void" output="false">
	<cfargument name="fileName" type="string" required="true">
	<cfset var folder = getFileFolder()>
	<cfif len(arguments.fileName) and reFind("^[a-f0-9]{64}\.bin$", arguments.fileName) and len(folder) and fileExists(folder & arguments.fileName)>
		<cftry><cffile action="delete" file="#folder##arguments.fileName#"><cfcatch type="any"></cfcatch></cftry>
	</cfif>
</cffunction>

<cffunction name="clearAdminCounts" access="private" returntype="void" output="false">
	<cfset structDelete(application, "galaxieShopCounts" & blogId())>
</cffunction>

<cffunction name="makeAlias" access="private" returntype="string" output="false" hint="A product's short name: lower case letters, numbers and dashes.">
	<cfargument name="text" type="string" required="true">
	<cfreturn left(reReplace(reReplace(lCase(trim(arguments.text)), "[^a-z0-9]+", "-", "all"), "^-+|-+$", "", "all"), 100)>
</cffunction>

<cffunction name="csvCell" access="private" returntype="string" output="false">
	<cfargument name="value" required="true">
	<cfset var text = toString(arguments.value)>
	<!--- A cell a spreadsheet would run as a formula starts with a quote mark instead. --->
	<cfif reFind("^[=+\-@]", text)><cfset text = "'" & text></cfif>
	<cfreturn '"' & replace(text, '"', '""', "all") & '"'>
</cffunction>

<cffunction name="blogId" access="private" returntype="numeric" output="false">
	<cfreturn javacast("int", application.BlogDbObj.getBlogId())>
</cffunction>

<cffunction name="valueOrEmpty" access="private" returntype="string" output="false">
	<cfargument name="value" required="false">
	<cfif isNull(arguments.value)><cfreturn ""></cfif>
	<cfreturn toString(arguments.value)>
</cffunction>

<cffunction name="isTrue" access="private" returntype="boolean" output="false">
	<cfargument name="value" required="false">
	<cfargument name="default" type="boolean" required="false" default="false">
	<cfif isNull(arguments.value) or (isSimpleValue(arguments.value) and not len(arguments.value))><cfreturn arguments.default></cfif>
	<cfreturn isBoolean(arguments.value) and arguments.value>
</cffunction>

</cfcomponent>
