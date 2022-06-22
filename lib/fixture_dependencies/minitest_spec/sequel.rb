require_relative '../minitest_spec'

class Minitest::Spec
  def run(*args, &block)
    Sequel::Model.db.transaction(:rollback=>:always){super}
  end
end
