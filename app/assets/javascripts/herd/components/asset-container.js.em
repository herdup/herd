Herd.AssetContainerComponent = Ember.Component.extend
  classNames: ['asset-container']
  bgImage: true
  asset: null
  child: null
  transform: null
  t: null



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

    else if @asset and @t

      @child = @asset.t @t
      return @assetUrl if @child?.url

      if !@child?.url
        debugger if @transform
        @child = @asset.store.createRecord 'asset',
          parentAsset: @asset
          transform: @transform || @asset.store.createRecord 'transform',
            options: @t
            type: 'Herd::MiniMagick'

        @child.save()

      "https://d13yacurqjgara.cloudfront.net/users/82092/screenshots/1073359/spinner.gif"
    else if @asset
      @asset.url
    else
      "http://www.york.ac.uk/media/environment/images/staff/NoImageAvailableFemale.jpg"

  actions:
    metaUpdate: ->
      @asset.save()
