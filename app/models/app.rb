class App
    include DataMapper::Resource
    include File.join(File.dirname(__FILE__), '..', 'settings' )    
    
    property :id, String, :required => true, :key=>true
    property :filename, String, :required => true
    property :identifier, String
    property :installs, Integer
    property :icon, Boolean
    property :android, Boolean
    property :delete_token, String
    
    property :created_at, DateTime
    property :updated_at, DateTime
    
    attr_accessor :icon_data, :app_data
    
    def initialize(params={})
       super(params)
       self.id = _generate_hash_id
       self.installs = 0
       self.created_at = Time.now 
       self.updated_at = Time.now
     end
    
    def install_url
        return self.app_url if self.android
        "itms-services://?action=download-manifest&url=#{self.manifest_url}"
    end
    
    def install_track_url
        return BASE_URL+"/r/"+self.id
    end
    
    def manifest_url
        return BASE_URL+"/"+self.id+"/manifest"
    end
    
    def icon_url
        return ASSET_URL+"/app/#{self.id}/icon.png" if self.icon
        return ASSET_URL+"/img/default_app.png"
    end
    
    def app_url
        return ASSET_URL+"/app/#{self.id}/#{CGI.escape(self.filename)}"
    end
    
    def name
        File.basename(self.filename, '.*') 
    end
    
    def destroy
      _delete_from_s3(self.id,self.filename)
      super
    end
    def save
      result = super
      if result
        _upload_to_s3(self.app_data, self.id, self.filename, false) if self.app_data # app
        _upload_to_s3(self.icon_data, self.id, nil, true) if self.icon_data # icon
      end
      return result
    end
    
    private
    def _upload_to_s3(app_data,key,filename, icon=false)

    	AWS::S3::Base.establish_connection!(
  	    :access_key_id => S3_KEY,
  	    :secret_access_key => S3_SECRET
    	)
        ipa_path = icon ? "app/#{key}/icon.png" : "app/#{key}/#{filename}"

        AWS::S3::S3Object.store(ipa_path, app_data, S3_BUCKET, :access => :public_read)
    end

    def _delete_from_s3(key, filename)

    	AWS::S3::Base.establish_connection!(
    	    :access_key_id => S3_KEY,
    	    :secret_access_key => S3_SECRET
    	)      
        AWS::S3::S3Object.delete("app/#{key}/icon.png", S3_BUCKET)
        AWS::S3::S3Object.delete("app/#{key}/#{filename}", S3_BUCKET)
        AWS::S3::S3Object.delete("app/#{key}", S3_BUCKET)
        
    end

    def _generate_hash_id
        # based on http://erickel.ly/sinatra-url-shortener

        # Create an Array of possible characters
        #chars = ('a'..'z').to_a + ('A'..'Z').to_a + ('0'..'9').to_a
        chars = ('a'..'z').to_a + ('a'..'z').to_a + ('a'..'z').to_a
        len = chars.length
        # Create a random 3 character string from our possible
        # set of choices defined above.
        tmp = chars[rand(len)]
        LENGTH_OF_HASH.times do
            tmp += chars[rand(len)]
        end

        # Until retreiving a Link with this short_url returns
        # false, generate a new short_url and try again.
        until App.get(tmp).nil?
            tmp = chars[rand(len)]
            LENGTH_OF_HASH.times do
                tmp += chars[rand(len)]
            end
        end

        # Return our new unique short_url
        tmp 
    end
end