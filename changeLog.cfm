If there are db changes (ie new fonts, themes, etc), generate the new installer files by going to common/data/generateDataFiles.cfm and download the new txt files found in the common/data/files folder on the server. 
Place the new files into the /installer/dataFiles folder that you will upload to GitHub. Don't overwrite the user files (getUsers, getUserRole, etc).
Move the other changed files from the blog to the git hub folder.
Develop and upload any database installer. Use the installer/update/updateDb.cfm template to do so.
Update the version in the Blog.cfc template.
Change the version at http://www.gregoryalexander.com/common/services/gregorysBlog/version.cfm

V.3.57 
Application.cfc
index.cfm
about.cfm
addCommentSubscribe.cfm
/admin/index.cfm
/admin/logonPage.cfm
/includes/pods/subscribe.cfm
/includes/templates/footerHtml.cfm
/includes/templates/renderKendoCardGrid.cfm
/includes/layers/topMenu.cfm
/org/camden/blog/blog.cfc


v3.15
/application.cfc
/about.cfm
/addCommentSubscribe.cfm
/searchResults.cfm
/admin/index.cfm
/admin/logonPage.cfm
/common/cfc/Image.cfc
/common/cfc/ProxyController.cfc
/common/cfc/JSoup.cfc
/common/cfc/db/ConditionalContent.cfc
/common/cfc/db/ContentTemplate.cfc
/common/cfc/db/ContentTemplateContentZone.cfc
/common/cfc/db/ContentTemplateTheme.cfc
/common/cfc/db/ContentTemplateType.cfc
/common/cfc/db/ContentZone.cfc
/common/cfc/db/CustomWindowContent.cfc
/common/cfc/db/Page.cfc
/common/cfc/db/PageContentTemplate.cfc
/common/cfc/db/PageMode.cfc
/common/cfc/db/PageType.cfc
/common/cfc/db/Pod.cfc
/common/codeWriter/themeSettings/index.cfm
/common/data/generateDataFiles.cfm
/common/db/importBlog.cfm
/common/libs/jQuery/jQueryNotify/ (entire lib)
/common/libs/jQuery/kendoUiExtended/ (entire lib)
/common/libs/uppy/uppyCss.cfm
/common/libs/kendo/js/kendo.all.min.js
/includes/layers/sideBar.cfm
/includes/layers/topMenu.cfm
/includes/pods/archives.cfm
/includes/templates/blogContentCss.cfm
/includes/templates/blogContentHtml.cfm
/includes/templates/blogJsContent.cfm
/includes/templates/footerHtml.cfm
/includes/templates/getPageSettings.cfm
/includes/templates/globalAndBodyCss.cfm
/includes/templates/head.cfm
/includes/templates/PageSettings.cfm
/includes/templates/responsiveJs.cfm
/includes/templates/tailEndScripts.cfm
/includes/templates/topMenuCss.cfm
/includes/templates/topMenuHtml.cfm
/includes/windows/adminInterface.cfm
/installer/insertData.cfm
/org/camden/blog.cfc

delete
/common/libs/jQuery/jQueryNotifyEggplant (entire folder)
/common/cfc/db/Container.cfc
/common/cfc/db/galaxieDb/CustomTemplate.cfc
/common/data/getCustomTemplate.txt
/common/data/backup/getCustomTemplate.txt
/common/data/files/getCustomTemplate.txt

From Gregorysblog.org
adminInterface.cfm
Renderer.cfc

Delete

v3.14
/includes/templates.blogContentCss.cfm
/includes/templates.tailEndScripts.cfm
/includes/templates.pageSettings.cfm
/org/camden/blog.cfc

-----------------------------------------------------------
V3.13
application.cfc
/admin/latestVersionCheck.cfm
/includes/windows/adminInterface.cfm
new folder /installer/update
/installer/update/updateDb.cfm
/installer/update/v3_12.cfm
/org/camden/blog.cfc

-----------------------------------------------------------
Version 3.12

Change
June
Application.cfc
/admin/Application.cfc
/index.cfm
/robots.txt
blog.cfc
ProxyController.cfc
Renderer.cfc
StringUtils.cfc
/common/function/page.cfm
/common/libs/prism/ all of the common libs prism folder, including plugins
/common/libs/tinymce/skins/ui (add entire ui folder)
/includes/layers/sidebar.cfm
/includes/pods/tagCloud.cfm
/includes/templates/js/tinymce.cfm
/includes/templates/blogJsContent.cfm
/includes/templates/blogContentHtml.cfm
/includes/templates/coreLogic.cfm
/includes/templates/getPost.cfm
/includes/templates/head.cfm
/includes/templates/pageSettings.cfm
/includes/templates/responsiveJs.cfm
/includes/templates/tailEndScripts.cfm
/includes/windows/adminInterface.cfm




