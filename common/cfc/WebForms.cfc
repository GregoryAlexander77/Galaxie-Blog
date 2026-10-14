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
	<cfreturn this>
</cffunction>

<cffunction name="getFieldTypes" access="public" returntype="array" output="false">
	<cfreturn duplicate(variables.fieldTypes)>
</cffunction>

<!--- ********************************************************************************************************************
	Reading
********************************************************************************************************************* --->

<cffunction name="getForms" access="public" returntype="array" output="false"
		hint="Every form of this blog, newest first, with its number of fields and submissions.">
	<cfset var data = queryExecute("
		SELECT f.WebFormId, f.Title, f.Alias, CASE WHEN f.Active = 1 THEN 1 ELSE 0 END AS Active, f.Created,
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
		fields: []
	}>
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
	</cfloop>
	<cfreturn result>
</cffunction>

<!--- ********************************************************************************************************************
	Saving a form (admin)
********************************************************************************************************************* --->

<cffunction name="saveForm" access="public" returntype="struct" output="false"
		hint="Creates or updates a form and replaces its fields with the ones given, in that order. Returns { success, webFormId, errors[] }.">
	<cfargument name="formData" type="struct" required="true" hint="webFormId (0 or empty = new), title, description, buttonLabel, confirmationMessage, confirmationUrl, notifyEmails, offerSubscribe, requireCaptcha, active, fields: [ { webFormFieldId, label, fieldType, required, placeholder, helpText, options } ]">
	<cfset var result = { success: false, webFormId: 0, errors: [] }>
	<cfset var data = arguments.formData>
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
	<cfset var result = { valid: true, errors: {}, values: [:] }>
	<cfset var field = "">
	<cfset var value = "">
	<cfset var picked = []>
	<cfset var choice = "">
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
	Helpers
********************************************************************************************************************* --->

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
