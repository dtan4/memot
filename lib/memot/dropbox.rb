require "dropbox_sdk"
require "memot/evernote"
require "memot/markdown"

module Memot
  class DropboxCli
    def initialize(access_token, evernote, redis, logger)
      @client = DropboxClient.new(access_token)
      @evernote = evernote
      @redis = redis
      @logger = logger
    end

    def parse_dir_tree!(path, notebook, recursive = false)
      latest_revision = get_revision(path)
      updated_revision = latest_revision

      @client.metadata(path)["contents"].each do |cont|
        cont_path = cont["path"]

        if cont["is_dir"]
          # if recursive
          #   child_rev = parse_dir_tree!(cont_path, recursive)
          #   latest_revision = child_rev if child_rev > latest_revision
          # end
        else
          if (cont["revision"] > latest_revision) &&
              (%w{.md .markdown}.include? File.extname(cont_path).downcase)
            save_to_evernote(cont_path, notebook, cont["revision"])
            updated_revision = cont["revision"] if cont["revision"] > updated_revision
          end
        end
      end

      set_revision(path, updated_revision) if updated_revision > latest_revision
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

    def save_to_evernote(path, notebook, revision)
      body = Memot::Markdown.parse_markdown(file_body_of(path))
      title = File.basename(path)

      if (note_guid = @evernote.get_note_guid(title, notebook)) == ""
        @evernote.create_note(title, body, notebook)
        @logger.info "Created: #{notebook}/#{title} (rev. #{revision})"
      else
        @evernote.update_note(title, body, notebook, note_guid)
        @logger.info "Updated: #{notebook}/#{title} (rev. #{revision})"
      end
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

    def file_body_of(path)
      @client.get_file(path)
    rescue DropboxError => e
      $stderr.puts e.message
      exit 1
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
