<cfcomponent displayname="ServiceKey.cfc" output="no">

<!---
*****************************************************************************************************************************************  
Security tokens and keys.
***************************************************************************************************************************************** 
--->
	
<!---******************  Functions to create a random phrase and a key ******************--->
	
<cffunction name="createEncryptionPhrase" access="package" returntype="string" hint="Generates an key to use for encryption. This is a private function only available to other functions on this page.">
	<!--- Use the rand function to create a new phrase. --->
	<!--- Local vars --->
    <cfset var result="">
    <cfset var i=0>

    <!--- Create string --->
    <cfloop index="i" from="1" to="15">
        <!--- Random character in range A-Z --->
        <cfset result=result&Chr(randRange(65, 90))>
    </cfloop>

	<cfreturn result>
	
</cffunction>

<cffunction name="createEncryptionKey" access="package" returntype="string" hint="Generates an key to use for encryption. This is a private function only available to other functions on this page.">
	<!--- Generate a secret key. --->
	<cfset encryptionKey = generateSecretKey( "AES" ) />
	
	<cfreturn encryptionKey>
	
</cffunction>
	
<!--- Generate the 'serviceKey'. This is the encrypted key that is created using the random phrase and the encryption key. I am calling this a 'service key' in order to obsfucate the logic as it is used on the client side. --->
<cffunction name="createServiceKey" access="remote" returntype="string" hint="Generates and saves our service key that is a comination of a phrase and an encryptionKey. Returns the serviceKey back to the client as a string. This should be the only 'key' related security function that is accessible to the client without having to pass in a 'serviceKey'.">
	
	<cfargument name="sessionId" required="true" hint="Pass in the current session Id."/>
	
	<!---Create a random encryption phrase.--->
	<cfset encryptionPhrase = createEncryptionPhrase(arguments.sessionId)>
	<!---Create a random key (this creates a new key every  single time it is invoked).--->
	<cfset encryptionKey = createEncryptionKey(arguments.sessionId)>
	<!---Use the encryption phrase and new key to create the 'serviceKey'.--->
	<cfset serviceKey = encrypt(encryptionPhrase, encryptionKey,  "AES", "hex") />	
	
	<!---Insert the values into the database in order to persist the keys (remember that a new encryption key will be randomly generated each time and we need to save them).--->
	<cfquery name="data" datasource="#instance.dsn#" username="#instance.username#" password="#instance.password#">
		INSERT INTO dbo.ServiceKey (
			EncryptionPhrase,	
			EncryptionKey,
			ServiceKey,
			SessionId,
			Active,
			Date
		) VALUES (
			<cfqueryparam value="#encryptionPhrase#" cfsqltype="cf_sql_varchar">,
			<cfqueryparam value="#encryptionKey#" cfsqltype="cf_sql_varchar">,
			<cfqueryparam value="#serviceKey#" cfsqltype="cf_sql_varchar">,
			<cfqueryparam value="#sessionId#" cfsqltype="cf_sql_varchar">,
			<cfqueryparam value="1" cfsqltype="cf_sql_bit">,
			getDate()
		)
	</cfquery>
				
	<!---Return the service key back to the client. We don't want to return any other keys to the client side for security.--->
	<cfreturn serviceKey>
	
</cffunction>
	
<!---******************  Functions to get the random phrase and a key ******************--->
	
<!---What is the key prase used to encrypt and decode the key with?--->
<cffunction name="getEncryptionPhrase" access="package" returntype="string" hint="Sets our key prase to use in encryption. This is a private function only available to other functions on this page.">
	
	<cfargument name="sessionId" required="true" hint="Pass in the current session Id."/>
	<cfargument name="serviceKey" required="true" hint="Pass in the current service key."/>
	
	<cfquery name="data" datasource="#instance.dsn#" username="#instance.username#" password="#instance.password#">
		SELECT EncryptionPhrase
		FROM dbo.ServiceKey
		WHERE SessionId = <cfqueryparam value="#arguments.sessionId#" cfsqltype="cf_sql_varchar" />
		AND ServiceKey = <cfqueryparam value="#arguments.serviceKey#" cfsqltype="cf_sql_varchar" />
		AND Active = 1
	</cfquery>
	
	<!---If there is more than one record for a sessionId due to a browser being refreshed, get the last record. --->
	<cfreturn data.EncryptionPhrase[data.recordcount]>
	
</cffunction>
	

<cffunction name="getEncryptionKey" access="package" returntype="string" hint="Generates an key to use for encryption. This is a private function only available to other functions on this page.">
	
	<cfargument name="sessionId" required="true" hint="Pass in the current session Id."/>
	<cfargument name="serviceKey" required="true" hint="Pass in the current service key."/>
	
	<!--- Get the key from the db. --->
	<cfquery name="data" datasource="#instance.dsn#" username="#instance.username#" password="#instance.password#">
		SELECT EncryptionKey
		FROM dbo.ServiceKey
		WHERE SessionId = <cfqueryparam value="#arguments.sessionId#" cfsqltype="cf_sql_varchar" />
		AND ServiceKey = <cfqueryparam value="#arguments.serviceKey#" cfsqltype="cf_sql_varchar" />
		AND Active = 1
	</cfquery>
	
	<!---If there is more than one record for a sessionId due to a browser being refreshed, get the last record. --->
	<cfreturn data.EncryptionKey[data.recordcount]>
	
