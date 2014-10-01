#= require ./core
#= require_self
#= require_tree ./mixins
#= require_tree ./initializers
#= require_tree ./models
#= require_tree ./views
#= require_tree ./components
#= require_tree ./templates
#= require_tree ./singletons


window.Herd = Ember.Namespace.create
  VERSION: '1.0.0'

# Override the default adapter with the `DS.ActiveModelAdapter` which
# is built to work nicely with the ActiveModel::Serializers gem.
class Herd.ApplicationAdapter extends DS.ActiveModelAdapter
  namespace: 'herd'
  headers:
    'X-CSRF-Token': $('meta[name="csrf-token"]').attr('content')
