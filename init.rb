Redmine::Plugin.register :redmine_ldap_password_changer do
  name 'Redmine LDAP Password Changer plugin'
  author 'Louie007'
  description 'This is a plugin for Redmine'
  version '0.0.1'
  url 'https://github.com/louie007/redmine_ldap_password_changer'
  author_url 'https://github.com/louie007'

  requires_redmine version_or_higher: '5.0'
end

require_relative 'after_init'
