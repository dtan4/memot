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
      latest_revision = get_latest_revision(path)

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

    def revision_path(dir)
      dir[-1] == "/" ? dir + ".memot.revision" : "/.memot.revision"
    end

    def get_latest_revision(dir)
      File.exists?(revision_path(dir)) ? open(revision_path).to_i : 0
    end

    def set_latest_revision(dir, revision)
      open(revision_path(dir), "w+") { |f| f.puts revision }
    end

    def get_file_body(path)
      @client.get_file(path)
    rescue DropboxError => e
      $stderr.puts e.message
      exit 1
    end

    def save_file(path, filepath)
      body = get_file_body(path)
      open(filepath, "w+") { |f| f.puts body } unless filepath == ""
    end

    def self.auth(app_key, app_secret)
      flow = DropboxOAuth2FlowNoRedirect.new(app_key, app_seccret)
      puts "Access to this URL: #{flow.start}"
      print "PIN code: "
      code = gets.strip
      access_token, user_id = flow.finish(code)
      access_token, user_id
    end
  end
end
