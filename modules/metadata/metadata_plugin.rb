module Proxy::Metadata
  class Plugin < ::Proxy::Plugin
    plugin :metadata, ::Proxy::VERSION

    http_rackup_path File.expand_path("http_config.ru", File.expand_path("../", __FILE__))
    https_rackup_path File.expand_path("http_config.ru", File.expand_path("../", __FILE__))

    default_settings :tftproot => '/var/lib/tftpboot'
  end
end