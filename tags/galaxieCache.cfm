<!---
	Name: galaxieCache.cfm
	Author: 		Gregory Alexander. This is a modern fork of the scopeCache library authored by Raymond Camden. This runs about 15-20% faster than 
					scopeCache and 5-10 faster than cfcache when using scope='html'! I *completely* overhauled the original library and added debugging cariages, JSON, and HTML file formats when storing the data in files.
	Purpose: 		Allows you to cache content in various scopes.

					This tag allows you to cache content and data in various RAM-based scopes. 
					The tag takes the following attributes:

	name/cachename:	The name of the data. Either name or cacheName is required. Use cacheName when using a cfmodule tag (required)
	scope: 			The scope where cached data will reside. Must be either session, 
					application, server, or file. (required)
	fileType:		We can store the data as a JSON or HTML when the scope is set to 'file'. Saving to WDDX is supported, but depracated.
					HTML is the most efficient and uses a simple cfinclude to output the data, however, it uses more disk space on the server. 
	file:			Fully qualified file name for file-based caching. Only used when the scope is set to 'file'.
	timeout: 		When the cache will timeout. By default, the year 3999 (i.e., never). 
					Value must be either a date/time stamp or a number representing the
					number of seconds until the timeout is reached. Use 0 if you want an immediate timeout to reset the cache data (optional)
	clear:			If passed and if true, will clear out the cached item. Note that
					This option will NOT recreate the cache. In other words, the rest of
					the tag isn't run (well, mostly, but dont worry).
	clearAll:		Removes all data from this scope. Exits the tag immediately.
	cacheDirectory: The cache directory where the cached files reside is required if you're using clearAll and 
					you want to delete all of the cached files when using file and fileType html.
	disabled:		Allows for a quick exit out of the tag. How would this be used? You can 
					imagine using disabled="#request.disabled#" to allow for a quick way to
					turn on/off caching for the entire site. Of course, all calls to the tag
					would have to use the same value.
	getCacheItems:	Returns a list of keys in the cache. The tag exists when called. 
					NOTICE! Some items may have expired. Items are only removed when you are fetching or clearing them.
	getCacheData:	Returns the value directly.
	suppressHitCount: Only used for file operations - if passed, we dont bother updating the file based cache with the hit count. Makes the file IO a bit less.
	supressHtmlServerScopeWithIndefiniteTimeout: Default is true. By default, we are not creating a structure saving the metadata for html files unless there is
					a timeout. You can change this default behavior and always create metadata for testing purposes.

	License: 		Uses the Apache2 license.

	When the tag is processed, we output the data at the start of tag execution and create the structure upon completion of template execution.

	Example usage with cfmodule:
	<cfmodule template="../../tags/galaxieCache.cfm" scope="application" cachename="#cacheName#" timeout="#(60*60)#" disabled="#application.disableCache#">
		...Code...
	</cfmodule>
--->

