module EjabberdRest
  module Error
    class RequestFailed < StandardError
    end

    class UnknownError < StandardError
    end

    class UserAlreadyRegistered < StandardError
    end
  end
end