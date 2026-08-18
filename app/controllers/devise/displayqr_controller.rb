class Devise::DisplayqrController < DeviseController
  prepend_before_filter :authenticate_scope!, :only => [:show,:update]
  
  include Devise::Controllers::Helpers
  
  def show
    if not resource.nil? and not resource.gauth_secret.nil?
      render :show
    else
      # Only re-establish the session when there IS a resource.
      #
      # This branch is reached precisely when resource is nil OR has no
      # gauth_secret, so the nil case is expected here. Devise's sign_in resolves
      # its record as `resource = args.last || resource_or_scope`
      # (devise-4.9.4/lib/devise/controllers/sign_in_out.rb:36), so passing a nil
      # resource made it fall back to the scope SYMBOL and Warden then tried to
      # serialize that:
      #   NoMethodError: undefined method `to_key' for :user:Symbol
      # -- a 500 before the page rendered at all.
      #
      # bypass_sign_in replaces `sign_in ..., :bypass => true`, which devise
      # 4.9.4 deprecates and will remove.
      bypass_sign_in(resource, scope: scope) if resource
      redirect_to stored_location_for(scope) || :root
    end
  end
  
  def update
    tmp = params[resource_name]
    resource.gauth_enabled = true
    resource.save!
    set_flash_message :notice, "Status Updated!"
    # Same deprecation fix as in #show. resource is non-nil on this path (it was
    # just saved above), so no guard is needed here.
    bypass_sign_in(resource, scope: scope)
    redirect_to stored_location_for(scope) || :root
  end
    
  private
  def scope
    resource_name.to_sym
  end
  
  def authenticate_scope!
    send(:"authenticate_#{resource_name}!")
    self.resource = send("current_#{resource_name}")
  end
end
