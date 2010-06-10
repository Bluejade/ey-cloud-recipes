#
# Cookbook Name:: nginx_rewrite
# Recipe:: default
#

if ['solo', 'app', 'app_master'].include?(node[:instance_role])

  file '/etc/nginx/servers/iwheel.rewrites' do
    action :delete
  end

  link '/etc/nginx/servers/iwheel.rewrites' do
    to '/data/nginx/iwheel.rewrites'
  end

  link '/etc/nginx/servers/iwheel_to_ssl.conf' do
    to '/data/nginx/iwheel_to_ssl.conf'
  end

end
