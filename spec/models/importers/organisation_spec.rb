require 'rails_helper'

RSpec.describe Importers::Organisation do
  it 'imports an organisation with the provided slug' do
    response = double(body: {
      results: [
        {
          some_field: 'some_value',
        },
      ]}.to_json)
    allow(HTTParty).to receive(:get).and_return(response)

    slug = 'hm-revenue-customs'
    Importers::Organisation.run(slug)

    expect(Organisation.count).to eq(1)
    expect(Organisation.first.slug).to eq(slug)
  end

  it 'queries the search API with the organisation\'s slug' do
    response = double(body: {
      results: [
        {
          some_field: 'some_value',
        },
      ]}.to_json)
    expected_url = 'https://www.gov.uk/api/search.json?filter_organisations=MY-SLUG&count=99&fields=content_id'
    expect(HTTParty).to receive(:get).with(expected_url).and_return(response)

    Importers::Organisation.run('MY-SLUG', batch: 99)
  end

  it 'imports all content items for the organisation' do
    response = double(body: {
      results: [
        {
          content_id: "number-1",
        },
        {
          content_id: "number-2",
        },
      ]}.to_json)
    allow(HTTParty).to receive(:get).and_return(response)
    Importers::Organisation.run("a-slug")
    organisation = Organisation.find_by(slug: "a-slug")
    expect(organisation.content_items.count).to eq(2)
  end

  it 'imports a `content_id` for every content item' do
    response = double(body: {
      results: [
        {
          content_id: "number-1",
        },
        {
          content_id: "number-2",
        },
      ]}.to_json)
    allow(HTTParty).to receive(:get).and_return(response)
    Importers::Organisation.run("a-slug")
    organisation = Organisation.find_by(slug: "a-slug")

    content_ids = organisation.content_items.pluck(:content_id)
    expect(content_ids).to eq(%w(number-1 number-2))
  end
end
