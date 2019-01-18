class Finders::AllOrganisations
  def self.run(locale: 'en')
    new.run(locale)
  end

  def run(locale)
    editions = find_all(locale)
    editions.map { |edition| new_organisation(edition) }
  end

private

  def new_organisation(org)
    Organisation.new(
      id: org[:content_id],
      name: org[:title]
    )
  end

  def find_all(locale)
    Dimensions::Edition.latest
      .select(:content_id, :title, :locale)
      .where(document_type: 'organisation', locale: locale)
      .order(:title)
  end
end
