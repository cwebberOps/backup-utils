#!/usr/bin/env ruby

require 'rubygems'
require 'fog'
require 'openssl'

config = YAML.load_file(File.join(File.dirname(__FILE__), '../etc', "config.yml"))

class Backup

  # This is the payload data that is being backed up
  attr_reader :value

  # This is the syncronous key used for encrypting the backup
  attr_reader :secret

  def initialize(value)
    @value = value

    # Generate random characters
    o = [('a'..'z'),('A'..'Z'),('0' .. '9')].map{|i| i.to_a}.flatten

    # Generate a random key for each backup
    @secret = (0..128).map{ o[rand(o.length)]  }.join

  end

  # Ecrypt the secret with the public RSA key that was pre-generated
  #
  # Returns: Encrypted secret
  def encrypt_secret(path_to_public_key)
    @public_key = OpenSSL::PKey::RSA.new(File.read(path_to_public_key))
    @public_key.public_encrypt(@secret)
  end

  # Encrypt the payload value. 
  #
  # Returns the payload encrypted.
  def encrypt_value
    cipher = OpenSSL::Cipher.new("AES256")
    cipher.encrypt
    cipher.key = @secret
    cipher.update(@value) + cipher.final
  end

end

class Remote

  attr_reader :dirname
  attr_reader :service

  def initialize(config)

    @service = Fog::Storage.new(
      :provider           => 'rackspace',
      :rackspace_api_key  => config['rackspace_api_key'],
      :rackspace_username => config['rackspace_username'],
      :rackspace_auth_url => config['rackspace_auth_url']
    )

    @config = config

  end

  def upload(name, value)
    self.create_backup_dir
    dir = @service.directories.get(@dirname)
    dir.files.create(
      :key  => name,
      :body => value
    )
  end

  def create_backup_dir
    t = Time.now
    @dirname = @config['bucket'] + '/' + t.strftime("%Y-%m-%d")
    unless @service.directories.get(@dirname)
      @service.directories.create(:key => @dirname)
    end
  end
end

backup = Backup.new(`#{config['command']}`)
dest = Remote.new(config)
dest.upload("key", backup.encrypt_secret(config['path_to_public_key']))
dest.upload("backup", backup.encrypt_value)


