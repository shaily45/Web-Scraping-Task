# frozen_string_literal: true

require 'active_support/concern'

module Api
  module V1
    # Scraper module
    module Scraper
      extend ActiveSupport::Concern

      def parse_scrape_params(scrape_filters)
        parsed_filters = JSON.parse(scrape_filters[:filters])
        input_number = parsed_filters['n']&.to_i
        return { error: 'Invalid or missing parameter: n' } if input_number.nil?

        parsed_filters
      end

      def handle_scraped_data(status, result)
        respond_to do |format|
          format.csv { handle_csv_response(status, result) }
        end
      end

      def handle_csv_response(status, result)
        if status == :success && result.any?
          send_data generate_csv(result), filename: "yc_companies_#{Time.now.to_i}.csv"
        else
          render json: { error: 'No data to export' }, status: :no_content
        end
      end

      def generate_csv(data)
        return CSV.generate(headers: true) if data.empty?

        CSV.generate(headers: true) do |csv|
          csv << data.first.keys
          data.each do |hash|
            csv << hash.values
          end
        end
      end
    end
  end
end
