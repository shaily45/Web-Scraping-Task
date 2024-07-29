# frozen_string_literal: true

require 'rails_helper'
require 'csv'

RSpec.describe Api::V1::ScrapingController, type: :controller do
  describe 'POST #scrape' do
    let(:valid_filters) { { 'n' => 10, 'filters' => {} }.to_json }
    let(:invalid_filters) { { 'n' => nil, 'filters' => {} }.to_json }
    let(:empty_result) { [] }
    let(:valid_result) { [{ 'name' => 'Company A', 'url' => 'http://example.com' }] }

    before do
      allow(YCombinatorScraper).to receive(:new).and_return(double(scrape: [:success, valid_result]))
    end

    context 'with valid parameters' do
      it 'returns a CSV file with the correct filename' do
        post :scrape, params: { filters: valid_filters }, format: :csv
        expect(response.content_type).to eq('text/csv')
        expect(response.headers['Content-Disposition']).to include('attachment; filename="yc_companies_')
        expect(response.body).to include('name,url')
        expect(response.body).to include('Company A,http://example.com')
      end
    end

    context 'with invalid or missing parameters' do
      before do
        allow(YCombinatorScraper).to receive(:new).and_return(double(scrape: [:error, nil]))
      end

      it 'returns a 400 Bad Request when parameter n is missing or invalid' do
        post :scrape, params: { filters: invalid_filters }
        expect(response).to have_http_status(:bad_request)
        expect(response.body).to include('Invalid or missing parameter: n')
      end
    end

    context 'with no data to export' do
      before do
        allow(YCombinatorScraper).to receive(:new).and_return(double(scrape: [:success, empty_result]))
      end

      it 'returns a 204 No Content' do
        post :scrape, params: { filters: valid_filters }, format: :csv
        expect(JSON.parse(response.body)['error']).to eq('No data to export')
      end
    end

    context 'when generating CSV' do
      it 'generates a CSV with headers and values' do
        csv = controller.send(:generate_csv, valid_result)
        csv_array = CSV.parse(csv, headers: true)
        expect(csv_array.headers).to include('name', 'url')
        expect(csv_array[0]['name']).to eq('Company A')
      end
    end
  end
end
