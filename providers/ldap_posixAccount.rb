def whyrun_supported?
	true
end

use_inline_resources

action :process do

  first_level = new_resource.domain.split(".")[1]
  second_level = new_resource.domain.split(".")[0]
  
  if new_resource.home_dir.nil?
    @home_dir = "/home/#{new_resource.user_name}"
  else
    @home_dir = new_resource.home_dir
  end

  if new_resource.parents.nil?
    full_entry = "uid=#{new_resource.user_name}"
  else 
    full_entry = "uid=#{new_resource.user_name}" + "," + "ou=#{new_resource.parents.join(",ou=")}"
  end
  
  auth = { :username => new_resource.username, :password => new_resource.password, :method => new_resource.method }

  @process_user = MainLDAP.new(new_resource.host, new_resource.port, auth)
  @dn = "#{full_entry},dc=#{second_level},dc=#{first_level}"
  @base = "dc=#{second_level},dc=#{first_level}"

  def create
    if @process_user.ldap_exists(@dn, @base, filter=Net::LDAP::Filter.eq("uid", "#{new_resource.user_name}"))
      Chef::Log.info("DN entry for user #{new_resource.user_name} already exists.Nothing to do.")
    else
      Chef::Log.info("DN entry for user #{new_resource.user_name} needs to be created")
      pass = Net::LDAP::Password.generate(:sha, new_resource.user_password)
      attributes = {
        :uid => "#{new_resource.user_name}",
        :cn => "#{new_resource.user_name}",
        :objectclass => ["top", "account", "posixAccount", "shadowAccount"],
        :userPassword => pass,
        :loginShell => "#{new_resource.shell}",
        :uidNumber => "#{new_resource.uid}",
        :gidNumber => "#{new_resource.gid}",
        :homeDirectory => @home_dir,
        :shadowLastChange => "15140",
        :shadowMin => "0",
        :shadowMax => "99999",
        :shadowWarning => "7"
      }

      @process_user.ldap_add(@dn, attributes)
    end
  end

  def delete
    if @process_user.ldap_exists(@dn, @base, filter=Net::LDAP::Filter.eq("uid", "#{new_resource.user_name}"))
      Chef::Log.info("DN entry for user #{new_resource.user_name} exists.Deleting")
      @process_user.ldap_delete(@dn)
    else
      Chef::Log.info("DN entry for user #{new_resource.user_name} already deleted.Nothing to do")
    end
  end

  case new_resource.make
  when "create"
    create
  when "delete"
    delete
  when "rebuild"
    delete
    create
  end
  
  new_resource.updated_by_last_action(true)

end
