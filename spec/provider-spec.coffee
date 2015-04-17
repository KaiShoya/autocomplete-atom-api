temp = require 'temp'

describe "Atom API autocompletions", ->
  [editor, provider] = []

  getCompletions = ->
    cursor = editor.getLastCursor()
    start = cursor.getBeginningOfCurrentWordBufferPosition()
    end = cursor.getBufferPosition()
    prefix = editor.getTextInRange([start, end])
    request =
      editor: editor
      bufferPosition: end
      scopeDescriptor: cursor.getScopeDescriptor()
      prefix: prefix
    provider.getSuggestions(request)

  beforeEach ->
    waitsForPromise -> atom.packages.activatePackage('autocomplete-atom-api')
    runs ->
      provider = atom.packages.getActivePackage('autocomplete-atom-api').mainModule.getProvider()
    waitsFor -> Object.keys(provider.completions).length > 0
    waitsFor -> provider.packageDirectories?.length > 0
    waitsForPromise -> atom.workspace.open('test.js')
    runs -> editor = atom.workspace.getActiveTextEditor()

  it "only includes completions in files that are in an Atom package or Atom core", ->
    emptyProjectPath = temp.mkdirSync('atom-project-')
    atom.project.setPaths([emptyProjectPath])

    waitsForPromise -> atom.workspace.open('empty.js')

    runs ->
      expect(provider.packageDirectories.length).toBe 0
      editor = atom.workspace.getActiveTextEditor()
      editor.setText('atom.')
      editor.setCursorBufferPosition([0, Infinity])

      expect(getCompletions().length).toBe 0

  it "includes properties and functions on the atom global", ->
    editor.setText('atom.')
    editor.setCursorBufferPosition([0, Infinity])

    expect(getCompletions().length).toBe 45
    expect(getCompletions()[0].text).toBe 'clipboard'

    editor.setText('var c = atom.')
    editor.setCursorBufferPosition([0, Infinity])

    expect(getCompletions().length).toBe 45
    expect(getCompletions()[0].text).toBe 'clipboard'

    editor.setText('atom.co')
    editor.setCursorBufferPosition([0, Infinity])
    expect(getCompletions().length).toBe 4
    expect(getCompletions()[0].text).toBe 'commands'
    expect(getCompletions()[0].type).toBe 'property'
    expect(getCompletions()[0].leftLabel).toBe 'CommandRegistry'
    expect(getCompletions()[1].text).toBe 'config'
    expect(getCompletions()[2].text).toBe 'contextMenu'
    expect(getCompletions()[3].snippet).toBe 'confirm(${1:options})'
    expect(getCompletions()[3].type).toBe 'method'
    expect(getCompletions()[3].leftLabel).toBe 'Number'

    editor.setText('atom.commands')
    editor.setCursorBufferPosition([0, Infinity])
    expect(getCompletions().length).toBe 1
    expect(getCompletions()[0].text).toBe 'commands'

    editor.setText('atom.Command')
    editor.setCursorBufferPosition([0, Infinity])
    expect(getCompletions().length).toBe 1
    expect(getCompletions()[0].text).toBe 'commands'

    editor.setText('atom.commands ')
    editor.setCursorBufferPosition([0, 13])
    expect(getCompletions().length).toBe 1
    expect(getCompletions()[0].text).toBe 'commands'

  it "includes methods on atom global properties", ->
    editor.setText('atom.clipboard.')
    editor.setCursorBufferPosition([0, Infinity])

    expect(getCompletions().length).toBe 3
    expect(getCompletions()[0].text).toBe 'read()'
    expect(getCompletions()[1].text).toBe 'readWithMetadata()'
    expect(getCompletions()[2].snippet).toBe 'write(${1:text}, ${2:metadata})'

    editor.setText('atom.clipboard.rea')
    editor.setCursorBufferPosition([0, Infinity])

    expect(getCompletions().length).toBe 2
    expect(getCompletions()[0].text).toBe 'read()'
    expect(getCompletions()[1].text).toBe 'readWithMetadata()'
