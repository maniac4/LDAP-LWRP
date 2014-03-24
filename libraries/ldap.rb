class MainLDAP

  def initialize(host, port, auth)
  	@host = host
  	@port = port
  	@auth = auth
  	ldap_bind
  end

  def ldap_bind(connection=NewConnection)
    require 'digest'
    require 'net/ldap'
  	@ldap_bind ||= connection.new(@host, @port, @auth)
  end

  def ldap_search(base, filter, search=LDAPHelper)
  	search.search(base, filter, @ldap_bind)
  end

  def ldap_add(dn, attrs, add=LDAPHelper)
    add.add(dn, attrs, @ldap_bind)
  end

  def ldap_delete(dn, delete=LDAPHelper)
  	delete.delete(dn, @ldap_bind)
  end

  def ldap_exists(dn, base, filter)
    search_result = ldap_search(base, filter)
    if !search_result.nil? and !search_result.empty?
      search_result.first.dn.eql?(dn)
    else
      false
    end
  end

end

class LDAPHelper

  def self.search(base, filter, ldap_bind)
    result = ldap_bind.search(:base => base, :filter => filter)
    raise "LDAP failed to process search action.Check your credentials." if result == false
    result
  end

  def self.add(dn, attrs, ldap_bind)
    result = ldap_bind.add(:dn => dn, :attributes => attrs)
    raise "LDAP failed to perform add action" if result == false
  end

  def self.delete(dn, ldap_bind)
    result = ldap_bind.delete(:dn => dn)
    raise "LDAP failes to perform delete action." if result == false
  end

end

class NewConnection

  def self.new(host, port, auth)
    result = Net::LDAP.new(:host => host, :port => port, :auth => auth, :encryption => :simple_tls)
    raise "Failes to initialize object.Please check input data." if result.bind == false
    result
  end

end  

