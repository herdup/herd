Herd.AssetContainerComponent = Ember.Component.extend
  asset: null
  t: null
  transform: null
  child: null

  +computed options
  optionsHash: ->
    return unless @t
    yaml = @t.split('|').join("\n")
    hash = jsyaml.load yaml
    sorted = {}
    for k in Object.keys(hash).sort()
      sorted[k] = hash[k]

    sorted

  +computed options
  sortedOptionsSegment: ->
    yaml = jsyaml.dump @optionsHash
    encodeURIComponent yaml.split("\n").join('|')

  +computed asset, transform, child.url
  assetUrl: ->

    if @child and @child.url
      return @child.url

    else if @t
      #@transform = @asset.store.all('transform').find (item, ix) =>
      #  item.options.match @t

      @child = @asset.t @t
      #childAssets.find (item, ix) =>
      #  item.transform?.options.match @t

      return @assetUrl if @child?.url

      if !@child?.url
        debugger if @transform
        @child = @asset.store.createRecord 'asset',
          parentAsset: @asset
          transform: @transform || @asset.store.createRecord 'transform',
            options: @t
            type: 'Herd::MiniMagick'


        @child.save()
        return "https://d13yacurqjgara.cloudfront.net/users/82092/screenshots/1073359/spinner.gif"
    else
      return @asset.url
