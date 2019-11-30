class Cargo
  attr_reader :name, :destination

  def initialize(name:, destination:)
    @name = name
    @destination = destination
  end
end
