require_recipe 'postgres::client'
require_recipe 'postgres::pgpass'
if ['solo', 'db_master'].include?(node[:instance_role])
  require_recipe 'postgres::server'
  require_recipe 'postgres::eybackup'
end
if ['solo', 'db_slave'].include?(node[:instance_role])
  require_recipe 'postgres::server'
  require_recipe 'postgres::setup_slave'
end
if ['solo', 'app_master', 'app', 'util'].include?(node[:instance_role])
  require_recipe 'postgres::database'
end
