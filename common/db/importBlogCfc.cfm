<cfset ORMReload()>
	
<!---SELECT * FROM BLOG
SELECT * FROM BLOGOPTION
SELECT * FROM CATEGORY
SELECT * FROM COMMENT
SELECT * FROM CustomTemplate
SELECT * FROM Font
SELECT * FROM Post
SELECT * FROM MEDIA
SELECT * FROM POSTCATEGORYLOOKUP
SELECT * FROM RELATEDPOST
SELECT * FROM ROLE
SELECT * FROM SEARCHQUERY
SELECT * FROM SUBSCRIBER
SELECT * FROM THEME
SELECT * FROM THEMESETTING
SELECT * FROM USERROLE
SELECT * FROM USERS--->
	
<!---New table media type
Image - FancyBox
Image - Facebook
Image - Google 16x9
Image - Google 4x3
Image - Google 1x1
Image - Static
Image - Twitter
Image - Video Cover
Scene - Greensock
Scene - Parallax
Video - Large
Video - Medium
Video - Small
Video - Vimeo URL
Video - YouTube URL
	
fancyBox
facebook
google16_9
google4_3
google1_1
static
twitter
videoCover
greensock
parallax
largeVideo
mediumVideo
smallVideo
vimeo
youTube

Fancy box images
Facebook sharing Images
Google sharing images
Google share image
Google share image
Static image
Twitter image
Image that covers a video
A greensock animated scene
A greensock parallax scene
Large format video
Medium Format video
Small video format
An external link to vimeo
An external link to YouTube--->

<!--- Also include my original themes function (this will go away soon once we have the new DB.) --->
<cfinclude template="#application.baseUrl#/common/function/displayAndTheme.cfm">
	
<!--- Common properties --->
<cfset FontRefObj = entityLoadByPK("Font", 1)>
	
<!---
If you have any errors, you can delete and reseed like so:
delete from theme;
DBCC CHECKIDENT ('[theme]', RESEED, 0);

Also, make sure that you delete all of the rows of a table if you change the database structure, otherwise, you will have DDL errors.
--->
	
<!---
Helpful scripts
select name 'ForeignKeyName', 
    OBJECT_NAME(referenced_object_id) 'RefrencedTable',
    OBJECT_NAME(parent_object_id) 'ParentTable'
from sys.foreign_keys
where referenced_object_id = OBJECT_ID('ThemeSetting') or 
    parent_object_id = OBJECT_ID('ThemeSetting')

ALTER TABLE ThemeSetting DROP FK_s2pjsumqgjmv2dy1tbl5rxyey
ALTER TABLE ThemeSetting DROP FK_6yh5m0facp8iqw99pxymgijfm

Remove all relationships from the database. This is helpful if you just want to delete everything and start over again
SELECT 'ALTER TABLE ' + Table_Name  +' DROP CONSTRAINT ' + Constraint_Name
FROM Information_Schema.CONSTRAINT_TABLE_USAGE

Note: if there is an error 'Error in executing the DDL.
[Macromedia][SQLServer JDBC Driver][SQLServer]The ALTER TABLE statement conflicted with the FOREIGN KEY constraint "FK_a980g2vsyna1y3c6hbucv2axi". The conflict occurred in database "gregorysBlog", table "dbo.Post", column 'PostId'.' and you can't delete or even find the constraint, delete all of the contents of the table that is throwing the error, or the table that has a reference to that table. This is a wierd SQL Server error that is generated. The constraint is not a real constraint in the database, but an invisible constainst that is thrown as the new constraaint in memory cannot be applied as there is existing data in the table that would violate the new constraint. To get rid of this invisible constraint, delete all of the records, all of the references, and finally delete the tables if necessary, and then rebuild the table structure without populating any of the records.

See https://stackoverflow.com/questions/12624345/invisible-foreign-key-in-sql-server-2005

A more comprehensive script:
select table_view,
    object_type, 
    constraint_type,
    constraint_name,
    details
from (
    select schema_name(t.schema_id) + '.' + t.[name] as table_view, 
        case when t.[type] = 'U' then 'Table'
            when t.[type] = 'V' then 'View'
            end as [object_type],
        case when c.[type] = 'PK' then 'Primary key'
            when c.[type] = 'UQ' then 'Unique constraint'
            when i.[type] = 1 then 'Unique clustered index'
            when i.type = 2 then 'Unique index'
            end as constraint_type, 
        isnull(c.[name], i.[name]) as constraint_name,
        substring(column_names, 1, len(column_names)-1) as [details]
    from sys.objects t
        left outer join sys.indexes i
            on t.object_id = i.object_id
        left outer join sys.key_constraints c
            on i.object_id = c.parent_object_id 
            and i.index_id = c.unique_index_id
       cross apply (select col.[name] + ', '
                        from sys.index_columns ic
                            inner join sys.columns col
                                on ic.object_id = col.object_id
                                and ic.column_id = col.column_id
                        where ic.object_id = t.object_id
                            and ic.index_id = i.index_id
                                order by col.column_id
                                for xml path ('') ) D (column_names)
    where is_unique = 1
    and t.is_ms_shipped <> 1
    union all 
    select schema_name(fk_tab.schema_id) + '.' + fk_tab.name as foreign_table,
        'Table',
        'Foreign key',
        fk.name as fk_constraint_name,
        schema_name(pk_tab.schema_id) + '.' + pk_tab.name
    from sys.foreign_keys fk
        inner join sys.tables fk_tab
            on fk_tab.object_id = fk.parent_object_id
        inner join sys.tables pk_tab
            on pk_tab.object_id = fk.referenced_object_id
        inner join sys.foreign_key_columns fk_cols
            on fk_cols.constraint_object_id = fk.object_id
    union all
    select schema_name(t.schema_id) + '.' + t.[name],
        'Table',
        'Check constraint',
        con.[name] as constraint_name,
        con.[definition]
    from sys.check_constraints con
        left outer join sys.objects t
            on con.parent_object_id = t.object_id
        left outer join sys.all_columns col
            on con.parent_column_id = col.column_id
            and con.parent_object_id = col.object_id
    union all
    select schema_name(t.schema_id) + '.' + t.[name],
        'Table',
        'Default constraint',
        con.[name],
        col.[name] + ' = ' + con.[definition]
    from sys.default_constraints con
        left outer join sys.objects t
            on con.parent_object_id = t.object_id
        left outer join sys.all_columns col
            on con.parent_column_id = col.column_id
            and con.parent_object_id = col.object_id) a
order by constraint_name, table_view, constraint_type 
--->

<!--- **********************************************************************************************
Import the Change Log Type. We'll use this to indicate what processes were successfully, or unsuccessfully done. 
*************************************************************************************************--->
	
<cfset changeLogTypeList = "Initial Blog Setup,Initial Blog Failure,Initial Blog Installed,New Version Installation,New Version Failure,New Version Installed,ORM Setup,ORM Setup Complete,Database Table Setup, Database Table Failure,Database Table Created">
	
<cfloop list="#changeLogTypeList#" index="i">
	<!--- Use a transaction --->
	<cftransaction>
		<!--- Load the entity. --->
		<cfset ChangeLogTypeDbObj = entityNew("ChangeLogType")>
		<!--- Set the values --->
		<cfset ChangeLogTypeDbObj.setChangeLogType(i)>
		<cfset ChangeLogTypeDbObj.setDate(now())>
		<!--- Save it. Note: updates will automatically occur on persisted objects if the object notices any change. We don't  have to use entity save after the Entity has been loaded and saved. --->
		<cfset EntitySave(ChangeLogTypeDbObj)>
	</cftransaction>
</cfloop>

<!--- **********************************************************************************************
Import the Blog. 
*************************************************************************************************--->

<!--- Get the data for the blog from the ini file --->
<cfset datasource = getProfileString("#application.iniFile#", "default", "dsn")>
<cfset blogName = application.blog.getProperty("blogTitle")>
<cfset blogDesc = application.blog.getProperty("blogDescription")>
<cfset blogUrl = application.blog.getProperty("blogUrl")>
<cfset parentSiteName = getProfileString("#application.iniFile#", "default", "parentSiteName")>
<cfset parentSiteUrl = getProfileString("#application.iniFile#", "default", "parentSiteLink")>
<cfset blogMetaKeywords = getProfileString("#application.iniFile#", "default", "blogKeywords")>	
<cfset locale = application.blog.getProperty("locale")>
<cfset offset = getProfileString("#application.iniFile#", "default", "offset")>
<cfset dsn = application.blog.getProperty("dsn")>
<cfset databaseType = application.blog.getProperty("blogDBType")>
<cfset dsnUserName = application.blog.getProperty("username")>
<cfset dsnPassword = application.blog.getProperty("password")>
<cfset mailServer = application.blog.getProperty("mailserver")>
<cfset mailServerUserName = application.blog.getProperty("mailusername")>
<cfset mailServerPassword = application.blog.getProperty("mailpassword")>
<cfset blogEmail = application.blog.getProperty("owneremail")>
<cfset failTo = getProfileString("#application.iniFile#", "default", "failTo")>
<cfset moderate = getProfileString("#application.iniFile#", "default", "moderate")>
<cfset ipblocklist = getProfileString("#application.iniFile#", "default", "ipblocklist")>
<cfset usecaptcha = getProfileString("#application.iniFile#", "default", "usecaptcha")>
<cfset allowgravatars = getProfileString("#application.iniFile#", "default", "allowgravatars")>
<cfset saltalgorithm = getProfileString("#application.iniFile#", "default", "saltalgorithm")>
<cfset saltkeysize = getProfileString("#application.iniFile#", "default", "saltkeysize")> 
<cfset hashalgorithm = getProfileString("#application.iniFile#", "default", "hashalgorithm")> 
<cfset encryptionPhrase = getProfileString("#application.iniFile#", "default", "encryptionPhrase")> 
<cfset blogVersion = application.blog.getVersion()>
<cfset blogVersionName = application.blog.getVersionName()>
	
