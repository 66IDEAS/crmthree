# frozen_string_literal: true

require "net/http"

module Crm
  class OutboundHttp
    Response = ::Data.define(:status, :body, :headers) do
      def success? = status.between?(200, 299)

      def json
        JSON.parse(body)
      rescue JSON::ParserError
        nil
      end
    end

    MAX_RESPONSE_BYTES = 2.megabytes
    RETRY_STATUSES = [429, 502, 503, 504].freeze

    def initialize(open_timeout: 4, read_timeout: 20, max_attempts: 2)
      @open_timeout = open_timeout
      @read_timeout = read_timeout
      @max_attempts = max_attempts
    end

    def call(method:, url:, headers: {}, body: nil)
      return Result.failure(:unsafe_url, errors: ["The outbound URL is not allowed."]) unless SafeOutboundUrl.allowed?(url)

      attempts = 0
      begin
        attempts += 1
        response = perform(method:, url:, headers:, body:)
        raise ResponseTooLarge if response.body.to_s.bytesize > MAX_RESPONSE_BYTES
        retryable = RETRY_STATUSES.include?(response.code.to_i) && attempts < @max_attempts
        raise RetryableResponse if retryable

        Result.success(Response.new(status: response.code.to_i, body: response.body.to_s,
          headers: response.each_header.to_h))
      rescue RetryableResponse, Net::OpenTimeout, Net::ReadTimeout, Errno::ECONNRESET, EOFError => error
        retry if attempts < @max_attempts
        Rails.logger.warn("Outbound request failed after #{attempts} attempts (#{error.class.name})")
        Result.failure(:upstream_unavailable, errors: ["The external service did not respond in time."], status: :bad_gateway)
      rescue ResponseTooLarge
        Result.failure(:response_too_large, errors: ["The external response exceeded 2 MB."], status: :bad_gateway)
      rescue StandardError => error
        Rails.logger.warn("Outbound request failed (#{error.class.name})")
        Result.failure(:upstream_unavailable, errors: ["The external service is unavailable."], status: :bad_gateway)
      end
    end

    private

    RetryableResponse = Class.new(StandardError)
    ResponseTooLarge = Class.new(StandardError)

    def perform(method:, url:, headers:, body:)
      uri = URI.parse(url)
      request_class = {get: Net::HTTP::Get, post: Net::HTTP::Post, put: Net::HTTP::Put,
                       patch: Net::HTTP::Patch, delete: Net::HTTP::Delete}.fetch(method.to_sym)
      request = request_class.new(uri.request_uri)
      headers.each { |key, value| request[key] = value }
      request.body = body.is_a?(String) ? body : JSON.generate(body) if body
      Net::HTTP.start(uri.host, uri.port, use_ssl: true, open_timeout: @open_timeout,
        read_timeout: @read_timeout) { |http| http.request(request) }
    end
  end
end
