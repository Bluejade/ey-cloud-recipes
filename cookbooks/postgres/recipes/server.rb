postgres_version = '8.3'
postgres_root    = '/db/postgresql'

require_recipe 'postgres::server_setup'
require_recipe 'postgres::server_configure'

execute "rc-update add postgresql-#{postgres_version} default" do
  action :run
end

remote_file "/etc/conf.d/postgresql-8.3" do
  source "postgresql.conf"
  owner "root"
  group "root"
  mode "0644"
end

if ['solo', 'db_master'].include?(node[:instance_role])
  execute "start-postgres" do
    command "/etc/init.d/postgresql-#{postgres_version} restart"
      action :run
    not_if "/etc/init.d/postgresql-#{postgres_version} status | grep -q start"
  end
end

username = node.engineyard.ssh_username
password = node.engineyard.ssh_password

psql "create-db-user-#{username}" do
  sql "create user #{username} with encrypted password '#{password}'"
  sql_not_if :sql => 'SELECT * FROM pg_roles',
             :assert => "grep -q #{username}"
end

node.engineyard.apps.each do |app|
  createdb app.database_name do
    owner username
  end
end

require_recipe 'postgres::eybackup'
