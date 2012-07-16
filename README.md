Backup Utils
============

Purpose
-------

This is a collection of misc utilities for doing backup things.

Requirements
------------

- fog gem
- ruby 1.8.7+

Utilities
---------

### backup.rb ###

This utility is configured using etc/config.yml and is used to take the
output of a command, encrypt it and then back it up. The idea is that
the private key never sits on the server that does the actual backup.

It uses fog to backup to a Swift or Rackspace endpoint.

The specific use case in mind was taking the output of slapcat in to
backup an LDAP server.

### restore.rb ###

This utility is configured using etc/config.yml and takes a private key
path and a date as an input. It then returns the corresponding backup
that was performed using backup.rb.
