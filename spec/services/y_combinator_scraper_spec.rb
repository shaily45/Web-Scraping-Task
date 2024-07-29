# frozen_string_literal: true

require 'rails_helper'

RSpec.describe YCombinatorScraper do
  let(:filters) { {} }
  let(:number) { 3 }
  let(:scraper) { YCombinatorScraper.new(number, filters) }

  describe '#scrape' do
    context 'when scraping is successful' do
      before do
        allow(scraper).to receive(:fetch_companies_list).and_return(Nokogiri::HTML('<html></html>'))
        allow(scraper).to receive(:fetch_company_details).and_return({ website: 'http://example.com',
                                                                       founders: 'John Doe, Jane Smith', founders_linkedin: 'http://linkedin.com/johndoe,http://linkedin.com/janesmith' })

        company_name_elements = [double(text: 'Company A'), double(text: 'Company B'), double(text: 'Company C')]
        location_elements = [double(text: 'Location A'), double(text: 'Location B'), double(text: 'Location C')]
        description_elements = [double(text: 'Description A'), double(text: 'Description B'),
                                double(text: 'Description C')]
        batch_elements = [double(text: 'Batch A'), double(text: 'Batch B'), double(text: 'Batch C')]
        company_url_elements = [double(attr: '/company-a'), double(attr: '/company-b'), double(attr: '/company-c')]

        allow_any_instance_of(Nokogiri::HTML::Document).to receive(:css).with('span._coName_86jzd_453').and_return(company_name_elements)
        allow_any_instance_of(Nokogiri::HTML::Document).to receive(:css).with('span._coLocation_86jzd_469').and_return(location_elements)
        allow_any_instance_of(Nokogiri::HTML::Document).to receive(:css).with('span._coDescription_86jzd_478').and_return(description_elements)
        allow_any_instance_of(Nokogiri::HTML::Document).to receive(:css).with('span._pill_86jzd_33').and_return(batch_elements)
        allow_any_instance_of(Nokogiri::HTML::Document).to receive(:css).with('a._company_86jzd_338').and_return(company_url_elements)
      end

      it 'returns success and scraped data' do
        result = scraper.scrape

        expect(result.first).to eq(:success)
        expect(result.last).to all(include(:company_name, :location, :short_description, :yc_batch,
                                           :company_detail_url, :website, :founders, :founders_linkedin))
        expect(result.last.size).to eq(number)
      end
    end

    context 'when an error occurs' do
      before do
        allow(scraper).to receive(:fetch_companies_list).and_raise(StandardError, 'An error occurred')
      end

      it 'returns error and error message' do
        result = scraper.scrape

        expect(result.first).to eq(:error)
        expect(result.last).to eq('An error occurred')
      end
    end
  end

  describe '#build_url' do
    context 'when filters are empty' do
      it 'returns the base URL' do
        expect(scraper.send(:build_url)).to eq(YCombinatorScraper::BASE_URL)
      end
    end

    context 'when filters are present' do
      let(:filters) { { batch: 'Summer2021', industry: 'Software' } }

      it 'returns the correct URL with filters' do
        expected_url = "#{YCombinatorScraper::BASE_URL}?batch=Summer2021&industry=Software"
        expect(scraper.send(:build_url)).to eq(expected_url)
      end
    end

    context 'when filters are present including company_size' do
      let(:filters) { { batch: 'YC22', industry: 'Tech', 'company_size' => '1-10' } }

      it 'returns the correct URL with filters' do
        expected_url = "#{YCombinatorScraper::BASE_URL}?batch=YC22&industry=Tech&team_size=%5B%221%22%2C%2210%22%5D"
        expect(scraper.send(:build_url)).to eq(expected_url)
      end
    end
  end

  describe '#fetch_company_details' do
    let(:company_url) { '/company-a' }
    let(:detail_url) { URI.join(YCombinatorScraper::BASE_URL, company_url).to_s }
    let(:html_content) do
      <<-HTML
      <html>
        <body>
          <div class="text-linkColor">
            <a href="http://example.com">Example</a>
          </div>
          <div class="leading-snug">
            <span class="font-bold">John Doe</span>
            <span class="font-bold">Jane Smith</span>
            <a href="http://linkedin.com/johndoe" title="LinkedIn profile">John Doe LinkedIn</a>
            <a href="http://linkedin.com/janesmith" title="LinkedIn profile">Jane Smith LinkedIn</a>
          </div>
        </body>
      </html>
      HTML
    end

    before do
      allow(Faraday).to receive(:get).with(detail_url).and_return(double(body: html_content))
    end

    it 'returns company details' do
      details = scraper.send(:fetch_company_details, company_url)
      expect(details).to include(founders: 'John Doe, Jane Smith')
    end
  end
end
