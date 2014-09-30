class Herd.AssetsIndexController extends Ember.ArrayController
  sortProperties: ['position']

  +computed arrangedContent.@each.position #, arrangedContent.@each.parentAsset,
  filteredContent: ->
    @arrangedContent.rejectBy('parentAsset')

  updateSortOrder: (indexes) ->
    @forEach (asset) ->
      asset.position = indexes[asset.id]
    @model.invoke 'save'

  actions:
    destroy: (asset) ->
      asset.destroyRecord()
      @model.removeObject asset if @model.contains asset

    uploadFinished: (resp) ->
      @store.pushPayload resp
      @model.pushObject @store.getById('asset', resp.asset?.id)

    uploadProgressed: (e) ->
      console.log('prog ', e)
