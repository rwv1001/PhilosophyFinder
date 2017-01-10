# config valid only for current version of Capistrano
lock '3.6.1'


set :application, 'PhilosophyFinder'
set :repo_url, 'git@github.com:rwv1001/PhilosophyFinder.git '

# Default branch is :master
# ask :branch, `git rev-parse --abbrev-ref HEAD`.chomp

# Default deploy_to directory is /var/www/my_app_name
set :deploy_to, '/home/deploy/PhilosophyFinder'

set :linked_files, %w{config/database.yml config/secrets.yml}
set :linked_dirs, %w{bin log tmp/pids tmp/cache tmp/sockets vendor/bundle public/system}
namespace :deploy do

  desc 'Restart application'
    task :restart do
    on roles(:app), in: :sequence, wait: 5 do
      execute :touch, release_path.join('tmp/restart.txt')
    end
  end

  desc "reload the database with seed data"
  task :seed do
    on roles(:app), in: :sequence, wait: 5 do
    execute "cd #{current_path}; $HOME/.rbenv/bin/rbenv exec bundle exec rake db:seed RAILS_ENV=production"
      end
  end

  desc "drop all data from the database"
  task :drop do
    on roles(:app), in: :sequence, wait: 5 do
      execute "cd #{current_path}; $HOME/.rbenv/bin/rbenv exec bundle exec rake db:drop RAILS_ENV=production"
    end
  end

  desc "create the database"
  task :create do
    on roles(:app), in: :sequence, wait: 5 do
      execute "cd #{current_path}; $HOME/.rbenv/bin/rbenv exec bundle exec rake db:create RAILS_ENV=production"
    end
  end

  desc "migrate the database"
  task :migrate do
    on roles(:app), in: :sequence, wait: 5 do
      execute "cd #{current_path}; $HOME/.rbenv/bin/rbenv exec bundle exec rake db:migrate RAILS_ENV=production"
    end
  end

  desc "recreate and seed database"
  task :recreate do
    on roles(:app), in: :sequence, wait: 5 do
      execute "cd #{current_path}; $HOME/.rbenv/bin/rbenv exec bundle exec rake db:drop RAILS_ENV=production"
      execute "cd #{current_path}; $HOME/.rbenv/bin/rbenv exec bundle exec rake db:create RAILS_ENV=production"
      execute "cd #{current_path}; $HOME/.rbenv/bin/rbenv exec bundle exec rake db:migrate RAILS_ENV=production"
      execute "cd #{current_path}; $HOME/.rbenv/bin/rbenv exec bundle exec rake db:seed RAILS_ENV=production"
    end
  end

  after :publishing, 'deploy:restart'
  after :finishing, 'deploy:cleanup'
end



# Default value for :scm is :git
# set :scm, :git

# Default value for :format is :airbrussh.
# set :format, :airbrussh

# You can configure the Airbrussh format using :format_options.
# These are the defaults.
# set :format_options, command_output: true, log_file: 'log/capistrano.log', color: :auto, truncate: :auto

# Default value for :pty is false
# set :pty, true

# Default value for :linked_files is []
# append :linked_files, 'config/database.yml', 'config/secrets.yml'

# Default value for linked_dirs is []
# append :linked_dirs, 'log', 'tmp/pids', 'tmp/cache', 'tmp/sockets', 'public/system'

# Default value for default_env is {}
# set :default_env, { path: "/opt/ruby/bin:$PATH" }

# Default value for keep_releases is 5
# set :keep_releases, 5
