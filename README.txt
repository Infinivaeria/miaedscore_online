# NOTE: THIS IS THE BLOG and test server for midscore and onemoonplanet
# https://onemoonpla.net
# https://midscore.art
# https://simulatorwolf.net
# https://simulwolf.net
# https://kejento.net
# https://aritywolf.net
# https://artywalf.net

## Documentation Index

- docs/CODE_DOCUMENTATION.md
  - Architecture overview, route map, view map, data model notes, and extension guidance.
- docs/WORK_LOG_2026-08-01.md
  - Detailed engineering log of the optimization and bug-fix session, with validations and known risks.

def CGMFS: comicman (comic manager) gallery filesystem

# Current version: 3.2.5
required usernames in ./db/db_list.txt:
 urls_redir
 blog
 user_blog_database


VERSION $dog_blog_version = "4.1.5f-production-linux-puma-line_db" #used in layout.html.erb (2023-04-27)
* updated root.rb for root path (https://thefieldtesters.net/ -- redirects to aritywolf's blog when root of thefieldtesters.net is requested)
* updated config/puma-nginx-production.rb for 4 threads (2023-04-27)
* https://thefieldtesters.net/?&autologin=1 -- autologin for thefieldtesters.net (2023-04-27) as ArityWolf
TODO: expand autologin feature to allow username logins, if possible and seemingly practical...
# this GET action is within cgmfs/root.rb
* add /backup to site route to easily and quickly backup miaedscore

VERSION $dog_blog_version = "v4.0.2f-production-linux-puma-line_db" #used in layout.html.erb (2023-04-26)
* added begin rescue routine to /u/shorten  (POST), to attempt to work around a low level network/socket error
from which there seems to be no real apparent fix, except for maybe checking buffers in STDIN/STDERR/STDOUT ala Perl

VERSION $dog_blog_version = "v4.0.1f-production-linux-puma-line-db" #used in layout.html.erb
# render option for blog posts now displays a num theory (numerological in nature) number, which is used FNAR.
### starting on line 156 ... (    r.on 'render' do) ... in blog.rb (you know the drill)

VERSION v4.0-production
# restart_server.rb - restart server in onemoonpla.net mode with 4 threads
# restart_server_hud.rb - restart server in hudl.ink, with 8 threads

VERSION v3.2.4-production
Update push.

Added Resolv gem to layout.html.erb (the only layout used in the onemoonpla.net DogBlog)

Bundler maintains most gems but not certain ones; check which ones do not work when we get the TIME of DAY.

layout.html.erb:
QUICK HACK to get the client's reversed DNS name
https://stackoverflow.com/questions/2993/reverse-dns-in-ruby

comments start at line 50 followed by the code, at the time of this writing.

IMPLEMENTED: DB SAVER IN ALL POST OUTPUTS
backup_db.rb in server root, miaedscore  /new POST, etc.
VERSION v3.2.2-production - TinyMCe editor premium  - signups closed manually (routes/blog.rb - in the view 'signup')
TODO - signup system with provided-to-user keycode
VERSION v2.0.5 - add render view
VERSION v2.0.1f - add markdown, raw html mode to edit/post (3/18/2023 - 10:12AM)
VERSION v2.0.1a - add markdown, raw html mode to edit/post
VERSION v2.0.0 - partition save efficiency (in view in blog.rb)
VERSION v1.0.3f - fixed page count bug, fiddled around with partioned array and concluded that there needs to be a partition save function that only saves non-empty partitions, even though the complexity to save each file may be negligible...
VERSION v1.0.2a - blog post page count and overall page count
VERSION v1.0.1a - fixed url redirection bug
VERSION v1.0.0a - midscore and onemoonplanet system (to be integrated with midscore i/o)
Changed files prior to v1.0.0a:
* /r/view.html.erb
* r.rb
Version 1.0.0 includes:
* blog system (/blog)
* url string shortener system (/r/admin/view -> /r/shortened_url)
* tested partitioned array data structure
* URL integer increment shortener (urls make (/admin); (for loggin in/admin/login?password='gUilmon95458a); out of date on this server and used only on HUdl.ink)
if r.params['password'] == 'gUilmon95458a'
* note: out of date on hudl.ink but we don't care. (we will be using the new system)

System: cgmfs (comicman gallery manager filesystem)
Framework: Roda (https://roda.io/)
Language: Ruby
Database: LineDB / PartitionedArray
Server: Puma
Webserver: Nginx

* IMPLEMENTED: The system is now capable of storing data in a partitioned array, and is capable of managing the partitioned array.
* blog system is complete, TODO includes page views; logging is done through log(text)
* url shortener (/r/shorten) is complete, and includes deleting the shortened url--logs are sent to telegram

VERSION 0.1: Initial development codebase (Worked on setting up the framework of the code, determining many things along the way in order to prevent code creep) - 4/23/2022 3:33PM


Day 0: began by setting up the framework and locations where code goes, and learnt a bit of the rubygem `rerun`.

To start the server in reload mode: `rerun --dir cgmfs -- "puma -C config/puma-nginx-production.rb"`

Or: `rerun --dir . -- "puma -C config/puma-nginx-oproduction.rb"` to monitor all files in the current directory project

You will want this so long as you are in development mode, and since its simply a command you can just not use it in production.

cgmfs: comicman gallery manager filesystem (midscore_web3)

Framework: Roda (https://roda.io/)

# Q: how to I configure git username and password?
# A: git config --global user.name "John Doe"


# Routes




# TODO: create an API route for the second life data analytics system
#
Premise:
 - Github copilot: The user can upload a file containing a list of comics
  - The system will parse the file and create a list of comics
  - The system will then create a list of comics that are similar to the comics in the list
  - In second life, be capable of transferring data in base64 from the second life server to hudl.ink.
  - The system will be divided into multiple groups. Each group will be assigned a number and you have a choice
     of selecting by their id or their name, as per the capabilities of Roda.
   - ex:
 First, also to get your bearings on CGMFS, you can try the following:
   - 1) Using the PartitionedArray class, implement a basic data pushing system for second life.
   - 1a) Underlying question: do you want to get to do more direct second life programming or do you want to create
        a framework that's so flexible it can integrate in your node routes, or:
     Do you create a separate system for second life that is specifically the server storing data pushed by second life
  with a semi frontend which ultimately will push to your dragonruby client
  - 2) Answer: I propose that for now we create a second life api section and focus on gathering data; routes can be
        changed later, and is possible it might work easier with roda.




Required ubuntu/debian installations:

`apt install gtk-doc-tools gobject-introspection glib2.0 libvips42 libvips-dev imagemagick libmagickwand-dev libfreeimage3 libfreeimage-dev jpegoptim optipng`
`apt install autoconf bison build-essential libssl-dev libyaml-dev libreadline6-dev zlib1g-dev libncurses5-dev libffi-dev libgdbm6 libgdbm-dev libdb-dev`


factor

testing:

The goal is to test the codebase and make sure it works as expected.


https://www.rubyguides.com/2015/12/ruby-time/ - for dealing with time, date, and datetime


# VERSION

`VERSION v0.9.1` (no version tallies before this point)

API Structure tested; Partitioned/Managed Partitioned Array Tested. Version is stuck at v0.9.x until the Managed Partitioned Array server is implemented and working.
