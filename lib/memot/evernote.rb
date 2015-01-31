require "evernote_oauth"

module Memot
  class EvernoteError < StandardError; end
  class EvernoteRateLimitReachedError < StandardError; end

  class Evernote
    def initialize(token, sandbox)
      @token = token
      @client = EvernoteOAuth::Client.new(token: token, sandbox: sandbox)
    end

    def create_note(title, body, notebook)
      note = ::Evernote::EDAM::Type::Note.new
      note.title = title.force_encoding("UTF-8")
      note.content = create_note_content(body).force_encoding("UTF-8")
      note.notebookGuid = get_notebook_guid(notebook)
      note_store.createNote(token, note)

    rescue ::Evernote::EDAM::Error::EDAMUserException, ::Evernote::EDAM::Error::EDAMSystemException => e
      raise_error e
    end

    def update_note(title, body, notebook, note_guid)
      note = note_store.getNote(token, note_guid, true, true, true, true)
      note.title = title.force_encoding("UTF-8")
      note.content = create_note_content(body).force_encoding("UTF-8")
      note.notebookGuid = get_notebook_guid(notebook, false)
      note_store.updateNote(token, note)

    rescue ::Evernote::EDAM::Error::EDAMUserException, ::Evernote::EDAM::Error::EDAMSystemException => e
      raise_error e
    end

    def get_note_guid(title, notebook)
      notebook_guid = get_notebook_guid(notebook, false)
      return "" if notebook_guid == ""

      filter = ::Evernote::EDAM::NoteStore::NoteFilter.new
      filter.notebookGuid = notebook_guid
      spec = ::Evernote::EDAM::NoteStore::NotesMetadataResultSpec.new
      spec.includeTitle = true
      results = note_store.findNotesMetadata(token, filter, 0, 10000, spec).notes.select { |nt| nt.title == title }
      results.length > 0 ? results.first.guid : ""

    rescue ::Evernote::EDAM::Error::EDAMSystemException => e
      raise_error e
    end

    def create_notebook(name, stack = "")
      notebook = ::Evernote::EDAM::Type::Notebook.new
      notebook.name = name
      notebook.stack = stack unless stack == ""
      note_store.createNotebook(token, notebook)

    rescue ::Evernote::EDAM::Error::EDAMUserException, ::Evernote::EDAM::Error::EDAMSystemException => e
      raise_error e
    end

    def get_notebook_guid(notebook, create = true)
      results = note_store.listNotebooks.select { |nb| nb.name == notebook }

      if results.length > 0
        results.first.guid
      else
        create ? create_notebook(notebook).guid : ""
      end
    rescue ::Evernote::EDAM::Error::EDAMSystemException => e
      raise_error e
    end

    private

    def client
      @client
    end

    def note_store
      @note_store ||= client.note_store
    end

    def token
      @token
    end

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

    def raise_error(e)
      raise EvernoteRateLimitReachedError, e.rateLimitDuration if e.errorCode == ::Evernote::EDAM::Error::EDAMErrorCode::RATE_LIMIT_REACHED

      error_text = ::Evernote::EDAM::Error::EDAMErrorCode::VALUE_MAP[e.errorCode]
      raise EvernoteError, "Exception raised (errorText: #{error_text})"
    end
  end
end
