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
          { identifier: '13650826', identifier_type: 'searchworks_reference' },
          { identifier: '10.3886/ICPSR37293.v1', identifier_type: 'DOI' }
        ],
        creators: [
          {
            name: 'Wing, Heather',
            name_type: 'Personal',
            affiliation: [
              {
                name: 'Columbus County Schools LEA NC'
              }
            ]
          }
        ],
        contributors: [
          {
            name: 'Wing, Heather',
            name_type: 'Personal',
            affiliation: [
              {
                name: 'Columbus County Schools LEA NC'
              }
            ]
          },
          {
            name: 'Inter-university Consortium for Political and Social Research.',
            name_type: 'Organizational'
          }
        ],
        titles: [
          {
            title: 'A Group Randomized Trial of Restorative Justice Programming to Address the School to Prison Pipeline, Reduce Aggression and Violence, and Enhance School Safety in Middle and High School Students, North Carolina, 2014-2018 [electronic resource]'
          }
        ],
        publication_year: '2020',
        access: 'Restricted',
        descriptions: [
          {
            description: "The project's overarching goals are to improve the knowledge and understanding of school safety and violence, and to enhance school safety programs through rigorous social and behavioral science research. This research project will meet these goals by implementing and evaluating a restorative justice school safety initiative that: 1) reduces bullying perpetration and victimization, aggression, and violence, 2) enhances school safety and mental health in middle and high school students, and 3) reduces the school to prison pipeline by diverting first offenders from the juvenile justice system into Teen Courts. In meeting this objective, we will implement and evaluate an innovative school safety initiative that includes a comprehensive school-based needs assessments using the School Success Profile-Plus (SSP+) student reporting system. In addition, Teen Courts will be implemented in schools to emphasize restorative justice, keep first time offenders out of the juvenile justice system, and reduce the school to prison pipeline. We will evaluate the efficacy of this restorative justice initiative for promoting school safety and reducing violence, by conducting a rigorous experimental trial of 24 middle- and high-schools that are randomly selected to either conduct SSP+ assessments and receive school-based Teen Courts (n=12) or to conduct SSP+ assessments without Teen Court programming (n=12).",
            description_type: 'Abstract'
          }
        ],
        subjects: [
          { subject: 'Bullying', subject_scheme: 'Library of Congress Subject Headings (LCSH)' },
          { subject: 'Restorative justice', subject_scheme: 'Library of Congress Subject Headings (LCSH)' },
          { subject: 'School safety and security', subject_scheme: 'Library of Congress Subject Headings (LCSH)' },
          { subject: 'Teen Court program', subject_scheme: 'Library of Congress Subject Headings (LCSH)' }
        ],
        url: 'http://doi.org/10.3886/ICPSR37293.v1',
        provider: 'SearchWorks'
      )
      # rubocop:enable Layout/LineLength
    end
  end
end
