class MultiSerializer < ActiveModel::Serializer

  def initialize(resources, *args)
    self.class._attributes_data.keys.each do |resource_name|
      self.class.remove_possible_method(resource_name)
    end
    self.class._attributes_data = {}
    resources.each do |name, resource|
      self.class.send(:define_method, name) { ActiveModelSerializers::SerializableResource.new(resource, args) }
      self.class.attribute(name)
    end
    super
  end

end
