class Herd.AssetsUploadView extends Ember.View
  templateName: 'assets/upload'
  progressStyle: 'width: 0%'

  actions:
    uploadProgressed: (e) ->
      @progressStyle = "width: #{e.percent}%"
