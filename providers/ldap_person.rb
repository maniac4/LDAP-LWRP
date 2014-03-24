def whyrun_supported?
	true
end

use_inline_resources

action :process do

  first_level = new_resource.domain.split(".")[1]
  second_level = new_resource.domain.split(".")[0]
  
  if new_resource.parents.nil?
    full_entry = "cn=#{new_resource.person}"
  else 
    full_entry = "cn=#{new_resource.person}" + "," + "ou=#{new_resource.parents.join(",ou=")}"
  end
  
  auth = { :username => new_resource.username, :password => new_resource.password, :method => new_resource.method }

  @process_person = MainLDAP.new(new_resource.host, new_resource.port, auth)
  @dn = "#{full_entry},dc=#{second_level},dc=#{first_level}"
  @base = "dc=#{second_level},dc=#{first_level}"

  def create
    if @process_person.ldap_exists(@dn, @base, filter=Net::LDAP::Filter.eq("cn", "#{new_resource.person}"))
      Chef::Log.info("DN entry for person #{new_resource.person} already exists.Nothing to do.")
    else
      Chef::Log.info("DN entry for person #{new_resource.person} needs to be created")
      pass = Net::LDAP::Password.generate(:sha, "#{new_resource.person_pass}")
      attributes = {
        :cn => "#{new_resource.person}",
        :objectclass => ["top", "person"],
        :userPassword => pass
      }

    @process_person.ldap_add(@dn, attributes)
    end
  end

  def delete
    if @process_person.ldap_exists(@dn, @base, filter=Net::LDAP::Filter.eq("cn", "#{new_resource.person}"))
      Chef::Log.info("DN entry for person #{new_resource.person} exists.Deleting")
      @process_person.ldap_delete(@dn)
    else
      Chef::Log.info("DN entry for person #{new_resource.person} already deleted.Nothing to do")
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
