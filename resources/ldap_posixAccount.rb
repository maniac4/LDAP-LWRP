actions :process

default_action :process

attribute :user_name, :kind_of => String, :name_attribute => true, :required => true
attribute :parents, :kind_of => Array, :default => nil
attribute :domain, :regex => /^\w+\.\w+$/, :kind_of => String, :required => true
attribute :user_password, :kind_of => String, :required => true, :default => nil
attribute :shell, :kind_of => String, :default => "/bin/bash"
attribute :home_dir, :kind_of => String, :default => nil
attribute :uid, :kind_of => Integer, :required => true
attribute :gid, :kind_of => Integer, :required => true
attribute :host, :kind_of => [Integer, String], :default => "localhost"
attribute :port, :kind_of => [Integer, String], :default => "636"
attribute :username, :kind_of => String, :required => true
attribute :password, :kind_of => String, :required => true, :default => nil
attribute :method, :kind_of => Symbol, :default => :simple
attribute :encryption, :kind_of => Symbol, :default => :simple_tls
attribute :make, :regex => /^create|delete|rebuild$/, :kind_of => String, :default => "create"