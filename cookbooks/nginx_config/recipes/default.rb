#
# Cookbook Name:: nginx_config
# Recipe:: default
#

if ['solo', 'app', 'app_master'].include?(node[:instance_role])

  file '/data/nginx/servers/iwheel.rewrites' do
    action :delete
  end

  link '/data/nginx/servers/iwheel.rewrites' do
    to '/data/nginx_customizations/keep.iwheel.rewrites'
  end


  file '/data/nginx/servers/iwheel.conf' do
    action :delete
  end

  link '/data/nginx/servers/iwheel.conf' do
    to '/data/nginx_customizations/keep.iwheel.conf'
  end

end
