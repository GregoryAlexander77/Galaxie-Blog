<!--- The jsonArray function turns a native ColdFusion query into an array of structs that can be easily used with jQuery. ---> 
<cfobject component="#application.baseComponentPath#common.cfc.cfJson" name="jsonArray">
<!--- Common destination --->
<cfset destination = expandPath("#application.baseUrl#/common/data/files")>
<!--- Set the dsn --->
<cfset dsn = "Galaxie3d">
	
<!---****************************************************************************************
Blog table
*****************************************************************************************--->
	
<cfset dataFileName = "getBlog">
	
<cfquery name="Data" datasource="#dsn#">
	SELECT TOP (1) BlogId
      ,'your-new-blog' as BlogName
      ,'Your new blog' as BlogTitle
      ,'http://www.myblog.com/index.cfm' as BlogUrl
      ,'Your blog description' as BlogDescription
      ,'' as BlogParentSiteName
      ,'' as BlogParentSiteUrl
      ,'' as BlogMetaKeywords
      ,BlogLocale
      ,'' as BlogDsn
      ,'' as BlogDatabaseType
      ,'' as BlogDsnUserName
      ,'' as BlogDsnPassword
      ,'' as BlogMailServer
      ,'' as BlogMailServerUserName
      ,'' as BlogMailServerPassword
      ,'myblog@yournewblog.com' as BlogEmail
      ,'myblog@yournewblog.com' as BlogEmailFailToAddress
      ,'' BlogTimeZone
	  ,'' BlogServerTimeZone
      ,0 as BlogServerTimeZoneOffset
      ,'' IpBlockList
      ,SaltAlgorithm
      ,SaltAlgorithmSize
      ,HashAlgorithm
      ,ServiceKeyEncryptionPhrase
      ,'3.0' as BlogVersion
      ,1 as IsProd
      ,0 as BlogInstalled
      ,'' as BlogInstallDate
      ,'' as BlogVersionDate
  FROM Blog
</cfquery>
	
<cfset blogId = Data.BlogId>
		
<!---<cfset BlogDbObj = entityLoadByPK("Blog", application.BlogDbObj.getBlogId())>--->
<!---Convert it to a cf query --->
<!---<cfset blogQry = EntityToQuery( BlogDbObj )>--->
<cfdump var="#Data#">
	
<cfwddx
	action="cfml2wddx"
	input="#Data#"
	output="blogDataXml"
	/>
	
<cffile action="write" file="#destination#/#dataFileName#.txt" output="#blogDataXml#">
	
<!---****************************************************************************************
Blog Option table
*****************************************************************************************--->
	
<cfset dataFileName = "getBlogOption">
	
<cfquery name="Data" datasource="#dsn#">
	SELECT 
      #BlogId# as BlogRef
      ,'https://ajax.googleapis.com/ajax/libs/jquery/3.4.1/jquery.min.js' as JQueryCDNPath
      ,'/common/libs/kendoCore/' as KendoFolderPath
      ,0 as KendoCommercial
      ,0 as UseSsl
      ,0 as ServerRewriteRuleInPlace
      ,1 as DeferScriptsAndCss
      ,1 as MinimizeCode
      ,0 as DisableCache
      ,10 as EntriesPerBlogPage
      ,1 as BlogModerated
      ,1 as UseCaptcha
      ,1 as AllowGravatar
      ,0 as IncludeGsap
      ,0 as IncludeDisqus
      ,'Plyr' as DefaultMediaPlayer
      ,'LowRes' as BackgroundImageResolution
      ,'' as AddThisApiKey
      ,'' as AddThisToolboxString
      ,'' as DisqusBlogIdentifier
      ,'' as DisqusApiKey
      ,'' as DisqusApiSecret
      ,'' as DisqusAuthTokenKey
      ,'' as DisqusAuthUrl
      ,'' as DisqusAuthTokenUrl
      ,'' as BingMapsApiKey
      ,'' as FacebookAppId
      ,'' as TwitterAppId
      ,'' as DefaultLogoImageForSocialMediaShare
  FROM BlogOption
</cfquery>
		
<!---<cfset BlogDbObj = entityLoadByPK("Blog", application.BlogDbObj.getBlogId())>--->
<!---Convert it to a cf query --->
<!---<cfset blogQry = EntityToQuery( BlogDbObj )>--->
<cfdump var="#Data#">
	
<cfwddx
	action="cfml2wddx"
	input="#Data#"
	output="blogDataXml"
	/>
	
<cffile action="write" file="#destination#/#dataFileName#.txt" output="#blogDataXml#">
	
