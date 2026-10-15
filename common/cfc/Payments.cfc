<cfcomponent displayName="Payments" output="false" hint="The blog's payment settings and money formatting (2026-10-14): one currency per blog, tax included or one added rate, test or live mode, and the owner's own Stripe keys. Edited in Blog Settings > Payments. Created once as application.payments in Application.cfc. The entity is PaymentSetting (common/cfc/db/galaxieDb). See doc/aiDraftArticles/eventsAndFormsDesign.cfm, Part 4.">

<!---
	Every write is inside a cftransaction: the application sets ormsettings.flushAtRequestEnd = false, so an entity change made
	outside a transaction (without ormFlush) would never reach the database.

	The secret key and the webhook signing secret are stored encrypted with a key kept in blog.ini.cfm ([payments]
	encryptionKey), so a copy of the database (a backup or an export) doesn't carry usable Stripe keys. They are never sent
	to the browser, logged, or put in an error message; the admin page only shows that one is saved and its last 4 characters.
	If blog.ini.cfm is replaced, the saved secrets can't be read any more and the owner enters them again.
--->

<cffunction name="init" access="public" returntype="any" output="false">
	<!--- The currencies offered, most used first. Formatting and decimal places come from Java's own currency data. --->
	<cfset variables.currencyCodes = "USD,EUR,GBP,CAD,AUD,NZD,CHF,SEK,NOK,DKK,PLN,CZK,HUF,JPY,SGD,HKD,INR,MXN,BRL,ZAR,ILS,AED">
	<cfset variables.settingsCache = {}>
	<cfreturn this>
</cffunction>

<!--- ********************************************************************************************************************
	Reading
********************************************************************************************************************* --->

<cffunction name="getCurrencies" access="public" returntype="array" output="false"
		hint="The currencies offered in Blog Settings: [{ code, name }].">
	<cfset var currencies = []>
	<cfset var code = "">
	<cfset var javaCurrency = createObject("java", "java.util.Currency")>
	<cfloop list="#variables.currencyCodes#" index="code">
		<cfset arrayAppend(currencies, { code: code, name: code & " - " & javaCurrency.getInstance(code).getDisplayName(getBlogJavaLocale()) })>
	</cfloop>
	<cfreturn currencies>
</cffunction>

<cffunction name="getSettings" access="public" returntype="struct" output="false"
		hint="The payment settings without any secret: currency, taxMode, taxName, taxRate, testMode, test and live { publishableKey, hasSecretKey, secretKeyHint, hasWebhookSecret, webhookSecretHint }, webhookUrl, secretsUnreadable.">
	<cfset var entity = loadEntity()>
	<cfset var settings = {
		currency: "USD", taxMode: "included", taxName: "", taxRate: 0, testMode: true,
		test: keyInfo("", "", ""), live: keyInfo("", "", ""),
		webhookUrl: getWebhookUrl(), secretsUnreadable: false
	}>
	<cfif not isNull(entity)>
		<cfset settings.currency = valueOrEmpty(entity.getCurrency())>
		<cfif not listFind(variables.currencyCodes, settings.currency)><cfset settings.currency = "USD"></cfif>
		<cfset settings.taxMode = valueOrEmpty(entity.getTaxMode()) eq "add" ? "add" : "included">
		<cfset settings.taxName = valueOrEmpty(entity.getTaxName())>
		<cfset settings.taxRate = val(valueOrEmpty(entity.getTaxRate()))>
		<cfset settings.testMode = isTrue(entity.getTestMode(), true)>
		<cfset settings.test = keyInfo(valueOrEmpty(entity.getStripeTestPublishableKey()), valueOrEmpty(entity.getStripeTestSecretKey()), valueOrEmpty(entity.getStripeTestWebhookSecret()))>
		<cfset settings.live = keyInfo(valueOrEmpty(entity.getStripeLivePublishableKey()), valueOrEmpty(entity.getStripeLiveSecretKey()), valueOrEmpty(entity.getStripeLiveWebhookSecret()))>
		<cfset settings.secretsUnreadable = settings.test.unreadable or settings.live.unreadable>
	</cfif>
	<cfreturn settings>
</cffunction>

<cffunction name="getCurrency" access="public" returntype="string" output="false" hint="The blog's currency code, eg. USD.">
	<cfreturn cachedSettings().currency>
</cffunction>

<cffunction name="getStripeKeys" access="public" returntype="struct" output="false"
		hint="Server use only (never send this to the browser): the keys for the current mode, { testMode, publishableKey, secretKey, webhookSecret }. A key that isn't saved, or can't be read, is an empty string.">
	<cfset var entity = loadEntity()>
	<cfset var keys = { testMode: true, publishableKey: "", secretKey: "", webhookSecret: "" }>
	<cfif not isNull(entity)>
		<cfset keys.testMode = isTrue(entity.getTestMode(), true)>
		<cfif keys.testMode>
			<cfset keys.publishableKey = valueOrEmpty(entity.getStripeTestPublishableKey())>
			<cfset keys.secretKey = decryptSecret(valueOrEmpty(entity.getStripeTestSecretKey()))>
			<cfset keys.webhookSecret = decryptSecret(valueOrEmpty(entity.getStripeTestWebhookSecret()))>
		<cfelse>
			<cfset keys.publishableKey = valueOrEmpty(entity.getStripeLivePublishableKey())>
			<cfset keys.secretKey = decryptSecret(valueOrEmpty(entity.getStripeLiveSecretKey()))>
			<cfset keys.webhookSecret = decryptSecret(valueOrEmpty(entity.getStripeLiveWebhookSecret()))>
		</cfif>
	</cfif>
	<cfreturn keys>
</cffunction>

