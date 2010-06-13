execute "install_pg_gem" do
  command "gem install pg --no-ri --no-rdoc --remote"
  not_if "gem list --local pg"
end

require_recipe 'postgres::eybackup'
