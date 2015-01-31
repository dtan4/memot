require "dropbox_sdk"

module Memot
  class Dropbox
    class << self
      def auth(app_key, app_secret)
        flow = DropboxOAuth2FlowNoRedirect.new(app_key, app_secret)
        puts "Access to this URL: #{flow.start}"
        print "PIN code: "
        code = gets.strip
        flow.finish(code)
      end
    end

    def initialize(access_token, redis)
      @client = DropboxClient.new(access_token)
      @redis = redis
    end

    def parse_dir_tree!(path)
      latest_revision = get_revision(path)
      updated_revision = latest_revision

      need_update = []

      client.metadata(path)["contents"].each do |cont|
        cont_path = cont["path"]
        cont_revision = cont["revision"]

        unless cont["is_dir"]
          if (cont_revision > latest_revision) && markdown?(cont_path)
            need_update << { dropbox_path: cont_path, revision: cont_revision }
            updated_revision = cont_revision if cont_revision > updated_revision
          end
        end
      end

      set_revision(path, updated_revision) if updated_revision > latest_revision

      need_update
    end

    def file_body_of(path)
      client.get_file(path)
    end

    private

    def client
      @client
    end

    def redis
      @redis
    end

    def markdown?(path)
      %w{.md .markdown}.include?(File.extname(path).downcase)
    end

    def dir_key_of(dir)
      "memot:#{dir}"
    end

    def get_revision(dir)
      key = dir_key_of(dir)

      if redis.exists(key)
        redis.get(key).to_i
      else
        set_revision(key, 0)
        0
      end
    end

    def set_revision(dir, revision)
      key = dir_key_of(dir)
      redis.set(key, revision)
    end
  end
end
