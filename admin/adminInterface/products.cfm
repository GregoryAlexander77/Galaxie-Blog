<!--- Shop (window 111, 2026-10-21; called Products until 10-22): the shop's switches, its pages and every product. Add a product or open one (window 112). The
switches are saved by ProxyController.cfc's saveShopSettings -> application.shop.saveSettings (common/cfc/Shop.cfc). A plain table,
not a grid: a small shop has a handful of products. --->
<cfset shopSettings = application.shop.getSettings()>
<cfset shopProducts = application.shop.listProducts()>
<cfset shopPages = application.shop.getShopPages()>
<cfset kindLabels = { physical: "Shipped", digital: "Download", service: "Service" }>

<script>
	<!--- Called by the product window after a save or delete, so the list stays current. --->
	function refreshProductsWindow() {
		try { $("#productsWindow").data("kendoWindow").refresh(); } catch (error) { <!--- The window may not be open. ---> }
	}
	$(document).ready(function() {
		$("#shopSettingsSubmit").on("click", function() {
			$.when(kendo.ui.ExtWaitDialog.show({ title: "Please wait...", message: "Saving the shop settings.", width: "<cfoutput>#application.kendoExtendedUiWindowWidth#</cfoutput>", icon: "k-ext-information" }));
			jQuery.ajax({
				type: 'post',
				url: '<cfoutput>#application.baseUrl#</cfoutput>/common/cfc/ProxyController.cfc?method=saveShopSettings',
				data: {
					csrfToken: '<cfoutput>#csrfToken#</cfoutput>',
					enabled: $("#shopEnabled").is(":checked"),
					promotionCodes: $("#shopPromotionCodes").is(":checked"),
					downloadDays: $("#shopDownloadDays").val(),
					downloadLimit: $("#shopDownloadLimit").val()
				},
				dataType: "json",
				success: function(response) {
					kendo.ui.ExtWaitDialog.hide();
					if (typeof response === "string") { try { response = JSON.parse(response); } catch (e) {} }
					if (response && response.success) {
						$.when(kendo.ui.ExtAlertDialog.show({ title: "Saved", message: "The shop settings were saved.", icon: "k-ext-information" }));
					} else {
						$.when(kendo.ui.ExtAlertDialog.show({ title: "Could not save", message: (response && response.errorMessage) || "The settings could not be saved.", icon: "k-ext-warning", width: "<cfoutput>#application.kendoExtendedUiWindowWidth#</cfoutput>" }));
					}
				},
				error: function(jqXHR, textStatus, error) {
					kendo.ui.ExtWaitDialog.hide();
					if (jqXHR.status === 403) { createLoginWindow(); } else {
						$.when(kendo.ui.ExtAlertDialog.show({ title: "Error while saving the shop settings", message: error, icon: "k-ext-error", width: "<cfoutput>#application.kendoExtendedUiWindowWidth#</cfoutput>" }));
					}
				}
			});
		});
	});//...document.ready
</script>

