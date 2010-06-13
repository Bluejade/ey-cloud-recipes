if ['db_slave'].include?(node[:instance_role])

  directory "/mnt/tmp" do
    action :create
    owner "postgres"
    group "postgres"
    mode 1777
  end

  directory "/db/postgresql/wal" do
    action :create
    owner "postgres"
    group "postgres"
    mode "0700"
  end
end
