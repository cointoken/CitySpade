set :stage, :background

# Simple Role Syntax
# ==================
# Supports bulk-adding hosts to roles, the primary
# server in each group is considered to be the first
# unless any hosts have the primary property set.
host = "test.cityspade.com"
role :app, %W{#{host}}
role :web, %W{#{host}}
role :db,  %W{#{host}}
role :crontab,  %W{#{host}}

# Extended Server Syntax
# ======================
# This can be used to drop a more detailed server
# definition into the server list. The second argument
# something that quacks like a hash can be used to set
# extended properties on the server.
server "#{host}", user: 'ec2-user', roles: %w{web app crontab}, my_property: :my_value

set :branch, :master

set :deploy_to, '/var/www/background'
# you can set custom ssh options
# it's possible to pass any option but you need to keep in mind that net/ssh understand limited list of options
# you can see them in [net/ssh documentation](http://net-ssh.github.io/net-ssh/classes/Net/SSH.html#method-c-start)
# set it globally
#  set :ssh_options, {
#    keys: %w(/home/rlisowski/.ssh/id_rsa),
#    forward_agent: false,
#    auth_methods: %w(password)
#  }
# and/or per server
# server 'example.com',
#   user: 'user_name',
#   roles: %w{web app},
#   ssh_options: {
#     user: 'user_name', # overrides user setting above
#     keys: %w(/home/user_name/.ssh/id_rsa),
#     forward_agent: false,
#     auth_methods: %w(publickey password)
#     # password: 'please use keys'
#   }
# setting per server overrides global ssh_options

# puma
set :puma_workers, 1 
set :puma_bind, "unix:///tmp/sockets/cityspade.background.puma.sock"
fetch(:default_env).merge!(rails_env: :production)
