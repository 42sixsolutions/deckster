
/**
 * Module dependencies.
 */

var express = require('express')
	, app = express()
	,MongoClient = require('mongodb').MongoClient


MongoClient.connect("mongodb://localhost/27017/users",function(err,db){
	"use strict";

	if(err) throw err;

	//Register templating engine
//	app.engine("html",cons.swig);
	app.set("view engine",'html');
	app.set('views',__dirname+'/views');	
	app.use(express.bodyParser());

	app.param('user',function(req,res,next,collectionName){
		console.dir("Connecting to collection: "+collectionName);
		console.dir(": "+db.collection("user"));
		req.collection = db.collection("user");
		return next();
	});

	app.put('/:user/:id',function(req,res){
		req.collection.update({'_id':req.params.id},{$set:req.body},function(err,update){
			var errorCode = err? 500: 200;
			var result;

			res.writeHead( errorCode,{
				'Content-Type':'application/json',
				'Access-Control-Allow-Origin': '*'
			});

			console.dir(update)

			if (errorCode != 200){
				result = JSON.stringify(err);
			}else{
				result = ((update==1)?{msg:'success'}:{msg:'error'});
			}

			console.dir(result)
			res.end(JSON.stringify(result));

		});
	});

	/*app.post('/:user/:id',function(req,res){
		console.dir(req.body);
		req.collection.findOne({'_id':req.params.id},function(err,result){
			console.dir("POST RESULT")
			console.dir(result)
			if(result == null){
				console.dir("INSERTING")
				req.body["_id"] = req.params.id
				req.collection.insert(req.body,{},function(err,result){
					var errorCode = err? 500: 200;
					
					res.writeHead( errorCode,{
						'Content-Type':'application/json',
						'Access-Control-Allow-Origin': '*'
					});
					if (errorCode != 200){
						result = JSON.stringify(err);
					}else{
						result = (result==null? {"_id":"undefined"}:result);
					}


					res.end(JSON.stringify(result));

				});
			}else{
				console.dir("UPDATING")
				req.collection.update({'_id':req.params.id},{$set:req.body},function(err,update){
					var errorCode = err? 500: 200;
					var result;

					res.writeHead( errorCode,{
						'Content-Type':'application/json',
						'Access-Control-Allow-Origin': '*'
					});


					if (errorCode != 200){
						result = JSON.stringify(err);
					}else{
						result = ((update==1)?{msg:'success'}:{msg:'error'});
					}

					console.dir(result)
					res.end(JSON.stringify(result));

				});
			}
		});
	});
	*/
	app.post('/:user/:id',function(req,res){
			console.dir(req.body);
			req.body["_id"] = req.params.id
			//req.body["layout"] = JSON.parse(req.body["layout"])
			//req.body["removedCards"] = JSON.parse(req.body["removedCards"])

			req.collection.save(req.body,function(err,result){
				console.dir("RESULT SAVED")
				console.dir(result)
				var errorCode = err? 500: 200;
				
				res.writeHead( errorCode,{
					'Content-Type':'application/json',
					'Access-Control-Allow-Origin': '*'
				});

				if (errorCode != 200){
					result = JSON.stringify(err);
				}else{
					result = (result==null? {"_id":"undefined"}:result);
				}

				res.end(JSON.stringify(result));
			
			});
		});

	app.get('/:user/:id',function(req,res){
		console.log(req.params.id);
		req.collection.findOne({'_id':req.params.id.toString()},function(err,result){
			var errorCode = err? 500: 200;
			
			res.writeHead( errorCode,{
				'Content-Type':'application/json',
				'Access-Control-Allow-Origin': '*'
			});
			if (errorCode != 200){
				result = JSON.stringify(err);
			}else{
				result = (result ==null? {"_id":"undefined"}:result);
			}
			console.dir(result);
			res.end(JSON.stringify(result));

		});
	});


	app.get('/:user',function(req,res){
		req.collection.find().toArray(function(err,results){
			if(err) throw err;
			res.send(results);
		});
	});

	app.listen(3000);
	console.log('Express server listening on port 3000');
})