#!/usr/bin/env ruby

# This will list out all active vault tokens that are stored in a consul backend
# It displays the DisplayName, Key (token), and associated policies, per token

require "net/http"
require "json"

consul_addr = ""
consul_token = ENV["CONSUL_TOKEN"]
vault_addr = ""
vault_token = ENV["VAULT_TOKEN"]

def fetch_resp(uri, token, limit = 10)
  raise ArgumentError, "too many HTTP redirects" if limit == 0

  req = Net::HTTP::Get.new(uri)

  if uri.to_s.include?("sys/raw")
    req.add_field("X-Vault-Token", "#{token}")
  else
    req.add_field("X-Consul-Token", "#{token}")
  end

  resp = Net::HTTP.start(uri.hostname, uri.port) do |http|
    http.request(req)
  end

  case resp
  when Net::HTTPSuccess
    resp
  when Net::HTTPRedirection
    location = resp["location"]
    # Follows redirects when using HA with vault and a standby nodeis reached
    fetch_resp(URI(location), token, limit - 1)
  else
    puts "Unexpected response from #{uri}"
  end
end

# Get list of paths to encrypted keys from consul
consul_uri = URI("#{consul_addr}/v1/kv/vault/sys/token/id?keys")
consul_resp = fetch_resp(consul_uri, consul_token)

body = JSON.parse(consul_resp.body)

# For each path/key in the consul response, query vault to read the key
body.each do |path|
  # Removes the backend path name from the path, if default this is "vault"
  path.sub!(/^\w+\//, "")

  vault_uri = URI("#{vault_addr}/v1/sys/raw/#{path}")
  vault_resp = fetch_resp(vault_uri, vault_token)

  h = JSON.parse(vault_resp.body)
  hv = JSON.parse(h["value"])

  puts "Display Name: #{hv["DisplayName"]}"
  puts "Key: #{hv["ID"]}"
  puts "Policies: #{hv["Policies"]}"
  puts "\n"
end
