class Sensor < ApplicationRecord
    # Optional free-form label used to group sensors (e.g. by room)
    normalizes :group_name, with: ->(value) { value.to_s.strip.presence }

    validates :code, presence: true, uniqueness: true,
                length: { maximum: 50 },
                format: {
                    with: /\A[a-zA-Z0-9_-]+\z/,
                    message: "only allows letters, numbers, underscores, and hyphens"
                }
    validates :group_name, length: { maximum: 50 }

    # Distinct, non-empty group names sorted alphabetically
    def self.groups
        where.not(group_name: nil).distinct.order(:group_name).pluck(:group_name)
    end
end
