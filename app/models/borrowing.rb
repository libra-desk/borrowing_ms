class Borrowing < ApplicationRecord
  validates_presence_of :book_id,
                        :student_id

  # Below is the validation that if the book was borrowed and not yet returned,
  # then another person cannot borrow that book.
  validates :book_id,
            uniqueness: {
              scope: :returned,
              message: "is already borrowed"
            },
            unless: :returned?

  def compute_fine
    return 0 if returned && returned_at <= due_at

    # Below code comparison is to ensure that the late_days is never negative
    late_days = [ (Time.current.to_date - due_at.to_date), 0 ].max
    late_days * FINE_AMOUNT_FOR_LATE_RETURNS
  end
end
