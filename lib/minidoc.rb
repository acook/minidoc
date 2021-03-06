require "mongo"
require "virtus"
require "active_model"
require "active_support/core_ext"

class Minidoc
  VERSION = "0.0.1"

  require "minidoc/associations"
  require "minidoc/connection"
  require "minidoc/finders"
  require "minidoc/grid"
  require "minidoc/indexes"
  require "minidoc/read_only"
  require "minidoc/record_invalid"
  require "minidoc/timestamps"
  require "minidoc/value"

  include Connection
  include Finders
  include Virtus.model
  extend ActiveModel::Naming
  include ActiveModel::Conversion
  include ActiveModel::Validations

  attribute :_id, BSON::ObjectId
  alias_attribute :id, :_id

  def self.delete_all
    collection.remove({})
  end

  def self.create(attrs = {})
    new(attrs).tap(&:save)
  end

  def self.create!(*args)
    new(*args).tap(&:save!)
  end

  def self.delete(id)
    collection.remove(_id: BSON::ObjectId(id.to_s))
  end

  def self.set(id, attributes)
    id = BSON::ObjectId(id.to_s)
    update_one(id, "$set" => attributes)
  end

  def self.unset(id, *keys)
    id = BSON::ObjectId(id.to_s)

    unsets = {}
    keys.each do |key|
      unsets[key] = 1
    end

    update_one(id, "$unset" => unsets)
  end

  def self.update_one(id, updates)
    collection.update({ "_id" => id }, updates)
  end

  def self.value_class
    @value_class ||= Class.new(self) do
      attribute_set.each do |attr|
        private "#{attr.name}="
      end

      private :attributes=
    end
  end

  def initialize(attrs = {})
    if attrs["_id"].nil? && attrs[:_id].nil?
      attrs[:_id] = BSON::ObjectId.new
    end

    @new_record = true
    @destroyed = false

    super(attrs)
  end

  def ==(other)
    other.is_a?(self.class) && self.id && self.id == other.id
  end

  def new_record?
    @new_record
  end

  def destroyed?
    @destroyed
  end

  def persisted?
    !(new_record? || destroyed?)
  end

  def delete
    self.class.delete(id)
  end

  def destroy
    delete
    @destroyed = true
  end

  def reload
    new_object = self.class.find(self.id)

    self.class.attribute_set.each do |attr|
      self[attr.name] = new_object[attr.name]
    end

    self
  end

  def save
    valid? ? create_or_update : false
  end

  def save!
    valid? ? create_or_update : raise(RecordInvalid.new(self))
  end

  def set(attributes)
    self.class.set(id, attributes)

    attributes.each do |name, value|
      self[name] = value
    end
  end

  def unset(*keys)
    self.class.unset(id, *keys)

    keys.each do |key|
      self[key] = nil
    end
  end

  def update(updates)
    self.class.update_one(id, updates)
  end

  def as_value
    self.class.value_class.new(attributes)
  end

  def to_key
    [id.to_s]
  end

  def to_param
    id.to_s
  end

private

  def create_or_update
    new_record? ? create : update
    @new_record = false
    true
  end

  def create
    self.class.collection << attributes
  end

  def update
    self.class.collection.update({ _id: id }, attributes)
  end
end