<!--- Populate the Blog table --->
<!--- Use a transaction --->
<cftransaction>
	<!--- Load the entity. --->
	<!---<cfset BlogDbObj = entityNew("Blog")>--->
	<cfset BlogDbObj = entityLoadByPK("Blog", 1)>
	<!--- Use the entity objects to set the data. --->
	<cfset BlogDbObj.setBlogName(blogName)>
	<cfset BlogDbObj.setBlogTitle(blogName)>
	<cfset BlogDbObj.setBlogUrl(blogUrl)>
	<cfset BlogDbObj.setBlogDescription(blogDesc)>
	<cfset BlogDbObj.setBlogParentSiteName(parentSiteName)>
	<cfset BlogDbObj.setBlogParentSiteUrl(parentSiteUrl)>
	<cfset BlogDbObj.setBlogMetaKeywords(blogMetaKeywords)>
	<cfset BlogDbObj.setBlogLocale(locale)>
	<cfset BlogDbObj.setBlogServerTimeZoneOffset(offset)>
	<cfset BlogDbObj.setBlogDsn(dsn)>
	<cfset BlogDbObj.setBlogDatabaseType(databaseType)>
	<cfset BlogDbObj.setBlogDsnUserName(dsnUserName)>
	<cfset BlogDbObj.setBlogDsnPassword(dsnPassword)>
	<cfset BlogDbObj.setBlogMailServer(mailServer)>
	<cfset BlogDbObj.setBlogMailServerUserName(mailServerUserName)>
	<cfset BlogDbObj.setBlogMailServerPassword(mailServerPassword)>
	<cfset BlogDbObj.setBlogEmail(blogEmail)>
	<cfset BlogDbObj.setBlogEmailFailToAddress(failTo)>
	<cfset BlogDbObj.setIpBlockList(ipblocklist)>
	<cfset BlogDbObj.setEntriesPerBlogPage(10)>
	<cfset BlogDbObj.setBlogModerated(moderate)>
	<cfset BlogDbObj.setUseCaptcha(usecaptcha)>
	<cfset BlogDbObj.setAllowGravatar(allowgravatars)>
	<cfset BlogDbObj.setSaltAlgorithm(saltalgorithm)>
	<cfset BlogDbObj.setSaltAlgorithmSize(saltkeysize)>
	<cfset BlogDbObj.setHashAlgorithm(hashalgorithm)>
	<cfset BlogDbObj.setServiceKeyEncryptionPhrase(encryptionPhrase)>
	<cfset BlogDbObj.setBlogFontSize(application.BlogFontSize)>
	<cfset BlogDbObj.setBlogVersion(blogVersion)>
	<cfset BlogDbObj.setBlogVersionName(blogVersionName)>
	<cfset BlogDbObj.setIsProd(true)>	
	<cfset BlogDbObj.setBlogInstalled(true)>
	<cfset BlogDbObj.setBlogInstallDate(now())>

	<!--- Save it. Note: updates will automatically occur on persisted objects if the object notices any change. We don't  have to use entity save after the Entity has been loaded and saved. --->
	<cfset EntitySave(BlogDbObj)>
	
</cftransaction>
		
<!--- **********************************************************************************************
The Blog UI Sttings don't  exist yet. its a new table.
*************************************************************************************************--->
	
	
<!--- **********************************************************************************************
Blog Option table. 
*************************************************************************************************--->
		
<!---<cfquery name="reset">
	DELETE FROM BlogOption;
	DBCC CHECKIDENT ('[BlogOption]', RESEED, 0);
</cfquery>--->

<!--- Important note: these values should be blank in the distrubution version! --->
<!--- Populate the Blog table --->
<!--- Use a transaction --->
<cftransaction>
	<!--- Load the blog table and get the first record (there only should be one record). This will pass back an object with the value of the blogId. --->
	<cfset BlogRef = entityLoadByPK("Blog", 1)>
	<!--- Load the entity. --->
	<!---<cfset BlogOptionDbObj = entityNew("BlogOption")>--->
	<cfset BlogOptionDbObj = entityLoadByPK("BlogOption", 1)>
	<!--- Use the entity objects to set the data. --->
	<cfset BlogOptionDbObj.setBlogRef(blogRef)>
	<cfset BlogOptionDbObj.setKendoCommercial(false)>
	<cfset BlogOptionDbObj.setIncludeGsap(application.includeGsap)>
	<cfset BlogOptionDbObj.setIncludeDisqus(application.includeDisqus )>
	<cfset BlogOptionDbObj.setDeferScriptsAndCss(application.deferScriptsAndCss)>
	<cfset BlogOptionDbObj.setUseSsl(true)>
	<cfset BlogOptionDbObj.setServerRewriteRuleInPlace(false)>
	<cfset BlogOptionDbObj.setMinimizeCode(true)>
	<cfset BlogOptionDbObj.setDisableCache(false)>
	<cfset BlogOptionDbObj.setDefaultMediaPlayer("Plyr")>
	<cfset BlogOptionDbObj.setBackgroundImageResolution("lowRes")>
	<cfset BlogOptionDbObj.setAddThisApiKey(application.addThisApiKey)>
	<cfset BlogOptionDbObj.setAddThisToolboxString(application.addThisToolboxString)>
	<cfset BlogOptionDbObj.setDisqusBlogIdentifier(application.disqusBlogIdentifier)>
	<cfset BlogOptionDbObj.setDisqusApiKey(application.disqusApiKey)>
	<cfset BlogOptionDbObj.setDisqusApiSecret(application.disqusApiSecret)>
	<cfset BlogOptionDbObj.setDisqusAuthTokenKey(application.disqusAuthTokenKey)>
	<cfset BlogOptionDbObj.setFacebookAppId(application.facebookAppId)>
	<cfset BlogOptionDbObj.setTwitterAppId(application.twitterAppId)>	
	<cfset BlogOptionDbObj.setDate(now())>

	<!--- Save it. Note: updates will automatically occur on persisted objects if the object notices any change. We don't  have to use entity save after the Entity has been loaded and saved. --->
	<cfset EntitySave(BlogOptionDbObj)>
	
</cftransaction>
		
<!--- **********************************************************************************************
Custom Template table. 
*************************************************************************************************--->
	
<!---<cfquery name="reset">
DELETE FROM CustomTemplate;
DBCC CHECKIDENT ('[CustomTemplate]', RESEED, 0);
</cfquery>--->
		
<cfset customHeadTemplate = application.themeSettingsArray[1][30]>
	
<!--- Important note: these values should be blank in the distrubution version! --->
<!--- Populate the Blog table --->
<!--- Use a transaction --->
<cftransaction>
	<!--- Load the blog table and get the first record (there only should be one record). This will pass back an object with the value of the blogId. --->
	<cfset BlogRef = entityLoadByPK("Blog", 1)>
	
	<!--- Note: we are removing the custom templates from using a theme. The custom templates are now universal and not dependent upon a single theme. --->
	<cfset customCoreLogicTemplate = application.themeSettingsArray[1][29]>
	<cfset customHeadTemplate = application.themeSettingsArray[1][30]>
	<cfset customBodyString = application.themeSettingsArray[1][31]>
	<cfset customFontCssTemplate = application.themeSettingsArray[1][32]>
	<cfset customGlobalAndBodyCssTemplate = application.themeSettingsArray[1][33]>
	<cfset customTopMenuCssTemplate = application.themeSettingsArray[1][34]>
	<cfset customTopMenuHtmlTemplate = application.themeSettingsArray[1][35]>
	<cfset customTopMenuJsTemplate = application.themeSettingsArray[1][36]>
	<cfset customBlogContentCssTemplate = application.themeSettingsArray[1][37]>
	<cfset customBlogJsContentTemplate = application.themeSettingsArray[1][38]>
	<cfset customBlogContentHtmlTemplate = application.themeSettingsArray[1][39]>
	<cfset customFooterHtmlTemplate = application.themeSettingsArray[1][40]>
		
	<!--- Load the entity. --->
	<cfset CustomTemplateDbObj = entityNew("CustomTemplate")>
	<!--- Use the entity objects to set the data. --->
	<cfset CustomTemplateDbObj.setBlogRef(blogRef)>
	<cfset CustomTemplateDbObj.setCoreLogicTemplate(customCoreLogicTemplate)>
	<cfset CustomTemplateDbObj.setHeaderTemplate(customHeadTemplate)>
	<cfset CustomTemplateDbObj.setBodyString(customBodyString)>
	<cfset CustomTemplateDbObj.setFontTemplate(customFontCssTemplate)>
	<cfset CustomTemplateDbObj.setCssTemplate(customGlobalAndBodyCssTemplate)>
	<cfset CustomTemplateDbObj.setTopMenuHtmlTemplate(customTopMenuHtmlTemplate)>
	<cfset CustomTemplateDbObj.setTopMenuJsTemplate(customTopMenuJsTemplate)>
	<cfset CustomTemplateDbObj.setBlogCssTemplate(customBlogContentCssTemplate)>
	<cfset CustomTemplateDbObj.setBlogJsTemplate(customBlogJsContentTemplate)>
	<cfset CustomTemplateDbObj.setBlogHtmlTemplate(customBlogContentHtmlTemplate)>
	<cfset CustomTemplateDbObj.setFooterHtmlTemplate(customFooterHtmlTemplate)>	
	<cfset CustomTemplateDbObj.setDate(now())>

	<!---<cfset EntitySave(CustomTemplateDbObj)>--->
	
