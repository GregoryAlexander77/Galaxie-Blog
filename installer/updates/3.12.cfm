<!--- description: Adds any fonts and themes (including the Joshua Tree themes) that are missing. --->
<!---
	This used to be part of the update logic in ProxyController.cfc. It now only adds the missing records. It does not overwrite the ones that are there (which is what it used to do for fonts), as many databases have never had their version updated (the version is 3 or 3.57 even though the blog is current) and this must not undo changes that a user has made.
--->
<cfset seedTables("Font,Theme", false)>