<!---****************************************************************************************
Capability table
*****************************************************************************************--->
	
<cfset dataFileName = "getCapability">
	
<cfquery name="Data" datasource="#dsn#">
	SELECT
	CapabilityId
	,1 as BlogRef
	,'' as RoleRef
	,CapabilityUuid
	,CapabilityName
	,CapabilityUiLabel
	,CapabilityDescription
	FROM Capability
	ORDER BY CapabilityName
</cfquery>
		
<!---<cfset BlogDbObj = entityLoadByPK("Blog", application.BlogDbObj.getBlogId())>--->
<!---Convert it to a cf query --->
<!---<cfset blogQry = EntityToQuery( BlogDbObj )>--->
<cfdump var="#Data#">
	
<cfwddx
	action="cfml2wddx"
	input="#Data#"
	output="blogDataXml"
	/>
	
<cffile action="write" file="#destination#/#dataFileName#.txt" output="#blogDataXml#">
	
<!---****************************************************************************************
Custom Template table
*****************************************************************************************--->
	
<cfset dataFileName = "getCustomTemplate">
	
<cfquery name="Data" datasource="#dsn#">
	SELECT 
	  #BlogId# as BlogRef
      ,1 as CustomTemplateId
      ,'' as CoreLogicTemplate
      ,'' as HeaderTemplate
      ,'' as BodyString
      ,'' as FontTemplate
      ,'' as CssTemplate
      ,'' as TopMenuCssTemplate
      ,'' as TopMenuHtmlTemplate
      ,'' as TopMenuJsTemplate
      ,'' as BlogCssTemplate
      ,'' as BlogJsTemplate
      ,'' as BlogHtmlTemplate
      ,'' as SideBarPanelHtmlTemplate
      ,'' as FooterHtmlTemplate
  FROM CustomTemplate
</cfquery>
		
<!---<cfset BlogDbObj = entityLoadByPK("Blog", application.BlogDbObj.getBlogId())>--->
<!---Convert it to a cf query --->
<!---<cfset blogQry = EntityToQuery( BlogDbObj )>--->
<cfdump var="#Data#">
	
<cfwddx
	action="cfml2wddx"
	input="#Data#"
	output="blogDataXml"
	/>
	
<cffile action="write" file="#destination#/#dataFileName#.txt" output="#blogDataXml#">
	
<!---****************************************************************************************
Font table
*****************************************************************************************--->
	
<cfset dataFileName = "getFont">
	
<cfquery name="Data" datasource="#dsn#">
	SELECT
      Font
      ,FontAlias
      ,FontWeight
      ,Italic
      ,FontType
      ,FileName
      ,WebSafeFont
      ,WebSafeFallback
      ,GoogleFont
      ,SelfHosted
      ,Woff
      ,Woff2
      ,UseFont
  	FROM Font
  	WHERE Font <> ''
	ORDER BY Font
</cfquery>
		
<!---<cfset BlogDbObj = entityLoadByPK("Blog", application.BlogDbObj.getBlogId())>--->
<!---Convert it to a cf query --->
<!---<cfset blogQry = EntityToQuery( BlogDbObj )>--->
<cfdump var="#Data#">
	
<cfwddx
	action="cfml2wddx"
	input="#Data#"
	output="blogDataXml"
	/>
	
<cffile action="write" file="#destination#/#dataFileName#.txt" output="#blogDataXml#">
	
<!---****************************************************************************************
Kendo Theme Table
*****************************************************************************************--->
	
<cfset dataFileName = "getKendoTheme">
	
<cfquery name="Data" datasource="#dsn#">
	SELECT
      KendoTheme
      ,KendoCommonCssFileLocation
      ,KendoThemeCssFileLocation
      ,KendoThemeMobileCssFileLocation
      ,DarkTheme
  	FROM KendoTheme
	ORDER BY KendoTheme
</cfquery>
		
<!---<cfset BlogDbObj = entityLoadByPK("Blog", application.BlogDbObj.getBlogId())>--->
<!---Convert it to a cf query --->
<!---<cfset blogQry = EntityToQuery( BlogDbObj )>--->
<cfdump var="#Data#">
	
<cfwddx
	action="cfml2wddx"
	input="#Data#"
	output="blogDataXml"
	/>
	
<cffile action="write" file="#destination#/#dataFileName#.txt" output="#blogDataXml#">
	
<!---****************************************************************************************
Map Provider Table
*****************************************************************************************--->
	
<cfset dataFileName = "getMapProvider">
	
