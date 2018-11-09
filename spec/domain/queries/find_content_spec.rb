RSpec.describe Queries::FindContent do
  include MonthlyAggregations

  let(:primary_org_id) { '96cad973-92dc-41ea-a0ff-c377908fee74' }

  let(:filter) do
    {
      date_range: 'last-30-days',
      organisation_id: primary_org_id,
      document_type: nil
    }
  end

  before do
    create :user
  end

  it 'returns the aggregations for the last 30 days' do
    edition1 = create :edition, base_path: '/path1', date: 2.months.ago, organisation_id: primary_org_id
    edition2 = create :edition, base_path: '/path2', date: 2.months.ago, organisation_id: primary_org_id

    create :metric, edition: edition1, date: 15.days.ago, upviews: 15, useful_yes: 8, useful_no: 9, searches: 10
    create :metric, edition: edition1, date: 10.days.ago, upviews: 20, useful_yes: 5, useful_no: 1, searches: 1
    create :metric, edition: edition2, date: 10.days.ago, upviews: 15, useful_yes: 8, useful_no: 19, searches: 10
    create :metric, edition: edition2, date: 11.days.ago, upviews: 10, useful_yes: 5, useful_no: 1, searches: 11

    calculate_monthly_aggregations!
    refresh_views

    response = described_class.call(filter: filter)
    expect(response[:results]).to contain_exactly(
      hash_including(upviews: 35, searches: 11, satisfaction: 0.5652173913043478, satisfaction_score_responses: 23),
      hash_including(upviews: 25, searches: 21, satisfaction: 0.3939393939393939, satisfaction_score_responses: 33),
    )
  end

  it 'returns the metadata for the last 30 days' do
    edition1 = create :edition,
      base_path: '/path1',
      organisation_id: primary_org_id,
      title: 'title-01',
      document_type: 'document-type-01'

    edition2 = create :edition,
      base_path: '/path2',
      organisation_id: primary_org_id,
      title: 'title-02',
      document_type: 'document-type-02'

    create :metric, edition: edition1, date: 15.days.ago
    create :metric, edition: edition2, date: 10.days.ago

    calculate_monthly_aggregations!
    refresh_views

    response = described_class.call(filter: filter)
    expect(response[:results]).to contain_exactly(
      hash_including(base_path: '/path1'),
      hash_including(base_path: '/path2'),
    )
  end

  describe 'Pagination' do
    before do
      4.times do |n|
        edition = create :edition, base_path: "/path/#{n}", organisation_id: primary_org_id
        create :metric, edition: edition, date: 15.days.ago, upviews: (100 - n)
      end

      calculate_monthly_aggregations!
      refresh_views
    end

    it 'returns the first page of data with pagination info' do
      response = described_class.call(filter: filter.merge(page: 1, page_size: 2))
      expect(response[:results]).to contain_exactly(
        hash_including(base_path: '/path/0'),
        hash_including(base_path: '/path/1'),
      )
      expect(response).to include(
        page: 1,
        total_pages: 2,
        total_results: 4,
      )
    end

    it 'returns the second page of data' do
      response = described_class.call(filter: filter.merge(page: 2, page_size: 2))
      expect(response[:results]).to contain_exactly(
        hash_including(base_path: '/path/2'),
        hash_including(base_path: '/path/3'),
      )
      expect(response).to include(
        page: 2,
        total_pages: 2,
        total_results: 4,
      )
    end
  end

  describe 'when no useful_yes/no.. responses' do
    before do
      edition = create :edition, organisation_id: primary_org_id
      create :metric, edition: edition, date: 15.days.ago, useful_yes: 0, useful_no: 0

      calculate_monthly_aggregations!
      refresh_views
    end

    it 'returns the nil for the satisfaction' do
      results = described_class.call(filter: filter)
      expect(results[:results].first).to include(
        satisfaction: nil,
        satisfaction_score_responses: 0
      )
    end
  end

  describe 'when no metrics in the date range' do
    before do
      create :edition, date: '2018-02-01'

      calculate_monthly_aggregations!
      refresh_views
    end

    it 'returns a empty array' do
      results = described_class.call(filter: filter)
      expect(results[:results]).to be_empty
    end
  end

  describe 'when invalid filter' do
    it 'raises an error if no `organisation_id` attribute' do
      filter.delete :organisation_id

      expect(-> { described_class.call(filter: filter) }).to raise_error(ArgumentError)
    end

    it 'raises an error if no `date_range` attribute' do
      filter.delete :date_range

      expect(-> { described_class.call(filter: filter) }).to raise_error(ArgumentError)
    end
  end
end