</cftransaction>
		
<!--- **********************************************************************************************
Category table. We will populate the categories from the original BlogCfc database. 
*************************************************************************************************--->
		
<!---<cfquery name="reset">
DELETE FROM Category;
DBCC CHECKIDENT ('[Category]', RESEED, 0);
</cfquery>--->
	
<!--- Get the categories from BlogCfc --->
<cfquery name="getTblBlogCategories" datasource="#dsn#">
	SELECT 
	categoryid
    ,categoryname
    ,categoryalias
    ,blog
	FROM tblblogcategories
</cfquery>
	
<cfoutput query="getTblBlogCategories">
	<!--- Populate the Category table --->
	<!--- Use a transaction --->
	<cftransaction>
		<!--- Load the blog table and get the first record (there only should be one record). This will pass back an object with the value of the blogId. --->
		<cfset BlogRef = entityLoadByPK("Blog", 1)>
		<!--- Load the entity. --->
		<cfset CategoryDbObj = entityNew("Category")>
		<!--- Use the entity objects to set the data. --->
		<cfset CategoryDbObj.setBlogRef(blogRef)>
		<cfset CategoryDbObj.setCategoryUuid(categoryid)>
		<cfset CategoryDbObj.setCategoryAlias(categoryalias)>
		<cfset CategoryDbObj.setCategory(categoryname)>
		<cfset CategoryDbObj.setDate(now())>

		<!--- Save it. Note: updates will automatically occur on persisted objects if the object notices any change. We don't  have to use entity save after the Entity has been loaded and saved. --->
		<!---<cfset EntitySave(CategoryDbObj)>--->
	</cftransaction>
</cfoutput>
			
<!--- **********************************************************************************************
Populate the Users table. We are no longer going in alpabetic order here as several tables are dependent on other tables.
*************************************************************************************************--->
			
<!---<cfquery name="reset">
DELETE FROM Users;
DBCC CHECKIDENT ('[Users]', RESEED, 0);
</cfquery>--->

<!--- Get the Users from BlogCfc --->
<cfquery name="getTblBlogUsers" datasource="#dsn#">
	SELECT username
	,password
	,salt
	,name
	,blog
	FROM tblusers
</cfquery>

<cfoutput query="getTblBlogUsers">
	<!--- Populate the Category table --->
	<!--- Use a transaction --->
	<cftransaction>
		<!--- Load the blog table and get the first record (there only should be one record at this time). This will pass back an object with the value of the blogId. This is needed as the setBlogRef is a foreign key and for some odd reason ColdFusion or Hybernate must have an object passed as a reference instead of a hardcoded value. --->
		<cfset BlogRef = entityLoadByPK("Blog", 1)>
		<!--- Load the entity. --->
		<cfset UserDbObj = entityNew("Users")>
		<!--- Use the entity objects to set the data. --->
		<cfset UserDbObj.setBlogRef(blogRef)>
		<cfset UserDbObj.setFirstName("")>
		<cfset UserDbObj.setLastName("")>
		<cfset UserDbObj.setFullName(name)>	
		<cfset UserDbObj.setEmail(blogEmail)>
		<cfset UserDbObj.setWebsite("")>
		<cfset UserDbObj.setUserName(username)>
		<cfset UserDbObj.setPassword(password)>
		<cfset UserDbObj.setSalt(salt)>
		<cfset UserDbObj.setLastLogin("")>
		<cfset UserDbObj.setActive(true)>
		<cfset UserDbObj.setDate(now())>

		<!--- Save it. Note: updates will automatically occur on persisted objects if the object notices any change. We don't  have to use entity save after the Entity has been loaded and saved. --->
		<!---<cfset EntitySave(UserDbObj)>--->
	</cftransaction>
</cfoutput>
			
<!--- **********************************************************************************************
Populate the Role table. 
*************************************************************************************************--->
			
<!---<cfquery name="reset">
DELETE FROM Role;
DBCC CHECKIDENT ('[Role]', RESEED, 0);
</cfquery>--->

<!--- Get the Users from BlogCfc --->
<cfquery name="getTblBlogRoles" datasource="#dsn#">
	SELECT  
	id
    ,role
    ,description
  	FROM tblblogroles
</cfquery>
			
<!--- Note, we have different roles than BlogCfc. --->
<!--- Create lists of the new role and description --->
<cfset newRoles = "Administrator,SuperUser,Editor,Author,Designer,Moderator,Subscriber,Guest">
<cfset newRoleDescriptions = "All functionality., Can do everything other than set server and database settings.,Can edit and make posts. Can also adjust categories and related posts.,Can create and edit their own posts.,Can edit theme settings. Can also add images to posts.,Can edit or remove comments and ban subscribers and guests.,Can upload photos in their own comments and edit their own profile. Can also preview site functionality., Can view posts and make comments. May not upload any media attached to their comments.">		

<!--- Use a transaction --->
<cftransaction>
	<cfparam name"newRoleLoopCount" default="0">
	<cfloop list="#newRoles#" index="role">

		<!--- Load the entity. --->
		<!---<cfset RoleDbObj = entityNew("Role")>--->
		<cfset RoleDbObj = entityLoad("Role", { Role = role }, "true" )>
		<!--- Use the entity objects to set the data. --->
		<cfset RoleDbObj.setBlogRef(blogRef)>
		<cfset RoleDbObj.setRoleUuid(id)>
		<cfset RoleDbObj.setRoleName(role)>
		<cfset RoleDbObj.setDescription(listGetAt(newRoleDescriptions, newRoleLoopCount))>
		<cfset RoleDbObj.setDate(now())>

		<!--- Save it. Note: updates will automatically occur on persisted objects if the object notices any change. We don't  have to use entity save after the Entity has been loaded and saved. --->
		<cfset EntitySave(RoleDbObj)>
	
		<!---Increment the counter--->
		<cfset newRoleLoopCount = newRoleLoopCount + 1>
	</cfloop>
</cftransaction>
				
<!--- **********************************************************************************************
Populate the Capability table. This table will be populated directly from the old tblRoles table. 
*************************************************************************************************--->
			
<cfquery name="reset">
DELETE FROM Capability;
DBCC CHECKIDENT ('[Capability]', RESEED, 0);
</cfquery>
	
<cfset newCapabilities = "AddPost,AssetEditor,EditCategory,EditComment,EditTemplate,EditFile,EditPage,EditPost,EditProfile,EditServerSetting,EditSubscriber,EditTheme,EditUser,ReleasePost">
<cfset newCapabilityDescriptions = "May create a new post,May add pictures and video.,May change or edit categories,May edit comments of other users,May edit a custom template that affects the blog page,May upload and delete files on the server,May edit an external blog page,May edit a blog post,May edit a profile,Can edit server settings- such as database DSN's and other administrative settings.,May delete or invite new subscribers,May design and change themes.,May edit blog users,Can release a blog post.">	

<!--- Use a transaction --->
<cftransaction>
	<cfparam name="newCapabilityLoopCount" default = 1>
	<!--- Loop through the new capabilities. These are not used yet but will be. --->
	<cfloop list="#newCapabilities#" index="capability">
		<cfset newUuid = createUUID()>
		<!--- Load the entity. --->
		<cfset CapabilityDbObj = entityNew("Capability")>
		<!---<cfset CapabilityDbObj = entityLoad("CapabilityDbObj", { CapabilityDbObj = capabilityDbObj }, "true" )>--->
		<!--- Use the entity objects to set the data. --->
		<cfset CapabilityDbObj.setBlogRef(blogRef)>
		<cfset CapabilityDbObj.setCapabilityUuid(newUuid)>
		<cfset CapabilityDbObj.setCapabilityName(capability)>
		<cfset CapabilityDbObj.setCapabilityDescription(listGetAt(newCapabilityDescriptions, newCapabilityLoopCount))>
		<cfset CapabilityDbObj.setDate(now())>

		<!--- Save it. Note: updates will automatically occur on persisted objects if the object notices any change. We don't  have to use entity save after the Entity has been loaded and saved. --->
		<cfset EntitySave(CapabilityDbObj)>
		<!--- Increment the loop count --->
		<cfset newCapabilityLoopCount = newCapabilityLoopCount + 1>
	</cfloop>