<cffunction name="getStatus" access="public" returntype="struct" output="false"
		hint="Whether online payment can be taken in the current mode: { ready, testMode, missing[] } - missing names what still has to be entered.">
	<cfset var settings = getSettings()>
	<cfset var keys = settings.testMode ? settings.test : settings.live>
	<cfset var modeName = settings.testMode ? "test" : "live">
	<cfset var status = { ready: false, testMode: settings.testMode, missing: [] }>
	<cfif not len(keys.publishableKey)><cfset arrayAppend(status.missing, "the Stripe #modeName# publishable key")></cfif>
	<cfif not keys.hasSecretKey or keys.unreadable><cfset arrayAppend(status.missing, "the Stripe #modeName# secret key")></cfif>
	<cfif not keys.hasWebhookSecret or keys.unreadable><cfset arrayAppend(status.missing, "the Stripe #modeName# webhook signing secret")></cfif>
	<cfset status.ready = arrayLen(status.missing) eq 0>
	<cfreturn status>
</cffunction>

<cffunction name="getWebhookUrl" access="public" returntype="string" output="false"
		hint="The address the owner enters in their Stripe dashboard (Developers > Webhooks).">
	<cfreturn application.blogHostUrl & "/common/services/stripeWebhook.cfm">
</cffunction>

<!--- ********************************************************************************************************************
	Money
********************************************************************************************************************* --->

<cffunction name="formatMoney" access="public" returntype="string" output="false"
		hint="An amount written the way the blog's locale writes the currency, eg. $99.00, CA$99.00 or 7,500 yen with no decimals.">
	<cfargument name="amount" required="true">
	<cfargument name="currencyCode" type="string" required="false" default="" hint="Defaults to the blog's currency.">
	<cfset var code = len(arguments.currencyCode) ? uCase(arguments.currencyCode) : getCurrency()>
	<cfset var javaCurrency = "">
	<cfset var formatter = "">
	<cftry>
		<cfset javaCurrency = createObject("java", "java.util.Currency").getInstance(code)>
		<cfset formatter = createObject("java", "java.text.NumberFormat").getCurrencyInstance(getBlogJavaLocale())>
		<cfset formatter.setCurrency(javaCurrency)>
		<cfset formatter.setMinimumFractionDigits(javaCurrency.getDefaultFractionDigits())>
		<cfset formatter.setMaximumFractionDigits(javaCurrency.getDefaultFractionDigits())>
		<cfreturn formatter.format(javacast("double", val(arguments.amount)))>
		<cfcatch type="any">
			<cfreturn code & " " & numberFormat(val(arguments.amount), "0.00")>
		</cfcatch>
	</cftry>
</cffunction>

<cffunction name="getTaxText" access="public" returntype="string" output="false"
		hint="How tax is shown next to prices: an empty string when prices include tax, otherwise eg. 'plus Sales tax (8.25%)'.">
	<cfset var settings = cachedSettings()>
	<cfif settings.taxMode neq "add" or settings.taxRate lte 0>
		<cfreturn "">
	</cfif>
	<cfreturn "plus " & (len(settings.taxName) ? settings.taxName : "tax") & " (" & formatPercent(settings.taxRate) & "%)">
</cffunction>

<!--- ********************************************************************************************************************
	Saving (Blog Settings)
********************************************************************************************************************* --->

<cffunction name="validateSettings" access="public" returntype="array" output="false"
		hint="The problems with the posted settings (an empty array when they can be saved). Called before Blog Settings saves anything.">
	<cfargument name="data" type="struct" required="true" hint="As saveSettings takes it.">
	<cfset var errors = []>
	<cfset var d = normalize(arguments.data)>
	<cfset var current = getSettings()>
	<cfset var keyError = "">
	<cfif not listFind(variables.currencyCodes, d.currency)>
		<cfset arrayAppend(errors, "Choose a currency.")>
	</cfif>
	<cfif d.taxMode eq "add" and (not isNumeric(d.taxRate) or d.taxRate lte 0 or d.taxRate gte 100)>
		<cfset arrayAppend(errors, "Enter the tax rate as a percentage, eg. 8.25.")>
	</cfif>
	<cfset keyError = checkKey(d.stripeTestPublishableKey, "pk_test_", "The Stripe test publishable key")><cfif len(keyError)><cfset arrayAppend(errors, keyError)></cfif>
	<cfset keyError = checkKey(d.stripeTestSecretKey, "sk_test_,rk_test_", "The Stripe test secret key")><cfif len(keyError)><cfset arrayAppend(errors, keyError)></cfif>
	<cfset keyError = checkKey(d.stripeTestWebhookSecret, "whsec_", "The Stripe test webhook signing secret")><cfif len(keyError)><cfset arrayAppend(errors, keyError)></cfif>
	<cfset keyError = checkKey(d.stripeLivePublishableKey, "pk_live_", "The Stripe live publishable key")><cfif len(keyError)><cfset arrayAppend(errors, keyError)></cfif>
	<cfset keyError = checkKey(d.stripeLiveSecretKey, "sk_live_,rk_live_", "The Stripe live secret key")><cfif len(keyError)><cfset arrayAppend(errors, keyError)></cfif>
	<cfset keyError = checkKey(d.stripeLiveWebhookSecret, "whsec_", "The Stripe live webhook signing secret")><cfif len(keyError)><cfset arrayAppend(errors, keyError)></cfif>
	<!--- Live mode needs its keys: turning test mode off without them would break checkout for visitors. --->
	<cfif not d.testMode>
		<cfif d.clearLiveKeys or (not len(d.stripeLivePublishableKey)) or (not len(d.stripeLiveSecretKey) and not current.live.hasSecretKey) or (not len(d.stripeLiveWebhookSecret) and not current.live.hasWebhookSecret)>
			<cfset arrayAppend(errors, "To turn test mode off, enter all three Stripe live keys first.")>
		</cfif>
	</cfif>
	<cfreturn errors>
</cffunction>

