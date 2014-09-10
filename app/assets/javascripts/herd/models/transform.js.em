class Herd.Transform extends DS.Model
  name: DS.attr 'string'
  createdAt: DS.attr 'date'
  type: DS.attr 'string'
  assetableType: DS.attr 'string'

  options: DS.attr 'string'
  assets: DS.hasMany 'asset'

  +computed options
  cleanOptions: ->
    return @options if !@options
    clean = @options.split("\n")
    clean.shift()
    clean.join("\n")
