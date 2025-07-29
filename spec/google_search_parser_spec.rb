# frozen_string_literal: true

require 'spec_helper'
require_relative '../lib/google_search_parser'

RSpec.shared_examples 'a valid google search result page with carousel' do
  it 'returns a JSON string' do
    expect(json_result).to be_a(String)
    expect { JSON.parse(json_result) }.not_to raise_error
  end

  it 'extracts the expected images' do
    expect(images).to match_array(expected_images)
  end

  it 'extract the expected information' do
    expect(images['artworks'].length).to be expected_images['artworks'].length
  end

  it 'has valid data' do
    expect(images['artworks']).not_to be_nil

    images['artworks'].each do |image|
      expect(image['name']).to be_a(String)
      expect(image['name']).not_to be_empty

      expect(image['link']).to be_a(String)
      expect(image['link']).to match(%r{\Ahttps://www\.google\.com/search\?[^ ]+})

      expect(image['image']).to be_a(String)
      expect(image['image']).not_to be_empty

      if image['extensions']
        expect(image['extensions']).to be_a(Array)
        expect(image['extensions'].first).to match(/^\d{4}$/) # validate the year format
      end
    end
  end
end

RSpec.describe GoogleSearchParser do
  let(:expected_images) { JSON.parse(expected_json) }
  let(:images) { JSON.parse(json_result) }
  let(:json_result) { parser.parse_images }
  let(:parser) { described_class.new(html_content) }

  describe '#parse_images' do
    context 'when parsing Van Gogh paintings' do
      let(:expected_json) { File.read('files/expected-array.json') }
      let(:html_content) { File.read('files/van-gogh-paintings.html') }

      it_behaves_like 'a valid google search result page with carousel'
    end

    context 'when parsing Pablo Picasso images HTML' do
      let(:expected_json) { File.read('files/pablo_picasso/expected_result.json') }
      let(:html_content) { File.read('files/pablo_picasso/search_result.html') }

      it_behaves_like 'a valid google search result page with carousel'
    end

    context 'when parsing Leonardo da Vinci images HTML' do
      let(:expected_json) { File.read('files/leonardo_da_vinci/expected_result.json') }
      let(:html_content) { File.read('files/leonardo_da_vinci/search_result.html') }

      it_behaves_like 'a valid google search result page with carousel'
    end

    context 'when parsing Claude Monet images HTML' do
      let(:expected_json) { File.read('files/claude_monet/expected_result.json') }
      let(:html_content) { File.read('files/claude_monet/search_result.html') }

      it_behaves_like 'a valid google search result page with carousel'
    end

    context 'when HTML has malformed structure but with valid data' do
      let(:expected_json) do
        {
          artworks: [
            {
              name: 'Sunflowers',
              link: 'https://www.google.com/search?sca_esv=c2e426814f4d07e9&gl=us&hl=en&q=' \
                    'Sunflowers&stick=H4sIAAAAAAAAAONgFuLQz9U3MI_PNVLiArFMUszTjcu1lLKTrfTL' \
                    'MotLE3PiE4tKkJiZxSVW5flF2cWLWLmCS_PScvLLU4uKARitY11JAAAA&sa=X&ved=2ah' \
                    'UKEwjK-K-JwLWKAxXcQTABHePpOFoQtq8DegQIMxAX',
              image: 'https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcS1s9TeQSMp52s4' \
                     'RilDMm5lMGHK26HjE3T6D-88O1l6Xf3pDCvv'
            },
            {
              name: 'Wheat Field with Cypresses',
              link: 'https://www.google.com/search?sca_esv=c2e426814f4d07e9&gl=us&hl=en&q=' \
                    'Wheat+Field+with+Cypresses&stick=H4sIAAAAAAAAAONgFuLQz9U3MI_PNVLiArFM' \
                    'SnJMTeK1lLKTrfTLMotLE3PiE4tKkJiZxSVW5flF2cWLWKXCM1ITSxTcMlNzUhTKM0syF' \
                    'JwrC4pSi4tTiwEkoHZyWQAAAA&sa=X&ved=2ahUKEwjK-K-JwLWKAxXcQTABHePpOFoQt' \
                    'q8DegQIMxAv',
              image: 'https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcQ-YYo-yqMf-K5i' \
                     '2GTIoT8OmNzoTdfxd55p4TbIcmtxLbyYvKzO',
              extensions: [
                '1889'
              ]
            }
          ]
        }.to_json
      end
      let(:html_content) { File.read('files/malformed_with_valid_data.html') }

      it_behaves_like 'a valid google search result page with carousel'
    end

    context 'when HTML has no images section' do
      let(:empty_html_file) { 'files/empty_page.html' }
      let(:empty_html_content) { File.read(empty_html_file) }
      let(:empty_parser) { described_class.new(empty_html_content) }

      it 'returns an empty JSON array' do
        result = empty_parser.parse_images
        expect(result).to eq([])
      end
    end

    context 'when HTML has malformed structure without valid data' do
      let(:malformed_html_file) { 'files/malformed.html' }
      let(:malformed_html_content) { File.read(malformed_html_file) }
      let(:malformed_parser) { described_class.new(malformed_html_content) }

      it 'returns an empty JSON array' do
        result = malformed_parser.parse_images
        expect(result).to eq([])
      end
    end
  end
end
