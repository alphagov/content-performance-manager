class Etl::Master::MasterProcessor
  include Concerns::Traceable

  def self.process(*args)
    new(*args).process
  end

  def self.process_aggregations(*args)
    new(*args).process_aggregations
  end

  def initialize(date: Date.yesterday)
    @date = date
  end

  def process
    raise DuplicateDateError if already_run?

    time(process: :master) do
      Etl::Master::MetricsProcessor.process(date: date)
      Etl::GA::ViewsAndNavigationProcessor.process(date: date)
      Etl::GA::UserFeedbackProcessor.process(date: date)
      Etl::GA::InternalSearchProcessor.process(date: date)
      Etl::Feedex::Processor.process(date: date)

      process_aggregations unless historic_data?
    end

    time(process: :monitor) do
      unless historic_data?
        Monitor::Etl.run
        Monitor::Dimensions.run
        Monitor::Facts.run
        Monitor::Aggregations.run
      end
    end
  end

  def process_aggregations
    Etl::Aggregations::Monthly.process(date: date)
    Etl::Aggregations::Search.process
  end

  def already_run?
    Facts::Metric.where(dimensions_date_id: date).any?
  end

private

  attr_reader :date

  def historic_data?
    date != Date.yesterday
  end

  class DuplicateDateError < StandardError;
  end
end
