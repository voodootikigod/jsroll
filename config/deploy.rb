


set :application, "jsroll"
set :repository, "github-jsroll:voodootikigod/#{application}.git"
set :scm, "git"
set :deploy_via, :remote_cache


before "deploy:setup", "db:password"

# If you aren't deploying to /u/apps/#{application} on the target
# servers (which is the default), you can specify the actual location
# via the :deploy_to variable:
# set :deploy_to, "/var/www/#{application}"



# For migrations
set :rails_env, 'production'

# Who are we?
# set :branch, "production"

# Where to deploy to?
role :web, "www.jsroll.com"
role :app, "www.jsroll.com"
role :db,  "www.jsroll.com", :primary => true

# Deploy details
set :user, "deploy"
set :deploy_to, "/sites/#{application}"
set :use_sudo, false
set :checkout, 'export'




namespace :deploy do
  desc "Default deploy - updated to run migrations"
  task :default do
    set :migrate_target, :latest
    update_code
    migrate
    symlink
    restart
  end
  desc "Restarting mod_rails with restart.txt"
  task :restart, :roles => :app, :except => { :no_release => true } do
    run "touch #{current_path}/tmp/restart.txt"
  end

  [:start, :stop].each do |t|
    desc "#{t} task is a no-op with mod_rails"
    task t, :roles => :app do ; end
  end
  
  desc "Run this after every successful deployment" 
  task :after_default do
    cleanup
  end
end


before "deploy:symlink", "recaptcha:symlink"

namespace :recaptcha do
  desc "Symbolically link recaptcha values"
  task :symlink do
    run <<-CMD
      ln -nfs #{shared_path}/system/recaptcha.rb #{release_path}/config/initializers/recaptcha.rb
    CMD
  end
end


namespace :db do
  desc "Create database password in shared path" 
  task :password do
    set :db_password, Proc.new { Capistrano::CLI.password_prompt("Remote database password: ") }
    run "mkdir -p #{shared_path}/config" 
    put db_password, "#{shared_path}/config/dbpassword" 
  end
end