</cffunction>
	

<cffunction name="decryptClientServiceKey" access="package" returntype="string" hint="Decrypts the encrypted key sent by the client. This is a private function only available to other functions on this page.">
	
	<!---The 'serviceKey' is actually a key created by the combination of a key phrase and an encyption key created using ColdFusion's generateKey method. --->
	<cfargument name="serviceKey" required="yes" hint="Pass in the serviceKey.">
	<cfargument name="sessionId" required="true" hint="Pass in the current session Id."/>
		
	<!--- Get the encryption key (created with ColdFusion's generateSecretKey method). --->
	<cfinvoke method="getEncryptionKey" returnvariable="encryptionKey">
		<cfinvokeargument name="sessionId" value="#arguments.sessionId#">
		<cfinvokeargument name="serviceKey" value="#arguments.serviceKey#">
	</cfinvoke>
    
	<!---The decrypt function takes the service key (which is generated using a key phrase) and an ecyrption key created by the generateSecretKey native ColdFusion method. Once decoded, it should match the 'encryption phrase'. --->
    <cfset decodedClientKey = decrypt(arguments.serviceKey, encryptionKey, "AES", "hex") />
	
	<!---Return it. It should match the encryption phrase.--->
	<cfreturn decodedClientKey>
	
</cffunction>

<cffunction name="isClientKeyAuthorized" access="package" returntype="boolean" hint="Compares the decoded client key and see if it matches the encryptionPhrase. If it does, the client is authorized.">
	<!---The 'serviceKey' is actually a key created by the combination of a key phrase and an encyption key created using ColdFusion's generateKey method. --->
	<cfargument name="serviceKey" required="yes">
	<cfargument name="sessionId" required="true" hint="Pass in the current session Id."/>
	
	<!---Get the encryption phrase--->
	<cfinvoke component="#this#" method="getEncryptionPhrase" returnvariable="encryptionPhrase">
		<!---The 'serviceKey' is actually a key created by the combination of a key phrase and an encyption key created using ColdFusion's generateKey method. --->
		<cfinvokeargument name="sessionId" value="#arguments.sessionId#">
		<cfinvokeargument name="serviceKey" value="#arguments.serviceKey#">
	</cfinvoke>
		
	<!---Decode the client key.--->
	<cfinvoke component="#this#" method="decryptClientServiceKey" returnvariable="decodedClientKey">
		<!---The 'serviceKey' is actually a key created by the combination of a key phrase and an encyption key created using ColdFusion's generateKey method. --->
		<cfinvokeargument name="sessionId" value="#arguments.sessionId#">
		<cfinvokeargument name="serviceKey" value="#arguments.serviceKey#">
	</cfinvoke>
	
	<!---Determine if the client key and the keyPhrase match. IF the keys match, the client is authorized.--->
	<cfif decodedClientKey eq encryptionPhrase>
		<cfset isAuth = true>
	<cfelse>
		<cfset isAuth = false>
	</cfif>
	
	<cfreturn isAuth>
	
</cffunction>

<!---
*****************************************************************************************************************************************  
AJAX Functions to the the general AWD site. 
***************************************************************************************************************************************** 
--->
<cffunction name="postContact" access="remote" returnformat="json" hint="Consumed by the AWD contact page. This is a remote method available to the client when the service key is authorized.">
	<cfargument name="contactName" type="string" required="yes" default="">
	<cfargument name="contactEmail" type="string" required="yes" default="">
	<cfargument name="contactWebSite" type="string" required="no" default="">
	<cfargument name="contactMessage" type="string" required="yes" default="">
	<!---The 'serviceKey' is actually a key created by the combination of a key phrase and an encyption key created using ColdFusion's generateKey method. --->
	<cfargument name="serviceKey" type="string" required="yes" default="">
	<cfargument name="sessionId" type="string" required="yes" default="">
	
	<!---An encrypted service Key is sent in in order to unlock this function. It is designed to prevent hacking from remote services not on this site. See if the service key matches the client side service key. If it does not, don't do anything. --->
	<cfinvoke method="isClientKeyAuthorized" returnvariable="isClientKeyAuthorized">
		<!---The 'serviceKey' is actually a key created by the combination of a key phrase and an encyption key created using ColdFusion's generateKey method. --->
		<cfinvokeargument name="serviceKey" value="#arguments.serviceKey#">
		<cfinvokeargument name="sessionId" value="#arguments.sessionId#">
	</cfinvoke>
	
	<cfif isClientKeyAuthorized>
		<cfmail from="notify@gregoryalexander.com" to="gregory@gregoryalexander.com" subject="AWD Contact" type="html">
			The following person contacted you via the AWD contact form:<br/>
			#arguments.contactName#<br/>
			#arguments.contactEmail#<br/>
			#arguments.contactWebSite#<br/>
			#arguments.contactMessage#<br/>
		</cfmail> 
	</cfif>
	

	<cfreturn isClientKeyAuthorized>
	
</cffunction>
	
	
</cfcomponent>