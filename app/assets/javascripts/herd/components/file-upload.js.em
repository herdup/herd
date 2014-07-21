Herd.FileUploadComponent = Ember.FileField.extend
  multiple: true,
  url: ''

  +observer files
  filesDidChange: ->
    uploader = Ember.Uploader.create
      url: @url
      paramNamespace: 'asset'

    for file in @files
      uploader.upload file, window.assetable

    uploader.on 'progress', (e) =>
      @uploadProgressed(e)

    uploader.on 'didUpload', (e) =>
      @uploadComplete(e)

  uploadComplete: (resp) ->
    @sendAction 'uploaded', resp

  uploadProgressed: (e) ->
    @sendAction 'progress', e
