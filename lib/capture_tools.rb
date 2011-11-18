require 'benchmark'
require 'json'
require 'net/http'
require 'uri'

module CaptureTools
  require 'capture_tools/errors'

  class Api
    Dir['./lib/capture_tools/api/*.rb'].each do |file|
      require('capture_tools/api/' + File.basename(file, File.extname(file)))
    end
    include CaptureTools::Api::Entity
    include CaptureTools::Api::EntityAuth
    include CaptureTools::Api::EntityType
    include CaptureTools::Api::Settings

    include Errors

    attr_reader :api_key, :base_url, :entity

    def initialize(arguments={}, logger=nil)
      @logger = logger
      @base_url = required_arg(arguments, :base_url).sub(/\/*$/, '')

      @headers = {
        'X-Application-Id' => required_arg(arguments, :app_id)
      }
      @authentication_args = {
        :client_id      => required_arg(arguments, :client_id),
        :client_secret  => required_arg(arguments, :client_secret),
      }
      unless noe(arguments[:entity])
        @authentication_args[:type_name] = arguments[:entity]
      end
    end

    def escape_val(val)
      val.gsub(/\'/) { |char| "\\'" }
    end

    def slash
      api_call({}, '')
    end

    # DA indicates that a client_id and client_secret that have direct access
    # priveledges are required for the api call.

    private

    def require_id(arguments={})
      arguments.delete :id if noe(arguments[:id])
      arguments.delete :uuid if noe(arguments[:uuid])
      if noe(arguments[:id]) && noe(arguments[:uuid])
        raise(CaptureHelperError.new(), "either id or uuid are required")
      end

      arguments[:id] || arguments[:uuid]
    end

    # HTTP api_call method with response handling
    def api_call(partial_query, method_name, headers = {})
      headers = @headers.merge(headers)
      # init query args
      query = partial_query.dup
      query.merge!(@authentication_args)

      # build uri
      uri = URI.parse("#{@base_url}/#{method_name}")
      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = uri.scheme == 'https'

      req = Net::HTTP::Post.new(uri.path)
      req.set_form_data(query)
      headers.each {|k, v| req[k] = v}
      http_res = nil # force scope
      total_time = Benchmark.realtime {
        http_res = http.start {|http_session|
          http_session.request(req)
        }
      }
      @logger.info("APID Call: #{method_name} " +
                   "Total time: #{total_time}") unless @logger.nil?
      handle_response http_res
    end

    def handle_response(http_res)
      if http_res.code == '200'
        begin
          data = JSON.parse(http_res.body)
        rescue JSON::ParserError => err
          raise CaptureRemoteError.new(), 'Unable to parse JSON response'
        end
      else
        raise CaptureRemoteError.new(),
              "Unexpected HTTP status code from server: #{http_res.code}\n" +
              "Message: #{http_res.body}"
      end

      if data['stat'] != 'ok'
        Errors::raise_from_response(data)
      end

      data
    end

    # Option Hash/Argument Helper methods
    def required_json_arg(option_hash, key)
      json_arg(true, option_hash, key)
    end

    def optional_json_arg(option_hash, key)
      json_arg(false, option_hash, key)
    end

    def json_arg(is_required, option_hash, key)
      value = get_arg(is_required, option_hash, key)

      if !noe(value)
        if value.class == String
          begin
            parsed = JSON.parse(value)
          rescue JSON::ParserError => err
            raise(CaptureHelperError.new(),
                  "Capture Error: Unable to parse JSON\n Error: #{err}")
          end
        elsif value.class == JSON
          value = JSON.to_s()
        elsif value.respond_to? :to_json
          value = value.to_json()
        else
          raise(CaptureHelperError.new(), 'Capture Error: Not JSON')
        end
        option_hash[key] = value # ensure JSON string
      end

      value
    end

    def required_arg(option_hash, key)
      get_arg(true, option_hash, key)
    end

    def optional_arg(option_hash, key)
      get_arg(false, option_hash, key)
    end

    def get_arg(is_required, option_hash, key)
      if option_hash.nil? || option_hash.class != Hash
        raise(CaptureHelperError.new(),
              "Capture Error: Invalid Arguments, #{key.to_s()}")
      end

      value = option_hash[key]
      if noe(value) && is_required
        raise(CaptureHelperError.new(),
              "Capture Error: Required arg missing, #{key.to_s()}")
      end

      value
    end
  end

  def nil_or_empty(it)
    if it.nil? || (it.is_a? String && it.empty?)
      true
    else
      false
    end
  end
  alias :neo :nil_or_empty
end