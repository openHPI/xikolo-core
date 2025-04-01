# frozen_string_literal: true

class TestGroupListener
  def test_group_created(test_group)
    Xikolo.api(:account).value!
      .rel(:groups)
      .post({name: test_group.group_name})
      .value

    test_group.persist_flippers(true)
  end
end
