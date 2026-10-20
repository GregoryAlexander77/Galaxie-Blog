<cfsetting enablecfoutputonly="true" showdebugoutput="false">
<!---
	Stripe webhook (2026-10-15). Stripe sends a signed message here when a checkout is paid or expires. The address goes in the
	Stripe dashboard (Developers > Webhooks) with the events checkout.session.completed, checkout.session.expired and
	charge.refunded; Blog Options > Payments shows it. For local testing: stripe listen --forward-to <this address>.

	This is the only place a booking or a paid event sign-up (2026-10-15) is marked as paid (a shop order, 2026-10-20, is also
	confirmed when the buyer comes back and the blog asks Stripe itself: Shop.cfc confirmFromStripe). The message is checked with the signing secret (Payments.cfc
	verifyStripeSignature), recorded by its event id so a repeated delivery is acted on once (PaymentWebhookLog), and answered
	quickly: anything but a 2xx makes Stripe send it again later.
--->
<cfif cgi.request_method neq "POST">
	<cfheader statuscode="405">
	<cfabort>
</cfif>

<cfset webhookRequest = getHTTPRequestData()>
<cfset webhookPayload = isBinary(webhookRequest.content) ? charsetEncode(webhookRequest.content, "utf-8") : toString(webhookRequest.content)>
<cfset webhookSignature = structKeyExists(webhookRequest.headers, "Stripe-Signature") ? webhookRequest.headers["Stripe-Signature"] : "">
<cfset webhookCheck = application.payments.verifyStripeSignature(webhookPayload, webhookSignature)>

<cfif not webhookCheck.valid>
	<!--- Not from Stripe (or the wrong signing secret is saved). Recorded without trusting anything in it. --->
	<cfset application.payments.logWebhookEvent("", "unverified", false, "Rejected: " & webhookCheck.reason)>
	<cfheader statuscode="400">
	<cfoutput>invalid signature</cfoutput>
	<cfabort>
</cfif>

