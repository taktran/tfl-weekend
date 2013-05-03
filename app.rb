# encoding utf-8

require 'sinatra'
require 'sinatra/flash'
require 'sass'
require 'haml'
require 'open-uri'
require 'nokogiri'

# Require all in lib directory
Dir[File.dirname(__FILE__) + '/lib/*.rb'].each {|file| require file }

class App < Sinatra::Application

  # Load config.yml into settings.config variable
  set :config, YAML.load_file("#{root}/config/config.yml")[settings.environment.to_s]

  set :environment, ENV["RACK_ENV"] || "development"
  set :haml, { :format => :html5 }

  ######################################################################
  # Configurations for different environments
  ######################################################################

  configure :staging do
    enable :logging
  end

  configure :development do
    enable :logging
  end

  ######################################################################

end

helpers do
  include Rack::Utils
  alias_method :h, :escape_html

  # More methods in /helpers/*
end

require_relative 'models/init'
require_relative 'helpers/init'

########################################################################
# Routes/Controllers
########################################################################

def protect_with_http_auth!
  protected!(settings.config["http_auth_username"], settings.config["http_auth_password"])
end

# ----------------------------------------------------------------------
# Main
# ----------------------------------------------------------------------

get '/css/style.css' do
  content_type 'text/css', :charset => 'utf-8'
  scss :'sass/style'
end

get '/' do
  @page_name = "home"

  tfl_weekend_data_url = "http://www.tfl.gov.uk/tfl/businessandpartners/syndication/feed.aspx?email=contact@tutaktran.com&feedId=1"

  # Get tfl data
  xml = Nokogiri::XML(open(tfl_weekend_data_url))

  @lines = []
  xml.xpath("//Lines/Line").each do |line|
    name = line.xpath("Name/text()")
    colour = line.xpath("Colour/text()")
    bgColour = line.xpath("BgColour/text()")

    status = line.xpath("Status/Message/Text/text()")
    status_colour = line.xpath("Status/Message/Colour/text()")
    status_bg_colour = line.xpath("Status/Message/BgColour/text()")

    @lines.push({
      :name => name.to_s,
      :colour => colour.to_s,
      :bg_colour => bgColour.to_s,
      :status => status.to_s,
      :status_colour => status_colour.to_s,
      :status_bg_colour => status_bg_colour.to_s
    })
  end

  haml :index, :layout => :'layouts/application'
end


# -----------------------------------------------------------------------
# Error handling
# -----------------------------------------------------------------------

not_found do
  logger.info "not_found: #{request.request_method} #{request.url}"
end

# All errors
error do
  @page_name = "error"
  @is_error = true
  haml :error, :layout => :'layouts/application'
end
