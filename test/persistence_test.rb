require File.expand_path('../helper', __FILE__)

class PersistenceTest < Minidoc::TestCase
  def test_ids
    user = User.new
    assert_equal BSON::ObjectId, user.id.class

    user = User.new(_id: BSON::ObjectId('52955cc5f9f6a538a9000001'))
    assert_equal BSON::ObjectId('52955cc5f9f6a538a9000001'), user.id

    user = User.new("_id" => BSON::ObjectId('52955cc5f9f6a538a9000001'))
    assert_equal BSON::ObjectId('52955cc5f9f6a538a9000001'), user.id
  end

  def test_new_record
    user = User.new
    assert_equal true, user.new_record?
    user.save
    assert_equal false, user.new_record?
  end

  def test_persisted
    user = User.new
    assert_equal false, user.persisted?
    user.save
    assert_equal true, user.persisted?
    user.destroy
    assert_equal false, user.persisted?
  end

  def test_save
    user = User.new
    old_id = user.id
    assert_equal true, user.save
    assert_equal 1, User.count
    assert_equal old_id, user.id
  end

  def test_create
    user = User.create!(name: "Bryan")
    assert_equal "Bryan", user.name
    assert_equal 1, User.count

    user = User.create(name: "Bryan")
    assert_equal "Bryan", user.name
    assert_equal 2, User.count
  end

  def test_update
    user = User.create(name: "Bryan")
    user.name = "Noah"
    assert_equal "Noah", user.name
    user.save
    assert_equal "Noah", user.reload.name
  end

  def test_destroy
    user = User.create(name: "Bryan")
    assert_equal false, user.destroyed?
    user.destroy
    assert_equal 0, User.count
    assert_equal true, user.destroyed?
  end

  def test_delete
    user = User.create(name: "Bryan")
    User.delete(user.id)
    assert_equal 0, User.count

    user = User.create(name: "Bryan")
    User.delete(user.id.to_s)
    assert_equal 0, User.count

    user = User.create(name: "Bryan")
    user.delete
    assert_equal 0, User.count
  end

  def test_reload
    user = User.create(name: "Bryan")
    assert_equal "Bryan", user.reload.name

    User.collection.update({_id: user.id}, {name: "Noah"})
    assert_equal "Noah", user.reload.name
  end

  def test_class_set
    user = User.create(name: "Bryan")
    User.set(user.id, name: "Noah")
    assert_equal "Bryan", user.name # Class set can't trigger update
    assert_equal "Noah", user.reload.name
    assert_equal "Noah", User.first.name

    User.set(user.id.to_s, name: "Mike")
    assert_equal "Mike", user.reload.name
    assert_equal "Mike", User.first.name
  end

  def test_instance_set
    user = User.create(name: "Bryan")
    user.set(name: "Noah")
    assert_equal "Noah", user.name
    assert_equal "Noah", user.reload.name
    assert_equal "Noah", User.first.name

    user = User.create(name: "Bryan")
    user.set("name" => "Noah")
    assert_equal "Noah", user.name
    assert_equal "Noah", user.reload.name
  end

  def test_class_unset
    user = User.create(name: "Bryan")
    User.unset(user.id, :name)
    assert_equal "Bryan", user.name # Class set can't trigger update
    assert_equal nil, user.reload.name
    assert_equal nil, User.first.name

    User.unset(user.id.to_s, :name)
    assert_equal nil, user.reload.name
    assert_equal nil, User.first.name
  end

  def test_instance_unset
    user = User.create(name: "Bryan")
    user.unset(:name)
    assert_equal nil, user.name
    assert_equal nil, user.reload.name
    assert_equal nil, User.first.name

    user = User.create(name: "Bryan")
    user.unset("name")
    assert_equal nil, user.name
    assert_equal nil, user.reload.name
  end
end
