class Map
  def initialize(locations:, roads:, itineraries:)
    @locations = locations
    @roads = roads
    @itineraries = itineraries
  end

  def can_move?(carrier:, from:, to:)
    _next_location, next_road = @itineraries[[from, to]]
    !!next_road&.accepts?(carrier: carrier)
  end

  def guidance(carrier:, from:, to:)
    @itineraries.fetch([from, to])
  end
end
