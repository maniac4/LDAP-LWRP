def whyrun_supported?
	true
end

use_inline_resources

action :process do

  first_level = new_resource.domain.split(".")[1]
  second_level = new_resource.domain.split(".")[0]
  
  if new_resource.parents.nil?
    full_entry = "ou=#{new_resource.ou}"
  else 
    full_entry = "ou=#{new_resource.ou}" + "," + "ou=#{new_resource.parents.join(",ou=")}"
  end
  
  auth = { :username => new_resource.username, :password => new_resource.password, :method => new_resource.method }

  @process_ou = MainLDAP.new(new_resource.host, new_resource.port, auth)
  @dn = "#{full_entry},dc=#{second_level},dc=#{first_level}"
  @base = "dc=#{second_level},dc=#{first_level}"

  def create
    if @process_ou.ldap_exists(@dn, @base, filter=Net::LDAP::Filter.eq("ou", "#{new_resource.ou}"))
      Chef::Log.info("DN entry for ou #{new_resource.ou} already exists.Nothing to do.")
    else
      Chef::Log.info("DN entry for ou #{new_resource.ou} needs to be created")
      attributes = {
        :ou => "#{new_resource.ou}",
        :objectclass => ["top", "organizationalUnit"]
      }
      @process_ou.ldap_add(@dn, attributes)
    end
  end

  def delete
    if @process_ou.ldap_exists(@dn, @base, filter=Net::LDAP::Filter.eq("ou", "#{new_resource.ou}"))
      Chef::Log.info("DN entry for ou #{new_resource.ou} exists.Deleting")
      @process_ou.ldap_delete(@dn)
    else
      Chef::Log.info("DN entry for ou #{new_resource.ou} already deleted.Nothing to do")
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
