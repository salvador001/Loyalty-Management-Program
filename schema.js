const mongoose = require('mongoose')
const userSchema = new mongoose.Schema({
    _id: mongoose.Schema.Types.ObjectId,
    name: String,
    email: String,
    password: String,
    walletAddress : String,
    orders: Object,
})

module.exports = mongoose.model('customers', userSchema)