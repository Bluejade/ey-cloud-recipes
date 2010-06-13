require_recipe 'postgres::client'

if ['solo', 'db_master'].include?(node[:instance_role])
  require_recipe 'postgres::server'
  require_recipe 'postgres::eybackup'
end
if ['solo', 'db_slave'].include?(node[:instance_role])
  require_recipe 'postgres::server'
end
if ['solo', 'app_master', 'app', 'util'].include?(node[:instance_role])
  require_recipe 'postgres::database'
end
