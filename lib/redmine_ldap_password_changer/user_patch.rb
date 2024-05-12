module RedmineLdapPasswordChanger
  module UserPatch

    def self.prepended(base)
      base.include InstanceMethods
    end

    module InstanceMethods

      def isExternal?
        return auth_source_id.present?
      end

      def changeExternalPassword(password,newPassword,newPasswordConfirm)
        return false if newPassword == "" || newPassword.length < Setting.password_min_length.to_i
        return false if newPassword != newPasswordConfirm
        if (self.isExternal?)
          return self.auth_source.change_password(self.login,password,newPassword)
        end
        return false
      end

      def newExternalPassword(newPassword,newPasswordConfirm)
        return false if newPassword == "" || newPassword.length < 4
        return false if newPassword != newPasswordConfirm
        if (self.isExternal?)
          return self.auth_source.lost_password(self.login,newPassword)
        end
        return false
      end

    end

  end
end

User.prepend RedmineLdapPasswordChanger::UserPatch
