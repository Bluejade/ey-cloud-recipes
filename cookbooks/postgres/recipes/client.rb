gem_package "pg" do
  action :install
end

require_recipe 'postgres::eybackup'
