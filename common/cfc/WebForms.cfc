<cfcomponent displayName="WebForms" output="false" hint="Forms the blog owner builds in the admin site and places in posts and pages (2026-10-13): reading and saving forms and their fields, checking and storing what visitors send, and exporting it. The entities are WebForm, WebFormField and WebFormSubmission (common/cfc/db/galaxieDb). Created once as application.webForms in Application.cfc. See doc/aiDraftArticles/eventsAndFormsDesign.cfm, Part 1.">

<!---
	Every write is inside a cftransaction: the application sets ormsettings.flushAtRequestEnd = false, so an entity change made
	outside a transaction (without ormFlush) would never reach the database.
--->

<cffunction name="init" access="public" returntype="any" output="false">
	<!--- The field types, in the order the form editor offers them. --->
	<cfset variables.fieldTypes = [
		{ type: "text", label: "Text (one line)" },
		{ type: "email", label: "Email address" },
		{ type: "phone", label: "Phone number" },
		{ type: "number", label: "Number" },
		{ type: "textarea", label: "Text (several lines)" },
		{ type: "select", label: "Dropdown" },
		{ type: "radio", label: "Choose one (radio buttons)" },
		{ type: "checkboxes", label: "Choose any (checkboxes)" },
		{ type: "date", label: "Date" },
		{ type: "consent", label: "Consent checkbox (I agree...)" }
	]>
	<cfset variables.fieldTypeList = "">
	<cfloop array="#variables.fieldTypes#" index="local.fieldType">
		<cfset variables.fieldTypeList = listAppend(variables.fieldTypeList, local.fieldType.type)>
	</cfloop>
	<!--- Field types whose Options column holds the choices, one per line. --->
	<cfset variables.choiceTypes = "select,radio,checkboxes">
	<!--- Field types that are never shown in a public sign-up list. --->
	<cfset variables.privateTypes = "email,phone">
	<cfreturn this>
</cffunction>

<cffunction name="getFieldTypes" access="public" returntype="array" output="false">
	<cfreturn duplicate(variables.fieldTypes)>
</cffunction>

<cffunction name="getStarterTemplates" access="public" returntype="array" output="false"
		hint="Ready-made starting points for a new form (2026-10-13), offered as 'Start from' in the form editor (admin/adminInterface/webFormDetail.cfm). Nothing is saved until the owner saves the form, and every part can be changed. The RSVP template is a plain form; the RSVP that counts guests and has cancel links comes with Events (see the design doc).">
	<cfset var templates = []>
	<cfset arrayAppend(templates, {
		"key": "blank", "name": "Blank form",
		"title": "", "description": "", "buttonLabel": "Send",
		"confirmationMessage": "Thank you. Your form was sent.", "offerSubscribe": false,
		"fields": []
	})>
	<cfset arrayAppend(templates, {
		"key": "contact", "name": "Contact",
		"title": "Contact", "description": "", "buttonLabel": "Send",
		"confirmationMessage": "Thank you for getting in touch. I'll reply as soon as I can.", "offerSubscribe": false,
		"fields": [
			starterField("Name", "text", true),
			starterField("Email address", "email", true),
			starterField("Subject", "text", false),
			starterField("Message", "textarea", true)
		]
	})>
	<cfset arrayAppend(templates, {
		"key": "newsletter", "name": "Newsletter signup",
		"title": "Newsletter signup", "description": "Sign up to get the newsletter by email.", "buttonLabel": "Sign up",
		"confirmationMessage": "Thanks for signing up!", "offerSubscribe": false,
		"fields": [
			starterField("First name", "text", false),
			starterField("Email address", "email", true),
			starterField("Agreement", "consent", true, "", "", "I agree to receive emails, and know I can unsubscribe at any time.")
		]
	})>
	<cfset arrayAppend(templates, {
		"key": "rsvp", "name": "RSVP",
		"title": "RSVP", "description": "Please let us know if you can come.", "buttonLabel": "Send RSVP",
		"confirmationMessage": "Thanks for letting us know!", "offerSubscribe": false,
		"fields": [
			starterField("Name", "text", true),
			starterField("Email address", "email", true),
			starterField("Will you come?", "radio", true, "", "", "Yes, I'll be there#chr(10)#No, I can't make it"),
			starterField("Number of guests", "number", false, "", "Including yourself."),
			starterField("Notes", "textarea", false, "", "Dietary needs, questions or anything else we should know.")
		]
	})>
	<!--- Potluck: the dish choice has limits (choice limits, below) so the table doesn't end up with ten desserts. --->
	<cfset var potluckDishes = starterField("What are you bringing?", "radio", true, "", "Full choices can't be picked; please choose another.", "Main dish#chr(10)#Side dish#chr(10)#Salad#chr(10)#Dessert#chr(10)#Bread#chr(10)#Drinks#chr(10)#Plates/cups/utensils")>
	<cfset potluckDishes["choiceLimits"] = [ "Main dish": 6, "Side dish": 6, "Salad": 4, "Dessert": 4, "Bread": 3, "Drinks": 4, "Plates/cups/utensils": 2 ]>
	<cfset arrayAppend(templates, {
		"key": "potluck", "name": "Potluck sign-up",
		"title": "Potluck sign-up", "description": "Let us know you're coming and what you'll bring.", "buttonLabel": "Sign me up",
		"confirmationMessage": "Thanks! See you there.", "offerSubscribe": false,
		"fields": [
			starterField("Name", "text", true),
			starterField("Email address", "email", true),
			starterField("How many are coming?", "number", false, "", "Including yourself."),
			potluckDishes,
			starterField("What's the dish?", "text", false, "eg. Mom's lasagna"),
			starterField("About how many does it serve?", "number", false),
			starterField("Dietary notes", "checkboxes", false, "", "", "Vegetarian#chr(10)#Vegan#chr(10)#Gluten-free#chr(10)#Contains nuts#chr(10)#Contains dairy"),
			starterField("Anything else?", "textarea", false)
		]
	})>
	<!--- On the site: every template starts private (no public list, form only), except RSVP and Potluck, which show who's
	coming / who's bringing what. Email and phone are never public. --->
	<cfloop array="#templates#" index="local.starter">
		<cfset local.starter["publicList"] = false>
		<cfset local.starter["showOnMode"] = "form">
		<cfif local.starter.key eq "rsvp">
			<cfset markStarterPublic(local.starter, "Name,Will you come?,Number of guests")>
		<cfelseif local.starter.key eq "potluck">
			<cfset markStarterPublic(local.starter, "Name,How many are coming?,What are you bringing?,What's the dish?")>
		</cfif>
	</cfloop>
	<cfreturn templates>
</cffunction>

<cffunction name="markStarterPublic" access="private" returntype="void" output="false"
		hint="Turns on a starter template's public sign-up list (form and list on the posts it's shown on) with the fields given by label.">
	<cfargument name="starter" type="struct" required="true">
	<cfargument name="labels" type="string" required="true">
	<cfset var field = "">
	<cfset arguments.starter["publicList"] = true>
	<cfset arguments.starter["showOnMode"] = "formAndList">
	<cfloop array="#arguments.starter.fields#" index="field">
		<cfif listFind(arguments.labels, field.label)>
			<cfset field["showPublic"] = true>
		</cfif>
	</cfloop>
</cffunction>

<cffunction name="starterField" access="private" returntype="struct" output="false"
		hint="One field of a starter template, in the shape the form editor uses.">
	<cfargument name="label" type="string" required="true">
	<cfargument name="fieldType" type="string" required="true">
	<cfargument name="required" type="boolean" required="true">
	<cfargument name="placeholder" type="string" required="false" default="">
	<cfargument name="helpText" type="string" required="false" default="">
	<cfargument name="options" type="string" required="false" default="">
	<cfreturn { "webFormFieldId": 0, "label": arguments.label, "fieldType": arguments.fieldType, "required": arguments.required,
		"placeholder": arguments.placeholder, "helpText": arguments.helpText, "options": arguments.options, "choiceLimits": {}, "showPublic": false }>
</cffunction>

<!--- ********************************************************************************************************************
	Reading
********************************************************************************************************************* --->

