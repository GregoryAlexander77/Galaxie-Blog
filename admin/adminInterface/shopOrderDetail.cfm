<!--- An order (window 114, 2026-10-21), opened from Orders (113) with createAdminInterfaceWindow(114, shopOrderId). Mark it shipped
(emails the buyer the first time) or refund it through Stripe: ProxyController.cfc's markShopOrderShipped and refundShopOrderPayment
-> application.shop (common/cfc/Shop.cfc). --->
<cfset shopOrder = application.shop.getOrder(val(URL.optArgs))>

<cfif structIsEmpty(shopOrder)>
	<cfoutput><p class="k-content">This order no longer exists.</p></cfoutput>
<cfelse>
<script>
	$(document).ready(function() {
		var csrf = '<cfoutput>#csrfToken#</cfoutput>';
		var proxy = '<cfoutput>#application.baseUrl#</cfoutput>/common/cfc/ProxyController.cfc';
		var shopOrderId = <cfoutput>#shopOrder.shopOrderId#</cfoutput>;
		var dialogWidth = "<cfoutput>#application.kendoExtendedUiWindowWidth#</cfoutput>";
		function alertBox(title, message, icon) {
			$.when(kendo.ui.ExtAlertDialog.show({ title: title, message: message, icon: icon || "k-ext-warning", width: dialogWidth }));
		}
		<!--- Posts a change, then shows the order again and refreshes the list. --->
		function send(method, data, waiting, doneMessage) {
			$.when(kendo.ui.ExtWaitDialog.show({ title: "Please wait...", message: waiting, width: dialogWidth, icon: "k-ext-information" }));
			jQuery.ajax({
				type: 'post', url: proxy + '?method=' + method, data: $.extend({ csrfToken: csrf, shopOrderId: shopOrderId }, data), dataType: "json",
				success: function(response) {
					kendo.ui.ExtWaitDialog.hide();
					if (typeof response === "string") { try { response = JSON.parse(response); } catch (e) {} }
					if (response && response.success) {
						try { refreshShopOrdersWindow(); } catch (error) {}
						$.when(kendo.ui.ExtAlertDialog.show({ title: "Done", message: response.message || doneMessage, icon: "k-ext-information" })).done(function() {
							$("#shopOrderDetailWindow").data("kendoWindow").refresh();
						});
					} else { alertBox("That didn't work", (response && response.errorMessage) || "Please try again."); }
				},
				error: function(jqXHR, textStatus, error) {
					kendo.ui.ExtWaitDialog.hide();
					if (jqXHR.status === 403) { createLoginWindow(); } else { alertBox("Error", error, "k-ext-error"); }
				}
			});
		}
		$("#shopOrderShipped").on("click", function() {
			send("markShopOrderShipped", { shipped: true }, "Marking the order as shipped.", "The order is marked as shipped, and the buyer was emailed.");
		});
		$("#shopOrderNotShipped").on("click", function() {
			send("markShopOrderShipped", { shipped: false }, "Changing the order.", "The order is back to paid, to ship.");
		});
		$("#shopOrderRefund").on("click", function() {
			var amount = parseFloat($("#shopOrderRefundAmount").val());
			var most = <cfoutput>#shopOrder.refundable#</cfoutput>;
			if (!(amount > 0) || amount > most + 0.001) { alertBox("Please check the amount", "Enter an amount up to " + most.toFixed(2) + "."); return; }
			$.when(kendo.ui.ExtYesNoDialog.show({ title: "Refund the buyer?", message: "Refund " + amount.toFixed(2) + " to the buyer's card? This can't be undone.", icon: "k-ext-question", width: dialogWidth })).done(function(answer) {
				if (!answer['button'] || answer['button'] !== 'Yes') { return; }
				<!--- The whole amount left is sent as 0, so rounding never leaves a cent behind. --->
				send("refundShopOrderPayment", { amount: Math.abs(amount - most) < 0.001 ? 0 : amount }, "Refunding.", "The refund is on its way to the buyer's card.");
			});
		});
	});//...document.ready
</script>

