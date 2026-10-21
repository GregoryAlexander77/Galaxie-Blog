/*
	Galaxie Blog shop on the site (2026-10-21).

	A product is placed in a post or page as <div class="galaxieProduct" data-product="product-alias">[Product: Name]</div> (the post
	editor's Insert > Product), or data-product="*" for every product (a shop page). This script is downloaded only when a page has
	one, when the visitor's cart has something in it, or when they come back from Stripe - see galaxieLoader.shop in
	includes/templates/head.cfm and the check in includes/templates/tailEndScripts.cfm.

	The cart lives in the visitor's browser (localStorage) as [{ alias, quantity }] and only says what they want. The server works out
	every price, the shipping, the tax and what is still in stock each time (ProxyController.cfc's priceShopCart and
	startShopCheckout; common/cfc/Shop.cfc), and only Stripe's confirmation marks an order paid, so nothing here is relied on.
*/
var galaxieShop = (function($) {

	var proxyUrl = "";
	var storageKey = "galaxieShopCart";
	var cartWindow = null;

	// Layout only. Colors and fonts come from the Kendo theme's classes.
	function addStyles() {
		if ($("#galaxieShopStyles").length) { return; }
		$("head").append($('<style id="galaxieShopStyles"></style>').text(
			".galaxieProduct { margin: 1.5em 0; }" +
			".galaxieProductCard { display: flex; gap: 16px; padding: 14px; border: 1px solid rgba(128,128,128,0.35); border-radius: 8px; max-width: 560px; }" +
			".galaxieProductCard + .galaxieProductCard { margin-top: 14px; }" +
			".galaxieProductPicture { width: 150px; height: 150px; object-fit: cover; border-radius: 6px; flex: none; }" +
			".galaxieProductCard h3 { margin: 0 0 0.25em 0; }" +
			".galaxieProductPrice { font-size: 1.25em; margin: 0.4em 0 0.6em 0; }" +
			".galaxieProductNote { margin-top: 0.4em; opacity: 0.75; }" +
			".galaxieCartButton { position: fixed; right: 16px; bottom: 16px; z-index: 10050; border-radius: 22px; padding: 8px 16px; box-shadow: 0 4px 14px rgba(0,0,0,0.25); }" +
			".galaxieCartCount { display: inline-block; min-width: 1.4em; margin-left: 0.4em; padding: 0 0.35em; border-radius: 0.7em; text-align: center; }" +
			".galaxieCartLine { display: grid; grid-template-columns: 44px 1fr auto; gap: 10px; align-items: center; padding: 10px 0; border-bottom: 1px solid rgba(128,128,128,0.25); }" +
			".galaxieCartThumb { width: 44px; height: 44px; object-fit: cover; border-radius: 4px; background: rgba(128,128,128,0.2); display: block; }" +
			".galaxieCartQty { display: inline-flex; align-items: center; gap: 4px; margin-top: 4px; }" +
			".galaxieCartQty .k-button { min-width: 2em; padding: 0 0.4em; }" +
			".galaxieCartLink { background: none; border: 0; padding: 0; margin-left: 0.6em; font: inherit; color: inherit; text-decoration: underline; cursor: pointer; }" +
			".galaxieCartSums { margin: 12px 0; }" +
			".galaxieCartSums div { display: flex; justify-content: space-between; margin: 3px 0; }" +
			".galaxieCartNotice { padding: 8px 0; border-bottom: 1px solid rgba(128,128,128,0.3); }" +
			".galaxieCartCheckout { width: 100%; }" +
			"@media (max-width: 600px) { .galaxieProductCard { flex-direction: column; } .galaxieProductPicture { width: 100%; height: 200px; } }"
		));
	}

	function escapeHtml(value) {
		return $("<div/>").text(value === null || value === undefined ? "" : String(value)).html();
	}

	function setProxy(options) {
		proxyUrl = ((options && options.baseUrl) || "") + "/common/cfc/ProxyController.cfc";
	}

	// The cart, as [{ alias, quantity }]. Private windows and blocked storage simply give an empty cart.
	function readCart() {
		try {
			var cart = JSON.parse(window.localStorage.getItem(storageKey) || "[]");
			return $.isArray(cart) ? cart.filter(function(item) { return item && typeof item.alias === "string"; }) : [];
		} catch (e) { return []; }
	}
	function writeCart(cart) {
		try { window.localStorage.setItem(storageKey, JSON.stringify(cart)); } catch (e) {}
		refreshCartButton();
	}
	function cartCount() {
		return readCart().reduce(function(total, item) { return total + (parseInt(item.quantity, 10) || 1); }, 0);
	}

	// ---------- Product cards

	function renderCard(product, open) {
		var card = $('<div class="galaxieProductCard k-content"></div>');
		if (product.imageUrl) {
			card.append($('<img class="galaxieProductPicture" alt="">').attr("src", product.imageUrl));
		}
		var body = $("<div></div>").appendTo(card);
		body.append($("<h3></h3>").text(product.name));
		if (product.description) { body.append($("<div></div>").text(product.description)); }
		body.append($('<div class="galaxieProductPrice"></div>').text(product.priceText));
		if (product.soldOut) {
			body.append($('<button type="button" class="k-button" disabled></button>').text("Sold out"));
		} else if (!product.available) {
			body.append($('<div class="galaxieProductNote"></div>').text(open ? "Not available right now." : "The shop is closed right now."));
		} else {
			$('<button type="button" class="k-button k-primary"></button>').text("Add to cart").on("click", function() {
				addToCart(product.alias, product.kind);
			}).appendTo(body);
		}
		if (product.shippingText) {
			body.append($('<div class="galaxieProductNote"></div>').text(product.shippingText === "Free" ? "Free shipping" : "+ " + product.shippingText + " shipping"));
		} else if (product.kind === "digital") {
			body.append($('<div class="galaxieProductNote"></div>').text("A download, emailed to you right after you pay"));
		}
		return card;
	}

	function init(options) {
		setProxy(options);
		addStyles();
		var boxes = $(".galaxieProduct[data-product]");
		if (boxes.length) {
			var wanted = [];
			boxes.each(function() {
				$.each(String($(this).attr("data-product")).split(","), function(i, alias) {
					alias = $.trim(alias);
					if (alias && wanted.indexOf(alias) < 0) { wanted.push(alias); }
				});
			});
			$.ajax({ type: "post", url: proxyUrl + "?method=getShopProducts", data: { aliases: wanted.indexOf("*") >= 0 ? "*" : wanted.join(",") }, dataType: "json", cache: false })
				.done(function(result) {
					var byAlias = {};
					var all = (result && result.products) || [];
					$.each(all, function(i, p) { byAlias[p.alias] = p; });
					boxes.each(function() {
						var box = $(this).empty();
						var aliases = String(box.attr("data-product")) === "*" ? all.map(function(p) { return p.alias; }) : String(box.attr("data-product")).split(",");
						var shown = 0;
						$.each(aliases, function(i, alias) {
							var product = byAlias[$.trim(alias)];
							if (product) { box.append(renderCard(product, result.open)); shown++; }
						});
						if (!shown) { box.append($("<p></p>").text("Nothing for sale here right now.")); }
					});
				})
				.fail(function() { boxes.empty(); });
		}
		refreshCartButton();
	}

	// ---------- The cart

	function addToCart(alias, kind) {
		var cart = readCart();
		var found = false;
		$.each(cart, function(i, item) {
			if (item.alias === alias) {
				// One copy of a download is all anyone needs.
				item.quantity = kind === "digital" ? 1 : Math.min(99, (parseInt(item.quantity, 10) || 1) + 1);
				found = true;
			}
		});
		if (!found) { cart.push({ alias: alias, quantity: 1 }); }
		writeCart(cart);
		openCart();
	}

	function refreshCartButton() {
		var count = cartCount();
		var button = $("#galaxieCartButton");
		if (!count) { button.remove(); return; }
		addStyles();
		if (!button.length) {
			button = $('<button type="button" id="galaxieCartButton" class="galaxieCartButton k-button k-primary"></button>').on("click", function() { openCart(); }).appendTo("body");
		}
		button.html("Cart <span class=\"galaxieCartCount k-content\">" + count + "</span>").attr("aria-label", "Your cart, " + count + (count === 1 ? " item" : " items"));
	}

	function openCart(notice) {
		addStyles();
		if (!cartWindow) {
			var box = $('<div class="galaxieCart" role="region" aria-live="polite"></div>').appendTo("body");
			cartWindow = box.kendoWindow({
				title: "Your cart", modal: true, width: Math.min(420, $(window).width() - 30), visible: false,
				close: function() { this.destroy(); cartWindow = null; }
			}).data("kendoWindow");
		}
		var content = cartWindow.element;
		content.html("<p>Loading your cart...</p>");
		cartWindow.center().open();
		var cart = readCart();
		if (!cart.length) {
			content.empty();
			if (notice) { content.append($('<div class="galaxieCartNotice"></div>').text(notice)); }
			content.append($("<p></p>").text("Your cart is empty."));
			return;
		}
		$.ajax({ type: "post", url: proxyUrl + "?method=priceShopCart", data: { itemsJson: JSON.stringify(cart) }, dataType: "json", cache: false })
			.done(function(result) {
				if (!result || !result.success) { content.html("<p>Your cart couldn't be loaded. Please try again.</p>"); return; }
				// The server's checked cart is the truth: products no longer for sale drop out, quantities follow the stock.
				writeCart(result.lines.map(function(line) { return { alias: line.alias, quantity: line.quantity }; }));
				drawCart(content, result, notice);
				cartWindow.center();
			})
			.fail(function() { content.html("<p>Your cart couldn't be loaded. Please try again.</p>"); });
	}

	function drawCart(content, result, notice) {
		content.empty();
		var notices = (notice ? [notice] : []).concat(result.errors || []);
		$.each(notices, function(i, text) { content.append($('<div class="galaxieCartNotice"></div>').text(text)); });
		if (!result.lines.length) { content.append($("<p></p>").text("Your cart is empty.")); return; }
		$.each(result.lines, function(i, line) {
			var row = $('<div class="galaxieCartLine"></div>').appendTo(content);
			row.append(line.imageUrl ? $('<img class="galaxieCartThumb" alt="">').attr("src", line.imageUrl) : $('<span class="galaxieCartThumb"></span>'));
			var middle = $("<div></div>").appendTo(row);
			middle.append($("<div></div>").text(line.name));
			var controls = $('<div class="galaxieCartQty"></div>').appendTo(middle);
			if (line.kind !== "digital") {
				$('<button type="button" class="k-button" aria-label="One fewer">-</button>').on("click", function() { changeQuantity(line.alias, -1); }).appendTo(controls);
				controls.append($("<span></span>").text(line.quantity));
				$('<button type="button" class="k-button" aria-label="One more">+</button>').on("click", function() { changeQuantity(line.alias, 1); }).appendTo(controls);
			} else {
				controls.append($("<span></span>").text("Download"));
			}
			$('<button type="button" class="galaxieCartLink">Remove</button>').on("click", function() { changeQuantity(line.alias, -1000); }).appendTo(controls);
			row.append($("<b></b>").text(line.lineTotalText));
		});
		var sums = $('<div class="galaxieCartSums"></div>').appendTo(content);
		function sum(label, value, strong) {
			var row = $("<div></div>").appendTo(sums);
			row.append($(strong ? "<b></b>" : "<span></span>").text(label)).append($(strong ? "<b></b>" : "<span></span>").text(value));
		}
		sum("Products", result.subtotalText);
		if (result.needsShipping) { sum("Shipping", result.shippingText); }
		if (result.taxText) { sum(result.taxLabel || "Tax", result.taxText); }
		sum("Total", result.totalText, true);
		if (!result.open) {
			content.append($("<p></p>").text("The shop is closed right now, so checking out isn't possible. Your cart will keep."));
			return;
		}
		content.append($("<p></p>").text("You pay on Stripe's secure page" + (result.needsShipping ? ", and give your shipping address there." : ".")));
		$('<button type="button" class="k-button k-primary galaxieCartCheckout">Check out</button>').on("click", function() { checkout($(this)); }).appendTo(content);
	}

	function changeQuantity(alias, change) {
		var cart = readCart().map(function(item) {
			if (item.alias === alias) { item.quantity = (parseInt(item.quantity, 10) || 1) + change; }
			return item;
		}).filter(function(item) { return item.quantity > 0; });
		writeCart(cart);
		openCart();
	}

	function checkout(button) {
		button.prop("disabled", true).text("Opening the secure checkout...");
		$.ajax({ type: "post", url: proxyUrl + "?method=startShopCheckout", data: { itemsJson: JSON.stringify(readCart()), returnUrl: window.location.href }, dataType: "json", cache: false })
			.done(function(result) {
				if (result && result.success && result.checkoutUrl) {
					window.location.href = result.checkoutUrl;
				} else {
					openCart((result && result.message) || "The checkout couldn't be opened. Please try again.");
				}
			})
			.fail(function() { openCart("The checkout couldn't be opened. Please try again."); });
	}

	// ---------- Back from Stripe: ?shopCheckout=<session> after paying, ?shopCancelled=<token> after going back

	function checkoutReturn(params, options) {
		setProxy(options);
		addStyles();
		if (window.history && window.history.replaceState) {
			window.history.replaceState(null, "", window.location.pathname + window.location.hash);
		}
		if (params.cancelled) {
			$.ajax({ type: "post", url: proxyUrl + "?method=cancelShopCheckout", data: { token: params.cancelled }, dataType: "json", cache: false })
				.always(function() { openCart("You didn't pay, so nothing was ordered. Your cart is still here."); });
			return;
		}
		var box = $('<div class="galaxieShopThanks" role="status" aria-live="polite"></div>').appendTo("body");
		var dialog = box.kendoWindow({ title: "Your order", modal: true, width: Math.min(560, $(window).width() - 30), visible: false, close: function() { this.destroy(); } }).data("kendoWindow");
		box.html("<p>Checking your payment...</p>");
		dialog.center().open();
		var tries = 0;
		(function check() {
			tries++;
			$.ajax({ type: "post", url: proxyUrl + "?method=getShopCheckoutResult", data: { sessionId: params.session }, dataType: "json", cache: false })
				.done(function(result) {
					if (result && result.success && result.paid) {
						writeCart([]);
						box.empty();
						box.append($("<h3></h3>").text("Thank you!"));
						box.append($("<p></p>").text("Your order is paid" + (result.email ? ". A receipt is on its way to " + result.email + "." : ".")));
						// The server builds this table from the order and escapes every name in it (Shop.cfc itemsTable).
						box.append(result.itemsHtml || "");
						if (result.downloads && result.downloads.length) {
							box.append($("<h4></h4>").text(result.downloads.length === 1 ? "Your download" : "Your downloads"));
							$.each(result.downloads, function(i, d) {
								var p = $("<p></p>").appendTo(box);
								p.append($("<a></a>").attr("href", d.url).text(d.name));
								if (d.expires) { p.append($("<span></span>").text(" (works until " + d.expires + ")")); }
							});
						}
						if (result.needsShipping) { box.append($("<p></p>").text("We'll email you when it ships.")); }
						dialog.center();
					} else if (tries < 10) {
						setTimeout(check, 2000);
					} else {
						box.html("<h3>Thank you</h3><p>Your payment is being confirmed. Your receipt is on its way by email; if it hasn't arrived in a few minutes, please check your spam folder.</p>");
						dialog.center();
					}
				})
				.fail(function() { box.html("<h3>Thank you</h3><p>Your receipt is on its way by email.</p>"); });
		})();
	}

	return { init: init, openCart: openCart, checkoutReturn: checkoutReturn };

})(jQuery);
