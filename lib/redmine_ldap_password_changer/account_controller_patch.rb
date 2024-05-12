module RedmineLdapPasswordChanger
  module AccountControllerPatch

    def self.prepended(base)
      base.prepend(InstanceMethods)
    end

    module InstanceMethods
      # Lets user choose a new password
      def lost_password
        (redirect_to(home_url); return) unless Setting.lost_password?
        if prt = (params[:token] || session[:password_recovery_token])
          @token = Token.find_token("recovery", prt.to_s)
          if @token.nil?
            redirect_to home_url
            return
          elsif @token.expired?
            # remove expired token from session and let user try again
            session[:password_recovery_token] = nil
            flash[:error] = l(:error_token_expired)
            redirect_to lost_password_url
            return
          end

          # redirect to remove the token query parameter from the URL and add it to the session
          if request.query_parameters[:token].present?
            session[:password_recovery_token] = @token.value
            redirect_to lost_password_url
            return
          end

          @user = @token.user
          unless @user && @user.active?
            redirect_to home_url
            return
          end
          if request.post?
            if @user.must_change_passwd? && @user.check_password?(params[:new_password])
              flash.now[:error] = l(:notice_new_password_must_be_different)
            else
              @user.password, @user.password_confirmation = params[:new_password], params[:new_password_confirmation]
              @user.must_change_passwd = false
              if @user.save
                @token.destroy
                Mailer.deliver_password_updated(@user, User.current)
                flash[:notice] = l(:notice_account_password_updated)
                redirect_to signin_path
                return
              end
            end
          end
          render :template => "account/password_recovery"
          return
        else
          if request.post?
            email = params[:mail].to_s.strip
            user = User.find_by_mail(email)
            # user not found
            unless user
              flash.now[:error] = l(:notice_account_unknown_email)
              return
            end
            unless user.active?
              handle_inactive_user(user, lost_password_path)
              return
            end
            # user cannot change its password
            unless user.change_password_allowed?
              flash.now[:error] = l(:notice_can_t_change_password)
              return
            end
            # create a new token for password recovery
            token = Token.new(:user => user, :action => "recovery")
            if token.save
              # Don't use the param to send the email
              recipent = user.mails.detect {|e| email.casecmp(e) == 0} || user.mail
              Mailer.deliver_lost_password(user, token, recipent)
              flash[:notice] = l(:notice_account_lost_email_sent)
              redirect_to signin_path
              return
            end
          end
        end
      end
    end

  end
end
  
AccountController.prepend RedmineLdapPasswordChanger::AccountControllerPatch