<cfquery name="Data" datasource="#dsn#">
	SELECT 
      MapProvider
  	FROM MapProvider
	ORDER BY MapProvider
</cfquery>
		
<!---<cfset BlogDbObj = entityLoadByPK("Blog", application.BlogDbObj.getBlogId())>--->
<!---Convert it to a cf query --->
<!---<cfset blogQry = EntityToQuery( BlogDbObj )>--->
<cfdump var="#Data#">
	
<cfwddx
	action="cfml2wddx"
	input="#Data#"
	output="blogDataXml"
	/>
	
<cffile action="write" file="#destination#/#dataFileName#.txt" output="#blogDataXml#">
	
<!---****************************************************************************************
Map Type Table
*****************************************************************************************--->
	
<cfset dataFileName = "getMapType">
	
<cfquery name="Data" datasource="#dsn#">
	SELECT        
	dbo.MapType.MapType, 
	dbo.MapType.MapProviderRef, 
	dbo.MapProvider.MapProvider
	FROM dbo.MapType INNER JOIN
    dbo.MapProvider ON dbo.MapType.MapProviderRef = dbo.MapProvider.MapProviderId
	ORDER BY MapType
</cfquery>
		
<!---<cfset BlogDbObj = entityLoadByPK("Blog", application.BlogDbObj.getBlogId())>--->
<!---Convert it to a cf query --->
<!---<cfset blogQry = EntityToQuery( BlogDbObj )>--->
<cfdump var="#Data#">
	
<cfwddx
	action="cfml2wddx"
	input="#Data#"
	output="blogDataXml"
	/>
	
<cffile action="write" file="#destination#/#dataFileName#.txt" output="#blogDataXml#">
	
<!---****************************************************************************************
Media Type Table
*****************************************************************************************--->
	
<cfset dataFileName = "getMediaType">
	
<cfquery name="Data" datasource="#dsn#">
	SELECT
      MediaTypeStrId
      ,MediaType
      ,Description
  	FROM MediaType
  	ORDER BY MediaType
</cfquery>
		
<!---<cfset BlogDbObj = entityLoadByPK("Blog", application.BlogDbObj.getBlogId())>--->
<!---Convert it to a cf query --->
<!---<cfset blogQry = EntityToQuery( BlogDbObj )>--->
<cfdump var="#Data#">
	
<cfwddx
	action="cfml2wddx"
	input="#Data#"
	output="blogDataXml"
	/>
	
<cffile action="write" file="#destination#/#dataFileName#.txt" output="#blogDataXml#">
	
<!---****************************************************************************************
Mime Type Table
*****************************************************************************************--->
	
<cfset dataFileName = "getMimeType">
	
<cfquery name="Data" datasource="#dsn#">
	SELECT 
      MimeType
      ,Extension
      ,Description
  	FROM MimeType
	ORDER BY MimeType
</cfquery>
		
<!---<cfset BlogDbObj = entityLoadByPK("Blog", application.BlogDbObj.getBlogId())>--->
<!---Convert it to a cf query --->
<!---<cfset blogQry = EntityToQuery( BlogDbObj )>--->
<cfdump var="#Data#">
	
<cfwddx
	action="cfml2wddx"
	input="#Data#"
	output="blogDataXml"
	/>
	
<cffile action="write" file="#destination#/#dataFileName#.txt" output="#blogDataXml#">
	
<!---****************************************************************************************
Role Table
*****************************************************************************************--->
	
<cfset dataFileName = "getRole">
	
<cfquery name="Data" datasource="#dsn#">
	SELECT
      #BlogId# as BlogRef
      ,RoleUuid
      ,RoleName
      ,Description
  	FROM Role
	ORDER BY RoleName
</cfquery>
		
<!---<cfset BlogDbObj = entityLoadByPK("Blog", application.BlogDbObj.getBlogId())>--->
<!---Convert it to a cf query --->
<!---<cfset blogQry = EntityToQuery( BlogDbObj )>--->
<cfdump var="#Data#">
	
<cfwddx
	action="cfml2wddx"
	input="#Data#"
	output="blogDataXml"
	/>
	
<cffile action="write" file="#destination#/#dataFileName#.txt" output="#blogDataXml#">
	
<!---****************************************************************************************
Role Capability Table
*****************************************************************************************--->
	
<cfset dataFileName = "getRoleCapability">
	
