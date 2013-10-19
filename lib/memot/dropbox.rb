require "dropbox_sdk"
require "memot/evernote"
require "memot/markdown"

module Memot
  class Dropbox
    def initialize(access_token, evernote)
      @client = DropboxClient.new(access_token)
      @evernote = evernote
    end

    def parse_dir_tree(path, notebook, recursive)
      latest_revision = get_latest_revision(path)
      refreshed_latest_revision = latest_revision

      @client.metadata(path)["contents"].each do |cont|
        cont_path = cont["path"]

        if cont["is_dir"]
          # if recursive
          #   child_rev = parse_dir_tree(cont_path, recursive)
          #   latest_revision = child_rev if child_rev > latest_revision
          # end
        else
          if cont["revision"] > refreshed_latest_revision
            save_to_evernote(path, notebook) if %w{.md .markdown}.include? File.extname(path).downcase
            latest_revision = cont["revision"] if cont["revision"] > latest_revision
          end
        end
      end

      set_latest_revision(path, refreshed_latest_revision)
    end

    private

    def save_to_evernote(path, notebook)
      body = Memot::Markdown.parse_markdown(get_file_body(path))
      title = File.basename(path)

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
    end
  end
end
