# frozen_string_literal: true

require './plugins/discourse-nntp-bridge/spec/rails_helper'
require 'sidekiq/testing'

describe Jobs::NntpBridgeImportScheduler do
  describe 'enqueue' do
    it 'should support enqueue' do
      Jobs.enqueue(:nntp_bridge_import_scheduler)
    end

    context 'with two existing categories' do
      let!(:category1) { Fabricate(:category, custom_fields: { nntp_bridge_newsgroup: 'general' }) }
      let!(:category2) { Fabricate(:category, custom_fields: { nntp_bridge_newsgroup: 'test' }) }

      before do
        Sidekiq::Testing.disable!
        Sidekiq::Queue.new.clear
        SiteSetting.queue_jobs = true
      end

      it 'should queue an importer for each newsgroup' do
        expect do
          Jobs::NntpBridgeImportScheduler.new.execute({})
        end.to change { Sidekiq::Queue.new.size }.by(2)
      end

      it 'should mark importers as queued' do
        expect(Jobs::NntpBridgeImportScheduler.importer_queued?('test')).to eq(false)
        expect(Jobs::NntpBridgeImportScheduler.importer_queued?('general')).to eq(false)

        Jobs::NntpBridgeImportScheduler.new.execute({})

        expect(Jobs::NntpBridgeImportScheduler.importer_queued?('test')).to eq(true)
        expect(Jobs::NntpBridgeImportScheduler.importer_queued?('general')).to eq(true)
      end
    end
  end
end