<cfset blockClass = HtmlUtilsObj.getKendoClass('')>
<cfoutput>
<table align="center" class="k-content adminBlocks" width="100%" cellpadding="5" cellspacing="0" border="0" style="table-layout: fixed">
	<colgroup><col style="width: 20%"><col></colgroup>
	<tr><td colspan="2" class="#blockClass#">Sell prints, downloads and services from your posts and pages. Put a product in a post or page with <b>Insert &gt; Product</b>, or make a shop page that lists them. Buyers pay on Stripe's secure page, and the money goes straight to you.</td></tr>
	<tr class="blockSpacer"><td colspan="2" class="border #blockClass#"></td></tr>
	<tr>
		<td class="#blockClass#"></td>
		<td class="#blockClass#">
			<button type="button" class="k-button k-primary" onclick="createAdminInterfaceWindow(112, 0);">Add a product</button>
			<button type="button" class="k-button" onclick="createAdminInterfaceWindow(113, 'paid');">Orders</button>
		</td>
	</tr>
	<tr class="blockSpacer"><td colspan="2" class="#blockClass#"></td></tr>

	<!--- Shop pages (2026-10-21): pages with your text and the products under it, like booking pages. --->
	<cfset blockClass = HtmlUtilsObj.getKendoClass(blockClass)>
	<tr class="blockSpacer"><td colspan="2" class="border #blockClass#"></td></tr>
	<tr>
		<td class="#blockClass#"><button type="button" class="k-button k-primary" style="width: 100%;" onclick="createAdminInterfaceWindow(24, 'newShop');">New shop page</button></td>
		<td class="#blockClass#">Where visitors shop: a page with your text and the products under it. It stays up, isn't dated and isn't in your RSS feed.<cfloop array="#shopPages#" index="thisShopPage"><br/><a href="#encodeForHtmlAttribute(thisShopPage.url)#" target="_blank" rel="noopener">#encodeForHtml(thisShopPage.title)#</a> (#encodeForHtml(thisShopPage.label)#<cfif not thisShopPage.released>, not published yet</cfif>) <a href="javascript:createAdminInterfaceWindow(116, #thisShopPage.postId#);">Change</a></cfloop></td>
	</tr>
	<tr class="blockSpacer"><td colspan="2" class="#blockClass#"></td></tr>

	<cfset blockClass = HtmlUtilsObj.getKendoClass(blockClass)>
	<tr class="blockSpacer"><td colspan="2" class="border #blockClass#"></td></tr>
	<tr><td colspan="2" class="#blockClass#"><h4 class="adminBlockHeading">Shop settings</h4></td></tr>
	<cfif shopSettings.paymentsReady and shopSettings.testMode>
	<tr class="blockSpacer"><td colspan="2" class="border #blockClass#"></td></tr>
	<tr><td colspan="2" class="#blockClass#">Payments are in <b>test mode</b> (Blog Options &gt; Payments): orders use Stripe's test cards and no money changes hands.</td></tr>
	</cfif>
	<tr class="blockSpacer"><td colspan="2" class="border #blockClass#"></td></tr>
	<tr>
		<td class="#blockClass#" align="right"><label for="shopEnabled">Shop is open:</label></td>
		<td class="#blockClass#"><input type="checkbox" class="k-checkbox" id="shopEnabled"<cfif shopSettings.enabled> checked</cfif>> <span class="k-form-hint">When it's closed, products still show, without an Add to cart button.</span>
		<!--- Without payments the shop shows as closed even when it's open here (owner, 10-22: "it says the shop is closed, but I
		opened the shop"), so say so right where it's opened, in the soft info callout. --->
		<cfif not shopSettings.paymentsReady>
			<blockquote class="k-notification-info"><p><b>Visitors will see the shop as closed until payments are set up.</b> Add your Stripe keys in <a href="javascript:createAdminInterfaceWindow(38, 'payments');">Blog Options &gt; Payments</a>, then the Add to cart buttons appear.</p></blockquote>
		</cfif></td>
	</tr>
	<tr class="blockSpacer"><td colspan="2" class="border #blockClass#"></td></tr>
	<tr>
		<td class="#blockClass#" align="right"><label for="shopPromotionCodes">Promotion codes:</label></td>
		<td class="#blockClass#"><input type="checkbox" class="k-checkbox" id="shopPromotionCodes"<cfif shopSettings.promotionCodes> checked</cfif>> <span class="k-form-hint">Buyers can enter a code you made in your Stripe dashboard.</span></td>
	</tr>
	<tr class="blockSpacer"><td colspan="2" class="border #blockClass#"></td></tr>
	<tr><td colspan="2" class="#blockClass#">Download links are emailed to the buyer and stop working after a few days or downloads, so they can't be passed around.</td></tr>
	<tr class="blockSpacer"><td colspan="2" class="border #blockClass#"></td></tr>
	<tr>
		<td class="#blockClass#" align="right"><label for="shopDownloadDays">Downloads work for:</label></td>
		<td class="#blockClass#">
			<input type="number" id="shopDownloadDays" class="k-textbox" min="1" max="365" step="1" value="#shopSettings.downloadDays#" style="width: 90px;"> days, and
			<input type="number" id="shopDownloadLimit" class="k-textbox" min="1" max="100" step="1" value="#shopSettings.downloadLimit#" style="width: 90px;"> downloads
		</td>
	</tr>
	<tr class="blockSpacer"><td colspan="2" class="border #blockClass#"></td></tr>
	<tr>
		<td class="#blockClass#"></td>
		<td class="#blockClass#"><button id="shopSettingsSubmit" type="button" class="k-button k-primary">Save settings</button></td>
	</tr>
	<tr class="blockSpacer"><td colspan="2" class="#blockClass#"></td></tr>

	<cfset blockClass = HtmlUtilsObj.getKendoClass(blockClass)>
	<tr class="blockSpacer"><td colspan="2" class="border #blockClass#"></td></tr>
	<tr><td colspan="2" class="#blockClass#"><h4 class="adminBlockHeading">Products</h4></td></tr>
	<tr class="blockSpacer"><td colspan="2" class="border #blockClass#"></td></tr>
	<tr>
		<td colspan="2" class="#blockClass#">
		<cfif not arrayLen(shopProducts)>
			No products yet. Click <b>Add a product</b> to make the first one.
		<cfelse>
			<!--- One row a product, in turn k-content and k-alt (owner, 10-21); click a row to change the product. --->
			<table class="shopAdminList" width="100%" cellpadding="6" cellspacing="0" border="0">
				<tr><th></th><th>Name</th><th>Kind</th><th>Price</th><th>Stock</th><th>Shown</th></tr>
				<cfset rowClass = "">
				<cfloop array="#shopProducts#" index="thisProduct">
					<cfset rowClass = HtmlUtilsObj.getKendoClass(rowClass)>
					<tr class="#rowClass# shopAdminRow" role="button" tabindex="0" title="Change this product" onclick="createAdminInterfaceWindow(112, #thisProduct.productId#);" onkeydown="if (event.key === 'Enter') { createAdminInterfaceWindow(112, #thisProduct.productId#); }">
						<td width="48"><cfif len(thisProduct.imageUrl)><img src="#encodeForHtmlAttribute(thisProduct.imageUrl)#" alt="" class="shopAdminThumb"><cfelse><span class="shopAdminThumb"></span></cfif></td>
						<td><a href="javascript:void(0);">#encodeForHtml(thisProduct.name)#</a></td>
						<td>#kindLabels[thisProduct.kind] ?: thisProduct.kind#</td>
						<td>#thisProduct.priceText#</td>
						<td><cfif thisProduct.trackStock>#thisProduct.stock#<cfif thisProduct.soldOut> (sold out)</cfif><cfelse>-</cfif></td>
						<td>#thisProduct.active ? "Yes" : "No"#</td>
					</tr>
				</cfloop>
			</table>
		</cfif>
		</td>
	</tr>
</table>
</cfoutput>
<style>
	table.shopAdminList th { text-align: left; border-bottom: 1px solid rgba(128, 128, 128, .35); }
	table.shopAdminList td { border-bottom: 1px solid rgba(128, 128, 128, .2); vertical-align: middle; }
	tr.shopAdminRow { cursor: pointer; }
	.shopAdminThumb { width: 40px; height: 40px; object-fit: cover; border-radius: 4px; display: inline-block; vertical-align: middle; background: rgba(128, 128, 128, .2); }
</style>
