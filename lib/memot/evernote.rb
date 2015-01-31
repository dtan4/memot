require "evernote_oauth"

module Memot
  class EvernoteCli
    def initialize(token, sandbox, logger)
      @token = token
      @client = EvernoteOAuth::Client.new(token: @token, sandbox: sandbox)
      @note_store = @client.note_store
      @logger = logger
    end

    def create_note(title, body, notebook)
      note = Evernote::EDAM::Type::Note.new
      note.title = title.force_encoding("UTF-8")
      note.content = create_note_content(body).force_encoding("UTF-8")
      note.notebookGuid = get_notebook_guid(notebook)
      @note_store.createNote(@token, note)

    rescue Evernote::EDAM::Error::EDAMUserException => e
      show_error_and_exit e
    end

    def update_note(title, body, notebook, note_guid)
      note = @note_store.getNote(@token, note_guid, true, true, true, true)
      note.title = title.force_encoding("UTF-8")
      note.content = create_note_content(body).force_encoding("UTF-8")
      note.notebookGuid = get_notebook_guid(notebook, false)
      @note_store.updateNote(@token, note)

    rescue Evernote::EDAM::Error::EDAMUserException => e
      show_error_and_exit e
    end

    def get_note_guid(title, notebook)
      notebook_guid = get_notebook_guid(notebook, false)
      return "" if notebook_guid == ""

      filter = Evernote::EDAM::NoteStore::NoteFilter.new
      filter.notebookGuid = notebook_guid
      spec = Evernote::EDAM::NoteStore::NotesMetadataResultSpec.new
      spec.includeTitle = true
      results = @note_store.findNotesMetadata(@token, filter, 0, 10000, spec).notes.select { |nt| nt.title == title }
      results.length > 0 ? results.first.guid : ""

    rescue Evernote::EDAM::Error::EDAMSystemException => e
      show_error_and_exit e
    end

    def create_notebook(name, stack = "")
      notebook = Evernote::EDAM::Type::Notebook.new
      notebook.name = name
      notebook.stack = stack unless stack == ""
      @note_store.createNotebook(@token, notebook)

    rescue Evernote::EDAM::Error::EDAMUserException => e
      show_error_and_exit e
    end

    def get_notebook_guid(notebook, create = true)
      results = @note_store.listNotebooks.select { |nb| nb.name == notebook }

      if results.length > 0
        results.first.guid
      else
        create ? create_notebook(notebook).guid : ""
      end
    rescue Evernote::EDAM::Error::EDAMSystemException => e
      show_error_and_exit e
    end

    private

    def create_note_content(body)
      content = <<EOS
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE en-note SYSTEM "http://xml.evernote.com/pub/enml2.dtd">
<en-note>
#{body}
</en-note>
EOS
      content
    end

    def show_error_and_exit(e)
      parameter = e.parameter
      errorText = Evernote::EDAM::Error::EDAMErrorCode::VALUE_MAP[e.errorCode]
      @logger.error "Exception raised (parameter: #{parameter} errorText: #{errorText})"
      exit 1
    end
  end
end
