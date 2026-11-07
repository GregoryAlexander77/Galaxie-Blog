/*
	New comments as they come in (2026-11-07, owner: "render the new comments on the front page"). Listens on galaxiePulse's
	"comments" channel. When a post shown on this page gets a new (approved) comment, its comment list is fetched again from
	common/services/liveComments.cfm - the same markup the page uses - and swapped in: the new ones are marked "New" and fade in,
	the count goes up, and a closed list says how many are new. The Recent Comments pod is refreshed the same way.
	Nothing is fetched for posts that aren't on the page.
*/
(function () {
	"use strict";
	function start(baseUrl) {
		if (!window.galaxiePulse) { return; }
		var counts = document.querySelectorAll(".galaxieCommentCount[data-post-id]");
		var pod = document.querySelector(".galaxieRecentComments");
		if (!counts.length && !pod) { return; }   // nothing on this page shows comments

		var style = document.createElement("style");
		style.textContent = "@keyframes galaxieCommentNewFade { from { background-color: rgba(255, 196, 0, .35); } to { background-color: transparent; } }"
			+ " tr.galaxieCommentNew > td { animation: galaxieCommentNewFade 6s ease-out; }"
			+ " .galaxieCommentNewBadge { display: inline-block; margin-left: 8px; padding: 0 7px; border-radius: 9px; font-size: 75%; font-weight: bold; background: #e8a400; color: #fff; vertical-align: middle; }";
		document.head.appendChild(style);

		function postIdsOnPage() {
			var ids = {};
			Array.prototype.forEach.call(document.querySelectorAll(".galaxieCommentCount[data-post-id]"), function (el) { ids[el.getAttribute("data-post-id")] = true; });
			return Object.keys(ids);
		}
		function shownIds(box) {
			var ids = {};
			Array.prototype.forEach.call(box.querySelectorAll('tr[id^="c"]'), function (tr) { ids[tr.id] = true; });
			return ids;
		}
		// The same wording as the page (includes/templates/blogContentHtml.cfm).
		function commentSentence(n) { return n === 0 ? "No comments yet." : n === 1 ? "There is 1 comment." : "There are " + n + " comments."; }
		function isOpen(box) { return !!box && window.getComputedStyle(box).display !== "none"; }
		function addControl(postId, countEl) {
			// The "Show Comments" arrow only exists once a post has comments: add it for a post's first comment.
			if (document.getElementById("commentControl" + postId)) { return; }
			var p = countEl.closest("p");
			if (!p) { return; }
			// Matching the list as it is: a post's own page shows its comments open.
			var open = isOpen(document.getElementById("comment" + postId));
			var wrap = document.createElement("span");
			wrap.innerHTML = '<span id="commentControl' + postId + '" class="collapse k-icon ' + (open ? 'k-i-sort-asc-sm' : 'k-i-sort-desc-sm') + ' k-primary" style="width: 35px; height:35px; border-radius: 50%;" onClick="handleComments(this)"></span>&nbsp;&nbsp;<span id="commentControlLabel' + postId + '">' + (open ? 'Hide Comments' : 'Show Comments') + '</span><br/><br/>';
			var after = p;
			while (after.nextElementSibling && after.nextElementSibling.tagName === "P") { after = after.nextElementSibling; }
			after.parentNode.insertBefore(wrap, after.nextSibling);
		}
		function refreshPost(postId) {
			var box = document.getElementById("comment" + postId);
			fetch(baseUrl + "/common/services/liveComments.cfm?postId=" + encodeURIComponent(postId), { credentials: "same-origin", cache: "no-store" })
				.then(function (r) { return r.ok ? r.json() : null; })
				.then(function (answer) {
					if (!answer || !answer.success) { return; }
					var before = box ? shownIds(box) : {};
					var newCount = 0;
					if (box) {
						box.innerHTML = answer.html;
						Array.prototype.forEach.call(box.querySelectorAll('tr[id^="c"]'), function (tr) {
							if (before[tr.id]) { return; }
							newCount++;
							tr.classList.add("galaxieCommentNew");
							if (tr.nextElementSibling) { tr.nextElementSibling.classList.add("galaxieCommentNew"); }
							var cell = tr.querySelector("td");
							if (cell) { var badge = document.createElement("span"); badge.className = "galaxieCommentNewBadge"; badge.textContent = "New"; cell.appendChild(badge); }
						});
					}
					Array.prototype.forEach.call(document.querySelectorAll('.galaxieCommentCount[data-post-id="' + postId + '"]'), function (el) {
						el.textContent = commentSentence(Number(answer.count) || 0);
						if (answer.count > 0) { addControl(postId, el); }
					});
					// A closed list says how many are new.
					var label = document.getElementById("commentControlLabel" + postId);
					if (label && newCount && box && !isOpen(box)) {
						label.textContent = "Show Comments (" + newCount + " new)";
					}
				})
				.catch(function () {});
		}
		// A page can have the pod twice (the side bar and the slide-out panel), each made for where it sits: one fetch per kind.
		function refreshPod() {
			var kinds = {};
			Array.prototype.forEach.call(document.querySelectorAll(".galaxieRecentComments"), function (podBox) {
				var key = (podBox.getAttribute("data-side-bar") || "div") + "|" + (podBox.getAttribute("data-modern") === "1" ? 1 : 0) + "|" + (podBox.getAttribute("data-dark") === "1" ? 1 : 0);
				(kinds[key] = kinds[key] || []).push(podBox);
			});
			Object.keys(kinds).forEach(function (key) {
				var parts = key.split("|");
				fetch(baseUrl + "/common/services/liveComments.cfm?part=recentComments&sideBar=" + encodeURIComponent(parts[0]) + "&modern=" + parts[1] + "&dark=" + parts[2], { credentials: "same-origin", cache: "no-store" })
					.then(function (r) { return r.ok ? r.json() : null; })
					.then(function (answer) {
						if (answer && answer.success && answer.html) { kinds[key].forEach(function (podBox) { podBox.innerHTML = answer.html; }); }
					})
					.catch(function () {});
			});
		}

		galaxiePulse.subscribe("comments", function (events, info) {
			var onPage = postIdsOnPage(), changed = {};
			if (info.reset) {
				onPage.forEach(function (id) { changed[id] = true; });
			} else {
				events.forEach(function (e) { if (e && e.postId && onPage.indexOf(String(e.postId)) !== -1) { changed[String(e.postId)] = true; } });
			}
			Object.keys(changed).forEach(refreshPost);
			refreshPod();
		});
	}
	window.galaxieLiveComments = { start: start };
})();
