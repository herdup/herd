mixin Herd.LiveAssets
  init: ->
    @_super()

    if Herd.LIVE_ASSETS
      source = new EventSource '/herd/assets/live'
      source.addEventListener 'assets', (e) =>
        Ember.run =>
          @store.pushPayload JSON.parse(e.data)

  actions:
    generateChild: (child, t) ->
      console.log child, t
