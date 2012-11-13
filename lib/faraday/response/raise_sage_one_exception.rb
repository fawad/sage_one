require 'faraday'

# @api private
module FaradayMiddleware

  # Checks the status of the API request and raises
  # relevant exceptions when detected.
  # @see SageOne::Error SageOne::Error for possible errors to rescue from.
  #
  # @api private
  class RaiseSageOneException < Faraday::Middleware
    def call(env)
      @app.call(env).on_complete do |response|
        case response[:status].to_i
        when 400
          raise SageOne::BadRequest, error_message(response)
        when 401
          raise SageOne::Unauthorized, error_message(response)
        when 403
          raise SageOne::Forbidden, error_message(response)
        when 404
          raise SageOne::NotFound, error_message(response)
        when 409
          raise SageOne::Conflict, error_message(response)
        when 422
          raise SageOne::UnprocessableEntity, error_message(response)
        end
      end
    end

    private

    def error_message(response)
      "#{response[:method].to_s.upcase} #{response[:url].to_s}: #{response[:status]} #{response_body_to_message(response[:body])}"
    end

    def response_body_to_message(body)
      return "" if body.nil?  # Nothing
      return body[:error] unless body[:error].nil? # OAuth requests
      rtn = []
      body['$diagnoses'].each { |d| rtn << "#{d['$source']}: #{d['$message']}" } unless body['$diagnoses'].nil?
      rtn.join(', ')
    end

  end
end
