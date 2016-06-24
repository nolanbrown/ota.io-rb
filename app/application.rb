require 'rubygems'
require 'sinatra'
require 'erb'
require 'json'
require 'data_mapper'
require 'aws/s3'
require 'plist'
require 'set'

include File.join(File.dirname(__FILE__), '..', 'settings' )    

DataMapper.setup(:default, ENV['DATABASE_URL'] || 'postgres://localhost/'+ DATABASE_NAME)

relative_require 'models/app'

DataMapper.auto_upgrade!

class OTA < Sinatra::Application
  include File.join(File.dirname(__FILE__), '..', 'settings' )    

  DataMapper.auto_upgrade!
  set :views, settings.root + '/app/views'  
  set :root, File.join(File.dirname(__FILE__), '..')
  
  API_VERSION = "v1"

  get '/' do
    erb :index
  end
  
  ##
  # GET Request finds App by ID
  #
  # Returns JSON object containing app details
  # 
  get "/#{API_VERSION}/app/:id" do
    app = App.get(params[:id])
    if app
        _success({:id=>app.id, :url=>settings.base_url+"/#{app.id}", :secure_url=>settings.secure_url+"/#{app.id}", :filename=>app.filename, :created_at=>app.created_at},200)
    else
      _error("Id not found", 404) unless app
    end
    
  end
  
  ##
  # DELETE Request finds App by ID
  #
  # Returns No data and 204 status code
  #
  delete "/#{API_VERSION}/app/:id" do
    
    app = App.get(params[:id])
    unless app
       _error("Id not found", 404)
    else
      if app.delete_token
        if app.delete_token == params[:token]          
          app.destroy
          status 204
        else
          _error("Invalid token", 400)
        end
      else
        app.destroy
        status 204
      end
    end      
  end
  
  ##
  # POST Request with App Details
  #
  # Returns JSON object containing app details
  #
  post "/#{API_VERSION}/app/new" do
    
      app_data = nil
      name = nil
      android = false    

      if params['app_data']
          name = params['app_data'][:filename]
          return _error("Invalid file type. Must be an IPA or APK",400) unless Set[File.extname(name)].proper_subset? Set[".ipa",".apk"]
          android = (File.extname(name) == ".apk")
          app_data = params['app_data'][:tempfile].read        
      end

      return _error("No app file provided",400) unless app_data

      identifier = params['identifier']

      app = App.new(:filename=>name, 
                    :identifier=>identifier, 
                    :android=>android,
                    )
      app.app_data = app_data
      app.icon = !params['icon'].nil?
      
      if app.icon
          app.icon_data = params['icon'][:tempfile].read 
      end
      app.delete_token = SecureRandom.uuid
      app.save

      
      if app.saved?
          _success({:id=>app.id, :url=>settings.secure_url+"/#{app.id}", :filename=>app.filename, :token => app.delete_token, :created_at=>app.created_at},201)
      else
          _error("Problem creating app",400)
      end
  end
  
  private

  ##
  # Helper to return errors
  #
  # Sets the status code and response body
  #
  def _error(message,code)    
      status code
      response.headers['Content-Type'] = 'application/json'
      body({:error=>{:message=>message}}.to_json)
  end

  ##
  # Helper to return a succesful response
  #
  # Sets the status code and response body
  #
  def _success(data,code)
      status code
      response.headers['Content-Type'] = 'application/json'
      body(data.to_json)
  end
end
