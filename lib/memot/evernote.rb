require "evernote_oauth"

module Memot
  class EvernoteCli
    def initialize(token, sandbox)
      @token = token
      @client = EvernoteOAuth::Client.new(token: @token, sandbox: sandbox)
      @note_store = @client.note_store
    end

    def create_note(title, body, notebook)
      note = Evernote::EDAM::Type::Note.new
      note.title = title
      note.content = create_note_content(body)
      note.notebookGuid = get_notebook_guid(notebook)

      begin
        @note_store.createNote(@token, note)
      rescue Evernote::EDAM::Error::EDAMUserException => e
        parameter = e.parameter
        errorText = Evernote::EDAM::Error::EDAMErrorCode::VALUE_MAP[e.errorCode]
        $stderr.puts "Exception raised (parameter: #{parameter} errorText: #{errorText})"
        exit 1
      end
    end

    def update_note(title, body, notebook, note_guid)
      note = @note_store.getNote(@token, note_guid)
      note.title = title
      note.content = create_note_content(body)
      note.notebookGuid = get_notebook_guid(notebook, false)

      begin
        @note_store.updateNote(@token, note)
      rescue Evernote::EDAM::Error::EDAMUserException => e
        parameter = e.parameter
        errorText = Evernote::EDAM::Error::EDAMErrorCode::VALUE_MAP[e.errorCode]
        $stderr.puts "Exception raised (parameter: #{parameter} errorText: #{errorText})"
        exit 1
      end
    end

    def get_note_guid(title, notebook)
      notebook_guid = get_notebook_guid(notebook, false)
      return "" if notebook_guid == ""

      filter = Evernote::EDAM::Type::NoteFilter.new
      filter.notebookGuid = notebook_guid
      results = @note_store.findNotesMetadata(@token, filter).select { |nt| nt.title == title }
      results.length > 0 ? results.first.guid : ""
    end

    def create_notebook(name, stack = "")
      notebook = Evernote::EDAM::Type::Notebook.new
      notebook.name = name
      notebook.stack = stack unless stack == ""

      begin
        @note_store.createNotebook(@token, notebook)
      rescue Evernote::EDAM::Error::EDAMUserException => e
        parameter = e.parameter
        errorText = Evernote::EDAM::Error::EDAMErrorCode::VALUE_MAP[e.errorCode]
        $stderr.puts "Exception raised (parameter: #{parameter} errorText: #{errorText})"
        exit 1
      end
    end

    def get_notebook_guid(notebook, create = true)
      results = @note_store.listNotebooks.select { |nb| nb.name == notebook }

      if results.length > 0
        results.first.guid
      else
        create ? create_notebook(notebook).guid : ""
      end
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
  end
end
