
# Length of generated ID for short urls
# ex. http://ota.io/abcde
# abcde is 5 characters long
LENGTH_OF_HASH = 5

configure :production do
  S3_KEY     = '<YOUR KEY>'
  S3_SECRET = '<YOUR SECRET>'
  S3_BUCKET = '<YOUR BUCKET>'
  S3_URL = "http://s3.amazonaws.com/#{BUCKET}"
  ASSET_URL = S3_URL
  
  DATABASE_NAME = "production_db_name"
  BASE_URL = 'http://yourdomain.com'
end

configure :development do
  S3_KEY     = '<YOUR KEY>'
  S3_SECRET = '<YOUR SECRET>'
  S3_BUCKET = '<YOUR BUCKET>'
  S3_URL = "http://s3.amazonaws.com/#{BUCKET}"
  ASSET_URL = S3_URL
  
  DATABASE_NAME = "ota_io"
  BASE_URL = 'http://yourdomain.com'
end