<cffunction name="getForms" access="public" returntype="array" output="false"
		hint="Every form of this blog, newest first, with its number of fields and submissions.">
	<cfset var data = queryExecute("
		SELECT f.WebFormId, f.Title, f.Alias, CASE WHEN f.Active = 1 THEN 1 ELSE 0 END AS Active,
			CASE WHEN f.PublicList = 1 THEN 1 ELSE 0 END AS PublicList, f.Created,
			(SELECT COUNT(*) FROM WebFormField ff WHERE ff.WebFormRef = f.WebFormId) AS FieldCount,
			(SELECT COUNT(*) FROM WebFormSubmission fs WHERE fs.WebFormRef = f.WebFormId) AS SubmissionCount,
			(SELECT MAX(fs.Created) FROM WebFormSubmission fs WHERE fs.WebFormRef = f.WebFormId) AS LastSubmission
		FROM WebForm f
		WHERE f.BlogRef = :blogId
		ORDER BY f.Created DESC, f.WebFormId DESC
	", { blogId = { value = application.BlogDbObj.getBlogId(), cfsqltype = "cf_sql_integer" } })>
	<cfset var forms = []>
	<cfloop query="data">
		<cfset arrayAppend(forms, {
			webFormId: data.WebFormId,
			title: data.Title,
			alias: data.Alias,
			active: data.Active eq 1,
			publicList: data.PublicList eq 1,
			created: data.Created,
			fieldCount: data.FieldCount,
			submissionCount: data.SubmissionCount,
			lastSubmission: data.LastSubmission
		})>
	</cfloop>
	<cfreturn forms>
</cffunction>

<cffunction name="getForm" access="public" returntype="struct" output="false"
		hint="One form and its fields in order, by id or by alias. Returns an empty struct when there is no such form on this blog.">
	<cfargument name="webFormId" required="false" default="">
	<cfargument name="alias" type="string" required="false" default="">
	<cfset var formEntity = "">
	<cfset var found = []>
	<cfset var fieldEntities = []>
	<cfset var fieldEntity = "">
	<cfset var result = {}>
	<cfif isNumeric(arguments.webFormId) and arguments.webFormId gt 0>
		<cfset found = ormExecuteQuery("FROM WebForm WHERE WebFormId = :id AND BlogRef = :blogId", { id = javacast("int", arguments.webFormId), blogId = javacast("int", application.BlogDbObj.getBlogId()) })>
	<cfelseif len(trim(arguments.alias))>
		<cfset found = ormExecuteQuery("FROM WebForm WHERE Alias = :alias AND BlogRef = :blogId", { alias = trim(arguments.alias), blogId = javacast("int", application.BlogDbObj.getBlogId()) })>
	</cfif>
	<cfif not arrayLen(found)>
		<cfreturn result>
	</cfif>
	<cfset formEntity = found[1]>
	<cfset result = {
		webFormId: formEntity.getWebFormId(),
		title: valueOrEmpty(formEntity.getTitle()),
		alias: valueOrEmpty(formEntity.getAlias()),
		description: valueOrEmpty(formEntity.getDescription()),
		buttonLabel: valueOrEmpty(formEntity.getButtonLabel()),
		confirmationMessage: valueOrEmpty(formEntity.getConfirmationMessage()),
		confirmationUrl: valueOrEmpty(formEntity.getConfirmationUrl()),
		notifyEmails: valueOrEmpty(formEntity.getNotifyEmails()),
		offerSubscribe: isTrue(formEntity.getOfferSubscribe()),
		requireCaptcha: isTrue(formEntity.getRequireCaptcha(), true),
		active: isTrue(formEntity.getActive(), true),
		publicList: isTrue(formEntity.getPublicList()),
		showOnMode: valueOrEmpty(formEntity.getShowOnMode()),
		showOnPosts: [],
		fields: []
	}>
	<!--- A list needs the privacy switch; anything else unknown (or NULL on an older row) means just the form. --->
	<cfif not listFind("form,formAndList,list", result.showOnMode) or not result.publicList>
		<cfset result.showOnMode = "form">
	</cfif>
	<cfset result.showOnPosts = getShowOnPosts(result.webFormId)>
	<cfset fieldEntities = ormExecuteQuery("FROM WebFormField WHERE WebFormRef = :id ORDER BY SortOrder, WebFormFieldId", { id = javacast("int", result.webFormId) })>
	<cfloop array="#fieldEntities#" index="fieldEntity">
		<cfset arrayAppend(result.fields, {
			webFormFieldId: fieldEntity.getWebFormFieldId(),
			label: valueOrEmpty(fieldEntity.getLabel()),
			fieldName: valueOrEmpty(fieldEntity.getFieldName()),
			fieldType: valueOrEmpty(fieldEntity.getFieldType()),
			required: isTrue(fieldEntity.getRequired()),
			placeholder: valueOrEmpty(fieldEntity.getPlaceholder()),
			helpText: valueOrEmpty(fieldEntity.getHelpText()),
			options: valueOrEmpty(fieldEntity.getOptions()),
			choices: listToArray(replace(valueOrEmpty(fieldEntity.getOptions()), chr(13), "", "all"), chr(10), false)
		})>
		<cfset result.fields[arrayLen(result.fields)].showPublic = isTrue(fieldEntity.getShowPublic()) and not listFindNoCase(variables.privateTypes, result.fields[arrayLen(result.fields)].fieldType)>
		<cfset result.fields[arrayLen(result.fields)].choiceLimits = parseChoiceLimits(valueOrEmpty(fieldEntity.getChoiceLimits()), result.fields[arrayLen(result.fields)].fieldType, result.fields[arrayLen(result.fields)].choices)>
	</cfloop>
	<cfreturn result>
</cffunction>

<!--- ********************************************************************************************************************
	Saving a form (admin)
********************************************************************************************************************* --->

<cffunction name="saveForm" access="public" returntype="struct" output="false"
		hint="Creates or updates a form and replaces its fields with the ones given, in that order. Returns { success, webFormId, errors[] }.">
	<cfargument name="formData" type="struct" required="true" hint="webFormId (0 or empty = new), title, description, buttonLabel, confirmationMessage, confirmationUrl, notifyEmails, offerSubscribe, requireCaptcha, active, fields: [ { webFormFieldId, label, fieldType, required, placeholder, helpText, options } ]">
	<cfset var result = { success: false, webFormId: 0, errors: [], changedPostIds: [] }>
	<cfset var data = arguments.formData>
	<cfset var publicList = isTrue(structKeyExists(data, "publicList") ? data.publicList : false)>
	<!--- Show on: only this blog's posts that exist and aren't deleted are kept. --->
	<cfset var showOnPostIds = existingPostIds(structKeyExists(data, "showOnPostIds") and isArray(data.showOnPostIds) ? data.showOnPostIds : [])>
	<cfset var oldPlacement = "">
	<cfset var placement = "">
	<cfset var placementPostId = 0>
	<cfset var title = trim(structKeyExists(data, "title") ? data.title : "")>
	<cfset var fields = structKeyExists(data, "fields") and isArray(data.fields) ? data.fields : []>
	<cfset var formEntity = "">
	<cfset var existing = []>
	<cfset var keptFieldIds = {}>
	<cfset var usedNames = {}>
	<cfset var field = "">
	<cfset var fieldEntity = "">
	<cfset var fieldName = "">
	<cfset var position = 0>
	<cfset var oldField = "">
	<cfset var isNew = not (structKeyExists(data, "webFormId") and isNumeric(data.webFormId) and data.webFormId gt 0)>

	<!--- Check everything first, so nothing is saved when something is wrong. --->
	<cfif not len(title)>
		<cfset arrayAppend(result.errors, "The form needs a title.")>
	</cfif>
	<cfif not arrayLen(fields)>
		<cfset arrayAppend(result.errors, "The form needs at least one field.")>
	</cfif>
	<cfloop array="#fields#" index="field">
		<cfset position = position + 1>
		<cfif not structKeyExists(field, "label") or not len(trim(field.label))>
			<cfset arrayAppend(result.errors, "Field #position# needs a label.")>
		</cfif>
		<cfif not structKeyExists(field, "fieldType") or not listFindNoCase(variables.fieldTypeList, field.fieldType)>
			<cfset arrayAppend(result.errors, "Field #position# has an unknown type.")>
		<cfelseif listFindNoCase(variables.choiceTypes, field.fieldType) and not arrayLen(listToArray(replace(structKeyExists(field, "options") ? field.options : "", chr(13), "", "all"), chr(10), false))>
			<cfset arrayAppend(result.errors, "Field #position# (#encodeForHtml(field.label)#) needs at least one choice, one per line.")>
		</cfif>
	</cfloop>
	<cfif structKeyExists(data, "notifyEmails") and len(trim(data.notifyEmails))>
		<cfloop list="#data.notifyEmails#" index="fieldName">
			<cfif not isValid("email", trim(fieldName))>
				<cfset arrayAppend(result.errors, "#encodeForHtml(trim(fieldName))# is not a valid email address.")>
			</cfif>
		</cfloop>
	</cfif>
	<cfif structKeyExists(data, "confirmationUrl") and len(trim(data.confirmationUrl)) and not reFindNoCase("^(https?://|/)", trim(data.confirmationUrl))>
		<cfset arrayAppend(result.errors, "The page to go to after sending must start with http://, https:// or /.")>
	</cfif>
	<cfif arrayLen(result.errors)>
		<cfreturn result>
	</cfif>

	<!--- An existing form is looked up before the transaction starts, so a missing one returns without opening it. --->
	<cfif not isNew>
		<cfset existing = ormExecuteQuery("FROM WebForm WHERE WebFormId = :id AND BlogRef = :blogId", { id = javacast("int", data.webFormId), blogId = javacast("int", application.BlogDbObj.getBlogId()) })>
		<cfif not arrayLen(existing)>
			<cfset arrayAppend(result.errors, "That form no longer exists.")>
			<cfreturn result>
		</cfif>
	</cfif>

	<cftransaction>
		<cfif isNew>
			<cfset formEntity = entityNew("WebForm")>
			<cfset formEntity.setBlogRef(application.BlogDbObj.getBlogId())>
			<!--- The alias is made once, from the title, and stays the same when the title changes, so posts that use it keep working. --->
			<cfset formEntity.setAlias(makeUniqueAlias(title))>
			<cfset formEntity.setCreated(now())>
		<cfelse>
			<cfset formEntity = existing[1]>
		</cfif>
		<cfset formEntity.setTitle(left(title, 125))>
		<cfset formEntity.setDescription(left(trim(structKeyExists(data, "description") ? data.description : ""), 1000))>
		<cfset formEntity.setButtonLabel(left(len(trim(structKeyExists(data, "buttonLabel") ? data.buttonLabel : "")) ? trim(data.buttonLabel) : "Send", 50))>
		<cfset formEntity.setConfirmationMessage(left(len(trim(structKeyExists(data, "confirmationMessage") ? data.confirmationMessage : "")) ? trim(data.confirmationMessage) : "Thank you. Your form was sent.", 2000))>
		<cfset formEntity.setConfirmationUrl(left(trim(structKeyExists(data, "confirmationUrl") ? data.confirmationUrl : ""), 500))>
		<cfset formEntity.setNotifyEmails(left(reReplace(trim(structKeyExists(data, "notifyEmails") ? data.notifyEmails : ""), "\s*,\s*", ",", "all"), 1000))>
		<cfset formEntity.setOfferSubscribe(isTrue(structKeyExists(data, "offerSubscribe") ? data.offerSubscribe : false))>
		<cfset formEntity.setRequireCaptcha(isTrue(structKeyExists(data, "requireCaptcha") ? data.requireCaptcha : true, true))>
		<cfset formEntity.setActive(isTrue(structKeyExists(data, "active") ? data.active : true, true))>
		<!--- On the site: a list can only be shown with the privacy switch on. --->
		<cfset formEntity.setPublicList(publicList)>
		<cfset formEntity.setShowOnMode(publicList and structKeyExists(data, "showOnMode") and listFind("formAndList,list", data.showOnMode) ? data.showOnMode : "form")>
		<cfset formEntity.setDate(now())>
		<cfset entitySave(formEntity)>

		<!--- Fields: update the ones that came back with their id (keeping their FieldName, so old submissions still line up),
		add new ones, and remove the ones that were taken out. --->
		<cfset position = 0>
		<cfloop array="#ormExecuteQuery('FROM WebFormField WHERE WebFormRef = :id', { id = javacast('int', formEntity.getWebFormId()) })#" index="oldField">
			<cfset usedNames[lCase(valueOrEmpty(oldField.getFieldName()))] = oldField.getWebFormFieldId()>
		</cfloop>
		<cfloop array="#fields#" index="field">
			<cfset position = position + 1>
			<cfset fieldEntity = "">
			<cfif structKeyExists(field, "webFormFieldId") and isNumeric(field.webFormFieldId) and field.webFormFieldId gt 0>
				<cfset existing = ormExecuteQuery("FROM WebFormField WHERE WebFormFieldId = :id AND WebFormRef = :formId", { id = javacast("int", field.webFormFieldId), formId = javacast("int", formEntity.getWebFormId()) })>
				<cfif arrayLen(existing)>
					<cfset fieldEntity = existing[1]>
				</cfif>
			</cfif>
			<cfif not isObject(fieldEntity)>
				<cfset fieldEntity = entityNew("WebFormField")>
				<cfset fieldEntity.setWebFormRef(formEntity.getWebFormId())>
				<cfset fieldName = makeFieldName(field.label, usedNames)>
				<cfset usedNames[fieldName] = 0>
				<cfset fieldEntity.setFieldName(fieldName)>
			</cfif>
			<cfset fieldEntity.setLabel(left(trim(field.label), 255))>
			<cfset fieldEntity.setFieldType(lCase(field.fieldType))>
			<cfset fieldEntity.setRequired(isTrue(structKeyExists(field, "required") ? field.required : false))>
			<cfset fieldEntity.setPlaceholder(left(trim(structKeyExists(field, "placeholder") ? field.placeholder : ""), 255))>
			<cfset fieldEntity.setHelpText(left(trim(structKeyExists(field, "helpText") ? field.helpText : ""), 500))>
			<cfset fieldEntity.setOptions(left(trim(replace(structKeyExists(field, "options") ? field.options : "", chr(13), "", "all")), 2000))>
			<!--- Choice limits: kept only for the field's current choices, as whole numbers of at least 1. --->
			<cfset fieldEntity.setChoiceLimits(serializeChoiceLimits(structKeyExists(field, "choiceLimits") ? field.choiceLimits : {}, lCase(field.fieldType), listToArray(replace(fieldEntity.getOptions(), chr(13), "", "all"), chr(10), false)))>
			<cfset fieldEntity.setShowPublic(isTrue(structKeyExists(field, "showPublic") ? field.showPublic : false) and not listFindNoCase(variables.privateTypes, field.fieldType))>
			<cfset fieldEntity.setSortOrder(position * 10)>
			<cfset fieldEntity.setDate(now())>
			<cfset entitySave(fieldEntity)>
			<cfset keptFieldIds[fieldEntity.getWebFormFieldId()] = true>
		</cfloop>
		<cfloop array="#ormExecuteQuery('FROM WebFormField WHERE WebFormRef = :id', { id = javacast('int', formEntity.getWebFormId()) })#" index="oldField">
			<cfif not structKeyExists(keptFieldIds, oldField.getWebFormFieldId())>
				<cfset entityDelete(oldField)>
			</cfif>
		</cfloop>

		<!--- Show on: replace the posts this form is assigned to. The posts it leaves and joins both change, so both are returned
		for the caller to clear from the page cache. --->
		<cfloop array="#ormExecuteQuery('FROM WebFormPost WHERE WebFormRef = :id', { id = javacast('int', formEntity.getWebFormId()) })#" index="oldPlacement">
			<cfset arrayAppend(result.changedPostIds, oldPlacement.getPostRef())>
			<cfset entityDelete(oldPlacement)>
		</cfloop>
		<cfloop array="#showOnPostIds#" index="placementPostId">
			<cfset placement = entityNew("WebFormPost")>
			<cfset placement.setWebFormRef(formEntity.getWebFormId())>
			<cfset placement.setPostRef(placementPostId)>
			<cfset placement.setDate(now())>
			<cfset entitySave(placement)>
			<cfset arrayAppend(result.changedPostIds, placementPostId)>
		</cfloop>
	</cftransaction>

	<cfset result.success = true>
	<cfset result.webFormId = formEntity.getWebFormId()>
	<cfreturn result>
</cffunction>

<cffunction name="deleteForm" access="public" returntype="boolean" output="false"
		hint="Deletes a form, its fields and every submission it received.">
	<cfargument name="webFormId" type="numeric" required="true">
	<cfset var found = ormExecuteQuery("FROM WebForm WHERE WebFormId = :id AND BlogRef = :blogId", { id = javacast("int", arguments.webFormId), blogId = javacast("int", application.BlogDbObj.getBlogId()) })>
	<cfif not arrayLen(found)>
		<cfreturn false>
	</cfif>
	<cftransaction>
		<cfquery name="local.deleteSubmissions" dbtype="hql">
			DELETE FROM WebFormSubmission WHERE WebFormRef = <cfqueryparam value="#arguments.webFormId#" cfsqltype="cf_sql_integer">
		</cfquery>
		<cfquery name="local.deleteFields" dbtype="hql">
			DELETE FROM WebFormField WHERE WebFormRef = <cfqueryparam value="#arguments.webFormId#" cfsqltype="cf_sql_integer">
		</cfquery>
		<cfquery name="local.deletePlacements" dbtype="hql">
			DELETE FROM WebFormPost WHERE WebFormRef = <cfqueryparam value="#arguments.webFormId#" cfsqltype="cf_sql_integer">
		</cfquery>
		<cfset entityDelete(found[1])>
	</cftransaction>
	<cfreturn true>
</cffunction>

<!--- ********************************************************************************************************************
	Submissions
********************************************************************************************************************* --->

<cffunction name="validateSubmission" access="public" returntype="struct" output="false"
		hint="Checks what a visitor sent against the form's fields. Returns { valid, errors: { fieldName: message }, values: { fieldName: cleaned value } }. Only the form's own fields are kept; anything else that was sent is ignored.">
	<cfargument name="webForm" type="struct" required="true" hint="As returned by getForm().">
	<cfargument name="sent" type="struct" required="true" hint="The posted values, keyed by FieldName.">
	<cfargument name="choiceCounts" type="struct" required="false" default="#{}#" hint="From getChoiceCounts(); when given, a choice that has reached its limit is refused.">
	<cfset var result = { valid: true, errors: {}, values: [:] }>
	<cfset var field = "">
	<cfset var value = "">
	<cfset var picked = []>
	<cfset var choice = "">
	<cfset var fullChoices = []>
	<cfloop array="#arguments.webForm.fields#" index="field">
		<cfset value = structKeyExists(arguments.sent, field.fieldName) ? arguments.sent[field.fieldName] : "">
		<cfif not isSimpleValue(value)>
			<cfset value = "">
		</cfif>
		<cfset value = trim(value)>
		<cfswitch expression="#field.fieldType#">
			<cfcase value="email">
				<cfif len(value) and not isValid("email", value)>
					<cfset result.errors[field.fieldName] = "Please enter a valid email address.">
				</cfif>
			</cfcase>
			<cfcase value="number">
				<cfif len(value) and not isNumeric(value)>
					<cfset result.errors[field.fieldName] = "Please enter a number.">
				</cfif>
			</cfcase>
			<cfcase value="date">
				<cfif len(value) and not isDate(value)>
					<cfset result.errors[field.fieldName] = "Please enter a date.">
				</cfif>
			</cfcase>
			<cfcase value="phone">
				<cfif len(value) and not reFind("^[0-9+().\-\s]{5,30}$", value)>
					<cfset result.errors[field.fieldName] = "Please enter a phone number.">
				</cfif>
			</cfcase>
			<cfcase value="select,radio">
				<!--- Only one of the offered choices. --->
				<cfif len(value) and not arrayFind(field.choices, value)>
					<cfset result.errors[field.fieldName] = "Please choose one of the options.">
				</cfif>
			</cfcase>
			<cfcase value="checkboxes">
				<!--- Several choices, sent as a comma separated list; keep only the offered ones. --->
				<cfset picked = []>
				<cfloop list="#value#" index="choice">
					<cfif arrayFind(field.choices, trim(choice))>
						<cfset arrayAppend(picked, trim(choice))>
					</cfif>
				</cfloop>
				<cfset value = arrayToList(picked, ", ")>
			</cfcase>
			<cfcase value="consent">
				<!--- Stored as "yes" only when the box was checked. --->
				<cfset value = (len(value) and value neq "false" and value neq "0") ? "yes" : "">
			</cfcase>
		</cfswitch>
		<cfif field.required and not len(value) and not structKeyExists(result.errors, field.fieldName)>
			<cfset result.errors[field.fieldName] = field.fieldType eq "consent" ? "Please check this box to continue." : "This field is required.">
		</cfif>
		<!--- Choice limits: refuse a picked choice that is already full. --->
		<cfif len(value) and not structKeyExists(result.errors, field.fieldName) and structKeyExists(field, "choiceLimits") and not structIsEmpty(field.choiceLimits)>
			<cfset fullChoices = []>
			<cfif field.fieldType neq "checkboxes">
				<cfset picked = [value]>
			</cfif>
			<cfloop array="#picked#" index="choice">
				<cfif choiceSpotsLeft(field, choice, arguments.choiceCounts) eq 0>
					<cfset arrayAppend(fullChoices, choice)>
				</cfif>
			</cfloop>
			<cfif arrayLen(fullChoices)>
				<cfset result.errors[field.fieldName] = "Sorry, " & arrayToList(fullChoices, ", ") & (arrayLen(fullChoices) gt 1 ? " are" : " is") & " already full. Please choose another.">
			</cfif>
		</cfif>
		<cfset result.values[field.fieldName] = left(value, 10000)>
	</cfloop>
	<cfset result.valid = structIsEmpty(result.errors)>
	<cfreturn result>
</cffunction>

<cffunction name="saveSubmission" access="public" returntype="numeric" output="false"
		hint="Stores checked values (from validateSubmission) and returns the new submission's id. Email and Name are copied from the first email field and the first field labelled 'name'.">
	<cfargument name="webForm" type="struct" required="true">
	<cfargument name="values" type="struct" required="true">
	<cfargument name="postId" required="false" default="0">
	<cfset var submission = "">
	<cfset var field = "">
	<cfset var email = "">
	<cfset var name = "">
	<cfloop array="#arguments.webForm.fields#" index="field">
		<cfif not len(email) and field.fieldType eq "email" and structKeyExists(arguments.values, field.fieldName)>
			<cfset email = arguments.values[field.fieldName]>
		</cfif>
		<cfif not len(name) and listFindNoCase("text", field.fieldType) and findNoCase("name", field.label) and structKeyExists(arguments.values, field.fieldName)>
			<cfset name = arguments.values[field.fieldName]>
		</cfif>
	</cfloop>
	<cftransaction>
		<cfset submission = entityNew("WebFormSubmission")>
		<cfset submission.setWebFormRef(arguments.webForm.webFormId)>
		<cfset submission.setPostRef(isNumeric(arguments.postId) ? val(arguments.postId) : 0)>
		<cfset submission.setEmail(left(email, 255))>
		<cfset submission.setName(left(name, 255))>
		<cfset submission.setValuesJson(serializeJSON(arguments.values))>
		<cfset submission.setStatus("received")>
		<cfset submission.setManageToken("")>
		<cfset submission.setCreated(now())>
		<cfset submission.setDate(now())>
		<cfset entitySave(submission)>
	</cftransaction>
	<cfreturn submission.getWebFormSubmissionId()>
</cffunction>

<cffunction name="getSubmissions" access="public" returntype="array" output="false"
		hint="A form's submissions, newest first, with their values decoded.">
	<cfargument name="webFormId" type="numeric" required="true">
	<cfset var data = queryExecute("
		SELECT s.WebFormSubmissionId, s.PostRef, s.Email, s.Name, s.ValuesJson, s.Status, s.Created
		FROM WebFormSubmission s
		INNER JOIN WebForm f ON f.WebFormId = s.WebFormRef
		WHERE s.WebFormRef = :id AND f.BlogRef = :blogId
		ORDER BY s.Created DESC, s.WebFormSubmissionId DESC
	", { id = { value = arguments.webFormId, cfsqltype = "cf_sql_integer" }, blogId = { value = application.BlogDbObj.getBlogId(), cfsqltype = "cf_sql_integer" } })>
	<cfset var submissions = []>
	<cfset var values = {}>
	<cfloop query="data">
		<cfset values = {}>
		<cfif len(data.ValuesJson) and isJSON(data.ValuesJson)>
			<cfset values = deserializeJSON(data.ValuesJson)>
		</cfif>
		<cfset arrayAppend(submissions, {
			webFormSubmissionId: data.WebFormSubmissionId,
			postId: data.PostRef,
			email: data.Email,
			name: data.Name,
			status: data.Status,
			created: data.Created,
			values: values
		})>
	</cfloop>
	<cfreturn submissions>
</cffunction>

<cffunction name="deleteSubmission" access="public" returntype="boolean" output="false"
		hint="Permanently deletes one submission of this blog's forms.">
	<cfargument name="webFormSubmissionId" type="numeric" required="true">
	<cfset var found = queryExecute("
		SELECT s.WebFormSubmissionId FROM WebFormSubmission s INNER JOIN WebForm f ON f.WebFormId = s.WebFormRef
		WHERE s.WebFormSubmissionId = :id AND f.BlogRef = :blogId
	", { id = { value = arguments.webFormSubmissionId, cfsqltype = "cf_sql_integer" }, blogId = { value = application.BlogDbObj.getBlogId(), cfsqltype = "cf_sql_integer" } })>
	<cfif not found.recordCount>
		<cfreturn false>
	</cfif>
	<cftransaction>
		<cfquery name="local.deleteSubmission" dbtype="hql">
			DELETE FROM WebFormSubmission WHERE WebFormSubmissionId = <cfqueryparam value="#arguments.webFormSubmissionId#" cfsqltype="cf_sql_integer">
		</cfquery>
	</cftransaction>
	<cfreturn true>
</cffunction>

<cffunction name="getSubmissionsCsv" access="public" returntype="string" output="false"
		hint="A form's submissions as CSV: the date sent, then one column per field (current fields first, then any older field names still found in submissions).">
	<cfargument name="webFormId" type="numeric" required="true">
	<cfset var webForm = getForm(webFormId = arguments.webFormId)>
	<cfset var submissions = []>
	<cfset var columns = []>
	<cfset var labels = []>
	<cfset var seen = {}>
	<cfset var field = "">
	<cfset var submission = "">
	<cfset var key = "">
	<cfset var row = []>
	<cfset var lines = []>
	<cfif structIsEmpty(webForm)>
		<cfreturn "">
	</cfif>
	<cfset submissions = getSubmissions(arguments.webFormId)>
	<cfloop array="#webForm.fields#" index="field">
		<cfset arrayAppend(columns, field.fieldName)>
		<cfset arrayAppend(labels, field.label)>
		<cfset seen[field.fieldName] = true>
	</cfloop>
	<cfloop array="#submissions#" index="submission">
		<cfloop collection="#submission.values#" item="key">
			<cfif not structKeyExists(seen, key)>
				<cfset arrayAppend(columns, key)>
				<cfset arrayAppend(labels, key)>
				<cfset seen[key] = true>
			</cfif>
		</cfloop>
	</cfloop>
	<cfset row = ["Sent"]>
	<cfloop array="#labels#" index="key"><cfset arrayAppend(row, csvCell(key))></cfloop>
	<cfset arrayAppend(lines, arrayToList(row, ","))>
	<cfloop array="#submissions#" index="submission">
		<cfset row = [csvCell(dateTimeFormat(submission.created, "yyyy-mm-dd HH:nn"))]>
		<cfloop array="#columns#" index="key">
			<cfset arrayAppend(row, csvCell(structKeyExists(submission.values, key) ? submission.values[key] : ""))>
		</cfloop>
		<cfset arrayAppend(lines, arrayToList(row, ","))>
	</cfloop>
	<cfreturn arrayToList(lines, chr(13) & chr(10))>
</cffunction>

<!--- ********************************************************************************************************************
	The form on the site
********************************************************************************************************************* --->

<cffunction name="renderFormHtml" access="public" returntype="string" output="false"
		hint="The HTML of a form for a post or page. Every label and value is encoded here. Kendo classes do the styling (k-textbox, k-checkbox, k-radio, k-button); common/js/webForms.js turns the dropdowns and dates into Kendo widgets, fills in the captcha and sends the form.">
	<cfargument name="webForm" type="struct" required="true" hint="As returned by getForm().">
	<cfargument name="showCaptcha" type="boolean" required="false" default="false">
	<cfargument name="choiceCounts" type="struct" required="false" default="#{}#" hint="From getChoiceCounts(): limited choices then show how many spots are left, and a full one can't be picked.">
	<cfset var html = createObject("java", "java.lang.StringBuilder").init()>
	<cfset var spotsLeft = -1>
	<!--- Not named "form": FORM is a ColdFusion scope. --->
	<cfset var webFormData = arguments.webForm>
	<cfset var field = "">
	<cfset var id = "">
	<cfset var choice = "">
	<cfset var choiceIndex = 0>
	<cfset var required = "">
	<cfset var describedBy = "">
	<cfset var idPrefix = "webForm" & webFormData.webFormId & "_">

	<cfset html.append('<form class="galaxieWebFormForm" data-alias="' & encodeForHtmlAttribute(webFormData.alias) & '" novalidate="novalidate">')>
	<cfif len(webFormData.description)>
		<cfset html.append('<p class="galaxieWebFormDescription">' & replaceNoCase(encodeForHtml(webFormData.description), "&##xa;", "<br/>", "all") & '</p>')>
	</cfif>
	<cfloop array="#webFormData.fields#" index="field">
		<cfset id = idPrefix & field.fieldName>
		<cfset required = field.required ? ' required="required" aria-required="true"' : ''>
		<cfset describedBy = ' aria-describedby="' & id & '_help ' & id & '_error"'>
		<cfset html.append('<div class="galaxieWebFormField" data-field="' & encodeForHtmlAttribute(field.fieldName) & '" data-type="' & encodeForHtmlAttribute(field.fieldType) & '">')>
		<cfswitch expression="#field.fieldType#">
			<cfcase value="radio,checkboxes">
				<!--- A group: the label is a legend, and each choice has its own label. --->
				<cfset html.append('<fieldset class="galaxieWebFormGroup"' & describedBy & '><legend>' & encodeForHtml(field.label) & (field.required ? ' *' : '') & '</legend>')>
				<cfset choiceIndex = 0>
				<cfloop array="#field.choices#" index="choice">
					<cfset choiceIndex = choiceIndex + 1>
					<cfset spotsLeft = choiceSpotsLeft(field, choice, arguments.choiceCounts)>
					<cfset html.append('<div class="galaxieWebFormChoice"><input type="' & (field.fieldType eq "radio" ? "radio" : "checkbox") & '" class="' & (field.fieldType eq "radio" ? "k-radio" : "k-checkbox") & '" id="' & id & '_' & choiceIndex & '" name="' & encodeForHtmlAttribute(field.fieldName) & '" value="' & encodeForHtmlAttribute(choice) & '"' & (spotsLeft eq 0 ? ' disabled="disabled"' : '') & '> <label for="' & id & '_' & choiceIndex & '"' & (spotsLeft eq 0 ? ' class="k-state-disabled"' : '') & '>' & encodeForHtml(choice & choiceSpotsText(spotsLeft)) & '</label></div>')>
				</cfloop>
				<cfset html.append('</fieldset>')>
			</cfcase>
			<cfcase value="consent">
				<cfset html.append('<div class="galaxieWebFormChoice"><input type="checkbox" class="k-checkbox" id="' & id & '" name="' & encodeForHtmlAttribute(field.fieldName) & '" value="yes"' & required & describedBy & '> <label for="' & id & '">' & encodeForHtml(len(field.options) ? field.options : field.label) & (field.required ? ' *' : '') & '</label></div>')>
			</cfcase>
			<cfdefaultcase>
				<cfset html.append('<label for="' & id & '">' & encodeForHtml(field.label) & (field.required ? ' *' : '') & '</label>')>
				<cfswitch expression="#field.fieldType#">
					<cfcase value="textarea">
						<cfset html.append('<textarea class="k-textbox" id="' & id & '" name="' & encodeForHtmlAttribute(field.fieldName) & '" rows="5" maxlength="10000" placeholder="' & encodeForHtmlAttribute(field.placeholder) & '"' & required & describedBy & '></textarea>')>
					</cfcase>
					<cfcase value="select">
						<!--- webForms.js makes this a Kendo DropDownList. --->
						<cfset html.append('<select id="' & id & '" name="' & encodeForHtmlAttribute(field.fieldName) & '"' & required & describedBy & '><option value="">Select...</option>')>
						<cfloop array="#field.choices#" index="choice">
							<cfset spotsLeft = choiceSpotsLeft(field, choice, arguments.choiceCounts)>
							<cfset html.append('<option value="' & encodeForHtmlAttribute(choice) & '"' & (spotsLeft eq 0 ? ' disabled="disabled"' : '') & '>' & encodeForHtml(choice & choiceSpotsText(spotsLeft)) & '</option>')>
						</cfloop>
						<cfset html.append('</select>')>
					</cfcase>
					<cfcase value="date">
						<!--- webForms.js makes this a Kendo DatePicker. --->
						<cfset html.append('<input type="text" class="galaxieWebFormDate" id="' & id & '" name="' & encodeForHtmlAttribute(field.fieldName) & '"' & required & describedBy & '>')>
					</cfcase>
					<cfdefaultcase>
						<cfset html.append('<input type="' & (field.fieldType eq "email" ? "email" : (field.fieldType eq "phone" ? "tel" : (field.fieldType eq "number" ? "number" : "text"))) & '" class="k-textbox" id="' & id & '" name="' & encodeForHtmlAttribute(field.fieldName) & '" maxlength="1000" placeholder="' & encodeForHtmlAttribute(field.placeholder) & '"' & (field.fieldType eq "email" ? ' autocomplete="email"' : '') & required & describedBy & '>')>
					</cfdefaultcase>
				</cfswitch>
			</cfdefaultcase>
		</cfswitch>
		<cfif len(field.helpText)>
			<cfset html.append('<div class="galaxieWebFormHelp" id="' & id & '_help">' & encodeForHtml(field.helpText) & '</div>')>
		</cfif>
		<!--- Filled in by webForms.js when the server says this field needs a look. Kendo's own validation message classes. --->
		<cfset html.append('<div class="galaxieWebFormError k-widget k-tooltip k-tooltip-validation k-invalid-msg" id="' & id & '_error" role="alert" hidden="hidden"></div>')>
		<cfset html.append('</div>')>
	</cfloop>

	<!--- Spam protection: a field people never see. A bot that fills it in is told the form was sent, and nothing is kept. --->
	<cfset html.append('<div class="galaxieWebFormHp" aria-hidden="true"><label>Leave this empty <input type="text" name="website" tabindex="-1" autocomplete="off"></label></div>')>

	<cfif arguments.showCaptcha>
		<!--- webForms.js asks the server for the image (the same captcha as the comment form). --->
		<cfset html.append('<div class="galaxieWebFormField galaxieWebFormCaptcha" data-field="captchaText"><label for="' & idPrefix & 'captchaText">Enter the text in the image *</label><div class="galaxieWebFormCaptchaImage"></div><input type="text" class="k-textbox" id="' & idPrefix & 'captchaText" name="captchaText" autocomplete="off" required="required" aria-required="true" aria-describedby="' & idPrefix & 'captchaText_error"><div class="galaxieWebFormError k-widget k-tooltip k-tooltip-validation k-invalid-msg" id="' & idPrefix & 'captchaText_error" role="alert" hidden="hidden"></div></div>')>
	</cfif>

	<cfif webFormData.offerSubscribe>
		<cfset html.append('<div class="galaxieWebFormField galaxieWebFormChoice"><input type="checkbox" class="k-checkbox" id="' & idPrefix & 'subscribe" name="subscribeToBlog" value="yes"> <label for="' & idPrefix & 'subscribe">Email me new posts (you''ll get an email to confirm first)</label></div>')>
	</cfif>

	<cfset html.append('<div class="galaxieWebFormActions"><button type="submit" class="k-button k-primary">' & encodeForHtml(webFormData.buttonLabel) & '</button></div>')>
	<cfset html.append('<div class="galaxieWebFormStatus" role="status" aria-live="polite"></div>')>
	<cfset html.append('</form>')>
	<cfreturn html.toString()>
</cffunction>

<!--- ********************************************************************************************************************
	Helpers
********************************************************************************************************************* --->

<!--- ********************************************************************************************************************
	On the site (2026-10-13): the posts a form is assigned to ("Show on"), and its public sign-up list
********************************************************************************************************************* --->

<cffunction name="existingPostIds" access="private" returntype="array" output="false"
		hint="The ids given that are this blog's posts or pages and aren't deleted, in the order given, without repeats.">
	<cfargument name="postIds" type="array" required="true">
	<cfset var wanted = []>
	<cfset var found = {}>
	<cfset var kept = []>
	<cfset var postId = "">
	<cfset var rows = "">
	<cfloop array="#arguments.postIds#" index="postId">
		<cfif isSimpleValue(postId) and isNumeric(postId) and postId gt 0 and not arrayFind(wanted, int(postId))>
			<cfset arrayAppend(wanted, int(postId))>
		</cfif>
	</cfloop>
	<cfif not arrayLen(wanted)>
		<cfreturn kept>
	</cfif>
	<cfset rows = queryExecute("SELECT PostId FROM Post WHERE PostId IN (:ids) AND BlogRef = :blogId AND (Remove IS NULL OR Remove = 0)", {
		ids = { value = arrayToList(wanted), cfsqltype = "cf_sql_integer", list = true },
		blogId = { value = application.BlogDbObj.getBlogId(), cfsqltype = "cf_sql_integer" } })>
	<cfloop query="rows">
		<cfset found[rows.PostId] = true>
	</cfloop>
	<cfloop array="#wanted#" index="postId">
		<cfif structKeyExists(found, postId)>
			<cfset arrayAppend(kept, postId)>
		</cfif>
	</cfloop>
	<cfreturn kept>
</cffunction>

<cffunction name="getPostChoices" access="public" returntype="array" output="false"
		hint="Every post and page of this blog that isn't deleted, by title, for the form editor's 'Show on' list: [{ postId, title, released }].">
	<cfset var posts = []>
	<cfset var rows = queryExecute("
		SELECT PostId, Title, Released FROM Post
		WHERE BlogRef = :blogId AND (Remove IS NULL OR Remove = 0)
		ORDER BY Title
	", { blogId = { value = application.BlogDbObj.getBlogId(), cfsqltype = "cf_sql_integer" } })>
	<cfloop query="rows">
		<cfset arrayAppend(posts, { "postId": rows.PostId, "title": rows.Title, "released": isTrue(rows.Released) })>
	</cfloop>
	<cfreturn posts>
</cffunction>

<cffunction name="getShowOnPosts" access="public" returntype="array" output="false"
		hint="The posts and pages a form is assigned to, as [{ postId, title, released }].">
	<cfargument name="webFormId" type="numeric" required="true">
	<cfset var posts = []>
	<cfset var rows = queryExecute("
		SELECT p.PostId, p.Title, p.Released
		FROM WebFormPost wp INNER JOIN Post p ON p.PostId = wp.PostRef
		WHERE wp.WebFormRef = :id AND p.BlogRef = :blogId AND (p.Remove IS NULL OR p.Remove = 0)
		ORDER BY wp.WebFormPostId
	", { id = { value = arguments.webFormId, cfsqltype = "cf_sql_integer" }, blogId = { value = application.BlogDbObj.getBlogId(), cfsqltype = "cf_sql_integer" } })>
	<cfloop query="rows">
		<cfset arrayAppend(posts, { "postId": rows.PostId, "title": rows.Title, "released": isTrue(rows.Released) })>
	</cfloop>
	<cfreturn posts>
</cffunction>

<cffunction name="getPlacementsForPost" access="public" returntype="array" output="false"
		hint="The active forms assigned to a post, and what each shows there: [{ alias, title, showForm, showList }]. Used below the post's text (includes/templates/blogContentHtml.cfm) and by the post editor's note.">
	<cfargument name="postId" type="numeric" required="true">
	<cfset var placements = []>
	<cfset var mode = "">
	<cfset var rows = queryExecute("
		SELECT f.Alias, f.Title, f.ShowOnMode, f.PublicList
		FROM WebFormPost wp INNER JOIN WebForm f ON f.WebFormId = wp.WebFormRef
		WHERE wp.PostRef = :postId AND f.BlogRef = :blogId AND f.Active = 1
		ORDER BY wp.WebFormPostId
	", { postId = { value = arguments.postId, cfsqltype = "cf_sql_integer" }, blogId = { value = application.BlogDbObj.getBlogId(), cfsqltype = "cf_sql_integer" } })>
	<cfloop query="rows">
		<!--- As in getForm: a list needs the privacy switch. --->
		<cfset mode = isTrue(rows.PublicList) and listFind("formAndList,list", rows.ShowOnMode) ? rows.ShowOnMode : "form">
		<cfset arrayAppend(placements, { alias: rows.Alias, title: rows.Title, showForm: mode neq "list", showList: mode neq "form" })>
	</cfloop>
	<cfreturn placements>
</cffunction>

<cffunction name="setSubmissionHidden" access="public" returntype="boolean" output="false"
		hint="Hides a submission from the form's public sign-up list, or shows it again. A hidden submission still holds its spot under the choice limits; only deleting it frees the spot.">
	<cfargument name="webFormSubmissionId" type="numeric" required="true">
	<cfargument name="hidden" type="boolean" required="true">
	<cfset var found = queryExecute("
		SELECT s.WebFormSubmissionId FROM WebFormSubmission s INNER JOIN WebForm f ON f.WebFormId = s.WebFormRef
		WHERE s.WebFormSubmissionId = :id AND f.BlogRef = :blogId
	", { id = { value = arguments.webFormSubmissionId, cfsqltype = "cf_sql_integer" }, blogId = { value = application.BlogDbObj.getBlogId(), cfsqltype = "cf_sql_integer" } })>
	<cfif not found.recordCount>
		<cfreturn false>
	</cfif>
	<cftransaction>
		<cfquery name="local.setStatus" dbtype="hql">
			UPDATE WebFormSubmission SET Status = <cfqueryparam value="#arguments.hidden ? 'hidden' : 'received'#" cfsqltype="cf_sql_varchar">
			WHERE WebFormSubmissionId = <cfqueryparam value="#arguments.webFormSubmissionId#" cfsqltype="cf_sql_integer">
		</cfquery>
	</cftransaction>
	<cfreturn true>
</cffunction>

<cffunction name="renderPublicListHtml" access="public" returntype="string" output="false"
		hint="The form's public sign-up list: a summary of the limited choices, a search box and a table of the fields marked 'Show in the public list', oldest sign-up first. Hidden submissions are left out. Empty when the form's privacy switch (PublicList) is off. Every value is encoded here; common/js/webForms.js adds the searching and sorting.">
	<cfargument name="webForm" type="struct" required="true" hint="As returned by getForm().">
	<cfset var html = createObject("java", "java.lang.StringBuilder").init()>
	<cfset var columns = []>
	<cfset var field = "">
	<cfset var choice = "">
	<cfset var counts = "">
	<cfset var summary = []>
	<cfset var parts = []>
	<cfset var rows = "">
	<cfset var values = "">
	<cfset var value = "">
	<cfset var shown = 0>
	<cfif not arguments.webForm.publicList>
		<cfreturn "">
	</cfif>
	<cfloop array="#arguments.webForm.fields#" index="field">
		<cfif field.showPublic>
			<cfset arrayAppend(columns, field)>
		</cfif>
	</cfloop>

	<!--- The summary: each limited choice as taken/limit, so people see what is still needed before they sign up. --->
	<cfset counts = getChoiceCounts(arguments.webForm)>
	<cfloop array="#arguments.webForm.fields#" index="field">
		<cfif structKeyExists(counts, field.fieldName)>
			<cfset parts = []>
			<cfloop array="#field.choices#" index="choice">
				<cfif structKeyExists(field.choiceLimits, choice)>
					<cfset arrayAppend(parts, encodeForHtml(choice) & " " & counts[field.fieldName][choice] & "/" & field.choiceLimits[choice] & (counts[field.fieldName][choice] gte field.choiceLimits[choice] ? " (full)" : ""))>
				</cfif>
			</cfloop>
			<cfset arrayAppend(summary, '<p class="galaxieWebFormListSummary"><b>' & encodeForHtml(field.label) & '</b> ' & arrayToList(parts, " &middot; ") & '</p>')>
		</cfif>
	</cfloop>
	<cfset html.append(arrayToList(summary, ""))>

	<cfset rows = queryExecute("
		SELECT ValuesJson FROM WebFormSubmission
		WHERE WebFormRef = :id AND (Status IS NULL OR Status <> 'hidden')
		ORDER BY Created, WebFormSubmissionId
	", { id = { value = arguments.webForm.webFormId, cfsqltype = "cf_sql_integer" } })>

	<cfif not arrayLen(columns)>
		<cfreturn html.toString()>
	</cfif>
	<cfif not rows.recordCount>
		<cfset html.append('<p class="galaxieWebFormListEmpty">No one has signed up yet.</p>')>
		<cfreturn html.toString()>
	</cfif>

	<cfset html.append('<div class="galaxieWebFormListTools"><input type="search" class="k-textbox galaxieWebFormListSearch" placeholder="Search the list" aria-label="Search the sign-up list"> <span class="galaxieWebFormListCount" aria-live="polite">' & rows.recordCount & (rows.recordCount eq 1 ? " sign-up" : " sign-ups") & '</span></div>')>
	<cfset html.append('<table class="galaxieWebFormListTable k-content"><thead><tr>')>
	<cfloop array="#columns#" index="field">
		<!--- A button in each heading sorts by that column (webForms.js). --->
		<cfset html.append('<th class="k-header" scope="col"><button type="button" class="galaxieWebFormListSort">' & encodeForHtml(field.label) & '</button></th>')>
	</cfloop>
	<cfset html.append('</tr></thead><tbody>')>
	<cfloop query="rows">
		<cfset values = {}>
		<cftry>
			<cfset values = deserializeJSON(rows.ValuesJson)>
			<cfcatch type="any"><cfset values = {}></cfcatch>
		</cftry>
		<cfif isStruct(values)>
			<cfset html.append('<tr>')>
			<cfloop array="#columns#" index="field">
				<cfset value = structKeyExists(values, field.fieldName) and isSimpleValue(values[field.fieldName]) ? values[field.fieldName] : "">
				<cfif field.fieldType eq "consent">
					<cfset value = len(value) ? "Yes" : "">
				</cfif>
				<!--- data-label: the column name, shown beside the value when the rows stack on a phone. --->
				<cfset html.append('<td data-label="' & encodeForHtmlAttribute(field.label) & '">' & replaceNoCase(encodeForHtml(value), "&##xa;", "<br/>", "all") & '</td>')>
			</cfloop>
			<cfset html.append('</tr>')>
		</cfif>
	</cfloop>
	<cfset html.append('</tbody></table>')>
	<cfreturn html.toString()>
</cffunction>

<cffunction name="addPlacementLinks" access="public" returntype="string" output="false"
		hint="Adds links for the forms assigned to a post under 'Show on' (they aren't in the post's text, so replacePlaceholders doesn't see them) to the end of the HTML, for the subscriber email and the feeds.">
	<cfargument name="html" type="string" required="true">
	<cfargument name="postId" type="numeric" required="true">
	<cfargument name="linkUrl" type="string" required="true">
	<cfset var result = arguments.html>
	<cfset var placement = "">
	<cfloop array="#getPlacementsForPost(arguments.postId)#" index="placement">
		<cfif placement.showForm>
			<cfset result = result & '<p><a href="' & encodeForHtmlAttribute(arguments.linkUrl) & '">Fill in the form "' & encodeForHtml(placement.title) & '" on the website</a></p>'>
		<cfelse>
			<cfset result = result & '<p><a href="' & encodeForHtmlAttribute(arguments.linkUrl) & '">See the sign-up list "' & encodeForHtml(placement.title) & '" on the website</a></p>'>
		</cfif>
	</cfloop>
	<cfreturn result>
</cffunction>

<cffunction name="replacePlaceholders" access="public" returntype="string" output="false"
		hint="Swaps each form placed in a post (<div class='galaxieWebForm' data-webform='alias'>[Form: Title]</div>) for a link to the post, for where the form can't work: the subscriber email (Renderer.cfc) and the RSS and Atom feeds (blog.cfc, which then reduce it to its text). Returns the HTML unchanged when it has no forms.">
	<cfargument name="html" type="string" required="true">
	<cfargument name="linkUrl" type="string" required="true" hint="The post's own address.">
	<cfset var result = arguments.html>
	<cfset var match = "">
	<cfset var title = "">
	<cfset var replacement = "">
	<cfset var position = 1>
	<cfif not findNoCase("galaxieWebForm", result)>
		<cfreturn result>
	</cfif>
	<cfloop condition="true">
		<!--- Our own markup, written by the Insert Form window; the class may sit anywhere among the attributes. --->
		<!--- Both kinds: the form (galaxieWebForm) and its sign-up list (galaxieWebFormList). --->
		<cfset match = reFindNoCase('<div[^>]*class="[^"]*\bgalaxieWebForm(List)?\b[^"]*"[^>]*>(.*?)</div>', result, position, true)>
		<cfif not match.pos[1]>
			<cfbreak>
		</cfif>
		<!--- The text inside reads "[Form: Title]" or "[Sign-up list: Title]", already HTML encoded. The quotes around it below are
		plain ones, not &quot;: the feeds strip the tags but not the entities, so &quot; would reach feed readers as text. --->
		<cfset title = trim(reReplace(mid(result, match.pos[3], match.len[3]), "<[^>]*>", "", "all"))>
		<cfset title = trim(reReplaceNoCase(title, "^\[(Form|Sign-up list):\s*(.*)\]$", "\2"))>
		<cfif match.len[2]>
			<cfset replacement = '<p><a href="' & encodeForHtmlAttribute(arguments.linkUrl) & '">' & (len(title) ? 'See the sign-up list "' & title & '" on the website' : 'See the sign-up list on the website') & '</a></p>'>
		<cfelse>
			<cfset replacement = '<p><a href="' & encodeForHtmlAttribute(arguments.linkUrl) & '">' & (len(title) ? 'Fill in the form "' & title & '" on the website' : 'Fill in the form on the website') & '</a></p>'>
		</cfif>
		<cfset result = left(result, match.pos[1] - 1) & replacement & mid(result, match.pos[1] + match.len[1], len(result))>
		<cfset position = match.pos[1] + len(replacement)>
	</cfloop>
	<cfreturn result>
</cffunction>

<!--- Choice limits (2026-10-13): a select, radio or checkboxes field can cap how many submissions pick each choice, eg. at most 4
desserts for a potluck. The limits are stored as JSON in WebFormField.ChoiceLimits. The counts come from the submissions that
are kept, so deleting a submission frees its spot. ProxyController's submitWebForm counts and saves inside one lock per form,
so two people can't both take the last spot. --->

<cffunction name="parseChoiceLimits" access="private" returntype="struct" output="false"
		hint="The stored limits as { choice: number }, keeping only the field's current choices and whole numbers of at least 1.">
	<cfargument name="choiceLimitsJson" type="string" required="true">
	<cfargument name="fieldType" type="string" required="true">
	<cfargument name="choices" type="array" required="true">
	<cfset var stored = {}>
	<cfset var limits = {}>
	<cfset var choice = "">
	<cfif not listFindNoCase(variables.choiceTypes, arguments.fieldType) or not len(trim(arguments.choiceLimitsJson))>
		<cfreturn limits>
	</cfif>
	<cftry>
		<cfset stored = deserializeJSON(arguments.choiceLimitsJson)>
		<cfcatch type="any"><cfreturn limits></cfcatch>
	</cftry>
	<cfif not isStruct(stored)>
		<cfreturn limits>
	</cfif>
	<cfloop array="#arguments.choices#" index="choice">
		<cfif structKeyExists(stored, choice) and isNumeric(stored[choice]) and int(stored[choice]) gte 1>
			<cfset limits[choice] = int(stored[choice])>
		</cfif>
	</cfloop>
	<cfreturn limits>
</cffunction>

<cffunction name="serializeChoiceLimits" access="private" returntype="string" output="false"
		hint="The limits the editor sent, as the JSON stored in WebFormField.ChoiceLimits, or an empty string when there are none.">
	<cfargument name="choiceLimits" required="true" hint="A struct of { choice: number }; anything else counts as no limits.">
	<cfargument name="fieldType" type="string" required="true">
	<cfargument name="choices" type="array" required="true">
	<cfset var limits = [:]>
	<cfset var choice = "">
	<cfif not isStruct(arguments.choiceLimits) or not listFindNoCase(variables.choiceTypes, arguments.fieldType)>
		<cfreturn "">
	</cfif>
	<cfloop array="#arguments.choices#" index="choice">
		<cfif structKeyExists(arguments.choiceLimits, choice) and isNumeric(arguments.choiceLimits[choice]) and int(arguments.choiceLimits[choice]) gte 1>
			<cfset limits[choice] = min(int(arguments.choiceLimits[choice]), 100000)>
		</cfif>
	</cfloop>
	<cfreturn structIsEmpty(limits) ? "" : left(serializeJSON(limits), 2000)>
</cffunction>

<cffunction name="getChoiceCounts" access="public" returntype="struct" output="false"
		hint="How many kept submissions picked each limited choice: { fieldName: { choice: count } }. Only fields with limits are counted, and a form without any limits returns an empty struct without reading the submissions.">
	<cfargument name="webForm" type="struct" required="true" hint="As returned by getForm().">
	<cfset var counts = {}>
	<cfset var field = "">
	<cfset var choice = "">
	<cfset var rows = "">
	<cfset var values = "">
	<cfset var value = "">
	<cfloop array="#arguments.webForm.fields#" index="field">
		<cfif structKeyExists(field, "choiceLimits") and not structIsEmpty(field.choiceLimits)>
			<cfset counts[field.fieldName] = {}>
			<cfloop collection="#field.choiceLimits#" item="choice">
				<cfset counts[field.fieldName][choice] = 0>
			</cfloop>
		</cfif>
	</cfloop>
	<cfif structIsEmpty(counts)>
		<cfreturn counts>
	</cfif>
	<cfset rows = queryExecute("SELECT ValuesJson FROM WebFormSubmission WHERE WebFormRef = :id",
		{ id = { value = arguments.webForm.webFormId, cfsqltype = "cf_sql_integer" } })>
	<cfloop query="rows">
		<cftry>
			<cfset values = deserializeJSON(rows.ValuesJson)>
			<cfcatch type="any"><cfset values = {}></cfcatch>
		</cftry>
		<cfif isStruct(values)>
			<cfloop array="#arguments.webForm.fields#" index="field">
				<cfif structKeyExists(counts, field.fieldName) and structKeyExists(values, field.fieldName) and isSimpleValue(values[field.fieldName])>
					<!--- A checkbox group is stored as "a, b"; padding both sides finds a whole choice even when it has a comma in it. --->
					<cfset value = ", " & values[field.fieldName] & ", ">
					<cfloop collection="#counts[field.fieldName]#" item="choice">
						<cfif (field.fieldType eq "checkboxes" and find(", " & choice & ", ", value)) or (field.fieldType neq "checkboxes" and values[field.fieldName] eq choice)>
							<cfset counts[field.fieldName][choice] = counts[field.fieldName][choice] + 1>
						</cfif>
					</cfloop>
				</cfif>
			</cfloop>
		</cfif>
	</cfloop>
	<cfreturn counts>
</cffunction>

<cffunction name="choiceSpotsLeft" access="public" returntype="numeric" output="false"
		hint="How many more submissions can pick this choice, or -1 when it has no limit.">
	<cfargument name="field" type="struct" required="true">
	<cfargument name="choice" type="string" required="true">
	<cfargument name="choiceCounts" type="struct" required="true" hint="From getChoiceCounts().">
	<cfset var taken = 0>
	<cfif not structKeyExists(arguments.field, "choiceLimits") or not structKeyExists(arguments.field.choiceLimits, arguments.choice)>
		<cfreturn -1>
	</cfif>
	<cfif structKeyExists(arguments.choiceCounts, arguments.field.fieldName) and structKeyExists(arguments.choiceCounts[arguments.field.fieldName], arguments.choice)>
		<cfset taken = arguments.choiceCounts[arguments.field.fieldName][arguments.choice]>
	</cfif>
	<cfreturn max(arguments.field.choiceLimits[arguments.choice] - taken, 0)>
</cffunction>

<cffunction name="choiceSpotsText" access="private" returntype="string" output="false"
		hint="What a visitor sees after a limited choice, eg. ' (3 spots left)' or ' (full)'; empty for a choice without a limit.">
	<cfargument name="spotsLeft" type="numeric" required="true">
	<cfif arguments.spotsLeft lt 0>
		<cfreturn "">
	<cfelseif arguments.spotsLeft eq 0>
		<cfreturn " (full)">
	</cfif>
	<cfreturn " (" & arguments.spotsLeft & (arguments.spotsLeft eq 1 ? " spot" : " spots") & " left)">
</cffunction>

<cffunction name="makeFieldName" access="public" returntype="string" output="false"
		hint="A short key for a field, made from its label (eg. 'Your email address' -> 'yourEmailAddress'), unique within the form.">
	<cfargument name="label" type="string" required="true">
	<cfargument name="usedNames" type="struct" required="false" default="#{}#" hint="Names already used in this form (lower case keys).">
	<cfset var words = listToArray(reReplace(lCase(arguments.label), "[^a-z0-9]+", " ", "all"), " ")>
	<cfset var name = "">
	<cfset var i = 0>
	<cfset var candidate = "">
	<cfloop from="1" to="#min(arrayLen(words), 5)#" index="i">
		<cfset name = name & (i eq 1 ? words[i] : uCase(left(words[i], 1)) & mid(words[i], 2, len(words[i])))>
	</cfloop>
	<cfif not len(name) or reFind("^[0-9]", name)>
		<cfset name = "field" & name>
	</cfif>
	<cfset name = left(name, 60)>
	<cfset candidate = name>
	<cfset i = 1>
	<cfloop condition="structKeyExists(arguments.usedNames, lCase(candidate))">
		<cfset i = i + 1>
		<cfset candidate = name & i>
	</cfloop>
	<cfreturn candidate>
</cffunction>

<cffunction name="makeUniqueAlias" access="private" returntype="string" output="false"
		hint="A url-style alias from the title (eg. 'Contact Us' -> 'contact-us'), unique among this blog's forms.">
	<cfargument name="title" type="string" required="true">
	<cfset var base = left(reReplace(reReplace(lCase(trim(arguments.title)), "[^a-z0-9]+", "-", "all"), "^-+|-+$", "", "all"), 90)>
	<cfset var candidate = "">
	<cfset var i = 1>
	<cfif not len(base)>
		<cfset base = "form">
	</cfif>
	<cfset candidate = base>
	<!--- The lookup is in its own function: Adobe ColdFusion can't evaluate a struct literal inside a cfloop condition. --->
	<cfloop condition="aliasIsTaken(candidate)">
		<cfset i = i + 1>
		<cfset candidate = base & "-" & i>
	</cfloop>
	<cfreturn candidate>
</cffunction>

<cffunction name="aliasIsTaken" access="private" returntype="boolean" output="false">
	<cfargument name="alias" type="string" required="true">
	<cfreturn arrayLen(ormExecuteQuery("FROM WebForm WHERE Alias = :alias AND BlogRef = :blogId", { alias = arguments.alias, blogId = javacast("int", application.BlogDbObj.getBlogId()) })) gt 0>
</cffunction>

<cffunction name="csvCell" access="private" returntype="string" output="false"
		hint="One CSV cell, quoted, with quotes doubled. A value that starts with = + - or @ gets a leading apostrophe so a spreadsheet doesn't run it as a formula.">
	<cfargument name="value" required="true">
	<cfset var text = isSimpleValue(arguments.value) ? toString(arguments.value) : "">
	<cfif reFind("^[=+\-@]", text)>
		<cfset text = "'" & text>
	</cfif>
	<cfreturn '"' & replace(text, '"', '""', "all") & '"'>
</cffunction>

<cffunction name="valueOrEmpty" access="private" returntype="string" output="false"
		hint="A string column's value, or an empty string when it is NULL.">
	<cfargument name="value" required="false">
	<cfif isNull(arguments.value)>
		<cfreturn "">
	</cfif>
	<cfreturn arguments.value>
</cffunction>

<cffunction name="isTrue" access="private" returntype="boolean" output="false"
		hint="A boolean column or form value however it arrives (true/false, 1/0, yes/no, on); NULL or empty uses the default.">
	<cfargument name="value" required="false">
	<cfargument name="defaultValue" type="boolean" required="false" default="false">
	<cfif isNull(arguments.value) or not isSimpleValue(arguments.value) or not len(arguments.value)>
		<cfreturn arguments.defaultValue>
	</cfif>
	<cfif arguments.value eq "on">
		<cfreturn true>
	</cfif>
	<cfif isBoolean(arguments.value)>
		<cfreturn arguments.value>
	</cfif>
	<cfreturn arguments.defaultValue>
</cffunction>

</cfcomponent>
