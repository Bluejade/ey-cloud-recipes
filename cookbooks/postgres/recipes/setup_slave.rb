postgres_root = '/db/postgresql'
postgres_version = '8.3'

if ['db_slave'].include?(node[:instance_role])

  template "#{postgres_root}/#{postgres_version}/postgresql.conf" do
    source "postgresql.conf.erb"
    owner "postgres"
    group "postgres"
    backup 0
    mode 0600

    variables(
      :sysctl_shared_buffers => node[:sysctl_shared_buffers],
      :shared_buffers => node[:shared_buffers],
      :max_fsm_pages => node[:max_fsm_pages],
      :max_fsm_relations => node[:max_fsm_relations],
      :maintenance_work_mem => node[:maintenance_work_mem],
      :work_mem => node[:work_mem],
      :max_stack_depth => node[:max_stack_depth],
      :effective_cache_size => node[:effective_cache_size],
      :default_statistics_target => node[:default_statistics_target],
      :logging_collector => node[:logging_collector],
      :log_rotation_age => node[:log_rotation_age],
      :log_rotation_size => node[:log_rotation_size],
      :checkpoint_timeout => node[:checkpoint_timeout],
      :checkpoint_segments => node[:checkpoint_segments],
      :wal_buffers => node[:wal_buffers],
      :wal_writer_delay => node[:wal_writer_delay],
      :postgres_root => postgres_root,
      :postgres_version => postgres_version
   )
  end

  remote_file "#{postgres_root}/#{postgres_version}/recovery.conf" do
    source "recovery.conf"
    owner "postgres"
    group "postgres"
    mode 0600
    backup 0
  end

  template "#{postgres_root}/#{postgres_version}/pg_hba.conf" do
    owner 'postgres'
    group 'postgres'
    backup 0
    mode 0600
    source "pg_hba.conf.erb"
    variables({
      :dbuser => node[:users].first[:username],
      :dbpass => node[:users].first[:password]
    })
  end

  directory "/mnt/tmp" do
    action :create
    owner "postgres"
    group "postgres"
    mode 1777
  end

  directory "/db/postgresql" do
    action :create
    owner "postgres"
    group "postgres"
    mode "0700"
  end

  directory "/db/postgresql/8.3" do
    action :create
    owner "postgres"
    group "postgres"
    mode 0700
  end

  directory "/db/postgresql/8.3/wal" do
    action :create
    owner "postgres"
    group "postgres"
    mode "0700"
  end

  execute "do_rsync?" do
    command "touch /db/resync"
    only_if { ! FileTest.directory?("/db/postgresql/8.3/data") }
  end

  execute "touch_000001_history" do
    command "touch /db/postgresql/8.3/wal/00000001.history && chown postgres:postgres /db/postgresql/8.3/wal/00000001.history"
    only_if { FileTest.exists?("/db/resync") }
  end

  execute "start_postgres_backup_sql" do
    command "echo \"SELECT pg_start_backup('`date`');\" | psql  -h #{node.engineyard.environment.db_host} -U postgres postgres"
    only_if { FileTest.exists?("/db/resync") }
  end

  execute "start_rsync" do
    command "su -c 'cd /db/postgresql/8.3;rsync -avPz --exclude .svn --exclude postgresql.conf --exclude recovery.conf --exclude pg_xlog #{node.engineyard.environment.db_host}:/db/postgresql/8.3/data/ /db/postgresql/8.3/data/' - postgres"
    only_if { FileTest.exists?("/db/resync") }
  end

  execute "stop_postgres_backup_sql" do
    command "echo \"SELECT pg_stop_backup();\" | psql -h #{node.engineyard.environment.db_host} -U postgres postgres"
    only_if { FileTest.exists?("/db/resync") }
  end

  execute "rm_xlog" do
    command "find /db/postgresql/8.3/data/pg_xlog -type f | xargs rm -f"
    only_if { FileTest.exists?("/db/resync") }
  end

  execute "update_archive_command" do
    command "ssh postgres@#{node.engineyard.environment.db_host} /db/postgresql/8.3/bin/update_archive_command #{node.engineyard.environment.db_slaves_hostnames}"
    only_if { FileTest.exists?("/db/resync") }

  end
  
  file "#{postgres_root}/#{postgres_version}/custom.conf" do
    action :create
    owner node[:owner_name]
    group node[:owner_name]
    mode 0644
    not_if { FileTest.exists?("#{postgres_root}/#{postgres_version}/custom.conf") }
  end

  execute "start_postgres" do
    command "cd /db/postgresql/8.3/data;ln -sfv /db/postgresql/8.3/postgresql.conf . && cd /db/postgresql/8.3/data;ln -sfv /db/postgresql/8.3/pg_hba.conf . && /etc/init.d/postgresql-8.3 start"
    only_if { FileTest.exists?("/db/resync") }
  end

  execute "no_longer_resync" do
  command "rm /db/resync"
  only_if { FileTest.exists?("/db/resync") }
  end
end
