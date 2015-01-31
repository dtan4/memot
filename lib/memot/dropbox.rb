require "dropbox_sdk"

module Memot
  class DropboxCli
    def initialize(access_token, redis, logger)
      @client = DropboxClient.new(access_token)
      @redis = redis
      @logger = logger
    end

    def parse_dir_tree!(path, notebook)
      latest_revision = get_revision(path)
      updated_revision = latest_revision

      need_update = []

      @client.metadata(path)["contents"].each do |cont|
        cont_path = cont["path"]

        unless cont["is_dir"]
          if (cont["revision"] > latest_revision) &&
              (%w{.md .markdown}.include? File.extname(cont_path).downcase)
            need_update << { dropbox_path: cont_path, notebook: notebook, revision: cont["revision"] }
            updated_revision = cont["revision"] if cont["revision"] > updated_revision
          end
        end
      end

      set_revision(path, updated_revision) if updated_revision > latest_revision

      need_update
    end

    def file_body_of(path)
      @client.get_file(path)
    rescue DropboxError => e
      @logger.error e.message
      exit 1
    end

    def self.auth(app_key, app_secret)
      flow = DropboxOAuth2FlowNoRedirect.new(app_key, app_secret)
      puts "Access to this URL: #{flow.start}"
      print "PIN code: "
      code = gets.strip
      flow.finish(code)
    end

    private

    def dir_key_of(dir)
      "memot:#{dir}"
    end

    def get_revision(dir)
      key = dir_key_of(dir)

      if @redis.exists(key)
        @redis.get(key).to_i
      else
        set_revision(key, 0)
        0
      end
    end

    def set_revision(dir, revision)
      key = dir_key_of(dir)
      @redis.set(key, revision)
    end

    def file_exists?(dir, name)
      @client.search(dir, name).length > 0
    end

    def save_file(path, filepath)
      body = file_body_of(path)
      open(filepath, "w+") { |f| f.puts body } unless filepath == ""
    end
  end
end