<cffunction name="saveSettings" access="public" returntype="struct" output="false"
		hint="Saves the payment settings. Returns { success, errors[] }; nothing is saved when something is wrong. A blank secret field keeps the saved secret.">
	<cfargument name="data" type="struct" required="true" hint="currency, taxMode, taxName, taxRate, testMode, stripeTest/LivePublishableKey, stripeTest/LiveSecretKey, stripeTest/LiveWebhookSecret, clearTestKeys, clearLiveKeys.">
	<cfset var result = { success: false, errors: validateSettings(arguments.data) }>
	<cfset var d = normalize(arguments.data)>
	<cfset var entity = "">
	<cfif arrayLen(result.errors)>
		<cfreturn result>
	</cfif>
	<cftransaction>
		<cfset entity = loadEntity()>
		<cfif isNull(entity)>
			<cfset entity = entityNew("PaymentSetting")>
			<cfset entity.setBlogRef(javacast("int", application.BlogDbObj.getBlogId()))>
			<cfset entity.setCreated(now())>
		</cfif>
		<cfset entity.setCurrency(d.currency)>
		<cfset entity.setTaxMode(d.taxMode)>
		<cfset entity.setTaxName(d.taxMode eq "add" ? left(d.taxName, 50) : "")>
		<cfset entity.setTaxRate(javacast("bigdecimal", d.taxMode eq "add" ? round(d.taxRate * 1000) / 1000 : 0))>
		<cfset entity.setTestMode(d.testMode)>
		<!--- Test keys --->
		<cfif d.clearTestKeys>
			<cfset entity.setStripeTestPublishableKey("")>
			<cfset entity.setStripeTestSecretKey("")>
			<cfset entity.setStripeTestWebhookSecret("")>
		<cfelse>
			<cfset entity.setStripeTestPublishableKey(d.stripeTestPublishableKey)>
			<cfif len(d.stripeTestSecretKey)><cfset entity.setStripeTestSecretKey(encryptSecret(d.stripeTestSecretKey))></cfif>
			<cfif len(d.stripeTestWebhookSecret)><cfset entity.setStripeTestWebhookSecret(encryptSecret(d.stripeTestWebhookSecret))></cfif>
		</cfif>
		<!--- Live keys --->
		<cfif d.clearLiveKeys>
			<cfset entity.setStripeLivePublishableKey("")>
			<cfset entity.setStripeLiveSecretKey("")>
			<cfset entity.setStripeLiveWebhookSecret("")>
		<cfelse>
			<cfset entity.setStripeLivePublishableKey(d.stripeLivePublishableKey)>
			<cfif len(d.stripeLiveSecretKey)><cfset entity.setStripeLiveSecretKey(encryptSecret(d.stripeLiveSecretKey))></cfif>
			<cfif len(d.stripeLiveWebhookSecret)><cfset entity.setStripeLiveWebhookSecret(encryptSecret(d.stripeLiveWebhookSecret))></cfif>
		</cfif>
		<cfset entity.setDate(now())>
		<cfset entitySave(entity)>
	</cftransaction>
	<cfset variables.settingsCache = {}>
	<cfset result.success = true>
	<cfreturn result>
</cffunction>

<!--- ********************************************************************************************************************
	Stripe (2026-10-15): hosted Checkout only, so card details never reach this server. A payment is only ever marked paid by
	a webhook whose signature checks out (common/services/stripeWebhook.cfm), never by the page the visitor comes back to.
********************************************************************************************************************* --->

<cffunction name="getTax" access="public" returntype="struct" output="false"
		hint="The tax added to an amount at checkout: { amount, label }. amount is 0 when prices include tax.">
	<cfargument name="amount" required="true">
	<cfset var settings = cachedSettings()>
	<cfset var tax = { amount: 0, label: "" }>
	<cfif settings.taxMode eq "add" and settings.taxRate gt 0 and val(arguments.amount) gt 0>
		<cfset tax.amount = round(val(arguments.amount) * settings.taxRate) / 100>
		<cfset tax.label = (len(settings.taxName) ? settings.taxName : "Tax") & " (" & formatPercent(settings.taxRate) & "%)">
	</cfif>
	<cfreturn tax>
</cffunction>

<cffunction name="toMinorUnits" access="public" returntype="string" output="false"
		hint="An amount in the currency's smallest unit, as Stripe wants it: 99.00 USD is 9900, 7500 JPY is 7500.">
	<cfargument name="amount" required="true">
	<cfargument name="currencyCode" type="string" required="true">
	<cfset var digits = 2>
	<cftry>
		<cfset digits = createObject("java", "java.util.Currency").getInstance(uCase(arguments.currencyCode)).getDefaultFractionDigits()>
		<cfcatch type="any"></cfcatch>
	</cftry>
	<cfreturn numberFormat(round(val(arguments.amount) * (10 ^ max(digits, 0))), "0")>
</cffunction>

<cffunction name="fromMinorUnits" access="public" returntype="numeric" output="false">
	<cfargument name="minorAmount" required="true">
	<cfargument name="currencyCode" type="string" required="true">
	<cfset var digits = 2>
	<cftry>
		<cfset digits = createObject("java", "java.util.Currency").getInstance(uCase(arguments.currencyCode)).getDefaultFractionDigits()>
		<cfcatch type="any"></cfcatch>
	</cftry>
	<cfreturn val(arguments.minorAmount) / (10 ^ max(digits, 0))>
</cffunction>

