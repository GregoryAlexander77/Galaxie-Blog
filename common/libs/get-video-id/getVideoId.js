! function (e, t) {
  "object" == typeof exports && "undefined" != typeof module ? module.exports = t() : "function" == typeof define && define.amd ? define(t) : (e = e || self).getVideoId = t()
}(this, function () {
  "use strict";
  var e = function (e) {
    if ("string" != typeof e) throw new TypeError("get-src expected a string");
    var t = /src="(.*?)"/gm.exec(e);
    if (t && t.length >= 2) return t[1]
  };

  function t(e) {
    return e.indexOf("?") > -1 ? e.split("?")[0] : e.indexOf("/") > -1 ? e.split("/")[0] : e.indexOf("&") > -1 ? e.split("&")[0] : e
  }

  function r(e) {
    var r = e;
    r = r.replace(/#t=.*$/, "");
    var i = /youtube:\/\/|https?:\/\/youtu\.be\/|http:\/\/y2u\.be\//g;
    if (i.test(r)) return t(r.split(i)[1]);
    var n = /\/v\/|\/vi\//g;
    if (n.test(r)) return t(r.split(n)[1]);
    var o = /v=|vi=/g;
    if (o.test(r)) return t(r.split(o)[1].split("&")[0]);
    var s = /\/an_webp\//g;
    if (s.test(r)) return t(r.split(s)[1]);
    var u = /\/embed\//g;
    if (u.test(r)) return t(r.split(u)[1]);
    if (!/\/user\/([a-zA-Z0-9]*)$/g.test(r)) {
      if (/\/user\/(?!.*videos)/g.test(r)) return t(r.split("/").pop());
      var a = /\/attribution_link\?.*v%3D([^%&]*)(%26|&|$)/;
      return a.test(r) ? t(r.match(a)[1]) : void 0
    }
  }

  function i(e, t) {
    return function (e) {
      if (Array.isArray(e)) return e
    }(e) || function (e, t) {
      if ("undefined" == typeof Symbol || !(Symbol.iterator in Object(e))) return;
      var r = [],
        i = !0,
        n = !1,
        o = void 0;
      try {
        for (var s, u = e[Symbol.iterator](); !(i = (s = u.next()).done) && (r.push(s.value), !t || r.length !== t); i = !0);
      } catch (e) {
        n = !0, o = e
      } finally {
        try {
          i || null == u.return || u.return()
        } finally {
          if (n) throw o
        }
      }
      return r
    }(e, t) || function (e, t) {
      if (!e) return;
      if ("string" == typeof e) return n(e, t);
      var r = Object.prototype.toString.call(e).slice(8, -1);
      "Object" === r && e.constructor && (r = e.constructor.name);
      if ("Map" === r || "Set" === r) return Array.from(e);
      if ("Arguments" === r || /^(?:Ui|I)nt(?:8|16|32)(?:Clamped)?Array$/.test(r)) return n(e, t)
    }(e, t) || function () {
      throw new TypeError("Invalid attempt to destructure non-iterable instance.\nIn order to be iterable, non-array objects must have a [Symbol.iterator]() method.")
    }()
  }

  function n(e, t) {
    (null == t || t > e.length) && (t = e.length);
    for (var r = 0, i = new Array(t); r < t; r++) i[r] = e[r];
    return i
  }

  function o(e) {
    var t, r, n = e;
    if (n.indexOf("#") > -1) {
      var o = n.split("#");
      n = i(o, 1)[0]
    }
    if (n.indexOf("?") > -1 && -1 === n.indexOf("clip_id=")) {
      var s = n.split("?");
      n = i(s, 1)[0]
    }
    var u = /https?:\/\/vimeo\.com\/([0-9]+)/.exec(n);
    if (u && u[1]) return u[1];
    var a = ["https?://player.vimeo.com/video/[0-9]+$", "https?://vimeo.com/channels", "groups", "album"].join("|");
    if (new RegExp(a, "gim").test(n))(r = n.split("/")) && r.length && (t = r.pop());
    else if (/clip_id=/gim.test(n)) {
      if ((r = n.split("clip_id=")) && r.length) t = i(r[1].split("&"), 1)[0]
    }
    return t
  }

  function s(e) {
    var t = /https:\/\/vine\.co\/v\/([a-zA-Z0-9]*)\/?/.exec(e);
    return t && t[1]
  }

  function u(e) {
    var t;
    if (e.indexOf("embed") > -1) return t = /embed\/(\w{8})/, e.match(t)[1];
    t = /\/v\/(\w{8})/;
    var r = e.match(t);
    return r && r.length > 0 ? e.match(t)[1] : void 0
  }

  function a(e) {
    var t = (e.indexOf("embed") > -1 ? /https:\/\/web\.microsoftstream\.com\/embed\/video\/([a-zA-Z0-9-]*)\/?/ : /https:\/\/web\.microsoftstream\.com\/video\/([a-zA-Z0-9-]*)\/?/).exec(e);
    return t && t[1]
  }
  return function (t) {
    if ("string" != typeof t) throw new TypeError("get-video-id expects a string");
    var i = t;
    /<iframe/gi.test(i) && (i = e(i)), i = (i = (i = i.trim()).replace("-nocookie", "")).replace("/www.", "/");
    var n = {
      id: null,
      service: null
    };
    if (/\/\/google/.test(i)) {
      var f = i.match(/url=([^&]+)&/);
      f && (i = decodeURIComponent(f[1]))
    }
    return /youtube|youtu\.be|y2u\.be|i.ytimg\./.test(i) ? n = {
      id: r(i),
      service: "youtube"
    } : /vimeo/.test(i) ? n = {
      id: o(i),
      service: "vimeo"
    } : /vine/.test(i) ? n = {
      id: s(i),
      service: "vine"
    } : /videopress/.test(i) ? n = {
      id: u(i),
      service: "videopress"
    } : /microsoftstream/.test(i) && (n = {
      id: a(i),
      service: "microsoftstream"
    }), n
  }
});
//# sourceMappingURL=get-video-id.min.js.map
