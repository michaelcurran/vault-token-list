#!/usr/bin/env ruby

# This will list out all active vault tokens that are stored in a consul backend
# It displays the DisplayName, Key (token), and associated policies, per token

require 'net/http'
require 'json'

consul_addr = ''
consul_token = ENV['CONSUL_TOKEN']
vault_addr = ''
vault_token = ENV['VAULT_TOKEN']

consul_uri = URI("#{consul_addr}/v1/kv/vault/sys/token/id?keys")
consul_req = Net::HTTP::Get.new(consul_uri)
consul_req.add_field("X-Consul-Token", "#{consul_token}")

consul_resp = Net::HTTP.start(consul_uri.hostname, consul_uri.port) do |http|
  http.request(consul_req)
end

body = JSON.parse(consul_resp.body)

body.each do |path|
  # Removes the backend path name from the path, if default this is "vault"
  path.sub!(/^\w+\//, '')

  vault_uri = URI("#{vault_addr}/v1/sys/raw/#{path}")
  vault_req = Net::HTTP::Get.new(vault_uri)
  vault_req.add_field("X-Vault-Token", "#{vault_token}")

  vault_resp = Net::HTTP.start(vault_uri.hostname, vault_uri.port) do |http|
    http.request(vault_req)
  end

  h = JSON.parse(vault_resp.body)
  hv = JSON.parse(h["value"])

  puts "Display Name: #{hv["DisplayName"]}"
  puts "Key: #{hv["ID"]}"
  puts "Policies: #{hv["Policies"]}"
  puts "\n"
end
