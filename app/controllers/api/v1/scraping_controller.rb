# frozen_string_literal: true

module Api
  module V1
    # ScrapingController class
    class ScrapingController < ApplicationController
      require 'csv'

      include Api::V1::Scraper

      def scrape
        parsed_filters = parse_scrape_params(scrape_params)
        return render json: { error: parsed_filters[:error] }, status: :bad_request if parsed_filters[:error].present?

        status, result = YCombinatorScraper.new(parsed_filters['n'], parsed_filters['filters']).scrape
        handle_scraped_data(status, result)
      end

      private

      def scrape_params
        params.permit(:filters)
      end
    end
  end
end
