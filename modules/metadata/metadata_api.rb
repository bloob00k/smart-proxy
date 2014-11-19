require 'metadata/server'
require 'proxy/validations'


=begin
 * $ curl http://169.254.169.254/latest/meta-data/    
ami-id
ami-launch-index
ami-manifest-path
block-device-mapping/
hostname
instance-action
instance-id
instance-type
kernel-id
local-hostname
local-ipv4
mac
network/
placement/
public-hostname
public-ipv4
public-keys/
reservation-id
security-groups
services/

=end


module Proxy::Metadata
  class Api < ::Sinatra::Base
    include ::Proxy::Log
    include ::Proxy::Validations
    helpers ::Proxy::Helpers
    authorize_with_trusted_hosts

    helpers do
      def instantiate variant, mac=nil
        # Filenames must end in a hex representation of a mac address but only if mac is not empty
        log_halt 403, "Invalid MAC address: #{mac}"                  unless valid_mac?(mac) || mac.nil?
        log_halt 403, "Unrecognized pxeboot config type: #{variant}" unless defined? variant.capitalize
        eval "Proxy::TFTP::#{variant.capitalize}.new"
      end

      def create ip, key, value = nil
        print "#{key} for #{ip}: #{value}"
       # tftp = instantiate variant, mac
       # log_halt(400, "TFTP: Failed to create pxe config file: ") {tftp.set(mac, (params[:pxeconfig] || params[:syslinux_config]))}
      end
      def delete ip
        print "delete metadata for #{ip}"
        #tftp = instantiate variant, mac
        #log_halt(400, "TFTP: Failed to delete pxe config file: ") {tftp.del(mac)}
      end
      def create_default variant
        tftp = instantiate variant
        log_halt(400, "TFTP: Failed to create PXE default file: ") { tftp.create_default params[:menu]}
      end
    end

    post "/fetch_boot_file" do
      log_halt(400, "TFTP: Failed to fetch boot file: ") {Proxy::TFTP.fetch_boot_file(params[:prefix], params[:path])}
    end

    post "/:variant/create_default" do |variant|
      create_default variant
    end

    get "/:variant/:mac" do |variant, mac|
      tftp = instantiate variant, mac
      log_halt(404, "TFTP: Failed to retrieve pxe config file: ") {tftp.get(mac)}
    end

    post "/:ip/:key" do |ip, key|
      #create variant, mac
      create ip, "#{key}", params[:value]
    end    
    
    delete "/:ip" do |ip|
      delete ip
    end

    post "/create_default" do
      create_default "syslinux"
    end

    # Create a new TFTP reservation
    post "/:mac" do |mac|
      create "syslinux", mac
    end

    # Delete a record from a network
    delete("/:mac") do |mac|
      delete "syslinux", mac
    end

    # Get the value for next_server
    get "/serverName" do
       {"serverName" => (Proxy::TFTP::Plugin.settings.tftp_servername || "")}.to_json
    end
  end
end
