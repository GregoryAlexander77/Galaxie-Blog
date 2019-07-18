<cfcomponent displayname="CfJson" hint="Cfc to convert ColdFusion objects into proper json objects." name="cfJson">
	
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
			
</cfcomponent>			