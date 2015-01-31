module Memot
  class Client
    def initialize(dropbox, evernote, logger)
      @dropbox = dropbox
      @evernote = evernote
      @logger = logger
    end

    def update(notes)
      need_update = []

      notes.each_pair do |notebook, dropbox_path|
        need_update << { notebook: notebook, updates: dropbox.parse_dir_tree!(dropbox_path) }
      end

      need_update.each do |update|
        notebook = update[:notebook]
        update[:updates].each { |u| save_to_evernote(u[:dropbox_path], notebook, u[:revision]) }
      end
    end

    def save_to_evernote(dropbox_path, notebook, revision)
      note_body = Memot::Markdown.parse_markdown(dropbox.file_body_of(dropbox_path))
      note_title = File.basename(dropbox_path)

      if (note_guid = evernote.get_note_guid(note_title, notebook)) == ""
        evernote.create_note(note_title, note_body, notebook)
        logger.info "Created: #{notebook}/#{note_title} (rev. #{revision})"
      else
        evernote.update_note(note_title, note_body, notebook, note_guid)
        logger.info "Updated: #{notebook}/#{note_title} (rev. #{revision})"
      end
    end

    private

    def dropbox
      @dropbox
    end

    def evernote
      @evernote
    end

    def logger
      @logger
    end
  end
end