<cftry>
	<cfset webhookEvent = deserializeJSON(webhookPayload)>
	<cfset webhookEventId = structKeyExists(webhookEvent, "id") ? webhookEvent.id : "">
	<cfset webhookType = structKeyExists(webhookEvent, "type") ? webhookEvent.type : "">
	<cfset webhookTestMode = not (structKeyExists(webhookEvent, "livemode") and isBoolean(webhookEvent.livemode) and webhookEvent.livemode)>

	<cfif len(webhookEventId) and application.payments.webhookEventSeen(webhookEventId)>
		<cfoutput>already handled</cfoutput>
		<cfabort>
	</cfif>

	<cfset webhookObject = webhookEvent.data.object>
	<cfset webhookResult = "ignored">

	<cfswitch expression="#webhookType#">

		<cfcase value="checkout.session.completed,checkout.session.async_payment_succeeded">
			<cfset webhookPayment = application.payments.getPaymentBySession(webhookObject.id)>
			<cfif structIsEmpty(webhookPayment)>
				<cfset webhookResult = "no payment recorded for this checkout">
			<cfelseif not (structKeyExists(webhookObject, "payment_status") and webhookObject.payment_status eq "paid")>
				<cfset webhookResult = "not paid yet (" & (structKeyExists(webhookObject, "payment_status") ? webhookObject.payment_status : "") & ")">
			<cfelseif webhookPayment.purpose eq "balance">
				<!--- The rest of a deposit booking (2026-10-15). --->
				<cfif webhookPayment.status eq "pending">
					<cfset application.payments.setPaymentStatus(
						sessionId = webhookObject.id,
						status = "paid",
						amountPaid = application.payments.fromMinorUnits(webhookObject.amount_total, webhookObject.currency),
						providerPaymentId = structKeyExists(webhookObject, "payment_intent") and isSimpleValue(webhookObject.payment_intent) ? webhookObject.payment_intent : ""
					)>
					<cfif application.bookings.applyBalancePayment(webhookPayment.bookingId, webhookPayment.amount)>
						<cfset application.bookings.sendBookingEmails(webhookPayment.bookingId, "balancePaid")>
					</cfif>
					<cfset webhookResult = "booking " & webhookPayment.bookingId & " balance paid">
				<cfelse>
					<cfset webhookResult = "balance payment already recorded">
				</cfif>
			<cfelse>
				<cfset application.payments.setPaymentStatus(
					sessionId = webhookObject.id,
					status = "paid",
					amountPaid = application.payments.fromMinorUnits(webhookObject.amount_total, webhookObject.currency),
					providerPaymentId = structKeyExists(webhookObject, "payment_intent") and isSimpleValue(webhookObject.payment_intent) ? webhookObject.payment_intent : ""
				)>
				<cfif webhookPayment.bookingId gt 0>
					<!--- The booking is credited with what it cost before tax; the Payment row keeps what Stripe actually took. --->
					<cfset webhookConfirmed = application.bookings.confirmPaidBooking(webhookPayment.bookingId, webhookPayment.amount)>
					<cfif webhookConfirmed.changed>
						<cfset application.bookings.sendBookingEmails(webhookPayment.bookingId, "booked")>
						<cfset webhookResult = "booking " & webhookPayment.bookingId & " paid, now " & webhookConfirmed.status>
					<cfelse>
						<cfset webhookResult = "booking " & webhookPayment.bookingId & " paid; it was already " & webhookConfirmed.status>
					</cfif>
				<cfelseif webhookPayment.submissionId gt 0>
					<!--- A paid event sign-up: confirm the held places, then the person's confirmation and the owner's notice. --->
					<cfif application.events.confirmPaidRsvp(webhookPayment.submissionId, application.payments.fromMinorUnits(webhookObject.amount_total, webhookObject.currency))>
						<cfset webhookRsvp = application.events.getRsvp(submissionId = webhookPayment.submissionId)>
						<cfif not structIsEmpty(webhookRsvp)>
							<cfset application.events.sendRsvpEmails(webhookRsvp, "confirmed")>
							<cfset application.events.sendRsvpEmails(webhookRsvp, "ownerNew")>
							<cfset application.blog.flushGalaxieCache(type = "post", postId = webhookRsvp.postId)>
						</cfif>
						<cfset webhookResult = "event sign-up " & webhookPayment.submissionId & " paid, now confirmed">
					<cfelse>
						<cfset webhookResult = "event sign-up " & webhookPayment.submissionId & " paid; it was already confirmed or cancelled">
					</cfif>
				<cfelseif webhookPayment.shopOrderId gt 0>
					<!--- A shop order (2026-10-20): paid, the shipping address and amounts kept, stock taken off, download links made, emails sent. --->
					<cfif application.shop.confirmPaidOrder(webhookPayment.shopOrderId, webhookObject)>
						<cfset webhookResult = "shop order " & webhookPayment.shopOrderId & " paid">
					<cfelse>
						<cfset webhookResult = "shop order " & webhookPayment.shopOrderId & " paid; it was already confirmed">
					</cfif>
				</cfif>
			</cfif>
		</cfcase>

		<cfcase value="charge.refunded">
			<!--- Any refund, including ones made in the Stripe dashboard. amount_refunded is the charge's total so far. --->
			<cfif structKeyExists(webhookObject, "payment_intent") and isSimpleValue(webhookObject.payment_intent) and len(webhookObject.payment_intent)>
				<cfset webhookBookingId = application.payments.applyRefundFromWebhook(webhookObject.payment_intent, application.payments.fromMinorUnits(webhookObject.amount_refunded, webhookObject.currency))>
				<cfset webhookRefs = application.payments.getRefsByPaymentIntent(webhookObject.payment_intent)>
				<cfif webhookBookingId gt 0>
					<cfset application.bookings.refreshPaymentStatus(webhookBookingId)>
					<cfset webhookResult = "booking " & webhookBookingId & " refund recorded">
				<cfelseif webhookRefs.submissionId gt 0>
					<cfset application.events.refreshRsvpPaymentStatus(webhookRefs.submissionId)>
					<cfset webhookResult = "event sign-up " & webhookRefs.submissionId & " refund recorded">
				<cfelseif webhookRefs.shopOrderId gt 0>
					<cfset application.shop.applyRefund(webhookRefs.shopOrderId)>
					<cfset webhookResult = "shop order " & webhookRefs.shopOrderId & " refund recorded">
				<cfelse>
					<cfset webhookResult = "refund for a payment this blog didn't take">
				</cfif>
			</cfif>
		</cfcase>

		<cfcase value="checkout.session.expired">
			<cfset webhookPayment = application.payments.getPaymentBySession(webhookObject.id)>
			<cfif not structIsEmpty(webhookPayment) and webhookPayment.status eq "pending">
				<cfset application.payments.setPaymentStatus(sessionId = webhookObject.id, status = "expired")>
				<cfif webhookPayment.bookingId gt 0 and application.bookings.expireHeldBooking(webhookPayment.bookingId)>
					<cfset webhookResult = "booking " & webhookPayment.bookingId & " released (checkout expired)">
				<cfelseif webhookPayment.submissionId gt 0 and application.events.expireHeldRsvp(webhookPayment.submissionId)>
					<cfset webhookResult = "event sign-up " & webhookPayment.submissionId & " released (checkout expired)">
				<cfelseif webhookPayment.shopOrderId gt 0>
					<cfset application.shop.expireOrder(webhookPayment.shopOrderId)>
					<cfset webhookResult = "shop order " & webhookPayment.shopOrderId & " closed (checkout expired)">
				<cfelse>
					<cfset webhookResult = "checkout expired">
				</cfif>
			</cfif>
		</cfcase>

	</cfswitch>

	<cfset application.payments.logWebhookEvent(webhookEventId, webhookType, true, webhookResult, webhookTestMode)>
	<cfoutput>ok</cfoutput>

	<cfcatch type="any">
		<!--- Stripe tries again later when it doesn't get a 2xx. --->
		<cflog file="galaxieBlogErrors" type="error" text="Stripe webhook: #cfcatch.message#">
		<cfheader statuscode="500">
		<cfoutput>error</cfoutput>
	</cfcatch>
</cftry>