</cftransaction> 
	
<cfquery name="reset">
DELETE FROM RoleCapability;
DBCC CHECKIDENT ('[RoleCapability]', RESEED, 0);
</cfquery>

<!--- Get the new roles. --->
<cfset newRoles = "Administrator,SuperUser,Editor,Author,Designer,Moderator,Subscriber,Guest">

<!--- Use a transaction --->
<cftransaction>
	<cfloop list="#newRoles#" index="role">

		<!--- Administrators and SuperUsers have all capabilities. --->
		<cfif role eq 'Administrator'>
			
			<!---<cfoutput>#role#<br/></cfoutput>--->

			<cfset myCapabilities = "AddPost,AssetEditor,EditCategory,EditComment,EditTemplate,EditFile,EditPage,EditPost,EditProfile,EditServerSetting,EditSubscriber,EditTheme,EditUser,ReleasePost">
				
			<!--- Loop through the capability list. --->
			<cfset myCapabilityLoopCount=1>
			<!--- Loop through the new capabilities. These are not used yet but will be. --->
			<cfloop list="#newCapabilities#" index="myCapability">
				<!---<cfoutput>#myCapability#<br/></cfoutput>--->
				
				<cfset newUuid = createUUID()>

				<!--- *************************************************************
				Get the administrator roleId 
				 ************************************************************* --->
				<cfset RoleDbObj = entityLoad("Role", { RoleName = role }, "true" )>
				<!--- Load the capability table with the capability coming from the list. --->
				<cfset CapabilityDbObj = entityLoad("Capability", { CapabilityName = myCapability }, "true" )>	

				<!--- Load the entity. --->
				<cfset RoleCapabilityDbObj = entityNew("RoleCapability")>

				<!--- Use the entity objects to set the data. --->
				<cfset RoleCapabilityDbObj.setBlogRef(blogRef)>
				<cfset RoleCapabilityDbObj.setRoleRef(RoleDbObj)>
				<cfset RoleCapabilityDbObj.setCapabilityRef(CapabilityDbObj)>
				<cfset RoleCapabilityDbObj.setDate(now())>

				<!--- Save it. Note: updates will automatically occur on persisted objects if the object notices any change. We don't  have to use entity save after the Entity has been loaded and saved. --->
				<cfset EntitySave(RoleCapabilityDbObj)>
			</cfloop>

		<cfelseif role eq 'SuperUser'>
			
			<cfset myCapabilities = "AddPost,AssetEditor,EditCategory,EditComment,EditTemplate,EditFile,EditPage,EditPost,EditProfile,EditSubscriber,EditTheme,EditUser,ReleasePost">
				
			<!--- Loop through the capability list. --->
			<cfset myCapabilityLoopCount=1>
			<!--- Loop through the new capabilities. These are not used yet but will be. --->
			<cfloop list="#myCapabilities#" index="capability">
				<!---<cfoutput>#myCapability#<br/></cfoutput>--->
				
				<cfset newUuid = createUUID()>

				<!--- *************************************************************
				Get the super user roleId 
				 ************************************************************* --->
				<cfset RoleDbObj = entityLoad("Role", { RoleName = role }, "true" )>
				<!--- Load the capability table with the capability coming from the list. --->
				<cfset CapabilityDbObj = entityLoad("Capability", { CapabilityName = capability }, "true" )>	
				<cfdump var="#CapabilityDbObj#">

				<!--- Load the entity. --->
				<cfset RoleCapabilityDbObj = entityNew("RoleCapability")>
 
				<!--- Use the entity objects to set the data. --->
				<cfset RoleCapabilityDbObj.setBlogRef(blogRef)>
				<cfset RoleCapabilityDbObj.setRoleRef(RoleDbObj)>
				<cfset RoleCapabilityDbObj.setCapabilityRef(CapabilityDbObj )>
				<cfset RoleCapabilityDbObj.setDate(now())>

				<!--- Save it. Note: updates will automatically occur on persisted objects if the object notices any change. We don't  have to use entity save after the Entity has been loaded and saved. --->
				<cfset EntitySave(RoleCapabilityDbObj)>

			</cfloop>

		<cfelseif role eq 'Editor'>

			<cfset myCapabilities = "EditCategory,EditComment,EditFile,EditPost">
				
			<!--- Loop through the capability list. --->
			<cfset myCapabilityLoopCount=1>
			<!--- Loop through the new capabilities. These are not used yet but will be. --->
			<cfloop list="#myCapabilities#" index="capability">
				<cfset newUuid = createUUID()>

				<!--- *************************************************************
				Get the super user roleId 
				 ************************************************************* --->
				<cfset RoleDbObj = entityLoad("Role", { RoleName = role }, "true" )>
				<!--- Load the capability table with the capability coming from the list. --->
				<cfset CapabilityDbObj = entityLoad("Capability", { CapabilityName = capability }, "true" )>	

				<!--- Load the entity. --->
				<cfset RoleCapabilityDbObj = entityNew("RoleCapability")>

				<!--- Use the entity objects to set the data. --->
				<cfset RoleCapabilityDbObj.setBlogRef(blogRef)>
				<cfset RoleCapabilityDbObj.setRoleRef(RoleDbObj)>
				<cfset RoleCapabilityDbObj.setCapabilityRef(CapabilityDbObj)>
				<cfset RoleCapabilityDbObj.setDate(now())>

				<!--- Save it. Note: updates will automatically occur on persisted objects if the object notices any change. We don't  have to use entity save after the Entity has been loaded and saved. --->
				<cfset EntitySave(RoleCapabilityDbObj)>

			</cfloop>

		<cfelseif role eq 'Author'>

			<cfset myCapabilities = "AddPost">
				
			<!--- Loop through the capability list. --->
			<cfset myCapabilityLoopCount=1>
			<!--- Loop through the new capabilities. These are not used yet but will be. --->
			<cfloop list="#myCapabilities#" index="capability">
				<cfset newUuid = createUUID()>

				<!--- *************************************************************
				Get the super user roleId 
				 ************************************************************* --->
				<cfset RoleDbObj = entityLoad("Role", { RoleName = role }, "true" )>
				<!--- Load the capability table with the capability coming from the list. --->
				<cfset CapabilityDbObj = entityLoad("Capability", { CapabilityName = capability }, "true" )>	

				<!--- Load the entity. --->
				<cfset RoleCapabilityDbObj = entityNew("RoleCapability")>

				<!--- Use the entity objects to set the data. --->
				<cfset RoleCapabilityDbObj.setBlogRef(blogRef)>
				<cfset RoleCapabilityDbObj.setRoleRef(RoleDbObj)>
				<cfset RoleCapabilityDbObj.setCapabilityRef(CapabilityDbObj)>
				<cfset RoleCapabilityDbObj.setDate(now())>

				<!--- Save it. Note: updates will automatically occur on persisted objects if the object notices any change. We don't  have to use entity save after the Entity has been loaded and saved. --->
				<cfset EntitySave(RoleCapabilityDbObj)>

			</cfloop>

		<cfelseif role eq 'Designer'>

			<cfset myCapabilities = "AssetEditor,EditTemplate,EditFile,EditPage,EditTheme">
				
			<!--- Loop through the capability list. --->
			<cfset myCapabilityLoopCount=1>
			<!--- Loop through the new capabilities. These are not used yet but will be. --->
			<cfloop list="#myCapabilities#" index="capability">
				<cfset newUuid = createUUID()>

				<!--- *************************************************************
				Get the super user roleId 
				 ************************************************************* --->
				<cfset RoleDbObj = entityLoad("Role", { RoleName = role }, "true" )>
				<!--- Load the capability table with the capability coming from the list. --->
				<cfset CapabilityDbObj = entityLoad("Capability", { CapabilityName = capability }, "true" )>	

				<!--- Load the entity. --->
				<cfset RoleCapabilityDbObj = entityNew("RoleCapability")>

				<!--- Use the entity objects to set the data. --->
				<cfset RoleCapabilityDbObj.setBlogRef(blogRef)>
				<cfset RoleCapabilityDbObj.setRoleRef(RoleDbObj)>
				<cfset RoleCapabilityDbObj.setCapabilityRef(CapabilityDbObj)>
				<cfset RoleCapabilityDbObj.setDate(now())>

				<!--- Save it. Note: updates will automatically occur on persisted objects if the object notices any change. We don't  have to use entity save after the Entity has been loaded and saved. --->
				<cfset EntitySave(RoleCapabilityDbObj)>

			</cfloop>

		<cfelseif role eq 'Moderator'>

			<cfset myCapabilities = "EditComment,EditProfile,EditSubscriber,EditUser">
				
			<!--- Loop through the capability list. --->
			<cfset myCapabilityLoopCount=1>
			<!--- Loop through the new capabilities. These are not used yet but will be. --->
			<cfloop list="#myCapabilities#" index="capability">
				<cfset newUuid = createUUID()>

				<!--- *************************************************************
				Get the super user roleId 
				 ************************************************************* --->
				<cfset RoleDbObj = entityLoad("Role", { RoleName = role }, "true" )>
				<!--- Load the capability table with the capability coming from the list. --->
				<cfset CapabilityDbObj = entityLoad("Capability", { CapabilityName = capability }, "true" )>	

				<!--- Load the entity. --->
				<cfset RoleCapabilityDbObj = entityNew("RoleCapability")>

				<!--- Use the entity objects to set the data. --->
				<cfset RoleCapabilityDbObj.setBlogRef(blogRef)>
				<cfset RoleCapabilityDbObj.setRoleRef(RoleDbObj)>
				<cfset RoleCapabilityDbObj.setCapabilityRef(CapabilityDbObj)>
				<cfset RoleCapabilityDbObj.setDate(now())>

				<!--- Save it. Note: updates will automatically occur on persisted objects if the object notices any change. We don't  have to use entity save after the Entity has been loaded and saved. --->
				<cfset EntitySave(RoleCapabilityDbObj)>

			</cfloop>
					
		<cfelseif role eq 'Subscriber'>

			<cfset myCapabilities = "EditProfile">
				
			<!--- Loop through the capability list. --->
			<cfset myCapabilityLoopCount=1>
			<!--- Loop through the new capabilities. These are not used yet but will be. --->
			<cfloop list="#myCapabilities#" index="capability">
				<cfset newUuid = createUUID()>

				<!--- *************************************************************
				Get the super user roleId 
				 ************************************************************* --->
				<cfset RoleDbObj = entityLoad("Role", { RoleName = role }, "true" )>
				<!--- Load the capability table with the capability coming from the list. --->
				<cfset CapabilityDbObj = entityLoad("Capability", { CapabilityName = capability }, "true" )>	

				<!--- Load the entity. --->
				<cfset RoleCapabilityDbObj = entityNew("RoleCapability")>

				<!--- Use the entity objects to set the data. --->
				<cfset RoleCapabilityDbObj.setBlogRef(blogRef)>
				<cfset RoleCapabilityDbObj.setRoleRef(RoleDbObj)>
				<cfset RoleCapabilityDbObj.setCapabilityRef(CapabilityDbObj)>
				<cfset RoleCapabilityDbObj.setDate(now())>

				<!--- Save it. Note: updates will automatically occur on persisted objects if the object notices any change. We don't  have to use entity save after the Entity has been loaded and saved. --->
				<cfset EntitySave(RoleCapabilityDbObj)>

			</cfloop>

		</cfif>		

	</cfloop>
				
