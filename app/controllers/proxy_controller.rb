# app/controllers/proxy_controller.rb
class ProxyController < ApplicationController
  require 'net/http'
  require 'uri'
  require 'nokogiri'

  def fetch_url
    url = params[:url]
    
    if url.blank?
      render json: { error: 'URL parameter is required' }, status: :bad_request
      return
    end
  
    begin
      uri = URI.parse(url)
      response = Net::HTTP.get_response(uri)
      
      doc = Nokogiri::HTML(response.body)

      css_links = doc.css('link[rel="stylesheet"]').map do |link| 
        href = link['href']
        href.start_with?('http') ? href : URI.join(url, href).to_s
      end
  
      css_contents = css_links.map do |css_url|
        begin
          css_uri = URI.parse(css_url)
          css_response = Net::HTTP.get_response(css_uri)
          { url: css_url, content: css_response.body } if css_response.is_a?(Net::HTTPSuccess)
        rescue
          nil
        end
      end.compact
  
      doc.css('img').each do |img|
        src = img['src']&.strip
        next if src.nil? || src.empty?
        img['src'] = URI.join(url, src).to_s unless src.start_with?('http', '//')
      rescue URI::InvalidURIError => e
        Rails.logger.warn("Invalid URI for image src: #{src}, error: #{e.message}")
        next
      end
      
      
      headers['Access-Control-Allow-Origin'] = '*'
      headers['Access-Control-Allow-Methods'] = 'GET, OPTIONS'
      headers['Access-Control-Allow-Headers'] = 'Origin, X-Requested-With, Content-Type, Accept'
      
      render json: {
        html: doc.to_html,
        css: css_contents
      }
    rescue URI::InvalidURIError
      render json: { error: 'Invalid URL format' }, status: :bad_request
    rescue => e
      render json: { error: "Failed to fetch URL: #{e.message}" }, status: :internal_server_error
    end
  end
  
end