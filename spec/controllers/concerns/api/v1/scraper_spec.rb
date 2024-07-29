# frozen_string_literal: true

require 'rails_helper'
require 'csv'

RSpec.describe Api::V1::Scraper do
  let(:dummy_class) do
    Class.new do
      include Api::V1::Scraper
      def render(*args); end

      def respond_to(*args); end

      def send_data(*args); end
    end
  end
  let(:dummy_instance) { dummy_class.new }

  describe '#parse_scrape_params' do
    context 'with valid params' do
      let(:valid_params) { { filters: '{"n": 10}' } }

      it 'returns parsed filters' do
        expect(dummy_instance.parse_scrape_params(valid_params)).to eq({ 'n' => 10 })
      end
    end

    context 'with invalid params' do
      let(:invalid_params) { { filters: '{}' } }

      it 'returns an error' do
        result = dummy_instance.parse_scrape_params(invalid_params)
        expect(result).to eq({ error: 'Invalid or missing parameter: n' })
      end
    end
  end

  describe '#handle_scraped_data' do
    let(:status) { :success }
    let(:result) { [{ name: 'Company A' }, { name: 'Company B' }] }

    it 'responds to CSV format' do
      format_double = double('format')
      expect(dummy_instance).to receive(:respond_to).and_yield(format_double)
      expect(format_double).to receive(:csv)
      dummy_instance.handle_scraped_data(status, result)
    end
  end

  describe '#handle_csv_response' do
    context 'with successful scrape and data' do
      let(:status) { :success }
      let(:result) { [{ name: 'Company A' }, { name: 'Company B' }] }

      it 'sends CSV data' do
        expect(dummy_instance).to receive(:send_data)
        dummy_instance.handle_csv_response(status, result)
      end
    end

    context 'with no data' do
      let(:status) { :success }
      let(:result) { [] }

      it 'renders an error' do
        expect(dummy_instance).to receive(:render).with(
          json: { error: 'No data to export' },
          status: :no_content
        )
        dummy_instance.handle_csv_response(status, result)
      end
    end
  end
end
