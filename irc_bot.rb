require 'cinch'

gem 'ruby-ham'
require 'n0nbh'
require 'npota'
require 'aprsfi'
require 'dxwatch'

gem 'qrz-callbook'
require 'qrz-callbook'

gem 'forecast_io'
require 'forecast_io'
ForecastIO.api_key = ''

gem 'geocoder'
require 'geocoder'

require "cinch/plugins/identify"
require 'cinch/message'

require 'action_view'
require 'action_view/helpers'
include ActionView::Helpers::DateHelper

module Cinch
  class Message 
    def reply(text, prefix = false)
      if Time.now.utc.friday?
        text = text.upcase
      end

      text = text.to_s
      if @channel && prefix
        text = text.split("\n").map {|l| "#{user.nick}: #{l}"}.join("\n")
      end

      @target.send(text)
    end
  end
end

def wind_direction(degrees)
  case degrees
  when 22.5..67.5
    "↙"
  when 67.5..112.5
    "←"
  when 112.5..157.5
    "↖"
  when 157.5..202.5
    "↑"
  when 202.5..247.5
    "↗"
  when 247.5..292.5
    "→"
  when 292.5..337.5
    "↘"
  else
    "↓"
  end
end


bot = Cinch::Bot.new do
  configure do |c|
    c.delay_joins = 5
    c.server = "irc.geekshed.net"
    c.channels = ["#test123"]
    c.nick = "HamBone"
     # add all required options here
    c.plugins.plugins = [Cinch::Plugins::Identify] # optionally add more plugins
    c.plugins.options[Cinch::Plugins::Identify] = {
      :username => "HamBone2",
      :password => "changethis",
      :type     => :nickserv,
    }
  end
  
  on :message, /^!help$/i do |m|
    m.reply "#{m.user.nick}: !hf - band conditions, !geo - solar conditions, !callsign <CALL> - callsign info, !wx <LOCATION> - weather for a place"
  end

  on :message, /^!geo$/i do |m|
    m.reply "Solar Terrestrial Data - Solar Flux: #{N0nbh['solarflux']} - A-Index: #{N0nbh['aindex']} - K-Index: #{N0nbh['kindex']} / #{N0nbh['kindexnt']} - X-Ray: #{N0nbh['xray']} - Sunspots: #{N0nbh['sunspots']} - Helium Line: #{N0nbh['heliumline']} - Proton Flux: #{N0nbh['protonflux']} - Electron Flux: #{N0nbh['electonflux']} - Aurora: #{N0nbh['aurora']} - Normalization: #{N0nbh['normalization']} - Magnetic Field: #{N0nbh['magneticfield']} - Solar Wind: #{N0nbh['solarwind']} - http://n0nbh.com"
  end
  
  on :message, /^!w0ny$/i do |m|
    m.reply "W0NY is a p0ny!"
  end
  
  on :message, /^!kd9dal$/i do |m|
    m.reply "cuntbunt"
  end

   on :message, /^!bingbong$/i do |m|
    m.reply "CHINA!"
  end
  
   on :message, /^!ae5cp$/i do |m|
    m.reply "SWAGRID"
  end
  
   on :message, /^!tj$/i do |m|
    m.reply "IT PREASE"
  end
  
  on :message, /^!hf$/i do |m|
    m.reply "HF Conditions"
    m.reply "Band     Day   Night"
    %w(80m-40m 30m-20m 17m-15m 12m-10m).each do |band|
      day = N0nbh.band_conditions(band, :day)
      night = N0nbh.band_conditions(band, :night)
      m.reply "#{band}  #{day}  #{night}".gsub('Poor', 'AIDS')
    end
    m.reply "MUF: #{N0nbh['muf']}mhz - Noise: #{N0nbh['signalnoise']} - http://n0nbh.com" 
  end

  on :message, /^!callsign (.*)/i do |m, callsign|
    begin
      call = QRZCallbook.new({ 'callsign' => callsign, 'username' => 'NS7I', 'password' => 'changethis' }).get_listing

      operator = [call['fname'], call['name']].compact.join(' ')
      operator << " (#{call['class']})" if call['class'] && call['class'] != ''

      if call['land'] == call['country']
        location_a = []
        location_a << call['addr2'] if call['addr2'] && call['addr2'] != ''
        location_a << call['county'] + ' County' if call['county'] && call['county'] != ''
        location_a << call['state'] if call['state'] && call['state'] != ''
        location_a << call['country'] if call['country'] && call['country'] != ''
        location = location_a.compact.join(', ')
      else
        location = call['land']
      end

      location << " (#{call['grid']})" if call['grid'] && call['grid'] != ''
        
      response = [call['call'], operator, location, call['bio']].compact.join(' - ')
    rescue QRZCallbook::SessionError => e
      response = e.message
    end
    m.reply "#{m.user.nick}: #{response}"
  end

  on :message, /^!npota activations (.*)/i do |m, callsign|
    activations = NPOTA.activations_by_callsign(callsign)
    if activations.any?
      m.reply "#{m.user.nick}: #{activations.length} upcoming activations by #{callsign}"
      activations[0..1].each do |a|
        m.reply "#{a['Name']} #{a['Type']} (#{a['ARRLCode']}): #{a['StartDate']}Z - #{a['EndDate']}Z - #{a['Comments']}"
      end
    else 
      m.reply "#{m.user.nick}: There are no upcoming activations by #{callsign}"
    end
  end

  on :message, /^!hogie/i do |m|
    
    callsign = 'N3BBQ-9'
    location = APRSfi.last_location_for(callsign)

    if location
      m.reply "#{m.user.nick}: Last APRS Beacon for #{callsign} at #{location['geocoded'][0].address} (#{location['lat']}, #{location['lng']}) - #{time_ago_in_words(location['time'])} ago - http://aprs.fi/#!mt=roadmap&z=13&call=a%2F#{callsign}&timerange=604800&tail=604800"
    else
      m.reply "#{m.user.nick}: No APRS locations found"
    end

    callsign = 'N3BBQ'

    spots = DXWatch.spots_for(callsign)

    begin
      if spots
        spots[0..0].each do |s|
          m.reply "Last Spot: #{s[:frequency]} - #{s[:comment]} - (spotted by #{s[:de]} #{time_ago_in_words(s[:time])} ago)"
        end
      else
        m.reply "No spots found"
      end
    rescue OpenURI::HTTPError
      m.reply "Spots unavailable. Try again later"
    end

    activations = NPOTA.activations_by_callsign(callsign)
    if activations.any?
      m.reply "Upcoming activations by #{callsign}"
      activations.each do |a|
        start_date = DateTime.parse(a['StartDate'] + ' UTC').to_time
        end_date = DateTime.parse(a['EndDate'] + ' UTC').to_time
        next if Time.now > end_date
        next if (start_date  - Time.now) > 60*60*24 # dont show if less than 24hr
        m.reply "#{a['Name']} #{a['Type']} (#{a['ARRLCode']}): #{a['StartDate']}Z - #{a['EndDate']}Z - #{a['Comments']}"
      end
    end
  end

  on :message, /^!aprs (.*)/i do |m, callsign|
    location = APRSfi.last_location_for(callsign)

    if location
      m.reply "#{m.user.nick}: Last APRS Beacon for #{callsign} at #{location['geocoded'][0].address} (#{location['lat']}, #{location['lng']}) - #{time_ago_in_words(location['time'])} ago - http://aprs.fi/#!mt=roadmap&z=13&call=a%2F#{callsign}&timerange=604800&tail=604800"
    else
      m.reply "#{m.user.nick}: No APRS locations found"
    end
  end

  on :message, /^!spots (.*)/i do |m, callsign|
    spots = DXWatch.spots_for(callsign)

    begin
      if spots
        m.reply "#{m.user.nick}: Spots for #{callsign}"
        spots[0..2].each do |s|
          m.reply "#{s[:frequency]} - #{s[:comment]} - (spotted by #{s[:de]} #{time_ago_in_words(s[:time])} ago)"
        end
      else
        m.reply "#{m.user.nick}: No spots found"
      end
    rescue OpenURI::HTTPError
      m.reply "#{m.user.nick}: Try again later"
    end
  end

  on :message, /^!wx (.*)/i do |m, wx_input|
    latlng = Geocoder.search(wx_input)
    location = latlng[0].data['formatted_address']
    lat = latlng[0].data['geometry']['location']['lat']
    lng = latlng[0].data['geometry']['location']['lng']
    forecast = ForecastIO.forecast(lat, lng)
    m.reply "#{m.user.nick}: Weather for #{location}: #{forecast.currently.summary} - #{forecast.currently.temperature.round(0)}°F - Wind: #{forecast.currently.windSpeed}mph #{wind_direction(forecast.currently.windBearing)} - #{(forecast.currently.humidity*100).to_i}% humidity#{forecast.currently.precipProbability > 0 ? ' - ' + (forecast.currently.precipProbability*100).to_i.to_s + '% chance ' + forecast.currently.precipType + ' now - ' : ''}"
    m.reply "Today: #{forecast.daily.data[0].summary} High of #{forecast.daily.data[0].temperatureMax.to_i}°F, Low of #{forecast.daily.data[0].temperatureMin.to_i}°F"
    m.reply "Tomorrow: #{forecast.daily.data[1].summary} High of #{forecast.daily.data[1].temperatureMax.to_i}°F, Low of #{forecast.daily.data[1].temperatureMin.to_i}°F"
  end
end

bot.start
