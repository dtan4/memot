module Memot
  class Config
    class << self
      def load_yaml(yaml_path)
        yaml = symbolize_keys(YAML.load_file(yaml_path))
        auth = yaml[:auth] || {}
        notes = yaml[:notes] || {}

        self.new(auth, notes)
      end

      def load_env
        auth = {
          dropbox: {
            app_key: ENV["MEMOT_DROPBOX_APP_KEY"],
            app_secret: ENV["MEMOT_DROPBOX_APP_SECRET"],
            access_token: ENV["MEMOT_DROPBOX_ACCESS_TOKEN"],
          },
          evernote: {
            token: ENV["MEMOT_EVERNOTE_TOKEN"],
            sandbox: ENV["MEMOT_EVERNOTE_SANDBOX"],
          },
        }

        if ENV["MEMOT_NOTES"]
          #
          # daily:/memo/daily,reading:/memo/reading
          #   -> { daily: "/memo/daily", reading: "/memo/reading" }
          #
          notes = ENV["MEMOT_NOTES"].split(",").map { |pair| pair.split(":") }.inject({}) do |nts, kv|
            nts[kv[0]] = kv[1]
            nts
          end
        else
          notes = {}
        end

        self.new(auth, notes)
      end

      private

      def symbolize_keys(hash)
        result = {}

        hash.each_pair do |key, value|
          result[key.to_sym] = if value.is_a? Array
                                 value.each { |element| symbolize_keys(element) }
                               elsif value.is_a? Hash
                                 symbolize_keys(value)
                               else
                                 value
                               end
        end

        result
      end
    end

    def initialize(auth, notes)
      @auth = auth
      @notes = notes
    end

    def auth
      @auth
    end

    def notes
      @notes
    end
  end
end
