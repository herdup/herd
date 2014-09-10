mixin Herd.LiveAssets
  init: ->
    @_super()

    if Herd.RAILS_ENV is 'development'
      source = new EventSource '/herd/assets/live'
      source.addEventListener 'assets', (e) =>
        Ember.run =>
          @store.pushPayload JSON.parse(e.data)
