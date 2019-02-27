# -*- coding: utf-8 -*-

RSpec.describe Streams::Messages::SingleItemMessage do
  include PublishingEventProcessingSpecHelper

  subject { described_class }

  include_examples 'BaseMessage#invalid?'
  include_examples 'BaseMessage#historically_political?'
  include_examples 'BaseMessage#withdrawn_notice?'

  describe '#edition_attributes' do
    let(:message) do
      msg = build(:message, attributes: message_attributes)
      msg.payload['details']['body'] = '<p>some content</p>'
      msg.payload['details']['government'] = { 'current' => true }
      msg.payload['withdrawn_notice'] = { "explanation" => 'something' }
      msg
    end

    let(:instance) { subject.new(message.payload, "routing_key") }

    it 'returns the attributes' do
      attributes = instance.edition_attributes
      expect(attributes).to eq(
        expected_raw_attributes(
          content_id: message.payload['content_id'],
          document_text: 'some content',
          historical: false,
          warehouse_item_id: "#{message.payload['content_id']}:#{message.payload['locale']}",
          withdrawn: true,
          acronym: nil
        )
      )
    end
  end

  context 'when unescaped characters in the base_path' do
    let(:message) do
      message = build :message
      message.payload['base_path'] = '/gov.uk/%E0%B8%81%E0%B8%B2%E0%B8%A3%E0%B8%A2'

      subject.new(message.payload, "routing_key")
    end

    it 'decodes the characters' do
      expect(message.edition_attributes).to include(base_path: '/gov.uk/การย')
    end
  end

  describe "extracts Organisation's acronym" do
    let(:message) do
      msg = build(:message, attributes: message_attributes)
      subject.new(msg.payload, "routing_key")
    end

    it 'assigns the acronym if provided' do
      message.payload['details']['acronym'] = 'HMRC'
      attributes = message.edition_attributes

      expect(attributes).to include(acronym: 'HMRC')
    end

    it 'does not assign a value when empty string' do
      message.payload['details']['acronym'] = ''
      attributes = message.edition_attributes

      expect(attributes).to include(acronym: nil)
    end

    it 'does not assigns a value if not provided' do
      message.payload['details'].delete 'acronym'
      attributes = message.edition_attributes

      expect(attributes).to include(acronym: nil)
    end
  end
end
