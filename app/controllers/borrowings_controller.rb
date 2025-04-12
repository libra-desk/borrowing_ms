require 'net/http'
require 'json'

class BorrowingsController < ApplicationController
  def index
    if params[:student_id] # This has to be passed via query params
      borrowings = Borrowing.where(student_id: params[:student_id])
    else
      borrowings = Borrowing.all
    end

    render json: borrowings
  end

  # This action allows borrowing of books
  def create
    if can_student_borrow? params[:student_id] and if_book_available? params[:book_id]
      borrowing = Borrowing.new(borrowing_params)
      borrowing.borrowed_at = Time.now
      borrowing.due_at = MAX_DAYS_BORROWABLE.days.from_now # 10 days to hold the book
      borrowing.returned = false

      if borrowing.save
        payload = {
          book_id: borrowing_params['book_id']
        }
  
        # Here below we are calling book_ms to update the status of this borrowing.
        # TODO: Try to do this calling via Kafka so that you dont have to 
        # wait for book_ms response. 
        response = call_book_ms("/books/#{borrowing_params['book_id']}/borrow", payload)
        head :created
      else
        head :unprocessable_entity
      end
    else
      head :unprocessable_entity
    end
  end

  # Borrowings should not be destroyed. This action is solely for an admin
  def destroy
    borrowing = Borrowing.find_by(id: params[:id])

    if borrowing
      borrowing.destroy
      head :no_content
    else
      head :not_found
    end
  end

  def borrowed_books
    student_id = params[:student_id]
    borrowings = Borrowing.where(student_id: student_id,
                                 returned: false
                                )
    book_ids = borrowings.map { |borrow| borrow.book_id }
    book_ids_payload = {
      book_ids: book_ids
    }
    response = call_book_ms("/borrowed_books", book_ids_payload)

    render json: response.body
  end

  def return_book
    borrowing = Borrowing.find_by(student_id: params[:student_id],
                                  book_id: params[:book_id]
                                 )
    if borrowing
      borrowing.update(returned: true,
                       returned_at: Time.now
                      )
      payload = {
        book_id: borrowing_params['book_id']
      }

      response = call_book_ms("/books/#{borrowing_params['book_id']}/return", payload)

      render json: borrowing.as_json.merge(fine_incurred: borrowing.compute_fine)
    else
      head :unprocessable_entity
    end
  end

  private

  def borrowing_params
    params.require(:borrowing).permit(:student_id, :book_id)
  end

  def can_student_borrow?(student_id)
    Borrowing.where(student_id: student_id, returned: false).count < MAX_BOOKS_BORROWABLE
  end

  def if_book_available?(book_id)
    !Borrowing.find_by(book_id: book_id, returned: false).present?
  end

  def call_book_ms endpoint, payload
    # uri = URI("http://localhost:3001/books/#{book_id}/#{endpoint}")
    uri = URI("http://localhost:3001/#{endpoint}")

    http = Net::HTTP.new(uri.host, uri.port)
    request = Net::HTTP::Post.new(uri.path,
                                  auth_headers
                                 )
    request.body = payload.to_json
    http.request(request)
  end

  def auth_headers
    {
      "Authorization" => token,
      "Accept" => "application/json",
      "Content-Type" => "application/json"
    }
  end
end
