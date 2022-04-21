<html lang="en-US"><head> <title>Welcome to the Galaxie Blog installer</title>
<meta http-equiv="content-type" content="text/html; charset=utf-8" />
<meta name="viewport" content="width=device-width, initial-scale=1">
<meta name="title" content="Welcome to Galaxie Blog" />
<cfsilent>
<cfparam name="kendoTheme" default="default">
</cfsilent>
<html>
<head>
    <style>html { font-size: 14px; font-family: Arial, Helvetica, sans-serif; }</style>
    <title></title>
    <link rel="stylesheet" href="https://kendo.cdn.telerik.com/2020.3.1021/styles/kendo.common.min.css" />
	<!--- Attach the style for the theme --->
	<a href=""></a>
    <cfoutput>
	<link rel="stylesheet" href="../common/libs/kendoCore/styles/kendo.#kendoTheme#.min.css" />
    <link rel="stylesheet" href="../common/libs/kendoCore/styles/kendo.#kendoTheme#.mobile.min.css" />
	</cfoutput>

    <script src="../../common/libs/kendoCore/js/jquery.min.js"></script>
    <script src="../../common/libs/kendoCore/js/kendo.ui.core.min.js"></script>
	
	<script type="text/javascript" src="../../common/libs/momentJs/moments.js"></script>
</head>
<style>
	
	/* Table classes */
	/* Applies a border on the outside of the table */
	table.tableBorder {
		border: 1px solid black;
		width: 100%;
		border-radius: 3px; 
		border-spacing: 0;
	}
	
	td.border {
		border-top: 1px solid #ddd;
	}
</style>
<body>
<script src="//cdnjs.cloudflare.com/ajax/libs/jszip/2.4.0/jszip.min.js"></script>
	
<form action="step2SiteInfo.cfm" method="post">
<table align="center" class="k-content tableBorder" width="100%" cellpadding="5" cellspacing="5">
	<tr>
		<td>
			<table align="center" class="k-content" width="100%" cellpadding="2" cellspacing="0">
			  <!-- Border -->
			  <tr height="2px">
				  <td align="left" valign="top" colspan="2" class="k-header border"></td>
			  </tr>
			  <tr>
				  <td align="left" valign="top" colspan="2" class="k-header" style="font-weight: bold">
					  Welcome to the Galaxie Blog Installer!</br>
					  (Step 1 of 6)
				  </td>
			  </tr>
			  <!-- Border -->
			  <tr height="2px">
				  <td align="left" valign="top" colspan="2" class="k-content border"></td>
			  </tr>
			  <tr>
				  <td>
				  	<img src="../images/welcome.jpg" alt="Welcome!" style="float: left; padding:5px;">
				  </td>
				  <td align="left" valign="top">
					<p>
					 This application will attempt to setup Galaxie Blog so you can immediately begin using it. Before getting started, there are a few things you should know:
					</p>

					<ul>
						<li>First, we need to know what your new blog URL will be, and are you using SSL?</li>
						<li>Second, the installer will not be able to create the DSN or database for you. You need to ensure your DSN is created and it points to a valid DSN.</li>
						<li>Third, we will guide you to manually add the blog folder to one short variable in the code. This is the only change that you will make to the actual code when installing the blog, the installer will do the rest for you.</li>
						<li>Galaxie Blog should support <i>any</i> modern database, feel free to use whatever you want to use. However, depening upon the dialect we may have to guide you through some additional steps. </li>
						<li>After the installer creates or selects the DSN, it will then attempt to configure the initial database. If you have existing tables in the database this might create a conflict. To avoid any conflict- you should install Galaxie Blog into an empty database.</li>
						<li>The last thing the installer will do is prompt you for some basic settings, like your name, email address, etc. Once done with this step the installer is going to edit itself so it cannot be run again. <b>This is intentional.</b> Instructions on how to run the installer again may be found in the core Galaxie Blog documentation.</li>
					</ul><br/>
					<p>Important note: if you change your location or database at a later time, you can always rerun this installer by changing the resintallBlog argument to true in the root application.cfc template. Please take note of this for future reference.</p>
					<br/>
					<input type="submit" value="Let's Get Started!" class="k-button k-primary" />
					  
				  </td>
			  </tr>
			  <!-- Border -->
			  <tr height="2px">
				  <td align="left" valign="top" colspan="2" class="k-content border"></td>
			  </tr>
			</table>
		</td>
	</tr>
</table>
</form>
