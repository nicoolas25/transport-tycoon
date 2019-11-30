require "json"

class Event
  def initialize(name:, carrier_state:, **overrides)
    @name = name
    @carrier_state = carrier_state
    @overrides = overrides
  end

  def to_json
    # {
    #   "event": "DEPART",     # type of log entry: DEPART of ARRIVE
    #   "time": 0,             # time in hours
    #   "duration": 1          # time in hours
    #   "transport_id": 0,     # unique transport id
    #   "kind": "TRUCK",       # transport kind
    #   "location": "FACTORY", # current location
    #   "destination": "PORT", # destination (only for DEPART events)
    #   "cargo": [             # array of cargo being carried
    #     {
    #       "cargo_id": 0,     # unique cargo id
    #       "destination": "A",# where should the cargo be delivered
    #       "origin": "FACTORY"# where it is originally from
    #     }
    #   ]
    # }
    result = to_hash
    cargos = result.delete(:cargos)
    carrier = result.delete(:carrier)
    result[:transport_id] = carrier.name
    result[:kind] = carrier.class.to_s.upcase
    result[:location] = result[:location].name
    result[:destination] = result[:destination].name
    result[:cargo] = cargos.map do |cargo|
      { cargo_id: cargo.name, destination: cargo.destination.name, origin: "FACTORY" }
    end

    JSON.generate(result)
  end

  def to_hash
    {
      event: @name,
      time: @carrier_state.from_time,
      duration: @carrier_state.to_time - @carrier_state.from_time,
      carrier: @carrier_state.carrier,
      location: @carrier_state.place,
      destination: @carrier_state.place,
      cargos: @carrier_state.cargos
    }.merge(@overrides)
  end
end
