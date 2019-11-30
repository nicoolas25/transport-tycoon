require "json"

Event = Struct.new(:event, :time, :transport_id, :kind, :location, :destination, :cargo, keyword_init: true) do
  def to_json
    # {
    #   "event": "DEPART",     # type of log entry: DEPART of ARRIVE
    #   "time": 0,             # time in hours
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
    JSON.generate(to_h)
  end
end
