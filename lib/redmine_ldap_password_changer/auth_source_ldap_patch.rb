module RedmineLdapPasswordChanger
  module AuthSourceLdapPatch

    def self.prepended(base)
      base.include InstanceMethods
    end

    module InstanceMethods

      def allow_password_changes?
        true
      end
      
      def password_encryption
        "SSHA"
      end

      def encode_password(clear_password)
        require 'digest'
        require 'base64'
        salt = User.generate_salt
        if self.password_encryption == "MD5"
          logger.debug "Encode as md5"
          return "{MD5}"+Base64.encode64(Digest::MD5.digest(clear_password)).chomp!
        end
        if self.password_encryption == "SSHA"
          logger.debug "Encode as ssha"
          return "{SSHA}"+Base64.encode64(Digest::SHA1.digest(clear_password+salt)+salt).chomp!
        end
        if self.password_encryption == "CLEAR"
          logger.debug "Encode as cleartype"
          return clear_password
        end
        #
      end

      # change password
      def change_password(login,password,newPassword)
        begin
          attrs = get_user_dn(login, password)
          if attrs
            logger.debug "Binding with user account"
            ldap_con = initialize_ldap_con(attrs[:dn], password)
            ops = [
              [:delete, :userPassword, password],
              [:add, :userPassword, newPassword]
            ]
            #return ldap_con.modify :dn => attrs[:dn], :operations => ops
            # This is another password change method, probably more common
            newPassword = encode_password(newPassword)
            # logger.info("NEW PASSWORD #{newPassword}")
            if newPassword.blank?
              logger.debug "Invaild password"
              return false
            else
              logger.debug "Try to change password"
              return ldap_con.replace_attribute attrs[:dn], :userPassword, newPassword
            end
          end
        rescue Exception => ex
          logger.error "LDAP: #{ex.message}"
          return false
        end
        return false
      end

      def lost_password(login,newPassword)
        begin
          attrs = get_user_dn_nopass(login)
          if attrs
            ldap_con = initialize_ldap_con(self.account, self.account_password)
             return ldap_con.replace_attribute attrs[:dn], :userPassword, encode_password(newPassword)
          end
        rescue
          return false
        end
        return false
      end

      def get_user_dn_nopass(login)
        ldap_con = nil
        ldap_con = initialize_ldap_con(self.account, self.account_password)
        attrs = {}
        search_filter = base_filter & Net::LDAP::Filter.eq(self.attr_login, login)
        ldap_con.search(:base => self.base_dn,
                        :filter => search_filter,
                        :attributes=> search_attributes) do |entry|
                                  if onthefly_register?
                                    attrs = get_user_attributes_from_ldap_entry(entry)
                                  else
                                    attrs = {:dn => entry.dn}
                                  end
                                  logger.debug "DN found for #{login}: #{attrs[:dn]}" if logger && logger.debug?
                                  end
        attrs
      end

    end

  end
end

AuthSourceLdap.prepend RedmineLdapPasswordChanger::AuthSourceLdapPatch
