<!--- Orders (window 113, 2026-10-21): the shop's orders, newest first. Opened with createAdminInterfaceWindow(113, view), view =
paid (the default), toShip, or all (including checkouts that were never paid). Click an order to open it (window 114). Export
downloads the paid orders as CSV (ProxyController.cfc's exportShopOrders). A plain table, in turn k-content and k-alt rows. --->
<cfset ordersView = listFind("paid,toShip,all", URL.optArgs) ? URL.optArgs : "paid">
<cfset shopOrders = application.shop.getOrdersForGrid(ordersView eq "all")>
<cfif ordersView eq "toShip">
	<cfset shopOrders = arrayFilter(shopOrders, function (o) { return o.Status eq "Paid, to ship"; })>
</cfif>

<script>
	<!--- Called by the order window after a change, so the list stays current. --->
	function refreshShopOrdersWindow() {
		try { $("#shopOrdersWindow").data("kendoWindow").refresh(); } catch (error) { <!--- The window may not be open. ---> }
	}
	$(document).ready(function() {
		$("#shopOrdersView").kendoDropDownList({
			change: function() {
				$("#shopOrdersWindow").data("kendoWindow").destroy();
				createAdminInterfaceWindow(113, this.value());
			}
		});
	});
</script>

<cfset blockClass = HtmlUtilsObj.getKendoClass('')>
<cfoutput>
<table align="center" class="k-content adminBlocks" width="100%" cellpadding="5" cellspacing="0" border="0" style="table-layout: fixed">
	<colgroup><col style="width: 20%"><col></colgroup>
	<tr>
		<td class="#blockClass#" align="right"><label for="shopOrdersView">Show:</label></td>
		<td class="#blockClass#">
			<select id="shopOrdersView" style="width: 250px;">
				<option value="paid"<cfif ordersView eq "paid"> selected</cfif>>Paid orders</option>
				<option value="toShip"<cfif ordersView eq "toShip"> selected</cfif>>To ship</option>
				<option value="all"<cfif ordersView eq "all"> selected</cfif>>All, including unpaid</option>
			</select>
			<a class="k-button" href="#application.baseUrl#/common/cfc/ProxyController.cfc?method=exportShopOrders&amp;csrfToken=#encodeForUrl(csrfToken)#">Export to CSV</a>
		</td>
	</tr>
	<tr class="blockSpacer"><td colspan="2" class="#blockClass#"></td></tr>
	<cfset blockClass = HtmlUtilsObj.getKendoClass(blockClass)>
	<tr class="blockSpacer"><td colspan="2" class="border #blockClass#"></td></tr>
	<tr>
		<td colspan="2" class="#blockClass#">
		<cfif not arrayLen(shopOrders)>
			#ordersView eq "toShip" ? "Nothing to ship." : "No orders yet."#
		<cfelse>
			<table class="shopAdminList" width="100%" cellpadding="6" cellspacing="0" border="0">
				<tr><th>Order</th><th>Date</th><th>Buyer</th><th>Products</th><th>Total</th><th>Status</th></tr>
				<cfset rowClass = "">
				<cfloop array="#shopOrders#" index="thisOrder">
					<cfset rowClass = HtmlUtilsObj.getKendoClass(rowClass)>
					<tr class="#rowClass# shopAdminRow" role="button" tabindex="0" title="Open this order" onclick="createAdminInterfaceWindow(114, #thisOrder.ShopOrderId#);" onkeydown="if (event.key === 'Enter') { createAdminInterfaceWindow(114, #thisOrder.ShopOrderId#); }">
						<td><a href="javascript:void(0);">#thisOrder.OrderNumber#</a></td>
						<td>#dateFormat(left(thisOrder.Date, 10), "mmm d")#</td>
						<td>#encodeForHtml(thisOrder.Name)#</td>
						<td>#encodeForHtml(thisOrder.Items)#</td>
						<td>#thisOrder.Total#</td>
						<td>#encodeForHtml(thisOrder.Status)#<cfif thisOrder.TestMode> (test)</cfif></td>
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
</style>
