class CGMFS
  hash_branch 'admin' do |r|
    r.hash_branches

    r.on 'login' do
      r.get do
        success = 'wur r u doing!?'
        if r.params['password'] == 'gUilmon95458a'
          # r.response.set_cookie("admin", value: "true")

          # session['user'] = 'aritywolf'
          # session['password'] = '859CDFE#F4E85'
          session['admin'] = true
          # r.redirect('/blog/aritywolf')

          success = 'Successfully logged in as admin' # unused
        end

        "#{success}"
      end
    end

    r.on 'add' do
      #  r.is String do |db_name|
      #    r.get do
      #      @@line_db.add_db!(db_name)
      #      r.redirect("/admin")
      #    end
      #  end

      r.post do
        @@line_db.add_db!(r.params['db_name'])
        @@line_db.update_databases
        @@line_db[r.params['db_name']].pad.new_table!(database_name: 'blog_database', database_table: 'blog_table') # load the blog database
        # "success"
        r.redirect('/admin')
      end
    end

    r.on 'remove' do
      r.is String do |db_name|
        @@line_db.remove_db!(db_name)
        @@line_db.update_databases
        # "success"
        r.redirect('/admin')
      end
    end

    r.on 'delete' do
      r.post do
        # "#{request.params("db_name")}"
        @@line_db.delete_db!(r.params['db_name'])
        @@line_db.update_databases
        # "success"
        r.redirect('/admin')
      end
    end

    r.on 'reload' do
      @@line_db.reload
      r.redirect('/admin')
    end

    r.is do
      unless session['admin']
        r.redirect '/blog/blog' # temp redirect
      end
      r.get do
        # list all available/active databases
        # "#{session["admin"]}"
        view('linedb/admin', engine: 'html.erb', layout: 'layout.html')
      end
    end
  end
end
