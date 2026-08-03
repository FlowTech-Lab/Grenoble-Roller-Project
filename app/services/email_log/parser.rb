# frozen_string_literal: true

module EmailLog
  class Parser
    def self.call(arguments_data)
      new(arguments_data).call
    end

    def initialize(arguments_data)
      @arguments_data = arguments_data
    end

    def call
      return empty_result if @arguments_data.blank?

      parsed_data = normalize_data(@arguments_data)
      args = extract_args_array(parsed_data)
      return empty_result unless args.is_a?(Array) && args.length >= 2

      {
        mailer: args[0].to_s.presence,
        method: args[1].to_s.presence,
        args: args[2..] || []
      }
    rescue JSON::ParserError => e
      Rails.logger.error("EmailLog::Parser JSON error: #{e.message}")
      empty_result
    rescue StandardError => e
      Rails.logger.error("EmailLog::Parser error: #{e.class} - #{e.message}")
      empty_result
    end

    private

    def normalize_data(data)
      case data
      when String
        JSON.parse(data).with_indifferent_access
      when Hash
        data.with_indifferent_access
      else
        data
      end
    end

    def extract_args_array(parsed_data)
      if parsed_data.is_a?(Hash)
        parsed_data[:arguments]
      elsif parsed_data.is_a?(Array)
        parsed_data
      end
    end

    def empty_result
      { mailer: nil, method: nil, args: [] }
    end
  end
end