</cftransaction>
				
<!--- **********************************************************************************************
Populate the User Role table. 
*************************************************************************************************--->
			
<!---<cfquery name="reset">
	DELETE FROM UserRole;
	DBCC CHECKIDENT ('[UserRole]', RESEED, 0);
</cfquery>--->

<!--- Get the Users from BlogCfc --->
<cfquery name="getTblUserRoles" datasource="#dsn#">
	SELECT 
	username
    ,roleidfk
	FROM tbluserroles
</cfquery>

<!--- Use a transaction --->
<cftransaction>
	<cfoutput query="getTblUserRoles">
			<!--- Get the user by the username in the Users Obj. --->
			<cfset UserRef = entityLoad("Users", { UserName = username }, "true" )>
			<!--- Get the role in BlogCfc --->
			<cfquery name="getTblBlogRole" datasource="#dsn#">
				SELECT 
				role
				FROM tblblogroles
				WHERE id = <cfqueryparam value="#getTblUserRoles.roleidfk[currentRow]#" cfsqltype="cf_sql_varchar">
			</cfquery>
			<cfset blogCfcRole = getTblBlogRole.role>
			<!--- Get the role in our new database --->
			<cfset RoleRef = entityLoad("Role", { Role = blogCfcRole }, "true" )>

			<!--- Load the entity. --->
			<cfset UserRoleDbObj = entityNew("UserRole")>
			<!--- Use the entity objects to set the data. --->
			<cfset UserRoleDbObj.setBlogRef(blogRef)>
			<cfset UserRoleDbObj.setUserRef(UserRef)>
			<cfset UserRoleDbObj.setRoleRef(1)><!---We are using the admin role as the default--->
			<cfset UserRoleDbObj.setDate(now())>

			<!--- Save it. Note: updates will automatically occur on persisted objects if the object notices any change. We don't  have to use entity save after the Entity has been loaded and saved. --->
			<!---<cfset EntitySave(UserRoleDbObj)>--->

	</cfoutput>
</cftransaction>

			
<!--- **********************************************************************************************
Populate the Theme and Theme Settings tables. 
*************************************************************************************************--->

<!---<cfquery name="reset">
	DELETE FROM Theme;
	DBCC CHECKIDENT ('[Theme]', RESEED, 0);
	DELETE FROM ThemeSetting;
	DBCC CHECKIDENT ('[ThemeSetting]', RESEED, 0);
</cfquery>--->
	
<cfset defaultKendoThemes = application.blog.getDefaultThemes()>
			
