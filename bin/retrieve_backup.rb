#!/usr/bin/env ruby

require 'rubygems'
require 'fog'
require 'openssl'
require 'optparse'

options = {}
optparse = OptionParser.new do |opts|
   opts.banner = "Usage: #{File.basename(__FILE__)} [options]"

   opts.on("-h",
      "--help",
      "Display this screen"
   ) do
      puts opts
      exit
   end

   opts.on("-d",
      "--date DATE",
      "Date to restore"
   ) do |date|
      options[:date] = date
   end

   opts.on("-k",
      "--key KEY",
      "Path to the private key"
   ) do |key|
      options[:key] = key
   end

end

begin
   optparse.parse!
   mandatory = [:key, :date]
   missing = mandatory.select{ |param| options[param].nil? }
   unless missing.empty?
      puts "Missing options: #{missing.join(', ')}"
      puts optparse
      exit 1
   end

rescue OptionParser::InvalidOption, OptionParser::MissingArgument
   puts $!.to_s
   puts optparse
   exit 1
end

class Restore

  attr_reader :date
  attr_reader :path_to_private_key
  attr_reader :secret
  attr_reader :remote
  attr_reader :config

  def initialize (date, path_to_private_key)

    @config = YAML.load_file(File.join(File.dirname(__FILE__), '../etc', "config.yml"))
    @remote = Remote.new(@config)
    @date = date
    @path_to_private_key = path_to_private_key

    @secret = self.decrypt_secret
  end

  def decrypt_secret
    encrypted_secret = @remote.download_key(@date)
    key = OpenSSL::PKey::RSA.new(File.read(@path_to_private_key))
    key.private_decrypt(encrypted_secret)
  end

  def decrypt_backup
    cipher = OpenSSL::Cipher.new("AES256")
    cipher.decrypt
    cipher.key = @secret
    cipher.update(@remote.download_backup(@date)) + cipher.final

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

  def download_key(date)
    dir = @service.directories.get(@config['bucket'] + '/' + date)
    dir.files.get("key").body
  end

  def download_backup(date)
    dir = @service.directories.get(@config['bucket'] + '/' + date)
    dir.files.get("backup").body
  end
end

sdsc = Restore.new(options[:date], options[:key])
puts sdsc.decrypt_backup
