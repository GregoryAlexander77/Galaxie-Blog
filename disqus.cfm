<!--- Note: the disqus_shortname, URL and identifier are passed to this page via the URL. --->
<div id="disqus_thread"></div>
<script type="text/javascript">
	/**
	*  RECOMMENDED CONFIGURATION VARIABLES: EDIT AND UNCOMMENT THE SECTION BELOW TO INSERT DYNAMIC VALUES FROM YOUR PLATFORM OR CMS.
	*  LEARN WHY DEFINING THESE VARIABLES IS IMPORTANT: https://disqus.com/admin/universalcode/#chr(35)#configuration-variables*/
	
	var disqus_config = function () {
	var disqus_shortname = '<cfoutput>#URL.alias#</cfoutput>';
	this.page.url = '<cfoutput>#URL.url#</cfoutput>';  // Replace PAGE_URL with your page's canonical URL variable
	this.page.identifier = '<cfoutput>#URL.Id#</cfoutput>'; // Replace PAGE_IDENTIFIER with your page's unique identifier variable
	};
	
	(function() { // DON'T EDIT BELOW THIS LINE */
		var d = document, s = d.createElement('script');
		s.src = 'https://gregorys-blog.disqus.com/embed.js';
		s.setAttribute('data-timestamp', +new Date());
		(d.head || d.body).appendChild(s);
	})();
</script>