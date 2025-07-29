require 'debug'
require 'nokogiri'
require 'json'

class GoogleSearchParser
  attr_reader :doc

  IMAGE_EXTENSION_SELECTOR = 'div.cxzHyb'
  IMAGE_BASE64_ID_PREFIX = 'data:image/jpeg;base64,'
  IMAGE_BASE64_ID_REGEX = /data:image\/jpeg;base64,([A-Za-z0-9+\/=]+(?:\\x3d)*)/
  IMAGE_NAME_SELECTOR = 'div.pgNMRc'
  IMAGE_TAG_SELECTOR = 'img.taFZJe'
  IMAGE_SECTION_SELECTOR = 'div.iELo6'
  IMAGES_SECTION_SELECTOR = '[data-attrid="kc:/visual_art/visual_artist:works"]'

  def initialize(html_content)
    @doc = Nokogiri::HTML(html_content)
  end

  def parse_images
    # Look for the images section
    images_section = @doc.css(IMAGES_SECTION_SELECTOR)
    
    return [].to_json unless images_section
    
    images = extract_images_from_section(images_section)

    serialize_response(images)
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
      base64_content = $1
      
      # Clean the hexadecimal escapes
      clean_base64 = base64_content.gsub(/\\x([0-9a-fA-F]{2})/) { |match| match[2..3].hex.chr }
      
      return IMAGE_BASE64_ID_PREFIX + clean_base64
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

  def extract_images_from_section(section)
    images = section.css(IMAGE_SECTION_SELECTOR).map do |image_section|
      a_tag = image_section.at_css('a')
      a_href = a_tag['href']
      extension = a_tag.at_css(IMAGE_EXTENSION_SELECTOR).text
      link = a_href.nil? ? nil : "https://www.google.com#{a_href}"

      img_data = {
        name: a_tag.at_css(IMAGE_NAME_SELECTOR).text,
        link: link,
        image: extract_image_url(image_section)
      }

      img_data[:extensions] = [extension] unless extension.strip.empty?
        
      img_data
    end

    return images
  end

  def extract_image_url(image_section)
    img_tag = image_section.at_css(IMAGE_TAG_SELECTOR)

    if img_tag['id']
      # If the image has an id, extract the image base64 from the script tag by the id
      img_url = extract_image_base64_by_id(img_tag['id'])
    else
      img_url = img_tag['data-src']
    end
  end
end 
