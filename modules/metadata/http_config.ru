require 'metadata/metadata_api'

map "/metadata" do
  run Proxy::Metadata::Api
end