<cffunction name="createBookingCheckout" access="public" returntype="struct" output="false"
		hint="Starts a Stripe Checkout Session for a booking and records it as a pending Payment. Returns { success, url, sessionId, message }.">
	<cfargument name="bookingId" type="numeric" required="true">
	<cfargument name="purpose" type="string" required="true" hint="full or deposit">
	<cfargument name="itemName" type="string" required="true">
	<cfargument name="itemDescription" type="string" required="false" default="">
	<cfargument name="amount" required="true" hint="Before tax, in the currency's normal units.">
	<cfargument name="currencyCode" type="string" required="true">
	<cfargument name="email" type="string" required="false" default="">
	<cfargument name="successUrl" type="string" required="true" hint="May contain {CHECKOUT_SESSION_ID}.">
	<cfargument name="cancelUrl" type="string" required="true">
	<cfargument name="expiresInMinutes" type="numeric" required="false" default="31" hint="Stripe allows 30 minutes to 24 hours.">
	<cfset var result = { success: false, url: "", sessionId: "", message: "" }>
	<cfset var keys = getStripeKeys()>
	<cfset var tax = getTax(arguments.amount)>
	<cfset var fields = []>
	<cfset var answer = "">
	<cfset var entity = "">
	<cfset var nowSeconds = int(createObject("java", "java.lang.System").currentTimeMillis() / 1000)>
	<cfif not len(keys.secretKey)>
		<cfset result.message = "Online payment isn't set up yet.">
		<cfreturn result>
	</cfif>
	<cfset arrayAppend(fields, ["mode", "payment"])>
	<cfset arrayAppend(fields, ["client_reference_id", "booking-" & arguments.bookingId])>
	<cfif isValid("email", arguments.email)><cfset arrayAppend(fields, ["customer_email", arguments.email])></cfif>
	<cfset arrayAppend(fields, ["success_url", arguments.successUrl])>
	<cfset arrayAppend(fields, ["cancel_url", arguments.cancelUrl])>
	<!--- Stripe allows 30 minutes to 24 hours. --->
	<cfset arrayAppend(fields, ["expires_at", numberFormat(nowSeconds + min(max(arguments.expiresInMinutes, 30), 1430) * 60 + 30, "0")])>
	<cfset arrayAppend(fields, ["allow_promotion_codes", "true"])>
	<!--- Which payment methods are offered is set in the owner's Stripe dashboard (Settings > Payment methods); Stripe no longer
	accepts payment_method_types here. Methods that take days to clear (bank debits) are best turned off there: a booking is only
	held for a short time. --->
	<cfset arrayAppend(fields, ["metadata[bookingId]", arguments.bookingId])>
	<cfset arrayAppend(fields, ["metadata[purpose]", arguments.purpose])>
	<cfset arrayAppend(fields, ["payment_intent_data[metadata][bookingId]", arguments.bookingId])>
	<cfset arrayAppend(fields, ["line_items[0][quantity]", "1"])>
	<cfset arrayAppend(fields, ["line_items[0][price_data][currency]", lCase(arguments.currencyCode)])>
	<cfset arrayAppend(fields, ["line_items[0][price_data][unit_amount]", toMinorUnits(arguments.amount, arguments.currencyCode)])>
	<cfset arrayAppend(fields, ["line_items[0][price_data][product_data][name]", left(arguments.itemName, 250)])>
	<cfif len(trim(arguments.itemDescription))>
		<cfset arrayAppend(fields, ["line_items[0][price_data][product_data][description]", left(trim(arguments.itemDescription), 500)])>
	</cfif>
	<cfif tax.amount gt 0>
		<cfset arrayAppend(fields, ["line_items[1][quantity]", "1"])>
		<cfset arrayAppend(fields, ["line_items[1][price_data][currency]", lCase(arguments.currencyCode)])>
		<cfset arrayAppend(fields, ["line_items[1][price_data][unit_amount]", toMinorUnits(tax.amount, arguments.currencyCode)])>
		<cfset arrayAppend(fields, ["line_items[1][price_data][product_data][name]", tax.label])>
	</cfif>
	<cfset answer = stripeRequest("POST", "/v1/checkout/sessions", fields, "booking-" & arguments.bookingId & "-" & arguments.purpose & "-" & hash(createUUID()))>
	<cfif not answer.success or not structKeyExists(answer.data, "id") or not structKeyExists(answer.data, "url")>
		<cfset result.message = "The payment page couldn't be opened. Please try again in a moment.">
		<cflog file="galaxieBlogErrors" type="error" text="Booking #arguments.bookingId#: Stripe checkout failed (#answer.status#): #answer.message#">
		<cfreturn result>
	</cfif>
	<cftransaction>
		<cfset entity = entityNew("Payment")>
		<cfset entity.setBlogRef(javacast("int", application.BlogDbObj.getBlogId()))>
		<cfset entity.setBookingRef(javacast("int", arguments.bookingId))>
		<cfset entity.setWebFormSubmissionRef(javacast("int", 0))>
		<cfset entity.setProvider("stripe")>
		<cfset entity.setProviderSessionId(answer.data.id)>
		<cfset entity.setProviderPaymentId("")>
		<cfset entity.setPurpose(arguments.purpose)>
		<cfset entity.setAmount(javacast("bigdecimal", val(arguments.amount)))>
		<cfset entity.setTaxAmount(javacast("bigdecimal", tax.amount))>
		<cfset entity.setAmountPaid(javacast("bigdecimal", 0))>
		<cfset entity.setRefundedAmount(javacast("bigdecimal", 0))>
		<cfset entity.setCurrency(uCase(arguments.currencyCode))>
		<cfset entity.setStatus("pending")>
		<cfset entity.setTestMode(keys.testMode)>
		<cfset entity.setCreated(now())>
		<cfset entity.setDate(now())>
		<cfset entitySave(entity)>
	</cftransaction>
	<cfset result.success = true>
	<cfset result.url = answer.data.url>
	<cfset result.sessionId = answer.data.id>
	<cfreturn result>
</cffunction>

<cffunction name="expireCheckout" access="public" returntype="boolean" output="false"
		hint="Closes an open Checkout Session so it can no longer be paid (the visitor went back without paying).">
	<cfargument name="sessionId" type="string" required="true">
	<cfset var answer = "">
	<cfif not reFind("^cs_[A-Za-z0-9_]+$", arguments.sessionId)>
		<cfreturn false>
	</cfif>
	<cfset answer = stripeRequest("POST", "/v1/checkout/sessions/" & arguments.sessionId & "/expire", [], "")>
	<cfreturn answer.success>
