RSpec.describe "Simulation's step", aggregate_failures: true do
  let(:simulation) { Simulation.new(state: state) }

  describe "a truck moving a cargo from A to B" do
    # From:
    #
    #  [ A     ] -----> [ B ]
    #  [ Cargo ]
    #  [ Truck ]
    #
    # To:
    #
    #  [ A ] -----> [ B     ]
    #               [ Cargo ]
    #               [ Truck ]

    let(:location_a) { Location.new(name: "A") }
    let(:location_b) { Location.new(name: "B") }
    let(:truck) { Truck.new(name: "1", origin: location_a) }
    let(:cargo) { Cargo.new(name: "1", destination: location_b) }
    let(:road) { TruckRoad.new(location_a, location_b) }
    let(:itineraries) do
      {
        # [From, To] => [Follow, Through]
        [location_a, location_b] => [location_b, road],
        [location_b, location_a] => [location_a, road],
      }
    end
    let(:map) do
      Map.new(
        locations: [location_a, location_b],
        roads: [road],
        itineraries: itineraries,
      )
    end
    let(:state) do
      State.new(
        time: 0,
        map: map,
        place_states: {
          location_a => PlaceState.new(place: location_a, cargos: [cargo]),
          location_b => PlaceState.new(place: location_b, cargos: []),
        },
        carrier_states: {
          truck => CarrierState.new(carrier: truck, type: :idle, from_time: 0, to_time: 0, place: location_a, cargo: nil),
        },
        events: [],
      )
    end

    it "moves the cargo to the destination" do
      expect(simulation.step.state.place_states.fetch(location_b)).to have_attributes(
        cargos: [cargo],
      )

      expect(simulation.step.state.carrier_states.fetch(truck)).to have_attributes(
        type: :traveling,
        place: location_a,
        from_time: 1,
        to_time: 2,
        cargo: nil,
      )
    end

    it "comes back home when the cargo is unloaded" do
      expect(simulation.step.step.state.carrier_states.fetch(truck)).to have_attributes(
        type: :idle,
        place: location_a,
        from_time: 2,
        to_time: 2,
        cargo: nil,
      )
    end

    it "stays home when no other cargo need to be moving" do
      expect(simulation.step.step.step.state.carrier_states.fetch(truck)).to have_attributes(
        type: :idle,
        place: location_a,
        from_time: 2,
        to_time: 2,
        cargo: nil,
      )
    end

    context "when no itinerary is found" do
      let(:itineraries) { {} }

      it "does nothing" do
        expect(simulation.step.state.carrier_states).to eq simulation.state.carrier_states
        expect(simulation.step.state.place_states).to eq simulation.state.place_states
      end
    end

    context "when the road is not a TruckRoad but a ShipRoad" do
      # From:
      #
      #  [ A     ] ~~~~~> [ B ]
      #  [ Cargo ]
      #  [ Ship  ]

      let(:road) { ShipRoad.new(location_a, location_b) }

      it "can't move a truck through a ShipRoad" do
        expect(simulation.step.state.carrier_states).to eq simulation.state.carrier_states
        expect(simulation.step.state.place_states).to eq simulation.state.place_states
      end
    end


    context "when the road is long" do
      # From:
      #
      #  [ A     ] ----- 2 hours -----> [ B ]
      #  [ Cargo ]
      #  [ Truck ]
      #
      # To:
      #
      #  [ A ] ----- 2 hours -----> [ B ]
      #             [ Cargo ]
      #             [ Truck ]

      let(:road) { TruckRoad.new(location_a, location_b, distance: 2) }

      it "starts a journey on the road" do
        expect(simulation.step.state.carrier_states.fetch(truck)).to have_attributes(
          type: :traveling,
          from_time: 0,
          to_time: 2,
          place: location_b,
          cargo: cargo,
        )
      end

      it "finishes its journey given enough time" do
        expect(simulation.step.step.state.place_states.fetch(location_b)).to have_attributes(
          cargos: [cargo],
        )

        expect(simulation.step.step.state.carrier_states.fetch(truck)).to have_attributes(
          type: :traveling,
          from_time: 2,
          to_time: 4,
          place: location_a,
          cargo: nil,
        )
      end
    end
  end

  describe "a truck moving a cargo from A to C through B" do
    # From:
    #
    #  [ A     ] -----> [ B ] -----> [ C ]
    #  [ Cargo ]
    #  [ Truck ]
    #
    # To:
    #
    #  [ A ] -----> [ B     ] -----> [ C ]
    #               [ Truck ]
    #               [ Cargo ]
    #
    # To:
    #
    #  [ A ] -----> [ B ] -----> [ C     ]
    #                            [ Cargo ]
    #                            [ Truck ]

    let(:location_a) { Location.new(name: "A") }
    let(:location_b) { Location.new(name: "B") }
    let(:location_c) { Location.new(name: "C") }
    let(:truck) { Truck.new(name: "1", origin: location_a) }
    let(:cargo) { Cargo.new(name: "1", destination: location_c) }
    let(:road_a_b) { TruckRoad.new(location_a, location_b) }
    let(:road_b_c) { TruckRoad.new(location_b, location_c) }
    let(:itineraries) do
      {
        # [From, To] => [Follow, Through]
        [location_a, location_c] => [location_b, road_a_b],
        [location_a, location_b] => [location_b, road_a_b],
        [location_b, location_a] => [location_a, road_a_b],
        [location_b, location_c] => [location_c, road_b_c],
        [location_c, location_a] => [location_b, road_b_c],
        [location_c, location_b] => [location_b, road_b_c],
      }
    end
    let(:map) do
      Map.new(
        locations: [location_a, location_b, location_c],
        roads: [road_a_b, road_b_c],
        itineraries: itineraries,
      )
    end
    let(:state) do
      State.new(
        time: 0,
        map: map,
        place_states: {
          location_a => PlaceState.new(place: location_a, cargos: [cargo]),
          location_b => PlaceState.new(place: location_b, cargos: []),
          location_c => PlaceState.new(place: location_c, cargos: []),
        },
        carrier_states: {
          truck => CarrierState.new(carrier: truck, type: :idle, from_time: 0, to_time: 0, place: location_a, cargo: nil),
        },
        events: [],
      )
    end

    it "moves the cargo to B then to C" do
      expect(simulation.step.state.carrier_states.fetch(truck)).to have_attributes(
        type: :traveling,
        place: location_c,
        from_time: 1,
        to_time: 2,
        cargo: cargo,
      )
    end

    context "when the road from B to C is for ships" do
      # From:
      #
      #  [ A     ] -----> [ B ] ~~~~~> [ C ]
      #  [ Cargo ]
      #  [ Truck ]
      #
      # To:
      #
      #  [ A ] -----> [ B     ] ~~~~~> [ C ]
      #               [ Truck ]
      #               [ Cargo ]
      #
      # To:
      #
      #  [ A     ] -----> [ B     ] ~~~~~> [ C ]
      #  [ Truck ]        [ Cargo ]

      let(:road_b_c) { ShipRoad.new(location_b, location_c) }

      it "unloads the cargo and heads back home if it can't go further" do
        expect(simulation.step.state.carrier_states.fetch(truck)).to have_attributes(
          type: :traveling,
          place: location_a,
          from_time: 1,
          to_time: 2,
          cargo: nil,
        )

        expect(simulation.step.state.place_states.fetch(location_b)).to have_attributes(
          cargos: [cargo],
        )
      end
    end
  end

  describe "a ship moving a cargo from A to B" do
    # From:
    #
    #  [ A     ] ~~~~~> [ B ]
    #  [ Cargo ]
    #  [ Ship  ]
    #
    # To:
    #
    #  [ A ] ~~~~~> [ B     ]
    #               [ Cargo ]
    #               [ Ship ]

    let(:location_a) { Location.new(name: "A") }
    let(:location_b) { Location.new(name: "B") }
    let(:ship) { Ship.new(name: "1", origin: location_a) }
    let(:cargo) { Cargo.new(name: "1", destination: location_b) }
    let(:road) { ShipRoad.new(location_a, location_b) }
    let(:itineraries) do
      {
        # [From, To] => [Follow, Through]
        [location_a, location_b] => [location_b, road],
        [location_b, location_a] => [location_a, road],
      }
    end
    let(:map) do
      Map.new(
        locations: [location_a, location_b],
        roads: [road],
        itineraries: itineraries,
      )
    end
    let(:state) do
      State.new(
        time: 0,
        map: map,
        place_states: {
          location_a => PlaceState.new(place: location_a, cargos: [cargo]),
          location_b => PlaceState.new(place: location_b, cargos: []),
        },
        carrier_states: {
          ship => CarrierState.new(carrier: ship, type: :idle, from_time: 0, to_time: 0, place: location_a, cargo: nil),
        },
        events: [],
      )
    end

    it "moves the cargo to the destination" do
      expect(simulation.step.state.place_states.fetch(location_b)).to have_attributes(
        cargos: [cargo],
      )

      expect(simulation.step.state.carrier_states.fetch(ship)).to have_attributes(
        type: :traveling,
        place: location_a,
        from_time: 1,
        to_time: 2,
        cargo: nil,
      )
    end

    context "when the road is not a ShipRoad but a TruckRoad" do
      # From:
      #
      #  [ A     ] -----> [ B ]
      #  [ Cargo ]
      #  [ Ship  ]

      let(:road) { TruckRoad.new(location_a, location_b) }

      it "can't move a ship through a TruckRoad" do
        expect(simulation.step.state.carrier_states).to eq simulation.state.carrier_states
        expect(simulation.step.state.place_states).to eq simulation.state.place_states
      end
    end
  end
end
