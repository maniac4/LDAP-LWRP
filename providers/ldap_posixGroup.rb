def whyrun_supported?
	true
end

use_inline_resources

action :process do

  first_level = new_resource.domain.split(".")[1]
  second_level = new_resource.domain.split(".")[0]
  
  if new_resource.parents.nil?
    full_entry = "cn=#{new_resource.group_name}"
  else 
    full_entry = "cn=#{new_resource.group_name}" + "," + "ou=#{new_resource.parents.join(",ou=")}"
  end
  
  auth = { :username => new_resource.username, :password => new_resource.password, :method => new_resource.method }

  @process_group = MainLDAP.new(new_resource.host, new_resource.port, auth)
  @dn = "#{full_entry},dc=#{second_level},dc=#{first_level}"
  @base = "dc=#{second_level},dc=#{first_level}"

  def create
    if @process_group.ldap_exists(@dn, @base, filter=Net::LDAP::Filter.eq("groupname", "#{new_resource.group_name}"))
      Chef::Log.info("DN entry for group #{new_resource.group_name} already exists.Nothing to do.")
    else
      Chef::Log.info("DN entry for group #{new_resource.group_name} needs to be created")
      attributes = {
        :groupname => "#{new_resource.group_name}",
        :cn => "#{new_resource.group_name}",
        :objectclass => ["top", "posixGroup"],
        :gidNumber => "#{new_resource.gid}"
      }

      @process_group.ldap_add(@dn, attributes)
    end
  end

  def delete
    if @process_group.ldap_exists(@dn, @base, filter=Net::LDAP::Filter.eq("groupname", "#{new_resource.group_name}"))
      Chef::Log.info("DN entry for group #{new_resource.group_name} exists.Deleting")
      @process_group.ldap_delete(@dn)
    else
      Chef::Log.info("DN entry for group #{new_resource.group_name} already deleted.Nothing to do")
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