</cffunction>

<cffunction name="getPaymentBySession" access="public" returntype="struct" output="false"
		hint="A recorded payment by its Checkout Session id: { paymentId, bookingId, purpose, amount, taxAmount, amountPaid, currency, status, testMode }, or an empty struct.">
	<cfargument name="sessionId" type="string" required="true">
	<cfset var found = []>
	<cfif reFind("^cs_[A-Za-z0-9_]+$", arguments.sessionId)>
		<cfset found = ormExecuteQuery("FROM Payment WHERE ProviderSessionId = :sessionId AND BlogRef = :blogId", { sessionId = arguments.sessionId, blogId = javacast("int", application.BlogDbObj.getBlogId()) })>
	</cfif>
	<cfif not arrayLen(found)>
		<cfreturn {}>
	</cfif>
	<cfreturn {
		paymentId: found[1].getPaymentId(),
		bookingId: val(valueOrEmpty(found[1].getBookingRef())),
		purpose: valueOrEmpty(found[1].getPurpose()),
		amount: val(valueOrEmpty(found[1].getAmount())),
		taxAmount: val(valueOrEmpty(found[1].getTaxAmount())),
		amountPaid: val(valueOrEmpty(found[1].getAmountPaid())),
		currency: valueOrEmpty(found[1].getCurrency()),
		status: valueOrEmpty(found[1].getStatus()),
		testMode: isTrue(found[1].getTestMode(), true)
	}>
</cffunction>

<cffunction name="getPaymentsForBooking" access="public" returntype="array" output="false"
		hint="A booking's payments that went through, newest first: [{ paymentId, sessionId, paymentIntentId, purpose, amountPaid, refunded, status, currency }].">
	<cfargument name="bookingId" type="numeric" required="true">
	<cfset var payments = []>
	<cfset var e = "">
	<cfset var found = ormExecuteQuery("FROM Payment WHERE BookingRef = :bookingId AND BlogRef = :blogId AND Status IN ('paid', 'partlyRefunded', 'refunded') ORDER BY PaymentId DESC", { bookingId = javacast("int", arguments.bookingId), blogId = javacast("int", application.BlogDbObj.getBlogId()) })>
	<cfloop array="#found#" index="e">
		<cfset arrayAppend(payments, {
			paymentId: e.getPaymentId(),
			sessionId: valueOrEmpty(e.getProviderSessionId()),
			paymentIntentId: valueOrEmpty(e.getProviderPaymentId()),
			purpose: valueOrEmpty(e.getPurpose()),
			amountPaid: val(valueOrEmpty(e.getAmountPaid())),
			refunded: val(valueOrEmpty(e.getRefundedAmount())),
			status: valueOrEmpty(e.getStatus()),
			currency: valueOrEmpty(e.getCurrency())
		})>
	</cfloop>
	<cfreturn payments>
</cffunction>

<cffunction name="getPaymentTotals" access="public" returntype="struct" output="false"
		hint="What a booking's payments add up to: { paid, refunded, refundable }.">
	<cfargument name="bookingId" type="numeric" required="true">
	<cfset var totals = { paid: 0, refunded: 0, refundable: 0 }>
	<cfset var payment = "">
	<cfloop array="#getPaymentsForBooking(arguments.bookingId)#" index="payment">
		<cfset totals.paid = totals.paid + payment.amountPaid>
		<cfset totals.refunded = totals.refunded + payment.refunded>
	</cfloop>
	<cfset totals.refundable = max(round((totals.paid - totals.refunded) * 100) / 100, 0)>
	<cfreturn totals>
</cffunction>

<cffunction name="refundBooking" access="public" returntype="struct" output="false"
		hint="Refunds a booking's online payments through Stripe, newest first: all of it, or up to amount. Returns { success, refunded, message }.">
	<cfargument name="bookingId" type="numeric" required="true">
	<cfargument name="amount" required="false" default="0" hint="0 = everything that can still be refunded.">
	<cfset var result = { success: false, refunded: 0, message: "" }>
	<cfset var totals = getPaymentTotals(arguments.bookingId)>
	<cfset var remaining = val(arguments.amount) gt 0 ? min(val(arguments.amount), totals.refundable) : totals.refundable>
	<cfset var payment = "">
	<cfset var part = 0>
	<cfset var answer = "">
	<cfif remaining lte 0>
		<cfset result.message = "There's nothing left to refund.">
		<cfreturn result>
	</cfif>
	<cfloop array="#getPaymentsForBooking(arguments.bookingId)#" index="payment">
		<cfif remaining lte 0><cfbreak></cfif>
		<cfset part = min(remaining, round((payment.amountPaid - payment.refunded) * 100) / 100)>
		<cfif part gt 0 and len(payment.paymentIntentId)>
			<cfset answer = stripeRequest("POST", "/v1/refunds", [
				["payment_intent", payment.paymentIntentId],
				["amount", toMinorUnits(part, payment.currency)],
				["metadata[bookingId]", arguments.bookingId]
			], "refund-" & payment.paymentId & "-" & toMinorUnits(payment.refunded + part, payment.currency))>
			<cfif not answer.success>
				<cfset result.message = "Stripe didn't make the refund: " & answer.message>
				<cflog file="galaxieBlogErrors" type="error" text="Booking #arguments.bookingId#: refund failed (#answer.status#): #answer.message#">
				<cfbreak>
			</cfif>
			<cfset recordRefund(payment.paymentId, payment.refunded + part)>
			<cfset result.refunded = result.refunded + part>
			<cfset remaining = round((remaining - part) * 100) / 100>
		</cfif>
	</cfloop>
	<cfset result.success = result.refunded gt 0>
	<cfreturn result>
</cffunction>

