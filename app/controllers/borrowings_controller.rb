class BorrowingsController < ApplicationController

  def index
    if params[:student_id] # This has to be passed via query params
      borrowings = Borrowing.where(student_id: params[:student_id])
    else
      borrowings = Borrowing.all
    end

    render json: borrowings
  end

  def create
    if can_borrow? params[:student_id]
      borrowing = Borrowing.new(borrowing_params)
      borrowing.borrowed_at = Time.now
      borrowing.returned_at = MAX_DAYS_BORROWABLE.days.from_now # 10 days to hold the book
      borrowing.returned = false

      if borrowing.save
        render json: borrowing, status: :created
      else
        render json: { errors: borrowing.errors.full_messages },
               status: :unprocessable_entity
      end
  end

  def return_book
    borrowing = Borrowing.find_by(id: params[:id])
    if borrowing.update(return: true, returned_at: Time.now)
      render json: borrowing
    else
      render json: { errors: borrowing.errors.full_messages }, 
             status: :unprocessable_entity
    end
  end

  private

  def borrowing_params
    params.permit(:student_id, :book_id)
  end

  def can_borrow? student_id
    # Students can only borrow 3 books at a time
    Borrowing.where(student_id: student_id, returned: false).count < MAX_BOOKS_BORROWABLE
  end

end
