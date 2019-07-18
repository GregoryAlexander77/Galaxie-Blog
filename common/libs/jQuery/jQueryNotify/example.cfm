<!DOCTYPE html>
<html>
<head>
<meta http-equiv="Content-Type" content="text/html; charset=utf-8" />
<title>jQuery UI Notification Widget by Eric Hynds</title>
<!--- <link type="text/css" rel="stylesheet" href="notify.css">
<!--- <link type="text/css" rel="stylesheet" href="http://ajax.googleapis.com/ajax/libs/jqueryui/1.8/themes/redmond/jquery-ui.css" /> --->
<link type="text/css" rel="stylesheet" href="/cssweb/common/frameworks/jQueryPlugins/jQueryNotify/ui.notify.css">
<style type="text/css">form input { display:block; width:250px; margin-bottom:5px }</style>
<script src="/cssweb/common/frameworks/jquery-1.11.2.min.js" type="text/javascript"></script>
<script src="/cssweb/common/frameworks/jquery-ui-1.11.2.eggplant/jquery-ui.js" type="text/javascript"></script>
<script src="src/jquery.notify.js" type="text/javascript"></script> --->

<!--- We also will load files to create a notification jsQuery plugin. We are not using the Kendo notification script right now. The Kendo notification script is buggy without a doctype. See note at top of this page for more information.  --->
<link type="text/css" rel="stylesheet" href="/cssweb/common/frameworks/jQueryPlugins/jQueryNotify/ui.notify.css">
<link type="text/css" rel="stylesheet" href="/cssweb/common/frameworks/jQueryPlugins/jQueryNotify/notify.css">
<script src="/cssweb/common/frameworks/jquery-1.11.2.min.js" type="text/javascript"></script>
<!--- jQuery ui component. --->
<script src="/cssweb/common/frameworks/jquery-ui-1.11.2.eggplant/jquery-ui.js" type="text/javascript"></script>
<!--- Custom notification plugin with a title and an onclick event (which Kendo does not have).  --->
<script language="JavaScript" src="/cssweb/common/frameworks/jQueryPlugins/jQueryNotify/src/jquery.notify.js" type="text/javascript"></script>

<script type="text/javascript">
function create( template, vars, opts ){
	return $container.notify("create", template, vars, opts);
}

$(function(){
	// initialize widget on a container, passing in all the defaults.
	// the defaults will apply to any notification created within this
	// container, but can be overwritten on notification-by-notification
	// basis.
	$container = $("#container").notify();
	
	// create two when the pg loads
	//create("default", { title:'Default Notification', text:'Example of a default notification.  I will fade out after 5 seconds'});
	//create("sticky", { title:'Sticky Notification', text:'Example of a "sticky" notification.  Click on the X above to close me.'},{ expires:false });
	create("default", { title:'Clickable Notification', text:'Click on me to fire a callback. Do it quick though because I will fade out after 5 seconds.' }, 
		{
			click: function(e,instance){
				alert("Click triggered!\n\nTwo options are passed into the click callback: the original event obj and the instance object.");
			}
		});   
});
</script>

</head>
<body>

<!--- container to hold notifications --->
<div id="container" style="display:none">
    <div id="withIcon">
        <a class="ui-notify-close ui-notify-cross" href="#">x</a>
        <div style="float:left;margin:0 10px 0 0"><img src="#{icon}" alt="warning" /></div>
        <h1>#{title}</h1>
        <p>#{text}</p>
    </div>
</div>

</body>
</html>
