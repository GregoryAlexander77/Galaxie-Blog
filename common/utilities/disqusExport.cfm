<cfscript>
datasource="gregorysBlog";
siteUrl="gregorysblog.org"
	
query function getCommentsForEntry(required string id) {
	return queryExecute("select comment, email, entryidfk, id, name, posted, website from tblblogcomments where entryidfk = :id order by posted asc", {id=id}, {datasource="#datasource#"});
}

string function getLink(required struct entry) {
	var alias = entry.alias?:entry.id;
	var link = "http://#siteUrl#/#year(entry.posted)#/#month(entry.posted)#/#day(entry.posted)#/#alias#";
	return link;
}

string function generateCommentXML(required query comments) {
	var s = "";
	for(var i=1; i<=comments.recordCount; i++) {
		var comment = comments.getRow(i);
		var postdate = dateConvert("local2utc", comment.posted);
		var website = comment.website ?: "";
		//modify the comment if it is too short
		if(len(comment.comment) < 3) comment.comment &= "  ";
		//i have double escaped shit, unescpae it
		comment.comment = replace(comment.comment, "&amp;quot;", """", "all");
		
		s &= "<wp:comment>
		<wp:comment_id>m1_#comment.id#</wp:comment_id>
		<wp:comment_author>#xmlFormat(comment.name)#</wp:comment_author>
		<wp:comment_author_email>#xmlFormat(comment.email)#</wp:comment_author_email>
		<wp:comment_author_url>#xmlFormat(website)#</wp:comment_author_url>
		<wp:comment_author_IP></wp:comment_author_IP>
		<wp:comment_date_gmt>#dateFormat(postdate,'yyyy-mm-dd')# #timeformat(postdate, 'HH:nn:ss')#</wp:comment_date_gmt>
		<wp:comment_content><![CDATA[#comment.comment#]]></wp:comment_content>
        <wp:comment_approved>1</wp:comment_approved>
        <wp:comment_parent>0</wp:comment_parent>
      	</wp:comment>";

	}
	
	return s;	
}

string function generateItemXML(required struct entry, required query comments) {
	var postdate = dateConvert("local2utc", entry.posted);

	var s = "
	<item>
	<title>#entry.title#</title>
	<link>#getLink(entry)#</link>
	<content:encoded>#xmlFormat(entry.body)#</content:encoded>
	<wp:post_date_gmt>#dateFormat(postdate,'yyyy-mm-dd')# #timeformat(postdate, 'HH:nn:ss')#</wp:post_date_gmt>
	<wp:comment_status>open</wp:comment_status>
	";
	
	s &= generateCommentXML(comments);
	
	s &= "</item>";

	return s;
}

// Specifies the 'index' to start
start = 5003;
// Specifies number of rows to process
total = 2000;

entries = queryExecute("select body, alias, id, posted, title from tblblogentries where released = 1 order by posted asc", {}, {datasource="gregorysBlog"});
//writeDump(entries);

items = "";
commentCount = 0;

for(i=1; i<=entries.recordCount; i++) {
	entry = entries.getRow(i);
	if(i == 1) {
		firstEntry = entry.title;
		firstPost = entry.posted;
	}
	if(i == entries.recordCount) { 
		lastEntry = entry.title;
		lastPost = entry.posted;
	}
	
	//writeDump(entry);
	comments = getCommentsForEntry(entry.id);
	commentCount += comments.recordCount;
	//writeDump(comments);
	itemString = generateItemXML(entry, comments);
	//probably bad string perf here, don't care
	items &= itemString;
}

prefix = '<?xml version="1.0" encoding="UTF-8"?>
<rss version="2.0"
  xmlns:content="http://purl.org/rss/1.0/modules/content/"
  xmlns:dsq="http://www.disqus.com/"
  xmlns:dc="http://purl.org/dc/elements/1.1/"
  xmlns:wp="http://wordpress.org/export/1.0/"
>
  <channel>';
postfix = '</channel></rss>';

finalContent = prefix & items & postfix;

//writeoutput(htmlcodeformat(finalContent));
//filename is based on start_count
filename = expandPath("./comments_#start#_#total#.xml");
fileWrite(filename, finalContent);
writeoutput("Wrote #entries.recordCount# entries/#commentCount# comments to #filename#<br/>");
writeoutput("First entry was #firstEntry# on #dateFormat(firstPost)#<br/>Last was #lastEntry# on #dateFormat(lastPost)#<br/>");
</cfscript>