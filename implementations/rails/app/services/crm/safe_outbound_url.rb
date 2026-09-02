# frozen_string_literal: true

require "ipaddr"
require "resolv"

module Crm
  class SafeOutboundUrl
    PRIVATE_RANGES = [
      IPAddr.new("0.0.0.0/8"), IPAddr.new("10.0.0.0/8"), IPAddr.new("100.64.0.0/10"),
      IPAddr.new("127.0.0.0/8"), IPAddr.new("169.254.0.0/16"),
      IPAddr.new("172.16.0.0/12"), IPAddr.new("192.168.0.0/16"), IPAddr.new("::1/128"),
      IPAddr.new("198.18.0.0/15"), IPAddr.new("224.0.0.0/4"), IPAddr.new("240.0.0.0/4"),
      IPAddr.new("::/128"), IPAddr.new("2001:db8::/32"), IPAddr.new("fc00::/7"),
      IPAddr.new("fe80::/10"), IPAddr.new("ff00::/8")
    ].freeze

    def self.allowed?(value)
      uri = URI.parse(value.to_s)
      return false unless uri.is_a?(URI::HTTPS) && uri.host.present? && uri.userinfo.nil?
      return true if ENV["CRM_ALLOW_PRIVATE_NETWORKS"] == "true"

      addresses = Resolv.getaddresses(uri.host)
      addresses.any? && addresses.all? do |address|
        ip = IPAddr.new(address)
        PRIVATE_RANGES.none? { |range| range.include?(ip) }
      end
    rescue URI::InvalidURIError, Resolv::ResolvError, IPAddr::InvalidAddressError
      false
    end
  end
end