<cffunction name="applyRefundFromWebhook" access="public" returntype="numeric" output="false"
		hint="A refund reported by Stripe (charge.refunded), including ones made in the Stripe dashboard. amountRefunded is the charge's total refunded so far. Returns the booking id, or 0.">
	<cfargument name="paymentIntentId" type="string" required="true">
	<cfargument name="amountRefunded" required="true">
	<cfset var found = ormExecuteQuery("FROM Payment WHERE ProviderPaymentId = :pi AND BlogRef = :blogId", { pi = arguments.paymentIntentId, blogId = javacast("int", application.BlogDbObj.getBlogId()) })>
	<cfif not arrayLen(found)>
		<cfreturn 0>
	</cfif>
	<cfset recordRefund(found[1].getPaymentId(), max(val(arguments.amountRefunded), val(valueOrEmpty(found[1].getRefundedAmount()))))>
	<cfreturn val(valueOrEmpty(found[1].getBookingRef()))>
</cffunction>

<cffunction name="recordRefund" access="private" returntype="void" output="false">
	<cfargument name="paymentId" type="numeric" required="true">
	<cfargument name="refundedTotal" required="true">
	<cfset var e = entityLoadByPK("Payment", javacast("int", arguments.paymentId))>
	<cfif isNull(e)><cfreturn></cfif>
	<cftransaction>
		<cfset e.setRefundedAmount(javacast("bigdecimal", val(arguments.refundedTotal)))>
		<cfset e.setStatus(val(arguments.refundedTotal) gte val(valueOrEmpty(e.getAmountPaid())) ? "refunded" : "partlyRefunded")>
		<cfset e.setDate(now())>
		<cfset entitySave(e)>
	</cftransaction>
</cffunction>

<cffunction name="getOpenSessionForBooking" access="public" returntype="string" output="false"
		hint="The Checkout Session id of a booking's payment that is still open (pending), or an empty string.">
	<cfargument name="bookingId" type="numeric" required="true">
	<cfset var found = ormExecuteQuery("FROM Payment WHERE BookingRef = :bookingId AND Status = :status AND BlogRef = :blogId ORDER BY PaymentId DESC", { bookingId = javacast("int", arguments.bookingId), status = "pending", blogId = javacast("int", application.BlogDbObj.getBlogId()) })>
	<cfreturn arrayLen(found) ? found[1].getProviderSessionId() : "">
</cffunction>

<cffunction name="setPaymentStatus" access="public" returntype="void" output="false"
		hint="Records what happened to a payment (from a verified webhook, or when the visitor cancels).">
	<cfargument name="sessionId" type="string" required="true">
	<cfargument name="status" type="string" required="true" hint="paid, expired or cancelled">
	<cfargument name="amountPaid" required="false" default="0">
	<cfargument name="providerPaymentId" type="string" required="false" default="">
	<cfset var found = ormExecuteQuery("FROM Payment WHERE ProviderSessionId = :sessionId AND BlogRef = :blogId", { sessionId = arguments.sessionId, blogId = javacast("int", application.BlogDbObj.getBlogId()) })>
	<cfif not arrayLen(found)>
		<cfreturn>
	</cfif>
	<cftransaction>
		<cfset found[1].setStatus(arguments.status)>
		<cfif arguments.status eq "paid">
			<cfset found[1].setAmountPaid(javacast("bigdecimal", val(arguments.amountPaid)))>
		</cfif>
		<cfif len(arguments.providerPaymentId)>
			<cfset found[1].setProviderPaymentId(left(arguments.providerPaymentId, 255))>
		</cfif>
		<cfset found[1].setDate(now())>
		<cfset entitySave(found[1])>
	</cftransaction>
</cffunction>

<cffunction name="verifyStripeSignature" access="public" returntype="struct" output="false"
		hint="Checks a webhook's Stripe-Signature header against the raw body with the current mode's signing secret: { valid, reason }. Rejects messages older than 5 minutes so an old one can't be replayed.">
	<cfargument name="payload" type="string" required="true" hint="The raw request body, exactly as received.">
	<cfargument name="signatureHeader" type="string" required="true">
	<cfset var result = { valid: false, reason: "" }>
	<cfset var secret = getStripeKeys().webhookSecret>
	<cfset var timestamp = "">
	<cfset var signatures = []>
	<cfset var part = "">
	<cfset var expected = "">
	<cfset var nowSeconds = int(createObject("java", "java.lang.System").currentTimeMillis() / 1000)>
	<cfif not len(secret)>
		<cfset result.reason = "no signing secret saved">
		<cfreturn result>
	</cfif>
	<cfloop list="#arguments.signatureHeader#" index="part">
		<cfif listFirst(trim(part), "=") eq "t"><cfset timestamp = listRest(trim(part), "=")></cfif>
		<cfif listFirst(trim(part), "=") eq "v1"><cfset arrayAppend(signatures, lCase(listRest(trim(part), "=")))></cfif>
	</cfloop>
	<cfif not isNumeric(timestamp) or not arrayLen(signatures)>
		<cfset result.reason = "no signature">
		<cfreturn result>
	</cfif>
	<cfif abs(nowSeconds - val(timestamp)) gt 300>
		<cfset result.reason = "too old">
		<cfreturn result>
	</cfif>
	<cfset expected = lCase(hmac(timestamp & "." & arguments.payload, secret, "HmacSHA256", "UTF-8"))>
	<cfif arrayFind(signatures, expected)>
		<cfset result.valid = true>
	<cfelse>
		<cfset result.reason = "signature mismatch">
	</cfif>
	<cfreturn result>
</cffunction>

<cffunction name="webhookEventSeen" access="public" returntype="boolean" output="false"
		hint="Whether a valid webhook with this event id was already handled (Stripe can send the same event more than once).">
	<cfargument name="eventId" type="string" required="true">
	<cfreturn arrayLen(ormExecuteQuery("FROM PaymentWebhookLog WHERE EventId = :eventId AND SignatureValid = :valid AND BlogRef = :blogId", { eventId = arguments.eventId, valid = true, blogId = javacast("int", application.BlogDbObj.getBlogId()) })) gt 0>
