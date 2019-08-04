require 'net/http'
require 'uri'
require 'nokogiri'
require 'pp'

# クローラー
class Crawler
  attr_reader :session_id
  def login
    password = File.open("#{Dir.home}/.sharecyclepass").read.chomp
    uri = URI.parse('https://tcc.docomo-cycle.jp/cycle/TYO/cs_web_main.php')
    request = Net::HTTP::Post.new(uri)
    request.content_type = 'application/x-www-form-urlencoded'
    request['Connection'] = 'keep-alive'
    request['Cache-Control'] = 'max-age=0'
    request['Origin'] = 'https://tcc.docomo-cycle.jp'
    request['Upgrade-Insecure-Requests'] = '1'
    request['User-Agent'] = 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/76.0.3809.87 Safari/537.36'
    request['Sec-Fetch-Mode'] = 'navigate'
    request['Sec-Fetch-User'] = '?1'
    request['Accept'] = 'text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,image/apng,*/*;q=0.8,application/signed-exchange;v=b3'
    request['Sec-Fetch-Site'] = 'same-origin'
    request['Referer'] = 'https://tcc.docomo-cycle.jp/cycle/TYO/cs_web_main.php?AreaID=1'
    request['Accept-Language'] = 'ja,en-US;q=0.9,en;q=0.8,ja-JP;q=0.7'
    request.set_form_data(
      'EventNo' => '21401',
      'GarblePrevention' => '%82o%82n%82r%82s%83f%81[%83^',
      'MemAreaID' => '1',
      'MemberID' => 'yugoyamamoto',
      'Password' => password
    )
    req_options = {
      use_ssl: uri.scheme == 'https'
    }
    response = Net::HTTP.start(uri.hostname, uri.port, req_options) do |http|
      http.request(request)
    end
    # response.code
    doc = Nokogiri::HTML.parse(response.body, nil, 'Shift_JIS')

    if doc.at_css('input[name=SessionID]')
      @session_id = doc.at_css('input[name=SessionID]')['value']
    else
      STDERR.puts 'login failed'
    end
  end

  def fetch_html(area_id)
    uri = URI.parse('https://tcc.docomo-cycle.jp/cycle/TYO/cs_web_main.php')
    request = Net::HTTP::Post.new(uri)
    request.content_type = 'application/x-www-form-urlencoded'
    request['Connection'] = 'keep-alive'
    request['Cache-Control'] = 'max-age=0'
    request['Upgrade-Insecure-Requests'] = '1'
    request['User-Agent'] = 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/75.0.3770.142 Safari/537.36'
    request['Origin'] = 'https://tcc.docomo-cycle.jp'
    request['Accept'] = 'text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,image/apng,*/*;q=0.8,application/signed-exchange;v=b3'
    request['Referer'] = 'https://tcc.docomo-cycle.jp/cycle/TYO/cs_web_main.php'
    request['Accept-Language'] = 'ja,en-US;q=0.9,en;q=0.8,ja-JP;q=0.7'
    request.set_form_data(
      'AreaID' => area_id.to_s,
      'EntServiceID' => 'TYO0001',
      'EventNo' => '21614',
      'GetInfoNum' => '100',
      'GetInfoTopNum' => '1',
      'Location' => '',
      'MapCenterLat' => '',
      'MapCenterLon' => '',
      'MapType' => '1',
      'MapZoom' => '13',
      'MemberID' => 'yugoyamamoto',
      'SessionID' => @session_id.to_s,
      'UserID' => 'TYO'
    )

    req_options = {
      use_ssl: uri.scheme == 'https'
    }

    response = Net::HTTP.start(uri.hostname, uri.port, req_options) do |http|
      http.request(request)
    end
    response.body
  end

  def ports(html)
    doc = Nokogiri::HTML.parse(html, nil, 'Shift_JIS')
    ports_elements = doc.css('form').reject do |item|
      item.css('div.port_list_btn_inner').empty?
    end
    ports_rows = []
    ports_elements.each do |port|
      lat = port.at_css('input[name=ParkingLat]')['value']
      lon = port.at_css('input[name=ParkingLon]')['value']
      texts = []
      port.at_css('div.port_list_btn_inner a').children.each do |ele|
        texts << ele.text if ele.name == 'text'
      end
      ports_rows << {
        lat: lat, lon: lon, place: texts.first, count_desc: texts.last,
        count: texts.last.to_i
      }
    end
    ports_rows
  end
end
