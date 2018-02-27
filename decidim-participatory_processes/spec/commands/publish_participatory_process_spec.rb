# frozen_string_literal: true

require "spec_helper"

module Decidim::ParticipatoryProcesses
  describe Admin::PublishParticipatoryProcess do
    subject { described_class.new(my_process, user) }

    let(:my_process) { create :participatory_process, :unpublished, organization: user.organization }
    let(:user) { create :user }

    context "when the process is nil" do
      let(:my_process) { nil }

      it "is not valid" do
        expect { subject.call }.to broadcast(:invalid)
      end
    end

    context "when the process is published" do
      let(:my_process) { create :participatory_process }

      it "is not valid" do
        expect { subject.call }.to broadcast(:invalid)
      end
    end

    context "when the process is not published" do
      it "is valid" do
        expect { subject.call }.to broadcast(:ok)
      end

      it "traces the action", versioning: true do
        expect(Decidim.traceability)
          .to receive(:perform_action!)
          .with("publish", my_process, user)
          .and_call_original

        expect { subject.call }.to change(Decidim::ActionLog, :count)

        action_log = Decidim::ActionLog.last
        expect(action_log.version).to be_present
        expect(action_log.version.event).to eq "update"
      end

      it "publishes it" do
        subject.call
        my_process.reload
        expect(my_process).to be_published
      end
    end
  end
end
