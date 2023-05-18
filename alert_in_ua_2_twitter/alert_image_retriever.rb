require 'open-uri'
require 'tempfile'
require 'uri'

class AlertInUa2Twitter::AlertImageRetriever
  URL = "https://alerts-screenshot.vercel.app/api/capture?width=1600&height=900&delay=5000&url=https://alerts.in.ua/?minimal&disableInteractiveMap"
  RETRY_COUNT = 2

  def get
    retries = 0
    begin
      temp_file = Tempfile.new(['image', '.png'])
      temp_file.binmode
      temp_file.write URI.open(URL).read
      temp_file.rewind
      puts "Image saved to #{temp_file.path}"
      temp_file.path
    rescue Exception => e
      retries += 1
      if retries <= RETRY_COUNT
        puts "An error occurred while fetching the image: #{e.message}, retrying... #{retries}}"
        retry
      else
        puts "An error occurred while fetching the image: #{e.message}"
        nil
      end
    ensure
      temp_file.close unless temp_file.nil?
    end
  end
end