<cfset blockClass = HtmlUtilsObj.getKendoClass('')>
<cfoutput>
<table align="center" class="k-content adminBlocks" width="100%" cellpadding="5" cellspacing="0" border="0" style="table-layout: fixed">
	<colgroup><col style="width: 20%"><col></colgroup>
	<tr><td colspan="2" class="#blockClass#"><h4 class="adminBlockHeading">Order #shopOrder.orderNumber#</h4></td></tr>
	<cfif shopOrder.testMode>
	<tr class="blockSpacer"><td colspan="2" class="border #blockClass#"></td></tr>
	<tr><td colspan="2" class="#blockClass#">A <b>test</b> order: paid with a Stripe test card, so no money changed hands.</td></tr>
	</cfif>
	<tr class="blockSpacer"><td colspan="2" class="border #blockClass#"></td></tr>
	<tr><td class="#blockClass#" align="right">Status:</td><td class="#blockClass#">#encodeForHtml(shopOrder.statusLabel)#</td></tr>
	<tr class="blockSpacer"><td colspan="2" class="border #blockClass#"></td></tr>
	<tr><td class="#blockClass#" align="right">Buyer:</td><td class="#blockClass#">#encodeForHtml(shopOrder.name)#<br/><a href="mailto:#encodeForHtmlAttribute(shopOrder.email)#">#encodeForHtml(shopOrder.email)#</a></td></tr>
	<tr class="blockSpacer"><td colspan="2" class="border #blockClass#"></td></tr>
	<tr><td class="#blockClass#" align="right">Ordered:</td><td class="#blockClass#">#dateFormat(isDate(shopOrder.paidAt) ? shopOrder.paidAt : shopOrder.created, "mmmm d, yyyy")# at #timeFormat(isDate(shopOrder.paidAt) ? shopOrder.paidAt : shopOrder.created, "h:mm tt")#<cfif isDate(shopOrder.shippedAt)>; shipped #dateFormat(shopOrder.shippedAt, "mmmm d")#</cfif></td></tr>
	<tr class="blockSpacer"><td colspan="2" class="#blockClass#"></td></tr>

	<cfset blockClass = HtmlUtilsObj.getKendoClass(blockClass)>
	<tr class="blockSpacer"><td colspan="2" class="border #blockClass#"></td></tr>
	<tr><td colspan="2" class="#blockClass#"><h4 class="adminBlockHeading">What they bought</h4></td></tr>
	<tr class="blockSpacer"><td colspan="2" class="border #blockClass#"></td></tr>
	<tr><td colspan="2" class="#blockClass#">#shopOrder.itemsHtml#</td></tr>
	<cfif shopOrder.refunded gt 0>
	<tr class="blockSpacer"><td colspan="2" class="border #blockClass#"></td></tr>
	<tr><td class="#blockClass#" align="right">Refunded:</td><td class="#blockClass#">#application.shop.money(shopOrder.refunded, shopOrder.currency)#</td></tr>
	</cfif>
	<cfif arrayLen(shopOrder.downloads)>
	<tr class="blockSpacer"><td colspan="2" class="border #blockClass#"></td></tr>
	<tr>
		<td class="#blockClass#" align="right">Downloads:</td>
		<td class="#blockClass#">
			<cfloop array="#shopOrder.downloads#" index="thisDownload">
				#encodeForHtml(thisDownload.name)#: downloaded #thisDownload.used# #thisDownload.used eq 1 ? "time" : "times"#<cfif len(thisDownload.expires)>, link works until #thisDownload.expires#</cfif><br/>
			</cfloop>
		</td>
	</tr>
	</cfif>
	<tr class="blockSpacer"><td colspan="2" class="#blockClass#"></td></tr>

	<cfif shopOrder.needsShipping and arrayLen(shopOrder.address)>
	<cfset blockClass = HtmlUtilsObj.getKendoClass(blockClass)>
	<tr class="blockSpacer"><td colspan="2" class="border #blockClass#"></td></tr>
	<tr><td colspan="2" class="#blockClass#"><h4 class="adminBlockHeading">Ship to</h4></td></tr>
	<tr class="blockSpacer"><td colspan="2" class="border #blockClass#"></td></tr>
	<tr><td class="#blockClass#"></td><td class="#blockClass#"><cfloop array="#shopOrder.address#" index="thisLine">#encodeForHtml(thisLine)#<br/></cfloop></td></tr>
	<tr class="blockSpacer"><td colspan="2" class="#blockClass#"></td></tr>
	</cfif>

	<!--- Shipping: a paid order, or a partly refunded one (2026-10-21), whose status stays while ShippedAt says it went. --->
	<cfset orderCanShip = shopOrder.needsShipping and (shopOrder.status eq "paid" or (shopOrder.status eq "partlyRefunded" and not isDate(shopOrder.shippedAt)))>
	<cfset orderCanUnship = shopOrder.needsShipping and (shopOrder.status eq "shipped" or (shopOrder.status eq "partlyRefunded" and isDate(shopOrder.shippedAt)))>
	<cfif orderCanShip or orderCanUnship or shopOrder.refundable gt 0>
	<cfset blockClass = HtmlUtilsObj.getKendoClass(blockClass)>
	<tr class="blockSpacer"><td colspan="2" class="border #blockClass#"></td></tr>
	<tr><td colspan="2" class="#blockClass#"><h4 class="adminBlockHeading">Actions</h4></td></tr>
		<cfif orderCanShip>
		<tr class="blockSpacer"><td colspan="2" class="border #blockClass#"></td></tr>
		<tr><td colspan="2" class="#blockClass#">Marking the order shipped emails the buyer.</td></tr>
		<tr class="blockSpacer"><td colspan="2" class="border #blockClass#"></td></tr>
		<tr><td class="#blockClass#"></td><td class="#blockClass#"><button type="button" id="shopOrderShipped" class="k-button k-primary">Mark as shipped</button></td></tr>
		<cfelseif orderCanUnship>
		<tr class="blockSpacer"><td colspan="2" class="border #blockClass#"></td></tr>
		<tr><td class="#blockClass#"></td><td class="#blockClass#"><button type="button" id="shopOrderNotShipped" class="k-button">Not shipped after all</button></td></tr>
		</cfif>
		<cfif shopOrder.refundable gt 0>
		<tr class="blockSpacer"><td colspan="2" class="border #blockClass#"></td></tr>
		<tr><td colspan="2" class="#blockClass#">Refunds go back to the buyer's card through Stripe. Up to #application.shop.money(shopOrder.refundable, shopOrder.currency)# can be refunded.</td></tr>
		<tr class="blockSpacer"><td colspan="2" class="border #blockClass#"></td></tr>
		<tr>
			<td class="#blockClass#" align="right"><label for="shopOrderRefundAmount">Refund:</label></td>
			<td class="#blockClass#"><input type="text" id="shopOrderRefundAmount" class="k-textbox" inputmode="decimal" value="#numberFormat(shopOrder.refundable, '0.00')#" style="width: 120px;"> <button type="button" id="shopOrderRefund" class="k-button">Refund</button></td>
		</tr>
		</cfif>
	</cfif>
	<!--- Notes (2026-10-22): a private note on this, at the bottom of the window. --->
	<cfset notesKind = "order"><cfset notesItemId = shopOrder.shopOrderId><cfinclude template="adminNotes.cfm">
</table>
</cfoutput>
</cfif>