<!--- Either the name or cachename is required. --->
<cfparam name="attributes.name" default="" type="string">
<!--- Cachename is used when using cfmodule --->
<cfparam name="attributes.cachename" default="" type="string">
<!--- Scope is required and can be server, application, session, file or html. Html is by far the fastest if it does not need frequent timeouts. --->
<cfparam name="attributes.scope" default="application" type="string">
<!--- Returns a list of keys in the cache. The tag exits when called. --->
<cfparam name="attributes.getCacheData" default="false" type="boolean">
<!--- The structure may be stored in a file using the WDDX format --->
<cfparam name="attributes.file" default="" type="string">
<!--- The fileType is either: wddx, json or html. --->
<cfparam name="attributes.fileType" default="html" type="string">
<!--- suppressHitCount is turned off by default; however, I am suppressing the hit count when the file type is set to HTML, as keeping it will consume more resources. When using HTML includes and want to increment the hit count, you must supply a timeout in the tag or module. --->
<cfparam name="attributes.suppressHitCount" default="false" type="boolean">
<!--- The default timeout is no timeout, so we use the year 3999. We will have flying cars then. --->
<cfparam name="attributes.timeout" default="#createDate(3999,1,1)#">
<!--- Disabled allows users to automatically exit the tag --->
<cfparam name="attributes.disabled" default="false" type="string">
<!--- Used to clear an item from the cache. Requires the file if the cache is file and the fileType is html --->
<cfparam name="attributes.clear" default="false" type="boolean">
<!--- Used to clear all items from the cache. Requires the cacheDirectory if you want to delete all of the files within a cache directory when using file with the fileType of html --->
<cfparam name="attributes.clearAll" default="false" type="boolean">
<!--- Specify the cacheDirectory if you want to clear the HTML-based file cache. --->
<cfparam name="attributes.cacheDirectory" default="" type="string">
<!--- Debug prints the process on the page --->
<cfparam name="attributes.debug" default="false" type="boolean">
<!--- Allows you to visualize the structure that is created --->
<cfparam name="attributes.dumpStruct" default="false" type="boolean">
<!--- By default, to conserve memory resources on the server, we are not saving the metadata with HTML files when there is an indefinite timeout. You can change this to always create the metadata along with the files, but other than for debugging or a custom solution that requires the metadata, this should be avoided as it consumes extra memory. --->
<cfparam name="attributes.supressHtmlServerScopeWithIndefiniteTimeout" default="true" type="boolean">

<cfif attributes.debug>
	<cfset debug = 1> 
<cfelse>
	<cfset debug = 0> 
</cfif>

<cfif attributes.dumpStruct>
	<cfset dumpStruct = 1> 
<cfelse>
	<cfset dumpStruct = 0> 
</cfif>
	
<cfparam name="supressHTMLServerScope" default="false">

<cfif debug>
	<br/>Debug mode<br/>
	Current time (on server): <cfoutput>#now()#</cfoutput><br/>
</cfif>

<!--- This variable will store all the guys we need to update --->
<cfset cleanup = "">
<!--- This variable determines if we run the caching. This is used when we clear a cache --->
<cfset processCache = true>

