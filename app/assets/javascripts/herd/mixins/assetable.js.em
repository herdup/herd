mixin Herd.Assetable
  assets: DS.hasMany 'asset'

  +computed assets.@each
  masterAssets: ->
    @assets.filterBy('parentAsset', null) || []
