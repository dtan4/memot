require "dropbox_sdk"
require "yaml"
require "memot/evernote"

module Memot
  class Dropbox
    CONF_PATH = ENV["HOME"] + "/.memot.yml"

    def initialize(root, access_token, evernote)
      @client = DropboxClient.new(access_token)
      @root = root
      @evernote = evernote
    end

    def parse_dir_tree(path, recursive)
      latest_revision = @config["revision"]
      @client.metadata(path)["contents"].each do |cont|
        cont_path = cont["path"]

        if cont["is_dir"]
          if recursive
            child_rev = parse_dir_tree(cont_path, recursive)
            latest_revision = child_rev if child_rev > latest_revision
          end
        else
          if cont["revision"] > @config["revision"]
            # save_to_evernote(path) if path =~ /\.(?:md|markdown)$/
            puts path if path =~ /\.(?:md|markdown)$/
            latest_revision = cont["revision"] if cont["revision"] > latest_revision
          end
        end
      end

      latest_revision
    end

    def save_to_evernote(path)
      body = get_file_body(path)
      title = File.basename(path)
      notebook = Fild.dirname(path).sub(/^#{root}\//, "")

      if (note_guid = @evernote.get_note_guid(title, notebook)) == ""
        @evernote.create_note(title, body, notebook)
      else
        @evernote.update_note(title, body, notebook, note_guid)
      end
    end

    def get_file_body(path)
      @client.get_file(path)
    end

    def save_file(path, filepath)
      body = get_file_body(path)
      open(filepath, "w+") { |f| f.puts body } unless filepath == ""
    end

    def auth
      flow = DropboxOAuth2FlowNoRedirect.new(DROPBOX_APP_KEY, DROPBOX_APP_SECRET)
      puts "Access to this URL: #{flow.start}"
      code = gets.strip
      access_token, user_id = flow.finish(code)
      @config = {
        auth: {
          access_token: access_token,
          user_id: user_id
        },
        revision: 0
      }
      open(MEMO2GIT_CONF, "w+") { |f| f.write @config.to_yaml }
      puts "Save authorization data to #{MEMO2GIT_CONF}"
      @config[:auth]
    end

    def refresh_revision(revision)
      @config["revision"] = revision
      open(MEMO2GIT_CONF, "w+") { |f| f.write @config.to_yaml }
      puts "latest revision is #{@config["revision"]}"
    end
  end
end