<cfif thisTag.executionMode eq "start">
	<!--- ****************************************************************************************************************
		Validation
	******************************************************************************************************************--->

	<!--- allow for quick exit --->
	<cfif attributes.disabled>
		<cfif debug>
			Exiting template<br/>
		</cfif>
		<cfexit method="exitTemplate">
	</cfif>

	<!--- Validation --->
	<!--- Sync the name and cacheName values to allow cachename in case we use cfmodule --->
	<cfif len(attributes.cacheName) and !len(attributes.name)>
		<cfset attributes.name = attributes.cacheName>
	</cfif>

	<!--- Validate the cache name --->
	<cfif !len(attributes.name) or !isSimpleValue(attributes.name)>
		<cfthrow message="galaxieCache: The name or cacheName attribute must be passed as a string.">
	</cfif>

	<!--- Scope is required and must be a valid value. --->
	<cfif !isSimpleValue(attributes.scope) or not listFindNoCase("application,session,server,file,html",attributes.scope)>
		<cfthrow message="galaxieCache: The scope attribute must be passed as one of: server, application, session, html or file.">
	</cfif>

	<!--- Set the timeout value --->
	<cfif not isDate(attributes.timeout) and (not isNumeric(attributes.timeout) or attributes.timeout lt 0)>
		<cfthrow message="galaxieCache: The timeout attribute must be either a date/time or a number.">
	<cfelseif isNumeric(attributes.timeout)>
		<!--- convert seconds to a time --->
		<cfset attributes.timeout = dateAdd("s",attributes.timeout,now())>
		<cfif debug>
			Timeout value is numeric and is set to <cfoutput>#attributes.timeout#</cfoutput><br/>

		</cfif>
	</cfif>

	<!--- Require a file name when the scope is set to html or file --->
	<cfif (attributes.scope eq "html" or attributes.scope eq 'file') and (attributes.file eq "")>
		<cfthrow message="galaxieCache: A file name is required when the scope is html or file.">
	</cfif>

	<!--- Dump the struct for visualization --->
	<cfif debug and dumpStruct and getColdFusionStructScope() neq 'none'>
		<!--- Dump the structure. --->
		<cfset scopeStruct = structGet(getColdFusionStructScope())>
		<cfdump var="#scopeStruct#" label="Current #getColdFusionStructScope()# vars">
	</cfif>

	<!--- ****************************************************************************************************************
		Initial Logic
	******************************************************************************************************************--->
	<cfif debug>
		Begin initial <cfoutput>#attributes.scope#</cfoutput> <cfif attributes.scope eq 'file'>and <cfoutput>#attributes.fileType#</cfoutput></cfif> scope logic for <cfoutput>#attributes.cacheName#</cfoutput><br/>
		Setting pointer to <cfoutput>#getColdFusionStructScope()#</cfoutput> scope<br/>
	</cfif>

	<!--- Determine if the structure needs to be initialized. This is not necessary when the scope is set to file and the fileType is not html as there will be no structure set in an actual ColdFusion scope --->	
	<cfif (getColdFusionStructScope() neq 'none')>  
		<!--- Get the ColdFusion/Lucee native structure --->
		<cfset scopeStruct = structGet(getColdFusionStructScope())>
		<!--- Determine if we should create the cache structure --->
		<cflock scope="#getColdFusionStructScope()#" type="readOnly" timeout="30">
			<cfif structKeyExists(scopeStruct,"galaxieCache")>
				<cfset needInit = false>
			<cfelse>
				<cfset needInit = true>
			</cfif>
		</cflock>
	</cfif>

	<!--- Create a pointer to our structure if it does not exist --->
	<cfif needInit>
		<cfif debug>
			Creating initial galaxieCache structure<br/>
		</cfif>

		<cflock scope="#getColdFusionStructScope()#" type="exclusive" timeout="30">
			<!--- check twice in case another thread finished --->
			<cfif not structKeyExists(scopeStruct,"galaxieCache")>
				<cfset scopeStruct["galaxieCache"] = structNew()>
			</cfif>
		</cflock>
	</cfif><!---<cfif needInit>--->

	<!--- ****************************************************************************************************************
		Pre-Processing and cleanup
	******************************************************************************************************************--->

	<!--- Dump the keys to the caller scope --->
	<cfif structKeyExists(attributes,"getCacheItems") and attributes.getCacheItems>
		<cfset caller[attributes.getCacheItems] = structKeyList(scopeStruct.galaxieCache)>
		<cfexit method="exitTag">
	</cfif>

	<!--- Do they want to nuke it all? --->
	<cfif attributes.clearAll>
		<cfif debug>
			Clearing cache<br/>
		</cfif>

		<!--- When serving static files, delete the files in the cache directory --->
		<cfif len(attributes.cacheDirectory)>
			<cfdirectory action="list" name="clearCacheDirectory" directory="#expandPath(attributes.cacheDirectory)#" recurse="true" />
			<cfloop query="clearCacheDirectory">
				<cfif clearCacheDirectory.type eq "file">
					<cflock name="#attributes.cacheDirectory#" type="exclusive" timeout="30">
						<cffile action="delete" file="#expandPath(attributes.cacheDirectory)##clearCacheDirectory.name#" />
					</cflock>
					<cfif debug> 
						Deleted <cfoutput>#attributes.cacheDirectory##clearCacheDirectory.name#</cfoutput><br/>
					</cfif>
				</cfif>
			</cfloop>
		</cfif><!---<cfif len(attributes.cacheDirectory)>--->

		<!--- Delete all the galaxieCache scopes in memory --->
		<cfset scopes = 'server,application,session'>
		<cfloop list="#scopes#" index="thisScope">
			<!--- Get the structure --->
			<cfset galaxieStruct = structGet(thisScope)>
			<!--- Delete this structure if exists --->
			<cflock scope="#thisScope#" type="readOnly" timeout="30">
				<cfif structKeyExists(galaxieStruct,"galaxieCache")>
					<cfset structDelete(galaxieStruct,"galaxieCache")>
					<cfif debug> 
						Deleted galaxieCache in <cfoutput>#thisScope#</cfoutput> scope<br/>
					</cfif>
				</cfif>
			</cflock>
		</cfloop> 

		<!--- Exit tag --->
		<cfexit method="exitTag">
	</cfif><!---<cfif attributes.clearAll>--->

	<!--- Clear the cache if necessary --->
	<cfif attributes.clear>
		<cfif debug>
			Clearing cache<br/>
		</cfif>

		<!--- Delete the file when we store the structure to the file system. --->
		<cfif debug>
			File exists? <cfoutput>#fileExists(expandPath(attributes.file))#</cfoutput><br/>
		</cfif>
		<cfif fileExists(expandPath(attributes.file))>
			<cfif debug>
				Deleting file<br/>
			</cfif>
			<!--- Delete the file --->
			<cflock name="#attributes.file#" type="exclusive" timeout="30">
				<cffile action="delete" file="#expandPath(attributes.file)#">
			</cflock>
		</cfif>

		<!--- Cleanup the structure. Note: we need to clean up the metadata on the server scope when using static HTML with a timeout. --->
		<cfset structDelete(scopeStruct.galaxieCache,attributes.name)>

		<!--- Exit tag --->
		<cfexit method="exitTag">
	</cfif><!---<cfif attributes.clear>--->

