lib_dir = File.join(File.dirname(__FILE__), 'lib', 'redmine_ldap_password_changer')

# Redmine patches
patch_path = File.join(lib_dir, '*_patch.rb')
Dir.glob(patch_path).each do |file|
  require file
end