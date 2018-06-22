module ::MItamae
  module Plugin
    module Resource
      class Download < ::MItamae::Resource::Base
        define_attribute :action, default: :fetch
        define_attribute :url, type: String, default_name: true
        define_attribute :destination, type: String
        define_attribute :mode, type: String
        define_attribute :owner, type: String
        define_attribute :group, type: String
        define_attribute :checksum, type: String

        self.available_actions = [:fetch]
      end
    end
  end
end