</cffunction>

<cffunction name="logWebhookEvent" access="public" returntype="void" output="false">
	<cfargument name="eventId" type="string" required="true">
	<cfargument name="eventType" type="string" required="true">
	<cfargument name="signatureValid" type="boolean" required="true">
	<cfargument name="result" type="string" required="true">
	<cfargument name="testMode" type="boolean" required="false" default="true">
	<cfset var entity = "">
	<cftransaction>
		<cfset entity = entityNew("PaymentWebhookLog")>
		<cfset entity.setBlogRef(javacast("int", application.BlogDbObj.getBlogId()))>
		<cfset entity.setProvider("stripe")>
		<cfset entity.setEventId(left(arguments.eventId, 255))>
		<cfset entity.setEventType(left(arguments.eventType, 100))>
		<cfset entity.setSignatureValid(arguments.signatureValid)>
		<cfset entity.setResult(left(arguments.result, 500))>
		<cfset entity.setTestMode(arguments.testMode)>
		<cfset entity.setReceived(now())>
		<cfset entitySave(entity)>
	</cftransaction>
</cffunction>

<cffunction name="stripeRequest" access="private" returntype="struct" output="false"
		hint="One call to the Stripe API with the current mode's secret key: { success, status, data, message }. The key is only ever sent to Stripe.">
	<cfargument name="method" type="string" required="true">
	<cfargument name="path" type="string" required="true">
	<cfargument name="fields" type="array" required="true" hint="[[name, value], ...] form fields, in order.">
	<cfargument name="idempotencyKey" type="string" required="false" default="">
	<cfset var result = { success: false, status: 0, data: {}, message: "" }>
	<cfset var secretKey = getStripeKeys().secretKey>
	<cfset var field = "">
	<cfset var httpResult = "">
	<cftry>
		<cfhttp url="https://api.stripe.com#arguments.path#" method="#arguments.method#" timeout="20" result="httpResult" charset="utf-8">
			<cfhttpparam type="header" name="Authorization" value="Bearer #secretKey#">
			<cfif len(arguments.idempotencyKey)>
				<cfhttpparam type="header" name="Idempotency-Key" value="#arguments.idempotencyKey#">
			</cfif>
			<cfloop array="#arguments.fields#" index="field">
				<cfhttpparam type="formfield" name="#field[1]#" value="#field[2]#">
			</cfloop>
		</cfhttp>
		<cfset result.status = val(httpResult.statusCode)>
		<cfif len(httpResult.fileContent) and isJSON(httpResult.fileContent)>
			<cfset result.data = deserializeJSON(httpResult.fileContent)>
		</cfif>
		<cfset result.success = result.status gte 200 and result.status lt 300>
		<cfif not result.success>
			<!--- Stripe's own error message (never contains the key). --->
			<cfset result.message = (isStruct(result.data) and structKeyExists(result.data, "error") and structKeyExists(result.data.error, "message")) ? result.data.error.message : httpResult.statusCode>
		</cfif>
		<cfcatch type="any">
			<cfset result.message = cfcatch.message>
		</cfcatch>
	</cftry>
	<cfreturn result>
</cffunction>

<!--- ********************************************************************************************************************
	Private
********************************************************************************************************************* --->

<cffunction name="cachedSettings" access="private" returntype="struct" output="false"
		hint="getSettings(), kept until the next save - prices are formatted on every booking page.">
	<cfif not structKeyExists(variables.settingsCache, "currency")>
		<cfset variables.settingsCache = getSettings()>
	</cfif>
	<cfreturn variables.settingsCache>
</cffunction>

<cffunction name="loadEntity" access="private" returntype="any" output="false" hint="This blog's PaymentSetting row, or null.">
	<cfset var found = ormExecuteQuery("FROM PaymentSetting WHERE BlogRef = :blogId ORDER BY PaymentSettingId", { blogId = javacast("int", application.BlogDbObj.getBlogId()) })>
	<cfif arrayLen(found)>
		<cfreturn found[1]>
	</cfif>
</cffunction>

<cffunction name="normalize" access="private" returntype="struct" output="false" hint="The posted settings, trimmed and with defaults.">
	<cfargument name="data" type="struct" required="true">
	<cfset var d = {}>
	<cfset var field = "">
	<cfloop list="currency,taxMode,taxName,taxRate,stripeTestPublishableKey,stripeTestSecretKey,stripeTestWebhookSecret,stripeLivePublishableKey,stripeLiveSecretKey,stripeLiveWebhookSecret" index="field">
		<cfset d[field] = structKeyExists(arguments.data, field) ? trim(arguments.data[field]) : "">
	</cfloop>
	<cfset d.currency = uCase(d.currency)>
	<cfset d.taxMode = d.taxMode eq "add" ? "add" : "included">
	<cfset d.taxRate = isNumeric(d.taxRate) ? val(d.taxRate) : d.taxRate>
	<!--- Checkboxes: present (any value but false/0) means checked. Test mode is on unless it's explicitly turned off. --->
	<cfset d.testMode = not (structKeyExists(arguments.data, "testMode") and isBoolean(arguments.data.testMode) and not arguments.data.testMode)>
	<cfset d.clearTestKeys = structKeyExists(arguments.data, "clearTestKeys") and isBoolean(arguments.data.clearTestKeys) and arguments.data.clearTestKeys>
	<cfset d.clearLiveKeys = structKeyExists(arguments.data, "clearLiveKeys") and isBoolean(arguments.data.clearLiveKeys) and arguments.data.clearLiveKeys>
	<cfreturn d>
</cffunction>

