class Sensor < ApplicationRecord
    validates :code, presence: true, uniqueness: true,
                length: { maximum: 50 },
                format: {
                    with: /\A[a-zA-Z0-9_-]+\z/,
                    message: "only allows letters, numbers, underscores, and hyphens"
                }
end