</cfif><!---<cfif thisTag.executionMode eq "start">--->

<!--- ****************************************************************************************************************
	Process the cache
******************************************************************************************************************--->
<!--- Process the cache --->
<cfif processCache>
	<cfif debug>
		Processing cache using <cfoutput>#attributes.scope#</cfoutput> scope<br/>
	</cfif>
	<!--- ****************************************************************************************************************
		Start Execution
	******************************************************************************************************************--->
	<cfif thisTag.executionMode eq "start">
		<cfif debug>
			Execution start<br/>
		</cfif>
		<!--- ******************************************************************
			Process Files
		********************************************************************--->
		<cfif attributes.scope eq "html">

			<!--- ************************* HTML Includes *************************--->
			<!--- Read the metadata in the server scope if it exists. HTML files will be stored in the server scope if there is a specified timeout; otherwise, the files will be stored on the server until manually cleared out. --->

			<!--- For html includes, we are *only* storing data in server scope when there is a timeout. If there is no time out, I will permanently  store the html on the server and it needs to be manually cleaned up when necessary. --->
			<cfif structKeyExists(scopeStruct.galaxieCache, attributes.name) and 
				  structKeyExists(scopeStruct.galaxieCache[attributes.name],"timeout")>
				<cfset htmlIncludeTimeout = scopeStruct.galaxieCache[attributes.name].timeout>
				<cfset indefiniteHtmlTimeout = false>
			<cfelse>
				<!--- Expire it when we have flying cars --->
				<cfset htmlIncludeTimeout = createDate(3999,1,1)>
				<cfset indefiniteHtmlTimeout = true> 
			</cfif>
			<!--- Determine if we should supress saving metadata for HTML files. This is done by default when there is no timeout for HTML files, but the user can change this behavior by changing the supressHtmlServerScopeWithIndefiniteTimeout attributes to false --->
			<cfif attributes.supressHtmlServerScopeWithIndefiniteTimeout and indefiniteHtmlTimeout>
				<cfset supressHTMLServerScope = true>
			</cfif>

			<cfif debug>
				Processing scoped structure<br/>
				<cfif dateCompare(now(),htmlIncludeTimeout) eq -1>
					Cache is valid<br/>
				<cfelse>

					Cache is expired<br/>
				</cfif>
			</cfif>

			<!--- Is the cache fresh? --->
			<cfif dateCompare(now(),htmlIncludeTimeout) eq -1>
				<cfif debug>
					<cfoutput>dateCompare(now(),htmlIncludeTimeout):#dateCompare(now(),htmlIncludeTimeout)#</cfoutput>
					Cache valid and expires at <cfoutput>#htmlIncludeTimeout#</cfoutput><br/>
				</cfif>

				<!--- Does the file currently exist? --->
				<cfif fileExists(expandPath(attributes.file))>
					<cfif debug>
						The file exists<br/>
					</cfif>

					<!--- We have to read the filie if the user wants to get the cached data. --->
					<cfif attributes.getCacheData>
						<cfif debug>
							Reading saved file<br/>
						</cfif>
						<!--- Read the file --->
						<cflock name="#attributes.file#" type="readonly" timeout="30">
							<cffile action="read" file="#expandPath(attributes.file)#" variable="contents" charset="UTF-8">
						</cflock>
						<cfif debug and dumpStruct>
							<cfdump var="#contents#" label="contents">
						</cfif>
						<!--- Send the content back to the client --->
						<cfset caller[attributes.getCacheData] = contents>
					<cfelse><!---<cfif attributes.getCacheData>--->
						<cfif debug>
							Including the file<br/>
						</cfif>
						<!--- Simply include the file --->
						<cfinclude template="#attributes.file#">
					</cfif><!---<cfif attributes.getCacheData>--->

					<!--- Note: when using HTML files, the server may have been restarted which will wipe out the serverCache that holds the metadata for the files. We may need to recreate the cache if it does not already exist. --->
					<cfif !supressHTMLServerScope and !structKeyExists(scopeStruct.galaxieCache, attributes.name)>
						<cfif debug>
							Saving cache metadata to server scope<br/>
						</cfif>

						<!--- Create our structure and store it in the caller scope --->
						<cfset scopeStruct.galaxieCache[attributes.name] = structNew()> 
						<!--- The value for html files is the template path. We only want to store essential metadata when including files --->
						<cfset scopeStruct.galaxieCache[attributes.name].file = attributes.file>
						<cfset scopeStruct.galaxieCache[attributes.name].timeout = attributes.timeout>
						<cfset scopeStruct.galaxieCache[attributes.name].hitCount = 0>
						<cfset scopeStruct.galaxieCache[attributes.name].created = now()>
					</cfif><!---<cfif !supressHTMLServerScope and !structKeyExists(scopeStruct.galaxieCache, attributes.name)>--->

					<cfif !supressHTMLServerScope and !attributes.suppressHitCount>
						<cfif debug>
							Updating hit count<br/>
						</cfif>

						<!--- When using HTML, the hit count is stored in metadata in the server scope. --->
						<cflock scope="server" type="exclusive" timeout="30">
							<!--- Increment the hit count. Note: we need to see if the structure exists. If the server restarted, the structure may have been destroyed. --->
							<cfif structKeyExists(scopeStruct.galaxieCache, attributes.name) and 
								structKeyExists(scopeStruct.galaxieCache[attributes.name],"timeout")>
								<cfset scopeStruct.galaxieCache[attributes.name].hitCount = scopeStruct.galaxieCache[attributes.name].hitCount + 1>
							<cfelse>
								<cfset scopeStruct.galaxieCache[attributes.name].hitCount = 0>
							</cfif>
						</cflock>	
					</cfif><!---<cfif !supressHTMLServerScope and !attributes.suppressHitCount>--->

					<!--- Note: only exit if the file exists and after including the file. Otherwise, no content will be displayed and the file will not initially be saved. --->
					<cfif debug>
						Exiting tag after including file<br/>
					</cfif>
					<cfexit method="exitTag">

				</cfif><!---<cfif fileExists(expandPath(attributes.file))>--->

			</cfif><!---<cfif dateCompare(now(),htmlIncludeTimeout) eq -1>--->
							
		<cfelseif attributes.scope eq 'file'><!---<cfif attributes.scope eq "html">--->

			<!--- Process the structure when it's stored to the file system --->
			<cfif structKeyExists(scopeStruct.galaxieCache[attributes.name],"hitcount")>

				<cfif debug>
					Reading saved file<br/>
				</cfif>

				<!--- Read the saved file if it exists. If it doesn't, we will save it later on --->
				<cfif fileExists(expandPath(attributes.file))>
					<cfif debug>
						File exists<br/>
					</cfif>

					<!--- Read the file in to check metadata --->
					<cflock name="#attributes.file#" type="readonly" timeout="30">	
						<!--- Read the file --->
						<cffile action="read" file="#expandPath(attributes.file)#" variable="contents" charset="UTF-8">
					</cflock>

					<!--- Prepare the data. Make sure to validate the data as the user can change the fileType and it will cause errors if the file is not formatted correctly --->
					<cfif attributes.fileType eq 'wddx' and isWddx(contents)>
						<!--- Convert the WDDX packet to CFML --->
						<cfwddx action="wddx2cfml" input="#contents#" output="data">
					<cfelseif attributes.fileType eq 'json' and isJson(contents)>
						<!--- DeSerialize the JSON --->
						<cfset data = deserializeJSON(contents)>
					</cfif>

					<cfif debug and dumpStruct>
						<cfdump var="#Data#" label="Data">
					</cfif>

					<!--- Output the cache content if the current date is less than the timeout. The timeout key in the structure may not exist if the file can't be read. This may occur when the file has been uploaded to the server and the user changes the fileType again --->
					<cfif dateCompare(now(),data.timeout) is -1> 
						<cfif debug>
							Cache is valid and expires at <cfoutput>#data.timeout#</cfoutput><br/>
						</cfif>
						<cfif attributes.getCacheData>
							<!--- Send the cache data back to the client --->
							<cfset caller[attributes.getCacheData] = data.value>
						<cfelse>
							<cfif debug>
								Outputting contents of file<br/>
							</cfif>
							<!--- Render the data from the file --->
							<cfoutput>#data.value#</cfoutput>
						</cfif>

						<cfif !attributes.suppressHitCount>
							<cfif debug>
								Updating hit count in file<br/>
							</cfif>

							<cflock name="#attributes.file#" type="exclusive" timeout="30">
								<!--- Increment the hit count. Note: I suppress the hitcount when using html --->
								<cfset data.hitCount = data.hitCount + 1>
								<!--- Save the file --->
								<cfif attributes.fileType eq 'wddx'>
									<!--- Convert the CFML packet to WDDX --->
									<cfwddx action="cfml2wddx" input="#data#" output="packet">
								<cfelseif attributes.fileType eq 'json'>
									<!--- Serialize JSON --->
									<cfset packet = serializeJSON(data)>
								</cfif>
								<!--- Save the file --->
								<cflock name="#attributes.file#" type="exclusive" timeout="30">
									<cffile action="write" file="#attributes.file#" mode="755" output="#packet#" charset="UTF-8">	
								</cflock>
							</cflock>
						</cfif><!---<cfif !attributes.suppressHitCount>--->

						<cfif debug>
							Exiting tag after processing file<br/>
						</cfif>
						<cfexit method="exitTag">						
					</cfif><!---<cfif dateCompare(now(),data.timeout) is -1>--->

				</cfif><!---<cfif fileExists(expandPath(attributes.file))>--->

			</cfif><!---<cfif structKeyExists(scopeStruct.galaxieCache[attributes.name],"hitcount")>--->

		<!--- ******************************************************************
			Process Scoped Structure
		********************************************************************--->
		<cfelse><!---<cfif attributes.scope eq "html">--->

			<cfif debug>
				Processing scoped structure<br/>
				<cfif structKeyExists(scopeStruct.galaxieCache,attributes.name) 
					and dateCompare(now(),scopeStruct.galaxieCache[attributes.name].timeout) eq -1>
					Cache is valid<br/>
				<cfelse>
					Cache is expired<br/>
				</cfif>
			</cfif>

			<!--- Is the current date less than the timeout? --->
			<cfif structKeyExists(scopeStruct.galaxieCache,attributes.name) 
				and dateCompare(now(),scopeStruct.galaxieCache[attributes.name].timeout) eq -1>
				<cfif debug>
					Updating hit count<br/>
				</cfif>

				<cflock type="exclusive" timeout="30">
					<!--- Increment the hit count --->
					<cfset scopeStruct.galaxieCache[attributes.name].hitCount = scopeStruct.galaxieCache[attributes.name].hitCount + 1>
				</cflock>	

				<cfif attributes.getCacheData>
					<cfif debug>
						Return the value of the scoped structure to the client<br/>
					</cfif>
					<!--- Return the value back to the client --->
					<cfset caller[attributes.getCacheData] = scopeStruct.galaxieCache[attributes.name].value>
				<cfelse><!---<cfif attributes.getCacheData>--->
					<cfif debug>
						Rendering the value in the scoped structure<br/>
					</cfif>
					<!--- Render the data --->
					<cfoutput>#scopeStruct.galaxieCache[attributes.name].value#</cfoutput>
				</cfif><!---<cfif attributes.getCacheData>--->

				<cfif debug>
					Exiting Tag<br/>
				</cfif>
				<cfexit method="exitTag"> 

			</cfif><!---<cfif dateCompare(now(),scopeStruct.galaxieCache[attributes.name].timeout) is -1>--->
		</cfif><!---<cfif attributes.scope eq "html">--->

	<!--- ****************************************************************************************************************
		End Execution
		Note: this should only execute one time when the structure does not already exist. I am exiting the custom tag if the timeout has not expired 
		in the logic above.
	******************************************************************************************************************--->	
	<cfelse><!---<cfif thisTag.executionMode eq "start">--->

		<cfif debug>
			Execution End<br/>
		</cfif>

		<cfif attributes.scope eq "html">

			<!--- Save data using server scope. --->		
			<cfif debug>
				Saving generated html content to file<br/> 
			</cfif>
			<!--- Write the file --->
			<cftry>
				<cflock name="#attributes.file#" type="exclusive" timeout="30">
					<cffile action="write" file="#expandPath(attributes.file)#" output="#thistag.generatedcontent#" charset="UTF-8">
				</cflock>
				<!--- There may be an error if the directory does not exist --->
				<cfcatch type="any">
					<!--- See of the directory exists --->
					<cfset directoryPath = getDirectoryFromPath(attributes.file)>
					<!--- Create the directory if it does not exist --->
					<cfif not directoryExists(directoryPath)>
						<p>The <cfoutput>#directoryPath#</cfoutput> does not exist. Please create it.</p>
					</cfif>
				</cfcatch>
			</cftry>

			<!--- Also metadata to server scope. Note: by default, html files will only have a galaxieCache key when there is a supplied timeout. --->
			<cfif !supressHTMLServerScope>

				<cfif debug>
					Saving cache metadata to server scope<br/>
				</cfif>

				<!--- Create our structure and store it in the caller scope --->
				<cfset scopeStruct.galaxieCache[attributes.name] = structNew()> 
				<!--- The value for html files is the template path. We only want to store essential metadata when including files --->
				<cfset scopeStruct.galaxieCache[attributes.name].file = attributes.file>
				<cfset scopeStruct.galaxieCache[attributes.name].timeout = attributes.timeout>
				<cfset scopeStruct.galaxieCache[attributes.name].hitCount = 0>
				<cfset scopeStruct.galaxieCache[attributes.name].created = now()>

			</cfif><!---<cfif !supressHTMLServerScope>--->
				
		<cfelseif attributes.scope eq 'file'><!---<cfif attributes.scope eq "html">--->

			<cfif debug>
				Saving cache to file<br/>
			</cfif>
			<!--- Create the structure and save it to a file --->
			<cfset data = structNew()>
			<cfif structKeyExists(attributes, "data")>
				<cfset data.value = attributes.data>
			<cfelse>
				<cfset data.value = thistag.generatedcontent>
			</cfif>
			<cfset data.timeout = attributes.timeout>
			<cfset data.hitCount = 0>
			<cfset data.created = now()>
			<cflock name="#attributes.file#" type="exclusive" timeout="30">
				<cfif attributes.fileType eq 'wddx'>
					<!--- Convert the CFML to WDDX --->
					<cfwddx action="cfml2wddx" input="#data#" output="packet">
				<cfelseif attributes.fileType eq 'json'>
					<!--- Serialize to JSON --->
					<cfset packet = serializeJSON(data)>
				</cfif>
				<!--- Write the file --->
				<cflock name="#attributes.file#" type="exclusive" timeout="30">
					<cffile action="write" file="#expandPath(attributes.file)#" output="#packet#" charset="UTF-8">
				</cflock>
			</cflock>

		<cfelse><!---<cfif attributes.scope eq "html">--->

			<cfif debug>
				Saving cache to <cfoutput>#attributes.scope#</cfoutput> scope<br/>
			</cfif>

			<!--- Create our structure and store it in the caller scope --->
			<cfset scopeStruct.galaxieCache[attributes.name] = structNew()>
			<cfif structKeyExists(attributes, "data")>
				<cfset scopeStruct.galaxieCache[attributes.name].value = attributes.data>
			<cfelse>
				<cfset scopeStruct.galaxieCache[attributes.name].value = thistag.generatedcontent>
			</cfif>
			<cfset scopeStruct.galaxieCache[attributes.name].timeout = attributes.timeout>
			<cfset scopeStruct.galaxieCache[attributes.name].hitCount = 0>
			<cfset scopeStruct.galaxieCache[attributes.name].created = now()>

		</cfif><!---<cfif attributes.scope eq "file" and fileExists(attributes.file)>--->
	</cfif><!---<cfif thisTag.executionMode eq "start">--->
