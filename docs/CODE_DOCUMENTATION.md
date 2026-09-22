# Code Documentation

## Purpose
This document provides a practical map of the current miaedscore codebase: architecture, major modules, routes, templates, data paths, and execution flow.

## Stack Overview
- Language: Ruby (primary), Rust (support service code), ERB templates
- Web framework: Roda
- App server: Puma
- Data layer: LineDB/PartitionedArray (file-backed)
- Frontend: server-rendered HTML with ERB and inline CSS/JS

## Top-Level Project Layout
- cgmfs/
  - Route registration and web feature entry points
- views/
  - ERB templates for blog, gallery, shortener, pages, admin and layout
- lib/
  - Shared utilities and data structure packages, including partitioned_array
- tiade-maeepers-saerver-all/
  - Rust service and route experiments/utilities
- db/
  - Runtime data files for line_db/partitioned storage
- assets/ and public/
  - Static resources and generated frontend assets
- config/
  - Puma and environment config used by runtime

## Runtime Execution Model
1. Roda route branches dispatch requests by top-level path.
2. Route handlers read/update LineDB structures under db.
3. Handlers set instance variables for ERB templates.
4. views/layout.html.erb wraps most page templates.
5. Some template code performs side effects (logging/counters) during render.

## Core Routing Areas

### Blog system
Primary file:
- cgmfs/routes/blog.rb

Responsibilities:
- Authentication entry points (login/logout/signup)
- Blog CRUD (new/edit/view/tag/list/delete lock toggle)
- Pinned posts
- Render endpoint for standalone post HTML with code-highlighting assets
- Privacy toggle for profile-level post visibility
- Statistics counters for page views

Important route groups:
- /blog/render
- /blog/login
- /blog/signup
- /blog/:user/view
- /blog/:user/new
- /blog/:user/edit/:id
- /blog/:user/tag/:tag
- /blog/:user/pin

### Gallery system
Primary file:
- cgmfs/routes/gallery.rb

Responsibilities:
- Gallery item CRUD
- Tag views and search
- Attachment upload/list
- User/gallery container style features

### Other route modules
- cgmfs/routes/root.rb
  - Root landing and primary redirects
- cgmfs/routes/admin.rb
  - Admin-facing routes and control pages
- cgmfs/routes/card.rb
  - Card/meta related output routes
- cgmfs/routes/moon.rb
  - Moon/date themed pages and helpers
- cgmfs/routes/sun.rb
  - Sun/date themed pages and helpers

## Templates and View Layer

### Shared layout
- views/layout.html.erb

Responsibilities:
- Global head/meta tags
- Primary navigation elements
- Shared styles
- Footer/status blocks
- Runtime logging/counter side effects (currently in view layer)

### Blog templates
Directory:
- views/blog/

Key templates:
- blog.html.erb: blog landing shell
- view_all.html.erb: list/feed view
- view.html.erb: single post page
- edit*.html.erb: edit forms by mode
- new*.html.erb: create forms by mode
- pin.html.erb: pinned post management view
- tag.html.erb: tag filtered listing
- login.html.erb/signup.html.erb: auth forms
- delete.html.erb: lock-toggle listing

### Gallery templates
Directory:
- views/blog/gallery/

Key features represented:
- per-item view pages
- tag and tag-search pages
- container/collection views and edits
- attachment upload/list pages

### Additional templates
- views/r/new.html.erb and views/r/view.html.erb
  - URL shortener/admin views
- views/page/*.html.erb
  - Flat page editing/listing/new page views
- views/linedb/admin.html.erb
  - Data admin page
- views/sl_data.html.erb and views/sl_api_list.html.erb
  - Second Life/API related UI

## Data Model Notes

### LineDB and PartitionedArray
Primary package path:
- lib/partitioned_array/lib/

Core components:
- line_db.rb / line_database.rb
  - database access and composition
- partitioned_array.rb / managed_partitioned_array.rb
  - partitioned storage implementation
- file_context_managed_partitioned_array*.rb
  - file-backed managed partition operations
- file_methods.rb
  - low-level file list and line operations

### Typical blog data keys
Observed keys in blog entries:
- blog_post_title
- blog_post_body
- blog_post_body_markdown
- blog_post_tags
- blog_post_date
- blog_post_author
- blog_post_comments
- blog_post_status
- blog_status_locked
- blog_post_rendered_type
- timestamp
- id

## Authentication and Authorization (Current)
- Session keys:
  - session['user']
  - session['password']
  - session['admin']
- Login route compares plaintext password values from stored table.
- Route-level checks gate edit/new/delete/private actions for matching user.
- Super password gate exists in login logic (hardcoded in route file).

## Observability and Logging
- Request and hitch logging currently occur in views/layout.html.erb.
- Page view counters are incremented in multiple request/view paths.
- Additional logger utilities exist in lib/loggers.

## Rust Service Area
Primary path:
- tiade-maeepers-saerver-all/src/

Purpose:
- Alternate server/bridge experiments and embedded HTML responses.
- Contains bridge iframe route behavior and related response generation logic.

## Internal Library Areas Outside PartitionedArray
- lib/shortened/shortened_url.rb
  - URL shortener utility behavior
- lib/sun_moon_phases.rb
  - date/phase related helpers
- lib/time_date/time_date.rb
  - time/date helper functions
- lib/proxy_middleware.rb
  - middleware support behavior

## Current Known Technical Debt
1. Side-effect-heavy rendering in shared layout template.
2. Auth secrets and password handling need hardening.
3. Mixed rendering/sanitization approaches across markdown/html content.
4. Large monolithic route file for blog workflow can be decomposed.

## File Inventory (Important Active Areas)

### Route files
- cgmfs/routes/admin.rb
- cgmfs/routes/blog.rb
- cgmfs/routes/blog/blog.rb
- cgmfs/routes/card.rb
- cgmfs/routes/gallery.rb
- cgmfs/routes/moon.rb
- cgmfs/routes/root.rb
- cgmfs/routes/sun.rb

### View files
- views/layout.html.erb
- views/list_urls.html.erb
- views/midscore_landing.html.erb
- views/sl_api_list.html.erb
- views/sl_data.html.erb
- views/blog/*.html.erb
- views/blog/gallery/*.html.erb
- views/blog/topic/topic.html.erb
- views/linedb/admin.html.erb
- views/page/*.html.erb
- views/r/*.html.erb

### Core lib files
- lib/bst_array_make.rb
- lib/file_keeper.rb
- lib/proxy_middleware.rb
- lib/shortened/shortened_url.rb
- lib/sun_moon_phases.rb
- lib/time_date/time_date.rb
- lib/partitioned_array/lib/*.rb

## How to Extend Safely
1. Add/modify routes in cgmfs/routes by feature area and keep authorization checks close to mutating actions.
2. Keep template files presentation-focused; move new side effects to route/middleware/helpers.
3. Add shared sanitization helpers for all user-provided content rendering paths.
4. Update this file and docs/WORK_LOG_YYYY-MM-DD.md whenever runtime behavior changes.

## Quick Developer Navigation
- Start here for behavior changes:
  - cgmfs/routes/blog.rb
  - cgmfs/routes/gallery.rb
  - views/layout.html.erb
- Start here for data structure behavior:
  - lib/partitioned_array/lib/line_db.rb
  - lib/partitioned_array/lib/partitioned_array.rb
  - lib/partitioned_array/lib/file_methods.rb
- Start here for standalone rendered output path:
  - cgmfs/routes/blog.rb route /blog/render
- Start here for tag and list rendering:
  - views/blog/view_all.html.erb
