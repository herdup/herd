mixin Herd.LiveAssets
  LIVE_ASSETS: ~> $('meta[name="herd-live-assets"]').attr('content') == 'true'

  init: ->
    @_super()

    if @LIVE_ASSETS
      source = new EventSource '/herd/assets/live'
      source.addEventListener 'assets', (e) =>
        Ember.run.scheduleOnce 'afterRender', @, ->
          @store.pushPayload JSON.parse(e.data)

  actions:
    generateChild: (child, t) ->
      console.log child, t
