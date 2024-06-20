const express=require('express')
const app=express()
const bodyParser=require('body-parser')
const jsonParser=bodyParser.json()
// const fs=require('fs')
const Customer = require('./schema');
const Partner = require('./schema copy')
const mongoose=require('mongoose')


const uri = "mongodb+srv://shourya:hdX01aEJbQBqL0Df@cluster0.wbqch.mongodb.net/e-commerce?retryWrites=true&w=majority"
mongoose.connect(uri,
{ 
    useNewUrlParser:true, 
    useUnifiedTopology:true
}
)

const hostname='127.0.0.1'


app.post('/login',jsonParser, (req,res)=>{
    Customer.findOne({email: req.body.email}).then(result=>{
        if(result.password=== req.body.password){
            res.status(200).send(result)
        }
        else{
            console.log('user is not valid')
            res.status(400).end()
        }
    }).catch(err=>res.status(500).end())
    
})

app.post('/register', jsonParser, (req,res)=>{
    var name;
    console.log(req.body.name)
      const data= new Customer({
          _id: new mongoose.Types.ObjectId(),
          name: req.body.name,
        email: req.body.email,
         password: req.body.password,
         walletAddress : "",
         orders : []
          
      })
      data.save().then(result=>{
          res.status(201).json(result)
          console.log(result)
          name = result.name;
      }).catch(err=>res.status(500))
      
  })

  app.post('/register-partner', jsonParser, (req,res)=>{
    var name;
      const data= new Partner({
          _id: new mongoose.Types.ObjectId(),
          name: req.body.name,
        email: req.body.email,
         walletAddress : req.body.walletAddress,
      })
      data.save().then(result=>{
          res.status(201).json(result)
          console.log(result)
          name = result.name;
      }).catch(err=>res.status(500))
      
  })

  app.put('/ordered',jsonParser, (req,res)=>{
    console.log(req.body.order)
    Customer.updateOne({_id: req.body._id}, {$push:{orders: req.body.order}}).then(() => {
        return Customer.findOne({ _id: req.body._id });
      }).then(updatedCustomer => {
        res.status(201).json(updatedCustomer.orders);
      }).catch(err=>
            console.warn(err))
   
  })

  app.put('/action',jsonParser, (req,res)=>{
    console.log(req.body.order)
    Customer.updateOne({ _id: req.body._id, "orders.id": req.body.orderId },
    { $set: { "orders.$.status": req.body.status } }
        ).then(() => {
            return Customer.findOne({ _id: req.body._id });
          }).then(updatedCustomer => {
            res.status(201).json(updatedCustomer.orders);
          }).catch(err=>
                console.warn(err))
   
  })
  app.put('/loyalregister', jsonParser, (req,res)=>{
    Customer.updateOne({_id: req.body._id}, {$set :{walletAddress: req.body.walletAddress}}
        ).then(result=>res.status(200).json(result)
    ).catch(err=>console.warn(err));
        }
  )


// app.post('/register', jsonParser, (req,res)=>{
//     const data= new User({
//         _id: new mongoose.Types.ObjectId(),
//         name:req.body.name,
//         email: req.body.email,
//         password: req.body.password, 
//         gender: req.body.gender,
//         body:[],
//         share:[]
//     })
//     data.save().then(result=>res.status(201).json(result)).catch(err=>res.status(500))
// })

// app.post('/sign-in',jsonParser, (req,res)=>{
//     User.findOne({email: req.body.email}).then(result=>{
//         if(result.password=== req.body.password){
//             res.status(200).send(result)
            
//         }
//         else{
//             console.log('user is not valid')
//             res.status(400).end()
//         }
//     }).catch(err=>res.status(500).end())
    
// })

// app.get('/api', (req,res)=>{
//     User.find().then(result=>res.status(200).json(result)).catch(err=>console.log(err))
//     })
// app.get('/abc', (req,res)=>{
// User.find({_id:`6124b1732f80ce118cd7b8d2`}).then(result=>res.status(200).json(result)).catch(err=>console.log(err))
//     })
    
// app.put('/api', jsonParser,(req,res)=>{
        
//         User.updateOne({_id: req.body._id}, {$set:{body:req.body.body}}).then(result=>res.status(201).json(result)).catch(err=>console.warn(err))
// } )
// app.put('/share', jsonParser, (req, res)=>{
//     User.updateOne({email: req.body.email}, {$push:{share: req.body.share}}).then(result=>res.status(201).json(result)).catch(err=>console.warn(err))
// })
// app.put('/add', jsonParser, (req, res)=>{
//     User.updateOne({_id: req.body._id}, {$push:{body: req.body.body}}).then(result=>res.status(201).json(result)).catch(err=>console.warn(err))
// })


app.listen(3001, hostname, ()=>{
    console.log(`listening at http://${hostname}:3001`)
})