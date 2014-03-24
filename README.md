Description:
=============
Configures LDAP Database using net-ldap gem and chef.

Dependencies:
--------------
```text
  Gems:
    net-ldap gem
    digest gem(goes natively in latest chef-solo/chef-client package)
  Schemas:
    core.schema(moved sn attribute from person objectclass from must to may section)
    nis.schema(added groupname attribute for searching in this library for posixGroup objectclass)
    sudo.schema
```

Actions:
---------
```text
Default action is process.
But if you want to manipulate the resourse you need to user attribute make.
Which can have 3 values:
-create (Creates entry.But do not modifies it if it exists)
-delete (Deletes entry if it exists)
-rebuild (This value you should use if you need to modify an entry.It simply sequentialy executes "delete" and then "create" values) 
```
Warning:
-----------
Please make sure that entry you are installing is having properly builded tree.
So if you want to install cn=test,ou=test1,ou=test,dc=exmaple,dc=com you should have this entry available u=test1,ou=test,dc=exmaple,dc=com.
Otherwise you will recieve an exception.
Also please avoid of attributes duplicates. 

Brief usage examples in recipe:
---------------------------------
```text
server_ip = "10.10.10.10"
domain = "dc=example,dc=com"
root_user = "cn=root,#{domain}"
root_pass = "secretpassword"

#Creates initial entry for example.com domain
ldap_domain "example.com" do
  host server_ip
  username root_user
  password root_pass
end

#Creates ou=test, from example.com base entry.So it will be : ou=test,dc=example,dc=com
ldap_organizationalUnit "test" do
  host server_ip
  username root_user
  password root_pass
  domain "example.com"
end

#Creates ou=testi1, from ou=test entry in example.com base domain.So it will be : ou=test1,ou=test,dc=example,dc=com
ldap_organizationalUnit "test1" do
  host server_ip
  username root_user
  password root_pass
  domain "example.com"
  parents ["test"] #Parents attribute accepts ou entries list in array.Later it will concatenate it generating DN entry
end

#Creates internal ldap user which can be granted privileges for reading,writing.
ldap_person "client" do
  host server_ip
  username root_user
  password root_pass
  domain "example.com"
  person_pass "test1234" #For password will be generated sha string.And it will be stored in LDAP not in plain view
  make "rebuild"
end

ldap_person "client2" do
  host server_ip
  parents ["test"] #Parents attribute accepts ou entries list in array.Later it will concatenate it generating DN entry
  username root_user
  password root_pass
  domain "example.com"
  person_pass "test1234" #For password will be generated sha string.And it will be stored in LDAP not in plain view
  make "rebuild"
end

#Creates posix group for linux group usage.
ldap_posixGroup "test" do
  host server_ip
  gid 5555
  username root_user
  password root_pass
  domain "example.com"
  make "rebuild"
 end

 ldap_posixGroup "test1" do
  host server_ip
  parents ["test"] #Parents attribute accepts ou entries list in array.Later it will concatenate it generating DN entry
  gid 5556
  username root_user
  password root_pass
  domain "example.com"
 end

#Creates posix user for linux user usage.
 ldap_posixAccount "test" do
  user_password "test1234" #For password will be generated sha string.And it will be stored in LDAP not in plain view
  host server_ip
  uid 5555
  gid 5555
  username root_user
  password root_pass
  domain "example.com"
 end

ldap_posixAccount "test123" do
  user_password "test1234"
  host server_ip
  parents ["test"]
  shell "/sbin/nologin"
  home_dir "/home/test321"
  uid 5588
  gid 5588
  username root_user
  password root_pass
  domain "example.com"
  make "rebuild"
 end

#Creates sudo privileges for desired user.
 ldap_sudoRole "test" do
  sudo_command1 "rm -rf *"
  sudo_command2 "/etc/init.d"
  sudo_command3 "tail -f /var/log/*"
  parents ["SUDOers"]
  host server_ip
  username root_user
  password root_pass
  domain "example.com"
end
```

