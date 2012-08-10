require 'nokogiri'
require 'redis'
require 'typhoeus'

countries = %w{AD AE AF AG AI AL AM AO AQ AR AS AT AU AW AX AZ BA BB BD BE BF BG BH BI BJ BL BM BN BO BQ BR BS BT BV BW BY BZ CA CC CD CF CG CH CI CK CL CM CN CO CR CU CV CW CX CY CZ DE DJ DK DM DO DZ EC EE EG EH ER ES ET FI FJ FK FM FO FR GA GB GD GE GF GG GH GI GL GM GN GP GQ GR GS GT GU GW GY HK HM HN HR HT HU ID IE IL IM IN IO IQ IR IS IT JE JM JO JP KE KG KH KI KM KN KP KR KW KY KZ LA LB LC LI LK LR LS LT LU LV LY MA MC MD ME MF MG MH MK ML MM MN MO MP MQ MR MS MT MU MV MW MX MY MZ NA NC NE NF NG NI NL NO NP NR NU NZ OM PA PE PF PG PH PK PL PM PN PR PS PT PW PY QA RE RO RS RU RW SA SB SC SD SE SG SH SI SJ SK SL SM SN SO SR SS ST SV SX SY SZ TC TD TF TG TH TJ TK TL TM TN TO TR TT TV TW TZ UA UG UM US UY UZ VA VC VE VG VI VN VU WF WS YE YT ZA ZM ZW}

pricing_url = 'http://twilio.com/voice/pricing'

redis = Redis.new

countries.each do |alpha2|
  begin
    response = Typhoeus::Request.get("#{pricing_url}/#{alpha2}", follow_location: true)
    if response.success?
      doc = Nokogiri::HTML(response.body)
      table = doc.search('#all-pricing table:first')
      rows = table.search('tr')
      skipped_first = false
      rows.map do |row|
        unless skipped_first
          skipped_first = true
          next
        end
        data = row.search('td')
        country = data[0].text
        price = data[1].text
        prefixes = data[2].text.strip.split(',').map(&:strip)
        prefixes.each do |prefix|
          redis.set prefix, "#{price}"
          serialized_country = "#{alpha2}:#{country}"
          puts "#{prefix} => #{price}"
          redis.sadd "countries:#{prefix}", serialized_country
          puts "countries:#{prefix} << #{serialized_country}"
        end
      end
    end
  rescue Exception => e
    puts e
    puts alpha2
  end
end
