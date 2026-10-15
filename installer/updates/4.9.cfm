<!--- description: Makes sure the tables for the 4.9 features exist: Forms (WebForm, WebFormField, WebFormSubmission, WebFormPost), Bookings (LocationOption, BookingType, LocationOptionLookup, AvailabilityRule, AvailabilityException, Booking), Payments (PaymentSetting, Payment, PaymentWebhookLog), Member accounts (MemberSetting, BlogMember, MemberLoginToken, MemberRememberToken) and Events (BlogEvent), and adds the Upcoming Events pod so Themes can switch it off. ORM normally creates the tables, and new columns, when the blog restarts after the upload; if a table is missing, this sets the column types for the database and reloads ORM to create it. Everything starts empty and switched off until you set it up. Safe to run more than once. --->
<!--- The work is done by DatabaseUpdater.cfc's ensureOrmTables(). Add anything else this version needs below it. --->
<cfset ensureOrmTables("WebForm,WebFormField,WebFormSubmission,WebFormPost,LocationOption,BookingType,LocationOptionLookup,AvailabilityRule,AvailabilityException,Booking,PaymentSetting,Payment,PaymentWebhookLog,MemberSetting,BlogMember,MemberLoginToken,MemberRememberToken,BlogEvent")>
<!--- Events (2026-10-15): the Upcoming Events pod's content template, so Themes can switch it off. --->
<cfif structKeyExists(application, "events")><cfset application.events.ensurePodTemplate()></cfif>
<!--- Files that are no longer used (2026-10-15): an old Page Collections window and an old editor upload handler. --->
<cfset removeFiles([
	"admin/adminInterface/configurePageCollections.cfm",
	"common/services/imageUpload.cfc"
])>