* Blog.cfc
* /includes/windows/adminInterface.cfm
* about.cfm
* /templates/coreLogic.cfm
* RecentComments.cfm
* ProxyController.cfc
* JSoup.cfc
* Renderer.cfc
* blog.cfc
* adminInterface.cfm
* recentComments.cfm
* coreLogic.cfm
* blogContentHtml.cfm
* /includes/layers/sidebar.cfm
* /includes/templates/pageSettings.cfm
* /includes/templates/sideBar.cfm
* /includes/templates/sideBarPanel.cfm
* Renderer.cfc
* /includes/templates/responsiveJs.cfm
* /includes/templates/head.cfm

Cleaning up text artifacts, added google analytics as a blog option, sorting issue with the posts grid, upload bug with enclosure image, twitter and facebook sharing Galaxie Blog Directive bug, making YouTube and Vimeo media responsive instead of having fixed heigth and width
* Application.cfc
* /common/cfc/ProxyController.cfc
* /includes/common/grids/posts.cfm
* /includes/windows/adminInterface.cfm
* blog.cfc
* Renderer.cfc
* /templates/coreLogic.cfm
* /common/db/galaxieDb/BlogOption.cfc
* /includes/templates/head.cfm
* /includes/templates/js/tinyMce.cfm
* /includes/templates/blogContentCss.cfm
* /common/libs/tinymce/plugins/media/plugin.js
* /common/libs/tinymce/plugins/media/plugin.min.js
* galaxiePlayer.cfm

Added server side validation when a post is missing, WebVtt interface error, adding the textpattern tinymce plugin to support markdown editing, added emoticon support in the editor, improved ldJson, improved time zone handling for RSS (getting the time zone from the blog owners timezone instead of where the server is located),
/common/cfc/DateTime.cfc
/common/cfc/Jsoup.cfc
/common/cfc/ProxyController.cfc
/common/cfc/Renderer.cfc
/common/cfc/StringUtils.cfc
/common/cfc/Udf.cfc 
/common/cfc/Renderer.cfc
/org/camden/blog/blog.cfc
/common/data/importBlogCfc.cfm
/includes/pods/tagCloud.cfm
/includes/layers/sideBar.cfm
/includes/templates/blogContentCss.cfm
/includes/templates/blogContentHtml.cfm
/includes/templates/blogJsContent.cfm
/includes/templates/coreLogic.cfm
/includes/templates/head.cfm
/includes/templates/pageSettings.cfm
/includes/templates/js/tinyMce.cfm
/includes/windows/adminInterface.cfm
/tags/parseses.cfm
addCommentSubscribe.cfm
about.cfm
googlesitemap.cfm
searchResults.cfm
robots.txt
/admin/index.cfm
/admin/login.cfm
/admin/loginPage.cfm
/common/cfc/db/Post.cfc
/installer/dataFiles/getThemeSetting.txt

Deleted 
/common/java/javaLoader/
/common/services/sendSubscriberEmail.cfm

Added:
/common/cfc/TimeZone.cfc
/common/services/handleFuturePost.cfm
/common/templates/getPost.cfm
/common/java/jsoup-1.15.1.jar
/images/background/gregoryalexander/purchased/antelopCanyon.webp
/images/background/gregoryalexander/purchased/antelopCanyonMobile.webp
/images/background/gregoryalexander/purchased/depositPhotos/abstractRed.webp
/images/background/gregoryalexander/purchased/depositPhotos/abstractRedMobile.webp
/images/background/gregoryalexander/purchased/depositPhotos/aquaTechLowRes.webp
/images/background/gregoryalexander/purchased/depositPhotos/aquaTechLowResMobile.webp
/images/background/gregoryalexander/purchased/depositPhotos/blueGearLowRes.webp
/images/background/gregoryalexander/purchased/depositPhotos/blueGearLowResMobile.webp
/images/background/gregoryalexander/purchased/depositPhotos/cumberlandFallsLowRes.webp
/images/background/gregoryalexander/purchased/depositPhotos/cumberlandFallsLowResMobile.webp
/images/background/gregoryalexander/purchased/depositPhotos/delicateArchLowRes.webp
/images/background/gregoryalexander/purchased/depositPhotos/delicateArchLowResMobile.webp
/images/background/gregoryalexander/purchased/depositPhotos/goldenGate.webp
/images/background/gregoryalexander/purchased/depositPhotos/goldenGateMobile.webp
/images/background/gregoryalexander/purchased/depositPhotos/onTheRoad.webp
/images/background/gregoryalexander/purchased/depositPhotos/onTheRoadMobile.webp
/images/background/gregoryalexander/purchased/depositPhotos/portofinoLowResMobile.webp
/images/background/gregoryalexander/purchased/depositPhotos/portofinoLowRes.webp
/images/background/gregoryalexander/purchased/depositPhotos/ranchLowRes.webp
/images/background/gregoryalexander/purchased/depositPhotos/ranchLowResMobile.webp
/images/background/gregoryalexander/purchased/depositPhotos/waveLowRes.webp
/images/background/gregoryalexander/purchased/depositPhotos/waveLowResMobile.webp
/images/background/gregoryalexander/purchased/depositPhotos/woodCreek.webp
/images/background/gregoryalexander/purchased/depositPhotos/woodCreekLowResMobile.webp
