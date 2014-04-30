module Vcloud
  module EdgeGateway

    shared_examples "a configuration differ" do

      let(:config_differ) { described_class }

      it 'should return an empty array for two identical empty Hashes' do
        local = { }
        remote = { }
        output = []
        differ = config_differ.new(local, remote)
        expect(differ.diff).to eq(output)
      end

      it 'should return an empty array for two identical simple Hashes' do
        local = { testing: 'testing', one: 1, two: 'two', three: "3" }
        remote = { testing: 'testing', one: 1, two: 'two', three: "3" }
        output =  []
        differ = config_differ.new(local, remote)
        expect(differ.diff).to eq(output)
      end

      it 'should return an empty array for two identical deep Hashes' do
        local = { testing: 'testing', one: 1, deep: [
          { foo: 'bar', deeper: [ 1, 2, 3, 4, 5 ] },
          { baz: 'bop', deeper: [ 6, 5, 4, 3, 2 ] },
        ]}
        remote = { testing: 'testing', one: 1, deep: [
          { foo: 'bar', deeper: [ 1, 2, 3, 4, 5 ] },
          { baz: 'bop', deeper: [ 6, 5, 4, 3, 2 ] },
        ]}
        output = []
        differ = config_differ.new(local, remote)
        expect(differ.diff).to eq(output)
      end

      it 'should highlight a simple addition' do
        local = { foo: '1' }
        remote = { foo: '1', bar: '2' }
        output = [["+", "bar", "2"]]
        differ = config_differ.new(local, remote)
        expect(differ.diff).to eq(output)
      end

      it 'should highlight a simple subtraction' do
        local = { foo: '1', bar: '2' }
        remote = { foo: '1' }
        output = [["-", "bar", "2"]]
        differ = config_differ.new(local, remote)
        expect(differ.diff).to eq(output)
      end

      it 'should highlight a deep addition' do
        local = { testing: 'testing', one: 1, deep: [
          { foo: 'bar', deeper: [ 1, 2, 3, 4, 5 ] },
          { baz: 'bop', deeper: [ 6, 5, 4, 3, 2 ] },
        ]}
        remote = { testing: 'testing', one: 1, deep: [
          { foo: 'bar', deeper: [ 1, 2, 3, 4, 5, 6 ] },
          { baz: 'bop', deeper: [ 6, 5, 4, 3, 2 ] },
        ]}
        output = [["+", "deep[0].deeper[5]", 6]]
        differ = config_differ.new(local, remote)
        expect(differ.diff).to eq(output)
      end

      it 'should highlight a deep subtraction' do
        local = { testing: 'testing', one: 1, deep: [
          { foo: 'bar', deeper: [ 1, 2, 3, 4, 5 ] },
          { baz: 'bop', deeper: [ 6, 5, 4, 3, 2 ] },
        ]}
        remote = { testing: 'testing', one: 1, deep: [
          { foo: 'bar', deeper: [ 1, 2, 3, 4, 5 ] },
          { baz: 'bop', deeper: [ 6, 5, 3, 2 ] },
        ]}
        output =  [["-", "deep[1].deeper[2]", 4]]
        differ = config_differ.new(local, remote)
        expect(differ.diff).to eq(output)
      end

      it 'should return an empty array when hash params are reordered' do
        local = { one: 1, testing: 'testing', deep: [
          { deeper: [ 1, 2, 3, 4, 5 ], foo: 'bar' },
          { baz: 'bop', deeper: [ 6, 5, 4, 3, 2 ] },
        ]}
        remote = { testing: 'testing', one: 1, deep: [
          { foo: 'bar', deeper: [ 1, 2, 3, 4, 5 ] },
          { baz: 'bop', deeper: [ 6, 5, 4, 3, 2 ] },
        ]}
        output = []
        differ = config_differ.new(local, remote)
        expect(differ.diff).to eq(output)
      end

      it 'should highlight when array elements are reordered' do
        local = { testing: 'testing', one: 1, deep: [
          { baz: 'bop', deeper: [ 6, 5, 4, 3, 2 ] },
          { foo: 'bar', deeper: [ 1, 2, 3, 4, 5 ] },
        ]}
        remote = { testing: 'testing', one: 1, deep: [
          { foo: 'bar', deeper: [ 1, 2, 3, 4, 5 ] },
          { baz: 'bop', deeper: [ 6, 5, 4, 3, 2 ] },
        ]}
        output = [
          ["+", "deep[0]", {:foo=>"bar", :deeper=>[1, 2, 3, 4, 5]}],
          ["-", "deep[2]", {:foo=>"bar", :deeper=>[1, 2, 3, 4, 5]}],
        ]
        differ = config_differ.new(local, remote)
        expect(differ.diff).to eq(output)
      end

      it 'should highlight when deep array elements are reordered' do
        local = { testing: 'testing', one: 1, deep: [
          { foo: 'bar', deeper: [ 1, 2, 3, 4, 5 ] },
          { baz: 'bop', deeper: [ 5, 6, 4, 3, 2 ] },
        ]}
        remote = { testing: 'testing', one: 1, deep: [
          { foo: 'bar', deeper: [ 1, 2, 3, 4, 5 ] },
          { baz: 'bop', deeper: [ 6, 5, 4, 3, 2 ] },
        ]}
        output =  [
          ["+", "deep[1].deeper[0]", 6],
          ["-", "deep[1].deeper[2]", 6]
        ]
        differ = config_differ.new(local, remote)
        expect(differ.diff).to eq(output)
      end
    end

  end
end
