const { userModel } = require("../models/user.model");
const { addressModel } = require("../models/address.model");

async function findCurrentUser(req) {
  return userModel.findOne({ firebase_uid: req.user.uid });
}

// GET /api/addresses
exports.getMyAddresses = async (req, res) => {
  let dataRes = { msg: "OK", data: null };

  try {
    const user = await findCurrentUser(req);
    if (!user) {
      dataRes.msg = "Không tìm thấy user";
      return res.status(404).json(dataRes);
    }

    const addresses = await addressModel
      .find({ user_id: user._id, deleted_at: null })
      .sort({ is_default: -1, createdAt: -1 });

    dataRes.data = addresses;
    return res.json(dataRes);
  } catch (err) {
    console.error("Get my addresses error:", err.message);
    dataRes.msg = "Server error: " + err.message;
    return res.status(500).json(dataRes);
  }
};

// POST /api/addresses
exports.createAddress = async (req, res) => {
  let dataRes = { msg: "OK", data: null };

  try {
    const user = await findCurrentUser(req);
    if (!user) {
      dataRes.msg = "Không tìm thấy user";
      return res.status(404).json(dataRes);
    }

    const { receiver_name, receiver_phone, address_detail, is_default } = req.body;

    if (!receiver_name || !receiver_phone || !address_detail) {
      dataRes.msg = "Thiếu thông tin địa chỉ";
      return res.status(400).json(dataRes);
    }

    if (is_default) {
      await addressModel.updateMany({ user_id: user._id }, { is_default: false });
    }

    const address = await addressModel.create({
      user_id: user._id,
      receiver_name,
      receiver_phone,
      address_detail,
      is_default: !!is_default,
    });

    dataRes.data = address;
    return res.json(dataRes);
  } catch (err) {
    console.error("Create address error:", err.message);
    dataRes.msg = "Server error: " + err.message;
    return res.status(500).json(dataRes);
  }
};

// PUT /api/addresses/:id
exports.updateAddress = async (req, res) => {
  let dataRes = { msg: "OK", data: null };

  try {
    const user = await findCurrentUser(req);
    if (!user) {
      dataRes.msg = "Không tìm thấy user";
      return res.status(404).json(dataRes);
    }

    const address = await addressModel.findOne({
      _id: req.params.id,
      user_id: user._id,
      deleted_at: null,
    });

    if (!address) {
      dataRes.msg = "Không tìm thấy địa chỉ";
      return res.status(404).json(dataRes);
    }

    const { receiver_name, receiver_phone, address_detail, is_default } = req.body;

    if (receiver_name !== undefined) address.receiver_name = receiver_name;
    if (receiver_phone !== undefined) address.receiver_phone = receiver_phone;
    if (address_detail !== undefined) address.address_detail = address_detail;

    if (is_default === true) {
      await addressModel.updateMany({ user_id: user._id }, { is_default: false });
      address.is_default = true;
    } else if (is_default === false) {
      address.is_default = false;
    }

    await address.save();

    dataRes.data = address;
    return res.json(dataRes);
  } catch (err) {
    console.error("Update address error:", err.message);
    dataRes.msg = "Server error: " + err.message;
    return res.status(500).json(dataRes);
  }
};

// DELETE /api/addresses/:id
exports.deleteAddress = async (req, res) => {
  let dataRes = { msg: "OK", data: null };

  try {
    const user = await findCurrentUser(req);
    if (!user) {
      dataRes.msg = "Không tìm thấy user";
      return res.status(404).json(dataRes);
    }

    const address = await addressModel.findOne({
      _id: req.params.id,
      user_id: user._id,
      deleted_at: null,
    });

    if (!address) {
      dataRes.msg = "Không tìm thấy địa chỉ";
      return res.status(404).json(dataRes);
    }

    address.deleted_at = new Date();
    await address.save();

    dataRes.data = { _id: address._id };
    return res.json(dataRes);
  } catch (err) {
    console.error("Delete address error:", err.message);
    dataRes.msg = "Server error: " + err.message;
    return res.status(500).json(dataRes);
  }
};
