<cfcomponent displayname="CfJson" hint="Cfc to convert a cf query into a proper jason javascript object." name="cfJson">
	
    <!--- 
	convertCfQuery2JsonStruct is used for telerik and other jQuery grids. The output is like so:
    {"data":[{"supplieremail":"elizabeth.novick@medtronic.com ","supplieraddress2":"Jacksonville, FL 32216","supplierid":6536,"suppliertyperef":1,"supplierphone":"(415) 518-9505","supplieraddress1":"6743 Southpoint Drive North","suppliername":"Elizabeth Novick","applicationref":"","date":"November, 20 2014 13:33:35","contractor":"Medtronic (for Visualase Products)","isactive":1}]}  
	
	And toJson returns data like so:
	[{"supplieremail":"elizabeth.novick@medtronic.com ","supplieraddress2":"Jacksonville, FL 32216","supplierid":6536,"suppliertyperef":1,"supplierphone":"(415) 518-9505","supplieraddress1":"6743 Southpoint Drive North","suppliername":"Elizabeth Novick","applicationref":"","date":"2014-11-20 13:33:35.947","contractor":"Medtronic (for Visualase Products)","isactive":1}] 
	 
	When using the convertCfQuery2JsonStruct method on the search.cfm page:
	{"data":[{"supplieremail":"eliz@test.com ","supplieraddress2":"Jacksonville, FL 98000","supplierid":6536,"suppliertyperef":1,"supplierphone":"(415) 999-9999","supplieraddress1":"6743 North Dr.","suppliername":"Fred Astair","applicationref":"","date":"November, 20 2014 13:33:35","contractor":"Xray Tech","isactive":1}]} 
	
	Here is an example of how to get the data from the server:
	// Get the notifications from the server
	jQuery.ajax({
		type: 'post', 
		url: '/cssweb/applications/contracts/ajaxCalls.cfc?method=getNotification',
		data: { // method and the arguments
			method: "getNotification",
			dateTime: "hello"
		},
		dataType: "json",
		success: result, // calls the result function.
		
		error: function(ErrorMsg) {
		   console.log('Error' + ErrorMsg);
		}
	});
	
	An individual item can be found like so: alert(result.data[0]['suppliername']); 
	
	Or using a simple loop with the column name of the feild like so:
	for(var i=0; i < result.data.length; i++){
		// Get the data held in the row in the array. 
		alert(result.data[i]['notification'])
	}
	
	A bit more complex is something like this, but you will probably never need it:
	Using a for item key loop:
	function result(result) {
		var item, key;
		for (item in result.data) {
			for (key in result.data[item]) {
				alert(result.data[item][key]);
			}
		}  
	} 
	
	Using a typical for loop with an index:
	function result(result){
		// Loop thru the outer object (data)
		for(var i=0; i < result.data.length; i++){
			// Get the data held in the row in the array. 
			var obj = result.data[i];
			// Create an inner for loop
			for(var key in obj){
				// Set the values. 
				var attrName = key;
				var attrValue = obj[key];
				//your condition goes here then append it if satisfied
				//alert(attrName);
			}
		}
	}
	
	Using a jQuery each function on the inner object:
	function result(result){
		// Loop thru the outer object (data)
		for(var i=0; i < result.data.length; i++){
			var obj = result.data[i];
			// For the inner object, we will use the jQuery each function
			$.each(obj, function( key, value ) {    
				alert(value);
			});
		}
	}
	
	If you are using Ben Nadels toJson function use:
	function result(result){
		// Loop thru the outer object (rows)
		for(var i=0; i < result.length; i++){
			var obj = result[i];
			// For the inner object, we will use the jQuery each function
			$.each(obj, function( key, value ) {    
				alert(value);
			});
		}
	}
	--->
    
    <cffunction name="convertCfQuery2JsonStruct" access="public" output="true" hint="convert a ColdFusion query object into to array of structures returned as a json array.">
    	<cfargument name="queryObj" type="query" required="true">
        <cfargument name="contentType" type="string" required="true">
        <cfargument name="includeDataHandle" type="boolean" required="false" default="true">
        <cfargument name="dataHandleName" type="string" required="false" default="data">
        <cfargument name="includeTotal" type="boolean" required="false" default="false">
        <!--- Optional arguments to over ride the total which is used when the grids use serverside paging. ---> 
        <cfargument name="overRideTotal" type="boolean" required="false" default="false">
        <cfargument name="newTotal" type="any" default="false" hint="On grids that use serverside paging on kendo grids, we need to override the total.">
        <!--- Optional arguments to enable the function to clean up the HTML in the notes column for the grid. Without these arguments, the html which formats the data will also be displayed in the grid. --->
        <cfargument name="removeStringHtmlFormatting" type="boolean" required="false" default="true">
        <!--- Note: if you are trying to clean strings, it will fail if the datatype is anything other than a string. You must also provide the column name that you want to clean. ---> 
        <cfargument name="columnThatContainsHtmlStrings" type="string" required="false" default="">
        <cfargument name="convertColumnNamesToLowerCase" type="boolean" default="false" hint="Because Javascript is case sensitive, you may just want to convert everything to lower case.">

		<cfset var rs = {} /> <!--- implicit structure creation --->
		<cfset rs.results = [] /> <!--- implicit array creation --->
        <!--- Get the columns. ---> 
        <cfset rs.columnList = lCase(listSort(queryObj.columnlist, "text" )) />
        <cfif not convertColumnNamesToLowerCase>
        	<!--- Get the column label, which is the actual name of the column that is not forced into uppercase as the columnList is. Note: the getMeta() function will return a two column array object with the numeric index along with the value. We need to convert this into a list. --->
			<cfset realColumnList = arrayToList(queryObj.getMeta().getcolumnlabels())>
        </cfif>
        
		<!--- Loop over the query object and build a structure of arrays --->
		<cfloop query="queryObj">
        	<!--- Create a temporary structure to hold the data. --->
			<cfset rs.temp = {} />
            <!--- Loop thru the columns. --->
			<cfloop list="#rs.columnList#" index="rs.col">
            	<!--- To remove any formatting and get the string, we will use a Java object to turn an html object into a valid xml doc, and then use xml processing to get to the underlying string. --->
                <cfif convertColumnNamesToLowerCase>
                	<!--- Get the lower cased column name (it was forced into a lower case up above). --->
                    <cfset columnName = rs.col>
        		<cfelse>
                	<!--- Find the index in our realColumnList --->
        			<cfset realColumnNameIndex = listFindNoCase(realColumnList, rs.col)>
                    <!--- Get at the value. ---> 
        			<cfset columnName = listGetAt(realColumnList, realColumnNameIndex)>
                </cfif>                
                <cfset columnValue = queryObj[rs.col][queryObj.currentrow]>
				<cfif removeStringHtmlFormatting>
                	<cfif columnName eq columnThatContainsHtmlStrings>
                    	<cfset firstPass = getStringFromHtml(columnValue)>
                        <!--- We have to do two passes here unfortunately. The first pass returns a string with the em tags, the 2nd pass should clear all formatting. Will revisit this when I have more time.  --->
                        <cfset columnValue = getStringFromHtml(firstPass)>
                    </cfif>
                </cfif>
				<cfset rs.temp[columnName] = columnValue />
			</cfloop>
			<cfset arrayAppend( rs.results, rs.temp ) />
		</cfloop>
        
        <!--- Build the final structure. ---> 
		<cfset rs.data = {} />
        
		<!--- Include the data handle if needed --->
		<cfif includeDataHandle>
			<cfset rs.data[dataHandleName] = rs.results />
		<cfelse>
			<cfset rs.data = rs.results />
		</cfif>
        
        <!--- Return the recordcount. This is needed on certain grids to display the total number of records. --->
        <cfif includeTotal>
        	<cfif overRideTotal>
            	<!--- Note: on virtual grids, when you don't include the total (which other than debugging, is never the case, there will be an error here (can't convert 'total' to a number). If debugging, put some random numeric value here.  --->
            	<cfset rs.data["total"] = newTotal>
            <cfelse>
        		<cfset rs.data["total"] = queryObj.recordcount>
            </cfif>
        </cfif>
        
		<cfreturn serializeJSON(rs.data) />
	</cffunction>
				
	<cffunction name="convertHqlQuery2JsonStruct" access="public">
		<cfargument name="hqlQueryObj" type="array" required="true" hint="Include a variable that contains the HQL data. This should be a HQL query with the mapped column names (ie SELECT new Map (UserId, ...)">
		<cfargument name="includeDataHandle" type="boolean" required="false" default="true" hint="Some libraries and widgets need a data handle in front of the data.">
		<cfargument name="dataHandleName" type="string" required="false" default="data">
		<cfargument name="includeTotal" type="boolean" required="false" default="false">
		<!--- Optional arguments to over ride the total which is used when the grids use serverside paging. ---> 
		<cfargument name="overRideTotal" type="boolean" required="false" default="false">
		<cfargument name="newTotal" type="any" default="false" hint="On grids that use serverside paging on kendo grids, we need to override the total.">
		
		<!---Create the outer structure--->
		<cfset json.data = {} />

		<!--- Include the data handle if needed --->
		<cfif includeDataHandle>
			<cfset json.data[dataHandleName] = hqlQueryObj />
		<cfelse>
			<cfset json.data = hqlQueryObj />
		</cfif>

		<!--- Return the recordcount. This is needed on certain grids to display the total number of records. --->
		<cfif includeTotal>
			<cfif overRideTotal>
				<!--- Note: on virtual grids, when you don't include the total (which other than debugging, is never the case, there will be an error here (can't convert 'total' to a number). If debugging, put some random numeric value here.  --->
				<cfset json.data["total"] = newTotal>
			<cfelse>
				<cfset json.data["total"] = arrayLen(hqlQueryObj) />
			</cfif>
		</cfif>
		<!--- Return it. --->		
		<cfreturn serializeJson(json.data)>
	</cffunction>
    
    <cffunction name="convertQueryRow2JavascriptObj" access="public" output="true" hint="Very similiar to convertCfQuery2JsonStruct, but this function convert a row within a query into a simple javascript object without the square brackets. This is used on the client side when populating the query results into an array that can be manipulated using javascript in order to stuff the array object into forms.">
    	<cfargument name="queryObj" type="query" required="true">
        <cfargument name="rowNumber" type="numeric" required="true" hint="Pass in the row number of the query object in order to create a separate javascript object for the given row">
		
        <!--- Create the implicit structure to hold the results. --->
		<cfset var rs.results = {} />
        <!--- Get the column list in the proper case. Note: I am stuffing the column name into Java dot notation in order to keep the proper casing. --->
		<cfset rs.columnList = arrayToList(queryObj.getMeta().getcolumnlabels()) />
        
		<!--- Loop over the columns. --->
        <cfloop list="#rs.columnList#" index="columnName">
            <!--- Get the value of the selected row. --->
            <cfset columnValue = queryObj[columnName][arguments.rowNumber]>
            <!--- Insert the name value pair into the structure. --->
            <cfset structInsert(rs.results, columnName, columnValue, true) />
        </cfloop>
        
        <!--- Return it.  --->
		<cfreturn serializeJSON(rs.results) />
        
	</cffunction>

	<!--- Based on Ben Nadels function. I changed it a bit, this only returns structure of strings. See ToJavascript on google for the original notes.  --->
    <cffunction name="toJson" access="public" returntype="string" output="false"
    hint="Based on CFJASON {http://jehiah.com/projects/cfjson/}, this converts ColdFusion structures to Javascript Object Notation. Returns a structure of strings. Depracated by my new convertCfQuery2JsonStruct functions. ">
        
        <cfargument name="Data" type="any" required="yes" />
     
        <cfscript>
    
            // Define the local scope.
            var LOCAL = StructNew();
    
            // Create an object to store the output. We are going to use
            // a java string buffer as there may be a large amount of
            // concatination.
            LOCAL.Output = CreateObject( "java", "java.lang.StringBuffer" ).Init();
    
            // Check to see if the data is an array.
            if (IsArray( ARGUMENTS.Data )){
    
                // Loop over the array to encode the items.
                for (LOCAL.Index = 1 ; LOCAL.Index LTE ArrayLen( ARGUMENTS.Data ) ; LOCAL.Index = (LOCAL.Index + 1)){
    
                    // Encode the value at this index. Call the function
                    // recursively as this could be any kind of data.
                    LOCAL.Value = toJson( ARGUMENTS.Data[ LOCAL.Index ] );
    
                    // Check to see if we are appending to a current value.
                    if (LOCAL.Output.Length()){
                        LOCAL.Output.Append( "," );
                    }
    
                    // Append the encoded value.
                    LOCAL.Output.Append( LOCAL.Value );
    
                }
    
                // Return the encoded values in an array notation.
                return( "[" & LOCAL.Output.ToString() & "]" );
    
            // Check to see if we have a structure.
            } else if (IsStruct( ARGUMENTS.Data )){
    
                // Check to see if the structure is empty. If it is, then
                // we don't have to do any more work, just return the
                // empty object notation.
                if (StructIsEmpty( ARGUMENTS.Data )){
                    return( "{}" );
                }
    
                // Get the array of keys in the structure.
                LOCAL.Keys = StructKeyArray( ARGUMENTS.Data );
    
                // Loop over the keys in the structure.
                for (LOCAL.Index = 1 ; LOCAL.Index LTE ArrayLen( LOCAL.Keys ) ; LOCAL.Index = (LOCAL.Index + 1)){
    
                    // Encode the value at this index. Call the function
                    // recursively as this could be any kind of data.
                    LOCAL.Value = toJson( ARGUMENTS.Data[ LOCAL.Keys[LOCAL.Index] ] );
    
                    // Check to see if we are appending to a current value.
                    if (LOCAL.Output.Length()){
                        LOCAL.Output.Append( "," );
                    }
    
                    // Append the encoded value.
                    LOCAL.Output.Append( """" & LCase( LOCAL.Keys[LOCAL.Index] ) & """:" & LOCAL.Value );
    
                }
    
                // Return the encoded values in an object notation.
                return( "{" & LOCAL.Output.ToString() & "}" );
    
            // Check to see if this is some sort of other object.
            } else if (IsObject( ARGUMENTS.Data )){
    
                // We found an object that is not a built in type...
                // return an unknown type.
                return( "unknown-obj" );
    
            // Check to see if we have a simple, numeric value.
            } else if (IsSimpleValue( ARGUMENTS.Data ) AND IsNumeric( ARGUMENTS.Data )){
    
                // Return the number as a string.
                return( ToString( ARGUMENTS.Data ) );
    
            // Check to see if we have a simple value.
            } else if (IsSimpleValue( ARGUMENTS.Data )){
    
                // Return the value encoded for Javascript.
                return( """" & JSStringFormat( ToString( ARGUMENTS.Data ) ) & """" );
    
            // Check to see if we have a query.
            } else if (IsQuery( ARGUMENTS.Data )){
    
                // We are going to convert the query into an array or
                // structures. This is going to be somewhat slower than
                // going straight from the query to javascript, but I
                // think it will make the query more usable.
    
                // Start by getting an array of the columns.
                LOCAL.Columns = ListToArray( ARGUMENTS.Data.ColumnList );
    
                // Create an array for the value.
                LOCAL.TempData = ArrayNew( 1 );
    
                // Loop over the rows in the query to create structures.
                for (LOCAL.RowIndex = 1 ; LOCAL.RowIndex LTE ARGUMENTS.Data.RecordCount ; LOCAL.RowIndex = (LOCAL.RowIndex + 1)){
    
                    // Create a structure for the current row.
                    LOCAL.TempRow = StructNew();
    
                    // Loop over the columns to add values to the strucutre.
                    for (LOCAL.Column = 1 ; LOCAL.Column LTE ArrayLen( LOCAL.Columns ) ; LOCAL.Column = (LOCAL.Column + 1)){
    
                        // Add the column value to the structure.
                        LOCAL.TempRow[ LOCAL.Columns[ LOCAL.Column ] ] = ARGUMENTS.Data[ LOCAL.Columns[ LOCAL.Column ] ][ LOCAL.RowIndex ];
    
                    }
    
                    // Append the structure to the data array.
                    ArrayAppend( LOCAL.TempData, LOCAL.TempRow );
    
                }
    
                // ASSERT: At this point, we have converted the query
                // into array of structs. Now encode it.
    
                // No need to return with object notation since the JS
                // encoding of the array will take care of that for us.
                return( toJson( LOCAL.TempData ) );
    
            // Check for default case.
            } else {
    
                // If we got this far, then we found a type that we
                // are not able to serialize.
                return( "unknown" );
    
            }
    
        </cfscript>
        
    </cffunction>
    
     <!---  *********************************************************************** Helper functions ***********************************************************************--->
    <cfscript>
    /**
		* @hint Parses HTML for strings, and returns the string into a 'clean' xml string. In order to accomplish this, we are going to use a Java object, tagSoup, to take a string and to format it into proper xml. Once the string is converted, we will use a native coldfusion xml search function to eliminate formatting on the string. This is done in c style syntax to make it easier to work with Java (Java does not use tag based arguments).It returns a simple string.
		* @arg1 htmlContent 
	*/
	// I take an HTML string and parse it into an XML(XHTML)
	// document. This is returned as a standard ColdFusion XML
	// document.
	function htmlParse( htmlContent, disableNamespaces = true ){
		if ( len(htmlContent) gt 0 ){

			// Create an instance of the Xalan SAX2DOM Java class as the
			// recipient of the TagSoup SAX (Simple API for XML) compliant
			// events. TagSoup will parse the HTML and announce events as
			// it encounters various HTML nodes. The SAX2DOM instance will
			// listen for such events and construct a DOM tree in response.
			var saxDomBuilder = createObject( "java", "com.sun.org.apache.xalan.internal.xsltc.trax.SAX2DOM" ).init(javacast("boolean", true));
	
			// Create our TagSoup parser.
			var tagSoupParser = createObject( "java", "org.ccil.cowan.tagsoup.Parser" ).init(javacast("boolean", true));
	
			// Check to see if namespaces are going to be disabled in the
			// parser. If so, then they will not be added to elements.
			if (disableNamespaces){
	
				// Turn off namespaces - they are lame an nobody likes
				// to perform xmlSearch() methods with them in place.
				tagSoupParser.setFeature(
					tagSoupParser.namespacesFeature,
					javaCast( "boolean", false )
				);
			}
	
			// Set our DOM builder to be the listener for SAX-based
			// parsing events on our HTML.
			tagSoupParser.setContentHandler( saxDomBuilder );
	
			// Create our content input. The InputSource encapsulates the
			// means by which the content is read.
			var inputSource = createObject( "java", "org.xml.sax.InputSource" ).init(
				createObject( "java", "java.io.StringReader" ).init( htmlContent )
			);
	
			// Parse the HTML. This will trigger events which the SAX2DOM
			// builder will translate into a DOM tree.
			tagSoupParser.parse( inputSource );
	
			// Now that the HTML has been parsed, we have to get a
			// representation that is similar to the XML document that
			// ColdFusion users are used to having. Let's search for the
			// ROOT document and return is.
			
			value = xmlSearch( saxDomBuilder.getDom(), "/node()" )[ 1 ];
		} else {
			value = '';
		}
		return(value);
		
	}

	function getStringFromHtml(htmlContent){
		/**
		* @hint Parses HTML for strings, and returns the string into a 'clean' xml string.
		* @arg1 htmlConent 
		*/

		if ( len(htmlContent) gt 0 ){
			// Parse the HTML into a valid XML document.
			xhtml = htmlParse( htmlContent );
			// Now that we have a proper xhtml document, we will use ColdFusions native xml search method to extract the innner text.
		
			// Extract the entire string from the notes section and get rid of all other formatting tags.
			cleanedString = xmlSearch( xhtml, "/html/string()" );
		} else {
			cleanedString = '';
		}
		return(cleanedString);
	}
	</cfscript>
			
	<!--- This makes a json string more readable. It is used to display the JSON-LD. This was found at http://chads-tech-blog.blogspot.com/2016/10/format-json-string-in-coldfusion.html --->
	<cffunction name="formatJson" hint="Indents JSON to make it more readable">
		<cfargument name="JSONString" default="" hint="JSON string to be formatted">
		<cfargument name="indentCharacters" default="#Chr(9)#" hint="Character(s) to use for indention">

		<cfset local.inQuotes = false>
		<cfset local.indent = 0>
		<cfset local.returnString = "">
		<cfset local.stringLength = Len(arguments.JSONString)>
		<cfloop index="i" from="1" to="#local.stringLength#">
			<cfset local.currChar = Mid(arguments.JSONString, i, 1)>
			<cfif i lt local.stringLength - 1>
				<cfset local.nextChar = Mid(arguments.JSONString, i + 1, 1)>
			<cfelse>
				<cfset local.nextChar = "">
			</cfif>
			<cfif local.currChar eq '"'>
				<cfset local.inQuotes = !local.inQuotes>
			</cfif>
			<cfif local.inQuotes>
				<cfset local.returnString = local.returnString & local.currChar>
			<cfelse>
				<cfswitch expression="#local.currChar#">
					<cfcase value="{">
						<cfset local.indent = local.indent + 1>
						<cfset local.returnString = local.returnString & "{" & chr(10) & chr(13) & RepeatString(arguments.indentCharacters, local.indent)>
					</cfcase>
					<cfcase value="}">
						<cfset local.indent = local.indent - 1>
						<cfset local.returnString = local.returnString & chr(10) & chr(13) & RepeatString(arguments.indentCharacters, local.indent) & "}">
						<cfif local.nextChar neq ",">
							<cfset local.returnString = local.returnString & chr(10) & chr(13)>
						</cfif>
					</cfcase>
					<cfcase value="," delimiters="Chr(0)">
						<cfset local.returnString = local.returnString & "," & chr(10) & chr(13) & RepeatString(arguments.indentCharacters, local.indent)>
					</cfcase>
					<cfcase value=":">
						<cfif local.nextChar neq " ">
							<cfset local.returnString = local.returnString & ": ">
						</cfif>
					</cfcase>
					<cfdefaultcase>
						<cfset local.returnString = local.returnString & local.currChar>
					</cfdefaultcase>
				</cfswitch>
			</cfif>
		</cfloop>

		<cfreturn trim(local.returnString)>
	</cffunction>


</cfcomponent>
