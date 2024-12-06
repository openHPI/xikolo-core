# frozen_string_literal: true

require 'xikolo/common'

RSpec.describe 'Xikolo.metrics' do
  subject { Xikolo.metrics.write series, tags:, values: }

  let(:series) { 'my-series' }
  let(:tags) { {a: 1, b: 2} }
  let(:values) { {a: 6, b: 2.5} }

  it 'sends data to a Telegraf Agent listening on a local UDP port' do
    server = UDPSocket.new
    server.bind 'localhost', 8094

    subject
    recv = server.read_nonblock(4096)

    # Formatted according to the InfluxDB Line Protocol
    # See https://docs.influxdata.com/influxdb/v1.7/write_protocols/line_protocol_tutorial/
    expect(recv).to eq 'my-series,a=1,b=2 a=6i,b=2.5'

    server.close
  end
end
