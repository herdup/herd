module Herd
  class Transform < ActiveRecord::Base

    attr_accessor :async
    has_many :assets, dependent: :destroy

    # serialize :options, HashWithIndifferentAccess
    # validates_presence_of :name
    validates_uniqueness_of :name, scope: [:type, :assetable_type]


    after_save -> {
      cascade if options_changed?
    }

    def self.options_from_string(string)
      string ||= ''
      YAML::load string.split('|').map(&:strip).join("\n")
    end

    # Query all model instance sthat have a given
    # key/value pair.
    def self.by_hash_key_value(key, value)
      kv = key + "=>" + value
      where("options @> :kv", kv: kv) 
    end

    def self.by_options_hash(hash) 
      scope = self
      hash.each do |k,v|
        scope = scope.by_hash_key_value(k,v)
      end
      scope
    end

    def self.where_t(params)
      clean = params.dup.delete_if {|k,v|v.nil?}

      scope = if clean[:options]
        by_options_hash clean.delete(:options)
      else
        self
      end
      scope.where(clean)
    end

    def self.find_or_create_with_options_string(string,name=nil,assetable_type)
      out = where(name: name, assetable_type: assetable_type).first_or_create
      if out.options != options_from_string(string)
        out.options = options_from_string(string) || {}
        out.save
      end
      out
    end

    def clean_options
      unless options.nil? or options.empty?
        options.map { |k,v| {k => (v =~ /^\d*$/ ? v.to_i : v) } }.reduce(:merge)
      end || {}.with_indifferent_access
    end

    def cascade
      # trigger asset regen if changed
      assets.map do |a|
        a.generate async
      end

      # trigger all assets of all similarly typed (sti) transforms assets
      self.class.unscoped.all.map do |t|
        next if t == self

        t.assets.map do |a|
          a.generate async
        end
      end if default?
    end

    def perform(parent_asset)
      raise 'subclass this'
    end

    def computed_asset(asset_or_id)
      asset_or_id.is_a?(Numeric) ? Asset.find(asset_or_id) : asset_or_id
    end

    def options_with_defaults
      if clean_options and self.class.defaults
        clean_options.reverse_merge self.class.defaults
      else
        clean_options
      end
    end

    def default?
      assetable_type.nil? and name == 'default'
    end

    class << self

      def default_transform
        where(assetable_type:nil, name: 'default').first_or_initialize
      end

      def defaults
        default_transform.try :clean_options
      end

      def defaults=(options)
        trans = default_transform

        if options != trans.options
          trans.options = options
          trans.save!
        end
      end

    end
  end
end
