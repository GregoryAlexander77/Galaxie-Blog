<!--- Insert Product window (window 115, 2026-10-21), opened by the post editor's Insert Product button and Insert > Product menu item
(includes/templates/js/tinyMce.cfm). Inserts a placeholder for a product card into the post or page:
<div class="galaxieProduct" data-product="product-alias">[Product: Name]</div>, or data-product="*" for every product (a list, as on a
shop page). On the site, common/js/shop.js shows the card there; in a feed or an email it becomes a link to the post. --->
<cfset insertableProducts = [{ "productId": 0, "alias": "*", "name": "All products (a list of everything for sale)" }]>
<cfloop array="#application.shop.listProducts(activeOnly = true)#" index="thisProduct">
	<cfset arrayAppend(insertableProducts, { "productId": thisProduct.productId, "alias": thisProduct.alias, "name": thisProduct.name & " (" & thisProduct.priceText & ")" })>
</cfloop>

<script>
	$(document).ready(function() {
		var insertableProducts = <cfoutput>#serializeJson(insertableProducts)#</cfoutput>;
		var insertProductChoice = $("#insertProductChoice").kendoDropDownList({
			dataSource: insertableProducts,
			dataTextField: "name",
			dataValueField: "alias",
			filter: "contains"
		}).data("kendoDropDownList");
		<!--- The first real product, when there is one: most of the time one product goes in a post. --->
		if (insertableProducts.length > 1) { insertProductChoice.select(1); }

		$("#insertProductSubmit").on("click", function() {
			var item = insertProductChoice.dataItem();
			var editor = tinymce.activeEditor;
			if (!item || !editor) {
				$.when(kendo.ui.ExtAlertDialog.show({ title: "Choose a product", message: "Open the post in the editor and choose what to place.", icon: "k-ext-warning", width: "<cfoutput>#application.kendoExtendedUiWindowWidth#</cfoutput>" }));
				return;
			}
			var label = item.alias === "*" ? "All products" : item.name.replace(/ \([^)]*\)$/, "");
			var alias = $('<div/>').text(item.alias).html().replace(/"/g, "&quot;");
			editor.insertContent('<div class="galaxieProduct" data-product="' + alias + '">[Product: ' + $('<div/>').text(label).html() + ']</div><p>&nbsp;</p>');
			$('#insertProductWindow').kendoWindow('destroy');
		});
	});
</script>

<cfset blockClass = HtmlUtilsObj.getKendoClass('')>
<cfoutput>
<table align="center" class="k-content adminBlocks" width="100%" cellpadding="5" cellspacing="0" border="0" style="table-layout: fixed">
	<colgroup><col style="width: 20%"><col></colgroup>
<cfif arrayLen(insertableProducts) eq 1>
	<tr><td colspan="2" class="#blockClass#">There are no products shown on the site yet. <a href="javascript:createAdminInterfaceWindow(112, 0);">Add a product</a>, then open this window again to place it.</td></tr>
<cfelse>
	<tr><td colspan="2" class="#blockClass#">Choose a product to show its card, with its picture, price and an Add to cart button. Or choose "All products" for a list of everything for sale. The post shows "[Product: name]" while you edit it.</td></tr>
	<tr class="blockSpacer"><td colspan="2" class="border #blockClass#"></td></tr>
	<tr>
		<td class="#blockClass#" align="right"><label for="insertProductChoice">Product:</label></td>
		<td class="#blockClass#"><input id="insertProductChoice" style="width: 95%;"></td>
	</tr>
	<tr class="blockSpacer"><td colspan="2" class="border #blockClass#"></td></tr>
	<tr>
		<td class="#blockClass#"></td>
		<td class="#blockClass#"><button id="insertProductSubmit" type="button" class="k-button k-primary">Insert</button></td>
	</tr>
</cfif>
</table>
</cfoutput>
