if ['db_slave'].include?(node[:instance_role])

  directory "/mnt/tmp" do
    action :create
    owner "postgres"
    group "postgres"
    mode 1777
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
    command "su -c 'cd /db/postgresql/8.3;rsync -avPz --exclude .svn --exclude recovery.conf --exclude postgresql.conf --exclude pg_xlog #{node.engineyard.environment.db_host}:/db/postgresql/8.3/data/ /db/postgresql/8.3/data/' - postgres"
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
    command "su -c 'ssh postgres@#{node.engineyard.environment.db_host} /db/postgresql/8.3/bin/update_archive_command #{node.engineyard.environment.db_slaves_hostnames}"
    only_if { FileTest.exists?("/db/resync") }

  end
  execute "start_postgres" do
    command "/etc/init.d/postgresql-8.3 start"
    only_if { FileTest.exists?("/db/resync") }
  end

  execute "no_longer_resync" do
  command "rm /db/resync"
  only_if { FileTest.exists?("/db/resync") }
  end
end
