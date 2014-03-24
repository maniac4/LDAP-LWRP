def whyrun_supported?
	true
end

use_inline_resources

action :process do
  raise "Sudo ldap lwrp requires at least 1st sudo command to be defined" if new_resource.sudo_command1.nil?

  first_level = new_resource.domain.split(".")[1]
  second_level = new_resource.domain.split(".")[0]
  
  if new_resource.parents.nil?
    full_entry = "cn=#{new_resource.user_name}"
  else 
    full_entry = "cn=#{new_resource.user_name}" + "," + "ou=#{new_resource.parents.join(",ou=")}"
  end
  
  auth = { :username => new_resource.username, :password => new_resource.password, :method => new_resource.method }

  @process_sudo = MainLDAP.new(new_resource.host, new_resource.port, auth)
  @dn = "#{full_entry},dc=#{second_level},dc=#{first_level}"
  @base = "dc=#{second_level},dc=#{first_level}"

  def create
    if @process_sudo.ldap_exists(@dn, @base, filter=Net::LDAP::Filter.eq("sudouser", "#{new_resource.user_name}"))
      Chef::Log.info("DN entry for sudo user #{new_resource.user_name} already exists.Nothing to do.")
    else
      Chef::Log.info("DN entry for sudo group #{new_resource.user_name} needs to be created")
      command_list = Array.new
      1.upto(100) do |c|
        command = "new_resource.sudo_command#{c}"
        command_value = eval("#{command}")
        if !command_value.nil? and !command_list.include?(command_value)
          command_list.push(command_value)
        end
      end      
      attributes = {
        :cn => "#{new_resource.user_name}",
        :objectclass => ["top", "sudoRole"],
        :sudoUser => "#{new_resource.user_name}",
        :sudoOption => "#{new_resource.sudo_option}",
        :sudoHost => "#{new_resource.sudo_host}",
        :sudoCommand => command_list
      }

      @process_sudo.ldap_add(@dn, attributes)
    end
  end

  def delete
    if @process_sudo.ldap_exists(@dn, @base, filter=Net::LDAP::Filter.eq("sudouser", "#{new_resource.user_name}"))
      Chef::Log.info("DN entry for sudo user #{new_resource.user_name} exists.Deleting")
      @process_sudo.ldap_delete(@dn)
    else
      Chef::Log.info("DN entry for sudo user #{new_resource.user_name} already deleted.Nothing to do")
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
