def whyrun_supported?
	true
end

use_inline_resources

action :process do

  first_level = new_resource.domain.split(".")[1]
  @second_level = new_resource.domain.split(".")[0]
  auth = { :username => new_resource.username, :password => new_resource.password, :method => new_resource.method }

  @process_domain = MainLDAP.new(new_resource.host, new_resource.port, auth)
  @dn = "dc=#{@second_level},dc=#{first_level}"
  @base = @dn

  def create
    if @process_domain.ldap_exists(@dn, @base, filter=Net::LDAP::Filter.eq("dc", "#{@second_level}"))
      Chef::Log.info("DN entry for domain #{new_resource.domain} already exists.Nothing to do.")
    else
      Chef::Log.info("DN entry for domain #{new_resource.domain} needs to be created")
      attributes = {
        :dc => "#{@second_level}",
        :objectclass => ["top", "domain"]
      }
      @process_domain.ldap_add(@dn, attributes)
    end
  end

  def delete
    if @process_domain.ldap_exists(@dn, @base, filter=Net::LDAP::Filter.eq("dc", "#{@second_level}"))
      Chef::Log.info("DN entry for domain #{new_resource.domain} exists. Deleting.")
      @process_domain.ldap_delete(@dn)
    else
      Chef::Log.info("DN entry for domain #{new_resource.domain} already deleted.Nothing to do")
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
