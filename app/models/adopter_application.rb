# == Schema Information
#
# Table name: adopter_applications
#
#  id                 :bigint           not null, primary key
#  notes              :text
#  profile_show       :boolean          default(TRUE)
#  status             :integer          default("awaiting_review")
#  created_at         :datetime         not null
#  updated_at         :datetime         not null
#  adopter_account_id :bigint           not null
#  pet_id             :bigint           not null
#
# Indexes
#
#  index_adopter_applications_on_adopter_account_id  (adopter_account_id)
#  index_adopter_applications_on_pet_id              (pet_id)
#
# Foreign Keys
#
#  fk_rails_...  (adopter_account_id => adopter_accounts.id)
#  fk_rails_...  (pet_id => pets.id)
#
class AdopterApplication < ApplicationRecord
  belongs_to :pet
  belongs_to :adopter_account

  enum :status, [:awaiting_review,
    :under_review,
    :adoption_pending,
    :withdrawn,
    :successful_applicant,
    :adoption_made]

  # remove adoption_made status as not necessary for staff
  def self.app_review_statuses
    AdopterApplication.statuses.keys.map do |status|
      unless status == "adoption_made"
        [status.titleize, status]
      end
    end.compact!
  end

  # check if an adopter has applied to adopt a pet
  def self.adoption_exists?(adopter_account_id, pet_id)
    AdopterApplication.where(adopter_account_id: adopter_account_id,
      pet_id: pet_id).exists?
  end

  # check if any applications are set to profile_show: true
  def self.any_applications_profile_show_true?(adopter_account_id)
    applications = AdopterApplication.where(adopter_account_id: adopter_account_id)
    applications.any? { |app| app.profile_show == true }
  end

  def self.retire_applications(pet_id:)
    where(pet_id:).each do |adopter_application|
      adopter_application.update!(status: :adoption_made)
    end
  end

  def applicant_name
    "#{adopter_account.user.last_name}, #{adopter_account.user.first_name}"
  end

  def withdraw
    update!(status: :withdrawn)
  end

  ransacker :applicant_name do
    Arel.sql("CONCAT(users.last_name, ', ', users.first_name)")
  end

  ransacker :status, formatter: proc { |v| statuses[v] } do |parent|
    parent.table[:status]
  end

  def self.ransackable_attributes(auth_object = nil)
    ["applicant_name", "status"]
  end
end