<cfelse><!---<cfif processCache>--->
	<cfif debug>
		Not processing file and exiting tag<br/>
	</cfif>
	<cfexit method="exitTag">
</cfif><!---<cfif processCache>--->

<cffunction name="getColdFusionStructScope" access="private" returntype="string" hint="Determine where the scope is actually stored. If we are using HTML, we will store the structure using the server scope when there is a timeout. If the scope argument is file, we store the structure within a file. Otherwise the structure will be set to the scope arguments which can be server, application, or sesssion.">
	<cfargument name="scope" default="#attributes.scope#" hint="Pass in the attributes.scope value">
	<cfargument name="fileType" default="#attributes.fileType#" hint="Pass in the attributes.fileType value">

	<cfif arguments.scope eq 'html'>
		<!--- When using html includes, we are storing metadata using the server scope --->
		<cfset actualScope = 'server'>
	<cfelseif arguments.scope eq 'file'>
		<!--- Otherwise we are storing the structure in the file system and there is no relevant CF server scope --->
		<cfset actualScope = 'none'>
	<cfelse>
		<!--- If we are not using files, this should either be 'server', 'application', or 'session' --->
		<cfset actualScope = arguments.scope>
	</cfif>
	<!--- Return it --->
	<cfreturn actualScope>
</cffunction>	

<cffunction name="getGalaxieCacheStruct" access="private" returntype="struct">

	<!--- Get the structure from the file system --->
	<cfif getColdFusionStructScope() eq 'file'>
		<!--- Read the file in to check metadata --->
		<cflock name="#attributes.file#" type="readonly" timeout="30">	
			<!--- Read the file --->
			<cffile action="read" file="#expandPath(attributes.file)#" variable="contents" charset="UTF-8">
		</cflock>

		<!--- Prepare the data. Make sure to validate the data as the user can change the fileType and it will cause errors if the file is not formatted correctly --->
		<cfif attributes.fileType eq 'wddx' and isWddx(contents)>
			<!--- Convert the WDDX packet to CFML --->
			<cfwddx action="wddx2cfml" input="#contents#" output="struct">
		<cfelseif attributes.fileType eq 'json' and isJson(contents)>
			<!--- DeSerialize the JSON --->
			<cfset var struct = deserializeJSON(contents)>
		</cfif>
	<cfelse>
		<!--- Get the structure.It may not exist when using HTML with no timeout. --->
		<cfset var struct = structGet(getColdFusionStructScope())>
	</cfif>

	<!--- Return it --->
	<cfreturn struct>
</cffunction>