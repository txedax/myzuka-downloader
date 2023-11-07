# typed: true
# frozen_string_literal: true

require 'uri'
require 'net/http'

# Formats strings
module StringFormat
  def remove_os_restricted(string)
    string.gsub(%r{[<>"/\\|?*#@&:]}, '')
  end

  def replace_multi(string, pattern)
    string.gsub(Regexp.union(pattern.keys), pattern)
  end

  module_function :remove_os_restricted, :replace_multi
end

# Allows to make http requests and download files.
module Requests
  def fetch(url)
    uri = URI(url)
    request = Net::HTTP::Get.new(uri)
    request['User-Agent'] = 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/118.0.0.0 Safari/537.36'

    response = Net::HTTP.start(uri.hostname, uri.port, use_ssl: uri.scheme == 'https') { |http| http.request(request) }

    case response
    when Net::HTTPSuccess     then response.body
    when Net::HTTPRedirection then fetch(response['location'])
    else response.error!
    end
  end

  def download(url, path)
    return if File.exist?(path)

    File.open(path, 'wb') do |file|
      file.write(fetch(url))
    end
  end

  module_function :fetch, :download
end

# Downloads your album.
class MDownloader
  attr_reader :album_name, :songs_data

  def initialize
    raise StandardError, 'URL is not provided' if ARGV.first.nil?
    raise StandardError, 'URL is not valid' if ARGV.first[%r{https://myzuka.club/Album/\d+/[A-Za-z0-9-]+}].nil?

    parse_data
    format_data
  rescue StandardError => e
    puts "Script failed with 'StandardError': #{e.message}"

    exit 1
  end

  def download
    Dir.mkdir("downloads/#{@album_name}") unless File.directory?("downloads/#{@album_name}")

    @songs_data.each do |item|
      Requests.download("https://myzuka.club#{item['song_url']}", "downloads/#{@album_name}/#{item['song_name']}.mp3")
      puts "File downloaded: #{item['song_name']}"
      sleep(rand(3..5))
    end
  end

  private

  def format_data
    @album_name = StringFormat.remove_os_restricted(@album_name)
    @songs_data = @songs_data.map do |item|
      {
        'song_name' => StringFormat.remove_os_restricted(StringFormat.replace_multi(item['song_name'], { '&#39;' => '\'' })),
        'song_url' => StringFormat.replace_multi(item['song_url'], { 'Play' => 'Download', 'amp;' => '' })
      }
    end
  end

  def parse_data
    html = Requests.fetch(ARGV.first)

    @album_name = html[%r{<h1>(.*?)</h1>}, 1]
    @songs_data = html.scan(/<span class="ico ".+?>/).inject([]) do |result, item|
      song_name = item[/data-title="([^"]+)"/, 1]
      song_url = item[/data-url="([^"]+)"/, 1]

      result << { 'song_name' => song_name, 'song_url' => song_url }
    end
  end
end

MDownloader.new.download if __FILE__ == $PROGRAM_NAME
