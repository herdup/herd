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

    def self.where_t(params)
      params.delete_if {|k,v|v.nil?}
      
      where(params)
    end

    def self.find_or_create_with_options_string(string,name=nil,assetable_type)
      where(name: name, assetable_type: assetable_type).first_or_create do |out|
        out.options = options_from_string(string) || {}
      end
    end
    # def options=(opt)
    #   super.options=(opt)attributes[:options] = opt.with_indifferent_access 
    # end

    def options
      opt = (read_attribute(:options) || {}).map { |k,v| {k => (v =~ /^\d*$/ ? v.to_i : v) } }.reduce(:merge)
      (opt || {}).with_indifferent_access
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

    def perform(parent_asset, options)
      raise 'subclass this'
    end

    def computed_asset(asset_or_id)
      asset_or_id.is_a?(Numeric) ? Asset.find(asset_or_id) : asset_or_id
    end

    def options_with_defaults
      options.reverse_merge self.class.defaults || {}
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

        if options != trans.options
          trans.options = options
          trans.save!
        end
      end

    end
  end
end
