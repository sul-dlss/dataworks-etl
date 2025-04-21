# frozen_string_literal: true

require 'rails_helper'

RSpec.describe DataworksMappers::Searchworks do
  subject(:metadata) { described_class.call(source:) }

  context 'with an ICPSR record with MARC metadata' do
    let(:source) { JSON.parse(File.read('spec/fixtures/sources/searchworks_icpsr.json')) }

    it 'maps to Dataworks metadata' do
      # rubocop:disable Layout/LineLength
      expect(metadata).to include(
        identifiers: [
          { identifier: '13650500', identifier_type: 'searchworks_reference' },
          { identifier: '10.3886/ICPSR36853.v2', identifier_type: 'DOI' }
        ],
        contributors: [
          {
            name: 'Prysby, Charles',
            name_type: 'Personal',
            affiliation: [
              {
                name: 'University of North Carolina-Greensboro'
              }
            ]
          },
          {
            name: 'Scavo, Carmine',
            name_type: 'Personal',
            affiliation: [
              {
                name: 'East Carolina University-Greenville, North Carolina'
              }
            ]
          },
          {
            name: 'American Political Science Association',
            name_type: 'Organizational'
          },
          {
            name: 'Inter-university Consortium for Political and Social Research',
            name_type: 'Organizational'
          },
          {
            name: 'Inter-university Consortium for Political and Social Research.',
            name_type: 'Organizational'
          }
        ],
        titles: [
          {
            title: 'SETUPS [electronic resource] Voting Behavior: The 2016 Election'
          }
        ],
        publication_year: '2017',
        access: 'Restricted',
        descriptions: [
          {
            description: 'Voting Behavior http://www.icpsr.umich.edu/web/pages/instructors/setups2016/ in the 2016 Election is an instructional module designed to offer students the opportunity to analyze a dataset drawn from the http://www.icpsr.umich.edu/icpsrweb/ICPSR/studies/36824?q=ANES+ 2016 American National Election (ANES) 2016 Time Series Study [ICPSR 36824]. This instructional module is part of the SETUPS (Supplementary Empirical Teaching Units in Political Science) series and differs from previous modules in that it is completely online, including the data analysis system components.',
            description_type: 'Abstract'
          }
        ],
        subjects: [
          { subject: 'Clinton, Hillary' },
          { subject: 'Economic activity' },
          { subject: 'Foreign policy' },
          { subject: 'Free trade' },
          { subject: 'Government' },
          { subject: 'Government spending' },
          { subject: 'Health insurance' },
          { subject: 'Immigration policy' },
          { subject: 'National elections' },
          { subject: 'News media' },
          { subject: 'Political attitudes' },
          { subject: 'Political participation' },
          { subject: 'Trump, Donald' },
          { subject: 'Voter attitudes' },
          { subject: 'Voting behavior' }
        ],
        url: 'http://doi.org/10.3886/ICPSR36853.v2',
        provider: 'SearchWorks'
      )
      # rubocop:enable Layout/LineLength
    end
  end
end
