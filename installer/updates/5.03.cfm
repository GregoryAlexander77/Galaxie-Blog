<!--- description: Galaxie 5.03: adds the column for how a post's hero heading moves (Hero style window). --->
<!--- DatabaseUpdater.cfc's ensureColumns() adds only what is missing; ORM may already have added it when the blog restarted. --->
<cfset ensureColumns("Post", [
	{ name: "HeroTextMotion", length: 20 }
])>
