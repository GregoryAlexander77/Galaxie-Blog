# Contributing to Galaxie Blog

Thank you for thinking about helping. Bug reports, fixes, documentation and ideas are all welcome. This page explains how to set up the blog, how the code is written, and what to check before you send a pull request.

Where the project is going is in the [roadmap](https://galaxieblog.org/roadmap). If you want to work on something bigger than a fix, open an issue first so we can agree on the approach before you spend time on it.

## Reporting a bug

Open a [GitHub issue](https://github.com/GregoryAlexander77/Galaxie-Blog/issues) and include:

- the Galaxie version (the admin home and the footer show it)
- the engine and version (Adobe ColdFusion 2023/2025, Lucee 6/7) and the database (SQL Server, MySQL or MariaDB)
- whether the blog is installed at the root or in a folder (for example `/blog/`)
- what you did, what you expected, and what happened, with the error message if there was one. The admin **Error Log** keeps the full details.

**Security problems:** please don't open a public issue. Use the **Report a vulnerability** button on the repository's **Security** tab, so it can be fixed before it is announced.

## Setting up the blog to work on

The quickest way is Docker: Galaxie on Lucee with MariaDB and a mail catcher, with one command. See [DOCKER.md](DOCKER.md). If your antivirus scans HTTPS traffic, it can block Lucee's first downloads; DOCKER.md explains what to do.

You can also use your own Adobe ColdFusion or Lucee server and follow the installation steps in the [README](README.md). Galaxie supports both engines, so if you can, test a change on both.

## Branches and pull requests

- `master` is the released code. Branch from it and send your pull request against it.
- Keep a pull request to one change. Small pull requests are reviewed sooner.
- Say in the description what changed, why, and how you tested it (engine, database, root or folder install).
- Commit subjects say what changed in plain words, for example `Comments: the reply link opens the right post`. No ticket numbers needed.

## How the code is written

Galaxie started from Raymond Camden's BlogCFC in 2018 and has grown a lot since. Match the code around your change rather than bringing in a new style.

**CFML**

- Most of the code is tag-based CFML. Moving to script is on the roadmap, a piece at a time; until a file has been moved, keep it in the style it's in.
- Indent with tabs.
- Comment the **why**, not the what: the reason something is done this way, the case it handles, or the bug it prevents.
- Use `<cfqueryparam>` for every value in a query.
- The main logic is in `org/camden/blog/blog.cfc`. The admin site calls it through `common/cfc/ProxyController.cfc`.
- Code must run on both Adobe ColdFusion and Lucee. A few differences we've hit:
  - On Adobe ColdFusion, the Elvis operator turns `false` into the default (`value ?: ""` gives `""` when value is `false`). Use `structKeyExists()` when a value can be `false` or `0`.
  - Lucee on Linux is case-sensitive about file and table names; Windows is not. Use the exact case.
  - Don't use `evaluate()`. Read a name built at run time from its scope instead (`form[name]`, `variables[name]`).
  - Adobe ColdFusion won't compile a `var` with the same name as an argument of its function. Lucee allows it, so this only shows up on Adobe.

**The database**

- Tables are Hibernate ORM entities in `common/cfc/db/galaxieDb/`.
- If you add or change an entity, also change the date at the end of `this.name` in `Application.cfc` (`_yyyymmdd`, no dashes) to today's date, so that running blogs start a fresh application with the new mapping.
- If an update needs data changes, add them to the version's script in `installer/updates/` (for example `5.07.cfm`). An update script must be safe to run twice, and a failure in it should be logged, not stop the update.

**The admin site and themes**

- The admin site uses Kendo UI. Use Kendo classes (for example `k-content`, `k-alt`) and never hard-coded colors, because every theme, including the dark ones, must stay readable.
- Admin windows share one layout: alternating `k-content` / `k-alt` blocks, labels in their own column on the left, and `h4.adminBlockHeading` for section titles. `admin/adminInterface/bookingTypeDetail.cfm` is a good example to copy.
- The Create and Edit Post windows stay the same: their shared rows are in `admin/adminInterface/postKindRows.cfm`, and a new row goes in both windows.
- Public pages must weigh the same for a visitor and for a signed-in admin. Anything extra for admins on a public page has to be small and load only when needed.

**Third-party libraries**

Libraries live in `common/libs/`. Don't edit them. Add the license of a new library to [THIRD-PARTY-LICENSES.md](THIRD-PARTY-LICENSES.md).

The post editor stays on TinyMCE 5 (5.10.9), because of the license terms of later versions and to keep the free plugins Galaxie uses. Please don't upgrade it to a newer major version.

## Before you send it

- Test on Adobe ColdFusion or Lucee, and on both if you can.
- After changing a `.cfc`, reinitialize the blog (add `?reinit=1` to the address) before testing.
- Check an admin window on a light theme and a dark one.
- If you changed what users see or do, a line for the release notes in the pull request description helps.

## License

Galaxie Blog is released under the [Apache License 2.0](LICENSE). By sending a pull request, you agree that your contribution is released under the same license.
