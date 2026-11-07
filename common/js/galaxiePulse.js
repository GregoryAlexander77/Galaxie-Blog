/*
	Galaxie Blog live updates (2026-11-07). One small poller for anything that wants to know when something changed: new comments
	now, notifications later. It asks common/services/pulse.cfm "what changed since I last looked?" for every channel something on
	the page has subscribed to, in one request, every few seconds (Blog Options, Live Updates). Answering costs the server no
	database or disk work, and nothing is fetched beyond that small answer unless something changed.

	Use:
		galaxiePulse.init({ url: "/blog/common/services/pulse.cfm", seconds: 30 });   // once per page (the page's own settings)
		var stop = galaxiePulse.subscribe("comments", function (events, info) {
			// events: what changed since last time, eg. [{ postId: 14 }]; info.reset: true when the page should refresh everything
		});
		galaxiePulse.check();   // ask now (eg. right after the visitor posted a comment)
		stop();                 // stop listening; with no listeners left it stops asking

	It doesn't ask while the tab is hidden (and asks as soon as it's back), slows down when the server can't be reached, stops
	for good when the owner turns Live Updates off, and the first answer only sets where it starts: nothing on the page changes.
*/
(function () {
	"use strict";
	if (window.galaxiePulse) { return; }

	var settings = { url: "", seconds: 30 };
	var listeners = {};      // channel -> [function]
	var seen = {};           // channel -> last version seen (text)
	var timer = null, busy = false, failures = 0, stopped = false, started = false;

	function channels() {
		return Object.keys(listeners).filter(function (c) { return listeners[c].length; });
	}
	function wait() {
		var ms = settings.seconds * 1000;
		if (failures) { ms = Math.min(ms * Math.pow(2, failures), 10 * 60 * 1000); }
		return ms * (0.9 + Math.random() * 0.2);   // spread the visitors out a little
	}
	function schedule(ms) {
		clearTimeout(timer);
		if (stopped || !started || !channels().length) { return; }
		timer = setTimeout(ask, ms);
	}
	function tell(channel, events, info) {
		(listeners[channel] || []).slice().forEach(function (fn) {
			try { fn(events, info); } catch (e) { if (window.console) { console.error(e); } }
		});
	}
	function ask() {
		if (stopped || busy) { return; }
		var list = channels();
		if (!list.length) { return; }
		if (document.visibilityState === "hidden") { return; }   // asked again when the tab comes back
		busy = true;
		var query = list.map(function (c) { return c + ":" + (seen[c] || "0"); }).join(",");
		fetch(settings.url + "?c=" + encodeURIComponent(query), { credentials: "same-origin", cache: "no-store" })
			.then(function (r) { return r.ok ? r.json() : Promise.reject(r.status); })
			.then(function (answer) {
				busy = false;
				failures = 0;
				if (!answer || answer.on === false) { stopped = true; return; }
				if (answer.seconds) { settings.seconds = Math.max(10, Number(answer.seconds) || 30); }
				var found = answer.channels || {};
				Object.keys(found).forEach(function (channel) {
					var info = found[channel], before = seen[channel];
					seen[channel] = String(info.v);
					if (!before) { return; }   // the first answer only sets where this page starts
					if (info.reset || (info.events && info.events.length)) {
						tell(channel, info.events || [], { reset: !!info.reset, version: String(info.v) });
					}
				});
				schedule(wait());
			})
			.catch(function () {
				busy = false;
				failures = Math.min(failures + 1, 6);
				schedule(wait());
			});
	}

	document.addEventListener("visibilitychange", function () {
		if (document.visibilityState === "visible") { schedule(400); }
	});

	window.galaxiePulse = {
		init: function (options) {
			options = options || {};
			if (options.url) { settings.url = options.url; }
			if (options.seconds) { settings.seconds = Math.max(10, Number(options.seconds) || 30); }
			if (options.on === false) { stopped = true; return; }
			started = true;
			schedule(800);   // the first ask comes quickly, so the starting point is close to when the page was made
		},
		subscribe: function (channel, fn) {
			channel = String(channel || "").toLowerCase();
			if (!channel || typeof fn !== "function") { return function () {}; }
			(listeners[channel] = listeners[channel] || []).push(fn);
			if (!timer) { schedule(800); }
			return function () {
				listeners[channel] = (listeners[channel] || []).filter(function (f) { return f !== fn; });
			};
		},
		check: function () { schedule(300); },
		isOn: function () { return started && !stopped; }
	};
})();
