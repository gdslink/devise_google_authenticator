module DeviseGoogleAuthenticator
  class Engine < ::Rails::Engine # :nodoc:
    config.to_prepare do
      DeviseGoogleAuthenticator::Patches.apply
    end

  end
end
