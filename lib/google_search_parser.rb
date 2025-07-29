# frozen_string_literal: true

require 'nokogiri'
require 'json'

class GoogleSearchParser
  attr_reader :doc

  IMAGE_EXTENSION_SELECTOR = 'div.cxzHyb'
  IMAGE_BASE64_ID_REGEX = %r{data:image/jpeg;base64,([A-Za-z0-9+/=]+(?:\\x3d)*)}
  IMAGE_NAME_SELECTOR = 'div.pgNMRc'
  IMAGE_TAG_SELECTOR = 'img.taFZJe'

  def initialize(html_content)
    @doc = Nokogiri::HTML(html_content)
  end

  def parse_images
    serialize_response(extract_images)
  end

  def serialize_response(images)
    return [] if images.empty?

    {
      artworks: images
    }.to_json
  end

  private

  def extract_and_clean_base64(str)
    # Extract the base64 from the script tag
    if str =~ IMAGE_BASE64_ID_REGEX
      base64_content = Regexp.last_match(1)

      # Clean the hexadecimal escapes
      clean_base64 = base64_content.gsub(/\\x([0-9a-fA-F]{2})/) { |match| match[2..3].hex.chr }

      return "data:image/jpeg;base64,#{clean_base64}"
    end

    nil
  end

  def extract_image_base64_by_id(img_id)
    script = @doc.css('script').select do |script|
      script.to_s.scan(img_id).any?
    end

    return nil unless script.any?

    extract_and_clean_base64(script[0].children[0].to_s)
  end

  def extract_images
    @doc.css(IMAGE_TAG_SELECTOR).map do |img_tag|
      a_tag = img_tag.parent
      a_href = a_tag['href']
      extension = a_tag.at_css(IMAGE_EXTENSION_SELECTOR)&.text
      link = a_href.nil? ? nil : "https://www.google.com#{a_href}"

      img_data = {
        name: extract_name(a_tag),
        link: link,
        image: extract_image_url(a_tag)
      }

      img_data[:extensions] = [extension] unless extension.nil? || extension&.strip&.empty?

      img_data
    end
  end

  # Try to extract the name from the image section.
  # If the name is empty, extract the name from the image tag.
  def extract_name(a_tag)
    name = a_tag.at_css(IMAGE_NAME_SELECTOR)&.text

    return name unless name.nil? || name&.strip&.empty?

    img_tag = a_tag.at_css(IMAGE_TAG_SELECTOR)
    img_tag['alt']
  end

  def extract_image_url(a_tag)
    img_tag = a_tag.at_css(IMAGE_TAG_SELECTOR)

    if img_tag['id']
      # If the image has an id, extract the image base64 from the script tag by the id
      extract_image_base64_by_id(img_tag['id'])
    else
      img_tag['data-src']
    end
  end
end