<cfquery name="Data" datasource="#dsn#">
	SELECT        
	dbo.RoleCapability.BlogRef, 
	dbo.RoleCapability.RoleRef, 
	dbo.Role.RoleName, 
	dbo.RoleCapability.CapabilityRef, 
	dbo.Capability.CapabilityName
	FROM dbo.Role INNER JOIN
    dbo.RoleCapability ON dbo.Role.RoleId = dbo.RoleCapability.RoleRef INNER JOIN
    dbo.Capability ON dbo.RoleCapability.CapabilityRef = dbo.Capability.CapabilityId
</cfquery>
		
<!---<cfset BlogDbObj = entityLoadByPK("Blog", application.BlogDbObj.getBlogId())>--->
<!---Convert it to a cf query --->
<!---<cfset blogQry = EntityToQuery( BlogDbObj )>--->
<cfdump var="#Data#">
	
<cfwddx
	action="cfml2wddx"
	input="#Data#"
	output="blogDataXml"
	/>
	
<cffile action="write" file="#destination#/#dataFileName#.txt" output="#blogDataXml#">
	
<!---****************************************************************************************
Theme Table
*****************************************************************************************--->
	
<cfset dataFileName = "getTheme">
	
<cfquery name="Data" datasource="#dsn#">
	SELECT        
	dbo.Theme.BlogRef, 
	dbo.Theme.KendoThemeRef, 
	dbo.KendoTheme.KendoTheme, 
	dbo.Theme.ThemeSettingRef, 
	dbo.Theme.ThemeAlias, 
	ThemeName,
	dbo.Theme.ThemeGenre, 
	dbo.Theme.SelectedTheme, 
	dbo.Theme.UseTheme, 
    dbo.Theme.DarkTheme
	FROM dbo.Theme INNER JOIN
    dbo.KendoTheme ON dbo.Theme.KendoThemeRef = dbo.KendoTheme.KendoThemeId
	ORDER BY ThemeName
</cfquery>
		
<!---<cfset BlogDbObj = entityLoadByPK("Blog", application.BlogDbObj.getBlogId())>--->
<!---Convert it to a cf query --->
<!---<cfset blogQry = EntityToQuery( BlogDbObj )>--->
<cfdump var="#Data#">
	
<cfwddx
	action="cfml2wddx"
	input="#Data#"
	output="blogDataXml"
	/>
	
<cffile action="write" file="#destination#/#dataFileName#.txt" output="#blogDataXml#">
	
<!---****************************************************************************************
Theme Setting Table
*****************************************************************************************--->
	
<cfset dataFileName = "getThemeSetting">
	
<cfquery name="Data" datasource="#dsn#">
	SELECT      
	dbo.Theme.ThemeId,
	dbo.Theme.ThemeName,
	dbo.ThemeSetting.FontRef, 
	dbo.Font.Font as BodyFont, 
	dbo.ThemeSetting.FontSize, 
	dbo.ThemeSetting.FontSizeMobile, 
	dbo.ThemeSetting.Breakpoint, 
	dbo.ThemeSetting.ContentWidth, 
	dbo.ThemeSetting.MainContainerWidth, 
    dbo.ThemeSetting.SideBarContainerWidth, 
	dbo.ThemeSetting.SiteOpacity, 
	dbo.ThemeSetting.FavIconHtml, 
	dbo.ThemeSetting.IncludeBackgroundImages, 
	dbo.ThemeSetting.BlogBackgroundImage, 
    dbo.ThemeSetting.BlogBackgroundImageMobile, 
	dbo.ThemeSetting.BlogBackgroundImageRepeat, 
	dbo.ThemeSetting.BlogBackgroundImagePosition, 
	dbo.ThemeSetting.BlogBackgroundColor, 
    dbo.ThemeSetting.StretchHeaderAcrossPage, 
	dbo.ThemeSetting.HeaderBackgroundColor, 
	dbo.ThemeSetting.HeaderBackgroundImage, 
	dbo.ThemeSetting.HeaderBodyDividerImage, 
	dbo.ThemeSetting.MenuFontRef, 
	MenuFont.Font AS MenuFont, 
    dbo.ThemeSetting.CoverKendoMenuWithMenuBackgroundImage, 
	dbo.ThemeSetting.LogoImageMobile, 
	dbo.ThemeSetting.LogoMobileWidth, 
	dbo.ThemeSetting.LogoImage, 
	dbo.ThemeSetting.LogoPaddingTop, 
    dbo.ThemeSetting.LogoPaddingRight, 
	dbo.ThemeSetting.LogoPaddingLeft, 
	dbo.ThemeSetting.LogoPaddingBottom, 
	dbo.ThemeSetting.DefaultLogoImageForSocialMediaShare, 
	dbo.ThemeSetting.BlogNameTextColor, 
    dbo.ThemeSetting.BlogNameFontRef, 
	BlogNameFont.Font AS BlogNameFont, 
	dbo.ThemeSetting.BlogNameFontSize, 
	dbo.ThemeSetting.BlogNameFontSizeMobile, 
	dbo.ThemeSetting.MenuBackgroundImage, 
    dbo.ThemeSetting.AlignBlogMenuWithBlogContent, 
	dbo.ThemeSetting.TopMenuAlign, 
	dbo.ThemeSetting.FooterImage, 
	dbo.ThemeSetting.WebPImagesIncluded
	FROM            dbo.ThemeSetting INNER JOIN
	dbo.Theme ON dbo.ThemeSetting.ThemeSettingId = dbo.Theme.ThemeSettingRef INNER JOIN
	dbo.Font ON dbo.ThemeSetting.FontRef = dbo.Font.FontId INNER JOIN
	dbo.Font AS BlogNameFont ON dbo.ThemeSetting.BlogNameFontRef = BlogNameFont.FontId INNER JOIN
	dbo.Font AS MenuFont ON dbo.ThemeSetting.MenuFontRef = MenuFont.FontId
