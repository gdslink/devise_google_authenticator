module DeviseGoogleAuthenticator::Patches
  # patch Sessions controller to check that the OTP is accurate
  module CheckGA
    extend ActiveSupport::Concern
    included do
      # here the patch

      alias_method :create_original, :create

      define_method :create do

        resource = warden.authenticate!(:scope => resource_name, :recall => "#{controller_path}#new")

        if resource.respond_to?(:get_qr) and ActiveRecord::ConnectionAdapters::Column.value_to_boolean(resource.gauth_enabled) #Therefore we can quiz for a QR
          tmpid = resource.assign_tmp #assign a temporary key and fetch it
          warden.logout #log the user out

          #we head back into the checkga controller with the temporary id
          respond_with resource, :location => { :controller => 'devise/checkga', :action => 'show', :id => tmpid}
        elsif resource.respond_to?(:get_qr) and !ActiveRecord::ConnectionAdapters::Column.value_to_boolean(resource.gauth_enabled) and resource.gauth_secret
          #we head back into the checkga controller with the temporary id
          respond_with resource, :location => { :controller => 'devise/displayqr', :action => 'show'}
        else #It's not using, or not enabled for Google 2FA - carry on, nothing to see here.
          set_flash_message(:notice, :signed_in) if is_flashing_format?
          sign_in(resource_name, resource)
          respond_with resource, :location => after_sign_in_path_for(resource)
        end

      end

    end
  end
end
