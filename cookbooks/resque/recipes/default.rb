#
# Cookbook Name:: resque
# Recipe:: default
#
if ['solo', 'util', 'app', 'app_master'].include?(node[:instance_role])
  
  package "sys-apps/ey-monit-scripts" do
    action :install
    version "0.17"
  end

  execute "install resque gem" do
    command "gem install resque redis redis-namespace yajl-ruby -r"
    not_if { "gem list | grep resque" }
  end

  case node[:ec2][:instance_type]
  when 'm1.small': worker_count = 2
  when 'c1.medium': worker_count = 3
  when 'c1.xlarge': worker_count = 8
  else 
    worker_count = 3
  end
  

  node[:applications].each do |app, data|
    template "/etc/monit.d/resque_#{app}.monitrc" do 
      owner 'root' 
      group 'root' 
      mode 0644 
      source "monitrc.conf.erb" 
      variables({
                  :num_workers => worker_count,
                  :app_name => app, 
                  :rails_env => node[:environment][:framework_env] 
                }) 
    end

    worker_count.times do |count|
      template "/data/#{app}/shared/config/resque_#{count}.conf" do
        owner node[:owner_name]
        group node[:owner_name]
        mode 0644
        source 'resque_rendered_docs.conf.erb'
      end
    end

    # Background importing is very DB write intensive, and it takes a long
    # time. Separate the background import task from the document generation
    # tasks so that if someone starts uploading a lot of legacy files, they
    # don't starve PDF generation. Also, only run a single import process (per
    # application server) so that we don't overwhelm PostgreSQL with writes
    # (which could be undone by having multiple application servers, in which
    # case a utility server could help)
    template "/data/#{app}/shared/config/resque_bg_import.conf" do
      owner node[:owner_name]
      group node[:owner_name]
      mode 0644
      source 'resque_background_import.conf.erb'
    end

    execute "ensure-resque-is-setup-with-monit" do
      command %Q{
      monit reload
      }
    end

    execute "restart-resque" do
      command %Q{
        echo "sleep 20 && monit -g #{app}_resque restart all" | at now
      }
    end
  end
end
