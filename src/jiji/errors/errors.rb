# coding: utf-8

module Jiji
module Errors

  class AuthFailedException < Exception
  end

  class NotFoundException < Exception
  end

  class UnauthorizedException < Exception
  end

  class NotInitializedException < Exception
  end

end
end
