require 'cinch'
gem 'n0nbh'
require 'n0nbh'

bot = Cinch::Bot.new do
  configure do |c|
    c.server = "irc.geekshed.net"
    c.channels = ["#hamtest123", "#fbom", "#redditnet"]
    c.nick = "HamBone"
  end

  on :message, "!geo" do |m|
    m.reply "Solar Terrestrial Data - Solar Flux: #{N0nbh['solarflux']} - A-Index: #{N0nbh['aindex']} - K-Index: #{N0nbh['kindex']} / #{N0nbh['kindexnt']} - X-Ray: #{N0nbh['xray']} - Sunspots: #{N0nbh['sunspots']} - Helium Line: #{N0nbh['heliumline']} - Proton Flux: #{N0nbh['protonflux']} - Electron Flux: #{N0nbh['electonflux']} - Aurora: #{N0nbh['aurora']} - Normalization: #{N0nbh['normalization']} - Magnetic Field: #{N0nbh['magneticfield']} - Solar Wind: #{N0nbh['solarwind']} - http://n0nbh.com"
  end

  on :message, "!hf" do |m|
    m.reply "HF Conditions"
    m.reply "Band     Day   Night"
    %w(80m-40m 30m-20m 17m-15m 12m-10m).each do |band|
      day = N0nbh.band_conditions(band, :day)
      night = N0nbh.band_conditions(band, :night)
      m.reply "#{band}  #{day}  #{night}".gsub('Poor', 'AIDS')
    end
    m.reply "MUF: #{N0nbh['muf']}mhz - Noise: #{N0nbh['signalnoise']} - http://n0nbh.com" 
  end
end

bot.start