<cffunction name="checkKey" access="private" returntype="string" output="false"
		hint="An error message when a key that was entered doesn't look like the key the field asks for (pasted into the wrong box, or the test key in the live box); otherwise an empty string. Returned rather than appended to an array argument: ColdFusion passes arrays by value.">
	<cfargument name="value" type="string" required="true">
	<cfargument name="prefixes" type="string" required="true">
	<cfargument name="fieldName" type="string" required="true">
	<cfset var prefix = "">
	<cfset var matches = false>
	<cfif not len(arguments.value)>
		<cfreturn "">
	</cfif>
	<cfloop list="#arguments.prefixes#" index="prefix">
		<cfif left(arguments.value, len(prefix)) eq prefix><cfset matches = true></cfif>
	</cfloop>
	<cfif not matches or reFind("[^A-Za-z0-9_]", arguments.value) or len(arguments.value) gt 500>
		<cfreturn arguments.fieldName & " should start with " & replace(arguments.prefixes, ",", " or ", "all") & ". Copy it again from your Stripe dashboard.">
	</cfif>
	<cfreturn "">
</cffunction>

<cffunction name="keyInfo" access="private" returntype="struct" output="false"
		hint="What the admin page may know about one mode's keys: the publishable key, and for each secret only whether it is saved and its last 4 characters.">
	<cfargument name="publishableKey" type="string" required="true">
	<cfargument name="storedSecretKey" type="string" required="true">
	<cfargument name="storedWebhookSecret" type="string" required="true">
	<cfset var secretKey = decryptSecret(arguments.storedSecretKey)>
	<cfset var webhookSecret = decryptSecret(arguments.storedWebhookSecret)>
	<cfreturn {
		publishableKey: arguments.publishableKey,
		hasSecretKey: len(arguments.storedSecretKey) gt 0,
		secretKeyHint: len(secretKey) ? "ending in " & right(secretKey, 4) : "",
		hasWebhookSecret: len(arguments.storedWebhookSecret) gt 0,
		webhookSecretHint: len(webhookSecret) ? "ending in " & right(webhookSecret, 4) : "",
		unreadable: (len(arguments.storedSecretKey) gt 0 and not len(secretKey)) or (len(arguments.storedWebhookSecret) gt 0 and not len(webhookSecret))
	}>
</cffunction>

<cffunction name="getEncryptionKey" access="private" returntype="string" output="false"
		hint="The key the secrets are encrypted with, from blog.ini.cfm; made on first use.">
	<!--- application.blogIniPath, not application.iniFile: on some installs iniFile is the full path expanded a second time
	(2026-10-14, CF2025), which reads as empty and writes nowhere. Kept in memory once read, so one request never makes two keys. --->
	<cfset var key = "">
	<cfif structKeyExists(variables, "encryptionKey") and len(variables.encryptionKey)>
		<cfreturn variables.encryptionKey>
	</cfif>
	<cfset key = getProfileString(application.blogIniPath, "payments", "encryptionKey")>
	<cfif not len(key)>
		<cfset key = generateSecretKey("AES")>
		<cfset setProfileString(application.blogIniPath, "payments", "encryptionKey", key)>
		<!--- Read back: never encrypt with a key that didn't reach the file. --->
		<cfif getProfileString(application.blogIniPath, "payments", "encryptionKey") neq key>
			<cfthrow message="The payment settings couldn't be saved: blog.ini.cfm can't be written.">
		</cfif>
	</cfif>
	<cfset variables.encryptionKey = key>
	<cfreturn key>
</cffunction>

<cffunction name="encryptSecret" access="private" returntype="string" output="false">
	<cfargument name="value" type="string" required="true">
	<cfreturn "enc1:" & encrypt(arguments.value, getEncryptionKey(), "AES/CBC/PKCS5Padding", "Base64")>
</cffunction>

<cffunction name="decryptSecret" access="private" returntype="string" output="false"
		hint="A stored secret in plain text, or an empty string when there is none or it can't be read (blog.ini.cfm was replaced).">
	<cfargument name="storedValue" type="string" required="true">
	<cfif left(arguments.storedValue, 5) neq "enc1:">
		<cfreturn "">
	</cfif>
	<cftry>
		<cfreturn decrypt(mid(arguments.storedValue, 6, len(arguments.storedValue)), getEncryptionKey(), "AES/CBC/PKCS5Padding", "Base64")>
		<cfcatch type="any">
			<cfreturn "">
		</cfcatch>
	</cftry>
</cffunction>

<cffunction name="getBlogJavaLocale" access="private" returntype="any" output="false" hint="The blog's locale (Blog Settings) as a java.util.Locale.">
	<cfset var tag = replace(trim(application.BlogDbObj.getBlogLocale()), "_", "-", "all")>
	<cfif not len(tag)><cfset tag = "en-US"></cfif>
	<cfreturn createObject("java", "java.util.Locale").forLanguageTag(tag)>
</cffunction>

<cffunction name="formatPercent" access="private" returntype="string" output="false" hint="8.250 as 8.25, 10.000 as 10.">
	<cfargument name="value" required="true">
	<cfset var text = numberFormat(arguments.value, "0.000")>
	<cfset text = reReplace(text, "0+$", "")>
	<cfreturn reReplace(text, "\.$", "")>
</cffunction>

<cffunction name="valueOrEmpty" access="private" returntype="string" output="false"
		hint="A property value, or an empty string when it is NULL (rows from before a column existed).">
	<cfargument name="value" required="false">
	<cfif isNull(arguments.value)>
		<cfreturn "">
	</cfif>
	<cfreturn arguments.value>
</cffunction>

<cffunction name="isTrue" access="private" returntype="boolean" output="false"
		hint="A boolean property, with a default for NULL.">
	<cfargument name="value" required="false">
	<cfargument name="defaultValue" type="boolean" required="false" default="false">
	<cfif isNull(arguments.value) or not isBoolean(arguments.value)>
		<cfreturn arguments.defaultValue>
	</cfif>
	<cfreturn arguments.value>
</cffunction>

</cfcomponent>
