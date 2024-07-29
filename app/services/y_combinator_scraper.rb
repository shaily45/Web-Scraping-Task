# frozen_string_literal: true

require 'selenium-webdriver'
require 'webdrivers'
require 'nokogiri'
require 'uri'

# YCombinatorScraper class
class YCombinatorScraper
  BASE_URL = 'https://www.ycombinator.com/companies'
  attr_reader :filters, :number

  def initialize(number, filters)
    @number = number
    @filters = filters || {}
  end

  def scrape
    doc = fetch_companies_list
    scraped_data = extract_company_data(doc)
    [:success, scraped_data]
  rescue StandardError => e
    [:error, e.message]
  end

  private

  def fetch_companies_list
    driver = initialize_selenium_driver
    # fetches result or wait atleast 10 secs
    Selenium::WebDriver::Wait.new(timeout: 10).until { driver.find_element(css: 'span._coName_86jzd_453') }
    doc = Nokogiri::HTML(driver.page_source)
    driver.quit
    doc
  end

  def initialize_selenium_driver
    options = Selenium::WebDriver::Chrome::Options.new(args: ['--headless', '--disable-gpu', '--no-sandbox',
                                                              '--disable-dev-shm-usage'])
    driver = Selenium::WebDriver.for(:chrome, options: options)
    driver.navigate.to(build_url)
    driver
  end

  def build_url
    return BASE_URL if filters.empty?

    result = filters.map do |key, value|
      param_key = filter_mappings[key.to_sym]
      next unless param_key && value

      encode_param = key == 'company_size' ? value.split('-').to_json : value
      encoded_value = URI.encode_www_form_component(encode_param)

      "#{param_key}=#{encoded_value}"
    end
    "#{BASE_URL}?#{result.join('&')}"
  end

  def filter_mappings
    { batch: 'batch',
      is_hiring: 'isHiring',
      industry: 'industry',
      region: 'regions',
      tag: 'tags',
      company_size: 'team_size',
      nonprofit: 'nonprofit',
      black_founded: 'highlight_black',
      hispanic_latino_founded: 'highlight_latinx',
      women_founded: 'highlight_women' }
  end

  def fetch_company_details(company_url)
    return {} unless company_url

    response = Faraday.get(URI.join(BASE_URL, company_url).to_s)
    doc = Nokogiri::HTML(response.body)
    {
      website: doc.css('div.text-linkColor a').attr('href'),
      founders: doc.css('.leading-snug .font-bold').map(&:text).join(', '),
      founders_linkedin: doc.css('.leading-snug a[title="LinkedIn profile"]').map { |link| link['href'] }.join(', ')
    }
  end

  def extract_company_data(doc)
    elements = transformed_selectors(doc)
    elements[:name].first(@number).map.with_index do |name_element, index|
      company_url = elements[:url][index]&.attr('href')
      detail_data = fetch_company_details(company_url)
      build_company_json(name_element, index, elements, detail_data, company_url)
    end
  end

  def transformed_selectors(doc)
    {
      name: 'span._coName_86jzd_453', location: 'span._coLocation_86jzd_469',
      description: 'span._coDescription_86jzd_478', batch: 'span._pill_86jzd_33',
      url: 'a._company_86jzd_338'
    }.transform_values { |selector| doc.css(selector) }
  end

  def build_company_json(name_element, index, elements, detail_data, company_url)
    {
      company_name: name_element.text,
      location: elements[:location][index]&.text,
      short_description: elements[:description][index]&.text,
      yc_batch: elements[:batch][index]&.text,
      company_detail_url: company_url
    }.merge(detail_data.slice(:website, :founders, :founders_linkedin))
  end
end
