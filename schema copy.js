const mongoose = require('mongoose')
const partnerSchema = new mongoose.Schema({
    _id: mongoose.Schema.Types.ObjectId,
    name: String,
    email: String,
    walletAddress : String,
})

module.exports = mongoose.model('partners', partnerSchema)