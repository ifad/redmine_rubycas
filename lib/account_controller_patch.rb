module AccountControllerPatch
  def login
    if params[:username].blank? && params[:password].blank? && RedmineRubyCas.enabled?
      if CASClient::Frameworks::Rails::Filter.filter(self)
        login = session[:"#{RedmineRubyCas.setting("username_session_key")}"]
        user  = User.where(login: login).first || User.new.tap{|u| u.login = login}

        if user.new_record?
          if RedmineRubyCas.setting("auto_create_users") == "true"
            user.attributes = RedmineRubyCas.user_extra_attributes_from_session(session)
            user.status = User::STATUS_REGISTERED

            register_automatically(user) do
              onthefly_creation_failed(user)
            end
          else
            render_error(
              :message => l(:cas_user_not_found, :user => session[:"#{RedmineRubyCas.setting("username_session_key")}"]),
              :status => 401
            )
          end
        else
          if user.active?
            if RedmineRubyCas.setting("auto_update_users") == "true"
              user.update_attributes(RedmineRubyCas.user_extra_attributes_from_session(session))
            end
            successful_authentication(user)
          else
            render_error(
              :message => l(:cas_user_not_found, :user => session[:"#{RedmineRubyCas.setting("username_session_key")}"]),
              :status => 401
            )
          end
        end

      end
    else
      super
    end
  end

  def logout
    if RedmineRubyCas.enabled? && RedmineRubyCas.setting("logout_of_cas_on_logout") == "true"
      CASClient::Frameworks::Rails::Filter.logout(self, home_url)
      logout_user
    else
      super
    end
  end
end
