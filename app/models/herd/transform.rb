module Herd
  class Transform < ActiveRecord::Base

    attr_accessor :async
    has_many :assets, dependent: :destroy

    serialize :options, HashWithIndifferentAccess
    # validates_presence_of :name
    validates_uniqueness_of :name, scope: [:type, :assetable_type, :options]

    before_validation -> {
      self.options = YAML::load(options) if options.kind_of? String
      self.options = options.with_indifferent_access unless options.kind_of? HashWithIndifferentAccess
    }

    before_save -> {
      self.options ||= self.class.defaults
    }

    after_save -> {
      assets.map do |a|
        a.generate async
      end if options_changed?

      self.class.all.map do |t|
        next if t == self
        t.assets.map do |a|
          a.generate async
        end
      end if default? #and options_changed?
    }

    after_create -> {
      TransformExportWorker.perform_async
    }
    after_destroy -> {
      TransformExportWorker.perform_async
    }

    def self.options_from_string(string)
      yaml = string.split('|').map(&:strip).join("\n")
      hash = YAML::load(yaml).with_indifferent_access
    end

    def self.where_t(params)
      params[:options] = options_from_string(params[:options]).to_yaml if params[:options]
      params.delete_if {|k,v|v.nil?}
      where(params)
    end

    def self.find_or_create_with_options_string(string,name=nil,assetable_type)
      params = {
        options:string,
        name: name,
        assetable_type: assetable_type
      }
      where_t(params).first_or_create
    end

    def perform(parent_asset, options)
      raise 'subclass this'
    end

    def computed_asset(asset_or_id)
      asset_or_id.is_a?(Numeric) ? Asset.find(asset_or_id) : asset_or_id
    end

    def options_with_defaults
      options.reverse_merge! self.class.defaults || {}
    end

    def default?
      assetable_type.nil? and name == 'default'
    end

    class << self

      def default_transform
        where(assetable_type:nil, name: 'default').first_or_initialize
      end

      def defaults
        default_transform.try :options
      end

      def defaults=(options)
        trans = default_transform
        trans.async = true

        if options != trans.options
          trans.options = options
          trans.save!
        end
      end

    end
  end
end