</cfquery>
		
<!---<cfset BlogDbObj = entityLoadByPK("Blog", application.BlogDbObj.getBlogId())>--->
<!---Convert it to a cf query --->
<!---<cfset blogQry = EntityToQuery( BlogDbObj )>--->
<cfdump var="#Data#">
	
<cfwddx
	action="cfml2wddx"
	input="#Data#"
	output="blogDataXml"
	/>
	
<cffile action="write" file="#destination#/#dataFileName#.txt" output="#blogDataXml#">
	
<!---****************************************************************************************
User Role Table
*****************************************************************************************--->
	
<cfset dataFileName = "getUserRole">
	
<cfquery name="Data" datasource="#dsn#">
	SELECT   
		#BlogId# as BlogRef,
		dbo.UserRole.UserRoleId, 
		dbo.UserRole.UserRef, 
		dbo.Users.FullName, 
		dbo.UserRole.RoleRef, 
		dbo.Role.RoleName, 
		dbo.UserRole.Date
	FROM dbo.UserRole INNER JOIN
    dbo.Users ON dbo.UserRole.UserRef = dbo.Users.UserId INNER JOIN
    dbo.Role ON dbo.UserRole.RoleRef = dbo.Role.RoleId
</cfquery>
		
<!---<cfset BlogDbObj = entityLoadByPK("Blog", application.BlogDbObj.getBlogId())>--->
<!---Convert it to a cf query --->
<!---<cfset blogQry = EntityToQuery( BlogDbObj )>--->
<cfdump var="#Data#">
	
<cfwddx
	action="cfml2wddx"
	input="#Data#"
	output="blogDataXml"
	/>
	
<cffile action="write" file="#destination#/#dataFileName#.txt" output="#blogDataXml#">
	
<!---****************************************************************************************
Users Table
*****************************************************************************************--->
	
<cfset dataFileName = "getUsers">
	
<cfquery name="Data" datasource="#dsn#">
	SELECT 
      #BlogId# as BlogRef
      ,'' as MediaRef
      ,'MyFirstName' as FirstName
      ,'MyLastName' as LastName
      ,'MyFirstName MyLastName' as FullName
      ,'' as DisplayName
      ,'' as Email
      ,'' as Website
      ,'' as Biography
      ,Status
      ,'Admin' as UserName
      ,'' as Password
      ,'' as Salt
      ,'MyPassword' as TemporaryPassword
      ,1 as ChangePasswordOnLogin
      ,'' as LastLogin
      ,1 as Active
      ,'' as SecurityAnswer1
      ,'' as SecurityAnswer2
      ,'' as SecurityAnswer3
      ,'' as SecurityRandomQuestion
      ,'' as SecurityRandomAnswer
  	FROM Users
	ORDER BY User
</cfquery>
		
<!---<cfset BlogDbObj = entityLoadByPK("Blog", application.BlogDbObj.getBlogId())>--->
<!---Convert it to a cf query --->
<!---<cfset blogQry = EntityToQuery( BlogDbObj )>--->
<cfdump var="#Data#">
	
<cfwddx
	action="cfml2wddx"
	input="#Data#"
	output="blogDataXml"
	/>
	
<cffile action="write" file="#destination#/#dataFileName#.txt" output="#blogDataXml#">
	


	
	