<!--- Use a transaction --->
<cftransaction>
	
	<!--- Set a loop count --->
	<cfset themeLoopCount = 1>
		
	<!--- Loop thru the default themes --->
	<cfloop list="#defaultKendoThemes#" index="kendoTheme">
		<!--- Get the needed values by the kendoTheme. --->
		<cfset themeId = application.blog.getThemeIdByTheme(kendoTheme)>
		<!--- Are we  using this theme? --->
		<cfset useTheme = true><!--- UseCustomTheme is application.themeSettingsArray[themeId][1], but that is not what we want here. This will be depracated. --->
		<!--- Get the Galaxie Blog theme name (note: the blog owner may have changed the custom name, and that's OK) --->
		<cfset themeName = getDefaultCustomThemeNameByTheme(kendoTheme)>
		<cfset kendoCommonCssFileLocation = application.kendoSourceLocation & "/styles/kendo.common.min.css" />
		<!--- Get the Kendo Theme Css File Location --->
		<cfset kendoThemeCssFileLocation = application.themeSettingsArray[themeId][26]>
		<!--- Get the mobile Kendo Theme Css File Location --->
		<cfset kendoThemeMobileCssFileLocation = application.themeSettingsArray[themeId][27]>
		<!--- Is thie a dark theme? --->
		<cfset darkTheme = application.themeSettingsArray[themeId][3]>

		<!--- Load the blog table and get the first record (there only should be one record at this time). This will pass back an object with the value of the blogId. This is needed as the setBlogRef is a foreign key and for some odd reason ColdFusion or Hybernate must have an object passed as a reference instead of a hardcoded value. --->
		<cfset BlogRef = entityLoadByPK("Blog", 1)>

		<!--- Load the entity. --->
		<!---<cfset ThemeDbObj = entityNew("Theme")>--->
		<cfset ThemeDbObj = entityLoadByPK("Theme", themeLoopCount)>
		<!--- Load the theme setting obj --->
		<cfset ThemeSettingRef = entityLoadByPK("ThemeSetting", themeLoopCount)>
		
		<!--- Use the entity objects to set the data. --->
		<cfset ThemeDbObj.setBlogRef(blogRef)>
		<cfset ThemeDbObj.setUseTheme(useTheme)>
		<cfset ThemeDbObj.setThemeName(themeName)>
		<cfset ThemeDbObj.setKendoTheme(kendoTheme)>
		<cfset ThemeDbObj.setKendoCommonCssFileLocation(kendoCommonCssFileLocation)>
		<cfset ThemeDbObj.setKendoThemeCssFileLocation(kendoThemeCssFileLocation)>
		<cfset ThemeDbObj.setKendoThemeMobileCssFileLocation(kendoThemeMobileCssFileLocation)>
		<cfset ThemeDbObj.setDarkTheme(darkTheme)>
		<cfset ThemeDbObj.setUseTheme(useTheme)>
		<cfset ThemeDbObj.setDate(now())>
			
		<!--- **********************************************************************************************
		Populate the Theme Setting table. 
		*************************************************************************************************--->

		<!--- Use the BlogObj to get the BlogRef --->
		<!--- To be consistent, the images need a forward slash in this table. --->
		<cfset ThemeDbObj.setBlogRef(blogRef)>
		<cfset contentWidth = application.themeSettingsArray[themeId][4]>
		<cfset mainContainerWidth = application.themeSettingsArray[themeId][5]>
		<cfset sideBarContainerWidth = application.themeSettingsArray[themeId][6]>
		<cfset siteOpacity = application.themeSettingsArray[themeId][7]>
		<cfset blogBackgroundImage = "/" & application.themeSettingsArray[themeId][8]>
		<cfset blogBackgroundImageRepeat = application.themeSettingsArray[themeId][9]>
		<cfset blogBackgroundImagePosition = application.themeSettingsArray[themeId][10]>
		<cfset stretchHeaderAcrossPage = application.themeSettingsArray[themeId][11]>
		<cfset alignBlogMenuWithBlogContent = application.themeSettingsArray[themeId][12]>
		<cfset topMenuAlign = application.themeSettingsArray[themeId][13]>
		<cfset headerBackgroundImage = "/" & application.themeSettingsArray[themeId][14]>
		<cfset menuBackgroundImage = "/" & application.themeSettingsArray[themeId][15]>
		<cfset coverKendoMenuWithMenuBackgroundImage = application.themeSettingsArray[themeId][16]>
		<cfset logoImageMobile = "/" & application.themeSettingsArray[themeId][17]>
		<cfset logoMobileWidth = application.themeSettingsArray[themeId][18]>
		<cfset logoImage = "/" & application.themeSettingsArray[themeId][19]>
		<cfset logoPaddingTop = application.themeSettingsArray[themeId][20]>
		<cfset logoPaddingRight = application.themeSettingsArray[themeId][21]>
		<cfset logoPaddingLeft = application.themeSettingsArray[themeId][22]>
		<cfset logoPaddingBottom = application.themeSettingsArray[themeId][23]>
		<cfset blogNameTextColor = application.themeSettingsArray[themeId][24]>
		<cfset headerBodyDividerImage = application.themeSettingsArray[themeId][25]>
		<cfset breakpoint = application.themeSettingsArray[themeId][28]>

		<cfoutput>#themeLoopCount#</cfoutput>
		<!--- Load the theme obj --->
		<cfset themeRef = entityLoadByPK("Theme", themeLoopCount)>
		<!--- Load the entity. --->
		<cfset ThemeSettingDbObj = entityNew("ThemeSetting")>
		<!---<cfset ThemeSettingDbObj = entityLoadByPK("ThemeSetting", themeLoopCount)>--->
		
		<!--- Use the entity objects to set the data. --->
		<!--- Removed August 2020. Set the reference in the theme table instead. <cfset ThemeSettingDbObj.setThemeRef(ThemeDbObj)>--->
		<cfset ThemeSettingDbObj.setFontRef(FontRefObj)>
		<cfset ThemeSettingDbObj.setFontSize(application.BlogFontSize)>
		<cfset ThemeSettingDbObj.setContentWidth(contentWidth)>
		<cfset ThemeSettingDbObj.setMainContainerWidth(MainContainerWidth)>
		<cfset ThemeSettingDbObj.setSideBarContainerWidth(sideBarContainerWidth)>
		<cfset ThemeSettingDbObj.setSiteOpacity(siteOpacity)>
		<cfset ThemeSettingDbObj.setBlogBackgroundImage(blogBackgroundImage)>
		<cfset ThemeSettingDbObj.setBlogBackgroundImageRepeat(blogBackgroundImageRepeat)>
		<cfset ThemeSettingDbObj.setBlogBackgroundImagePosition(blogBackgroundImagePosition)>
		<cfset ThemeSettingDbObj.setStretchHeaderAcrossPage(stretchHeaderAcrossPage)>
		<cfset ThemeSettingDbObj.setAlignBlogMenuWithBlogContent(alignBlogMenuWithBlogContent)>
		<cfset ThemeSettingDbObj.setTopMenuAlign(topMenuAlign)>
		<cfset ThemeSettingDbObj.setHeaderBackgroundImage(headerBackgroundImage)>
		<cfset ThemeSettingDbObj.setMenuBackgroundImage(menuBackgroundImage)>
		<cfset ThemeSettingDbObj.setCoverKendoMenuWithMenuBackgroundImage(coverKendoMenuWithMenuBackgroundImage)>
		<cfset ThemeSettingDbObj.setLogoImageMobile(logoImageMobile)>
		<cfset ThemeSettingDbObj.setLogoMobileWidth(logoMobileWidth)>
		<cfset ThemeSettingDbObj.setLogoImage(logoImage)>
		<cfset ThemeSettingDbObj.setLogoPaddingTop(logoPaddingTop)>
		<cfset ThemeSettingDbObj.setLogoPaddingRight(logoPaddingRight)>
		<cfset ThemeSettingDbObj.setLogoPaddingLeft(logoPaddingLeft)>
		<cfset ThemeSettingDbObj.setLogoPaddingBottom(logoPaddingBottom)>
		<cfset ThemeSettingDbObj.setBlogNameTextColor(blogNameTextColor)>
		<cfset ThemeSettingDbObj.setBlogNameFontRef(FontRefObj.getFontId())>
		<cfset ThemeSettingDbObj.setHeaderBodyDividerImage(headerBodyDividerImage)>
		<cfset ThemeSettingDbObj.setBreakpoint(breakpoint)>
		<cfset ThemeSettingDbObj.setDate(now())>
			
		<!---Now that the theme setting is set, insert the theme setting into the theme obj.--->
		<!--- Added in August 2020. Needs testing. --->
		<cfset ThemeDbObj.setThemeSettingRef(ThemeSettingDbObj)>
			
		<!--- Save it. Note: updates will automatically occur on persisted objects if the object notices any change. We don't  have to use entity save after the Entity has been loaded and saved. --->
		<cfset EntitySave(ThemeSettingDbObj)>
		<!--- Save the theme obj. Note: updates will automatically occur on persisted objects if the object notices any change. We don't  have to use entity save after the Entity has been loaded and saved. --->
		<cfset EntitySave(ThemeDbObj)>
		
		<!--- Increment the loop count --->
		<cfset themeLoopCount = themeLoopCount + 1>
	</cfloop>
</cftransaction>
			
<cfcatch type="any">
</cfcatch>
			
</cftry>
			
<!--- **********************************************************************************************
Font table
*************************************************************************************************--->
			
<!--- <cfquery name="reset">
DELETE FROM Font;
DBCC CHECKIDENT ('[Font]', RESEED, 0);
</cfquery>--->
			
<cfset fontList = "Arial,Arial Black,Bebas Neue,Bookman,Candara,Comic Sans MS,Courier,Eagle Lake,Eras Bold,Eras Book,Eras Demi,Eras Light,Exo 2,Franklin Gothic,Georgia,Impact,Indie Flower,ITC Avant Garde,Josefin Sans,Kaufmann Script Bold,Oxygen,Palatino,Quicksand,Roboto,Times,Times New Roman,Trajan,Ubuntu,Verdana">
	
<cfloop list="#trim(fontList)#" index="font">
	
	<cfif font eq 'Kaufmann Script Bold'>
		<cfset googleFont = false>
		<cfset customFont = true>
	<cfelseif font contains 'Eras'>
		<cfset googleFont = false>
		<cfset customFont = true>
	<cfelseif font eq 'Arial Black'>
		<cfset googleFont = false>
		<cfset customFont = false>
	<cfelse>
		<cfset googleFont = true>
		<cfset customFont = false>
	</cfif>
			
	<cfif font eq 'Arial'>
		<cfset fontType = "Montotype">
		<cfset googleFont = false>
	<cfelseif font eq 'Arial Black'>
		<cfset fontType = "sans-serif">
		<cfset googleFont = false>
	<cfelseif font eq 'Bebas Neue'>
		<cfset fontType = "sans-serif">
	<cfelseif font eq 'Bookman'>
		<cfset fontType = "serif">
	<cfelseif font eq 'Candara'>
		<cfset fontType = "casual humanist sans">		
	<cfelseif font eq 'Comic Sans MS'>
		<cfset fontType = "comic-sans">
	<cfelseif font eq 'Courier'>
		<cfset fontType = "monospace">
	<cfelseif font eq 'Eagle Lake'>
		<cfset fontType = "calligraphic script">		
	<cfelseif font eq 'Eras Bold'>
		<cfset fontType = "sans-serif">
		<cfset googleFont = false>
	<cfelseif font eq 'Eras Book'>
		<cfset fontType = "sans-serif">
		<cfset googleFont = false>
	<cfelseif font eq 'Eras Demi'>
		<cfset fontType = "sans-serif">	
		<cfset googleFont = false>
	<cfelseif font eq 'Eras Light'>
		<cfset fontType = "sans-serif">
		<cfset googleFont = false>
	<cfelseif font eq 'Exo 2'>
		<cfset fontType = "geometric sans-serif">
	<cfelseif font eq 'Franklin Gothic'>
		<cfset fontType = "sans-serif">		
	<cfelseif font eq 'Georgia'>
		<cfset fontType = "serif">
	<cfelseif font eq 'Impact'>
		<cfset fontType = "realist sans-serif">
	<cfelseif font eq 'Indie Flower'>
		<cfset fontType = "handwriting">		
	<cfelseif font eq 'ITC Avant Garde'>
		<cfset fontType = "sans-serif">
	<cfelseif font eq 'Josefin Sans'>
		<cfset fontType = "sans-serif">
	<cfelseif font eq 'Kaufmann Script Bold'>
		<cfset fontType = "brush script">		
	<cfelseif font eq 'Oxygen'>
		<cfset fontType = "unicode">
	<cfelseif font eq 'Palatino'>
		<cfset fontType = "old-style serif">	
	<cfelseif font eq 'Quicksand'>
		<cfset fontType = "sans-serif">		
	<cfelseif font eq 'Roboto'>
		<cfset fontType = "sans-serif">
	<cfelseif font eq 'Times'>
		<cfset fontType = "monotype">
	<cfelseif font eq 'Trajan'>
		<cfset fontType = "serif">	
	<cfelseif font eq 'Ubuntu'>
		<cfset fontType = "open type">
	<cfelseif font eq 'Verdana'>
		<cfset fontType = "humanist sans-serif">
	<cfelse>
		<cfset fontType = "">
	</cfif>

	<!--- Load the entity. --->
	<cfset FontDbObj = entityNew("Font")>
	<!--- There is not relationship here. --->
	<cfset FontDbObj.setFont(font)>
	<cfset FontDbObj.setFontType(fontType)>	
	<cfset FontDbObj.setGoogleFont(googleFont)>
	<cfset FontDbObj.setCustomFont(customFont)>
	<cfset FontDbObj.setDate(now())>

	<!--- Save it. Note: updates will automatically occur on persisted objects if the object notices any change. We don't  have to use entity save after the Entity has been loaded and saved. --->
	<!---<cfset EntitySave(FontDbObj)>--->
		
</cfloop>
		
<!--- **********************************************************************************************
Populate the Mime Type table. 
*************************************************************************************************--->
		
<!---<cfquery name="reset">
	DELETE FROM MimeType;
	DBCC CHECKIDENT ('[MimeType]', RESEED, 0);
</cfquery>--->
		
<!--- Both the mime type and the extension are in a list separated by an underscore. --->
<cfset mimeTypes = ".pdf_application/pdf_Portable Document Format,.js_application/javascript_JavaScript,.json_application/json_JSON format,.jsonld_application/ld+json_JSON LD Format,.xml_application/xml_XML,.zip_application/zip_ZIP archive,.ogv_application/ogg_OGG video,.mpg_audio/mpeg_MPEG Audio,.woff2_font/woff2_Web Open Font Format (WOFF),.gif_image/gif_Graphics Interchange Format (GIF),.jpg_image/jpeg_jpeg image,.png_image/png_Portable Network Graphics,.svg_image/svg+xml_Scalable Vector Graphics (SVG),.webp_image/webp_WEBP image,.css_text/css_Cascading Style Sheets (CSS),.html_text/html_HyperText Markup Language (HTML),.txt_text/Plain Text_(generally ASCII or ISO 8859-n),.vtt_text/vtt_Web Video Text Tracks,mpeg_video/mpeg_mpeg_MPEG Video,.webm_video/webm_WEBM video">
	
<cfloop list="#mimeTypes#" index="mimeType">
	
	<!--- Get the mime type extension --->
	<cfset mimeTypeExtension = listGetAt(mimeType, 1, '_')>
	<!--- Get the mime type --->
	<cfset mimeType = listGetAt(mimeType, 2, '_')>
	<!--- And the desc --->
	<cftry>
		<cfset desc = listGetAt(mimeType, 3, '_')>
		<cfcatch type="any">
			<cfset desc = "">
		</cfcatch>
	</cftry>

	<!--- Load the entity. --->
	<cfset MimeTypeDbObj = entityNew("MimeType")>
	<!--- Use the entity objects to set the data. --->
	<cfset MimeTypeDbObj.setMimeType(mimeType)>
	<cfset MimeTypeDbObj.setExtension(mimeTypeExtension)>	
	<cfset MimeTypeDbObj.setDescription(desc)>
	<cfset MimeTypeDbObj.setDate(now())>

	<!--- Save it. Note: updates will automatically occur on persisted objects if the object notices any change. We don't  have to use entity save after the Entity has been loaded and saved. --->
	<!---<cfset EntitySave(MimeTypeDbObj)>--->
			
</cfloop>
		
<!--- **********************************************************************************************
Populate the Post table. 
*************************************************************************************************--->
		
<!---<cfquery name="reset">
	DELETE FROM RelatedPost;
	DBCC CHECKIDENT ('[RelatedPost]', RESEED, 0);
</cfquery>--->

<!--- Comments must be deleted prior to deleting the posts. --->
<!---<cfquery name="reset">
	DELETE FROM Comment;
	DBCC CHECKIDENT ('[Comment]', RESEED, 0);
</cfquery>--->
		
<!---<cfquery name="reset">
	DELETE FROM Media;
	DBCC CHECKIDENT ('[Media]', RESEED, 0);
</cfquery>--->
			
<!---<cfquery name="reset">
	DELETE FROM Post;
	DBCC CHECKIDENT ('[Post]', RESEED, 0);
</cfquery>--->

<!--- Get the Users from BlogCfc --->
<cfquery name="getTblBlogEntries" datasource="#dsn#">
	SELECT 
		id
		,title
		,body
		,posted
		,morebody
		,alias
		,username
		,blog
		,allowcomments
		,enclosure
		,filesize
		,mimetype
		,views
		,released
		,mailed
		,summary
		,subtitle
		,keywords
		,duration
  	FROM tblblogentries
</cfquery>

<!--- Use a transaction --->
<cftransaction>
	<cfoutput query="getTblBlogEntries">
			
		<!--- Load the blog table and get the first record (there only should be one record at this time). This will pass back an object with the value of the blogId. This is needed as the setBlogRef is a foreign key and for some odd reason ColdFusion or Hybernate must have an object passed as a reference instead of a hardcoded value. --->
		<cfset BlogRef = entityLoadByPK("Blog", 1)>
		<!--- Get the user by the username in the Users Obj. --->
		<cfset UserRef = entityLoad("Users", { UserName = username }, "true" )>

		<!--- Load the entity. --->
		<!---<cfset PostDbObj = entityNew("Post")>--->
		<cfset PostDbObj = entityLoad("Post", { PostUuid = id }, "true" )>
		<!--- Use the entity objects to set the data. --->
		<cfset PostDbObj.setBlogRef(BlogRef)>
		<cfset PostDbObj.setUserRef(UserRef)>
		<cfset PostDbObj.setPostUuid(id)>
		<cfset PostDbObj.setPostAlias(alias)>
		<cfset PostDbObj.setTitle(title)>
		<cfset PostDbObj.setDescription(summary)>
		<cfset PostDbObj.setBody(body)>
		<cfset PostDbObj.setMoreBody(morebody)>
		<cfset PostDbObj.setAllowComment(allowcomments)>
		<cfset PostDbObj.setNumViews(views)>
		<cfset PostDbObj.setMailed(mailed)>
		<cfset PostDbObj.setReleased(released)>
		<cfset PostDbObj.setRemoved(0)>
		<cfset PostDbObj.setDatePosted(posted)>	
		<cfset PostDbObj.setDate(now())>
		<!--- Save it. --->
		<cfset EntitySave(PostDbObj)>
			
	</cfoutput>
</cftransaction>
			
<!--- **********************************************************************************************
Populate the Comment table. 
*************************************************************************************************--->

<!--- Get the Users from BlogCfc --->
<cfquery name="getTblBlogComments" datasource="#dsn#">
	SELECT 
		id
		,entryidfk
		,name
		,email
		,comment
		,posted
		,subscribe
		,website
		,moderated
		,subscribeonly
		,killcomment
	FROM tblblogcomments
</cfquery>

<!--- Use a transaction --->
<cftransaction>
	<cfoutput query="getTblBlogComments">
		<!--- Load the blog table and get the first record (there only should be one record at this time). This will pass back an object with the value of the blogId. This is needed as the setBlogRef is a foreign key and for some odd reason ColdFusion or Hybernate must have an object passed as a reference instead of a hardcoded value. --->
		<cfset BlogRef = entityLoadByPK("Blog", 1)>
		<!--- Get the post ref --->
		<cfset thisPostRef = entityLoad("Post", { PostUuid = entryidfk }, "true" )>
		<!--- Has the comment been approved? --->
		<cfif moderated eq 0>
			<cfset approved = 0>
		<cfelse>
			<cfset approved = 1>
		</cfif>	
		
		<!--- Load the entity. --->
		<cfset CommentDbObj = entityNew("Comment")>
		<!--- Use the entity objects to set the data. --->
		<cfset CommentDbObj.setBlogRef(BlogRef)>
		<cfset CommentDbObj.setPostRef(thisPostRef.getPostId())>
		<!--- don't  set the user or comment ref --->
		<!--- ParentCommentRef is null right now. I will not use it in this version. --->
		<cfset CommentDbObj.setCommentUuid(id)>
		<cfset CommentDbObj.setComment(comment)>
		<cfset CommentDbObj.setDatePosted(posted)>
		<cfset CommentDbObj.setSubscribe(subscribe)>
		<cfset CommentDbObj.setApproved(approved)>
		<cfset CommentDbObj.setPromote(0)>	
		<cfset CommentDbObj.setHide(0)>	
		<cfset CommentDbObj.setSpam(0)>	
		<cfset CommentDbObj.setPromote(0)>	
		<!--- KillComment in BlogCfc is a UUID for some odd reason. I'm going to set this to false. --->
		<cfset CommentDbObj.setRemove(0)>	
		<cfset CommentDbObj.setCommentOrder(currentRow)>	
		<cfset CommentDbObj.setDate(now())>

		<!--- Save it. Note: updates will automatically occur on persisted objects if the object notices any change. We don't  have to use entity save after the Entity has been loaded and saved. --->
		<!---<cfset EntitySave(CommentDbObj)>--->

	</cfoutput>
</cftransaction>		
			
<!--- **********************************************************************************************
Populate the PostCategoryLookup table. 
*************************************************************************************************--->
			
<!---<cfquery name="reset">
	DELETE FROM PostCategoryLookup;
	DBCC CHECKIDENT ('[PostCategoryLookup]', RESEED, 0);
</cfquery>--->

<!--- Get the Post Categories from BlogCfc --->
<cfquery name="getTblBlogEntriesCategories" datasource="#dsn#">
	SELECT 
	categoryidfk
    ,entryidfk
  	FROM tblblogentriescategories
</cfquery>

<!--- Use a transaction --->
<cftransaction>
	<cfoutput query="getTblBlogEntriesCategories">
		<!--- Get the Category Id  --->
		<cfset CategoryRef = entityLoad("Category", { CategoryUuid = categoryidfk }, "true" )>
		<!--- Get the Post Id--->
		<cfset PostRef = entityLoad("Post", { PostUuid = entryidfk }, "true" )>

		<!--- Load the entity. --->
		<cfset PostCategoryObj = entityNew("PostCategoryLookup")>
		<!--- Use the entity objects to set the data. --->
		<cfset PostCategoryObj.setCategoryRef(CategoryRef)>
		<cfset PostCategoryObj.setPostRef(PostRef)>
		<cfset PostCategoryObj.setDate(now())>

		<!--- Save it. Note: updates will automatically occur on persisted objects if the object notices any change. We don't  have to use entity save after the Entity has been loaded and saved. --->
		<!---<cfset EntitySave(PostCategoryObj)>--->

	</cfoutput>
</cftransaction>
			
<!--- **********************************************************************************************
Populate the RelatedPost table. 
*************************************************************************************************--->

<cfquery name="reset">
	DELETE FROM RelatedPost;
	DBCC CHECKIDENT ('[RelatedPost]', RESEED, 0);
</cfquery>
			
<!--- Get the Post Categories from BlogCfc --->
<cfquery name="getTblBlogEntriesRelated" datasource="#dsn#">
	SELECT 
	entryid
    ,relatedid
  	FROM tblblogentriesrelated
</cfquery>

<!--- Use a transaction --->
<cftransaction>
	<cfif getTblBlogEntriesRelated.recordcount gt 0>
	<cfoutput query="getTblBlogEntriesRelated">
		<!--- Get the Post object  --->
		<cfset PostRef = entityLoad("Post", { PostUuid = entryid }, "true" )>
		<!--- Get the Related Post object--->
		<cfset RelatedPostRef = entityLoad("Post", { PostUuid = relatedid }, "true" )>
			
		<cfset RelatedPostObj = entityNew("RelatedPost")>
		<cfdump var="#RelatedPostObj#">
			
			
		<!--- Use the entity objects to set the data. --->
		<cfset RelatedPostObj.setPostRef(PostRef)>
		<cfset RelatedPostObj.setRelatedPostRef(RelatedPostRef)>
		<cfset RelatedPostObj.setDate(now())>

		<!--- Save it. Note: updates will automatically occur on persisted objects if the object notices any change. We don't  have to use entity save after the Entity has been loaded and saved. --->
		<cfset entitySave(RelatedPostObj)>

	</cfoutput>
	</cfif>
</cftransaction>
			
<!--- **********************************************************************************************
Populate the Media table. 
*************************************************************************************************--->
<!--- Use a transaction --->
<cftransaction>
	<cfoutput query="getTblBlogEntries">			
		<!--- Save the enclosures into the new media table. --->
		<cfif len(enclosure) gt 0>
			<!--- Get the post record by the PostUuid --->
			<cfset PostRef = entityLoad("Post", { PostUuid = id }, "true" )>
			<!--- Get the mime type --->
			<cfset MimeTypeRef = entityLoad("MimeType", { MimeType = mimetype }, "true" )>

			<!---Instantiate the media obj--->
			<cfset MediaDbObj = entityNew("Media")>
			<!--- The only four pieces of information available are the PostRef, MimeTypeRef, enclosure, and file size in the tblBlogEntries table. --->
			<cfset MediaDbObj.setPostRef(PostRef)>
			<cfset MediaDbObj.setMimeTypeRef(MimeTypeRef)>
			<cfset MediaDbObj.setMediaPath(enclosure)>
			<cfset MediaDbObj.setMediaSize(filesize)>
			<!--- Save it. --->
			<!---<cfset EntitySave(MediaDbObj)>--->
		</cfif>
			
	</cfoutput>
</cftransaction>
			
<!--- **********************************************************************************************
Populate the Search Query table 
*************************************************************************************************--->
			
<!---<cfquery name="reset">
	DELETE FROM SearchQuery;
	DBCC CHECKIDENT ('[SearchQuery]', RESEED, 0);
</cfquery>--->

<!--- Get the Post search results from BlogCfc --->
<cfquery name="getTblSearchStats" datasource="#dsn#">
	SELECT 
	searchterm
	,searched
	,blog
	FROM tblblogsearchstats
</cfquery>

<!--- Use a transaction --->
<cftransaction>
	<cfoutput query="getTblSearchStats">
		
		<!--- Load the blog table and get the first record (there only should be one record at this time). This will pass back an object with the value of the blogId. This is needed as the setBlogRef is a foreign key and for some odd reason ColdFusion or Hybernate must have an object passed as a reference instead of a hardcoded value. --->
		<cfset BlogRef = entityLoadByPK("Blog", 1)>

		<!--- Load the entity. --->
		<cfset SearchQueryObj = entityNew("SearchQuery")>
		<!--- Use the entity objects to set the data. --->
		<cfset SearchQueryObj.setBlogRef(BlogRef)>
		<cfset SearchQueryObj.setSearchQuery(searchterm)>
		<cfset SearchQueryObj.setDate(searched)>

		<!--- Save it. Note: updates will automatically occur on persisted objects if the object notices any change. We don't  have to use entity save after the Entity has been loaded and saved. --->
		<!---<cfset EntitySave(SearchQueryObj)>--->

	</cfoutput>
</cftransaction>
			
<!--- **********************************************************************************************
Populate the Subscriber table. 
*************************************************************************************************--->
			
<!---<cfquery name="reset">
	DELETE FROM Subscriber;
	DBCC CHECKIDENT ('[Subscriber]', RESEED, 0);
</cfquery>--->

<!--- Get the Users from BlogCfc --->
<cfquery name="getTblBlogSubscribers" datasource="#dsn#">
	SELECT 
		email
		,token
		,blog
		,verified
	FROM tblblogsubscribers
</cfquery>

<!--- Use a transaction --->
<cftransaction>
	<cfoutput query="getTblBlogSubscribers">
		<!--- Load the blog table and get the first record (there only should be one record at this time). This will pass back an object with the value of the blogId. This is needed as the setBlogRef is a foreign key and for some odd reason ColdFusion or Hybernate must have an object passed as a reference instead of a hardcoded value. --->
		<cfset BlogRef = entityLoadByPK("Blog", 1)>

		<!--- Load the entity. --->
		<cfset SubscriberDbObj = entityNew("Subscriber")>
		<!--- Use the entity objects to set the data. --->
		<cfset SubscriberDbObj.setBlogRef(BlogRef)>
		<!---The postRef should be left blank.It's not an option in BlogCfc.--->
		<cfset SubscriberDbObj.setSubscriberEmail(email)>
		<cfset SubscriberDbObj.setSubscriberToken(token)>
		<cfset SubscriberDbObj.setSubscriberVerified(verified)>
		<!--- In BlogCfc, all subscribers subsribe to everything. --->
		<cfset SubscriberDbObj.setSubscribeAll(1)>	
		<cfset SubscriberDbObj.setDate(now())>

		<!--- Save it. Note: updates will automatically occur on persisted objects if the object notices any change. We don't have to use entity save after the Entity has been loaded and saved. --->
		<!---<cfset EntitySave(SubscriberDbObj)>--->

	</cfoutput>
</cftransaction>
			
<!---<cfset PostObj = entityLoadByPK("Post", 13)>
<cfdump var="#PostObj#">--->
			
<!---<cfdump var="#blogRef#">
<cfset BlogOptionDbObj = entityLoadByPK("BlogOption", 1)>
	
<cfdump var="#BlogOptionDbObj#">
	
<cfdump var="#ThemeDbObj#">
	
<cfdump var="#ThemeSettingDbObj#">--->

<cfset PostDbObj = entityLoadByPK("Users", 1)>
<cfdump var="#PostDbObj#">
<br/><br/>
<!---<cfset PostCategoryLookupDbObj = entityLoadByPK("PostCategoryLookup", 2)>
<cfdump var="#PostCategoryLookupDbObj#">--->
<br/><br/>
<!---<cfset CategoryLookupDbObj = entityLoadByPK("Category", 2)>
<cfdump var="#CategoryLookupDbObj#">--->
