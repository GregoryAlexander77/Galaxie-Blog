# Galaxie Blog roadmap

The full roadmap, with the reasons behind each step, is at **https://galaxieblog.org/roadmap**. This is the short version.

Galaxie Blog 5.0 (the Howl at the Moon Edition) came out on October 29, 2026, followed by 5.01 and 5.02, and 5.07 is on its way. The 5.x versions are about the platform underneath the features: a cleaner structure, modern script code, BoxLang support and an API. On top of that: redesigned and new themes, a page builder, and new comments and notifications.

> **A plan, not a promise.** There are no dates. Each step ships when it is ready and tested, inside an ordinary 5.x release, and the plan can change.

## How releases ship

Each release comes with a small update download of only the files that changed (for blogs one version behind) next to the full download, and a few lines of notes. Security fixes go out right away.

## The plan, in order

1. **Settle 5.0** and ship the smaller items as fix releases (5.01 to 5.09).
2. **Lay the foundation:** BoxLang support (work has started), a Docker setup (Lucee first, comes with 5.07), a [`CONTRIBUTING.md`](CONTRIBUTING.md) with the house style, and TestBox tests for the flows that matter most.
3. **Rewrite `Application.cfc`** in script, split by job.
4. **Theme tokens:** one set of named design values that every theme fills in.
5. **Two tracks at once:** split `blog.cfc` into script services with events, plus traffic charts, built-in backups and restore, and redesigned and new themes.
6. **The page builder:** pages built from blocks that every theme styles, on the Scenes engine.
7. **New comments and notifications.**
8. **Integrations:** webhooks and a read-only API with per-integration tokens.
9. **Plugins:** hooks, admin windows, page builder blocks and themes.

**Later, 6.x:** forums, built on the 5.x comment engine.

## Coming in 5.07

- Galaxie in Docker: Lucee, MariaDB and a mail catcher, with one command
- Formatting in comments: bold, italics, code blocks and links, for everyone
- New comments appear on their own, with a setting to turn this off or change how often it checks
- Reply to comments from the administrative site, and Trusted Commenters
- Scenes: a Scene wizard, and a Layout choice in Create and Edit Post
- A Forms wizard
- A code editor for Source code in the post editor
- A confirmation before every delete or remove in the administrative site
- Heroes: a Moving hero in the Hero editor, moving gradients, one Hero text window for every hero, a Parallax hero style
- The author's photo on the post cards, and who wrote each post in the Recent Posts pod
- Indexes that make SQL Server and PostgreSQL blogs faster
- Say hello and cfblogs.org in Blog Options
- Error reports to the project only if you choose to send them

## Smaller items still to come

- Two-factor sign-in for the administrative site
- Shorter IP addresses in the visitor log (an option, off by default)
- A "Backing up your blog" docs page
- A demo site
- Being considered: a scheduled task check. The administrative site shows when each of the blog's scheduled tasks last ran, and emails you when one is late (ColdFusion's October 2026 update stopped many scheduled tasks without an error)

## Open questions

How queries are written (tags or `queryExecute()`), the ORM on BoxLang, the theme tokens, how a built page is stored, and plugin trust. Input is welcome in [GitHub issues](https://github.com/GregoryAlexander77/Galaxie-Blog/issues).
